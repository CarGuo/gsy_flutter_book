# Flutter 大小核优化又被回滚，然后又合并？

上周的 [#195071](https://github.com/flutter/flutter/pull/195071)  我们才聊过，在 Snapdragon 8 Elite 这类  Little Core 的 CPU 上，然后没想道后面还能继续折腾，类似的问题其实不止一个：

- Android： Snapdragon 的 Performance Core 明明不弱，但是 Flutter 之前把 Raster Thread 限制在两颗 Prime Core 上，所以选择放开亲和性后反而变快，因为大核不代表就快，它需要持久才能热起来
- iOS 之前 [#190815](https://github.com/flutter/flutter/issues/190815) 也类似，就算 Flutter UI/Raster Thread 设置了 QoS，也可能长期被匹配到  E-core 上，只有人为增加工作负载之后，线程才会被系统挪动到 P-core，卡顿才会消失

也就是其实都可以看出来一个问题：：

> **Flutter 的 UI/Raster Thread 是短时、周期性、对延迟敏感的任务**，而 CPU 调度器通常还要兼顾吞吐量、功耗、温度和整个系统的负载，所以所谓的最优选择不一定就可以在不同平台完全一致。

**比如 Android 上两颗 4.61 GHz 的 Prime Core 反而可能比六颗 3.63 GHz 的 Performance Core 慢**，因为虽然 4.61 GHz 是最高可达频率，但是线程每次唤醒的成本高啊，而 Flutter Raster Thread 的工作经常非常短，比如某帧只需要处理 1–2 ms 的光栅化工作，也就是假设线程每隔 16.7 ms 被唤醒一次，做完任务马上休眠，而如果 Prime Cluster 就可能因为空闲降到最低频率，**这时候线程被唤醒，CPU 频率还没爬升上升，任务就已经执行完了**。

但是如果把 Raster Thread 跑到其他 Performance Core，那里可能正好有别的任务让 Cluster 保持在较高频率，Flutter 反而可以直接有更好的调度。

但是问题出现在这里，修复之后，**官方 Benchmark 反而出现 2 倍回退**，因为在 [#195826](https://github.com/flutter/flutter/issues/195826) 里面提到，合入 #195071 后官方 `fading_child_animation_perf` Benchmark 的 `average_frame_rasterizer_time_millis` 出现 2 倍性能回退，所以选择回滚。

> 也就是方案还是带来其他负面影响。

**其实如果把时间往回拉，你会发现 Flutter 已经在这个问题上反复踩坑**，不知道官方有没有感受出来，这次很像一轮 CPU 亲和性策略的循环：

| 时间                                                         | 问题                                                         | 当时的处理思路                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ---------------------------------- |
| 2023 年，[#134452](https://github.com/flutter/flutter/issues/134452) | Pixel 6 Pro 上 UI/Raster 可能被调度到慢核，产生卡顿          | 通过亲和性限制，倾向性能核         |
| 2024 年，[#153690](https://github.com/flutter/flutter/issues/153690) | Pixel 8 上 UI、Raster、部分 Dart Worker 可能挤在同一颗最快核心 | 扩大可用核心集合，避免过度集中     |
| 2026 年 10 月，[#195070](https://github.com/flutter/flutter/issues/195070) | 没有传统小核的 Snapdragon 被错误分类，6 颗 Performance Core 被排除 | 使用 `cpu_capacity` 识别无小核设备 |
| 2026 年 11 月，[#195826](https://github.com/flutter/flutter/issues/195826) | 扩大核心范围后，官方 Benchmark 出现回退                      | 回滚改动，重新评估策略             |

从最初限制核心，是因为 Android 调度器会把关键渲染线程安排到较慢的核心，影响帧率，但限制以后在 Pixel 8 这类设备上，又出现了 UI、Raster 和部分 Worker 竞争同一颗核心的情况。

然后继续修正，到了没有传统 Little Core 的 Oryon 架构，Flutter 还是依靠最高频率分组，导致又把六颗性能核排除了。

然后这次放开以后，SM8850 上确实变快，但官方测试又遇到了回退。

> 所以我感觉更合理的方向应该重新考虑整个核心选择和调度机制，这样缝缝补补简直就是屎山堆积。

**所以你觉得应该是 Flutter 到底应该自己选核心，还是让操作系统决定？**

目前官方有个 [ADPF 集成 RFC #45](https://github.com/flutter/rfc/pull/45) 的提案，对应 [#195992](https://github.com/flutter/flutter/issues/195992)，就是希望可以设计一个告诉 Android 帧截止时间的支持，然后让系统自己调度，也就是 Fllutter 可能可以不需要再根据 CPU 的静态参数判断哪些核心适合 Raster，而是告诉 Android：

- 哪些线程负责 UI Build 和 Raster
- 每帧需要在多久以内完成
- 上一帧实际上花了多久
- 当前是否刚从较长时间的空闲状态恢复

> **这样 Android 就能结合 CPU 频率、调度策略和功耗预算作决定**。

目前 RFC 作者用 Pixel 8、Pixel 9、Lenovo Tab 做了多轮 Profile Benchmark，特别关闭了测试环境的 Fixed Performance Mode，让设备采用正常动态调频策略，大概情况如下：

| Benchmark             | 原型前 Raster Avg | ADPF 原型 | 改善 |
| --------------------- | ----------------- | --------- | ---- |
| Pixel 8，复杂布局滚动 | 4.18 ms           | 2.65 ms   | 36%  |
| Pixel 8，Tiles 滚动   | 4.62 ms           | 2.91 ms   | 37%  |
| Pixel 9，复杂布局滚动 | 4.15 ms           | 2.59 ms   | 38%  |
| Pixel 9，Tiles 滚动   | 4.28 ms           | 2.42 ms   | 44%  |

不过目前原型也存在回退的情况，**比如某些轻负载场景在 Pixel 8 和 Lenovo Tab 上更慢，Hybrid Composition 下还有特殊的线程合并处理问题**。

但是我感觉这套方案的方向更合理，至少交给系统处理比这样维护屎上更稳定，你这个规则又不支持外部自己更新配置，还不如直接交给系统更合理。
