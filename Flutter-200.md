今天很高兴地宣布 Flutter 2 的发布，距离Flutter 1.0 的发布已经两年多了，但是在很短的时间内， Flutter 已经关闭了 24,541 issues，并合并了 765 个贡献者的 17,039个PR。

自去年9月 Flutter 1.22 发布以来，Flutter 已经关闭了 5807 issues 并合并了 298位贡献者的 4091 个PR。


### Web

截止到今天，Flutter 的 Web 支持已经从 Beta 过渡到稳定 Channel 。在此初始稳定版本中，Flutter 在 Web 平台下将代码的可重用性提高到另一个层次，因此现在当开发者创建Flutter 应用程序时，Web 只是该应用程序的另一个可支持的目标设备。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image1)

通过利用 Web 平台的众多优势，Flutter 为构建丰富的交互式Web应用程序奠定了基础，Flutter 主要专注于性能和渲染保真度的改进，除了 HTML renderer 之外，我们还添加了一个新的基于 CanvasKit 的渲染器，另外我们还添加了特定于 Web 的功能，例如 [Link Widget](https://pub.dev/documentation/url_launcher/latest/link/Link-class.html) 以确保在浏览器中运行的应用感觉像Web应用。

> 你可以在Flutter的 Web 支持博客文章中找到有关此稳定版本的更多详细信息: https://medium.com/flutter/web-post-d6b84e83b425

### Sound Null Safety

空安全声明是 Dart 语言的重要补充，它通过区分可空类型和非可空类型进一步增强了类型系统，这使开发人员能够防止 null 错误崩溃。

通过将空检查合并到类型系统中，开发者可以在开发过程中捕获这些错误，从而防止生产崩溃。从 Flutter 2 开始，包含 Dart 2.12 的稳定版完全支持空安全声明。

> 有关更多详细信息，请参见 Dart 2.12博客文章：https://medium.com/dartlang/announcing-dart-2-12-499a6e689c87

pub.dev 包存储库已经发布了 1,000 多个空安全软件包，其中包括 Dart，Flutter，Firebase 和 Material 团队的数百个软件包。

> 如果你是软件包作者，请查看迁移指南并考虑立即进行迁移： https://dart.dev/null-safety/migration-guide

### Desktop

在此版本中，Flutter的桌面支持已经发布在稳定 Channel，这意味着 Flutter 已经准备好让你尝试一下使用它开发桌面应用，当然你可以将其视为“beta snapshot”，以预览将于今年晚些时候发布的最终稳定版本。

> PS ：所以这是为了赶 KPI 才发布的么？

为了使 Flutter 桌面达到发布的质量，Flutter 从大小上进行了改进，从确保文本编辑像在每个受支持的平台上的原生体验一样开始，包括诸如：[text selection pivot points](https://github.com/flutter/flutter/pull/71756)以及 [a keyboard event once it’s been handled](https://github.com/flutter/flutter/issues/33521)的能力。

在处理完键盘事件后，在鼠标输入端现在可以立即开始使用高精度定点设备进行拖动，而不必等待处理触摸输入时所需的延迟。

此外内置的上下文菜单已添加到 Materia l和 Cupertino 设计语言的 `TextField` 和 `TextFormField` 控件中。

最后，[grab handles have been added](https://github.com/flutter/flutter/pull/74299) 已经被添加到 `ReorderableListView` 控件中。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image2)



`ReorderableListView` 现在具有可拖住的功能，可通过鼠标轻松拖放，
在移动项目中 `ReorderableListView` 要求用户长按才能启动拖动，这哥场景在移动设备上适用，但是很少有台式机用户会想到用鼠标长按某个项目来移动它，因此此版本还包括适用于鼠标或触摸输入的移动方式。另外常用功能的另一项改进是更新的滚动条，该滚动条可以正确显示桌面形状因素。

 ![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image3)


此版本还包括一个更新的 `Scrollbar` 控件，该控件在桌面环境中非常使用，包括拖动预览、单击轨道以上下滚动页面以及在鼠标悬停在鼠标的任何部分上时显示轨道的功能。

此外由于 `Scrollbar` 是使用新 `ScrollbarTheme` 主题，因此开发者可以设置其样式以使其与应用程序的外观和风格相匹配。

对于其他特定于桌面的功能，此版本还启用了 Flutter 应用程序的命令行参数处理功能，以便可以使用诸如 Windows File Explorer 中的文件双击之类的简单操作来打开应用程序中的文件。

另外 Flutter 在致力于在应用在 Windows 和 macOS 的上调整大小变得更加流畅，并为国际用户启用IME（输入法编辑器）。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image4)

> 此外，我们还提供了更新的文档，介绍了开始准备将桌面应用程序部署到特定操作系统商店时需要执行的操作。https://flutter.dev/desktop#distribution


在尝试使用 Flutter 桌面 Beta 时，开发者可以通过按预期方式切换到 Beta 通道并根据flutter.dev 上的指导为目标平台设置配置标志来访问它。此外，我们还制作了稳定通道上可用的 beta 快照。

如果开发者使用 `flutter config` 启用某个桌面配置设置（例如 `enable-macos-desktop`），则可以尝试桌面支持的 beta 功能，而不必经历漫长的过程如删除 Flutter SDK 后才能转移到 beta 频道等，这非常适合尝试一下或将桌面支持用作简单的 “Flutter Emulator.”。


但是，如果您选择停留在 Stable Channel 上以访问桌面 Beta，则不会像切换到Beta或dev频道那样快地获得新功能或错误修复,因此如果你正在积极地针对 Windows，macOS 或 Linux，我们建议您切换到可更快提供更新的渠道。


> 当 Flutter 桌面的第一个完整的生产版本快完全发布时，我们知道还有更多工作要做，包括对与本机顶级菜单集成的支持，更接近各个平台的文本编辑体验以及可访问性支持，以及常规的


### New iOS features

此版本带来了与 iOS 相关的178个PR合并，包括 [#23495](https://github.com/flutter/engine/pull/23495)（将状态恢复带到iOS），[#67781](https://github.com/flutter/flutter/pull/67781)（它满足了长期存在的直接从命令行构建IPA而无需打开Xcode的要求），以及 [#69809](https://github.com/flutter/flutter/pull/69809)，更新了CocoaPods版本以匹配最新工具。

此外，Cupertino 设计语言实现中还添加了一些 iOS 控件，如新的`CupertinoSearchTextField` 提供了 iOS 搜索栏 UI。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image5)


`CupertinoFormSection`，`CupertinoFormRow` 和 `CupertinoTextFormFieldRow` 控件更容易满足 iOS 的设计风格。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image6)

除了适用于iOS的功能外，在着色器和动画方面，我们还将继续 iOS 和 Flutter 的性能改进，iOS仍然是 Flutter 的主要平台，我们将继续努力带来重要的新功能和性能改进。

### New widgets: Autocomplete and ScaffoldMessenger

此版本的 Flutter 附带了两个新控件： `AutocompleteCore` 和 `ScaffoldMessenger`。

`AutocompleteCore` 表示将自动完成功能纳入 Flutter 应用程序所需的基本
功能。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image7)

