#  Android 开发者的跨平台 - Flutter or Compose ？

hello 大家好，我是 Flutter GDE 郭树煜，同时也是 Github GSY 项目的负责人，比如 GSYVideoPlayer ，今天要给大家分享的主题是 Android 开发者的跨平台 - Flutter or Compose ？ 今天的分享不会是很深入的技术内容，更多可能是科普向，特别是对 Flutter 和 Compose 还不是特别了解的 Androider 们，通过数据帮助大家来理解 Flutter 和 Compose。

# 一、Android 开发和跨平台开发的现状  

首先我们聊聊现状，不知道你有没有这种感觉，就是现在的 Android 开发者很多时候不再是 Android 开发，或者说不是纯 Android App 开发，目前简单总结大致可以分为两类：

- **以 Android 为技术栈的嵌入式开发**，如电视、手表、教育平板、监控等，这里面近年来又以车机开发较为突出。
- **大前端开发**，从 Android 、 iOS 、Web 到小程序等各类面向 UI 相关的工作内容

这个现状的具体原因在于：**Android 开源让它可以更好地被各行各业消化，同时这些年 App 开发体系越发成熟**。

> 我还记得 2015 年那会我带的移动团队开发一款 App ，标配就是 Android 和 iOS 各自 4-5 个人，还经常需要加班加点，项目里会用到大量第三方的开源框架。

而现在随着官方这些年 Jetpack 体系的成熟，Android 开发者更多会聚焦到 Jetpack 体系内，比如：`Room`、`CameraX`、`Hilt`、`Navigation`、`Paging`、`WorkManager`、`Emoji2`、`DataStore`、`Media`、`Startup` 等，而 Compose 就是 Jetpack 里的最大亮点之一，**如果说 Android 开发现在进入了 Jetpack 纪元，那 Jetpack Compose 就是 Jetpack 纪元里的超新星**。

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image1.png)



**Jetpack Compose 是 Android 新推出的声明式 UI  工具包，它主要是用于简化和加速 Android 上的 UI 开发，同时 Compose 经过 Jetbrains  开源的 compose-jb 支持到跨平台开发的能力**。

这里三个重点：

- Jetpack Compose 是 Android 的 UI 的工具包
- Jetbrains  开源了 compose-jb  支持跨平台
- Compose 是声明式开发

**从大前端开发的角度看，声明式开发可以说是当今的主流**，React、Vue、SwiftUI、Flutter 等都是声明式编程，还有如近期发布的 HarmonyOS 3.1版本，也着重标注了它将全面进入声明式开发阶段。

> 所以不管你喜不喜欢，声明式开发是主流，虽然它近期看起来不会完全替代 Android 的 XML 布局，但是这是主流的趋势。

再说跨平台，如今跨平台开发相信大家都不会陌生，各类跨平台开发框架都相当成熟，**但是对于 Android 开发来说， Flutter 和 Compose 确实会显得比较特殊**，因为它们都是属于 Google 开源的产品，都能支持跨平台，所以可以对于部分 Android 开发者来说会陷入困惑：我该选哪个？

针对这个疑惑，我们先看一些数据对比，首先如下图所示，是 Google Trend 上 Flutter 和 Compose 在全球和国内的一些关键词搜索热度对比，可以看到**全球范围内都是在稳步上升，但是在国内是属于强烈波动的状态，也就是国内有很多人对于  Flutter 和 Compose 都还处于徘徊观望状态**。

| ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image2.png) | ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image3.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

另外也可以看到 ， Flutter 出来比较久，所以如今他的热度会比较高，当然这也是现在跨平台的需求剧增有关系，很多平台开发人员不再仅仅 ”安居” 于自己的平台，**并且从国内的数据可以看到，国内对于跨平台的热情其实一直很高**。

> 虽然 Flutter 从发布以来一直争议不断，但是这些年下来 Flutter 也证明了自己的价值，后面我们会有单独的详细的数据分析。

