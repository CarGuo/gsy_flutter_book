> 原文链接：https://medium.com/flutter/whats-new-in-flutter-2-10-5aafb0314b12

欢迎来到 Flutter 2.10 稳定版本的更新，自上次发布至今还不到两个月，但即使在这么短的时间内，**Flutter 2.10 也关闭了 1,843 个 issues，合并了来自全球 155 位贡献者的 1,525 个 PR**，所以非常感谢大家这段时间出色的工作，尤其是在 2021 年假期期间。

作为此版本的重要组成部分，这里有几件令人兴奋的事情要宣布，包括：

- **Flutter 对 Windows 支持的重大更新；**
- **一些关于性能方面的重大改进；**
- **关于对框架中图标和颜色相关的新功能支持；**
- **一些开发工具方便的改进；**

此外还有一些关于**移除 dev channel 的更新、减少对旧版 iOS 的支持以及简短的重要变更列表等等**。

## 为 Windows 上的生产应用做好准备

首先，Flutter 2.10 版本给我们带来了稳定版本的 Windows 支持，现在开发者可以不再通过设置 flag 来启用 Windows 的支持，因为**在 Flutter 2.10 上现在默认支持编译生成 Windows 应用**

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-2100/image1)


当然，此版本还包括对**文本处理、键盘处理和键盘快捷键相关的改进，以及更好地和 Windows 进行集成，支持命令行参数，全球化多语言文本输入和辅助功能**等等。

