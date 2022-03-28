Hello 大家好，我是《Flutter 开发实战详解》的作者，Github GSY 系列开源项目的负责人郭树煜，目前开源的 [gsy_github_app_flutter](https://github.com/CarGuo/gsy_github_app_flutter) 以 13k+ 的 star 在中文总榜的 dart 排行上暂处第一名。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image1)


> 数据来源： https://github.com/GrowingGit/GitHub-Chinese-Top-Charts/blob/master/content/charts/overall/software/Dart.md


## 开始之前

Flutter 开源至今其实已经将近 7 年的时间，而我是从 2017 年开始接触的 Flutter ，如今在 2022 年看来，**Flutter 已经是不再是以前小众的跨平台框架**。

如图所示，可以看到如今的 Flutter 已经有高达 `135k` 的 star ， `10k+` Open 和 `50k+` Closed 的 issue 也足以说明 Flutter 社区和用户的活跃度。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image2)


在去年下半旬的数据调查中，**Flutter 也成为了排名第一的被使用和被喜爱的跨平台框架**，这里说这么说并不是说你一定要去学 Flutter ，而是说不管我们喜不喜欢，目前 Flutter 已经证明了它的价值。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image3)

![image.png](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image4)

> 数据来源： https://rvtechnologies.com/10-reasons-why-flutter-is-growing-as-a-cross-platform-framework/


其实在去年和前年，我也做过一些简单的统计：

- 2020 年 `52` 个样本中有 `19` 个 App 里出现了 Flutter；
- 2021 年 `46` 个样本中有 `24` 个 App 里出现了 Flutter；

这份数据样本比较小，主要是从我个人常用的 App 进行统计，所以不准确也不具备代表性，但是可以一定程度反映了国内现在 Flutter 应用使用的情况。

> 数据来源： https://juejin.cn/post/7012382656578977806


最后  Flutter 在 Web 和 PC 端也有支持，但是我暂时还未投入生产使用，目前可以简单总结就是：


#### Web

- Flutter Web 目前支持 `HtmlCanvas` 和 `CanvasKit`(WASM)，默认是移动端使用 HTML 而桌面端使用 WASM；
- pub.dev 上 `60%` 左右的包是 Web 兼容；
- 体积和 SEO 是使用过程中最需要提前考虑的问题；

> 可参考资料： https://juejin.cn/post/7059619009213726733


#### Desktop

PC 端目前相对更弱势一些，如果是和 `Electron` 比较，可以简单认为， Flutter PC 版可以使用更低的内存占用和更小的体积，甚至更好的 FFI 继承 C 的能力，但是同样的生态目前也更弱，第三方支持相对较少，需要自己独立解决的问题会相对更多。

> Window 可投入生产版本已经正式发布
>
> 可参考资料： https://juejin.cn/post/7018450473292136456


## Flutter 和原生开发的不同


Flutter 作为跨平台的 UI 框架，它主要的特点是做到：**在性能还不错的情况下，框架的 UI 与平台无关**，而从平台的角度上看， Flutter 其实就是一个“单页面”的应用。


### 1、单页面应用

什么是“单页面”应用？

也就是对于原生 Android 和 iOS 而言，**整个跨平台 UI 默认都是运行在一个 `Activity` / `ViewController` 上面**，默认情况下只会有一个  `Activity` / `ViewController`， 事实上 Flutter、 ReactNative 、Weex 、Ionic 默认情况下都是如此，**所以一般情况下框架的路由和原生的路由也是没有直接关系**。

举个例子，如下图所示，

- 在当前 Flutter 端路由堆栈里有 `FlutterA` 和 `FlutterB` 两个页面 Flutter 页面；
- 这时候打开新的 `Activity` / `ViewController`，启动了**原生页面X**，可以看到**原生页面 X** 作为新的原生页面加入到原生层路由后，把 `FlutterActivity` / `FlutterViewController` 给挡住，也就是把  `FlutterA` 和 `FlutterB` 都挡住；
- 这时候在 Flutter 层再打开新的 `FlutterC` 页面，可以看到依然会被原生页面X挡住；

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image5)

