# Flutter 3.32 发布，快来看有什么更新吧

Flutter 3.32 来了，**本次核心更新主要集中在 Framework 的控件调整上**，当然还是离不开 iOS 风格的控件优化，另外还有一些重大变更（重命名和 API 弃用），整体来看这个版本的迭代并不大，升级成本也不高，应该不会有什么大坑。



# Web



**Web 上的 hot reload 开始了实验性支持**，需要在 `flutter run -d chrome` 时增加   `--web-experimental-hot-reload` ，或者在 VS Code  的 launch.json 配置：

```yaml
"configurations": [
…
  {
    "name": "Flutter for web (hot reloadable)",
    "type": "dart",
    "request": "launch",
    "program": "lib/main.dart",
    "args": [
      "-d",
      "chrome",
      "--web-experimental-hot-reload",
    ]
  }
]
```

> DartPad 上也提供了热重载功能，并新增了 Reload 按钮，这很关键，之前的体验确实太差了。

# Framework

目前，官方正在努力尝试将 Material 里的通用功能转移到独立的 Widget，但是这肯定是一个漫长的过程，详细可见：https://github.com/flutter/flutter/issues/101479 。

## Widget

在 3.32 增加了一个新的 `Expansible`  控件，支持创建具有不同视觉主题的展开和折叠的 Widget，由一个 header 和一个 body 组成，header 始终显示，body 默认折叠状态 ，可以配置  ListView 一起使用。

另外一个就是  `RawMenuAnchor`，支持创建具有不同视觉效果的菜单，还可以独立用作无样式菜单：

