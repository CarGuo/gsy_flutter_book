# Flutter Festival | 2022 年 Flutter 适合我吗？Flutter VS Other 量化对比


Hello 大家好，我是《Flutter 开发实战详解》的作者，Github GSY 系列开源项目的负责人郭树煜，比如 [gsy_github_app_flutter](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2FCarGuo%2Fgsy_github_app_flutter) 、GSYVideoPlayer 等的项目 。

>  看到这个题目大家应该知道，今天这个主题并不是纯粹的技术内容分享，可以说还有点吃力不讨好，其实我很少分享这类主题，不过最近觉得有必要做这么一个算是科普向的内容吧。

![](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image1)



## Flutter 的现状

我是在 2017 年左右接触的 Flutter ，说来起来有趣，那时候因为我需要做一场关于跨平台技术的内部分享，主要目的是给公司其他事业部推 React Native 框架，好巧不巧地那时候刚好看到 Flutter ，就被我当作凑数的“添头”给加到分享里，自此我就开始了和 Flutter 之间的故事。

回到正题，Flutter 开源至今其实已经将近 7 年的时间，如今在 2022 年看来，**Flutter 已经是不再是以前小众的跨平台框架了**。

![image-20220222115737486](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image2)

如图所示，截止我 2 月份截图时，可以看到如今的 Flutter 已经有高达 `137k` 的 star ， `10k+` Open 和 `50k+` Closed 的 issue 也足以说明 Flutter 社区和用户的活跃度。

**从官方公布的数据上， Flutter 已经基本超过其他跨平台框架，成为最受欢迎的移动端跨平台开发工具，截至 2022 年 2 月，有近 50 万个应用程序使用了 Flutter**。

如图所示，去年下半旬的数据调查中，**Flutter 也成为了排名第一的“被使用”和“被喜爱”的跨平台框架**，可以看到 Flutter 在  2019  到 2022 有了很明显的增长，有接近 42% 的跨平台开发者会使用 Flutter。


![image-20220222115623672](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image3)

![image-20220222115549701](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image4)



其实在去年和前年，我也做过一些简单的统计：

- 2020 年 `52` 个样本中有 `19` 个 App 里出现了 Flutter；
- 2021 年 `46` 个样本中有 `24` 个 App 里出现了 Flutter；

本次基于 2022 年 2 月 22 号，在对比了 **57 款**常用 App 之后得到的数据：

| Flutter                                                      | React Native                                                 | Weex                                               | 没有使用跨平台                                               |
| :----------------------------------------------------------- | :----------------------------------------------------------- | :------------------------------------------------- | ------------------------------------------------------------ |
| 27                                                           | 24                                                           | 5                                                  | 13                                                           |
| 链家、转转、掘金、**中国大学 MOOC**、同花顺、饿了么、凤凰新闻、微信、微视、哔哩哔哩漫画、腾讯课堂、企业微信、学习强国、闲鱼、携程旅行、腾讯会议、**微博**、贝壳找房、百度网盘、 WPS Office、唯品会、**美团众包**、**美团外卖商家版**、**UC**、QQ（libmxflutter），**小米运动**、**优酷视频** | 美团 、**美团众包** 、**美团外卖商家版** 、美团外卖、爱奇艺、**中国大学 MOOC** 、脉脉 、小红书、安居客、得物、58同城、微信读书、汽车之家、飞书、喜马拉雅、去哪儿旅行、菜鸟、京东、快手、携程、**米家**、**UC**、**小米运动**、**优酷视频** | **UC** 、**闲鱼** 、 **微博** 、**米家、优酷视频** | QQ音乐、Boss直聘、今日头条、流利说、知乎、腾讯新闻、财经社、酷狗音乐、拼多多、抖音、起点、什么值得买、百度地图 |

> 这些数据来源于 Android 的 Apk ，以是否存在` libflutter.so` 、`libreactnativejni.so` 和 `libweexcore.so` 等动态库为依据，如果项目使用了插件化下发可能会被忽略。

