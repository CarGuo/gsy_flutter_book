# Flutter Analyzer 系列坑推进，必看，AI 时代这玩意最吃你内存

很多人现在已经不打开 Android Studio 了吧，但是还是发现电脑内存给吃光了？很大概率这里面 Dart Analyzer  做出了很大贡献。

最近赶住的几条 [Dart Analyzer 的 Issue](https://github.com/dart-lang/sdk/issues)，感觉 Flutter 大型项目里的 Analyzer 确实有点蛋疼，特别是现在  AI Agent、多个 Git worktree 一起开之后，内存本来就紧张，结果 Analyzer 还给你加料，几个 Bug 叠加：

| Issue                                                        | 主要问题                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [#64862](https://github.com/dart-lang/sdk/issues/64862?utm_source=chatgpt.com) | 同一份 Library 在一次分析中解析两遍，665 次变成 1330 次      |
| [#64881](https://github.com/dart-lang/sdk/issues/64881?utm_source=chatgpt.com) | 一次 API 修改以后，729 个 Library 所在的依赖循环反复重新 link，内存从 2.7 GB 增价到 4.0 GB |
| [#64202](https://github.com/dart-lang/sdk/issues/64202?utm_source=chatgpt.com) | Plugin 缺少持久化缓存，导致每次 CI 都可能重复进行大量语义分析 |
| [#64297](https://github.com/dart-lang/sdk/issues/64297?utm_source=chatgpt.com) | SingleFileByteStore 如何降低缓存文件的 I/O 开销              |
| [#64223](https://github.com/dart-lang/sdk/issues/64223?utm_source=chatgpt.com) | Monorepo 中插件错误分析整个工作区，单个 isolate 内存达到 11.6 GB |
| [#63244](https://github.com/dart-lang/sdk/issues/63244?utm_source=chatgpt.com) | 相同插件在不同 package 下重复进行 AOT 编译                   |
| [#63846](https://github.com/dart-lang/sdk/issues/63846?utm_source=chatgpt.com) | 不同 Dart SDK 的插件缓存冲突，导致 macOS `Code Signature Invalid` 崩溃 |

## 同一个 Library，插件为什么会算两次？

先聊聊 [#64862](https://github.com/dart-lang/sdk/issues/64862)，这里的 Library 说的不只是 `.dart` 文件，比如：

```dart
// user.dart
library user;

part 'user_model.dart';
part 'user_service.dart';
```

这三个文件可以组成一份 Library，Analyzer 需要把类型、符号引用和不同 `part` 之间的关系一起处理，才能拿到完整的语义结果。

而 Dart 3.10 引入的新 [Analyzer Plugin 机制](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/using_plugins.md) ，会让插件在独立 isolate 里运行，可以有自己的 `AnalysisDriver` 和缓存，比如项目启用了 Riverpod Lint 之后，主分析服务要检查 Dart 代码，插件也要用自己的分析结果运行规则。

而插件这里的执行流程就比较神奇了：

![](/article-assets/5fd1c491f50a11df0f177867.webp)

`AnalysisDriver` 先解析 Library，然后把 `ResolvedUnitResult` 事件发给 `PluginServer`，之后插件为了执行需要整个 Library 信息的规则，会调用：

```dart
var libraryResult = await analysisContext.currentSession
    .getResolvedLibrary(unitResult.path);
```

这个调用本身没问题，因为 `ResolvedUnitResult` 确实可以代表一个编译单元，因为有些规则需要完整 Library 的 AST 和类型信息。

**问题是当时的 `_resolvedLibraryCache` 只保留包含 priority file 的 Library 结果，也就是 IDE 正在优先分析的那些文件，CI 扫整个项目的时候，绝大多数 Library 不在这个范围内**。

> 所以 Driver 刚刚把 Library A 解析完并发出事件，插件紧接着又要 A 的完整结果，Driver 却找不到刚算出来的东西，然后又重新解析一遍。

比如在 Dart 3.13.7、`analysis_server_plugin` 0.3.25 的测试里面，公共 Flutter + Riverpod 样例有 665 份 Library，`analyzeFile` 调用了 1330 次，私有项目有 736 份 Library，调用了 1472 次。

然后 PR 的 [CL 574462](https://dart-review.googlesource.com/c/sdk/+/574462) 想法也挺那啥：

> **给非 priority Library 加一个只保留最近 8 份完整结果的小缓存**，不负责长期保存 AST，只负责处理「刚发出解析事件，插件马上又来取结果」这个短窗口支持

测试里 `analyzeFile` 在改了之后，从 1330 次回到 665 次，插件的 Cold Run 从约 4.4–4.7 秒降到 4.1–4.5 秒，启用持久化 ByteStore 的 Warm Run 从 1.55 秒变成 1.34 秒，感觉其实对速度没太明显提升。

但是我总觉得这个改法有坑。

## #64881 更离谱

[#64881](https://github.com/dart-lang/sdk/issues/64881)  就更离谱了，明明代码没变了，磁盘上的分析缓存居然会失效，比如一个包含 729 个 Library 的依赖 cycle，只要经历过一次 API 修改，**之后每次启动时， Analysis Server 都重新 link，**还会写出一份大概 10 MB 的 bundle，然后就算把那次修改撤回去也没用。

> **单窗口内存从修改前的 2.7 GB 变成修改后的 4.0 GB，清理缓存才能暂时恢复，但下次 API 修改又会触发**。

**所以你的内存就是这样没的**，这里的 Library cycle 就是相互依赖、需要放在同一轮 link 里处理的一组 Library，大概类似：

```dart
// dep/lib/kinds.dart
enum Kind { a, b }

// dep/lib/dep.dart
import 'kinds.dart' as kinds;

class Base {
  Base.named(this.url, {this.kind = kinds.Kind.a});
  final String url;
  final kinds.Kind kind;
}
```

然后应用里的 `a.dart` 和 `b.dart` 互相 import，`b.dart` 又继承了这个 `Base`：

```dart
// app/lib/a.dart
import 'b.dart';
class A { B? b; }

// app/lib/b.dart
import 'a.dart';
import 'package:dep/dep.dart';
class B extends Base {
  B(super.url) : super.named();
  A? a;
}
```

这里构造函数的默认值 `kinds.Kind.a`，它通过带前缀的 import 引用了 enum，而子类又通过 `super.url` 继承了父类构造参数，比如真实项目里触发这条的可能是 `video_player` 的 `VideoPlayerController`，因为它构造参数里也有类似 `platform_interface.VideoViewType.textureView` 的默认值。

然后通过 `dart language-server` 的诊断状态页查可以看到 `link` 次数：

| 操作 | `link` | `libraryFile` |
| --- | ---: | ---: |
| 空缓存首次启动 | 4 | 13 |
| 不修改代码，再启动 | 0 | 0 |
| 给 `a.dart` 新增一个公开方法，再启动 | 1 | 2 |
| 不修改代码，再启动 | **1** | **2** |
| 继续不修改，再启动 | **1** | **2** |

> 正常来说，最后两次应该和第二次一样直接命中磁盘缓存，但是这里两个计数都是 0，也就是每次都在重建。

原因绕了一圈还是回到 Analyzer 自己读取缓存的实现上：

> 重建 cycle 的时候，`dep` 从已经有 bundle 里惰性加载，然后 `ResolutionReader.readElement` 处理 `ElementTag.libraryImportPrefix `的时候，读了 `currentLibraryFragment.element.fragments`。

问题是这个 `fragments` getter 会被细粒度依赖跟踪机制记录成一次 **opaque API use**，也就是说，本来只是 Analyzer 反序列化自己保存的默认值，然后结果被记成「外部代码用了一个无法细粒度确认的 API」。

之后 bundle 保存了这个要求，下一次启动时 `RequirementsManifest.isSatisfied` 发现 `opaqueApiUses` 不为空，就拒绝复用，然后重新 link 的时候又触发同一条读取路径，再记录一次，到这里循环艺术形成了：

> 第一次 API 修改 → 重新 link → 读取构造函数默认值 → 错误记录 opaque 依赖 → 保存一份下次必定被拒绝的缓存 → 之后每次启动又重新 link。

**这个是真的难顶。**

## 还有组合款

然后是 [#64202](https://github.com/dart-lang/sdk/issues/64202)，它和前面两个问题刚好组成另外一个完全体：当插件 Driver 用的是 `MemoryCachingByteStore(NullByteStore(), 256 MiB)`，内存里可以暂存解析数据，但进程结束以后就没了。

然后主 Analysis Server 可能已经有完整的磁盘缓存，第二次 `dart analyze` 很快，但是插件 isolate 启动以后，**还是要自己重新读文件、解析、link 和计算依赖摘要**。

> 比如开启插件后，`dart analyze --fatal-infos` 大概 15 秒，不启用插件用已经有的缓存只需要 2.4 秒。

而且这里的十几秒耗时，光读取和解析 6697 个文件就用了 4.3 秒，link 3359 个 Library cycle 用了 5.4 秒，计算细粒度依赖 2.6 秒，**真正执行 Riverpod 规则只有 0.1 秒**。

> 也就是说，**你以为是 Riverpod Lint 很重，实际上规则本身只占很小一部分，大头花给插件重复准备整个语义分析环境上**。

## Monorepo 放大问题

然后还有进阶版本，到了大型 Flutter Monorepo 还会再放大一层，[#64223](https://github.com/dart-lang/sdk/issues/64223) 还有一个更可怕的场景：

> Dart 3.13.2 的 LSP 把整个工作区作为分析根目录转交给插件，导致本来只配置在一个小 package 里的插件，也开始分析整个 Monorepo。

比如项目有 1.4 万个 Dart 文件、45 个分析上下文，**同一插件 isolate 只分析小 package 时占 0.19 GB，改成打开整个仓库根目录就到了 11.6 GB，天啊，这个说的不就是我吗！！！！！**

> **启用两个插件时整个进程 34 GB，不启用插件是 10.3 GB，不过目前看起来是修复了**。

**另外在 macOS 上同时打开两个使用不同 Dart SDK 的工程，两个 Analysis Server 可能读写同一个插件 `plugin.aot` 缓存文件，一个进程映射的文件被另一个覆盖，系统会用 `Code Signature Invalid` 把它 SIGKILL，这个也是之前一个恶心的 Bug** 。

## 最后

把这些 Issue 放一起看，总感觉 Analyzer 有一堆 AI 写出来的烂摊子，边界问题太多了，32GB 的内存都不用这么造，每次都要硬盘 swap 到死机。
