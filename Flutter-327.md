# Flutter 3.27 发布啦，快来看有什么更新吧

Flutter 3.27 悄悄的就来了，该版本包含了大量更新，包括：

- Cupertino 相关组件的大量优化
- Material 下的一些主题和控件调整，包括之前我们聊过的  Row and Column spacing 
- Android Impeller 默认开启和 iOS 性能优化
- P3 色域的 UI 支持
- Web 下的大量改进
- Swift Package Manager 的支持
- 之前聊过的 Edge to Edge 和 Android Freeform  支持
- pub 下载数
- DevTool 工具大改进和优化，包括设备断线数据保持
- 对老 Dart SDK 插件不在维护适配，弃用 OC

# Framework

## Cupertino 

不得不说，自从负责 Flutter  iOS 的 PM 回归后，Cupertino 的优化就一直在提速，本次 3.27 针对 iOS 风格的  Cupertino  组件也做了进一步高保真更新，如：

-  对 `CupertinoCheckbox` 和 `CupertinoRadio` 的大小、颜色、描边宽度和按下时的效果进行了调整
- 对 `CupertinoRadio`、`CupertinoCheckbox` 和 `CupertinoSwitch` 添加了鼠标光标、语义标签、Thumb 图像和填充颜色等属性
- 调整了某些属性，如  `CupertinoCheckbox`  的 inactive 弃用、 `CupertinoSwitch` 的 track 重命名
- `CupertinoSlidingSegmentedControl ` 的 Thumb Radius、Separator Height、填充、阴影和 Thumb Scale 对齐方式的一些保真度更新，支持禁用单个区段，以及基于区段内容的比例布局：

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image1.png)

另外，`CupertinoNavigationBar` 和 `CupertinoSliverNavigationBar` 的背景适配了透明状态，所以可以支持 sliver 导航栏在展开状态下和背景有相同的颜色，但在折叠状态下具有不同的可自定义颜色（并且能够在滚动时在两种颜色之间进行插值）。

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image2.gif)

同时， 3.27 还支持新的 `CupertinoButtonSize` 枚举， 而 `CupertinoButton` 中新的 `sizeStyle` 属性可以用来适配应用 iOS 15+ 的按钮样式，使用新的 `CupertinoButton.tinted` 构造函数可以创建半透明背景的按钮，最后 `CupertinoButton` 还有一个新的 `onLongPress` ，支持通过键盘快捷键执行操作。

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image3.png)

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image4.png)

针对 `CupertinoPicker` 和 `CupertinoDatePicker` ，现在支持滚动到用户所点击的 Item：

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image5.gif)

`CupertinoAlertDialog` 现在支持点击滑动手势：

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image6.gif)

其他还有：

- `CupertinoActionSheet` 调整了所有系统文本大小设置中的填充和字体大小，以及在按钮上滑动时支持触觉反馈
- `CupertinoContextMenu` 支持在其操作溢出屏幕时滚动
- `CupertinoDatePicker` 不再剪切其列中的长内容
- `CupertinoMagnifier` 通过提供放大比例来支持缩放效果

## Material

在 3.27 版本中，`CardTheme`、`DialogTheme` 和 `TabBarTheme` 被重构，通过添加了 `CardThemeData`、`DialogThemeData` 和 `TabBarThemeData`  替代，以便和现有 Material Library 规范一致。

其他 Material 调整还有：

- 针对 `SegmentedButton` 增加 `direction` 属性，让项目支持垂直对齐

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image7.gif)



- 在 `ButtonStyleButton` 相关类（`ElevatedButton`、`FilledButton`、`OutlinedButton`、`TextButton`、`MenuItemButton` 和 `SubmenuButton`）的 styleFrom 方法中添加了更多与图标相关的属性，从而支持更多自定义
- `ButtonStyleButton` 类的图标大小和颜色默认值调整到和 Material 3 规范一致
- 当 drawer 打开时，AppBar 的下滚动行为会正确保留，与原生 Android 体验相匹配。
- `MenuAnchor` 通过焦点修复得到了进一步改进，并且解决了多个 `DropdownMenu` 问题，包括嵌套可滚动对象中的滚动问题和筛选器机制行为

