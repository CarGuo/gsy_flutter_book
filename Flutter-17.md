作为系列文章的第十七篇，本篇再一次带来 Flutter 开发过程中的实用技巧，让你继续弯道超车，全篇均为个人的日常干货总结，以实用填坑为主，让你少走弯路狂飙车。

## 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)

[![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image1)
](https://github.com/CarGuo/GSYGithubAppFlutter)


## 1、Package get git 失败

Flutter 项目在引用第三库时，一般都是直接引用 `pub` 上的第三方插件，但是有时候我们为了安全和私密，会选择使用 git 引用，如：

```
  photo_view:
    git:
      url: https://github.com/CarSmallGuo/photo_view.git
      ref: master
```

这时候在执行 `flutter packages get` 过程中，如果出现失败后，再次执行 `flutter packages get` 可能会遇到如下图所示的问题：

[![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image2))
](https://github.com/CarGuo/GSYGithubAppFlutter)

而 `flutter packages get` 提示 `git` 失败的原因，主要是：

在下载包的过程中出现问题，下次再拉包的时候，**在 `.pub_cache` 内的 `git` 目录下会检测到已经存在目录，但是可能是空目录等等，导致 `flutter packages get` 的时候异常。**

**所以你需要清除掉 `.pub_cache` 内的 `git` 的异常目录，然后最好清除掉项目下的 `pubspec.lock` ，之后重新执行 `flutter packages get` 。**

> `win` 一般是在 `C:\Users\xxxxx\AppData\Roaming\Pub\Cache` 路径下有 `git` 目录。
>
> `mac` 目录在 `~/.pub-cache` 。

## 2、TextEditingController


![image.png](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image3)

如上代码所示，红线部分表示，如果 `controller` 为空，就赋值一个 `TextEditingController` ，这样的写法会导致如下图所示问题：


![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image4)

**弹出键盘时输入成功后，收起键盘时输入的内容消失了！** 这是因为键盘的弹出和收起都会触发页面 `build` ，而在 `controller` 为 `null` 时，每次赋值的  `TextEditingController` 会导致 `TextField` 的 `TextEditingValue` 重置。


![image.png](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image5)

如上图所示，因为当  `TextField` 的 `controller` 不为空时，update 时是不会执行 `value` 的拷贝，所以为了避免这类问题，如下图所示， **需要先在全局构建 `TextEditingController` 再赋值，如果 `controller` 为空直接给 null 即可，避免 `build` 时每次重构 `TextEditingController` 。**


![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image6)

## 3、Scrollable


![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image7)

如上图所示，在之前第七篇的时候分析过，**滑动列表内一般都会有 `Scrollable` 的存在，而 `Scrollable` 恰好是一个 `InheritedWidget`** ，这就给我们在 `children` 中调用 `Scrollable` 相关方法提供了便利。

如下代码所依，通过 `Scrollable.of(context)` 我们可以更解耦的在 `ListView/GridView` 的 `children` 对其进行控制。

```
ScrollableState state = Scrollable.of(context)

///获取 _scrollable 内 viewport 的 renderObject
RenderObject renderObject = state.context.findRenderObject();
///监听位置更新
state.position.addListener((){});
///通知位置更新
state.position.notifyListeners();
///滚动到指定位置
state.position.jumpTo(1000);
····

```

## 4、图片高斯模糊

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image8)

在 Flutter 中，提供了 `BackdropFilter` 和 `ImageFilter` 实现了高斯模糊的支持，如下代码所示，可以快速实现上图的高斯模糊效果。

```
class BlurDemoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: new Container(
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: new Image.asset(
                "static/gsy_cat.png",
                fit: BoxFit.cover,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              )),
            new Center(
              child: new Container(
                width: 200,
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                    child: new Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new Icon(Icons.ac_unit),
                        new Text("哇！！")
                      ],
                    )))))
          ],
        )));
  }
}
```

## 5、滚动到指定位置

因为目前 Flutter 并没有直接提供滚动到指定 `Item` 的方法，在每个 `Item` 大小不一的情况下，折中利用如图下所示代码，可以快速实现滚动到指定  `Item` 的效果：


![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image9)

上图为部分代码，完整代码可见 [scroll_to_index_demo_page2.dart](https://github.com/CarGuo/GSYFlutterDemo/blob/master/lib/widget/scroll_to_index_demo_page2.dart) ，这里主要是给每个 `item` 都赋予了一个 `GlobalKey` , 利用 `findRenderObject` 找到所需 `item` 的 `RenderBox` ，然后使用 `localToGlobal` 获取 `item` 在 `ViewPort` 这个 `ancestor` 中的偏移量进行滚动：

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image10)


