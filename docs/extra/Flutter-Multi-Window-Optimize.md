---
title: "Flutter 多窗口重要优化合并，多窗口性能和实用性大幅提升"
---

# Flutter 多窗口重要优化合并，多窗口性能和实用性大幅提升

最近 [#179874](https://github.com/flutter/flutter/pull/179874) 这个 PR 终于重新通过 [#192128](https://github.com/flutter/flutter/pull/192128) 合并到 master 了，**也就是从这个 PR 开始，Flutter 的 Multi-View 渲染，终于可以从“只要来一帧，所有 View 都重新 composite”，变成了 “哪一个 View 真脏了，只 composite 哪一个”**。

![](/article-assets/588bf53913c67e51947c8926.gif)

> 这个实现之前最麻烦的地方在于：**Texture、Platform View、前后台切换这些变化，实际上不支持天然把 Flutter RenderObject 标成 dirty**，所以这个 PR 大量代码其实都是在补齐这套 dirty 信号链。

这个 PR 其实也挺坎坷，原本的 Multi-View  处理比较粗暴，对应之前的 [#164320](https://github.com/flutter/flutter/issues/164320)， `RendererBinding.drawFrame()` 在完成 layout / paint 后，实际上的逻辑基本等价于：

```dart
for (final RenderView renderView in renderViews) {
  renderView.compositeFrame();
}
```

也就是这里根本不管某个 `RenderView` 有没有变化，比如现在桌面 Multi-Window 有：

- View A 播放动画，60 FPS
- View B 完全静止
- View C 完全静止

> 但是之前只要 A 请求了一帧，A/B/C 三个 RenderView 都会执行 `compositeFrame()`。

但是这个问题浪费的可不只是一个 Dart 函数调用场景，`RenderView.compositeFrame()`  会重新完成 Layer Tree 到 `ui.Scene` 的构建，然后通过 `FlutterView.render(scene)` 把 Scene 提交给 Engine。

> 也就是说，你虽然没有重新 paint B，但还是会把 B 的已有 Layer Tree 再走一遍 scene composition / render submission，而这类问题以前单 View 根本不存在，但是 Multi-View 出来之后，场景就不一样了。

所以这次 PR 的核心改动其实本身页不复杂，比如在 `RenderView` 里加了：

```dart
bool get needsCompositeFrame => _needsCompositeFrame;

void markNeedsCompositeFrame() {
  _needsCompositeFrame = true;
}
```

然后 `RendererBinding.drawFrame()` 变成：

```dart
for (final RenderView renderView in renderViews) {
  if (renderView.needsCompositeFrame) {
    renderView.compositeFrame();
  }
}
```

也就是说现在实际上形成了两层 dirty：

> **RenderObject dirty - View dirty - 只提交 dirty View。**

**所以现在 Flutter 除了 RenderObject ，还需要知道哪个 View “ 脏了”** ，PR 给  `PipelineOwner`  加了一个 `onFlushedPaint`：

```dart
typedef FlushedPaintCallback = void Function(bool isDirty);
```

然后当 `PipelineOwner.flushPaint()` 完成之后 `onFlushedPaint?.call(dirtyNodes.isNotEmpty);` ，每一个 View 对应的 PipelineOwner 如果这一帧确实 paint 过 RenderObject，就调用：

```dart
renderView.markNeedsCompositeFrame();
```

所以链路就变成了：

![](/article-assets/94200eb6011f7a49091572bd.webp)

这个设计很好理解，**就是 paint 是 View 是不是需要重新产生 Scene 的最直接证据**，所以如果三个窗口里只有窗口 A 有动画：

> A 的 PipelineOwner 有 dirty paint node，所以 A composite，而 B/C 没有 dirty node，就连 `compositeFrame()` 都用不进。

这对于 Flutter 正在推进的桌面 Multi-Window 挺重要的，因为窗口越多，这个优化越有价值，因为原来的成本更接近“总 View 数”，现在开始接近“本帧 Dirty View 数”。

> **这个在后续的 GoogleBook ，鸿蒙 PC 之类的多窗口场景都挺有意义的**，它可以省掉没变化 View 的 scene composition 和 engine render submission，还有后续可能产生的 raster/compositor 工作。

当然，这个问题到这里本来还挺简单的，**但是遇到 `Texture` 场景就变复杂了，因为在  `Texture`  这种视频场景，会有画面变了，但 Flutter RenderObject 根本没变的情况**。

比如  View A 里放了 `Texture(textureId: 123)` ，视频解码器产生了新的一帧，从 Flutter Framework 角度看的话：

- `TextureBox` 大小没变
- Widget 没变
- RenderObject 属性没变
- 没人调用 `markNeedsPaint()`

以前其实也没什么问题，因为 Flutter 每一帧反正都会对所有 RenderView 全部 composite ，所以 Texture 的新内容自然就顺便被提交了。

但是现在如果开始跳过“干净 View”，就出现类似：

> Texture 123 明明已经产生新视频帧，但 View A 看起来完全不 dirty，所以 Flutter把整个 View A 跳过了。

然后就会看到，视频就画面就冻结了，所以这个 PR 新增了一条新的通知链路， **Engine 到 Framework 反向 dirty 通知链路**：

![](/article-assets/e4e62fd7e0dfdb479cec95c7.webp)

在 Framework 新增 `PlatformDispatcher.onTextureFrameAvailable`  场景下，Engine 不只是自己知道“Texture 新帧到了”，现在还能告诉 Dart 类似：

> **Texture ID 123 有新内容了。**

然后 `TextureBox` attach 时会注册监听：

```dart
void _handleTextureFrameAvailable(int textureId) {
  if (!_freeze && textureId == _textureId) {
    markNeedsPaint();
  }
}
```

**所以 Texture 的变化等于被重新纳入 Flutter 原本的 dirty rendering 系统**，**等于实际上给它补了一个原来被全量重绘行为隐藏掉的依赖关系**：

> External Texture 的 content mutation 以前对 Framework 是不可见的，现在变成了一个明确的 invalidation signal。

**另外针对  Android 这里还顺便修个同样的路径问题**， Android `FlutterRenderer` 以前 Texture 新帧来的时候，大量地方调用的是 `scheduleEngineFrame();` ，但是严格来说这也只表达了：

> “Engine，你赶紧搞一帧。”

然后这次 PR 把它换成了  `flutterJNI.markTextureFrameAvailable(id);` ，等于是：

- `scheduleEngineFrame()` **不携带哪个 Texture 发生变化 的信息**，所以进入 Framework 后你还是不知道应该 dirty 哪个 View

- `markTextureFrameAvailable(id)` 带有具体 Texture ID，所以：

  - 标记 native Texture 有新内容

  - 通知 Framework：texture 123 变了

  - Framework 找到对应 `TextureBox`

  - `markNeedsPaint()`

  - 最终只 composite 包含它的 View

然后 Engine 那边就可以继续用 `ScheduleFrame(/*regenerate_layer_trees=*/false);`，同时还保留了 External Texture 很重要的一个优化：

> **Texture 新帧不需要重新生成完整 Engine layer tree，可以复用现有 Layer Tree。**

**也就是说这次不只是为了 dirty-view 优化把 Texture 路径变重，还把 Android 原来比较粗的 `scheduleEngineFrame()` 路径统一到了真正的 Texture frame notification 路径**。

**最后就是  PlatformView ，这个问题也是挺蛋疼的**，而且第一次 PR 的时候还漏了这个场景，原始 #179874 在 8 月第一次合入的时候，只给 `TextureBox` 接了 `onTextureFrameAvailable`，后来在重新提交的 [#192128](https://github.com/flutter/flutter/pull/192128) Review 里，reviewer 才发现了一个问题：

> 有些 RenderObject 并不是通过 `TextureBox` 使用 Texture，例如 `RenderAndroidView` 自己直接 paint `TextureLayer`。

也就是下面这种场景顾及到了：

```
Texture Widget
    → TextureBox
    → TextureLayer
```

但是实际上还有这条路需要处理：

```
Android PlatformView
    → RenderAndroidView
    → TextureLayer
```

所以重新合入的版本又专门给 `RenderAndroidView` 加了同一套 Texture frame listener：

```dart
void _handleTextureFrameAvailable(int textureId) {
  if (_viewController.requiresViewComposition) {
    return;
  }

  if (textureId == _viewController.textureId) {
    markNeedsPaint();
  }
}
```

可以看出来，Flutter 一开始设计的时候没考虑多窗口，现在适配起来其实很多地方都容易暗藏背刺，比如：

- External Texture 是一个
- Texture-based Android Platform View 也是一个
- Lifecycle、Engine 主动请求 repaint 又是一类

**所以这次它还增加了一个 `onMarkAllViewsNeedRender` 兜底**，有些事件你没办法精确判断哪个 View 变了，这时候 Flutter 可以选择显式退回全部 View dirty。

比如 App 从后台恢复，Engine 处理 `AppLifecycleState.resumed` 和  `AppLifecycleState.inactive` 时会执行：

```dart
MarkAllViewsNeedRender();
ScheduleFrame();
```

然后通过新增的：

然后通过新增的 `PlatformDispatcher.onMarkAllViewsNeedRender` ，在 Framework 执行：

```dart
for (final RenderView view in renderViews) {
  view.markNeedsCompositeFrame();
}
```

> 所以这里的 `OnPlatformViewScheduleFrame()` 这种 Engine 会主动要求 repaint 的路径也一样会先全部 mark dirty。

**还有 Warm-up frame 也特殊处理了**，因为 warm-up frame 不保证内容真的已经显示到 Surface，所以就算刚刚 composite 过，Flutter 也还是会再次 `renderView.markNeedsCompositeFrame();` ，保证下一个真正的 VSync frame 再提交一次。

简单来说就是：

> **能精确追踪 View dirty 的地方就局部 dirty；没办法安全判断的系统级事件就明确 full invalidation。**

所以这个 PR 其实也是十分坎坷，它第一次合入 4 小时左右就被 revert 了，因为 Web benchmark 全部开始 timeout，所以很快通过 [#191252](https://github.com/flutter/flutter/pull/191252) revert。

刚开始还以为 dirty-view 优化把 Web 搞挂了，但后面查出来发现是 Flutter 的 Web benchmark recorder `_autoUpdateBenchmarkPhase` 会等待一定数量的 Timeline Event ：

- `preroll_frame`
- `apply_frame`

而这些事件只有真正执行 `ui.Scene.render` ，也就是 View 真正 composite 时才会产生，偏偏部分 benchmark 会主动 schedule 一个 frame，但这一帧根本没有任何 RenderObject dirty。

> 以前这样照样可以 composite，所以 benchmark 能收到 `preroll_frame / apply_frame`，但是这个 PR 后没东西发生变话，也就是正确跳过 composite，导致了没 Timeline Event ，然后 benchmark recorder 以为这一帧还没完成 ，所以一直等刀 timeout。

然后重新合入的 #192128 直接在 benchmark binding 里，让 benchmark 自己继续保持“每 Frame 必有 composition event”的旧假设：

```dart
for (final RenderView renderView in renderViews) {
  renderView.markNeedsCompositeFrame();
}
```

等于这个 PR 属于是一个从头贯穿到尾的性能优化调整，把 Flutter 从以前的单 View 形态迁移到多 View 形态，给多窗口场景打了一个不错的地基，**Flutter Multi-View 渲染 pipeline 从“Frame 粒度”进一步细化到了“View 粒度”**，然后重新建立了这几种 invalidation：

- **普通 RenderObject Paint** ： `PipelineOwner.onFlushedPaint`
- **External Texture** ： `onTextureFrameAvailable(textureId)`
- **Texture-backed Platform View** ： 同样按 textureId 找到 RenderAndroidView
- **Lifecycle / Engine 强制刷新** ： `onMarkAllViewsNeedRender`
- **Warm-up / 新增 View** ：显式 `markNeedsCompositeFrame`

> 在折叠屏 和 Android PC  到来的情况下，Flutter 也终于开始把基础设定调整到多窗口了，也算是难得了。

另外最近一些项目的多窗口实现做的也挺不错的，比如 libnativeapi 的 Demo ，可以看到挺多有意思的能力，感兴趣的也可以看：https://github.com/libnativeapi/nativeapi/tree/main/examples  ：

![](/article-assets/a5586dd39bdab3e204eade64.gif)

![](/article-assets/2cdd612e59e95c00faf6ea4a.gif)
