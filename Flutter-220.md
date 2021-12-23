
> 原文链接：https://medium.com/flutter/whats-new-in-flutter-2-2-fd00c65e2039


**本次 Flutter 2.2 正式版主要着重于优化：包括 iOS 性能改进，Android 延迟加载组件，针对 Flutter Web 的更新等等**


每个 Flutter 新稳定版本的发布都会带来一些更新，无论是性能增强、新功能还是错误修复，尽管 Flutter 2 才发行了两个月，但 2.2 依旧在 Flutter 2 的基础上做了很多改进，**该版本合并了 2456 个 PR，涉及 Framework、 engine 和 plugins 的 issue 关闭了 3105 个 **。


## Flutter 2.2 更新稳定

此版本在 Flutter 2 之上进行了大量的改进，包括 Android，iOS 和 Web 上的更新，如新的`Material` 图标，文本处理，滚动条行为的更新以及对 `TextSpan` 控件的鼠标光标支持。

### Dart 2.13

Flutter 2.2 包含了 Dart 2.13 版本，此 Dart 更新主要包含一个**新的类型别名功能**，使开发者能够为类型和函数创建别名：

```dart
// Type alias for functions (existing)
typedef ValueChanged<T> = void Function(T value);

// Type alias for classes (new!)
typedef StringList = List<String>;

// Rename classes in a non-breaking way (new!)
@Deprecated("Use NewClassName instead")
typedef OldClassName<T> = NewClassName<T>;
```

使用类型别名可以为复杂的长类型提供“漂亮”的短名称，还可以让开发者以连续的方式重命名类。

> 更多 dart 2.13 内容 ：https://medium.com/dartlang/announcing-dart-2-13-c6d547b57067

### Flutter Web 更新

Flutter Web 作为 Flutter 最新的稳定平台，Web 在此版本中做了很多的改进。

首先，**使用新的 service 加载机制优化了缓存行为**，并修复了的重复下载 `main.dart.js` 的问题。

在 Flutter Web 的早期版本中，后台在更新下载到应用程序后，用户不刷新浏览器是不会看到这些更改，而从 Flutter 2.2 开始，当检测到更改时用户可以直接看到更新，而无需再次手动刷新页面。

> 启用此更改要求重新生成 Flutter 应用的 `index.html`，所以你可以先保存  `index.html`  里的修改，然后删除 `index.html` 文件，再通过 `flutter create .` 在项目目录中运行从而重新创建它。

**Flutter 2.2 还对两个 Web 渲染器进行了改进：**

- **对于 HTML 添加了对字体功能的支持**，启用设置 `FontFeature` 以及使用画布 API 渲染文本，以便在悬停时将其显示在正确的位置。

- **对于 HTML 和 CanvasKit都添加了 `computeLineMetrics` 和对着色器蒙板的支持**，以解决 Flutter Web 和移动应用程序之间的差距，例如：开发人员现在可以使用不透明蒙板，使用着色器蒙板执行淡出过渡，并使用 `computeLineMetrics` 像在移动应用程序中一样使用。

对于 Flutter Web 而言，`Semantics` 是的首要任务之一， Flutter 通过构建`SemanticsNode` 树来实现可访问性。Flutter Web 用户启用 `Semantics` 后，框架将生成与 `DOM` 树平行的 `RenderObjectDOM`树，并将语义属性转换为 `Aira`。

在此版本中改进了语义节点的位置，以缩小使用转换时移动和桌面 Web 应用程序之间的距离，这意味着在使用转换为 `Widget` 设置样式时，焦点框应正确显示在元素上。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image1)

我们还在配置文件和发布模式下使用命令行标志公开了语义节点调试树，以帮助开发人员通过可视化为其 Web 应用程序创建的语义节点来调试可访问性。

要在 Flutter Web 应用启用此功能，请运行以下命令：

```
$ flutter run -d chrome --profile \ 
  --dart-define = FLUTTER_WEB_DEBUG_SHOW_SEMANTICS = true
```

激活该标志后将能够在 `Widget` 顶部看到语义节点，就可以调试并查看语义元素是否放置在不应放置的位置。

