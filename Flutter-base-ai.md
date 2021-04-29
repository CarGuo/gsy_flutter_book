
> 因为最近公司来了新人，之前很少接触过跨平台应用开发，所以为了给他们介绍关于 Flutter 的一些基础，这里特意整理了一份通用性质的常识性讲解，**结尾顺便介绍一个有趣的案例**。


## 一、单页面应用

了解 Flutter 之前，首先介绍一个简单基础知识点，**那就是大部分的移动端跨平台框架都是“单页面”应用**。

什么是“单页面”应用？也就是对于原生 Android 和 iOS 而言，**整个跨平台 UI 默认都是运行在一个 `Activity` / `ViewController` 上面**，默认情况下只会有一个  `Activity` / `ViewController`， Flutter、 ReactNative 、Weex 、Ionic 默认情况下都是如此，**所以一般情况下框架的路由和原生的路由是没有直接关系**。

举个例子，如下图所示，

- 在当前 Flutter 端路由堆栈里有 `FlutterA` 和 `FlutterB` 两个页面 Flutter 页面；
- 这时候打开新的 `Activity` / `ViewController`，启动了**原生页面X**，可以看到**原生页面X** 作为新的原生页面加入到原生层路由后，把 `FlutterActivity` / `FlutterViewController` 给挡住，也就是把  `FlutterA` 和 `FlutterB` 都挡住；
- 这时候在 Flutter 层再打开新的 `FlutterC` 页面，可以看到依然会被原生页面X挡住；

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-base-ai/image1)

所以通过这部分内容可以看出来，**跨平台应用默认情况下作为单页面应用，他们的路由堆栈是和原生层存在不兼容的隔离**。

> 当然这里面重复用了一个词：**“默认”**，也就是其实可以支持自定义混合堆栈的，比如官方的 `FlutterEngineGroup` ，第三方框架 `flutter_boost` 、 `mix_stack` 、`flutter_thrio` 等等。

## 二、渲染逻辑

介绍完“单页面”部分的不同，接下来讲讲 Flutter 在渲染层面的不同。

在渲染层面 Flutter 和其他跨平台框架存在较大差异，如下图所示是现阶段常见的渲染模式对比：


![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-base-ai/image2)

- 对于原生 Android 而言，是**原生代码经过 skia 最后到 GPU 完成渲染绘制**，Android 原生系统本身自带了 skia；
- 对于 Flutter 而言，**Dart 代码里的控件经过 skia 最后到 GPU 完成渲染绘制**，这里在 Andriod 上使用的系统的 skia ，而在 iOS 上使用的是打包到项目里的 skia ；
- 对于 ReactNative/Weex 等类似的项目，它们是**运行在各自的 JS 引擎里面，最后通过映射为原生的控件，利用原生的渲染能力进行渲染**；
- 对于 ionic 等这类 Hybird 的跨平台框架，使用的主要就是 **WebView 的渲染能力**；

> skia 在 Android 上根据不同情况就可能会是 `OpenGL` 或者 `Vulkan` ，在 iOS 上如果有支持 `Metal` 也会使用 `Metal` 加速渲染。


通过前面的介绍，可以看出了：

`ReactNative/Weex` 这类跨平台和原生平台存在较大关联：

- 好处就是：如果需要使用原生平台的控件能力，接入成本会比较低；
- 坏处自然就是： 渲染严重依赖平台控件的能力，耦合较多，不同系统之间原生控件的差异，同个系统的不同版本在控件上的属性和效果差异，组合起来在后期开发过程中就是很大的维护成本。、

> 例如：*在 iOS 上调试好的样式，在 Android 上出现了异常；在 Android 上生效的样式，在 iOS 上没有支持；在 iOS 平台的控件效果，在 Android 上出现了不一样的展示，比如下拉刷新，Appbar等；*

`Flutter` 与之不同的地方就是渲染直接利用 skia 和 GPU 交互，在 Android 和 iOS 平台上实现了平台无关的控件，简单说就是 `Flutter` 里的 `Widget` 大部分都是和 Android 和 iOS 没有关系。

**本质上原生平台是提供一个类似 `Surface` 的画板，之后剩下的只需要由 Flutter 来渲染出对应的控件**

