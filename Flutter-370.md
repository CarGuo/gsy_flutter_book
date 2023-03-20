# 2023 年第一弹， Flutter 3.7 发布啦，快来看看有什么新特性



> 核心内容原文链接： https://medium.com/flutter/whats-new-in-flutter-3-7-38cbea71133c

2023 年新春之际， Flutter 喜提了 3.7 的大版本更新，在 Flutter 3.7 中主要有**改进框架的性能，增加一些很棒的新功能，例如：创建自定义菜单栏、级联菜单、更好地支持国际化的工具、新的调试工具等等**。

另外 Flutter 3.7 还**改进了 Global selection、使用 Impeller提升渲染能力、DevTools 等功能，以及一如既往的性能优化**。

> PS ：3.7 版本包含大量，大量，大量更新内容，感觉离 4.0 不远了。

# 提升 Material 3 支持

随着以下 Widget 的迁移，Material 3 支持在 3.7 中得到了极大提升：

- `Badge`
- `BottomAppBar`
- `Filled `和 `Filled Tonal`  按键
- `SegmentedButton`
- `Checkbox`
- `Divider`
- `Menus`
- `DropdownMenu`
- `Drawer`和`NavigationDrawer`
- `ProgressIndicator`
- `Radio `  按键
- `Slider`
- `SnackBar`
- `TabBar`
- `TextFields`和`InputDecorator`
- `Banner`

要使用这些新功能只需打开 `ThemeData `  的 `useMaterial3`标志即可。

