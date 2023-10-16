# Flutter 与 Dart 的市场应用

> 本文来自《2023年中国谷歌教育合作项目---武汉城市学院---面向Flutter框架的Dart语言师资培训与教学研讨》内容文字版。

Hello，大家好，我是 Flutter GDE 郭树煜，也是《Flutter 开发实战详解》的作者，同时也是 Github GSY 项目的负责人，这些年主要致力于 Flutter 相关的开发和创作，平常主要活跃在国内掘金技术社区和知乎等平台。

本次分享的主题是 Flutter 和 Dart 的市场应用，也就是我们不会太过于针对某个技术点做深度展开，主要是从 Flutter 的角度出发，帮助大家更全面地去了解 Flutter 和 Dart。

**也希望可以通过一些大家平时并不关注的东西，来帮助大家重新认识 Flutter 和 Dart** 。

> ⚠️内容超长超长！！！

# 为什么 Flutter 要选择 Dart

相信大家对于 Flutter 都有过这样一个疑问：**为什么 Flutter 要选择 Dart** ？这是大多数人早期接触 Flutter 时应该都会有的一个疑问。

确实，**Dart 一开始并不是为了 Flutter 而存在**，Dart 亮相于 2011 年，但是在 Web 领域竞争失利之后，它就被 Google 「雪藏」了，直到 2017 年 Google I/O 正式向外界公布了 Flutter 之后，Dart 作为其主要开发语言再次走去大众的视野。

说到这个问题，就不得不要先聊一聊  Flutter 的起源，也挺有意思，大家都知道早期 Flutter 最先支持的平台是 Android 和 iOS ，**但是事实上 Flutter 其实起源于 Google 内部的前端团队**。

> Flutter 来源于前端 Chrome 团队，起初 Flutter 的创始人和整个团队几乎都是来自 Web 项目组，在 Flutter 前负责人 Eric 的相关访谈中说过， Flutter 来自 Chrome 内部的一个实验，他们把一些乱七八糟的 Web 规范去掉后，在一些内部基准测试的性能居然能提升 20 倍，因此 Google 内部就开始立项，所以 Flutter 出现了。

所以这也是为什么早期 Dart 语言的语法糖很少，风格比较保守的原因之一，**因为它所服务的 Flutter ，本身就是在去掉一大堆「规范」从而得到性能提升之后才诞生的项目**。

所以回到原来的问题上，Dart 起初也是为了 Web 而生，从诞生关系上说，Flutter 和 Dart 并不是毫无关系的存在。

当然，这并不是 Flutter 选择 Dart 的关键因素，**其实 Flutter 选择 Dart 最大的原因是因为 Dart 可以主动契合 Flutter 的脚步**：

> Dart 原本就是处于竞争失利的「雪藏项目」，所以它没什么历史包袱，**可以深度和 Flutter 项目绑定，跟进项目的发展**。

Flutter 需要什么 Dart 就可以立马提供支持，比如每个大版本和小版本，**从 vm 到编译到语法支持，都可以跟着 Flutter 需求的节奏来更新迭代**，例如 Flutter 3.10.3 在做小版本更新的时候，就绑定了大量 Dart 的修复，大家可以做到步伐一致，你更新时我也更新。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image1.png)

> 所以为什么 Flutter 选择 Dart ，因为 Dart 没有历史包袱，Dart 作为自己的一个产品存在，比起每次都去某个组织下反馈和推进问题，肯定是自家的「贫困兄弟」配合起来更舒服，例如类似的问题也在 Skia 上出现。

如果用过 Flutter 的应该知道，Flutter 现在选择自研 Impeller 渲染引擎来替代 Skia ，就是因为 Skia 有历史包袱存在，它不只是服务于 Flutter ，虽然它很好用，但是它「不完全是 Flutter 的形状」，所以 Impeller 的出现是 Flutter 后期维护的必然。

> 比如 Impeller 的替换也带来也不少新的问题，但是挺过来就会发现，它的收益会更大。

所以 Dart 也是如此，**挺过来了阵痛期，那么 Dart 的配合就会反哺 Flutter 的发展**，而 Dart 对于 JS 、Kotlin、Java 用户来说并不是什么门槛，所以选择 Dart 可以看作是当时 Flutter 对于未来的取舍。

用新项目来盘活一个凉了的项目其实也是 Google 擅长的操作，例如 Kotlin 也是搭上 Android 之后才开始提高了市场存在，例如在 IEEE Spectrum 上，IEEE 作为世界上最大的工程和应用科学专业组织，旗下 IEEE Spectrum 是 **IEEE 的旗舰出版物**

而 **Dart 居然在 2023 IEEE Spectrum 和 Trending 里超过了 Kotlin，接近 Swift，所以选择 Flutter 对于 Dart 本身也是一件好事** 。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image2.png)

