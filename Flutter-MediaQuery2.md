# Flutter 小技巧之通过 MediaQuery 优化 App 性能

许久没更新小技巧系列，温故知新，在两年半前的[《 MediaQuery 和 build 优化你不知道的秘密》](https://juejin.cn/post/7114098725600903175) 我们聊过了在 Flutter 内 MediaQuery 对应 rebuild 机制，由于 MediaQuery 在 `MaterialApp` 内，并且还是一个 `InheritedWidget` ， **所以每当你使用一个  `MediaQuery.of(context)` ，其实就是在向 `InheritedWidget` 内登记更新绑定** ：

![](http://img.cdn.guoshuyu.cn/20250227_MediaQuery2/image1.png)

具体例子如下图所示：

- 我们在 `MyHomePage`  使用了 `MediaQuery.of(context)`  
- 然后我们跳转到 `EditPage`
- 在  `EditPage `  打开键盘，然后作为上一级页面的  `MyHomePage`   触发了一些列 rebuild 打印

![](http://img.cdn.guoshuyu.cn/20250227_MediaQuery2/image2.gif)

上面的例子很好诠释了  `MediaQuery.of(context)`  使用不当的后果，**特别是当堆栈内页面多的时候，就有很多不必要的开销**，而要知道  `MediaQuery` 涉及 20 来参数，从各种边界到字体大小再到界面比例，可以说在 UI 适配时是经常使用的对象，特别是折叠屏场景更是必不可少，所以合理使用   `MediaQuery`  就非常重要。

![](http://img.cdn.guoshuyu.cn/20250227_MediaQuery2/image3.gif)



而事实上同样代码，你只需要将   `MediaQuery.of(context)`   挪到页面  `Scaffold`  内去使用它的 `ctx`，就会发现第二个页面打开键盘时第一个页面不会触发 rebuild 了：

![](http://img.cdn.guoshuyu.cn/20250227_MediaQuery2/image4.gif)

而为什么放到页面  `Scaffold`  内去使用 context 就好很多？这是因为   `Scaffold`   内通过「覆盖」`MediaQuery` ，让他的 body  等 child 部分在   `MediaQuery.of(context)`  时获取到的是  `Scaffold`   内的 `MediaQueryData` ： 

![](http://img.cdn.guoshuyu.cn/20250227_MediaQuery2/image5.png)

另外由于  `Scaffold`  内部也大量使用 `MediaQuery` ，在触发 `MediaQueryData`  更新时，也会触发  `Scaffold`   的更新，  所以其内部像 body 等参数，也会通过 `widget.body` 实例等方式，从而避免由于  `MediaQuery`  更新导致其 child 重复 rebuild 的问题 ：

> 更多细节可见：[《 MediaQuery 和 build 优化你不知道的秘密》](https://juejin.cn/post/7114098725600903175) 

所以我们知道，**使用  `MediaQuery`  拿的是哪个 context 很重要**，如果用错了非  `Scaffold`   的 context ，那么就很容易造成不必要的性能损耗。

> 而不同 context 也可能让你拿到不一样的参数结果，比如各种 padding 。

但是，前面我们说到 `MediaQuery`  本身带有那么多参数，如果我们只是在意  `size` ，但是键盘弹出的时候改变的是 `viewInsets` ，如果这样也导致页面更新，好像也不是很合理，所以后来（3.10） Flutter 更新了 `MediaQuery.propertyOf `  系列方法。

比如还是一开始的代码，但是我把 `MediaQuery.Of(context)`  换成  `MediaQuery.sizeOf(context)  `，入下图所示，在弹出键盘时同样不会触发上一级的 `MyHomePage` 的 rebuild ，因为此时它关联的是独立的 size 参数：

![](http://img.cdn.guoshuyu.cn/20250227_MediaQuery2/image6.gif)

事实上类似的用法在 `Scaffold` 内部也用到了，基本上能通过 `paddingOf `、`sizeOf` 、`viewInsetsOf`  等 propertyOf  方法获取到参数的，就不要直接用 `.Of(context)`   ，这也是 3.10 之后  `MediaQuery`  上针对性的性能提升：

![](http://img.cdn.guoshuyu.cn/20250227_MediaQuery2/image7.png)

而之所以 propertyOf 系列参数可以做到约束   `MediaQueryData`  更新时只触发绑定参数的能力，内部主要还是在 context 登记时，通过 `aspect` 单独触发  `InheritedModel` 实现。

每个 `InheritedModel` 都是一个单独的 `InheritedWidget`  的实现，而这样  `InheritedModel` 内部的 `InheritedModelElement`  就会记录每个子组件依赖的 `aspect`，从而形成一个新的独立类型映射，因此   `InheritedModel`  支持订阅特定模型的变化。

另外，关于 `MediaQueryData.fromWindow` ，在上古版本内还有 `MediaQueryData.fromWindow`  这样的 API ，而现在都是  `MediaQueryData.fromView` ，而之所以这么调整是因为：

> 起初 Flutter 假定了它只支持一个 Window 的场景，所以会有 `SingletonFlutterWindow` 这样的 instance window 对象存在，同时 `window` 属性又提供了许多和窗口本身无关的功能，而这种设定在未来多窗口逻辑下会显得很另类。

所以后来开始废除单例 window ，改为  `View.of(context)` ，也就是可以通过 `MediaQueryData.fromView(View.of(context))` 这样的方式获取 `MediaQueryData` ，类似的还有：

```dart
/// 3.10 之前
double dpr = WidgetsBinding.instance.window.devicePixelRatio;
Locale locale = WidgetsBinding.instance.window.locale;
double width =
   MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width;


/// 3.10 之后
double dpr = View.of(context).devicePixelRatio;
Locale locale = View.of(context).platformDispatcher.locale;
double width =
   MediaQueryData.fromView(View.of(context)).size.width;

```

可以看到，这里的  `View`  内部肯定也是一个 `InheritedWidget` ，它将 `FlutterView` 通过 `BuildContext` 往下共享，从而提供类似上古时代 「window」 的参数能力，而通过 `View.of ` 获取的参数：

- **当 `FlutterView` 本身的属性值发生变化时，是不会通知绑定的 `context` 更新，这个行为类似于之前的 `WidgetsBinding.instance.window`**
- 只有当 `FlutterView` 本身发生变化时，比如 `context` 绘制到不同的 `FlutterView` 时，才会触发对应绑定的 `context` 更新

可以看到现在  `View.of`  这个行为考虑的是「多 `FlutterView`」 下的更新场景，如果在单  `FlutterView` 场景下，它几乎就是静态的，如果你不关心 `MediaQuery` 动态更新的场景，后者你更应该使用这类「静态获取」的方式。

> 更多可见 [《一起来了解 View.of 和 PlatformDispatcher》](https://juejin.cn/post/7233964656287973436)

好了，今天的小技巧就到这里，温故知新，基本上今天的内容都是过去的片段，把它们放在一起之后，你应该就知道如何使用 `MediaQuery` 可以让你的 Flutter App 性能有所提升了吧？



