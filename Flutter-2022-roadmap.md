
最近 Flutter 发布了官方关于 2022 的 [战略](https://docs.google.com/document/d/e/2PACX-1vTI9X2XHN_IY8wDO4epQSD1CkRT8WDxf2CEExp5Ef4Id206UOMopkYqU73FvAnnYG6NAecNSDo9TaEO/pub) 和 [路线图](https://github.com/flutter/flutter/wiki/Roadmap) ，本篇主要针对内容做一些总结和解读，给正在使用 Flutter 或者正打算使用 Fluter 的人做个参考。


## 总结陈述相关

目前 Flutter 社区的发展已经很大，官方统计在过去的一年里，**数据上 Flutter 已经基本超过超过其他跨平台框架，成为最受欢迎的移动端跨平台开发工具，截至 2022 年 2 月，有近 50 万个应用程序使用 Flutter**。

在过去一年里， Flutter 社区有数千人为该项目提供了贡献和支持，从个人到 `Canonical`、`Microsoft`、`ByteDance` 和`阿里巴巴`等大公司都对 Flutter 提供了不少帮助。

当然 Flutter 也不是尽善尽美，Flutter 虽然也有被一些大型应用所使用，例如：`SHEIN`  （顶级时尚零售商）、`微信`（10 亿+用户 IM 应用程序）和` PUBG`  （7.5 亿+玩家大逃杀游戏），但是它在大型应用中使用并不明显。

因为在大型应用中有大量的历史需求和代码，还有重构所需的成本限制，**使用 Flutter 进行混合开发其实支持不如 `Jetpack Compose`** ，是的， Flutter 官方表示：

> *相反，Android 的 Jetpack Compose 产品非常适合这一类产品，因为它可以轻松地基于 JVM 的框架，逐步添加到现有的 Android 应用程序中*。 


**也就是从官方的角度看，混合开发下，特别是 Android 平台，其实 `Compose` 更适合混合开发，感觉这也是 `add-to-app` 的维护和推进到现在好像并不乐观的原因**。


## 展望

**Flutter 在 2022 年首要的战略目标就是月活跃用户的增长**，官方的理念就是：


> 一个 `SDK` 再优秀，如果只有少部分人在使用，那它也不能体现价值；但是一个 `SDK` 即使平庸，但是有大量开发者使用，那也会拥有一个健康繁荣的生态氛围，这样使用框架的人才能从中受益。


### 1、提升开发体验

**目前谷歌认为虽然 Dart 和 Flutter 相对原生平台会给开发者带来学习成本，但是也会带来了不错的收益**，另外得益于社区良好的发展和维护，目前 Flutter 和 Dart 丰富的开发工具和文档，可以让开发人员顺利地迁移到 Flutter，所以 Dart 和 Flutter 未来的开发体验会越来越好。

而官方未来也将持续优化 Flutter 的一些开发体验，例如： DevTools 中有助于调试性能问题的新功能。


**但是事实上在新版 `Android Stuio Bumblebee` 和 `Flutter 插件` 的体验目前并不好**，一些 `Plugin` 上功能的消失或者无法正常使用的问题其实比较让人难受，例如：**出现 iOS 运行提示 Cocospod 不存在，但是其实已经安装的问题**。

虽然这种问题通过其他方式解决并不麻烦，比如命令行运行，但是显得就很低级。目前 `Android Stuio Bumblebee Patch1` 已经解决了该问题，**但是这次更新无法增量，只能全量覆盖**。另外

还有关于 Flutter 插件上关于 module 的自动导入消失的等等 ···

> 可以看到 Flutter 已经投入很多精力和时间在改进 Flutter 的开发体验，作为目前最大体量的跨平台开发框架，时不时有些瑕疵还是可以理解，希望 2022 Flutter 能更加注重细节的问题。

### 2、跨平台

关于跨平台上体验上，在 iOS 和 Android 上 Flutter 目前已经可以说得做到了不错的体验和质量，而随着 Window 第一个稳定版本已经发布了，今年的大目标之一就是继续提高 Web 和 Desktop 相关的开发体验和交付质量。

另外 Android 开发人员正在对 `Material` 的进行支持，同时对新硬件功能和外形尺寸等进行适配，以及与 Jetpack 库和 Kotlin 代码的更好集成也都是计划之一。

最后 Flutter 在 Web 上目前已经使用了 `CanvasKit`、`WebGPU`、`AOM` 和`带有 GC 的 WebAssembly` 等新技术，在新的一年也会继续维护和提高 Web 的交付质量，例如： **在 Web 上的 hotload 以及改进 Dart-to-JS 的使用场景**。


## 2022 年路线图

- **正如前面解读的，Desktop 的投入是最主要的目标之一，从 Windows开始，然后是 Linux 和 macOS ，将尽快推进 Desktop 平台全部 Stable**。


- 关于 Web 方面，在高兼容和提高性能的同时，也打算尝试让 Flutter Web 可以嵌入到其他非 Flutter 的 HTML 页面里。

- Flutter 的 framewok 和 engine 方面， **Material 3 和支持从单个 `Isolate` 渲染到多个窗口会是很重要的一部分内容，另外还有一个大头就是改进各个平台上本编辑的体验**。其实个人认为，Flutter 在文本编辑和键盘方便的体验确实还不够好。


- Dart 语言方法主要是 2022 可能会引入静态元编程，另外语法改进，计划扩展 Dart 的编译工具链以支持编译到 `Wasm`  也在计划当中。

- 关于 Jank 问题，Flutter 已经开始考虑重构着色器了，其中 **2022 年 iOS 将会迁移到新的着色器框架上，并在后续再移植到其他平台**，但是从 [#85737](https://github.com/flutter/flutter/issues/85737) 上看，任重道远，希望不会有什么大坑吧～


## 最后

总的来看， Flutter 团队的今年的投入和计划还是占比不低，Flutter 社区的活跃也加速着 Flutter 的成熟。

但是同样随着 Flutter 项目越来越庞大，例如 [#95343](https://github.com/flutter/flutter/issues/95343) 这样的问题可能也会越来越多，因为使用的人多了，需要面对的需求就多了，细节的把控上就更具备挑战性。

同样就如官方所说，虽然 Flutter 团队有在推进混合开发的支持，但是 Flutter 从根源实现上，对于混合开发其实就很不友好，例如：`渲染同步`、`路由同步`、`混合内存优化`、`混合数据共享`等等，不是说不支持，而是成本和收获的问题，所以可以看到最近这些稳定版本，Flutter 关于 `add-to-app` 的提及相对较少，目前看来 Flutter 官方主要还是计算在**维护好 Andorid 和 iOS 平台的基础上，继续优化 Web 的质量和推进 Desktop 全平台正式发布更主流。**