> 自动完成是 Flutter 经常需要的功能，如果对完整功能的设计感到好奇，请查看自动完成设计文档。 https://docs.google.com/document/d/1fV4FDNdcza1ITU7hlgweCDUZdWyCqd-rjz_J7K2KkfY/


`ScaffoldMessenger` 用来处理许多与 `SnackBar` 相关的问题，包括能够轻松创建`SnackBar` 以响应 `AppBar` 动作；创建 `SnackBars` 以在 `Scaffold` 过渡之间持久存在的能力；能够在 `SnackBars` 完成时显示 `SnackBars`的能力，即使用户已导航到具有其他 `Scaffold` 的页面，也将执行异步操作。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image8)


所有这些优点可以从现在开始使用几行代码来显示 SnackBars ：

```
final messenger = ScaffoldMessenger.of(context);
messenger.showSnackBar(SnackBar(content: Text(‘I can fly.’)));

```

### Multiple Flutter instances with Add-to-App


从与许多 Flutter 开发人员的交谈中我们了解到，许多人没有使用 Flutter 开发全新应用程序的想法，但他们可以通过将 Flutter 添加到现有的 iOS 和 Android 应用程序中来利用 Flutter。

此功能称为 [Add-to-App](https://flutter.dev/docs/development/add-to-app)，是在两个移动平台上重用 Flutter 代码同时仍保留现有本机代码库的绝佳方法。但是在此之前我们有时会听到，不清楚如何将第一个页面集成到 Flutter 中。

将 Flutter 和本机交织在一起会使得导航状态难以维护，并且在视图级别集成多个 Flutter 会占用大量内存。

过去其他 Flutter 实例的存储成本与第一个实例相同，在Flutter 2 中，我们将创建额外的Flutter 引擎的静态内存成本降低了约 99％，每个实例约为 180kB。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image9)


