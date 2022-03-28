对于使用过 Flutter 的开发来说，应该对在 Flutter 混合开发中，通过 `PlatformView` 接入原生控件的方式并不陌生，而如果你是从 Flutter 1.20 之前就开始使用 Flutter ，那么应该对于 Android 上  `PlatformView`  的各种体验问题有过深刻的体会，比如：[ `WebView` 里弹出键盘的问题](https://juejin.cn/post/6858473695939084295)。

> ⚠️注意：文末有惊喜

## 从一个问题开始

恰巧最近一位朋友在 Flutter 2.10.1 上使用 `webview_flutter` 和 `flutter_pdfview`  测试时出现了如下的问题：

```
attachToContext: GLConsumer is already attached to a context at 
android.graphics.SurfaceTexture.attachToGLContext(SurfaceTexture.java:289)
```

**所以借着这个问题来给大家科普下 Flutter 里 `PlatformView` 实现的变迁和未来调整**，首先这个问题的起因是因为：

> virtual displayes 和 hybrid composition 两种 `PlatformView `实现混合使用。

因为从 Flutter 2.10 开始，官方的  Plugin 如  `webview_flutter`  默都是使用  *hybrid composition* 的实现，而第三方的 `flutter_pdfview`  目前还是使用以前的  *virtual display* ，这就出现了两种 `PlatformView` 实现同时出现的情况。

当然，官方在 2.10.2 版本的 [#31390 ](https://github.com/flutter/engine/pull/31390) 上修复了这个问题， 问题的原因在于：**当 rasterizer 任务运行不同的线程时，`GrContext ` 会被重新创建，从而导致 `texture` 变成没有初始化的状态，进而重复调用 `attachToGLContext` 导致崩溃**。

>  所以后续官方修复这个问题，就是在 `attachToGLContext` 之前，如果  `texture`  已经 attach 过，就先调用 `detachFromGLContext` 进行释放，从而避免了初始化 context 的问题。

但是从问题上看，其实这个问题并不是  2.10 才会出现，而是只要在  `SurfaceTextureWrapper`  这个对象存在时 ，混合使用 *virtual displayes* 和 *hybrid composition* 就能引发这个 bug 。

> `SurfaceTextureWrapper`  是官方用于处理同步的问题，因为当 `SurfaceTexture` 被释放时，由于   `SurfaceTexture.release`  是在 platform  线程被调用，而 `attachToGLContext ` 是在 raster  线程被调用，不同线程调用时可能导致：**当 `attachToGLContext ` 被调用时  texture  已经被释放了，所以需要    `SurfaceTextureWrapper`  用于实现 Java 里同步锁的效果**。

所以如果在低版本不想升级，那么可以选择所有 Plugin 都使用   *virtual display*  模式或者   *hybrid composition*  模式，比如   `webview_flutter`   就提供了 `WebView.platform`  用于用户自由选择 `PlatformView`  的渲染模式。

**当然一般情况下我是更建议大家目前都使用   *hybrid composition*  模式，虽然两种模式都有潜在问题，但是相比起来目前    *virtual display*   带来的性能和键盘问题会让人更难以接受**。



## 区别和演进

其实在之前的 [《 Hybrid Composition 深度解析》](https://juejin.cn/post/6858473695939084295) 里就介绍过它们实现的区别，这里再结合上面的问题，从不一样的角度介绍下它们的实现差异和变迁。

### VirtualDisplay 

一般 dart 代码里直接使用 `AndroidView ` 的我们就可以简单认为是使用  *virtual display*   ，比如 [flutter_pdfview 1.2.2 版本 ](https://pub.flutter-io.cn/packages/flutter_pdfview)  ， 这种实现方式是 **通过将 `AndroidView` 需要渲染的内容绘制到 `VirtualDisplays` 实现中 ，然后在 `VirtualDisplay` 对应的内存里，绘制的画面就可以通过其 `Surface` 获取得到**。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-HV/image1)

> `VirtualDisplay` 类似于一个虚拟显示区域，需要结合 `DisplayManager` 一起调用，一般在副屏显示或者录屏场景下会用到。`VirtualDisplay` 会将虚拟显示区域的内容渲染在一个 `Surface`上。

如上图所示，**简单来说就是原生控件的内容被绘制到内存里，然后 Flutter Engine 通过相对应的 `textureId` 就可以获取到控件的渲染数据并显示出来**。

关于   *virtual display*    实现，如果你需要对应路径去调试问题，可以参看如下流程：

![image-20220305161230961](http://img.cdn.guoshuyu.cn/20220328_Flutter-HV/image2)

### HybridComposition

使用    *hybrid composition*   相对会比直接使用 `AndroidView`  在代码上更复杂一点， 需要使用到 [PlatformViewLink](https://link.juejin.cn/?target=https%3A%2F%2Fapi.flutter.dev%2Fflutter%2Fwidgets%2FPlatformViewLink-class.html)、 [AndroidViewSurface](https://link.juejin.cn/?target=https%3A%2F%2Fapi.flutter.dev%2Fflutter%2Fwidgets%2FAndroidViewSurface-class.html) 和 [PlatformViewsService](https://link.juejin.cn/?target=https%3A%2F%2Fapi.flutter.dev%2Fflutter%2Fservices%2FPlatformViewsService-class.html) 这三个对象，首先我们要创建一个 dart 控件：

- 通过 `PlatformViewLink` 的 `viewType` 注册了一个和原生层对应的注册名称，这和之前的 `PlatformView` 注册一样；
- 然后在 `surfaceFactory` 返回一个 `AndroidViewSurface` 用于处理绘制和接收触摸事件；
- 最后在 `onCreatePlatformView` 方法使用 `PlatformViewsService` 初始化 `AndroidViewSurface` 和初始化所需要的参数，同时通过 Engine 去触发原生层的显示。

```dart
Widget build(BuildContext context) {
  // This is used in the platform side to register the view.
  final String viewType = 'hybrid-view-type';
  // Pass parameters to the platform side.
  final Map<String, dynamic> creationParams = <String, dynamic>{};

  return PlatformViewLink(
    viewType: viewType, 
    surfaceFactory:
        (BuildContext context, PlatformViewController controller) {
      return AndroidViewSurface(
        controller: controller,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      );
    },
    onCreatePlatformView: (PlatformViewCreationParams params) {
      return PlatformViewsService.initSurfaceAndroidView(
        id: params.id,
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: StandardMessageCodec(),
      )
        ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
        ..create();
    },
  );
}
```

如果通过上面的问题来做个直观的对比，就会是如下图所示的变化：

![image-20220305160606360](http://img.cdn.guoshuyu.cn/20220328_Flutter-HV/image3)

使用    *hybrid composition*    之后， **`PlatformView` 是通过 `FlutterMutatorView` 把原生控件 `addView` 到 `FlutterView` 上，然后再通过 `FlutterImageView` 的能力去实现图层的混合**，简单解释就是：

>  Flutter 只直接通过原生的 `addView` 方法将  `PlatformView`  添加到 `FlutterView`  ，这就不需要什么 `surface ` 渲染再去获取的开销，而当你还需要再 `PlatformView` 上渲染 Flutter 自己的 Widget 时，Flutter 就会通过再叠加一个  `FlutterImageView`  来承载这个 Widget 。

![img](http://img.cdn.guoshuyu.cn/20220328_Flutter-HV/image4)



举个例子，如下图所示，其中：

- 两个灰色的 Re 是原生的 `TextView`;

- 蓝色、黄色、红色的是 Flutter 的 `Text` ；

![img](http://img.cdn.guoshuyu.cn/20220328_Flutter-HV/image5)

从渲染结果上可以看到：

- 灰色的原生 `TextView`  通过 `PlatformView` 直接就通过原生的 `addView` 方法添加到 `FlutterView` 上；
- 而红色的  Flutter  的  `Text` 控件因为和 `PlatformView `没交集，所以还是 Flutter 原本的渲染逻辑； 
- 黄色和蓝色的 Flutter 控件，因为和  `PlatformView`   有交集，所以通过新的 `FlutterImageView` 做承载渲染。

使用  *hybrid composition*     后，在 Engine 去 `SubmitFrame` 时，会通过 `current_frame_view_count` 去对每个 view 画面进行规划处理，然后会通过判定区域内是否需要 `CreateSurfaceIfNeeded` 函数，最终触发原生的 `createOverlaySurface` 方法去创建 `FlutterImageView`。

```c++
    for (const SkRect& overlay_rect : overlay_layers.at(view_id)) {
      std::unique_ptr<SurfaceFrame> frame =
          CreateSurfaceIfNeeded(context,               //
                                view_id,               //
                                pictures.at(view_id),  //
                                overlay_rect           //
          );
      if (should_submit_current_frame) {
        frame->Submit();
      }
    }
```

如果有需要调试   *hybrid composition*   相关功能的，可以参考如下路径， 和  *virtual display*   不同之处就是在 `create` 之后的路径产生了变化 ， 更多详细演示可见：https://juejin.cn/post/6858473695939084295#heading-2

![image-20220305165318255](http://img.cdn.guoshuyu.cn/20220328_Flutter-HV/image6)

![image-20220305141848256](http://img.cdn.guoshuyu.cn/20220328_Flutter-HV/image7)

### 结论

所以可以看到，***hybrid composition*    保留了更多的原生控件效果，也节省了渲染成本** ，当然目前 `PlatformView` 还有一个比较尖锐的问题，例如 [#95343](https://github.com/flutter/flutter/issues/95343) 的闪动问题，这个问题看来在未来会通过更改渲染方式和纹理优化来解决。

是的，还是因为性能等问题，所以**新的 `PlatforView` 实现来又要来了，从上面提到的  [#31198](https://github.com/flutter/engine/pull/31198)  已经合并可以猜测，下一个稳定版本中，现在的 *virtual displayes*  实现将不复存在，进而替代的是通过新的 `TextureLayer` 实现，未来不排除 *hybrid composition*   也会被取消，不知道大家此刻心情如何？**

![image-20220305170157117](http://img.cdn.guoshuyu.cn/20220328_Flutter-HV/image8)

简单说就是：

- 新的 `PlatformViewWrapper` 会替换掉原本   *virtual display*   里 `SurfaceTextureWrapper`  相关的逻辑，通过对输入的 `Surface` 进行 `lockHardwareCanvas` 获取到 `Canvas` ，再通过 `super.draw(surfaceCanvas);`  进行绘制；
- 关于  *hybrid composition*   目前看起里仅是更换了称谓，只要核心逻辑没有大变动；

而如果未来  `PlatformViewWrapper`  的实现效果良好 ，可以猜测 *hybrid composition*   模式也会进而退出历史舞台，所以唯有感慨， Flutter 的技术演进速度真的好快。