所以通过这部分内容可以看出来，**跨平台应用默认情况下作为单页面应用，他们的路由堆栈是和原生层存在不兼容的隔离**。

> 当然这里面重复用了一个词：**“默认”**，也就是其实可以支持自定义混合堆栈的，比如官方的 `FlutterEngineGroup` ，第三方框架 `flutter_boost` 、 `mix_stack` 、`flutter_thrio` 等等都是为了解决混合开发的场景。

### 2、渲染逻辑

介绍完“单页面”部分的不同，接下来讲讲 Flutter 在渲染层面的不同。

在渲染层面 Flutter 和其他跨平台框架存在较大差异，如下图所示是现阶段常见的渲染模式对比：


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image6)

- 对于原生 Android 而言，是**原生代码经过 skia 最后到 GPU 完成渲染绘制**，Android 原生系统本身自带了 skia；

- 对于 Flutter 而言，**Dart 代码里的控件经过 skia 最后到 GPU 完成渲染绘制**，这里在 Andriod 上使用的系统的 skia ，而在 iOS 上使用的是打包到项目里的 skia ；

- 对于 ReactNative/Weex 等类似的项目，它们是**运行在各自的 JS 引擎里面，最后通过映射为原生的控件，利用原生的渲染能力进行渲染**；（ PS，今年官方终于要发布重构的版本了：[2022 年 React Native 的全新架构更新](https://juejin.cn/post/7063738658913779743) ）

- 对于 ionic 等这类 Hybird 的跨平台框架，使用的主要就是 **WebView 的渲染能力**；

> skia 在 Android 上根据不同情况就可能会是 `OpenGL` 或者 `Vulkan` ，在 iOS 上如果有支持 `Metal` 也会使用 `Metal` 加速渲染。

通过前面的介绍，可以看出了：

`ReactNative/Weex` 这类跨平台和原生平台存在较大关联：

- 好处就是：如果需要使用原生平台的控件能力，接入成本会比较低；

- 坏处自然就是： 渲染严重依赖平台控件的能力，耦合较多，不同系统之间原生控件的差异，同个系统的不同版本在控件上的属性和效果差异，组合起来在后期开发过程中就是很大的维护成本。

> 例如：*在 iOS 上调试好的样式，在 Android 上出现了异常；在 Android 上生效的样式，在 iOS 上没有支持；在 iOS 平台的控件效果，在 Android 上出现了不一样的展示，比如下拉刷新，Appbar等；* 如果这些问题再加上每个系统版本 Framework 的细微差别，就会变得细思极恐。
>
> 另外再说个例子，Android 和 iOS 的阴影效果差异。


`Flutter` 与之不同的地方就是渲染直接利用 skia 和 GPU 交互，在 Android 和 iOS 平台上实现了平台无关的控件，简单说就是 `Flutter` 里的 `Widget` 大部分都是和 Android 和 iOS 没有关系。

**本质上原生平台是提供一个类似 `Surface` 的画板，之后剩下的只需要由 Flutter 来渲染出对应的控件**

> 一般是使用 `FlutterView` 作为渲染承载，它在 Android 上内部使用可以是 `SurfaceView` 、 `TextureView` 或者 `FlutterImageView` ；在 iOS 上是 `UIView` 通过 `Layer` 实现的渲染。

**所以 Flutter 的控件在不同平台可以得到一致效果，但是和原生控件进行混合也会有较高的成本和难度**，在接入原生控件的能力上，Flutter 提供了 `PlatformView` 的机制来实现接入， `PlatformView` 本身的实现会比较容易引发内存和键盘等问题，所以也带来了较高的接入成本。

> 目前最新版本基本强制要求 Hybrid Composition ，所以相对以前的 `PlatformView`  会好一点点，当然可能遇到的问题还是有的。比如密码键盘切换，切换页面时 `PlatformView` 时页面闪动。

### 3、项目结构


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image7)

如上图所示，默认情况下 Flutter 工程结构是这样的：

