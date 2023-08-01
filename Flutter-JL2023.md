![](http://img.cdn.guoshuyu.cn/20230728_JJ/image1.png)

# 掘力计划｜Flutter 混合开发的混乱之治【直播回顾】

Hello，大家好，我是 Flutter GDE 郭树煜，今天的主题是 Flutter 的混合开发，但是其实内容并不会很广，主要分享会集中在 Android 平台的 `PlatformView ` 实现上，其实本次内容之前我已经在掘金发过一篇[简要的文字概括](https://juejin.cn/post/7257119213889454139)，今天主要是根据这个内容做一个更详细的技术展开。

> 之所以会集中在 Android 平台的 `PlatformView ` 实现上去分享，是因为正如标题所示那样，Android 平台的  `PlatformView `  实现目前呈现的状态：混乱。

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image2.png)

## 混乱之始

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image3.png)

就像每个混乱都有它的起源，比如艾泽拉斯的混乱之治起源于燃烧军团的入侵，而混合开发在 Flutter 领域之所以混乱，主要源自它本身独特的实现。

我们常说光明总是伴随着黑暗，Flutter 最大的特点在于：渲染的控件是通过 Skia 直接和 GPU 交互，所以可做到在性能不错的同时，在不同平台得到一致性的渲染效果。

也就是说 Flutter 控件和平台无关，甚至连 UI 绘制线程都和原生平台 UI 线程是相互独立，这就决定了： **Flutter 在和原生平台做混合开发时会有相对高昂的技术成本**。

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image4.png)

> 简单想象下，例如你需要把一个原生的按键渲染到 WebView 里面和前端标签混合到一起，这是不是很不可思议？

还一个更容易理解的角度，其实从渲染的角度看 Flutter 更像是一个「游戏」引擎，只是他可以用来开发 App ，当然它现在也可以用来开发游戏，近两年谷歌的 I/O 大会都用它做了热场游戏，例如今年就做了一个像图片里的卡牌动作游戏，所以 Flutter 其实更像是游戏引擎的逻辑，所以它独立于平台的特性，既是优势，也带来了劣势：

> 毕竟把原生控件渲染进一个类似 unity 的引擎进行混合并不容易。

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image5.gif)

那如果只是单纯的技术问题，也只是实现成本较高而已，为什么会说混乱呢？这就需要谈到目前 Android `PlatformView`  的实现。

不过再谈及 Android `PlatformView ` 实现之前，先简单说说 iOS ，iOS 平台是**通过将 Flutter UI 分为两个透明纹理来完成组合**：

> 需要在 `PlatformView` 下方呈现的 Flutter UI 可以被绘制到其下方的纹理；而需要在 `PlatformView` 上方呈现的 Flutter UI 可以被绘制到其上方的纹理， 它们只需要在最后组合起来就可以了。

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image6.png)

简单来说，就是通过在 `NativeView` 的不同层级设置不同的透明图层，然后把不同位置的控件渲染到不同图层，最终达到组合起来的效果。

> 那 Android 是否采用这种实现？答案明显并不是，因为这种实现在 iOS 上框架渲染后系统会有回调通知，例如：*当 iOS 视图向下移动 `2px` 时，我们也可以将其列表中的所有其他 Flutter 控件也向下渲染 `2px`*。

但是在 Android 上就没有任何有关的系统 API，因此无法实现同步输出的渲染，所以基于此，在各个版本的更新迭代下， Android 的 `PlatformView ` 实现衍生出多种实现逻辑。

目前活跃在 Android 平台的  `PlatformView` 支持主要有以下三种：

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image7.png)

可以看到官方都已经为大家定义好了简称 VD、HC、TLHC ，有了简称也方便大家提 issue 时沟通，毕竟每次在讨论时都用全称很费劲：

> **因为你需要不停指出你用的是什么模式，然后在什么模式下正常or不正常，另外知道这些简称最大的作用就是看 issue 时不迷糊**。