## CarouselView

3.27 对 CarouselView 引入了 `CarouselView.weighted`，可在轮播中实现更动态的布局，通过在构造函数中调整 `flexWeights` 参数，可以实现多种项布局：

> 例如，[3， 2， 1] 创建  [multi-browse](https://m3.material.io/components/carousel/specs#3c9dc903-2f88-4b27-84e3-213c50674632) 布局，[7， 1] 生成 [hero](https://m3.material.io/components/carousel/specs#66eb8746-70f0-4bad-b940-8e1028268d65) 布局，[1， 7， 1] 生成[居中 hero](https://m3.material.io/components/carousel/specs#92c779ce-de8b-4dee-8201-95d3e429204f) 布局，这些值表示每个项目在轮播视图中占据的相对权重，可以自定义以满足用户的特定需求。

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image8.gif)

## Mixing Route Transitions

现在，当旧路由和新路由具有不同的页面 transitions 时，ModalRoutes 会更加灵活。

当有新的 route 进入界面时，有时他们需要之前已有的 route 进行一定的过渡，与新 route 的入口过渡同步，所以现在 `ModalRoutes` 可以相互提供退出过渡构建器，因此进入和退出过渡始终同步，从而支持页面使用 Flutter 的 Navigator 和 Router 在一个页面上拥有多个路由过渡选项。

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image9.gif)

## 文本选择改进

这算是老话题了，好几个版本里都有相关改进，而在 3.27 开始，Flutter 的 `SelectionArea` 现在支持 Shift + Click 手势，在 Linux、macOS 和 Windows 上将选区范围移动到单击位置

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image10.gif)

另外，还可以通过 `SelectableRegionState` 上的 `clearSelection` 方法清除 `SelectionArea` 和 `SelectableRegion` 下的选择。

`SelectableRegionState` 现在也可以通过 `SelectionArea` 访问，为其提供 `GlobalKey` 并访问其 `SelectionAreaState.selectableRegion` 。