可以看到 Flutter 和 React Native 的出现都接近 50%，而 Weex 的占有率已经很低，**另外在这个小样本下，可以看到现在大多数 App 或多或少都可能带有一些跨平台框架的趋势**。

> 同时，加粗部分的 App 因为业务需要， 在应用内使用了不止一种的跨平台框架，比如UC、闲鱼等。

而在官方去年的 Q4 数据调查里，*在过去 6 个月中，分别**有 72% 和 91% 的开发者使用  Flutter 为 iOS 和 Android 开发 App*** 。

![0*TERDonM4zc_kafRm](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image5)



再看一份数据，是 Dart 的第三方插件托管平台 pub.dev 上的数据，基于 2022-02-22 的数据：

| All         | 23495 packages |
| ----------- | -------------- |
| Flutter     | 21714 packages |
| Android/iOS | 20352 packages |
| Web         | 12584 packages |
| PC          | 14314 packages |
| Null safety | 12615 packages |

目前大概有 2.3 万个公开的第三方支持包托管在 pub 上，其中支持 Flutter 的有 2.1 万个，可以看出 Dart 语言的用户基本都是来源于 Flutter 。

另外从数据上看大部分的库都支持 Android 和 iOS ，而对于 Web 和 PC 的支持接近60% ，而比较意外的是，目前支持 Null safety 的包也就接近60%，也就是还有 40% 多的包还停留在较老的版本上。

而在官方的 Q4 调查里可以看到，**使用 Flutter 作为主要工作的比例在逐步提高**。

![0_Zw_zyVq5CfP7Y09o](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image6)

最后在聊一聊 Flutter 官方对于 Flutter 一直坚持一个理念：

**一个 `SDK` 再优秀，如果只有少部分人在使用，那它也不能体现价值；而一个 `SDK` 即使平庸，但是有大量开发者使用，那也会拥有一个健康繁荣的生态氛围，这样使用框架的人才能从中受益**。

> 补充一句，你知道调查里大家最不满意的 Flutter 的是哪个方面吗？
>
> **是文本编辑**！Q4调查里，对文本编辑功能的满意度从 82.3%（单行）和 82.2%（过滤和格式化）下降到 69.6%（多行）和 66.6%（富文本编辑器），目前多编辑体验和输入富文本支持上，确实不是特别友好。

## Flutter VS Other 

聊完 Flutter 的现状，我们继续讨论 Flutter 和其他框架的一些直观对比。

### 实现原理

这部分内容其实分享过很多次，简单说一下，首先对比它们的实现原理，如下图所示，可以看到：

- 对于原生 Android 或者 Compose 而言，是**原生代码经过 skia 最后到 GPU 完成渲染绘制**，Android 原生系统本身自带了 skia；

- 对于 Flutter 而言，**Dart 代码里的控件经过 skia 最后到 GPU 完成渲染绘制**，这里在 Andriod 上使用的系统的 skia ，而在 iOS 上使用的是打包到项目里的 skia ；

- 对于 ReactNative/Weex 等类似的项目，它们是**运行在各自的 JS 引擎里面，最后通过映射为原生的控件，利用原生的渲染能力进行渲染**；

- 对于 uni-app 等这类 Hybird 的跨平台框架，使用的主要就是 **WebView 的渲染能力**；（不讨论开启weex情况）



![](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image7)



首先看到，从理论上来说， **Flutter 在实现上是最接近原生，因为从实现路径上基本是一致的，而 RN/Weex 相对会差一些，而 uni-app 通过 WebView 的渲染会是最末**。

但是对于性能问题，**事实上很多时候性能门槛不在于框架，而在于开发者**，我见过用 Cordova 开发的 App 性能和体验都调教得很不错，我记得有一次大会分享和支付宝的大佬聊过，支付宝也使用了很多 H5 的 Hybird 技术，得益于 UC 的自研内核，在性能体验上一直还挺不错。