另外再看  [TIOBE](https://www.tiobe.com/tiobe-index/)  2022 和 2023 的榜单，TIOBE 编程语言社区排行榜是编程语言流行趋势的一个指标，可以一定程度反应某个编程语言的热门程度，可以看到 Kotlin 从去年 的 28 位飙升到现在的 18 位，而 Dart 也从之前的 35 位晋升到现在的 31 位。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image3.png)

![](http://img.cdn.guoshuyu.cn/20231015_WH/image4.png)

> Dart 的持续成长离不开 Flutter ，而 Flutter 的发展也离不开 Dart 的配合，所以我们很多时候也可以简单戏称：因为 Dart 项目就在 Flutter 隔壁，方便沟通和调整，这并不完全是一句玩笑。

那么这些年，Dart 为了 Flutter 又做了哪些变化？除了我们都熟知的空安全支持，Dart 的 null safety 历经三年的时间，如今 Dart 终于有用了完善的类型系统，目前 pub.dev 上排名前 1000 的包中有 99% 支持空安全，那么针对 Flutter 适配，Dart 又有过哪些有意思的调整？

![](http://img.cdn.guoshuyu.cn/20231015_WH/image5.png)

##  isolate

我们知道，**isolate 是 Dart 里开启一个 ”真“ 异步任务的入口**，因为 Flutter 里 Dart 本身是一个单线程的任务轮询机制，而我们的 Dart 代码也是运行在一个独立的 isolate 里（简称 root isolate），在不开启一个新的 isolate 的时候，我们的 async 异步代码都只是一个线程上的任务轮询。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image6.png)

也就是，如下所示代码来看，我们通过 `async` 这样的关键字去实现一个异步解析 json 文件，但是在执行 `jsonDecode` 的时候，如果 json 内容比较巨大，其实它就会影响到 Flutter 里正常的 UI 渲染造成卡顿，因为他占用的还是单线程的资源。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image7.png)

而如果需要开始一个 ”真“ 异步任务的话，也就是要开启一个新的线程操作的话，就需要创建一个新的 isolate ，**但是 isolate 之间不共享内存**，只能通过 port 等方式在 isolates 之间交换状态，所以 Dart 也不需要 Java 一样需要线程锁去做互斥，不过就是数据传输效率较低。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image8.png)

>  如代码所示，但是此时的 isolate 还不支持传递自定义对象，它只可以传递基础数据类型。

而在 Dart 2.15 里新增了一个叫 isolate groups 的概念，**isolate groups 中的 isolate 共享程序里的各种内部数据结构**。

也就是虽然 isolate groups 还是不允许 isolate 之间共享可变对象，但 groups 可以通过共享堆来实现结构共享，比如可以将对象从一个 isolate 传递到另一 isolate，这样就可以用于执行需要返回大量内存数据的任务：

> 例如通过网络调用获取数据，将该数据解析为一个大型 JSON 对象，然后将该 JSON 对象返回到主isolates，这种实现在 Dart 2.15 之前执行该操作需要“深度复制”，如果复制花费的时间超过帧预算时间，就可能会导致 UI 卡顿。

如下代码对比，也就是以前你的 json 在 decode 之后，还需要回到 root isolate 进行实体对象填充，但是有了 isolate groups 之后，你就可以在新的 isolate 上完成整个 json 解析和填充对象的事情。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image9.png)

这个功能的作用带来了什么？如今在 isolate groups 中启动额外的 isolate 可以快近 100 倍，因为现在不需要初始化程序结构，并且产生新的 isolate 所需要的内存减少了 10-100 倍。

**这个改变对于 Flutter 有什么意义**？

而在 Flutter 3.7 发布时， Flutter 增加了  background isolate 的支持，在 Flutter 3.7 之前，在 Flutter Plugin 里 Dart 和原生代码交互的时候，我们只能从 root isolate 去调用 Platform Channels ：

> 这个 Platform Channels 就是 Dart 调用原生代码去执行某些操作，比如调用相册读取图片，然后返回选中的图像路径或者数据。

如果你尝试从其他 isolate 去调用 Platform Channels ，就会收获这样的错误警告，表示对应的一些服务并没有初始化。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image10.png)

> 这是因为在 Flutter 3.7 之前，Platform Channels 需要和一个叫 `_DefaultBinaryMessenger ` 这个全局对象进行通信，但是一但切换了 isolate ，因为 Dart 不共享对象，它就会变为 null ，因为 isolate 之间不共享内存。

而从 Flutter 3.7 开始，简单地说，Flutter 会通过新增的 BinaryMessenger 来实现非 root isolate 也可以和 Platform Channels 直接通信，例如：

> 我们可以在全新的 isolate 里，通过 Platform Channels 获取到平台上的原始图片后，在这个独立的 isolate 进行一些数据处理，然后再把数据返回给 root isolate ，这样数据处理逻辑既可以实现跨平台通用，又不会卡顿 root isolate 的运行。

如下所示， background isolate  逻辑也很简单，就是在 root isolate 里获取 `RootIsolateToken` ，然后在调用 Platform Channels 之前 `ensureInitialized` 关联 该 Token ，就可以实现跨 isolate 的 Platform Channels 调用。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image11.png)

**这就是 Background isolate 的使用场景，而这离不开 Dart 在 isolate group 的改进和支持的基础上去实现**，这里之所以可以在 isolate 里直接传递 `RootIsolateToken` ，就是得益于前面所说的 Dart 2.15 的 isolate groups

所以从这个例子可以看到，Dart 可以为了 Flutter 针对去做一些调整和配合，这也是为什么 Flutter 愿意选择 Dart 的原因之一。

而这个调整，也让 Flutter 的 Platform Channels 可以从任何 Isolate 进行 invoked ，从而提高了 Flutter 的平台执行效率。



## Dart FFI

我们再来一个例子，就是 Dart FFI ，Dart 可以通过 FFI 实现 Dart 与 C 的相互调用，这是 Dart 在 2.10 版本作为稳定支持发布的一个能力，**该能力让 Flutter 在使用接入动态库时不再需要间接通过 Channels 异步调用，而是可以直接通过 Dart 同步调用C API** 。

比如在接入数据库场景，Dart 可以直接同数据库进行交互，这样可以让 Dart 的数据库能力和平台无关，甚至可以让对应 Dart 数据库能力拓展到 Dart 后端服务支持，例如现在 Flutter 常用的数据库包 sqlite3、Realm、ObjectBox、Hive、isar 等都是通过 Dart FFI 实现，所以它在支持全平台的同时，也可以脱离 Flutter 运行。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image12.png)

当然，这里还并不能特别体现出 Dart 和 Flutter 的配合，而在后续 Dart 2.18 的时候预览了 Dart 与 Objective-C / Swift  直接交互的支持，同时接着又开始测试 Dart 与 Java / Kotlin 直接交互的支持。

