# Flutter 正在推进全新 PlatformView 实现 HCPP， 它又用到了 Android 上的什么黑科技

跨平台开发里的 PlatformView 实现一直是一个经久不衰的话题，在之前的 [《深入 Flutter 和 Compose 的 PlatformView 实现对比》](https://juejin.cn/post/7461597205342928936) 我们就详细聊过 Flutter 和 Compose 在 PlatformView 实现上的异同之处，也聊到了 Compose 为什么在相同实现上对比 Flutter 会更有优势的原因。

那么随着 3.29 的发布，恰好关注到其实 Flutter 在 Android 的 PlatformView 上其实正在落地另外一种实现，而这种实现目前看来可以做到在 HC 的基础上得到更好的性能，所以也被暂时称为 HCPP。

在聊 HCPP 之前我们再简单回顾下 Flutter 在 Android 上的 PlatformView 实现模式：

- VD：最老的实现模式，利用副屏 `VirtualDisplay` 的相关支持在内存实现原生控件的模拟绘制和纹理提取
- HC：通过直接将原生控件 add 到 `FlutterView` 上，然后通过新的 `FlutterImageView` 提供新的 Surface 来实现控件 UI 堆叠合成
- TLHC：还是直接将原生控件 add 到 `FlutterView` 上，但是中间利用通过 parent 替代掉 child 的 canvas，让原生控件绘制的对应的 ` surface.lockHardwareCanvas` 上

> 有点抽象？，没关系，后面有简单的直观例子。

在这个过程中几种模式各有优劣，比如：

- TLHC 模式不支持 `SurfaceView` 等控件，因为 `SurfaceView` 有自己独立的 Surface 和 Canva ，它的 Surface 直接来自 `SurfaceFlinger` ，也就是当前 Window 下
- TLHC 模式与异步更新 View 一起使用时（如 TextureView 或基于 GL 的渲染器），需要在更新内容时在对应 PlatformView  显式调用 `invalidate`  才能保证正确渲染，例如 ` textureView` 的  `onSurfaceTextureUpdated` 调用  ` mapView.invalidate`  
- HC 模式因为不同 API 版本和线程问题，会有同步和额外的性能开销
- ····

所以目前这三种模式是协同工作，例如：

- `initAndroidView` ： 默认会使用最新的模式，目前就是 TLHC，如果遇到不支持的就降级到 VD![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image1.png)

- `initSurfaceAndroidView`： 默认会使用最新的模，目前就是 TLHC，如果遇到不支持的就降级到 HC![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image2.png)

- `initExpensiveAndroidView`：直接强制使用 HC 模式![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image3.png)

那么，回到本次的主题 ，针对全新的 HCPP 实现，Flutter 提供了全新的 API  `initHybridAndroidView` ，可以看到，**它需要 Vulkan 和 API 34 的环境才支持使用，如果从这点看，它的通用性又相对较低**：

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image4.png)

**那为什么它需要 API 34 呢？这和它直接使用 `SurfaceControl `的 API 逻辑有很大关系**，另外，从 Engine 的判断逻辑上可以看到，目前除了判断  Vulkan 和 API  之后，还需要配置对应的 `EnableSurfaceControl`  才可以测试 HCPP，也就是在 `AndroidManifest` 增加：

```xml
<meta-data
       android:name="io.flutter.embedding.android.EnableSurfaceControl"
       android:value="true" />
```

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image5.png)

接着就让我们来看看 HCPP 和其他几种模式有什么区别，其实主要就是和 HC 和 TLHC 进行比较，这里首先做一个容器 Demo ，主要是通过混合 Flutter 和原生控件的效果来区分它们的实现，让  `platformView` 渲染在两个 Flutter Widget 之间：

```dart
return MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Stack(
    alignment: AlignmentDirectional.center,
    children: <Widget>[
      ///200x200的绿色 Flutter 方块
      TextButton(
        key: const ValueKey<String>('AddOverlay'),
        onPressed: _togglePlatformView,
        child: const SizedBox(width: 190, height: 190, child: ColoredBox(color: Colors.green)),
      ),
      
      ///200x200的原生控件，这里用的是一个红色的原生方块
      if (showPlatformView) ...<Widget>[
        SizedBox(width: 200, height: 200, child: widget.platformView),
        
        
        ///黄色 Flutter 条
        TextButton(
          key: const ValueKey<String>('RemoveOverlay'),
          onPressed: _togglePlatformView,
          child: const SizedBox(
            width: 800,
            height: 25,
            child: ColoredBox(color: Colors.yellow),
          ),
        ),
      ],
    ],
  ),
);
```

