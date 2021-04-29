相信 Flutter 的开发者应该遇到过，对于大量数据的列表进行图片加载时，在 iOS 上很容易出现 `OOM `的问题，这是因为 Flutter 特殊的图片加载流程造成。

> 在 Android 上 Flutter `Image` 主要占用的内存不是 `JVM` 的内存，而是 `Graphics` 相关的内存，这样的内存调用可以最大程度利用 Native 内存。

## 一、默认流程

Flutter 默认在进行图片加载时，会先通过对应的 `ImageProvider` 去加载图片数据，然后通过 `PaintingBinding` 对数据进行编码，之后返回包含编码后图片数据和信息的 `ImageInfo` 去实现绘制。

> 详细图片加载流程可见：[《十、 深入图片加载流程)》](https://mp.weixin.qq.com/s/0sEBzLxXrYSswKolxxJePA)


本身这个逻辑并没有什么问题，**问题就在于 Flutter 中对于图片在内存中的 Cache 对象是一个 `ImageStream` 对象**。

Flutter 中 `ImageCache` 缓存的是一个异步对象，缓存异步加载对象的一个问题是：**在图片加载解码完成之前，你无法知道到底将要消耗多少内存，并且大量的图片加载，会导致的解码任务需要产生大量的IO**。

所以一开始最粗暴的情况是：通过 `PaintingBinding.instance` 去设置 `maximumSize` 和 `maximumSizeBytes`，但是这种简单粗爆的处理方法并不能解决长列表图片加载的溢出问题，因为在长列表中，快速滑动的情况下可能会在一瞬间“并发”出大量图片加载需求。


所以在 1.17 版本上，官方针对这种情况提供了场景化的处理方式： `ScrollAwareImageProvider`。


## 二、ScrollAwareImageProvider

1.17 中可以看到，在 `Image` 控件中原本 `_resolveImage` 方法所使用的 `imageProvider` 被 `ScrollAwareImageProvider` 所代理，并且多了一个叫 `DisposableBuildContext<State<Image>>` 的 context 参数。那 `ScrollAwareImageProvider` 的作用是什么呢？ 

```dart
  void _resolveImage() {
    final ScrollAwareImageProvider provider = ScrollAwareImageProvider<dynamic>(
      context: _scrollAwareContext,
      imageProvider: widget.image,
    );
    final ImageStream newStream =
      provider.resolve(createLocalImageConfiguration(
        context,
        size: widget.width != null && widget.height != null ? Size(widget.width, widget.height) : null,
      ));
    assert(newStream != null);
    _updateSourceStream(newStream);
  }
```

其实 `ScrollAwareImageProvider` 对象最主要的使用就是在  `resolveStreamForKey` 方法中，通过 `Scrollable.recommendDeferredLoadingForContext` 方法去判断当前是不是需要推迟当前帧画面的加载，换言之就是：**是否处于快速滑动的过程**。

那 `Scrollable.recommendDeferredLoadingForContext` 作为一个 `static` 方法，如何判断当前是不是处于列表的快速滑动呢？

这就需要通过当前 `context`  的 `getElementForInheritedWidgetOfExactType` 方法去获取 `Scrollable` 内的 `_ScrollableScope` 。 

> `_ScrollableScope` 是  `Scrollable`  内的一个 `InheritedWidget` ，而 Flutter 中的可滑动视图内必然会有 `Scrollable` ，所以只要 `Image` 是在列表内，就可以通过 ` context.getElementForInheritedWidgetOfExactType<_ScrollableScope>()` 去获取到 `_ScrollableScope` 。


获取到 `_ScrollableScope` 就可以获取到它内部的 `ScrollPosition` ， 进而它的 `ScrollPhysics` 对应的 `recommendDeferredLoading` 方法，判断列表是否处于快速滑动状态。所以判断是否快速滑动的逻辑其实是在 `ScrollPhysics`。 

```dart

  bool recommendDeferredLoading(double velocity, ScrollMetrics metrics, BuildContext context) {
    assert(velocity != null);
    assert(metrics != null);
    assert(context != null);
    if (parent == null) {
      final double maxPhysicalPixels = WidgetsBinding.instance.window.physicalSize.longestSide;
      return velocity.abs() > maxPhysicalPixels;
    }
    return parent.recommendDeferredLoading(velocity, metrics, context);
  }
  
```

> 关于 `ScrollPhysics` 的解释可以看 [《十八、 神奇的ScrollPhysics与Simulation》](https://mp.weixin.qq.com/s/Q1uwIb87gKB3gC9ZxSmYng)


然后回到 `resolveStreamForKey` 方法，可以看到当 `Scrollable.recommendDeferredLoadingForContext` 返回 `true` 时就等待，等待就是会通过 ` SchedulerBinding` 在下一帧绘制时再次调用 `resolveStreamForKey`， 递归再走一遍 `resolveStreamForKey` 的逻辑，如果判断此时不再是快速滑动，就走正常的图片加载逻辑。 


```dart
@override
  void resolveStreamForKey(
    ImageConfiguration configuration,
    ImageStream stream,
    T key,
    ImageErrorListener handleError,
  ) {
    if (stream.completer != null || PaintingBinding.instance.imageCache.containsKey(key)) {
      imageProvider.resolveStreamForKey(configuration, stream, key, handleError);
      return;
    }
    if (context.context == null) {
      return;
    }
    if (Scrollable.recommendDeferredLoadingForContext(context.context)) {
        SchedulerBinding.instance.scheduleFrameCallback((_) {
          scheduleMicrotask(() => resolveStreamForKey(configuration, stream, key, handleError));
        });
        return;
    }
    imageProvider.resolveStreamForKey(configuration, stream, key, handleError);
  }
```


如上代码所示，可以看到在 `ScrollAwareImageProvider` 的 `resolveStreamForKey` 方法中，当 `stream.completer != null` 且存在缓存时，直接就去加载原本已有的流程，如果快速滑动过程中图片还没加载的，就先不加载。


> Flutter 中为了防止 `context` 在图片异步加载流程中持有导致内存泄漏，又针对 `Image` 封装了一个 `DisposableBuildContext` 。
>
> `DisposableBuildContext`  是通过持有 `State` 来持有 `context` 的，并且在 `dispose` 时将 `_state = null` 设置为 `null` 来清除对 `State` 的持有。所以可以看到 上述代码中，`context.context == null` 时直接就 `return` 了。


另外前面介绍的 `resolveStreamForKey` 也是新增加的方法，在原本的 `ImageProvider` 进行图片加载时，会通过 `ImageStream resolve` 方法去得到并返回一个  `ImageStream`。

而 `resolveStreamForKey` 将原本 `imageCache` 和 `ImageStreamCompleter` 的流程抽象出来，并且在 `ScrollAwareImageProvider` 中重写了 `resolveStreamForKey` 方法的执行逻辑，这样快速滑动时，图片的下载和解码可以被中断，从而减少了不必要的内存占用。

虽然这种方法不能100%解决图片加载时 OOM 的问题，但是很大程度优化了列表中的图片内存占用，官方提供的数据上看理论上可以在原本基础上节省出 70% 的内存。

![](http://img.cdn.guoshuyu.cn/20200805_Flutter-Image+1_17/image1)

> 相关推荐：[Merged Defer image decoding when scrolling fast #49389](https://github.com/flutter/flutter/pull/49389/files#diff-5de603a8009bb4e46fc0553915af4277R7)



## 资源推荐

* Github ： https://github.com/CarGuo
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**
* 开源 React Native 项目：https://github.com/CarGuo/GSYGithubApp