支持此功能的新 API 可以在 beta 通道上预览，并在 flutter.dev 上记录了一系列演示此新模式的示例项目，通过此更改，我们不再犹豫建议在本机应用程序中创建Flutter引擎的多个实例。


### Flutter Fix

每当任何框架成熟并使用越来越多的代码库聚集用户时，随着时间的推移，趋势就是避免对框架API进行任何更改，以避免破坏越来越多的代码行。

Flutter 2 拥有超过 500,000 个Flutter开发人员，涉及的平台数量越来越多，因此它很快就面临了这样的问题。但是为了使我们能够随着时间的推移不断改进 Flutter，我们希望能够对 API 进行重大更改。问题是如何在不中断开发人员的情况下继续改进Flutter API？

我们的答案是 Flutter Fix：（http://flutter.dev/docs/development/tools/flutter-fix）

Flutter Fix 是事物的组合。首先，`dartCLI ` 工具有一个新的命令行选项，名为 dart fix ，它知道在哪里可以查找已弃用的 API 列表以及如何使用这些 API 更新代码。其次它是可用修补程序本身的列表，最后它是针对 VS Code，IntelliJ 和 Android Studio IDE 的更新的 Flutter 扩展集，它们知道哪些改变是属于公开相同的内容，展示可用的修复程序列表，如带小划线的快速修复程序，可帮助您单击鼠标来更改代码。

举例来说，假设您的应用中包含以下代码行：

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image10)

由于不推荐使用此构造函数的参数，因此应将其替换为以下内容：

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image11)


即使你熟悉的 Flutter 中所有被弃用的内容，但在代码中必须进行的更改数量也就越大，应用所有修补程序的难度就越大，并且更容易出错。

人类在这类重复性任务上并不擅长。但是计算机很擅长；通过执行以下命令，就可以看到我们如何在整个项目中进行的所有修复：

```
$ dart fix --dry-run
```

如果您想批量应用它们，可以轻松地这样做：

```
 dart fix --apply
```

或者，如果您想在自己喜欢的IDE中以交互方式应用这些修补程序，也可以这样做：

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image12)

多年来我们一直在将旧的API标记为已弃用，但是现在有了关于何时删除实际已弃用的API的政策，Flutter 2 是我们第一次这样做。

即使我们尚未捕获所有已弃用的API作为数据来提供 Flutter Fix，但我们仍将继续从先前已弃用的 API 中添加更多信息，并将在未来的重大更改中继续这样做。

我们的目标是尽最大努力使 Flutter 的 API 达到最佳状态，同时还要使您的代码保持最新。

### Flutter DevTools

为了清楚说明 DevTools 是用于调试Flutter应用程序的工具，我们在调试 Flutter 应用程序时将其重命名为 Flutter DevTools 。此外我们还做了很多工作，以使其达到 Flutter 2的生产质量。

在您启动 DevTools 之前也可以帮助开发者解决问题的新功能是：Android Studio，IntelliJ 或 Visual Studio Code 能够在出现常见异常时发出通知，并提供将其引入DevTools 中以帮助您调试的功能它。

例如，以下内容显示您的应用程序中已引发溢出异常，该异常会在 Visual Studio Code 中弹出一个选项，用于调试DevTools中的问题。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image13)

按下该按钮可打开出现问题控件上的 DevTools 中的 Flutter Inspector，因此可以对其进行修复。

今天我们仅针对布局溢出异常执行此操作，但我们的计划是针对所有常见异常提供这种处理，DevTools可以解决这些异常。

一旦运行了 DevTools，选项卡上的新错误标记将帮助开发者跟踪应用程序中的特定问题。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image14)

DevTools 的另一个新功能是能够轻松查看分辨率比显示的图像高的图像，这有助于跟踪过多的应用程序大小和内存使用情况。要启用此功能，请在 Flutter Inspector 中启用“反转超大图像”。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image15)

现在，当开发者显示分辨率明显大于其显示尺寸的图像时，该图像将上下颠倒显示，以便在开发者的应用中轻松查找。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image16)

此外，根据大众的需求，除了在 Flutter Inspector 的“布局资源管理器”中显示有关灵活布局的详细信息外，我们还添加了显示固定布局的功能，使开发者能够调试各种布局。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image17)