### 构建大小

接着我们对比应用构建的大小，这里主要对比 Android ，因为 iOS 上应用的大小似乎越来越没人在意，比如 QQ 这个极端的例子：

![image-20220225113714959](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image8)



回到问题上，关于应用大小问题，之前恰好看到有多人说过：

>  “Compose 上 Kotlin/JVM 为 JVM 和 Android 平台生成 jar/aar 文件、通过 Kotlin/Native 为 IOS 平台生成 framework 文件、通过 Kotlin/JS 为 Web 平台生成 JavaScript 文件，最终调用的还是原生 API，这使得采用 Compose Multiplatform 不会导致性能损耗，且不会像 Flutter 那样明显增大应用体积。”

是的，从实现上看 Flutter 在实现上确实应该比 Compose 占据更多体积，但是真实情况是怎么样呢？

首先我们创建几个空项目，然后打包时只保留 `arm64-v8a`  相关的动态库，因为一般情况下上架也只会保留其中一种 so 库。

在我们不写任何代码的情况下，构建出 Android 的 Release 包，得到如下结果：

- Flutter

![l37e90013d3143b59b2fedac8175846c2-s-mab43156a06c705c0e724893593dff285](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image9)

- React Native

![l86641a7d82e2feff1f984855ecbd562c-s-mdb88514a3334653b9e61c27c51634605](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image10)

- Compose

![l6125476d649868bb69a29a009574a232-s-mf07265732fba4b70ab8330b8014db858](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image11)

- 原生 Android

![l64e110c95184cd1d58dc061c7a37337f-s-m7042d4089e4705f94ae59f9477189827](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image12)



可以看到 ：

- React Native 的空包最大，主要体积来自于其内部的各种动态库，比如 JSCore ；
- Flutter 次之，主要体积来也是自于其内部的动态库，比如 Flutter 的 framework；
- Compose 的体积和原生相当接近，主要内容来自于 classes 文件；当然这里没有混淆和压缩，混淆和压缩后可以小很多；



从结果上看空项目下确实是 Flutter 比 Compose 所占据的体积更大，但是这里有一点需要注意的是：

- 单纯 Flutter 开发下，主要的应用体积会来自 `libapp.so`  ，这部分代码是经过 AOT 编译后的 Native 二进制代码；
- 而 Compose 的体积增长主要来自于 classes 文件，这部分的代码增长需要通过混淆等来压缩；

额外提一点，**大家可能会好奇 Compose 编译后是怎么完成布局渲染**？

这里简单介绍下，**Compose 里的控件和原生控件并不是一个体系**，大家如果去看编译后的内容，就会发现例如 `BOX`  这样的控件在编译后是通过 `ComposerKt`  和 `BoxKt` 等的 framework 实现来完成的布局与绘制。

![image-20220223163739226](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image13)

所以 **Compose 编译后不是转化为原生的 Android 上的 View 去显示**，而是依赖于平台的 `Canvas` ，在这点上和 Flutter 有点相似，简单地说可以理解为 Compose  是全新的一套 View 。

> 另外友情提示：虽然是全新的 View ，但是 `Compose` 的组件在 Android 上是可以显示了布局边界。

回顾到体积的问题上，因为我恰好开源有一些列 GSY 项目，它们实现的业务逻辑十分相似，所以都打包成 Release 模式之后，我们对比它们的体积大小：

- Flutter 

![ld53439aaeaa21568253c98480767caee-s-m1c224ff23fb985b1bded376f0cceebdc](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image14)

- React Native 

![lca0d0a439e3b9d18d0195521fad90c14-s-m7fdc781bd60e584b0c161115fa824f43](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image15)

- 原生 Android

![le2f6c0258c501a6fdae93b47deff024c-s-mc5ea88d982f7d79299b1b0391b7e95ab](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image16)



因为我目前还没有 Compose 的项目，所以这里以原生作为对比，可以看到：

