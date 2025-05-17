# Flutter Widget IDE 预览新进展，开始推进落地发布

去年 11 月我们就聊过[《Flutter 终于正式规划 IDE Widget 预览支持》](https://juejin.cn/post/7441006286765064218)，而现在 Widget 预览功能终于开始推进正式落地，并发布了第二版的[规划文档](https://flutter.dev/go/widget-previews-architecture)：

![](https://img.cdn.guoshuyu.cn/image-20250425094605665.png)

> 如果你没看到前文，建议看看 ：https://juejin.cn/post/7441006286765064218

其实一直以来由于 Flutter 具备 hotload 的能力，所以在 Widget Preview 能力这部分都被认为不是必须的场景，但是**基于开发者可以更直观验证一些场景，如屏幕大小、方向、字体大小和区域设置等变量对App 的影响**，Widget 预览最终还是被提上了议程。

而这次， Widget Preview 之所以正式开始推进，核心主要依赖两点：

- [skwasm 正式落地和 html renderer 正式移除](https://juejin.cn/post/7446613741627736091)
- [Flutter 3.31 beta 支持  Web hot reload ](https://github.com/flutter/flutter/issues/53041)

因为 Widget Preview 实际会在  `.dart_tool` 目录下创建一个名为  `widget_preview_scaffold` 的 Flutter 项目，**这个预览支持项目是一个 Flutter Web App** 。

> 所以可以理解为，现在大家都是基于 Canvas 的同源 UI ，所以可以用 Web 来实时渲染，从而在 IDE 内实现实时预览。

![](https://img.cdn.guoshuyu.cn/unnamed555.gif)

> 在预览里，开发者可以和预览进行交互，支持缩放和平移，甚至可以预览动画，不过预览时的实际帧率最高只会是 60 FPS。

而本次 V2 版本规划的预览支持里，主要是新增了  `flutter widget-preview`  一些列命令，命令负责为项目生成预览脚手架并与预览环境交互支持。

例如，执行 `flutter widget-preview start` 命令后，就会在 `.dart_tool` 目录下生成一个预览工程，工程结构大致为：

- **lib/src/widget_preview_rendering.dart**：preview scaffold 项目的真正入口点，负责初始化 Dart Tooling Daemon（DTD） 服务和用于渲染 lib/src/generated_preview.dart 中定义的预览的控件
- **lib/src/generated_preview.dart**：包含 `List<WidgetPreview> previews()` 函数，函数最终会将已处理的 WidgetPreview 列表返回到  preview scaffold 用于渲染
- **lib/src/widget_preview.dart**：包含 WidgetPreview 类的定义，是一个与 Preview 接近 1:1 映射的数据类，类包括一个 builder 属性，这个属性采用一个闭包返回要预览的 widget
- **lib/src/dtd_services.dart**：包含一个 Dart Tooling Daemon （DTD） 服务器连接，为工具提供 Widget 预览服务，并访问其他工具提供的服务（比如和 IDE、分析服务器等交互）。

之后命令会初始化  `widget_preview_scaffold` 的 `pubspec.yaml`，在开发者的项目中添加路径依赖，并列出开发者项目中的资源。

然后在 `widget_preview_scaffold` 的根目录下生成一个 `preview_manifest.json` ，包含有关当前 Dart 和 Flutter SDK 版本的信息，以及用户的 pubspec.yaml 的哈希值，这个哈希值用于后续自动对比用户工程的 pubspec 是否发生变化。

接着会使用 `package:analyzer` 搜索 `@Preview()` 注解，就如下面代码一样 ，记录需要预览函数名称、库和提供给注解的所有参数等。

最终会根据 analyzer 搜索的结果生成 `lib/src/generated_preview.dart` 。

```dart
@Preview(name: 'Top-level preview')
Widget preview() => const Text('Foo');


@Preview(name: 'Builder preview')
WidgetBuilder builderPreview() {
  return (BuildContext context) {
    return const Text('Builder');
  };
}


class MyWidget extends StatelessWidget {
  @Preview(name: 'Constructor preview')
  const MyWidget.preview({super.key});


  @Preview(name: 'Factory constructor preview')
  factory MyWidget.factoryPreview() => const MyWidget.preview();


  @Preview(name: 'Static preview')
  static Widget previewStatic() => const Text('Static');


  @override
  Widget build(BuildContext context) {
    return const Text('MyWidget');
  }
}

```

而一旦用户运行了命令并生成预览脚手架工程之后，它就会被编译并使用提供的 --machine 运行，之后 Flutter 工具将在开发人员的项目目录上初始化一个文件观察器，用于检测源代码的更改，比如：

> analyzer 会检测文件中添加或删除的   `@Preview()`  ，必要时重新生成 lib/src/generated_preview.dart 。

另外，`flutter widget-preview clean`  可以触发删除 `.dart_tool/widget_preview_scaffold/ ` 项目，强制它在下次运行 `flutter widget-preview start `时重新生成 。

而针对 Preview 注解也有可定制参数，比如在预览时调节主题，亮度，文本大小等：

```dart
base class Preview {
  /// Annotation used to mark functions that return widget previews.
  const Preview({
    this.name,
    this.width,
    this.height,
    this.textScaleFactor,
    this.wrapper,
    this.theme,
    this.brightness,
  });

```

![](https://img.cdn.guoshuyu.cn/unnamed666.gif)

同时，为了防止用户在整个 widget 预览环境中执行热重启，每个渲染的预览都能够在预览的 widget 上执行 “Soft restart” ：

![](https://img.cdn.guoshuyu.cn/unnamed999.gif)

>  “Soft restart” 只是从一帧的 widget 树中删除预览的 widget，然后再将其重新插入到下一帧：https://github.com/flutter/flutter/pull/166846

最后，因为最终需要在 IDE 中托管的 webview 中打开预览，需要类似于 Dart/Flutter DevTools 嵌入到 IDE 中的方式，但是由于 DWDS（Web VM 服务实现）需要一个开放的 Chrome 调试端口才能运行，这在 VSCode 等 IDE 中不可用，但是 DWDS 又是热重载的必备支持，所以目前最大的阻碍是：

> 在没有 Chrome 调试端口的情况下运行 DWDS，同时保持热重载，做到当 DWDS 无法访问 Chrome 调试器时，改为提供一组有限的功能：https://github.com/dart-lang/webdev/issues/2605

其他问题还有比如 `dart:io`、原生插件等场景需要如何在预览工程处理，但是这些问题都是后话，在 DWDS 适配 IDE场景支持后，IDE 预览就可以基本考虑实验性落地了。

看得出来其实 IDE 预览的话核心其实来自 Flutter Web ，由于 Flutter Web 支持 hotload 之后，用一个阴影工程来做实时预览确实是一个相对低成本的选择，不过真的要完整落地，需要考虑的细节还是很多，其中最重要的莫过于使用过程中的性能影响，如果体验太差，还不如直接 hotload 运行实际。

那么，你会期待或者需要 Flutter 的 IDE Widget 预览吗？

# 参考链接

- https://github.com/flutter/flutter/issues/159342

















