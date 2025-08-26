# Google I/O Extended ：2025 Flutter 的现状与未来



大家好，我是 Flutter GDE 郭树煜，Github GSY 项目的维护人，今天主要分享的内容是「Flutter 的现状与未来」，可能今天更多会是信息科普类型的内容，主要是分享关于 Flutter 的现状与未来

![](https://img.cdn.guoshuyu.cn/image-20250707084543577.png)

# 现状

其实 Flutter 从开源到现在一直以来“争议”还是比较多的，但是开源到现在也有 8 年时间了，如果从内部立项看，去年也已经过了十周年，官方去年也发过十周年的纪念内容，所以兜兜转转到现在，其实 Flutter 已经不算是一开始一样的小众框架了，比如在国内大厂，它可能不是主力框架，但是也开始融入到各个地方，比如这张图，我们可以看到不少熟悉的身影：

![](https://img.cdn.guoshuyu.cn/image-20250523152007309.png)

当然，在中小企业内的比例就更高一些，比如 2025 年 6 月腾讯统计了当前市面上应用热门跨平台框架 Flutter、RN 使用情况

- Flutter 整体渗透率约 13%，在旅游类应用渗透率最高（29.5%）
- React Native 整体渗透率约 9%，在旅游类产品渗透率最高（18.2%）

| ![image-20250625093911474](https://img.cdn.guoshuyu.cn/image-20250625093911474.png) | ![](https://img.cdn.guoshuyu.cn/image-20250625093919744.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

> 可以看到 Flutter 最多应用在工具类，而 RN 最多应用于购物类，数据来自 [腾讯端服务](https://mp.weixin.qq.com/s/OjOiq70zYDTp6WLWJf4dAg)

另外对于 Flutter 在国内的影响还有鸿蒙，自从 2024 年鸿蒙 Next 发布之后，Flutter 也引来了新的进程，由华为主导的跨平台框架适配鸿蒙 Next 里，Flutter 是最早开源的，而后期华为也针对 Flutter 适配鸿蒙做了许多工作，例如 Impeller 的移植支持：

![](https://img.cdn.guoshuyu.cn/image-20250627130523585.png)

而之所以会这样，其中一部分原因就是，也是早期 ArkUI 在底层渲染设计就参考了 Flutter ，甚至有不少以 Flutter 命名，另外其系统的构建基座（GN/ninja）都和 Flutter 十分贴合。

华为近期也提到过，目前鸿蒙 TOP 应用中 40%采用跨平台三方框架，其中主流就主要以 Flutter、RN 等框架为主，所以可以看到鸿蒙也是为 Flutter 提供了全新的开发场景：

![](https://img.cdn.guoshuyu.cn/image-20250624103509178.png)

而提到鸿蒙这里就不得不提微信，前面我们看到微信有使用 Flutter，而微信在鸿蒙 Next 的应用上，也有部分页面是通过 Flutter 进行适配，例如 ArkUI Inspector 下可以看到微信的朋友圈是 Flutter 实现：

![](https://img.cdn.guoshuyu.cn/image-20250610171300597.png)

另外，在之前微信小程序的 skyline 的渲染引擎，也可以看到是基于 Flutter 的身影：

![](https://img.cdn.guoshuyu.cn/image-20250627134903958.png)

> ·`read dependencies for .../libskyline.so from cache or meta：` 就记录了 libskyline.so 的依赖库

当然，这还不是 Flutter 应用最意向不到的地方，你甚至可以在 OPPO 的 ColorOS 的灵动岛在运行时的输出上，可以看到此时 ColorOS 灵动岛的 UI 渲染也是基于 Flutter 实现的：

![](https://img.cdn.guoshuyu.cn/image-20250610171108909.png)

还有 OPPO 的开发平台上， 也可以看到过负一屏相关的 log 截图，相关输出也是 Flutter：

![](https://img.cdn.guoshuyu.cn/image-20250610171119171.png)

前面提到的这些 Flutter 应用场景，上层使用的都是不是 Dart ，只是在底层使用了 Flutter 渲染引擎，类似的我还看到过有一个叫 Shaft 的项目，他用 Swift 重构了 Flutter 的上层，替代了 Dart ，这些也都是 Flutter 的另类应用。

而如果再看一些新的全球使用案例，对应的有：

- **NotebookLM** ：Google 旗下的AI笔记应用，但是在播客圈爆火，能将音频源转化播客的对话，之前一直是 Web，而刚刚推出的 App 采用了 Flutter 开发
- **Google Cloud**：新的 Cloud Assist 采用 Flutter 编写，另外类似 Google Pay，Google Classroom，Google One 也是
- **Universal**：环球的主题公园的 App 
- **teamLab**: 东京的博物馆 App
- **GE Appliances:** 通用电气设备的嵌入式领域
- **LG**：去年说过的 LG 电视 webOS 使用了 Flutter ，今天计划推出全新的 webOS-Flutter SDK 
- **Canonical **：Ubuntu 的维护和支持企业，将 Flutter 用于 Ubuntu 的第一方应用市场，并且 Flutter 现在在 PC 端的需求，例如的多窗口等需求，都是由其提供支持

![](https://img.cdn.guoshuyu.cn/image-20250707084714721.png)

另外， Flutter  技术服务公司 VGV，在和 ‌ Trackhouse Racing 建立战略合作并提供技术支持的同时，还赞助了 NASCAR  比赛的 99 号雪佛兰赛车，把 Flutter Logo 也打到了车头上，从这点看，也有以 Flutter 为技术服务过的还不错的公司：

![](https://img.cdn.guoshuyu.cn/image-20250707084733317.png)

而根据  *Apptopia*  的统计数据，2024 年 AppStore 里 Flutter 占据所有新免费 iOS 应用的近 30% ，虽然这个数据已经不是很亮眼了，但是在如今这个市场环境下还算可以：

![](https://img.cdn.guoshuyu.cn/image-20250707084810077.png)

而对于 Dart ，根据 JetBrains 的统计，过去五年的受众增长上， Dart 在跟上了前十的位置，而 Dart 基本都来自 Flutter 开发，所以这也可以看出这些年 Flutter 的一个增长趋势：

![image-20250523135554376](https://img.cdn.guoshuyu.cn/image-20250523135554376.png)

事实上，Dart 一直都一门保守的语言，它的新特性增加都十分克制，如果真要说开发体验，肯定是不如 Kotlin ，但是它的好处在于，可以完完全全贴合 Flutter 的需要去调整，完全属于 Flutter 的形状，而自从 2021 全面支持空安全之后，这些年来也陆陆续续增加了不少新特性，比如这次 I/O 发布的 Dart 3.8 ，就新增了可识别空值的元素（Null-aware elements ）支持：

![](https://img.cdn.guoshuyu.cn/image-20250618084821827.png)

 这个语法糖可以用于在 List、Set、Map 等集合中处理可能为 null 的元素或键值对，简化显式检查 null 的场景：

| ![carbon](https://img.cdn.guoshuyu.cn/carbon.png) | ![](https://img.cdn.guoshuyu.cn/carbon%20(1).png) |
| ------------------------------------------------- | ------------------------------------------------- |

最后，Dart 3.8 也开始尝试交叉编译支持，目前暂时新增了从 Windows、macOS 开发机器编译为原生 Linux 二进制文件的支持，这个支持也可以更多用于对嵌入式平台的支持，虽然暂时还不应用官方，但是交叉编译对于 Dart 来说确实是一个不错的补充：

![](https://img.cdn.guoshuyu.cn/image-20250521083103699.png)![](https://img.cdn.guoshuyu.cn/image-20250619154309169.png)



# 3.32 和未来

本次 I/O 发布的 Flutter 3.32 其实并不算是一个很大的版本更新，但是它带来了几个关键的东西。

##  Property Editor

第一个就是 Property Editor，它需要 Flutter 3.32+ 才支持使用，属于 IDE 增强工具，可以直接在可视化界面查看和修改 Widget 属性：

![](https://img.cdn.guoshuyu.cn/image-20250619141930500.png)

简单来说，就是**开发者可以快速发现和修改 Widget 的现有和可用的参数，不需要跳转到定义或手动编辑源代码**，而在 Property Editor 中选择一个 Widget 时，它对应的文档会显示在顶部，可以直接阅读 Widget 文档无需跳转：

![](https://img.cdn.guoshuyu.cn/ab5494e12bff973ffae273768296d264.gif)

比如可以看到，你修改的参数，可以会同步到代码和运行中的程序里：

![](https://img.cdn.guoshuyu.cn/studio_video_1750313067640.gif)

当然，这个功能单独来看并不是十分实用，可支持的属性也比较少，但是如果能够搭配后续的 master 的控件实时预览，那么整体实用性就可以提高不少，目前 Widget 预览功能已经在 master 可以体验：

![](https://img.cdn.guoshuyu.cn/361e4800d54c9df7176ccd3ca643f0be.gif)

而 Flutter Widget Preview 之所以正式开始推进落地，核心主要于 Flutter Web ：

- html render 移除后，Flutter 在 Web 端统一了 canvas 渲染实现
- Flutter 3.31 beta 开始支持 Web hot reload

![](https://img.cdn.guoshuyu.cn/93f4ffcabe81b51eb7887ec54af5e6db.gif)

所以，可以简单理解，控件预览就是在项目的 `.dart_tool` 目录下生成一个预览工程，并通过 Flutter Web 的方式进行渲染，所以整体可交互程度也会比较高。

## 合并线程

在 3.32 开始， Windows 和 macOS 也开始支持合并 Dart UI 线程和平台线程，这个合并其实从 3.29 就开始了，而它的最终目标肯定就是在全平台上都让 Dart UI 线程和平台线程合并统一。

而之所以会有这样的改动，是因为之前 Flutter 里的运行机制：isolate、 Thread、Runner ，简单说就是：

- Dart 代码都是运行在某个 isolate 里面，比如我们入口的 main 就是运行在 root isolate 里，也是我们 Dart 代码的「主线程」
- isolate 和线程之间的关系并非 1:1 ，只是执行的时候需要一个线程来完成
- Runner 其实是 Flutter 上的抽象概念，它和 isolate 其实并没有直接关系，实际上 Engine 并不在乎 Runner 具体跑在哪个线，对于 Flutter Engine 而言，它可以往 Runner 里面提交 Task ，所以 Runner 也被叫做 TaskRunner，例如 Flutter 里就有四个 Task Runner（UI、GPU、IO、Platform）

![image-20250619144138715](https://img.cdn.guoshuyu.cn/image-20250619144138715.png)

而在 Android 和 iOS 上，以前会为 UI，GPU，IO 分别创建一个线程，其中 UI Task Runner 就是 Dart root isolate，也就是 Dart 主线程， Platform Runner 其实就是设备平台自己的主线程。

所以，在过去 **Flutter 的 UI Runner 和平台的 Platform Runner 是处于不同线程**，其中 Dart 的 root isolate 会在被关联到 UITaskRunner 上。

![](https://img.cdn.guoshuyu.cn/image-20250707085559861.png)

而现在两个线程被合并了，说人话就是： `UI Runner = Platform Runner ` ，首先这个调整比较大，但是不那么麻烦，因为前面我们说过，Runner 其实并不关心你跑在哪个线程，所以实际上切换的时候，就是让 Runner 关联到对应的 MessageHandler 线程即可。

> 用于处理 isolate message 的 event loop 的默认实现，实际就是没有一个专用的事件循环线程，而是在有新消息到达时将 `dart::MessageHandlerTask` 发布到线程池。

为什么要这么做？其实原因就是，在此之前，Dart 和平台之间跑在不同线程，Dart 调用平台 API 都需要通过 MethodChannel 的异步交互，不管是在性能和交互便捷性上都不尽人意。

而现在跨平台开发里，这类型调用都开始支持同步调用了，比如 RN 就支持同步平台互操作的能力，而对于 Flutter 来说，通过 ffigen 和 jnigen ，也可以实现 dart 和 oc 和 java 的同步调用，但是这里面有个基础前提，那就是 dart 和平台需要在同一线程，所以线程同步就这么提上了日程。

当然，合并我那线程后，也带来了一些问题，比如：

- 在 Android 断点开发时，断点 Dart 代码现在会导致 ANR 弹框，因为以前断点 dart 并不会阻塞 UI 线程，所以并不会触发 ANR ，但是现在同个线程后，这个 ANR 频率有些感人
- 一些原生 Plugin ，以前写的逻辑占用了部分主线程，但是因为和 Dart 线程是分开的，所以造成的卡顿不明显，但是合并线程后，导致的卡顿掉帧就十分明显
- 因为线程合并之后，启动引擎、应用和设置 Dart 代码都运行的平台线程上，会导致第一个可交互帧的时间变长，而针对这个，Flutter 也增加了 Engine 会在单独的 Dart UI 线程上启动引擎，然后在引擎初始化后会将 UI 任务移至平台线程合并，从而改善应用启动延迟的问题

最后，合并线程可以让 App 使用 Dart FFI 与原生 API 进行直接互作了，例如在 Windows 上启用了合并线程，**开发者就可以使用 Dart FFI 通过 win32 API 直接调整应用窗口的大小** ，而不需要走繁琐的 Channel。

![](https://img.cdn.guoshuyu.cn/image-20250707085633595.png)

所以，线程合并的主要目的，是为了抛弃历史产物 MethodChannel，而在互操作这件事情，未来肯定是 Dart 和平台语言直接互调用，而 3.32 也提到了，ffigen/jnigen 也在持续改进并内测，预计下半年会有全新的消息。

## 多窗口

多窗口相信也是许多 Flutter 开发者关心的，而目前官方的多窗口功能已经可以在对应的 PR 上去编译体现，以下是我在 windows  和  macOS 上的试用体验：

![](https://img.cdn.guoshuyu.cn/909aada223a2c7c8e1786de75ce49465.gif)![](https://img.cdn.guoshuyu.cn/ba7ae4ca5c9ffda3b798cfa5856b9d13.gif)

其实这里有个有趣的地方是，目前多窗口是由 Ubuntu 团队在推进支持，但是最先支持的是 windows ，然后 macOS ，目前 Linux 进度是最落后的，这也是这里面比较有趣的地方。

目前体验下来，Windows 上的性能还过得去，而在 macOS 上暂时的性能会差一些，因为 Flutter 一直以来都是单窗口设置，而在多窗口下，需要实现的单一 Engine 在渲染多个视图时，光栅线程、UI 线程和 GPU 访问权限等资源必须被共享或复用，这导致了在处理多个渲染目标时内部存在「竞争」或「低效调度」等问题，比如：

> 一个视图的光栅化阻塞了另一个视图等情况，所以需要改进 UI 和光栅线程之间的并行化支持。

目前基于线程合并的推进，多窗口也开始支持 ffi 版本的实现，基于 ffi 版本整体的性能体验也会更好一些。

## iOS 26

iOS 26 的液态风格也是近期 Flutter 上的热门话题，比如 RN 用的是原生控件，所以它可以很方便就用到液态玻璃的特性，而 Flutter 是自渲染，所以存在特性兼容成本。

目前其实已经有不少开发者通过着色器在 Flutter 上复现了相应的 UI 和 UX 效果，目前体验下来，有不少实现的还原度和体验还是相当不错的：

| ![](https://img.cdn.guoshuyu.cn/286cef5cb0a33c426aae0d2767c4e833.gif) | ![](https://img.cdn.guoshuyu.cn/ezgif-1cf390045b3b08.gif) | ![](https://img.cdn.guoshuyu.cn/4a9e2721ee5f2f657bebbdf864be7e7d.gif) | ![](https://img.cdn.guoshuyu.cn/ezgif-1b8f8df0b39f35.gif) | ![](https://img.cdn.guoshuyu.cn/ezgif-44ddd557acf5e7.gif) |
| ------------------------------------------------------------ | --------------------------------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------- | --------------------------------------------------------- |



当然，这里想说的是，对于 iOS 26 的液态玻璃实现，官方已经明确了不会内置支持，甚至连 Android 的最新  Material 3 Expressive 也是，因为恰好在 Android 和 iOS 的设计风格大变的节点， Flutter  官方打算推动一个酝酿许久的计划：移除 Cupertino 和 Material 的内置：

![image-20250611084251881](https://img.cdn.guoshuyu.cn/image-20250611084251881.png)

事实上这也是社区一直以来大家的话题，就像近期的 Flutter 更新里，总是包含了许多 Cupertino 风格的内置更新，包括本次 I/O 的 3.32 也是，但是作为平台风格控件，社区更多认为，它在设计上不应该内置在 Framework 。

Flutter 是一个跨平台的自渲染控件，它的核心竞争力主要是多平台统一的渲染能力，这也是它和 RN 之间的最大区别，RN 大多数情况下是保留了平台的特性效果，这明显是两个不同的需求，而官方应该更多集中精力在渲染性能和稳定性支持上。

当然不是说就完全放弃平台特色控件的支持，而是它更多应该是一个外部依赖包推进，而不是在 Framework 里内置去跟进，抽离出来独立的特色 Package 也能更好推进特性开发，现在 Framework 里，一个简单的 UI 性质调整，光跑 test 可能都要 30 分钟，而且 merge 要应对的 ci 、reivew和冲突也十分繁琐，导致这类特性推进成本偏高。

所以抽离出特色控件，也是为了后续可以更快捷跟进实现，iOS 26 的出现，无疑推动了 Flutter 对抽离特色控件这件事的落地。

![](https://img.cdn.guoshuyu.cn/image-20250707085720580.png)



# 相关链接

- [Flutter 3.32 的 Property Editor 生产力工具](https://juejin.cn/post/7506590644543553548)

- [Flutter 3.32 发布](https://juejin.cn/post/7506408162736766991)

- [Dart 3.8 发布](https://juejin.cn/post/7506414257400053799)

- [Dart & Flutter momentum at Google I/O 2025](https://medium.com/flutter/dart-flutter-momentum-at-google-i-o-2025-4863aa4f84a4 )

- [Flutter Widget Preview 功能已合并到 master](https://juejin.cn/post/7522006762512039955)

- [Flutter 上的 Platform 和 UI 线程合并](https://juejin.cn/post/7474503566154219560)

- [Flutter 官方多窗口体验](https://juejin.cn/post/7510701347072344105)
- [腾讯端服务-腾讯APP如何实现功能无感升级](https://mp.weixin.qq.com/s/OjOiq70zYDTp6WLWJf4dAg)
- [京东零售技术-行业专家齐聚 | 共探跨端动态化新态势]()






