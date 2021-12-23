> 原文链接：https://medium.com/flutter/announcing-flutter-1-20-2aaf68c89c75

谷歌对 Flutter 的定位是提供一个便捷的工具包，从而在任何设备上得到出色的绘制体验，所以对于每个 release 版本，将会努力确保 Flutter 能**快速，美观，高效和开放**地支持每个平台，而在今天发布到 release 分支的 1.20 版本中，主要也是关于以上这四个方面的改进。


在**快速**这个类别中，从底层级别的渲染引擎到 Dart 语言本身，本次我们都实现了多项性能改进。

为了使开发者能够构建更加**精美**的 Flutter 应用程序，1.20 版本提供了多项 UI 增强功能，包括期待已久的:

- `autofill` 支持;
- 对 `Widget` 进行分层以支持平移和缩放的新方式;
- 新的鼠标光标支持;
- 对旧版本的 `Material Widget`（例如时间和日期选择器），以及 desktop 和 mobile 上 Flutter 应用中 About box 的全新响应式 license 页面的更新。

为了继续提高 Flutter 的工作**效率**，我们对 `Visual Studio Code` 的 Flutter 扩展进行了更新，该扩展将 `Dart DevTools` 直接带入的 IDE 中，在移动文件时会自动更新了导入语句，并提供了一组新的元数据用于构建自己的工具。

由于 Flutter 的**开放**性和出色的社区贡献者，本 stable 版包含来自全球 `359` 个贡献者的 `3,029` 个合并 **PR** 和 `5,485` 个 **closed issues**，其中包括来自 Flutter 社区的 `270` 个贡献者。

实际上，这是 Flutter release 版本中包含的最多社区贡献，特别是向这些社区贡献者表示感谢：

- CareF 的 28个 PR；
- AyushBherwani1998 的 26个PR（包括 10 个 Flutter samples 作为他的 Google Summer of Code 项目的一部分）；
- a14n 的 13个PR（其中许多用于为 Flutter 的 landing null safety）

如果没有广泛的社区贡献者团队，我们将无法持续发布 Flutter，所以非常感谢大家的支持！

Flutter 的每个新版本都会带来了更多使用的动力，实际上在 4月就有报道过 Google Play 商店中的 Flutter 应用程序数量已达到 `50,000`，每月峰值新应用程序数量为 `10,000`。

现在，仅三个月后，Google Play 中就已经有超过 `90,000` 个Flutter应用，我们在印度看到了很多这种增长，现在印度是 Flutter 开发人员的第一大区域，在过去六个月中翻了一番，这与Google 在该地区增加的投资相吻合。最后 Flutter 不能没有 Dart  ，因此很高兴看到 IEEE 报告说 Dart 自去年以来已经上升了 4 个排位，在他们跟踪的前 50 种语言中排名第 12。

## Flutter 和 Dart 的性能改进