- `android` 原生的工程目录，可以配置原生的 `appName` ，`logo` ，启动图， `AndroidManifest` 等等；
- `ios` 工程目录，配置启动图，`logo`，应用名称，`plist` 文件等等；
- `build` 目录，这个目录是编译后出现，一般是 git 的 ignore 目录，打包过程和输入结果都在这个目录下，Android 原生的打包过程输出也被重定向输出到这里；
- `lib` 目录，用来写 dart 代码的，入口文件一般是 `main.dart`；
- `pubspec.yaml` 文件，Flutter 工程里最重要的文件之一，不管是静态资源引用（图片，字体）、第三方库依赖还是 Dart 版本声明都写在这里。

如下图是使用是关于 `pubspec.yaml` 文件的结构介绍

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image8)

> 需要注意，当这个文件发生改变时，需要重新执行 `flutter pub get`，并且 `stop` 应用之后重新运行项目，而不是使用 `hotload` 。

如下所示是 Flutter 的插件工程，Flutter 中分为 `Package` 和 `Plugin` ，如果是  

- `Package` 项目属于 Flutter 包工程，不会包含原生代码；
- `Plugin`  项目属于 Flutter 插件工程，包含了 Android 和 iOS 代码；

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image9)

### 4、打包调试

Flutter 运行之前都需要先执行 `flutter pub get` 来先同步下载第三方代码，下载的第三方代码一般存在于（Mac） `/Users/你的用户名/.pub-cache` 目录下 。

下载依赖成功后，可以直接通过 `flutter run` 或者 IDE 工具点击运行来启动 Flutter 项目，这个过程会需要原生工程的一些网络同步工作，比如：

- Android 上的 Gradle 和 aar 依赖包同步；
- iOS 上需要 pod install 同步一些依赖包；

如果需要在项目同步过程中查看进度：

- Android 可以到 `android/` 目录下执行 `./gradlew assembleDebug` 查看同步进度；
- iOS 可以到 `ios/` 目录下执行 `pod install`，查看下载进度；

同步的插件中，如果是 `Plugin` 带有原生平台的代码逻辑，那么可以在项目根目录下看到一个叫做 `.flutter_plugins` 和 `.flutter-plugins-dependencies` 的文件，它们是 git ignore 的文件，Android 和 iOS 中会根据这个文件对本地路径的插件进行引用，后面 Flutter 运行时会根据这个路径动态添加依赖。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image10)


默认情况下 Flutter 在 **debug 下是 JIT 的运行模式**所以运行效率会比较低，速度相对较慢，但是可以 hotload。

在 **release 下是 AOT 模式**，运行速度会快很多，同时 Flutter 在**模拟器上一般默认会使用 CPU 运行，在真机上会使用 GPU 运行**，所以性能表现也不同。

> 另外 iOS 14 真机上 debug 运行，断后链接后再次启动是无法运行的。

如果项目存在缓存问题，可以**直接执行 `flutter clean` 来清理缓存**。

**最后说下 Flutter 的为什么不支持热更新？**

前面讲过 ReactNative 和 Weex 是通过将 JS 代码里的控件转化为原生控件进行渲染，所以本质上 JS 代码部分都只是文本而已，利用 `code-push` 推送文本内容本质上并不会违法平台要求。

而 Flutter 打包后的文件是二进制文件，推送二进制文件明显是不符合平台要求的。

> release 打包后的 Android 会生成 `app.so` 和 `flutter.so` 两个动态库；iOS 会生成 `App.framework` 和 `Flutter.framework` 两个文件。


所以 Flutter 的第三方热更新市面上常见的有：`MxFlutter`、`Fair`、`Kraken`、`liteApp`、`NEJFlutter`、`Flap`（MTFlutter）、`flutter_code_push` (chimera) 等等，而这些框架都不会是直接下发可执行的二进制文件，大致市面上根据 DSL 的不同，动态化方案可以分为两大类：面向前端的和面向终端。

如下图所示，例如 WXG 的 `LiteApp`、腾讯的 `MxFlutter` 和阿里的 `Kraken` （北海） 就是面向前端 ，使用 JS/TS 。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image11)

>  参考资料： https://mp.weixin.qq.com/s/OpgqjTIiB6z9YiN1FTDeYQ

如下图所示：例如 `Flap` 、`flutter_code_push` 就是面向终端，主要是对 Dart 的 DSL 或者编码下功夫。



![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image12)


>  参考资料： https://tech.meituan.com/2020/06/23/meituan-flutter-flap.html