当然还有另外一种实现方式，具体可见  [scroll_to_index_demo_page.dart](https://github.com/CarGuo/GSYFlutterDemo/blob/master/lib/widget/scroll_to_index_demo_page.dart)


## 6、findRenderObject

在 Flutter 中是存在 **容器 Widget** 和 **渲染Widget** 的区别的，一般情况下:

- `Text`、`Sliver` 、`ListTile` 等都是属于渲染 Widget ，其内部主要是 `RenderObjectElement` 。
- `StatelessWidget` / `StatefulWidget` 等属于容器 Widget ，其内部使用的是 `ComponentElement` ， **`ComponentElement` 本身是不存在 `RenderObject` 的。**

结合前面篇章我们说过 `BuildContext` 的实现就是 `Element`，所以 `context.findRenderObject()` 这个操作其实就是 `Element` 的 `findRenderObject()` 。

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image11)

那么如上图所示，`findRenderObject` 的实现最终就是获取 `renderObject`，在 `Element` 中 `renderObject` 的获取逻辑就很清晰了，**在遇到 `ComponentElement` 时，执行的是 `element.visitChildren(visit);`** , 递归直到找到  `RenderObjectElement` 。

所以如下代码所示，`print("${globalKey.currentContext.findRenderObject()}");` 最终输出了 `SizedBox` 的 `RenderObject` 。

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image12)


## 7、行间距

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image13)


在 Flutter 中，是没有直接设置 `Text` 行间距的方法的， `Text` 显示的效果是如下图所示的逻辑组成：

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image14)

那么我们应该如何处理行间距呢？如下图所示，**通过设置 `StrutStyle` 的 `leading` , 然后利用 `Transform` 做计算翻方向位置偏移，因为 `leading` 是上下均衡的，所以计算后就可以得到我们所需要的行间距大小。** (虽然无法保证一定 100%像素准确，你是否还知道其他方法？)

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image15)


> **这里额外提一点，可以通过父节点使用 `DefaultTextStyle` 来实现局部样式的共享哦。**

## 8、Builder

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image16)

在 Flutter 中存在 `Builder` 这样一个 Widget，看源码发现它其实就是 `StatelessWidget` 的简单封装，那为什么还需要它的存在呢？


如下图所示，相信一些 Flutter 开发者在使用 `Scaffold.of(context).showSnackBar(snackbar)` 时，可能 遇到过如下错误，这是因为传入的 `context` 属于错误节点导致的，**因为此处传入的 `context` 并不能找到页面所在的 `Scaffold` 节点。**

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image17)

所以这时候 `Builder` 的作用就体现了，如下所示，通过 `builder` 方法返回赋予的 `context` ，在向上查找 `Scaffold` 的时候，就可以顺利找到父节点的 `Scaffold` 了，这也一定程度上体现了 `ComponentElement` 的作用之一。

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image18)

## 9、快速实现动画切换效果

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image19)

要实现如上图所示动画效果，在 Flutter 中提供了 `AnimatedSwitcher` 封装简易实现。

如下图所示，**通过嵌套 `AnimatedSwitcher` ，指定 `transitionBuilder` 动画效果，然后在数据改变时，同时改变需要执行动画的 `key` 值，即可达到动画切换的效果。**

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image20)

## 10、多语言显示异常

在官方的 [https://github.com/flutter/flutter/issues/36527](https://github.com/flutter/flutter/issues/36527) issue 中可以发现，**Flutter 在韩语/日语 与中文同时显示，会导致 iOS 下出现文字渲染异常的问题** ，如下图所示，左边为异常情况。

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image21)

改问题解决方案暂时有两种：

- **增加字体 ttf ，全局指定改字体显示。**

- **修改主题下所有 `TextTheme` 的 `fontFamilyFallback` ：**