这还不是全部，这只是Flutter DevTools 2中更多新功能的摘要：
- 在 Flutter 框架图中添加了平均 FPS 信息并提高了可用性；
- 用红色错误标签在网络事件探查器中调出失败的网络请求。
- 更快的新内存视图图表，更小且更易于使用，其中包括用于描述特定时间活动的新悬浮卡。
- 将搜索和过滤添加到“日志记录”选项卡。
- 在启动DevTools之前跟踪日志，因此启动时可以查看完整的日志历史记录。
- 将“性能”视图重命名为“ CPU Profiler”，以使其更清楚地提供什么功能。
- 向 CPU Profiler 火焰图添加了时序网格。
- 将“时间轴”视图重命名为“性能”，以便更清楚地了解其提供的功能。

### Android Studio / IntelliJ扩展

用于 IntelliJ 系列 IDE 的 Flutter 插件也为 Flutter 2 提供了许多新功能，首先有一个新的项目向导，它与 IntelliJ 中的新向导样式匹配。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image18)

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image19)

另外如果正在 Linux 上使用 IntelliJ 或 Android Studio 对从 Snap Store 安装的Flutter SDK 进行编程，则 Flutter 快照路径已添加到已知 SDK 路径列表中，这使Flutter 快照的用户可以更轻松地在“设置”中配置 Flutter SDK。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image20)

### Visual Studio代码扩展

Visual Studio Code 的 Flutter 扩展也对 Flutter 2 进行了改进，从许多测试增强功能开始，包括重新运行仅失败的测试的功能。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image21)

经过两年的开发，对 Dart 的LSP（语言服务器协议）支持现已作为默认方式提供给 Dart 分析器，以将其集成到 Flutter 扩展的 Visual Studio Code 中。

LSP 支持对 Flutter 开发进行了许多改进，包括能够在当前Dart文件中应用某种类型的所有修复程序，并使代码完成生成完整的函数调用（包括括号和必需的参数）的功能。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image22)

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image23)

LSP 的支持不仅限于Dart，它还支持 pubspec.yaml 和 analysis_options.yaml 文件中的代码完成。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image24)


### DartPad updated to support Flutter 2

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image25)

现在，开发者可以尝试使用 Flutter 的新的空安全版本，而无需离开自己喜欢的浏览器。

### Ecosystem updates

Flutter 的开发经验不仅包含框架和工具，还包括其他内容，它还包括适用于 Flutter 应用程序的各种软件包和插件。

自上一次 Flutter 稳定版本发布以来，该领域也发生了很多事情。例如，在 `camera` 和`video_player` 插件之间已合并了将近30个PR，以大大提高两者的质量。

另外，如果你是一个 `Firebase` 的用户，我们很高兴地宣布最流行的插件质量已经得到了新的提升，包括空安全的支持，以及全套的支持 Android，iOS，Web，和 MacOS，这些插件包括：

- Core
- Authentication
- Cloud Firestore
- Cloud Functions
- Cloud Messaging
- Cloud Storage
- Crashlytics

另外，如果您正在寻找应用程序的崩溃报告，则可能需要考虑 Sentry，该公司已经发布了适用于Flutter应用程序的新SDK：https://blog.sentry.io/2021/03/03/with-flutter-and-sentry-you-can-put-all-your-eggs-in-one-repo/ 。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image26)

借助Sentry的Flutter SDK，可以实时收到在 Android，iOS或本机平台上发生的错误的通知。

此外，如果还没有看到 Flutter Community 的 “plus” 插件，则需要将其签出。

他们分叉了 Flutter 团队最初开发的许多受欢迎的插件，并添加了 null 安全支持，对其他平台的支持和一整套全新的文档，以及开始修复 flutter/plugins 存储库中的适当问题，该插件包括以下内容：

- Android Alarm+
- Android Intent+
- Battery+
- Connectivity+
- Device Info+
- Network Info+
- Package Info+
- Sensors+
- Share+

> http://plus.fluttercommunity.dev/

此时与 Flutter 兼容的软件包和插件集的数量超过 15,000，这会使得很开发者难找到优质的的软件包和插件。

因此，我们会发布发布点数（静态分析得分），受欢迎程度，喜欢度，并且，对于特别高的质量，会发布那些特别标记为 Flutter Favorite 的包装，为了及时应对 Flutter 2，我们在收藏夹列表中添加了几个新软件包：

- animated_text_kit
- bottom_navy_bar
- chopper
- font_awesome_flutter
- flutter_local_notifications
- just_audio


