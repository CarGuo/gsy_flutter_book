# 血压飙升，Flutter & Dart 2025 年度巨坑回顾

近日，Google 官方发布了[《Flutter & Dart 2025 年度十大高光时刻回顾》](https://mp.weixin.qq.com/s/HQ5_59Mm1WT1xsiPuy6I2w)，内容包括：

- Flutter 3.29 - 3.38 版本更新
- Dart 3.7 - 3.19 版本更新
- Flutter Roadmap & Google I/O 
- NotebookLM、teamLab、Agape、Universal Destinations & Experiences、Reflection.app 、 GE Appliances 、talabat  等案例展示
- Material 和 Cupertino 拆分进度
- build_runner 提速速度
- Dart 与 Flutter MCP Server
- Flutter AI Toolkit 、GenUI
- ····

但是又怎么可以报喜不报忧？既然官方报喜，那我就来点忧的，**2025 在 Flutter 内容上我的大概写了有 60 来篇，稍微整理几个给大家直观回顾下 2025 Flutter 究竟经历了哪些经典巨坑**。

> 只能 Flutter 坑接坑不断，但 iOS 能占一半。



# 宏

Flutter 在  2025 年 1 月的时候，开年就送上了大礼，官方决定 Dart 宏功能推进暂停，后续专注定制数据处理支持，宏功能是在 2024 年初开始决定推进的，而 2025 年开年，官方得到了一个结论：

> **做出来能用是能用，但是质量和性能都达不到一开始的预期，而且维护成本很高**。

所以对于社区里大家盼星星盼月亮都在等的宏支持就这么夭折了，虽然不久前官方也再次出来解释了为什么暂停：

- 宏执行时序与 Dart 常量模型存在根本冲突
- JSON metadata 方案“能跑但不可用”
- Analyzer + CFE 双体系导致工作量与复杂度指数级爆炸
- 性能与 IDE 体验无法接受
- 无法完全替代 build_runner

![](https://img.cdn.guoshuyu.cn/b74421cfbeff28a7333aa868e55327a9.png)

> 更多可见：[《Dart 官方再解释为什么放弃了宏编程》](https://juejin.cn/post/7591730714140606506)

但是宏终归还是凉了，**官方也将精力回归到 build_runer ，也在性能上做出了一些不小的提升**，但是  Augmentation  支持还是没落地（它允许通过 `augment` 关键字，在新文件里去“补充”旧文件的定义），这也是 2025 官方在宣布宏放弃之后，没能完全填不上的坑。

![](https://img.cdn.guoshuyu.cn/image-20260124154705188.png)

# 线程合并

线程合并是 Flutter 在 3.29 的重大调整，在过去 **Flutter 的 UI Runner 和 Android/iOS 平台的 Platform Runner 是处于不同线程**，其中 Dart 的 root isolate 会在被关联到 UITaskRunner 上。

所以在过去 Flutter 里会有异步 platform channels 的存在，因为 UI Runner 和 Platform Runner 分属不同线程，所以 Dart 和 Native 互相调用时需要序列化和异步消息传递。

而在 3.29 里，作为改进移动平台上 Native 和 Dart 互操作系列调整中的一部分，两个线程被合并了，说人话就是： `UI Runner = Platform Runner `：

![](https://img.cdn.guoshuyu.cn/image-20260124155051931.png)

实际上这是一个不错的调整，**因为同步调用是趋势，而且也能解决 Flutter 的许多历史问题，也是一个大趋势**，但是步子迈大了，总会扯出一些问题，而线程合并带来的问题还不少：

- Android 断点 Dart 代码现在会导致 ANR 弹窗死循环
- 线程合并之后，启动引擎、应用和设置 Dart 代码都运行的平台线程上，会导致第一个可交互帧的时间变长
- Win 出现 Failed to post message to main thread 或者渲染卡死问题
- 一些插件过去没适配同步线程，导致卡顿明显
- ······

> 更多可见：[《Flutter 在全新 Platform 和 UI 线程合并后，出现了什么大坑和变化？》](https://juejin.cn/post/7496397558359162934)

这个改动带来的效益和目标是好的，也为 FFI 等同步调用场景打下了基础，但是奈何这类 break change 带来的问题，在初期版本可以说是灾难，在当时生产几乎都是选择暂时关闭这个特性。

# mprotect failed: Permission denied

iOS 可以说是 2026 Flutter 问题的重灾区，特别因为 iOS 26 的到来，给 Flutter 带来了不少全新的适配成本，其中就包括这个 mprotect failed，**现象就是无法在 iOS 真机上 Debug 运行**，因为 Apple 官方禁止了 JIT 支持的“漏洞”。

这个问题其实也很戏剧性：

- 问题一开始出现在  iOS 18.4 beta，但是在 Flutter 还没处理的时候，但 iOS 18 beta2 该“漏洞”又可以正常使用，所以适配放缓
- iOS 26 beta1  mprotect 漏洞又重新禁止了，所以 Flutter 又需要对适配加急

所以 Flutter 不得不在 iOS 26 ，通过 LLDB 的  `debugserver` ，然后利用 python 脚本实现适配黑科技：对同一个内存地址，在 Debug 时做到同时 RW 和 RX 支持 ，实际上就是开了两道门。

> 更多可见：[《Flutter 又双叒叕可以在 iOS 26 的真机上 hotload 运行了》](https://juejin.cn/post/7542461507402924075)

事实上这个支持一直不太好，成功率不高，经常会出现超时等问题，一直等到 iOS 26 发布之后， devicectl + lldb 的支持才完善，Debug 的真机 JIT 运行才回到正轨。

所以这里还有另外一问题，就是**由于苹果对于 `ios-deploy` 的“废弃”，导致了 iOS 真机 Debug 运行出现 Timed out \* to update 的问题**  ，具体表现在：

> 如果你直接在 Xcode 直接运行这个 Flutter 项目是可以正常运行，但是通过 flutter 命令运行或者 ide run 就不行。

这个坑相信有不少人踩过，当时临时解决方式包括有：

- 需要安装 Xcode 并且运行时会弹出 Xcode 窗口
- 用户在 macOS 的`“系统设置 > 隐私与安全性 > 自动化”`中给予相应的权限 
- 关闭 Wi-Fi，因为有时候即使 iPhone 通过 USB 数据线连接到 Mac，Xcode 也可能优先选择通过 Wi-Fi 进行调试连接
- 如果还不行，可以尝试 Xcode 直接运行，然后执行 `flutter attatch` 尝试连接 Dart VM Observatory 服务

![](https://img.cdn.guoshuyu.cn/image-20260124161537216.png)

> 搞笑的是，有一段时间，`flutter attatch` 尝试连接 Dart VM Observatory 服务也 Timeout 了，详细可见：[《聊聊 Flutter 在 iOS 真机 Debug 运行出现 Timed out *** to update 的问题》](https://juejin.cn/post/7529752760076009508)

一直到 [《Flutter 完成全新 devicectl + lldb 的 Debug JIT 运行支持》](https://juejin.cn/post/754246150740292407) 之后，iOS 的开发运行才回归正轨，这时候已经是接近 2025 的 9 月份了。

# iOS 26 模拟器无法运行

在 3.35 的时候，Flutter 开发者发现，Flutter 在 iOS 26 模拟器上也“随机”出现无法运行的情况，运行时会出现 `Unable to find a destination matching the provided destination specifie` 这样的提示：

![](https://img.cdn.guoshuyu.cn/image-20260124162130747.png)

当然，这个即是 Flutter 的问题，也不是 Flutter 的问题，但是它是真很坑，因为在一开始，大家都不知道为什么会出现这个问题，而且为什么有的项目会有，有的项目不会，经过很长时间排查才发现，**是一些插件和模拟器之间的适配问题**，实际上问题是：

> **用的插件不支持 “ARM 模拟器”，而你默认使用的 iOS 26 模拟器只支持 ARM** 。

而解决问题的方式也很简单，只需在 Mac 上安装 **Rosetta** ，然后从 Xcode 中移除 **iOS 26** 平台，然后运行以下命令：

> `xcodebuild -downloadPlatform iOS -architectureVariant universal`

**重新下载的会是具有通用架构支持的 iOS 26**，而不仅仅是基于 Apple 的 ARM 架构默认配置，所以解决方案是强制 Xcode 下载 iOS 26 模拟器的“通用”版本，而不是默认的“Apple Silicon”，通过 `xcodebuild -downloadPlatform iOS -architectureVariant universal` 之后，就可以看到通用的 iOS 26 模拟器组件以及 Rosetta 模拟器：

![](https://img.cdn.guoshuyu.cn/image-20260124162411373.png)

当然，**Rosetta 只能说是一个临时的解决方式，核心还是要看哪些插件仍然无法运行 ARM** ，但是也是一些 Flutter 插件没适配好，这锅 Flutter 也要背。

> 详细可见：[《Flutter 在 iOS 26 模拟器跑不起来？其实很简单》](https://juejin.cn/post/7560986017034190891)


# iOS 26 WebView

这也是一个大坑问题，就是 Flutter WebView 在 iOS 26 上有点击问题，原因来自 Flutter 的技术债务，核心原因就是因为一直以来线程合并之前的 `MethodChannel`  只能异步。

![](https://img.cdn.guoshuyu.cn/fc0e1d51b8436be04733d96fc59f80f1.gif)

> 可谓是一环扣一环，毕竟线程同步后的 FFI 还真是解决这个的思路。

那你要说这个问题有多坑，你看我都可以写三篇文章，就知道这个问题有多蛋疼：

- [《为什么你的 Flutter WebView 在 iOS 26 上有点击问题？》](https://juejin.cn/post/7571306072423448618)

-  [《Flutter 官方正式解决 WebView 在 iOS 26 上有点击问题》](https://juejin.cn/post/7583577045578907674) 
- [《再次紧急修复，Flutter 针对 WebView 无法点击问题增加新的快速修复》](https://juejin.cn/post/7584443518162141220)

问题最开始出现在 iOS 18.2 beta 版本上，当页面上先触发了某些 Flutter widget（或者 overlay，比如 context menu / Drawer）后，**WKWebView 内的点击（链接、按钮）不再响应**（可高亮，但不会激活），需要重新加载 WebView 才恢复。

而具体原因在于，Flutter 在 iOS 的 PlatformView（例如承载 WKWebView 的视图）上实现了一套“手势拦截/延迟”机制：在需要时会把一个 `FlutterDelayingGestureRecognizer`（`delayingRecognizer` ）切到某些状态（`possible`, `ended`, `failed` 等）来告诉 UIKit 或者其他 recognizers 是否应该阻止/允许手势传递。

又因为，Flutter 和 UIKit 都各自有手势识别系统（GestureRecognizer），为了防止互相抢事件，Flutter engine 在 iOS 上加入了一个“**delaying gesture recognizer**”（延迟识别器）：

> 它的作用是：当 Flutter 框架检测到某个 widget 想“阻止”事件时（比如 `GestureDetector` 或 overlay 遮罩），Flutter 会让这个 `delayingRecognizer`  阻止 UIKit 里的 recognizer（例如 WKWebView 的点击识别器）响应。

而问题主要出现在  Flutter → UIKit 手势交界，详细的这里就不展开了，反正就是 Flutter 一开始为了解决这个问题做了一件事：

> 在 blockGesture 的处理流程里把 `delayingRecognizer` **移除后再添加回去**，以强制 UIKit/WebKit 刷新识别器关系，解决了问题：![](https://img.cdn.guoshuyu.cn/image-20260124164533846.png)

但是这个做法在 iOS 26 上不行了，所以官方有做了两个处理：

- 完整修复方案， 利用 FFI 和全新的 HitTest 实现，从底层正式重构修复问题，但是改动很多，没那么快合并到正式版本
- 临时解决方案，增加一个方式，通过递归操作，再来一下 NO & YES ![](https://img.cdn.guoshuyu.cn/image-20260124164751872.png)![](https://img.cdn.guoshuyu.cn/image-20260124164827711.png)

针对完整解决方案，除了需要改引擎和框架，第三方插件也需要适配，但是属于是彻底解决问题的思路，而临时方案的好处就是：**可以什么插件都不改就生效**。

> 所以，这个问题虽然解决了，但是这个坑还在，就看什么时候 break change 了。

# binary is invalid

依然还是 iOS 问题，可以看到 2025 大坑，有一半以上都是 iOS 的，问题在于  3.38.1 之后的版本，在提交 App Store 的时候，有概率发现打包提交 iOS 的包会出现 `The binary is invalid` 的相关错误，简单来说，就是**App Store 拒绝了某个二进制文件，因为它包含了无效的内容**。

![](https://img.cdn.guoshuyu.cn/image-20260124165158754.png)

那么这个内容是怎么来的？大概率是模拟器架构的 Framework 被错误地打包进了正式发布的 App ，具体原因还要提到最新版本增加的 Native Assets 功能。

Native Assets 的目标是**让在 Flutter/Dart 包中集成 C、C++、Rust 或 Go 代码，可以像集成普通 Dart 包一样简单**，也就是它允许 Dart 包定义如何构建和打包原生代码，开发者不需要深入了解每个平台的底层构建系统，也是 Dart FFI 未来的重要基建。

那它怎么导致了这次这个低级问题的出现？实际上这是一个构建脚本逻辑缺陷导致的“脏构建”问题，当 Flutter 构建依赖于 Native Assets（比如 `sqlite3` 等库）的 Plugin 时，这些原生资源会被编译并输出到 `build/native_assets/$platform` 目录（例如 `build/native_assets/ios`）。

因为在现有的构建脚本（`xcode_backend.dart`）在打包时，会简单粗暴地将 `build/native_assets/ios` 目录下的**所有**框架复制到最终的 App Bundle (`Runner.app/Frameworks`) ，例如：

- 先运行了模拟器跑应用，这时模拟器专用的框架（如 `sqlite3arm64ios_sim.framework`）就会被生成并留在了 `build/native_assets/ios` 目录

- 接着，开发者在**没有运行 `flutter clean`** 的情况下，直接运行了 Release 构建
- 构建脚本会把之前遗留的“模拟器框架”也一并复制进了 Release 包
- App Store 检测到 Release 包中含有模拟器架构的代码，因此拒绝接收

![](https://img.cdn.guoshuyu.cn/8884c0e3fa1c1884895c2235e0b6a1b1.png)

而且，其实这个问题是存在两个 Bug ，目前 Fix 的 PR 也都已经合并，开发者处理思路有：

- 存在 native assets 的
  - 使用 main - `flutter channel main`
  - archiving 之前，使用 `flutter clean` 和 `flutter build ios --config-only`
- 没有使用  native assets 的:
  - 使用最新 `flutter channel main`
  - 使用稳定版 `flutter channel stable`

> 因为第二个 bug 是某个 beta 版本弄出来的。

所以，这也是一个草台版本的 bug ，但是带来的影响还是很坑的，毕竟提交的时候才发现版本不行，而且找起来也很麻烦，虽然解决很容易，但是恶心层度贼高。

> 详细可见：[《Flutter 3.38.1 之后，因为某些框架低级错误导致提交 Store 被拒》](https://juejin.cn/post/7591350620189360134)

# iOS 键盘问题

又是 iOS ，这次还是 iOS 26 问题，Flutter 在 iOS 26 上，某些场景会因为出现半透明键盘，而页面底下本来应该被键盘遮挡的 Widget，由于默认没有被绘制，从而出现键盘背景颜色 UI 异常：

![](https://img.cdn.guoshuyu.cn/32f9cdb5-9073-4512-9e63-09f3bf8d195a.png)

虽然问题看起来是一个圆角问题，但是实际上这是 **iOS 26 系统键盘增加了“半透明”后带来的问题，Flutter 在键盘后面那一层在某些场景下没有正确渲染内容**，导致键盘半透明区域透出来的不是底下 BottomSheet 的真实内容，而是一整块黑色区域。

> issue 提到问题，问题最明显的场景主要出现在 iOS 26 的 `showModalBottomSheet()` 下。

虽然问题看起来是一个圆角问题，但是实际上这是 **iOS 26 系统键盘增加了“半透明”后带来的问题，Flutter 在键盘后面那一层在某些场景下没有正确渲染内容**，导致键盘半透明区域透出来的不是底下 BottomSheet 的真实内容，而是一整块黑色区域。

![](https://img.cdn.guoshuyu.cn/image-20260124165819033.png)

当然，**正常大家使用输入框输入文本内容不会有什么问题**，甚至如果你用 Dialog 场景也不会有什么问题，它主要出现在默认有底色场景的类似 `BottomSheet` 这种场景，所**针对问题其实可以选择配置 `UIDesignRequiresCompatibility = YES` 来解决，或者替换为 Dialog 来绕过场景**，但是如果要等官方修复这个场景，可能会需要等待评估是否真的有必要大规模底层改动。

这个问题就在于，官方是真的在考虑是否大规模修改底层来解决问题，毕竟按照之前的尿性，如果真的为了这个大规模修改底层，那么 issue 生 issue ，解一送十也不是不可能。

![](https://img.cdn.guoshuyu.cn/image-20260124170013289.png)

> 详细可见：[《Flutter 又迎大坑修改？iOS 26 键盘变化可能带来大量底层改动》](https://juejin.cn/post/7596245612558319625)

# 最后

看了 2025 的年度大坑回顾，不知道有没有你踩过的共鸣？但是这只是一些比较典型或者恶心的，其他琐碎小问题其实也不少，但是好在 Flutter 也有在积极解决这些大坑，不过可以看出来 iOS 26 确实带来了不少问题，很多问题也不是 Flutter 特有的，RN 和 KMP 也不可避免，**只能说平台升级带来的坑是真不少**，不然你看，谷歌看 Android 16 没带来什么大问题，所以给大家准备了 AGP 9 整整 KPI ，多贴心：

> [Android Gradle Plugin 9.0 发布，为什么这会是个史诗级大坑版本](https://juejin.cn/post/7597900782910685203)

那么，2025 你遇到过什么坑呢？