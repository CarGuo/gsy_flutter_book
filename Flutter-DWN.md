# 掘金x得物公开课 - Flutter 3.0下的混合开发演进

hello 大家好，我是《Flutter 开发实战详解》的作者，Github GSY 项目的负责人郭树煜，同时也是今年新晋的 [Flutter GDE](https://juejin.cn/post/7102242694755254279)，借着本次 Google  I/O 之后发布的 Flutter 3.0，来和大家聊一聊 Flutter 里混合开发的技术演进。

为什么混合开发在 Flutter 里是特殊的存在？因为它渲染的控件是通过 Skia 直接和 GPU 交互，也就是说 Flutter 控件和平台无关，甚至连 UI 绘制线程都和原生平台 UI 线程是相互独立，**所以甚至于 Flutter  在诞生之初都不支持和原生平台的控件进行混合开发，也就是不支持 `WebView` ，这就成了当时最大的缺陷之一** 。

其实从渲染的角度看 Flutter 更像是一个 2D 游戏引擎，事实上 Flutter 在这次 Google I/O 也分享了基于 [Flutter 的游戏开发 ToolKit 和第三方工具包 Flame](https://juejin.cn/post/7103284735010406407) ，如图所示就是本次 Google I/O 发布的 Pinball 小游戏，所以从这些角度上看都可以看出 Flutter 在混合开发的特殊性。

> **如果说的更形象简单一点，那就是如何把原生控件渲染到 `WebView` 里**。



![TT](http://img.cdn.guoshuyu.cn/20220626_DWN/image2.gif)

# 最初的社区支持

不支持   `WebView`  在最初可以说是 Flutter 最大的痛点之一，所以在这样窘迫的情况下，社区里涌现出一些临时的解决方法，比如 `flutter_webview_plugin` 。

类似  `flutter_webview_plugin`  的出现，解决了当时大部分时候 App 里打开一个网页的简单需求，如下图所示，它的思路就是：

> 在 Flutter 层面放一个占位控件提供大小，然后原生层在同样的位置把 ` WebView` 添加进去，从而达到看起来把 ` WebView`  集成进去的效果，**这个思路在后续也一直被沿用**。

![image-20220625170833702](http://img.cdn.guoshuyu.cn/20220626_DWN/image3.png)

**这样的实现方式无疑成本最低速度最快，但是也带来了很多的局限性**。

相信大家也能想到，**因为 Flutter 的所有控件都是渲染一个 `FlutterView` 上，也就是从原生的角度其实是一个单页面的效果**，所以这种脱离 Flutter 渲染树的添加控件的方法，无疑是没办法和 Flutter 融合到一起，举个例子：

- 如图一所示，从 Flutter 页面跳到 Native 页面的时候，打开动画无法同步，因为 `AppBar` 是 Flutter 的，而 Native 是原生层，它们不在同一个渲染树内，所以无法实现同步的动画效果
- 如图二所示，比如在打开 Native 页面之后，通过 `Appbar` 再打开一个黄色的 Bottm Sheet ，可以看到此时黄色的  Bottm Sheet 打开了，但是却被 Native 遮挡住（Demo 里给 Native 设置了透明色），因为 Flutter 的 Bottm Sheet  是被渲染在 `FlutterView` 里面，而 Native UI 把 `FlutterView`  挡住了，所以新的 `Flutter UI` 自然也被遮挡
- 如图三所示，当我们通过 reload 重刷 Flutter UI 之后，可以看到 Flutter 得 UI 都被重置了，但是此时 Native UI 还在，因为此时已经没有返回按键之类的无法关闭，这也是这种集成方式一不小心就影响开发的问题
- 如图四通过 iOS 上的 debug 图层，我们可以更形象地看到这种方式的实现逻辑和堆叠效果

| 动画不同步                                                   | 页面被挡                                                     | reload 之后                                                  | iOS                                                          |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| ![11111111](http://img.cdn.guoshuyu.cn/20220626_DWN/image4.gif) | ![222222222](http://img.cdn.guoshuyu.cn/20220626_DWN/image5.gif) | ![333333](http://img.cdn.guoshuyu.cn/20220626_DWN/image6.gif) | ![image-20220616142126589](http://img.cdn.guoshuyu.cn/20220626_DWN/image7.png) |

# PlatformView

随着 Flutter 的发展，官方支持混合开发势在必行，所以第一代  `PlatformView`  的支持还是诞生了，但是由于 Android 和 iOS 平台特性的不同，最初Android 的 `AndroidView`  和 iOS 的 `UIKitView` 实现逻辑相差甚远，**以至于后面  Flutter 的 `PlatformView` 的每次大调整都是围绕于 Android 在做优化** 。

###   Android 

最初 Flutter 在 Android 上对  `PlatformView`   的支持是通过 `VirtualDisplay`  实现，`VirtualDisplay` 类似于一个虚拟显示区域，需要结合 `DisplayManager` 一起调用，`VirtualDisplay`  一般在副屏显示或者录屏场景下会用到，而在 Flutter 里 `VirtualDisplay` 会将虚拟显示区域的内容渲染在一个内存 `Surface`上。

**在 Flutter 中通过将 `AndroidView` 需要渲染的内容绘制到 `VirtualDisplays` 中 ，然后通过 textureId 在 `VirtualDisplay` 对应的内存中提取绘制的纹理**， 简单看实现逻辑如下图所示：

![image-20220626151538054](http://img.cdn.guoshuyu.cn/20220626_DWN/image8.png)

> 这里其实也是类似于最初社区支持的模式：通过在 Dart 层提供一个 `AndroidView` ，从而获取到控件所需的大小，位置等参数，当然这里多了一个 `textureId` ，这个 id 主要是提交给 Flutter Engine ，通过 id  Flutter 就可以在渲染时将画面从内存里提出出来。

### iOS

在 iOS 平台上就不使用类似 `VirtualDisplay` 的方法，而是**通过将 Flutter UI 分为两个透明纹理来完成组合**，这种方式无疑更符合 Flutter 社区的理念，这样的好处是：

> 需要在 `PlatformView`  下方呈现的 Flutter UI 可以被绘制到其下方的纹理；而需要在  `PlatformView`   上方呈现的 Flutter UI 可以被绘制到其上方的纹理， 它们只需要在最后组合起来就可以了。

是不是有点抽象？

简单看下面这张图，其实就是通过在 `NativeView` 的不同层级设置不同的透明图层，然后把不同位置的控件渲染到不同图层，最终达到组合起来的效果。

![image-20220626151526444](http://img.cdn.guoshuyu.cn/20220626_DWN/image9.png)

那明明这种方法更好，为什么 Android 不一开始也这样实现呢？

因为当时在实现思路上， `VirtualDisplay`  的实现模式并不支持这种模式，因为在 iOS 上框架渲染后系统会有回调通知，例如：*当 iOS 视图向下移动 `2px` 时，我们也可以将其列表中的所有其他 Flutter 控件也向下渲染 `2px`*。

但是在 Android 上就没有任何有关的系统 API，因此无法实现同步输出的渲染。**如果强行以这种方式在 Android 上使用，最终将产生很多如 `AndroidView` 与 Flutter UI 不同步的问题**。

### 问题

事实上  `VirtualDisplay`   的实现方式也带来和很多问题，简单说两个大家最直观的体会：

#### 触摸事件

因为控件是被渲染在内存里，虽然**你在 UI 上看到它就在那里，但是事实上它并不在那里**，你点击到的是 `FlutterView `，所以**用户产生的触摸事件是直接发送到 `FlutterView`**。

所以触摸事件需要在  `FlutterView` 到 Dart ，再从 Dart 转发到原生，然后如果原生不处理又要转发回 Flutter ，如果中间还存在其他派生视图，事件就很容易出现丢失和无法响应，而这个过程对于  `FlutterView`  来说，在原生层它只有一个 View 。

所以 Android 的 `MotionEvent` 在转化到 Flutter 过程中可能会因为机制的不同，存在某些信息没办法完整转化的丢失。

#### 文字输入

一般情况下 **`AndroidView` 是无法获取到文本输入，因为 `VirtualDisplay` 所在的内存位置会始终被认为是 `unfocused` 的状态**。

>  `InputConnections` 在 `unfocused` 的 View 中通常是会被丢弃。

所以 **Flutter 重写了 `checkInputConnectionProxy` 方法，这样 Android 会认为 `FlutterView` 是作为 `AndroidView` 和输入法编辑器（IME）的代理**，这样 Android 就可以从 `FlutterView` 中获取到 `InputConnections` 然后作用于 `AndroidView` 上面。

> 在 Android Q 开始又因为非全局的  `InputMethodManager` 需要新的兼容

当然还有诸如性能等其他问题，但是至少先有了支持，有了开始才会有后续的进阶，在 Flutter 3.0 之前， `VirtualDisplay`   一直默默在  `PlatformView`   的背后耕耘。

# HybridComposition

时间来到 Flutter 1.2，Hybrid Composition 是在 Flutter 1.2 时发布的 Android 混合开发实现，它使用了类似 iOS 的实现思路，提供了 Flutter  在 Android 上的另外一种 `PlatformView` 的实现。

如下图是在 Dart 层使用 `VirtualDisplay`  切换到 `HybridComposition` 模式的区别，最直观的感受应该是需要写的 Dart 代码变多了。

![111111](http://img.cdn.guoshuyu.cn/20220626_DWN/image10.png)

但是其实   `HybridComposition`   的实现逻辑是变简单了： **`PlatformView` 是通过 `FlutterMutatorView` 把原生控件 `addView` 到 `FlutterView` 上，然后再通过 `FlutterImageView` 的能力去实现图层的混合**。

> 又懵了？不怕，马上你就懂了

简单来说就是  `HybridComposition`    模式会直接把原生控件通过 `addView` 添加到 `FlutterView` 上 。**这时候大家可能会说，咦～这不是和最初的实现一样吗？怎么逻辑又回去了** ？

> 其实确实是社区的进阶版实现，Flutter 直接通过原生的 `addView` 方法将 `PlatformView` 添加到 `FlutterView`  里，而当你还需要在 `PlatformView` 上渲染 Flutter 自己的 Widget 时，Flutter 就会通过再叠加一个 `FlutterImageView` 来承载这个 Widget 的纹理。

举一个简单的例子，如下图所示，一个原生的 `TextView`  被通过   `HybridComposition`   模式接入到 Flutter 里（`NativeView`），而在 Android 的显示布局边界和 Layout Inspector 上可以清晰看到： **灰色 `TextView` 通过 `FlutterMutatorView` 被添加到 `FlutterView` 上被直接显示出来** 。

![image-20220618152055492](http://img.cdn.guoshuyu.cn/20220626_DWN/image11.png)

**所以在    `HybridComposition`   里 `TextView` 是直接在原生代码上被 add 到 `FlutterView` 上，而不是提取纹理**。

那如果我们看一个复杂一点的案例，如下图所示，其中蓝色的文本是原生的  `TextView` ，红色的文本是 Flutter 的 `Text` 控件，在中间 Layout Inspector 的 3D 图层下可以清晰看到：

- 两个蓝色的  `TextView`  是通过 `FlutterMutatorView` 被添加在 `FlutterView` 之上，并且把没有背景色的红色 RE 遮挡住了
- 最顶部有背景色的红色 RE 也是 Flutter 控件，但是因为它需要渲染到   `TextView`  之上，所以这时候多一个 `FlutterImageView` ，它用于承载需要显示在 Native 控件之上的纹理，从而达 Flutter 控件“真正”和原生控件混合堆叠的效果。

![image-20220616165047353](http://img.cdn.guoshuyu.cn/20220626_DWN/image12.png)

**可以看到 `Hybrid Composition` 上这种实现，能更原汁原味地保流下原生控件的事件和特性，因为从原生角度看它就是原生层面的物理堆叠，需要都一个层级就多加一个   `FlutterImageView`  ，同一个层级的 Flutter 控件共享一个  `FlutterImageView`**  。

当然，在  `HybridComposition`   里 `FlutterImageView` 也是一个很有故事的对象，由于篇幅原因这里就不详细展开，这里大家可以简单看这张图感受下，也就是在有 `PlatformView` 和没有  `PlatformView`  是，Flutter 的渲染会有一个转化的过程，而**在这个变化过程，在 Flutter 3.0 之前可以通过 ` PlatformViewsService.synchronizeToNativeViewHierarchy(false);` 取消**。

![image-20220618153757996](http://img.cdn.guoshuyu.cn/20220626_DWN/image13.png)

最后，Hybrid Composition 也不少问题，比如上面的转化就是为了解决动画同步问题，当然这个行为也会产生一些性能开销，例如：

>  在 Android 10 之前， *Hybrid Composition* 需要将内存中的每个 Flutter 绘制的帧数据复制到主内存，之后再从 GPU 渲染复制回来 ，所以也会导致 *Hybrid Composition* 在 Android 10 之前的性能表现更差，例如在滚动列表里每个 Item 嵌套一个 *Hybrid Composition* 的 `PlatformView`  ，就可能会变卡顿甚至闪烁。

其他还有线程同步，闪烁等问题，由于篇幅就不详细展开，如果感兴趣的可以详细看我之前发布过的 [《Flutter 深入探索混合开发的技术演进》](https://juejin.cn/post/7093858055439253534) 。



# TextureLayer

随着 Flutter 3.0 的发布，第一代 `PlatformView` 的实现 `VirtualDisplay` 被新的 `TextureLayer` 所替代，如下图所示，简单对比 `VirtualDisplay` 和 `TextureLayer` 的实现差异，**可以看到主要还是在于原生控件纹理的提取方式上**。



![image-20220618154327890](http://img.cdn.guoshuyu.cn/20220626_DWN/image14.png)

从上图我们可以得知：

- 从 `VirtualDisplay` 到 `TextureLayer` ， **Plugin 的实现是可以无缝切换，因为主要修改的地方在于底层对于纹理的提取和渲染逻辑**；
- 以前 Flutter 中会将 `AndroidView` 需要渲染的内容绘制到 `VirtualDisplays` ，然后在 `VirtualDisplay` 对应的内存中，绘制的画面就可以通过其 `Surface` 获取得到；**现在 `AndroidView` 需要的内容，会通过 View 的 `draw` 方法被绘制到 `SurfaceTexture` 里，然后同样通过 `TextureId` 获取绘制在内存的纹理** ；

是不是又有点蒙？简单说就是不需要绘制到副屏里，现在直接通过 override  `View` 的 `draw` 方法就可以了。

在  *TextureLayer* 的实现里，同样是需要**把控件添加到一个 `PlatformViewWrapper` 的原生布局控件里，但是这个控件通过  override 了  `View` 的 `draw` 方法，把原本的 Canvas 替换成 `SurfaceTexture`  在内存的 Canvas ，所以   `PlatformViewWrapper`  的 child 会把控件绘制到内存的  `SurfaceTexture`  上。**

![](http://img.cdn.guoshuyu.cn/20220626_DWN/image15.png)

举个例子，还是之前的代码，如下图所示，这时候通过  *TextureLayer* 模式运行之后，通过 Layout Inspector 的 3D 图层可以看到，两个原生的 `TextView`  通过 `PlatformViewWrapper`   被添加到 ` FlutterView` 上。

但是不同的是，**在 3D 图层里看不到 `TextView` 的内容，因为绘制  `TextView` 的 Canvas 被替换了**，所以   `TextView`  的内容被绘制到内存的 Surface 上，最终会在渲染时同步 Flutter Engine 里。

![](http://img.cdn.guoshuyu.cn/20220626_DWN/image16.png)

看到这里，你可能也发现了，这时候因为有  `PlatformViewWrapper`   的存在，点击会被  `PlatformViewWrapper`   内部拦截，从而也解决了触摸的问题， 而这里刚好有人提了一个问题，如下图所示：

> "从图 1 Layout Inspector 看， `PlatformWrapperView` 是在 `FlutterSurfaceView` 上方，为什么如图 2 所示，点击 Flutter button 却可以不触发 native button的点击效果？"。

| 图1                                                          | 图2                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------- |
| ![image.png](http://img.cdn.guoshuyu.cn/20220626_DWN/image17) | ![img](http://img.cdn.guoshuyu.cn/20220626_DWN/image18) |

思考一下，因为最直观的感受：**点击不都是被   `PlatformViewWrapper`    拦截了吗？明明   `PlatformViewWrapper`   是在 `FlutterSurfaceView`  之上，为什么 `FlutterSurfaceView`  里的 FlutterButton 还能被点击到**？

这里简单解释一下：

- 1、首先那个 Button 并不是真的被摆放在那里，而是通过 `PlatformViewWrapper` 的 `super.draw`绘制到 surface 上的，所以在那里的是 `PlatformViewWrapper` ，而不是 Button ，**Button 的内容已经变成纹理去到了  `FlutterSurfaceView`  里面**。
- 2、 **`PlatformViewWrapper` 里重写了 `onInterceptTouchEvent` 做了拦截**，`onInterceptTouchEvent` 这个事件是从父控件开始往子控件传，因为拦截了所以不会让 Button 直接响应，然后在 `PlatformViewWrapper` 的 `onTouchEvent`  响应里是做了点击区域的分发，响应会分发到了 `AndroidTouchProcessor` 之后，会打包发到 `_unpackPointerDataPacket` 进入 Dart
- 3、 在 Dart 层的点击区域，如果没有 Flutter 控件响应，会是 `_PlatformViewGestureRecognizer`-> `updateGestureRecognizers` -> `dispatchPointerEvent` -> `sendMotionEvent` 又发送回原生层
- 4、回到原生 `PlatformViewsController` 的 `createForTextureLayer` 里的 `onTouch` ，执行 `view.dispatchTouchEvent(event);`

![image-20220625171101069](http://img.cdn.guoshuyu.cn/20220626_DWN/image19.png)

总结起来就是：**`PlatfromViewWrapper` 拦截了 Event ，通过 Dart 做二次分发响应，从而实现不同的事件响应 ** ，它和 VirtualDisplay 的不同是，  VirtualDisplay  的事件响应都是在 `FlutterView` 上，但是TextureLayout 模式，是有独立的原生  `PlatfromViewWrapper`  控件来开始，所以区域效果和一致性会更好。

### 问题

最后这里还需要提个醒，如果你之前使用的插件使用的是 `HybirdComposition `  ，但是没做兼容，也就是使用的还是 `PlatformViewsService.initSurfaceAndroidView`  的话，它也会切换成  `TextureLayer` 的逻辑，**所以你需要切换为 `PlatformViewsService.initExpensiveAndroidView` ，才能继续使用原本   `HybirdComposition `   的效果**。

> ⚠️我也比较奇怪为什么 Flutter 3.0 没有提及 Android 这个 breaking change ，因为对于开发来说其实是无感的，不小心就掉坑里。

那你说为什么还要    `HybirdComposition `   ？ 

前面我们说过，  `TextureLayer`  是通过在  `super.draw` 替换 Canvas  的方法去实现绘制，但是它替换不了 `Surface` 里的一些 Canvas ，所以比如一些需要 `SurfaceView` 、`TextureView` 或者有自己内部特殊 `Canvas` 的场景，你还是需要    `HybirdComposition `  ，只不过可能会和官方新的 API 名字一样，它 Expensive 。

Expensive  是因为在 Flutter 3.0 正式版开始，`FlutterView` 在使用    `HybirdComposition `   时一定会 converted to `FlutterImageView` ，这也是 Flutter 3.0 下一个需要注意的点。

![image-20220616170253242](http://img.cdn.guoshuyu.cn/20220626_DWN/image20.png)

> 更多内容可见 [《Flutter 3.0 之 PlatformView ：告别 VirtualDisplay ，拥抱 TextureLayer》](https://juejin.cn/post/7098275267818291236)

![image-20220625164049356](http://img.cdn.guoshuyu.cn/20220626_DWN/image21.png)

# 最后

最后做个总结，可以看到 Flutter 为了混合开发做了很多的努力，特别是在 Android 上，也是因为历史埋坑的原因，由于时间关系这里没办法都详细介绍，但是相信本次之后大家对 Flutter 的 `PlatformView` 实现都有了全面的了解，这对大家在未来使用 Flutter 也会有很好的帮助，如果你还有什么问题，欢迎交流。

![image-20220626151444011](http://img.cdn.guoshuyu.cn/20220626_DWN/image22.png)