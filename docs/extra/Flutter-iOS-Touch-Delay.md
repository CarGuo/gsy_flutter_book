---
title: "Flutter iOS 的深度优化 PR，搞笑的是贡献者被 Gemini 评审折磨"
---

# Flutter iOS 的深度优化 PR，搞笑的是贡献者被 Gemini 评审折磨

最近  PR #191368 给 Flutter 修了一个多年的老毛病，说起来这个老毛病还是来自一个偶然发现，是另外一个 issue #190815 里的一个讨论， Knopp 在最近就发现， iOS 很喜欢把 Flutter 放到 E-core 上去运行，具体来说就是:

> **main thread 和 raster thread 即便 QoS 设置正确，也长期被 iOS 调度在 E-core 上**，系统似乎认为 Flutter 每一帧工作量很小，不值得占用 P-core，但是偏偏 E-core 又很容易被其他后台活动挤占，只要稍微延迟一点，就可能错过 frame deadline，**而有趣的地方在于，knopp 人为给 UI 和 raster 增加计算负载之后，iOS 反而把它们迁到 P-core，jank 就消失了**。

![](https://img.cdn.guoshuyu.cn/image-20260821112620974.png)

所以问题变了，**有时候你优化的太好，反而被系统故意维保**，而这个问题实际上在 PR #191368 上也类似，因为整体也是因为“很小的调度延迟，导致错过整帧”。

比如旧的 Flutter touch 流程里大概类似：

```
touchesMoved
    ↓
PostTask 到 UI
    ↓
Dart / Framework 处理
    ↓
RequestFrame
    ↓
再 PostTask
    ↓
AwaitVSync
    ↓
CADisplayLink
```

在 CPU 视角下，`PostTask` 可能只增加几十、几百微秒，但帧调度视角就不一样了，比如我们假设：

```
touchesMoved                0.0 ms
本轮 CADisplayLink          0.7 ms
```

Flutter 本来只有 0.7 ms 的窗口可以完成「 *pointer handling - RequestFrame - AwaitVSync*」操作，如果线程稳定跑在 P-core 上，流程上 「*PostTask - 很快醒来 - 0.2 ms*」一般没什么问题，但是如果放在比较拥挤的 E-core，那就可能会：

```
PostTask
    ↓
线程暂时没拿到 CPU
    ↓
0.8 ms 后才运行
    ↓
CADisplayLink 已经过去
```

这里实际上损失的不是 **0.6 ms**，真实场景下Flutter 得等下一次 VSync：

- 60 Hz：**+16.67 ms**
- 120 Hz：**+8.33 ms**

> 也就是让 iOS 的 touch-to-present latency 整整减少了一帧。

当然， #191368 这个问题实际上要从很久远前说起，那时候还是  iPhone X ，这个还是当年针对 iPhone X / XS 时代的触摸事件抖动设计的。

早期 iOS 11～12 上，硬件采样本身相对稳定，但 UIKit 把触摸事件送给应用的时间其实很不均匀，可能这一帧来了两个事件，下一帧一个都没有，再下一帧又来两个，**这时候 Flutter 如果照单全收，视觉上的滚动步长就会忽大忽小**。

> 所以 Flutter 就加了一个 `SmoothPointerDataDispatcher` ，它的核心目标就是：当前一个 pointer packet 还处于处理周期时，新 packet 先缓存到 `pending_packet_`，等下一个 VSync 再发。

也就是这个机制是为了平滑 iPhone X/XS 上不规则的输入投递，而代价是可能增加一个输入周期的延迟，然后这个优化就一直存在到现在，大概快 7 年的时间。

而实际上，目前 Flutter iOS 团队在 issue #191199 里测了从 iPhone 6S、XS 到 iPhone 17 Pro 的一批机器，历史上的 iPhone XS / iOS 12，**触摸投递时间 spread 当时大概有 12.08 ms，相当于 60 Hz 一帧的 72%**，而现在的设备和系统上，这个数字已经收敛到一个很小的范围：

| 测试环境 | Touch delivery spread | `SmoothPointerDataDispatcher` 被迫 stash 的比例 |
|---|---:|---:|
| 120 Hz，correction 开启 | 0.18 ms | 99.2% |
| 120 Hz，correction 关闭 | 0.21 ms | 99.3% |
| 60 Hz，iPhone 17 Pro 低电量模式 | 0.15 ms | 99.5% |
| 60 Hz，iPhone XS / iOS 18.7.10 | 1.47 ms | 99.4% |
| 60 Hz，iPhone 6S / iOS 15.8.8 | 0.83 ms | 0% |
| iPhone XS / iOS 12，2019 年数据 | 12.08 ms | — |

也就是说，**在很多当前设备上 UIKit 的 touch delivery 已经很稳定了，但是 Flutter 这层“平滑器”还在把 99% 左右的 pointer packet 主动压到下一个 VSync**。

> 比如某个 packet 恰好在 VSync 边界之后到达并进入 stash，`is_pointer_data_in_progress_` 很容易一直保持为 true，后续拖动事件就会持续处在“晚一拍”的模式，直到手势结束。

而这个情况在 60 Hz 下一帧是 16.67 ms，120 Hz 下也有 8.33 ms，这对于滚动、拖拽这种视觉直接跟手指绑定的交互上看，这个差距完全可以被感知。

**但是后续测试里，把 Smooth 删掉后，某些 iPhone 直接从 60 fps 掉到 30 fps ，所以问题还不是那么简单**。

knopp 做了最直接的实验：只把 Smooth 换成 Default，其他地方全部不动：

- 在 iPhone 13 Pro 上拖动时，原来 `handleBeginFrame` 大约每 8 ms 一次，换成 Default 后变成约 16 ms
- 在 iPhone XS 上从 16 ms 变成 32 ms。换句话说

也就是 120 Hz 会掉到 60 fps，60 Hz 设备甚至可能掉到 30 fps ，所以这里又有了另外一个神秘发现：

> **`SmoothPointerDataDispatcher` 多年来还顺手掩盖了 iOS VSync waiter 的调度缺陷。**

经不经典，意不意外？一个 Bug 在多年持续里，是另外一个问题的 Feature ，因为在旧流程大致会是这样的情况：

```text
UIKit touchesMoved
        ↓
Platform → UI PostTask
        ↓
pointer processing
        ↓
Framework RequestFrame
        ↓
Animator 再 PostTask
        ↓
AwaitVSync
        ↓
启动 / 唤醒 CADisplayLink
        ↓
等下一次 CADisplayLink
        ↓
BeginFrame
```

这里有两个经典的“稍后再执行”：

- 一个发生在 `Shell::OnPlatformViewDispatchPointerDataPacket`，也就是 Platform TaskRunner 和 UI TaskRunner 已经在同一条线程上，代码依然 `PostTask`
- 另一个发生在 `Animator::RequestFrame`，现有代码会把 `AwaitVSync()` 再 Post 到 UI task runner，理由是希望它发生在当前 UI 调用结束之后，尽量避开昂贵 callout

> 放到普通异步工作里，这两次 PostTask 可能只是极小的 CPU 时间，但是放进 iOS 一帧内部，它们改变的就是**你能不能赶上当前 UIKit update cycle 的 `CADisplayLink` callback**。

只要 `AwaitVSync` 晚过了这一轮 display-link dispatch，损失就不是几十微秒，那可就是下一个 8.33 / 16.67 ms 的 VSync，**所以这次优化真正关心的是相位**。

所以这个 PR 就不是简单去掉 Smooth 了，需要把整个 touch 流程改造一遍，比如把 touch 到请求 VSync 重新压回同一个  run-loop turn，类似：

```text
touchesMoved
     ↓
Framework 处理 pointer，并请求新 frame
     ↓
VSync request
     ↓
CADisplayLink callback
```

**这里前三步要求在 same runloop turn 内同步完成**，所以 #191368 实际上连续拆掉了几个等待点：

- 首先，iOS 从 `SmoothPointerDataDispatcher` 换成 `DefaultPointerDataDispatcher`，pointer packet 不再为了“平滑”主动等下一次 VSync

- 接着，Shell 从普通 `PostTask` 改成了 `RunNowOrPostTask`，也就是如果目标 TaskRunner 就运行在当前线程，立刻执行；确实跨线程时才 PostTask
- 第三个改动就比较激进了，`Animator::RequestFrame()` 里原来的 `GetUITaskRunner()->PostTask(... AwaitVSync() ...)` 直接缩成 `AwaitVSync()`

第三个其实也是关键修改，Framework 因为滚动位置变化调用 `scheduleFrame` 后，Engine 可以当场把“我要下一帧”的意图送进 `VSyncWaiter`，这样就不需要等当前 run-loop task 结束再回来，这样最终时序就有机会成为：

```text
同一次 UIKit UI Update

Event Dispatch
    │
    ├─ touchesMoved
    │    └─ Flutter pointer processing
    │          └─ scheduleFrame
    │                └─ AwaitVSync
    │
    └─ CADisplayLink callback
             └─ BeginFrame
```

**实际上这种结构和 Apple 现在公开的 UIKit update phase 顺序是吻合的**，标准 UI update 依次经历 ：

> `beforeEventDispatch → afterEventDispatch → beforeCADisplayLinkDispatch → afterCADisplayLinkDispatch → beforeCATransactionCommit → afterCATransactionCommit` ，并且这些 phase 连续运行，中间不会退出到下一轮 run loop。

knopp 自己也在 iOS 18 和 iOS 26 上做了时间戳验证，测到 `touchesMoved` 后大概半毫秒左右 `CADisplayLink` 才来，而且多次采样都保持这个先后关系。

> 换句话说，Flutter 只要别自己插入额外的 event-loop turn，就确实有机会在 display link 到来前把新的 frame request 注册好。

而且  VSyncWaiter 的修改还解决了另一个坑：**第一帧不傻等刚刚启动的 CADisplayLink** 。

实际上只做到同步调用 `AwaitVSync` 还不够，因为之前那个“60 fps 变 30 fps”的实验已经证明，iOS 的 `CADisplayLinkn` 在刚刚从 paused 状态唤醒时，并不会给 Flutter 补回当前这一帧，所以 #191368 对 `VsyncWaiterIOS` 又做了一层特殊处理：

> 过去 `FlutterVSyncClient` 默认每收到一个 tick 就把 `CADisplayLink` pause 掉，下一次 Flutter 请求 frame，再调用 `await()` 把它打开，当前 `VSyncClient.swift` 里的 `allowPauseAfterVsync` 默认确实是  true，`await()` 本身也只是将 `isPaused` 设成  false。

而新方案把 `allowPauseAfterVsync`  设成 false，让 DisplayLink 在连续交互时保持运转，同时引入 `waiting_for_vsync_` ，也就是：

```text
DisplayLink 已经运行
    ↓
AwaitVSync 只标记 waiting_for_vsync_ = true
    ↓
马上到来的真实 CADisplayLink tick 消费这个请求
```

然后从 idle 状态来的第一帧走另一条路：

```text
DisplayLink 当前 paused
    ↓
unpause DisplayLink
    ↓
立即 FireCallback()
    ↓
Flutter 马上 BeginFrame
```

这个解决的其实就是之前去掉 Smooth 后，会掉到 30 fps 的问题，因为之前**每帧都把 DisplayLink 关掉，touch 到来以后再打开，然后再等它下一次 tick，等于非常容易错过本轮展示机会。**

不过这个修改过程，Knopp 可以说是被 Flutter 的 AI Review 连续折腾的无语了，把人都给逼的无奈了：

![](https://img.cdn.guoshuyu.cn/image-20260821085058973.png)

Gemini Code Assist 看到新增的 `waiting_for_vsync_` 后，连续报了几个 critical：

> 它认为 `AwaitVSync()` 在 UI thread 修改这个变量，而 `CADisplayLink` callback 从 Platform thread 读取它，所以存在 data race，建议加 `std::mutex`。

然后作者第一次回复得已经很明确：

> “UI thread and platform thread are the same thing.”

然后 Gemini 又沿着多线程假设继续推导  race/deadlock，作者继续回复 “不需要 mutex”，然后 Gemini 继续抽风，然后 Knopp 直接无奈了：

> Flutter 的 `Settings` 里，`merged_platform_ui_thread` 默认已经是 `kEnabled`，含义就是 **Platform TaskRunner 和 UI TaskRunner 共用 Platform thread**，iOS 的配置层甚至都不允许通过 `FLTEnableMergedPlatformUIThread=false` 把它关掉，但是 Gemini 好像还活在上世纪。

而且还不止这些，AI 总会在奇奇怪怪的地方做一些边角料 case 保护，但是你不解释通过，这个 PR 就很难走到下一步，所以 AI Review 有时候也是很烦人的：

![](https://img.cdn.guoshuyu.cn/image-20260821104720275.png)

所以整个 Bug 和问题的历史因素很多，跨度很长，也有系统奇怪的调度策略，你优化的太好，系统反而认为你不需要那么多开销，给你丢 E-core 上去，所以只能说真正的性能优化，有时候确实很奇葩。

















