# Flutter 小技巧之 Flutter 3 下的 ThemeExtensions 和  Material3

**本篇分享一个简单轻松的内容： `ThemeExtensions ` 和 `Material3`** ，它们都是 Flutter 3.0 中的重要组成部分，相信后面的小知识你可能还没了解过～。

# ThemeExtensions 

相信大家都用过 Flutter 里的 ` Theme` ，在 Flutter 里可以通过修改全局的  ` ThemeData`  就来实现一些样式上的调整，比如 ：全局去除 `InkWell` 和 `TextButton` 的点击效果。

```dart
theme: ThemeData(
   primarySwatch: Colors.blue,
   // 去掉 InkWell 的点击水波纹效果
   splashFactory: NoSplash.splashFactory,
   // 去除 InkWell 点击的 highlight
   highlightColor: Colors.transparent,
   textButtonTheme: TextButtonThemeData(
     // 去掉 TextButton 的水波纹效果
     style: ButtonStyle(splashFactory: NoSplash.splashFactory),
   ),
),
```

当然，开发者也可以通过  `Theme.of(context)` 去读取 `ThemeData` 的一些全局样式，从而让自己的控件配置更加灵活，**但是如果  `ThemeData`  里没有符合你需求的参数，或者你希望这个参数只被特定控件是用，那该怎么办** ？ 

Flutter 3 给我们提供了一个解决方案： `ThemeExtensions ` 。

开发者可以通过继承 `ThemeExtension`  并 override 对应的  `copyWith` 和 `lerp`  方法来自定义需要拓展的  `ThemeData` 参数，比如这样：

```dart
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  static const light = StatusColors(open: Colors.green, closed: Colors.red);
  static const dark = StatusColors(open: Colors.white, closed: Colors.brown);

  const StatusColors({required this.open, required this.closed});

  final Color? open;
  final Color? closed;

  @override
  StatusColors copyWith({
    Color? success,
    Color? info,
  }) {
    return StatusColors(
      open: success ?? this.open,
      closed: info ?? this.closed,
    );
  }

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) {
      return this;
    }
    return StatusColors(
      open: Color.lerp(open, other.open, t),
      closed: Color.lerp(closed, other.closed, t),
    );
  }

  @override
  String toString() => 'StatusColors('
      'open: $open, closed: $closed'
      ')';
}
```

之后就可以将上面的  `StatusColors` 配置到 `Theme` 的  `extensions` 上，然后通过 ` Theme.of(context).extension<StatusColors>()`  读取配置的参数。

```dart
theme: ThemeData(
  primarySwatch: Colors.blue,
  extensions: <ThemeExtension<dynamic>>[
    StatusColors.light,
  ],
),

·····
  
@override
Widget build(BuildContext context) {

  /// get status color from ThemeExtensions 
  final statusColors = Theme.of(context).extension<StatusColors>();
  
  return Scaffold(
    extendBody: true,
    body: Container(
      alignment: Alignment.center,
      child: new ElevatedButton(
          style: TextButton.styleFrom(
            backgroundColor: statusColors?.open,
          ),
          onPressed: () {},
          child: new Text("Button")),
    ),
  );
}
```

是不是很简单？**通过 `ThemeExtensions ` ，第三方 package 在编写控件时，也可以提供对应的  `ThemeExtensions` 对象，实现更灵活的样式配置支持**。

# Material3

Material3 又叫 MaterialYou ， 是谷歌在 Android 12 时提出的全新 UI 设计规范，现在 Flutter 3.0 里你可以通过  `useMaterial3: true`  打开配置支持。

```dart
theme: ThemeData(
  primarySwatch: Colors.blue,
  ///打开 useMaterial3 样式
  useMaterial3: true,
),
```

当然，**在你开启  Material3 之前，你需要对它有一定了解，因为它对 UI 风格的影响还是很大的，知己知彼才能不被背后捅刀**。

如下图所示，是在 `primarySwatch: Colors.blue` 的情况下，`AppBar` 、`Card`、`TextButton`、 `ElevatedButton` 的样式区别：

