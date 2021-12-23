> 原文链接 https://medium.com/flutter/whats-new-in-flutter-2-5-6f080c3f3dc

**Flutter 2.5 是 Flutter 版本历史上排名第二的大版本更新**，该版本：

- 关闭了 4600 个 issues；
- 合并了 252 contributors 和 216 reviewers 的 3932 个 PR；

回顾过去一年，可以看到有 1337 位 contributors 创建了 21,072 个 PR 这样庞大的数据，其中有15,172 个被合并。

事实上该版本依然是对性能和开发工具进行了改进，同时还有增加许多新功能，包括：

- 对 Android 的全屏支持、更多 Material You（也称为 v3）支持；
- 更新文本编辑功能以支持可切换的键盘快捷键；
- Widget Inspector 可查阅更多详细信息；
- Visual Studio Code 项目中对添加依赖项增加新的支持；
- IntelliJ/Android Studio 中新增测试运行获取覆盖率信息；
- 一个全新的应用程序模板，为 Flutter 应用程序提供更好的开发基础；


## 性能：iOS 着色器预热、异步任务、GC 和消息传递

[#25644](https://github.com/flutter/engine/pull/25644) 中的第一个 PR 就是**用于离线训练运行 Metal 着色器预编译**，如基准测试所示，它将最坏情况的帧光栅化时间减少了 2/3 秒，将第 99 个百分位帧减少了一半。

然而着色器预热只是卡顿的来源之一，在**之前的版本处理来自网络、文件系统、插件或其他 isolate 的异步事件都可能会中断动画**，这是另一个卡顿的来源。


所以 [#25789](https://github.com/flutter/engine/pull/25789) 改进了调度策略，在此版本 isolate 的 UI 事件循环里，帧处理现在优先于处理其他异步事件，从而在测试中消除了此类的卡顿。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image1)


另一个导致卡顿的原因是**垃圾收集器 (GC) 暂停 UI 线程以回收内存**。

以前某些图像的内存在响应 Dart VM 的 GC 执行时会延迟回收，作为早期版本中的解决方法，Flutter 引擎会通过 Dart VM 的 GC 回收暗示图像内存可以回收，这在理论上可以实现了更及时的内存回收。

不幸的是这也导致了太多的主要 GC，并且有时仍然无法足够快地回收内存，以避免内存受限设备上的低内存情况，而**在这个版本中未使用的图像的内存被急切地回收**（[#26219](https://github.com/flutter/engine/pull/26219)、[#82883](https://github.com/flutter/flutter/pull/82883)、[#84740](https://github.com/flutter/flutter/pull/84740)），大大减少了 GC。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image2)

例如在一项测试用例中，**播放 20 秒动画 GIF 从需要 400 多次 GC 变为只需要 4 次**，更少的主要 GC 意味着涉及图像出现和消失的动画将减少卡顿，并消耗更少的 CPU 和功率。

Flutter 2.5 的另一个性能改进是在 **Dart 和 Objective-C/Swift (iOS) 或 Dart 和 Java/Kotlin (Android) 之间发送消息时的延迟。**

通常作为[调整](https://docs.google.com/document/d/1oNLxJr_ZqjENVhF94-PqxsGPx0qGXx-pRJxXL6LSagc/edit#heading=h.9gabvat7tlxf) 消息频道的一部分，从消息编解码器中删除不必要的副本可将延迟减少高达 50% ，当然具体取决于消息大小和设备（[#25988](https://github.com/flutter/engine/pull/25988)，[#26331](https://github.com/flutter/engine/pull/26331)）。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image3)

> 你可以在此链接获取到更多关于平台通道性能的信息： https://medium.com/flutter/improving-platform-channel-performance-in-flutter-e5b4e5df04af

## Dart 2.14：格式、语言特性、发布和 linting 开箱即用

此版本的 Flutter 和 Dart 2.14 一起发布。

[新版本的 Dart](https://medium.com/@mit.mit/announcing-dart-2-14-b48b9bb2fb67) 带有新的格式，使[级联](https://dart.dev/guides/language/language-tour#cascade-notation) 更加清晰，**新的 pub 支持忽略文件，以及新的语言功能，包括三重移位运算符的回归**。

**此外 Dart 2.14 创建了一组标准的 lint，在新的 Dart 和 Flutter 项目之间共享，开箱即用**。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image4)

开发者不仅会在创建新的 Dart 或 Flutter 项目时获得这些 lint，而且只需几个步骤就可以将相同的分析添加到现有应用程序中。

> 合并迁移lint：https://flutter.dev/docs/release/breaking-changes/flutter-lints-package#migration-guide
>
> 有关这些 lint 的详细信息、新语言功能等，请查看 https://medium.com/dartlang/announcing-dart-2-13-c6d547b57067 

## Framework：Android 全屏、Material You & 文本编辑快捷方式

从 [#81303](https://github.com/flutter/flutter/pull/81303) 开始, [我们修复了 Android 一系列与全屏模式相关的问题](https://github.com/flutter/flutter/pull/81303)，此更改还添加了一种在其他模式下收听全屏更改的方法。

> 例如用户与应用互动时，当系统 UI 返回时，**开发人员现在可以编写代码在返回全屏时执行其他操作**。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image5)


> *新的 Android 全屏模式：普通模式（左）、边到边模式（中）、带有自定义 SystemUIOverlayStyle 的边到边（右）*


在此版本中，我们对新 Material You（又名 v3）的规范增加了支持，**包括对浮动操作按钮大小和主题的更新**（[#86441](https://github.com/flutter/flutter/pull/86441)），在`MaterialState.scrolledUnder` 可以使用 Demo 中的示例代码查看的新状态 PR 式例 ( [#79999](https://github.com/flutter/flutter/pull/79999) )。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image6)


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image7)

> *新的 MaterialState.scrolledUnder 状态在起作用*

另一个改进是**添加了 scroll metrics notifications**（[#85221](https://github.com/flutter/flutter/pull/85221)、[#85499](https://github.com/flutter/flutter/pull/85499)），即使用户没有滚动，它也会提供可滚动区域的通知，例如下面显示了 `ListView` 根据的基础大小适当地出现或消失滚动条：

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image8)

在这种情况下不必编写任何代码，但如果想捕获 `ScrollMetricNotification` 更改，则可以通过此监听来完成。

> 特别感谢社区贡献者[xu-baoolin](https://github.com/xu-baolin)，他为此付出了努力并提出了一个很好的解决方案。


另一个出色的社区贡献是为 `ScaffoldMessenger` ， 你可能还记得 Flutter 2.0 开始 `ScaffoldMessenger` 作为一个更强大的方式来显示 `SnackBars` ， 在屏幕的底部为用户提供通知，而在 **Flutter 2.5 中，现在可以在 `Scaffold` 的顶部添加一个横幅**，该横幅会一直保持到用户关闭它为止。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image9)

应用程序可以通过调用以下 `showMaterialBanner` 方法来获得此行为 `ScaffoldMessenger` ：

```dart
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('The MaterialBanner is below'),
        ),
        body: Center(
          child: ElevatedButton(
            child: const Text('Show MaterialBanner'),
            onPressed: () => ScaffoldMessenger.of(context).showMaterialBanner(
              MaterialBanner(
                content: const Text('Hello, I am a Material Banner'),
                leading: const Icon(Icons.info),
                backgroundColor: Colors.yellow,
                actions: [
                  TextButton(
                    child: const Text('Dismiss'),
                    onPressed: () => ScaffoldMessenger.of(context)
                        .hideCurrentMaterialBanner(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
```

[Material 指南规定](https://material.io/components/banners#usage) 开发者的应用[横幅](https://material.io/components/banners#usage)一次只能显示一个，因此如果你调用多次 `showMaterialBanner`，`ScaffoldMessenger` 它将维护一个队列，在前一个横幅已被关闭之后，再显示一个新横幅。

> 感谢 [Calamity210](https://github.com/Calamity210) 对 Flutter 中的 Material 支持做出了如此出色的补充！

在此版本中，我们添加了**文本编辑键盘快捷键可覆盖的功能** [#85381](https://github.com/flutter/flutter/pull/85381)，这是在 Flutter 2.0 及其新的文本编辑功能的基础上进一步构建，例如文本选择以及能够在处理键盘事件后停止它的传播。

> 如果您希望 **Ctrl-A** 执行一些自定义操作而不是选择所有文本。

`DefaultTextEditingShortcuts` 类包含每个平台上受支持的键盘快捷键列表，如果开发者想覆盖任何内容，可以使用 Flutter 的现有 `Shortcuts` 将任何快捷方式重新映射到现有或自定义意图。

> API 参考: https://api.flutter.dev/flutter/widgets/DefaultTextEditingShortcuts-class.html

## 插件：相机、图像选择器和 plus 插件

另一个具有有很多改进的插件是[相机插件](https://pub.dev/packages/camera)：

-   [#3795](https://github.com/flutter/plugins/pull/3795) [相机] android-rework 第 1 部分：支持 Android 相机功能的基类
-   [#3796](https://github.com/flutter/plugins/pull/3796) [相机] android-rework 第 2 部分：Android 自动对焦功能
-   [#3797](https://github.com/flutter/plugins/pull/3797) [camera] android-rework part 3：Android曝光相关功能
-   [#3798](https://github.com/flutter/plugins/pull/3798) [相机] android-rework 第 4 部分：Android 闪光和变焦功能
-   [#3799](https://github.com/flutter/plugins/pull/3799) [相机] android-rework 第 5 部分：Android FPS 范围、分辨率和传感器方向功能
-   [#4039](https://github.com/flutter/plugins/pull/4039) [相机] android-rework 第 6 部分：Android 曝光和焦点功能
-   [#4052](https://github.com/flutter/plugins/pull/4052) [camera] android-rework part 7：Android降噪功能
-   [#4054](https://github.com/flutter/plugins/pull/4054) [相机] android-rework 第 8 部分：最终实现的支持模块
-   [#4010](https://github.com/flutter/plugins/pull/4010) [camera] 在 iOS 上不触发设备方向
-   [#4158](https://github.com/flutter/plugins/pull/4158) [相机] 修复坐标旋转以在 iOS 上设置焦点和曝光点
-   [#4197](https://github.com/flutter/plugins/pull/4197) [相机] 修复相机预览并不总是在方向改变时重建
-   [#3992](https://github.com/flutter/plugins/pull/3992) [camera] 设置不受支持的 FocusMode 时防止崩溃
-   [#4151](https://github.com/flutter/plugins/pull/4151) [camera] 引入camera_web包

[image_picker 插件](https://pub.dev/packages/image_picker) 也做了很多工作，专注于端到端的相机体验：

-   [#3898](https://github.com/flutter/plugins/pull/3898) [image_picker] 图像选择器修复相机设备
-   [#3956](https://github.com/flutter/plugins/pull/3956) [image_picker] 将相机捕获的存储位置更改为 Android 上的内部缓存，以符合新的 Google Play 存储要求
-   [#4001](https://github.com/flutter/plugins/pull/4001) [image_picker] 删除了对相机权限的冗余请求
-   [#4019](https://github.com/flutter/plugins/pull/4019) [image_picker] 当相机是 source 时修复旋转

这项工作改进了 Android 的相机和 image_picker 插件的功能和稳健性。

此外你会注意到 [摄像头插件](https://pub.dev/packages/camera_web) 的早期版本可用于网络支持 ( [#4151](https://github.com/flutter/plugins/pull/4151) )。

此预览为在 Web 上查看相机预览、拍照、使用闪光灯和缩放控件提供基本支持，它目前还不是被[认可的插件](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin)，因此您需要[明确添加它](https://pub.dev/packages/camera_web/install)以在才能在 web 中使用。

> 详细内容: https://pub.dev/packages/camera_web/install

在此版本的 Flutter 中，Flutter 团队的每个相应插件现在都带有一个类似 [电池](https://pub.dev/packages/battery) 的建议：


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image10)

此外，由于这些插件不再被积极维护，它们不再被标记为 Flutter 最喜欢的插件，我们建议使用以下插件的 plus 版本：


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image11)

## Flutter DevTools：性能、Widget 检查器和 Polish

首先最重要的是 DevTools 中增加利用引擎更新的支持（[#26205](https://github.com/flutter/engine/pull/26205)、[#26233](https://github.com/flutter/engine/pull/26233)、[#26237](https://github.com/flutter/engine/pull/26237)、[#26970](https://github.com/flutter/engine/pull/26970)、[#27074](https://github.com/flutter/engine/pull/27074)、[#26617](https://github.com/flutter/engine/pull/26617)）。

其中一组更新使 **Flutter 能够更好地将跟踪事件与特定框架相关联**，这有助于开发人员确定框架可能超出预算的原因。

可以在 DevTools Frames 图表中看到这一点，该图表已被重建为“实时”，可以在应用程序呈现时填充在此图表中，从此图表中选择一个帧导航到该帧的时间线事件：


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image12)

Flutter 引擎现在还可以识别时间线中的着色器编译事件，Flutter DevTools 使用这些事件来帮助诊断应用程序中的着色器编译卡顿。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image13)

借助这项新功能，DevTools 会检测何时因着色器编译丢失帧，以便可以解决卡顿问题。

在 `flutter run` 时与 `--purge-persistent-cache` 标志一起使用，这会清除缓存以确保重现用户在 “首次运行” 或 “重新打开” (iOS) 体验中看到的环境。

> 此功能仍在开发中，如果有任何问题，可以查阅：https://b.corp.google.com/issues/new?component=775375&template=1369639

此外跟踪应用程序中的 CPU 性能问题时，可能会被来自 Dart 和 Flutter 库或引擎本机代码的分析数据淹没，如果想关闭其中任何一个以专注于您自己的代码，您可以**使用新的 CPU Profiler 功能 [#3236](https://github.com/flutter/devtools/pull/3236) 来实现，该功能可以从这些来源中隐藏分析器信息**。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image14)

对于没有过滤掉的任何类别，它们现在已经进行了颜色编码（[#3310](https://github.com/flutter/devtools/pull/3310)、[#3324](https://github.com/flutter/devtools/pull/3324)），以便可以轻松查看 **CPU 帧图表来自系统的哪些部分**。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image15)

> 彩色框架图，用于识别应用中的应用、原生、Dart 和 Flutter 代码活动

性能并不时调试的唯一因素，此版本的 DevTools 附带了对 Widget Inspector 的更新，**允许将鼠标悬停在 Widget 时评估对象、视图属性、小部件状态等**。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image16)

而当选择一个 Widget 时，它会自动填充在新的小部件检查器控制台中，这样就可以在其中浏览 Widget 的属性。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image17)

**在断点处暂停时还可以从控制台计算表达式**。

除了新功能外 Widget Inspector 还进行了翻新，为了让 DevTools 成为了解和调试 Flutter 应用程序的更有用，我们与芬兰的一家创意技术机构[Codemate](https://codemate.com/)合作进行了一些更新。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image18)

在此屏幕截图中可以看到以下更改：


-   **更好地传达调试切换按钮的作用**——这些按钮具有新图标、面向任务的标签，以及描述它们的作用和何时使用它们的丰富工具提示，每个工具提示进一步链接到该功能的详细文档。

-   **更容易扫描和定位感兴趣的 Widgets**——Flutter 框架中常用的 Widget 现在在检查器左侧的 Widget 树视图中显示图标，它们根据类别进一步进行颜色编码，例如布局 Widget 显示为蓝色，而内容Widget 显示为绿色。此外每个文本 Widget 现在显示其内容的预览。

-   **对齐布局资源管理器和小部件树的配色方案**- 现在可以更轻松地从布局资源管理器和 Widget 树中识别相同的 Widget。例如屏幕截图中的“列” Widget 位于布局浏览器中的蓝色背景上，并且在 Widget 树视图中具有蓝色图标。

## IntelliJ/Android Studio：集成测试、测试覆盖率和图标预览


Flutter 的 IntelliJ/Android Studio 插件在此版本中也进行了许多改进，首先是运行集成测试的能力 ( [#5459](https://github.com/flutter/flutter-intellij/pull/5459) )。

集成测试是在设备上运行的整个应用程序测试，位于 integration_test 目录中，并使用与`testWidgets()` 单元测试相同的功能。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image19)

要将集成测试添加到项目，请 [按照 flutter.dev 上的说明进行操作](https://flutter.dev/docs/testing/integration-tests)，要将测试与 IntelliJ 或 Android Studio 连接，请添加启动集成测试的运行配置并连接设备以供测试使用，运行配置可以让开发者运行测试，包括设置断点、步进等。

此外，Flutter 最新的 IJ/AS 插件允许查看单元测试和集成测试运行的覆盖率信息，可以从“调试”按钮旁边的工具栏按钮访问它：

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image20)

覆盖信息在编辑器的装订线中使用红色和绿色条显示，在这个例子中第 9-13 行被测试，但第 3 和 4 行没有被测试。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image21)

最新版本还包括预览来自 pub.dev 包中使用的图标的新功能，这些包是围绕 TrueType 字体文件（[#5504](https://github.com/flutter/flutter-intellij/pull/5504)、[#5595](https://github.com/flutter/flutter-intellij/pull/5595)、[#5677](https://github.com/flutter/flutter-intellij/pull/5677)、[#5704](https://github.com/flutter/flutter-intellij/pull/5704)）构建的，就像 Material 和 Cupertino 图标支持预览一样。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image22)

要启用图标预览，您需要告诉插件您正在使用哪些软件包，settings/preferences 中有一个新的文本字段：

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image23)


请注意，如屏幕截图中的示例代码所示，此设置仅适用于在类中定义为静态常量的图标，它不适用于表达式，例如 `LineIcons.addressBook()` or `LineIcons.values['code']` 。

## Visual Studio Code：依赖项、Fix All 和 Test Runner

Flutter 的 Visual Studio Code 插件也在此版本中得到了改进，两个新命令 “Dart: Add Dependency” and “Dart: Add Dev Dependency” ([#3306](https://github.com/Dart-Code/Dart-Code/issues/3306), [#3474](https://github.com/Dart-Code/Dart-Code/issues/3474))。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image24)

这些命令提供的功能类似于[Jeroen Meijer 的 Pubspec Assist 插件](https://marketplace.visualstudio.com/items?itemName=jeroen-meijer.pubspec-assist)，新命令开箱即用，并提供定期从 pub.dev 获取的包类型过滤列表。

开发者可能还对适用于 Dart 文件的“Fix All”命令（[#3445](https://github.com/Dart-Code/Dart-Code/issues/3445)、[#3469](https://github.com/Dart-Code/Dart-Code/issues/3469)）感兴趣，并且可以一步修复所有与[dart fix](https://dart.dev/tools/dart-fix)相同的问题。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image25)

这也可以通过添加 `source.fixAll` 到 `editor.codeActionsOnSave` 的 VS Code 设置来设置为在保存时运行，或者想尝试预览功能，可以启用该 `dart.previewVsCodeTestRunner` 设置并查看通过新的 Visual Studio Code 测试运行程序运行的 Dart 和 Flutter 测试。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image26)

Visual Studio Code 测试运行器看起来与当前的 Dart 和 Flutter 测试运行器略有不同，它将跨会话保留结果。Visual Studio Code 测试运行器还添加了新的装订线图标，显示测试的最后状态，可以单击以运行测试（或右键单击以获取上下文菜单）。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image27)

在即将发布的版本中，现有的 Dart 和 Flutter 测试运行器将被移除，以支持新的 Visual Studio Code 测试运行器。


## 工具：异常、新应用模板和 Pigeon 1.0

在此版本中，调试器现在可以在未处理的异常上正确中断，而这些异常以前时被 framework 捕获 ( [#17007](https://github.com/flutter/flutter/issues/17007) )。

这改善了调试体验，**因为调试器现在可以直接指向他们在代码中的抛出行，而不是指向框架深处的随机行。**

一个相关的新功能使开发者能够决定 FutureBuilder 是否应该重新抛出或吞下错误 ([#84308](https://github.com/flutter/flutter/pull/84308)），这应该会为开发者提供大量额外的例外情况，以帮助追踪 Flutter 应用程序中的问题。

自 Flutter 诞生以来，就出现了 Counter 应用模板，它具有许多优点：

- 它展示了 Dart 语言的许多特性；
- 展示了几个关键的 Flutter 概念，并且它足够小；
- 可以放入单个文件中，即使有很多的解释性评论；

然而它没有为Flutter 应用程序提供一个特别好的起点，在此版本中，通过以下命令提供了一个新模板 ( [#83530](https://github.com/flutter/flutter/pull/83530) )：

`$ flutter create -t skeleton my_app`


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image28)

骨架模板生成一个遵循社区最佳实践的两页列表视图，它的开发经过大量内部和外部审查，为构建生产质量应用程序提供了更好的基础，并支持以下功能：

-   用于 `ChangeNotifier` 协调多个 Widget
-   默认情况下使用 arb 文件生成本地化
-   包括示例图像并为图像资产建立 1x、2x 和 3x 文件夹
-   使用“功能优先”的文件夹组织
-   支持共享首选项
-   支持明暗主题
-   支持多页面间导航

随着时间的推移，随着 Flutter 最佳实践的发展预计这个新模板也会随之发展。

另一方面，**如果你正在开发插件而不是应用程序，那么可能会对 Pigeon 的 1.0 版本感兴趣**。

Pigeon 是一个代码生成工具，用于在 Flutter 及其主机平台之间生成类型安全的互操作代码，它允许定义插件 API 的描述，并为 Dart、Java 和 Objective-C（分别可用于 Kotlin 和 Swift）生成框架代码。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-250/image29)

Flutter 团队的一些插件中已经使用了 Pigeon，在此版本中它提供了更多有用的错误消息，增加了对泛型、原始数据类型作为参数和返回类型以及多个参数的支持，预计开发者将来会更频繁地使用它。


## 重大更改和弃用

以下是 Flutter 2.5 版本中的重大变化：

-   [默认拖动滚动设备](https://flutter.dev/docs/release/breaking-changes/default-scroll-behavior-drag)
-   [在 v2.2 之后删除了弃用的 API](https://flutter.dev/docs/release/breaking-changes/2-2-deprecations)
-   [引入包：flutter_lints](https://flutter.dev/docs/release/breaking-changes/flutter-lints-package)
-   [ThemeData 的 accent 属性已被弃用](https://flutter.dev/docs/release/breaking-changes/theme-data-accent-properties)
-   [GestureRecognizer Cleanup](https://flutter.dev/docs/release/breaking-changes/gesture-recognizer-add-allowed-pointer)
-   [用 collate 替换 AnimationSheetBuilder.display](https://flutter.dev/docs/release/breaking-changes/animation-sheet-builder-display)
-   [使用 HTML 插槽在 Web 中呈现平台视图](https://flutter.dev/docs/release/breaking-changes/platform-views-using-html-slots-web)
-   [将 LogicalKeySet 迁移到 SingleActivator](https://github.com/flutter/flutter/pull/80756)

随着继续更新 Flutter Fix（在您的 IDE 中和通过`dart fix`命令可用），总共有 157 条规则来自动迁移受这些或过去的重大更改以及任何弃用影响的代码。

此外随着 Flutter 2.5 的发布，**我们将弃用[2020 年 9 月宣布的](http://flutter.dev/go/rfc-ios8-deprecation)对 iOS 8 的支持**。放弃对市场份额不到 1% 的 iOS 8 的支持，使 Flutter 团队能够专注于更广泛使用的新平台，弃用意味着这些平台可以工作，但我们不会在这些平台上测试 Flutter 的新版本或插件。

> 您可以在 flutter.dev 上查看当前支持的 Flutter 平台列表: https://flutter.dev/docs/development/tools/sdk/release-notes/supported-platforms 