最后但并非最不重要的一点是，对于对软件包的是否适用于 Flutter 的最新版本感兴趣的软件包作者或软件包用户，您将需要访问 Codemagic 的新 pub.green 网站。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-200/image27)

Codemagic 新的 pub.green 网站显示了最新 Flutter 版本与顶级软件包的兼容性，
pub.green 网站测试了 pub.dev 上可用的 Flutter 和 Dart 软件包与不同Flutter版本的兼容性。

> 详细可见：https://blog.codemagic.io/pub-green/

### Breaking Changes

我们对 Flutter 2 进行了以下重大更改，其中许多可以使用 dart fix 命令或所选 IDE 中的快速修复程序自动缓解：

- [#61366](https://github.com/flutter/flutter/pull/61366) Continue the clipBehavior breaking change。
- [#66700](https://github.com/flutter/flutter/pull/66700) 默认 `FittedBox`的 `clipBehavior` 为无。
- [#68905](https://github.com/flutter/flutter/pull/68905) 从 `Cupertino` 颜色分辨率 API 删除 nullOk 参数
- [#69808](https://github.com/flutter/flutter/pull/69808) 从 `Scaffold.of` 和 `ScaffoldMessenger.of` 删除 nullOk 参数
- [#68910](https://github.com/flutter/flutter/pull/68910) 从 `Router.of ` 中删除 nullOk 参数，并使其返回不可为空的值
- [#68911](https://github.com/flutter/flutter/pull/68911) 添加  `maybeLocaleOf` 到本地化
- [#68736](https://github.com/flutter/flutter/pull/68736) 在 `Media.queryOf` 删除 nullOK
- [#68917](https://github.com/flutter/flutter/pull/68917) 从 `Focus.of` 、 `FocusTraversalOrder.of` 和 `FocusTraversalGroup.of` 中删除 nullOk 参数
- [#68921](https://github.com/flutter/flutter/pull/68921) 从 `Shortcuts.of` ，`Actions.find` 和 `Actions.handler` 中删除 nullOk 参数
- [#68925](https://github.com/flutter/flutter/pull/68925) 从`AnimatedList.of` 和 `SliverAnimatedList.of` 中删除nullOk参数
- [#69620](https://github.com/flutter/flutter/pull/69620) 从 `BuildContex` 中删不推荐使用的方法
- [#70726](https://github.com/flutter/flutter/pull/70726) 从 `Navigator.of` 中删除 nullOk 参数，并添加 `Navigator.maybeOft`
- [#72017](https://github.com/flutter/flutter/pull/72017) 删除不推荐使用的`CupertinoTextThemeData.brightness`
- [#72395](https://github.com/flutter/flutter/pull/72395) 从 `HoverEvent` 中删除不建议使用的 `PointerEnterEvent`，`PointerExitEvent` 。
- [#72532](https://github.com/flutter/flutter/pull/72532) 删除不建议使用的`showDialog.child`
- [#72890](https://github.com/flutter/flutter/pull/72890) 删除不推荐使用的`Scaffold.resizeToAvoidBottomPadding`
- [#72893](https://github.com/flutter/flutter/pull/) 删除不推荐使用的`WidgetsBinding`.[`deferFirstFrameReport`，`allowFirstFrameReport`]
- [#72901](https://github.com/flutter/flutter/pull/#72901) 删除不推荐使用的 `StatefulElement.inheritFromElement`
- [#72903](https://github.com/flutter/flutter/pull/#72903) 删除不推荐使用的 `Element` 方法
- [#73604](https://github.com/flutter/flutter/pull/73604) 删除不建议使用的 `CupertinoDialog`
- [#73745](https://github.com/flutter/flutter/pull/73745) 从  [CupertinoSliver] `NavigationBar` 删除不推荐使用的 `actionForegroundColor`
- [73746](https://github.com/flutter/flutter/pull/#73746) 删除不赞成使用的 `ButtonTheme.bar`
- [#73747](https://github.com/flutter/flutter/pull/73747) 删除 span deprecations 
- [#73748](https://github.com/flutter/flutter/pull/73748) 删除弃用的 `RenderView.scheduleInitialFrame`
- [#73749](https://github.com/flutter/flutter/pull/73749) 删除不赞成使用的 `Layer.findAll`
- [#75657](https://github.com/flutter/flutter/pull/75657) 从 `Localizations.localeOf` 删除残留的 nullOk 参数
- [#74680](https://github.com/flutter/flutter/pull/74680) 从`Actions.invoke`  删除 nullOk ，添加 `Actions.maybeInvoke` .