在 Flutter 团队中，我们一直在寻找减少应用程序大小和延迟的新方法。以上一个版本为示例，此版本**修复了 [icon font tree shaking 时的工具性能问题](https://github.com/flutter/flutter/pull/55417)，[并在构建非 Web 应用程序时font tree shaking 为默认行为](https://github.com/flutter/flutter/pull/56633)**。

icon font tree shaking 会删除未在应用程序中使用的图标，从而减小尺寸。将其用于Flutter Gallery 应用程序时，我们发现它使应用程序大小减少了100kb。现在，在进行 release 版本构建时，默认情况下在移动应用程序中会出现这个行为，目前仅限 `TrueType` 字体，但在将来的版本中将取消该限制。

我们在此版本中进行的另一项性能改进是**使用预热阶段来减少动画初始显示中的锯齿**，可以在此动画中看到一个改进的示例（降低到一半速度）。

![不用和有SkSL预热的动画](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image1)

如果 Flutter 应用程序在首次运行期间出现了不稳定的动画，则 Skia Shading Language 着色器将在应用程序构建过程中提供预编译功能，从而可以使其速度提高 2 倍以上。如果想利用此高级功能，请参见 flutter.dev 上的 [SkSL 预热页面](https://flutter.dev/docs/perf/rendering/shader)。

最后，当我们针对 desktop 进行优化时，我们将继续完善对鼠标的支持。在此版本中，我们重构了鼠标点击测试系统，以提供由于性能问题而被阻止的许多体系结构优势，重构使我们能够在基于 Web 的微基准测试中将性能提高多达 `15` 倍！这意味着开发者将获得更好，更一致，更准确的命中测试，而无需放弃性能：双赢！

通过这种更好，更快，更强大的鼠标命中测试，我们增加了对鼠标光标的支持，这是 desktop 最受欢迎的功能之一。默认情况下，几个常用的小部件将显示开发者期望的光标，或者开发者可以从受支持的光标列表中指定另一个。
![Android上现有小部件上的新鼠标光标](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image2)

此版本的 Flutter 基于 2.9 版本的 Dart 构建的，它具有一个新的基于状态的 `two-pas UTF-8 `解码器，该解码器具有在 Dart VM 中优化的解码原语，部分利用了 `SIMD` 指令。UTF-8是迄今为止互联网上使用最广泛的字符编码方法，当收到较大的网络响应时，能够快速对其进行解码至关重要。在我们的UTF-8解码基准测试中，我们发现，在低端ARM设备上，英语文本的全面改进从近200％提高到中文文本的400％。

## 自动填充移动文本字段

一段时间以来，最受用户欢迎的功能之一是为 Flutter 程序中对文本自动填充在 Android 和 iOS提供支持。使用 [PR 52126](https://github.com/flutter/flutter/pull/52126)，我们很高兴地说等待已经结束：不再要求用户重新输入，操作系统已为他们收集的数据。

![自动填充](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image3)


另外你会很高兴听到我们也已经开始为 Web 添加此功能。


## 一个用于常见交互模式的新控件

此版本引入了一个新的小部件 `InteractiveViewer`。该 `InteractiveViewer` 设计用于建设普通类型的交互性到应用程序，如: 平移，缩放和拖动“N”下降甚至大小调整，其中类似这种[简单的棋盘](https://github.com/justinmc/flutter-go)。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image4)


要查看如何将集成 `InteractiveViewer` 到自己的应用程序中，请查看[API文档](https://api.flutter.dev/flutter/widgets/InteractiveViewer-class.html)，你可以在 DartPad 中使用它。另外，如果你想了解的 `InteractiveViewer` 设计和开发方法，则可以在YouTube 上看到 [Chicago Flutter on YouTube.](https://www.youtube.com/watch?v=ChFa0A72Uto)的演讲。

如果你有兴趣向 `InteractiveViewer` 启用的 Flutter 应用程序中添加新的交互，那么你可能也会很高兴听到我们在此版本中添加了更多功能来拖动“n”。具体来说，如果你想准确知道目标控件上的放置发生在哪里（Draggable对象本身始终可以使用它），现在可以使用 `DragTarget onAcceptDetails` 方法获取该信息。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image5)

请查看此样本以获取详细信息，并期待将来的发行版，该发行版还将在拖动期间提供此信息，以便`DragTarget` 可以在拖动操作期间更轻松地提供视觉更新。

## 更新了 Material Slider，RangeSlider，TimePicker 和 DatePicker

除了新的控件之外，此版本还包含许多更新的控件，包括 `Slider` 和 `RangeSlider`。有关更多信息，请参见 `Slider` 控件的新增功能。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image6)
![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image7)

`DatePicker` 已更新，包括新的紧凑型设计以及对日期范围的支持。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image8)

最后，TimePicker它具有全新的风格。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image9)

如果您想使用它，这是一个使用 [Flutter构建的有趣的 Web 演示](https://flutter-time-picker.firebaseapp.com/#/)。


### Responsive Licenses page

此版本的另一个更新是可以从中获得新的 esponsive licenses page: `AboutDialog`。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image10)

来自社区贡献者 TonicArtos 的 [PR 57588](https://github.com/flutter/flutter/pull/57588) 不仅进行了更新，以符合 Material 准则，使其看起来非常美观，而且更易于浏览，并设计为可在平板电脑和台式机上以及在手机上正常使用。谢谢 TonicArtos！由于每个 Flutter 应用程序都应显示其使用的软件包的许可证，因此使每个 Flutter 应用程序都变得更好了。


## 发布插件需要新的 pubspec.yaml 格式

当然，Flutter不仅是控件，它也是工具，此版本附带太多更新，但是，这里有一些亮点。


首先，是一项公共服务公告：如果您是 Flutter 插件的作者，那么 `pubspec.yaml` 发布插件将不再支持旧格式。如果尝试执行 `pub publish` 时会收到以下错误消息：

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image11)

旧格式不支持指定插件支持的平台，并且自 Flutter 1.12 起已弃用。现在，发布新的或更新的插件需要新的 `pubspec.yaml` 格式。

对于插件客户而言，这些工具仍然可以理解旧的 `pubspec` 格式，在未来一段时间内 `pub.dev`上所有使用旧格式的现有插件将继续与Flutter应用程序配合使用。


## 在Visual Studio Code 中预览嵌入式 Dart DevTools

此版本中最大的工具更新是 Visual Studio Code 扩展，它提供了一项新功能的预览，使得开发者能够将 Dart DevTools 屏幕直接带入编码工作区。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image12)