> 有关 Windows 稳定版发布的更多信息，请参阅[Flutter for Windows 博客文章](https://timsneath.medium.com/6979d0d01fed)，该文章描述了 Flutter 在 Windows 上的架构实现，让你了解目前有多少 Flutter 包和插件已经支持 Windows，你还可以查看我们的工具和应用合作伙伴在 Windows 上使用 Flutter 所做的一些 Demo！


## 性能改进

Flutter 2.10 包括了对 Flutter 社区成员 [knopp](https://github.com/knopp) 所提供的**脏区管理**支持，他为 [ iOS/Metal 上的单个脏区域启用了部分重绘的支持](https://github.com/flutter/engine/pull/28801)，在基准测试中这一变动降低了 90% - 99% 的光栅化时间，并将 GPU 利用率从 90% 以上降低到 10% 以下。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-2100/image2)

> 我们希望在未来的版本中将这部分重绘带到来的好处支持到[其他平台](https://github.com/flutter/engine/pull/29591)。

在 Flutter 2.8 版本中，我们[发布了自己的 picture recording format](https://github.com/flutter/flutter/issues/53501)，现在 Flutter 2.10 中我们开始使用它进行功能优化，例如现在 Flutter  可以[**更简单地实现**](https://github.com/flutter/engine/pull/29775) **opacity layers**，即使在最坏的情况下，**基准测试中的帧光栅时间也下降到了之前的三分之一以下。**

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-2100/image3)

> 随着我们继续开发 picture recording format ，预计这些优化可以将扩展到更多的场景。

在 profile 和 release 模式下，Dart 代码会提前编译为 native 代码，这里面提高性能和降低其大小的关键在于整个程序的 type flow 分析，它解锁了许多编译器优化和激进的 tree-shaking。

但是由于 type flow 分析必须涵盖整个程序，因此开销可能会有些昂贵，所以此版本增加了[**更快的 type flow 分析实现**](https://dart.googlesource.com/sdk.git/+/e698500693603374ecc409e158f36c25bff45b12)，在我们的基准测试中，**Flutter 应用程序的总体构建时间下降了约 10%**。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-2100/image4)

> 与往常一样，增强性能、减少内存使用和减少延迟是 Flutter 团队的首要任务，期待未来版本的进一步改进。

## iOS 更新

除了性能改进之外，我们还添加了一些特定平台的增强功能，其中一项新增的功能是来自[luckysmg](https://github.com/luckysmg)[的 iOS 中更流畅的键盘动画](https://github.com/flutter/engine/pull/29281)，它会默认被应用于你的 App 而无需你做任何事情。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-2100/image5)

**我们还通过修复一些[边缘](https://github.com/flutter/plugins/pull/4608)条件下[崩溃](https://github.com/flutter/plugins/pull/4619)的[情况](https://github.com/flutter/plugins/pull/4661)来提高了 iOS 相机插件的稳定性。**

最后，**通过[压缩](https://github.com/flutter/engine/pull/30077)[指针](https://github.com/flutter/engine/pull/30333)使得 64 位的 iOS 架构可以减少内存的使用**。

> 64 位架构将指针表示为 4 字节的数据结构，当你有很多对象时，指针本身占用的空间会增加 APP 的整体内存使用量，特别是如果你的 App 规模比较庞大和复杂的时候，会导致更多的 GC 流失，但是 iOS App 很大一部分不太可能有对象需要占用 32 位地址空间（20 亿个对象），更不用说庞大的 64 位地址空间（900 亿个对象）了。

Dart 2.15 中提供了压缩指针，在这个 Flutter 版本中，我们使用它们来减少 64 位 iOS 应用程序的内存使用量，您可以[查看 Dart 2.15 博客文章来了解详细信息](https://medium.com/dartlang/dart-2-15-7e7a598e508a)。

> 在阅读 Dart 博客文章时，不要忘记[查看 Dart 2.16 的公告](https://medium.com/dartlang/dd87abd6bad1)，了解有关支持 Flutter for Windows 的更新，包括包平台标记和 pub.dev 上的新搜索体验。


## 安卓更新

此版本还包含许多针对 Android 的改进。

默认情况下当创建新应用时，**Flutter 会默认支持最新版本的 Android** 12 版本 （API 级别 31），此外，在此版本中**我们自动启用了**[multidex](https://developer.android.com/studio/build/multidex)**支持**。

如果您的应用支持低于 21 的 Android SDK 版本，并且超过了 64K 方法限制，**只需将`--multidex` 标志传递给 `flutter build appbundle` 或者 `flutter build apk` 就可以让你的应用支持 multidex。**

最后，**Flutter 工具现在会在 Gradle 发生错误时提供常见的问题解决步骤**，例如如果在应用中添加了一个插件，需要你提高最低 Android SDK 版本时，你现在会在日志中看到 “Flutter Fix” 建议。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-2100/image6)


## Web 更新

此版本同样包含对 Web 的一些改进。

例如在以前的版本中，在 Web 上滚动多行的 `TextField` 到边缘时它不会正确滚动，而在 Flutter  2.10 下 [**edge scrolling for text selection**](https://github.com/flutter/flutter/pull/93170) 支持当选中滚动超过 `TextField` 的范围时，内容依然可以继续正常滚动，改更新适用于 Web 和桌面应用。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-2100/image7)

此外 Flutter 还包括对 Web 的另一项显着改进：**减少将 Flutter 映射到 Web 的开销。**

在以前的版本中，每次我们想要将原生的 HTML 控件引入 Flutter 应用时，我们都需要一个 overlay 作为我们对 Web 的平台视图的支持，这些叠加层中的每一个都支持自定义绘制，但也代表着一定数量的开销。

> 如果你的应用中有大量原生 HTML 小部件（例如 links），则会因此增加大量性能开销。在这个版本中，**我们为 Web 创建了一个新的“non-painting platform view”，基本上消除了这种开销**。

我们已经在 [Link 控件](https://pub.dev/documentation/url_launcher/latest/link/Link-class.html) 中利用了这种优化，这意味着如果你的 Flutter Web 应用程序中有很多 Link，它们不会再有任何重大开销，而随着时间的推移，我们会将此优化应用到其他控件上。

## Material 3

Flutter 2.10 版本是向 Material 3 过渡的开始，其中包括[**从 single seed color 生成整个配色方案**](https://github.com/flutter/flutter/pull/93463)的能力。

你可以使用使用任何颜色构造 `ColorScheme` 实例：

```dart
final lightScheme = ColorScheme.fromSeed(seedColor: Colors.green); 
final darkScheme = ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark); 
```

`ThemeData` 其 factory  构造函数还有一个新的 `colorSchemeSeed` 参数，可生成主题的配色方案：

```dart
final lightTheme = ThemeData(colorSchemeSeed: Colors.orange, …);
final darkTheme = ThemeData(colorSchemeSeed:Colors.orange, brightness: Brightness.dark, …);
```

此外，此版本包括还包含了 `ThemeData.useMaterial3` 标识位，它用于将组件切换到新的 Material 3 外观支持。

最后，**我们添加了[1,028 个新的 Material 图标](https://github.com/flutter/flutter/pull/95007)**。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-2100/image8)


## 集成测试改进

2020 年 12 月 开始我们宣布了一种[使用 integration_test 包进行端到端测试](https://medium.com/flutter/updates-on-flutter-testing-f54aa9f74c7e)的新方法，这个新包取代了 flutter_driver 包作为进行集成测试的推荐方式，提供了如 Firebase Test Lab对 Web 和桌面端的支持。

从那时起我们对集成测试进行了进一步的改进，包括**将 integration_test 包捆绑到 Flutter SDK 本身**中，使其更容易与开发者的应用进行集成。

> 如果你想将现有的 flutter_driver 测试移动到 integration_test，可以参考迁移指南：https://docs.flutter.dev/testing/integration-tests/migration


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-2100/image9)


## Flutter 开发工具

在这个版本中我们也对 Flutter DevTools 做了一些改动，包括更便捷地从命令后使用 DevTools，现在可以直接**通过 `dart devtools` 去会下载和执行更新版本而不是使用`pub global activate`**。

我们还进行了许多关于[可用性](https://github.com/flutter/devtools/pull/3526) 的[更新](https://github.com/flutter/devtools/pull/3493) 其中包括[**改进了变量窗格中检查大型列表和映射的支持**](https://github.com/flutter/devtools/pull/3497)（感谢[elliette](https://github.com/elliette)）。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-2100/image10)



## VSCode 改进

Flutter 的 Visual Studio Code 扩展也获得了许多增强功能，包括**代码中更多位置的颜色预览**和[**更新代码的颜色选择器**](https://github.com/Dart-Code/Dart-Code/issues/3240)。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-2100/image11)

此外，如果你想成为 VSCode 的 Dart 和 Flutter 扩展插件的预发布版本的测试人员，可以[在扩展设置中切换到预发布版本](https://github.com/Dart-Code/Dart-Code/issues/3729)。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-2100/image12)

## 删除开发通道

在[Flutter 2.8 版本](https://medium.com/flutter/whats-new-in-flutter-2-8-d085b763d181) 已经宣布我们正在努力**移除 dev channel**，从而简化开发者的选择并移除工程开销，而在这个版本中[我们已经完成了这项工作](https://github.com/flutter/flutter/issues/94962)，包括：

-   更新了 Flutter 工具以帮助将开发人员迁移出 dev channel
-   更新了 wiki 以反映更新
-   更新了弃用政策
-   从 DartPad、预提交测试和网站中删除了dev channel支持

## 对 iOS 9.3.6 的不再支持

由于实验室中目标设备的使用减少和维护难度增加，现在将对**iOS 9.3.6的**[**支持**](http://flutter.dev/go/rfc-32-bit-ios-support)[**从“支持”层转移到“尽力而为”层**](https://docs.flutter.dev/development/tools/sdk/release-notes/supported-platforms)，这意味着对 iOS 9.3.6 的支持和对 32 位 iOS 设备的支持将仅通过临时修复和社区测试来维持。

> https://docs.flutter.dev/development/tools/sdk/release-notes/supported-platforms)

**在 2022 年第三季度的稳定版本中，我们预计从 Flutter 稳定版本中放弃对 32 位 iOS 设备以及 iOS 版本 9 和 10 的支持**，这意味着在那之后基于稳定的 Flutter SDK 构建的应用将不再在 32 位 iOS 设备上运行，并且 **Flutter 支持的最低 iOS 版本将增加到 iOS 11**。

## 重大变化


-   所需的 Kotlin 版本：https://docs.flutter.dev/release/breaking-changes/kotlin-version
-   在 v2.5 之后删除了已弃用的 API：https://docs.flutter.dev/release/breaking-changes/2-5-deprecations)
-   Web 上的原始图像使用正确的来源和颜色：https://docs.flutter.dev/release/breaking-changes/raw-images-on-web-uses-correct-origin-and-colors
-  Scribble Text Input Client：https://docs.flutter.dev/release/breaking-changes/scribble-text-input-client

如果你仍在使用这些 API，可以[阅读 flutter.dev 上的迁移指南](https://docs.flutter.dev/release/breaking-changes)，与往常一样，非常感谢社区[提供的测试](https://github.com/flutter/tests/blob/master/README.md)，帮助我们识别这些重大变化。