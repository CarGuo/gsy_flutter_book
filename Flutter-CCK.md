# 一文快速带你了解 KMM 、 Compose 和 Flutter 的现状

又到了喜闻乐见的环节，**本篇主要是科普 KMM 、 Compose 和 Flutter 的最新现状**，对于 Compose 和 Flutter 大家可能并不陌生，但是对于 KMM 也许会存在疑惑，KMM 全称 Kotlin Multiplatform Mobile ，故名思义它是用 Kotlin 实现的跨平台框架，那为什么今天突然会聊到它？

起因如下图所示，今天突然有群友提及了 KMM ，并且用了“变天”的词汇，顿时就勾起了我的兴起，因为 KMM 这些年来一直“不温不火”，可以说很多使用 Kotlin 开发的 “Androider” 对它都很陌生，难道最近它又有了什么突破性的进展？

| ![](http://img.cdn.guoshuyu.cn/20221027_M1/image1.png) | ![](http://img.cdn.guoshuyu.cn/20221027_M1/image2.png) |
| ------------------------------------------------------ | ------------------------------------------------------ |

而在求证一番之后，原来起因来自 10 月初 **Android 官方宣布 [ Jetpack 开始要支持 KMM](https://android-developers.googleblog.com/2022/10/announcing-experimental-preview-of-jetpack-multiplatform-libraries.html)** 了，目前 [Collections](https://developer.android.com/jetpack/androidx/releases/collection) 和 [DataStore](https://developer.android.com/topic/libraries/architecture/datastore) 已经可以通过依赖 `-dev01`  版本在多平台上使用，同时 **KMM 进入 Beta 版本阶段**。

**所以目前 KMM 变不了天，至少它还处于 Beta 阶段，但是 Jetpack 开始支持 KMM 是个很好的消息，这意味着 KMM 的社区支持有了官方保证**。

> 好了，介绍完起因，接下来开始进入今天的主题，什么是 KMM 、 Compose 和 Flutter。



# KMM

Kotlin Multiplatform Mobile – KMM 是基于 Kotlin 并应用在 iOS 和 Android 的一种跨平台技术，它的特点是结合了跨平台和原生开发协同开发的模式，如下图所示，简单的理解就是：**从纯原生开发变成了 KMM + 原生 UI 开发**。

![](http://img.cdn.guoshuyu.cn/20221027_M1/image3.png)

**使用 KMM 可以把你的业务逻辑和基建部分的能力跨平台化**，例如网络请求、数据存储，状态上报等模块通过 KMM 实现 Android 和 iOS 通用，例如前面介绍的 DataStore 就可以在 iOS 上支持使用。

> 在官方的介绍里 KMM 的早期使用者有百度、Netflix、VMWare、Philips 等，目前收到的反馈都挺不错，而 Beta 版本也意味着现在 KMM 已经具备了使用的基础。

*那你可能会好奇，KMM 支持 Web 吗*？

聊到这个话题就很有趣，从我的角度上看，我会说 Kotlin Mutiplatform  支持，但是 KMM 不支持。

如果你安装过 KMM 插件和创建过 KMM 项目，你会看到 KMM 不管是从 logo 还是项目创建都只有 Android 和 iOS ，但是，Kotlin Mutiplatform  是支持 Web 的，通过 Kotlin JS 。

| ![](http://img.cdn.guoshuyu.cn/20221027_M1/image4.png) | ![image-20221027153602062](http://img.cdn.guoshuyu.cn/20221027_M1/image5.png) |
| ------------------------------------------------------ | ------------------------------------------------------------ |

如果接触 Kotlin Mutiplatform 比较早，那你那么可能还听说过 KMP ，KN 之类的缩写，那它们和 KMM 又是什么关系？简单来说：

- KMP 一般指的就是 Kotlin Mutiplatform  ，我依稀记得 KMP 这个概念是在 Kotlin 1.2 的时候被提出，可以将Kotlin 运行到特定平台的 JVM 和 JS 代码上
- KN 一般指的是 Kotlin Native ，KN 属于是将 Kotlin 编译为 Native 二进制文件的技术，甚至可以在没有虚拟机的情况下运行，例如 KMM 上的 iOS 就是使用了 KN 的能力，
- KMM 是利用了 JVM 和 KN 能力实现的针对 Android 和 iOS 平台的 Kotlin 框架：Android（Kotlin/JVM）和 iOS （Kotlin/Naitve）

![](http://img.cdn.guoshuyu.cn/20221027_M1/image6.png)

另外还有 Kotlin JS 用于 Web 平台，**所以 KMP 可以看作是大集合，而 KMM 是其中针对 Android 和 iOS 的支持，另外通过 Kotlin Native 和 Kotlin JS 也可以支持拓展到 PC 端和 Web 端**。

那么到这里你应该理解：**KMM 主要是用来写跨平台逻辑，涉及到 UI 部分你还是需要通过原生实现**，如果你从另外一个角度看，用 KMM 对于 Android 开发来说几乎等于白送的能力，因为它只需要 Kotlin。

> 至少 Compose 你还需要适应下响应式开发模式。

*那或者有人就问：那 KMM 这也的意义何在*？

事实上还真有，**KMM 在 App 的基建上会很实用，比如做数据上报，崩溃统计，数据分析等等**，纯逻辑的跨平台不影响 UI 部分，目前也是在这些场景上 KMM 应用较多。

> 另外还有人问我，KMM 可以用 Java 开发吗？ 嗯，这是个好问题，下次不要再问了。

当然，KMM 也存在一些局限，比如使用 ViewModel 和协程如何在 iOS 上运行的问题，不过社区针对这部分也有一些第三方支持，所以对于 KMM 的未来还是值得期待。

# Compose

Compose 相信大家不会陌生，**其实 Compose 也可以分两部分看待， Jetpack Compose 和 Compose Multiplatform**：

- 由 Android 官方维护的  Jetpack Compose 
- 由 JetBrains 维护的 [compose-jb ](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2FJetBrains%2Fcompose-jb)实现的 Compose Multiplatform 

**如果说 KMM 时用于实现跨平台的业务逻辑，那么 Compose  Multiplatform 就是专注于跨平台 UI 上的支持**，那 KMM 和 Compose  Multiplatform 是什么关系呢？

从项目角度看，  compose-jb 和 KMM 其实没有关系，因为 KMM 还在 beta ，但是 Compose Multiplatform 正式已经发布接近一年的时间。

> 但是你要说完全没关系显然是不可能，毕竟 Kotlin Native 和 Kotlin JS 的能力其实在 Compose Multiplatform  里很重要。

当然，如下图所示，Compose Multiplatform  在跨平台开发体验上还是有所区别，**Compose 目前是通过多个模块不同实现来支持多平台，所以目前 Jetpack Compose 和 Compose Multiplatform 有一些“割裂”**，特别是在 Web 端，想要达到 Flutter 一样共享代码的比例还需要继续努力。

![](http://img.cdn.guoshuyu.cn/20221027_M1/image7.png)

> PS ：图比较老，iOS 其实目前已经进入[实验阶段](https://github.com/JetBrains/compose-jb/issues/2397#issuecomment-1277536570) ，[` androidx.compose.ui.main.defaultUIKitMain` ](https://github.com/JetBrains/compose-jb/blob/master/experimental/examples/falling-balls-mpp/src/uikitMain/kotlin/main.uikit.kt) 相关的支持距离正式发布可以期待。

另外 Compose Multiplatform 还有的问题就是缺少插件社区，这其实是跨平台领域必不可少的配置：**前端有 npm 、Flutter 有 pub，你可以通过它们的中央官网搜索你想要的库，查看它们的热度，版本，兼容和使用量等等信息，设置官方认证和安全保障，但是 Maven 时代在这方面一直很弱**。

另一方面 Compose 的优势也很明显：

- Kotlin 生态
- Android 开发友好
- 打包体积增长不大，代码压缩比例高
- 性能不错，compose-android 和 compose-desktop 都使用 Skia 

**而随着 Jetpack 开始支持 KMM ，那么 Compose  Multiplatform 的社区支持力度将得到进一步提升，因为变相 Compose  Multiplatform  也可以支持 Jetpack** 。

至于前面所说的“割裂”问题，目前可以看到官方也在有序推进，其中就有 desktop 的部分代码已经挪到了androidx 上，从这里看或者统一的 Compose lib 并不遥远。

![](http://img.cdn.guoshuyu.cn/20221027_M1/image8.png)



> PS： JetBrains 目前就已经将 Toolbox 应用通过 Compose Multiplatform 实现并且发布使用。

# Flutter

常看我文章的应该对 Flutter 更不陌生，现在 Flutter 已经是 3.3 的版本，Flutter 的特点就是跨平台，因为它并没有自己的平台，同时它也是 single codebase 的跨平台实现。

![](http://img.cdn.guoshuyu.cn/20221027_M1/image9.png)

关于 Flutter 和其他框架的对比或者使用数据这里就不多赘述，因为这方便之前我已经分享过很多，感兴趣的可以参考下方链接，这里介绍一些其他比较有意思的话题。

> - [Flutter VS Other 量化对比](https://juejin.cn/post/7084533408986054669)
>
> - [国内大厂应用在移动端 Flutter 框架使用分析](https://juejin.cn/post/7012382656578977806)
>
> - [国内大厂在移动端跨平台的框架接入分析](https://juejin.cn/post/6844904177949212680)

**在 Jetbrains 的开源项目里有一个叫  [skiko ](https://github.com/JetBrains/skiko)  的项目**，Skiko（Kotlin 的 Skia 的缩写）是一个图形库，它支持 Kotlin/JVM 、Kotlin/JS 、Kotlin/Native 等相关实现，目前支持有：

- Kotlin/JVM  - Linux、Windows、macOS、Android
- Kotlin/JS   -  web
- Kotlin/Native - iOS 、macOS

如果从这个角度看 Compose  Multiplatform 未来的方向会和 Flutter 很像，甚至因为 Flutter 走过更多的坑，所以 Compose  Multiplatform 在对接 Skia 上可以有更多的参考。

> 其实未来  Linux、Windows 等平台也完全可以脱离 JVM 通过 Kotlin/Native + Skiko 实现支持，只是维护成本会变高。

而 **Flutter 在自建渲染引擎上其实已经越来越激进，因为直接使用 Skia 已经无法满足日益增长的 Bug 和性能极限，所以官方开始了自研[渲染引擎Impeller](https://mp.weixin.qq.com/s/GptJbPXPediNRc4KvZzr6g)** 。

因为 Flutter 团队现在出现问题每次都要和 Skia 团队沟通，然后等跟进，这样的节奏太慢了，从官方的更新日志上就可以看出目前 Flutter 的迭代速度依然很夸张。

![](http://img.cdn.guoshuyu.cn/20221027_M1/image10.png)

所以**这次自研的  Impeller 本质上是为了解决 Skia 需要运行时遇到的问题， Impeller 可以直接在编译器就完成 GLSL 和 MSL ，不需要 SKSL 从而提高了性能和运行时的稳定性** ，目前优先在 iOS 平台上开始支持 ，配合 Metal 做优化，后续如果没问题也会同步支持 Android 和  Vulkan  。

> 从这个角度猜测，Flutter 在 Skia 遇到的问题 Compose  Multiplatform  也很可能会遇上，而如果后续 Impeller 项目进展顺利，那它或者并不会局限在 Flutter ，也许也可以拓展支持到 Compose  Multiplatform上。

其实自研发引擎并不奇怪，随着项目的发展和深入，很多底层问题没办法快速推进就会反推自研，例如 [Hermes 在 RN 0.7 成为默认 Engine](https://juejin.cn/post/7140474062211383333) 也是类似问题的体现，**自研底层属于是一个负责任的开源团队的必经之路**。

# 最后

今天这篇文章的内容更多的科普性质而非技术行，主要是针对目前 KMM 、Compose 和 Flutter 的现状做一个陈述，其实很多时候它们之间并不冲突，但是作为开发者很经常就像开头一样，用“对立”的角度来看 A 火了 B 就要挂，这种心态大可不必。

另外，**我更喜欢“百花齐放”的氛围，当然你也可以万花丛中只取一朵，所以不必过于焦虑，需要什么就用什么就可以**，技术服务于业务，就像我接触到的很多开发，他们需要使用什么技术并不是自己能决定的。

> 就比如前面那位问我  “KMM 上可以用 Java” 的那位兄弟，他是因为公司 leader 觉得 Kotlin 不成熟而不给用在 Android 上，嗯，他的 Leader 是一位后端开发。