所以后续我们也会用简称来称呼它们，而之所以会有这么多模式，其实就是因为**没有一种模式可以完全满足和覆盖需求** ，这也导致了明明后来出现的模式是为了替代旧的支持，但是最终形成了共存的情况，从而导致了后续混乱的开始。

> 这就好比兽族入侵艾泽拉斯，最后的结果却是兽族和人族共存下来，各个模式之间最终既相爱又相杀的一种情况。

## VD

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image8.png)

我们先说最早的 VD，VD 简单来说就是使用 VirtualDisplay 渲染原生控件到内存。

`VirtualDisplay` 类似于一个虚拟显示区域，需要结合 `DisplayManager` 一起调用，`VirtualDisplay` 一般在副屏显示或者录屏场景下会用到，而在 Flutter 里 `VirtualDisplay` 会将虚拟显示区域的内容渲染在一个内存 `Surface`上。

在 Flutter 中需要用到 Android 原生 View 的地方会让你使用一个叫 `AndroidView`  的控件，如图所示，**在 Flutter 中通过将 `AndroidView` 需要渲染的内容绘制到 `VirtualDisplays` 中 ，然后通过 textureId 在 `VirtualDisplay` 对应的内存中提取绘制的纹理**：

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image9.png)

> 通过在 Dart 层提供一个 `AndroidView` ，从而获取到控件所需的大小，位置等参数，然后通过  `textureId` ，主要是这个 id 提交给 Flutter Engine ，通过 id Flutter 就可以在渲染时将画面从内存里提出出来。

那么这个实现在满足和最初混合开发接入原生控件的同时，也带来和许多的局限，最常见的就是**触摸事件**和**文字输入**的支持问题。

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image10.png)

#### 触摸事件

因为控件是被渲染在内存里，所以虽然**你在 UI 上看到它就在那里，但是事实上它并不在那里**，你点击到的是 Flutter 所在的原生 `FlutterView`，**用户产生的触摸事件是直接发送到 `FlutterView`**。

> 触摸事件需要在 `FlutterView` 到 Dart ，再从 Dart 转发到原生，然后如果原生不处理又要转发回 Flutter ，中间如果还存在其他派生视图，事件就很容易出现丢失和无法响应。

而 Android 的 `MotionEvent` 在转化到 Flutter 过程中可能会因为机制的不同，存在某些信息没办法完整转化的丢失。

#### 文字输入

另外关于文字输入 的问题，一般情况下 **`AndroidView` 是无法获取到文本输入，因为 `VirtualDisplay` 所在的内存位置会始终被认为是 `unfocused` 的状态**。

> 而 `InputConnections` 在 `unfocused` 的 View 中通常是会被丢弃。

所以 **Flutter 重写了 View 的 `checkInputConnectionProxy` 方法，这样 Android 会认为 `FlutterView` 是作为 `AndroidView` 和输入法编辑器（IME）的代理**，这样 Android 就可以从 `FlutterView` 中获取到 `InputConnections` 然后作用于 `AndroidView` 上面。

> 在 Android Q 开始又因为非全局的 `InputMethodManager` 需要新的兼容

所以键盘问题在第一代 VD 上最为突出，因为在不同版本的 Android 上可能会经常非常容易异常，为 `WebView` 作为混合开发里最常用到的插件，键盘是它最精彩会用到的能力之一，这个局限对于 VD 来说非常致命。

## HC

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image11.png)

Flutter 是在 1.2 版本开始支持 HC，简单说就是直接把原生控件覆盖在 Flutter 上进行堆叠，它使用了类似 iOS 的实现思路，简单来说就是 `HybridComposition` 模式会直接把原生控件通过 `addView` 添加到 `FlutterView` 上 。