之后我们可以通过  `initExpensiveAndroidView  ` 强制 PlatformView 使用 HC 模式，可以看到，在 HC 模式下出现很多经典的原生层，特别是多了 `FlutterImageView` 的转换还有它的子类 `PlatformOverlayView` ：

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image6.png)

我们通过 3D 图可以看到，红色的原生 `BoxPlatformView`  正常被渲染，然后在其之上的 Flutter 控件(一部分黄色条)，是通过  `FlutterImageView`  的子类 `PlatformOverlayView`  提供的 Surface 独立渲染：

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image7.png)

然后我们再通过 `initAndroidView`  来使用 TLHC 模式，可以看到此时是通过 `PlatformViewWrapper` 这个 parent 作为容器来承载，而  `PlatformViewWrapper`  会替换掉原生 `BoxPlatformView`   的 Canvas，让原生控件的内容渲染到指定 Surface 上 ：

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image8.png)

我们通过原生 3D 图可以看到，此时的  `BoxPlatformView`   其实在原生层并没有绘制任何东西，因为其 Canvas 是被替换到内存的 `SurfaceTexture` 上：

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image9.png)

说到  `SurfaceTexture` ，这个插个题外话，对于 THLC 和 VD 而言，现在创建纹理时是会根据 Android API 来使用不同实现，其中  `SurfaceProducer` 比较特殊：

![](https://img.cdn.guoshuyu.cn/WechatIMG1260.jpg)

因为在此之前，Android 上的 Flutter 引擎支持两个外部渲染源：SurfaceTexture （OpenGLES 纹理）和 ImageReader（GPU-ready buffer），其中 `Image.getHardwareBuffer`  需要 API 28 支持。

而为了适配 Impeller 团队提出了 `SurfaceProducer` 概念，让 Android 在运行时选择“最佳”渲染 Surface，除了 PlatformView 场景，在外界纹理场景也需要适配的情况：

```diff
- TextureRegistry.SurfaceTextureEntry entry = textureRegistry.createSurfaceTexture();
+ TextureRegistry.SurfaceProducer producer = textureRegistry.createSurfaceProducer();

- Surface surface = new Surface(entry.surfaceTexture());
+ Surface surface = producer.getSurface();
```

那么我们看 HCPP，通过   `initHybridAndroidView`  我们启用了 HCPP 模式，可以看到，此时 UI 的层级结构类似 TLHC， 但是 parent 使用的是 HC 模式中的 `FlutterMutatorView`  ：

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image10.png)

然后我们看 3D 效果，原生控件 `BoxPlatformView` 其实可以被完整被渲染，证明其 Canvas 并没有被替代，那么这里就有一个神奇的问题了：**Flutter 的黄色控件，是如何渲染到红色的  `BoxPlatformView`  之上的**？

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image11.png)

这就不得不提 `PlatformViewsController2` ，作为一个 HCPP 的临时对象，它的实现里有一个关键的对象  `SurfaceControl` ，并且在事务提交时通过 `setLayer` 设置了 z 轴为 `1000` ：

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image12.png)

我们可以看提交更改里，基本上全新的  `PlatformViewsController2`  核心逻辑都在于操作  `SurfaceControl` ：

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image13.png)

在  Android 里，`SurfaceControl` 是一种用于管理和操作与显示系统相关的图形资源的类，简单说就是与 `Surface` 相关的操作，`SurfaceControl`  可以用于创建和管理  `Surface `，它是和`SurfaceFlinger`  交互的一个主要接口，交互的方式则是通过  `Transaction` 。

而在 HCPP 里，我们可以看到，此时的   `Surface`  正是通过一个全新的 `SurfaceControl`  创建得到，而这个 `SurfaceControl`  的  `Transaction`  来自 `FlutterView` ：

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image14.png)

也就是，在 HCPP 模式里，Flutter 通过 `SurfaceControl.Transaction ` 构造了一个全新的 `Surface` 用于 `SurfaceFlinger` 合成，**并且还通过 ` setLayer`  将 Surface 的 z 轴设置到了 1000 ，而这个 1000 就是黄色 Flutter 控件可以渲染到原生红色方块之上的原因**。

举个例子，我们将 `SurfaceControl` 这部分代码复制到一个简单的纯原生项目里，并且同样对创建的 `Surface` 设置 1000 和绘制红色：