- Flutter 项目从空的 5.7 M 变成了 9.8M ，增长了 4.1 M 的大小；
- React Native 项目从 9.4 M 变成了 12.7M，增长了 3.4 M 的大小；
- 原生项目从 3.2 M 变成了 9.3 M ，增长了 6.1 M 的大小；

虽然不精准，但是可以看到在大致相同的业务场景下， **Flutter 和原生项目的总大小反而相差不大，而原生项目的增加其实比 Flutter 更显著一些**。

但是这里的前提是原生不开启压缩和混淆，如果开启压缩和混淆之后，如下图所示可以看到体积发生了变化，体积从 9.3M 变成了 6.4 M ，所以大致上可以看出，**在开启混淆和压缩之后，原生 App 体积增长和 Flutter 差异不会太大**。

![image-20220223172138586](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image17)



另外，这里我找了一个网上的纯 Compose 做了测试，在开启混淆和压缩后，Compose 体积的大小变化就十分显著：**从 9.6 M 变成了 2.4 M ，这得益于 Compose 里的代码基本都是可以被混淆的**。

![image-20220223170138121](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image18)

![image-20220223170242884](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image19)



所以得到结论：

- **在开启了压缩之后的 Compose ，体积确确实实会比 Flutter 更小更有优势，这里的优势来源于 classes 的压缩效率**
- **React Native 的体积一般情况下都会比 Flutter 更大，同理 Weex 也类似；**



当然这个也不是绝对的，体积大小有时候也和开发者的习惯有关系，比如某天我就在群里刚好看到，某个 App 的 Flutter 业务动态库居然可以高达 77.4 M 。



![lb47319abc6776b6ac76d45775ecfa7e8-s-m0f2c227b7d605d6930401a084bd16170](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image20)



这是什么概念？一般情况下 10M - 15M 就是普通中小型 App 的 Flutter 动态库大小 ，而 大型 APP 一般也会控制在 20M - 35M 之间，就算是很大的体积了，例如 UC 也就是 35 M 、企业微信 28.9M 的水平。



![lf6f59898fbe0c6b11639e81c92796155-s-m5f015f612b387f867b36de285a780d88](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image21)



![le0e42c9311522a26d2a83afda916b3db-s-m1548598cff0bb0080caf643514588d90](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image22)



所以体积大小上，更多是开发者的主观控制，也和你是否开启混淆和压缩有关系，主要介绍这个是让大家对不同项目的打包产物有个直观的认识，从而对选择哪种开发框架提供一个判断的依据。

### 构建过程

接下来聊聊构建过程，为什么聊这个，因为对于新手来说，构建过程的问题是一个很容易放弃的过程。

如下图所示就是非原生开发在运行 Flutter 时经常可以遇到的问题：

![l9d17062e9171bfc73b423f52f22bae27-s-m908dc799447e36c1a7c8ca7275416992](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image23)



如果你看到运行后一直停留在` assembleDebug` 阶段没有进入下一步，那这时候其实是 Android 在通过网络下载一些环境依赖，比如 Gradle SDK、 aar 库等这些运行所需的包，而这个过程通过 `flutter run` 或者 idea 运行是看不出来进度的，你只有进入 `andorid/` 目录下执行 `./gradlew assembleDebug` 就可以看到类似的进度：

![l0d886e19d6ba2c3eca279cea12c62628-s-me77c94c2fa3e28791919d0d3153efc9f](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image24)

例如在 Flutter 官方 Q4 的调查里，在发布应用程序时，需要处理 Xcode (iOS) 和 Gradle (Android) 是最常见的问题，为什么说这个？ 首先这里可以看出一点，**对原生平台的不熟悉会是使用跨平台开发的一个痛点**。

![0_3MXILeNbFbIFagLu](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image25)

![0_qtLcSyZO68tuY6Gk](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image26)

当然，在对比所有跨平台开发的这个环节里， Flutter 虽然不能说是最好，但是 React Native 绝对是最拉胯的，因为不管是 Weex 还是 React Native ， node_module 黑洞一直都是头痛的问题：

