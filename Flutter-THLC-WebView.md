# Flutter THLC 的 WebView 滚动终于从 70 FPS 提升到 120 FPS

天见犹怜， [flutter/flutter#195861](https://github.com/flutter/flutter/pull/195861) 终于合并了，终于把 TLHC 模式嵌入 的 WebView 滚动从 70 FPS 提到 120 FPS，**之前一直用 HC 的原因就是 TLHC WebView 滚动不有舒服**，关于几种模式我们应该聊过很多次了：

| 合成模式       | 原生 View 怎么显示                                | 主要特点                                        |
| -------------- | ------------------------------------------------- | ----------------------------------------------- |
| TLHC           | Android View 先绘制成纹理，再交给 Flutter 合成    | Flutter 侧性能较好，但 WebView 快速滚动可能卡顿 |
| HC             | 原生 View 留在 Android View 层级，由 Android 合成 | 原生兼容性较好，但存在 Flutter 线程合并开销     |
| HCPP（实验性） | Flutter 和原生内容分别使用 Surface，由系统合成    | 减少传统 HC 同步开销，有设备和系统要求          |

之前  WebView 快速滚动不够流畅一直是 Texture Layer 模式的已知性能问题，因为每次 WebView 更新内容的时候，都需要把 Android View 的绘制结果送进 Flutter 使用的纹理，之前的主要过程是：

- `PlatformViewWrapper.draw()` 被 Android 主线程调用
- 通过 `lockHardwareCanvas()` 获取离屏 Surface 的画布
- 调用 `super.draw()`，把 WebView 及其子 View 的内容画进去
- 立即调用 `unlockCanvasAndPost()`，提交这次离屏绘制
- 通知 Flutter 有新的纹理帧可以使用

问题其实一直久出在第 4 步，`unlockCanvasAndPost()` 看起来虽然只是提交 Canvas，但是背后一直会触发 Android RenderThread 的绘制工作。

**而 Android 并不会为每个 `HardwareRenderer` 单独准备一条 RenderThread，它们共享进程内的 RenderThread**，所以 WebView 的离屏绘制和应用主窗口的绘制，实际上会争用同一条 RenderThread。

> 也就是 WebView 正在快速滚动，里面有比较重的 GPU 绘制任务的时候，这种资源争用就很明显了。

问题是这个解决很简单，搞得我之前都只能本地 Engine 解决，就很傻逼。

这个问题主要就是在于 WebView 抢在主窗口前面占用了 RenderThread ，一般来说 Android 的 View 绘制大体分成两个阶段：

- Record View#draw：Android 主线程遍历 View，记录绘制命令
- DrawFrame：RenderThread 消费这些命令，执行 GPU 相关渲染工作

正常情况下，主线程记录好当前窗口的绘制内容，随后就可以把工作交给 RenderThread，但是 TLHC 比较特殊，它需要额外绘制一个离屏 Surface，以前的 `PlatformViewWrapper.draw()` 在主窗口的 View 遍历还没结束的时候，就提前提交了这个 Surface。

结果出现了下面的时序：

![](/article-assets/4321fed3401fd31fce92324e.webp)

而这里的问题关键其实在于：

- 主窗口还没完成帧同步，WebView 就提前向共享 RenderThread 提交了一份比较重的绘制任务

- 而当主窗口随后进行同步时，RenderThread 已经在忙了

- 但是主窗口的同步路径需要等待 RenderThread 响应，于是 Android 主线程也跟着被阻塞

之前 Pixel 9 Trace 数据大概会是：

| 指标             | 修改前  | 修改后   |
| ---------------- | ------- | -------- |
| 主窗口帧同步耗时 | ~5.1 ms | ~1.4 ms  |
| 多出来的等待     | ~3.5 ms | 基本消除 |
| WebView 滚动 FPS | ~70     | 120      |

**主窗口同步耗时可以减少了 3.7ms，要知道 120Hz 的设备每帧只有 8.33ms 的时间预算，光减少的这 3.7ms，就已经相当于一帧预算的 44%**！！！！！

而修改的也很简单，就是就是调整执行顺序，之前的问题大概在：

```java
@Override
public void draw(Canvas canvas) {
    Surface surface = renderTarget.getSurface();

    Canvas targetCanvas = surface.lockHardwareCanvas();

    try {
        super.draw(targetCanvas);
    } finally {
        renderTarget.scheduleFrame();
        surface.unlockCanvasAndPost(targetCanvas);
    }
}
```

这里的问题就在 `finally`，因为 `super.draw()` 还处于 Android 主窗口的绘制遍历过程里面，代码就立即调用 `unlockCanvasAndPost()`。

所以新实现保留了同步录制，但是把提交动作暂存起来：

```java
@Override
public void draw(Canvas canvas) {
    // ... 获取 Surface 和锁定 Canvas

    try {
        super.draw(targetCanvas);
    } finally {
        pendingFrameSurface = targetSurface;
        pendingFrameCanvas = targetCanvas;

        mainHandler.postAtFrontOfQueue(
            postPendingFrameRunnable
        );
    }
}
```

这样就可以等这轮主线程的遍历执行完再调用：

```java
private void postPendingFrame(boolean scheduleFrame) {
    // ... 取出待提交的 Surface 和 Canvas

    surface.unlockCanvasAndPost(canvas);

    if (scheduleFrame && renderTarget != null) {
        renderTarget.scheduleFrame();
    }
}
```

通过  `postAtFrontOfQueue()`，这个 API 会把 Runnable 放到主线程消息队列前面，让它在当前消息执行完之后，尽快获得执行机会。

所以这次调整相当于：

- WebView 的绘制命令仍然在 `draw()` 中生成
- 先让主窗口完成自己的帧同步
- 紧接着提交 WebView 的离屏帧
- 最后通知 Flutter 更新纹理

而且它没有把 `unlockCanvasAndPost()` 搬到后台线程，调用还是发生在 Android 主线程，只不过从当前绘制遍历内部，挪到了消息队列下一次执行时，这样就能避免 WebView 提前占用 RenderThread，影响主窗口最关键的同步过程。

不过我感觉可能还有坑，比如你把原来立即执行的 `unlockCanvasAndPost()` 延后了，是不是就会产生一个新的状态：

> **Canvas 已经锁定，也已经完成绘制命令录制，但是 Surface 还没有解锁提交。**

这时如果 WebView 突然销毁、改变尺寸或者进入后台，是不是就不能简单等待那个 Runnable ？

目前看 PR 确实额外处理了几个场景，但是就怕后面越堆越屎山：

| 场景                           | 新增处理               | 避免的问题                      |
| ------------------------------ | ---------------------- | ------------------------------- |
| 同一轮遍历中再次调用 `draw()`  | 先提交上一帧           | 同一 Surface 重复锁定           |
| PlatformView 改变大小          | 先提交，再 `resize()`  | 旧 Canvas 对应的 Surface 被调整 |
| 窗口进入后台或不可见           | 立即提交待处理帧       | Surface 长时间处于锁定状态      |
| PlatformView 销毁              | 先解锁，再释放         | 资源释放时仍有未完成的 Canvas   |
| `unlockCanvasAndPost()` 抛异常 | 捕获异常，不再通知新帧 | 失败的提交被当成有效帧          |

另外还有一个优化，可以避免创建无意义的 1×1 Buffer，比如以前创建 TLHC PlatformView 的顺序是：

- 创建 `PlatformViewRenderTarget`
- 创建 `PlatformViewWrapper`
- Wrapper 构造期间立即锁定并清空 Surface
- RenderTarget 此时还是默认的 `1×1`
- 再把 RenderTarget 调整到实际大小

也就是比如你创建一个 1080×1920 的 WebView，以前大概会是：

```
创建 RenderTarget
     ↓
先以 1×1 大小获取 Surface
     ↓
分配对应的图像资源
     ↓
调整成 1080×1920
     ↓
原来的 1×1 资源被丢弃
```

现在新的顺序大概会是：

```
final PlatformViewRenderTarget renderTarget =
    makePlatformViewRenderTarget(textureRegistry);

// 先调整尺寸
renderTarget.resize(physicalWidth, physicalHeight);

// 再创建 Wrapper
viewWrapper = new PlatformViewWrapper(
    context,
    renderTarget
);
```

这样就可以避免初始尺寸下多余的 `ImageReader` 资源创建和替换，不过这个优化主要影响 PlatformView 初始化阶段，收益可能不会那么明显。

**不过 TLHC 的顽疾终于解决了，也是很感动了**。
