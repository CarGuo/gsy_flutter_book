# Flutter 3.29 发布，看起来会是一个“大坑”的版本

**Flutter 3.29 正式发布，如果不出意外，这将是一个带着“大坑”到来的版本**，因为该版本带来了很多「重大调整或者弃用」 ，**所以如果你想升级到 3.29，还需要多慎重了解这次升级到底更新了什么**。

之所以说带着“大坑”，主要是 3.29 更新带来了太多“意料之外”的东西，例如：

- Dart 代码会直接在 Android/iOS 的主 UI 线程上运行，而不是单独的 Dart UI 线程，此时 Dart 和平台调用直接可以同步执行
- iOS skia 正式被移除
- 没有 Vulkan 驱动的 Android 设备将回退到在 OpenGLES 上运行的 Impeller，而不是使用 Skia
- 移除了 Flutter Gradle 插件，之前没迁移的需要手动迁移适配
- Web 平台 HTML renderer 正式移除
- 全新的 DevTools
- ···

相信大家从上述描述里应该可以感受到 3.29 潜在的“威能”，那么下面就让我们看看 3.29 给我们带来了什么更新吧。

# Framework

## Cupertino 更新

和 3.27 那会一样， Flutter iOS 的 PM 回归后， 每次更新都会包含不少 Cupertino 的身影，而本次 3.29 开始 `CupertinoNavigationBar` 和 `CupertinoSliverNavigationBar`  将支持 [bottom widget](https://main-api.flutter.dev/flutter/cupertino/CupertinoNavigationBar/bottom.html) 配置，一般会用于搜索字段或分段控件的场景。

例如在 `CupertinoSliverNavigationBar` 里现在可以使用 [bottomMode](https://main-api.flutter.dev/flutter/cupertino/CupertinoSliverNavigationBar/bottomMode.html) 属性配置底部 Widget，从而支持自动调整大小直到隐藏，或者始终在导航栏滚动时显示：

![](http://img.cdn.guoshuyu.cn/20250212_F329/image1.gif)

![](http://img.cdn.guoshuyu.cn/20250212_F329/image2.gif)

> Flutter 在 Cupertino 的高保真支持上力度上，从近来的几个版本都可以明显感受到。

其他导航栏的更新包括：

- 当部分滚动时，`CupertinoSliverNavigationBar` 可以在展开和折叠状态之间对齐

- 新的 `CupertinoNavigationBar.large` 构造函数支持静态导航栏显示大标题

- Cupertino popups  窗口支持[更生动的背景模糊](https://github.com/flutter/flutter/pull/159272)效果，从而提高了 Cupertino 风格的保真度：

  ![](http://img.cdn.guoshuyu.cn/20250212_F329/image3.png)

- 新的 `CupertinoSheetRoute`  可以使用拖动手势将其移除，同时还提供了新的 `showCupertinoSheet` ：

  ![](http://img.cdn.guoshuyu.cn/20250212_F329/image4.gif)

-  `CupertinoAlertDialog` 改进了在深色模式下的 native 保真度：![](http://img.cdn.guoshuyu.cn/20250212_F329/image5.png)

- 在文本选择时，反转选择后，Flutter 的文本选择手柄在 iOS 上会交换它们的顺序，并且文本选择放大镜的边框颜色现在会和当前主题匹配：![](http://img.cdn.guoshuyu.cn/20250212_F329/image6.gif)

> 不得不说最近几个版本都有关于文本选择的更新内容，也许不久之后，Flutter 文本处理能力的短板会被补齐。

## Material 更新

谷歌对于 Material 设计规范的跟进依然还是「迷之聚焦」，这对于国内开发者而言不知是福是祸， 3.29 提供了新的 Material 3  页面过渡构建器 `FadeForwardsPageTransitionsBuilder` ，主要是为了匹配 Android 的最新页面过渡行为。

在页面跳转过渡期间，页面会从右向左滑动淡入，退出页面会从右向左滑动淡出，这个新过渡还解决了以前由 `ZoomPageTransitionsBuilder` 导致的性能问题：

![](http://img.cdn.guoshuyu.cn/20250212_F329/image7.gif)

此外，3.29 还更新了 `CircularProgressIndicator` 和 `LinearProgressIndicator`，从而适配 Material 3 规范，如果要使用更新的样式，需要将 `year2023` 属性设置为 `false`，或者将 [ProgressIndicatorThemeData.year2023](https://main-api.flutter.dev/flutter/material/ProgressIndicatorThemeData/year2023.html) 设置为 `false ` ：

![](http://img.cdn.guoshuyu.cn/20250212_F329/image8.gif)

![](http://img.cdn.guoshuyu.cn/20250212_F329/image9.gif)

> `year2023` 属于将 **Deprecated** 的字段。

在 3.29 还引入了  M3 最新的 `Slider`  设计样式，`Slider` 默认为以前的 Material 3 样式，如果要启用最新设计，同样需要将 `year2023` 设置为 `false`，或将 `SliderThemeData.year2023 `设置为 `false` ：

![](http://img.cdn.guoshuyu.cn/20250212_F329/image10.png)最后，3.29 里还包含了 Material library 的多个错误修复和功能增强，例如：

- Keyboard navigation 现在可以正确触发 `DropdownMenu.onSelected` 回调
- 改进了 `TabBar` 弹性动画 ![](https://img.cdn.guoshuyu.cn/333321r_compressed.gif)
- 改进了 `RangeSlider` 的 thumb 对齐方式，包括 divisions 、padding 和圆角
- 增强了多个 Material 组件的自定义支持，例如 `mouseCursor` 属性已添加到 `Chip`、`Tooltip` 和 `ReorderableListView`  里面，从而允许在悬停时自定义鼠标光标

## Text selection 

**近来几个版本 Framework 更新都会包含文本选择的更新**，比如之前各种手势和鼠标触发的选择效果等，而 3.29 现在通过 `SelectionListener` 和 `SelectionListenerNotifier` 提供了有关 `SelectionArea` 或 `SelectableRegion` 下的文本选择信息：

`SelectionDetails` （通过 `SelectionListenerNotifier` 获得）提供了所选内容的开始和结束偏移量（相对于 wrapped 的子树），并提示所选内容是否存在以及是否已折叠：

![](http://img.cdn.guoshuyu.cn/20250212_F329/image11.gif)

另外还可以通过  `SelectableRegionSelectionStatusScope`  获取 `SelectionArea` 或 `SelectableRegion` 状态的信息，例如通过使用 `SelectableRegionSelectionStatusScope.maybeOf(context)`  检查`SelectableRegionSelectionStatus` 状态：

```dart
class MySelectableText extends StatefulWidget {
  const MySelectableText({super.key, required this.selectionNotifier, required this.onChanged});

  final SelectionListenerNotifier selectionNotifier;
  final ValueChanged<SelectableRegionSelectionStatus> onChanged;

  @override
  State<MySelectableText> createState() => _MySelectableTextState();
}

class _MySelectableTextState extends State<MySelectableText> {
  ValueListenable<SelectableRegionSelectionStatus>? _selectableRegionScope;

  void _handleOnSelectableRegionChanged() {
    if (_selectableRegionScope == null) {
      return;
    }
    widget.onChanged.call(_selectableRegionScope!.value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectableRegionScope?.removeListener(_handleOnSelectableRegionChanged);
    _selectableRegionScope = SelectableRegionSelectionStatusScope.maybeOf(context);
    _selectableRegionScope?.addListener(_handleOnSelectableRegionChanged);
  }

  @override
  void dispose() {
    _selectableRegionScope?.removeListener(_handleOnSelectableRegionChanged);
    _selectableRegionScope = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionListener(
      selectionNotifier: widget.selectionNotifier,
      child: const Text('This is some text under a SelectionArea that can be selected.'),
    );
  }
}
```

## Accessibility 

3.29 改进了多个 Material 控件里 Accessibility 的用户体验：

- 启用屏幕阅读器后，表单 Widget 仅宣布它遇到的第一个错误。
- 屏幕阅读器现在会读出下拉菜单的正确标签。

# Web

在去年发布 wasm 时，Flutter 在 Web 上的 WebAssembly （wasm） 支持要求开发者使用特殊的 HTTP 响应 headers 来托管 Flutter 应用，而现在相关要求在 3.29 开始放宽。

现在使用默认 headers 可以允许应用使用 wasm 运行，但仅限于单个线程，而更新 headers 可以让 wasm 构建的 Flutter Web 应用使用多个线程运行。

同时 3.29 修复了 WebGL 后端上图像的几个问题：

- [从 UI 线程异步解码图像以避免卡顿](https://github.com/flutter/engine/pull/53201)
- [Image.network 开箱即用支持 CORS 图像](https://github.com/flutter/flutter/pull/157755)

另外补充一点，**关于 Flutter Web 在 WebAssembly 上的 SEO 优化支持，官方正在研究一种使用Flutter 语义树来适配的场景** ：

![](http://img.cdn.guoshuyu.cn/20250212_F329/image12.png)

Flutter Web 在 3.29  还允许开发者[更好地控制图像在 Web 上的显示方式](https://github.com/flutter/flutter/pull/159917)，过去 Image 会在发生 CORS 错误时自动使用 `<img>` 元素来显示来自 URL 的图像，这可能会导致出现一些不一致的行为。

而现在 `webHtmlElementStrategy` 标志允许开发者选择何时使用 `<img>` 元素，**虽然默认情况下自动回退处于禁用状态**，不过仍然可以标志启用回退，甚至根据应用场景确定 `<img>` 元素的优先级。

![](http://img.cdn.guoshuyu.cn/20250212_F329/image13.png)

# Engine

## Impeller Vulkan  稳定性

3.29 修复了不少 Vulkan 问题，包活：

- 修复了许多用户在支持 Vulkan 的旧版设备上出现的可重现闪烁和视觉抖动问题
- 禁用了 Android  Hardware Buffer swapchains
- 由于在 MediaTek/PowerVR SoC 上使用 Vulkan 会导致的大量黑屏和崩溃报告，目前这些设备现在仅使用 Impeller OpenGLES，**注意不是 skia** 
- Android 模拟器已更新为使用 Impeller GLES 后端，**注意不是 skia** 

## Impeller OpenGLES

在 3.29 里，**没有 Vulkan 驱动的 Android 设备将回退到在 OpenGLES 上运行的 Impeller，而不是使用 Skia**，默认情况下该行为处于启用状态，无需配置。

> 这样 Flutter 将实现 100% 支持 Android 上的 Impeller。

## Impeller iOS

**和去年提到的 roadmap 一样，现在 iOS 后端已删除 Skia 支持，并且 `FLTEnableImpeller` 选择退出标志不再有效**，随着 Flutter 开始从 iOS 版本中删除 Skia ，预计在未来版本中会进一步减小二进制文件大小。

# 新功能

## Backdrop filter优化

从 3.29 开始，显示多个背景滤镜的应用现在可以使用新的 `BackdropGroup` 和新的 `BackdropFilter.grouped`，通过这些 Widget 可以提高多个模糊的性能：

```dart
Widget build(BuildContext context) {
  return BackdropGroup(
    child: ListView.builder(
      itemCount: 60,
      itemBuilder: (BuildContext context, int index) {
        return ClipRect(
          child: BackdropFilter.grouped(
            filter: ui.ImageFilter.blur(
              sigmaX: 40,
              sigmaY: 40,
            ),
            child: Container(
              color: Colors.black.withOpacity(0.2),
              height: 200,
              child: const Text('Blur item'),
            ),
          ),
        );
     }
   ),
 );

```

> 上述代码展示了如何使用 BackdropGroup 让每个列表项都有一个有效的模糊效果，并且引擎将只执行一次背景模糊，但结果在视觉上与多次模糊相同。

**在 3.29 里，如果这些 Backdrop filter 控件都共享一个共同的 BackdropKey，那么 Flutter 引擎就可以将多个背景过滤器组合到一个渲染操作中**。

Backdrop Key 可以唯一标识背景过滤器的输入，当共享时表示执行一次过滤，这可以显著减少在场景中使用多个背景滤镜的开销。

对应的 Key 可以通过 `backdropKey` 构造函数参数手动提供，也可以通过 `.grouped` 构造函数从[BackdropGroup] 中查找。

## ImageFilter.shader

新的 `ImageFilter` 构造函数允许将自定义着色器应用于任何子 Widget ，这和 `package：flutter_shaders` 中的 `AnimatedSampler` 功能类似，不同之处在于它还适用于 backdrop filters 。



## Android/iOS 上的 Dart 线程更改

众所周知，一直以来 **Flutter 的 Dart UI Thread 和 Android/iOS 平台的 UI Thread 是不同线程**，这在 [《深入理解 Dart 异步实现机制》](https://juejin.cn/post/7383281753145475099) 和过去我们聊  background isolate 得时候聊过，而独立的 Dart UI 线程的主要目的之一防止阻塞平台 UI 线程。

但是由于 Flutter 是在与 native 主线程不同的 Thread（UI 线程）上执行 Dart 代码，所以会出现 Dart 和平台互相调用时需要序列化和异步消息传递，这意味着：

> Flutter 和 Native 之间需要使用 platform channels 来封装对平台线程的调用，而不是能够直接从 Dart 调用 API（即通过 FFI），这让一些简单的同步调用增加了性能损耗和无意义的异步行为。

**而从 3.29 开始，Android 和 iOS 上的 Flutter 将在应用的主线程上执行 Dart 代码，并且不再有单独的 Dart UI 线程**。

> 这是改进移动平台上 Native 和 Dart 互操作系列调整中的第一部分，**因为它将允许对平台进行同步调用和从平台进行同步调用，并且不会产生序列化和消息传递的开销**。

而当双方处于同一个线程下时，同步响应和调用可以更好处理一些平台事件处理、文本输入、插件调用和辅助功能等。

> **特别是在对于 `PlatformView`  混合渲染等场景，如果处于同一线程之上，那么一些场景下的  `PlatformView`  由于不同线程导致的闪烁或者同步问题或者也可以得到改善**。

当然， Eric 也在 [150525#issuecomment-2652547816](https://github.com/flutter/flutter/issues/150525#issuecomment-2652547816) 提到合并线程后的忧虑，比如 Dart 和 Native 平台同一线程之后，那么「滚动/动画」是否会因此出现相互影响，特别是第三方插件处理不当的时候，反而更加卡顿的情况。

**当然，在整个 Flutter 团队的目标里，完全剔除 platform/message channels 是必然的方向，未来整个异步 channel 肯定会被彻底“消灭”**。

# DevTools and IDEs

## 新的 DevTools inspector

默认情况下，3.29 下所有用户都启用了新的 DevTools inspector，新的 inspector 具有一个精简的 Widget  Tree 和一个全新的 Widget 属性视图，以及一个自动更新以响应热重载和导航事件的选项。

![](http://img.cdn.guoshuyu.cn/20250212_F329/image14.png)

通过全新的 inspector ，开发者可以更直观地调试布局问题和诊断布局问题：

![](http://img.cdn.guoshuyu.cn/20250212_F329/image15.png)

![](http://img.cdn.guoshuyu.cn/20250212_F329/image16.gif)

如果你想关闭它，目前可以从 Inspector settings 对话框中禁用它：

![](http://img.cdn.guoshuyu.cn/20250212_F329/image17.png)

> 更多可见：https://docs.flutter.dev/tools/devtools/inspector#new

## 对设备上 Widget 选择的更改

从 DevTools 检查器启用 widget 选择模式后，设备上的任何选择都被视为 widget 选择。

以前在初始 Widget 选择后，开发者需要单击设备上的 **Select widget** 按钮，然后选择另一个小组件，而现在有一个设备上的按钮，可用于快速退出 Widget 选择模式：

![](http://img.cdn.guoshuyu.cn/20250212_F329/image18.gif)

## 日志记录工具改进

DevTools 中的 Logging 工具在 3.29 更新中得到了一些改进：

- 日志包含并显示更多元的数据，例如日志严重性、类别、区域和 isolate 
- 添加了对按日志严重性级别进行筛选的支持
- 性能和初始加载时间的显著改进

![image-20250212121519602](http://img.cdn.guoshuyu.cn/20250212_F329/image19.png)

# 重大更改和弃用

本次重大更改和弃用影响范围还是比较大的。

## 一些 package 将停止支持

以下过去由官方提供的 package ，计划在 2025 年 4 月 30 日后停止支持，关于这些包后续可由第三方协调建立和维护分叉：

- [ios_platform_images planned to be discontinued #162961](https://github.com/flutter/flutter/issues/162961)
- [css_colors planned to be discontinued #162962](https://github.com/flutter/flutter/issues/162962)
- [palette_generator planned to be discontinued #162963](https://github.com/flutter/flutter/issues/162963)
- [flutter_image discontinued #162964](https://github.com/flutter/flutter/issues/162964)
- [flutter_adaptive_scaffold planned to be discontinued #162965](https://github.com/flutter/flutter/issues/162965)
- [flutter_markdown planned to be discontinued #162966](https://github.com/flutter/flutter/issues/162966)

## 删除 Flutter Gradle 插件

3.29 移除了 Flutter Gradle 插件，这个在很久之前就提到了，该插件其实自 3.19 起已被弃用，后续将把 Flutter Gradle 插件从 Groovy 转换为 Kotlin，并将其迁移到使用 AGP 公共 API，这个改动有望降低发布新 AGP 版本时损坏的频率，并减少基于构建的回归。

> 不得不说，现在 Android 平台自己的 AGP 兼容问题越来越麻烦，坑越来越多。

**如果是在 3.16 之前创建但尚未迁移的项目可能会受到影响**，比如 Flutter 工具在构建项目时会有警告：“`You are applying Flutter's main Gradle plugin imperatively`”，则基本可以确定会受到这个变动的影响，开发者需要根据  docs.flutter.dev 上提供的方式进行迁移。

> 更多可见：https://docs.flutter.dev/release/breaking-changes/flutter-gradle-plugin-apply

## 删除 Web HTML renderer

这个在之前的 [《Flutter Web 正式移除 HTML renderer，只支持 CanvasKit 和 SkWasm》 ](https://juejin.cn/post/7446613741627736091) 已经聊到过，而从 3.29 开始， HTML renderer 就被正式移除了。

同时正如前面所说的，一些由于  WebAssembly 带来的缺失也逐步完善，例如 CORS images 和通过语义树来适配的 SEO 等场景都在补齐：

![](http://img.cdn.guoshuyu.cn/20250212_F329/image20.png)

## Material changes 

作为 Material 中正在进行的主题规范化项目的一部分，3.29 弃用 `ThemeData.dialogBackgroundColor` 并迁移到了 `DialogThemeData.backgroundColor` ，开发者可以使用 `dart fix` 命令迁移受影响的代码。

同样在 Material 中，`ButtonStyleButton` `iconAlignment` 属性在添加到 `ButtonStyle` 和关联的 `styleFrom` 方法后已被弃用。

# 多窗口

最后，不得不提提及 PC 端多窗口支持的进展，在去年的 [《Flutter PC 多窗口新进展，已在 Ubuntu/Canonical 展示》](https://juejin.cn/post/7431894641426202636) 官方已经向我们展示了多窗口的可行性，而从 [#142845](https://github.com/flutter/flutter/issues/142845) 看目前推进的进度还可以：

![](http://img.cdn.guoshuyu.cn/20250212_F329/image21.png)

而从 [#30701](https://github.com/flutter/flutter/issues/30701#issuecomment-2618378846) 可以看到，不久之后对应的 PR 草稿将正式开始进行审查，所以相信今年应该可以看到期盼已久的多窗口落地：

![](http://img.cdn.guoshuyu.cn/20250212_F329/image22.png)

# 宏支持停止

关于 Dart 宏支持部份，正如 [《Flutter 新春第一弹，Dart 宏功能推进暂停，后续专注定制数据处理支持》](https://juejin.cn/post/7464998185485877311) 所说，**由于宏的性能具体目标还太遥远，Flutter 团队决定把当前的实现回归到编辑（例如静态分析和代码完成）和增量编译（热重载的第一步）上**，并且**具体在于重新投资Dart 中的数据支持**，从聚焦于而优化数据序列化和反序列化问题。



# 最后

可以看到 ，Flutter 3.29 带来了不少新功能的同时，也引入了不少大变动，所以如果你想将生产项目升级到 3.29 ，那么在「稳定」和「可控」评估上就需要更加谨慎，至少也要等到 `3.29.3` 再行动不迟。

那么，**勇士们准备好吃螃蟹了吗**？



# 参考链接 

- https://medium.com/flutter/f90c380c2317