我们都知道在 Flutter 中可以通过 `fontFamily` 来引入第三方字体，例如**通常会将 svg 图标转换为 `iconfont.ttf` 来实现矢量图标的入**，而一般情况下我们是不会设置 `fontFamily` 来使用第三方字体， 那默认情况下 Flutter 使用的是什么字体呢？


会出现这个疑问，是因为有一天设计给我发了下面那张图，问我 *“为什么应用在苹果平台上的英文使用的是 `PingFang SC` 字体而不是 `.SF UI Display` ”* ？ 正如下图所示，它们的 *G* 字母在显示效果上会有所差异，比如 平方的 *G* 有明显的转折线。


![](http://img.cdn.guoshuyu.cn/20200619_Flutter-Font-Other/image1)


**这时候我不禁产生的好奇，在 Flutter 中引擎默认究竟是如何选择字体？**

通过官方解释，在 
`typography.dart` 源码中可以看到，

- Flutter 默认在 Android 上使用的是 `Roboto` 字体；
- 在 iOS 上使用的是 `.SF UI Display` 或者 `.SF UI Text` 字体。

> The default font on Android is Roboto and on iOS it is .SF UI Display or .SF UI Text (SF meaning San Francisco). If you want to use a different font, then you will need to add it to your app. 

![](http://img.cdn.guoshuyu.cn/20200619_Flutter-Font-Other/image2)

那理论上在 iOS 使用的就是 `.SF UI Display` 字体才对，因为如下源码所示，在 `Typography` 中当  `platform` 是 `iOS` 时，使用的就是 `Cupertino` 相关的 `TextTheme`，而 `Typography`  中的 `white` 和 `black` 属性最终会应用到 `ThemeData` 的 `defaultTextTheme`、 `defaultPrimaryTextTheme` 和  `defaultAccentTextTheme` 中，所以应该是使用 `.SF` 相关字体才会，为什么会显示的是 `PingFang SC` 的效果？

```
 factory Typography({
    TargetPlatform platform = TargetPlatform.android,
    TextTheme black,
    TextTheme white,
    TextTheme englishLike,
    TextTheme dense,
    TextTheme tall,
  }) {
    assert(platform != null || (black != null && white != null));
    switch (platform) {
      case TargetPlatform.iOS:
        black ??= blackCupertino;
        white ??= whiteCupertino;
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        black ??= blackMountainView;
        white ??= whiteMountainView;
    }
    englishLike ??= englishLike2014;
    dense ??= dense2014;
    tall ??= tall2014;
    return Typography._(black, white, englishLike, dense, tall);
  }
```

为了搞清不同系统上字体的区别，在查阅了资料后可知：

- 默认在 iOS 上：

   - 中文字体：`PingFang SC`

   - 英文字体：`.SF UI Text` 、`.SF UI Display`

- 默认在 Android 上：

   - 中文字体：`Source Han Sans` / `Noto`

    - 英文字体：`Roboto`

也就是就 iOS 上除了 `.SF` 相关的字体外，还有 `PingFang` 字体的存在，这时候我突然想起在之前的 [《Flutter完整开发实战详解(十七、 实用技巧与填坑二)》](https://juejin.im/post/5d6cb579f265da03da24aeb9#heading-10) 中，因为国际化多语言在 `.SF` 会出现显示异常，所以使用了 `fontFamilyFallback` 强行指定了 `PingFang SC` 。


```
  getCopyTextStyle(TextStyle textStyle) {
    return textStyle.copyWith(fontFamilyFallback: ["PingFang SC", "Heiti SC"]);
  }
```


![](http://img.cdn.guoshuyu.cn/20200619_Flutter-Font-Other/image3)

终于破案了，因为当 `fontFamily` 没有设置时，就会使用 `fontFamilyFallback` 中的第一个值将作为首选字体，而在 `fontFamilyFallback` 中是顺序匹配的，当`fontFamily` 和 `fontFamilyFallback` 两者都不提供，则将使用默认平台字体。


而在 1.12.13 版本下测试发现 `.SF` 导致的问题已经修复了，所以只需要将 `fontFamilyFallback` 相关的代码去除即可。

**那在 iOS 上使用 `.SF` 字体有什么好处？** 按照网络上的说法是：

> `SF Text` 的字距及字母的半封闭空间，比如 `"a"!` 上半部分会更大，因其可读性更好，适用于更小的字体; `SF Display` 则适用于偏大的字体。具体分水岭就是 `20pt` , 即字体小于 `20pt` 时用 `Text` ，大于等于 `20pt` 时用 `Display` 。
>
> 更棒的是由于 `SF` 属于动态字体，`Text` 和 `Display` 两种字体族是系统动态匹配的，也就是说你不用费心去自己手动调节，系统自动根据字体的大小匹配这两种显示模式。


那能不能在 Android 上也使用`.SF` 字体呢？按照官方的说法：

- 在使用 Material package 时，在 Android 上使用的是 ·Roboto font· ，而 iOS 使用的是 `San Francisco font(SF)` ；
- 在使用 Cupertino package 时，默认主题始终使用 `San Francisco font(SF)` ；

**但是因为 `San Francisco font license` 限制了该字体只能在 iOS、macOS 或 tvOS 上运行使用，所以如果使用了 Cupertino 主题的话，在 Android 上运行时使用 fallback font。**


所以你觉得能不能在 Android 上使用？


最后再补充下，在官方的 [architecture](https://github.com/flutter/flutter/wiki/The-Engine-architecture) 中有提到，在 Flutter 中的文本呈现逻辑是有分层的，其中：

- 衍生自 Minikin 的 libtxt 库用于字体选择，分隔行等；
- HartBuzz 用于字形选择和成型；
- Skia作为 渲染 / GPU后端；
- 在 Android / Fuchsia 上使用 FreeType 渲染，在 iOS 上使用CoreGraphics 来渲染字体 。


> 那读完本篇，你奇奇怪怪的知识点有没有增加？



![](http://img.cdn.guoshuyu.cn/20200619_Flutter-Font-Other/image4)