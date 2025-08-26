# Flutter 里的  Layer 解析，带你了解不一样角度下的 Flutter  渲染逻辑

众所周知，Flutter 最被人熟知的就是 `Widget` - `Element` - `RenderObject` 这三棵树，而实际上如下图所示，在 `paint` 阶段，`RenderObject` 并不直接执行真正的绘制操作，而是会创建和配置相应的 `Layer` 对象，例如 `PictureLayer` ：

![](https://img.cdn.guoshuyu.cn/%E6%9C%AA%E5%91%BD%E5%90%8D%E6%96%87%E4%BB%B6.jpg)

而我们知道，在 Dart 层面，当 `RenderObject` 的 `isRepaintBoundary` 为 `ture` 时，Flutter Framework 就会自动创建一个 `OffsetLayer` 来“承载”这片区域，所以 `Layer` 内部的画面更新一般不会影响到其他 `Layer` ，这是 Flutter 在 Dart 层面最基础的 Layer 概念。

> 例如 `Navigator` 跳转不同路由页面，每个页面内部就有一个 `RepaintBoundary` 控件，这个控件对应的 `RenderRepaintBoundary` 内的 `isRepaintBoundary` 标记位就是为 `true` ，从而路由页面之间形成了独立的 `Layer` 。

那 `Layer` 是如何更新？**这就涉及了  Dart `Layer` 内部的 `markNeedsAddToScene` 和 `updateSubtreeNeedsAddToScene` 这两个方法**，简单来说：

- `markNeedsAddToScene` 方法类似 `setState` ，它其实就是把 `Layer` 内的 `_needsAddToScene` 标记为 `true` 
- `updateSubtreeNeedsAddToScene` 方法就是遍历所有 child `Layer`，通过递归调用  `updateSubtreeNeedsAddToScene()` 判断是否有 `child` 需要 `_needsAddToScene` ，如果是那就把自己也标记为 `true`。

而对应到实际的执行上就是：**只有当 `_needsAddToScene` 等于 `true` 时，对应 `Layer` 的 `addToScene` 才会被调用；而当 `Layer` 的 `_needsAddToScene` 为 `false` 且 `_engineLayer` 不为空时就触发 `Layer` 的复用**。

> 例如，当一个新的页面打开时，底部的页面并没有发生变化时，它只是参与画面的合成，所以对于底部页面来说它 “`Layer`” 是可以直接被复用参与绘制 。

当然，Dart 层的 Layer 实际上对应在 C++ 有具体的 EngineLayer 实现，而 **Flutter 提交给 Engine 进行光栅化操作的对象，实际上就是承载绘制指令的  C++ `LayerTree`**，而 Layer 从 Dart 「透传」到 C++ 之后，就会通过 flow 模块来实现光栅化并合成输出，这才是真实绘制的开始。

> Flutter 里 Layer 有 Dart 层面的 Layer 和 C++ 层面的 Layer ，简单说，一般 C++ 层面的会称为 `EngineLayer` ，比如 `ClipPathLayer`  和  `ClipPathEngineLayer` 。

而这里说的「透传」，在上古老版本的是 `ui.window`，在现在的版本指的是  `ui.FlutterView`，在 Dart 层面一般是通过如 `ui.window.render(sceneBuilder.build())`或者  `FlutterView.run`(sceneBuilder.build())  来提交到 C++ 构建，但是这里我们可以看到， `render` 方法需要的参数是 `Scene` 对象而不是 `Layer` ，这又是为什么？

> 因为简单来说，**`Scene` 对象就是 Flutter 在 Dart 操作 C++  Layer 的入口**，而在 Flutter Framework 中 `Scene` 只能通过 `SceneBuilder` 构建。

所以如下图所示，一般来说 Dart 层的 Layer 不会直接操作 `Scene` ，而是通过统一基类的 `addToScene` 方法来操作 `SceneBuilder` ， 例如 Dart 层的 `ClipPathLayer` 会在它实现的 ` addToScene(ui.SceneBuilder builder)` 调用 `builder.pushClipPath` 来得到一个 `ClipPathEngineLayer`，而所有 Dart Layer 最终会通过 `sceneBuilder.build()` 统一提交到 C++ ：

![](https://img.cdn.guoshuyu.cn/mermaid-diagram-2025-07-23-150335.png)

所以 `ui.SceneBuilder` (Dart) 属于构建渲染场景的关键 API，它提供了一系列 push 方法和 add 方法，如 `addPicture`、`addTexture` 和 `addPlatformView`，这些方法在底层分别对应着 Engine 中 `PictureLayer`、`TextureLayer` 和 `PlatformViewLayer` 的创建，**`SceneBuilder` 的职责就是收集这些 Layer，并将它们组装成一个完整的 `LayerTree`，最终交由 Engine 处理**。

而在 Flutter 里，一般 Flutter 中 `Layer` 可以分为 `ContainerLayer` 和非 `ContainerLayer` ，`ContainerLayer` 是可以具备子节点，也就是带有 `append` 方法，例如：

- 位移类（`OffsetLayer`/`TransformLayer`）;
- 透明类（`OpacityLayer`）
- 裁剪类（`ClipRectLayer`/`ClipRRectLayer`/`ClipPathLayer`);

![](https://img.cdn.guoshuyu.cn/image-20250723135433338.png)

对于 `ContainerLayer` ，**因为这些 `Layer` 都是一些像素合成的操作，其本身是不具备“描绘”控件的能力，如果要呈现画面一般需要和 `PictureLayer` 结合**。

> 比如 `ClipRRect` 控件的 `RenderClipRRect` 内部，在 `pushClipRRect` 时可以会创建 `ClipRRectLayer` ，而新创建的 `ClipRRectLayer` 会通过 `appendLayer` 方法触发 `append` 操作添加为父 `Layer` 的子节点。

非 `ContainerLayer` 一般不具备子节点，比如:

- `PictureLayer` 是用于绘制画面，Flutter 上的控件基本是绘制在这上面；
- `TextureLayer` 一般用于外界纹理或者  PlatformView 实现
- `PlatformViewLayer` 一般用于 PlatformView  相关嵌入的使用场景；

举个例子，控件绘制时的 `Canvas` 来源于 `PaintingContext` ， 而如下代码所示 `PaintingContext` 通过 `_repaintCompositedChild` 执行绘制后得到的 `Picture` 最后就是提交给所在的 `PictureLayer.picture`：

```dart
void stopRecordingIfNeeded() {
    if (!_isRecording)
      return;
    _currentLayer.picture = _recorder.endRecording();
    _currentLayer = null;
    _recorder = null;
    _canvas = null;
  }
```

而对于  `TextureLayer`  和 `PlatformViewLayer` ，实际上它们也是有着不一样的故事，特别是在 PlatformView 实现上。

在 C++ 层面，`PlatformViewLayer` 和 `TextureLayer` 是 Flutter Engine 在 `flow` 渲染层中的两个核心类，特别是在 PlatformView 上：

- `PlatformViewLayer` 通过将最终的视图合成工作委托给宿主系统（Android），提供了原生的交互和 UI 保真度，但对应性能开销也会较高 ，比如 Android 平台的 HC 实现
- `TextureLayer` 提供了更轻量级的纹理合成支持，用于在 Flutter 自己的渲染管线内展示原生像素流，但在交互性和原生视图类型兼容性上存在一些限制，比如 Android 平台的 VD 和 TLHC 实现

要了解 `PlatformViewLayer` 和 `TextureLayer` 在  PlatformView 的实现，就需要简单聊聊 Layer 的 `Preroll` 与 `Paint` 阶段：

- **`Preroll` 阶段**：这是对 `LayerTree` 的第一次遍历，Engine 会调用每个 Layer 的 `Preroll` 方法，用于计算绘制边界（paint bounds）、确定渲染属性（如不透明度、裁剪区域）以及检查所需资源是否就绪

- **`Paint` 阶段**：这是第二次遍历，Engine 调用每个 Layer 的 `Paint` 方法来生成绘制指令，对于大多数 Layer 而言，这意味着将绘制命令添加到一个 `DisplayList`（Flutter 内部的绘制操作记录）

## TextureLayer

`TextureLayer` 的核心目标是在 Flutter 画布上提供一个矩形区域，用于渲染由原生代码管理的外部纹理，它的机制非常适合那些会产生连续图像流的场景，例如视频播放器、相机预览，或使用 OpenGL/Vulkan 等原生图形库渲染的自定义图形。

`TextureLayer` 的 `Preroll` 方法实现非常直接，它主要调用 `set_paint_bounds` 来声明其在场景中所占据的矩形区域，此外它还会通知 `DiffContext` 该子树中存在 `TextureLayer`，防止在某些情况下父级 `ContainerLayer` 错误地跳过对 `TextureLayer` 的差异比对（diffing）优化。

`Paint` 方法是 `TextureLayer` 功能的核心，简单流程为：

- **获取纹理对象**：通过 `PrerollContext` 中的 `texture_registry`，使用成员变量 `texture_id_` 查找到对应的 `flutter::Texture` 对象
- **执行绘制**：如果纹理对象有效，就调用对象的 `Paint` 方法 `texture->Paint(context.canvas,...)`，这个调用会直接将外部纹理绘制到当前 Flutter 的 `DlCanvas` 上

> 这里的`texture_id_` 对应的是一个实现了 `flutter::ExternalTexture` C++ 接口的原生对象，在不同平台上，`ExternalTexture` 的实现有所不同，例如在 Android 上通常由 `SurfaceTexture` 支持；在 iOS 上，则由一个实现了 `FlutterTexture` 协议的对象来支持，这个对象提供一个 `CVPixelBuffer` 。

而 `TextureLayer` 支持绘制的核心是可以直接在 GPU 上生成纹理，然后通过 `ExternalTexture` 接口将对应的 GPU 纹理的句柄（handle）传递给 Flutter Engine ，从而避免了将像素数据从 GPU 拷贝到主内存，再从主内存拷贝回 GPU 的昂贵过程。

## PlatformViewLayer

如果说 `TextureLayer` 是把最终绘制过程统一到 Flutter ，那 `PlatformViewLayer` 就是将最终绘制过程从 Flutter 放到系统渲染。

在 `Preroll` ，`PlatformViewLayer`  会执行一个关键检查：`if (context->view_embedder == nullptr)`，这意味着它的正常工作其实依赖于一个有效的 `ViewEmbedder` 上下文。

> 如果检查失败，就会直接输出类似 "*Trying to embed a platform view but the PrerollContext does not support embedding*" 的错误。

通过检查后，它会设置一个贯穿渲染流程的标志位：`context->has_platform_view = true;`，这个标志位会向整个渲染管线宣告：即将发生一次“合成中断”。

所以 `PlatformViewLayer` 的 `Paint` 方法与 `TextureLayer` 的截然不同，对于 Flutter 的 `DlCanvas` 而言，这个方法几乎是一个空操作，它不会向 `context.canvas` 发出任何绘制指令，它的唯一作用是在 `LayerTree` 中充当一个标记。

> 在 Dart 层，`PlatformViewLayer.addToScene` 方法会调用 `builder.addPlatformView(...)`，也就是指示 Engine 在场景中插入这个特殊标记的指令。

**所以  `PlatformViewLayer`  里`ViewEmbedder` 很关键，它起到了编排合成中断的作用**。

而 `ViewEmbedder` 是一个平台相关的组件，负责管理原生视图层级，当 Rasterizer 在 `Preroll` 阶段检测到 `has_platform_view` 标志位被设置时，就会导致整个渲染行为会发生根本性改变，它不再将所有 Flutter 内容渲染到单一的 Surface，而是执行以下步骤：

1. **渲染底层内容**：将 `PlatformViewLayer` 之前的所有 Flutter 内容渲染到一个离屏纹理中
2. **通知 Embedder**：通知 `ViewEmbedder` 显示由 `view_id_` 标识的原生视图
3. **渲染顶层内容**：将 `PlatformViewLayer` 之后的所有 Flutter 内容渲染到第二个离屏纹理中
4. **委托系统合成**：最后，它依赖宿主操作系统的合成器（Android 上的 `SurfaceFlinger`）来正确地堆叠这些图层，最终形成屏幕上看到的画面

![](https://img.cdn.guoshuyu.cn/image-20250723154845066.png)

因此，`PlatformViewLayer` 本质上不是一个给 Skia 或 Impeller 的绘制指令，而是给 Engine Shell 和操作系统合成器的一个高级命令，而这个切换过程涉及昂贵的内存操作和线程同步，这也是其性能开销的根源。

# 最后

那么，到这里关于 Flutter 里 Layer 的整体概念就介绍完了，虽然说的是 Layer ，但是也涉及了不少其他东西，例如 PlatformView，整体来说这并不是一篇实用的文章，但是它确实能帮你更好理解 Flutter 里的渲染机制，特别是对于 PlatformView 的底层实现原理，换句话说，也许哪天你遇到 Flutter 画面闪烁了，这些概念也许就用上了呢？