再看 StackOverFlow 的数据，可以看到  Flutter 和 Compose 都在稳步上升，这里面 Compose 相关看起来比较少的原因，和它发布时间还较短有关系，而 Flutter 从目前的占有比例上看其实不算低了。 

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image4.png)

既然说 Flutter 和 Compose  就不得不说 Dart 和 Kotlin ，同样是 StackOverFlow 的数据，可以看到虽然他们发布都有一段时间了，但是其实是在 2017 年开始它们的占有率才出现了爆发式的上升，这是为什么呢？

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image5.png)

其实这个现象和 2017 Google I/O 大会有直接关系：

- Kotlin 是 2012 年开源的，而 2017 Google I/O 大会上官方正式支持将 Kotlin 作为 Android 开发的 First-Class（一等公民）语言

- Dart 亮相于 2011 年，而 2017 年 Google I/O 正式向外界公布了 Flutter，Dart 是它的主要开发语言

> 所以 Kotlin 本来不温不火，但是因为 Android 它开始被更多人所使用，同样 Dart 本来已经快被雪藏，却因为 Flutter 而焕发第二春，**看起谷歌在这方面运营能力还是很值得肯定的**。

我们再看一份数据，这是目前 Kotlin  和 Dart 在 Github 上关于 PR 和 Star 的数据趋势，可以看到开始增长的时间节点依然是 2017，不过 Dart 的关注度还是从 Flutter 正式版发布后才有爆发式增长， 而从增长上看，不管是 Kotlin 还是 Dart 目前都很过得去，**不过目前它们的主要应用场景还是局限在 Android 和 Flutter**。

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image6.png)

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image7.png)



再看国外调研的一份关于 Flutter 和 Compose 在 Droidcon 上有多少次关于这两个项目的演讲主题和结果，虽然数据相对较小和局限，但是可以看到 Flutter 自发布以来每年都在稳定的主题，而 Compose  在稳定版发布后有明显爆发式增长

| ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image8.png) | ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image9.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |



最后，恰好 GitHub 也发布了 2022年度报告，其中一些数据还是值得我们关注，例如在开发语言增长上， Kotlin 排进了前十，另外移动端开发依旧是开源主流之一，其中 Kotlin、Dart 、Flutter 、Android 都是主要的对象。

| ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image10.png) | ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image11.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

当然，就像前面说的，**不管是 Dart 还是 Kotlin ，它们主要是场景还是在于 Flutter 和 Android ，通过  [TIOBE](https://www.tiobe.com/tiobe-index/) 在 2022 年 11 月的编程语言指数上可以看到，  Dart 和 Kotlin 还是未能进入 TIOBE 指数前 20 名**，该指数每月更新一次，在编程语言的流行程度上有比较高的参考价值。

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image12.png)

不是说其他领域不能用，比如 Kotlin 和 Dart 都能写后端，我以前自己也有一些后端项目，当时为了方便，直接把Android 上 kotlin 的逻辑复用到服务端，而 Dart 本身通过 ffi 直接支持数据库等的能力，也让它可以脱离 Flutter 作为单独的后台服务运行，这在我以前的文章也分享过，目前支持 Dart 的 ffi 数据库也有好几款了，所以不是说不能用不支持，只是相对还是少很多。

我们最后在看一份数据， [RedMonk 2022 Q3](https://redmonk.com/sogrady/2022/10/20/language-rankings-6-22/) 的调查里，在 Github 和 StackOverflow 的流行指数上还是比较靠前的，Kotin 排在第 17 位，而 Dart 排在第 19 位，从应用领域看，这两种语言目前的势头还是不错的。

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image13.png)



> 所以总结来说： **Android 成就了 Kotlin ，而 Kotlin 成就了 Compose ，同样 Flutter 成就了 Dart **。

#  二、Compose 对于 Android 开发来说是什么  

接下来进入第二个主题，Compose 对于 Android 开发来说是什么：

- **Compose 对 Android 来说最重要的是新的现代化 UI 开发框架，Compose 提供了 Andorid 声明式的 UI 开发能力，这是核心的重点**。
-  **Jetbrains  开源的 compose-jb  让  Compose 得到了额外的增值，可以把开发能力拓展到其他平台，这是附带价值**。

