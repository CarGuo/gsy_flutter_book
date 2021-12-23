
> 原文链接：https://medium.com/flutter/whats-new-in-flutter-2-8-d085b763d181


欢迎来到 Flutter 2.8！该版本包含了 207 位 contributors 和 178 位 reviewers 的内容，其中一共有 2,424 个合并的 PR，并 Closed 了 2976 个问题。

与往常一样，Flutter 的工作的第一位就是保证质量，我们花费了大量时间来确保 Flutter 在支持的设备范围内可以尽可能平稳和稳健地运行。

## Startup

**该版本改进了应用的启动延迟问题**，这个改进在 Google Pay 中进行了， Google Pay 作为一个主流的大型应用程序，代码超过 100 万行，使用它进行测试可以确保这些更改所产生的影响是可以被感知的。

**所有这些改进使得 Google Pay 在低端 Android 设备上运行时的启动延迟降低了 50%，在高端设备上降低了 10%**。

Flutter 通过影响 Dart VM 的垃圾收集策略的方式，可以有助于避免在应用启动期间出现不合时宜的 GC 。

> 例如在 Android 上渲染第一帧之前，Flutter 现在 [只通知 Dart VM `TRIM_LEVEL_RUNNING_CRITICAL` 及以上的内存压力信号](https://github.com/flutter/flutter/issues/90551)，在本地测试中，这个更改将低端设备上的第一帧时间减少了多达 300 毫秒。

出于[严谨的考虑](https://github.com/flutter/engine/pull/29145#pullrequestreview-778935616)，在之前的版本中 Flutter 创建平台视图时会阻塞平台线程，这次通过[详细的推理和测试](https://github.com/flutter/flutter/issues/91711) 确定了可以删除一些序列化，这个改进消除了在低端设备上启动 Google Pay 期间超过 100 毫秒的阻塞。

另外，以前设置默认字体管理器时，会在设置第一个 Dart isolate 时添加人为的延迟，而[延迟默认字体管理器](https://github.com/flutter/engine/pull/29291) 和 Dart `Isolate` 设置，这样既改善了启动延迟，又使上述优化的效果更加明显。


## # Memory

由于 Flutter 频繁地加载 Dart VM 的 “service isolate”，这部分 AOT 代码与应用程序捆绑在一起，因此 Flutter 会同时将这两者都读入内存，因此针对内存受限的设备， Flutter 开发人员在进行性能跟踪时[遇到了问题](https://github.com/flutter/flutter/issues/91382)。

在 2.8 版本中针对 Android 设备， Dart VM 的 service isolate [被拆分为](https://github.com/flutter/engine/pull/29245)可以单独加载的[自己的包](https://github.com/flutter/engine/pull/29245)，这样的调整让设备可节省最多 40 MB 的内存。

通过[ Dart VM informing the OS ](https://github.com/flutter/flutter/issues/92120)，内存占用进一步减少了 10%  ，AOT 程序使用的内存将可能不需要再次读取文件，因此，之前保存文件备份数据副本的页面可以被回收并用于其他用途。

## Profiling

以便更好地了解应用程序中的性能问题，在应用程序启动时启用，2.8 版本现在会将跟踪事件发送到 `Android systrace` 记录器，即使 Flutter 应用程序构建在发布模式下也会发送这些事件。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-280/image1)

此外为了创建更少卡顿的动画效果，开发者可能会想要更多关于光栅缓存行为的性能跟踪信息，因为这个行为对于 Flutter 来说是比较昂贵的，**可以重复使用的图片进行 blit， 而不是在每一帧上重新绘制它们，在性能跟踪中的新事件流现在允许跟踪光栅缓存图片的生命周期**。

## Flutter DevTools

对于调试性能问题，**该版本的 `DevTools` 添加了一个新的“Enhance Tracing”功能，它可以帮助开发者诊断因昂贵的构建、布局和绘制操作而导致的 UI 卡顿**。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-280/image2)

启用这些跟踪功能中的任何一个后，时间轴将包含用于构建的 Widget、布置的渲染对象和绘制渲染对象的新事件（视情况而定）。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-280/image3)


**此外该版本的 `DevTools` 增加了分析应用程序启动性能的支持**，该配置文件包含从 Dart VM 初始化到第一个 Flutter 帧渲染的 CPU 样本。

在按下 “Profile app start up” 按钮并加载应用程序启动配置文件后，开发者将看到为配置文件选择的 “AppStartUp” 用户标签，另外还可以通过在可用用户标签列表中，选择此用户标签过滤器（如果有）来加载应用程序启动配置文件。

> 选择此标签会显示应用启动的配置文件数据。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-280/image4)


## Web platform views


**Android 和 iOS 并不是唯一获得性能改进的平台，该版本还改进了 Flutter web 平台的性能**。

Flutter Web 使用 `HtmlElementView` Widget 实现了这一点，它允许开发者在 Flutter Web 应用程序中托管 HTML 元素。

如果开发者使用的是 google_maps_flutter 插件或 video_player 插件的 web 版本，或者你已经遵循了 Flutter 团队关于[如何优化网络上显示图像的建议](https://docs.flutter.dev/development/platform-integration/web-images#use-img-in-a-platform-view)，那么您其实已经在使用 platform views。


在之前版本的 Flutter 中，platform view 会立即创建一个新的画布，每个额外的平台视图都会添加另一个画布，可是创建额外的画布是很昂贵的，因为每个画布都是整个窗口的大小。

**所以该版本会复用早期平台视图创建的画布**，这意味着开发者可以在 `HtmlElementView`  的 Web 应用中拥有多个实例而不会降低性能，同时还可以减少使用平台视图时的滚动卡顿。



## WebView 3.0

**这次 `webview_flutter` 的另一个新版本是，这里提高了版本号，是因为新功能的数量增加了，而且还因为 Web 视图在 Android 上的工作方式可能发生了重大变化**。

在之前的版本中， `webview_flutter` 的  hybrid composition 模式已经可用，但并不是默认设置。

hybrid composition 修复了先前默认 virtual displays  模式存在的许多问题，根据用户反馈和问题跟踪的结果，我们认为是时候让 hybrid composition 成为默认设置了，另外 `webview_flutter` 还增加了一些要求很高的功能：


- 支持 POST 和 GET 来填充内容（[4450](https://github.com/flutter/plugins/pull/4450)、[4479](https://github.com/flutter/plugins/pull/4479)、[4480](https://github.com/flutter/plugins/pull/4480)、[4573](https://github.com/flutter/plugins/pull/4573)）
- 从文件和字符串（[4446](https://github.com/flutter/plugins/pull/4446)、[4486](https://github.com/flutter/plugins/pull/4486)、[4544](https://github.com/flutter/plugins/pull/4544)、[4558](https://github.com/flutter/plugins/pull/4558)）加载 HTML
- 透明背景支持（[3431](https://github.com/flutter/plugins/pull/4569)、[3431](https://github.com/flutter/plugins/pull/4569)、[4570](https://github.com/flutter/plugins/pull/4570)）
- 在加载内容之前编写 cookie（[4555](https://github.com/flutter/plugins/pull/4555)、[4555](https://github.com/flutter/plugins/pull/4556)、[4557](https://github.com/flutter/plugins/pull/4557)）

此外在 3.0 版本中，`webview_flutter` 为新平台提供了初步支持：web，这个支持允许开发者从单个代码库构建 mobile 和  web 应用，在 Flutter Web 应用程序中托管 Web 视图是什么样的？从代码的角度来看它看起来是一样的：

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

void main() {
  runApp(const MaterialApp(home: HomePage()));
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    // required while web support is in preview
    if (kIsWeb) WebView.platform = WebWebViewPlatform();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Flutter WebView example')),
        body: const WebView(initialUrl: 'https://flutter.dev'),
      );
}
```
在 Web上运行时它也会按开发者的预期工作：


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-280/image5)

请注意，**其实当前的 `webview_flutter` for web 的实现还有许多限制，因为它是使用 构建的 `iframe` 实现的**。

它仅支持简单的 URL 加载，无法控制加载的内容或者和加载的内容交互

> 有关更多信息，请查看 [webview_flutter_web  Readme](https://pub.dev/packages/webview_flutter_web)

但是 `webview_flutter_web` 由于太收欢迎，我们将作为 [未经认可的插件提供](https://docs.flutter.dev/development/packages-and-plugins/developing-packages#endorsed-federated-plugin)，如果你想尝试一下，请将以下行添加到 pubspec.yaml 中：

```yaml
dependencies:
  webview_flutter: ^3.0.0
  webview_flutter_web: ^0.1.0 # add unendorsed plugin explicitly
```

## Flutter Favorites

Flutter Ecosystem Committee  生态系统委员会再次召开会议，指定以下 Flutter Favorites 包：

-   三种自定义路由器包：[`beamer`](https://pub.dev/packages/beamer)，[`routemaster`](https://pub.dev/packages/routemaster) 和 [`go_router`](https://pub.dev/packages/go_router)
-   [`drift`](https://pub.dev/packages/drift)，一个功能强大且流行的 Flutter 和 Dart 响应式持久化库的重命名，构建在 `sqlite`
-   [`freezed`](https://pub.dev/packages/freezed)，一个 Dart “语言补丁” 为定义模型、克隆对象、模式匹配等提供简单的语法
-   [`dart_code_metrics`](https://pub.dev/packages/dart_code_metrics)
-   几个非常好看的图形用户界面包：[`flex_color_scheme`](https://pub.dev/packages/flex_color_scheme)，[`flutter_svg`](https://pub.dev/packages/flutter_svg)，[`feedback`](https://pub.dev/packages/feedback)，[`toggle_switch`](https://pub.dev/packages/toggle_switch)，和 [`auto_size_text`](https://pub.dev/packages/auto_size_text)

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-280/image6)

# 特定于平台的软件包

如果你是软件包作者，必须选择哪些平台是将支持的，如果正在使用特定于平台的本机代码构建插件，可以[使用](https://docs.flutter.dev/development/packages-and-plugins/developing-packages#plugin-platforms)`pluginClass`[项目中的属性](https://docs.flutter.dev/development/packages-and-plugins/developing-packages#plugin-platforms)来实现，[该](https://docs.flutter.dev/development/packages-and-plugins/developing-packages#plugin-platforms)[属性](https://docs.flutter.dev/development/packages-and-plugins/developing-packages#plugin-platforms)`pubspec.yaml`指示提供功能的 native 类：


```yaml
flutter:
  plugin:
    platforms:
      android:
        package: com.example.hello
        pluginClass: HelloPlugin
      ios:
        pluginClass: HelloPlugin
```

但是随着 [Dart FFI](https://dart.dev/guides/libraries/c-interop) 变得更加成熟，可以像 `path_provider_windows` 包一样在 100% Dart 中实现用于特定平台的功能，所以当没有任何本机类可以使用，但你仍想将你的包指定为仅支持某些平台时，请改用该`dartPluginClass` 属性：

```yaml
flutter:
  plugin:
    implements: hello
    platforms:
      windows:
        dartPluginClass: HelloPluginWindows
```

使用这个配置后，即使没有任何 native 代码，也已将包指定为仅支持某些平台，另外还必须提供 Dart 插件类；可以在 flutter.dev 上的 Dart-only 平台实现文档中了解更多信息。


## Firebase

> 关于它的一系列升级和更新，很大一块，反正国内用不上，懒得写了

## Desktop

**Flutter 2.8 版本在 Windows、macOS 和 Linux 稳定版本的道路上又迈出了一大步。** 包括国际化和本地化支持，如最近的 中文IME支持、韩语IME支持和汉字IME支持。

一个为稳定版本准备的例子：完全重构 Flutter 处理键盘事件以允许同步响应，这使 Widget 能够处理按键并取消其在 tree 的其余部分中传播。

最初是在 Flutter 2.5 和 Flutter 2.8 中添加了对问题的回归和修复，这是重新设计处理特定于设备的键盘输入的方式，重构 Flutter 处理文本编辑方式来达到补充的目的，所有这些都是键盘输入密集型桌面应用程序所必需。

此外我们会继续扩展 Flutter 对视觉密度的支持并为对话框公开对齐方式，以实现更加桌面友好的 UI。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-280/image7)

最后 Flutter 团队并不是唯一一个在 Flutter 桌面上工作的人，举个例子，Canonical 的桌面团队正在与 Invertase 合作，在 Linux 和 Windows 上实现最流行的 Flutter Firebase 插件。



![](http://img.cdn.guoshuyu.cn/20211223_Flutter-280/image8)

## DartPad

DartPad 的改进，其中最大的改进是对更多包的支持，事实上现在有 23 个包可供导入，除了几个 Firebase 服务，该名单包含常用软件如 `bloc`，`characters`，`collection`，`google_fonts`，和 `flutter_riverpod` ，DartPad 团队会继续添加新的软件包，因此如果想查看当前支持哪些软件包，请单击右下角的信息图标。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-280/image9)

还有另一个新的 DartPad 功能也非常方便。以前 DartPad 总是运行最新的稳定版本，在此版本中可以使用状态栏中的新频道菜单，来选择最新的 Beta 频道版本以及之前的稳定版本（称为“旧频道”）。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-280/image10)

## Removing the dev channel

Flutter “channel” 控制着底层 Flutter 框架和引擎在你的开发机器上变化的速度，Stable 代表最少的问题，而 master 代表最多。

**由于资源限制，我们最近停止更新 `dev` channel**。虽然为此我们确实收到了一些关于此的问题，但我们发现只有不到 3% 的 Flutter 开发人员使用该`dev`渠道。

因此我们决定正式退役的进程`dev`渠道，因为很少有开发人员使用 dev 频道，但 Flutter 工程师需要花费大量时间和精力来维护它。

你可以使用该 `flutter channel` 命令决定想要哪个频道，以下是 Flutter 团队对每个频道的看法：

-    `stable`频道代表我们拥有的最高质量的构建。它们每季度（大致）发布一次，并针对中间的关键问题进行热修复，这就是“慢”通道：安全、成熟、长期服务。

-    `beta` 频道为那些习惯于更快节奏的人提供了一种快速移动的替代方案。目前每月发布。

-    `master` 频道是我们活跃的开发频道，我们不提供对该频道的支持，但我们针对它运行了一套全面的单元测试。

当 `dev` 在未来几个月停用该频道时，请考虑 `beta` 或 `master `频道，具体取决于对问题的容忍度以及对最新和最好的需求。

## Breaking Changes

与往常一样，我们都在努力减少每个版本中重大更改的数量，在此版本中，Flutter 2.8 除了已过期并根据我们的重大变更政策已被删除的已弃用 API 之外，没有重大变更：

- [90292](https://github.com/flutter/flutter/pull/90292)删除autovalidate弃用
- [90293](https://github.com/flutter/flutter/pull/90293)删除FloatingHeaderSnapConfiguration.vsync弃用
- [90294](https://github.com/flutter/flutter/pull/90294)删除AndroidViewController.id弃用
- [90295](https://github.com/flutter/flutter/pull/90295)删除BottomNavigationBarItem.title弃用
- [90296](https://github.com/flutter/flutter/pull/90296)删除不推荐使用的文本输入格式类



## 总结

**看完 Flutter 2.8 的更新，最主要是关于性能、稳定性和 WebView 的调整，本质上这个版本应该会比较友好，因为几乎没有 Breaking Changes ，所以值得一试，推荐等 2.8.3 之后的版本。**