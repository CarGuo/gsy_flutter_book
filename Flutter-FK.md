# Flutter 2024 年度回顾总结，致敬这精彩的一年

2024 年的最后一天，就让我们快速**回顾下这一年里 Flutter 给我们带来了哪些变化，当然 2024 肯定少不了鸿蒙的身影**。

这一年里 Flutter 主要发布了 `3.19`、`3.22`、`3.24` 和 `3.27` 四个版本，总结下来，这一年主要的大变动有：

- iOS 控件进一步调整和增加 Widget 更贴近 Cupertino，例如  `CupertinoCheckbox`  和 `CupertinoNavigationBar`：   								![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image1.png)![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image2.gif)

- Gemini Dart SDK，Google AI 官方 SDK 支持，虽然国内大家应该都用不上：![](http://img.cdn.guoshuyu.cn/20241231_FK/image1.png)

- MacOS PlatformView 落地，推进 MacOS 官方 WebView 支持，其他平台也会跟进

- Impeller Android  稳定版发布，Android 全面支持 Impeller 对齐 iOS 渲染引擎，同时未来规划 iOS 和 Android 的 skia 引擎弃用

- WasmGC 落地，2025 将移除 Html Renderer ，Flutter Web 全面转向 WebAssembly，仅保留 canvasKit 和 wasm 两个 Renderer：![](http://img.cdn.guoshuyu.cn/20241231_FK/image2.png)

- DeepLink 校验和官方 API 支持，适配 DevTools 工具，支持 Android 和 iOS 验证支持：![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image17.png)

- Gradle Kotlin DSL 支持，进一步贴近 Kotlin 生态

- Swift Package Manager 支持，适配未来 iOS 弃用 Cocoapods，贴近 Swifit/Xcode 生态：![](http://img.cdn.guoshuyu.cn/20240806_SPM/image13.png)

- Web Multi-view 支持，可以同时将内容渲染到多个 HTML 元素中，核心是不再只是 Full-screen 模式
- 全面支持 P3 色域，Color API 大调整：![](http://img.cdn.guoshuyu.cn/20241231_FK/image3.png)
- Android Edge to Edge 模式适配		![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image14.gif)

- pub.dev 大改版，支持统计下载量等调整：![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image15.png)
- Flutter 工程项目切换到 monorepo 和支持 workspaces 模式 

- 其他各类功能优化和 API 改进，比如文本选择改进，Row/Column 支持 spacing，新增 TreeView\CarouselView  ，性能优化，Mixing Route Transitions 支持等：![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image8.gif)

另外，2024 同步 Flutter 发布的还有 Dart  `3.3` 、`3.4`、`3.5`、`3.6` 四个版本，其中主要大变更包括：

- extension 类型支持，这种拓展类型是一种编译时抽象，**属于是编译时包装构造，在运行时绝对没有扩展类型的踪迹**，它用不同的纯静态接口来 “Wrapper” 现有类型，它们可以轻松修改现有类型的接口（对于任何类型的相互调用都至关重要），而不会产生实际 Wrapper 的成本：![](http://img.cdn.guoshuyu.cn/20241231_FK/image4.png)

- Dart interop 无需 channel 直接调用 (Java/Kotlin/Objective C/Swift/JS）支持，Java 和 Kotlin 通过调用 JNIgen 生成器 ，Objective-C 建立在 FFI 和 FFIgen生成器
- Native interop 和捆绑 native 源码实验，可以支持发布包含本机源代码的 Dart package，以及一个标准化协议，用于启用 `dart` 和 `flutter` CLI 工具来自动构建和捆绑该源代码

- Dart 宏编程预览支持 ：![](http://img.cdn.guoshuyu.cn/20241231_FK/image5.gif)

- Pub workspaces ，支持在一个 monorepo 中开发多个相关包，通过定义一个引用仓库中其他 package 的根 pubspec，在仓库中的任何位置运行 pub get 将导致所有 package 的共享解析。这可确保所有包都使用一组一致的依赖项进行开发:![](http://img.cdn.guoshuyu.cn/20241231_FK/image6.png)

- Digit separators，允许使用下划线 （_） 作为数字分隔符，这有助于使长数字字面量更具可读性，例如多个连续的下划线表示更高级别的分组：![](http://img.cdn.guoshuyu.cn/20241231_FK/image7.png)

除此之外，Flutter & Dart 还有一些处于推进和预览测试的功能了，例如：

- 全新 DevTools 实验更新，支持 “离线” 数据处理和加载，全新 New Inspector 和 WebAssembly 支持：![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image18.png)

- **Flutter GPU 预览发布，简单说就是支持真 3D 渲染**，Flutter GPU 是 Impeller 对于 HAL 的一层很轻的包装，并搭配了关于着色器和管道编排的自动化能力，Flutter GPU 由 Impeller 支持，但重要的是要记住它不是 Impeller ，Impeller 的 HAL 是私有内部代码与 Flutter GPU 的要求非常不同， Impeller 的私有 HAL 和 Flutter GPU 的公共 API 设计之间是存在一定差异化实现：![](http://img.cdn.guoshuyu.cn/20240807_PRE/image1.gif)![](http://img.cdn.guoshuyu.cn/20240807_PRE/image5.png)

- Flutter PC 多窗口草稿发布，已在 Ubuntu/Canonical 展示 ：![](http://img.cdn.guoshuyu.cn/20241101_FPC/image7.gif)

- Flutter 终于正式规划 IDE Widget 预览支持：![](http://img.cdn.guoshuyu.cn/20241125_preview/image5.gif)

- 全新  `Decorators` 语法公布，但暂未落地：![](http://img.cdn.guoshuyu.cn/20241231_FK/image8.png)

- 全新 `Enum shorthands` 和 `Primary Constructors` 语法支持：![](http://img.cdn.guoshuyu.cn/20241218_De/image8.png)![](http://img.cdn.guoshuyu.cn/20241218_De/image9.png)

同时，**今年刚好是 Flutter 项目成立的 10 周年**，Flutter 是从 2014 年作为代号为 “Sky” 的 Google 实验框架开始：

![](http://img.cdn.guoshuyu.cn/20241218_FT/image1.png)

而在这些年发展下，目前在超过 1,400 多名贡献者的努力下，还有 10,000 多名包发布者 50,000 多个社区 package 的协助下，Flutter 才有今天的成长：

![](http://img.cdn.guoshuyu.cn/20241218_FT/image2.png)

根据官方数据，**Flutter 在全球拥有超过 100 万月活跃开发人员，并为近 30% 的新 iOS 应用程序提供支持**，超过 90,000 名开发人员参与的 60 多个国家/地区的 Flutter 本地社区线下会议，而根据 Apptopia 2024 的数据显示：

> “Apptopia 跟踪 Apple AppStore 和 Google Play Store 中的数百万个应用，并分析和检测哪些开发人员 SDK 用于创建这些应用，Flutter 是跟踪的最受欢迎的 SDK 之一：在 Apple AppStore 中 它的使用量从 2021 年所有跟踪免费应用的 10% 左右稳步增长到 2024 年所有跟踪免费应用的近 30%。

![](http://img.cdn.guoshuyu.cn/20241231_FK/image9.png)

当然，还少不了鸿蒙，**目前社区版鸿蒙有 [OpenHarmony-SIG](https://gitee.com/openharmony-sig)/[flutter_engine](https://gitee.com/openharmony-sig/flutter_engine) 和 [鸿蒙突击队](https://gitee.com/harmonycommando_flutter)/[flutter](https://gitee.com/harmonycommando_flutter/flutter) 两个版本**，其中「突击队」版本对 Engine 的跟进版本会更新一些。

另外，在[ HarmonyOS Flutter 开发公众号](https://mp.weixin.qq.com/s/dBXQtk-x1lGBzjUSAB1yGw)发布的内容里也提到，目前鸿蒙 Flutter 适配由华为主导，社区维护，计划每年推出 1-2 个比较大的版本，基本上两个大版本都是通过 fork 官方的主要版本来实现：

![](http://img.cdn.guoshuyu.cn/20241231_FK/image10.png)

> 另外，除了已有的插件开发方式，**鸿蒙 Flutter 计划推出一种成本更低的方案，即通过一种统一接口描述，自动生成各端调用代码，省去开发者的编码工作**。

好了，Flutter 的 2024 到这里就结束了，这一年说长不长，说短不短，也感谢大家 2024 的陪伴，**接下来，我们 2025 再见**。