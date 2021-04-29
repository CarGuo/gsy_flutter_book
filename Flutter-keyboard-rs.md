事情是这样的，由于近期 Flutter 发布了 `1.17` 的稳定版，按照“惯例”开始着手把生产项目升级到 `1.12.13+hotfix.9` 版本，在升级适配完成之后，一个突如其来的 Bug 让我陷入了沉思。


![](http://img.cdn.guoshuyu.cn/20200519_Flutter-keyboard-rs/image1)

如上图所示，可以看到在键盘 B 页面打开后，退回上一个页面 A 时键盘已经收起，但是原先键盘所在的区域在 A 页面变成了空白，而 A 页面内容也被 `resize` 成了键盘弹出后的大小。

### 1、Scaffold

**针对这个问题，首先想到的 `Scaffold` 的 `resizeToAvoidBottomInset` 属性。**


在 Flutter 中 `Scaffold` 默认情况下 `resizeToAvoidBottomInset` 为 `true`，当 `resizeToAvoidBottomInset` 为 `true` 时，`Scaffold` 内部会将 `mediaQuery.viewInsets.bottom` 参与到 `BoxConstraints` 的大小计算，也就是**键盘弹起时调整了内部的 `bottom` 位置来迎合键盘。**

但是问题发送在 A 界面，这时候键盘已经收起，`mediaQuery.viewInsets.bottom` 应该更新为 0 ，那为何界面没有产生应有的更新呢？

### 2、MediaQuery

那么猜测问题可能出现在 `MediaQuery` 上。

**从源码我们得知 `MediaQuery` 是一个 `InheritedWidget`，它会往下共享对应的 `MediaQueryData`，在 `MediaQueryData` 中保存了各种设备的信息**，比如 `size` 、`devicePixelRatio` 、 `textScaleFactor` 、 `viewPadding` 以及 `viewInsets` 等。

那 `viewInsets` 是什么的呢？官方的解释是：

> “可以被系统显示的区域，通常是和设备的键盘等相关，当键盘弹出时 `viewInsets.bottom` 对应的就是键盘的顶部。”

那上面的 bug 看起来可能就是 `Scaffold` 的 `viewInsets.bottom` 在键盘收起来时没有正常重置。

### 3、Window

那这里首先我们要知道 `MediaQuery` 的 `viewInsets` 是怎么被设置的？

通过分析源码可以知道 **`MediaQuery` 的 `MediaQueryData` 来源于 `WidgetsBinding.instance.window`**，默认是在 `MaterialApp` 的 `_MediaQueryFromWindow` 中被设置：

```
  @override
  void didChangeMetrics() {
    setState(() {
      // The properties of window have changed. We use them in our build
      // function, so we need setState(), but we don't cache anything locally.
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQueryData.fromWindow(WidgetsBinding.instance.window),
      child: widget.child,
    );
  }
```

如上代码可以看到 `MediaQuery` 的 `MediaQueryData` 是来源于 `Window`，并且这里还注册了 `WidgetsBindingObserver` 的 `didChangeMetrics` 回调，也就是当 `window` 改变时，调用  `setState` 来更新 `MediaQuery` 中的 `MediaQueryData` 。

而在 `MediaQueryData.fromWindow` 中， `viewInsets` 是通过将 `window.viewInsets` 和 `window.devicePixelRatio` 相除后得到的像素密度值。

```
viewInsets = EdgeInsets.
fromWindowPadding(window.viewInsets, window.devicePixelRatio),
```

那 `Window` 的值又是哪里来的？

其实 **`Window` 的值来源于 Flutter Engine，在键盘弹出时 Flutter Engine 会通过 `_updateWindowMetrics` 方法更新 `Window` 数据，并执行 `window.onMetricsChanged` 和 `window._onMetricsChangedZone` 方法。**

**其中 `onMetricsChanged` 回调最终会触发 `handleMetricsChanged` 方法，从而执行 `scheduleForcedFrame()` 更新界面和 ` observer.didChangeMetrics();` 通知  `MaterialApp`  中的 `MediaQueryData` 更新。**


```
@pragma('vm:entry-point')
// ignore: unused_element
void _updateWindowMetrics(
  double devicePixelRatio,
  double width,
  double height,
  double depth,
  double viewPaddingTop,
  double viewPaddingRight,
  double viewPaddingBottom,
  double viewPaddingLeft,
  double viewInsetTop,
  double viewInsetRight,
  double viewInsetBottom,
  double viewInsetLeft,
  double systemGestureInsetTop,
  double systemGestureInsetRight,
  double systemGestureInsetBottom,
  double systemGestureInsetLeft,
) {
  window
    .._devicePixelRatio = devicePixelRatio
    .._physicalSize = Size(width, height)
    .._physicalDepth = depth
    .._viewPadding = WindowPadding._(
        top: viewPaddingTop,
        right: viewPaddingRight,
        bottom: viewPaddingBottom,
        left: viewPaddingLeft)
    .._viewInsets = WindowPadding._(
        top: viewInsetTop,
        right: viewInsetRight,
        bottom: viewInsetBottom,
        left: viewInsetLeft)
    .._padding = WindowPadding._(
        top: math.max(0.0, viewPaddingTop - viewInsetTop),
        right: math.max(0.0, viewPaddingRight - viewInsetRight),
        bottom: math.max(0.0, viewPaddingBottom - viewInsetBottom),
        left: math.max(0.0, viewPaddingLeft - viewInsetLeft))
    .._systemGestureInsets = WindowPadding._(
        top: math.max(0.0, systemGestureInsetTop),
        right: math.max(0.0, systemGestureInsetRight),
        bottom: math.max(0.0, systemGestureInsetBottom),
        left: math.max(0.0, systemGestureInsetLeft));
  _invoke(window.onMetricsChanged, window._onMetricsChangedZone);
}
```

所以可以看到，当键盘弹出和收起时，`Engine` 会更新 `Window` 的数据，`Window` 触发界面绘制更新，同时更新 `MaterialApp` 中的 `MediaQueryData` 。

![](http://img.cdn.guoshuyu.cn/20200519_Flutter-keyboard-rs/image2)

### 4、Route

那按照这个情况，不可能出现上述键盘导致空白区域的问题，那问题**可能就是出现在 `Scaffold` 使用的 `MediaQueryData` 没有更新**。

这时候我突然想起，之前为了锁定页面的字体大小不跟随系统缩放，我在路由层使用了 `MediaQueryData.fromWindow` 复制一份 `MediaQuery`，问题很可能出在这里：

```
Navigator.of(context).push(new CupertinoPageRoute(builder: (context) {
   return MediaQuery(
      data:MediaQueryData.fromWindow(WidgetsBinding.instance.window)
                         .copyWith(textScaleFactor: 1),
                  child: Page2(), );
   }));
```


不过这也不对，出现问题的是有键盘的 B 页面返回到没有键盘的 A 页面，这时候 A 页面已经打开，那之前打开 A 页面的 `WidgetsBinding.instance.window` 应该是对的，而 **A 页面所在的 `CupertinoPageRoute` 的 `builder` 方法，不可能在键盘 B 页面打开时再次被执行才对？**


但是在经过调试后震惊的发现，程序在进入 B 页面弹出键盘后，居然会触发了 A 页面 `CupertinoPageRoute` 的 `builder` 方法重新执行。


**能够在跨页面触发更新，第一个想到的就是全局的状体管理框架**，因为应用需要全局切换*主题、多语言和用户信息共享*等，在应用的顶层一般会通过状体管理框架往下共享和管理这些信息。

由于原本项目比较复杂，所以重新做了一个简单的测试 Demo ，并且引入比较简单的 `ScopedModel` 框架管理，然后在打开有键盘的 B 页面后执行延时一会执行`notifyListeners();`，发现果然出现了同样的问题。


```
    return ScopedModel(
      model: t,
      child: ScopedModelDescendant<TestModel>(
        builder: (context, child, model) {
          return MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: MyHomePage(title: 'Flutter Demo Home Page'),
          );
        },
      ),
    );
```

### 5、Navigator


这里不禁就有疑问，为什么 `MaterialApp` 的更新会导致 `PageRoute` 重新 `builder` 呢？

这就涉及 `Navigator` 的相关逻辑，我们常用的 `Navigator` 其实是一个 `StatefulWidget`，当  `MaterialApp` 被更新时，可以看到在 `NavigatorState` 的 `didUpdateWidget` 回调中会调用 `_history` 里所有路由的 `changedExternalState()` 方法。


```
 @override
  void didUpdateWidget(Navigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.observers != widget.observers) {
      for (NavigatorObserver observer in oldWidget.observers)
        observer._navigator = null;
      for (NavigatorObserver observer in widget.observers) {
        assert(observer.navigator == null);
        observer._navigator = this;
      }
    }
    for (Route<dynamic> route in _history)
      route.changedExternalState();
  }
  
```

而 `changedExternalState` 执行后会调用 `_forceRebuildPage` 将路由里的 `_page` 清空，这样自然下次 `Route` 在 `build` 时触发的 `PageRoute` 重新 `builder` 方法。


 ```
 @override
  void changedExternalState() {
    super.changedExternalState();
    if (_scopeKey.currentState != null)
      _scopeKey.currentState._forceRebuildPage();
  }
  
·····

  void _forceRebuildPage() {
    setState(() {
      _page = null;
    });
  }
 
 ```

所以回归到最初的问题：**这个 bug 首先是因为不规范使用了 `MediaQueryData.fromWindow(WidgetsBinding.instance.window)` ，之后又恰好在有键盘的页面打开后触发了 `MaterialApp ` 的更新，导致了 `PageRoute` 重新 `builder`， 使得没有键盘的 `Scaffold` 使用了弹出键盘的 `viewInsets.bottom`。**

**所以这里只需要将 `MediaQueryData.fromWindow` 换成 `MediaQuery.of(context)` 就可以解决问题，而当在没有 `context` 或者需要直接使用 `MediaQueryData.fromWindow` 时，那一定要搭配上 `WidgetsBindingObserver.didChangeMetrics` 配合更新。**

```
    Navigator.of(context).push(new CupertinoPageRoute(builder: (context) {
      return MediaQuery(
        data:MediaQuery.of(context)
            .copyWith(textScaleFactor: 1),
        child: Page2(), );
    }));
```


最后说一句，虽然这个 bug 并不复杂，但是恰好能带出挺多经常忽略的知识点，所以长篇介绍这么多，也希望这样的 bug 解决思路，可以帮助到大家在日常开发过程中解决更多问题。

 

![](http://img.cdn.guoshuyu.cn/20200519_Flutter-keyboard-rs/image3)