> 所以从这个角度看，如果你继续做 Android 开发，那么学会 Compose 是必须的技能，因为它未来可能会是 Android 上主流的开发模式，尽管它目前还比较年轻。

说他年轻，是因为目前他的正式版发布也就一年的时间，目前 Jetpack Compose  和  compose-jb  的正式版本都在 1.2 ，第一个正式版是都是在 2021 年发布，并且在近一年时间内发布了两个大版本，另外可以看到  compose-jb  都是在 Jetpack Compose  发布之后再跟进版本更新，**所以  Jetpack Compose  是一些的基础核心**。

| ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image14.png) | ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image15.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

*那么大家肯定很关心一个问题，有哪些大厂 App 在使用 Compose* ？

目前关于 Flutter 的技术文章我们可能看到过很多大厂的分享，但是 Compose 相关的比例却不多，所以我也只能从我自己手机里一些常用软件的归类，目前恰好可以找到如下图所示的 6 款 App 里有存在  Compose 的痕迹。

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image16.png)



> **当然，使用 Jetpack Compose 和使用  compose-jb  其实是两码事**，所以我也不知道上述产品是否也有使用  compose-jb  的场景，因为其实   compose-jb  目前在跨平台开发上的体验还是有些差别的。

**而作为全新的独立 UI 框架， Compose 自然不会像以前一样的控件体系**，类似的声明式布局方式对于 Android 开发者来说可能会有一定的学习成本，最直观的就是 Compose 里会使用状态管理和绑定，而不会是像以前一样拿 `view.xxxx` 这样的操作方法，这是一个思路转变的过程。

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image17.png)

另外从反编译后的代码里可以看到，**Compose 里的控件和原生控件并不是一个体系**，大家如果去看编译后的内容，就会发现例如 `BOX` 这样的控件在编译后是通过 `ComposerKt` 和 `BoxKt` 等的 framework 实现来完成的布局与绘制。

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image18.png)

所以 **Compose 编译后不是转化为原生的 Android 上的 View 去显示**，而是依赖于平台的 `Canvas` ，在这点上和 Flutter 有点相似，简单地说可以理解为 Compose 是全新的一套 View 。

> 另外友情提示：虽然是全新的 View ，但是 `Compose` 的组件在 Android 上是可以显示了布局边界。

**另外 Compose 里的代码基本都是可以被混淆的**，所以开启混淆之后代码的压缩率也很高。

在 Compose 里两棵树的设计，虚拟 Dom 风格的 SlotTable 和 React 设计类似，从而保证了 LayoutNode 的性能，Compose 的核心设计开发人员 Jim Sproch 之前是 React 的核心开发。

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image19.png)

> **其实这也是一种大前端的趋势，不管你是客户端还是前端开发，你的能力都应该可以得到应用。**

再说  compose-jb ，如下图所示， compose-jb  在跨平台开发体验上还是有所区别，**Compose 目前是通过多个模块实现来支持多平台，所以目前 Jetpack Compose 和  compose-jb  有一些“割裂”**， compose-jb 本质上是将 compose-desktop，compose-web 以及 compose-android 进行了整合，特别是在 Web 端，想要达到 Flutter 一样共享代码的比例还需要继续努力。