![](http://img.cdn.guoshuyu.cn/20220605_N2/image1.png)

可以看到圆角和默认的颜色都发生了变化，并且除了 UI 更加圆润之外，交互效果也发生了一些改变，比如：

- 点击效果和 `Dialog` 的默认样式都发生了变化；
- Android 上列表滚动的默认 `OverscrollIndicator` 效果也发生了改变；

| 交互                                                   | 列表                                                         |
| ------------------------------------------------------ | ------------------------------------------------------------ |
| ![](http://img.cdn.guoshuyu.cn/20220605_N2/image2.gif) | ![333333](http://img.cdn.guoshuyu.cn/20220605_N2/image3.gif) |

目前在 Flutter 3 中受到 `useMaterial3` 影响的主要有以下这些 Widget ，可以看到主要影响的还是具有交互效果的 Widget 居多：

* [AlertDialog]

* [AppBar]
* [Card]
* [Dialog]
* [ElevatedButton]
* [FloatingActionButton]
* [Material]
* [NavigationBar]
* [NavigationRail]
* [OutlinedButton]
* [StretchingOverscrollIndicator]
* [GlowingOverscrollIndicator]
* [TextButton]

**那 Material3 和之前的 Material2 有什么区别呢**？

以 `AppBar` 举例，可以看到在 M2 和 M3 中背景颜色的获取方式就有所不同，在 M3 下没有了 `Brightness.dark` 的判断，那是说明 M3 不支持暗黑模式吗？

![](http://img.cdn.guoshuyu.cn/20220605_N2/image4.png)

回答这个问题之前，我们先看 `_TokeDefaultsM3` 有什么特别之处，从源码注释里可以看到   `_TokeDefaultsM3`  是通过脚本自动生成，并且目前版本号是 `v0_92` ，**所以 M3 和 M2 最大的不同之一就是它的样式代码现在是自动生成**。

![](http://img.cdn.guoshuyu.cn/20220605_N2/image5.png)

在  Flutter 的 [gen_defaults](https://github.com/flutter/flutter/tree/ca2d60e8e2344d8c0ed938869f7c974cb745e841/dev/tools/gen_defaults/lib) 下就可以看到，基本上涉及 M3 的默认样式，都是通过 `data` 下的数据利用模版自动生成，比如 `Appbar` 的 `backgroundColor` 指向的就是 `surface` 。

![](http://img.cdn.guoshuyu.cn/20220605_N2/image6.png)

**而之所以 M3 的默认样式不再需要  `Brightness.dark` 的判断，是因为在 M3 使用的 `ColorScheme` 里已经做了判断**。

![image-20220602214139954](http://img.cdn.guoshuyu.cn/20220605_N2/image7.png)

**事实上现在 Flutter 3.0 里 `colorScheme` 才是主题颜色的核心，而 `primaryColorBrightness` 和 `primarySwatch` 等参数在未来将会被弃用**，所以如果目前你还在使用 `primarySwatch`  ，在 `ThemeData` 内部会通过  `ColorScheme.fromSwatch` 方法转换为  `ColorScheme` 。

```dart
ColorScheme.fromSwatch(
  primarySwatch: primarySwatch,
  primaryColorDark: primaryColorDark,
  accentColor: accentColor,
  cardColor: cardColor,
  backgroundColor: backgroundColor,
  errorColor: errorColor,
  brightness: effectiveBrightness,
);
```

另外你也可以通过  `ColorScheme.fromSeed` 或者 `colorSchemeSeed ` 来直接配置  `ThemeData` 里的 `ColorScheme` ，**那 `ColorScheme` 又是什么** ？

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF4285F4)),
  ///打开 useMaterial3 样式
  useMaterial3: true,
),
```

**这里其实就涉及到一个很有趣的知识点：Material3 下的 HCT 颜色包： [material-color-utilities](https://github.com/material-foundation/material-color-utilities)** 。

在 Material3 下颜色其实不是完全按照 RGB 去计算，而是会经过  [material-color-utilities](https://github.com/material-foundation/material-color-utilities)  的转化，通过内部的 `CorePalette` 对象，RGB 会转化为 HCT 相关的值去计算显示。

![](http://img.cdn.guoshuyu.cn/20220605_N2/image8.png)

对于 HCT 其实是 Hue、Chroma、Tone 三个单词的缩写，可以解释为色相、色度和色调，通过谷歌开源的  [material-color-utilities](https://github.com/material-foundation/material-color-utilities)   插件就可以方便实现 HCT 颜色空间的接入，目前该 repo 已支持 Dart、Java 和 Typecript 等语言，另外 C/C++ 和 Object-C 也在即将支持。

![](http://img.cdn.guoshuyu.cn/20220605_N2/image9.png)

得益于 HCT ，例如我们前面的 `ColorScheme.fromSeed(seedColor: Color(0xFF4285F4))`，就可以通过一个 seedColor 直接生成一系列主题颜色，这就是 Material3 里可以拥有更丰富的主题色彩的原因。

![](http://img.cdn.guoshuyu.cn/20220605_N2/image10.png)

> 更多可见 [《HCT 的色彩原理》](https://material.io/blog/science-of-color-design)

# 最后

最后我们回顾一下，今天的小技巧有：

- 通过 `ThemeExtensions` 拓展想要的自定义 `ThemeData`
- 通过 `useMaterial3` 启用 Material3 ，并通过 `ColorScheme` 配置更丰富的 HCT 颜色

好了，现在你可以去问你的设计师：你知道什么是 HCT 么？