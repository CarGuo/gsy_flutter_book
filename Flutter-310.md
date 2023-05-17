# Google I/O 2023 - Flutter 3.10 发布，快来看看有什么更新吧



> 核心部分原文链接：https://medium.com/flutter/whats-new-in-flutter-3-10-b21db2c38c73



虽然本次 I/O 的核心 keynote 主要是 AI ，但是按照惯例依然发布了新的 Flutter 稳定版，不过并非大家猜测的 4.0，而是 3.10 ，Flutter 的版本号依然那么的出人意料。

**Flutter 3.10 主要包括有对 Web、mobile、graphics、安全性等方面的相关改进**，核心其实就是：

- iOS 默认使用了 Impeller
- 一堆新的 Material 3 控件袭来
- iOS 新能优化，Android 顺带可有可无的更新
- Web 可以无 iframe 嵌套到其他应用

# Framework



## Material 3

看起来谷歌对于 Material 3 的设计规范很上心，根据最新的  [Material Design spec](https://m3.material.io/components) 规范 Flutter 也跟进了相关的修改，其中包括有**新组件和组件主题和新的视觉效果等**。

目前依然是由开发者可以在 `MaterialApp` 主题配置下，通过 `useMaterial3`  标志位选择是否使用 Material 3，**不过从下一个稳定版本开始，`useMaterial3` 默认会被调整为 `true`** 。

![](http://img.cdn.guoshuyu.cn/20230511_F3/image1.png)

> 对于 Material 3 ，可以通过  https://flutter.github.io/samples/material_3.html 上的相关 Demo 预览。

## ColorScheme.fromImageProvider

所有 M3 组件配置主题的默认颜色 `ColorScheme`，**默认配色方案使用紫色 shades，这有区别于之前默认的蓝色**。

除了可以从单一 “seed” 颜色来定制配置方案之后，通过 `fromImageProvider` 图像也可以创建自定义配色方案。

![](http://img.cdn.guoshuyu.cn/20230511_F3/image2.gif)

## NavigationBar

本次还增加了一个 M3 版本的 `BottomNavigationBar` 控件效果，虽然 [M3](https://m3.material.io/components/navigation-bar/overview) 使用不同的颜色、highlighting 和 elevation，但它的工作方式其实还是和以前一样。

如果需要调整 `NavigationBars` 的默认外观，可以使用使用 `NavigationBarTheme` 来覆盖修改，虽然目前你不需要将现有 App 迁移到  `NavigationBars` ，但是官方建议还是尽可能在新项目里使用  `NavigationBars`  作为导航控件。

![](http://img.cdn.guoshuyu.cn/20230511_F3/image3.gif)



## NavigationDrawer

M3 针对 Drawer 同样提供了新的 `NavigationDrawer `，它通过 `NavigationDestinations` 显示单选列表，也可以在该列表中包含其他控件。

> 同步M3下 `Drawer` 也更新了颜色和高度，同时对布局进行了一些小的更改。

`NavigationDrawer` 需要时可以滚动，如果要覆盖 `NavigationDrawer` 的默认外观，同样可以使用 `NavigationDrawerTheme` 来覆盖。

![](http://img.cdn.guoshuyu.cn/20230511_F3/image4.gif)



## SearchBar 和 SearchAnchor

这是 Flutter 为搜索查询和提供预测效果新增的控件。

当用户在输入搜索查询时，会在 “search view” 中计算匹得到一个配响应列表，用户选择一个结果或调整匹配结果。

如果要覆盖 `SearchBarTheme` 的默认外观，同样可以使用 `SearchAnchorTheme` 来覆盖。 

| ![](http://img.cdn.guoshuyu.cn/20230511_F3/image5.gif) | ![](http://img.cdn.guoshuyu.cn/20230511_F3/image6.gif) |
| ------------------------------------------------------ | ------------------------------------------------------ |




## Secondary Tab Bar

M3 下 Flutter 现在默认提供创建第二层选项卡式内容的支持，针对二级 Tab 可以使用 `TabBar.secondary`。



![](http://img.cdn.guoshuyu.cn/20230511_F3/image7.gif)

## DatePicker 和 TimePicker  更新

M3下 `DatePicker `更新了控件的日历、文本字段的颜色、布局和形状等，对应 API 没有变动，但会个新增了 `DatePickerTheme` 用于调整控件样式。

`TimePicker` 和`DatePicker` 一样，更新了控件的常规版本和紧凑版本的颜色、布局和形状。

| ![](http://img.cdn.guoshuyu.cn/20230511_F3/image8.gif) | ![](http://img.cdn.guoshuyu.cn/20230511_F3/image9.gif) |
| ------------------------------------------------------ | ------------------------------------------------------ |



## BottomSheet 更新

 M3 下 `BottomSheet` 除了颜色和形状更新之外，还添加了一个可选的拖动手柄，当设置 `showDragHandle`为 `true` 时生效。

![](http://img.cdn.guoshuyu.cn/20230511_F3/image10.gif)



##  ListTile 更新

M3下 `ListTile` 更新了定位和间距，包括 content padding、leading 和 trailing 控件的对齐、minimum leading width, 和  vertical spacing 等，但是 API 保持不变。

![](http://img.cdn.guoshuyu.cn/20230511_F3/image11.gif)



# TextField 更新

M3 更新了所有 `TextField` 对原生手势支持。

用鼠标双击或三次点击  `TextField`  和在触摸设备上双击或三次点击效果相同，默认情况下 `TextField` 和`CupertinoTextField ` 都可以使用该功能。

### `TextField`  double click/tap 手势

- Double click + drag：扩展字块中的选择。
- Double tap + drag：扩展字块中的选择。



![](http://img.cdn.guoshuyu.cn/20230511_F3/image12.gif)

### `TextField`  triple click/tap 手势 

Triple click

- 在多行 `TextField`(Android/Fuchsia/iOS/macOS/Windows) 中选择点击位置的段落块。
- 在多行 `TextField` (Linux) 内部时，在 click 位置选择一个行块。
- 选择单行中的所有文本 `TextField`。

Triple tap

- 在 multi-line `TextField` 中选择点击位置的段落块 。
- 选择单行 `TextField` 中的所有文本 

Triple click+拖动

- 扩展段落块中的选择 (Android/Fuchsia/iOS/macOS/Windows)。
- 扩展行块中的选择 (Linux)。

![](http://img.cdn.guoshuyu.cn/20230511_F3/image13.gif)



> 简单来说，就是手势和鼠标在双击和三击下，会触发不同的选择效果，并且 Linux 在三击效果下会有点差异



## Flutter 支持 SLSA 级别 1

Flutter Framework 现在使用软件工件供应链级别 ( [SLSA](https://slsa.dev/) ) 级别 1 进行编译，这里面支持了许多安全功能的实现，包括：

- **脚本化构建过程**：Flutter 的构建脚本现在允许在受信任的构建平台上自动构建，建立在受保护的架构上有助于防止工件篡改，从而提高供应链安全性。
- **带有审计日志的多方批准**：Flutter 发布工作流程仅在多个工程师批准后执行，所有执行都会创建可审计的日志记录，这些更改确保没有人可以在源代码和工件生成之间引入更改。
- **出处**：Beta 和稳定版本现在使用 [provenance](https://slsa.dev/provenance/v0.1) 构建，这意味着具有预期内容的可信来源构建了框架发布工件，每个版本都会发布链接以查看和验证 [SDK 存档](https://docs.flutter.dev/release/archive) 的出处。

![](http://img.cdn.guoshuyu.cn/20230511_F3/image14.png)

这项工作还在朝着 SLSA L2 和 L3 合规性迈进，这两个级别侧重于在构建过程中和构建之后提供 artifacts 保护。



# Web



## 改进了加载时间

3.10 减小了图标字体的文件大小，它会从 Material 和 Cupertino 中删除了未使用的字形，从而提供了更快加载。

## CanvasKit 变小

基于 Chromium 的浏览器可以使用更小的自定义 CanvasKit 渠道，托管在  Google  [gstatic.com ](http://gstatic.com/) 上的 CanvasKit 可以进一步提高性能。

## Element 嵌入

现在可以 [从页面中的特定 Element 来加载 Flutter  Web](https://docs.flutter.dev/deployment/web#embedding-a-flutter-app-into-an-html-page) ，不需要 `iframe`，在这个版本之前 fluter web 是需要填充整个页面主体或显示在 `iframe` 标记内，简单说就是把 flutter web 嵌套到其他 Web 下更方便了。

> 具体 Demo 可见：https://github.com/flutter/samples/tree/main/web_embedding

## **着色器支持**

Web 应用可以使用 Flutter 的  [fragment shader](https://docs.flutter.dev/development/ui/advanced/shaders) ：

```yaml
flutter:
  shaders:
    - shaders/myshader.frag
```



# Engine

## Impeller

在 3.7 稳定版中 iOS 提供了 [Impeller ](https://docs.flutter.dev/perf/impeller)  预览支持，从那时起 Impeller 就收到并解决了用户的大量反馈。

在 3.10 版本中，我们对 Impeller 进行了 250 多次提交，**现在我们将 Impeller 设置为 iOS 上的默认渲染器**。

默认情况下，所有使用 Flutter 3.10 为 iOS 构建的应用都使用 Impeller，这样  iOS 应用预计将会有更少的卡顿和更一致的性能。

自 3.7 版本以来，iOS 上的 Impeller 改进了内存占用，可以使用较少的渲染通道和中间渲染目标。

在较新的 iPhone 上，**启用有损纹理压缩可在不影响保真度的情况下减少内存占用，这些进步也显着提高了 iPad 的性能**。

![](http://img.cdn.guoshuyu.cn/20230511_F3/image15.png)

比如 [Wonderous](https://flutter.gskinner.com/wonderous/) 应用中的 “pull quote” 页面，**这些改进是的当前页面下的内存占用量减少了近一半**。

内存使用量的减少也适度降低了 GPU 和 CPU 负载，Wondrous 应用可能不会记录这些负载下降，它的框架之前已经优化的不错，但这一变化应该会延长续航能力。

Impeller 还释放了团队可以更快地交付流行功能请求的能力，例如在 iOS 上支持更广泛的 P3 色域。

> 社区贡献加速了我们的进步，特别是 GitHub 用 户[ColdPaleLight](https://github.com/ColdPaleLight) 和 [luckysmg](https://github.com/luckysmg ) ，他们编写了多个与 Impeller 相关的补丁，提高了保真度和性能。

虽然 Impeller 满足大多数 Flutter 应用的渲染需求，但你可以选择关闭 Impeller。如果选择退出，请考虑在[ GitHub 上提交问题](https://github.com/flutter/flutter/issues/new/choose)以告诉我们原因。

> ```
> <key>FLTEnableImpeller</key>
> <false/>
> ```

用户可能会注意到 Skia 和 Impeller 在渲染时存在细微差别，这些差异可能是错误，所以请勿在 Github 上提出问题，**在未来的版本中，我们将删除适用于 iOS 的旧版 Skia 渲染器以减小 Flutter 的大小**。

另外，Impeller 的 Vulkan 后端然在支持当中，Android 上的 Impeller 仍在积极开发中，但尚未准备好进行预览。

> 要了解 Impeller 进展，请查看 https://github.com/orgs/flutter/projects/21。

# Performance

3.10 版本涵盖了除 Impeller 之外还有更多性能改进和修复。

## 消除卡顿

这里要感谢 [luckysmg](https://github.com/luckysmg)， 他们发现可以缩短从 Metal 驱动获取下一个可绘制层的时间，而方式就是需要将 `FlutterViews` 背景颜色设置为非零值。

此更改消除了最近 iOS 120Hz 显示器上的低帧率问题，**在某些情况下它会使帧速率增加三倍**，这帮助我们解决了六个 GitHub issue。

**这一变化具有意义重大，以至于我们向后移植了一个修补程序到 3.7 版本中**。

在 3.7 稳定版中，我们将本地图像的加载从平台线程转移到 Dart 线程，以避免延迟来自平台线程的 vsync 事件。但是[用户](https://github.com/flutter/flutter/issues/121525)注意到 Dart 线程上的这项额外工作也导致了一些卡顿。

在 3.10 中，**我们将本地图像的打开和解码从 Dart 线程移至[后台线程](https://github.com/flutter/engine/pull/39918)**，这个更改消除了具有大量本地图像的屏幕上潜在的长时间停顿，同时避免了延迟 vsync 事件，在我们的本地测试和自动化基准测试中，这个更改将多个同步图像的加载时间缩短了一半。

![](http://img.cdn.guoshuyu.cn/20230511_F3/image16.png)



我们继续在 Flutter 新的内部 DisplayList 结构之上构建优化，在 3.10 中，我们添加了 [R-Tree based culling](https://github.com/flutter/engine/pull/38429) 机制。

这种机制在我们的渲染器中更早地移除了绘制操作的处理。[例如](https://github.com/flutter/flutter/issues/92366) 优化加速了输出在屏幕外失败的自定义painter。

我们的  [microbenchmarks](https://flutter-engine-perf.skia.org/e/?begin=1671661938&end=1671754421&keys=X789f7ff76f30f8ccc672464f335fe09b&num_commits=50&request_type=1&xbaroffset=31974)  显示 DisplayList 处理时间最多减少了 50%，具有裁剪自定义绘画的 App 可能会看到不同效果的改进，改进的程度取决于隐藏绘制操作的复杂性和数量。

## 减少 iOS 启动延迟

之前应用中标识符查找的[低效策略](https://github.com/flutter/flutter/issues/37826)增加了应用启动延迟，这个启动延迟的增长与应用的大小成正比。

而在 3.10 中，[我们修复了 bundle identifier lookup](https://github.com/flutter/engine/pull/39975)，这将大型应用的启动延迟减少了 100 毫秒或大约 30–50%。

## 缩小尺寸

Flutter 使用 `SkParagraph` 作为文本、布局和渲染的默认库，之前我们包括了一个标志以支持回退到遗留 `libtxt`和 `minikin` 。

由于我们对 `SkParagraph` 有充分的信心，[我们](https://github.com/flutter/engine/pull/39499)在 3.10 中删除了 `libtxt` 和 `minikin` 以及它们的标志，这将 Flutter 的压缩大小减少了 30KB。

> 看起来信心十足了。

## 稳定性

在 3.0 版本中，我们在渲染管道后期启用了一项 Android 功能，该功能使用高级 GPU 驱动，当只有一个“dirty” 区域发生变化时，这些驱动功能会重新绘制较少的屏幕内容。

我们之前已经将它添加到早期的优化中以达到类似的效果，尽管我们的基准测试结果不错，但还是出现了两个问题：

- 首先，改进最多的基准可能不代表实际用例。
- 其次，[事实证明很难找到](https://github.com/flutter/engine/pull/37493)支持此 GPU 驱动功能的设备和 Android 版本集

鉴于有限的进步和支持，我们在 Android 上[禁用了](https://github.com/flutter/engine/pull/40898)部分重绘功能。

而使用 Skia 后端时，该功能在 iOS 上依然保持启用状态，我们希望在未来的版本中可以[通过 Impeller 启用它。](https://github.com/flutter/flutter/issues/124526)



# API 改进

## APNG解码器

Flutter 3.10  [解决了一个我们最受关注的问题](https://github.com/flutter/flutter/issues/37247)，它增加了 `APNG` 解码图像的[能力](https://github.com/flutter/engine/pull/31098)，现在可以使用 Flutter 现有的图片加载 API 来加载 `APNG`  图片。

## 图片加载 API 改进

3.10 添加了一个[新方法](https://master-api.flutter.dev/flutter/dart-ui/instantiateImageCodecWithSize.html) `instantiateImageCodecWithSize`，该方法满足以下三个条件的[用例支持：](https://github.com/flutter/flutter/issues/118543)

- 加载时宽高比未知
- 边界框约束
- 原始纵横比约束

# Mobile

## iOS

### 无线调试

**现在可以在无线的情况下运行和热重新加载的 Flutter iOS 应用**。

在 Xcode 中成功无线配对 iOS 设备后，就可以使用 flutter run 将应用部署到该设备，**如果遇到问题，请在 Window > Devices** 和 **Simulators > Devices**下验证网络图标是否出现在设备旁边。

> 要了解更多信息，可以查阅 https://docs.flutter.dev/get-started/install/macos#ios-setup。

### 宽色域图像支持

iOS 上的 Flutter 应用现在可以支持宽色域图像的精确渲染，要使用宽色域支持，应用必须使用 Impeller 并在 `Info.plist` 文件添加 `FLTEnableWideGamut ` 标志。

### 拼写检查支持

 `SpellCheckConfiguration()` 控件现在默认支持 [Apple](https://developer.apple.com/documentation/uikit/uitextchecker) 在 iOS 上的拼写检查服务，可以使用 `spellCheckConfiguration` 中的参数对其进行设置 `CupertinoTextField` 。

![](http://img.cdn.guoshuyu.cn/20230511_F3/image17.gif)



### 自适应复选框和单选

3.10 将 `CupertinoCheckBox` 和 `CupertinoRadio` 添加到库中 `Cupertino` ，他们创建符合 Apple 样式的复选框和单选按钮组件。

Material 复选框和单选控件添加了 `.adaptive` 构造函数，在 iOS 和 macOS 上，这些构造函数使用相应的 Cupertino 控件，在其他平台上使用 Material 控件。

### 优化 Cupertino 动画、过渡和颜色

Flutter 3.10 改进了一些动画、过渡和颜色以匹配 SwiftUI，这些改进包括：

- [更新](https://github.com/flutter/flutter/pull/122275) `CupertinoPageRoute`
- [添加](https://github.com/flutter/flutter/pull/110127)标题放大动画 `CupertinoSliverNavigationBar`
- 添加几种[新的 iOS 系统颜色 ](https://github.com/flutter/flutter/pull/118971)`CupertinoColors`

![](http://img.cdn.guoshuyu.cn/20230511_F3/image18.gif)



### PlatformView 性能

当 `PlatformViews `出现在屏幕上时，Flutter会限制 iOS 上的[刷新率以减少卡顿](https://github.com/flutter/engine/pull/39172)，当应用显示动画或可滚动时，用户可能会在应用出现 `PlatformViews`  时注意到这一点。

### macOS 和 iOS 可以在插件中使用共享代码

Flutter 现在支持插件 `pubspec.yaml` 文件中的 `sharedDarwinSource` ，这个 key 表示 Flutter 应该共享 iOS 和 macOS 代码。

```
ios: 
  pluginClass:  PathProviderPlugin 
  dartPluginClass:  PathProviderFoundation 
  sharedDarwinSource:  true 
macos: 
  pluginClass:  PathProviderPlugin 
  dartPluginClass:  PathProviderFoundation 
  sharedDarwinSource:  true
```

### 应用扩展的新资源

我们为 Flutter 开发人员添加了使用 iOS 应用扩展文档，这些扩展包括实时活动、主屏幕控件和共享扩展。

为了简化创建主屏幕控件和共享数据，我们向 `path_provider` 和 `homescreen_widget` 插件添加了新方法。

> 具体可见：https://docs.flutter.dev/development/platform-integration/ios/app-extensions

### 跨平台设计的新资源

该文档现在包括针对特定 [UI  组件](https://docs.flutter.dev/resources/platform-adaptations#ui-components)的跨平台设计注意事项，要了解有关这些 UI 组件的更多信息，请查看Flutter UX GitHub 存储库中的讨论： https://github.com/flutter/uxr/discussions

> 具体可见：https://docs.flutter.dev/resources/platform-adaptations#ui-components



## Android

### Android CameraX 支持

[Camera X ](https://developer.android.com/training/camerax)是一个 Jetpack 库，可简化向 Android 应用添加丰富的相机功能。

该功能适用于多种 Android 相机硬件，在 3.10 中，我们为 Flutter Camera 插件添加了对 CameraX 的初步支持，此支持涵盖以下用例：

- 图像捕捉
- 视频录制
- 显示实时相机预览

```
Dependencies: 
  camera:  ^0.10.4  # 最新相机版本
  camera_android_camerax:  ^0.5.0
```



# 开发者工具

我们继续改进了 DevTools，这是一套用于 Dart 和 Flutter 的性能和调试工具，一些亮点包括：

- DevTools UI 使用 Material 3，这让外观现代化又增强了可访问性。
- DevTools 控制台支持在调试模式下评估正在运行的应用，在 3.10 之前，只能在暂停应用时执行此操作。
- 嵌入式 [Perfetto 跟踪查看器](https://perfetto.dev/)取代了以前的时间线跟踪查看器。

Perfetto 可以处理更大的数据集，并且比传统的跟踪查看器表现得更好，例如：

- 允许固定感兴趣的线程
- 单击并拖动以从多个帧中选择多个时间轴事件
- 使用 SQL 查询从时间轴事件中提取特定数据

![](http://img.cdn.guoshuyu.cn/20230511_F3/image19.png)

# 弃用和重大更改

## 弃用的 API

3.10 中的重大更改包括在 v3.7 发布后过期的弃用 API。

要查看所有受影响的 API 以及其他上下文和迁移指南，请查看[之前版本的弃用指南](https://docs.flutter.dev/release/breaking-changes/3-7-deprecations)。

> [Dart Fix ](https://docs.flutter.dev/development/tools/flutter-fix)可以修复其中的许多问题，包括在 IDE 中快速修复和使用`dart fix`命令批量应用。

## Android Studio Flamingo 升级

将 Android Studio 升级到 Flamingo 后，你可能会在尝试 `flutter run` 或 `flutter build` Flutter Android 应用时看到错误。

[发生此错误是因为 Android Studio Flamingo 将其捆绑的 Java SDK 从 11 更新到 17，](https://docs.gradle.org/current/userguide/compatibility.html#java)使用 Java 17 时，之前的 7.3 Gradle 版本无法运行。

我们[更新](https://github.com/flutter/flutter/pull/123916)来了 `flutter analyze --suggestions` 以验证是否由于 Java SDK 和 Gradle 版本之间的不兼容而发生此错误。

> 要了解修复此错误的不同方法，请查看我们的迁移指南：https://docs.flutter.dev/go/android-java-gradle-error。

## Window singleton 弃用

改版本弃用了 Window singleton，依赖它的应用和库需要开始[迁移](https://docs.flutter.dev/release/breaking-changes/window-singleton)。

当你的应用在未来版本的 Flutter 中做支持时，这会可以为你的应用提前做好多窗口准备支持。

> PS：还可以关注下本次 I/O 基于 Flutter 发布的新小游戏：[I/O FLIP 小游戏](https://juejin.cn/post/7231378331139997757)