最后，3.27 还解决了 RenderParagraph 的一些问题，在[调整窗口](https://github.com/flutter/flutter/pull/155719)大小后，以及在实际[文本外部](https://github.com/flutter/flutter/pull/155892)单击或点击时， `SelectionArea` 或 `SelectableRegion` 下选择文本仍可按预期工作

## Row and Column spacing 

这也是一个老话题了，这个 PR 其实提了很多年，在之前的 [《Row/Column 即将支持 Flex.spacing》](https://juejin.cn/post/7410222585210175539) 我们介绍过，3.27 开始可以在正式版里使用 Rows 和 Columns  的 spacing 提供了行列间距：

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image11.png)

# Engine

## Android Impeller

**从 3.27 开始，Impeller 将成为 Android 设备上的默认渲染引擎**，而在较旧的 Android 设备和不支持 Vulkan 的设备上，Skia 渲染引擎仍将像以前一样使用。

如果需要关闭 Impeller，用户可以通过将 `--no-enable-impeller` 传递给命令行工具，或者将以下内容添加懂啊 `AndroidManifest.xml` ：

```xml
<meta-data
android:name=”io.flutter.embedding.android.EnableImpeller”
android:value=”false” />

```

后续，在改进 Impeller 在 Android 上的性能和保真度的同时，Flutter 还打算让 Impeller 的 OpenGL 后端生产准备好删除 Skia 回退支持，不过对比 iOS，Android 硬件生态系统比 iOS 生态系统更加多样化，所以  Impeller 还需要更多的社区反馈来优化改进。

## iOS 优化

在以前的 Flutter 版本中，用户可能会遇到 iOS 设备上应用在 compositor backpressure 上每帧等待几毫秒的问题，这个背压将被视为栅格工作负载开始时的延迟，而这种延迟可能会会导致漏帧和卡顿，特别在帧时间预算较小的高帧速率设备上尤其明显。

而在 3.27 版本开始，添加了 Metal rendering surface 的[新实现](https://github.com/flutter/engine/pull/48226)，该实现支持在 UI 工作负载完成后更一致地开始光栅工作负载。

这意味着用户会观察到整体帧时间更加稳定，因为 iOS 系统合成器上的等待时间更少，**特别是 Flutter 现在在高帧率设备上将更一致地达到 120Hz**。

在基准测试中，这种改进许多情况下平均帧光栅化时间大幅缩短：

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image12.png)

## 色域

关于颜色，还包括了大色域调整，也就是之前聊过的 [《Flutter Color 大调整，需适配迁移，颜色不再是 0-255，而是 0-1.0，支持更大色域》](https://juejin.cn/post/7430493860192976906) 相关内容，主要就是迁移如 `withOpacity` 、`fromARGB`  等 API。

现在 3.27 支持  DisplayP3 色彩空间中的颜色定义 UI，之前只支持 P3 图片效果。

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image13.png)



# Web

3.27 对 Flutter Web 进行了多项改进，主要集中在性能、效率和可访问性方面：

- Safari 和 Firefox 中的图像解码现在使用 `<img>` 元素而不是 WebAssembly 编解码器完成所有静态图像，这消除了与图像解码相关的卡顿，并减少了 WASM 内存使用量
- PlatformView 经过优化，减少了画布叠加的数量，从而提高了渲染效率
- 官方所有插件和包现在都与 WebAssembly 兼容
- 对标题、对话框、密码、iOS 键盘、链接和可滚动对象实施了多个辅助功能修复。
- 修复了 CanvasKit 和 Skwasm 渲染器中的许多渲染错误，包括图像过滤器、剪切和 `Paint` 对象的内存使用
- 改进了多视图模式下的拖动滚动。

可以看到，在不维护 HTML renderer 之后，Flutter  Web 的调整和改进顺畅了不少，**同时 remove html 相关也已经合并到 main，将在 2025 年的第一个 Flutter 稳定版本中发布**。

> 关于 Flutter Web 正式移除 HTML renderer，更多可见： https://juejin.cn/post/7446613741627736091

# iOS

[Flutter 正在迁移到 Swift Package Manager](https://juejin.cn/post/7399592120128978970) ，这个在之前的我们聊过，其中包括 [CocoaPods 官宣进入维护模式，不在积极开发新功能，未来将是 Swift Package Manager 的时代](https://juejin.cn/post/7402832701668507675) ，而使用 Swift Package Manager 带来了几个好处：

- Swift 包生态系统：Flutter 插件将能够利用不断增长的 Swift 包生态系统
- Flutter 环境更简洁，Swift Package Manager 与 Xcode 捆绑在一起，无需安装 Ruby 和 CocoaPods 

在此之前，Swift Package Manager 支持仅在 Flutter 的 “main” 分支上可用，**而从 3.27 开始，Swift Package Manager 功能现在也可以在 “beta” 和 “stable” 频道上使用，只是目前 Swift Package Manager 功能默认处于关闭状态**。

未来 Pub.dev 现在会检查插件的 Swift Package Manager 兼容性，不兼容的软件包将不会收到完整的软件包分数。

> 详细可见：https://juejin.cn/post/7399592120128978970

# Android

默认情况下，在运行 Android 15+ 的设备上，Flutter App 将使用 Edge to Edge 模式并全屏运行：

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image14.gif)

这个我们之前也聊过，Android Freeform 允许用户调整应用窗口的大小，并已作为开发人员选项提供，Flutter 的 `SafeArea` 和 `MediaQuery` 已更新适配支持，以便在自由窗口移动到硬件切口时处理硬件切口。

> 详细可见： https://juejin.cn/post/7441865024613646345

另外，开发人员现在可以使用 `build.gradle.kts` 文件，Flutter 工具现在支持 Kotlin 构建文件，同时 Groovy 仍然是一种受支持的 Gradle 语言。

> Flutter 3.27 是支持 Gradle [旧版 apply 脚本方法](https://docs.gradle.org/8.5/userguide/plugins.html#sec:script_plugins)的最后一个版本，迁移可见：https://docs.flutter.dev/release/breaking-changes/flutter-gradle-plugin-apply 

# Ecosystem

## pub.dev 上的包下载计数

现在，当查看 pub 上包页面时，将看到 30 天的下载计数，取代了之前的“人气分数”。

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image15.png)

此外，还添加了一个交互式迷你图，显示一段时间内的每周下载活动，此图表可帮助开发人员和程序包作者发现package 使用情况的趋势，例如它可能表明新版本已导致使用量激增，或者某个软件包的受欢迎程度正在增加或下降。

## Pub workspaces 

关于monorepo 和 workspaces ，在之前的[《Flutter 正在切换成 Monorepo 和支持 workspaces》](https://juejin.cn/post/7433673239426007078)我们也聊过， 而在 Dart 3.6 开始正式推出了 [Pub workspaces](https://dart.dev/go/pub-workspaces)，以支持在一个 monorepo 中开发多个相关包，通过定义一个引用仓库中其他 package 的根 pubspec，在仓库中的任何位置运行 pub get 将导致所有 package 的共享解析。这可确保所有包都使用一组一致的依赖项进行开发:

```yaml
name: workspace
environment:
  sdk: ^3.5.0
workspace:
  - packages/package_a
  - packages/package_b

```

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image16.png)

workspaces 下 analyzer 会选择共享 resolution analyzer 现在只需要跟踪整个工作区的单个 analysis 上下文，从而在 IDE 中打开整个存储库时显著减少内存使用量。

> 详细可见：https://juejin.cn/post/7433673239426007078

## 从 GitHub 自动发布 Flutter 包

Flutter 扩展了 setup-dart [publish](https://github.com/dart-lang/setup-dart/blob/main/.github/workflows/publish.yml) Github Actions 工作流，从而支持将 Flutter 包[自动发布到](https://dart.dev/tools/pub/automated-publishing#configuring-automated-publishing-from-github-actions-on-pub-dev) pub.dev

## 应用内购 iOS 和 macOS 插件更新

Flutter 将 [StoreKit 2](https://developer.apple.com/storekit/) 支持添加到 `in_app_purchase_storekit` 包中，以迁移 iOS 18 中已弃用的 StoreKit 1 API，该支持能够在未来添加新的 StoreKit 2 功能，例如更好的订阅管理。

# DevTools

## DevTools updates

3.27 版本包括 DevTools 新功能和优化改进，以及一些令人兴奋的新实验性功能。

首先，DevTools 在 Flutter Deep Links 工具中添加了对验证 iOS 深度链接设置的支持，现在可以验证 Android 和 iOS 的深度链接。

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image17.png)

另外，对处理 “离线” 数据的工作流程进行了一些改进，有时需要导出开发者在 DevTools 中查看的数据以备将来使用或加载到其他工具中。

3.27 新增支持将网络数据导出为 `.har` 文件，以及将内存快照加载到 DevTools 中，以便在 DevTools 未连接到正在运行的应用程序时查看。

此外，如果曾经你在调试 DevTools 的内存问题时，遇到过由于应用崩溃而丢失了内存工具数据，本次同样修复了这一 UX 痛点，3.27 将支持在 Crash 后继续在 DevTools 中查看最新的内存工具数据，即使在应用断开连接后也是如此。

## Flutter Inspector

Flutter Inspector 进行了一些重大更改，以提高可用性并增强的 UI 调试过程，开发者可以通过切换 “New Inspector” 设置来启用新的 Inspector：

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image18.png)

调整包括：

- 一个压缩的 Widget 树，可以更轻松地查看深度嵌套的 Flutter widget 树，这在 IDE 中使用 Flutter Inspector 时特别有用
- 用于切换是否应将 implementation Widget 包含在 Widget 树中的选项，implementation widget 是你没有包含在应用代码中的 widget，而是由 Flutter 框架或其他包添加到 widget 树中的 widget。
- 所选 Widget 的详细信息视图，其中显示内联布局查看器、Widget 和渲染对象属性，以及 Flex Widget 及其子项的 Flex 布局浏览器。

## 试用 WebAssembly

3.27 可以在 DevTools 设置中启用 WebAssembly 功能以加载 WASM 编译的 DevTools Web 应用。

这应该会产生比默认 JS 编译版本的 DevTools 更好的性能，目前该功能是实验性的阶段：

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image19.png)