虽然在支持一系列核心辅助功能方面取得了比较大的进步，但我们将继续改善辅助功能的支持。在 2.2 稳定版之后的 `master` 和 `dev` 通道上可用的内部版本中，我们还添加了一个 API，使得开发人员能够以编程方式自动启用其应用程序的可访问性，并解决了将 Tab 与屏幕阅读器配合使用的问题。

**最后最新版本的 Flutter DevTools 现在支持 Flutter Web 应用**。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image2)

### iOS页面过渡和增量安装

**在此版本中对于 iOS 我们通过将渲染动画帧所需的时间减少了 75％** ，使在 `Cupertino` 中的页面过渡更加平滑么。

在此版本中还实现了在开发过程中增量的iOS安装，**基准测试中我们发现安装更新版本的 iOS 应用程序的时间减少了40％**。

### 使用 Flutter 构建自适应平台应用

随着 Flutter 稳定版的支持平台越来越多，不仅需要考虑支持不同形式的设备（例如移动设备，平板电脑和台式机），还需要支持不同输入类型（触摸与鼠标+键盘）以及具有不同平台的应用，所以我们将：**可以根据不同目标平台的详细信息，进行自我调整的应用称为“平台自适应”应用**。

> 更多可见：https://flutter.dev/docs/development/ui/layout/building-adaptive-apps

对于根据这些原则为多个平台编写的 Demo 的应用程序，我们推荐参考 `gSkinner` 的 [Flokk](https://flutter.gskinner.com/flokk) 和 [Flutter Folio](https://flutter.gskinner.com/folio) 应用程序。

Flutter 平台自适应应用指南的 UX 部分基于新的大屏幕 `Material` 指南，`Material` 团队的新指南包括对一些主要布局文章的处理，以及对多个组件的更新和更新的设计套件，所有这些都考虑到了大屏幕。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image3)


### 更多材料图标

在“ `Material` 指南”的主题上，在此发行版中我们分割出两个单独的 PR，为 Flutter 添加了新的 `Material` 图标，包括 `Dash` 自己的图标。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image4)

这些更新使开发者的应用程序的 `Material`  图标总数达到了 7,000 多个，现在可以在fonts.google.com/icons 上按类别和名称进行搜索。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image5)


> 找到合适的图标后，新的 Flutter 标签会显示如何使用它，或者可以选择仅下载该图标以用作应用程序中。


### 改善文字处理

文本处理一直是 Flutter 里着重处理的领域，在此版本中已经开始重构处理文本输入的方式，以启用诸如在 **`Widget` 点击冒泡时取消 `keystroke` 之类的功能，并引入完全自定义与文本操作相关的 `keystrokes` 的功能**。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image6)


能够取消 `keystrokes` 使 **Flutter 能够实现使用空格键和箭头键之类触发滚动的功能**，从而为最终用户提供更直观的体验。在 `keystrokes` 进入到应用程序中的父窗口 `Widget` 之前，开发者可以使用相同的功能来处理 `keystrokes`。

另一个示例是可以在 `TextField` 和按钮之间使用 Tab 键切换：


```dart
import 'package:flutter/material.dart';
 
void main() => runApp(App());
 
class App extends StatelessWidget {
 @override
 Widget build(BuildContext context) => MaterialApp(
       title: 'Flutter Text Editing Fun',
       home: HomePage(),
     );
}
 
class HomePage extends StatelessWidget {
 @override
 Widget build(BuildContext context) => Scaffold(
       body: Column(
         children: [
           TextField(),
           OutlinedButton(onPressed: () {}, child: const Text('Press Me')),
         ],
       ),
     );
}
```


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image7)

**自定义文本操作让开发者可以执行诸如 `TextField`中 `Enter` 键的特殊处理之类的操作**，例如可以触发在聊天客户端中发送消息，同时允许通过 `Ctrl` + `Enter` 插入换行符。

> 这些文本操作使 Flutter 本身可以提供不同的 `keystrokes` ，以将文本编辑的行为与主机 OS 本身进行匹配，如 Windows 和 Linux上 的 `Ctrl + C` 和 macOS 上的 `Cmd + C`。

下面的示例将覆盖默认的向左箭头操作，并为 `Backspace`和 `Delete` 键提供新的操作：



