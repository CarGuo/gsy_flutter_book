# Flutter 之快速理解混合开发里的手势事件传递

本篇我们聊聊  `PlatformView`   里的手势事件传递，为什么会有这么一篇？其实在此之前已经写过很多 Flutter 里关于混合开发里 `PlatformView`  的内容，而随着 Flutter 版本的迭代， `PlatformView`   的实现也出现了一定的历史包袱问题，恰好最近和[大佬](https://juejin.cn/user/4309694831660711)讨论了混合使用   `VirtualDisplay`  和 `HybirdComposition` 时手势事件有什么区别，就顺便把讨论结果梳理出来。

> 对历史包袱问题感兴趣的可以看 [《混合开发的摸爬滚打》](https://juejin.cn/post/7153184663077388295)，之前写过 `PlatformView`   的文章最早的已经两年多前，关于事件处理经历过太多版本，如今可能会产生了一些误解或者错误引导，就在本篇一次性解释。

首先在当前 3.3 的版本里，Flutter   `PlatformView`   主要有    `VirtualDisplay`  、 `HybirdComposition`  和 `TextureLayer` 三种实现，而这三种实现在手势事件传递实现有差异，但是流程一致，所以本篇的目的就是快速梳理它们的异同。

**如果从当前的实现逻辑上总结，他们在流程上基本是一致的，事件都是从原生 -> Dart -> 原生这样的一个响应处理过程** ，也就是如下图所示，由原生的 `onTouchEvent`  产生手势事件，然后经过 dart 的统一的[事件竞技场](https://juejin.cn/post/6844903841742192648)处理后，最后回到原生层再去触发原生控件响应事件。



![](http://img.cdn.guoshuyu.cn/20221026_N17/image1.png)

也就是在当前的设计里，**无论是哪种   `PlatformView`   的实现，原生控件都不会马上响应触摸事件，而是统一发送到 dart 进行处理，之后再返回触发 Native 控件进行响应**，这样处理的好坏在于：

- 好处是处理逻辑能在 dart 里统一，并且针对原生控件的事件处理也可以在 dart 层进行拦截处理
- 坏处是原生 Event 经历了多次转换，中间可能出现精度丢失和响应速度的问题，特别是在需要大量拖拽的场景

> 所以在 `PlatformView` 的 dart 实现里会有 `gestureRecognizers` 参数用于开发者处理自定义事件响应的支持，例如配置 `EagerGestureRecognizer`   可以用于获得所有手势，解决手势冲突问题。

那么它们在实现上有什么差异？其实这些差异不会直接影响你的使用，如果不感兴趣可以不关心，但是对于理解整个手势事件传递来说又是必不可缺。

# VirtualDisplay

`VirtualDisplay `可以说是老骥伏枥了，兜兜转转最后在 3.3 版本系还继续服役，我们都知道 `VirtualDisplay ` 的实现是采用 Android 上副屏的渲染逻辑，然后把控件渲染到内存，通过纹理 id 提取合成画面，也就是：

> **虽然你看到控件在那里，但是其实它并不是真的在那里，你看的是只是合成之后的纹理，所以 `VirtualDisplay  ` 上原生端接受到的触摸事件，其实是来自于 `FluterView`**  。

在  `VirtualDisplay  `  里触摸事件的发起和普通 Flutter 控件一样，都是从 `FlutterView` 的 `onTouchEvent` 开始，经过统一的[事件竞技场](https://juejin.cn/post/6844903841742192648)处理后，最终回到 java 层去触发 NativeView 响应手势信息。

![](http://img.cdn.guoshuyu.cn/20221026_N17/image2.png)

所以在  `VirtualDisplay  `  里所有的 Event 都是直接来自  `FlutterView`  ，走的是  `AndroidTouchProcessor` 进行发送。

#  `HybirdComposition`  

对于  `HybirdComposition` 来说这个实现又不大一样，因为 `HybirdComposition`  是直接把原生 View 通过 `addView` 添加到 `FlutterView` 上面，中间通过  `FlutterMutatorView` 作为容器，大概效果如下图所示。

![](http://img.cdn.guoshuyu.cn/20221026_N17/image3.png)

**那是不是  `HybirdComposition` 上用户的触摸点击事件是直接由原生控件进行响应呢？答案是否定的**。

其实[一开始](https://github.com/flutter/engine/commit/1832613e0961902d9d368b3b4b6541b858050eb4#diff-efdceec13b333498e1451586d96adc90030b07bc1b7818cc4dbb16b85f1aba32)  `HybirdComposition`  的设定确实是这样，但是后来为了统一和方便处理，  `FlutterMutatorView`  上添加了  `onInterceptTouchEvent` 进行了拦截，所以事件都无法传递到它的子控件上，而是在   `FlutterMutatorView`   通过  `AndroidTouchProcessor` 发送到 Dart 层。

![](http://img.cdn.guoshuyu.cn/20221026_N17/image4.png)

当然，**事实上在坐标处理上也有差异**，因为这里的 `onTouchEvent` 是   `FlutterMutatorView`  上的触摸事件坐标，而为了能够匹配到 dart 里的坐标进行响应，还需要通过矩阵转化为屏幕坐标，而这部分换算在  `VirtualDisplay `里是不需要的。

![](http://img.cdn.guoshuyu.cn/20221026_N17/image5.png)



![](http://img.cdn.guoshuyu.cn/20221026_N17/image6.png)



事实上   `HybirdComposition`  的实现在触摸事件响应上比较有迷惑性，特别是某些场景下会很有趣，例如在下面这个场景上：

> 红色的是 Flutter 控件，蓝色是 Native 控件，它们恰好有一部分重叠在一起。

| ![](http://img.cdn.guoshuyu.cn/20221026_N17/image7.png) | ![](http://img.cdn.guoshuyu.cn/20221026_N17/image8.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |

我们知道在   `HybirdComposition`   里，如果 Flutter 控件需要覆盖在 Native 控件之上是，就会需要一个 `FlutterImageView` 来做新的图层承载，但是 `FlutterImageView`  本身并没有做触摸事件处理，所以如果这时候点击红色 RE ，就会有两种情况：

- 点击的是和蓝色 Native 控件相交的区域，因为事件穿透的影响，此时会是通过    `FlutterMutatorView`   触发事件发送到 Dart
- 点击的是没有相交的区域时，因为事件穿透的影响，此时会是通过   `FlutterView`   触发事件发送到 Dart

![](http://img.cdn.guoshuyu.cn/20221026_N17/image9.png)



> 虽然这个过程其实很诡异，但是实际上并不会影响最终结果，详细感兴趣可以看 [《Flutter 3.0下的混合开发演进》](https://juejin.cn/post/7113655154347343909)

#  TextureLayer

其实 `TextureLayer` 的事件实现和    `HybirdComposition`  类似，不同之处在于它是通过  `PlatformViewWrapper` 做父容器来拦截事件。

![](http://img.cdn.guoshuyu.cn/20221026_N17/image10.png)

 `PlatformViewWrapper` 同样通过 `onInterceptTouchEvent` 进行了事件拦截，所以事件都无法传递到它的子控件上，而是通过  `AndroidTouchProcessor` 发送到 Dart 层，同时在对应的  `onTouchEvent`  上需要做事件转化。

![](http://img.cdn.guoshuyu.cn/20221026_N17/image11.png)

> PS ，这里看到 ` TextView`  是空白的原因就是  `PlatformViewWrapper`  通过 Hook 了 Canvas 从而提取 Child 纹理的过程，详细感兴趣可见：[《Flutter 3.0下的混合开发演进》](https://juejin.cn/post/7113655154347343909)。

所以本质上 `TextureLayer` 和    `HybirdComposition`   在事件消费处理上类似，只是不会有像   `HybirdComposition`    一样会有   `FlutterImageView`  那样诡异的传递方式而已。

![](http://img.cdn.guoshuyu.cn/20221026_N17/image12.png)



# 最后

好了，本篇的内容其实并不复杂，**主要是帮助你理清 `PlatformView` 里手势事件传递和处理的相关逻辑**，理清这部分逻辑，在你使用 add-to-app 时针对一些手势冲突会更有帮助，如果还有什么想说的，欢迎留言讨论～