使用新的 `dart.previewEmbeddedDevTools` 设置启用此功能，上面的屏幕截图显示了直接嵌入到 Visual Studio Code 中的 Flutter Widget Inspector ，启用了此新设置，你可以使用状态栏上 的Dart DevTools 菜单选择嵌入的收藏页面。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image13)

此菜单允许您选择要显示的页面。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image14)
该功能仍处于预览状态，因此，如果您有任何问题，请告诉我们。（https://github.com/Dart-Code/Dart-Code/issues）

## 网络跟踪更新

Dart DevTools 的最新版本随附“网络”页面的更新版本，可启用 Web 套接字分析。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image15)

现在，“Network” 页面会将计时信息以及你的状态和内容类型等其他信息添加到应用中的 network calls  中。对详细信息UI进行了其他改进，以提供 websocket 或 http 请求中数据的概述。我们还为该页面提供了更多计划，包括 HTTP请求/响应主体和监视 gRPC 流量。

## Updating import statements on file rename

Visual Studio Code 的另一个新功能是在重命名时更新导入，当文件被移动或重命名时，它会自动更新导入语句。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image16)

该功能目前仅适用于单个文件，不适用于多个文件或文件夹，但即将推出该功能。

## Tooling metadata for every tool builder

还要提到的另一项更新是针对构建 Flutter 工具的人员，我们在 GitHub 上创建了一个新项目，以捕获和发布有关 Flutter 框架本身的元数据，它提供以下内容的机器可读数据文件：
- 当前所有Flutter小部件的[目录](https://github.com/flutter/tools_metadata/blob/master/resources/catalog/widgets.json)（395个小部件）;
- Material 和 Cupertino 颜色集的 Flutter 框架[颜色名称到颜色值的映射];(https://github.com/flutter/tools_metadata/tree/master/resources/colors)
- Material和Cupertino图标的[图标元数据](https://github.com/flutter/tools_metadata/tree/master/resources/icons)，包括图标名称和预览图标;

这与我们自己用于 Android Studio / IntelliJ 和 VS Code 扩展的元数据相同；我们认为这在构建自己的工具时可能会觉得有用。实际上，此元数据使 IntelliJ IDE 系列的功能可以显示Flutter代码中使用的颜色：

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image17)

与此相关的是IntelliJ和Android Studio中的一项新功能，该功能显示 `Color.fromARGB（）`和`Color.fromRGBO（）`的色块：

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image18)

特别感谢 GitHub 上的 dratushnyy 为 IntelliJ 中的颜色预览做出了贡献！

## Typesafe platform channels for platform interop

为了响应用户调查中插件作者的普遍需求，最近我们一直在尝试如何使 Flutter 与主机平台之间的通信对于插件和 Add-to-App 更安全更轻松。为了满足这一需求，我们创建了 `Pigeon` 这个命令行工具，该工具使用 Dart 语法在平台通道顶部生成类型安全的消息传递代码，而无需添加其他运行时依赖项。

使用Pigeon，你可以在直接调用 Dart 方法的情况下调用 Java / Objective-C / Kotlin / Swift 类方法并传递非基本数据对象，而无需在平台通道上手动匹配方法字符串和序列化参数。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-120/image19)

