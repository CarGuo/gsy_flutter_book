# Flutter 状态管理基准测评，一个很有趣的观点

最近刚好看到，Filip Hráček 发了一篇 Flutter 状态管理 Benchmark，实际上对比 Provider、Riverpod、GetX、Signals 到底差了几微秒性能 差异的意义不大，主要是有一个问题：

> **状态管理库本身的开销很好测，但用了这个库以后，一个真实 Flutter App 最终会写成什么样的整体影响，这个一直比较难评估**。

比如如果只写一个循环，让 Riverpod、Provider、Signals 连续通知 10000 次，这样很容易得到一张漂亮的吞吐量排行榜，但是实际毫无意义，这种测试对真实 App 场景毫无帮助。

> 真实情况下，用户点一下按钮，状态改变一次，接下来真正吃时间的通常是哪些 `Element` 被标成 dirty、多少个 `build()` 被重新执行，还有这些 Widget 后面有没有继续引起 layout 和 paint。

所以这个的测试放弃了状态管理 microbenchmark，核心是拿同一个 Todo App 的七种状态管理实现，跑完整 UI workload**，一直花了五天、2100 个 trial、300 个 round 来控制设备噪声**：

![](/article-assets/1e94dd78eeef5646751f561a.gif)

然后得到的结果也挺有意思的，**除了 `package:bloc` 那个异常快的样本之外，Provider、Riverpod、GetX、Signals 的方案，相对原生 `setState()` 的差距都小得几乎没有工程意义**：

> Riverpod、GetX、Signals 大约只增加 5～6 微秒，按 120Hz 一帧约 8.33ms 算，只占不到 0.1% 的 frame budget。

**所以在同个水平下，用什么状态管理框架对性能影响不大，只是写法和管理上的差别**，不过有个有意思的是`bloc_library` 居然比 Vanilla 的 `setState()` 平均少了约 21 微秒 build time ：

![](/article-assets/1160944970025d45084368cd.webp)

如果只看图，可能会觉得，Bloc 性能吊打所有状态管理，但是实际上情况还有点不一样，为什么一个带 Event、Stream、BlocBuilder 的 Bloc，居然还能比 `setState()` 快？

这里可能要先回到 Flutter 自己的机制，`setState()`  本身其实非常薄，Flutter 官方实现里，它执行传入的 callback，然后调用 `Element.markNeedsBuild()`。

> 官方文档也说过：**调用 `setState()` 的 direct overhead is minimal**，真正成本高的是之后可能发生的 subtree rebuild，以及进一步带来的 layout 和 paint。

所以一个状态管理库最后根部没有让 App 更快，你计算 `notifyListeners()` 花了多少时间、Riverpod dependency lookup 花多少时间、Bloc 发一个 state 花多少时间的意义其实不大，一样的代码下大家差距根本体现不出来。

比如一个页面上有 100 个 Widget，某次状态变化实际上只影响其中一个 loading indicator：

- A 实现把监听放在整个页面外面，状态变化后大块 subtree 都重新执行 `build()`
- B 实现把响应状态的 Widget 放得很低，只重新构建 loading indicator 周围的一小块

**这时候哪怕 B 的状态分发机制本身多花几微秒，它最终的整帧 build time 依然可能比 A 少几十微秒**，所以 Flutter 官方性能指南也一直强调这一点：

> 调用 `setState()` 时，要尽量把它 localize 在真正发生 UI 变化的 subtree，避免状态放在 Widget Tree 太高的位置。

所以坐着在检查 `bloc_library` 的 Sample 后，发现这里恰好发生了类似的事情，它实现的 rebuild 更 granular，而且 loading indicator 的逻辑都被放到了 Widget Tree 更低的位置，所以图里的 `-21μs` 其实是里面混进了 Widget Tree 结构差异。

这一点从仓库自身的设计也能看出来，`bloc_library`  没有单纯拿一个全局 state 然后所有 Widget 一起监听，它把状态进一步拆成 `TodosBloc`、`FilteredTodosBloc` 等不同 Bloc，比如 `FilteredTodosBloc` 监听 `TodosBloc`，UI 再通过 `BlocBuilder` 对对应 state 做局部构建，这个架构下本身就非常容易形成较细的观察边界。

所以事实上状态管理的测试，本质上还是回到代码颗粒度测试上，**我们测试的不是这个库的性能，核心是这个状态管理方式最终诱导出来的 Widget Tree** 。

所以 Filip 把不同实现之间的性能差异拆成三类：

- A 类是 Library 自己带来的差异，比如订阅结构、对象通知、Stream 调度、dependency tracking，这些最接近传统 benchmark 想测的 “Riverpod 和 Provider 谁内部实现更快”

- B 类是**库的 API 和设计哲学，会影响开发者最终怎么组织状态和 Widget**，比如一个状态库很容易让开发者把不同状态拆成多个独立 observable object，那么真实工程里就更容易得到较细的 invalidation scope；如果另外一种 API 最舒服的写法是让一个大 Model 被整个页面 `watch`，那平均项目中可能就会产生更多 rebuild

> 这个性能收益其实不来自某个特别快的数据结构，可它又确实是“用了这个状态管理方案以后”产生的结果。

- **C 类是写 Sample 的那个开发者个人习惯**，`flutter_architecture_samples`  这个项目已经存在九年，不同 Sample 来自不同作者，比如 Bloc Sample 有 Felix Angelov 参与，Freezed + Provider Sample 有 Remi Rousselet 参与，这些人对各自生态理解程度并不一致，Widget 拆分方式、loading 放在哪里、是否使用额外 Widget，也都可能不同

同一个功能不等于同一个 Widget Tree，而且同一个测试脚本，也不等于每一次状态变化造成了同样数量的 rebuild，所以 Bloc 那个大约 21 微秒的优势，实际上也没办法就归因是 `package:bloc ` 更好，因为 C 的影响其实最大。

> 比如 Provider 完全可以写得很细，你也可以用 `Provider.of(..., listen: false)` 拿一个对象处理 callback，再用 `Selector` 只监听真正需要刷新的字段。

但是问题在于，实际上日常用 Provider 的开发者很少会这么写，如果为了 benchmark 人为把 Provider 代码调到极致，那 Signals、Bloc、Riverpod 同样全部都可以优化到最小 invalidation，那么最后测出来的东西会得很可以， AI 都不会用这么“极致”的写法。

> **所以 B 类的框架设计的价值就在这里，API 能不能更自然鼓励细粒度观察？**

因为 B 类差异——API 是否自然鼓励细粒度观察——本来就是一套状态管理方案真实工程体验的一部分。如果全手工消掉它，反而把一个有价值的因素从 Benchmark 里删掉了。

问题只在于 C 类差异现在还混在里面。

所以这项实验当前真正缺的并不是更多 trial，而是一套**既保留各框架自然 idiom，同时又能尽量控制实现者差异的 workload 设计**。

而对于实际 Flutter 项目来说，这里最有意义的点在于：

> **状态管理库不会是 Flutter UI 性能问题首先应该怀疑的地方**，`setState()` 自身便宜，Provider 的 listener dispatch、Riverpod 的 dependency tracking、Bloc 的 state propagation、Signals 的 reactive tracking，当然都不是零成本，但放进真实页面 build workload 后，目前这次实验测出来的差距只有几微秒。



## 链接



https://filiph.net/text/flutter-state-management-performance-2026.html