```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
 
void main() => runApp(MyApp());
 
class MyApp extends StatelessWidget {
 @override
 Widget build(BuildContext context) => MaterialApp(
       title: 'Flutter TextField Key Binding Demo',
       home: Scaffold(body: UnforgivingTextField()),
     );
}
 
/// A text field that clears itself if the user tries to back up or correct
/// something.
class UnforgivingTextField extends StatefulWidget {
 @override
 State<UnforgivingTextField> createState() => _UnforgivingTextFieldState();
}
 
class _UnforgivingTextFieldState extends State<UnforgivingTextField> {
 // The text editing controller used to clear the text field.
 late TextEditingController controller;
 
 @override
 void initState() {
   super.initState();
   controller = TextEditingController();
 }
 
 @override
 Widget build(BuildContext context) => Shortcuts(
       shortcuts: <LogicalKeySet, Intent>{
         // This overrides the left arrow key binding that the text field normally
         // has in order to move the cursor back by a character. The default is
         // created by the MaterialApp, which has a DefaultTextEditingShortcuts
         // widget in it.
         LogicalKeySet(LogicalKeyboardKey.arrowLeft): const ClearIntent(),
 
         // This binds the delete and backspace keys to also clear the text field.
         // You can bind any key, not just those already bound in
         // DefaultTextEditingShortcuts.
         LogicalKeySet(LogicalKeyboardKey.delete): const ClearIntent(),
         LogicalKeySet(LogicalKeyboardKey.backspace): const ClearIntent(),
       },
       child: Actions(
         actions: <Type, Action<Intent>>{
           // This binds the intent that indicates clearing a text field to the
           // action that does the clearing.
           ClearIntent: ClearAction(controller: controller),
         },
         child: Center(child: TextField(controller: controller)),
       ),
     );
}
 
/// An intent that is bound to ClearAction.
class ClearIntent extends Intent {
 const ClearIntent();
}
 
/// An action that is bound to ClearIntent that clears the TextEditingController
/// passed to it.
class ClearAction extends Action<ClearIntent> {
 ClearAction({required this.controller});
 
 final TextEditingController controller;
 
 @override
 Object? invoke(covariant ClearIntent intent) {
   controller.clear();
 }
}
```



![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image8)

### 自动滚动行为

实际显示滚动条时 Android 和 iOS 的逻辑是相同的，而对于桌面应用程序，当内容大于容器时通常会自动显示滚动条，这需要添加 `Scrollbar` 作为父 `Widget`，**为了在手机或 PC 上都能正常，此版本`Scrollbar` 会在必要时会自动添加**。

例如下面所示的无滚动条的代码：

```dart
import 'package:flutter/material.dart';
 
void main() => runApp(App());
 
class App extends StatelessWidget {
 @override
 Widget build(BuildContext context) => MaterialApp(
       title: 'Automatic Scrollbars',
       home: HomePage(),
     );
}
 
class HomePage extends StatelessWidget {
 @override
 Widget build(BuildContext context) => Scaffold(
       body: ListView.builder(
         itemCount: 100,
         itemBuilder: (context, index) => Text('Item $index'),
       ),
     );
}
```

在桌面上运行它时，将显示一个滚动条：


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image9)

如果你不喜欢滚动条的外观或始终显示滚动条的逻辑，**可以设置一个 `ScrollBarTheme`，则可以在整个应用范围内或在特定实例上，通过设置来更改它 `ScrollBehavior` 来完成修改**。

### 鼠标光标在文本范围内

在 Flutter 的早期版本中，开发者可以在任何窗口小部件上添加鼠标光标（如指示可点击内容的手），而实际上 Flutter 本身在大多数情况下会添加这些鼠标光标，例如：在所有按钮上添加一个手形鼠标光标。

但是如果要运行带有不同文本跨度，且具有各自样式并且可能足够长的自动换行的格式丰富的文本，那么`TextSpan` 就不会是一个 `Widget`，因此不能用作鼠标光标的可视范围...而从此版本开始，**当拥有 `TextSpan` 带有手势识别器的时将自动获得相应的鼠标光标**：


```dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as urlLauncher;
 
void main() => runApp(App());
 
class App extends StatelessWidget {
 static const title = 'Flutter App';
 @override
 Widget build(BuildContext context) => MaterialApp(
       title: title,
       home: HomePage(),
     );
}
 
class HomePage extends StatelessWidget {
 @override
 Widget build(BuildContext context) => Scaffold(
       appBar: AppBar(title: Text(App.title)),
       body: Center(
         child: RichText(
           text: TextSpan(
             style: TextStyle(fontSize: 48),
             children: [
               TextSpan(
                 text: 'This is not a link, ',
                 style: TextStyle(color: Colors.black),
               ),
               TextSpan(
                 text: 'but this is',
                 style: TextStyle(color: Colors.blue),
                 recognizer: TapGestureRecognizer()
                   ..onTap = () {
                     urlLauncher.launch('https://flutter.dev');
                   },
               ),
             ],
           ),
         ),
       ),
     );
}
```

现在可以拥有所需的自动换行文字跨度，并且其中任何带有识别器的文字都将获得适当的鼠标光标。

![image.png](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image10)

在此版本中，`TextSpan` 还支持 `onEnter`和  `onExit` ，并且对应的拥有 `mouseCursor`。

## Flutter 2.2 更新预览

除了可用于生产的新功能外，Flutter 2.2 还提供了许多预览功能，包括 **iOS 着色器编译器性能改进，Android 延迟组件支持，Flutter 桌面更新以及 Sony 的 ARM64 Linux 主机支持**。

### 预览：iOS着色器编译改进

用图形渲染术语来说，“着色器” 是要在最终用户设备上可用的 GPU 编译并运行的程序。自成立以来 Flutter 一直在底层 Skia 图形库中使用着色器，以其自身的高质量图形效果（包括颜色，阴影，动画等）提供本机性能。

由于 Flutter API 的灵活性，着色器可以实时生成和编译，并与需要它们的帧工作负载同步，所以当编译着色器的时间超出框架预算时，体验结果对于用户来说会很明显。

为了避免出现问题，**Flutter 提供了在运行期间训练缓存着色器的功能，然后将它们打包并捆绑到应用程序中，并在 Flutter Engine 启动时在第一帧之前进行编译**。这意味着预编译的着色器不必在帧工作负载期间进行编译，也不会造成垃圾回收，但是 Skia 最初仅为 `OpenGL` 实现了此功能。

> 因此当我们默认情况下在 iOS 上启用 `Metal` 以响应 Apple 弃用 `OpenGL` 时，根据我们的基准测试，渲染帧时间增加了，而用户报告的产生的垃圾也增加了。

我们的测量数据表明，这些报告通常是由于着色器编译时间增加，Skia 为 `Metal` 后端生成的着色器数量，增加以及已编译的着色器无法在各次运行之间缓存，而使得 jank 持续到第一次运行之外而导致的一个应用程序。

> 因此直到现在，在 iOS 上避免这种麻烦的唯一方法是简化场景和动画，但这并不理想。

但是，**现在在 dev 通道上是 Skia 中对 `Metal` 的着色器预热的新支持的预览**，通过 Skia，Flutter 现在可以在第一帧工作负载开始之前编译带捆绑的着色器。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image11)

但是，此解决方案有一些警告：

- Skia 仍然需要为 `Metal` 生成比 `OpenGL` 后端更多的着色器；
- 最终的着色器对机器代码的编译仍需要与框架工作负载同步发生，但这比在框架渲染时间中进行整个着色器生成和编译要快；
- 首次运行应用程序后，将缓存生成的机器代码，直到重新启动设备为止；

如果想在应用程序中利用此新支持，可以按照 flutter.dev 上的说明进行操作。

但是，我们还没有完成这项工作。在 Android 和 iOS 上此实现都有一些缺点：

- 部署的应用程序的大小较大，因为它包含捆绑的着色器；
- 应用程序启动等待时间更长，因为捆绑的着色器需要预先编译；
- 开发人员暗示了我们对这种实现所带来的体验不满意；

我们认为最后一个问题最重要，特别是查看了执行培训运行的过程，并推理了因应用程序大小和应用程序启动延迟而带来过于繁琐的折衷。

**因此我们将继续研究，消除不依赖此实现的着色器编译垃圾以及所有垃圾的方法**。特别是我们正在与 Skia 团队合作，以减少响应 Flutter 的要求而生成的着色器的数量，并研究使用 Flutter Engine 捆绑的一小套静态定义的着色器实现。

> 可以在Flutter 中关注该项目，以了解我们的进度：https://github.com/flutter/flutter/projects/188

### Android 延迟加载组件

