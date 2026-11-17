# Flutter Android 性能修复：8 个大核的手机，Raster 居然只跑在 2 个核上？

最近 Flutter  刚刚合并了 [PR #195071](https://github.com/flutter/flutter/pull/195071)，这个 Bug 挺搞笑的，因为 Android Engine 一套沿用上古的 CPU 亲和性策略：

> 在 Snapdragon 8 Elite 这一类没有传统小核的芯片上，Flutter 会把六个性能核当成效率核，最后只允许 Raster 线程在两个超大核上运行。

然后开发者在 Snapdragon 8 Elite Gen 5（SM8850）真机上 （Galaxy S25），通过应用侧修改线程亲和性来测试，放开可用核心之后，**Raster 帧耗时中位数下降了 16%～21%，Raster 线程累计 CPU 执行时间减少 16%～18%**，这个一看就很反常，明明两个超大核的最高频率更高，为什么放到普通性能核上反而跑得更快？

这套策略最早可以追溯到 2023 年的 [Engine #45673](https://github.com/flutter-team-archive/engine/pull/45673)，当时 Flutter 希望让 UI、Raster 之类的关键线程避开慢核，所以通过 `/sys/devices/system/cpu/cpuN/cpufreq/cpuinfo_max_freq` 读取每个核心的最高频率，最高频率的一组叫 `kPerformance`，最低频率的一组叫 `kEfficiency`。

但是这样做之后又遇到一个问题：

- 一些 Android 手机只有一个频率最高的核心，例如 [#153690](https://github.com/flutter/flutter/issues/153690) 的 Pixel 8，UI、Raster 和部分 Dart Worker 可能挤到同一个核上
- 所以后来的 [Engine #54616](https://github.com/flutter-team-archive/engine/pull/54616) 把 UI、Raster 的策略放宽成 `kNotEfficiency`，也就是除了最低频率那组，其他核心都能用

这个做法在有传统大小核的手机上还算合理，但是 Snapdragon 8 Elite / 8 Elite Gen 5 改成了两个 Prime 超大核加六个 Oryon 性能核，已经没有传统 Little Core 了，比如拿 PR 实测的 SM8850 来说，CPU 0～5 的最高频率是 3.63 GHz，CPU 6～7 是 4.61 GHz，然后 Flutter 一比较，还是把前六个识别成了 `kEfficiency`，所以 `kNotEfficiency` 最后只剩下 CPU 6～7：

![Snapdragon 8 Elite Gen 5 修复前后的 Raster 线程 CPU 亲和性](/article-assets/fae8cf055dd463158fcc0e37.webp)

所以实际上问题出在把「最高频率最低」直接当成「小核」，也就是问题处理上 PR 不需要重写调度框架，只需要额外读取 `/sys/devices/system/cpu/cpuN/cpu_capacity` 就可以了，这个值提供了 CPU 在最高频率下的相对计算能力。

这里新增的 `HasNoLittleCores()` 要求每个核心都有 Capacity 数据，而且不能全部相同，然后检查：

```cpp
return min_capacity != max_capacity &&
       min_capacity * 2 >= max_capacity;
```

**也就是最弱核心至少达到最强核心的 50%**，SM8850 的六个性能核是 762，两个超大核是 1024，比例为 74.4%，所以 Flutter 判断这颗芯片没有明显的小核分组，把原来的 `kNotEfficiency` 改成 `kNotLittle`，然后让 UI、Raster 的可用核心扩大到 CPU 0～7。

> 传统大小核上，像 Cortex-A520 相对 X4 的 Capacity  37%，就不会触发这种放宽。

当然，这里还有两个保守处理：

> 只要某个核心的 Capacity 读不到，或者所有核心都报告相同值，Flutter 就继续沿用旧的频率分组逻辑。

而且 `kEfficiency` 的分组逻辑没有变化，在 SM8850 上它还是指那六个最高频率较低的 Oryon 性能核，后台线程的原有策略也没有被整体重做。

> 那到这里，其实还有另外一个问题，**两个超大核明明更快，Raster 为什么反而慢了**？

所以 PR 用 Perfetto 找到的执行过程，因为 Raster 属于一帧来时忙一阵、处理完又等待下一帧的负载，两个超大核虽然有 4.61 GHz 的上限，但在这台 SM8850 上，**Raster 被限制到 CPU 6～7 之后，线程每次执行往往从 883 MHz 开始，97%～100% 的 CPU 执行时间都低于 1 GHz**。

**也就是你看到的最高频率很漂亮，但一帧的工作可能已经结束了，频率还没来得及爬上去**。

> **这就类似于你骑车起步挂高档，但是只给你 3s 时间，速度还没起来，就停了。**

所以如果 App 启动时用 `sched_setaffinity` 把 Raster 的可用范围改成 CPU 0～7 后，Perfetto 看到线程更多地跑在六个普通性能核上，**实际平均执行频率为 1.25～1.4 GHz，反而比限制在超大核时高**。

![放开 CPU 亲和性前后三类场景的 Raster 帧耗时中位数](/article-assets/707f028b550b130cb64386e2.webp)

**是不是很有趣，就和之前我们聊的，在 iOS 上，因为优化的太好，系统觉得你不需要 Power 核心，直接给你挪到小核上一样抽象**，这次的也是，比如放开后， PR 里打开并滚动详情页可以看到：

- Raster 帧耗时中位数从 1.48 ms 降到 1.24 ms，超过 12 ms 的帧从 7 个减少到 2 个
- 在 120 Hz、每帧 8.3 ms 的预算下，这种变化主要体现在页面切换、冷启动和少数比较重的帧上
- 其他两个场景的中位数也分别从 1.25 降到 1.00 ms、1.74 降到 1.38 ms

实际上这种按 CPU 频率划分核心、再手动指定亲和性的办法，对真实芯片拓扑和调度行为做了太多假设，其实本身就不是很健壮，但是为了解决问题，暂时选择这个方向也是一种妥协。

理论上  [Android 官方的 Performance Hint 文档](https://source.android.com/docs/core/perf/performance-hint-api)本来就建议 App 不要自己绑定 CPU 核心，因为哪一组核更合适，会随着 SoC 架构、温度、功耗限制和系统负载变化，一般来说更合理的做法是把目标帧耗时、实际工作耗时交给 ADPF，让 Android 去决定频率和核心。

> 其实Flutter 也有相关的 [#192582 Draft PR](https://github.com/flutter/flutter/pull/192582)，尝试在 Android 15+ 用 ADPF Hint Session。

整体来看，这个问题其实挺有意思的，Flutter 原本通过限制线程可用 CPU 来追求稳定性能，结果新硬件把这个假设打破了，变成了负优化，只能说，这就是“写死”的魅力。