举一个简单的例子，如图所示，一个原生的 `TextView` 被通过 HC 模式接入到 Flutter 里（`NativeView`），而在 Android 的显示布局边界和 Layout Inspector 上可以清晰看到： **灰色 `TextView` 通过 `FlutterMutatorView` 被添加到 `FlutterView` 上被直接显示出来** 。

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image12.png)

**所以在 HC 模式里 `TextView` 是直接在原生代码上被 add 到 `FlutterView` 上，而不是提取纹理**。

那如果我们看一个复杂一点的案例，如图所示，其中蓝色的文本是原生的 `TextView` ，红色的文本是 Flutter 的 `Text` 控件，在中间 Layout Inspector 的 3D 图层下可以清晰看到：

- 两个蓝色的 `TextView` 是被添加在 `FlutterView` 之上，并且把没有背景色的红色 RE 遮挡住了
- 最顶部有背景色的红色 RE 也是 Flutter 控件，但是因为它需要渲染到 `TextView` 之上，所以这时候多一个 `FlutterImageView` ，它用于承载需要显示在 Native 控件之上的纹理，从而达 Flutter 控件“真正”和原生控件混合堆叠的效果。

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image13.png)

**可以看到 `Hybrid Composition` 上这种实现，能更原汁原味地保流下原生控件的事件和特性，因为从原生角度看它就是原生层面的物理堆叠，需要叠加一个层级就多加一个 `FlutterImageView` ，同一个层级的 Flutter 控件共享一个 `FlutterImageView`** 。

当然，这里出现的 `FlutterImageView` ，其实还有一个作用，就是**为了解决动画同步和渲染**。

前面说过，HC 是直接被添加到原生 `FlutterView` 上面，所以走的还是原生的渲染流程和时机，而这时候通过 `FlutterImageView` ，也就是把 Flutter 控件渲染也同步到原生的 `OnDraw` 上，这样对于画面同步会更好。

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image14.png)

当然，这样带来了一个问题，因为此时原生控件是直接渲染，所以需要在原生的平台线程上执行，纯在 Flutter 的 UI 线程就存在线程同步问题，所以在此之前一些场景下会有画面闪烁 bug ，例如：

- `A page` -> `webview page` -> `B page` ， 当  `webview page` 打开 `B page`  时，有时候 `A page` 的 UI 在 `B page `  突然闪动

- 当 `B page`  返回 `webview page `, 然后再返回  `A page`， 有时候 `B page` UI 突然闪现在 `A page` 

虽然这个问题最后也通过类似线程同步实现解决，但是也带来一定程度的性能开销，另外在 Android 10 之前还会存在 GPU->CPU->GPU的性能损耗，所以 HC 属于会性能开销较大，又需要原生控件特性的场景。

## TLHC

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image15.png)

3.0 版本之后开始支持 TLHC 模式，最初它的目的还是取代上面这两种模式，解决混乱之治，但是奈何它最后和阿尔萨斯一样，成了新一代的巫妖王。

目前 TLHC 和 VD 还有 HC 一起共存下来，该模式的最大特点是控件虽然在还是布局在该有的位置上，但是其实是通过一个 `FrameLayout` 代理 `onDraw` 然后替换掉 child 原生控件的 `Canvas`  来实现混合绘制。

TLHC 算是参考了 VD 和 HC 的模式，然后利用平台的特点来完成渲染，所以它带了 HC ，但又并不是 HC，最大的特点就是它不在让控件通过原生线程绘制，所以也就不需要做线程同步。

而说它参考 VD ，主要是它和 VD 很类似，不同之处在于**原生控件纹理的提取方式上**，如图可以看到 ：

- 从 VD 到 TLHC 里， **Plugin 的实现是可以无缝切换，因为主要修改的地方在于底层对于纹理的提取和渲染逻辑**
- 以前 Flutter 中将 `AndroidView` 需要渲染的内容绘制到 `VirtualDisplays` ，然后在 `VirtualDisplay` 对应的内存中，绘制的画面就可以通过其 `Surface` 获取得到；**现在 `AndroidView` 需要的内容，会通过 View 的 `draw` 方法被绘制到 `SurfaceTexture` 里，然后同样通过 `TextureId` 获取绘制在内存的纹理** 

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image16.png)