对于 Android 版本，使用 Dart 的拆分 AOT 编译功能，[允许 Flutter 应用程序在运行时下载包含提前编译的代码和 assets 的模块](https://github.com/flutter/flutter/pull/76192)。

**将这些可安装拆分的模块称为延迟组件**，通过仅在需要时才推迟下载代码和 assets ，可以大大减小初始安装大小，**例如我们实施了 `Flutter Gallery` 版本初始安装尺寸减少了 46 ％**。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image12)

在启用延迟组件的情况下进行构建时，**Dart 会将仅使用 `deferred` 关键字导入的代码编译到单独的共享库中，这些共享库与 assets 一起打包到延迟组件中**。

目前延迟组件仅在 Android 上可用，并且此功能作为早期预览版提供，在 flutter.dev 上新的[`Deferred components`](https://flutter.dev/docs/perf/deferred-components) 页面中了解如何实现延迟的组件。

> https://flutter.dev/docs/perf/deferred-components
>
> http://github.com/flutter/flutter/issues


### Flutter Windows UWP Alpha

Flutter 的另一个更新是针对 PC 的，对Windows UWP 的支持已在移至了 alpha。UWP 允许将Flutter 应用程序带到无法运行标准 Windows 应用程序的设备（包括Xbox）。

要进行尝试首先需要设置 UWP 先决条件。然后切换到 dev 通道并启用 UWP 支持：

```
$ flutter channel dev
$ flutter upgrade
$ flutter config — enable-windows-uwp-desktop
```

启用后，创建 Flutter 应用程序将包括一个新 winuwp 文件夹，该文件夹可让在 UWP 容器中构建和运行应用程序：


```
$ flutter create uwp_fun
$ cd uwp_fun
$ flutter pub get
$ flutter run -d winuwp
```

因为要构建 Windows UWP 应用程序在 Windows 的沙箱环境中运行，所以在开发过程中需要在本地主机上的应用程序防火墙上打一个洞，以启用诸如热重载和调试器断点之类的功能。

可以按照 Flutter 桌面文档页面 `checknetisolation` 上的说明使用命令执行此操作，完成此操作后可以在 Windows 上看到 Flutter 应用程序作为 UWP 应用程序运行。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image13)

当然也可以运行更多有趣的UWP应用，例如在 Xbox 上运行的 Flutter 应用。

> 请查看flutter.dev/desktop/#windows-uwp。


### 索尼对 ARM64 Linux 主机的支持


Flutter 社区的另一项杰出成就来自 Sony 的软件工程师 HidenoriMatsubayashi，他为针对ARM64 Linux 的支持做出了贡献，通过此 PR 可以在 ARM64 Linux 上构建和运行 Flutter 应用程序。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image14)

> https://github.com/flutter/flutter/pull/61221


### Flutter 生态系统和工具更新

Flutter Engine 和 Framework 只是整个 Flutter 生态的一部分，软件包生态系统和工具的更新对 Flutter 开发人员来说同样重要。

在生态系统方面，本次将发布许多新的 Flutter Favorite 软件包，以及 FlutterFire（Flutter对 Firebase 的支持）的一些更新，其中 FlutterFire 支持新的 Firebase App Check 预览，因此 Flutter 开发人员可以马上就用到它。

在工具方面，**Flutter DevTools 进行了新的更新以优化应用程序的内存占用**，并为提供程序包增加了一个新选项卡，另外 **VS Code 和 Android Studio / IntelliJ 的 IDE 插件都有显着更新**，并且如果是针对 Flutter 的内容作者，则可以采用全新的方式将 DartPad 集成到作品中。

最后有一个名为 `FlutterFlow` 的新的低代码应用程序设计和构建工具，该工具针对 Flutter 并在Web上运行，因为它本身是由 Flutter 构建的。

### Flutter 最受欢迎的更新

作为该版本的一部分，Flutter 生态系统委员会认证了 24 个新的 Flutter Favorite 软件包，这是我们迄今为止最大的扩展，新标记的 Flutter 收藏夹包括：

- FlutterFire ：`cloud_firestore`，`cloud_functions`，`firebase_auth`，`firebase_core`，`firebase_crashlytics`，`firebase_messaging` 和`firebase_storage` ；

> http://firebase.flutter.dev/

