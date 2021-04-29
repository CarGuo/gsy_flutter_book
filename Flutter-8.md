作为系列文章的第八篇，本篇是主要讲述 Flutter 开发过程中的实用技巧，让你少走弯路少掉坑，全篇属于很干的干货总结，以实用为主，算是在深入原理过程中穿插的实用篇章。

## 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)

#### 1、Text 的 TextOverflow.ellipsis 不生效

有时候我们为 `Text` 设置 *ellipsis* ，却发现并没有生效，而是出现如下图左边提示 `overflowed` 的警告。

其实大部分时候，这是 `Text` 内部的  `RenderParagraph` 在判断 `final bool didOverflowWidth = size.width < textSize.width;` 时， *size.width* 和 *textSize.width* 是相等导致的。

所以你需要给  `Text`  设置一个 `Container` 之类的去约束它的大小，或者是 `Row` 中通过 `Expanded` +  `Container` 去约束你的 `Text`，如果不知道于应该多大，可以通过 `LayoutBuilder` 设置。

![请无视图片](http://img.cdn.guoshuyu.cn/20190604_Flutter-8/image1)


#### 2、获取控件的大小和位置

看过第六篇的同学应该知道， 我们可以用 `GlobalKey` ，通过 *key* 去获取到控件对象的 `BuildContext`，而前面我们也说过 `BuildContext` 的实现其实是 `Element` ，而 `Element` 持有 `RenderObject` 。So，我们知道的 `RenderObject ` ，实际上获取到的就是 `RenderBox` ，那么通过 RenderBox 我们就只大小和位置了：
```
  showSizes() {
    RenderBox renderBoxRed = fileListKey.currentContext.findRenderObject();
    print(renderBoxRed.size);
  }

  showPositions() {
    RenderBox renderBoxRed = fileListKey.currentContext.findRenderObject();
    print(renderBoxRed.localToGlobal(Offset.zero));
  }
```


#### 3、获取状态栏高度和安全布局

如果你看过 `MaterialApp` 的源码，你应该会看到它的内部是一个 `WidgetsApp` ，而 `WidgetsApp` 内有一个 `MediaQuery`，熟悉它的朋友知道我们可以通过 `MediaQuery.of(context).size` 去获取屏幕大小。

其实 `MediaQuery` 是一个 `InheritedWidget` ，它有一个叫 `MediaQueryData` 的参数，这个参数是通过如下图设置的，再通过源码我们知道，一般情况下 `MediaQueryData` 的 `padding` 的 `top` 就是状态栏的高度。

所以我们可以通过 `MediaQueryData.fromWindow(WidgetsBinding.instance.window).padding.top  ` 获取到状态栏高度，当然有时候可能需要考虑 `viewInsets` 参数。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-8/image2)

至于 `AppBar ` 的高度，默认是 ` Size.fromHeight(kToolbarHeight + (bottom?.preferredSize?.height ?? 0.0)),`，*kToolbarHeight* 是一个固定数据，当然你可以通过实现 `PreferredSizeWidget` 去自定义 `AppBar`。

同时你可能会发现，有时候在布局时发现布局位置不正常，居然是从状态栏开始计算，这时候你需要用 `SafeArea` 嵌套下，至于为什么，看源码你就会发现 `MediaQueryData` 的存在。

#### 4、设置状态栏颜色和图标颜色

简单的可以通过 `AppBar` 的 *brightness* 或者 `ThemeData` 去设置状态栏颜色。

但是如果你不想用 `AppBar` ，那么你可以嵌套 `AnnotatedRegion<SystemUiOverlayStyle>` 去设置状态栏样式，通过 `SystemUiOverlayStyle` 就可以快速设置状态栏和底部导航栏的样式。

同时你还可以通过 `SystemChrome.setSystemUIOverlayStyle` 去设置，前提是你没有使用  `AppBar` 。**需要注意的是，所有状态栏设置是全局的，** 如果你在 A 页面设置后，B 页面没有手动设置或者使用 AppBar ，那么这个设置将直接呈现在 B 页面。

#### 5、系统字体缩放

现在的手机一般都提供字体缩放，这给应用开发的适配上带来一定工作量，所以大多数时候我们会选择禁止应用跟随系统字体缩放。

