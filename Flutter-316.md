# Flutter 3.16 发布，快来看有什么更新吧

> 参考原文：https://medium.com/flutter/whats-new-in-flutter-3-16-dba6cb1015d1

Flutter 又又又发布新季度更新啦，同时随着而来的还有 Dart 3.2，本次 3.16 开始 Material 3 会成为新的默认主题，另外 Android 也迎来了 Impeller 的预览支持，另外还有 [Flutter Casual Games Toolkit ](https://medium.com/flutter/building-your-next-casual-game-with-flutter-716ef457e440)  的重大更新。

> **最重要的是，Impeller 的 Android 支持来了。**

# Framework

## Material  default

现在，从 3.16 开始，`MaterialApp` 里的 `useMaterial3` 默认会是 true，如果你还希望使用 M2，可以使用  `useMaterial3: false` 来使用 M2 的主题效果，**不过 Material 2 相关的东西未来会被弃用并删除**。

另外在 M3 上其实有的 Widget  和 M2 并不是完全兼容，所以更新到 3.16  后一些 UI 你可以需要做手动迁移适配，例如  [NavigationBar](https://api.flutter.dev/flutter/material/NavigationBar-class.html) 的 UI 效果。

> 更多迁移问题可见：https://github.com/flutter/flutter/issues/91605 ，另外通过  https://flutter.github.io/samples/material_3.html 你可以比较两种主题下的不同效果。

M3 下的主题主要由 `ThemeData.colorScheme` 和 `ThemeData.textTheme` 来决定，创建 Material 3 配色首选是使用 `ColorScheme.fromSeed()` ，另外也可以通过  `ColorScheme.fromImageProvider` 来从图像下获取配色方案支持。

> 木已成舟，建议大家及早适配。

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image1.gif)

另外对于 M3  motion 的改进还包括添加 `Easing` 和 `Durations` 类，而 Material 2 的 curves 现在被重命名，会包含 “legacy” 的警告，表示它最终将被弃用和删除。( [#129942](https://github.com/flutter/flutter/pull/129942) )

> 简单来说就是，新增加了 motion.dart 来替代老的  [curves.dart#L26 ](https://github.com/flutter/flutter/blob/main/packages/flutter/lib/src/material/curves.dart#L26)。

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image2.png)

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image3.png)

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image4.gif)

## 在编辑菜单中添加附加选项

在 iOS 上，用户现在可以选择文本并启动提供多种标准服务的共享菜单，在 3.16 的版本中本次添加了查找、搜索和共享选项。

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image5.gif)

## 增加 TextScaler 

为了支持 Android 14 的[非线性字体缩放功能](https://blog.google/products/android/android-14/#:~:text=Also%2C you can improve readability,rate than smaller font size.)来帮助视力障碍，新 `TextScaler` 类替换了`Text.textScaleFactor ` 属性。( [#128522](https://github.com/flutter/flutter/pull/128522) )

## SelectionArea 更新

`SelectionArea`  现在支持鼠标单击、双击以及长按触摸设备相关的原生手势，默认情况下，这些新手势可通过`SelectionArea ` 和 `SelectableRegion` 来支持：

- 单击：在单击的位置设置折叠选区
- 双击：选择单击位置的单词
- 双击 + 拖动：扩展单词块中的选择范围

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image6.gif)



- 长按+拖动：扩展单词块中的选择范围。

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image7.gif)

## 对焦点 Widget 进行操作的菜单项

