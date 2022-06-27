# Flutter 3.0 发布啦～快来看看有什么新功能-2022 Google I/O

> 本次 Flutter 3.0 主要包括 macOS 和 Linux 的稳定版发布，以及相关的性能改进等。原文链接 https://medium.com/flutter/whats-new-in-flutter-3-8c74a5bc32d0


又到了发布 Flutter 稳定版本的时候，在三个月前我们发布了 Flutter 关于 Windows 的稳定版，而今天，除 Windows 之外，**Flutter 也正式支持 macOS 和 Linux 上的稳定运行**。

![](http://img.cdn.guoshuyu.cn/20220627_Flutter-300/image1)

在这里感谢所有 Flutter contributors 的辛勤工作，本次版本发布合并了 5248 个 PR。

**Flutter 3.0 的发布，主要包括 Flutter 对 macOS 和 Linux 正式版支持、进一步的性能改进、手机端和 Web 端相关的更新等等。此外还有关于减少对旧版本 Windows 的支持，以及一些 breaking changes 列表**。

# 稳定版 Flutter 已经支持所有桌面平台

Linux 和 macOS 已达进入稳定版本阶段，包括以下功能：

## 级联菜单和对 macOS 系统菜单栏的支持

现在可以使用 `PlatformMenuBar` 在 macOS 上创建菜单栏，该 Widget 支持仅插入平台菜单，并控制 macOS 菜单中显示的内容。

![](http://img.cdn.guoshuyu.cn/20220627_Flutter-300/image2)

## 所有桌面平台全面支持国际化文本输入

包括使用[input method editors](https://en.wikipedia.org/wiki/Input_method)(IME)，如中文、日文和韩文，在 Flutter 3.0 上所有桌面平台上都得到支持，包括第三方输入法如搜狗和谷歌日文输入法。

## 所有桌面平台的  Accessibility

Flutter for Windows、macOS 和 Linux 全面支持 Accessibility 服务，例如屏幕阅读、无障碍导航和倒置颜色等。

## macOS 上默认的 Universal binaries

从 Flutter 3 开始，Flutter macOS 桌面应用都将被构建为 universal binaries，从而支持现有的基于 Intel 处理器的 Mac， 和 Apple 的 Apple Silicon 设备。


## 放弃 Windows 7/8 

在 Flutter 3.0 中，推荐将 Windows 的版本提升到 Windows 10，虽然目前 Flutter 团队不会阻止在旧版本（Windows 7、Windows 8、Windows 8.1）上进行开发，但 [Microsoft 不再支持](https://docs.microsoft.com/en-us/lifecycle/faq/windows) 这些版本，虽然 Flutter 团队将继续为旧版本提供“尽力而为”的支持，但还是鼓励开发者升级。

> **注意**：目前还会继续为在 Windows 7 和 Windows 8 上能够正常*运行* Flutter 提供支持；此更改仅影响开发环境。

# 移动端更新

对移动端的更新包括以下内容：

## 折叠手机的支持

Flutter 3 版本开始支持可折叠的移动设备。在 Microsoft 发起的合作中，新功能和 Widget 可让开发者在可折叠设备上拥有更舒适的体验。

**其中包括 `MediaQuery` 现在包含一个 `DisplayFeatures` 列表，用于描述设备的边界和状态**，如铰链、折叠和切口等。此外 `DisplayFeatureSubScreen` 现在可以通过定位其子 Widget 的位置不会与 `DisplayFeatures` 的边界重叠，并且目前已经与 framework 的默认对话框和弹出窗口集成，使得 Flutter 能够立即感知和响应这些**元素**。

![image.png](http://img.cdn.guoshuyu.cn/20220627_Flutter-300/image3)

这里非常感谢 Microsoft 团队，尤其是[@andreidiaconu](https://github.com/andreidiaconu)，感谢他们的 contributions！另外可以试用一下[Surface Duo 模拟器示例](https://docs.microsoft.com/en-us/dual-screen/flutter/samples)，它包括一个带有 Flutter Gallery 特殊分支的示例，可以用于了解 Flutter 在折叠屏中的实际应用。

## iOS 可变刷新率支持

**Flutter 现在支持 iOS 上的 ProMotion 刷新率，包括 iPhone 13 Pro 和 iPad Pro 等**。

在这些设备上，Flutter 可以以达到 120 hz的刷新率进行渲染，再次之前 iOS 上的刷新率限制为 60hz，有关更多详细信息，请参阅[flutter.dev/go/variable-refresh-rate](http://flutter.dev/go/variable-refresh-rate)。

> 更多可见：[《Flutter 120hz 高刷新率在 Android 和 iOS 上的调研总结》](https://juejin.cn/post/7081273509690736653)

## 简化 iOS 的发布

Flutter 团队 [为 flutter build ipa 命令添加了新选项](https://github.com/flutter/flutter/pull/97672)支持以简化发布 iOS 应用。

当开发者准备好分发到 TestFlight 或 App Store 时，可以通过运行 `flutter build ipa` 以构建 Xcode 存档（`.xcarchive`文件）和应用程序包（`.ipa`文件）。 这时候可以选择添加 `—-export-method ad-hoc`、` —-export-method development` 或 `—-export-method enterprise` 来定制发布支持。

[构建应用程序包后，可以通过 Apple Transport macOS 应用](https://apps.apple.com/us/app/transporter/id1450874784)或在命令行上使用 `xcrun altool`（运行 `man altool` 用于 App Store Connect API 的密钥身份验证）将其上传到 Apple 。上传后，应用就可以可发布到[TestFlight 或 App Store](https://docs.flutter.dev/deployment/ios#release-your-app-to-the-app-store)。

**通过这个简化流程，在设置初始的[Xcode 项目设置后](https://docs.flutter.dev/deployment/ios#review-xcode-project-settings)，例如名称和应用图标，开发者可以不再需要打开 Xcode 来发布 iOS 应用**。

## Gradle 版本更新

现在使用 Flutter 工具创建新项目，会发现生现在开始使用最新版本的 Gradle 和 Android Gradle Plugin，对于现有项目，需要手动将版本升级到 Gradle 的 7.4 和 Android Gradle 插件的 7.1.2。

## 停用 32 位 iOS/iOS 9/iOS 10

正如 2022 年 2 月发布的 2.10 稳定版本时所说的那样，Flutter 对 32 位 iOS 设备以及 iOS 9 和 10 版本的支持即将结束。此更改影响 iPhone 4S、iPhone 5、iPhone 5C 以及第 2、3 和 4 代 iPad 设备。Flutter 3 是它们最后一个支持 iOS 版本支持。

> 要了解有关此更改的更多信息，请查看[RFC：End of support for 32-bit iOS devices](http://flutter.dev/go/rfc-32-bit-ios-unsupported)。


#  Web 更新

Web 应用更新包括以下内容：

## 图像解码

Flutter web 现在会在支持它的浏览器中自动检测和使用 ImageDecoder API，而截至今天大多数基于 Chromium 的浏览器（Chrome、Edge、Opera、三星浏览器等）都添加了此 API。

**新的 API 使用浏览器的内置图像编解码器从主线程异步解码图像，这将图像解码速度提高了 2 倍，并且它从不阻塞主线程，从而消除了以前由图像引起的所有卡顿问题**。

## Web 应用的生命周期

Flutter Web 应用程序的新生命周期 API 使开发者可以更灵活地从托管 HTML 页面控制 Flutter 应用的引导过程，并帮助 Lighthouse 分析应用的性能，包括以下经常请求的场景：

-   启动画面。
-   加载指示器。
-   在 Flutter 应用程序之前显示的纯 HTML 交互式登录页面。

> 有关更多信息，请查看docs.flutter.dev 上的[自定义 Web 应用程序初始化](https://docs.flutter.dev/development/platform-integration/web/initialization)。

# 工具更新

Flutter 和 Dart 工具的更新包括：

## 更新的 lint 包

lint 包的 2.0 版已发布：

-   Flutter：[https ://pub.dev/packages/flutter_lints/versions/2.0.0](https://pub.dev/packages/flutter_lints/versions/2.0.0)
-   Dart：[https ://pub.dev/packages/lints/versions/2.0.0](https://pub.dev/packages/lints/versions/2.0.0)

**在 Flutter 3 中生成的应用程序会通过 `flutter create` 自动启用 v2.0 的 lints 集**。Flutter 现在鼓励现有的应用、包和插件都迁移到 v2.0 以遵循该协议，迁移支持可以通过运行 `flutter pub upgrade --major-versions flutter_lints`.

**v2 中大多数新添加的 lint 警告都带有自动修复功能**。因此在 `pubspec.yaml` 文件中升级到最新的包版本后，可以运行 `dart fix —-apply` 自动修复大多数 lint 警告（可能一些警告仍然需要一些手动工作。

> 尚未使用  `package:flutter_lints`  的应用、软件包或插件可以按照[迁移指南](https://docs.flutter.dev/release/breaking-changes/flutter-lints-package#migration-guide)进行迁移。

## 性能改进

感谢 contributor [knopp](https://github.com/knopp)，[局部重绘](https://github.com/flutter/engine/pull/29591)的支持已在 Android 设备上启用。

在本地测试中，此更改将Pixel 4 XL 设备在 `backdrop_filter_perf` 基准测试上， 90th percentile 和 99th 的帧光栅化时间减少了 5 倍，**现在在 iOS 和基础此更新的 Android 设备上都启用了，当存在单个矩形脏区域时的部分重绘支持**。

另外，Flutter 3.0 还进一步改进了[不透明动画相关的性能](https://github.com/flutter/engine/pull/30957)，特别是当一个 `Opacity` Widget 只包含一个渲染 primitive 时， `Opacity` 下关于 `saveLayer` 的调用通常会被省略。在基准测试下中，这种情况下的光栅化时间提高了[一个数量级](https://flutter-flutter-perf.skia.org/e/?begin=1643063115&end=1644004520&keys=X32827d8819e8271e025f50e77bf2bec0&requestType=0&xbaroffset=27447)，在未来的版本中，我们计划将此优化应用于更多场景。

再次感谢 contributor [JsouLiang](https://github.com/JsouLiang) 的提交，现在引擎的光栅和 UI 线程在 Android 和 iOS 上运行的优先级高于其他线程，例如 Dart VM 后台垃圾回收线程，而在我们的基准测试中，这导致平均框架构建时间[加快了约 20%](https://flutter-flutter-perf.skia.org/e/?begin=1644581114&end=1644647407&keys=X3999dc0a0c89054eaa9f66bcff27d882&num_commits=50&request_type=1&xbaroffset=27549)。

在 Flutter 3.0 之前，光栅缓存的准入策略仅查看图片中绘制操作的数量，不幸的是这会导致引擎花费更多的内存，来缓存实际上渲染速度非常快的图片。新版本[引入了一种机制](https://github.com/flutter/engine/pull/31417)，该机制会根据其图片绘制操作的成本来估计图片的渲染复杂性，将其用作光栅缓存准入策略从而[减少内存使用量](https://flutter-flutter-perf.skia.org/e/?begin=1644790212&end=1646044276&keys=X4c7dd4e4903a38523816c00b31d4d787&requestType=0&xbaroffset=27636)，并且不会在我们的基准测试中降低性能。

感谢 contributor [ColdPaleLight](https://github.com/ColdPaleLight)，他修复了[帧调度](https://github.com/flutter/engine/pull/31513) 中的一个错误，该错误导致 iOS 上的少量动画帧被丢弃的问题。

## Impeller

团队一直在努力寻找解决 iOS 和其他平台上卡顿的解决方案。**在 Flutter 3 版本中可以在 iOS 上preview 一个名为[Impeller](https://github.com/flutter/engine/tree/main/impeller) 的实验性渲染工具，Impeller 在引擎构建时会预编译[一组更小、更简单的着色器](https://github.com/flutter/flutter/issues/77412)，这样它们就不会在应用程序运行时编译，这一直是 Flutter 中卡顿的主要来源**。

Impeller 尚未准备好正式发布，目前还远未到完成阶段，所以并非所有 Flutter 功能都能实现，但我们对它在 Flutter [/gallery](https://github.com/flutter/gallery) 应用程序中的保真度和性能感到非常满意，特别是 Gallery 应用里过渡动画中最差的帧快了大约 [20 倍](https://flutter-flutter-perf.skia.org/e/?begin=1650297849&end=1651261748&queries=sub_result%3Dworst_frame_rasterizer_time_millis%26test%3Dnew_gallery_impeller_ios__transition_perf%26test%3Dnew_gallery_ios__transition_perf&requestType=0)。

**Impeller 可以在 iOS 上通过启动 tag 来启动，开发者可以传递 `—-enable-impeller` 到`flutter run` 或将 `Info.plist` 文件中的 `FLTEnableImpeller` 标志设置为 `true` 来尝试 Impeller**。


## Android上的内嵌广告

使用 `google_mobile_ads` 时，开发者应该会在用户关键交互（例如页面之间的滚动和转换）中得到更好的性能。

在底层，Flutter 现在使用新的异步组合来实现 Android 视图，它们通常称为[platform views](https://docs.flutter.dev/development/platform-integration/platform-views)。这意味着 Flutter 光栅线程不再需要等待 Android 视图渲染。相反，Flutter 引擎会使用它管理的 OpenGL 纹理将视图放置在屏幕上。

# 更多更新

Flutter 生态系统的其他更新包括：

## Material 3

Flutter 3 支持[Material Design 3](https://m3.material.io/)，即下一代 Material Design。

Flutter 3 为 Material 3 提供了更多可选支持，包括 Material You 功能如：**动态颜色，新的颜色系统和排版、组件的更新以及 Android 12 中引入的新视觉效果，如新的触摸波纹设计和拉伸过度滚动效果**。

>开发者可以在 codelab 的 [Take your Flutter app from Boring to Beautiful](https://codelabs.developers.google.com/codelabs/flutter-boring-to-beautiful)  中尝试 Material 3 功能，有关如何选择加入这些新功能，以及哪些组件支持 Material 3 的详细信息，请参阅[API 文档](https://api.flutter.dev/flutter/material/ThemeData/useMaterial3.html)。

## 主题扩展

Flutter 现在可以使用名为 *Theme extensions* 的概念向 Material 的 `ThemeData` 添加任何内容，开发者可以通过 `ThemeData`.extensions 去添加自己想要的内容，而不是（在 Dart 意义上）继承 `ThemeData` 并重新实现其`copyWith`、`lerp`和其他方法。

此外，作为 package 开发人员，你可以提供 `ThemeExtensions` 相关内容，有关此内容的更多详细信息，请参阅[flutter.dev/go/theme-extensions并](https://flutter.dev/go/custom-colors-m3) 和  GitHub 上 的[示例](https://github.com/guidezpl/flutter/blob/master/examples/api/lib/material/theme/theme_extension.1.dart)。

## Ads

对于发布商而言，个性化广告征求同意并处理 Apple 的 App Tracking Transparency (ATT) 非常重要。

为了支持这些要求，Google 提供了用户消息传递平台 (UMP) SDK，它取代了之前的开源 [Consent SDK](https://github.com/googleads/googleads-consent-sdk-ios)，在即将发布的 GMA SDK for Flutter 中，我们将添加对 UMP SDK 的支持，以帮助发布者获得用户同意。

> 有关更多详细信息，请查看 pub.dev 上的[google_mobile_ads](https://pub.dev/packages/google_mobile_ads)页面。

# Breaking changes

随着 Flutter 的不断改进 ，我们的目标是尽量减少重大更改的数量，而随着 Flutter 3 的发布，Flutter 有以下重大变化：

-   [在 v2.10 之后删除了已弃用的 API](https://docs.flutter.dev/release/breaking-changes/2-10-deprecations)
-   [由 ZoomPageTransitionsBuilder 替换的页面过渡](https://docs.flutter.dev/release/breaking-changes/page-transition-replaced-by-ZoomPageTransitionBuilder)
-   [迁移 useDeleteButtonTooltip 到 Chips 的 deleteButtonTooltipMessage](https://docs.flutter.dev/release/breaking-changes/chip-usedeletebuttontooltip-migration)
-   [ThemeData 的 toggleableActiveColor 属性已被弃用](https://docs.flutter.dev/release/breaking-changes/toggleable-active-color)

> 如果你正在使用这些 API，请参阅[Flutter.dev 上的迁移指南](https://docs.flutter.dev/release/breaking-changes)。



# Flutter 3 相关介绍，包括Flutter桌面端、Flutter firebase 、Flutter游戏- 谷歌2022 I/O 大会，

> 原本链接 https://medium.com/flutter/introducing-flutter-3-5eb69151622f


Flutter 3 作为 Google I/O 主题演讲的主要部分，Flutter 3 完成了 Flutter 从以移动为中心到多平台框架的路线图，本次提供了 **macOS 和 Linux 桌面应用相关的支持，以及对 Firebase 集成的改进、提高生产力和性能以及对 Apple Silicon 的支持等等**。


![](http://img.cdn.guoshuyu.cn/20220627_Flutter-300/image4)

# Flutter 3 之旅

 Flutter 为了彻底改变应用的开发方式：将 Web 的迭代开发模型与以前游戏保留的硬件加速图形渲染和像素级控制相结合。

自 Flutter 1.0 beta 发布以来的过去四年里，Flutter 团队逐渐在这些基础上进行构建，添加了新的 framework 功能和新的 Widget，与底层平台更深入地集成，还有丰富的packages 支持以及许多性能和工具改进。

![image.png](http://img.cdn.guoshuyu.cn/20220627_Flutter-300/image5)

随着产品的成熟，越来越多的人开始使用 Flutter 构建应用程序。如今有超过 500,000 个使用 Flutter 构建的应用程序。

来自 [data.ai](https://www.data.ai/en/)等研究公司的分析以及公开推荐表明，Flutter 被许多领域的[客户](https://flutter.dev/showcase)使用：

- [微信等社交应用](https://play.google.com/store/apps/details?id=com.tencent.mm&hl=en_US&gl=US)
- [Betterment](https://apps.apple.com/us/app/betterment-investing-saving/id393156562)和[Nubank](https://play.google.com/store/apps/details?id=com.nu.production&hl=en_US&gl=US)等金融和银行应用；

- [SHEIN](https://play.google.com/store/apps/details?id=com.zzkko&hl=en_US&gl=US)和[trip.com](https://apps.apple.com/us/app/trip-com-hotels-flights-trains/id681752345)等商务应用;
- [Fastic](https://fastic.com/)和[Tabcorp](https://auspreneur.com.au/tabcorp-adopts-googles-flutter-platform/)等生活方式应用；
- [My BMW](https://www.press.bmwgroup.com/global/article/detail/T0328610EN/the-my-bmw-app:-new-features-and-tech-insights-for-march-2021?language=en)等配套应用
- [巴西政府](https://apps.apple.com/app/id1506827551)等公共机构；

> **如今，有超过 500,000 个使用 Flutter 构建的应用程序**。

开发人员告诉我们，Flutter 可以更快地为更多平台构建精美的应用。在我们最近的用户研究中：

-   91% 的开发人员同意 Flutter 减少了构建和发布应用所需的时间。
-   85% 的开发者同意 Flutter 让他们的应用比以前更漂亮。
-   85% 的人同意 Flutter 让他们能够为比以前更方便地在更多的平台发布他们的应用。

在 [Sonos 最近的一篇博客文章中](https://tech-blog.sonos.com/posts/renovating-setup-with-flutter/)，他讨论了他们关于体验方便的改进，强调了其中的第二点：

> “毫不夸张地说，解锁 [Flutter] 是有一定程度的‘*溢价*’，这与我们团队之前交付的任何东西都不同。对我们的设计师来说最重要的是，Flutter 可以轻松地构建新的 UI，这意味着我们的团可以花更少的时间对规范说“不”，而将更多的时间用于迭代规范。这听起来值得，所以我们建议大家可以尝试一下 Flutter。”


#  Flutter 3 介绍

**借助 Flutter 3，开发者可以通过一个代码库为六个平台构建应用**，为开发人员提供无与伦比的生产力，并帮助初创公司在一开始就将新想法快速得带入完整的目标市场。

在之前的版本中，我们在 iOS 和 Android 的技术上添加了[Web](https://medium.com/flutter/flutter-web-support-hits-the-stable-milestone-d6b84e83b425) 和 [Windows 支持](https://medium.com/flutter/announcing-flutter-for-windows-6979d0d01fed)，现在**Flutter 3 增加了对 macOS 和 Linux 应用程序的稳定支持**。

添加对应平台的支持不仅仅是渲染像素：**它包括新的输入和交互模型、编译和构建支持、accessibility 和国际化以及特定于平台的集成等等，Flutter 团队的目标是让开发者能够灵活地利用底层操作系统，同时根据开发者的选择尽可能多的共享 UI 和逻辑**。

在 macOS 上，现在支持 Intel 和 Apple Silicon，提供[Universal Binary](https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary)的支持，允许应用打包支持两种架构上的可执行文件。在 Linux 上，Canonical 和 Google 合作提供了一个最佳的开发选项。

[Superlist](https://superlist.com/)是 Flutter 如何实现  Desktop 应用的一个很好的例子，它会今天在测试版中发布。

Superlist 通过将列表、任务和自由格式内容组合成全新的待办事项列表和个人计划的新应用程序，提供协作能力，而 Superlist 团队之所以选择 Flutter，是因为它能够提供快速、高度品牌化的桌面体验，我们认为他们迄今为止的进步证明了为什么 Flutter 是一个不错的选择。


Flutter 3 还改进了许多基础功能，包括了改性能、Material You 支持和开发效率的提高。

除了上面提到的工作，在这个版本中，Flutter 现在支持完全给予原生[Apple 芯片](https://support.apple.com/en-us/HT211814)进行开发，虽然 Flutter 自发布以来一直与基于 M1 的 Apple 设备兼容，但 Flutter 现在可以充分利用了[Dart 对 Apple 芯片的支持](https://medium.com/dartlang/announcing-dart-2-14-b48b9bb2fb67)，从而能够在基于 M1 的设备上更快地编译并支持 macOS 应用程序的 [Universal Binary](https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary) 文件

我们对[Material Design 3](https://m3.material.io/)的工作也在此版本中基本完成，它允许开发人员提供动态配色方案和新的视觉组件，以适应性强的跨平台设计系统：


![](http://img.cdn.guoshuyu.cn/20220627_Flutter-300/image6)


Flutter 由 Dart 提供支持，Dart 是一种用于多平台开发的高生产力、可移植语言，我们在这个周期中对 Dart 的改进工作包括有：
- 减少样板文件；
- 提高可读性的新语言功能；
- 实验性 RISC-V 支持;
- 升级的 linter 和新文档;

>有关 Dart 2.17 中所有新改进的更多详细信息，请查看[博客](https://medium.com/dartlang)。


# Firebase 和 Flutter

当然，构建应用的不仅仅是 UI ， 应用的发布者需要一整套工具来构建、发布和运行应用，包括： 身份验证、数据存储、云功能和设备测试等服务。

目前有多种服务都已经支持 Flutter，包括[Sentry](https://docs.sentry.io/platforms/flutter/)、[AppWrite](https://appwrite.io/docs/getting-started-for-flutter)和 [AWS Amplify](https://docs.amplify.aws/start/q/integration/flutter/)。

Google 提供的应用服务是 Firebase，[SlashData ](https://www.slashdata.co/developer-program-benchmarking/?)的开发者基准测试研究表明，62% 的 Flutter 开发者在他们的应用中使用 Firebase。

因此，在过去的几个版本中，我们一直在与 Firebase 合作，以便能更好地将 Flutter 的集成。这包括将 Flutter 的 Firebase 插件发布到 1.0，添加更好的文档和工具，以及[FlutterFire UI](https://pub.dev/packages/flutterfire_ui)等新 Widget，为开发人员提供可重用的身份验证和配置文件界面 UI 等等。

而在今天，我们宣布将 Flutter/Firebase 集成升级为 Firebase 产品的核心支持。我们正在将源代码和文档转移到 Firebase 存储库和站点中，开发者可以期待我们与 Android 和 iOS 同步发展 Firebase 对 Flutter 的支持。

此外，我们还进行了一些重大改进，以支持使用 Firebase 时支持崩溃报告服务 Crashlytics。通过Flutter [Crashlytics 插件](https://firebase.google.com/docs/crashlytics)，开发者可以实时跟踪致命错误，提供与 iOS 和 Android 开发人员相同的功能集。

这包括重要的警报和指标，如“无崩溃用户”可帮助开发者掌握应用的稳定性。Crashlytics 分析管道已升级和改进对 Flutter 崩溃的支持，从而更快可以地对问题进行分类、优先排序和修复问题。

最后我们简化了插件设置过程，因此只需几个步骤即可从 Dart 代码中启动和运行 Crashlytics。



# Flutter 休闲游戏工具包

对于大多数开发者来说，Flutter 是一个应用框架。但是随着休闲游戏开发社区也在不断壮大，利用 Flutter 提供的硬件加速图形支持以及[Flame](https://flame-engine.org/)等开源游戏引擎的需求一致在提高。

我们想让休闲游戏开发者更容易上手，因此在今天的 I/O 上，我们宣布发布[休闲游戏工具包](https://flutter.dev/games)，它提供的模板和最佳实践的入门工具包以及广告和云服务。

![](http://img.cdn.guoshuyu.cn/20220627_Flutter-300/image7)

尽管 Flutter 并非专为高强度 3D 动作游戏而设计的渲染引擎，但其中一些游戏的非游戏 UI 已经开始转向 Flutter ，包括拥有数亿用户的热门游戏，如[PUBG Mobile ](https://play.google.com/store/apps/details?id=com.tencent.ig)。

对于 I/O，我们想看看我们可以将这项技术推到多远，所以 Flutter 团队创建了一个有趣的弹球游戏，由 Firebase 和 Flutter 的网络支持提供支持。

[I/O Pinball](https://pinball.flutter.dev/ ) 提供了一个围绕 Google 的吉祥物设计的游戏：Flutter 的 Dash、Firebase 的 Sparky、Android 机器人和 Chrome 恐龙，我们认为这是展示 Flutter 的一种有趣方式。


![image.png](http://img.cdn.guoshuyu.cn/20220627_Flutter-300/image8)

# 由 Google 赞助，由社区提供支持

我们喜欢 Flutter 的原因，不仅仅是一款 Google 开发的产品——而是因为它是一款“所有人”的产品。

开源意味着我们都可以参与并受益于它的成功，无论是通过贡献新代码或文档，创建核心框架软件包，编写书籍和培训课程来教授他人。

为了展示社区的最佳状态，我们最近与 DevPost 合作赞助了 Puzzle Hack 挑战赛，让开发人员有机会通过使用 Flutter 重新构想经典的滑动拼图来展示他们的技能，这将展示 web, desktop 和 mobile如何结合。

> 相关的视频链接：https://youtu.be/l6hw4o6_Wcs