# Flutter 3.24 发布啦，快来看看有什么更新

2024年立秋，Flutter 3.24 如期而至，本次更新主要包含 **Flutter GPU 的预览，Web 支持嵌入多个 Flutter 视图，还有更多  Cupertino 相关库以及 iOS/MacOS 的更新等**，特别是 Flutter GPU 的出现，可以说它为 Impeller  未来带来了全新的可能，甚至官方还展示了[小米如何使用 Flutter 为 SU7 新能源车开发 App](http://flutter.dev/showcase/xiaomi) 的案例。

>  可以看到，曾经 Flutter 的初代 PM 强势回归之后，Flutter 再一次迎来了新的春风。

# Flutter GPU

其实这算是我对 3.24 最感兴趣的更新，因为 Flutter GPU 真的为 Flutter 提供了全新的可能。

**Flutter GPU  是 Impeller 对于 HAL 的一层很轻的包装，并搭配了关于着色器和管道编排的自动化能力**，也通过 Flutter GPU  就可以使用 Dart 直接构建自定义渲染器，所以 Flutter GPU 可以扩展到 Flutter  HAL 中直接渲染的内容。

当然，**Flutter GPU 由 Impeller 支持，但重要的是要记住它不是 Impeller  ，Impeller 的 HAL 是私有内部代码与 Flutter GPU 的要求非常不同**， Impeller 的私有 HAL 和 Flutter GPU 的公共 API 设计之间是存在一定差异化实现。

而通过 Flutter GPU，如曾经的  Scene (3D renderer)  支持，也可以被调整为基于  Flutter GPU 的全新模式实现，因为 Flutter GPU 的 API 允许完全控制渲染通道附件、顶点阶段和数据上传到 GPU 的过程，这种灵活性对于创建复杂的渲染解决方案（从 2D 角色动画到复杂的 3D 场景）至关重要。

![](http://img.cdn.guoshuyu.cn/20240807_PRE/image5.png)  

可以想象，通过 Flutter GPU，Flutter 开发者可以更简单地对 GPU 进行更精细的控制，通过与 HAL 直接通信，创建 GPU 资源并记录 GPU 命令，从而最大限度的发挥 Flutter 的渲染能力。

![](http://img.cdn.guoshuyu.cn/20240807_PRE/image1.gif)

有关 Flutter GPU 相关的，详细可见：[《Flutter GPU 是什么？为什么它对 Flutter 有跨时代的意义？》](https://juejin.cn/post/7399985723673821193)

如果你对 Flutter Impeller 和其着色器感兴趣，也可以看：

- [《快速了解 Flutter 的渲染引擎的优势》](https://juejin.cn/post/7337898389450080306)

- [《Flutter 里的着色器预热原理》](https://juejin.cn/post/7385942645232828442)



# MacOS PlatformView

其实官方并没有提及这一部分，但是其实从 3.22 就已经有相关实现，相信很多 Flutter 开发都十分关系 PC 上的  PlatformView 和 Webview 的进展，这里也简单汇总下。

关于 macOS 上的 PlatformView 支持，其实 2022 年中的时候，大概是 3.1.0 就有雏形，但是那时候发现了不少问题，例如：

- `UiKitView` 并不适合 macOS ，因为它本质上使用的 iOS 的 UiView  ，而 macOS 上需要使用的是 NSView；所以后续推进了 `AppKitView` 的出现，从 MacOS 的 Darwin 平台视图基类添加派生类，能力与 `UiKitView` 大致相同，但两者实现分离
- 3.22 基本就已经完成了 macOS 上 Webview 的接入支持， [#132583 PR](https://github.com/flutter/flutter/pull/132583) 很早就提交了，但是因为此时的 PlatformView 实现还不支持手势（触控板滚动）等支持，并且也还存在一些点击问题，所以还存于 block 

所以目前  `AppKitView`  已经有了，相关的实现也已经支持，但是还有一些问题 block 住了，另外目前 MacOS 上在 [#6221]( https://github.com/flutter/packages/pull/6221) 关于 WebView 的支持上，还存在：

- 不支持滚动 API，`WKWebView ` 在 macOS 上不公开 `scrollView ` ，获取和设置滚动位置的代码不起作用
- 由于 macOS 上的视图结构不同，因此无法设置背景颜色，`NSView`  没有与 UIView 相同的颜色和不透明度控制，因此设置背景颜色将需要替代实现

>  官方也表示，在完善 macOS 的同时，随后也将推出适用于 Windows 的 PlatformView 和 WebView。

而目前 macOS 上 PlatformView 的实现，采用的是 Hybrid composition 模式，这个模式看过我以前文章的应该不会陌生，它的实现相对性能开销上会比较昂贵：

> 因为 Flutter 中的 UI 是在专用的光栅线程上执行，而该线程很少被阻塞，但是当使用  Hybrid composition  渲染PlatformView 时，Flutter UI 继续从专用的光栅线程合成，但 PlatformView 是在平台线程上执行图形操作。

为了光栅化组合内容，Flutter 需要在在其光栅线程和 PlatformView 线程之间执行同步，因此 PlatformView 线程上的任何卡顿或阻塞操作都会对 Flutter 图形性能产生负面影响。

之前在 Mobile 上出现过的 Hybrid composition  闪烁情况，在这上面还是很大可能会出现，例如 [#138936]( https://github.com/flutter/flutter/issues/138936) 就提到过类似的问题并修复。

另外还有如 [#152178](https://github.com/flutter/flutter/issues/152178) 里的情况，如果  debugRepaintRainbowEnabled 为 true ，PlatformView 可能会不会响应点击效果 。

**所以，如果你还在等带 PC 上 PlatformView 和 WebView 等的相关支持，那么今年应该会能看到 MacOS 上比较完善的发布** 。

# Framewrok

##  全新 Sliver

3.24 包含了一套可组合在一起以实现动态 App bar 相关行为的全新 Sliver ：

- [SliverFloatingHeader](http://api.flutter.dev/flutter/widgets/SliverFloatingHeader-class.html)
- [PinnedHeaderSliver](http://api.flutter.dev/flutter/widgets/PinnedHeaderSliver-class.html)
- [SliverResizingHeader](http://api.flutter.dev/flutter/widgets/SliverResizingHeader-class.html)

`SliverPersistentHeader`  可以使用这些全新的 Slivers 来实现浮动、固定或者跟随用户滚动而调整大小的 App bar，这些新的 Slivers 与现有的 Slivers 效果类似 `SliverAppBar` ，但具有更简单的 API 。

例如 `PinnedHeaderSliver`  ，它就可以很便捷地就重现了 iOS 设置应用的 Appbar 的效果：



![](http://img.cdn.guoshuyu.cn/20240807_F324/image1.gif)

## Cupertino 更新

3.24 优化了 `CupertinoActionSheet`  的交互效果，现在用手指在 Sheet 的按钮上滑动时，可以有相关的触觉反馈，并且按钮的字体大小和粗细现在与 iOS 相关的原生风格一致。

![](http://img.cdn.guoshuyu.cn/20240807_F324/image2.gif)



另外还为  `CupertinoButton` 添加了新的焦点属性，同时 `CupertinoTextField`  也可以自定义的 disabled 颜色。

> 未来 Cupertino 库还会继续推进，本次回归的 PM 主要任务之一就是针对 iOS 和 macOS 进行全新一轮的迭代。

## TreeView

`two_dimensional_scrollables`  发布了全新的 TreeView 以及相关支持，用于构建高性能滚动树，这些滚动树可以随着树的增长向各个方向滚动，`TreeSliver`  还添加到了用于在一维滑动中的支持。

![](http://img.cdn.guoshuyu.cn/20240807_F324/image3.gif)

## CarouselView

`CarouselView`  作为轮播效果的实现，可以包含滑动的项目列表，滚动到容器的边缘，并且 leading 和 trailing  item 可以在进出视图时动态更改大小。

![](http://img.cdn.guoshuyu.cn/20240807_F324/image4.gif)

## 其他 Widget 更新

从 3.24 开始，一些非特定的设计核心 Widget 会从 Material 库中被移出到 Widgets 库，包括：

- `Feedback`  Widget 支持设备的触摸和音频反馈，以响应点击、长按等手势
- `ToggleableStateMixin` / `ToggleablePainter`用于构建可切换 Widget（如复选框、开关和单选按钮）的基类

## AnimationStatus 的增强

[AnimationStatus](https://api.flutter.dev/flutter/animation/AnimationStatus.html) 添加了一些全新的枚举，包括：

- isDismissed
- isCompleted
- isRunning
- isForwardOrCompleted

其中一些已存在于 `Animation`子类中 如 `AnimationController` 和 `CurvedAnimation` ， 现在除了 AnimationStatus 之外，所有这些状态都可在 Animation 子类中使用。

最后，AnimationController  中添加了 `toggle` 方法来切换动画的方向。

![](http://img.cdn.guoshuyu.cn/20240807_F324/image5.png)

## SelectionArea 更新

SelectionArea 又又又引来更新，本次  `SelectionArea`  支持更多原生手势，例如使用鼠标单击三次以及在触摸设备上双击，默认情况下，`SelectionArea` 和 `SelectableRegion ` 都支持这些新手势。

单击三次

- 三次单击 + 拖动：扩展段落块中的选择内容。
- 三次点击：选择单击位置处的段落块。

![](http://img.cdn.guoshuyu.cn/20240807_F324/image6.gif)

双击

- 双击+拖动：扩展字块的选择范围（Android/Fuchsia/iOS 和 iOS Web）。
- 双击：选择点击位置的单词（Android/Fuchsia/iOS 和 Android/Fuchsia Web）。

![](http://img.cdn.guoshuyu.cn/20240807_F324/image7.gif)



# Engine

## Impeller 

为了今年移除 iOS 上的  Skia 支持，Flutter 一直在努力改进 Impeller 的性能和保真度，例如对文本渲染的一系列改进大大提高了[表情符号滚动的性能](https://github.com/flutter/flutter/issues/138798)，消除了滚动大量表情符号时的卡顿，这是对 Impeller 文本渲染功能的一次极好的压力测试。

此外，通过[解决一系列问题](https://github.com/flutter/engine/pull/53042)，还在这个版本中大大提高了 Impeller 文本渲染的保真度，特别是文本粗细、间距和字距调整，现在这些在 Impeller 都和 Skia 的文本保真度相匹配。

![](http://img.cdn.guoshuyu.cn/20240807_F324/image8.png)

## **Android 预览**

3.24 里 Android 继续为预览状态 ，由于[Android 14 中的一个错误](https://github.com/flutter/flutter/issues/146499#issuecomment-2082873125)影响了 Impeller 的 PlatformView API 支持，所以本次延长了 Impeller 在 Android 上的预览期。

> 目前 Android 官方已经修复了该错误，但在目前市面上已经有许多未修复的 Android 版本在运行，所以解决这些问题意味着需要进行额外的 API 迁移，因此需要额外的稳定发布周期，所以本次推迟了将 Impeller 设为默认渲染器的决定。

## 改进了 downscaled images 的默认设置

从 3.24 开始，**图像的默认值 `FilterQuality`已从 `FilterQuality.low`  调整为`FilterQuality.medium`**。

因为目前看来， `FilterQuality.low` 会更容易导致图像看起来出现“像素化”效果，并且渲染速度比 `FilterQuality.medium` 更慢。

# Web

## Multi-view 支持

Flutter Web 现在可以利用 Multi-view 嵌入，同时将内容渲染到多个 HTML 元素中，核心是不再只是 Full-screen   模式，此功能称为 “embedded mode” 或者 “multi-view”，可灵活地将 Flutter 视图集成到现有 Web 应用中。

在 multi-view 模式下，Flutter Web 应用不会在启动时立即渲染，相反它会等到 host 应用使用 addView 方法添加第一个“视图” ，host 应用可以动态添加或删除这些视图，Flutter 会相应地调整其 Widget 状态。

要启用 multi-view  模式，可以在 `flutter_bootstrap.js` 文件中的 `initializeEngine`方法, 通过 `multiViewEnabled: true`进行设置。

```js
// flutter_bootstrap.js
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function onEntrypointLoaded(engineInitializer) {
    let engine = await engineInitializer.initializeEngine({
      multiViewEnabled: true, // Enables embedded mode.
    });
    let app = await engine.runApp();
    // Make this `app` object available to your JS app.
  }
});
```

设置之后，就可以通过 JavaScript 管理视图，将它们添加到指定的 HTML 元素并根据需要将其移除，每次添加和移除视图都会触发 Flutter 的更新，从而实现动态内容渲染。

```js
// Adding a view...
let viewId = app.addView({
  hostElement: document.querySelector('#some-element'),
});

// Removing viewId...
let viewConfig = flutterApp.removeView(viewId);
```

另外视图的添加和删除通过类的  `WidgetsBinding ` 的 `didChangeMetrics`   去管理和感知：

```dart
@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateViews();
  }

  @override
  void didUpdateWidget(MultiViewApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Need to re-evaluate the viewBuilder callback for all views.
    _views.clear();
    _updateViews();
  }

  @override
  void didChangeMetrics() {
    _updateViews();
  }

  Map<Object, Widget> _views = <Object, Widget>{};

  void _updateViews() {
    final Map<Object, Widget> newViews = <Object, Widget>{};
    for (final FlutterView view in WidgetsBinding.instance.platformDispatcher.views) {
      final Widget viewWidget = _views[view.viewId] ?? _createViewWidget(view);
      newViews[view.viewId] = viewWidget;
    }
    setState(() {
      _views = newViews;
    });
  }


```

另外通过 `final int viewId = View.of(context).viewId;` 也可以识别视图， `viewId` 可用于唯一标识每个视图。

> 更多可见 https://docs.flutter.dev/platform-integration/web/embedding-flutter-web

# iOS

## Swift Package Manager 初步支持

一直以来 Flutter 都是使用 CocoaPods 来管理 iOS 和 macOS 依赖项，而 Flutter 3.24 增加了对 Swift Package Manager 的早期支持，这对于 Flutter 来说，好处就是：

- **Flutter 的 Plugin 可以更贴近 Swift 生态**
- **简化 Flutter 安装环境，Xcode 本身就是包含 Swift Package Manager**，如果 Flutter 的项目使用 Swift Package Manager，则完全无需安装 Ruby 和 CocoaPods 等环境

而从目前的官方 Package 上看，[#146922](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fflutter%2Fflutter%2Fissues%2F146922) 上需要迁移支持的 Package 大部分都已经迁移完毕，剩下的主要文档和脚本部分的支持。

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image13.png)

> **更多详细可见 [《Flutter 正在迁移到 Swift Package Manager ，未来会弃用 CocoaPods 吗？》](https://juejin.cn/post/7399592120128978970)**

# Ecosystem

## SharedPreferences 更新

[sharedpreferences](https://pub.dev/packages/shared_preferences) 插件添加了两个新 API ：SharedPreferencesAsync 和 SharedPreferencesWithCache，**最重要的变化是 Android 实现使用 PreferencesDataStore 而不是 SharedPreferences**。

SharedPreferencesAsync 允许用户直接调用平台来获取设备上保存的最新偏好设置，但代价是异步，速度比使用缓存版本慢一点。这对于可以由其他系统或隔离区更新的偏好设置很有用，因为更新缓存会使缓存失效。

SharedPreferencesWithCache 建立在 SharedPreferencesAsync 之上，允许用户同步访问本地缓存的偏好设置副本。这与旧 API 类似，但现在可以使用不同的参数多次实例化。

这些新 API 旨在将来取代当前的 SharedPreferences API。但是，这是生态系统中最常用的插件之一，我们知道生态系统需要一些时间才能切换到新 API。

# DevTools 和 IDE

**DevTools Performance** 工具新增 **Rebuild Stats**功能，可以捕获有关在应用中甚至在特定 Flutter 框架中构建 Widget 的次数的信息。

![image-20240807052902246](http://img.cdn.guoshuyu.cn/20240807_F324/image9.png)

另外，本次还对 **Network profiler** 和 **Flutter Deep Links** 等工具进行了完善和关键错误修复，并进行了一些常规改进，如 *DevTools 在 VS Code 窗口内打开* 和 *DevTools在 Android Studio 工具窗口内打开*

![image-20240807052955842](http://img.cdn.guoshuyu.cn/20240807_F324/image10.png)

![](http://img.cdn.guoshuyu.cn/20240807_F324/image11.png)

3.24 版本还对 [DevTools Extensions](https://docs.flutter.dev/tools/devtools/extensions) 进行了一些重大改进，现在可以在调试 Dart 或 Flutter 测试时使用 DevTools Extensions ，甚至可以在不调试任何内容而只是在 IDE 中编写代码时使用。

# 最后

不得不说 Flutter 在新技术投资和跟进上一直很热衷，不管是之前的 WASM Native ，还是 Flutter GPU 的全新尝试，甚至 RN 还在挣扎 Swift Package Manager 的支持时，Flutter 已经初步落地 Swift Package Manager，还有类似 sharedpreferences 跟进到 PreferencesDataStore 等，都可以看出 Flutter 的技术迭代还是相对激进的。

本次更新，Flutter team 也展示了案例：

- **小米的一个小团队如何以及为何使用 Flutter 为 SU7 新能源车开发 App ：http://flutter.dev/showcase/xiaomi**
- [**法国铁路公司SNCF Connect**](http://flutter.dev/showcase/sncf-connect) 在欧洲的案例，它与奥运会合作，为使数百万游客能够在奥运会期间游览法国
- Whirlpool 正在利用 Flutter 在巴西探索新的销售渠道
- ·····

另外，2024 年 Fluttercon 欧洲举办了首届 Flutter 和 Dart 生态系统峰会，具体讨论了如：

- FFI 和 jnigen/ffigen 缺少更多示例和文档
- method channels 调试插件的支持
- 合并 UI 和平台线程的可能性
- 研究减轻插件开发负担的策略
- 解决包装生态系统碎片化问题

而接下来 9 月份 Fluttercon USA 也将继续在纽约召开深入讨论相关主题，可以看到 Flutter 正在进一步开放和听取社区开发者的意见并改进，Flutter 虽然还有很多坑需要补，但是它也一直在努力变得更好。

**所以，骚年，你打算更新 3.24 吃螃蟹了吗？还是打算等 3.24.6** ？