![](https://img.cdn.guoshuyu.cn/1_KLn6ye1qAU9vAI3zgIhLCg.jpg)

# Flutter 3.35 发布，快来看看有什么更新吧

Flutter 3.35 来了，本次版本大部分调整属于较小改动，主要包含 Web 默认启动 hot reload、  Material 和 Cupertino 风格控件的一些更新，还有一些性能优化和工具更新等，而最让人关注的莫过于 **Multi-window 支持终于发布了**，虽然暂时只有 Windows 和 macOS。

# Web

从 3.35 开始，**Flutter Web 将默认启动 hot reload**，这算是 Web 平台统一之后的最大突破，而 hot reload 的支持也是后续 Widget PreView 功能的基础支撑。

> 目前可以通过  `--no-web-experimental-hot-reload` 禁用。

其次，为了将 WebAssembly (Wasm) 作为 Web 的默认构建 target，现在每个 JS build 都会执行一次 Wasm 的 “dry run”  编译，它会通过一系列检查确定应用程序的 Wasm 适配情况，并将结果以警告形式发送到控制台，用户可以使用 `--(no-)wasm-dry-run`  标志来对该功能进行调整。

> 可以看到，Flutter Web 将在 Wasm 路线一路走到底，感兴趣的可以看：[Flutter Web 的发展历程：Dart、Flutter 与 WasmGC](https://juejin.cn/post/7527276907273076775)

另外，Flutter Web 和屏幕阅读器及其他工具的通信有了重大进展，针对国际用户新增了语义语言环境支持 ( [#171196](https://github.com/flutter/flutter/pull/171196) )，确保无障碍功能可以针对用户偏好的语言进行优化。

# Framework

## 无障碍

在 Framework 上，开发者现在可以使用全新的 `SemanticsLabelBuilder`  ( [#171683](https://github.com/flutter/flutter/pull/171683) ) 简化多个数据点组合的过程，不在需要进行繁琐的字符串连接。

对于复杂的可滚动视图，可以使用全新的 `SliverEnsureSemantics` 小部件（ [#166889](https://github.com/flutter/flutter/pull/166889) ）来包装 slivers，确保它们始终在语义树中表示，即使滚动出视图。

`CustomPainter` （ [#168113](https://github.com/flutter/flutter/pull/168113) ）的语义属性现在已经填充支持，所以 Fltuter 能够让自定义绘制的 UI 适配无障碍访问。

text selection toolbar 现在可以正确对齐从右到左 (RTL) 的语言，从而改善体验 ( [#169854](https://github.com/flutter/flutter/pull/169854) )。

而针对平台问题修复上有：

- 在 iOS 上， `CupertinoSliverNavigationBar` 现在可以正确遵循 accessible text  缩放（ [#168866](https://github.com/flutter/flutter/pull/168866) ），并且 VoiceOver 标签激活行为现在可以正常工作（ [#170076](https://github.com/flutter/flutter/pull/170076) ）。

- 对于 Android，Talkback 问题现在可在使用 platform view ( [#168939](https://github.com/flutter/flutter/pull/168939) ) 时解决，这对于嵌套平台控件的应用来说是一个关键的修复。



## Material 和 Cupertino

虽然 Flutter 已经官宣了将从 Framework 剥离 Material 和 Cupertino 风格控件为独立包维护，但是本次更新还是包含了一些 Material 和 Cupertino 的更新。

![](https://img.cdn.guoshuyu.cn/image-20250813111054956.png)

本次新增还主要包括：

- **增加 DropdownMenuFormField（** [**#163721**](https://github.com/flutter/flutter/pull/163721) **）：** 现在可以将 M3 效果的 `DropdownMenu` 直接集成到表单中
- **Scrollable NavigationRail ：** 现在可以将 `NavigationRail` 配置为滚动模式
- **NavigationDrawer header and footer ：** 现在可以向 `NavigationDrawer` 添加页眉和页脚
- **CupertinoExpansionTile (** [**#165606**](https://github.com/flutter/flutter/pull/165606) **)：** 使用新的 `CupertinoExpansionTile` 创建可扩展和可折叠的列表项![](https://img.cdn.guoshuyu.cn/1_Npm3gOKVmU1hMq4ujCPxCg.gif)

- 许多 Cupertino 都已经已更新为使用 `RSuperellipse` 形状（ [#167784](https://github.com/flutter/flutter/pull/167784) ），从而提供 iOS 用户期望的标志性连续角外观。
-  `CupertinoPicker` ( [#170641](https://github.com/flutter/flutter/pull/170641) ) 和 `CupertinoSlider` ( [#167362](https://github.com/flutter/flutter/pull/167362) ) 等关键交互组件添加了触觉反馈
-  `Slider` 的值指示器可以配置为始终可见 ( [#162223](https://github.com/flutter/flutter/pull/162223) ) ：`const SliderThemeData(showValueIndicator: ShowValueIndicator.always);`

另外，本次还针对 slivers  做了一个重大更新，对于构建复杂滚动的场景，现在可以明确控制**slivers 的绘制顺序（或 z 顺序）** （ [#164818](https://github.com/flutter/flutter/pull/164818) ），从而可实现高级效果，例如与其他碎片重叠的“粘性”标题，而不会出现视觉故障：

```dart
CustomScrollView(
	paintOrder: SliverPaintOrder.lastIsTop,
	center: const ValueKey<int>(2),
	anchor: 0.5,
	slivers: List<Widget>.generate(5, makeSliver),
)
```

而对于 **navigation**  和 **forms** ，3.35 还增加了更细粒度的控制支持：

- **全屏对话框 (** [**#167794**](https://github.com/flutter/flutter/pull/167794) **)：** ModalRoute（及其所有后代）和 `showDialog` 都新增了 `fullscreenDialog` 属性，允许自定义对话框路由的 navigation  行为

- `FormField` 现在包含一个 onReset 回调，从而支持表单清除逻辑 ( [#167060](https://github.com/flutter/flutter/pull/167060) )

接着就是**万众瞩目的多窗口**，Canonical 终于在添加多窗口支持取得卓越进展，在 3.35 中已经实现了在 Windows 和 macOS 中创建和更新窗口的基础逻辑 ( [#168728](https://github.com/flutter/flutter/pull/168728) )，后续版本将更新 Linux 系统，并引入实验性 API 以支持多窗口功能。

![](https://img.cdn.guoshuyu.cn/ezgif-2af5c58e96f9c7.gif)

> Canonical 作为 Ubuntu 的开发商，多窗口能力最晚支持 Linux 也是有趣，更多可见：[《Flutter 官方多窗口体验 ，为什么 Flutter 推进那么慢，而 CMP 却支持那么快》](https://juejin.cn/post/7510701347072344105) 。

然后就是几乎每个版本更新都会有的文本输入和选择功能：

- **更加统一的手势系统：** `PositionedGestureDetails` 接口（ [#160714](https://github.com/flutter/flutter/pull/160714) ）的引入统一了所有 pointer-based 的手势的细节，并允许开发者实现更通用的自定义手势处理代码
- **iOS single-line scrolling（** [**#162841**](https://github.com/flutter/flutter/pull/162841) **）：** 为了更好地与原生 iOS 行为保持一致，用户默认不再可以滚动single-line text fields，因为在 iOS 上，单行 TextField 无法通过用户输入（例如平移手势来移动视口）进行滚动，用户需要拖动选择 handle 来进行滚动:![](https://img.cdn.guoshuyu.cn/image-20250813113502216.png)



- **Android home/end 按键支持（** [**#168184**](https://github.com/flutter/flutter/pull/168184) **）：**添加了对 Android 上的 `Home` 和 `End` 键盘快捷键的支持

最后，就如前面说的， 对于 Framework 来说，**未来的核心目标之一就是解耦 Flutter 的设计库**，也就是将 Material 和 Cupertino 库从 Flutter 核心框架中移出，并将它们放入各自的独立包中进行维护，这有利于设计库的迭代更新速度，也可以让 Flutter 的核心架构更专注于渲染部分的实现。

> 更多可见：https://docs.google.com/document/d/189AbzVGpxhQczTcdfJd13o_EL36t-M5jOEt1hgBIh7w/edit?usp=sharing

# iOS & Android

在 Android 上，**从 3.35 开始可以在 Flutter 应用中使用 `SensitiveContent` ，在媒体投影期间保护敏感的用户内容**，在 API 35 及更高版本中，可以使用该控件在屏幕共享期间遮挡整个屏幕，从而帮助防止数据被盗。

而在 iOS 上，由于 JIT 的全面禁止，目前官方正在积极优化 Flutter 与 iOS 26 测试版]的兼容性，在之前的[《Flutter 又双叒叕可以在 iOS 26 的真机上 hotload 运行了》](https://juejin.cn/post/7519118964975992886)我们聊过，由于  `mprotect` 的方法行不通了，所以官方临时使用一个外置脚本，通过 `NOTIFY_DEBUGGER_ABOUT_RX_PAGES` 触发 LLDB 断点的函数来让 LLDB 赋予临时 RWX 权限的实现。

但是这毕竟不是长久之计，所以在 [#173416](https://github.com/flutter/flutter/issues/173416) ，官方将基于  `devicectl`  和 LLDB 实现全新的 JIT 和 hotload 适配支持，比如 Flutter 工具将通过 `lldb` 进程的标准输入（stdin）流和输出（stdout）流来发送预设好的命令，从而实现附加进程和连接 debugserver 等实现。

# Engine

3.35 版本继续专注于提升 Impeller 的性能和兼容性，**此外官方还投入了大量精力支持 iOS 平台的 `UISceneDelegate` 接口**，并引入了其他工具改进。

首先 Flutter 在 3.29 和 3.32 引入和线程合并功能，**而针对该功能在 3.35 增加了通过在新线程上执行初始化的相关优化**，启动完成后平台线程和 Dart 线程依旧会被合并，从而减少了应用的启动时间。

而关于 Impeller 的优化有：

- 从中间目标中删除 MSAA
- 删除有损纹理压缩默认值
- 修复了后续绘制中卡住的 `MaskFilter` 问题。
- 优化了路径渲染。
- 添加了 Vivante GPU 支持
- 优化了 `DrawImageNine` 现在使用快速 Porter Duff 混合
- 修复 VideoPlayer 中的内存泄漏
- 增加了模糊半径计算，以获得具有较大 sigma 的更清晰的模糊

关于 iOS 在 Engine 层修复有：

- 解决了使用 `ClipRSuperellipse` 嵌套的 `WebView` 中的崩溃问题
- 修复当从远程通知在后台启动应用时，图像解码异常那问题
- 将  Live Text (OCR) 选项恢复到 text fields

关于 Android 在 Engine 层修复有：

- 模板项目迁移至 Android 24
- 修复了 Android <= 14 上背景图像读取器崩溃的问题
- 修复了 OpenGLES Impeller 的片段着色器中的统一数组
- 修复了 OpenGLES Impeller 中颠倒的片段着色器通道
- 修复 `FlutterEngineGroup` 中的崩溃问题

关于 macOS 在 Engine 层修复有：

- 修复显示 P3 颜色



# Dart & Flutter MCP 

现在 Dart 和 Flutter MCP Server 正式 stable 发布，主要是增强了 AI 编码助手的 Dart 和 Flutter 上下文，Dart 和 Flutter MCP Server  充当桥梁，可以让 AI 通过 Dart 和 Flutter 工具链访问项目的更多上下文：

- **修复运行时错误** ：检查实时 Widget 树，识别 Flutter RenderFlex 溢出，并自动应用正确的修复
- **管理依赖项** ：在 pub.dev 上找到针对特定任务的最佳包，将其添加到 `pubspec.yaml` ，然后运行 `pub get` 
- **编写和纠正代码** ：为新功能生成样板，然后自行纠正其在此过程中引入的任何分析错误
- ····



![](https://img.cdn.guoshuyu.cn/ezgif-6e17e4f396dce5.gif)

现在可以通过 Gemini Code Assist、Firebase Studio、Gemini CLI、GitHub Copilot 和 Cursor 等连接到 Dart 和 Flutter MCP Server 。

> 有关 Dart 和 Flutter MCP  的功能和配置，可以查看：https://dart.dev/tools/mcp-server 。



# 实验性 Widget Preview



在之前的 [《提前在体验的预览支持》](https://juejin.cn/post/7522006762512039955) 我们就聊过 Flutter Widget Preview 即将落地，现在 3.35 正是推出了 Flutter Widget Previews 的早期实验版本。

Widget Preview 现在支持在完全独立于完整应用的沙盒环境中可视化和测试 Widget，并且在构建设计系统或跨多种配置（例如各种屏幕尺寸、主题和文本比例）同时并行测试组件时非常有用：

![](https://img.cdn.guoshuyu.cn/1_lbPiKmVYKfvwC8v20DuGWA.gif)

体验 Widget Preview 很简单，只要你在 master 分支，然后添加对应的 `@Preview` 注解，之后执行 `flutter widget-preview start ` 即可运行预览：

```dart
@Preview(name: 'Top-level preview')
Widget preview() => const Text('Foo');

@Preview(name: 'Builder preview')
WidgetBuilder builderPreview() {
  return (BuildContext context) {
    return const Text('Builder');
  };
}

class MyWidget extends StatelessWidget {
  @Preview(name: 'Constructor preview')
  const MyWidget.preview({super.key});

  @Preview(name: 'Factory constructor preview')
  factory MyWidget.factoryPreview() => const MyWidget.preview();

  @Preview(name: 'Static preview')
  static Widget previewStatic() => const Text('Static');

  @override
  Widget build(BuildContext context) {
    return const Text('MyWidget');
  }
}
```

 `@Preview` 注解可以添加在普通函数或者构造函数上，例如 `MyWidget.preview` 就是一个比较实用的方式：

```dart
  @Preview(name: 'Constructor preview')
  const MyWidget.preview({super.key});
```

当然，目前运行  `flutter widget-preview start `  时，如果你的依赖里有 git 依赖时，预览就直接报错，因为`widget_preview_scaffold` 会在根目录下生成一个 `preview_manifest.json` ，包含有关当前 Dart 和 Flutter SDK 版本的信息，以及用户的 pubspec.yaml 的哈希值，这个哈希值用于后续自动对比用户工程的 pubspec 是否发生变化，而很明显目前不支持 git 依赖的

![](https://img.cdn.guoshuyu.cn/image-20250702134432581.png)

而目前预览成功运行之后，其实会直接打开一个外部 Chrome 来承载 Widget Preview ，我们可以根据需要在 `@Preview` 添加对应 `Size` 来调节高度和宽度，如果不设置宽度，那么它会跟随浏览器的宽度进行变化：

![](https://img.cdn.guoshuyu.cn/image-20250702134445125.png)

而实际上的页面运行之后其实就是一个基于 CanvasKit 的 Fluttre Web，你可以直接进行各种 UI 操作，基本上和你在 App 里的体验没什么差别：

![ezgif-526a0d55a0d519](https://img.cdn.guoshuyu.cn/ezgif-526a0d55a0d519.gif)

> 更多可见：https://juejin.cn/post/7522006762512039955



# Analysis Server 速度改进

使用 Analysis Server 的 dart 命令行工具，现在运行 AOT 编译的 Analysis Server 快照，这些命令包括 `dart analyze` 、 `dart fix` 和 `dart language-server` 。

使用 AOT 编译的 Analysis Server 快照时，功能上并无差异，但各种测试表明，项目分析时间显著缩短，更新后在示例包上运行一些常用命令时统计数据的变化：

![](https://img.cdn.guoshuyu.cn/image-20250813131928148.png)

总体而言，**一些简短的命令（例如格式化）现在可以在极短的时间内完成，而运行时间较长的命令（例如分析）的速度则提高了近 50%**。

# 重大变更和弃用

- 为了使主题更加一致， `AppBarTheme` 、 `BottomAppBarTheme` 和 `InputDecorationTheme` 等组件主题已重构，并基于新的面向数据的 `…ThemeData` 类型
- **Radio widget redesign:**  `Radio` 、 `CupertinoRadio` 和 `RadioListTile` 已重新设计优化适配 accessibility，`groupValue` 和 `onChanged` 已弃用，取而代之的是新的 `RadioGroup` Widget，用于管理一组单选按钮的状态
- **Form widget and slivers:** `Form` 不再能够直接用作 Sliver，要将 `Form` 包含在 `CustomScrollView` 中，需要将其包装在 `SliverToBoxAdapter` 
- **Semantics elevation and thickness removal:**  `SemanticsConfiguration` 和 `SemanticsNode` 上的 `elevation` 和 `thickness` 属性已被移除
- **DropdownButtonFormField 值弃用：** `DropdownButtonFormField` 上的 `value` 参数已被弃用，并重命名为 `initialValue` 

在 3.35 版本中，将弃用 3.13 之前的 Flutter SDK IDE 支持，在下一个稳定版本中 3.16 之前的 Flutter SDK 将被弃用。

**Android 上已弃用 32 位 x86 架构** ，Flutter 支持的最低 Android SDK 版本（由 `flutter.minSdkVersion` 提供）目前为 API 24（Android 7），现在至少必须具备：

- Gradle version: 8.7.0 
- Android Gradle Plugin (AGP): 8.6.0
- Java: 17 Java：17

# 最后

随着多窗口功能的发布，Flutter Window 终于又可以开始焕发它新的活力了，这也算是 3.35 里最重要的更新，而未来最值得期待的，必然是**解耦 Flutter 的设计库**，也就是将 Material 和 Cupertino 库从 Flutter 核心框架中移出，这对于 Flutter 来说无疑是一项庞大又费时工作，但是对于未来而言，这确实时必要的举动。

那么，大家准备好吃螃蟹了么？