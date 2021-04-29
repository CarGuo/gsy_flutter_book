作为系列文章的第二十一篇，本篇将通过不一样的角度来介绍 Flutter Framework 的整体渲染原理，深入剖析 Flutter 中构成 Layer 后的绘制流程，让开发者对 Flutter 的渲染原理和实现逻辑有更清晰的认知。


## 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)

## 一、Layer 相关的回顾

先回顾下，我们知道在 Flutter 中的控件会经历 `Widget` -> `Element` -> `RenderObject` -> `Layer` 这样的变化过程，而其中 `Layer` 的组成由 `RenderObject` 中的 `isRepaintBoundary` 标志位决定。

> 当调用 `setState` 时，`RenderObject` 就会往上的父节点去查找，根据 `isRepaintBoundary `是否为 true，会决定是否从这里开始往下去触发重绘，换个说法就是：**确定要更新哪些区域**。
>

比如 `Navigator` 跳转不同路由页面，每个页面内部就有一个 `RepaintBoundary` 控件，这个控件对应的 `RenderRepaintBoundary` 内的 `isRepaintBoundary` 标记位就是为 `true` ，从而路由页面之间形成了独立的 `Layer` 。

**所以相关的 `RenderObject` 在一起组成了 `Layer`，而由 `Layer` 构成的 `Layer Tree` 最后会被提交到 Flutter Engine 绘制出画面**。


那 `Layer` 是怎么工作的？它的本质又是什么？ Flutter Framework 
中 `Layer` 是如何被提交到 Engine 中？

## 二、Flutter Framework 中的绘制

带着前面 `Layer` 的问题，我们先做个假设：如果抛开 Flutter Framework 中封装好的控件，我们应该如何绘制出一个画面？或者说如何创建一个 `Layer` ？

举个例子，如下代码所示，运行后可以看到一个居中显示的 100 x 100 的蓝色方块，并且代码里没有用到任何 `Widget` 、 `RenderObject` 甚至 `Layer`，而是使用了 **`PictureRecorder` 、`Canvas` 、 `SceneBuilder` 这些相对陌生的对象完成了画面绘制，并且在最后执行的是 `window.render`** 。

```
import 'dart:ui' as ui;

void main() {
  ui.window.onBeginFrame = beginFrame;

  ui.window.scheduleFrame();
}

void beginFrame(Duration timeStamp) {
  final double devicePixelRatio = ui.window.devicePixelRatio;

  ///创建一个画板
  final ui.PictureRecorder recorder = ui.PictureRecorder();

  ///基于画板创建一个 Canvas
  final ui.Canvas canvas = ui.Canvas(recorder);
  canvas.scale(devicePixelRatio, devicePixelRatio);

  var centerX = ui.window.physicalSize.width / 2.0;
  var centerY = ui.window.physicalSize.height / 2.0;

  ///画一个 100 的剧中蓝色
  canvas.drawRect(
      Rect.fromCenter(
          center: Offset.zero,
          width: 100,
          height: 100),
      new Paint()..color = Colors.blue);

  ///结束绘制
  final ui.Picture picture = recorder.endRecording();

  final ui.SceneBuilder sceneBuilder = ui.SceneBuilder()
    ..pushOffset(centerX, centerY)
    ..addPicture(ui.Offset.zero, picture)
    ..pop();

  ui.window.render(sceneBuilder.build());
}
```

因为在 Flutter 中 `Canvas` 的创建是必须有 `PictureRecorder` ，而 `PictureRecorder` 顾名思义就是创建一个图片用于记录绘制，所以在上述代码中：
- 先是创建了 `PictureRecorder`；
- 然后使用 `PictureRecorder` 创建了 `Canvas` ；
- 之后使用 `Canvas` 绘制蓝色小方块；
- 结束绘制后通过 `SceneBuilder` 的 `pushOffset` 和 `addPicture` 加载了绘制的内容；
- 通过 `window.render` 绘制出画面。

