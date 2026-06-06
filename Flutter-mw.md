# Flutter 多窗口最近进度，为什么 3.44  还不落地

本来以为 3.44 至少会发布 win 的多窗口，结果只宣布了个 **Canonical 成为 Flutter Desktop 的主要维护者和战略合作伙伴** ，实际上很久前 Flutter 就把桌面端交给对方维护，这两年也基本是这么在推进，只是速度确实太慢：

![](https://img.cdn.guoshuyu.cn/image-20260526140329644.png)

这次更新里主要提到了 `showRawDialog` / `showDialog`  走原生 dialog window ，如果你 `flutter config --enable-windowing`  开启了  windowing，那么 dialog 会通过 windowing system 显示在自己的窗口，而不是当前窗口内的 modal overlay，平台不支持时，会 fallback 到普通 dialog route。

> 这个问题倒是把我坑了，因为我一直用的 beta 版本，**这次用了多窗口之后，很多 loading 和弹窗直接去到了新窗口上，然后又没适配，直接 UX 都乱了**。

另外目前在接口层面，大部分 win 接口已经可用了：

- `RegularWindowController` / `RegularWindow`
- `DialogWindowController` / `DialogWindow`
- `TooltipWindowController` / `TooltipWindow`
- `PopupWindowController` / `PopupWindow`
- `SatelliteWindowController` / `SatelliteWindow`

![](https://img.cdn.guoshuyu.cn/ezgif-76433ae53becf2cf.gif)

不过多窗口在 Flutter 里确实挺多边界问题，因为框架一开始就没设计多窗口概念，所以很多东西都是在重构，现在的多窗口的实现是**一个 Flutter engine 实例能够渲染多个独立的操作系统窗口**，而这些窗口共享同一个 Dart isolate 和 widget tree，然后通过 view ID 区分不同的渲染目标，所以多窗口之间的竞态细节会比较多。

> 不过问题更多还是在于平台适配，从零开始做一套脱离平台渲染的多窗口，还真的难度不小。

# Win

根据我体验下来，win 11 上基本都还行，用起来问题不大，就是多窗口焦点切换还有点交互支持不够友好，但是在 win 10 上目前问题应该比较多 ：

![](https://img.cdn.guoshuyu.cn/ezgif-6295426c2ace2047.gif)

比如在一些 Win10 上，*开关窗口、激活、最大化* 这些基础功能在多窗口都还有问题，主要是 **WM_SIZE 与 等待机制在 Win10 上的行为不一致**。

目前 Flutter Win embedder 处理窗口大小变化（包括最大化、多窗口创建/关闭时的尺寸变化）的核心逻辑是：

- 窗口收到 `WM_SIZE` 消息（resize、maximize 等触发）
- embedder 的平台线程在 `flutter_windows_view.cc` 中执行一个  `condition_variable` + `mutex` ，超时是 100ms，持续等待直到 Flutter engine 产出一帧与新目标尺寸匹配的帧
- 等待释放后，新帧才真正呈现到屏幕

这个等待机制是 Flutter Win 主要是为了防止出现画面撕裂和黑屏闪烁的，而问题就在于这个， Win10 在某些窗口操作（尤其是最大化，以及多窗口场景下的创建/激活/关闭）时，`WM_SIZE` 消息时序导致等待提前超时或条件变量通知时序错乱，跟 Win11 又居然不一样，这就导致等待的触发路径跟不上了。

另外 Win 10 和 Win11 在窗口合成也有差异：

**DWM（Desktop Window Manager）行为差异：**

- Win10/Win11 的 DWM、窗口合成策略、驱动模型和窗口样式存在差异
- Win 11 的窗口合成会更激进处理中间帧，窗口在内容好之前不会 "破门而出" 显示给用户
- Win 10 的 DWM 对窗口显示的同步更宽松，更容易暴露出黑帧

**`WS_EX_LAYERED` 与 `WM_NCCALCSIZE` 处理差异：**

- Flutter Win 创建窗口时使用的窗口样式，在 Win 10 和 11 上对 `WM_NCCALCSIZE` 的处理有行为差异，会影响 resize 时的中间状态是否可见

当然，更大问题其实是多窗口场景放大了这些问题：

- 单窗口时，应用启动已经走了一遍这个路径，即便有 bug 也只暴露一次
- 多窗口时，每次新建/激活/关闭窗口都会触发上述路径，Win 10 上每次操作都可能走到有问题的分支

另外还可能存在点击问题，居然会有在第一帧 layout 完成之前就被分发进来的点击事件，这些问题都是相当细节的具体场景，**目前我整体体验 win11 还行，就是焦点切换还不太友好**。

# macOS

另外 macOS 上也是类似，**主要问题还是窗口在第一帧渲染完成之前就显示了**，而且问题在 Intel Mac（macOS 15.7.5）上可以稳定复现，在 M2 MacBook Pro（macOS 26.4）上又不稳定复现，不得不说，现在 macOS 的版本号碎片化也很丰富了。

那为什么这个问题在 macOS 上也会？因为 macOS 的窗口显示机制：

- macOS 使用 `NSWindow` 和 `NSView`，窗口创建后如果调用 `makeKeyAndOrderFront:`，窗口就会立即可见
- Flutter macOS embedder 目前没有实现 "延迟显示直到第一帧就绪" 的机制

而 `RegularWindowController` 目前又缺少：

- **隐藏/延迟创建能力**：创建窗口但不立即显示，等待就绪信号

- **每窗口的 "首帧已呈现" 信号**：没有一个回调或事件能告知上层 "这个窗口的第一帧已渲染完毕"

- **创建时的初始背景色**：窗口在内容就绪前没有正确的背景颜色，导致显示黑色或透明状态

所以这就导致了 macOS 上窗口时序没办法严格遵循，而实际上这个问题在单窗口场景下就一直有，很久之前 [#55427](https://github.com/flutter/flutter/issues/55427)（2020 年提的） 就有类似 ：

> *Consider hiding windows until the engine is active in the desktop runner templates* .

这上面 macOS  的问题一直都还没被修复，因为系统机制原因，Windows 的修复思路很直接，在 runner 模板里创建窗口时加 `WS_VISIBLE` 为 false，然后等 engine 的 first-frame callback 触发后再 `ShowWindow`，因为 Win32 API 设计上支持这种模式，callback 机制也在 engine 里已经存在。

而  macOS  就遭罪了，AppKit 的 `orderFront:` 和 `makeKeyAndOrderFront:` 是立即生效的，没有 deferred 参数。

> 也就是根据需求，**需要在 embedder 层向 engine 注册 per-view 的 first-frame 回调，而这个机制在 macOS embedder 没可用实现**，目前 macOS embedder 的 first-frame 通知是 engine 级别的，不是 view 级别的，多窗口下无法精确知道 "哪个 view 的第一帧已就绪"。

当然，在 Tooltip/Popup 场景下会好一点，因为用了 `alphaValue = 0.0` + positioner 回调来延迟显示，但是也是治标不治本，这也是 macOS 目前最大痛点。

# Linux

而 Linux 就更糟心了，相信用 Linux 的应该都懂，这就不是人力问题，而是 **GTK3 的 OpenGL 上下文架构从设计上就不支持多个 GtkGLArea 共享同一个 GL 上下文**，这导致多 view 渲染在 Linux 上面临需要绕过 GTK 底层限制的工程问题，感受一下：

| 时间          | 事件                                                         |
| ------------- | ------------------------------------------------------------ |
| 2023 年 11 月 | issue #138178 由 dkwingsmt 创建，标注 "mostly for tracking purposes"，无人认领 |
| 2024 年 7 月  | engine PR #54018 作为第一步合入（仅是基础结构调整）          |
| 2024 年 10 月 | **prototype 可用**，正在拆分为可提交的 PR；同时揭示了核心技术问题（GTK3 GL 上下文限制） |
| 2024 年 10 月 | engine PR #55541（view ID 分配）、#55542（view ID 释放）合入，这是仅有的两个实质进展 |
| 2025 年 6 月  | robert-ancell 提交 draft PR #170045，尝试用 EGL 绕过 GTK3 限制，但标注 "not working on X11" |
| 2025 年 7 月  | PR #170045 **被关闭**，未合入，X11 fallback 未完成           |
| 2026 年 1 月  | bot 自动提醒 assignee 没有进展，robert-ancell 回复 "Still chipping away at this"（仍在做） |
| 2026 年 3 月  | issue #183911 创建，指出 Linux embedder 多 view 下 shader 需要共享，是又一个新的 P2 子问题 |
| 2026 年 5 月  | bot 再次提醒无进展，**assignee 被系统自动移除**，issue 目前无人认领 |

**GTK3 的 `GtkGLArea` 每个实例都有独立的 `GdkGLContext`，这些上下文之间默认不能共享 texture、framebuffer 等 GL 资源。** 

在单窗口场景下，Flutter engine 把帧渲染到一个 `GdkGLContext` 里就结束了，但是啊，多窗口下 engine 需要把不同 view 的帧分别 present 到对应的 `GtkGLArea`，而各自的 GL 上下文是隔离的，engine 没有办法直接把一个 view 的渲染结果跨上下文传递给另一个 window。

而 prototype 采用的绕过方案，**在 implicit view（第一个窗口）的 GL 上下文里渲染所有内容**，然后通过 CPU 回读再写入其他窗口的上下文，但是这一听就知道多不靠谱， CPU readback 本身就是 GPU pipeline 的性能杀手。

另外还有提到**用独立的 EGL 上下文替代 GdkGLContext**，`EGLImage` 是一种可以在 EGL 上下文之间共享 texture 的机制，不需要 CPU 拷贝。

**但是，但是，但是这个方案在 X11 上不工作啊** ，X11 和 Wayland 在 EGL 的实现细节上有差异，`EGLImage` 在 X11 上的驱动支持没有在 Wayland 上那么普遍，而且 X11 的 `GdkGLContext` 是基于 GLX 而不是 EGL 的，和 EGL-based 的 Flutter context 之间需要额外的 interop，这部分还没有实现，所以路子又窄了。

这也是 Linux 的另一个独特麻烦，**需要同时需要支持 X11 和 Wayland 两套显示协议**，而这两者在底层 GL/EGL 栈上的行为有明显差异：

- Wayland 上 EGL 是原生的，`EGLImage` 扩展支持普遍，EGL context 和 GTK4/Wayland surface 的集成有官方文档
- X11 上 GTK 传统上使用 GLX（不是 EGL），与 EGL-based 的 Flutter rendering context 之间需要额外的互操作层，没有干净的官方路径
- 即便强制在 X11 上用 EGL（通过 `EGL_EXT_platform_x11`），扩展的驱动支持也不如 Wayland 普遍，开源驱动（Mesa）和私有驱动（NVIDIA）行为不一致

> 这也是为什么很多对支持 Linux 不热衷的原因。

# 最后

不管怎么说，多窗口确实推进的有些久了，Canonical 的投入也一直不瘟不火，感觉 AI 时代了，在不加速推进 release ，感觉多窗口就要烂裤兜里了，不过目前至少我在 win11 场景上还行。