- 社区 plus 包：`android_alarm_manager_plus`，`android_intent_plus`，`battery_plus`，`connectivity_plus`，`device_info_plus`，`network_info_plus`，`package_info_plus`，`sensors_plus` 和 `share_plus`；

> http://plus.fluttercommunity.dev/

- `googleapis` 
- `win32`
- `intl` 和 `characters`
- Sentry packages ：`sentry`和 `sentry_flutter`
- `infinite_scroll_pagination`和 `flutter_native_splash` 


所有这些软件包都已迁移到空安全的状态，并视情况支持 Android，iOS 和 Web 。

> 例如：firebase_crashlytics 上没有底层 SDK，android_alarm_manager_plus 是专门为Android 设计的。

社区 plus 提供从 Flutter 团队包的超集。例如自 Flutter 最初发行之前，Flutter 团队就由Google 的电池组提供了 `bettery package`，并且已迁移至零安全状态，但仅在 Android 和 iOS 上受支持，而 **`battery_plus` 包另一方面它支持所有六个 Flutter 平台，包括 Web，Windows，macOS 和 Linux**。

> 九个 “plus” 软件包都获得了 Flutter 受欢迎的奖项，这代表了 Flutter 整个社区在成熟度上迈出的一大步。

`googleapis` 插件提供了约 185 个 Google API 的自动生成的 Dart 包装器，可在客户端或服务器端 Dart应 用程序（包括Flutter应用程序）中使用。

`win32` 程序包是工程学的奇迹，**它使用 Dart FFI 封装了大多数常用的 Win32 API 调用**，以使 Dart 代码可以直接访问它们，而无需使用 C 编译器或 Windows SDK 。

随着 Flutter 在 Windows 平台上的流行，该 win32 软件包已成为许多流行插件（包括`path_provider`）最流行的插件的关键依赖项。作为完整性的测试，作者 timsneath 使用原始 Dart 在原始 Win32 中做了一些有趣的事情，例如实现记事本，蛇和俄罗斯方块：


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image15)

> 该 win32 软件包绝对值得一试，看看你是否能够在 Windows 上使用 Dart 或 Flutter 进行了任何操作。

### FlutterFire 更新和 Firebase 应用程序检查

`FlutterFire` 是 Flutter 对 Firebase 的支持，是 Flutter 上最受欢迎的插件集合之一。

`Invertase` 在 Flutter 2 版本上投入生产以来一直在进行改进方面做得非常出色。实际上自FlutterFire 首次发布以来，`Invertase` 处理了 79 ％的未解决问题，并将未完成的 PR 数减少了88％。

此外他们不仅在生产质量插件方面做得很好，而且还将 Beta 质量插件迁移到了零安全性，并使其在同一内核上构建和运行，以便开发者可以混合和匹配。

此外，`Invertase` 继续为 `FlutterFire` 插件添加新功能，其中包括对该版本 Flutter 进行的 Flutter 与 `Cloud Firebase` 集成的许多更新：


- [`Typesafe`](https://firebase.flutter.dev/docs/firestore/usage/#typing-collectionreference-and-documentreference) 用于读取和写入数据的API
- 支持 Firebase 本地仿真器套件;
- 使用数据包优化数据查询

最后 `FlutterFire` 支持新 Firebase 产品的 Beta 版本：`Firebase App Check`。

`Firebase App Check` 可保护您的后端资源（如 Cloud Storage ）免受计费欺诈或网络钓鱼之类的滥用，借助 App Check 运行 Flutter 应用程序的设备，会使用应用程序身份证明提供程序来证明它确实是您的真实应用程序，并且还可以检查它是否在未受干扰的真实设备上运行。

> https://firebase.flutter.dev/docs/app-check/overview

### Flutter DevTools 更新

Flutter DevTools 在此版本中进行了许多值得注意的更新，**包括两项内存跟踪改进以及一个仅用于 provider 插件的全新标签**。

此版本的 DevTools 中的第一个内存跟踪改进功能，**提供了跟踪对象分配位置的功能，让开发者在代码中查找内存泄漏的位置非常方便。**


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image16)

第二种是**将自定义消息注入到内存时间轴的功能，这样开发者就可以提供特定于应用程序的标记，例如在完成一些占用大量内存的工作之前和之后，以便可以检查自己是否清理正确**。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image17)

> 随着 Flutter 应用的规模越来越大，我们将继续确保 Flutter 开发人员拥有跟踪和修复各种内存泄漏和运行时问题所需的工具。