![](http://img.cdn.guoshuyu.cn/20221027_M1/image7.png)



如上图所示的 iOS  其实目前也已经进入[实验阶段](https://github.com/JetBrains/compose-jb/issues/2397#issuecomment-1277536570) ，[` androidx.compose.ui.main.defaultUIKitMain` ](https://github.com/JetBrains/compose-jb/blob/master/experimental/examples/falling-balls-mpp/src/uikitMain/kotlin/main.uikit.kt) 相关的支持距离正式发布可以期待，而   compose-jb  目前对跨平台的支持的 “割裂” 也来自于此，比如 Web 下的代码会是这种感觉。

```kotlin
import org.jetbrains.compose.web.dom.*
import org.jetbrains.compose.web.css.*

fun main() {
    var count: Int by mutableStateOf(0)

    renderComposable(rootElementId = "root") {
        Div({ style { padding(25.px) } }) {
            Button(attrs = {
                onClick { count -= 1 }
            }) {
                Text("-")
            }

            Span({ style { padding(15.px) } }) {
                Text("$count")
            }

            Button(attrs = {
                onClick { count += 1 }
            }) {
                Text("+")
            }
        }
    }
}
```

> **另外值得一提的是，Compose for Wear OS 的 1.0 稳定版也发布了**。

还有一个关键点就是，如果使用   compose-jb   ，你可能还会接触到 Kotlin/JS 、Kotlin/Native、KMM 等对应的名词，这部分对于 Android 开发来说也算是额外的学习成本，**所以在跨平台体验上目前  compose-jb 的路才刚刚开始，一致性的跨平台开发体验相信会是  compose-jb 努力的方向**。

其实前面所说的“割裂”问题，目前可以看到官方也在有序推进，其中就有 desktop 的部分代码已经挪到了androidx 上，从这里看或者统一的 Compose lib 并不遥远。

![](http://img.cdn.guoshuyu.cn/20221027_M1/image8.png)



另外 **Jetpack Compose 现在针对 Compose 体系的官方依赖支持，也推出了  Gradle BOM (Bill of Materials) 依赖模式**，用于指定每个 Compose 库的稳定版本。

> 目前第一个版本是  Compose 2022 年 10 月版，现在最新的应该是 2022.11.00。

那么 Gradle BOM 的作用是什么？如下图所示，**简单说就是不用再单独写依赖版本， 我们可以通过仅指定 BOM 的版本管理所有 Compose 库版本**，BOM 本身具有指向不同 Compose 库的稳定版本的链接，所以它们可以很好地协同工作。

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image20.png)

*当然，聊到这个就顺便聊一聊制约 compose-jb 的问题：缺少插件社区*。

这其实是跨平台领域必不可少的配置：**前端有 npm 、Flutter 有 pub，你可以通过它们的中央官网搜索你想要的库，查看它们的热度，版本，兼容和使用量等等信息，设置官方认证和安全保障，甚至还有趋势推荐，库支持的平台有哪些等等，但是 Maven 时代在这方面一直很弱**，这是 compose-jb  后续发展需要解决的最大问题之一。

最后说到 Compose 就不得不说 Android Studio ：**Compose 和  Android Studio 版本其实有很强的依赖关系**，例如：

1、Android Studio Arctic Fox （白狐狸） 开始支持 Compose preview 、 Interactive preview 和  Deploy to Device  ，并开始支持 Live Edit of literals 和 Layout Inspector 。

2、Android Studio Bumblebee （小蜜蜂） Layout Inspector 才支持检查 Compose 布局中的语义信息，并且默认启用 interactive preview，interactive preview 允许在预览时进行交互，就像是已经运行到设备上工作一样。

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image21.gif)

> 这里的 Preview interactive 模式直接在 Android Studio 中运行，无需运行模拟器，这会导致一些限制：没有网络访问权限、没有文件访问权限、某些上下文 API 可能不完全可用。

值得一提的是， **Compose 目前不支持 hotload**，Android Studio 的 apply code 的实用程度相信大家深有体会，不过 Compose 有支持 preview 时的文本  Live Edit of literals ，这也算是一个可将一下的工具。

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image22.gif)



3、Android Studio Chipmunk （小松鼠）  开始支持 [`animatedVisibility`](https://link.juejin.cn/?target=https%3A%2F%2Fdeveloper.android.com%2Fjetpack%2Fcompose%2Fanimation%23animatedvisibility) 的动画预览，动画预览和`animatedVisibility`需要使用 Compose 1.1.0 或更高版本。

| ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image23.gif) | ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image24.gif) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |



4、Android Studio Dolphin （海豚） 支持 Compose Animation Coordination，如果你的动画是用于 composable preview，那么可以使用 [Animation Preview](https://link.juejin.cn/?target=https%3A%2F%2Fdeveloper.android.com%2Fjetpack%2Fcompose%2Ftooling%23animations) 来同时检查和协调所有动画，甚至还可以冻结特定的动画，并且支持 composables 何时进行或不进行重构

| ![](http://img.cdn.guoshuyu.cn/20220916_AS/image1.gif) | ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image25.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

最后，如果你好奇现在哪些大厂在使用 compose-jb ，目前我还没找到比较有价值的数据，不过据称  JetBrains 目前就已经将 Toolbox 应用通过  compose-jb  实现并且发布使用。

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image26.png)





# 三、 Flutter 对于 Android 开发来说是什么

接下来我们聊聊 Flutter 对于 Android 开发者来说又是什么？**你如果选择还是只做 Android ，那么 Flutter 对你来说可能意义不大**，Flutter 其实起源于 Chrome 内部团队，所示它其实和 Android 没什么关系，**但是如果你对其他平台感兴趣，那么 Flutter 绝对是你不错的选择**。

Flutter 正式版是在 2018 年发布，发布之后几乎就是每个季度都会更新一个大版本，如下图所示可以看到 Flutter 的推进和迭代速度是很快的，这也侧面反映了 Flutter 社区的活力。



![](http://img.cdn.guoshuyu.cn/20221124_SQS/image27.png)



**如果大版还不够有说服力，那么近期的小版本迭代速度，这也可以体现 Flutter 社区的生命力，当然也侧面反映出全平台支持的困难，需要解决的问题很多**，因为跨平台需要兼容处理的问题会更多，这也是 Flutter 坑多的原因。

![](http://img.cdn.guoshuyu.cn/20221124_SQS/image28.png)



我们再从 Github 发布的 2022 年度报告上看，在各项开源数据里 Flutter 都名列前矛：

- 顶级开源项目里按贡献者排序 Flutter 排第三
- 顶级开源项目里按首次贡献者统计的，Flutter 在获取贡献“一血”里排名第四
- 在每个项目的贡献者数量里 Flutter 排名第二
- 在外部贡献者百分比里 Flutter 排名第三

| ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image29.png) | ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image30.png) | ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image31.png) | ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image32.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |

> **由此可以看到 Flutter 强大的生命力，特别是来自社区的活跃，Flutter 每个版本发布都会合并大量来着社区的 PR ，这也是 Flutter 这些年来快速发展的原因**，同时也是在本次  Github 发布的报告里，随处可以见 Flutter 的原因。

*那么说一千道一万，目前有哪些我们熟知的企业在使用 Flutter 呢*？

如下图所示是目前我手机里有 Flutter 存在的 App ，另外还有过去三年里 Flutter 在跨平台领域的占有率增长，**可以看到 Flutter 目前在跨平台领域的存在感并不低，其实介绍这么多数据，只是为了和大家说明一个问题：Flutter 已经不算小众了**。

>  百度网盘、转转、阿里云盘、闲鱼、微信、掘金、企业微信、微博、B站漫画、阿里云、 UC浏览器、优酷视频、钉钉、360摄像头、网易邮箱、天猫精灵、链家、美团众包、凤凰新闻、腾讯课堂、喜马拉雅、携程旅行、贝壳找房、WPS、学习强国、唯品会、同花顺

| ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image33.png) | ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image34.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

回到 Flutter 本身上，**Flutter 的优势体现在于  single codebase ，它是真的做道一套代码编译成不同平台的 native 代码运行**，Flutter 跨平台最特殊在于它不依赖平台控件，控件最后都是利用 Skia 通过平台 GPU 渲染出来。

