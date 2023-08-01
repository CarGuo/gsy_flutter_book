![](http://img.cdn.guoshuyu.cn/20230719_N30/image1.png)

# Flutter III 之你不知道的 PlatformView 的混乱之治

如果你是从 2018 年开始使用 Flutter ，那么相信你对于 Flutter 在混合开发的支持历程应该会有一个深刻的体会，如果你没尽力过这个时期，不要担心，通过我过往 `PlatformView` 的相关文章，你也可以有一个清晰的感受：

- [Flutter 3.0下的混合开发演进](https://juejin.cn/post/7113655154347343909)

- [告别 VirtualDisplay ，拥抱 TextureLayer](https://juejin.cn/post/7098275267818291236)

- [Flutter 深入探索混合开发的技术演进](https://juejin.cn/post/7093858055439253534)

- [HybridComposition 和 VirtualDisplay 的实现与未来演进](https://juejin.cn/post/7071549421116194847)

- [ Hybrid Composition 深度解析](https://juejin.cn/post/6858473695939084295)

- [Android PlatformView 和键盘问题](https://juejin.cn/post/6844904070906380296)

总而言之，目前 Flutter 对于 `PlatformView` 的支持，特别是在 Android 平台上，只能用一个字来形容：「乱」。

![](http://img.cdn.guoshuyu.cn/20230719_N30/image2.png)

这个「乱」不只是体现在 API 和底层实现方案上，更表现在你遇到 issue 时，不确定到底是因为什么引起的困惑上，因为目前 Flutter 在 Android 平台的  `PlatformView`  会根据不同的 SDK 版本和场景进行「兜底」兼容，存在各种历史包袱。

> 其实我已经不是很想写这方面的内容了，但是奈何总有人问，那么本篇就来个总结式科普。

目前活跃在 Android 平台的  `PlatformView` 支持主要有以下三种：

- Virtual Display (VD)
- Hybrid Composition (HC)
- Texture Layer Hybrid Composition (TLHC)

可以看到官方都已经为大家定义好了简称 VD、HC、TLHC ，有了简称也方便大家提 issue 时沟通，毕竟每次在讨论时都用全称很费劲：

> **因为你需要不停指出你用的是什么模式，然后在什么模式下正常or不正常，另外知道这些简称最大的作用就是看 issue 时不迷糊**。

那么，接下来主要简单介绍它们的区别：

## VD

VD简单来说就是使用 VirtualDisplay 渲染原生控件到内存，然后利用 id 在 Flutter 界面上占用一个相应大小的位置，最后通过 id 关联到 Flutter Texture 里进行渲染。

![](http://img.cdn.guoshuyu.cn/20230719_N30/image3.png)

问题也很明显，因为控件不会真实存在渲染的位置，所以此时的点击和对原生控件的操作，其实都是需要由 Flutter 这个 View 进行二次转发，另外因为控件是渲染在内存里，所以和键盘交互需要通过二级代理处理，这就产生了各种键盘输入的异常问题。

> 键盘问题突出在不同版本的 Android 兼容上。

## HC

1.2 版本开始支持 HC，简单说就是直接把原生控件覆盖在 Flutter 上进行堆叠，如果出现 Flutter Widget 需要渲染在 Native Widget 上，就采用新的 `FlutterImageView` 来承载新图层。

![](http://img.cdn.guoshuyu.cn/20230719_N30/image4.png)

好处是原生视图是直接显示渲染，坏处就是在 Android 10 之前存在 GPU->CPU->GPU的性能损耗。

另外因为此时原生控件是直接渲染，所以需要在原生的平台线程上执行，这和 Flutter 的 UI 线程就存在线程同步问题，所以在此之前一些场景下会有画面闪烁 bug 。

## TLHC

3.0 版本开始支持 TLHC 模式，最初的目的是取代上面这两种模式，奈何最终只能共存下来，该模式下控件虽然在还是布局在该有的位置上，但是其实是通过一个 `FrameLayout` 代理 `onDraw` 然后替换掉 child 原生控件的 `Canvas`  来实现混合绘制。

![](http://img.cdn.guoshuyu.cn/20230719_N30/image5.png)

> 所以看到此时上图 `TextView` 里没有了内容，因为 `TextView` 里的  `Canvas`  被替换成 Flutter 在内存里创建的   `Canvas`   。

但是这种实现天然不支持  `SurfaceView`  ，因为   `SurfaceView`  是双缓冲机制，所以通过 parent 替换    `Canvas`    的实现并不支持。

## 总结

上述就是这目前三种模式的简单描述和对比，如果看不明白，可以通过前面的历史文章进行了解，总结下以下它们的主要问题：

- VD ： 控件不是被真实渲染，容易有触摸和键盘等问题
- HC：  直接堆叠控件，会有性能开销和线程同步问题，某些场景容易出现闪烁和卡顿
- TLHC：不支持  `SurfaceView` ，对于使用   `SurfaceView`  的播放器、地图等插件会有兼容性问题。

> 所以这也是为什么 1.2  HC 出来之后，VD 还在继续被投入使用，以至于 TLHC 发布之后，依然没能完全取代 VD 和 HC 的主要原因，因为目前它们都不是最优解。

而从目前的情况下，`PlatformView` 也成了 Android 平台的沉重包袱，因为多种底层模式在同时工作，并且还在互相「兼容」。

#### API

那么回归到 API 上，在目前 3.0+ 的  Flutter  上同样对应有三个 API ，但是这三个 API 并不是直接对应上述三种模式：

- `initAndroidView` ：默认情况下会使用 TLHC 模式，当 SDK 低于 23 或者存在 `SurfaceView` 的时候，会使用 VD 模式兼容
- `initSurfaceAndroidView` ： 默认情况下会使用 TLHC 模式，当 SDK 低于 23 或者存在 `SurfaceView` 的时候，会使用  HC 模式兼容
- `initExpensiveAndroidView`： 强行完全使用 HC 模式

看到没有，这里有一个问题就是：**你其实没办法主动控制是 TLHC 还是 VD ，对于 HC 你倒是可以强行指定**。

另外，不知道你注意到没有，不管是 `initAndroidView` 还是  `initSurfaceAndroidView`  ，它们都可能会在升级到新版本时使用 TLHC 模式，**也就是如果你的  Plugin 没有针对性做更新，那么可能会在不知觉的情况下换了模式，从而有可能出现 bug** 。

 例如  TLHC 模式：

- 对于 `SurfaceView` 的不支持存在一些特殊情况，假设一开始 `PlatformView` 创建时不存在 `SurfaceView` ，但是后续又添加了  `SurfaceView`  ，那么该模式将无法正常工作 [#109690](https://github.com/flutter/flutter/issues/109690)。
- 对于 TextureView 场景，有时候会出现不正常更新的异常情况[#103686](https://github.com/flutter/flutter/issues/103686) 。

现在你看出 PlatformView 的混乱了吧？从底层实现的不统一，到 API 再不同版本下不同的行为变化，这就是目前 Android 在 PlatformView 支持下的混乱生态，同时如果你对于目前 PlatformView 存在的问题刚兴趣，可以查阅以下相关 issue：

- [#103686](https://github.com/flutter/flutter/issues/103686)
- [#109690](https://github.com/flutter/flutter/issues/109690)
- [#112712](https://github.com/flutter/flutter/issues/112712)
- [#130692](https://github.com/flutter/flutter/issues/130692)

所以，目前的 Android PlatformView 就给我一种既视感，好比魔兽世界里的平行分支：

- 地狱咆哮喝下了恶魔之血，绿皮吼爷打爆深渊领主玛诺洛斯
- 地狱咆哮拒绝喝恶魔之血，橙皮吼爷打爆深渊领主玛诺洛斯

虽然都是打爆了玛诺洛斯，虽然吼爷结局都一样扑街，但是中间的剧情走向还是有着极大的分歧，所以只能寄希望未来的世界线可以正常「收束」，能有一位「伯瓦尔」来结束这个混乱之治的时代。

![](http://img.cdn.guoshuyu.cn/20230719_N30/image6.png)