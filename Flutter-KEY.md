

最近刚好有网友咨询一个问题，那就顺便借着这个问题给大家深入介绍下 Flutter 中键盘弹起时，`Scaffold` 的内部发生了什么变化，让大家更好理解 Flutter 中的输入键盘和 `Scaffold` 的关系。

如下图所示，当时的问题是：*当界面内有 `TextField` 输入框时，点击键盘弹起后，界面内底部的按键和 FloatButton 会被挤到键盘上面，有什么办法可以让底部按键和 FloatButton 不被顶上来吗？*

![](http://img.cdn.guoshuyu.cn/20210429_Flutter-KEY/image1)


其实解决这个问题很简单，那就是只要**把 `Scaffold` 的 `resizeToAvoidBottomInset` 配置为 `false`** ，结果如下图所示，键盘弹起后底部按键和 FloatButton 不会再被顶上来，问题解决。**那为什么键盘弹起会和 `resizeToAvoidBottomInset` 有关系？**


![](http://img.cdn.guoshuyu.cn/20210429_Flutter-KEY/image2)




### Scaffold 的 resize


`Scaffold` 是 Flutter 中最常用的页面脚手架，前面知道了通过 `resizeToAvoidBottomInset` ，我们可以配置在键盘弹起时页面的底部按键和 FloatButton 不会再被顶上来，其实这个行为是因为 `Scaffold` 的 `body` 大小被 `resize` 了。


那这个过程是怎么发生的呢？首先如下图所示，我们在 `Scaffold`  的源码里可以看到，当`resizeToAvoidBottomInset` 为 true 时，会使用 `mediaQuery.viewInsets.bottom` 作为 `minInsets` 的参数，也就是可以确定：**键盘弹起时的界面 `resize` 和 `mediaQuery.viewInsets.bottom` 有关系**。

![](http://img.cdn.guoshuyu.cn/20210429_Flutter-KEY/image3)


而如下图所示， `Scaffold` 内部的布局主要是靠 `CustomMultiChildLayout` ，`CustomMultiChildLayout` 的布局逻辑主要在 `MultiChildLayoutDelegate` 对象里。

前面获取到的 `minInsets`  会被用到 `_ScaffoldLayout` 这个 `MultiChildLayoutDelegate` 里面，也就是说  **`Scaffold` 的内部是通过 `CustomMultiChildLayout` 实现的布局，具体实现逻辑在  `_ScaffoldLayout` 这个 `Delegate` 里**。



![](http://img.cdn.guoshuyu.cn/20210429_Flutter-KEY/image4)


> 关于 `CustomMultiChildLayout` 的详细使用介绍在之前的文章 [《详解自定义布局实战》](https://juejin.cn/post/6844903878509461518#heading-10) 里可以找到。


接着看 `_ScaffoldLayout` ， 在  `_ScaffoldLayout`  进行布局时，会通过传入的
 `minInsets` 来决定 `body` 显示的 `contentBottom` ， 所以可以看到**事实上传入的 `minInsets` 改变的是 `Scaffold` 布局的 bottom 位置**。
 
![](http://img.cdn.guoshuyu.cn/20210429_Flutter-KEY/image5)


> 上图代码中使用的 `_ScaffoldSlot.body` 这个枚举其实是作为 `LayoutId` 的值，`MultiChildLayoutDelegate` 在布局时可以通过 `LayoutId` 获取到对应 child 进行布局操作，详细可见： [《详解自定义布局实战》](https://juejin.cn/post/6844903878509461518#heading-10) 

![](http://img.cdn.guoshuyu.cn/20210429_Flutter-KEY/image6)


那么 `Scaffold` 的 `body` 是什么呢？ 如上图代码所示，其实  `Scaffold`  的 `body` 是一个叫 `_BodyBuilder` 的对象，而这个  `_BodyBuilder` 内部其实是一个 `LayoutBuilder`。（注意，在 `widget.appbar` 不为 `null` 时，会 `removeTopPadding`）

所以如下图代码所示 `body` 在添加时，**它父级的`MediaQueryData` 会被重载，特别是 `removeTopPadding` 会被清空，`viewInsets.bottom` 也是会被重置**。

![](http://img.cdn.guoshuyu.cn/20210429_Flutter-KEY/image7)


最后如下代码所示，`_BodyBuilder` 的 `LayoutBuilder` 里会获取到一个 `top` 和 `bottom` 的参数，这两个参数都通过前面在  `_ScaffoldLayout` 布局时传入的 `constraints` 去判断得到，最终 `copyWith` 得到新的 `MediaQuery` 。

![](http://img.cdn.guoshuyu.cn/20210429_Flutter-KEY/image8)


这里就涉及到一个有意思的点，在 `_BodyBuilder` 里的通过 `copyWith` 得到新的 `MediaQuery` 会影响什么呢？如下代码所示，这里用一个简单的例子来解释下。


```dart
class MainWidget extends StatelessWidget {
  final TextEditingController controller =
      new TextEditingController(text: "init Text");
  @override
  Widget build(BuildContext context) {
    print("Main MediaQuery padding: ${MediaQuery.of(context).padding} viewInsets.bottom: ${MediaQuery.of(context).viewInsets.bottom}");
    return Scaffold(
      appBar: AppBar(
        title: new Text("MainWidget"),
      ),
      extendBody: true,
      body: Column(
        children: [
          new Expanded(child: InkWell(onTap: (){
            FocusScope.of(context).requestFocus(FocusNode());
          })),
          ///增加 CustomWidget
          CustomWidget(),
          new Container(
            margin: EdgeInsets.all(10),
            child: new Center(
              child: new TextField(
                controller: controller,
              ),
            ),
          ),
          new Spacer(),
        ],
      ),
    );
  }
}
class CustomWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("Custom MediaQuery padding: ${MediaQuery.of(context).padding} viewInsets.bottom: ${MediaQuery.of(context).viewInsets.bottom}\n  \n");
    return Container();
  }
}

```

如上代码所示：

- 代码中定义了 `MainWidget` 和 `CustomWidget` 两个控件；
- `MainWidget`  里使用了 `Scaffold` ，并且 `CustomWidget` 在 `MainWidget`  里被使用；
- 分别在这两个 Widget 的`build` 方法里打印出对应的 `MediaQuery.of(context).padding` 和  `MediaQuery.of(context).viewInsets.bottom` 的值；

如下图所示，在键盘弹起和不弹起时可以看到 `padding` 值是不同的，而 `viewInsets.bottom` 都为 0。
 
![](http://img.cdn.guoshuyu.cn/20210429_Flutter-KEY/image9)

为什么  `padding` 值的 `top` 会不一致，**自然是因为 `CustomWidget` 和 `MainWidget`获取到的 `MediaQuery.of(context)` 对象不是同一个数据。**


- `MainWidget` 使用的 `MediaQuery.of(context)` 得到的 `MediaQueryData` 是上级往下传递的，里面**包含了 `top:47` 的状态栏高度和 `bottom:34` 的底部安全区域高度**。


- `CustomWidget`  里面 `MediaQuery.of(context)` 得到的 `MediaQueryData` ，自然就是前面分析过的 `_BodyBuilder` 里的通过 `copyWith` 得到新的 `MediaQuery`，所以  `CustomWidget`  得到的 `MediaQueryData` 其实**在 `Scaffold` 内部已经被重置了，所以它的 `top:0` ，获取不到状态栏高度**。


> 事实上这就是大家为什么有时候 **`MediaQuery.of( context)` 可以获取到状态栏高度，有时候又获取不到的原因**，因为你的 `context` 获取到的是 `Scaffold` 之外的 `MediaQueryData`， 还是 `Scaffold`  内被重载过的 `MediaQueryData`，自然会得到不一样的结果。


如下图所示，键盘弹起因为被 resize 了，所以界面的 `bottom` 安全区域变成了 0 ，而

- 在 `MainWidget` 中可以获取到 `viewInsets.bottom` 也就是键盘的高度；
- 在 `CustomWidget` 获取不到 `viewInsets.bottom` ，因为在 `Scaffold` 内被重载清除了。


![](http://img.cdn.guoshuyu.cn/20210429_Flutter-KEY/image10)


总结一下：**`Scaffold` 的 `resizeToAvoidBottomInset` 会通过 `MediaQueryData` 影响 body 的布局，同时在 `Scaffold` 内 `MediaQuery` 会被重载，所以使用的 `context` 位置不同，获取到的 `MediaQueryData`  也不同，如果需要获取键盘高度和状态栏高度的话，最好使用  `Scaffold`  外的  `context` 。** 


![](http://img.cdn.guoshuyu.cn/20210429_Flutter-KEY/image11)


> 这里讲了 `MediaQuery`  和 `MediaQueryData` 的内容，为什么 `MediaQuery` 通过嵌套就可以重载？为什么通过 `context` 可以往上获取到离 `context` 最近的  `MediaQueryData`？因为 `MediaQuery` 是一个 `InheritedWidget` : [《全面理解State》](https://juejin.cn/post/6844903866706706439#heading-5) 。



### 键盘如何影响 Scaffold 


前面我们聊了 `Scaffold` 的 `resizeToAvoidBottomInset` 会通过 `MediaQueryData` 影响 body 的布局，那是怎么影响的呢？


事实上这得从 `MaterialApp` 说起，在  `MaterialApp`  内部的深处嵌套着一个叫 `_MediaQueryFromWindow` 的 Widget ，它在内部通过 ` WidgetsBinding.instance.addObserver` 对 App 的各种系统事件做了监听，并且对应都执行了 `setState` 。

所以如下源码所示，当键盘弹出时， `build` 方法会被执行， 而 `MediaQueryData` 就会通过`MediaQueryData.fromWindow` 获取到新的 `MediaQueryData` 数据。


```dart
 @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // ACCESSIBILITY

  @override
  void didChangeAccessibilityFeatures() {
    setState(() { });
  }

  // METRICS

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  @override
  void didChangeTextScaleFactor() {
    setState(() { });
  }

  // RENDERING
  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    MediaQueryData data = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    if (!kReleaseMode) {
      data = data.copyWith(platformBrightness: debugBrightnessOverride);
    }
    return MediaQuery(
      data: data,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
```



举个例子，如下图所示，从 Android 的 Java 层弹出键盘开始，会把改变后的视图信息传递给 C++ 层，最后回调到 Dart 层，从而触发 `MaterialApp` 内的 `didChangeMetrics` 方法执行 ` setState(() {});` ，进而让  `_MediaQueryFromWindow` 内的 `build` 更新了 `MediaQueryData` ，最终改变了 `Scaffod` 的 `body` 大小。

![](http://img.cdn.guoshuyu.cn/20210429_Flutter-KEY/image12)

那么到这里，你知道如何在 Flutter 里正确地去获取键盘的高度了吧？

### 最后

从一个简单的 `resizeToAvoidBottomInset` 去拓展到 `Scaffod` 的内部布局和 `MediaQueryData` 与键盘的关系，其实这也是学习框架过程中很好的知识延伸，通过特定的问题去深入理解框架的实现原理，最后再把知识点和问题关联起来，这样问题在此之后便不再是问题，因为入脑了～

![](http://img.cdn.guoshuyu.cn/20210429_Flutter-KEY/image13)