**要充分利用 M3 的特性支持，还需要完整的 M3 配色方案，可以使用新的 [theme builder](https://m3.material.io/theme-builder#/custom)  工具，或者使用构造函数的  `colorSchemeSeed` 参数生成一个`ThemeData`** ：

```dart
MaterialApp ( 
  theme : ThemeData ( 
    useMaterial3 : true, 
    colorSchemeSeed : Colors.green, 
  ), 
  // …
 );
```

> 使用这些组件，可以查看展示所有新 M3 功能的 [interactive demo](https://flutter-experimental-m3-demo.web.app/#/)

![](http://img.cdn.guoshuyu.cn/20230125_F37/image1.gif)

# 菜单栏和级联菜单

Flutter 现在可以创建菜单栏和级联 context 菜单。

**对于 macOS 可以使用 `PlatformMenuBar` 创建一个菜单栏，它定义了由 macOS 而不是 Flutter 渲染的原生菜单栏支持**。

而且，对于所有平台可以定义一个  [Material Design menu](https://m3.material.io/components/menus/overview)  ，它提供级联菜单栏 ( `MenuBar`) 或由用户界面触发的独立级联菜单( `MenuAnchor`) 。

这些菜单可完全自主定制，菜单项可以是自定义 Widget，或者是使用新的菜单项 Widget ( `MenuItemButton`, `SubmenuButton`)。

![](http://img.cdn.guoshuyu.cn/20230125_F37/image2.png)



# Impeller 预览

这里很高兴地宣布新的 [Impeller 渲染引擎](https://github.com/flutter/engine/tree/main/impeller) 已经[可以在 ](https://github.com/flutter/engine/tree/main/impeller#try-impeller-in-flutter) Stable Channel 上的 iOS 进行预览。

**Flutter 团队相信 Impeller 的性能将达到或超过大多数应用的 Skia 渲染器，并且在保真度方面，Impeller 实现几乎覆盖了少数极端下的使用场景**。

> 未来在即将发布的稳定版本中可能会让 Impeller 成为 iOS 上的默认渲染器，如果有任何问题，欢迎在 GitHub 的  [Impeller Feedback](https://github.com/flutter/flutter/issues) 上提交反馈。

虽然目前期待的结果是 iOS 上的 Impeller 可以满足几乎所有现有 Flutter 应用的渲染需求，但 API 覆盖率仍然存在一些差距：

在 [Flutter wiki ](https://github.com/flutter/flutter/wiki/Impeller#status)上列出了少量剩余的未覆盖情况，用户可能还会注意到 Skia 和 Impeller 之间在渲染中的细微视觉上存在差异，而这些细微差别可能会导致错误，所以如果有任何问题，请不要犹豫，欢迎在 Github [提出问题](https://github.com/flutter/flutter/issues)。

> 社区的贡献大大加快了 Impeller 上的进展。特别是 GitHub 用户 [ColdPaleLight](https://github.com/ColdPaleLight)、[guoguo338](https://github.com/guoguo338)、[JsouLiang](https://github.com/JsouLiang)  和 [magicianA ](https://github.com/magicianA)为该版本贡献了 291 个 Impeller 相关补丁中的 37 个（>12%）。

另外 Flutter 将继续在 Impeller 的 Vulkan 上继续推进支持（在旧设备上回退到 OpenGL），但 Android 上的 Impeller 目前还未准备好，Android 上的支持正在积极开发中，希望可以在未来的版本中分享更多关于它的信息——以及未来更多关于 desktop 和 web 上的支持

> 在 GitHub 上的 [Impeller 项目板上](https://github.com/orgs/flutter/projects/21) 可以关注进展。



# iOS 版本验证

当开发者发布 iOS 应用时， [checklist of settings to update](https://docs.flutter.dev/deployment/ios#review-xcode-project-settings)  可确保开发者的应用已准备好提交到 App Store。

![](http://img.cdn.guoshuyu.cn/20230125_F37/image3.png)

`flutter build ipa` 命令现在会验证其中一些设置，并在发布前通知开发者是否需要对应用进行更改。



# 开发工具更新

在 3.7 版本中，有几个关于新的工具和功能方面的改进。

DevTools 内存调试工具新增了三个功能选项卡，**Profile**、**Trace **和 **Diff**，它们支持所有以前支持的内存调试功能，并添加了更多功能以方便调试。

![](http://img.cdn.guoshuyu.cn/20230125_F37/image4.png)

新功能包括：

- 按 class 和 memory 类型分析应用的当前内存分配
- 调查哪些代码路径在运行时为一组 class 分配内存
- 差异内存快照以了解两个时间点之间的内存管理

> 所有这些新的内存功能都记录在 [docs.flutter.dev](https://docs.flutter.dev/development/tools/devtools/memory) 上

Performance 页面还有一些值得注意的新功能，性能页面顶部的**Frame Analysis**  提供了对所选 Flutter frame 的分析：

可能包括有关跟踪到的  frame 的 expensive 操作的建议，或有关在 Flutter 框架中检测到的 expensive 操作的警告。

![](http://img.cdn.guoshuyu.cn/20230125_F37/image5.png)

这些只是 3.7 里 DevTools 的几个亮点， 3.7 版本还包含几个错误修复和更多功能改进，包括 Inspector、Network profiler 和 CPU profiler 的一些重要错误修复。

> 如需更深入的更新列表，请查看 Flutter 3.7 中 DevTools 更改的发行说明。

# 自定义 Context 菜单

**3.7 开始可以在 Flutter 应用的任何位置创建自定义 Context 菜单，还可以使用它们来自定义内置的 Context 菜单**。

例如，开发者可以将 “发送电子邮件” 按钮添加到默认文本选择工具栏，当用户选择电子邮件地址 ([code](https://github.com/flutter/samples/blob/main/experimental/context_menus/lib/email_button_page.dart)) 时，该工具栏就会显示。

![](http://img.cdn.guoshuyu.cn/20230125_F37/image6.gif)

通过 `contextMenuBuilder `参数，该参数已添加到默认情况下显示 Context 菜单的 Widget，例如 `TextField`。

> 现在开发者可以从 `contextMenuBuilder` 返回任何想要的 Widget，包括修改默认的平台自适应的 Context 菜单。

这个新功能也适用于文本选择之外，例如创建一个 `Image`，然后在右键单击或长按时显示 “**Save**” 按钮（[code](https://github.com/flutter/samples/blob/main/experimental/context_menus/lib/image_page.dart)），通过 `ContextMenuController` 在应用的任何位置显示当前平台的默认 Context 菜单或自定义菜单。

![](http://img.cdn.guoshuyu.cn/20230125_F37/image7.gif)

> 更多可见 [Flutter  Demo  context_menus](https://github.com/flutter/samples/tree/main/experimental/context_menus)中的全套示例。

# CupertinoListSection 和 CupertinoListTile 小部件

Cupertino 新增了两个新的 Widget，`CupertinoListSection` 和`CupertinoListTile`，用于显示 iOS 风格的可滚动小部件列表。

> 它们是Material `ListView` 和 `ListTile` 的 Cupertino 版本。

| ![](http://img.cdn.guoshuyu.cn/20230125_F37/image8.png) | ![](http://img.cdn.guoshuyu.cn/20230125_F37/image9.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |

# 滚动改进

3.7 版本带来了多项 [滚动更新](https://github.com/flutter/flutter/issues?page=1&q=is%3Aissue+is%3Aclosed+closed%3A2022-07-11..2022-11-30+label%3A"f%3A+scrolling"+reason%3Acompleted)：

- 触控板交互改进
- 新的 Widget（如 `Scrollbars` 和`DraggableScrollableSheet`）
- 滚动 Context 文本选择的改进处理

> 值得注意的是， [MacOS 应用现在将通过添加新的滚动 ](https://github.com/flutter/flutter/pull/108298)physics 来体验更高的保真度以匹配桌面平台。

另外还有新的 `AnimatedGrid` 和 `SliverAnimatedGrid` 动画。

![](http://img.cdn.guoshuyu.cn/20230125_F37/image10.gif)

最后，本次还[修复了](https://github.com/flutter/flutter/pull/108706)几个滚动 Widget 的构造函数中的问题，例如`ListView` ：

> 在 Flutter 框架的 NNBD 迁移过程中，原本 `itemBuilder` 允许用户按需提供 widgets 类型，但是在迁移到  `IndexedWidgetBuilder` 时不允许用户返回 null。

这意味着 `itemBuilder` 不能再返回 `null`，而本次跟新该设定已经通过 `NullableIndexedWidgetBuilder` 修复。

![](http://img.cdn.guoshuyu.cn/20230125_F37/image11.png)



# 国际化工具和文档

国际化支持已经全面改进，3.7 版本通过完全重写了 `gen-l10n `工具来实现支持：

- 描述性的语法错误
- 涉及嵌套/多个复数、选择和占位符的复杂消息

![](http://img.cdn.guoshuyu.cn/20230125_F37/image12.png)

> 有关更多信息，可参阅更新的 [国际化 Flutter 应用](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)页面。



# 全局选择改进

`SelectionArea` 现在支持键盘选择，开发者可以使用键盘快捷键扩展现有选择，例如 `shift+right`。

![](http://img.cdn.guoshuyu.cn/20230125_F37/image13.png)



# 后台 isolates

3.7 开始 [Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)  可以从任何 `Isolate`  invoked ， 以前用户只能从 Flutter 提供的主 Isolate 调用平台通道，而现在 [Plugins](https://docs.flutter.dev/development/packages-and-plugins/developing-packages)  或 [Add-to-app](https://docs.flutter.dev/development/add-to-app) 能更好地使用 Isolate 和主机平台代码进行交互。

> 有关更多信息，请查看在 flutter.dev 上的 [platform-specific code](https://docs.flutter.dev/development/platform-integration/platform-channels)  和 [Introducing background isolate channels](https://medium.com/flutter/introducing-background-isolate-channels-7a299609cad8)。



# 文本放大镜

3.7 开始在 Android 和 iOS 上选择文本时出现的放大镜。

对于所有带有文本选择的应用，这是开箱即用的能力，但如果你想禁用或自定义它，请参阅 [magnifierConfiguration](https://master-api.flutter.dev/flutter/material/TextField/magnifierConfiguration.html) 属性。

| ![](http://img.cdn.guoshuyu.cn/20230125_F37/image14.gif) | ![](http://img.cdn.guoshuyu.cn/20230125_F37/image15.gif) |
| -------------------------------------------------------- | -------------------------------------------------------- |



# 插件的快速迁移

由于 Apple 现在专注于使用 Swift 作为他们的 APIs ，我们希望开发参考资料以帮助 Flutter 插件开发人员使用 Swift 迁移或创建新插件。

> [quick_actions](https://pub.dev/packages/quick_actions) 插件已从 Objective-C  迁移到 Swift，可用作最佳实践的演示。如果有兴趣成为帮助我们迁移插件的一员，请参阅wiki[的 Swift 迁移部分](https://github.com/flutter/flutter/wiki/Contributing-to-Plugins-and-Packages#swift-migration-for-1p-plugins)。

**适用于 iOS 开发人员的资源**，我们为 iOS 开发者发布了一些新资源，包括：

- [面向 SwiftUI 开发者的 Flutter](https://docs.flutter.dev/get-started/flutter-for/ios-devs?tab=swiftui)
- [面向 Swift 开发人员的 Dart](https://dart.dev/guides/language/coming-from/swift-to-dart)
- [Swift 开发者的 Flutter 并发](https://docs.flutter.dev/resources/dart-swift-concurrency)
- [将 Flutter 添加到现有的 SwiftUI 应用](https://docs.flutter.dev/development/add-to-app/ios/add-flutter-screen)
- [使用 Flutter 创建 flavors ](https://docs.flutter.dev/deployment/flavors)（适用于 Android 和 iOS）



# Bitcode deprecation

[从 Xcode 14 开始，watchOS 和 tvOS 应用不再需要 bitcode，App Store 也不再接受来自 Xcode 14 的 bitcode 提交。](https://developer.apple.com/documentation/xcode-release-notes/xcode-14-release-notes)

> 因此，Flutter 已删除对 bitcode 的支持。

默认情况下，Flutter 应用不启用位码，我们预计这不会影响许多开发人员。

但是如果你在 Xcode 项目中手动启用了 bitcode，请在升级到 Xcode 14 后立即禁用它。

你可以通过打开 `ios/Runner.xcworkspace` 并将 **Enable Bitcode** 设置为 **No** 来实现，Add-to-app  的开发人员可以在宿主 Xcode 项目中禁用它。

![](http://img.cdn.guoshuyu.cn/20230125_F37/image16.png)



# iOS PlatformView BackdropFilter

我们添加了在有 blurred 效果的 Flutter  Widget 下方呈现时使原生 iOS 视图模糊的功能，并且 `UiKitView` 现在可以包装在 `BackdropFilter`。

![](http://img.cdn.guoshuyu.cn/20230125_F37/image17.png)

> 有关详细信息，请参考 [iOS PlatformView BackdropFilter ](http://flutter.dev/go/ios-platformview-backdrop-filter-blur)设计文档。



# 内存管理

3.7 版本对内存管理进行了一些改进，具体有：

- 减少垃圾收集暂停导致的卡顿
- 由于分配速度和后台 GC 线程而降低 CPU 利用率
- 减少内存占用

作为一个例子，Flutter 扩展了现有的手动释放支持某些 `dart:ui`  对象。

> 以前，Native 资源由 Flutter 引擎持有，直到 Dart VM 垃圾回收 Dart 对象。

通过对用户应用的分析和我们自己的基准测试，我们确定该策略不足以避免不合时宜的 GC 和过度使用内存。

**因此，在此版本中，Flutter 引擎添加了显式释放用于 `Vertices` 、`Paragraph` 和 `ImageShader  ` 对象持有的原生资源的 API** 。

![](http://img.cdn.guoshuyu.cn/20230125_F37/image18.png)



> 在迁移到的 Flutter 框架基准测试中，这些改进将 90% 的帧构建时间减少了 30% 以上，最终用户将体验到更流畅的动画和更少的卡顿。

此外，Flutter 引擎不再[将 GPU 图像的大小注册到 Dart VM](](https://github.com/flutter/engine/pull/35473))，这些图像在不再需要时会由框架手动释放。

沿着类似的思路，现在 Flutter 引擎的策略是仅向 Dart VM 报告支持 `dart:ui`  的 Dart 对象部分的 Native 的  [shallow size](https://github.com/flutter/engine/pull/35813) 。

![](http://img.cdn.guoshuyu.cn/20230125_F37/image19.png)

> 在基准测试中，本次更改消除了在 Widget 创建 GPU 驻留图像时构建帧的同步 GC 。

在此版本中，Flutter Engine 还更好地利用了有关 Flutter 应用状态的信息来动态更新 Dart VM。

> Flutter 现在使用 Dart VM 的 [RAIL](https://web.dev/rail/) Style [API ](https://github.com/dart-lang/sdk/commit/c6a1eb1b61844b2d733f9e2f4c7754f1920325d7)在路由转换动画期间进入 [低延迟模式](https://github.com/flutter/flutter/pull/110600)。

在低延迟模式下，Dart VM 的内存分配器会倾向堆增长而不是垃圾收集，以避免因 GC 暂停而中断过渡动画。

> 虽然类似更改不会带来任何显着的性能改进，但 Flutter 团队计划在未来的版本中扩展此模型的使用，以进一步消除不合时宜的 GC 暂停。

此外，本次还 修复了  Flutter 引擎空闲时通知 Dart VM 的 逻辑[错误](https://github.com/flutter/engine/pull/37737)，修复这些错误可以防止与 GC 相关的卡顿。

最后，对于  add-to-app 的 Flutter 应用，当 Flutter 视图不再显示时 Flutter [会通知 Dart VM  ](https://github.com/flutter/engine/pull/37539)引擎，当没有 Flutter 视图可见时，Dart VM 为与视图关联的对象触发  GC ，此更改可以减少了 Flutter 的内存占用。



# 停用 macOS 10.11 到 10.13

Flutter 不再支持 macOS 10.11 和 10.12 版本，3.7 版本发布后，也取消对 10.13 的支持，这可以并将帮助团队大大简化代码库。

这也意味着在 3.7 版本及以后版本中针对稳定的 Flutter SDK 构建的应用将不再适用于这些版本，并且 Flutter 支持的最低 macOS 版本增加到 10.14 Mojave。

因此，由于 Flutter 支持的所有 iOS 和 macOS 版本都包含 Metal 支持，OpenGL 后端已从 iOS 和 macOS 嵌入器中删除，删除这些后，Flutter 引擎的压缩大小减少了大约 100KB。



# toImageSync

3.7 版本在 `dart:ui` 里 [添加了](https://github.com/flutter/engine/pull/33736) `Picture.toImageSync` 和 `Scene.toImageSync` 方法。

> 类似于异步 `Picture.toImage`，从 `Picture` 转化为 `Image` 时会从   `Scene.toImage.Picture.toImageSync ` 同步返回一个句柄，并在后台异步进行 `Image` 光栅化。

**当 GPU 上下文可用时，图像将保持为 GPU 常驻状态**，这意味着会比  `toImage` 具有更快的渲染速度（生成的图像也可以保留在 GPU 中，但这种优化尚未在该场景中实现。）

新的`toImageSync`API 支持用例，例如：

- 快速实现光栅化成本高昂的图片，以便在多个帧中重复使用。
- 对图片应用多通道滤镜。
- 应用自定义着色器。

例如，Flutter 框架 [现在使用该 API](https://github.com/flutter/flutter/pull/106621) 来提高 Android 上页面转换的性能，这几乎将帧光栅化时间减半，减少卡顿，并允许动画在支持这些刷新率的设备上达到 90/120fps。

# 自定义 shader 改进

3.7 版本包含了对 Flutter 对自定义片段着色器支持的大量改进。

**Flutter SDK 现在包含一个着色器编译器，可将 `pubspec.yaml` 文件中列出的 GLSL 着色器编译为目标平台的正确特定格式**。

此外，自定义着色器现在可以热加载，iOS 上的 Skia 和 Impeller 后端现在也支持自定义着色器。

> [更多可见 docs.flutter.dev 上编写和使用自定义片段着色器](https://docs.flutter.dev/development/ui/advanced/shaders)文档，以及 pub.dev 上的 `flutter_shaders` 包。

# 字体热重载

以前向 `pubspec.yaml` 文件添加新字体需要重新运行应用才能看到它们，这个行为这与其他可以热加载的 asset 不同。

现在，对字体清单的更改（包括添加新字体）可以热加载到应用中。

# 减少 iOS 设备上的动画卡顿

感谢 [luckysmg ](https://github.com/luckysmg)的开源贡献改进减少了 iOS 上的动画卡顿，特别是手势期间在主线程上[添加虚拟](https://github.com/flutter/engine/pull/35592)  `CADisplayLink`  对象，现在会强制以最大刷新率进行刷新。

此外，[键盘动画]((https://github.com/flutter/engine/pull/34871))现在将刷新率设置为 `CADisplayLink` ，与 Flutter 引擎动画使用的刷新率相同。

由于这些变化，用户应该注意到 120Hz iOS 设备上的动画更加一致流畅。



# 最后个人感想

以上就是来自 Flutter 团队关于 Flutter 3.7 的主要更新内容，可以看到本次更新内容相当丰富：

- 最显眼的莫过于 Impeller 在 iOS 可以预览，性能提升未来可期
- 关于菜单相关的更新，也极大丰富了 Flutter 在编辑和本次选择中的疲弱态势
- 全局选择的改进和文本放大镜也进一步完善了 Flutter 文本操作的生态
- 性能、内存优化老生常谈，特别是 iOS 上的优化
- 开发工具进一步提升

当然本次大版本更新设计的内容范围很广，可以预见会有各式各样的坑在等大家，特别本次更新很多涉及底层 Framework 部分，所以按照惯例，等三个小版本会更稳。