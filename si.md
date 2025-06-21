# Compose Multiplatform Skia  对比 Flutter Impeller ，都是跨平台自绘有什么差异

近期 Jetbrains  的 [Compose Multiplatform 1.8 发布了第一个 iOS 稳定版](https://juejin.cn/post/7501158867579387943)，三年的时间终于让 Compose Multiplatform 在移动端平台全面走向稳定版本，不同的是，Compose 在 Android 走的是 Kotlin/JVM + 系统 Skia ，而在 iOS 是 Kotlin/Native + 独立 Skia 的配置。

那么就有小伙伴好奇，都是自绘制方案，Jetbrains  的 Compose Multiplatform  Skiko （Skia） 和 Google 的 Flutter Impeller 有什么区别？为什么 Flutter 会放弃 Skia？

![](https://img.cdn.guoshuyu.cn/image-20250508131025893.png)

> 本篇就让我们简单聊聊 skia 和 impeller 的对比。

# Skia & Compose Multiplatform

## Skia

首先我们有一点需要确定的是， **Skia 是一个通用型的全面跨平台 2D 图形 API** ，它在众多领域都被广泛使用，包括 Chrome 、Android 系统等，这其实就是它和 Impeller 定位的最大区别之一，**毕竟 Impelller 的定位并不是成为一个通用图形 API** 。

而在 Skia 的里，除了 CPU 渲染的核心是 `SkRasterPipeline`，**最重要的一个角色就是 Ganesh 后端**，它是用于 GPU 加速 ，支持多种图形 API如 OpenGL、Vulkan 和 Metal ，负责记录绘制指令、管理 GPU 资源，从而让  Skia 能够运行在各种硬件平台。

而在这里面有个特殊的概念，那就是 **Skia 传统的 Ganesh 后端及其 Skia Shading Language (SkSL) 严重依赖运行时着色器编译**，简单说就是：

> 着色器是 GPU 上运行所需的单元，也可以说成是在 GPU 上运行的代码段，Skia 需要把「绘制命令」编译成可在 GPU 执行代码的过程，就叫做着色器编译。

所以 Skia 需要「动态编译」着色器，但是 Skia 的着色器「生成/编译」与「帧工作」是按顺序处理，如果这时候着色器编译速度不够快，就可能会出现掉帧（Jank）的情况，这个我们也常叫做「着色器卡顿」。

其实这就是 Skia 的特色，在着色器上极大的灵活性 ，但也存在容易卡顿（jank）风险，l另外 Skia  最早是针对 OpenGL 设计，虽然现在已经扩展支持 Vulkan 和 Metal ，但是 Ganesh  在新 API 上的表现只能说中规中矩。

那么 Skia 有什么后手吗？答案是有的，Skia 还有新一代 GPU 后端：**Graphite ，它会针对 Metal 和 Vulkan 等场景进行优化，显著降低记录渲染命令的 CPU 成本，并简化着色器的预编译过程**。

> Graphite 的核心就是优化运行时着色器编译卡顿问题，虽然还是需要运行时生成着色器，**但是它支持应用枚举将要使用的图形特性**，从而能够在应用启动时甚至提前 (AOT) 预编译所有必需的着色器 。

不过目前 Graphite 还是非稳定阶段，Chrome 也正在切换到 Graphite，Skia 的长期目标是弃用 Ganesh 并仅推进 Graphite ，**所以支持着色器提前编译是主要方向，有的只是时间问题**。

事实上 Skia 一直以来也知道这个问题，所以才会提出 Graphite ：

![](https://img.cdn.guoshuyu.cn/image-20250508164734729.png)

> 对于 Graphite ， 其实  Flutter 与 Skia 团队本身就存在密切合作，因为它是以 Impeller 为模型的改进

## Compose Multiplatform

那我们知道了 Skia 的特点之后，就可以可以聊聊 Compose Multiplatform 了，Compose Multiplatform 虽然使用 Skia 自绘，但是它在 Android 和 iOS 上的场景完全不一样。

这里的不一样指的不是一个 Kotlin/JVM 一个 Kotlin/Native，因为 Compose Multiplatform 有 Skiko (Skia for Kotlin) 来“拉平”这些差异：

> Skiko 针对 JVM 的 JNI、 Native 的 Cinterop 和 JS 的  Wasm 等统一了抽象接口，降低了维护复杂度。

**真正不一样的其实在于「系统支持上」** ，前面我们聊过，Skia 严重依赖运行时着色器编译，那么为什么很多时候 Android 原生 View 体系的 App 看起来很流畅呢？这就需要提到 Andriod 的系统支持 HWUI/Skia 。

### Android

在原生 Android 应用里，**虽然看不到什么「显式」的「着色器预热」或者「着色器提前编译」，但是渲染绘制时都离不开 HWUI/Skia** ，其中关键支持之一就是 HWUI ：

> HWUI 构建在 Skia 之上，支持硬件加速，让绝大多数标准的绘图操作都可以通过 HWUI 在 GPU 上执行。

除了提升执行效率，HWUI 还有缓存机制，它可以通过复用已处理的图形资源（如纹理、路径数据、字形位图、形状缓存等），减少了相关重复的 GPU 数据上传和 CPU 计算开销，这也是关键。

HWUI 的资源缓存与 GPU 驱动的着色器缓存协同工作，对于常见的 UI 元素和操作（如文本绘制、纯色填充、简单渐变、位图纹理采样），一般使用的着色器都类似，这些着色器很可能在应用启动时，甚至在系统 UI 渲染其他应用时，就已经被 GPU 驱动编译并缓存了，**因此，对于大多数标准 UI 场景，着色器实际上是“热”的，或者能够非常迅速地“热身”**。

> 简单说，许多应用和系统组件都依赖于相似的渲染操作，常用的着色器可能已经在驱动程序的全局缓存中“预热”了，这也是你为什么刚开机那会感觉有点卡的原因之一。

那么这和 Compose 有什么关系？Compose 在 Android 并没有内嵌自己的 skia 版本，本质上 View 和 Compose 都是通过 HWUI - Skia 的过程，**同时 Compose 是直接使用系统自带的渲染管道**，尽管渲染模式和构建树变了，但是它还是在   `android.graphics.Canvas`  体系之下， **这意味着原生 View 所受益的缓存机制同样也适用于 Android  Compose** 。

> 更多可见：[《着色器预热？为什么 Flutter 需要？为什么原生 App 不需要？那 Compose 呢？Impeller 呢？》](https://juejin.cn/post/7385942645232828442)

**所以，知道什么是“亲生”的了吗？作为系统原生 UI ，就不存在所谓“预热”的困扰，因为机制不同，它已经隐藏在操作系统和 GPU 驱动层面**。

### iOS

那么，回到 iOS 平台，Compose Multiplatform 作为“非亲生”的 UI 框架，它需要预热吗？答案肯定是需要的，**那它是怎么解决预热和 jank 问题的呢？答案是目前看起来是没有**。

![](https://img.cdn.guoshuyu.cn/image-20250508132052276.png)

是的，目前 Compose Multiplatform 在 iOS 平台关于 shader warm-up 的支持还看不到，毕竟 Skia 在 iOS 平台各种边界 Jank 可以说并不少，目前看来也许 Jetbrains 在等待 Skia 的 Graphite 成熟之后，可以一步到位解决着色器编译卡顿的问题。

**事实上 Flutter 之所以自研 Impeller ，起初的核心就是难以推动 Skia 在 iOS 上的各种 Jank ，毕竟对于  Skia  而言 iOS 只是众多平台之一，而  Graphite  何时稳定对于 Flutter 也等不起**。

> 当然，也不排除 Compose 可以在上层 UI 的重组与优化上尽可能规避这些问题。

# Flutter & Impeller

那么来到 Flutter 的 Impeller ，首先最大的不同就是： **App 所需的所有着色器都在 Flutter 引擎构建时进行离线编译，而不是在应用运行时编译**。

![image-20250508145448244](https://img.cdn.guoshuyu.cn/image-20250508145448244.png)

例如，Impeller 里着色器以 GLSL 4.60 进行编写，然后在构建时：

- `impellerc`（Impeller 着色器编译器）会将 GLSL 转换为 SPIR-V（一种中间表示）
- 然后这个 SPIR-V 再由特定于后端的转译器（通过传递给 `impellerc` 的标志控制）进行处理，从而将其转换为对应 GPU API 的高级着色语言（如 Metal Shading Language 用于 Metal，GLSL ES 用于 OpenGL ES，Vulkan GLSL 用于 Vulkan）
- 这些高级着色器随后会被编译、优化并链接成单个二进制 Blob ，而这个 Blob 会作为十六进制转储嵌入到 C 源码文件中，然后编译到应用程序中，确保着色器与引擎打包在一起 

![image-20250508145516530](https://img.cdn.guoshuyu.cn/image-20250508145516530.png)

另外，**着色器反射（确定着色器输入、输出、uniform 等）也在构建时离线执行**，所有 PSO 都是预先构建的，所以在 Impeller 运行过程中等于是自己准备好了「碗筷」，自给自足。

除此之外，Impeller 另外的核心就是优化 Flutter 架构的渲染过程，它的渲染方法在 Flutter 上可以比 Skia 能更有效地利用 GPU ，**让设备的硬件以更少的工作量来渲染动画和复杂的 UI 元素，从而提高渲染速度**，例如：

> **Impeller 会采用 tessellation 和着色器编译来分解和提前优化图形渲染**，这样 Impeller 就可以减少设备上的硬件工作负载，从而实现更快的帧速率和更流畅的动画。

而这个特性也决定了 Impeller 无法成为通用性框架，比如 Skia 的 SkSL 所能生成的着色器的多样性和即时复杂性，在 Impeller 场景中就会受到更多限制，这和预编译着色器集的能力有很大关系，所以对于 Impeller 来说：

> **Impeller 是专注于常见、可优化的渲染基元，而不是一个通用、无限灵活的着色器系统**。

同时 Impeller 作为全新渲染 API ，没有历史负担和只专注于 Flutter 的定位，让它可以很快推进各种能力，并适配 Metal 、Vulkan 的全新 API 特性，特别是利用并发，在必要时将单帧渲染工作负载分配到多个线程等场景。

这里值得一提的是， **Flutter 在  `DisplayList`  层面对 engine 做了解耦，所以  `DisplayList`  帮助了 Flutter 适配到 skia 和 Impeller 的切换，而 Impeller 上，HAL 帮助 Impeller 适配到 Metal/Vulkan/OpenGLES 等不同管道**。

![](https://img.cdn.guoshuyu.cn/image-20250508155056180.png)



当然，Impeller 虽然不再使用 Skia ，但是 Impeller 对文本渲染依赖 SkParagraph 以及对图像处理依赖 Skia 编解码器：

- Flutter 的文本渲染和功能集（如复杂脚本支持、排版准确性）从根本上受制于 SkParagraph 的能力，而 Impeller 更多在于高效地光栅化和合成 SkParagraph 提供的字形
- Flutter 在查询系统提供的图像格式之前，会使用一组由 Skia 包装的标准编解码器

![](https://img.cdn.guoshuyu.cn/image-20250508110356113.png)![](https://img.cdn.guoshuyu.cn/image-20250508110541592.png)

这么看好像 Impeller 比现阶段的 Skia 强大不少，至少不需要动态编译着色器了，那么它存在什么问题呢？

- Impeller 还没有 Skia 庞大且成熟的全部功能集，尤其是在高级或小众的 2D 图形操作、复杂路径效果、某些混合模式或完整的图像滤镜谱系方面容易存在 bug
- Vulkan 上的路径渲染和内存优化问题
- 文本能力相对疲弱，容易触发边界 bug，比如排版异常、字形异常、粗细异常、闪烁
- ····

> 这些我们都在 [《快速了解 Flutter 的渲染引擎的优势》](https://juejin.cn/post/7337898389450080306) 聊过。

另外还有对于 OpenGL 的兼容上，比如 Flutter 3.29 才发布了 Android 平台正式全面启用 Impeller ，但是 3.29.2 版本就开始「回退」，原因是 Impeller 在某些不支持 Vlukan 的低版本设备上使用 Impeller GLES 作兼容时会 Crash ，所以只能暂时再次转为 Skia GLES ：

![](https://img.cdn.guoshuyu.cn/image-20250508152222658.png)

从以上问题都可以看出，**Impeller 在细节和稳定性上还需要继续努力，毕竟相比较 Skia 它还是太年轻了**。

当然，**Impeller 还画了一个大饼： [Flutter GPU](https://juejin.cn/post/7399985723673821193)** ，它目前还处于早期预览阶段，最直接就是它支持真 3D 渲染，就是这个坑何时能填就是个未知数了：

![](https://img.cdn.guoshuyu.cn/40c8ebdfa1095926b549ae6ff94c8185.gif)

![](https://img.cdn.guoshuyu.cn/image-20250508153129085.png)

![](https://img.cdn.guoshuyu.cn/4d157c3c4500e9d72b764b1eadccef56.gif)

> 更多可见：[Flutter GPU 是什么？为什么它对 Flutter 有跨时代的意义？](https://juejin.cn/post/7399985723673821193)

# 最后

最后，我们简单回顾下，Impeller 和 Skia 当前最大的区别就两个：

- Impeller 着色器是提前编译，而 Skia 是运行时动态编译
- Impeller 定位只为 Flutter 服务，而 Skia 更多考虑兼顾通用性支持

其他对比可以参考下发表格：

| 方面                     | Flutter (使用 Impeller)                                    | Compose Multiplatform (使用 Skia/Skiko)                 | 关键考量                                                     |
| ------------------------ | ---------------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------------ |
| **主要渲染引擎**         | Impeller (C++ 原生)                                        | Skia (通过 Skiko)                                       | Impeller 与 Flutter 引擎紧密集成，Skiko  需要考虑引入了 JNI 开销 |
| **着色器策略**           | 预编译 (AOT)                                               | 运行时编译 (Ganesh)，Graphite (未来可能) 支持部分预编译 | Impeller 核心优势在于消除运行时编译卡顿；Skia/Ganesh 灵活但在 iOS 有 Jank 风险，Graphite 在于未来 |
| **高级功能集**           | 发展中，核心功能完善，部分高级特性可能不及 Skia 全面       | 完整 Skia 功能集，非常丰富                              | 对复杂、小众图形功能有强需求的项目，Skia 更具优势            |
| **文本渲染质量**         | 依赖 SkParagraph，目标是原生级质量，动画抖动等问题在修复中 | 依赖 Skia 文本栈，质量高，支持复杂脚本和可变字体        | 两者均依赖 Skia 的文本处理能力，但 Impeller 的渲染实现仍在打磨 |
| **自定义着色器支持**     | 有限/不同机制，主要依赖预编译着色器                        | 通过 SkSL  非常灵活                                     | Skia 在自定义着色器方面更强大                                |
| **平台成熟度 - 移动端**  | Impeller 在 iOS/Android 上为默认，基本能力表现还行         | Skia/Skiko 在 Android/iOS 上成熟度较高                  | Impeller 在 Flutter 移动端已是主要生产主力                   |
| **图形原生互操作便捷性** | Impeller 内部 C++ API，对 Flutter 开发者透明               | Skiko 提供了 Kotlin API，但深入 Skia C++ 层需额外工作   | Impeller 对于图形操作的可控度会更高，因为它不需要考虑通用性  |

当然，不管是 Skia 还是 Impeller ，目前在正常使用场景下的性能问题基本不大，如果你在使用过程中无法正常使用或者卡出翔，那么最大可能只能是人的问题，而不是框架的问题。

对了，最后提一句，**Skia 和 Impeller 其实都是 Google 的**，就像前面说的，它们之间是合作关系，对于 Graphite ，它是以 Impeller 为模型的 Skia 后端改进。

> 另外，最近 [《React Native 前瞻式更新 Skia & WebGPU》](https://juejin.cn/post/7501989765085298700) 也提到了  Graphite - WebGPU 的方向 ，事实上 Skia 也是在往着更全面的方向发展。