![image-20220223173738326](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image27)







举个例子，React Native 项目的 node_module 黑洞，经常导致了它在环境安装和运行上会给你“惊喜”，各种丰富的插件和工具，在实用的同时又成了臃肿的坑，比如这是我前段时间久违需要处理一个 React Native 项目时遇到的问题：

![l44f7689357e4deb77b7c5019177f3442-s-m2fc075a1dd990c3aaabc19acb201f279](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image28)

![lc29a1742b1876eea0deee1c895d05a1a-s-m1d64d4caf0ea69d9a76e350e370f46de](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image29)

**依赖中的依赖，各种库的版本所需的 node 环境不同，需要我从中平衡出一个合适的版本**。当然这不是最麻烦的，最麻烦的是在电脑 A 上运行成功之后，在 B 电脑  npm 之后发现无法运行的问题，相信这是每个 React Native 开发的必修课。

![](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image30)

> 从前端开发角度，比如扁平化依赖，当然扁平化依赖的展开后依赖深度就变成了数量很可观的文件目录，依赖结构变得就不直观了，当然现在的 npm ，pnpm 工具都有了新的优化，

相反 Flutter 在这方面就轻量很多，目前 Dart 的 pub 包层级很浅，路径相对清晰，这也是我觉得在这方面 Flutter 基本上比 React Native 更舒服的原因，**所以在原生环境依赖复杂度一致的情况下，Flutter 确实比 RN 更容易进入 hello world** 。



### Flutter & Compose

最后聊聊 Flutter 和 Compose 之间的对比。

相信大家对于 Flutter 和 React Native 之间的对比看得多了，因为  React Native 发布至今已经很久了，并且 Flutter 和 React Native 之间是不同公司在维护 ，而**对于 Flutter 和 Compose ，它们都是谷歌开源的项目，并且都在支持多平台，那它们之间有什么不同？应该如何选择？**



首先提一个题外话：**前端有 npm 、Flutter 有 pub 、iOS 有 cocoaPods，你可以通过它们的官网搜索你想要的库，查看它们的热度，版本，兼容和使用量等等信息，但是 Android 呢？**

Android 的 Gradle 是不是缺少了这样一个便捷的存在，以至于我们只能在 Github 通过关键字去检索，而这个影响其实也渗透到 Compose 里，这对 Compose 在跨平台发展上是一个问题。

首先谷歌官方的定义，**Compose 是 Android 的现代原生界面工具包，而且正如前面我们介绍的，它是一套全新的 UI ，所以 Compose 是有自己的平台，也就是 Android，那是它的主场**。