最后，关于 Flutter 热更新动态化的支持，可以参考这个表格：



![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image13)


> 参考资料：Flutter实现动态化更新-技术预研 https://juejin.cn/post/7033708048321347615



### 5、Flutter 简单介绍

这里介绍下 Flutter Dart 部分相关的内容，对于原生开发来说，Flutter 主要优先了解**响应式和`Widget`** 。

#### 响应式

响应式编程也叫做声明式编程，这是现在前端开发的主流，当然对于客户端开发的一种趋势，比如 `Jetpack Compose` 、`SwiftUI` 。

> Jetpack Compose 和 Flutter 的在某些表层上看真的很相似。

**响应式简单来说其实就是你不需要手动更新界面，只需要把界面通过代码“声明”好，然后把数据和界面的关系接好，数据更新了界面自然就更新了。**

从代码层面看，对于原生开发而言，**没有 `xml` 的布局，没有 `storyboard`**，布局完全由代码完成，所见即所得，同时也**不会需要操作界面“对象”去进行赋值和更新，你所需要做的就是配置数据和界面的关系**。

> 响应式开发比数据绑定或者 MVVM 不同的地方是，它每次都是重新构建和调整整个渲染树，而不是简单的对 UI 进行 `visibility` 操作。

如下图所示，是 Flutter 下针对响应式 UI 的典型第三方示例： `responsive_framework`


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image14)

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image15)

##### Widget

`Widget` 是 Flutter 里的基础概念，也是我们写代码最直接接触的对象，**Flutter 内一切皆 Widget ，Widget 是不可变的（immutable），每个 Widget 状态都代表了一帧。** 

所以 `Widget` 作为一个 `immutable` 对象，它不可能是真正工作的 UI 对象，**在 Flutter 里真正的 `View` 级别对象是 `Element` 和 `RenderObject` ， 其中 `Element`  的抽象对象就是我们经常用到的 `BuildContext`**。

举个例子，如下代码所示，其中 `testUseAll` 这个 `Text` 在同一个页面下在三处地方被使用，并且代码可以正常运行渲染，如果是一个真正的 `View` ，是不能在一个页面下这样被多个地方加载使用的。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image16)

所以 Flutter 中 **`Widget` 更多只是配置文件的地位**，用于描述界面的配置代码，具体它们的实现逻辑、关系还有分类，可以看我写的书 **《Flutter开发实战详解》中** 的第三章和第四章部分。

#### 有趣的问题

最后说一个比较有意思的问题，之前有人说 **Flutter 里是传递值还是引用**？这个问题看过网上有不少文章解释得很奇怪，存在一些误导性的解释，其实这个问题很简单：

**Flutter 里一切皆是对象， 就连 `int` 、 `double` 、`bool` 也是对象，你觉得对象传递的是什么？** 

