# Flutter 3.7 之快速理解 toImageSync 是什么？能做什么？



随着 Flutter 3.7 的更新， `dart:ui` 下多了 `Picture.toImageSync` 和  `Scene.toImageSync`  这两个方法，和`Picture.toImage` 以及 `Scene.toImage` 不同的是  ，`toImageSync`  是一个同步执行方法，所以它不需要 `await`  等待，而调用 `toImageSync` 会直接返回一个 Image 的句柄，并在 Engine 后台会异步对这个 Image 进行光栅化处理。

# 前言

那  `toImageSync `  有什么用？不是有个  `toImage`  方法了，为什么要多一个  Sync 这样的同步方法？

- **目前   `toImageSync `   最大的特点就是图像会在 GPU 中常驻** ，所以对比 `toImage` 生成的图像，它的绘制速度会更快，并且可以重复利用，提高效率。

  > `toImage` 生成的图像也可以实现 GPU 常驻，但目前没有未实现而已。

-  `toImageSync `  是一个同步方法，在某些场景上弥补了 `toImage` 必须是异步的不足。

  ![](http://img.cdn.guoshuyu.cn/20230207_sync/image1.png)

而   `toImageSync `   的使用场景上，官方也列举了一些用途，例如：

- 快速捕捉一张昂贵的栅格化图片，用户支持跨多帧重复使用
- 应用在图片的多路过滤器上
- 应用在自定义着色器上

具体在 Flutter Framework 里，目前   `toImageSync `    最直观的实现，就是被使用在 Android 默认的页面切换动画  `ZoomPageTransitionsBuilder  ` 上，得意于  `toImageSync `   的特性，Android 上的页面切换动画的性能，**几乎减少了帧光栅化一半的时间**，从而减少了掉帧和提高了刷新率。

> 当然，这是通过牺牲了一些其他特性来实现，后面我们会讲到。

# SnapshotWidget

前面说了  `toImageSync `   让 Android 的默认页面切换动画性能得到了大幅提升，那究竟是如何实现的呢？这就要聊到 Flutter 3.7 里新增加的 `SnapshotWidget` 。

其实一开始  `SnapshotWidget`  是被定义为 `RasterWidget` ，从初始定义上看它的 Target 更大，但是最终在落地的时候，被简化处理为了 `SnapshotWidget`  ，而从使用上看确实 Snapshot 更符合它的设定。 

![](http://img.cdn.guoshuyu.cn/20230207_sync/image2.png)



## 概念

**`SnapshotWidget` 的作用是可以将 Child  变成的快照（`ui.Image`）从而替换它们进行显示，简而言之就是把子控件都变成一个快照图片**，而 `SnapshotWidget`  得到快照的办法就是   `Scene.toImageSync`  。

> 那么到这里，你应该知道为什么   `toImageSync `   可以提高 Android 上的页面切换动画的性能了吧？因为  `SnapshotWidget`  会在页面跳转时把  Child  变成的快照，而   `toImageSync `    栅格化的图片还可以跨多帧重复使用。

那么问题来了，`SnapshotWidget`  既然是通过  `toImageSync `    将  Child  变成的快照（`ui.Image`）来提高性能，那么带来的副作用是什么？

答案是动画效果，**因为子控件都变成了快照，所以如果 Child 控件带有动画效果，会呈现“冻结”状态**，更形象的对比如下图所示：

| FadeUpwardsPageTransitionsBuilder                        | ZoomPageTransitionsBuilder                               |
| -------------------------------------------------------- | -------------------------------------------------------- |
| ![](http://img.cdn.guoshuyu.cn/20230207_sync/image3.gif) | ![](http://img.cdn.guoshuyu.cn/20230207_sync/image4.gif) |

默认情况下 Flutter 在 Android 上的页面切换效果使用的是  `ZoomPageTransitionsBuilder` ，而   `ZoomPageTransitionsBuilder`  里在页面切换时会开启 `SnapshotWidget` 的截图能力，所以可以看到，它在页面跳转时，对比  `FadeUpwardsPageTransitionsBuilder` 动图，  `ZoomPageTransitionsBuilder`  的红色方块和掘金动画会停止。

> 因为动画很短，所以可以在代码里设置  **` timeDilation = 40.0;`**  和 `SchedulerBinding.resetEpoch` 来全局减慢动画执行的速度，另外可以配置 `MaterialApp ` 的 `ThemeData`  下对应的  `pageTransitionsTheme` 来切换页面跳转效果。

所以在官方的定义中，**`SnapshotWidget`  是用来协助执行一些简短的动画效果**，比如一些 scale 、 skew 或者 blurs 动画在一些复杂的 child 构建上开销会很大，而使用  `toImageSync `   实现的  `SnapshotWidget`  可以依赖光栅缓存：

> 对于一些简短的动画，例如  `ZoomPageTransitionsBuilder`  的页面跳转，  `SnapshotWidget`  会将页面内的 children 都转化为快照（`ui.Image`），尽管页面切换时会导致 child 动画“冻结”，但是实际页面切换时长很短，所以看不出什么异常，**而带来的切换动画流畅度是清晰可见的**。

再举个更直观的例子，如下代码所示，运行后我们可以看到一个旋转的 logo 在屏幕上随机滚动，这里分别使用了  `AnimatedSlide` 和  `AnimatedRotation`  执行移动和旋转动画。

```dart
Timer.periodic(const Duration(seconds: 2), (timer) {
  final random = Random();
  x = random.nextInt(6) - 3;
  y = random.nextInt(6) - 3;
  r = random.nextDouble() * 2 * pi;
  setState(() {});
});

AnimatedSlide(
  offset: Offset(x.floorToDouble(), y.floorToDouble()),
  duration: Duration(milliseconds: 1500),
  curve: Curves.easeInOut,
  child: AnimatedRotation(
    turns: r,
    duration: Duration(milliseconds: 1500),
    child: Image.asset(
      'static/test_logo.png',
      width: 100,
      height: 100,
    ),
  ),
)
```

![](http://img.cdn.guoshuyu.cn/20230207_sync/image5.gif)



如果这时候在 `AnimatedRotation`  上层加多一个 `SnapshotWidget`  ，并且打开 `allowSnapshotting` ，可以看到此时 logo 不再转动，因为整个 child 已经被转化为快照（`ui.Image`）。

| ![](http://img.cdn.guoshuyu.cn/20230207_sync/image6.png) | ![](http://img.cdn.guoshuyu.cn/20230207_sync/image7.gif) |
| -------------------------------------------------------- | -------------------------------------------------------- |

>所以 `SnapshotWidget`  不适用于子控件还需要继续动画或有交互响应的地方，例如轮播图。



## 使用

如之前的代码所示，使用 `SnapshotWidget`  也相对简单，你只需要配置 `SnapshotController` ，然后通过 `allowSnapshotting `控制子控件是否渲染为快照即可。

```dart
 controller.allowSnapshotting = true;
```

`SnapshotWidget`  在捕获快照时，会生成一个全新的 `OffsetLayer`  和 `PaintingContext`，然后通过 `super.paint` 完成内容捕获（这也是为什么不支持 PlatformView 的原因之一），之后通过 `toImageSync` 得到完整的快照（`ui.Image`）数据，并交给  `SnapshotPainter` 进行绘制。

| ![](http://img.cdn.guoshuyu.cn/20230207_sync/image8.png) | ![](http://img.cdn.guoshuyu.cn/20230207_sync/image9.png) |
| -------------------------------------------------------- | -------------------------------------------------------- |

所以  `SnapshotWidget`  完成图片绘制会需要一个  `SnapshotPainter` ，默认它是通过内置的 `_DefaultSnapshotPainter`  实现，当然我们也可以自定义实现   `SnapshotPainter` 来完成自定义逻辑。

> 从实现上看，`SnapshotPainter` 用来绘制子控件快照的接口，正如上面代码所示，会根据 child 是否支持捕获（`_childRaster == null`），从而选择调用 `paint` 或 `paintSnapshot` 来实现绘制。

另外，目前受制于  `toImageSync `   的底层实现， `SnapshotWidget`  无法捕获 PlatformView 子控件，如果遇到 PlatformView，`SnapshotWidget`   会根据 `SnapshotMode` 来决定它的行为：

| normal     | 默认行为，如果遇到无法捕获快照的子控件，直接 thrown        |
| ---------- | ---------------------------------------------------------- |
| permissive | 宽松行为，遇到无法捕获快照的子控件，使用未快照的子对象渲染 |
| forced     | 强制行为，遇到无法捕获快照的子控件直接忽略                 |

另外 `SnapshotPainter`  可以通过调用 `notifyListeners` 触发 `SnapshotWidget` 使用相同的光栅进行重绘，简单来说就是：

> **你可以在不需要重新生成新快照的情况下，对当然快照进行一些缩放、模糊、旋转等效果，这对性能会有很大提升**。

所以在  `SnapshotPainter`   里主要需要实现的是 `paint` 和 `paintSnapshot` 两个方法：

- paintSnapshot 是绘制 child 快照时会被调用

- paint 方法里主要是通过 `painter` （对应 `super.paint`）这个 Callback 绘制 child ，当快照被禁用或者 `permissive` 模式下遭遇 PlatformView 时会调用此方法

![](http://img.cdn.guoshuyu.cn/20230207_sync/image10.png)

举个例子，如下代码所示，在 `paintSnapshot` 方法里，通过调整 `Paint ..color` ，可以在前面的小 Logo 快照上添加透明度效果：

```dart
class TestPainter extends SnapshotPainter {
  final Animation<double> animation;

  TestPainter({
    required this.animation,
  });

  @override
  void paint(PaintingContext context, ui.Offset offset, Size size,
      PaintingContextCallback painter) {}

  @override
  void paintSnapshot(PaintingContext context, Offset offset, Size size,
      ui.Image image, Size sourceSize, double pixelRatio) {
    final Rect src = Rect.fromLTWH(0, 0, sourceSize.width, sourceSize.height);
    final Rect dst =
    Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
    final Paint paint = Paint()
      ..color = Color.fromRGBO(0, 0, 0, animation.value)
      ..filterQuality = FilterQuality.low;
    context.canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  bool shouldRepaint(covariant TestPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
  }
}
```



![](http://img.cdn.guoshuyu.cn/20230207_sync/image11.gif)

其实还可以把移动的动画部分挪到  `paintSnapshot` 里，然后通过对 animation 的状态进行管理，然后通过  `notifyListeners` 直接更新快照绘制，这样在性能上会更有优势，Android 上的  `ZoomPageTransitionsBuilder`   就是类似实现。

```dart
  animation.addListener(notifyListeners);
  animation.addStatusListener(_onStatusChange);
    
  void _onStatusChange(_) {
    notifyListeners();
  }
  @override
  void paintSnapshot(PaintingContext context, Offset offset, Size size, ui.Image image, Size sourceSize, double pixelRatio) {
    _drawMove(context, offset, size);
  }

  @override
  void paint(PaintingContext context, ui.Offset offset, Size size, PaintingContextCallback painter) {
    switch (animation.status) {
      case AnimationStatus.completed:
      case AnimationStatus.dismissed:
        return painter(context, offset);
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
    }
    ....
  }


```

> 更多详细可以参考系统 `ZoomPageTransitionsBuilder`  里的代码实现。



# 拓展探索

其实除了 `SnapshotWidget`  之外，`RepaintBoundary` 也支持了   `toImageSync `  ， 因为   `toImageSync `     获取到的是 GPU 中的常驻数据，所以在**实现类似控件截图和高亮指引等场景绘制上**，理论上应该可以得到更好的性能预期。

```dart
final RenderRepaintBoundary boundary =
    globalKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
final ui.Image image = boundary.toImageSync();
```

除此之外，`dart:ui `里的 `Scene` 和 `_Image` 对象其实都是 `NativeFieldWrapperClass1` ，以前我们解释过：**`NativeFieldWrapperClass1` 就是它的逻辑是由不同平台的 Engine 区分实现** 。

| ![](http://img.cdn.guoshuyu.cn/20230207_sync/image12.png) | ![](http://img.cdn.guoshuyu.cn/20230207_sync/image13.png) |
| --------------------------------------------------------- | --------------------------------------------------------- |

> 所以如果你直接在 `flutter/bin/cache/pkg/sky_engine/lib/ui/compositing.dart `下去断点 `toImageSync`  是无法成功执行到断点位置的，因为它的真实实现在对应平台的 Engine 实现。

![](http://img.cdn.guoshuyu.cn/20230207_sync/image14.png)

另外，前面我们一直说 `toImageSync`   对比 `toImage`  是 GPU 常驻，那它们的区别在哪里？从上图我们就可以看出：

- `toImageSync`  执行了 `Scene:RasterizeToImage`  并返回 `Dart_Null` 句柄
- `toImage`  执行了 `Picture:RasterizeLayerTreeToImage`  并直接返回

简单展开来说，就是：

-  `toImageSync`   最终是通过 `SkImage::MakeFromTexture`  通过纹理得到一个  GPU  `SkImage` 图片 
-  `toImage`   是通过 `makeImageSnapshot` 和 `makeRasterImage` 生成 `SkImage` ， `makeRasterImage` 是一个复制图像到 CPU 内存的操作。


| ![](http://img.cdn.guoshuyu.cn/20230207_sync/image15.png) | ![](http://img.cdn.guoshuyu.cn/20230207_sync/image16.png) | ![](http://img.cdn.guoshuyu.cn/20230207_sync/image17.png) | ![](http://img.cdn.guoshuyu.cn/20230207_sync/image18.png) |
| --------------------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------------- |

其实一开始 `toImageSync`    是被命令为 `toGpuImage` ，但是为了更形象通用，最后才修改为  `toImageSync`    。

![](http://img.cdn.guoshuyu.cn/20230207_sync/image19.png)

而  `toImageSync`    等相关功能的落地可以说同样历经了漫长的讨论，关于是否提供这样一个 API 到最终落地，其执行难度丝毫不比 [background isolate ](https://juejin.cn/post/7195825738472620087) 简单，比如：是否定义异常场景，遇到错误是否需要在Framwork 层消化，是否真的需要这样的接口来提高性能等等。

| ![](http://img.cdn.guoshuyu.cn/20230207_sync/image20.png) | ![](http://img.cdn.guoshuyu.cn/20230207_sync/image21.png) | ![](http://img.cdn.guoshuyu.cn/20230207_sync/image22.png) | ![](http://img.cdn.guoshuyu.cn/20230207_sync/image23.png) |
| --------------------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------------- |

而   `toImageSync`    等相关功能最终能落地，其中最重要的一点我认为是：

> `toGoulmage` gives the framework the ability to take performance into their own hands, which is important given that our priorities don't always line up.



# 最后

 `toImageSync`    只是一个简单的 API ，但是它的背后经历了很多故事，同时    `toImageSync`   和它对应的封装 `SnapshotWidget`  ，最终的目的就是提高 Flutter 运行的性能。

也许目前对于你来说   `toImageSync`    并不是必须的，甚至  `SnapshotWidget`  看起来也很鸡肋，但是一旦你需要处理复杂的绘制场景时，   `toImageSync`    就是你必不可少的菜刀。