3.16 开始增加清除使用菜单项时焦点更改的功能： `FocusManager`  的  `applyFocusChangesIfNeeded` 现在支持恢复菜单焦点 ，当用户单击菜单项时，焦点将返回到打开菜单之前具有焦点的项目。( [#130536](https://github.com/flutter/flutter/pull/130536) )

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image8.gif)

## iOS、macOS 的菜单项快捷方式自动重新排序

Mac 平台上的 Flutter 应用现在可以对菜单中的快捷方式修饰符进行排序，以遵循 Apple 人机界面指南。( [#129309](https://github.com/flutter/flutter/pull/129309) )

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image9.png)

## MatrixTransition 动画

新的 `MatrixTransition` 允许在创建动画过渡时进行矩阵变换，根据当前动画值，可以提供 child widget 的矩阵变换。( [#131084](https://github.com/flutter/flutter/pull/131084) )

```dart

class MatrixTransitionExampleApp extends StatelessWidget {
  const MatrixTransitionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MatrixTransitionExample(),
    );
  }
}

class MatrixTransitionExample extends StatefulWidget {
  const MatrixTransitionExample({super.key});

  @override
  State<MatrixTransitionExample> createState() =>
      _MatrixTransitionExampleState();
}

class _MatrixTransitionExampleState extends State<MatrixTransitionExample>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: MatrixTransition(
          animation: _animation,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: FlutterLogo(size: 150.0),
          ),
          onTransform: (double value) {
            return Matrix4.identity()
              ..setEntry(3, 2, 0.004)
              ..rotateY(pi * 2.0 * value);
          },
        ),
      ),
    );
  }
}

```



![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image10.gif)



## PaintPattern 添加到 flutter_test

在 `flutter_test `包中，新 `PaintPattern` 类允许开发者验证 `CustomPainter`  和 `Decoration` （在单元测试中使用）等 Widget 对画布进行的绘制调用。

以前需要一个文件来验证是否绘制了正确的颜色和矩形，但现在可以使用 `PaintPattern` ，例如以下示例验证了 `MyWidget `在画布上绘制了一个圆圈：

```dart
expect(
  find.byType(MyWidget),
  paints
    ..circle(
      x: 10,
      y: 10,
      radius: 20,
      color: const Color(0xFFF44336),
    ),
);
// Multiple paint calls can even be chained together.
expect(
  find.byType(MyWidget),
  paints
    ..circle(
      x: 10,
      y: 10,
      radius: 20,
      color: const Color(0xFFF44336),
    ),
    ..image(
      image: MyImage,
      x: 20,
      y: 20,
    ),
);
```

## 滚动更新

继 Flutter 3.13 中首次发布二维滚动基础之后，3.16 带来了更多功能和完善， 2D foundation  现在支持 `KeepAlive`  Widget，以及默认焦点遍历和隐式滚动。

3.13 版本发布后不久，[two_Dimension_scrollables](https://pub.dev/packages/two_dimensional_scrollables) 包就发布了，该包由 Flutter 团队维护，包含第一个构建在该框架基础上的 2D 滚动 widget - `TableView`，目前已添加了丰富的装饰和样式支持以及其他错误修复。

# Engine

## Impeller Android

在 3.16 版本中，Android 上的 Impeller 已准备好在 stable 上提供预览，该预览版包括有关支持 Vulkan 的设备上的 Impeller 特性。

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image11.png)

> 图表显示了过去一年中在 Impeller 的 Vulkan 后端上运行的 Flutter Gallery 转换性能基准测试改进，用户将观察到卡顿更少且稳态帧速率更高。

目前 Impeller 在没有 Vulkan 支持的设备上会表现不佳，单在未来几个月内还会将 Impeller 的 OpenGL 后端功能继续完善。

Flutter 开发者现在可以在支持 Vulkan 的 Android 设备上试用 Impeller，方法是将标志 `— enable-impeller 传递`给 `flutter run`，或者将以下设置添加到 `AndroidManiest.xml`文件中的 `<application>`：

```xml
<meta-data
  android:name="io.flutter.embedding.android.EnableImpeller"
  android:value="true" />
```

> 通常，Impeller 在运行 Android API  29 或更高版本的 64 位操作系统的设备上会使用 Vulkan 。

目前 Android Vulkan 预览版已知问题有：

- platform view 尚未实现支持，包含 platform view 的框架性能会有些差。
- 自定义着色器还未实现。

因为 Android 硬件生态系统更加多样化，预计 Android 的预览期将比 iOS 更长，这是无法避免的，另外，Impeller 的 Vulkan 在“调试”构建中启用了超出 Skia 使用的功能的额外调试功能，并且这些功能会产生额外的运行时开销，**所以有关 Impeller 性能的反馈来自最好来自 profile 或发布版本**。

## Impeller 性能, 保真度和稳定性

3.16 还对 Impeller 中的文本性能进行了多项改进，这对 Android 和 iOS 都是同样的。特别是改进了 Impeller 字形图集的管理，以及在引擎的 UI 和光栅线程之间划分文本工作负载的方式，所以 3.16 上用户会注意到文本繁重工作负载中的卡顿现象减少。

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image12.png)

> 图表显示，在使用 Impeller 的 iPhone 11 上进行的一项文本密集型基准测试中平均帧光栅化时间（以毫秒为单位）有所减少。

本次 3.16 已经对 flutter/engine 存储库做出了 209 个 Impeller 相关承诺，解决了 217 个问题，其中包括 42 个有关保真度、稳定性或性能问题的用户报告。

## Engine 性能

为了在具有异构多处理功能的移动设备上支持更好的性能，本次 [修改了](https://github.com/flutter/engine/pull/45673) Engine 对性能敏感的线程（例如 UI 和光栅线程）与设备更强大的内核的支持。

本次修改在某些情况下改进非常显着，预计在 Android 上的 Skia 和 Impeller 进行本次更改后，用户将注意到卡顿现象减少，而在 iOS 设备上，这种影响不太明显，因为在 iOS 设备上，功能较强大的内核与功能较弱的内核之间的差异较小。

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image13.png)



## Impeller 性能 overlay

在之前的版本中，Flutter 的[性能 overlay ](https://docs.flutter.dev/perf/ui-performance#the-performance-overlay)功能并未与 Impeller 一起发布，本次版本修复了该问题。现在在启用 Impeller 的情况下，性能 overlay 可以正确显示。

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image14.png)

## 现在可以正确显示 Dithering

在 3.16 版本中， `Paint.enableDithering` 属性默认设置为 true，不再支持开发人员配置，在此之前，渐变在所有设备上都有很多色带，并且在使用某些动画时看起来也很奇怪，而解决方案是使渐变不透明，并使用 Skia 的Dithering 渐变。

> 而为了简化迁移过程， Impeller 永远不会支持除梯度之外的任何内容的 Dithering。

- 3.16 之前

  ![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image15.png)

- 3.16 之后

  ![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image16.png)

# 游戏

## Flutter 游戏工具包

在过去的几年里 Flutter 发布了数以万计的游戏，从简单但有趣的谜题到更复杂的街机游戏，其中包括：

-  Etermax 的[Trivia Crack](https://triviacrack.com/)
- Lotum 的[4 Pics 1 Word](https://flutter.dev/showcase/lotum)（猜词游戏）
- Dong Digital 的 [Brick Mania](https://play.google.com/store/apps/details?id=net.countrymania.brick&hl=en)（街机游戏）
- Onrizon 的[StopotS](https://play.google.com/store/apps/details?id=com.gartic.StopotS&hl=en)（类别游戏）
-  Flutter for I/O 的 [复古弹球游戏](https://pinball.flutter.dev/)
-  [PUBG](https://flutter.dev/showcase/pubg-mobile) 移动版在社交和菜单屏幕中使用 Flutter
- ····

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image17.gif)

为了帮助游戏开发者提高工作效率，Flutter 今天推出了休闲游戏工具包的重大更新，它是一系列新资源的集合，可帮助开发者从概念转向推出更多特定类型的游戏模板，例如纸牌游戏、无尽跑酷游戏，以及 Play 游戏服务、应用内购买、广告、成就、crashlytics 等服务集成和多人游戏支持。

> 要了解更多信息，可以查看 https://medium.com/flutter/building-your-next-casual-game-with-flutter-716ef457e440



# Web

## Chrome DevTools 上的 Flutter 时间轴事件

Flutter 时间轴事件现在显示在 Chrome DevTools 的性能面板中。( [#130132](https://github.com/flutter/flutter/issues/130132) )

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image18.png)

# Android

## 鼠标滚轮支持

为了适配鼠标在平板电脑或可折叠设备的效果，3.16 版本中  flutter 支持对鼠标滚动与 Android 设备上的滚动速度相匹配。( [44724](https://github.com/flutter/engine/pull/44724) )

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image19.gif)

## 预测性后退导航

Android 14 版本包含预测性后退手势功能，3.16 更新为 Flutter 带来了预测性返回手势。

```dart
PopScope(
  canPop: _myCondition,
  child: ...
),

PopScope(
  canPop: true,
  onPopInvoked (bool didPop) {
    _myHandleOnPopMethod();
  },
  child: ...
),

NavigatorPopHandler(
  onPop: () => _nestedNavigatorKey.currentState!.pop(),
  child: Navigator(
    key: _nestedNavigatorKey,
    …
  ),
)
···
```



![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image20.gif)

# iOS系统

## 应用扩展

Flutter 现在可以支持针对某些 [iOS 应用扩展](https://developer.apple.com/app-extensions/)，这意味着可以使用 Flutter  Widget 为某些类型的 iOS 应用绘制 UI，当然这并不适用于所有类型的应用扩展，因为 API（例如主屏幕空间）或内存可能存在限制。

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image21.png)

由于应用扩展的内存限制，仅建议使用 Flutter 为内存限制大于 100MB 的扩展类型构建应用扩展 UI。

此外，Flutter 在调试模式下会使用额外的内存，因此当用于构建扩展 UI 时，Flutter 并不完全支持在物理设备上以调试模式运行应用扩展。

> 详细可见： https://docs.flutter.dev/platform-integration/ios/app-extensions



# 生态

目前 [Flutter  Favorite](https://docs.flutter.dev/packages-and-plugins/favorites) 已经重新启动，在本周期中 Flutter 生态系统委员会将 [Flame](https://pub.dev/packages/flame)、[flutter_animate](https://pub.dev/packages/flutter_animate)、[flutter_rust_bridge](https://pub.dev/packages/flutter_rust_bridge)、[Riverpod](https://pub.dev/packages/riverpod)、[video_player](https://pub.dev/packages/video_player)、[macos_ui](https://pub.dev/packages/macos_ui) 和 [fpdart](https://pub.dev/packages/fpdart) 包指定为新的 Flutter Favorite。

## Camera X 改进

在 3.10 稳定版本中， Flutter 相机插件中添加了对 Camera X 的初步支持，而 CameraX 解决了该插件的 Camera 2 实现中存在的许多问题。

```yaml
dependency: 
 camera:  ^0.10.4 
 camera_android_camerax:  ^0.5.0
```

## macOS 视频播放器

[video_player](https://pub.dev/packages/video_player) 中添加了 macOS 支持。

# 开发工具

## 开发工具扩展

新的 [DevTools 扩展框架](https://pub.dev/packages/devtools_extensions) 支持：

- 包作者为其直接在 DevTools 中显示的包构建自定义工具。
- 软件包作者可以编写强大的工具，利用 DevTools 中的现有框架和实用程序。
- 使用 DevTools 调试应用以访问特定于其用例的工具的 Dart 和 Flutter 开发人员（由应用的依赖项以及哪些依赖项提供 DevTools 扩展决定）。

感谢 [Provider](https://pub.dev/packages/provider)、[Drift](https://pub.dev/packages/drift) 和 [Patrol](https://pub.dev/packages/patrol) 的软件包作者，这个生态系统已经建立起来，现在就可以使用这些软件包的 DevTools 扩展！

| ![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image22.png) | ![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image23.png) | ![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image24.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |

## 开发工具更新

此版本的 DevTools 的一些亮点包括：

- 添加了对 DevTools 扩展的支持
- 添加了一个新的“主”屏幕，显示连接的应用的摘要

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image25.png)

其他改进包括：

- 整体表现
- 热重启 robustness
- 文本选择和复制行为
-  viewer polish 网络分析响应

## VS Code UI 的可发现性

感谢 Flutter 社区成员 [DanTup](https://github.com/DanTup) ，Flutter VS Code 扩展现在拥有一个 Flutter 侧边栏，可让轻松访问：

- 打开 Flutter DevTools 屏幕
- 查看活动的调试会话
- 查看可用设备
- 创建新项目
- 热重载并重启
- 运行 Flutter Doctor -v
- ····

![](http://img.cdn.guoshuyu.cn/20231116_Flutter316/image26.png)

# 最后

本次更新的还是属于比较“低调”的更新，最大的变化应该就是 M3 的默认主题和 Android Impeller ，其他的其实影响并不是很大，其中 M3 主题还是建议大家及早适配，因为 M2 的控件效果未来确实会慢慢剔除。

另外可以看到本次更新的核心还是集中在 Android 和 iOS ，PC 更新节奏看起来受到“某些影响”后慢了不少？同时关于 Jetbrains 的插件更新也没体现，核心 IDE 的资源都投入到 VSCode 了，只能说且行且珍惜。

好了，勇敢的少年，开始吃螃蟹了。