![](https://img.cdn.guoshuyu.cn/image-20250521054943990.png)



## Cupertino

### Squircles

 shape 在 3.32 功能引入一个新增功能：rounded superellipse ，这种形状通常被称为“Apple squircle”，是 iOS 设计的基石，与传统的圆角矩形相比，它以其更平滑且具有更连续的曲线，其中 `CupertinoAlertDialog` 和 `CupertinoActionSheet` 都已更新为使用这个新形状 ：

![](https://img.cdn.guoshuyu.cn/0_NIsvxkNdRcbgtLdk.gif)

>  其他还有：`RoundedSuperellipseBorder`  、`ClipRSuperellipse` 、`Canvas.drawRSuperellipse, Canvas.clipRSuperellipse`, 和 `Path.addRSuperellipse` 。

需要注意的是，**目前这个能力暂时在 iOS 和 Android 上支持**，性能也有初步优化中。

### sheet 

3.32 还修复了 sheet 的固定导航栏的高度并确保内容不会出现在底部被截断的情况：

![](https://img.cdn.guoshuyu.cn/image-20250521055545128.png)

另外 ，Sheet 之前和 `PopupMenuButton` 的过渡不兼容的问题也得到修复，并且改进了工作表的圆角过渡效果：

![](https://img.cdn.guoshuyu.cn/1_iEWYohD1vd7FMpPWvK2__A.gif)

###  Navigation bars

`CupertinoSliverNavigationBar.search` 在打开或关闭搜索视图时，可以看到对应的动画的保真度改进，以及搜索的前缀和后缀图标的正确切换 ：

![](https://img.cdn.guoshuyu.cn/0_R1tsiciz-w7OdOjr.gif)

最后，使用 `CupertinoNavigationBars` 或 `CupertinoSliverNavigationBars` 的路由之间的过渡也已更新，适配支持了最新的 iOS 过渡 ：

![](https://img.cdn.guoshuyu.cn/ezgif-312c432dca9218.gif)



## Material



3.32 开始，`CarouselController` 提供了  `animateToIndex` 方法，无论是使用 `flexWeights` 的固定大小还是动态大小的项目，都可以在轮播中提供基于索引的导航：

![](https://img.cdn.guoshuyu.cn/0_nT-5bpsRVyZELaTq.gif)

TabBar 现在支持 `onHover` 和 `onFocusChange` 回调：

![](https://img.cdn.guoshuyu.cn/0_nFVGZ5PG6gTqc_F7.gif)

`SearchAnchor` 和 `SearchAnchor.bar` 现在分别包含 `viewOnOpen`  和 `onOpen` 回调 ：

![](https://img.cdn.guoshuyu.cn/0_H9mW79LCQEJBJ_i2.gif)

`CalendarDatePicker` 现在支持 `calendarDelegate `，可以在公历系统之外集成自定义日历逻辑，比如下方自定义了一其中偶数月有 21 天，奇数月有 28 天，每个月都从星期一开始：

![](https://img.cdn.guoshuyu.cn/0_uqbdwtRR2oryyhJy.gif)

其他控件调整还有：

- 向 `showDialog`、`showAdaptiveDialog` 和 `DialogRoute` 添加 `animationStyle`，从而在打开和关闭对话框时自定义动画
- `Divider`  支持 `borderRadius` 自定义分隔线的边框，尤其是在分隔线较粗的情况
- `DropdownMenu`  允许它的菜单宽度小于文本字段
- 当鼠标悬停在 `RangeSlider` 滑块上时，仅显示悬停的滑块的叠加层



## Accessibility

3.32 将语义编译时间缩短了 ~80%，在 Flutter for web 中意味着启用语义后， frame time  将减少 30% 。

> **语义树大概率未来会和 SEO 优化有关**。

而新的 `SemanticsRole` API 已集成到 `Semantics`  及其关联组件，主要是增强了允许将特定角色分配给 Widget 的整个子树：

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';


class MyCustomListWidget extends StatelessWidget {
  const MyCustomListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This example shows how to explicitly assign list and listitem roles
    // when building a custom list structure. 
    return Semantics(
      role: SemanticsRole.list,
      explicitChildNodes: true,
      child: Column( 
        children: <Widget>[
          Semantics(
            role: SemanticsRole.listItem, 
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Content of the first custom list item.'),
            ),
          ),
          Semantics(
            role: SemanticsRole.listItem, 
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Content of the second custom list item.'),
            ),
          ),
        ],
      ),
    );
  }
}
```

同时改进的还有：

- **改进了 Widget 和屏幕阅读器的用户体验：** 在各种控件（包括文本字段、焦点处理、菜单、滑块和下拉菜单）中提供更好的辅助功能支持和用户体验
- **使用语义实现更流畅的 Web 焦点导航：** 优化了启用语义时的 Web 焦点行为，显著减少了控件之间的突然焦点跳转
- **改进了 Android TalkBack 的链接识别功能**：Android TalkBack 现在可以正确识别并读出使用 `Semantics.linkUrl` 或 `url_launcher` 软件包中的 `Link` widget 定义的链接
- **Flutter for web 中的 Windows 高对比度模式支持：** 引入了对 Windows 的“强制颜色”模式（通常用于高对比度方案）的支持，开发人员可以在 `ThemeData` 中设置 `useSystemColors` ，以自动将系统颜色应用于 Flutter 主题。
- **改进的 iOS 语音控制体验：** 通过确保不可作的 Widget 不再显示不必要的标签，从而改善了 iOS 语音控制的用户体验。

## 文本输入

3.32 李文本输入进行了许多改进，比如：

- 系统文本选择上下文菜单在 iOS 上启动

-  `Autocomplete`  控件选项的布局被移植到 `OverlayPortal`

- 可以在文本字段中自定义 `onTapUpOutside` 的行为 （[#162575](https://github.com/flutter/flutter/pull/162575)）

- 开发人员现在可以生成他们想要的任何 Widget 作为 `FormField` 的错误消息，而不仅仅是错误文本 （[#162255](https://github.com/flutter/flutter/pull/162255)）。

- Flutter 中的可选文本优化 （[#162228](https://github.com/flutter/flutter/pull/162228)） ，并且在 Web 上的性能提升 （[#161682](https://github.com/flutter/flutter/pull/161682)）

## 多窗口支持的进展

今天看来多窗口有望落地，目前 PC 端功能，特别是多窗口支持，基本都是 Canonical 在负责，目前 Canonical 已经修复了当具有多个窗口时损坏的几项功能：

- Accessibility: [#164577](https://github.com/flutter/flutter/pull/164577)
- App lifecycle notifications: [#164872](https://github.com/flutter/flutter/pull/164872)
- Focus: [#164296](https://github.com/flutter/flutter/pull/164296) 
- Keyboard events: [#162131](https://github.com/flutter/flutter/pull/162131), [#163962](https://github.com/flutter/flutter/pull/163962)
- Text input: [#163847](https://github.com/flutter/flutter/pull/163847), [#164014](https://github.com/flutter/flutter/pull/164014)
- Mouse events: [#163855](https://github.com/flutter/flutter/pull/163855)

Canonical 还添加了一项功能，允许 Dart FFI 直接与 Flutter 引擎通信 （[#163430](https://github.com/flutter/flutter/issues/163430)），这也为 Flutter 未来的窗口 API 奠定了基础。

最后，Canonical 嗨在 Linux 上引入了光栅线程 （[#161879](https://github.com/flutter/flutter/pull/161879)），从而提高了帧吞吐量，确保 Flutter Linux 即使在有多个窗口时也能保持流畅。

> **未来大概率 PC 端都是由 Canonical 团队负责推进落地**。

## 桌面线程合并

Canonical 还更新了 Windows 和 macOS，从而支持 App 合并 UI 和平台线程（[#162883](https://github.com/flutter/flutter/pull/162883)、[#162935](https://github.com/flutter/flutter/pull/162935)），**从这点看桌面端也追上了移动端进程**。

合并线程可以让 App 使用 Dart FFI 与原生 API 进行直接互作，例如在 Windows 上启用了合并线程，**开发者就可以使用 Dart FFI 通过 win32 API 直接调整应用窗口的大小**
在 Windows 上，可以通过在 `wWinMain` 方法中将以下内容添加到 `windows/runner/main.cpp` 文件中来打开合并的线程：

```dart
project.set_ui_thread_policy(UIThreadPolicy::RunOnPlatformThread)
```


在 macOS 上，可以通过将以下内容添加到 `macos/Runner/Info.plist` 文件中的 `<dict>` 元素中来打开合并线程：

```dart
<key>FLTEnableMergedPlatformUIThread</key>
<true />
```


而在未来， Windows 和 macOS 将默认启用合并线程。

# iOS 

3.32 增强了 iOS 上 Flutter 的粘贴体验，对于没有自定义作的基本文本字段，**用户在粘贴其他应用的内容时将不再看到确认对话框，现在，所有 Flutter iOS 应用都默认启用该功能**。

> 请注意，如果 App 使用自定义 action（例如 context menus 的“发送电子邮件”），还暂时不支持该能力：[#140184](https://github.com/flutter/flutter/issues/140184)。

# Android

**Flutter 的 Gradle 插件已经从 Groovy 转换为 Kotlin**。

另外，现在 Flutter 可以在 Android 上使用触控笔写入文本字段，就像 Apple Pencil 手写输入在 Flutter iOS 上一样，用户可以直接在任何 Flutter 文本输入字段上开始书写，手写内容将在字段中显示为文本，但是目前尚不支持所有手势，目前只在 Android 14 及更高版本上支持，可以使用 `TextField.stylusHandwritingEnabled` 或者 `CupertinoTextField.stylusHandwritingEnabled` 禁用。



# Engine

从 3.29.3 版本开始，**在  Android API 级别 28 （Android 9） 及更早版本的设备上，Flutter 应用将使用旧版 Skia 渲染器，而 Impeller 仍然是 API 级别 29 （Android 10） 及更高版本的设备上的默认渲染器**。

另外，在 3.32  版本里，以下设备将使用 OpenGLES 而不是 Vulkan：

- [Android 模拟器 ](https://github.com/flutter/flutter/pull/162454)
- API 版本低于 31 的 MediaTek 设备
- 低于 CXT 的 PowerVR 设备
- 不支持 Vulkan 1.3 的旧版三星 XClipse GPU

最后需要注意的是，Flutter 3.27 存在许多与支持 Vulkan 的设备上的 Impeller 渲染相关的渲染错误和崩溃，这些错误和崩溃已在 3.29 及更高版本中修复，因为这些修复没有在  3.27 中 hot fix，所以强烈建议大家更新到 3.29 或更高版本。

同时，3.32 还改进了 Impeller 的文本渲染，从而让 Impeller 字形图集中的字形分辨率更高，文本动画更流畅，抖动更少，并修复了浮点计算中的舍入错误，以下是之前（上）和3.32（下）的对比：

![](https://img.cdn.guoshuyu.cn/0_yGjm9dQU4oCG5XwG.gif)

![](https://img.cdn.guoshuyu.cn/0_s1EWYhGX9j4qOWB1.gif)

另外还有各种其他保真度和性能改进，包括：

- 圆锥曲线不再近似，而是直接细分[#166165](https://github.com/flutter/flutter/pull/166165)
- 部分重绘已经过优化 [#161626](https://github.com/flutter/flutter/pull/161626)，以避免频繁的内存分配
- 通过删除多余的附件[#165137](https://github.com/flutter/flutter/pull/165137)提高了模糊速度
- 修复了文本旋转 180 度的方向 [#164958](https://github.com/flutter/flutter/issues/164958)

# DevTools 

从新的 Property Editor 工具轻松编辑 Widget 属性并阅读文档，该工具可以从 Flutter Property Editor 侧边栏面板 （[VS Code](https://docs.flutter.dev/tools/vs-code#property-editor)） 或工具窗口 （[Android Studio / IntelliJ](https://docs.flutter.dev/tools/android-studio#property-editor)） 访问：

![](https://img.cdn.guoshuyu.cn/image-20250521063128817.png)

![](https://img.cdn.guoshuyu.cn/image-20250521063136761.png)

DevTools 还进行了其他改进，包括：

- 对 Network 屏幕的新离线支持
- 修复了 review history 、inspector errors、Deep Links 工具相关的问题的错误修复
-  CPU Profiler 和 Memory 屏幕的数据改进
- 多项性能和内存改进，缩短数据加载时间并减少与内存相关的崩溃

另外还改进 Dart 分析器，添加了  “doc imports”，这是一种新的基于注释的语法，允许在文档注释中引用外部元素：

```dart
/// @docImport 'dart:async';
library;

/// Doc comments can now reference elements like
/// [Future] and [Future.value] from `dart:async`,
/// even if the library is not imported with an actual import.
class Foo {}
```

## Android Studio 中的 Gemini 对  Flutter 和 Dart 的支持

现在 AS 的 Gemini 可以为 Dart 和 Flutter 开发提供直接的支持，另外 **Dart 和 Flutter 对模型上下文协议 （MCP） 的支持即将推出**，MCP 和最近发布的 [Dart MCP SDK](https://pub.dev/packages/dart_mcp) 的支持正在积极进行中，新的 [Dart Tooling MCP Server](https://github.com/dart-lang/ai/tree/main/pkgs/dart_tooling_mcp_server) 也正在开发中，它将向 MCP 客户端（如 IDE）公开 Dart 和 Flutter 静态、运行时和生态系统工具。

这将为 Dart 和 Flutter 开发人员带来以下好处：

- 更准确、更相关的代码生成
- 对于复杂的任务，比如修复布局问题、管理依赖项，甚至解决运行时错误可以变得更佳可靠，因为 MCP 协议暴露了来自实际 Dart 和 Flutter 工具的语义信息

# Build with AI

从今天开始，Flutter 正在将 Firebase 中的 Vertex AI 发展为 Firebase AI Logic，只需一个 Flutter SDK 即可访问两个 Gemini API 提供商，从而支持能够直接从 Flutter 应用使用 Gemini 和 Imagen 模型，而无需服务器端 SDK。

> 对应  `firebase_ai` 或者 `firebase_vertexai` 包

![image-20250521063836011](https://img.cdn.guoshuyu.cn/image-20250521063836011.png)

# 重大更改和弃用

## Android accessibility 


在 Android 上，自 [API 36 起 ](https://api.flutter.dev/flutter/semantics/AnnounceSemanticsEvent-class.html#android)，accessibility announcements 事件现已弃用，相反可以通过配置 `SemanticProperties.liveRegion` 来使用“polite”隐式公告，目前在配置为不应聚焦的文本时存在一个已知限制。

## 已停止对 6 个包的支持

- `flutter_markdown`[ #162966](https://github.com/flutter/flutter/issues/162966)
- `ios_platform_images `[#162961](https://github.com/flutter/flutter/issues/162961)
- `css_colors`  [#162962](https://github.com/flutter/flutter/issues/162962)
- `palette_generator` [#162963](https://github.com/flutter/flutter/issues/162963)
- `flutter_image` [#162964](https://github.com/flutter/flutter/issues/162964)
- `flutter_adaptive_scaffold`  [#162965](https://github.com/flutter/flutter/issues/162965)

## iOS 和 macOS 最低版本

Flutter 将在下一个稳定版本中弃用对 iOS 12 和 macOS 10.14 （Mojave） 的支持，并将针对最低 iOS 13 和 macOS 10.15 （Catalina） 提供支持。

## 其他重大更改

- 弃用了 Material 中的 `ExpansionTileController`，取而代之的是 Widgets 层中新的可重用 `ExpansibleController`
- 重命名 `SelectionChangedCause.scribble` （已弃用）为 `SelectionChangedCause.stylusHandwriting` ，因为 Apple 的 Scribble 功能现在与 Android 的 Scribe 统一。
- 作为我们持续规范化 Material 主题工作的一部分，`ThemeData.indicatorColor` 已被弃用，取而代之的是 `TabBarThemeData.indicatorColor` 而 `cardTheme`、`dialogTheme` 和 `tabBarTheme` 的组件主题类型将需要分别迁移到 `CardThemeData`、`DialogThemeData` 和 `TabBarThemeData`
- 某些行为中的 `SpringDescription` 公式已得到更正

# 最后

那么，少年，你准备好吃螃蟹了吗？目前来看，这并不是一个会有什么大坑的版本。



# 原文链接

- https://medium.com/flutter/whats-new-in-flutter-3-32-40c1086bab6e