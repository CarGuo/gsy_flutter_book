---
title: "Flutter Impeller Vulkan 内存持续上涨，问题没想到是文字阴影"
---

# Flutter Impeller Vulkan 内存持续上涨，问题没想到是文字阴影

最近 Flutter 的 [#195323](https://github.com/flutter/flutter/issues/195323) 挺有意思，用户最初发现的是，Flame 游戏里十来个带模糊阴影的 HUD 文字，只要每帧重绘，Native Heap 就一直往上涨，27 分钟从 34 MB 涨到 775 MB。

但是后面把文字、阴影都删掉，只保留一个持续触发重绘、没有实际画出图形的 `CustomPainter`，Vulkan 下的 Native Heap 居然还会稳定增长，这就有点怀疑人生了。

> 也就是**文字阴影每帧反复分配纹理，所以确实有问题，但是没有文字的 Vulkan 空帧也在涨内存，这个目目前还不知道为什么**

## 为什么不变的文字也会增加内存开销？

作者在 Adreno 725、Android 16 上用的 Flutter 3.47.7、Impeller Vulkan、Release 模式做了四组 60 秒实验，一个文字是每帧变化的计数器，另一个是内容完全不变的 `STATIC LABEL`，阴影模糊半径设成 4，再和没有模糊的情况对比：

| 场景 | Native Heap 增长速度 |
| --- | ---: |
| 变化计数器 + 不变标签，`blurRadius: 4` | **123 KB/s** |
| 只有变化计数器，`blurRadius: 4` | **66 KB/s** |
| 只有不变标签，`blurRadius: 4` | **8 KB/s** |
| 两段文字，`blurRadius: 0` | **14 KB/s** |

![图 1：按原 Issue 的 60 秒 Native Heap 采样数据重绘的对比图](/article-assets/ccd5d173c5de638cf7a6ef6e.webp)

然后你看不变的标签，它单独存在的时候，虽然界面还会走构建过程，但基本不发生持续的实际重绘，但是和变化计数器放在一起后，标签也跟着重新绘制，整组增长速度就从 66 KB/s 到了 123 KB/s。

> **所以光看 `Text` 内容有没有变、是不是 `const` 其实根本看不出来问题，因为它每帧进入了绘制。**

而原因是，Flutter 3.47.7 的 `TextShadowCache` 用 `TextFrame` 的地址参与生成缓存键，下一帧就算字符完全一样，只要对应的 `TextFrame` 换了，之前的阴影就可能命中不了，而且  [`MarkFrameEnd()`](https://github.com/flutter/flutter/blob/3.47.7/engine/src/flutter/impeller/entity/contents/text_shadow_cache.cc#L35-L38) 还会直接删除本帧没用上的缓存条目。

> 比如输入框里的 `Typing.`、`Typing..`、`Typing...` 来回循环，看起来就几个固定状态，但一个状态隔了几帧再回来时，原来的缓存可能就已经被清掉了，所以它又要生成 Gaussian Blur 的阴影纹理。

![图 2：文字阴影缓存失效与 Vulkan 空帧增长是两条需要分别验证的路径](/article-assets/011685c0a4439c3b6ac06def.webp)

**这里 Flutter 已经合并了 [#190681](https://github.com/flutter/flutter/pull/190681)，把缓存键改为内容指纹，解决了不变文字跨帧命中失败的问题**，然后还有 [#194769](https://github.com/flutter/flutter/pull/194769) ，它准备让模糊过程中的临时 RenderTarget 继续复用，只把必须跨帧保留的输出纹理排除在复用池外，同时给文字阴影缓存设置最多 240 个未使用帧和 8 MiB 的预算，也就是当前帧正在用的缓存条目不会因为超出预算被立即驱逐。

> 这套调整在 PR 的 Mali-G68 复现场景里，把 Raster P50 从 5.35 ms 降到 1.94 ms，收益还是挺明显。

## 但是问题是阴影没了，Vulkan 还涨

用户之后还做了更干净的对照：`CustomPainter` 每帧执行 `save/clip/translate/scale/restore`，但不调用任何实际绘制图形的操作。

还是同一台设备，连续观察约 7 分钟，Release + Vulkan 的 Native Heap 增长 10.1 KB/s，把游戏里的绘制内容清空也有 10.3 KB/s，而暂停游戏循环、不再产生帧后增长降到了 0。

而且同一设备的 Profile 对比：

- Vulkan 增长 **13.0 KB/s**
- OpenGLES 只有 **2.8 KB/s**

按 60Hz 粗算，Release Vulkan 相当于每渲染一帧多出约 170～175 字节的 Native Heap 增长，所以前面其实只是模糊阴影显著放大了这个现象。

而且有意思的是， Dart Heap 保持很小，强制 Dart GC 也没办法让这部分内存回落，`dumpsys meminfo` 的 `Graphics` 也基本不变。

>  感觉这里Native Heap 一直涨，也不能说就是 C++ 对象泄漏了？感觉也可能涉及分配器保留内存或驱动侧的分配。

这个这种问题还真抽象，这种文字不变都会上涨的问题，谁能想到？
