# Flutter 深入探索混合开发的技术演进

关于 Flutter 混合 `PlatformView` 的实现已经介绍过两次，随着 5 月份谷歌 IO 的接近，新的  `PlatformView` 实现应该也会随之而来，本次就从头到尾来一个详细的关于 `PlatformView`  的演进总结。

> Flutter 作为新一代的跨平台框架，通过自定义渲染引擎的创新大大提高了跨平台的性能和一致性，但也正是因为这点， 相比之下 Flutter 在混合开发时对于原生控件的支持成本更高。

## Flutter 混合开发的难点

首先 Flutter 在混合开发中最大的难点就在于它独立的渲染引擎，举一个不是很恰当的例子：

> Flutter 里混合开发类似与把原生控件渲染到 `WebView ` 里。

大致上在 Flutter 里混合开发的感觉就是这样，因为 **Flutter UI 不会转换为原生控件，而是由 Flutter Engine 使用 Skia 直接渲染在 `Surface` 上**。

所以 Flutter 在最早出来时并不支持  `WebView` 或 `MapView` 这些常用的控件，这也导致了当时 Flutter 一度的风评不大好，所以衍生出了第一代非官方的混合开发支持，例如： `flutter_webview_plugin `。

**在官方 `WebView` 控件支持出来之前** ，第三方是直接在 `FlutterView` 上覆盖了一个新的原生控件，利用 Dart 中的占位控件来**传递位置和大小**。

> Flutter 里几乎所有渲染都是渲染到  `FlutterView`  这样一个单页面上，所以直接覆盖一个新的原生 `WebView` 只能说缓解燃眉之急。

如下图，在 Flutter 端 `push` 出来一个 **设定好位置和大小** 的 `SingleChildRenderObjectWidget` ，从而得到需要显示的大小和位置，将这些信息通过 `MethodChannel` 传递到原生层，在原生层 `addContentView` 一个指定大小和位置的 `WebView` 。