**因为 Flutter 是全平台的 UI 框架，所以 Dart 团队希望支持所运行平台上所有主要语言的直接交互能力**，例如：

> 在 2.18， Dart 代码可以直接调用 Objective-C 和 Swift 代码，这可以用于调用 macOS 和 iOS 平台上的 API 而无需通过 Channel 转化。

举个例子，在 OC/Swift 上 Dart 目前用的是 ffigen，我们首先在   `pubspec`  文件引入对应依赖：

![](http://img.cdn.guoshuyu.cn/20231015_WH/image13.png)

我们创建一个 `config.yaml` 文件以包含  `ffigen`  配置，配置指向头文件，并列出了哪些 Objective-C 接口应该生成包装器，指定需要输出的 dart 文件名：

![](http://img.cdn.guoshuyu.cn/20231015_WH/image14.png)

> 注意这里的  `entry-points` 路径需要安装  CommandLineTools ，可以通过 xcode-select install 命令来安装。

配置里  `NSTimeZone.h`  中的 headers 选择 Objective-C 绑定，并仅包括 `NSTimeZone ` 接口中的 API，之后运行命令，生成绑定 dart 文件。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image15.png)

该命令会创建一个新的 `foundation_bindings.dart`  文件  ，其中包含一堆生成的 API 绑定，如图可见高达 2000 多行：

![](http://img.cdn.guoshuyu.cn/20231015_WH/image16.png)

之后使用该绑定文件就可以得到我们想要的调用，如下代码所示，通过引入文件之后，我们就可以通过这个 dart 文件直接调用 OC 里的系统方法，通过  `dart run timezones.dart`  就可以直接执行对应的 OC 方法得到结果：

![](http://img.cdn.guoshuyu.cn/20231015_WH/image17.png)

![](http://img.cdn.guoshuyu.cn/20231015_WH/image18.png)

类似的在 Android 平台， Java 上 Dart 目前用的是 jnigen ，流程上有异曲同工，只是采用的是 jni 方法，同样支持 Dart 和 Java 支持交互：

![](http://img.cdn.guoshuyu.cn/20231015_WH/image19.png)

所以可以看到， Dart 在自身发展的过程中，都可以很便捷地跟随 Flutter 的节奏进行优化，不管是 isolate 还是 FFI ， Flutter 需要什么，Dart 就提供什么，这就是为什么 Flutter 选择 Dart ，因为 Dart 可以为了 Flutter 而走出改变。

## Dart  WebAssembly Native

最后再聊一个还没完全发布的支持，因为需要一个叫  WasmGC 的东西，所以目前是以预览形式提供支持。

要将 Dart 和 Flutter 编译为 Wasm Native 需要一个支持 WasmGC 的浏览器，Wasm 标准计划添加 WasmGC 来帮助 Dart 等垃圾收集语言高效地执行代码。

这是一个相对庞大的工程周期，因为它需要引入一个 WasmGC 的垃圾回收协议，然后集成到各大浏览器，如下图所示，一直以来 Flutter 对于 WebAssembly 的支持都是：使用 Wasm 来处理 CanvasKit 的 runtime，而 Dart 代码会被编译为 JS，而这对于 Dart 团队来时，其实是一个「妥协」的过渡期。



![](http://img.cdn.guoshuyu.cn/20231015_WH/image20.png)

因为首先不管是 `main.dart.js` 和 `canvaskit.wasm` 文件都会相对较大，这对 web 场景来说是很致命的，其次转化与执行效率也是一个瓶颈，但是一旦有了   WasmGC  ，浏览器原生支持之后，Dart 完全可以编译为 `main.dart.wasm` ，另外只需要一个 `skwasm.wasm` 的桥文件，这样不管是体积还是执行效率都可以得到改善。



![](http://img.cdn.guoshuyu.cn/20231015_WH/image21.png)

这是为了 Flutter 的 Web 场景，Dart 团队原因配合去推进 WasmGC ，同时把自己变成 WebAssembly Native 的支持， 除此之外，Dart 团队正在研究启用[静态元编程](https://github.com/dart-lang/language/blob/master/working/macros/feature-specification.md)，这种强大的机制允许一段代码（宏）在程序编译期间修改和扩展程序的源代码，**例如可以减少反序列化 JSON 或创建数据类所需的样板文件**。

从以上种种都可以看出 Flutter 和 Dart 默契的脚步。

# Flutter 的应用现状

接着我们聊聊 Flutter 的应用现状， 说起 Flutter 可能一开始大家会觉得，这就是一个小众的跨平台框架，而现在已经 2023 年下半年了， 我们回过头再来看一看， Flutter 是否还是小众。

2023 年 10 月 8 号数据，这是我个人 50 多款 App 里关于跨平台框架使用的情况，主要依据是 Android App 里是否携带了  `libflutter.so` 、`libreactnativejni.so`、`lisweexjsb.so`  动态库，所以只能说 App 里有用到对应框架，不能说 App 就完全是基于 Flutter 开发，因为有不少 App 内采用了不止一种跨平台框架，这在超级 App 的场景下很常见。

|                           Flutter                            |                         React Native                         | Weex                                                   |
| :----------------------------------------------------------: | :----------------------------------------------------------: | :----------------------------------------------------- |
| 链家、转转、优酷、**中国大学MOOC**、豆瓣、同花顺、美团外卖商家版、凤凰新闻、微信、起点读书、**智联招聘**、哔哩哔哩漫画、腾讯课堂、UC 浏览器、Keep、学习强国、闲鱼、携程、微博、百度网盘、唯品会、WPS、企业微信、阿里云盘、**钉钉** | 美团众包、爱奇艺、美团、**中国大学MOOC** 、大众点评、脉脉、小红书、安居客、得物、58、飞书、京东、米家、网易云音乐、**钉钉** | 优酷、**智联招聘**、**闲鱼**、**微博**、淘宝、**钉钉** |

可以看到，这个小样本里，就有 25 个手机 App 里发现了 Flutter 框架，基本都还是常见的 App ，所以不只是中小企业里，大企业里 Flutter 也有自己的生存空间。

另外在桌面端产品上，企业微信、钉钉、网易有道等也表示有一定投入使用，所以从 2023 这个时间节点上看， Flutter 在跨平台框架领域内已经不是曾经的小众框架，他其实从 2022 年开始就已经走入了「千家万户」。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image22.png)

这里特别要提到的是微信，它在前段时间发布了全新的小程序新渲染引擎 Skyline 的正式版，宣称加载速度提升 50% 以上，而网友通过抓包发现，确认是 Skyline 的渲染是 [flutter 绘制方案](https://link.juejin.cn/?target=https%3A%2F%2Fgist.github.com%2FOpenGG%2F1c71380dd1401b7c93d39294772344fe) 。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image23.png)

![](http://img.cdn.guoshuyu.cn/20231015_WH/image24.png)

> 这里说的是微信小程序使用 Flutter 渲染，**更主要是其渲染更加精细可控，同步光栅化的策略，可以更好解决局部渲染、原生组件融合**等问题。

当然，微信小程序使用的是 Flutter 的渲染模式，而不是 Futter 开发方式，开发依然是原来的微信套件，只是 Skyline 做了一层转化，这也是一些大厂对于 Flutter 常见的玩法之一。

类似的例子还有华为，比如说近期闹的沸沸扬扬的 OpenHarmony ，相信大家或者已经听说过，明年的 Harmony Next 版本将正式剥离 AOSP 支持，也就是鸿蒙上到时候没有了 AOSP 和 JVM ，只能采用华为提供给的 ArkTS 和 ArkUI 进行开发。

为什么要在这里举这样一个例子？因为**ArkUI 和 Flutter 之间的联系也是很密切**。

例如 ArkUI 的 framework [arkui_ace_engine ](https://link.juejin.cn/?target=https%3A%2F%2Fgitee.com%2Fopenharmony%2Farkui_ace_engine)，里面就可以看到很多熟悉的 Flutter 代码，**不过这里面有点特殊在于，这些代码都是用 C++ 实现的**，例如下图中的 `Stack` 的控件就和 Flutter 里的 Stack 大同小异。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image25.png)

![](http://img.cdn.guoshuyu.cn/20231015_WH/image26.png)

另外，除了 ArkUI 华为还开源了 [ArkUI-X](https://link.juejin.cn/?target=https%3A%2F%2Fgitee.com%2Farkui-x) ，**ArkUI-X 扩展了 ArkUI 框架让其支持跨平台开发，而这部分跨平台的底层逻辑，同样来自 Flutter 和 Skia 的支持**。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image27.png)

与 Flutter 不同的是，OpenHarmony 上层开发用的是 ArkTS 和 ArkUI，调用走的是 NAPI（Native API）的区别。

另外，目前 OpenHarmony 的 SIG 社区也开始着手让 Flutter 可以适配到 OpenHarmony 上运行，因为 Flutter 在 OpenHarmony 的 embedding 层面适配其实并不会很麻烦，毕竟两者之间并不疏远。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image28.png)

![](http://img.cdn.guoshuyu.cn/20231015_WH/image29.png)

**所以这个角度也表明了 Flutter 渲染模式确实比较优秀，就算抛开上层逻辑，底层的渲染管道模型也有很大的参考和使用价值**。

另外，其实官方 2023 年初的时候也提供过一份数据：

- Google Play 商店的数据，Flutter 开发的应用接近 700,000 
- Play 商店中五分之一的新应用使用了 Flutter

所以这也可以看出 Flutter 的整体热度优势，既然 Flutter 还保持有热度，那我们就需要对他有所了解，那接下来我们就来聊聊 Flutter 的优势是什么？

## Flutter 的优势

说到 Flutter 的优势就不得不提社区活跃，官方这些年的推荐节奏和迭代速度都十分稳定，特别是类似 Impeller 这种通过自研来解决 Skia 上无法推进的问题的实现，可以看出来 Flutter 官方的支持力度很高，例如：

- 1.12 推出了支持混合开发的 Add to App
- 1.17 iOS 开始支持 Metal 渲染
- 2.10 开始支持 PC 平台
- 3.0 开始支持全平台
- 3.10 开始发布 iOS  Impeller 正式版
- ·····

![](http://img.cdn.guoshuyu.cn/20231015_WH/image30.png)

另外 Github 社区也相当活跃，例如 **Flutter 3.13  就在短短三个月内合并了 724 个 PR ，单单这一个版本就合并了 55 名社区成员的首次提交，注意是首次提交**，从这里也可以看出社区的活跃度很高。

Statista 是**一个全球数据和商业智能平台**，广泛收集来自 170 个行业 22,500 个来源的 80,000 多个主题的统计数据、报告和见解，在 [statista](https://www.statista.com/) 的数据统计里：

- 2023 年全球增长最快的技术技能里 Flutter 排名第二
- 在 2019 年至 2022 年全球软件开发人员使用的跨平台移动框架中，也可以看到 Flutter 的快速增长和市场占有率
- 最后，在 2023 年 全球开发人员最常用的库和框架里， Flutter 也排进了前 10 

**从这些数据上可以看出，Flutter 并不再是一个小众的框架**。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image31.png)

![](http://img.cdn.guoshuyu.cn/20231015_WH/image32.png)

![](http://img.cdn.guoshuyu.cn/20231015_WH/image33.png)

而从技术层面看，Flutter 最大的优势就是直接与 GPU 沟通，这里可能我们就有必要简单回顾下跨平台的框架的发展：

- 最初的跨平台框架如 Cordova ，是通过 `WebView` 加载本地 h5 资源实现 UI 跨平台，然后 js bridge 和原生平台交互调用 Plugin 来实现原生调用
- 第二阶段是为了性能而出现的 React Native 和 Weex ，通过统一的前端标签控件转化为原生控件进行渲染，从而提高了性能，不过因为是通过原生控件渲染，所以存在 UI 会有一致问题和兼容适配的成本。
- 第三阶段出现在了 Flutter 上，Flutter 通过独立渲染引擎，利用 GPU 直接渲染控件，从而避免了代理渲染的性能开销，同时也保证了不同平台上 UI 一致。

因为 Flutter 里控件是直接通过 Engine 利用 GPU 渲染，所以它的控件做到了在不同平台所加即所得，**这样的实现大大提高了框架维护的成本，但是极大地提高了开发的效率和逻辑复用的能力**。

所以 Flutter 的优势总结很简单：**在性能还不错的同时，做到了 UI 平台无关的统一效果**。





## Flutter 的劣势

既然有优势那肯定有劣势，这个劣势才是我们更需要了解的，因为只有知道哪有不好，我们才能去针对性规避和解决问题，或者避免在这些场景使用 Flutter 从而减少踩坑的风险。

### 混合开发

**其实 Flutter 的局限很大程度来自它的优势**，因为这种独立渲染 UI 的实现，让 Flutter 的 UI 渲染树脱离了原生平台，这时候，如果你需要在 Flutter 里接入原生控件，那么接入成本和对性能的影响都会比较大。

事实上开发 App 就不可避免需要接入 WebView 、地图、广告、视频等原生 UI ，所以在很长一段时间， Flutter 每个版本都在为接入原生控件而努力调整，比如 Android 至今已经有个三次较大的 PlatformView 接入变化，目前基本上算是可以实现接入使用，但是还存在一些局限。

当然不是说 Flutter 在混合开发上接入平台 UI 的支持上完全不行，而是这种实现导致了接入成本变高，例如以典型的 Android 平台为例子，发展至今 Android 平台就已经拥有了三种混合开发的 PlatformView 支持：

![](http://img.cdn.guoshuyu.cn/20231015_WH/image34.png)

这里并不是支持类型多就代表好，反而是因为支持类型多导致了各种历史包袱和混乱的场景。

> 所以这里的难度在于，例如你需要把一个原生的按键渲染到 WebView 里面和前端标签混合到一起，这是不是很不可思议？毕竟把原生控件渲染进一个类似 unity 的引擎进行混合并不容易。

### 文字排版和文本输入

文字排版是一个需要长时间打磨的过程，从目前来看 Flutter 文本排版能力和文字输入交互能力还是偏弱，特备是一些功能原生平台已经支持的，Flutter 因为是平台无关的控件，所以都需要重新开发一遍，例如：

- 3.13 通过社区成员的 PR，在 iOS 上使用 TextField 才支持了字符识别

  ![](http://img.cdn.guoshuyu.cn/20231015_WH/image35.gif)

- Flutter 3.3 才增加了 `SelectionArea` 来支持文本选择，之后的 3.7   `SelectionArea`  支持键盘操作，知道 3.13 这个功能还存在 bug ，另外 Flutter 也是在 3.7 才支持了系统类似的文本放大镜能力。

  ![](http://img.cdn.guoshuyu.cn/20231015_WH/image36.gif)

说回文本输入，在 Android 上，**当输入法要和某些 View 进行交互时，系统会通过`View` 的  `onCreateInputConnection ` 方法返回一个 `InputConnection` 实例给输入法用于交互通信** ，整体流程并不会很长。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image37.png)

而在 Flutter 上明显就复杂不少，首先这里实现了一个 **InputConnectionAdaptor** ，它作为 `InputConnection` 的实现，用于输入法和 Flutter 之间的通信交互，然后通过 **TextInputChannel** 和 Dart 进行通信，最后将键盘输入的内容数据封装为 Map 传给 Dart 层，Dart 层解析显示内容。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image38.png)

所以在文本内容输入和获取上，Flutter 需要走更长的流程，并且更容易在内存中「遗留」用户的输入，比如输入的密码可能会保留一段时间才会被 GC ，例如下图就是在 Flutter 上输入一段文本 `abcd12345` 作为模拟密码输入，此时内存留残留的明文密码证实以为 Plugin 原生曾传递给 Dart 的 Map 数据的残留，这部分数据在传递之后没有立即被回收，导致残留在内容可能出现泄漏。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image39.png)

> 在文本输入和处理上，它走的路程更长，体验也相对容易出现问题。

### 内存占用较高

因为 Flutter 相当于另外运行了一套 Dart 虚拟机和一套渲染引擎，所以不可避免在和平台脱轨的时候，也增加了内存的占用，所以如果是将 Flutter 用于混合开发，那么内存管理与优化将会是一个问题，特别是如果你需要使用多引擎的时候。

官方和第三方也都提供了一些 Add-to-App 的支持，但是其实效果都不是特别理想，你可以简单理解， Dart VM 和 JVM 两者之间相互独立，此时两者之间的数据同步就存在成本，例如：

- 用户登陆状态同步
- 个人信息同步
- 图片缓存同步
- 用户状态同步
- 页面路由同步

如果中间实现做的不好，很容易出现原生层以后的信息，还需要在 VM 层保存多一分，同时多了一份独立的 Dart VM 和 Flutter Engine 也相对占用更多内存。

另外前面提到的路由也没同步，因为 Flutter 对于原生来说就是一个单页面。什么是“单页面”应用？也就是对于原生 Android 和 iOS 而言，**整个跨平台 UI 默认都是运行在一个 `Activity` / `ViewController` 上面**。

默认情况下只会有一个 `Activity` / `ViewController`， Flutter  默认情况下就是如此，原生平台只需要提供一个 `FlutterView` ，然后通过一个 `Activity`  承载就可回忆了，剩下都是由 Flutter 引擎自己完成，**所以一般情况下框架的路由和原生的路由是没有直接关系**。

举个例子，如下图所示，

- 在当前 Flutter 端路由堆栈里有 `FlutterA` 和 `FlutterB` 两个页面 Flutter 页面；
- 这时候打开新的 `Activity` / `ViewController`，启动了**原生页面X**，可以看到**原生页面X** 作为新的原生页面加入到原生层路由后，把 `FlutterActivity` / `FlutterViewController` 给挡住，也就是把 `FlutterA` 和 `FlutterB`都挡住；
- 这时候在 Flutter 层再打开新的 `FlutterC` 页面，可以看到依然会被原生页面X挡住；

![](http://img.cdn.guoshuyu.cn/20231015_WH/image40.png)

> 当然业界也有维护支持混合路由的框架，只是这样的维护成本和内存占用也会相对提升。

其实 Flutter 官方在将 Flutter 作为 Module 接入到原生 App 里的支持一直不高，因为类似的场景天然不大适合 Flutter ，当然不是说不能用，只是你需要接受不少客观存在的问题，例如内存问题就是其实之一，另外还有数据同步问题：

> 因为是独立的 VM ，所以数据同步，状态同步和共享也是一大成本所在。

所以还是回归到最初那个问题，混合开发模式下 Flutter 其实并不具备特别高的优势。

# Flutter 必须理解的概念

那么简单了解了 Flutter 的优劣之后，我们最后我们有必要顺便来讲讲 Flutter 里我们都必须知道的一些概念。

## Widget 的真相

如果大家用过 Flutter ，应该知道 Flutter 里的我们写的界面都是通过 `Widget` 完成，并且可能会看起来嵌套得很多层，为什么呢？

这里就要先简单说一下 Flutter 的一些基础信息，**在 Flutter 里有 `Widget` 、 `Element`、 `RenderObject` 、 `Layer` 等关键的核心设定**。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image41.png)

其中我们最常写的 **`Widget` 并不是真正的 View 实例**，这和我们以前用代码搭建 UI 有很大的区别。

`Widget`  是需要转化为对应的 `RenderObject  `才能绘制，而 `Element `是  `Widget` 和 `RenderObject`  关键的中间实例，我们日常 Flutter 开发里用到的 **`BuildContext` 就是 `Element` 的抽象对象**。

**所以在 Flutter 里 `Widget` 代码只是“配置文件”的作用，真正工作的实例是它内部对应的 `Element` 和 `RenderObject` 实体**。

Widget 里的变量都是 `final` 的，例如我们定义一个不是 `final` 的 value2 在 Widget 里，其实会有相应的警告和错误提示，它会告诉你，Widget 是不可变的，所以 Widget 每次改变都是重构，在一个不可变的对象里，定一个可变的变量会产生歧义，比如代码里的 value2 ，如果发生改变，其实会是一个新的  Widget ，而这里不加 final ，会让人以为这个变量能在当前 Widget 周期内发生变化。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image42.png)

所以 Widget 可以在使用时的被频繁构建，因为它不是真正干活的，**`Widget`承载的是 `RenderObject` 里绘制时需要的各种状态信息**。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image43.png)

这里举个简单例子，如图代码所示，我们定义了一个 text 的 Widget，然后分别在 4 个地方添加，并成功运行，如果是一个真正的 View ，是不可以同时在 4 个地方被加载。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image44.png)

![](http://img.cdn.guoshuyu.cn/20231015_WH/image45.png)

通过这个例子可以看到 `Widget` 并不是真正干活的，而主要负责绘制和布局的逻辑都在 `RenderObject` 。 **因为布局和绘制的主要逻辑都在 `RenderObject`**。

所以这也回到了最初的那个问题，为什么 `Widget` 会是这样的嵌套模式，因为其实它充当的是配置信息的作用，同时嵌套深度可能最终转化为布局和渲染状态时，只是多偏移了几个 `offset` 。

而在 Flutter 里 `RenderObject` 作为绘制和布局的实体，主要可以分为两大子类：`RenderBox` 和 `RenderSliver` ，其中 `RenderSliver` 主要是在可滑动列表这种场景中使用，而不同布局就是 `RenderBox` 场景。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image46.png)

他们才是真正负责绘制和布局的实例，例如 RenderBox 的布局里，**一般情况 Flutter 里的大小布局是从上往下传递 `Constraints` ，从下往上返回 `Size` 这样的流程**。

![image-20231008150202922](http://img.cdn.guoshuyu.cn/20231015_WH/image47.png)

简单理解这句话就是：父容器根据布局需要往下传递一个约束信息，而最子容器会根据自己的状态返回一个明确的大小，如果自己没有就继续往下的 child 递归。

> 更粗旷一些说就是：从上往下传递约束，传入的约束一般是有 `minHeight`、 `maxHeight` 、 `minWidth` 和 `maxWidth` 等等，但是从下往上返回的 size 时，就会是一个固定 `width` 和 `height` 尺寸。

所以一般如果对于 `Widget` 的布局感兴趣或者有疑惑，就可以先找到这个 `Widget` 的 `RednerObject` ，看这个 `RednerObject` 的 `performLayout` 逻辑是怎么实现，你就知道它的工作原理，你看它的 Widget 是看不出什么东西的。

而关于  RenderSliver ，就需要结合可滑动列表来描述，如下图所示，在 Flutter 里我们常见的滑动列表场景，简单地说其实是由三部分组成：

- *`Viewport`* ： **它主要提供的是一个“视窗”的作用，也就是列表所在的可视区域大小；**
- *`Scrollable`* ：**它主要通过对手势的处理来实现滑动效果** ，滑动里面的 Sliver 
- *`Sliver`* ： 准确来说应该是 *RenderSliver*， **它主要是用于在 Viewport 里面布局和渲染内容，例如 SliverList**

![](http://img.cdn.guoshuyu.cn/20231015_WH/image48.png)

以 `ListView` 为例，如上图所示是 `ListView` 滑动过程的变化，其中：

- 绿色的 `Viewport` 就是我们看到的列表窗口大小；
- 紫色部分就是处理手势的 `Scrollable`，让黄色部分 `SliverList` 在 `Viewport` 里产生滑动；
- 黄色的部分就是 `SliverList` ， 当我们滑动时其实就是它在 `Viewport` 里的位置发生了变化；

所以一般情况下  `Viewport` 和 `Scrollable` 的实现都是很通用的，在 **Flutter 里要实现不同的滑动列表，就是通过自定义和组合不同的 `Sliver` 来完成布局**。

例如 Flutter 3.13 就带来了一组新的 slivers，用于组合独特的滚动效果，其中 [SliverMainAxisGroup](https://link.juejin.cn/?target=https%3A%2F%2Fmaster-api.flutter.dev%2Fflutter%2Fwidgets%2FSliverMainAxisGroup-class.html) 和 [SliverCrossAxisGroup](https://link.juejin.cn/?target=https%3A%2F%2Fmaster-api.flutter.dev%2Fflutter%2Fwidgets%2FSliverCrossAxisGroup-class.html) 都支持将多个 sliver 排列在一起，在主轴中，可以创建的一个效果是粘性标题，允许在每组条子滚动时将固定的标题推出视图之外等。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image49.png)

所以这里讲那么多，虽然没有深入展开，但是也是为大家科普了为什么 Widget 是不可变的，为什么 Widget 不是真正的 View ，Widget 作为配置文件背后负责工作的 RenderObject 又是什么。

## BuildContext

前面我们讲了 Widget 不是真正的 View，而真正负责绘制和布局的是 RenderObject ，那么这里的 Element 又是什么？这就不得不说到 Flutter 里的 `BuildContext`。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image41.png)

Flutter 里的 `BuildContext` 相信大家都不会陌生，虽然它叫 Context，但是它实际是 Element 的抽象对象，而在 Flutter 里我们经常可以看到它，它主要来自于 `ComponentElement` 。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image50.png)

关于 `ComponentElement` 可以简单介绍一下，在 Flutter 里根据 Element 可以简单地被归纳为两类：

- `RenderObjectElement` ：具备 `RenderObject` ，拥有布局和绘制能力的 Element
- `ComponentElement` ：没有 `RenderObject` ，我们常用的 `StatelessWidget` 和 `StatefulWidget` 里对应的 `StatelessElement` 和 `StatefulElement` 就是它的子类。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image51.png)



所以当你知道了 `BuildContext` 是什么的时候，那么对于 Element 就自然不会陌生，而 Widget Tree、Element  Tree 和 RenderObject  Tree 也常常被称作为 Flutter 里的三棵树，其中 Element 实例一般情况下和 RenderObject 实例一一对应，除非该 Element 是  `ComponentElement` 。

另外，通过  `BuildContext`  我们就可以访问到 Element Tree ，而 Flutter 里正是利用这个特点，让我们可以通过   `BuildContext`  往下去共享状体，并且通过   `BuildContext`  往上去获取数据。

#### InheritedElement

在 Flutter 里进行状态共享会使用 **`InheritedWidget`**  ，基本上市面上的状态管理框架在共享数据的时候都是基于它实现。

通过前面我们知道，有 `InheritedWidget` 就会有  `InheritedElement` ，在它   `InheritedElement`  的内部，就会有一个 Map 用于记录和保存需要往下共享的映射关系。

例如 Flutter 里的的各种 `of(context)` ，其实就是通过当前 context ，往上去查到对应的映射关系，找到最近的共享对象，然后返回，例如  `Navigator.of(context);` 返回的是 `NavigatorState` 用于控制路由跳转。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image52.png)

所以到这里大家应该对于 BuildContext 有了基础的认知，明白了 BuildContext 就是 Element 的抽象，使用 Context 就是操作 Element 这样的一个逻辑。

## Flutter Web

为什么这里会突然聊到 Flutter Web ，因为 Flutter Web 在 Flutter 体系里很特殊，有必要针对了解一下它的区别。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image53.png)

首先 Web 平台完全是 html / js / css 的天下，并且 Web 平台需要同时兼顾 PC 和 Mobile 的不同环境，这就让 Flutter Web 成了 Flutter 所有平台里“最另类又奇葩”的落地。

首先 Flutter Web 和其他 Flutter 平台一样共用一套 Framework ，理论上绝大多数的控件实现都是通用的，当然如果要说最不兼容的 API 对象，那肯定就是 `Canvas` 了，这其实和 Flutter Web 特殊的实现有关系，后面我们会聊到这个问题。

而由于 Web 的特殊场景，**Flutter Web 最初在“几经周折”之后落地了两种不同的渲染逻辑：html 和 canvaskit** ，它们的不同之余在于：

#### html

- 好处：html 的实现更轻量级，渲染实现基本依赖于 Web 平台的各种 HTMLElement ，特别是 Flutter Web 下定义的各种 `<flt-*>` 实现，可以说它更贴近现在的 Web 环境，所以有时候我们也称呼它为 `DomCanvas`。
- 问题：html 的问题也在于太过于贴近 Web 平台，贴近平台也就是耦合于平台，事实上 `DomCanvas` 实现理念其实和 Flutter 并不贴切，也导致了 Flutter Web 的一些渲染效果在 html 模式下存在兼容问题，特别是 `Canvas` 的 API 。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image54.gif)

#### canvaskit

- 好处：canvaskit 的实现可以说是更贴近 Flutter 理念，因为它其实就是 Skia + WebAssembly 的实现逻辑，能和其他平台的实现更一致，性能更好，比如滚动列表的渲染流畅度更高等。
- 问题：很明显使用 WebAssembly 带来的 wasm 文件会导致体积增大不少，Web 场景下其实很讲究加载速度，而在这方面 wasm 能优化的空间很小，并且 WebAssembly 在兼容上也是相对较差，另外 skia 还需要自带字体库等问题都挺让人头痛。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image55.png)

另外 canvaskit 还有一些比较边缘的兼容问题，例如这个页面是采用 wasm 渲染的 Flutter Web 页面，但是当我们用插件翻译页面内容时，可以看到只有标题被翻译了，主体内容并没有。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image56.png)

这是因为此时 Flutter Web 的主体内容都是 canvas 绘制，没有 html 内容，所以无法被识别翻译，另外如果你保存或者打印网页，也是输出不了完整 body 内容。

不过 Flutter Web 的定位从最近的 Web 更新也可以看出来，在 Flutter 3.10 关于 Web 的发布里，官方就对 Flutter Web 有明确的定位：

> **“Flutter 是第一个围绕 CanvasKit 和 WebAssembly 等新兴 Web 技术进行架构设计的框架。”**

Flutter 团队表示，**Flutter Web 的定位不是设计为通用 Web 的框架**，类似的 Web 框架现在有很多，比如 Angular 和 React 等在这个领域表现就很出色，而 Flutter 应该是围绕 CanvasKit 和 [WebAssembly](https://link.juejin.cn/?target=https%3A%2F%2Fwebassembly.org%2F) 等新技术进行架构设计的平台。

所以从这一点也可以看出来， **Flutter 本身的定位就不是去竞争和转化开发者**，例如在 Web 领域，它更多是对前沿技术的尝试：Dart  Native 已经开始支持直接编译为原生的 wasm 代码，一个叫 WasmGC 的垃圾收集实现被引入到标准里，未来性能更好体积更小的 Flutter Web 应该会值得期待。

## Flutter 的动画能力

最后聊一聊 Flutter 最强力的能力之一，动画，主要是从这个动画能力也可以看出 Flutter 的战略布局，因为 Flutter 本身的设定上，直接与 GPU 交互渲染，这其实已经类似游戏引擎的概念。

而从另外一个角度看，在近两年 Google I/O 上谷歌都通过 Flutter 发布了对应的小游戏，如下图所示，谷歌官方出品的  [pinball](https://pinball.flutter.dev/#/)  和  [I/O FLIP](https://flip.withgoogle.com/)  小游戏，都可以看到 Flutter 优秀的渲染能力，这两个游戏的完成度和流畅性都挺不错的，特别这还是一个 Web 游戏。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image57.gif)

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image5.gif)

甚至在 Flutter Forword 的大会上，谷歌还展示了暂未开放的真 3D 游戏能力，所以在动画方面 Flutter 本身就具备优秀的品质，因为 Flutter 已经在布局游戏领域，甚至官方推出的 Games Toolkit 和第三方 Flame  SDK ，都在小游戏领域表现出不错的品质，所以如果只是 App 上的动画支持，可以说是绰绰有余。

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image21.gif)

如果回到 App 上，不希望用游戏那么重的框架，但是又需要丰富炫酷的动画，那么可以看看 Flutter 上的商业方案 rive 。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image1.gif)

Rive 提供一个设计平台，你只需要在平台上调教好所有的动画配置，之后导出一个很小的动画文件，然后放到 Flutter  App 里，就可以通过 Flutter 的 Canvas 绘制出各种炫酷的动画效果。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image58.png)

如下图可以看到都是通过 rive 实现的 Flutter 动画，因为都是直接通过 GPU 渲染，**所以可以做到在 Web 端设计时预览的效果，100% 还原到 App 运行时的动画效果**，而从动画执行的效果看也是相当优质的，所以在动画能力上， Flutter 具备很强的先天优势，因为它本身就是一个独立的渲染引擎。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image17.gif)

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image18.gif)

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image19.gif)

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image23.gif)

所以在动画这一块，Flutter 已经有十分成熟的市场支持，Rive 一定程度实现动画都可以有类似游戏的交互效果，像上述这些动画，都是通过 rive 实现的效果，而且每个动画的大小才几十到几百K。

就算不用 rive ，大家熟知的另外的动画框架 lottie 也在 Flutter 上有了 Dart 版本的支持，基本上 Flutter 的 Canvas 能力还是很强的，另外目前 Lottie 的创始人已经加入了 Rive，目前看来依托 Flutter 发家的 RIve ，现在在框架领域的动画支持的势头还不错。

![](http://img.cdn.guoshuyu.cn/20231015_WH/image59.gif)

![](http://img.cdn.guoshuyu.cn/20231015_WH/image60.png)

> 当然，通过动画主要也是为了展示 Flutter 本身的渲染能力支持，因为有些人觉得 Flutter 写出来的 App 卡，这里面首先就要区分 Debug 时的 JIT 执行和 Release 时的 AOT 执行的区别，然后还需要看你是否理解了前面所说的 Flutter 的一些特点，毕竟很多时候性能的瓶颈并不在于框架，而在于写的人的代码，而动画和游戏的能力，正是体现出 Flutter 本身渲染支持的最好表现力。

# 最后

好了，今天的内容大概就这些，今天的内容比较多，最后简单做个回归，我们大概介绍了有：

- Dart 为什么选择 Flutter ，通过 isoalte、ffi 等方向介绍了 Dart 对于 Flutter 的配合与支持
- 接着我们介绍过了 Flutter 的优劣，通过市场占有和热度展示了 Flutter 的优势，通过一些特殊场景展示了 Flutter 的不足
- 最后我们通过 Widget、BuildContext、Flutter Web、动画等角度介绍了 Flutter 里一些比较重要的内容，帮助大家从各个角度更好地去理解 Flutter

总的来说，2023 Flutter 和 Dart 会是跨平台领域里不错的一个选择，如果有跨平台需求，绝对可以试一试，谢谢大家。