```
getThemeData() {
  var themeData = ThemeData(
        primarySwatch: primarySwatch
   );

    var result = themeData.copyWith(
      textTheme: confirmTextTheme(themeData.textTheme),
      accentTextTheme: confirmTextTheme(themeData.accentTextTheme),
      primaryTextTheme: confirmTextTheme(themeData.primaryTextTheme),
    );
    return result;
}
/// 处理 ios 上，同页面出现韩文和简体中文，导致的显示字体异常
confirmTextTheme(TextTheme textTheme) {
  getCopyTextStyle(TextStyle textStyle) {
    return textStyle.copyWith(fontFamilyFallback: ["PingFang SC", "Heiti SC"]);
  }

  return textTheme.copyWith(
    display4: getCopyTextStyle(textTheme.display4),
    display3: getCopyTextStyle(textTheme.display3),
    display2: getCopyTextStyle(textTheme.display2),
    display1: getCopyTextStyle(textTheme.display1),
    headline: getCopyTextStyle(textTheme.headline),
    title: getCopyTextStyle(textTheme.title),
    subhead: getCopyTextStyle(textTheme.subhead),
    body2: getCopyTextStyle(textTheme.body2),
    body1: getCopyTextStyle(textTheme.body1),
    caption: getCopyTextStyle(textTheme.caption),
    button: getCopyTextStyle(textTheme.button),
    subtitle: getCopyTextStyle(textTheme.subtitle),
    overline: getCopyTextStyle(textTheme.overline),
  );
}
```

> ps ：**通过`WidgetsBinding.instance.window.locale;` 可以获取到手机平台本身的当前语言情况，不需要 `context` ，也不是你设置后的 `Locale` 。**


## 11、长按输入框导致异常的情况

如果项目存在多语言和主题切换的场景，可能会遇到长按输入框导致异常的场景，目前可推荐两种解放方法：

- 1、可以给你的自定义 `ThemeData` 强制指定固定一个平台，但是该方式会导致平台复制粘贴弹出框没有了平台特性：

```
 ///防止输入框长按崩溃问题
platform: TargetPlatform.android
```


- 2、增加一个自定义的 `LocalizationsDelegate` , 实现多语言环境下的自定义支持：

```


class FallbackCupertinoLocalisationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalisationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) => loadCupertinoLocalizations(locale);

  @override
  bool shouldReload(FallbackCupertinoLocalisationsDelegate old) => false;
}

class CustomZhCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const CustomZhCupertinoLocalizations();

  @override
  String datePickerMinuteSemanticsLabel(int minute) {
    if (minute == 1) return '1 分钟';
    return minute.toString() + ' 分钟';
  }

  @override
  String get anteMeridiemAbbreviation => '上午';

  @override
  String get postMeridiemAbbreviation => '下午';

  @override
  String get alertDialogLabel => '警告';

  @override
  String timerPickerHourLabel(int hour) => '小时';

  @override
  String timerPickerMinuteLabel(int minute) => '分';

  @override
  String timerPickerSecond(int second) => '秒';

  @override
  String get cutButtonLabel => '裁剪';

  @override
  String get copyButtonLabel => '复制';

  @override
  String get pasteButtonLabel => '粘贴';

  @override
  String get selectAllButtonLabel => '全选';
}

class CustomTCCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const CustomTCCupertinoLocalizations();

  @override
  String datePickerMinuteSemanticsLabel(int minute) {
    if (minute == 1) return '1 分鐘';
    return minute.toString() + ' 分鐘';
  }

  @override
  String get anteMeridiemAbbreviation => '上午';

  @override
  String get postMeridiemAbbreviation => '下午';

  @override
  String get alertDialogLabel => '警告';

  @override
  String timerPickerHourLabel(int hour) => '小时';

  @override
  String timerPickerMinuteLabel(int minute) => '分';

  @override
  String timerPickerSecond(int second) => '秒';

  @override
  String get cutButtonLabel => '裁剪';

  @override
  String get copyButtonLabel => '復制';

  @override
  String get pasteButtonLabel => '粘貼';

  @override
  String get selectAllButtonLabel => '全選';
}

Future<CupertinoLocalizations> loadCupertinoLocalizations(Locale locale) {
  CupertinoLocalizations localizations;
  if (locale.languageCode == "zh") {
    switch (locale.countryCode) {
      case 'HK':
      case 'TW':
        localizations = CustomTCCupertinoLocalizations();
        break;
      default:
        localizations = CustomZhCupertinoLocalizations();
    }
  } else {
    localizations = DefaultCupertinoLocalizations();
  }
  return SynchronousFuture<CupertinoLocalizations>(localizations);
}

```


> 自此，第十七篇终于结束了！(///▽///)

### 资源推荐

* Github ： https://github.com/CarGuo
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**
* 开源 React Native 项目：https://github.com/CarGuo/GSYGithubApp


![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image22)