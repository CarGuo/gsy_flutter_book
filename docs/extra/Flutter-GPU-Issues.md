---
title: "Flutter GPU 最近这一串问题，其实也是 Flutter 另一个投入在看不到的地方"
---

# Flutter GPU 最近这一串问题，其实也是 Flutter 另一个投入在看不到的地方

最近十几天 Flutter GPU 和 Impeller 的几个 Issue 放在一起看还挺有意思：[同一个 CommandBuffer 的两个 Pass 在 Adreno 上触发 Device Lost](https://github.com/flutter/flutter/issues/195250)，紧接着 [Flutter GPU 又因为完成回调执行两次触发 SIGSEGV](https://github.com/flutter/flutter/issues/195247)。

> 其他还有还有纹理池没有收缩、GC 期间释放 Vulkan Texture，以及 `Image.toByteData()` 在 GLES 上直接把 App 弄崩的问题。

刚开始看着好像毫无关系，特别是这些问题发生在不同 API、不同 GPU，不同 Flutter 版本上，但其实目前都是同一类问题：

> **GPU 命令什么时候算录制完成，提交失败由谁负责通知，资源什么时候才真的可以释放。**

## 一个 CommandBuffer 放两个 Pass，为什么 Adreno 会 Device Lost？

首先是 [Issue #195250](https://github.com/flutter/flutter/issues/195250) ，它的问题发生在特定的 Galaxy Z Fold6，Android 16，Adreno Vulkan 驱动 0762.41 上面，算是某些特定机型的，过程其实就是常见的 3D 后处理：

> *第一个 Pass 带着 Depth Test 绘制 Mesh，把颜色写进一张 Texture，然后第二个 Pass 把这张颜色纹理绑定到 Fragment Shader，做一次全屏绘制，最后显示结果，而这两个 Pass 都放在同一个 `CommandBuffer` 里面，这也是常见的一种正常用法。*

```dart
// 根据 Issue 简化，省略纹理创建、Pipeline 和 Buffer 绑定。
final cb = gpu.gpuContext.createCommandBuffer();
final p1 = cb.createRenderPass(targetWithColorAndDepth);
p1.drawIndexed(indexCount);

final p2 = cb.createRenderPass(outputTarget);
p2.bindTexture(fragmentSlot, colorTexture, sampler: sampler);
p2.draw(3);

cb.submit(completionCallback: (ok) => print('GPU completed: $ok'));
```

但在 Galaxy Z Fold6 上它就任性，比如异常场景每帧编码和提交就耗时  275 ms，也就是前几帧的完成回调要等 570–850 ms，这时候第 5 帧就会报 `ErrorDeviceLost`，**之后 Swapchain 等待也持续失败，画面出现无法继续更新的情况**。

另外还有多组对照：

- 换成 RGBA8 或者 RGBA16F、改成 256×256、增加 4× MSAA 都会失败
- 把两个 Pass 拆成两个 CommandBuffer，反而连续运行了 360 帧
- 只清除颜色再采样也正常

> 所以触发条件集中在「真正绘制了带 Depth 的 Mesh，然后在同一 CommandBuffer 里被下一 Pass 采样」。

那 Flutter 是怎么录制命令的？如果对照 [3.47.7 的 `RenderPass::Begin`](https://github.com/flutter/flutter/blob/3.47.7/engine/src/flutter/lib/gpu/render_pass.cc#L77-L84)、[`CommandBuffer::Submit`](https://github.com/flutter/flutter/blob/3.47.7/engine/src/flutter/lib/gpu/command_buffer.cc#L175-L187) 和 [`RenderPassVK`](https://github.com/flutter/flutter/blob/3.47.7/engine/src/flutter/impeller/renderer/backend/vulkan/render_pass_vk.cc)，就可以发现 `RenderPassVK` 构造阶段就调用了 `beginRenderPass()`，但它的 `OnEncodeCommands()` 基本只负责 `endRenderPass()`，而旧版的 `CommandBuffer::Submit()` 要到提交时才遍历所有 Pass 调用它，所以在旧实现里两个 Pass 的录制顺序实际上会变成：

![](/article-assets/26cb2317a6532e28c63778d0.webp)

而这里第三步其实就已经违反 Vulkan 对 `vkCmdBeginRenderPass` 的使用约束：

> **当前还有一个 RenderPass 没结束，就不能开始另一个。**

**不过问题就在于，某些驱动可能容忍这种非法录制，而某些不宽容的，就会在复杂的 Depth 绘制和纹理采样路径上出错**，这也可以解释为什么简单的 Clear 测试能通过，但是真正绘制后还是可能 Device Lost，这其实就看那个设备的驱动包容性有多高。

> 而 Flutter 已经在最近的 [PR #194167：End each pass when the next command is recorded ](https://github.com/flutter/flutter/pull/194167)已经在解决了，这个 PR 已经改成创建下一个 Pass 时，先调用 `EndOpenPass()` 结束上一个 Pass，也就是 Metal 和 Vulkan 都会在这个位置完成编码，不过 OpenGL ES 还是需要按顺序在提交时编码。

然后另一个需要注意的地方是，Flutter 的 Vulkan RenderPass Builder 原本就配置了从 Color Attachment Write 到 Fragment Shader Read 的外向 Subpass Dependency，所以感觉可能还是机型本身就有其他问题居多。

> 虽然这里 Pass 生命周期错误是肯定又问题，但是 Device Lost 为什么就在这个型号上其实不一定真就完全是这个问题。

## GPU 提交失败以后，Flutter 还会再 SIGSEGV

然后还有 [Issue #195247](https://github.com/flutter/flutter/issues/195247)，Flutter GPU 的 `submit()` 可以传 `completionCallback`，可以让 GPU 完成任务以后通知 Dart，而正常来说，这次 Vulkan 提交失败，底层和上层都认为应该通知调用方。

然后底层的 [`CommandQueueVK::Submit`](https://github.com/flutter/flutter/blob/3.47.7/engine/src/flutter/impeller/renderer/backend/vulkan/command_queue_vk.cc) 安排了一个 `fml::ScopedCleanupClosure`：

> 如果提交过程中提前返回，就调用一次 `completion_callback(kError)`。

但是它从 Vulkan Queue 收到 `ErrorDeviceLost` 后就提前退出，然后清理回调自然执行，问题是返回到上一层 [`flutter::gpu::CommandBuffer::Submit`](https://github.com/flutter/flutter/blob/3.47.7/engine/src/flutter/lib/gpu/command_buffer.cc#L181-L187) 后，代码又检查一次 `!status.ok()`，也就是再调用一次同样的完成回调。

![](/article-assets/5b0c2060cbd5617963409f56.webp)

而 Flutter 把 Dart 回调保存在 `std::unique_ptr<tonic::DartPersistentValue>` 里面，第一次通知时通过 `std::move` 把它交给 UI 线程任务，原来的指针就空了。

这样第二次调用还是尝试移动同一个指针，结果第二个任务拿到的是 `nullptr`，执行到 [`callback->dart_state().lock()`](https://github.com/flutter/flutter/blob/3.47.7/engine/src/flutter/lib/gpu/command_buffer.cc#L235-L238) 的时候就直接 SIGSEGV。

> 只能说你永远不知道一份代码里有多少 bug ，直到你发现了它。

## GPU 资源的持有和销毁

另外还有一个 [#193775](https://github.com/flutter/flutter/issues/193775) 的 `GpuImageSurface` 纹理池也很典型，用户在 Windows 上每帧申请 Surface Frame，显示上一帧的 Image，理论上两三张纹理轮转就够了，结果运行到 GC 后停在 62 张 512×512 的纹理，之后池子再也不回收，而在 macOS Metal 的上还能独立复现到 108 张。

**这里的问题其实是 Flutter GPU 的 `Texture`、`RenderPass`、`CommandBuffer` 都可能继续持有 Native Texture 引用**，而 Dart 对部分 GPU 对象没有确定性的 Dispose API，只能等 GC 最终释放包装对象。

因为 `Surface::IsReusable()` 会检查引用数量，引用还没解除时就继续创建纹理，等到引用解除后，`PruneTextureRecords()` 又主要清理尺寸或者格式不匹配的记录，同样尺寸的池子不会主动缩回合理的数量，所以问题变成了：

> 前半段是「回收太晚导致不断分配」，后半段是「已经可以复用以后，池子的高水位仍然不下降」。

类似的问题还出现在 [#193941](https://github.com/flutter/flutter/issues/193941) 的 `Picture.toImageSync()`：

> 在 iPhone 16 Pro Max 上每帧连做 32 次 256×256 的离屏图像生成，发现每次都新建 GPU Texture，没有复用 RenderTargetCache。

在这个特定场景里面，创建 Texture 占了 Raster Thread CPU 耗时约 29%，大约每帧 1 ms，虽然不大，但是占用的开销也是持续的。

## 最后

所以整体看下来，这批 Issue 都能看出来现在 Impeller 和  Flutter GPU 其实一直在处理的各种边角料细节特别多，而这些还恰恰是没办法完全依靠 AI 处理的脏活，这也是 Flutter 目前大量精力投入的地方，也是没被看到的东西。
