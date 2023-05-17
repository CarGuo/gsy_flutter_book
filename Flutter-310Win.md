# Flutter 3.10 适配之单例 Window 弃用，一起来了解  View.of 和 PlatformDispatcher

Flutter 3.10 发布之后，大家可能注意到，在它的 [release note](https://juejin.cn/post/7231565908631633979#heading-46) 里提了一句： **Window singleton 相关将被弃用，并且这个改动是为了支持未来多窗口的相关实现**。

> 所以这是一个为了支持多窗口的相关改进，多窗口更多是在 PC 场景下更常见，但是又需要兼容 Mobile 场景，故而有此次改动作为提前铺垫。

如下图所示，如果具体到对应的 API 场景，主要就是涉及 `WidgetsBinding.instance.window` 和 `MediaQueryData.fromWindow` 等接口的适配，因为   `WidgetsBinding.instance.window`  即将被弃用。

![](http://img.cdn.guoshuyu.cn/20230517_310/image1.png)

> 你可以不适配，还能跑，只是升级的技术债务往后累计而已。

那首先可能就有一个疑问，为什么会有需要直接使用  `WidgetsBinding.instance.window`  的使用场景？简单来说，具体可以总结为：

- 没有  `BuildContext` ，不想引入  `BuildContext`  
- 不希望获取到的 ` MediaQueryData`  受到所在  `BuildContext`  的影响，例如键盘弹起导致 padding 变化重构和受到 `Scaffold` 下的参数影响等

> 这部分详细可见：[《MediaQuery 和 build 优化你不知道的秘密》  ](https://juejin.cn/post/7114098725600903175)。

那么从 3.10 开始，针对  `WidgetsBinding.instance.window`  可以通过新的 API 方式进行兼容：

- 如果存在 `BuildContex`  ， 可以通过 `View.of`  获取 `FlutterView`，这是官方最推荐的替代方式
- 如果没有  `BuildContex`   可以通过 `PlatformDispatcher` 的 `views` 对象去获取

这里注意到没有，现在用的是  `View.of`  ，获取的是  `FlutterView` ，对象都称呼为 View 而不是 「Window」，对应的 `MediaQueryData.fromWindow`  API 也被弃用，修改为 `MediaQueryData.fromView` ，这个修改的依据在于：

> 起初 Flutter 假定了它只支持一个 Window 的场景，所以会有 `SingletonFlutterWindow` 这样的 instance window 对象存在，同时 `window` 属性又提供了许多和窗口本身无关的功能，在多窗口逻辑下会显得很另类。

那么接下来就让我们用「长篇大论」来简单介绍下这两个场景的特别之处。

# 存在 BuildContext

回归到本次的调整，首先是存在 BuildContext 的场景，如下代码所示，对于存在 `BuildContex`  的场景，  `View.of`  相关的调整为：

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

可以看到，这里的  `View`  内部实现肯定是有一个  `InheritedWidget`  ，它将  `FlutterView`  通过 `BuildContext` 往下共享，从而提供类似 「window」 的参数能力，而通过   `View.of`   获取的参数：

- **当 `FlutterView` 本身的属性值发生变化时，是不会通知绑定的 `context` 更新，这个行为类似于之前的  ` WidgetsBinding.instance.window`**
- 只有当  `FlutterView` 本身发生变化时，比如  `context`  绘制到不同的  `FlutterView` 时，才会触发对应绑定的 `context` 更新

可以看到    `View.of`    这个行为考虑的是「多   `FlutterView`」  下的更新场景，如果是需要绑定到具体对应参数的变动更新，如  `size`  等，还是要通过以前的 `MediaQuery.of` / `MediaQuery.maybeOf`   来实现。

而对于  `View` 来说，**每个 `FlutterView`  都必须是独立且唯一的**，在一个 Widget Tree 里，一个  `FlutterView`   只能和一个 `View` 相关联，这个主要体现在   `FlutterView`   标识   `GlobalObjectKey`   的实现上。

![](http://img.cdn.guoshuyu.cn/20230517_310/image2.png)

简单总结一下：**在存在 `BuildContex`  的场景，可以简单将 `WidgetsBinding.instance.window` 替换为 `View.of(context)` ，不用担心绑定了 `context` 导致重构，因为   `View.of`     只对   `FlutterView`  切换的场景生效**。

# 不存在 BuildContext

对于不存在或者不方便使用 `BuildContext` 的场景，官方提供了  `PlatformDispatcher.views`   API 来进行支持，不过因为 `get views` 对应的是 `Map` 的 `values` ，它是一个 `Iterable` 对象，**那么对于 3.10 我们需要如何使用   `PlatformDispatcher.views`   来适配没有 `BuildContext` 的  `WidgetsBinding.instance.window`  场面**？

![](http://img.cdn.guoshuyu.cn/20230517_310/image3.png)

> `PlatformDispatcher`  内部的` views` 维护了中所有可用 `FlutterView` 的列表，用于提供在没有  `BuildContext`  的情况下访问视图的支持。

你说什么情况下会有没有   `BuildContext`  ？比如 Flutter 里 的 `runApp` ，如下图所示，3.10 目前在  `runApp`  时会通过 `platformDispatcher.implicitView` 来塞进去一个默认的 `FlutterView` 。

![](http://img.cdn.guoshuyu.cn/20230517_310/image4.png)

`implicitView` 又是什么？其实 `implicitView`  就是 `PlatformDispatcher._views`  里 id 为 0 的  `FlutterView` ，默认也是 `views` 这个  `Iterable`  里的 `first` 对象。

![](http://img.cdn.guoshuyu.cn/20230517_310/image5.png)

也就是在没有  `BuildContext`  的场景， 可以通过 `platformDispatcher.views.first` 的实现迁移对应的  `instance.window` 实现。

```dart
/// 3.10 之前
MediaQueryData.fromWindow(WidgetsBinding.instance.window)
/// 3.10 之后
MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first)
```

为什么不直接使用  `implicitView`   对象？ 因为   `implicitView`   目前是一个过渡性方案，官方希望在多视图的场景下不应该始终存在  implicit view 的概念，而是应用自己应该主动请求创建一个窗口，去提供一个视图进行绘制。

![](http://img.cdn.guoshuyu.cn/20230517_310/image6.png)

所以对于 `implicitView`    目前官方提供了  `_implicitViewEnabled`   函数，后续可以通过可配置位来控制引擎是否支持  `implicitView`   ，也就是 **`implicitView` 在后续更新随时可能为 null ，这也是我们不应该在外部去使用它的理由**，同时它是在  `runApp` 时配置的，所以它在应用启动运行后永远不会改变，如果它在启动时为空，则它永远都会是 null。

> `PlatformDispatcher.instance.views[0]`  在之前的单视图场景中，无论是否有窗口存在，类似的 `implicitView` 会始终存在；而在多窗口场景下，`PlatformDispatcher.instance.views` 将会跟随窗口变化。

另外我们是通过 `WidgetsBinding.instance.platformDispatcher.views` 去访问  `views` ，而不是直接通过 `PlatformDispatcher.instance.views`  ，因为通常官方更建议在 Binding 的依赖关系下去访问  `PlatformDispatcher` 。

> 除了需要在 `runApp()` 或者 `ensureInitialized()` 之前访问 PlatformDispatcher 的场景。

另外，如下图所示，通过 Engine 里对于 window 部分代码的实现，可以看到我们所需的默认` FlutterView` 是 id 为 0 的相关依据，所以这也是我们通过  `WidgetsBinding.instance.platformDispatcher.views`  去兼容支持的逻辑所在。

| ![](http://img.cdn.guoshuyu.cn/20230517_310/image7.png) | ![](http://img.cdn.guoshuyu.cn/20230517_310/image8.png) | ![](http://img.cdn.guoshuyu.cn/20230517_310/image9.png) | ![](http://img.cdn.guoshuyu.cn/20230517_310/image10.png) |
| ------------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------- | -------------------------------------------------------- |



# 最后

最后总结一下，说了那么多，其实不外乎就是将 `WidgetsBinding.instance.window` 替换为 `View.of(context)` ，如果还有一些骚操作场景，可以使用  `WidgetsBinding.instance.platformDispatcher.views`  ，如果不怕后续又坑，甚至可以直接使用   `WidgetsBinding.instance.platformDispatcher.implicitView`  。

整体上解释那么多，**主要还是给大家对这次变动有一个背景认知，同时也对未来多窗口实现进展有进一步的了解**，相信下一个版本多窗口应该就可以和大家见面了。

更多讨论可见：

- https://github.com/flutter/flutter/issues/120306
- https://github.com/flutter/engine/pull/39553
- https://github.com/flutter/flutter/issues/116929
- https://github.com/flutter/flutter/issues/99500
- https://github.com/flutter/engine/pull/39788