虽然仍然处于预发行阶段，但是 Pigeon 已经变得足够成熟，因此我们可以在 video_player 插件中使用它。如果您想对 Pigeon 进行测试以供自己使用，请参阅更新的[平台渠道文档](https://flutter.dev/docs/development/platform-integration/platform-channels#pigeon)以及[该示例项目](https://github.com/flutter/samples/tree/master/add_to_app/flutter_module_books)。

## 无法列出太多工具更新

Flutter 1.20 时间表中的工具发生了太多重大变化，因此我们无法在此处列出所有内容。但是，您可能希望自己查看更新公告：

- [VS Code扩展v3.13](https://groups.google.com/g/flutter-announce/c/TlN12RemsYw)
- [VS Code扩展v3.12](https://groups.google.com/g/flutter-announce/c/8tSufvaRJUg)
- [VS Code扩展v3.11](https://groups.google.com/g/flutter-announce/c/gM0bqO7NFA0)
- [Flutter IntelliJ插件M46发布](https://groups.google.com/g/flutter-announce/c/8C2v2ueXjts)
- [Flutter IntelliJ插件M47发布](https://groups.google.com/g/flutter-announce/c/6SF3PG_XB8g/m/6mAY7eC_AAAJ)
- [Flutter IntelliJ插件M48发布](https://groups.google.com/g/flutter-announce/c/i9NTk5o9rZQ)
- [Flutter内置的面向Flutter开发人员的新工具](https://medium.com/flutter/new-tools-for-flutter-developers-built-in-flutter-a122cb4eec86)

## 重大变化

与以往一样，我们试图将重大更改的数量保持在较低水平。以下是Flutter 1.20版本中的列表。

- [#55336](https://github.com/flutter/flutter/pull/55336) Adding `tabSemanticsLabel` to `CupertinoLocalizations` - [迁移指南PR](https://github.com/flutter/website/pull/3996)
- [#55977](https://flutter.dev/go/clip-behavior) Add `clipBehavior` to widgets with `clipRect`
- [#55998](https://groups.google.com/forum/#!searchin/flutter-announce/55998%7Csort:date/flutter-announce/yoq2VGi94q8/8pTsRL28AQAJ) Fixes the navigator pages update crashes when there is still route.
- [#56582](https://flutter.dev/docs/release/breaking-changes/cupertino-tab-bar-localizations#migration-guide) Update Tab semantics in Cupertino to be the same as Material
- [#57065](https://github.com/flutter/flutter/pull/57065) Remove deprecated child parameter for NestedScrollView’s overlap managing slivers
- [#58392](https://github.com/flutter/flutter/pull/58392) iOS mid-drag activity indicator

## Summary

希望你和我们一样对这个版本感到兴奋，从许多角度来看，这是 Flutter 迄今为止最大的发行版。随着性能的提高，新的和更新的小部件以及工具的改进，我们只能做到更突出。我们要感谢社区贡献者的数量不断增长，而且不断壮大，使每个 Flutter 版本都可以比以前的版本更大，更快，更强大。还有更多的功能，包括对空安全性的支持，新版本的 `Ads`，`Maps` 和 `WebView` 插件，以及正在进行的更多工具支持。