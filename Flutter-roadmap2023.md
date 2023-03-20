# Flutter 2023 Roadmap 解析



随着  [Flutter Forward](https://juejin.cn/post/7192646390948823098) 大会召开， Flutter 官方在 [3.7 版本 ](https://juejin.cn/post/7192468840016511034)之余为我们展示了如 3D 渲染支持、add-to-web 等未来可能出现的 Feature，但是这些都还只是处于开发中，未来可能还会有其他变动，而在大会结束后，官方也公布了更详细 [2023 年的 Roadmap](https://github.com/flutter/flutter/wiki/Roadmap)。

> [Flutter Forward](https://juejin.cn/post/7192646390948823098) 展示未来大方面，Roadmap 展示接下来更详细的计划。

# 性能

首先 **2023 年官方首要任务还是在于性能优化，也就是 Impeller** ，3.7 开始  Impeller 已经可以在 iOS 上进行预览，那么下一步就是将 Impeller 提升为 iOS 的默认底层渲染器，从而解决陈年顽疾如[色器编译器卡顿](https://github.com/orgs/flutter/projects/21) 的问题。

> iOS 之后， Impeller 在 Android 上针对 Vulkan 支持和在桌面端的支持也会逐步推进，**这将是 Flutter 2023 最让人期待的目标：全员 Impeller**，相信自己的渲染器，修复器问题会比 Skia 更快？

对于 Web，Flutter 一直都存在两种底层 render 支持：html 和 canvaskit，而随着 Dart3 将直接支持 WebAssembly （使用 WebAssembly 规范的新 WasmGC 指令），**Flutter 官方也将[更多投入 WASM 路线](https://github.com/flutter/flutter/issues/41062)** 。

![](http://img.cdn.guoshuyu.cn/20230129_roadmap/image1.png)

> 那么这是不是官方在二选一中做出了最终抉择？为此 [ Flutter Web 支持 “hot reload”（不仅仅是 “hot restart”） -  #53041](https://github.com/flutter/flutter/issues/53041) 相关进度目前也暂时停滞。

**另外对于 Web 还有并计划实现[多线程渲染](https://github.com/flutter/flutter/issues/114243) ，减少应用的下载大小，并提高自定义着色器的性能等相关计划**。

> 看起来 Flutter Web 的实用性在 2023 会被进一步增强。

最后关于  VM 的性能优化，官方在 2023 将致力于[**改进存分配策略**](https://github.com/dart-lang/sdk/issues/47574)，从而提高应用的响应速度和启动性能：

> 目前考虑是利用 v8 GC 的 RAIL（Response、Animation、Idle、Loading）模型，在不同阶段提供通知（就像它目前为 idle 所做的那样），并且 VM 可以相应地调整一些 GC 行为。

# 质量

首先 Flutter 官方很看重 Accessibility 的能力，所以 2023 年目标之一是：**提高所有平台上的 Accessibility 的支持质量**。

> 虽然国内开发团队貌似对 Accessibility 并不是特别感冒。

同时继续改进 Flutter 相关的文档质量也是目标之一，其实从我个人来看，目前 Flutter 提供的各类文档的质量和覆盖已经相当不错了。

另外，2023 Flutter 还将继续完善所有平台上 UI 还原能力，尤其是 Android 和 iOS：

> 例如，预计今年 Cupertino 相关控件集将取得重大进展，让 iOS 平台能够保持最新状态并增加支持的 Widget 数量。

同时在界面相关方面，未来 Flutter 官方还计划实现：

-  [Android 13 的预测后退手势](https://github.com/flutter/flutter/issues/109513)： `android:enableOnBackInvokedCallback` ，主要是用于大屏幕和可折叠设备

  ![](http://img.cdn.guoshuyu.cn/20230129_roadmap/image2.gif)

-  [Android 手写输入](https://github.com/flutter/flutter/issues/115607)支持
- [相机插件](https://github.com/flutter/plugins/tree/main/packages/camera)移植到 Android 最新的 CameraX API

> 貌似 Android 14 也要来了，一波未平一波又起。

# Features

2023 还会有一些实用的新功能，这些功能对于开发者来说应该是很迫切的需求，衡量它们的标准主要有：

- 受欢迎程度（一个问题收到了多少“点赞”）
- 平价性和可移植性（一旦一个平台支持后，它能不能给其他平台同时带来价值）
- 能够达到一些更好的结果（例如可以进一步提高性能的新功能）。

所以 2023 预计要实现的功能有：

- [自定义  asset 转换器](https://github.com/flutter/flutter/issues/101077)，因为它们可以提高性能，例如在构建时对  icon fonts 进行转换，支持自定义 API，让第三方工具可以自定义转换
- [优化可滚动控件](https://github.com/orgs/flutter/projects/32)，例 [Table ](https://github.com/flutter/flutter/issues/87370)和[ Tree](https://github.com/flutter/flutter/issues/114299) ，提供类似 builder 的懒加载能力 ，以此来应用的性能
- **[多窗口支持](https://github.com/flutter/flutter/issues/30701)，特别是对于桌面端，因为这是一个呼声很高的功能**，例如考虑在实现上通过三个打开的窗口共享相同的统一 `widget-tree` 
- **[macOS ](https://github.com/flutter/flutter/issues/41722) 和 [Windows](https://github.com/flutter/flutter/issues/108486) 上的 `PlatformView ` 支持**，也是呼声很高的功能
- [边界拖放 ](https://github.com/flutter/flutter/issues/30719)能力的支持。
- **[iOS 上支持的无线调试](https://github.com/flutter/flutter/issues/15072)** 。
- [自定义 “flutter create” 模板](https://github.com/flutter/flutter/issues/77104)，从而更好支持如 [Flame 引擎](https://flame-engine.org/)引导。
- 支持  [element embedding](https://github.com/flutter/flutter/issues/118481)  ，也就是 [add-to-web - #32329](https://github.com/flutter/flutter/issues/32329)， 从而开发人员可以将 Flutter 内容添加到任何 Web `<div>`

> 都是很值得期待的功能，期待下个版本时能够用上。

# 研究

由于 Impeller 的到来，**未来 Flutter 可能会支持某种形式的自适应布局，从而实现更贴近平台特性的 UI 效果**。

> 这个探索会先从 Android 与 iOS 开始，这类支持可以很好补全目前 Flutter 上，针对某些平台特性需要在业务代码上额外适配的问题。

另外 Flutter Forward 提到的 3D 能力，也在今年的实验范围之内，同时利用 Impeller 改进底层 `dart:ui` API 和新的着色器等相关能力，也是探索的目标之一。

与此相关的还有 [Display P3 宽色域支持](https://github.com/flutter/flutter/issues/55092)（可能会从 iOS 开始），这也是一项要求很高的功能

> 这个改进总觉得可能会引发其他坑。。。。

除此之外，Flutter 还在研究从 ICU4C 迁移到 ICU4X（新的[基于 Rust 的 ICU 后端](https://github.com/unicode-org/icu4x)），这里需要探索如何将 Rust 嵌入到所有平台的构建渠道，如何在引擎和 Dart FFI 包之间共享 Rust 代码，以及如何对此类包中使用的二进制代码执行 tree-shaking。

最后，**还有如何更新 Flutter SDK 使用 Dart 3 的新功能，例如更新我们的 API 使用 records 和 patterns**，更新我们的工具链支持 RISC-V，还有使用插件的新 FFI 功能等。



# 发布

2023 年计划**发布 4 个稳定版本和 12 个 Beta 版本**，在 2023 年不一样的地方是新功能在 Beta 时 Flutter 团队就会对外公布它们，而不是和之前一样等倒它们进入 Stable 版本。

> 也就是官方鼓励开发者更多投入到 Beta 的尝试中来，我忽然想起 Android Studio Canary 版本貌似比 Release 更稳定的现状····

# 非目标的功能

目前 Web 上实现 hot reload 暂时停滞，因为 Flutter 的 Web 团队目前都在致力于 Wasm 的生产支持。

另外，对于以下功能 Flutter 团队目前依旧没有支持的计划：

- [code push](https://github.com/flutter/flutter/issues/14330#issuecomment-1279484739)
- 对可穿戴设备（[Apple Watch](https://github.com/flutter/flutter/issues/28901#issuecomment-1385926218)、[Android Wear](https://github.com/flutter/flutter/issues/2057)）
- [汽车集成 ](https://github.com/flutter/flutter/issues/26801#issuecomment-1013565542)的内置支持
- [对 Web SEO 的 ](https://github.com/flutter/flutter/issues/46789#issuecomment-1007835929)内置支持
- [通过 honebrew 安装](https://github.com/flutter/flutter/issues/14050#issuecomment-1012647917)

虽然以上一些功能的呼声虽然也很高，但是主要是因为一些技术可行性和成本相关等的考虑，一些不可行或者难以解决的问题会暂且被搁置。

> 对于 code push 的官方支持就不要期待了，这都多少年过去了，对于热门问题的修复顺序，具体可见：https://github.com/flutter/flutter/wiki/Popular-issues