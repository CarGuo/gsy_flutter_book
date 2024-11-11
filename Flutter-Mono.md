# Flutter 正在切换成 Monorepo 和支持 workspaces 

其实关于 Monorepo 和 workspaces 相关内容在之前[《Dart 3.5 发布，全新 Dart Roadmap Update》](https://juejin.cn/post/7399984522094116891#heading-4) 和 [《Flutter 之 ftcon24usa 大会，创始人分享 Flutter 十年发展史》](https://juejin.cn/post/7418061055207178249) 就有简单提到过，而目前来说刚好看到 flaux 这个新进展，所以就再展开来聊聊目前  Flutter 里进行中的 Monorepo 和 workspaces。

![](http://img.cdn.guoshuyu.cn/20241105_Mono/image1.png)

> 其实如果你不跑引擎，不提 PR 或者不看源码，那 monorepo 调整对你来说应该没什么正向影响。

# monorepo

可能有人还没听说过 monorepo，先介绍下 monorepo（mono repository） ，它是一种项目代码的管理方式，就是将多个项目存储在一个 repo 中，在 monorepo 里多个项目的所有代码都存储在单个仓库里，这个集中式存储库包含 repo 中的所有组件、库和内部依赖项等。

monorepos 也不是什么新概念，很早之前 Google、Meta、Microsoft、 Twitter 等公司都在大规模使用 monorepos ，比如 `React` 、 `Vscode` 、`Babel`  都使用了 monorepo，如下图所示可以看出来他们在形式和结果的区别：

![](http://img.cdn.guoshuyu.cn/20241105_Mono/image2.png)

> 更多可见原文：https://blog.bytebytego.com/p/ep62-why-does-google-use-monorepo

使用 monorepo 的最主要原因之一是简化代码管理，由于所有代码都存储在单个存储库中，因此可以更轻松地跟踪更改、保持版本一致性等，例如 Meta 的工程师曾就表示过：

> Meta 的 monorepo 包含公司的大部分代码，可以轻松访问所有代码对开发人员的效率非常重要，工程师可以更深入地了解其依赖关系，调试整个堆栈中的问题，并实施功能或错误修复，所有这些都触手可及······
>
> ······版本控制是使用多个存储库时最复杂的问题之一，每个存储库都是独立的，团队可以自由决定要采用的依赖项版本，但是由于每个存储库都按照自己的节奏发展，这些不一致会导致项目可能包含同一依赖项的多个版本，从而导致后续版本控制的各种冲突·····
>
> https://www.growingdev.net/p/what-it-is-like-to-work-in-metas

所以 monorepo 不仅仅只是将所有源代码“紧密放在一起”，更是确保存储库中各个库和应用相互兼容的重要工具：

> 简单点说人话就是：**将现在 Flutter 项目下的 `flutter/engine` 、`flutter/buildroot` 和 `flutter/flutter ` 这三个存储库合并到单个 flutter/flutter 存储库中**。

采用 monorepo 对于目前 Flutter 来说有着许多好处，例如更方便的 CI 和更容易协作，同时提高代码共享的能力，例如在现在的  `flutter/flutter `  项目下，由于 `flutter/flutter `  和  `flutter/engine`  是两个独立项目，所以经常可以看到一堆”无意义“的 Roll Engine  PR 的记录存在：

![](http://img.cdn.guoshuyu.cn/20241105_Mono/image3.png)

> “Roll Flutter Engine from····” 主要是为了更改 framework 引用的 engine 的版本，每次 engine 有新的提交的时候，都会在 framework 自动创建一个 PR，更新 engine ，当所有测试通过时，PR 就会自动合并。

而如果使用 monorepo ， `flutter/flutter `  和  `flutter/engine`  将不再是相互隔离的 repo ，在 CI 和版本管理上都会更轻便可控，例如一开始文章提到的 `flutter/flaux` ，就是目前 Flutter 正在测试合并流程的项目，在最终合并到主`flutter/flutter`  之前验证 monorepo 的仓库。

> 也就是 `flutter/engine` 这个 repo 最终会在未来的某个时间点被 Archive ，虽然这和 Flutter 以前解释说[不适用 monorepo 的原因相违背]( https://github.com/flutter/flutter/blob/master/docs/about/Why-we-have-a-separate-engine-repo.md)， 但是这个阶段来看，Flutter 还是需要选择 monorepo。

对于 monorepo 而已，所有依赖都是一个来源，所以意味着不存在版本冲突和依赖地狱，同时 monorepo 还支持原子提交，在大规模重构里开发人员可以在一次提交中更新多个包或项目。

![](http://img.cdn.guoshuyu.cn/20241105_Mono/image4.png)

其实目前 pub 上很多项目都在使用类似 monorepo 的结构，例如 [riverpod](https://github.com/rrousselGit/riverpod/tree/master/packages) 、[cfug/dio](https://github.com/cfug/dio) 、[ubuntu/app-center](https://github.com/ubuntu/app-center) 、[Flame-Engine/Flame](https://github.com/flame-engine/flame) 等项目都在使用 [melos](https://pub-web.flutter-io.cn/packages/melos) 做  monorepos 管理，而 Flutter 这次也是通过自定义对应的 CI 基础能力来更新以支持合并后的 repo 构建，也就是 Flutter 针对 monorepo 结构自定义了一套新的 CI 系统，**事实上 monorepo 核心之一，就是在于 CI 的搭建还有项目结构分层的处理上**。

> 更多可见：https://melos.invertase.dev/~melos-latest/#projects-using-melos 、https://github.com/orgs/flutter/projects/182/

## 总结

总结起来，Flutter 迁移到 monorepo 的好处在于：

- **提交原子性**：engine、framework 和 buildroot 的变更可以一起提交，更好管理
- **减少依赖** ：可以减少大量内部版本依赖和冲突问题，大规模减少类似 Roll 类型的历史提交等

- **简化 PR**：用户可以更直观和方便提交 PR，包括这个 PR 需要从 engine 到 framework 多方调整的时候

- **更方便测试：** engine 和 framework 可以在同套 CI 下测试调整

当然 monorepo 也带来了新的问题，例如一个 repo 下多个 Dart 项目的解析问题，这就不得不说下面的 workspaces 概念。

# workspaces

在 Dart 3.5 的时候，Dart Roadmap 就提出了 pub workspaces 概念，核心就是在 monorepo 中实现多个相邻包的共享解析，比如「共享解析」可以解决类似编辑器中的 Analyzer 占用空间过大问题，因为它可以减少单独的上下文 context。

> analysis_options.yaml 下的大量规则引入也会增加内存上涨，事实上 Dart Analyzer 的上下文数量一直是内存消耗大户。

在 [dart#53874](https://github.com/dart-lang/sdk/issues/53874) 提到过，由于 monorepo 结构化的原因，Analyzer 在工作的时候最终会为每个包及其所有依赖项加载了多个重复的 analysis contexts，从而导致 monorepo 里每个包 analysis 时在内存中生成了多个副本，最终出现内存占用过大问题：



![](http://img.cdn.guoshuyu.cn/20241105_Mono/image5.png)



![](http://img.cdn.guoshuyu.cn/20241105_Mono/image6.png)

**而解决方案就是在这些 repo 中为每个依赖项创建一个共享解决方案，也就是这里提到的  `pub workspaces`** ，通过  workspaces ，项目在 monorepo 中可以实现多个相邻包的共享解析，通过共享 Analyzer 等工具在分析每个包之间共享上下文，从而节省大量内存。

> 也就是 workspaces 可以让  monorepo  创建共享版本来优化依赖项解析速度和内存。

例如，你可以通过 `workspace`  关键字启用  workspaces 并引入对应的 packages 结构：

```yaml
name: workspace
environment:
  sdk: ^3.5.0
workspace:
  - packages/package_a
  - packages/package_b
```

然后在 `packages/package_a/pubspec.yaml` 和 `packages/package_b/pubspec.yaml` 添加一行 `resolution: workspace`： 

```yaml
name: package_a
environment:
  sdk: 3.5.0
resolution: workspace

dependencies:
  # You can depend on packages inside the workspace:
  package_b: ^1.2.4 # This version constraint will be checked against the local version
dev_dependencies:
  test: ^1.0.0

```

此时你的项目就已经处于  workspace 的工作模式下，而 workspaces 主要是支持 workspaces 下 monorepo 的包之间的共享解析，例如**在仓库中的任意位置运行 `flutter pub get` ，项目会将产生一个共享解析，具体表现为：只会在 root  `pubspec.yaml`  同级目录生成 一个 root  `pubspec.lock`** 。

![](http://img.cdn.guoshuyu.cn/20241105_Mono/image7.png)

另外，通过 dart pub deps 也可以更清晰看到整个 workspace 的依赖关系，也可以更好管理和同步依赖，结合 monorepo 结构或者 melos 等工具的能力，会让整个项目更直观可控：

![](http://img.cdn.guoshuyu.cn/20241105_Mono/image8.png)





# 最后

可以看到 monorepo 和 workspaces  属于相辅相成的存在，而 monorepo 也不是单纯就是把东西放到一个 repo ，更多涉及项目结构的分层，包的细化还有最关键的 CI 工具支持等，同时 monorepo 也可以更好管理所有项目的依赖关系，甚至支持增量构建等等。

总的来说 monorepo 并不是什么新鲜东西，只是到了这个阶段 Flutter 所需要做的一个调整，之前采用 multi repo 是规划里把多个 repo 当作独立产品，而现在是作为一个整体项目来管理的情况下，自然选择  monorepo 更合适。



## 参考资料

- https://github.com/dart-lang/sdk/issues/53875

- https://github.com/dart-lang/pub-dev/pull/7762

- https://github.com/dart-lang/pub/issues/4391

- https://github.com/dart-lang/pub/issues/4127

- https://docs.google.com/document/d/1UEEAGdWIgVf0X7o8WPQCPmL4LSzaGCfJTM0pURoDLfE/edit?resourcekey=0-c5CMaOoc_pg3ZwJKMAM0og&tab=t.0

- https://github.com/flutter/engine/blob/main/pubspec.yaml

- https://github.com/orgs/flutter/projects/182

- https://github.com/flutter/flaux

- https://github.com/flutter/cocoon