![](http://img.cdn.guoshuyu.cn/20220309_DWZB/image1.png)

这样看起来就像是在 Flutter 中添加了 `WebView` ，但实际这样的操作只能说是“救急”，**因为这样的行为脱离了 Flutter 的渲染树**，其中一个问题就是：

>  当你跳转 Flutter 其他页面的时候会被当前原生的 `WebView` 挡住；并且打开页面的动画时`Appbar` 和 `WebView` 难以保持一致，因为 `Appbar` 和 `WebView` 是出于两个动画体系和渲染体系。

就比如打开了新的 Flutter UI 2 页面，但是由于它还是在 `FlutterView` 内，所以它会被 `WebView` 所遮挡。

![image-20220307175357032](http://img.cdn.guoshuyu.cn/20220309_DWZB/image2.png)

但是这个“占位”显示的思路，也起到了一定的作用，在后续 Flutter 支持原生 `PlatformView` 上起到了带头的作用。

## Flutter 初步支持原生控件

为了让 Flutter 真正走向大众化，官方开始推出了官方基于  `PlatformView`  的系列实现，比如: `webview_flutter` ，而这个实现 “缝缝补补” 也被沿用至今，成了 Flutter 接入原生的方式 之一。

### Android

在 `PlatformView`  的整个实现中 Android 坑一直是最多的，因为一开始 Android 上主要是通过 `AndroidView` 做完成这项工作，而它的 *Virtual Displays* 实现其实并不友好。

**在 Flutter 中会将 `AndroidView` 需要渲染的内容绘制到 `VirtualDisplays` 中 ，然后在 `VirtualDisplay` 对应的内存中，绘制的画面就可以通过其 `Surface` 获取得到**。

> `VirtualDisplay` 类似于一个虚拟显示区域，需要结合 `DisplayManager` 一起调用，一般在副屏显示或者录屏场景下会用到，在 `VirtualDisplay` 里会将虚拟显示区域的内容渲染在一个 `Surface` 上。

![image-20220307180859494](http://img.cdn.guoshuyu.cn/20220309_DWZB/image3.png)

如上图所示，**简单来说就是原生控件的内容被绘制到内存里，然后 Flutter Engine 通过相对应的 `textureId` 就可以获取到控件的渲染数据并显示出来**，这个过程 `AndroidView` 这个占位控件提供了 size、offset 等位置和大小参数。

通过从 `VirtualDisplay` 获取纹理，并将其和 Flutter 原有的 UI 渲染树混合，使得 Flutter 可以在自己的 Flutter Widget tree 中以图形方式插入 Android 原生控件。

### iOS

在 iOS 平台上就不使用类似 `VirtualDisplay` 的方法，而是**通过将 Flutter UI 分为两个透明纹理来完成组合：一个在 iOS 平台视图之下，一个在其上面**。

所以这样的好处就是：

- 需要在 “iOS平台” 视图下方呈现的Flutter UI，最终会被绘制到其下方的纹理上；
- 而需要在 “平台” 上方呈现的 Flutter UI，最终会被绘制在其上方的纹理；

iOS 上**它们只需要在最后组合起来就可以了**，通常这种方法更好，因为这意味着 Native View 可以直接添加到 Flutter 的 UI 层次结构中，但是可惜一开始 Android 平台并不支持这种模式。

### 问题

尽管前面可以使用 `VirtualDisplay` 将 Android 控件嵌入到 Flutter UI 中 ，但这种 `VirtualDisplay` 这种介入还有其他麻烦的问题需要处理。

#### 触摸事件

**默认情况下， `PlatformViews` 是没办法接收触摸事件**，因为 `AndroidView` 其实是被渲染在 `VirtualDisplay` 中 ，而每当用户点击看到的 `"AndroidView"` 时，其实他们就真正”点击的是正在渲染的 `Flutter` 纹理 ，**用户产生的触摸事件是直接发送到 Flutter View 中，而不是他们实际点击的 `AndroidView`**。

所以 `AndroidView` 使用 Flutter Framework 中检测用户的触摸是否在需要的特殊处理的区域内：

> 当触摸成功时会向 Android embedding 发送一条消息，其中包含 touch 事件的详细信息。

这就变成有些本末倒置，触摸事件从原生-Flutter-原生，中间的转化导致某些信息被丢失，也导致了响应的延迟。

#### 文字输入

**`AndroidView` 是无法获取到文本输入，因为 `VirtualDisplay` 所在的位置会始终被认为是 `unfocused` 的状态**。

所以需要做一套代理来处理 `InputConnections` 做输入，甚至这个行为在 `WebView` 上更复杂，因为 `WebView`  具有自己内部的逻辑来创建和设置输入连接，而这些输入连接并没有完全遵循 Android 的协议。

###  同步问题

另外还需要处理各种同步问题，比如官方就创建了一个 `SurfaceTextureWrapper`  用于处理同步的问题。

因为当承载 `AndroidView`  的 `SurfaceTexture` 被释放时，由于 `SurfaceTexture.release` 是在 platform 线程被调用，而 `attachToGLContext `是在 raster 线程被调用，不同线程调用时可能导致：**当 `attachToGLContext `被调用时 texture 已经被释放了，所以需要 `SurfaceTextureWrapper` 用于实现 Java 里同步锁的效果**。



## Flutter Hybrid Composition



所以经历了 *Virtual Display* 的折磨之后，官方终于在后续推出了更为合理的实现。

### 实现逻辑

 *hybrid composition*  的出现给 Flutter 提供了一种新的混合思路，**那就是直接把原生控件添加到 Flutter 里一起组合渲染**。

首先简单介绍下使用，比起  *Virtual Display* 直接使用 `AndroidView`  ，*hybrid composition*  相对会复杂一点点，dart 里使用到 `PlatformViewLink` 、`AndroidViewSurface` 、 `PlatformViewsService` 这三个对象。

正常在 dart 层面，使用  *hybrid composition*   接入原生控件：

- 通过 `PlatformViewLink` 的 `viewType` 注册了一个和原生层对应的注册名称，这和之前的 `PlatformView` 注册一样；
- 然后在 `surfaceFactory` 返回一个 `AndroidViewSurface` 用于处理绘制和接收触摸事件，同时也是一个类似占位的作用；
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

看起来好像是把一个  `AndroidView`  完成的事情变得相对复杂了，但是其实  *hybrid composition*  的实现相比其实更好理解。

使用 *hybrid composition* 之后， **`PlatformView` 就直接通过 `FlutterMutatorView`（一个特殊的 `FrameLayout`） 把原生控件 `addView` 到 `FlutterView`上，然后再通过 `FlutterImageView` 的能力去实现多图层的混合**。

不理解吗？没事，我们后面会详细介绍，先简单解释就是：

> Flutter 只直接通过原生的 `addView` 方法将 `PlatformView` 添加到 `FlutterView` ，这就不需要什么 `surface `渲染再去获取的开销，而当你还需要再 `PlatformView` 上渲染 Flutter 自己的 Widget 时，Flutter 就会通过再叠加一个 `FlutterImageView` 来承载这个 Flutter Widget 。

![image-20220308173844917](http://img.cdn.guoshuyu.cn/20220309_DWZB/image4.png)



### 深入例子详解



接下来让我们从实际例子去理解 *Hybrid Composition* ，结合  Andriod Studio 的 Layout Inspector，并开启手机的绘制边界来看会更直观。

如下代码所示，一般情况下我们运行之后会看到一片黑色，因为这时候  `FlutterView` 只有一个 `FlutterSurfaceView` 的子控件存在，此时虽然我们画面上是有一个 Flutter 的红色 `RE`  文本控件 ，不过因为是由 Flutter 直接在 Surface 直接绘制，所以   Layout Inspector 看不到只显示黑色。

```dart
Stack(
  fit: StackFit.expand,
  children: [
    Align(
      alignment: Alignment.center,
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 100, color: Colors.red),
      ),
    )
  ],
)
```



![](http://img.cdn.guoshuyu.cn/20220309_DWZB/image5.png)

此时我们添加一个通过 *Hybrid Composition* 实现一个原生的 `TextView` 控件，通过 `PlatformView` 在 Flutter 上渲染出一个灰色 `RE` 文本。

```dart
Stack(
  fit: StackFit.expand,
  children: [
    Align(
      alignment: Alignment(-0.6, -0.6),
      child: SizedBox(
        height: 100,
        width: 100,
        child: NativeView(),
      ),
    ),
    Align(
      alignment: Alignment.center,
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 100, color: Colors.red),
      ),
    )
  ],
)
```

![image-20220308110032575](http://img.cdn.guoshuyu.cn/20220309_DWZB/image6.png)

可以看到，如上图所示，在我们的显示布局边界上可以清晰看到它的信息：

>  `TextView` 通过 `FlutterMutatorView` 被添加到 `FlutterView` 上被直接显示出来。

**所以  `TextView`  是直接在原生代码上被 add 到  `FlutterView` 上，而不是提取纹理**，另外可以看到，左侧栏里多了一个 `FlutterImageView` ，并且之前看不到的 Flutter 控件红色 `RE` 文本也出现了，背景也变成了 Flutter 上的白色。

我们先暂时忽略新出现的  `FlutterImageView`  和 Flutter UI 能够出现在 Layout Inspector 的原因，留到后面再来分析，此时我们再新增加以一个红色的 Flutter  `RE` 控件到` Stack` 里，位于 `PlatformView` 的灰色 `RE` 下。

```dart
Stack(
  fit: StackFit.expand,
  children: [
    Align(
      alignment: Alignment(-0.4, -0.4),
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 100, color: Colors.red),
      ),
    ),
    Align(
      alignment: Alignment(-0.6, -0.6),
      child: SizedBox(
        height: 100,
        width: 100,
        child: NativeView(),
      ),
    ),
    Align(
      alignment: Alignment.center,
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 100, color: Colors.red),
      ),
    )
  ],
)
```



![](http://img.cdn.guoshuyu.cn/20220309_DWZB/image7.png)

如上图所示，可以看到布局和渲染效果正常，Flutter 的红色 `RE ` 被上面的  `PlatformView` 灰色 `RE` 遮挡了部分，这是符合代码的渲染效果。

如果这时候我们把新增加的第二个红色 `RE` 放到灰色  `PlatformView` 灰色 `RE` 上，会发生什么情况？

```dart
 Stack(
  fit: StackFit.expand,
  children: [
    Align(
      alignment: Alignment(-0.6, -0.6),
      child: SizedBox(
        height: 100,
        width: 100,
        child: NativeView(),
      ),
    ),
    Align(
      alignment: Alignment(-0.4, -0.4),
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 100, color: Colors.red),
      ),
    ),
    Align(
      alignment: Alignment.center,
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 100, color: Colors.red),
      ),
    )
  ],
)
```

![image-20220308110325717](http://img.cdn.guoshuyu.cn/20220309_DWZB/image8.png)

可以看到红色的 `RE`  成功被渲染到灰色  `RE` 上 ，而之所以能够渲染上去的原因，是因为这个和  `PlatformView`  有交集的 `Text` ，被渲染到一个新增的 `FlutterImageView` 控件上， 也就是 Flutter 判断了此时新红色  `RE` 文本需要渲染到 `PlatformView`  上，所以添加了一个  `FlutterImageView`  用于承载这部分渲染内容。

如果这时候挪动第二个红色的  `RE` 让它和  `PlatformView`  没有交集，但是还是在 `Stack` 里位于   `PlatformView`   之上会如何？

```dart
Stack(
  fit: StackFit.expand,
  children: [
    Align(
      alignment: Alignment(-0.6, -0.6),
      child: SizedBox(
        height: 100,
        width: 100,
        child: NativeView(),
      ),
    ),
    Align(
      alignment: Alignment(-0.8, -0.8),
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 50, color: Colors.red),
      ),
    ),
    Align(
      alignment: Alignment.center,
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 100, color: Colors.red),
      ),
    )
  ],
)
```



![image-20220308110754283](http://img.cdn.guoshuyu.cn/20220309_DWZB/image9.png)

可以看到虽然  `FlutterImageView` 没了，第二个红色的  `RE` 也回到了默认的 Surface上，所以这就是 *Hybrid Composition* 混合原生控件的最基础设计理念：

- **直接把原生控件添加到 `FlutterView` 之上**；
- **原生和 Flutter 控件混合堆叠时，用新的    `FlutterImageView`   来实现层级覆盖；**
- **如果没有交集就不需要新的 `FlutterImageView`；**



关于   `FlutterImageView`   后面再展开，我们继续这个例子，让两个 Flutter   的红色 `RE` 都渲染到  `PlatformView`    的灰色的`RE `上会是什么情况？

```dart
Stack(
  fit: StackFit.expand,
  children: [
    Align(
      alignment: Alignment(0.6, 0),
      child: SizedBox(
        height: 100,
        width: 100,
        child: NativeView(),
      ),
    ),
    Align(
      alignment: Alignment(0.6, 0),
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 50, color: Colors.red),
      ),
    ),
    Align(
      alignment: Alignment.center,
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 100, color: Colors.red),
      ),
    )
  ],
)
```



![image-20220308181045237](http://img.cdn.guoshuyu.cn/20220309_DWZB/image10.png)

如上图所示，可以看到两个红色的 Flutter `RE` 控件共享了一个 `FlutterImageView`  ，这里可以得到一个新的结论：**和 `PlatformView` 有交集的同层级 Flutter 控件会同享同一个 `FlutterImageView`  。 **

我们继续调整示例，如下代码我们新增多一个 `PlatformView`  的灰色 `RE` 控件，然后调整位置，但是 Flutter 控件都在一个层级上，运行之后可以看到，只要 Flutter 控件都在同一个层级，就同享同一个 `FlutterImageView`  。

```dart
Stack(
  fit: StackFit.expand,
  children: [
    Align(
      alignment: Alignment(-0.2, 0),
      child: SizedBox(
        height: 100,
        width: 100,
        child: NativeView(),
      ),
    ),
    Align(
      alignment: Alignment(0.2, 0),
      child: SizedBox(
        height: 100,
        width: 100,
        child: NativeView(),
      ),
    ),
    Align(
      alignment: Alignment(0, -0.1),
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 50, color: Colors.red),
      ),
    ),
    Align(
      alignment: Alignment(0,  0.2),
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 100, color: Colors.red),
      ),
    )
  ],
)
```

![image-20220308181925410](http://img.cdn.guoshuyu.cn/20220309_DWZB/image11.png)



但是如果不在一个层级呢？我们调整两个灰色 `RE` 的位置，让 `PlatformView`  的灰色 `RE` 和 Flutter 的红色 `RE` 交替出现。

```dart
Stack(
  fit: StackFit.expand,
  children: [
    Align(
      alignment: Alignment(-0.2, 0),
      child: SizedBox(
        height: 100,
        width: 100,
        child: NativeView(),
      ),
    ),
    Align(
      alignment: Alignment(0, -0.1),
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 50, color: Colors.red),
      ),
    ),
    Align(
      alignment: Alignment(0.2, 0),
      child: SizedBox(
        height: 100,
        width: 100,
        child: NativeView(),
      ),
    ),
    Align(
      alignment: Alignment(0,  0.2),
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 100, color: Colors.red),
      ),
    )
  ],
)
```

![image-20220308182349443](http://img.cdn.guoshuyu.cn/20220309_DWZB/image12.png)

可以看到，两个红色的 Flutter `RE` 控件都单独被渲染都一个 `FlutterImageView` 上，所以我们有新的结论：**和 `PlatformView` 有交集的 Flutter 控件如果在不同层级，就需要不同的  `FlutterImageView`  来承载。**

所以一般在使用 `PlatformView`  的场景上，不建议有过多的层级堆叠或者过于复杂的 UI 场景。



接着我们继续测试，还记得前面说过   *Virtual Display*  上关于触摸事件的问题，所以此时我们直接给 `PlatformView`  的 灰色 `RE` 在原生层添加点击事件弹出 Toast 测试。

```dart
 Stack(
  fit: StackFit.expand,
  children: [
    Align(
      alignment: Alignment(-0.7, 0),
      child: SizedBox(
        height: 100,
        width: 100,
        child: NativeView(),
      ),
    ),
    Align(
      alignment: Alignment(0.8, 0),
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 50, color: Colors.red),
      ),
    ),
    Align(
      alignment: Alignment.center,
      child: Container(
        color: Colors.amber,
        child: new Text(
          "RE",
          style: TextStyle(fontSize: 100, color: Colors.red),
        ),
      ),
    ),
  ],
)
```

![image-20220308112613726](http://img.cdn.guoshuyu.cn/20220309_DWZB/image13.png)



可以看到运行后点击能够正常弹出 Toast ，所以对于  `PlatformView`   来说本身的点击和触摸是可以正常保留，然后我们调整下红色大 `RE` 和灰色 `RE` 让他们产生交集，同时给红色的大 `RE` 也添加点击事件，弹出 `SnackBar` 。

```dart
Stack(
  fit: StackFit.expand,
  children: [
    Align(
      alignment: Alignment(-0.3, 0),
      child: SizedBox(
        height: 100,
        width: 100,
        child: NativeView(),
      ),
    ),
    Align(
      alignment: Alignment(0.8, 0),
      child: new Text(
        "RE",
        style: TextStyle(fontSize: 50, color: Colors.red),
      ),
    ),
    Align(
      alignment: Alignment.center,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: new Text("Re Click")));
        },
        child: Container(
          color: Colors.amber,
          child: new Text(
            "RE",
            style: TextStyle(fontSize: 100, color: Colors.red),
          ),
        ),
      ),
    ),
  ],
)
```



![](http://img.cdn.guoshuyu.cn/20220309_DWZB/image14.png)

运行之后可以看到，点击没有被覆盖的灰色部分，还是可以弹出 Toast ，点击红色 `RE` 和灰色 `RE` 的交集处，可以正常弹出  `SnackBar`。

所以可以看到 ***Hybrid Composition*  上这种实现，能更原汁原味地保流下原生控件的事件和特性，因为从原生 角度，它就是原生层面的物理堆叠**。

现在大家应该大致对于  *Hybrid Composition*  有了一定理解，那回到前面那个一开始 Layout InSpector 黑屏 ，后来又能渲染出界面的原因，这就和首次添加 Hybrid Composition 时多出来的 `FlutterImageView` 有关系。



如下图所示，可以看到此时原生的灰色 `RE` 和 Flutter 的红色 `RE` 是没有交集的，为什么会多出来一个  `FlutterImageView`  呢？

![image-20220309093557122](http://img.cdn.guoshuyu.cn/20220309_DWZB/image15.png)



这就需要说到 `flutterView.convertToImageView()` 这个方法。

在 Flutter 渲染  *Hybrid Composition* 的 `PlatformView` 时，会有一个  `flutterView.convertToImageView()`  的操作，这个操作是：**把默认的 `FlutterSurfaceView` 渲染切换到 `FlutterImageView` 上** ，所以此时会有一个 新增的  `FlutterImageView`  出现在  `FlutterSurfaceView`  之上。

> 为什么需要  `FlutterImageView`  ？那就要先理解下  `FlutterImageView`   是如何工作的，因为在前面我们说过，和  `PlatformView`  有交集的时候 Flutter 的控件也会被渲染到   `FlutterImageView`   上。

`FlutterImageView`   本身是一个原生的 Android View 控件，它的内部有几个关键对象：

- `imageReader`  ：提供一个 surface ，并且能够直接访问到 surface  里的图像数据；
- `flutterRenderer` :  外部传入的 Flutter 渲染类，这里用于切换/提供 Flutter Engine 里的渲染所需 surface  ；
- `currentImage` : 从 `imageReader`  里提取出来的 `Image` 画面；
- `currentBitmap` ：将  `Image`  转为 `Bitmap` ，用于 `onDraw` 时绘制；



所以简单地说 `FlutterImageView`   工作机制就是：**通过 `imageReader`  提供 surface 给 Engine 渲染，然后把 `imageReader`  里的画面提取出来，渲染到  `FlutterImageView`    的  `onDraw`   上**。



所以回归到前面的  `flutterView.convertToImageView()`  ，在 Flutter 渲染  *Hybrid Composition* 的 `PlatformView` 时，会先把自己也变成了一个   `FlutterImageView`  ，然后进入新的渲染流程：

- Flutter 在 `onEndFrame` 时，也就是每帧结束时，会判断当前界面是否还有 `PlatformView `，如果没有就会切换会默认的   `FlutterSurfaceView`  ；
- 如果还存在   `PlatformView ` ，就会调用 `acquireLatestImage` 去获取当前  `imageReader`  里的画面，得到新的 `currentBitmap`  ，然后触发 `invalidate` 。
- `invalidate`  会导致 `FlutterSurfaceView`  执行 `onDraw` ，从而把  `currentBitmap`   里的内容绘制出来。

![image-20220308171209135](http://img.cdn.guoshuyu.cn/20220309_DWZB/image16.png)



所以我们搞清楚了  `FlutterImageView` 的作用，也搞清楚了为什么有了  *Hybrid Composition*  的  `PlatformView ` 之后，在 Android Studio 的 Layout Inspector 里可以看到 Flutter 控件的原因：



> **因为有 *Hybrid Composition*   之后， `FlutterSurfaceView` 变成了 `FlutterImageView` ，而  `FlutterImageView` 绘制是通过 `onDraw` ，所以可以在  Layout Inspector 里出现。**



那为什么会有把  `FlutterSurfaceView` 变成了 `FlutterImageView`  这样的操作？**原因其实是为了更好的动画同步和渲染效果**。

因为前面说过，*Hybrid Composition* 是直接把添加到 `FlutterView` 上面，所以走的还是原生的渲染流程和时机，而这时候通过把 `FlutterSurfaceView` 变成了 `FlutterImageView`  ，也就是把 Flutter 控件渲染也同步到原生的 `OnDraw` 上，这样对于画面同步会更好。

那有人就要说了，我就不喜欢  `FlutterImageView`  的实现，有没有办法不在使用 *Hybrid Composition*  时把 `FlutterSurfaceView` 变成了 `FlutterImageView`  呢？

有的，官方在 `PlatformViewsService` 内提供了对应的设置支持： 

```dart
 PlatformViewsService.synchronizeToNativeViewHierarchy(false);
```

在设置为 false 之后，可以看到只有  *Hybrid Composition*   的 `PlatformView`  的内容才能在 Layout Inspector 上看到，而 `FlutterSurfaceView`  看起来就是黑色空白。

![image-20220308151751781](http://img.cdn.guoshuyu.cn/20220309_DWZB/image17.png)

![image-20220308151856383](http://img.cdn.guoshuyu.cn/20220309_DWZB/image18.png)



### 问题

那 *Hybrid Composition*  就是完美吗？ 肯定不是，事实上  *Hybrid Composition*   也有很多小问题，其中就比如性能问题。

例如在不使用  *Hybrid Composition*   的情况下，Flutter App 中 UI 是在特定的光栅线程运行，所以 Flutter 上 App 本身的主线程很少受到阻塞。

**但是在  *Hybrid Composition*   下，Flutter UI 会由平台的 `onDraw` 绘制，这可能会导致一定程度上需要消耗平台性能和占用通信的开销**。

例如在 Android 10 之前， *Hybrid Composition* 需要将内存中的每个 Flutter 绘制的帧数据复制到主内存，之后再从 GPU 渲染复制回来 ，所以也会导致   *Hybrid Composition*   在  Android 10 之前的性能表现更差，例如在滚动列表里每个 Item 嵌套一个   *Hybrid Composition* 的 `PlatformView` 。

> 具体体现在 ImageReader 创建时，大于 29 的可以使用 `HardwareBuffer` ，而`HardwareBuffer` 允许在不同的应用程序进程之间共享缓冲区，通过 `HardwareBuffers` 可以映射各种硬件系统的可访问 memory，例如 GPU。

![image-20220309153648439](http://img.cdn.guoshuyu.cn/20220309_DWZB/image19.png)

**所以如果当 Flutter 出现动画卡顿时，或者你就应该考虑使用 *Virtual Display* 或者禁止  `FlutterSurfaceView` 变成了 `FlutterImageView`**。

> 事实上  *Virtual Display*  的性能也不好，因为它的每个像素都需要通过额外的中间图形缓冲区。



## 未来变化

在目前 master 的  [#31198](https://github.com/flutter/engine/pull/31198) 这个合并上，提出了新的实现方式用于替代现有的 *Virtual Display* 。

这个还未发布到正式本的调整上， *Hybrid Composition*  基本没有变化，主要是调整了一些命名，主要逻辑还是在于 `createForTextureLayer` ，目前还无法保证它后续的进展，目前还有 一部分进度在 [#97628](https://github.com/flutter/flutter/pull/97628) ，所以先简单介绍下它的情况。

在这个新的实现上，*Virtual Display* 的逻辑变成了 `PlatformViewWrapper ` ， `PlatformViewWrapper `  本身是一个 `FrameLayout`  ，同样是 `flutterView.addView(); ` ，基本逻辑和  *Hybrid Composition*  很像，只不过现在添加的是  `PlatformViewWrapper `  。

![image-20220309163231386](http://img.cdn.guoshuyu.cn/20220309_DWZB/image20.png)



在这里   *Virtual Display*   没有了，原本    *Virtual Display*    创建的 Surface 被设置到  `PlatformViewWrapper `   里面。

简单介绍下：**在  `PlatformViewWrapper `   里，会通过 `surface.lockHardwareCanvas();` 获取到当前 ` Surface` 的 `Canvas` ，并且通过 `draw(surfaceCanvas)` 传递给了 `child `**。

所以  `child ` 的 UI 就被绘制到传入的  ` Surface`  上，而 Flutter Engine 根据  ` Surface`   的 id 又可以获取到对应的数据，通过一个不可视的 `PlatformViewWrapper` 完成了绘制切换而无需使用   `VirtualDisplay`  。

当然，目前在测试中接收到的反馈里有还不如以前的性能好，所以后续会如何调整还是需要看测试结果。



> PS ，如果这个修改正式发布，可能 Flutter 的 Android miniSDK 版本就需要到 23 起步了。因为   `lockHardwareCanvas()` 需要 23 起，而不用兼容更低平台的原因是  `lockCanvas()` 属于 CPU copy ，性能上会慢很多

![](http://img.cdn.guoshuyu.cn/WechatIMG230.jpeg)