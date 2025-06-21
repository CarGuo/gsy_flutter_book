# 2025 跨平台框架更新和发布对比，这是你没看过的全新版本

2025 年可以说又是一个跨平台的元年，其中不妨有「鸿蒙 Next」 平台刺激的原因，也有大厂技术积累“达到瓶颈”的可能，又或者“开猿截流、降本增笑”的趋势的影响，2025 年上半年确实让跨平台框架又成为最活跃的时刻，例如：

- [Flutter  Platform 和 UI 线程合并](https://juejin.cn/post/7496397558359162934)和[Android Impeller 稳定](https://juejin.cn/post/7470457106844827687#heading-7)
- [React Native 优化 Skia 和发布全新 WebGPU 支持](https://juejin.cn/post/7501989765085298700)
- [Compose Multiplatform iOS 稳定版发布，客户端全平台稳定](https://juejin.cn/post/7501158867579387943)
- [腾讯 Kotlin 跨平台框架 Kuikly 正式开源](https://juejin.cn/post/7497558282410115091)
- [字节跨平台框架 Lynx 正式开源](https://juejin.cn/post/7478167090530320424)
- [uni-app x 跨平台框架正式支持鸿蒙](https://juejin.cn/post/7503974160264069156)
- ····

而本篇也是基于上面的内容，对比当前它们的情况和未来可能，帮助你在选择框架时更好理解它们的特点和差异。

> **就算你不用，也许面试的时候就糊弄上了**？

# Flutter

首先 Flutter 大家应该已经很熟悉了，作为在「自绘领域」坚持了这么多年的跨平台框架，相信也不需要再过多的介绍，因为是「自绘」和 「AOT 模式」，让 Flutter 在「平台统一性」和「性能」上都有不错的表现。

> 开发过程过程中的 hotload 的支持程度也很不错。

而自 2025 以来的一些更新也给 Flutter 带来了新的可能，比如 [Flutter  Platform 和 UI 线程合并](https://juejin.cn/post/7496397558359162934) ，简单来说就是以前 Dart main Thread 和 Platform UI Thread 是分别跑在独立线程，它们的就交互和数据都需要经过 Channel 。

![](https://img.cdn.guoshuyu.cn/mermaid-diagram-2025-05-15-144352.png)

而合并之后，Dart main 和 Platform UI 在 Engine 启动完成后会合并到一个线程，**此时 Dart 和平台原生语言就支持通过同步的方式去进行调用**，也为 Dart 和 Kotlin/Java，Swift/OC 直接同步互操作在 Framework 提供了进一步基础支持。

> 当然也带来一些新的问题，具体可见线程合并的相关文章。

**另外在当下，其实 Flutter 的核心竞争力是 Impeller** ，因为跨平台框架不是系统“亲儿子”，又是自绘方案，那么在性能优化上，特别 iOS 平台，就不得不提到着色器预热或者提前编译。

> 传统 Skia 需要把「绘制命令」编译成可在 GPU 执行代码的过程，一般叫做着色器编译， Skia 需要「动态编译」着色器，但是 Skia 的着色器「生成/编译」与「帧工作」是按顺序处理，如果这时候着色器编译速度不够快，就可能会出现掉帧（Jank）的情况，这个我们也常叫做「着色器卡顿」

而 Impeller 正是这个背景的产物，简单说，**App 所需的所有着色器都在 Flutter 引擎构建时进行离线编译，而不是在应用运行时编译**。

![image-20250515102018153](https://img.cdn.guoshuyu.cn/image-20250515102018153.png)

这其实才是目前是 Flutter 的核心竞争力，不同于 Skia 需要考虑多场景和平台通用性，需要支持各种灵活的额着色器场景，Impeller 专注于 Flutter ，所以它可以提供更好的专注支持和问题修复，更多可见：[着色器预热？为什么 Flutter 需要？](https://juejin.cn/post/7385942645232828442)

> 当然 Skia 也是 Google 项目，对于着色器场景也有 Graphite  后端在推进支持，它也在内部也是基于 Impeller 为原型去做的改进，所以未来 Skia 也可以支持部分场景的提前编译。

而在鸿蒙平台，华为针对 Flutter 在鸿蒙的适配，在华为官方过去的分享里，也支持了 [Flutter引擎Impeller鸿蒙化](https://mp.weixin.qq.com/s/dBXQtk-x1lGBzjUSAB1yGw)，详细可见：https://b23.tv/KKNDAQB

甚至，Flutter 在类游戏场景支持也挺不错，如果配合 rive 的状态机和自适应，甚至可以开发出很多出乎意料的效果，而官方也有 Flutter 的游戏 SDK 或者 Flame 第三方游戏包支持：

![](https://img.cdn.guoshuyu.cn/image-20250515103629035.png)

最后，那么 Flutter 的局限性是什么呢？其实也挺多的，例如：

- 文字排版能力不如原生
- PC平台推进交给了 Canonical  团队负责，虽然有多窗口雏形，但是推进慢
- 不支持官方热更新，shorebird 国内稳定性一般
- 内存占用基本最高
- Web 只支持 wasm 路线
- 鸿蒙版本落后主版本太多
- 不支持小程序，虽然有第三方实现，但是力度不大
- ····

> 所以，Flutter 适合你的场景吗？

# React Native

如果你很久没了解过 RN ，那么 2025 年的 RN 会超乎你的想象，可以说 Skia 和 WebGPU 给了它更多的可能。

![img](https://img.cdn.guoshuyu.cn/ezgif-6e2a53103262dd.gif)

**RN 的核心之一就是对齐 Web 开发体验**，其中最重要的就是 0.76 之后 New Architecture 成了默认框架，例如 Fabric, TurboModules, JSI 等能力解决了各种历史遗留的性能瓶颈，比如：

- JSI 让 RN 可以切换 JS 引擎，比如 `Chakra`、`v8`、`Hermes` ，同时允许 JS 和 Native 线程之间的同步相互执行
- 全新的 Fabric 取代了原本的 UI Manager，支持 React 的并发渲染能力，特别是现在的新架构支持 React 18 及更高版本中提供的并发渲染功能，对齐 React 最新版本，比如 Suspense & Transitions：![](https://img.cdn.guoshuyu.cn/680ecce9a6f64f621a8e9e0fb339ae58.gif)
- Hermes JS 引擎预编译的优化字节码，优化 GC 实现等
- TurboModules 按需加载插件
- ····

另外**现在新版 RN 也支持热重载**，同时可以更快对齐新 React 特性，例如 React 19 的 Actions、改进的异步处理等 。

而另一个支持**就是 RN 在 Skia 和 WebGPU 的探索和支持**，使用 Skia 和 WebGPU 不是说 RN 想要变成自绘，而是在比如「动画」和「图像处理」等场景增加了强力补充，比如：

> React Native Skia Video 模块，实现了原生纹理（iOS Metal, Android OpenGL）到 React Native Skia 的直接传输，优化了内存和渲染速度，可以被用于视频帧提取、集成和导出等，生态中还有 React Native Vision Camera 和 React Native Video (v7)  等支持 Skia 的模块：![](https://img.cdn.guoshuyu.cn/ezgif-6b98de7735b829.gif)

还有是 React Native 开始引入 WebGPU  支持，其效果将**确保与 Web 端的 WebGPU API 完全一致，允许开发者直接复制代码示例的同时，实现与 Web Canvas API 对称的 RN Canvas API**：

![](https://img.cdn.guoshuyu.cn/ezgif-67663972ea023c.gif)

最后，WebGPU  的引入还可以让 React Native 开发者能够利用 ThreeJS 生态，直接引入已有的 3D 库，这让 React Native 的能力进一步对齐了 Web ：

![](https://img.cdn.guoshuyu.cn/ezgif-679e940c014b17.gif)

最后，RN 也是有华为推进的鸿蒙适配，会采用 XComponent 对接到 ArkUI 的后端接口进行渲染，详细可见：[鸿蒙版 React Native 正式开源](https://juejin.cn/post/7413617657919307826) 。

而在 PC 领域 RN 也有一定支持，比如微软提供的 windows 和 macOS 支持，社区提供的 web 和 Linux 支持，只是占有并不高，一般忽略。

而在小程序领域，有京东的 Taro 这样的大厂开源支持，整体在平台兼容上还算不错。

> 当然，RN 最大的优势还在于成熟的 code-push 热更新支持。

那么使用 RN 有什么局限性呢？**最直观的肯定是平台 UI 的一致性和样式约束**，这个是 OEM 框架的场景局限，而对于其他的，目前存在：

- 第三方库在新旧框架支持上的风险
- RN 版本升级风险，这个相信大家深有体会
- 平台 API 兼容复杂度较高
- 0.77 之后才支持 Google Play 的 16 KB 要求
- 可用性集中在 Android 和 iOS ，鸿蒙适配和维度成本更高
- 小程序能力支持和客户端存在一定割裂
- ····

事实上， RN 是 Cordova 之后我接触的第一个真正意义上的跨平台框架，从我知道它到现在应该有十年了，那么你会因为它的新架构和 WebGPU 能力而选择 RN 么？ 

更多可见：

- [React Native 前瞻式重大更新 Skia & WebGPU](https://juejin.cn/post/7501989765085298700)

- [React Native 0.76，New Architecture 将成为默认模式](https://juejin.cn/post/7412075509481242634)

# Compose Multiplatform

Compose Multiplatform（CMP） 近期的热度应该来自 [Compose Multiplatform iOS 稳定版发布](https://juejin.cn/post/7501158867579387943) ，作为第二个使用 Skia 的自绘框架，除了 Web 还在推进之外， CMP 基本完成了它的跨平台稳定之路。

![](https://img.cdn.guoshuyu.cn/image-20250515112425327.png)

> Compose Multiplatform（CMP） 是 UI，Kotlin Multiplatform (KMP) 是语言基础。

**CMP 使用 Skia 绘制 UI ，甚至在 Android 上它和传统 View 体系的 UI 也不在一个渲染树**，并且 CMP 通过 Skiko  (Skia for Kotlin) 这套 Kotlin 绑定库，进而抹平了不同架构（Kotlin Native，Kotlin JVM ，Kotlin JS，Kotlin wasm）调用 skia 的差异。

所以 CMP 的优势也来自于此，它可以通过 skia 做到不同平台的 UI 一致性，并且在 Android 依赖于系统 skia ，所以它的 apk 体积也相对较小，而在 PC 平台得益于 JVM 的成熟度，CMP 目前也做到了一定的可用程度。

其中和 Android  JVM 模式不同的是，**Kotlin 在 iOS 平台使用的是 Kotlin/Native** ，Kotlin/Native 是 KMP 在 iOS 支持的关键能力，它负责将 Kotlin 代码直接编译为目标平台的机器码或 LLVM 中间表示 (IR)，最终为 iOS 生成一个标准 `.framework` ，这也是为什么 Compose iOS 能实现接近原生的性能。

> 实现鸿蒙支持目前主流方式也是 Kotlin/Native ，**不得不说 Kotlin 最强大的核心价值不是它的语法糖，而是它的编译器**，当然也有使用 Kotlin/JS 适配鸿蒙的方案。

**所以 CMP 最大的优势其实是 Kotlin** ，Kotlin 的编译器很强大，支持各种编译过程和产物，可以让 KMP 能够灵活适配到各种平台，并且 Kotlin 语法的优势也让使用它的开发者忠诚度很高。

不过遗憾的是，目前 CMP 鸿蒙平台的适配上都不是 Jetbrains 提供的方案，华为暂时也没有 CMP 的适配计划，目前已知的 CMP/KMP 适配基本是大厂自己倒腾的方案，有基于 KN 的 llvm 方案，也有基于 Kotlin/JS 的低成本方案，只是大家的路线也各不相同。

> 在小程序领域同样如此。

另外现在 **CMP 开发模式下的 hot reload 已经可以使用** ，不过暂时只支持 desktop，原理大概是只支持 jvm 模式。

而在社区上，[klibs.io 的发布](https://juejin.cn/post/7449965819360411685)也补全了 Compose Multiplatform 在跨平台最后一步，这也是 Compose iOS 能正式发布的另外一个原因：

![](https://img.cdn.guoshuyu.cn/image-20250507093526487.png)

那么聊到这里，CMP 面临的局限性也很明显：

- 鸿蒙适配成本略高，没有官方支持，低成本可能会选择 Kotlin/JS，为了性能的高成本可能会考虑 KN，但是 KN 在 iOS 和鸿蒙的 llvm 版本同步适配也是一个需要衡量的成本
- 小程序领域需要第三方支持
- iOS 平台可能面临的着色器等问题暂无方案，也许未来等待 Skia 的 Graphite  后端
- 在 Android JVM 模式和 iOS 的 KN 模式下，第三方包适配的难度略高
- hotload 暂时只支持 PC
- 桌面内存占用问题
- 不能热更新
- ····

相信 2025 年开始，CMP 会是 Android 原生开发者在跨平台的首选之一，毕竟 Kotlin 生态不需要额外学习 Dart 或者 JS 体系，那么你会选择 CMP 吗？

# Kuikly

Kuikly 其实也算是 KMP 体系的跨平台框架，只是腾讯在做它的时候还没 CMP ，所以一开始 Kuikly 是通过 KMM 进行实现，而后**在 UI 层通过自己的方案完成跨平台**。

![](https://img.cdn.guoshuyu.cn/image-20250427162207966.png)

这其实就是 Kuikly 和 CMP 最大的不同，**底层都是 KMP 方案，但是在绘制上 Kuikly 采用的是类 RN 的方式**，目前 Kuikly 主要是在 KMP 的基础上实现的自研 DSL 来构建 UI ，比如 **iOS 平台的 UI 能力就是 UIkit** ，而大家更熟悉的 Compose 支持，目前还处于开发过程中：

![](https://img.cdn.guoshuyu.cn/image-20250427164025155.png)

> SwiftUI 和 Compose 无法直接和 Kuikly 一起使用，但是 Kuikly 可以在 DSL 语法和 UI 组件属性对齐两者的写法，变成一个类 Compose 和 SwiftUI 的 UI 框架，也就是 **Compose DSL 大概就是让 Kuikly 更像 Compose ，而不是直接适配 Compose** 。

那么，Kuikly 和 RN 之间又什么区别?

第一，Kuikly  支持 Kotlin/JS 和  Kotlin/Native 两种模式，也就是它可以支持性能很高的 Native 模式

第二，**Kuikly 实现了自己的一套「薄原生层」**，Kuikly 使用“非常薄”的原生层，该原生层只暴露最基本和无逻辑的 UI 组件（原子组件），也就是 Kuikly 在 UI 上只用了最基本的原生层 UI ，真正的 UI 逻辑主要在共享的 Kotlin 代码来实现：

> 通过将 UI 逻辑抽象到共享的 Kotlin 层，减少平台特定 UI 差异或行为差异的可能性，「薄原生层」充当一致的渲染目标，确保 Kotlin 定义的 UI 元素在所有平台上都以类似的方式显示。

![](https://img.cdn.guoshuyu.cn/image-20250427174350110.png)

也就是说，Kuikly 虽然会依赖原生平台的控件，但是大部分控件的实现都已经被「提升」到 Kuikly 自己的 Kotlin 共享层，**目前 Kuikly  实现了 60%  UI 组件的纯 Kotlin 组合封装实现，不需要 Native 提供原子控件** 。

> 另外 Kuikly 表示后续会支持全平台小程序，这也是优势之一。

最后，**Kuikly 还在动态化热更新场景**， 可以和自己腾讯的热更新管理平台无缝集成，这也是优势之一。

那么 Kuikly 存在什么局限性？首先就是动态化场景只支持 Kotlin/JS，而可动态化类型部分：

- 不可直接依赖平台能力
- 不可使用多线程和协程
- 不可依赖内置部分

其他的还有：

- UI 不是 CMP ，使用的是类 RN 方式，所谓需要稍微额外理解成本
- 不支持 PC 平台
- 基于原生 OEM，虽然有原子控件，但是还是存在部分不一致情况
- 在原有 App 集成 Kuikly ，只能把它简单当作如系统 webview 的概念来使用

> 另外，腾讯还有另外一个基于 CMP 切适配鸿蒙的跨平台框架，只是何时开源还尚不明确

那么，你会为了小程序和鸿蒙而选择 Kuikly 吗？

更多可见：[腾讯 Kuikly 正式开源](https://juejin.cn/post/7497558282410115091)

# Lynx 

**如果说 Kuikly 是一个面向客户端的全平台框架，那么 Lynx 就是一个完全面向 Web 前端的跨平台全家桶**。

![](https://img.cdn.guoshuyu.cn/image-20250515130140009.png)

目前 Lynx 开源的首个支持框架就是基于 React 的 ReactLynx，当然官方也表示Lynx 并不局限于 React，所以不排除后续还有 VueLynx 等其他框架支持，而 **Lynx 作为核心引擎支持，其实并不绑定任何特定前端框架**，只是当前你能用的暂时只有 ReactLynx ：

![](https://img.cdn.guoshuyu.cn/image-20250515125825087.png)

而在实现上，源代码中的标签，会在运行时被 Lynx 引擎解析，翻译成用于渲染的 Element，嵌套的 Element 会组成的一棵树，从而构建出UI界面：

![](https://img.cdn.guoshuyu.cn/image-20250515130228375.png)

所以从这里看，初步开源的 Lynx 是一个类 RN 框架，不过从官方的介绍“*选择在移动和桌面端达到像素级一致的自渲染*” ，可以看出来**宣传中可以切换到自渲染**，虽然暂时还没看到。

而对于 Lynx 主要的技术特点在于：

- **「双线程架构」**，思路类似 react-native-reanimated ，JavaScript 代码会在「主线程」和「后台线程」两个线程上同时运行，并且两个线程使用了不同的 JavaScript 引擎作为其运行时：![](https://img.cdn.guoshuyu.cn/image-20250515130546387.png)

- 另外特点就是 **PrimJS** ，一个基于 QuickJS 深度定制和优化的 JavaScript 引擎，主要有模板解释器（利用栈缓存和寄存器优化）、与 Lynx 对象模型高效集成的对象模型（减少数据通信开销）、垃圾回收机制（非 QuickJS 的引用计数 RC，以提升性能和内存分析能力）、完整实现了 Chrome DevTools Protocol (CDP) 以支持 Chrome 调试器等
- “Embedder API” 支持直接与原生 API 交互 ，提供多平台支持

所以从 Lynx 的宏观目标来看，它即支持类 RN 实现，又有自绘计划，同时除了 React 模式，后期还适配 Vue、Svelte 等框架，可以说是完全针对 Web 开发而存在的跨平台架构。

> 另外支持平台也足够，Android、iOS、鸿蒙、Web、PC、小程序都在支持列表里。

最后，Lynx 对“即时首帧渲染 (IFR)”和“丝滑流畅”交互体验有先天优势，开发双线程模型及主线程脚本 (MTS) 让 Lynx 的启动和第一帧渲染速度还挺不错，比如：

- Lynx 主线程负责处理直接处理屏幕像素渲染的任务，包括：执行主线程脚本、处理布局和渲染图形等等，比如**负责渲染初始界面和应用后续的 UI 更新，让用户能尽快看到第一屏内容**

- **Lynx 的后台线程会运行完整的 React 运行时**，处理的任务不直接影响屏幕像素的显示，包括在后台运行的脚本和任务(生命周期和其他副作用)，它们与主线程分开运行，这样可以让主线程专注于处理用户交互和渲染，从而提升整体性能

而在多平台上，Lynx 是自主开发的渲染后端支持 Windows、tvOS、MacOS 和 HarmonyOS ，但是不确实是否支持 Linux：

![](https://img.cdn.guoshuyu.cn/image-20250515133216684.png)

那 Lynx 有什么局限性？首先肯定是它非常年轻，虽然它的饼很大，但是对应社区、生态系统、第三方库等都还需要时间成长。

> 所以官方也建议 **Lynx 最初可能更适合作为模块嵌入到现有的原生应用中，用于构建特定视图或功能，而非从零开始构建一个完整的独立应用** 。

其次就是对 Web 前端开发友好，对客户端而言学习成本较高，并且按照目前的开源情况，除了 Android、iOS 和 Web 的类 RN 实现外，其他平台的支持和自绘能力尚不明确：

![=](https://img.cdn.guoshuyu.cn/image-20250515134353100.png)![](https://img.cdn.guoshuyu.cn/image-20250515134344861.png)

最后，Lynx  的开发环境最好选 macOS，**关于 Windows 和 Linux 平台目前工具链兼容性还需要打磨**。

那么，总结下来，Lynx 应该会是前端开发的菜，那你觉得 Lynx 是你的选择么？

更多可见：[字节跨平台框架 Lynx 开源](https://juejin.cn/post/7478167090530320424)

# uni-app x

说到 uni-app 大家第一印象肯定还是小程序，而虽然 uni-app 也可以打包客户端 app，甚至有基于 weex 的 nvue 支持，但是其效果只能说是“一言难尽”，而这里要聊的 uni-app x ，其实就是 DCloud 在跨平台这两年的新尝试。

具体来说，就是 uni-app 不再是运行在 jscore 的跨平台框架，它是“基于 Web 技术栈开发，运行时编译为原生代码”的模式，相信这种模式大家应该也不陌生了，简单说就是：js（uts） 代码在打包时会直接编译成原生代码：

| 目标平台     | uts 编译后的原生语言 |
| ------------ | -------------------- |
| Android      | Kotlin               |
| iOS          | Swift                |
| 鸿蒙         | ArkTS                |
| Web / 小程序 | JavaScript           |

甚至极端一点说，uni-app x 可以不需要单独写插件去调用平台 API，你可以直接在 uts 代码里引用平台原生 API ，因为你的代码本质上也是会被编译成原生代码，所以 uts ≈ native code ，只是使用时需要配置上对应的条件编译(如 `APP-ANDROID`、`APP-IOS` )支持：

```JS
import Context from "android.content.Context";
import BatteryManager from "android.os.BatteryManager";
​
import { GetBatteryInfo, GetBatteryInfoOptions, GetBatteryInfoSuccess, GetBatteryInfoResult, GetBatteryInfoSync } from '../interface.uts'
import IntentFilter from 'android.content.IntentFilter';
import Intent from 'android.content.Intent';
​
import { GetBatteryInfoFailImpl } from '../unierror';
​
/**
 * 获取电量
 */
export const getBatteryInfo : GetBatteryInfo = function (options : GetBatteryInfoOptions) {
  const context = UTSAndroid.getAppContext();
  if (context != null) {
    const manager = context.getSystemService(
      Context.BATTERY_SERVICE
    ) as BatteryManager;
    const level = manager.getIntProperty(
      BatteryManager.BATTERY_PROPERTY_CAPACITY
    );
​
    let ifilter = new IntentFilter(Intent.ACTION_BATTERY_CHANGED);
    let batteryStatus = context.registerReceiver(null, ifilter);
    let status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1);
    let isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING || status == BatteryManager.BATTERY_STATUS_FULL;
​
    const res : GetBatteryInfoSuccess = {
      errMsg: 'getBatteryInfo:ok',
      level,
      isCharging: isCharging
    }
    options.success?.(res)
    options.complete?.(res)
  } else {
    let res = new GetBatteryInfoFailImpl(1001);
    options.fail?.(res)
    options.complete?.(res)
  }
}
​

```

比如上方代码，通过 `import BatteryManager from "android.os.BatteryManager"` 可以直接导入使用 Android 的 `BatteryManager` 对象。

可以看到，在 uni-app x 你是可以“代码混写”的，所以与传统的 uni-app 不同，uni-app 依赖于定制 TypeScript 的 uts 和 uvue 编译器：

- uts 和 ts 有相同的语法规范，并支持绝大部分 ES6 API ，在编译时会把内置的如`Array`、`Date`、`JSON`、`Map`、`Math`、`String` 等内置对象转为 Kotlin、Swift、ArkTS 的对象等，所以也不需要有 uts 之类的虚拟机，另外 uts 编译器在处理特定平台时，还会调用相应平台的原生编译器，例如 Kotlin 编译器和 Swift 编译器
- uvue 编译器基于 Vite 构建，并对它进行了扩展，大部分特性（如条件编译）和配置项（如环境变量）与 uni-app 的 Vue3 编译器保持一致，并且支持 less、sass、ccss 等 CSS 预处理器，例如 uvue 的核心会将开发者使用 Vue 语法和 CSS 编写的页面，编译并渲染为 ArkUI

而在 UI 上，目前除了编译为 ArkUI 之外，Android 和 iOS 其实都是编译成原生体系，目前看在 Android 应该是编译为传统 View 体系而不是 Compose ，而在 iOS 应该也是 UIKit ，按照官方的说法，**就是性能和原生相当**。

所以从这点看，**uni-app x 是一个类 RN 的编译时框架**，所以，**它的局限性问题也很明显，因为它的优势在于编译器转译得到原生性能，但是它的劣势也是在于转译**：

- 不同平台翻译成本较高，并不支持完整的语言，阉割是必须的，API 必然需要为了转译器而做删减，翻译后的细节对齐于优化会是最大的挑战
- iOS 平台还有一些骚操作，保留了可选 js 老模式和新 swift 模式，核心是因为插件生态，**官方表示 js 模式可以大幅降低插件生态的建设难度**， 插件作者只需要特殊适配 Android 版本，在iOS和Web端仍使用 ts/js 库，可以快速把 uni-app/web 的生态迁移到 uni-app x 
- 生态支持割裂，uni-app 和 uni-app x 插件并不通用
- 不支持 PC
- HBuilderX IDE
- ·····

那么，你觉得 uni-app x 会是你跨平台选择之一么？

更多可见：[uni-app x 正式支持鸿蒙](https://juejin.cn/post/7503974160264069156)

# 最后

最后，我们简单做个总结：

| 框架 (Framework)      | 开发语言   | 渲染方式                     | 特点                                                         | 缺点                                               | 支持平台                                                     | 维护企业  |
| --------------------- | ---------- | :--------------------------- | ------------------------------------------------------------ | -------------------------------------------------- | ------------------------------------------------------------ | --------- |
| Flutter               | Dart       | 自绘，Impeller               | 自绘，多平台统一，未来支持 dart 和平台语言直接交互，Impeller 提供竞争力，甚至支持游戏场景 | 占用内存大，文本场景略弱，Impeller 还需要继续打磨  | android、iOS、Web、Windows、macOS、Linux、鸿蒙（华为社区提供） | Google    |
| React Native          | JS 体系    | 原生 OEM + Skia/WebGPU 支持  | 新架构提供性能优化，对齐 Web，引入 skia 和 webGPU 补充，code-push 热更新 | UI 一致性和新旧架构的第三方支持                    | android、iOS、鸿蒙（华为社区提供），额外京东 Taro 支持小程序，web、windows、macOS、Linux 第三方支持 | Facebook  |
| Compose Multiplatform | Kotlin体系 | Skia 自绘                    | Kotlin 体系，skia 自绘，多平台统一，支持 kn、kjs、kwasm 、kjvm 多种模式 | KN 和 JVM 生态需要整合，没有着色器预编方案         | android、iOS、Web、Windows、macOS、Linux                     | Jetbrains |
| Kuikly                | Kotlin体系 | 原生 OEM ，「薄原生层」      | 基于  KMP 的类 RN 方案，在动态化有优势                       | 小部分 UI 一致性场景，UI 与 CMP 脱轨               | android、iOS、Web、鸿蒙、小程序                              | 腾讯      |
| Lynx                  | JS 体系    | 原生 OEM，未来也有自绘       | 对齐 Web 开发首选，秒开优化，规划丰富                        | 非常早期 ，生态发展中，客户端不友好                | android、iOS、Web、Windows、macOS、鸿蒙、小程序              | 字节      |
| uni-app x             | uts        | 原生 OEM，直接翻译为原生语言 | 支持混写 uts 和原生代码，直接翻译为原生                      | 生态插件割裂，UI 一致性问题，翻译 API 长期兼容成本 | android、iOS、Web、鸿蒙、小程序                              | DCloud    |

什么，你居然看完了？事实上我写完都懒得查错别字了，因为真的太长了。

