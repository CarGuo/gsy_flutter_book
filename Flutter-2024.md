> 参考链接：https://github.com/flutter/flutter/wiki/Roadmap

2024 来了，Flutter 3.19 也发布了，目前 Flutter 官方团队也发布了 2024 的规划，而随着 3.19 的发布，目前 Impeller 在 Android 平台已经支持了 Android OpenGL 预览，随着 Impeller 的质量和性能的提升，Impeller 将有较大的计划变动：

- **今年 Flutter Team 将计划删除 iOS 上的 Skia 的支持，从而完成 iOS 到 Impeller 的完全迁移**；
- 在 Android 上 Impeller 今年预计将完成  Vulkan 和 OpenGLES 支持，预计目标同样是完全抛弃使用 Skia 

看来今年 Impeller 有望达到 Flutter 原本 Skia 的可用高度，另外抛弃 Skia 也可以减少生产中的问题回归，就是对于开发者来说，如果还没切换到 Impeller ，这算是一个较大的升级挑战。

另外关于  Material 3  继续支持，也是 2024  的计划之一，从 3.16 开始就是 Material 3 default （M3），从 3.16 开始 `MaterialApp` 里的 `useMaterial3` 默认会是 true，但是你是可以直接使用 `useMaterial3: false` 来关闭，就是未来 **Material 2 相关的东西会被弃用并删除**。

> 更多可见：https://juejin.cn/post/7304537109850472499

在 2023 年的时候，**Flutter 发布了 Multiple Flutter Views 的支持计划**，虽然目前这项支持在 PC 端还没完全落地，但是官方已经计划将这种支持扩展到 Android 和 iOS，同时继续提高 platform views 的性能和实用性，目前 3.19 上很多支持都已经切换到 THLC。

在 iOS 上，3.19 已经开始适配 **Apple 官方要求的[隐私清单](https://juejin.cn/post/7311876701909549065) **，未来将继续支持 [Swift Package Manager](https://github.com/flutter/flutter/issues/33850) 等相关标准需要，在 Android 上将启动 Kotlin 构建脚本的支持（kts） 。

另外 **Dart 与其他平台代码直接交互的支持一直是 Dart 的核心工作之一**，目前 Dart 直接调用 [ Objective C](https://dart.dev/interop/objective-c-interop) 已经接近稳定，未来关于 Dart 直接调用 swift/java/kotlin 的支持也将继续推进其稳定性和可用性，相信随着 [Native assets](https://juejin.cn/post/7334503381200781363#heading-22)相关的支持的成熟，未来 Dart 直接和原生语言交互的能力会越来越成熟。

在 Web 平台上，2024 将继续推进应用的大小优化，更好用的多线程支持，PlatformView 的支持和应用加载时间的缩减，同时 **CanvasKit 将成为默认渲染，这和去年发布的规划一致，详细可以参考去年的[《Flutter Web 路线已定，可用性进一步提升，快来尝鲜 WasmGC》](https://juejin.cn/post/7232164444985622588)** ，另外改进文本输入以及研究支持选项 [Flutter  Web 的 SEO](https://github.com/flutter/flutter/issues/46789) 也在今年的计划里。

> 这包涵了 Dart 编译为 WasmGC 并支持 [Flutter Web 的 Wasm 编译](https://docs.flutter.dev/platform-integration/web/wasm)，还有Dart [新的 JS 互操作机制，支持 JS 和 Wasm 编译](https://github.com/dart-lang/sdk/issues/35084) 相关内容。

另外 Web 还在计划恢复支持[网络热重载](https://github.com/flutter/flutter/issues/53041)。

关于桌面端，因为某些众所周知的原因，虽然过去一年没什么大的进展，但是今年还是有相关的推进计划，例如：

- 推进 [macOS](https://github.com/flutter/flutter/issues/41722) 和 [Windows](https://github.com/flutter/flutter/issues/31713) 上的 PlatformView 支持，从而实现对 webview 等内容的支持

- 在 Linux 上的重点将是 GTK4 支持和可访问性

- 在所有平台上将继续支持来自一个 Dart isolate 的多个视图，最终目标是支持从一个 Widget 树渲染多个窗口。

> 多窗口问题提了好久，去年[《例 Window 弃用，一起来了解 View.of 和 PlatformDispatcher》](https://juejin.cn/post/7233964656287973436)出来的时候，我还以为马上桌面多窗口支持就要来了，没想到这么一等就是 2024 了。

而在 Dart 语言方便， **[2024 首要支持就是Dart 宏（Macros）编程](https://juejin.cn/post/7330528367354282034)**，只有这样 JSON 序列化有救，预计这个能力会在[ 2024 年交付支持它们的第一阶段](https://github.com/dart-lang/language/issues/1482)，当然，如果出现一些无法解决的架构问题，也可能会放弃这项工作宏，宏支持详细可见：https://juejin.cn/post/7330528367354282034

最后，官方又再次声明，**[ Flutter 仍然不打算投资对代码推送或热更新](https://github.com/flutter/flutter/issues/14330)的内置支持，对于代码推送，推荐可以关注 [shorebird.dev](https://shorebird.dev/)，对于 UI 推送（也称为服务器驱动的 UI）相关支持，推荐 [rfw](https://pub.dev/packages/rfw) 包的实现**。

总的来看，Flutter 2024 的核心还是 Impeller 的推进落地，Web 上继续推动 WasmGC 从而实现全新的 Wasm Native 支持，PC 端还是继续填补曾经的大饼，最值得期待的就是 Dart 宏（Macros）编程未来的支持落地了。

那么，2024 的 Flutter 官方计划里，是否符合你的预期呢？