# Breaking Changes

## MD3

Flutter 还是很热衷于 MD3，应该说谷歌都很热衷，最新的 MD 3 令牌（v6.1）已应用于 Flutter Material 库。

Material Design 令牌更新了 Light 模式下 4 种颜色角色的映射，只是为了在视觉上更具吸引力，同时保留可访问的对比度：

- On-primary-container （Primary10 to Primary30）
- On-secondary-container (Secondary10 to Secondary30)）
- On-tertiary-container (Tertiary10 to Tertiary30)
- On-error-container (Error10 to Error30)

![](http://img.cdn.guoshuyu.cn/20241212_Flutter327/image20.png)

另外，`Chip` 系列的边框颜色（`Chip`、`ActionChip`、`ChoiceChip`、`FilterChip` 和 `InputChip`）已从 `ColorScheme.outline` 更新为 `ColorScheme.outlineVariant`。

## Objective-C iOS

自 2019 年发布 Flutter 1.9.1 以来，新的 iOS 项目默认使用 Swift，现在创建新的[ Objective-C iOS 项目现已弃用](https://github.com/flutter/flutter/issues/148586)，该 `flutter create --ios-language objc` 标志将在 Flutter 的未来版本中删除。

开发者仍然可以打开 Xcode 项目并添加 Objective-C 文件，包括插件文件，而带有该 `flutter create --android-language java` 标志的 Android 应用继续支持 Java。

## Deep link 默认标志

Flutter 的 deep linking  标志的默认值已从 **false** 更改为 **true**，这意味着 deep linking  现在默认为选择加入，如果你使用了第三方插件进行深度链接，如：

- [firebase dynamic links Firebase](https://firebase.google.com/docs/dynamic-links)
- [uni_link](https://pub.dev/packages/uni_links)
- [app_links](https://pub.dev/packages/app_links)

在这种情况下，你需要手动将 Flutter 深度链接标志重置为 **false**。

```
<meta-data android:name="flutter_deeplinking_enabled" android:value="false" />
```

> 更多可见：https://docs.google.com/document/d/1TUhaEhNdi2BUgKWQFEbOzJgmUAlLJwIAhnFfZraKgQs/edit?usp=sharing

## 弃用 IDE 中对旧版 SDK 的支持

3.27 开始将对 IDE 插件支持进行更改，从 Dart 3.6 版本开始，Flutter 将弃用对 3.0 之前版本（2023 年 5 月发布）的 Dart SDK 的支持。

> 这意味着，虽然这些工具仍可与较旧的 SDK 一起使用，但 Flutter 官方将不再为这些版本的特定问题提供官方支持或修复。

随着 Dart 3.7 的发布（预计在 2025 年第一季度发布），Flutter 将完全取消对这些旧 SDK 版本的支持，插件的未来版本可能与这些版本不兼容。

> 参考链接：https://medium.com/flutter/whats-new-in-flutter-3-27-28341129570c



# 最后

可以看到 Flutter 3.27 包含了大量更新，虽然依然还没看到 PC 端的一些新发布，但是其实之前我们聊过，例如在之前的 [《Flutter PC 多窗口新进展》](https://juejin.cn/post/7431894641426202636)我们就聊过了多窗口目前的落地和演示情况，同时如[《Flutter 终于正式规划 IDE Widget 预览支持》](https://juejin.cn/post/7441006286765064218)，也大概看到可 Flutter 在 IDE 预览支持的进展。

可以看到，许多新老的 feature 落地时间应该会在 2025 第一季度或者第二季度，所以，3.27 你打算吃螃蟹了？还是等 3.27.6 ？