![](http://img.cdn.guoshuyu.cn/20221027_M1/image9.png)

**所以 Flutter 里的控件基本和平台无关，这对于跨平台来说有很大优势**，因为控件只和 Flutter 框架有关系，在 Andriod 上得到的效果，在 iOS 上也可以得到一样的结果，所见即所得，这对开发效率有很高的帮助。

> 但是这也大大提供了框架维护的工作量，例如文本输入框  `TextFiled`   和 `Text`  都针对移动平台和 PC 平台，需要在控件内部兼容手势触摸和键鼠操作，，这也是为什么类似 Global Selection 等功能会到 3.3 才开始有官方支持。

所有 Flutter 需要面对的 Bug 也很多，在面对越来越多不可控的底层渲染问题之后，**Flutter 开始自建渲染引擎，因为直接使用 Skia 已经无法满足日益增长的 Bug 和性能极限，所以官方开始了自研[渲染引擎Impeller](https://link.juejin.cn/?target=https%3A%2F%2Fmp.weixin.qq.com%2Fs%2FGptJbPXPediNRc4KvZzr6g)** 。

因为 Flutter 团队现在出现问题每次都要和 Skia 团队沟通，然后等跟进，这样的节奏太慢了，从前面官方的小版本更新日志上就可以看出目前 Flutter 的迭代速度依然很夸张。

> **这次自研的 Impeller 本质上是为了解决 Skia 需要运行时遇到的问题，让 Impeller 可以直接在编译器就完成 GLSL 和 MSL ，不需要 SKSL 从而提高了性能和运行时的稳定性** ，目前优先在 iOS 平台上开始支持 ，配合 Metal 做优化，后续如果没问题也会同步支持 Android 和 Vulkan 。

从这个角度猜测，Flutter 在 Skia 遇到的问题 compose-jb 也很可能会遇上，而如果后续 Impeller 项目进展顺利，那它或者并不会局限在 Flutter ，也许也可以拓展支持到 compose-jb上，

> 其实**在 Jetbrains 的开源项目里有一个叫  [skiko ](https://github.com/JetBrains/skiko)  的项目**，Skiko（Kotlin 的 Skia 的缩写）是一个图形库，它支持 Kotlin/JVM 、Kotlin/JS 、Kotlin/Native 等相关实现。

所以自研发引擎的模式并不奇怪，随着项目的发展和深入，很多底层问题没办法快速推进就会反推自研，例如 [Hermes 在 RN 0.7 成为默认 Engine](https://juejin.cn/post/7140474062211383333) 也是类似问题的体现，**自研底层属于是一个负责任的开源团队的必经之路**。

最后，**如果真要总结 Flutter 对于 Android 开发者最大的意义，就是拥有开发其他平台的能力**，通过 Flutter 去了解和接触开发其他平台的，同时还能提前习得大部分 Compose 的开发能力，如下图所示是 Compose 和 Flutter 的代码对比：

| ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image35.png) | ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image36.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

**所以这也是 Andorid 开发会了 Flutter 就离 Compose 不远的原因，反过来也是**。

这里可以顺便推荐下大佬的 Flutter 和 Compose 入门项目 [FlutterUnit](https://github.com/toly1994328/FlutterUnit) 和  [ComposeUnit](https://github.com/toly1994328/ComposeUnit) ，上面的代码就是来自这两个项目，里面列举了很多案例，特别适合入门的小伙伴。

| ![](http://img.cdn.guoshuyu.cn/20221124_SQS/image37.png) | ![image-20221115171152896](http://img.cdn.guoshuyu.cn/20221124_SQS/image38.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |



# 最后

本次分享的核心还行想告诉大家，目前 Compose 和 Flutter 成熟度已经不错了，当你的领导和你说，Kotlin、Dart 还不够普及，Flutter 和 Compose 还太小众的时候，或者你就可有一些数据依据。

最后可以总结的是：

- Compose 的核心还是 Android 的 UI 库，做 Android 的必须掌握这个未来的能力，至于 compose-jb 的跨平台增值能力，还有一段路要走。
- Flutter 的核心是全平台更稳定的支持，更有社区活力，特别是在相对“冷清”的桌面端上的优势，在目前公开信息上，钉钉、字节和企业微信都在 Flutter 桌面端开始有投入。

**所以结合自己的路线，选哪个应该就很清楚了，而不管选择哪一个，都会对另外一个框架有提前铺垫的作用，所以也不用担心得此失彼，感兴趣的小伙伴可以开始动起来了**～