> 一般是使用 `FlutterView` 作为渲染承载，它在 Android 上内部使用可以是 `SurfaceView` 、 `TextureView` 或者 `FlutterImageView` ；在 iOS 上是 `UIView` 通过 `Layer` 实现的渲染。

**所以 Flutter 的控件在不同平台可以得到一致效果，但是和原生控件进行混合也会有较高的成本和难度**，在接入原生控件的能力上，Flutter 提供了 `PlatformView` 的机制来实现接入， `PlatformView` 本身的实现会比较容易引发内存和键盘等问题，所以也带来了较高的接入成本。

## 三、项目结构


![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-base-ai/image3)

如上图所示，默认情况下 Flutter 工程结构是这样的：

- `android` 原生的工程目录，可以配置原生的 `appName` ，`logo` ，启动图， `AndroidManifest` 等等；
- `ios` 工程目录，配置启动图，`logo`，应用名称，`plist` 文件等等；
- `build` 目录，这个目录是编译后出现，一般是 git 的 ignore 目录，打包过程和输入结果都在这个目录下，Android 原生的打包过程输出也被重定向输出到这里；
- `lib` 目录，用来写 dart 代码的，入口文件一般是 `main.dart`；
- `pubspec.yaml` 文件，Flutter 工程里最重要的文件之一，不管是静态资源引用（图片，字体）、第三方库依赖还是 Dart 版本声明都写在这里。

如下图是使用是关于 `pubspec.yaml` 文件的结构介绍

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-base-ai/image4)

> 需要注意，当这个文件发生改变时，需要重新执行 `flutter pub get`，并且 `stop` 应用之后重新运行项目，而不是使用 `hotload` 。

如下所示是 Flutter 的插件工程，Flutter 中分为 `Package` 和 `Plugin` ，如果是  

- `Package` 项目属于 Flutter 包工程，不会包含原生代码；
- `Plugin`  项目属于 Flutter 插件工程，包含了 Android 和 iOS 代码；

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-base-ai/image5)

## 四、打包调试

Flutter 运行之前都需要先执行 `flutter pub get` 来先同步下载第三方代码，下载的第三方代码一般存在于（Mac） `/Users/你的用户名/.pub-cache` 目录下 。

下载依赖成功后，可以直接通过 `flutter run` 或者 IDE 工具点击运行来启动 Flutter 项目，这个过程会需要原生工程的一些网络同步工作，比如：

- Android 上的 Gradle 和 aar 依赖包同步；
- iOS 上的需要 pod install 同步一些依赖包；

如果需要在项目同步过程中查看进度：

- Android 可以到 `android/` 目录下执行 `./gradlew assembleDebug` 查看同步进度；
- iOS 可以到 `ios/` 目录下执行 `pod install`，查看下载进度；

同步的插件中，如果是 `Plugin` 带有原生平台的代码逻辑，那么可以在项目根目录下看到一个叫做 `.flutter_plugins` 和 `.flutter-plugins-dependencies` 的文件，它们是 git ignore 的文件，Android 和 iOS 中会根据这个文件对本地路径的插件进行引用，后面 Flutter 运行时会根据这个路径动态添加依赖。

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-base-ai/image6)


默认情况下 Flutter 在 **debug 下是 JIT 的运行模式**所以运行效率会比较低，速度相对较慢，但是可以 hotload。

在 **release 下是 AOT 模式**，运行速度会快很多，同时 Flutter 在**模拟器上一般默认会使用 CPU 运行，在真机上会使用 GPU 运行**，所以性能表现也不同。

> 另外 iOS 14 真机上 debug 运行，断后链接后再次启动是无法运行的。

如果项目存在缓存问题，可以**直接执行 `flutter clean` 来清理缓存**。

最后说下 Flutter 的为什么不支持热更新？ 

前面讲过 ReactNative 和 Weex 是通过将 JS 代码里的控件转化为原生控件进行渲染，所以本质上 JS 代码部分都只是文本而已，利用 `code-push` 推送文本内容本质上并不会违法平台要求。

而 Flutter 打包后的文件是二进制文件，推送二进制文件明显是不符合平台要求的。