>  从可以看官方的 [路线图]( https://developer.android.google.cn/jetpack/androidx/compose-roadmap) 可以看出来， 谷歌对 Compose  的经历主要都是集中在 Android 原生平台，而  Compose Multiplatform 是由 JetBrains 维护的 [compose-jb ](https://github.com/JetBrains/compose-jb ) 来实现。

**Flutter 没有自己的平台** ，它是一个跨多平台的 UI 框架，它出生就是为了多平台而生，从目前支持的  Android、iOS、Web 、Window 都发布了正式版支持，而 Linux 和 MacOS 估计也不远了。

所以这是它们直接最大的区别之一：**Compose 是谷歌为 Android 设计的全新 UI 框架，并且 JetBrains  把它拓展到支持跨平台，而 Flutter 主要就是为了跨平台而生** 。

虽然都支持跨平台，但是二者之间也是有很大差异，如图所示是它们实现上的不同：

![image-20220223174643400](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image31)



在实现上的差异是： **Flutter 对外是通过一套官方的 Framework 来支持多平台，而 Compose 目前是通过多个模块不同实现来支持多平台**。

Flutter 不用说，就是通过编译时不同的命令去生成不同平台的代码，这期间统一有 Flutter framework 来完成输出，而目前 Compose 在 Web  、Desktop 和 Mobile 上的实现逻辑是并不一定能通用的，特别是 Web。

> Compose  目前在 iOS 还没有正式的支持，虽然可以通过一些方式支持，但是还不是特别方便，而在 Web 上 Compose 需要使用和导入的包也是具备特殊化，反而是 Mobile 和 Desktop 之间反而是能共用 `compose-ui` 的内容。

举个例子，在  [compose-jb ](https://github.com/JetBrains/compose-jb )  里 对 Web 的支持代码如下，可以看到导入的和使用的控件都具备它自己的特殊性。

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



所以对于 Compose 来说，更多像是：你学会了这个框架，然后就具备了写 Web 和 Desktop  的能力；而对于 Flutter 来说它在跨平台的体验会更好。

所以从我理解上是：

- **Compose 是 Jetpack 系列的全新 UI 库**，主要是被应用到 Android 界面开发，它就是为了重新定义 Android 上 UI 的编写方式， 所以你也可以选择不用，用不用都能开发 Android 的 UI，**但是如果你继续在Android 上深耕，那么你最好还是要学会**。
- **Flutter 的未来在于多平台，更稳定可靠的多平台 UI 框架。如果你的路线方向不是大前端或者多端开发者，那你可以不会也没关系。**

而从使用这角度，不管你是先学会 Compose 还是先学会 Flutter，对于你掌握另外一项技能都有帮助，相当于学会一种就等于学会另一种的 70% ：

- **如果你是原生开发，还没接触过 Flutter ， 那先去学 Compose** ，这对你的 Android 生涯更有帮助，然后再学 Flutter 也不难。
- **如果你已经在使用或者学习 Flutter ，那么请继续深造**，不必因为担心 Compose 而停滞不前，当你掌握了 Flutter 后其实离 Compose 也不远了。

> 对比了 Flutter 和 Conpose 的很多设计理念和源码，他们在实现上的相似度很高。

当然，**跨平台之所以是跨平台，首先就是要有对应原生平台的存在，** 很多原生平台的问题都需要回归到平台去解决，那些喜欢吹 xxx 制霸原生要凉的节奏，仅仅是因为“你的焦虑会成为它们的利润”，没有了平台还要跨平台干嘛？



## 一些见解

最后简单聊聊我的一些见解。

### 跨平台的底层逻辑

在 Flutter 之前，移动端跨平台的底层逻辑无非两种：

- 一种是靠 WebView 跨平台；
- 一种是靠代理原生控件跨平台；

所以早期的移动端跨平台控件一开始就 Cordova 、Ionic  等这些框架，它们的目的就是将前端 H5 的能力拓展到 App 端，让前端开发能力也可以方便开发 Android 和 iOS 应用，那时候的口号我记得是：**write Once, run everywhere** 。

后来，得益于 React 的盛行，React Native 开辟了新的逻辑：用前端的方式去写原生 App ，通过把 JS 控件转化为原生控件进行渲染，让移动端跨平台的性能脱离了 WebView 的限制，性能得到了提升，而 React Native 强调的是  **learn once, write everywhere** ，也就是你学会了 React ，可以开发网页，也可以开发 App 。

而到了 Flutter ，它直接摆脱了平台控件的依赖，它自己产出了一套平台无关的控件，通过 GPU 直接渲染出来，这样做的成本无疑是最高的，但是所带来的“解耦”和“所见即所得”无疑是最好的，而 Flutter 的口号是 **Build apps for any screen** 。

**但是如果是放到真实应用场景上，不是说 Flutter 就是最优解，而是需要衡量你的业务场景来选择合适你的框架** ， 例如：

- 如果你的业务场景是多框架混合开发，那 Flutter 明显不占据优势；
- 如果你的场景是需要很强的文本编辑和富文本场景，那 Flutter 明显不占据优势；
- 如果你的 KPI 对内存占用特别敏感，那 Flutter 也不是特别占据优势；
- 如果你需要热更新，那 Flutter 也并不占据优势；

### 热更新

既然说到热更新，就简单介绍下热更新的问题。首先 Flutter 官方并不支持热更新，不像 React Native 一样有着十分成熟且通用的 `code-push` 框架。

> 为什么呢？首先  React Native  写的 JS 代码是属于纯脚本文本，就算打包成 bundle 文件它也是纯文本格式，所以通过  `code-push`  下发一个文本 bundle 并不违规，同时  `code-push`  也没办法下发打包后的原生平台代码，因为那不合规。

Flutter 打包后的 AOT 代码属于可执行二进制文件，如果通过热更新逻辑直接下发它，那无疑是违法了苹果 App store 和 Google Play 的政策，那 Flutter 能不能热更新呢？

答案是可以的，鉴于国内对热更新的“必须性”，也诞生了许多第三方框架，例如：

> MxFlutter（腾信） 、Fair （58 同城） 、 liteApp （企业微信）、Flap （MTFlutter 美团）、flutter_code_push （chimera） 等等。

它们都不是直接下发编译后的二进制代码，例如：

- MxFlutter 是用 js/ts 写控件来下发更新；
- liteApp 是通过 vue 模版来输入；
- Flap  是对 Dart 的 DSL 和编码过程做处理下发；

这些做法都需要为了热更新去做一些牺牲，所以本质上 Flutter 在热更新这个问题一直“不友好”。

> 当然，如果不上架 Google Play ，那么 Android 热更新 so 动态库本来就不是什么门槛，所以如果你其实可以在 Android 上粗暴地使用已有的插件化方案解决。

### 多平台

最后说一些 Flutter 的多平台，还记得前面说的  **Build apps for any screen** 吗？Flutter 不也是 *write Once, run everywhere* 吗？官方不就是支持一套代码直接打包 Android、iOS、Web、Window、MacOS、Linux 这些平台吗？

**从我的经验出发，我想说 *write Once, run everywhere* 很美好，但是不现实**。 Flutter 确实可以一套代码直接运行到所有平台，但是就目前的体验而言，一套代码去适配所有平台的成本远远高于它所带来的便捷。

先说 Web ，Web 平台在几个平台里最特殊，因为它本身就需要适配 Mobile 端和 PC 端的操作逻辑，而目前Flutter Web ：

- 在  Mobile 端使用的是 `HtmlCanvas` ，也就是转化为 Web 端的“原生”控件进行渲染，这就带来了耦合和 API 适配的难度；
- 在 PC 端 Flutter 可以使用 `CanvasKit` 来进行绘制，但是它使用 `wasm` 技术目前相对“激进” ，实际无论在体积、SEO、兼容性上都存在问题；

**所以 Flutter Web 目前还不好用，那它发布的稳定版本意义在哪里？ 就在于你的代码支持打包成 Web！**

当你在构建完关于 Android 和 iOS 的应用后，你可以把 App 的一些 UI 和业务快速构建出 Web 页面，这就是它的价值所以，**你完全不需要从 0 开始去实现这部分以后的内容**，在“又不是不能用”的前提下。



> 目前比如阿里卖家、美团外卖商家课堂等等项目使用了 Flutter Web



再说 PC 端，PC 端本身的应用逻辑就和手机差异化很大：鼠标、键盘、可编窗口大小、横屏、滚动等这些方面，其实很难直接可以一套代码兼容，在我的理解更多是在  Android 和 iOS 上的一些控件、动画、UI、列表、业务逻辑等，可以在需要的时候直接在 PC 端上使用。**如果真的需要比较好的体验，个人建议还是至少把 PC 和 Mobile 分开两个业务项目实现**。

那如果真的要一套代码，有什么好的支持吗 ？也是有的，例如：  `responsive_framework` 。



![image21](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image32)

![image22](http://img.cdn.guoshuyu.cn/20220627_Flutter-FF/image33)