但是对于对象的操作是有区别的，比如对于 `int` 、  `double` 等 `class` 的 `+` 、`-` 、`*` 、 `\` 等操作，其实是执行了这个 `class` 的 `operator` 操作符的操作， 然后返回了一个 `num` 对象。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image17)

而对于这个操作，只需要要去 `dart vm` 看看 `Double` 对象在进行加减乘除时做了什么，如下图所示，看完相信就知道方法里传递 `int` 、`double` 对象后进行操作会是什么样的结果。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image18)


## Flutter 和 Compose

最后聊一聊 Flutter 和 Compose。

其实自从 Jetpack Compose 面世以来，关于 Flutter 与 Compose 之间的选择问题就开始在 Android 开发中出现，就如同之前有 iOSer 纠结在 Flutter 和 SwiftUI 之间选谁一样，**对于 Android 开发来说似乎“更头痛”的是 Flutter 与 Compose “同出一爹”**。

这里我只是提供一些我个人的理解，并不代表官方的观点：

**Flutter 和 Compose 的未来目标会比较一致，但是至少它们出现的初衷是不一样。**


**首先 Compose 是 Jetpack 系列的全新 UI 库**，理解下这点！Compose 是 Jetpack 系列的成员之一，所以可以被应用到 Android 界面开发中，**所以你也可以选择不用，用不用都能开发 Android 的 UI** 。

然后再说 Compose 出生的目的：就是为了重新定义 Android 上 UI 的编写方式，为了**提高 Android 原生的 UI 开发效率，让 Android 的 UI 开发方式能跟上时代的步伐**。

> 不管你喜不喜欢，声明式的界面开发就是如今的潮流，不管是 React 、SwiftUI 、Flutter 等都在表明这一点。

而对于 **Flutter 而言就是跨平台，因为 Flutter 没有自己的平台** ，有人说 `Fuchsia` 会是  Flutter 的家，但那已经属于后话，毕竟  `Fuchsia` 要先能养活自己。

因为 Flutter 出生就是为了跨平台存在的全新 UI 框架，从底层到上层都是“创新”和“大胆”的设计，就选择 Dart 本身就是一项很“大胆”的决定，甚至在 Web 平台都敢支持选用 `Canvaskit` 的 `WASM` 模式。

> 所以 Flutter 的“任性”从一出来就不被看好，当然至今也有不看好它的人，因为它某种程度很“偏激”和不友好。


另外从起源和维护上：

- Flutter 起源是 Chrome 项目组，选用了 Dart ，所以 Flutter 并不是归属于 Android 的项目；
- Compose 起源于 Android 团队，它使用的是 Kotlin ；

所以他们起源和维护都属于不同 Group ，所以从我们外界看可能会觉得有资源冲突，但是本质上他们是不同的大组在维护的。

好了，扯了那么多，总结下就是：

- **Compose 是 Android UI 的未来，现阶段你可以不会，但是如果未来你会继续在 Android 平台的话，你就必须会。** ，而 Compose 的跨平台支持也在推进，不过不是谷歌维护，而是由 Jetpack 提供的 Compose for Compose Multiplatform 。

- **Flutter 的未来在于多平台，更稳定可靠的多平台 UI 框架。如果你的路线方向不是大前端或者多端开发者，那你可以不会也没关系。**


说带了这些框架主要还是做 UI 的，学哪个看你喜欢哪个就行～当然，可能更重要是看你领导要求你用哪个，而回归到冲突的问题上， **Flutter 和 Compose 冲突吗？** 

从立项的意义上看  Flutter 和 Compose 好像是冲突的，但是**从使用者的角度看，它们并不冲突**。

因为对于开发者而言，不管你是先学会 Compose 还是先学会 Flutter，对于你掌握另外一项技能都有帮助，相当于学会一种就等于学会另一种的 70% 

从未来的角度看：

- **如果你是原生开发，还没接触过 Flutter ， 那先去学 Compose** ，这对你的 Android 生涯更有帮助，然后再学 Flutter 也不难。

- **如果你已经在使用或者学习 Flutter ，那么请继续深造**，不必因为担心 Compose 而停滞不前，当你掌握了 Flutter 后其实离 Compose 也不远了。

> 它们二者的未来都会是多平台，而我认为的冲突主要是在于动手学起来，而不是在二者之间徘徊纠结。

从现实角度出发：目前 Flutter 2.0 下的 Android  和 iOS 已经趋向稳定，Web 已经进入 Stable 分支，而 Macos/Linux/Win 也进入了 Beta 阶段，并且可以在 Stable 分支通过 snapshot 预览。**所以从这个阶段考虑，如果你需要跨平台开发，甚至 PC 平台，那么优先考虑 Flutter 吧。** 

> 你选择 React Native 也没问题，说起来最近 React Native 的版本号已经到了 0.67 了，还是突破不到 1.0 ····


当然大家可能会关心框架是否有坑的问题，**本质上所有框架都有坑，甚至网络因素都可能会成为你的痛点，问题在于你是否接受这些坑**，平台的背后本身就是“脏活”和“累活”， Flutter 的全平台之路很艰难，能做好 Android 和 iOS 的支持和兼容就很不容易了。

最后还是要例行补充这一点：

> **跨平台之所以是跨平台，首先就是要有对应原生平台的存在，** 很多原生平台的问题都需要回归到平台去解决，那些喜欢吹 xxx 制霸原生要凉的节奏，仅仅是因为“你的焦虑会成为它们的利润”。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-SQS/image19)