在 Flutter 中字体缩放也是和 `MediaQueryData` 的 `textScaleFactor` 有关。所以我们可以在需要的页面，通过最外层嵌套如下代码设置，将字体设置为默认不允许缩放。

```
    MediaQuery(
      data: MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(textScaleFactor: 1),
      child: new Container(),
    );
```

#### 6、Margin 和 Padding

在使用 `Container` 的时候我们经常会使用到 *margin* 和 *padding* 参数，其实在上一篇我们已经说过， `Container` 其实只是对各种布局的封装，内部的 *margin* 和 *padding* 其实是通过 `Padding` 实现的，而  `Padding`  不支持负数，所以如果你需要用到负数的情况下，推荐使用 `Transform ` 。

```
  Transform(
      transform: Matrix4.translationValues(10, -10, 0),
      child: new Container(),
    );
```

#### 7、控件圆角裁剪

日常开发中我们大致上会使用两种圆角方案：

- 一种是通过 `Decoration`  的实现类 `BoxDecoration` 去实现。
- 一种是通过 `ClipRRect` 去实现。

其中 `BoxDecoration`  一般应用在 `DecoratedBox` 、 `Container` 等控件，这种实现一般都是直接 *Canvas* 绘制时，针对当前控件的进行背景圆角化，并不会影响其 *child* 。这意味着如果你的  *child*  是图片或者也有背景色，那么很可能圆角效果就消失了。

而  `ClipRRect` 的效果就是会影响   *child*  的，具体看看其如下的 RenderObject 源码可知。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-8/image3)

#### 8、PageView

如果你在使用 `TarBarView` ，并且使用了 `KeepAlive` 的话，那么我推荐你直接使用 `PageView` 。因为目前到 1.2 的版本，在 `KeepAlive` 的 状态下，跨两个页面以上的 Tab 直接切换， `TarBarView`  会导致页面的 `dispose` 再重新 `initState`。尽管  `TarBarView`   内也是封装了   `PageView`  + `TabBar` 。

你可以直接使用  `PageView`  + `TabBar` 去实现，然后 tab 切换时使用 `_pageController.jumpTo(MediaQuery.of(context).size.width * index);` 可以避免一些问题。当然，这时候损失的就是动画效果了。事实上 `TarBarView` 也只是针对 `PageView`  + `TabBar` 做了一层封装。

除了这个，其实还有第二种做法，使用如下方 **`PageStorageKey`** 保持页面数状态，但是因为它是 *save and restore values*  ，所以的页面的 `dispose` 再重新 `initState` 方法，每次都会被调用。

```
    return new Scaffold(
      key: new PageStorageKey<your value type>(your value)
    )
```
#### 9、懒加载

Flutter 中通过  `FutureBuilder` 或者 `StreamBuilder` 可以和简单的实现懒加载，通过 `future` 或者 `stream` “异步” 获取数据，之后通过 `AsyncSnapshot` 的 data 再去加载数据，至于流和异步的概念，以后再展开吧。

#### 10、Android 返回键回到桌面

Flutter 官方已经为你提供了 [android_intent](https://github.com/flutter/plugins/blob/master/packages/android_intent) 插件了，这种情况下，实现回到桌面可以如下简单实现：

```
  Future<bool> _dialogExitApp(BuildContext context) async {
    if (Platform.isAndroid) {
      AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: "android.intent.category.HOME",
      );
      await intent.launch();
    }

    return Future.value(false);
  }
·····
 return WillPopScope(
      onWillPop: () {
        return _dialogExitApp(context);
      },
      child:xxx);
```

>自此，第八篇终于结束了！(///▽///)

### 资源推荐

* Github ： [https://github.com/CarGuo/](https://github.com/CarGuo)
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**

##### 完整开源项目推荐：

* [GSYGithubApp Flutter](https://github.com/CarGuo/GSYGithubAppFlutter ) 
* [GSYGithubApp React Native](https://github.com/CarGuo/GSYGithubApp ) 
* [GSYGithubAppWeex](https://github.com/CarGuo/GSYGithubAppWeex)



![我们还会再见吗？](http://img.cdn.guoshuyu.cn/20190604_Flutter-8/image4)