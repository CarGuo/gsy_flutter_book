# Flutter  Widget  Preview  功能已合并到 master，提前在体验毛坯的预览支持

在之前的[《Flutter Widget IDE 预览新进展，开始推进落地发布》](https://juejin.cn/post/7497194242211168294)我们聊过 Flutter Widget  Preview 即将落地，而现在我们已经可以在 master 分支体验 Widget 预览的效果。

而通过之前的了解，我们知道 Widget Preview 的实现主要依赖于 Flutter Web， 比如 Widget Preview 实际会在 `.dart_tool` 目录下创建一个名为 `widget_preview_scaffold` 的 Flutter 项目，**这个预览支持项目是一个 Flutter Web App** ，而 Flutter Web 开始支持 Hotload ，是直接支持 Widget Preview 落地的关键。

体验 Widget Preview 很简单，只要你在 master 分支，然后添加对应的 `@Preview` 注解，之后执行 `flutter widget-preview start ` 即可运行预览：

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

 `@Preview` 注解可以添加在普通函数或者构造函数上，例如 `MyWidget.preview` 就是一个比较实用的方式：

```dart
  @Preview(name: 'Constructor preview')
  const MyWidget.preview({super.key});
```

当然，目前运行  `flutter widget-preview start `  时，如果你的依赖里有 git 依赖时，预览就直接报错，因为`widget_preview_scaffold` 会在根目录下生成一个 `preview_manifest.json` ，包含有关当前 Dart 和 Flutter SDK 版本的信息，以及用户的 pubspec.yaml 的哈希值，这个哈希值用于后续自动对比用户工程的 pubspec 是否发生变化，而很明显目前不支持 git 依赖的

![](https://img.cdn.guoshuyu.cn/image-20250702134432581.png)

而目前预览成功运行之后，其实会直接打开一个外部 Chrome 来承载 Widget Preview，可以看到此时预览下高度出现了溢出：

![](https://img.cdn.guoshuyu.cn/image-20250702134421499.png)

这时候我们可以根据需要在 `@Preview` 添加对应 `Size` 来调节高度和宽度，如果不设置宽度，那么它会跟随浏览器的宽度进行变化：

![](https://img.cdn.guoshuyu.cn/image-20250702134445125.png)

那你说这和直接运行一个 Flutter Web 有什么区别？实际上还是有一点的，比如你可以在面板上同时预览和修改多个页面，并且还能根据需要，调节左上角来组织页面的排列方式：

![](https://img.cdn.guoshuyu.cn/image-20250702134457946.png)![](https://img.cdn.guoshuyu.cn/image-20250702134515128.png)

而实际上的页面运行之后其实就是一个基于 CanvasKit 的 Fluttre Web，你可以直接进行各种 UI 操作，基本上和你在 App 里的体验没什么差别：

![ezgif-526a0d55a0d519](https://img.cdn.guoshuyu.cn/ezgif-526a0d55a0d519.gif)

甚至目前你还可以打开和跳转到其他页面，只是目前体验下这个流程存在一些不和谐的情况，比如：

- 打开的 Dialog 是基于当前预览窗口来弹出![](https://img.cdn.guoshuyu.cn/image-20250702134559653.png)

  

- 打开新的路由页面时，也是直接充满预览窗口![](https://img.cdn.guoshuyu.cn/ezgif-5ae80045c26df2.gif)

当然，在预览时你大概率还会遇到各种全局配置的错误问题，比如使用自定义的多语言时，在预览时因为获取不到对象而出现异常：

![](https://img.cdn.guoshuyu.cn/image-20250702134530729.png)

目前的解决方式是需要你单独在注解里配置，同样的还有主题等其他参数，因为不配置的话就是使用默认主题：

![image-20250702134537402](https://img.cdn.guoshuyu.cn/image-20250702134537402.png)

另外，如果代码里使用了一些平台插件，比如 toast ，而这些插件又不支持 Web ，那么大概率也是执行报错：

![](https://img.cdn.guoshuyu.cn/image-20250702134551366.png)

整体看来目前的 Widget 预览还是比较毛坯，完全落地实现上肯定是要集成在 IDE 里，只是因为 DWDS（Web VM 服务实现）需要开放的 Chrome Debug 端口才能运行，而 VSCode 等 IDE 不支持此功能，而热重载支持又需要 DWDS，所以目前才没有将预览的 WebView 集成在 IDE 体验。

当然，如果真要说这个预览有什么实际用途，目前看来主要还是可以同时预览多个控件，并且能灵活配置其大小，主题，字体等功能，相对直接运行一个 Flutter Web 进行测试会更方便，但是实际上对于整体开发效率提升而已，似乎也没太大作用。









# 参考链接

- https://api.flutter.dev/flutter/widgets/Preview-class.html
- https://docs.google.com/document/d/1iMHDjC8HY_0xoOh1soxIf3MWLCtz4nD_Vn2goodO5YA/edit?tab=t.cf4w60pgaj0u