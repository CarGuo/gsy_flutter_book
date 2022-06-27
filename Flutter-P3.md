在 Flutter 3.0 发布之前，我们通过 [《Flutter 深入探索混合开发的技术演进》](https://juejin.cn/post/7093858055439253534) 盘点了 Flutter  混合开发的历史进程， 在里面就提及了第一代 `PlatformView` 的实现  *VirtualDisplay*  即将被移除，而随着最近 Flutter 3.0 的发布，这个变更正式在稳定版中如期而至，**所以今天就详细分析一下，新的 *TextureLayer* 如何替代 PlatformView** 。



首先，如下图所示，简单对比 *VirtualDisplay*  和  *TextureLayer* 的实现差异，**可以看到主要还是在于原生控件纹理的提取方式上**。

![image-20220516154120729](http://img.cdn.guoshuyu.cn/20220627_Flutter-P3/image1)

从上图我们可以得知：

- 从 *VirtualDisplay*  到  *TextureLayer* ， **Plugin 的实现是可以无缝切换，因为主要修改的地方在于底层对于纹理的提取和渲染逻辑**；

  

- 以前 Flutter 中会将 `AndroidView` 需要渲染的内容绘制到 `VirtualDisplays`  ，然后在 `VirtualDisplay` 对应的内存中，绘制的画面就可以通过其 `Surface` 获取得到；**现在 `AndroidView` 需要的内容，会通过 View 的 `draw` 方法被绘制到 `SurfaceTexture` 里，然后同样通过 `TextureId` 获取绘制在内存的纹理** ；

是不是有点懵？简单地说，如下图所示：

- 现在 `PlatformViewsController`  在加载 `PlatformView` 时， 在  `createForTextureLayer`  方法里会先创建一个 `PlatformViewWrapper` 对象，然后返回一个 `TextureId` 给 Dart ；
-  `PlatformViewWrapper`  本身是一个 Android 的 `FrameLayout` ，主要作用就是：通过` addView`添加原生控件，然后**在` draw` 方法里通过  `super.draw(surfaceCanvas);`将 Android View 的 Canvas 替换成 `PlatformView` 创建的 `SurfaceTexture` 的 Canvas** ；
- 在 Dart 层面， `AndroidView`  通过  `TextureId`  告诉 Engine 需要渲染的纹理信息，Engine 提取出前面  `super.draw(surfaceCanvas);` 所绘制的纹理，并渲染出来；

![image-20220516163607760](http://img.cdn.guoshuyu.cn/20220627_Flutter-P3/image2)



**这里面的关键就在于  `super.draw(surfaceCanvas);`** 。

在 `PlatformView`  创建时，Flutter 会为其创建一个`SurfaceTexture` 用于生成 `Surface`，相当于是在内存里新建了一个画板。

而   `PlatformViewWrapper`   里通过 `surface.lockHardwareCanvas()`获取到了这个画板的 Canvas ，也就是 `surfaceCanvas` ，相当于是画笔 。

接着 Flutter 通过 `override` 了   `PlatformViewWrapper`   的 `draw(Canvas canvas)`方法，然后在  `super.draw` 时把默认 View 的 Canvas  替换为上面的  `surfaceCanvas`。

比如这时候我们需要渲染的原生控件是 `TextView` ，**因为此时  `TextView`  是    `PlatformViewWrapper`    的子控件，所以当它绘制时，使用的画笔就会是  `surfaceCanvas` ，而它的界面效果就会被绘制到对应 Id 的 `SurfaceTexture`  里**。

所以在新流程里，原生控件同样是渲染到内存，然后通过 Id  去获取纹理数据，但是对比 VirtualDisplay  它更直接，因为是直接位置到内存纹理而不是通过虚显，并且这里有个关键内容：

> **使用的是 `lockHardwareCanvas()` 而不是 `lockCanvas()`， `lockHardwareCanvas()`  需要 API 23 以上才支持，因为它支持硬件加速，而不是像 `lockCanvas` 一样需要频繁的 CPU 拷贝，从而提高了性能。** 

那我们知道，在以前的  `VirtualDisplays`  实现里，除了性能问题，还有控件的触摸问题，因为 `AndroidView` 其实是被渲染在 `VirtualDisplay` 中 ，而每当用户点击看到的 `"AndroidView"` 时，其实他们就真正”点击的是正在渲染的 `Flutter` 纹理 ，用户产生的触摸事件是直接发送到 Flutter View 中，而不是他们实际点击的 `AndroidView`。

而在 *TextureLayer* 的实现里，**虽然控件同样是被绘制到内存，但是   `PlatformViewWrapper`   是真实存在布局里的** 。

什么意思呢？

如下图所示，是将两个 `TextView` 通过 *TextureLayer* 的方式添加到 Flutter 里 ，然后我们通过 Android Studio 的 Layout Inspector 查看，可以看到 `FlutterView` 下会有两个  `PlatformViewWrapper`   ，并且它们都有一个 `TextView` 的子控件。

![image-20220516112123711](http://img.cdn.guoshuyu.cn/20220627_Flutter-P3/image3)

**此时因为 `TextView` 的子控件的 Canvas 被 Flutter 给替换了，所以在画面上看不到渲染内容，但是它们所在的位置依然可以接受点击事件**。

所以在  `PlatformViewWrapper`   中，它 override 了 `onTouchEvent` 方法，并且将对应的 `MotionEvent` 进行封装，然后分发到 Flutter 的 Dart 层进行处理。

> 当然，此时 `PlatformViewWrapper`   的位置和大小 ，是通过 Dart 层的 `AndroidView` 传递过来的信息进行定位，而  `PlatformViewWrapper`   的位置其实和渲染效果没有关系，即使  `PlatformViewWrapper`   不在正常位置，画面也可以正常渲染，它影响的主要还是触摸事件的相关逻辑。

值得注意的是，  **`PlatformViewWrapper`   里的  ` onInterceptTouchEvent` 返回了 true ，也就是触摸事件会被它拦截，而不会传递，避免了 `FlutterView` 收到干扰**。

![image-20220516172819574](http://img.cdn.guoshuyu.cn/20220627_Flutter-P3/image4)

这里刚好有人提了一个问题，如下图所示：

> "从 Layout Inspector 看 `FlutterWrapperView` 是在 `FlutterSurfaceView` 上方，为什么点击 Flutter button 却可以不触发 native button的点击效果？"。


| 图1                                                          | 图2                                                          |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| ![image.png](http://img.cdn.guoshuyu.cn/20220627_Flutter-P3/image5) | ![](http://img.cdn.guoshuyu.cn/20220627_Flutter-P3/image6) |

> 这里简单解释一下：
> - 1、首先那个 Button 并不是真的被摆放在那里，而是通过 `PlatformViewWrapper` 的 `super.draw` 绘制到 surface 上的，所以在那里的是  `PlatformViewWrapper`  ，而不是 Button
> - 2、 `PlatformViewWrapper` 里 `onInterceptTouchEvent` 做了拦截，`onInterceptTouchEvent` 这个事件是从父控件开始往子控件传，因为拦截了所以不会让 Button 直接响应，然后在  `PlatformViewWrapper`  的  `onTouchEvent` 其实是做了点击区域的分发，响应分发到了 `AndroidTouchProcessor` 之后，会打包发到 `_unpackPointerDataPacket` 进入 Dart
> - 3、 在 Dart 层的点击区域，如果没有 Flutter 控件响应，会是 `_PlatformViewGestureRecognizer` -> `updateGestureRecognizers` -> `dispatchPointerEvent` -> `sendMotionEvent` 发送回原生层
> - 4、回到原生 `PlatformViewsController` 的 `createForTextureLayer` 里的 `onTouch` ，执行 `view.dispatchTouchEvent(event);`


另外 `PlatformViewWrapper`   还提供了焦点相关的处理逻辑，通过接口将焦点的变化状态返回给 Dart 层。

![image-20220516173618441](http://img.cdn.guoshuyu.cn/20220627_Flutter-P3/image7)

最后，  `PlatformViewWrapper` 里还有一个小兼容处理：就是在  Android Q 上 `SurfaceTexture` 需要绘制完上一帧之后，才能绘制下一帧。

![image-20220516174428087](http://img.cdn.guoshuyu.cn/20220627_Flutter-P3/image8)

简单地说，具体流程为：

- 所以当 Engine 每次绘制时，就会触发 `onFrameComsumed` 去对  `pendingFramesCount` 进行 -1 操作；
- 每次有新的 `SurfaceTexture` 或者 `draw(Canvas canvas)` 调用，就对  `pendingFramesCount` 进行 +1 操作；

通过  `pendingFramesCount`  的计数方式，当 `pendingFramesCount.get() <= 0L` 才进行 `Surface` 绘制，保证了  Android Q 上 `SurfaceTexture`  每次提交绘制都是最后一帧的画面。

可以看到 ，新的   *TextureLayer* 实现更简单直接，实现了在性能提高的同时，简化了实现的复杂度，同时也弥补了   *VirtualDisplay*   的一些缺陷。

最后，从 Flutter 3.0 源码上看，**社区有打算移除 *HybirdComposition* 的计划，但是这无疑是一个涉及面比较大的 break change ，最终是否能够通过还不得而知**，而从我个人角度出发，我是觉得  *HybirdComposition*  在某些场景还有存在的必要，如果想详细了解  *HybirdComposition*   ，可以参考  [《Flutter 深入探索混合开发的技术演进》](https://juejin.cn/post/7093858055439253534#heading-8) 

![image-20220516180731371](http://img.cdn.guoshuyu.cn/20220627_Flutter-P3/image9)