简单说就是不需要绘制到副屏里，现在直接通过 override `View` 的 `onDraw` 方法就可以了，然后因为它是绘制到内存，最终渲染还是在 Flutter 线程完成，所以也就不需要线程同步。

举个例子，还是之前的代码，如图所示，这时候通过 TLHC  模式运行之后，通过 Layout Inspector 的 3D 图层可以看到，两个原生的 `TextView` 通过 `PlatformViewWrapper` 被添加到 `FlutterView` 上。

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image17.png)

但是不同的是，**在 3D 图层里看不到 `TextView` 的内容，因为绘制 `TextView` 的 Canvas 被替换了**，所以 `TextView` 的内容被绘制到内存的 Surface 上，最终会在渲染时同步 Flutter Engine 里。

> 不过 **`PlatfromViewWrapper` 拦截了 Event ，但是其实还是通过 Dart 做二次分发响应，从而实现不同的事件响应** ，它和 VD 的不同是， VD 的事件响应都是在 `FlutterView` 上，但是TLHC 模式，是有独立的原生 `PlatfromViewWrapper` 控件来开始，所以区域效果和一致性会更好。

**那么为什么说 TLHC 模式是巫妖王呢**？

因为这种实现天然不支持  `SurfaceView`  ，因为   `SurfaceView`  是双缓冲机制，所以通过 parent  替换    `Canvas`    的实现并不支持，也就是对于类似地图、视频等插件，如果是  `SurfaceView`   ，会出现无法支持的问题。

那有人说，我用 `TextureView` 不就行了？对不起，目前在 [#103686](https://github.com/flutter/flutter/issues/103686)  下，对于 `TextureView`    有时候也会出现不正常更新的异常情况。

所以 TLHC 没能带来终结，它反而引入的新的致命缺陷，并且和 VD 还有 HC 融合到了一起。

## 混乱之治

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image18.png)

那为什么这三种模式会导致混乱？首先我们简单总结下前面介绍的内容：

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image19.png)

而随着三种模式的存在，在 API 层面，目前出现了兼容式运行的情况，在 API 上，在目前 3.0+ 的  Flutter  上同样对应有三个 API ，但是这三个 API 并不是直接对应上述三种模式：

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image20.png)

看到没有，这里有一个问题就是：**你其实没办法主动控制是 TLHC 还是 VD ，对于 HC 你倒是可以强行指定**。

另外，不知道你注意到没有，不管是 `initAndroidView` 还是  `initSurfaceAndroidView`  ，它们都可能会在升级到新版本时使用 TLHC 模式，**也就是如果你的  Plugin 没有针对性做更新，那么可能会在不知觉的情况下换了模式，从而有可能出现 bug** 。

> 对于  TLHC 还有一个问题，就是如果你原本没有 SurfaceView  ，但是后面添加  SurfaceView   ，也会触发异常显示的问题。

现在你看出 PlatformView 的混乱了吧？从底层实现的不统一，到 API 再不同版本下不同的行为变化，这就是目前 Android 在 PlatformView 支持下的混乱生态，同时如果你对于目前 PlatformView 存在的问题感兴趣，可以查阅以下相关 issue：

- [#103686](https://github.com/flutter/flutter/issues/103686)
- [#109690](https://github.com/flutter/flutter/issues/109690)
- [#112712](https://github.com/flutter/flutter/issues/112712)
- [#130692](https://github.com/flutter/flutter/issues/130692)

不过整体来说，官方还是建议大家使用 TLHC 模式，因为它的思路总的来说性能会更好，并且更符合预期，在不出现兼容运行的情况下。

好了，今天分享的内容就这些，谢谢大家。

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image21.png)