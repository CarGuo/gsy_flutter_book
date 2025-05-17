# Flutter Roadmap 2025 发布，快来看看有什么更新吧

又到了 Flutter 公布年度计划的时候，开始之前我们先回顾下官方对 2024  Roadmap 的完成度

- ✅ iOS 完成 Impeller 完成迁移，skia 不再可用
- ✅ Material 3 default
- ❌ Multiple Flutter Views 的支持计划 
- ✅ Swift Package Manager 和 Kotlin Script 支持
- ✅ Dart 和原生的互操作性与 Native assets 推进
- ✅ Web 多线程，PlatformView 优化、JS 互操作、WasmGC 和 Skwasm 落地
- ✅ Web hotload 功能
- ❌ PC 端 PlatformView 支持吗，**目前只落地了 MacOS**
- ❌ 宏编程落地失败，改为推进全新 build_runner 

当然，除了以上 Roadmap ，Flutter 在 2024 也完成了不少特性更新，例如：

- Impeller Android 落地
- Impeller OpenGLES 支持
- Android THLC 纹理层混合合成支持
- 全新系列 Deeplinking  支持
- Flutter GPU 预览
- Web Multi View 支持
- 文本选择一系列改进
- 全新 Flutter Inspector 和 DevTools
- ·····

回顾 Flutter 2024 可谓「忧喜参半」，基本是在各种负面流言里走到了  2025，那么 Flutter 的 2025 Roadmap 又有哪些计划呢？

# 性能

性能部分不用多言，Flutter 在核心平台 Android 和 iOS 上的性能优化一直都是持续目标，目前 iOS 已经实现全 Impeller 迁移条件，从 3.29 开始 **`FLTEnableImpeller` 可选退出标志不再有效**，所以 2025 首要目标之一就是**完全删除 iOS 版本内的 Skia**，完全 Impeller 之后，iOS 的体积也可以相应有所缩减。

而对于 Android，核心重点会放到 Android API  29 或更高版本的设备，这些设备将默认 Impeller 支持，而对于较旧的设备，还需要继续保持 Skia 支持，具体原因还是在于 Impeller 的 OpenGLES 兼容上，具体原因可见之前聊 Vulkan 时谈到的：

> [为什么 Flutter 在 Android 低版本回退 skia](https://juejin.cn/post/7482671750209191936#heading-0)

# Mobile

在移动平台上，2025 iOS 主要目标之一就是支持  iOS 19 和 Xcode 17 ，然后完成 **Swift Package Manager （SwiftPM） 的迁移， 2025  SwiftPM 将成为默认选项** ，这个其实去年聊 [《Flutter 迁移到 Swift Package Manager》 ](https://juejin.cn/post/7399592120128978970) 时 Flutter 就已经实现了支持，而之所以这样，原因我们也在 [《CocoaPods 不再更新，未来将是 Swift Package Manager 的时代》](https://juejin.cn/post/7402832701668507675) 谈过。

另外继续完善 Cupertino 控件支持，也是目标之一，去年各大版本更新时对于  Cupertino  控件的支持力度相信大家也感受过。

而对于 Android ，除了  Android 16 的适配之后，Flutter 还计划将 [ Gradle 构建逻辑从 Groovy 迁移到 Kotlin](https://juejin.cn/post/7470457106844827687#heading-20)，虽然现在也支持 Kotlin DSL，但是未来默认将会是 Kotlin DSL ，这也是跟进当前的 Android 构建趋势。

另外，得益于 3.29 开始的 [《Flutter 上的 Platform 和 UI 线程合并》](https://juejin.cn/post/7474503566154219560)  ，直接从 Dart 调用 Objective C 和 Swift 代码（适用于 iOS）以及 Java 和 Kotlin（适用于 Android）提供了更好的基础，2025 也许这种同步调用方式可以在 Framework 和 Plugin 层面大规模引入。

> 目前线程合并，主要体验出来的问题，就是 Android 在 debug 断点 Dart 时容易跳出 ANR 弹窗。

# Web

去年，Flutter Web 在性能和质量方面取得了不少进展，例如减小了应用大小，更好地利用了多线程，并缩短了应用加载时间等，具体体现在：

- 通过 skwasm 缩减大小和提高加载速度
- PlatformView 经过优化，减少了画布叠加的数量，从而提高了渲染效率
- 在 wasm 通过 header 支持多线程和单线程切换
- 从 UI 线程异步解码图像以避免卡顿
- Image.network 开箱即用支持 CORS 图像
- 支持 Wasm 的 Dart 与 JS 互操作
-  `webHtmlElementStrategy` 标志允许开发者选择何时使用 `<img>` 元素
- ····

> 从 3.29 开始， HTML renderer 就被正式移除了，也就是未来 Flutter Web 只需要聚焦在   Wasm/WebAssembly 即可。

在 2025 年，Fluter 计划进一步改进 Flutter Web 的核心，例如：Accessibility 、文本输入、国际文本渲染、大小、性能和平台集成等，并计划删除遗留的 HTML 和 JS 库。

最后 Web 平台当前预览的 hotload，也有望在 2025 年推出。



# Desktop

**Flutter 的核心团队表示 2025 年将专注于移动和 Web 支持**，而 Desktop 的开发维护其实从 2024 年开始就已经是  Canonical 团队负责，比如去年公布的[《Flutter PC 多窗口新进展》](https://juejin.cn/post/7431894641426202636) 就是 Canonical  负责推进的 Linux、macOS 和 Windows 多窗口的支持。

> 目前已经完成 windows 平台支持，并正在支持 Linux 和 MacOS ，详细可见 ：https://github.com/flutter/flutter/issues/142845

# Dart 

在 [《Dart 宏功能推进暂停》](https://juejin.cn/post/7464998185485877311) 我们知道了 Dart 中宏支持方案被放弃，所以 Flutter 预计在 2025 年将改进 build_runner 中当前对代码生成的支持，并探索改进 Dart 对序列化和反序列化支持的替代方法。

> 详细可见： https://github.com/dart-lang/build/issues/3800

另外官方还计划**研究对交叉编译 Dart AOT 可执行文件的支持**，例如「在 macOS 开发机器上编译为 Linux AOT 可执行文件」的相关支持。

# 热更新

**官方继续表示不会提供热更新或者代码推送服务**，对于代码推送，官方推荐 shorebird.dev ，至于为什么官方推荐 shorebird，可以看之前的 [《Flutter 里最接近官方的热更新方案：Shorebird》](https://juejin.cn/post/7477147173537366068) ，整体来看 shorebird 确实是比较不错的选择。

而如果是  UI 推送（也称为服务器驱动的 UI），官方推荐 rfw ，它提供了一种机制，用于根据可在运行时获取的声明性 UI 描述来呈现控件，从而实现远程驱动的效果。

# 最后

目前看来，「交叉编译 Dart AOT 」是我 2025 里最感兴趣的特性，当然，在 Windows 上直接构建出一个 iOS 的 Ipa 这种支持我估计不会有，毕竟这个的可行性和复杂度太高了。

而最期待的莫过于 Canonical  团队的支持，希望目前多窗口的 draft 可以最终落地成功，毕竟这段时间的 Desktop 开发体验，缺少多窗口确实是很大的局限。

那么，你最希望什么特性能在 2025 年被完成？