在使用要跟踪的 Flutter 框架时，不仅是运行时问题，而且还存在一些其他问题：**有时开发者也想跟踪与软件包有关的问题**。

pub.dev 上有超过 15,000 个与 Flutter 兼容的软件包和插件，应用随着时间的推移使用更多软件包的可能性越来越大。考虑到这一点，我们一直在尝试向 Flutter DevTools 添加新的 “Provider”选项卡。

事实上，这个标签是由 Remi Roussel 创建，provider 包维护人员。如果你正在运行最新版本的Flutter DevTools，并且正在调试使用 provider 插件的 Flutter 应用程序，则将自动获得新的“Provider” 选项卡。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image18)


“Provider”选项卡向开发者显示与每个提供程序相关的数据，包括**在运行应用程序时的实时更改，它可以让您直接更改数据，以测试应用程序的主要情况！**

这只是此发行版中Flutter DevTools中一些很酷的新功能，有关完整列表，请在此处查看各个公告：

- Flutter DevTools 2.1 ：https://groups.google.com/g/flutter-announce/c/tCreMfJaJFU/m/38p1BBeiCAAJ
- Flutter DevTools 2.2.1 ：https://groups.google.com/g/flutter-announce/c/t8opLnUyiFQ/m/dJth-jKxAAAJ
- Flutter DevTools 2.2.3 ：https://groups.google.com/g/flutter-announce/c/t8opLnUyiFQ/m/YX5Ds_q0AgAJ


### IDE插件更新

Flutter 的 Visual Studio Code 和 IntelliJ / Android Studio IDE 扩展也已在此版本中更新，例如 Visual Studio Code 扩展现在支持两个附加的 Dart 代码重构：**内联方法和内联局部变量**。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image19)

在 Android Studio / IntelliJ 扩展中，我们添加了**使用选项将所有堆栈跟踪打印到控制台的功能**。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image20)


### DartPad workshops

为了确保我们能够在迅速发展的 Flutter 开发人员社区中准备好文档，Dart 和 Flutter 团队一直在寻找改进和扩展创建教育内容的方法。

在此版本中，我们为 DartPad 添加了一个新的分步 UI，开发人员可以使用该 UI 跟随讲师指导的讲习班。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-220/image21)

通过直接向 DartPad 添加说明，我们可以为 I/O 提供指导性的工作室体验，但是我们不只是为自己的工作室构建它；如果你想在 Dart 或 Flutter  Workshop 中使用它，可以按照 DartPad Workshop 创作指南进行操作。

> https://github.com/dart-lang/dart-pad/wiki/Workshop-Authoring-Guide

这样的主旨在于利用 DartPad 共享代码，并在自己的网站中嵌入 DartPad 。


### 社区聚焦：FlutterFlow

**FlutterFlow 是一款“低代码”应用程序设计和开发工具，可以通过浏览器中构建所有应用程序，它提供了一种所见即所得的环境**，可以使用 Firebase 的真实数据跨多个页面布置你的应用程序。

低代码工具的目标是轻松完成大多数常见的事情，从而开发者可以编写尽可能少的自定义代码行。实际上作为演示，他们构建了一个完整的多页移动应用程序，用于在不到一个小时的时间内，你可以在YouTube 上看到整个过程。

> https://youtu.be/TXsjnd_4SBo


FlutterFlow 输出 Flutter 代码，因此如果需要添加代码以进一步自定义应用程序，你可以在flutterflow.io 上了解有关 FlutterFlow 产品发布的信息。

> https://flutterflow.io/blog/launch

## 重大变化

与往常一样，我们一直努力减少重大更改的数量，在此版本中，我们已将其限制为消除以下弃用项：
- 73750 删除不建议使用的BinaryMessages：https://github.com/flutter/flutter/pull/73750
- 73751 删除不推荐使用的 `TypeMatcher`类 :https://github.com/flutter/flutter/pull/73751

## 概括

Play商店中有八分之一以上的新应用是使用 Flutter 构建，仅 Play 商店中有超过 20 万个Flutter 应用，这样的持续增长令人震惊，世界各地各种规模的应用程序都将其 UI 委托给Flutter，以打造精美的多平台体验，以迎合他们所处的任何地方的用户。