> 需要注意⚠️： `render` 方法被限制必须在 `onBeginFrame` 或 `onDrawFrame` 中调用，所以上方代码才会有 `window.onBeginFrame = beginFrame;`。在官方的[examples/layers/raw/](https://github.com/flutter/flutter/blob/449f4a6673f6d89609b078eb2b595dee62fd1c79/examples/layers/raw/) 下有不少类似的例子。

![](http://img.cdn.guoshuyu.cn/20200327_Flutter-21/image1)


可以看到 Flutter Framework 在底层绘制的最后一步是 `window.render` ，而如下代码所示： `render` 方法需要的参数是 `Scene` 对象，并且 `render` 方法是一个 `native` 方法，**说明 Flutter Framework 最终提交给 Engine 的是一个 `Scene`**。


```
  void render(Scene scene) native 'Window_render';
```

**那 `Scene ` 又是什么？前面所说的 `Layer` 又在哪里呢？它们之间又有什么样的关系？**


## 三、Scene 和 Layer 之间的苟且

在 Flutter 中 `Scene` 其实是一个 `Native` 对象，它对应的其实是 `Engine` 中的 [`scene.cc`](https://github.com/flutter/engine/blob/78a1c7ebf9adfc988b66381245502536695bfd75/lib/ui/compositing/scene.cc#L44) 结构，而 Engine 中的 `scene.cc` 内包含了一个 `layer_tree_` 用于绘制，所以**首先可以知道`Scene` 在 `Engine` 是和 `layer_tree_` 有关系**。

然后就是在 **Flutter Framework 中 `Scene` 只能通过 `SceneBuilder` 构建**，而 `SceneBuilder` 中存在很多方法比如： `pushOffset`、`pushClipRect`、`pushOpacity` 等，这些方法的执行后，可以通过 Engine 会创建出一个对应的 `EngineLayer`。

```
  OffsetEngineLayer pushOffset(double dx, double dy, { OffsetEngineLayer oldLayer }) {
    assert(_debugCheckCanBeUsedAsOldLayer(oldLayer, 'pushOffset'));
    final OffsetEngineLayer layer = OffsetEngineLayer._(_pushOffset(dx, dy));
    assert(_debugPushLayer(layer));
    return layer;
  }
  EngineLayer _pushOffset(double dx, double dy) native 'SceneBuilder_pushOffset';
```

**所以 `SceneBuilder` 在 `build` 出 `Scene` 之前，可以通过 `push` 等相关方法产生 `EngineLayer`**， 比如前面的蓝色小方块例子，`SceneBuilder` 就是通过 `pushOffset` 创建出对应的图层偏移。

接着看 Flutter Framework 中的 `Layer` ，如下代码所示，在 `Layer` 默认就存在 `EngineLayer` 参数，所以可以得知 `Layer` 肯定和 `SceneBuilder` 有一定关系。

```
  @protected
  ui.EngineLayer get engineLayer => _engineLayer;

  @protected
  set engineLayer(ui.EngineLayer value) {
    _engineLayer = value;
    if (!alwaysNeedsAddToScene) {
    
      if (parent != null && !parent.alwaysNeedsAddToScene) {
        parent.markNeedsAddToScene();
      }
    }
  }
  ui.EngineLayer _engineLayer;
  
  /// Override this method to upload this layer to the engine.
  ///
  /// Return the engine layer for retained rendering. When there no
  /// corresponding engine layer, null is returned.
  
  @protected
  void addToScene(ui.SceneBuilder builder, [ Offset layerOffset = Offset.zero ]);

```

其次在 `Layer` 中有一个关键方法： **`addToScene`**，先通过注释可以得知这个方法是由子类实现，并且执行后可以得到一个 `EngineLayer` ，并且这个方法需要一个 `SceneBuilder` ，而查询该方法的实现恰好就有`OffsetLayer` 和 `PictureLayer` 等。

![](http://img.cdn.guoshuyu.cn/20200327_Flutter-21/image2)

所以如下代码所示，在 `OffsetLayer` 和 `PictureLayer` 的 `addToScene` 方法实现中可以看到：

- `PictureLayer` 调用了 `SceneBuilder` 的 `addPicture`;
- `OffsetLayer` 调用了 `SceneBuilder` 的 `pushOffset` ；

```
class PictureLayer extends Layer {
  ···
  @override
  void addToScene(ui.SceneBuilder builder, [ Offset layerOffset = Offset.zero ]) {
    builder.addPicture(layerOffset, picture, isComplexHint: isComplexHint, willChangeHint: willChangeHint);
  }
  ···
}

class OffsetLayer extends ContainerLayer {
  ···
  OffsetLayer({ Offset offset = Offset.zero }) : _offset = offset;

  @override
  void addToScene(ui.SceneBuilder builder, [ Offset layerOffset = Offset.zero ]) {
    engineLayer = builder.pushOffset(
      layerOffset.dx + offset.dx,
      layerOffset.dy + offset.dy,
      oldLayer: _engineLayer as ui.OffsetEngineLayer,
    );
    addChildrenToScene(builder);
    builder.pop();
  }
  ···
}
```

所以到这里 **`SceneBuilder` 和 `Layer` 通过 `EngineLayer` 和 `addToScene` 方法成功关联起来，而 `window.render` 提交的 `Scene` 又是通过  `SceneBuilder` 构建得到，所以如下图所示， `Layer` 和 `Scene` 就这样“苟且”到了一起**。


![](http://img.cdn.guoshuyu.cn/20200327_Flutter-21/image3)


对面前面的蓝色小方块代码，如下代码所示，这里修改为使用 `Layer` 的方式实现，可以看到这样的实现更接近 Flutter Framework 的实现：**通过 `rootLayer` 一级一级 `append` 构建出`Layer` 树，而 `rootLayer` 调用 `addToScene` 方法后，因为会执行 `addChildrenToScene` 方法，从而往下执行 child `Layer` 的 `addToScene`**。

```
import 'dart:ui' as ui;

void main() {
  ui.window.onBeginFrame = beginFrame;

  ui.window.scheduleFrame();
}

void beginFrame(Duration timeStamp) {
  final double devicePixelRatio = ui.window.devicePixelRatio;
  
  ///创建一个画板
  final ui.PictureRecorder recorder = ui.PictureRecorder();

  ///基于画板创建一个 Canvas
  final ui.Canvas canvas = ui.Canvas(recorder);
  canvas.scale(devicePixelRatio, devicePixelRatio);

  var centerX = ui.window.physicalSize.width / 2.0;
  var centerY = ui.window.physicalSize.height / 2.0;

  ///画一个 100 的剧中蓝色
  canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 100, height: 100),
      new Paint()..color = Colors.blue);

  final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();

  OffsetLayer rootLayer = new OffsetLayer();


  OffsetLayer offsetLayer = new OffsetLayer(offset: Offset(centerX, centerY));
  rootLayer.append(offsetLayer);

  PictureLayer pictureLayer = new PictureLayer(Rect.zero);
  pictureLayer.picture = recorder.endRecording();
  offsetLayer.append(pictureLayer);


  rootLayer.addToScene(sceneBuilder);


  ui.window.render(sceneBuilder.build());
}

```
## 四、Layer 的品种

这里额外介绍下 Flutter 中常见的 `Layer`，如下图所示，一般 Flutter 中 `Layer` 可以分为 `ContainerLayer` 和非 `ContainerLayer` 。

![](http://img.cdn.guoshuyu.cn/20200327_Flutter-21/image4)

`ContainerLayer` 是可以具备子节点，也就是带有 `append` 方法，大致可以分为：

- 位移类（`OffsetLayer`/`TransformLayer`）;
- 透明类（`OpacityLayer`）
- 裁剪类（`ClipRectLayer`/`ClipRRectLayer`/`ClipPathLayer`);
- 阴影类 (`PhysicalModelLayer`)

为什么这些 `Layer` 需要是 `ContainerLayer` ？**因为这些 `Layer` 都是一些像素合成的操作，其本身是不具备“描绘”控件的能力，就如前面的蓝色小方块例子一样，如果要呈现画面一般需要和 `PictureLayer` 结合**。

> 比如 `ClipRRect` 控件的 `RenderClipRRect` 内部，在 `pushClipRRect` 时可以会创建 `ClipRRectLayer` ，而新创建的 `ClipRRectLayer ` 会通过 `appendLayer` 方法触发 `append` 操作添加为父 `Layer` 的子节点。

而非 `ContainerLayer` 一般不具备子节点，比如:

- `PictureLayer` 是用于绘制画面，Flutter 上的控件基本是绘制在这上面；
- `TextureLayer` 是用于外界纹理，比如视频播放或者摄像头数据；
- `PlatformViewLayer` 是用于 iOS 上 `PlatformView` 相关嵌入纹理的使用；

举个例子，控件绘制时的 `Canvas` 来源于 `PaintingContext` ， 而如下代码所示 `PaintingContext` 通过 `_repaintCompositedChild` 执行绘制后得到的 `Picture` 最后就是提交给所在的 `PictureLayer.picture`。

```
void stopRecordingIfNeeded() {
    if (!_isRecording)
      return;
    _currentLayer.picture = _recorder.endRecording();
    _currentLayer = null;
    _recorder = null;
    _canvas = null;
  }
```


## 五、Layer 的内外兼修


了解完 `Layer` 是如何提交绘制后，接下来介绍的就是 `Layer` 的刷新和复用。

我们知道当 `RenderObject` 的 `isRepaintBoundary` 为 `ture` 时，Flutter Framework 就会自动创建一个 `OffsetLayer` 来“承载”这片区域，而 `Layer` 内部的画面更新一般不会影响到其他 `Layer` 。

**那 `Layer` 是如何更新？这就涉及了 `Layer` 内部的 `markNeedsAddToScene` 和 `updateSubtreeNeedsAddToScene` 这两个方法。**

如下代码所示，`markNeedsAddToScene` 方法其实就是把 `Layer` 内的 `_needsAddToScene` 标记为 `true` ; 而 `updateSubtreeNeedsAddToScene ` 方法就是遍历所有 child `Layer`，通过递归调用  `updateSubtreeNeedsAddToScene()` 判断是否有 `child` 需要 `_needsAddToScene` ，如果是那就把自己也标记为 `true`。

```
  @protected
  @visibleForTesting
  void markNeedsAddToScene() {
    // Already marked. Short-circuit.
    if (_needsAddToScene) {
      return;
    }

    _needsAddToScene = true;
  }
  
  @override
  void updateSubtreeNeedsAddToScene() {
    super.updateSubtreeNeedsAddToScene();
    Layer child = firstChild;
    while (child != null) {
      child.updateSubtreeNeedsAddToScene();
      _needsAddToScene = _needsAddToScene || child._needsAddToScene;
      child = child.nextSibling;
    }
  }

```

是不是和 `setState` 调用 `markNeedsBuild` 把自己标志为 `_dirty` 很像？**当 `_needsAddToScene` 等于 `true` 时，对应 `Layer` 的 `addToScene` 才会被调用；而当 `Layer` 的 `_needsAddToScene` 为 `false` 且 `_engineLayer` 不为空时就触发 `Layer` 的复用**。

```
void _addToSceneWithRetainedRendering(ui.SceneBuilder builder) {
 
    if (!_needsAddToScene && _engineLayer != null) {
      builder.addRetained(_engineLayer);
      return;
    }
    addToScene(builder);

    _needsAddToScene = false;
  }
```

是的，当一个 `Layer` 的 `_needsAddToScene` 为 `false` 时 表明了自己不需要更新，那这个 `Layer` 的 `EngineLayer` 又存在，那 就可以被复用。举个例子：当一个新的页面打开时，底部的页面并没有发生变化时，它只是参与画面的合成，所以对于底部页面来说它 “`Layer`” 是可以直接被复用参与绘制。


**那 `markNeedsAddToScene` 在什么时候会被调用？**

如下图所示，当 `Layer` 子的参数，比如： `PictureLayer` 的 `picture`、`OffsetLayer` 的 `offset` 发生变化时，`Layer` 就会主动调用 `markNeedsAddToScene` 标记自己为“脏”区域。另外当 `Layer` 的 `engineLayer` 发生变化时，就会尝试触发父节点的 `Layer` 调用 `markNeedsAddToScene` ，这样父节点也会对应产生变化。


![](http://img.cdn.guoshuyu.cn/20200327_Flutter-21/image5)

```
@protected
  set engineLayer(ui.EngineLayer value) {
    _engineLayer = value;
    if (!alwaysNeedsAddToScene) {
      if (parent != null && !parent.alwaysNeedsAddToScene) {
        parent.markNeedsAddToScene();
      }
    }
  }
```

而 `updateSubtreeNeedsAddToScene` 是在 `buildScene` 的时候触发，在 `addToScene` 之前调用 `updateSubtreeNeedsAddToScene` 再次判断 child 节点，从而确定是否需要发生改变。

```
ui.Scene buildScene(ui.SceneBuilder builder) {
    List<PictureLayer> temporaryLayers;
    assert(() {
      if (debugCheckElevationsEnabled) {
        temporaryLayers = _debugCheckElevations();
      }
      return true;
    }());
    updateSubtreeNeedsAddToScene();
    addToScene(builder);
   
    _needsAddToScene = false;
    final ui.Scene scene = builder.build();

    return scene;
  }
```

## 六、Flutter Framework 的 Layer 构成

最后回归到 Flutter Framework ，在 Flutter Framework 中 `_window.render` 是在 `RenderView` 的 `compositeFrame` 方法中被调用；而 `RenderView ` 是在`RendererBinding` 的 `initRenderView` 被初始化；`initRenderView` 是在 `initInstances` 时被调用，也就是 `runApp` 的时候。

简单来说就是：**`runApp` 的时候创建了 `RenderView` ，并且 `RenderView` 内部的 `compositeFrame` 就是通过 `_window.render`来提交 `Layer` 的绘制。**

```
  void compositeFrame() {
    Timeline.startSync('Compositing', arguments: timelineWhitelistArguments);
    try {
      final ui.SceneBuilder builder = ui.SceneBuilder();
      final ui.Scene scene = layer.buildScene(builder);
      if (automaticSystemUiAdjustment)
        _updateSystemChrome();
      _window.render(scene);
      scene.dispose();
      assert(() {
        if (debugRepaintRainbowEnabled || debugRepaintTextRainbowEnabled)
          debugCurrentRepaintColor = debugCurrentRepaintColor.withHue((debugCurrentRepaintColor.hue + 2.0) % 360.0);
        return true;
      }());
    } finally {
      Timeline.finishSync();
    }
  }
```

所以 `runApp` 的时候 Flutter 创建了 `RenderView`，并且在 `Window` 的 `drawFrame` 方法中调用了 `renderView.compositeFrame();` 提交了绘制，而 **`RenderView` 作为根节点，它携带的 `rootLayer` 为 `OffsetLayer` 的子类 `TransformLayer`，属于是 Flutter 中 `Layer` 的根节点**。

![](http://img.cdn.guoshuyu.cn/20200327_Flutter-21/image6)

这里举个例子，如下图所示是一个简单的不规范代码，运行后出现的结果是一个黑色空白页面，这里我们通过 `debugDumpLayerTree` 方法打印出 `Layer` 的机构。

```
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    new Future.delayed(Duration(seconds: 1), () {
      debugDumpLayerTree();
    });
    return MaterialApp(
      title: 'GSY Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Container(),
      //routes: routers,
    );
  }
}
```

打印出的结果如下 LOG 所示，正如前面所说 `TransformLayer` 作为 `rooterLayer` 它的 `owner` 是 `RenderView`，然后它有两个 child 节点： child1 `OffsetLayer` 和  child2  `PictureLayer` 。

> 默认情况下因为 `Layer` 的形成机制（`isRepaintBoundary` 为 `ture` 自动创建一个 `OffsetLayer`）和 `Canvas` 绘制需要，至少会有一个 `OffsetLayer` 和  `PictureLayer`。

```
I/flutter (32494): TransformLayer#f8fa5
I/flutter (32494):  │ owner: RenderView#2d51e
I/flutter (32494):  │ creator: [root]
I/flutter (32494):  │ offset: Offset(0.0, 0.0)
I/flutter (32494):  │ transform:
I/flutter (32494):  │   [0] 2.8,0.0,0.0,0.0
I/flutter (32494):  │   [1] 0.0,2.8,0.0,0.0
I/flutter (32494):  │   [2] 0.0,0.0,1.0,0.0
I/flutter (32494):  │   [3] 0.0,0.0,0.0,1.0
I/flutter (32494):  │
I/flutter (32494):  ├─child 1: OffsetLayer#4503b
I/flutter (32494):  │ │ creator: RepaintBoundary ← _FocusMarker ← Semantics ← FocusScope
I/flutter (32494):  │ │   ← PageStorage ← Offstage ← _ModalScopeStatus ←
I/flutter (32494):  │ │   _ModalScope<dynamic>-[LabeledGlobalKey<_ModalScopeState<dynamic>>#e1be1]
I/flutter (32494):  │ │   ← _OverlayEntry-[LabeledGlobalKey<_OverlayEntryState>#95107] ←
I/flutter (32494):  │ │   Stack ← _Theatre ←
I/flutter (32494):  │ │   Overlay-[LabeledGlobalKey<OverlayState>#ceb36] ← ⋯
I/flutter (32494):  │ │ offset: Offset(0.0, 0.0)
I/flutter (32494):  │ │
I/flutter (32494):  │ └─child 1: OffsetLayer#e8309
I/flutter (32494):  │     creator: RepaintBoundary-[GlobalKey#bbad8] ← IgnorePointer ←
I/flutter (32494):  │       FadeTransition ← FractionalTranslation ← SlideTransition ←
I/flutter (32494):  │       _FadeUpwardsPageTransition ← AnimatedBuilder ← RepaintBoundary
I/flutter (32494):  │       ← _FocusMarker ← Semantics ← FocusScope ← PageStorage ← ⋯
I/flutter (32494):  │     offset: Offset(0.0, 0.0)
I/flutter (32494):  │
I/flutter (32494):  └─child 2: PictureLayer#be4f1
I/flutter (32494):      paint bounds: Rect.fromLTRB(0.0, 0.0, 1080.0, 2030.0)
```

根据上述 LOG 所示，首先看：

- `OffsetLayer` 的 `creator` 是 `RepaintBoundary`，而其来源是 `Overlay`，我们知道 Flutter 中可以通过 `Overlay` 做全局悬浮控件，而 `Overlay` 就是在 `MaterialApp` 的 `Navigator` 中创建，并且它是一个独立的`Layer` ； 
- 而 `OffsetLayer` 的 child 是 `PageStorage` ，`PageStorage` 是通过 `Route` 产生的，也即是默认的路由第一个页面。


**所以现在知道为什么 `Overlay` 可以在  `MaterialApp` 的所有路由页面下全局悬浮显示了吧。**


如下代码所示，再原本代码的基础上增加 `Scaffold` 后继续执行 `debugDumpLayerTree`。

```

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    new Future.delayed(Duration(seconds: 1), () {
      debugDumpLayerTree();
    });
    return MaterialApp(
      title: 'GSY Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Container(),
      ),
      //routes: routers,
    );
  }
}
```

可以看到这里多了一个 `PhysicalModelLayer` 和 `PictureLayer` ，`PhysicalModelLayer` 是用于设置阴影等效果的，比如关闭 `debugDisablePhysicalShapeLayers` 后 `AppBar` 的阴影会消失，而之后的 `PictureLayer` 也是用于绘制。

```
I/flutter (32494): TransformLayer#ac14b
I/flutter (32494):  │ owner: RenderView#f5ecc
I/flutter (32494):  │ creator: [root]
I/flutter (32494):  │ offset: Offset(0.0, 0.0)
I/flutter (32494):  │ transform:
I/flutter (32494):  │   [0] 2.8,0.0,0.0,0.0
I/flutter (32494):  │   [1] 0.0,2.8,0.0,0.0
I/flutter (32494):  │   [2] 0.0,0.0,1.0,0.0
I/flutter (32494):  │   [3] 0.0,0.0,0.0,1.0
I/flutter (32494):  │
I/flutter (32494):  ├─child 1: OffsetLayer#c0128
I/flutter (32494):  │ │ creator: RepaintBoundary ← _FocusMarker ← Semantics ← FocusScope
I/flutter (32494):  │ │   ← PageStorage ← Offstage ← _ModalScopeStatus ←
I/flutter (32494):  │ │   _ModalScope<dynamic>-[LabeledGlobalKey<_ModalScopeState<dynamic>>#fe143]
I/flutter (32494):  │ │   ← _OverlayEntry-[LabeledGlobalKey<_OverlayEntryState>#9cb60] ←
I/flutter (32494):  │ │   Stack ← _Theatre ←
I/flutter (32494):  │ │   Overlay-[LabeledGlobalKey<OverlayState>#ee455] ← ⋯
I/flutter (32494):  │ │ offset: Offset(0.0, 0.0)
I/flutter (32494):  │ │
I/flutter (32494):  │ └─child 1: OffsetLayer#fb2a6
I/flutter (32494):  │   │ creator: RepaintBoundary-[GlobalKey#fd46b] ← IgnorePointer ←
I/flutter (32494):  │   │   FadeTransition ← FractionalTranslation ← SlideTransition ←
I/flutter (32494):  │   │   _FadeUpwardsPageTransition ← AnimatedBuilder ← RepaintBoundary
I/flutter (32494):  │   │   ← _FocusMarker ← Semantics ← FocusScope ← PageStorage ← ⋯
I/flutter (32494):  │   │ offset: Offset(0.0, 0.0)
I/flutter (32494):  │   │
I/flutter (32494):  │   └─child 1: PhysicalModelLayer#f1460
I/flutter (32494):  │     │ creator: PhysicalModel ← AnimatedPhysicalModel ← Material ←
I/flutter (32494):  │     │   PrimaryScrollController ← _ScaffoldScope ← Scaffold ← Semantics
I/flutter (32494):  │     │   ← Builder ← RepaintBoundary-[GlobalKey#fd46b] ← IgnorePointer ←
I/flutter (32494):  │     │   FadeTransition ← FractionalTranslation ← ⋯
I/flutter (32494):  │     │ elevation: 0.0
I/flutter (32494):  │     │ color: Color(0xfffafafa)
I/flutter (32494):  │     │
I/flutter (32494):  │     └─child 1: PictureLayer#f800f
I/flutter (32494):  │         paint bounds: Rect.fromLTRB(0.0, 0.0, 392.7, 738.2)
I/flutter (32494):  │
I/flutter (32494):  └─child 2: PictureLayer#af14d
I/flutter (32494):      paint bounds: Rect.fromLTRB(0.0, 0.0, 1080.0, 2030.0)
I/flutter (32494): 

```

最后通过再使用 `Navigator` 跳到另外一个页面，再新页面打印 `Layer` 树，可以看到又可以多了个 `PictureLayer` 、`AnnotatedRegionLayer` 和 `TransformLayer` ： 其中多了的 `AnnotatedRegionLayer` 是用于处理新页面顶部状态栏的显示效果。

```
I/flutter (32494): TransformLayer#12e21
I/flutter (32494):  │ owner: RenderView#aa5c7
I/flutter (32494):  │ creator: [root]
I/flutter (32494):  │ offset: Offset(0.0, 0.0)
I/flutter (32494):  │ transform:
I/flutter (32494):  │   [0] 2.8,0.0,0.0,0.0
I/flutter (32494):  │   [1] 0.0,2.8,0.0,0.0
I/flutter (32494):  │   [2] 0.0,0.0,1.0,0.0
I/flutter (32494):  │   [3] 0.0,0.0,0.0,1.0
I/flutter (32494):  │
I/flutter (32494):  ├─child 1: OffsetLayer#fc176
I/flutter (32494):  │ │ creator: RepaintBoundary ← _FocusMarker ← Semantics ← FocusScope
I/flutter (32494):  │ │   ← PageStorage ← Offstage ← _ModalScopeStatus ←
I/flutter (32494):  │ │   _ModalScope<dynamic>-[LabeledGlobalKey<_ModalScopeState<dynamic>>#43140]
I/flutter (32494):  │ │   ← _OverlayEntry-[LabeledGlobalKey<_OverlayEntryState>#46f19] ←
I/flutter (32494):  │ │   Stack ← _Theatre ←
I/flutter (32494):  │ │   Overlay-[LabeledGlobalKey<OverlayState>#af6f4] ← ⋯
I/flutter (32494):  │ │ offset: Offset(0.0, 0.0)
I/flutter (32494):  │ │
I/flutter (32494):  │ └─child 1: OffsetLayer#b6e14
I/flutter (32494):  │   │ creator: RepaintBoundary-[GlobalKey#0ce90] ← IgnorePointer ←
I/flutter (32494):  │   │   FadeTransition ← FractionalTranslation ← SlideTransition ←
I/flutter (32494):  │   │   _FadeUpwardsPageTransition ← AnimatedBuilder ← RepaintBoundary
I/flutter (32494):  │   │   ← _FocusMarker ← Semantics ← FocusScope ← PageStorage ← ⋯
I/flutter (32494):  │   │ offset: Offset(0.0, 0.0)
I/flutter (32494):  │   │
I/flutter (32494):  │   └─child 1: PhysicalModelLayer#4fdc6
I/flutter (32494):  │     │ creator: PhysicalModel ← AnimatedPhysicalModel ← Material ←
I/flutter (32494):  │     │   PrimaryScrollController ← _ScaffoldScope ← Scaffold ←
I/flutter (32494):  │     │   ClipDemoPage ← Semantics ← Builder ←
I/flutter (32494):  │     │   RepaintBoundary-[GlobalKey#0ce90] ← IgnorePointer ←
I/flutter (32494):  │     │   FadeTransition ← ⋯
I/flutter (32494):  │     │ elevation: 0.0
I/flutter (32494):  │     │ color: Color(0xfffafafa)
I/flutter (32494):  │     │
I/flutter (32494):  │     ├─child 1: PictureLayer#6ee26
I/flutter (32494):  │     │   paint bounds: Rect.fromLTRB(0.0, 0.0, 392.7, 738.2)
I/flutter (32494):  │     │
I/flutter (32494):  │     ├─child 2: AnnotatedRegionLayer<SystemUiOverlayStyle>#cbeaf
I/flutter (32494):  │     │ │ value: {systemNavigationBarColor: 4278190080,
I/flutter (32494):  │     │ │   systemNavigationBarDividerColor: null, statusBarColor: null,
I/flutter (32494):  │     │ │   statusBarBrightness: Brightness.dark, statusBarIconBrightness:
I/flutter (32494):  │     │ │   Brightness.light, systemNavigationBarIconBrightness:
I/flutter (32494):  │     │ │   Brightness.light}
I/flutter (32494):  │     │ │ size: Size(392.7, 83.6)
I/flutter (32494):  │     │ │ offset: Offset(0.0, 0.0)
I/flutter (32494):  │     │ │
I/flutter (32494):  │     │ └─child 1: PhysicalModelLayer#edb15
I/flutter (32494):  │     │   │ creator: PhysicalModel ← AnimatedPhysicalModel ← Material ←
I/flutter (32494):  │     │   │   AnnotatedRegion<SystemUiOverlayStyle> ← Semantics ← AppBar ←
I/flutter (32494):  │     │   │   FlexibleSpaceBarSettings ← ConstrainedBox ← MediaQuery ←
I/flutter (32494):  │     │   │   LayoutId-[<_ScaffoldSlot.appBar>] ← CustomMultiChildLayout ←
I/flutter (32494):  │     │   │   AnimatedBuilder ← ⋯
I/flutter (32494):  │     │   │ elevation: 4.0
I/flutter (32494):  │     │   │ color: MaterialColor(primary value: Color(0xff2196f3))
I/flutter (32494):  │     │   │
I/flutter (32494):  │     │   └─child 1: PictureLayer#418ce
I/flutter (32494):  │     │       paint bounds: Rect.fromLTRB(0.0, 0.0, 392.7, 83.6)
I/flutter (32494):  │     │
I/flutter (32494):  │     └─child 3: TransformLayer#7f867
I/flutter (32494):  │       │ offset: Offset(0.0, 0.0)
I/flutter (32494):  │       │ transform:
I/flutter (32494):  │       │   [0] 1.0,0.0,0.0,-0.0
I/flutter (32494):  │       │   [1] -0.0,1.0,0.0,0.0
I/flutter (32494):  │       │   [2] 0.0,0.0,1.0,0.0
I/flutter (32494):  │       │   [3] 0.0,0.0,0.0,1.0
I/flutter (32494):  │       │
I/flutter (32494):  │       └─child 1: PhysicalModelLayer#9f36b
I/flutter (32494):  │         │ creator: PhysicalShape ← _MaterialInterior ← Material ←
I/flutter (32494):  │         │   ConstrainedBox ← _FocusMarker ← Focus ← _InputPadding ←
I/flutter (32494):  │         │   Semantics ← RawMaterialButton ← KeyedSubtree-[GlobalKey#9ead9]
I/flutter (32494):  │         │   ← TickerMode ← Offstage ← ⋯
I/flutter (32494):  │         │ elevation: 6.0
I/flutter (32494):  │         │ color: Color(0xff2196f3)
I/flutter (32494):  │         │
I/flutter (32494):  │         └─child 1: PictureLayer#2a074
I/flutter (32494):  │             paint bounds: Rect.fromLTRB(320.7, 666.2, 376.7, 722.2)
I/flutter (32494):  │
I/flutter (32494):  └─child 2: PictureLayer#3d42d
I/flutter (32494):      paint bounds: Rect.fromLTRB(0.0, 0.0, 1080.0, 2030.0)
I/flutter (32494): 

```

所以可以看到，Flutter 中的 `Widget` 在最终形成各式各样的 `Layer` ，每个 `Layer` 都有自己单独的区域和功能，比如 `AnnotatedRegionLayer`在新的页面处理状态栏颜色的变化，而这些 `Layer` 最终通过 `SceneBuilder` 转化为 `EngineLayer` ，最后提交为 `Scene` 经由 Engine 绘制。


最后总结一下：**Flutter Framework 的 `Layer` 在绘制之前，需要经历 `SceneBuinlder` 的处理得到 `EngineLayer`，其实  Flutter Framework 中的  `Layer` 可以理解为 `SceneBuinlder` 的对象封装，而 `EngineLayer` 才是真正的 Engine 图层 ，在之后得到的 `Scene` 会被提交 Engine 绘制**。



> 自此，第二十一篇终于结束了！(///▽///)

## 资源推荐

* Github ： https://github.com/CarGuo
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**
* 开源 React Native 项目：https://github.com/CarGuo/GSYGithubApp



![](http://img.cdn.guoshuyu.cn/20200327_Flutter-21/image7)