```java
protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
  
    	 ········
   
       // 获取 FrameLayout
        FrameLayout rootView = findViewById(R.id.container);
        rootView.postDelayed(new Runnable() {
            @Override
            public void run() {
                final SurfaceControl.Builder surfaceControlBuilder = new SurfaceControl.Builder();
                surfaceControlBuilder.setBufferSize(500, 500);
                surfaceControlBuilder.setFormat(PixelFormat.RGBA_8888);
                surfaceControlBuilder.setName("Flutter Overlay Surface");
                surfaceControlBuilder.setOpaque(false);
                surfaceControlBuilder.setHidden(false);
                final SurfaceControl surfaceControl = surfaceControlBuilder.build();
                final SurfaceControl.Transaction tx =
                        binding.container.getRootSurfaceControl().buildReparentTransaction(surfaceControl);
                tx.setLayer(surfaceControl, 1000);
                tx.apply();
                surface1 = new Surface(surfaceControl);
                surfaceControl1 = surfaceControl;

                // 在 SurfaceView 上绘制一些内容
                drawOnSurface(surface1, Color.RED);   
            }
        }, 2000);

}

private void drawOnSurface(Surface surface, int color) {
    Canvas canvas = surface.lockCanvas(null);
    if (canvas != null) {
        canvas.drawColor(color);
        surface.unlockCanvasAndPost(canvas);
    }
}
```

然后我们看最终绘制的效果，可以看到绿色背景的 `FrameLayout` 是在 `WebView` 下方的，但是通过 `container.getRootSurfaceControl()` 创建的 `Surface`  因为 z 轴为 1000 的原因，最终红色方块会绘制到 ` WebView` 之上：

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image15.png)

另外，在目前逻辑中，Engine 如果判断当前帧如果不存在 PlatformView ，并且上一帧存在 PlatformView，那么就会调用 `hideOverlaySurface2` 从而直接触发  Java 层面的` platformViewsController2.hideOverlaySurface()`  ，进而隐藏不需要的 Layer ：

```c++
  if (!FrameHasPlatformLayers()) {
    frame->Submit();
    // If the previous frame had platform views, hide the overlay surface.
    if (previous_frame_view_count_ > 0) {
      jni_facade_->hideOverlaySurface2();
    }
    jni_facade_->applyTransaction();
    return;
  }
```

所以可以看到，**HCPP 主要就是通过  `SurfaceControl`  来构造一个高层级的 `Surface` 从而实现最终绘制时混合覆盖的问题**，这和我们之前聊  [《深入 Flutter 和 Compose 的 PlatformView 实现对比》](https://juejin.cn/post/7461597205342928936) 里 Compose 可以在 PlatformView 里直接使用 `SurfaceView` 的道理类似，都是  `SurfaceFlinger` 合成时的层级操作。

至于为什么需要 API 34， 主要也是 SurfaceControl 对应的一些 API 需要的版本都很高，另外我依稀记得，  Android 14 在通过 SurfaceControl 实现低延迟绘图时，可以更好支持 Canvas API 通过硬件加速绘制到 HardwareBuffer ：

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image16.png)

![](http://img.cdn.guoshuyu.cn/20250215_HCPP/image17.png)

如果对于 Engine 部份逻辑感兴趣的，也可以看  `external_view_embedder_2#SubmitFlutterView`   这部分逻辑里如何通过 GetLayer 去创建 `FlutterOverlaySurface` 。

目前 HCPP 还处于 main 分之的 beta 状态，如果后续正式落地，那对于 Android PlatformView 实现将会是存在 4 种组合模式，相比较 iOS 端多个 CALayer 的合成模式，Android 的 PlatformView 可以说是一路坎坷至今。

最后，你觉得 HCPP 会成为落地为全新的 PlatformView 支持吗？

> PS ：`io.flutter.embedding.android.EnableSurfaceControl`  标识还用于控制 Impeller 内部使用  Vulkan swapchain 或者 Android SurfaceControl （AHB swapchain），在 Android SurfaceControl  模式下，Java 端创建的 Transaction 会链接到  AHB swapchain。
>
> 当然， AHBSwapchainVK 交换链实现并非在所有 Android 版本上都可用，一般不支持的话，会回退到 KHR swapchain。

# 参考链接

- https://github.com/flutter/flutter/issues/163073

- https://github.com/flutter/flutter/pull/161829

- https://github.com/flutter/flutter/issues/144184





