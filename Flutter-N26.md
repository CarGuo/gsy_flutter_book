# Flutter 小技巧之 InkWell & Ink 你了解多少

今天要介绍一个「陈年」小技巧，主要是关于 `InkWell` 的基础科普，`InkWell`  控件相信大家不会陌生， 作为 Flutter 开发中最常用的点击 Widget ，配合 Flutter 自带的 `Material`  ，可以轻松实现带有水波纹等的点击效果。

![](http://img.cdn.guoshuyu.cn/20230619_N26/image1.gif)

而之所以要介绍这个，主要是发现好像有一部分人对于  `InkWell`   的点击效果实现存在误解，例如，你知道水波纹是如何实现的吗？

首先，如下代码所示，可以看到代码运行后在屏幕中间出现了一个蓝色的正方形，此时如果你点击正方形，会发现 `click InkWell` 会正常打印，但是却看不到水波效果，这是为什么呢？

| ![](http://img.cdn.guoshuyu.cn/20230619_N26/image2.png) | ![](http://img.cdn.guoshuyu.cn/20230619_N26/image3.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |

其实这里和 `InkWell`  的  child 有关系，如果把上面蓝色的 `Container`  的 `color` 修改为 `Colors.blue.withAlpha(100) ` ，如下图所示，可以看到此时水波纹效果又出现了。

![](http://img.cdn.guoshuyu.cn/20230619_N26/image4.gif)

**所以一开始水波纹效果之所以会看不到，直接原因其实是因为被  `InkWell`  的  child  的蓝色给覆盖**。

> 所以可以明确一点，  `InkWell`   的水波纹和点击效果，其实是在底部产生。

事实上 ， **`InkWell`  的点击效果并不是通过它自身产生的，而是通过 `Material` 实现的动画绘制**，默认情况下使用的是 `Scaffold`  内部的 `Material` 来完成点击效果的绘制。

> 所以**对于不熟悉 ` InkWell` 的开发者来说，这是一个比较反直觉的设定**， ` InkWell`  的点击效果不是通过自身产生的，而是默认通过所在的   `Scaffold`  内的   `Material`  来完成点击动画。

所以，当你不使用   `Scaffold`   直接引用  `InkWell`  时，就会收到如下图所示的错误提示，因为没有了    `Scaffold`   ， 默认的  `Material`  不存在了，一般这时候我们可以手动添加多一个   `Material`  控件来解决错误。

![](http://img.cdn.guoshuyu.cn/20230619_N26/image5.png)

**那  `Material`   是如何实现点击动画**？

事实上在 `Material` 内部存在一个叫 `_InkFeatures`  的控件，就是它负责在点击产生时绘制点击效果，如下图所示，**`InkWell`  默认会有 `InkSplash` 和 `InkHighlight` 两个点击效果，它们分别对应水波纹效果和高亮效果**。

![](http://img.cdn.guoshuyu.cn/20230619_N26/image6.png)

那   `InkWell`    的点击时如何通知  `Material`   绘制动画？

首先，如下图所示，当   `InkWell`   内有点击产生时会触发 `_startNewSplash` 方法，然后通过控件位置和大小去创建当前所需的 `InkFeature`  。

![](http://img.cdn.guoshuyu.cn/20230619_N26/image7.png)

正如前面所示，默认情况下  `InkWell`   在点击时会创建一个 `InkSplash` 和 `InkHighlight` ，它们分别对应水波纹效果和点击高亮效果，而不管是  `InkSplash`  还是  `InkHighlight` ，它们在被创建的时候，都会通过 ` Material.of(context)` 获取  `MaterialInkController` ，然后再创建通过 controller 的  `addInkFeature()`   方法将点击效果添加到  `Material`  中。

| ![](http://img.cdn.guoshuyu.cn/20230619_N26/image8.png) | ![](http://img.cdn.guoshuyu.cn/20230619_N26/image9.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |

在 `Material`  中，`addInkFeature ` 会通过 `markNeedsPaint`  来使得  `_InkFeatures`  发生重绘，从而触发  `InkSplash` 和 `InkHighlight` 的点击 `paint` 动画。

![](http://img.cdn.guoshuyu.cn/20230619_N26/image10.png)

当然，有添加就有移除，例如  `InkHighlight`  就会在动画结束时调用  `dispose` 方法移除对应的 `InkFeature` 。

| ![image-20230619151104834](http://img.cdn.guoshuyu.cn/20230619_N26/image11.png) | ![](http://img.cdn.guoshuyu.cn/20230619_N26/image12.png) |
| ------------------------------------------------------------ | -------------------------------------------------------- |

那么简单总结一下： **`InkWell`    的点击效果是通过   `Material`    实现，默认使用的是 `Scaffold`  自带的  `Material`**  。

那么既然   `InkWell`    的点击效果是通过   `Material` 实现，前面点击的水波纹和高亮效果其实是被 `Container` 的背景色遮挡，如下图所示，这时候我们可以添加多一个   `Material`  ，然后将背景色挪到   `Material`  上，此时可以看到点击效果恢复正常。

| ![](http://img.cdn.guoshuyu.cn/20230619_N26/image13.png) | ![](http://img.cdn.guoshuyu.cn/20230619_N26/image14.gif) |
| -------------------------------------------------------- | -------------------------------------------------------- |

当然，你也可以将颜色挪到更外层的 `Container` ，这样就不会遮挡到     `Material`  绘制点击动画的效果。

![](http://img.cdn.guoshuyu.cn/20230619_N26/image15.png)

**那么还有没有更优雅的做法？这就不得不提 `Ink`** 。

 `Ink`  的作用就是为了方便使用 `InkWell ` 的点击效果而存在， 你可以把 ` Container` 上的 `color` 、`decoration` 等配置挪到 `Ink`   上从而解决    `Material`   的点击效果被遮挡的问题。

![](http://img.cdn.guoshuyu.cn/20230619_N26/image16.png)

因为 `Ink`  内部是通过 `InkDecoration`  实现主要逻辑，而 `InkDecoration` 本身也是一个 `InkFeature` ， 所以在触发点击效果时， `InkDecoration`  作为  `InkFeature`  ，在创建时同样会调用  `controller.addInkFeature(this);` ，所以同样会触发绘制，只是绘制的层级在 `InkWell` 内其他   `InkFeature`   之下。

![](http://img.cdn.guoshuyu.cn/20230619_N26/image17.png)

当然，如下图所示你也可以这么写，  **`Ink`   的核心理念就是实现在  `Material` 空间上进行绘制，这样就不会干扰或者遮挡后续 `InkWell ` 的点击效果**。

![](http://img.cdn.guoshuyu.cn/20230619_N26/image18.png)

所以   `Ink`    相当于时另辟蹊径，利用  `Material` 的特性来解决覆盖问题，所以针对 `InkWell ` 点击效果被覆盖问题，你是选择调整层级配合 `Material` 还是使用    `Ink`    ？

> 当然，如果你想要的去除水波纹点击效果，那么可以参考 [《Flutter 3 下的 ThemeExtensions 和 Material3》 ](https://juejin.cn/post/7105869440985595912)。

那么本篇小技巧到这里就结束啦，是不是很简单，核心主要是理解  `InkWell `  点击效果的由来，避免有时候自己被某些坑绕进去而无法自拔，如果你还有什么想说的，欢迎留言评论。