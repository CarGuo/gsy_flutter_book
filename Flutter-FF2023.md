# 2023  Flutter Forward 大会回顾，快来看看 Flutter 的未来会有什么

[Flutter Forward](https://flutter.dev/events/flutter-forward) 作为一场 Flutter 的突破性发布会，事实上 [Flutter 3.7 在大会前已经发布](https://juejin.cn/post/7192468840016511034) ，所以本次大会更多是介绍未来的可能，核心集中于 *come on soon* 的支持，所以值得关注的内容很多，特别是一些 Feature 让人十分心动。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image1.png)



# 开始之前

按照惯例，在展望未来之前需要先总结过去，首先，到目前为止已经超过 700,000 个已发布应用使用了 Flutter，例如腾讯知名的 PUBG 再次登上了大会 PPT。

| ![](http://img.cdn.guoshuyu.cn/20230126_FF/image2.png) | ![](http://img.cdn.guoshuyu.cn/20230126_FF/image3.png) |
| ------------------------------------------------------ | ------------------------------------------------------ |

另外，如 [Google Classroom](https://edu.google.com/workspace-for-education/classroom/) 团队也分享了他们使用 Flutter 开发的经历和收获，包括了代码复用率和开发效率等。

| ![](http://img.cdn.guoshuyu.cn/20230126_FF/image4.png) | ![](http://img.cdn.guoshuyu.cn/20230126_FF/image5.png) |
| ------------------------------------------------------ | ------------------------------------------------------ |

> “使用 Flutter，我们将相同功能的代码大小减少了 66%……这意味着每个平台的错误更少，未来的技术债务也更少。”（Kenechi Ufondu，Google 课堂软件工程师）

另外从 Flutter 目前的用户数据情况看，当前阶段 Flutter 还是很受欢迎的。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image6.png)

而关于 Flutter 3.7 部分这里就不再赘述，感兴趣可以看前面已经发布的 [Flutter 3.7 的更新说明](https://juejin.cn/post/7192468840016511034) 。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image7.png)

**本次 Flutter 还安利了两个低代码的友商平台：[FlutterFlow](https://flutterflow.io/) 和 [WidgetBook](https://www.widgetbook.io/)** 。

不得不说它们的成熟度都挺高的，例如 FlutterFlow 的在线调试运行和翻译支持就相当惊艳。

| ![](http://img.cdn.guoshuyu.cn/20230126_FF/image8.png)  | ![](http://img.cdn.guoshuyu.cn/20230126_FF/image9.png)  |
| ------------------------------------------------------- | ------------------------------------------------------- |
| ![](http://img.cdn.guoshuyu.cn/20230126_FF/image10.png) | ![](http://img.cdn.guoshuyu.cn/20230126_FF/image11.png) |

另外  WidgetBook 作为开源项目，它支持 Flutter 开发者针对自己的控件进行分类归纳，同时可以在使用 Widgetbook Cloud 的情况下，将 Widget 与 Figma 同步并和团队共享，为设计和开发人员提供更灵活的协作工具。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image12.png)

> FlutterFlow 并不是完全免费哦。

# Dart 3 alpha

本次大会的另外一个重点就是 Dart 3 alpha ，其实在此之前官方就有提前预热过，在[《Flutter 的下一步， Dart 3 重大变更即将在 2023 到来》](https://juejin.cn/post/7174985128799076389) 里我们就提前预览过对应更新，其中大家最关注的莫过于 [Records](https://github.com/dart-lang/language/blob/master/accepted/future-releases/records/records-feature-specification.md)  和  [Patterns](https://github.com/dart-lang/language/blob/master/accepted/future-releases/0546-patterns/feature-specification.md#patterns ) 。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image13.png)

**Records 支持高效简洁地创建匿名复合值，不需要再声明一个类来保存，而在 Records 组合数据的地方，Patterns 可以将复合数据分解为其组成部分**。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image14.png)

> 例如要将 `geoLocation` 上面的返回值（由一对整数组成的记录）解构为两个单独的 `int` 变量 `lat`和 `long`，就可以使用这样的 Patterns 声明。

Patterns 是完全类型安全的支持，并且会在开发过程中进行错误检查。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image15.png)

你还可以对值的类型进行 Patterns 匹配，通过 `switch`可以使用匹配类型的 Patterns ，以及每种类型的字段。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image16.png)

当然，Dart 3 还有一个重点就是 100% 空安全的要求，也就是不再支持非空安全的代码，这对于旧项目来说是很大的挑战，相信还是有相当一大部分人的 Flutter 项目一直维持在低版本。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image17.png)

Dart 3 还进行了很大程度的优化， 例如 Dart 3  进行了清理一些不必要的 API ，同时对编译做了很大的优化，例如下图是变异后的代码对比。

| ![](http://img.cdn.guoshuyu.cn/20230126_FF/image18.png) | ![](http://img.cdn.guoshuyu.cn/20230126_FF/image19.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |

另外 Dart 3 将支持更多的平台架构，例如  [RISC-V](https://en.wikipedia.org/wiki/RISC-V) ，同时还在覆盖 Windows 上的 ARM64 支持，而 Web 上 Dart 3 也将可以脱离 Flutter 直接支持 [WebAssembly (Wasm)](https://webassembly.org/) 。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image20.png)

最后在新工具的支持下，Dart 可以根据 C/ObjC/Swift/Java/Kotlin 代码的头文件/接口文件，自动创建具有 Dart 接口的绑定，以及那些跨语言调用所需的自动绑定，也就是 FFIgen + JNIgen。

> 具体可见：https://github.com/flutter/samples/blob/main/experimental/pedometer/README.md

| ![](http://img.cdn.guoshuyu.cn/20230126_FF/image21.png) | ![](http://img.cdn.guoshuyu.cn/20230126_FF/image22.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |



# Web

本次还有一个惊喜就是  add-to-web 要来了， 一个叫做 **element embedding** 的支持即将到来。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image23.png)

**element embedding 允许将 Flutter 添加到任何 Web `<div>`中**  ，当以这种方式嵌入时，Flutter 就变成了一个 Web 组件与 Web DOM 完全集成，甚至可以使用 CSS 来设置父 Flutter 对象的样式。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image24.gif)

> 例如将 Flutter 嵌入到基于 HTML 的网页中，然后使用 CSS 旋转效果，并且在旋转时 Flutter 内容仍可以交互。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image25.png)

同时 Dart 3 还对  Pub 上的 [js 包](http://pub.dev/packages/js)进行了一些重大更改，从而实现 **JavaScript 和  Dart 之间可以直接调用**，如里使用 `@JSExport` 属性注释 Dart 代码中的任何函数，然后从  JS 代码中调用它。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image26.png)

除此之外 Flutter Web 也有一系列的优化计划，其中针对体积大小的优化是最重要的指标之一。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image27.png)

从官方提供的数据下看，未来 Flutter Web 的加载速度将会不断提升。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image28.png)

最后，现在 Flutter 支持在 Web 上的使用  Pixel shaders ，从而实现各种炫酷的视觉效果。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image29.png)

![](http://img.cdn.guoshuyu.cn/20230126_FF/image30.gif)



# Flutter 新闻工具包

本次还有一个有意思但是对国内比较鸡肋的介绍： [Flutter News Toolkit](https://github.com/flutter/news_toolkit)，一个用来加速新闻应用开发的免费 Flutter 应用模板。

这是 Flutter 团队和 [GNI](https://newsinitiative.withgoogle.com/) 合作的项目，官方宣称与 iOS 和 Android 上的传统双端开发相比，在该领域使用 FNT 可以节省高达 80% 的时间。

| ![](http://img.cdn.guoshuyu.cn/20230126_FF/image31.png) | ![](http://img.cdn.guoshuyu.cn/20230126_FF/image32.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |



# 使用 Wonderous 适应大屏幕

Wonderous 早在去年 9 月份官方就[推荐过一次](https://mp.weixin.qq.com/s/cAwU2RmG-VtTBjPLweoobg) ，这一次主要是介绍了 Wonderous 的下一个版本，**增加了对可折叠设备、平板电脑和平板电脑横向的支持**。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image33.png)

> 此次迭代同时测试了 Flutter 对不同设备格式的适配能力， 具体可见：https://github.com/gskinnerTeam/flutter-wonderous-app

![](http://img.cdn.guoshuyu.cn/20230126_FF/image34.png)



#  Impeller

**随着 3.7 的发布，Impeller 现在已经可以在 iOS 上进行预览**。

Impeller 针对 Flutter 进行了优化，提供了更大的灵活性和对图形管道的控制支持。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image35.png)

例如使用预编译着色器，减少运行时由着色器编译引起的丢帧，利用 Metal 和 Vulkan 中的原始支持等等。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image36.png)

除了让 UI 更流畅，Impeller 还可以在某些极端情况下显着提高性能，比如大会介绍的一个例子：

> 左边是默认渲染器，右边是 Impeller，可以看到滚动是左侧因为性能问题导致帧速率为 7-10 fps，而右侧 Impeller 可以稳定在 60 fps  。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image37.png)



# 3D

**本次最后一个亮点就是 Flutter 未来将正式支持 3D 渲染**，同时也代表着 Flutter 在游戏领域的更进一步。

> 其实从去年的 I/O 也好，还有本次  [Flutter Forward](https://flutter.dev/events/flutter-forward)  提前预热的相关内容，可以看到 Flutter 进军游戏领域一直没有停歇。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image38.png)

在本次演示中，除了支持 3D 渲染之外，还支持对 3D 文件资源进行 hotload 、添加动画支持。

| ![](http://img.cdn.guoshuyu.cn/20230126_FF/image39.png) | ![](http://img.cdn.guoshuyu.cn/20230126_FF/image40.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |

可以看到，在演示中多个 3D 模型同时渲染动画的情况下，画面依然可以流畅运行，这绝对是本次 Flutter Forward 最让人期待的特性。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image41.gif)

最后官方还演示了在低端 iPhone 上的 3d 游戏场景（有指纹解锁的老 iPhone ），可以看到画面还是相当流畅。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image42.gif)



# 最后

**看完之后你是不是蠢蠢欲动？但是这里面绝大多的都还只是开发中，可能会在未来可能还会有其他变动**，而本次  Flutter Forward  展示它们的目的，相信也是官方想让大家更直观地了解 Flutter 未来的方向。

最后总结一下，本次  Flutter Forward  主要的核心内容有：

-  Impeller
- 3D 支持
- add-to-web 支持
- Dart 3 

让我们期待未来 Flutter 的更新能让这些 Feature 都能用上吧，在没有坑的情况下～