> release 打包后的 Android 会生成 `app.so` 和 `flutter.so` 两个动态库；iOS 会生成 `App.framework` 和 `Flutter.framework` 两个文件。

## 五、Flutter 简单介绍

最后简单介绍下 Flutter Dart 部分相关的内容，对于原生开发来说，Flutter 主要优先了解这三点：**响应式、`Widget` 和状态管理** 。

### 响应式

响应式编程也叫做声明式编程，这是现在前端开发的主流，当然对于客户端开发的一种趋势，比如 `Jetpack Compose` 、`SwiftUI` 。

> Jetpack Compose 和 Flutter 的在某些表层上看真的很相似。

**响应式简单来说其实就是你不需要手动更新界面，只需要把界面通过代码“声明”好，然后把数据和界面的关系接好，数据更新了界面自然就更新了。**

从代码层面看，对于原生开发而言，**没有 `xml` 的布局，没有 `storyboard`**，布局完全由代码完成，所见即所得，同时也**不会需要操作界面“对象”去进行赋值和更新，你所需要做的就是配置数据和界面的关系**。

> 响应式开发比数据绑定或者 MVVM 不同的地方是，它每次都是重新构建和调整整个渲染树，而不是简单的对 UI 进行 `visibility` 操作。

### Widget

`Widget` 是 Flutter 里的基础概念，也是我们写代码最直接接触的对象，**Flutter 内一切皆 Widget ，Widget 是不可变的（immutable），每个 Widget 状态都代表了一帧。** 

所以 `Widget` 作为一个 `immutable` 对象，它不可能是真正工作的 UI 对象，**在 Flutter 里真正的 `View` 级别对象是 `Element` 和 `RenderObject` ， 其中 `Element`  的抽象对象就是我们经常用到的 `BuildContext`**。

举个例子，如下代码所示，其中 `testUseAll` 这个 `Text` 在同一个页面下在三处地方被使用，并且代码可以正常运行渲染，如果是一个真正的 `View` ，是不能在一个页面下这样被多个地方加载使用的。

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-base-ai/image7)

所以 Flutter 中 **`Widget` 更多只是配置文件的地位**，用于描述界面的配置代码，具体它们的实现逻辑、关系还有分类，可以看我写的书 **《Flutter开发实战详解》中** 的第三章和第四章部分。

### 状态管理

Flutter 作为响应式开发框架，本质上它其实不再追求什么 MVC 、MVP、MVVVM 的设计模式，它更多是对界面状态的管理。

> 就是要抛弃以前在原生平台上，需要拿到 `View` 的对象，然后做对其进行 UI 设置这种思路。

Flutter 上更多需要管理数据的流向，比如：

- 数据是从哪里发出，然后再到哪里消费；
- 数据是单向还是双向；
- 数据需要进过哪些中间转化；
- 数据是从哪一层开始往下传递；
- 数据绑定了哪些地方；
- 如何实现多个地方的局部刷新；

因为对于界面来说，它只需要根据数据进行变化即可，我们不需要获取它去单独设置，所以 Flutter 中有各种数据管理和共享的框架，比较流行的有 `provider` 、 `getx` 、 `flutter_redex `、`flutter_mobx` 等等。

### 有趣的问题

最后说一个比较有意思的问题，之前有人说 **Flutter 里是传递值还是引用**？这个问题看过网上有不少文章解释得很奇怪，存在一些误导性的解释，其实这个问题很简单：

**Flutter 里一切皆是对象， 就连 `int` 、 `double` 、`bool` 也是对象，你觉得对象传递的是什么？** 

但是对于对象的操作是有区别的，比如对于 `int` 、  `double` 等 `class` 的 `+` 、`-` 、`*` 、 `\` 等操作，其实是执行了这个 `class` 的 `operator` 操作符的操作， 然后返回了一个 `num` 对象。

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-base-ai/image8)

而对于这个操作，只需要要去 `dart vm` 看看 `Double` 对象在进行加减乘除时做了什么，如下图所示，看完相信就知道方法里传递 `int` 、`double` 对象后进行操作会是什么样的结果。

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-base-ai/image9)






