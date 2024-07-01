# 着色器预热？为什么 Flutter 需要？为什么原生 App 不需要？那 Compose 呢？Impeller 呢？

依旧是来自网友的问题，这个问题在一定程度上还是很意思的，因为大家可能会想，Flutter 使用 skia，原生 App 是用 skia ，那为什么在 Flutter 上会有着色器预热（Shader Warmup）这样的说法？原生是不是也有？那 Compose MultiPlafrom 是不是也需要？

![](http://img.cdn.guoshuyu.cn/20240629_S/image1.png)

> ⚠️⚠️⚠️ 今天又是又干又长，属于点赞了收藏了就🟰我会了系列。

# 是什么，为什么？

首先，我们要知道着色器预热（Shader Warmup）是什么，它又能干嘛？简单说：

> 着色器是 GPU 上运行所需的单元，也可以说成是在 GPU 上运行的代码段，skia 把「绘制命令」编译成可在 GPU 执行代码的过程，就叫做着色器编译。

好了，那着色器编译有什么问题？ skia 需要「动态编译」着色器，但是 skia 的着色器「生成/编译」与「帧工作」是按顺序处理，如果着色器编译速度不够快，就可能会出现掉帧（Jank）的情况，这个我们可以叫做「着色器卡顿」。

那么，Flutter 使用 skia 作为渲染引擎时，skia 就会在应用首次打开时去生成着色器，这就很容易造成在设备上首次运行时出现「卡顿」的情况：

> 如果你的 Flutter 移动应用的动画看起来很「卡顿」，但仅在第一次运行时出现，那么这很可能是由于着色器编译造成。

**所以发生这种情况的原因是设备需要编译一些代码（着色器），从而告诉 GPU如何渲染图形 ，那么这时候着色器预热就出现了**。

> 着色器预热有点类似于，尽可能让  Flutter 在 skia 上多挤出一点性能的味道。

简单说，就是通过 `flutter run --profile --cache-sksl`  ，让 Flutter 运行时预热（缓存）着色器，然后把导出文件打包到 App，让 Flutter Engine 在启动绘制第一帧之前处理。

所以预热的本质，**是将部分性能敏感的 SkSL（Skia Shader Language）生成时间提前放到编译期去处理**，所以它需要在真机上进行运行，从而捕获  SkSL  导出配置文件，才能在打包时通过编译参数（--bundle-sksl-path）将导出的 SkSL 预置在应用里面。

> SkSL 最终还是需要在运行时转化为平台的 GPU 语言才能执行，因为它与底层 GLSL 或 Metal(MSL) 实现无关，SkSL 可以对信息进行编码，当转换为 GLSL 时，它将使用创建它的 GPU 的一些特有能力，所以 SkSL 与平台无关，但它与功能检测和使用有关，skia 可能会假设，如果在生成时检测到某个功能，它就可以使用该功能。

那么到这里，我们知道了什么是着色器和着色器预热，并且知道为什么 Flutter 会用到着色器预热，**事实上着色器预热只是一种补充手段，它不是 Flutter 必须，而是为了解决边界问题而存在的「过渡」手段，但是它又对 Flutter 的未来起到了“推动作用“**。

那么接下来我们再看原生和 Flutter 的区别。

# 原生 VS Flutter

那么为什么原生开发的 App 不需要着色器预热，但是 Flutter  上确需要呢？

前面我们知道，着色器预热只是一种「补充手段」，而需要「补充手段」的原因，自然就是 Flutter 不是系统的亲儿子，**而原生开发框架，它作为亲儿子，自然就不需要「预热」，因为本来就很「亲热」了**。

因为在原生开发里，极少需要开发者去「自定义着色器」 ，除非你是做游戏的，不然大部分时候着色器都是提前内置在系统等着你，例如：

> iOS 上 Core Animation 所需的着色器，在系统内部对于所有的  App 来说都是共享的，在 Framework 框架内根本不需要考虑运行中的着色器编译问题。

可能有人就奇怪了，不是在说 Android 和 Flutter 么，为什么提 iOS ？**因为 Flutter 里的着色器预热，它的存在 90% 都是为了 iOS 而存在**。

因为在 Android 内部，本身具有二进制着色器持久缓存，而 iOS 没有，所以 iOS 的首次卡顿一直是 Flutter 里的诟病问题。

另外，由于 SkSL 创建过程中需要捕获一些用户设备的特定的参数，不同设备“预热”的配置文件不一定通用，在 Android 上的“预热”可能只会只对某些硬件有效，**这也是为什么预热需要在真机上进行的原因之一**。

最后，使用**着色器预热的后期维护成本很高**，先不说不同设备/不同系统版本是否通用，就单纯每升级一次 Flutter SDK 就需要做一次新的“预热”这个行为，就很费事：

> “预热”要求用户操作整个应用的所需流畅，并点击一些常见动画场景，并且缓存文件也是针对特定的 skia 和 Flutter 版本构建的，还需要为 iOS 和 Android 构建两个不同的缓存文件。

当然，也有类似  `flutter drive --profile --cache-sksl`  的命令脚本，但是维护这个预热着色器的行为，本身就不是什么长期的选择。

**事实上着色器预热这东西不亏是“烂摊子”，在 iOS 平台开始使用 Metal 和  Metal Binary Archive 之后，这个雷区彻底“爆炸”，最终达成了弃坑并推动「换 Impeller」 的壮举**：

- https://github.com/flutter/flutter/issues/32170 

说回 Android vs Flutter，虽然 Android 原生和 Flutter 大家都是使用 skia ，但是除了需不需要预热这个区别外，其实还是存在差异，**事实上 Flutter 在 Engine 捆绑了自己的 skia 副本， Flutter 的 skia 版本和 Flutter SDK 有关，于平台无关**，所以原生 android skia 和 Flutter skia 还是存在一定差异化。

> [Flutter also embeds its own copy of Skia as part of the engine](https://docs.flutter.dev/resources/architectural-overview : )
>
> 详细可见：https://www.youtube.com/watch?v=OLjhAl7adGE

![](http://img.cdn.guoshuyu.cn/20240629_S/image2.png)

另外说到 Android skia ，可以在简单聊个题外话，**其实在 Honeycomb(3.0)  - P(9.0) ，Skia 不一定是你设备的 GPU 直接渲染工具**，例如下图是 Android Oreo(8.0) 在开发者模式下的选项。

![](http://img.cdn.guoshuyu.cn/20240629_S/image3.png)

>Android Honeycomb(3.0) 开始用 hwui 取代了部分 skia，hwui 是一个将 Canvas 命令转换为硬件加速 OpenGL 命令的库，所以在到  P 之前，当硬件加速开启时，hwui 会自己进行渲染，而不是 skia ，而从  Oreo(8.0)  开始 hwui 渲染支持 skia opengl 选项，而 P(9.0) 开始支持 vulkan ，另外 P(9.0) 开始 skia 库也不再作为一个单独的动态库 so，而是集成到 hwui 里，成为默认。

好了，这里扯了那么多，**大概也了解了为什么原生不需要着色器预热，并且 Flutter 的 skia 和原生 skia 也是存在差异** 。

# Impeller

那么时间来到 Impeller ， Impeller 其实属于「必然」又「无奈」的产物，在此之前，着色器预热的更新问题推进一直卡在 skia 节点，毕竟 skia 并不是完全服务于 Flutter ，所以随着矛盾的积累，最终只能「搞拆迁」。

与 skia 的不同在于，**Impeller  会提前预编译大多数着色器，从而减少渲染延迟，并消除与动态着色器编译相关的卡顿，因为预预编译发生在 Flutter 应用的构建过程里，所以可以确保着色器在应用启动后立即可用**。

> 当然，搞拆迁，自然是东拆西补，不少老问题又被翻出来重新回炉。

简单说，例如 Flutter Engine 在构建的时候，它的 Impeller 会使用  `impellerc` 对  `entity/shaders/` 目录下的所有着色器进行预处理(SPIR-V)，然后再看情况例如编译为 iOS 上的 MSL(Metal SL) ，其中内置着色器就是如下图所示这部分 ：

![](http://img.cdn.guoshuyu.cn/20240629_S/image4.png)

这样 Flutter 也就有了自己的「亲爹」，大部分需要的着色器都在离线时被编译为 shader library，在运行时不再需要什么预热着色器或者编译着色器的操作。

另外在 Impeller 里 Contents 也是很重要的存在，所有绘图信息都要转化为  Entity ，而  Entity 对有对应的 Contents ，用于表示一个绘图操作：

| ![](http://img.cdn.guoshuyu.cn/20240629_S/image5.png) | ![](http://img.cdn.guoshuyu.cn/20240629_S/image6.png) |
| ---------------------------------------------------------- | ---------------------------------------------------------- |

所以，回到前面说个的 iOS Framework 可以使用系统的共享着色器一样，Impeller 放弃了使用 SkSL ，而是使用 *GLSL*  作为着色器语言，通过 `impellerc` 在编译期即可将所有的着色器转换为  MSL(Metal SL) ， 并使用 *MetalLib* 格式打包为 *AIR* 字节码内置在应用中，属于自己「造爹」了。



![](http://img.cdn.guoshuyu.cn/20240629_S/image7.png)



另外，Impeller 不依赖于特定的客户端渲染 API ，着色器只需编写一次，根据上面的那组固定着色器，提前编译：

- `impellerc` （Impeller Shader Compiler ） 将 GLSL 转换为 SPIRV，这个阶段不对生成的 SPIRV 执行任何优化，保留所有调试信息。
- 使用 SPIRV，后端特定的转译器将 SPIRV 转换为适当的高级着色语言

![](http://img.cdn.guoshuyu.cn/20240629_S/image8.png)

所以大概就是：

- `impellerc`  将 GLSL 代码编译成 SPIRV
- SPIRV 可用于 OpenGL、OpenGL ES、Metal、Vulkan 等
- 最终生成的 lib 可以在各种平台上执行。

这里值得一提的是， **Flutter 在  `DisplayList`  层面对 engine 做了解耦，所以  `DisplayList`  帮助了 Flutter 适配到 skia 和 Impeller 的切换，而 Impeller 上，HAL 帮助 Impeller 适配到 Metal/Vulkan/OpenGLES 等不同管道**。

![](http://img.cdn.guoshuyu.cn/20240629_S/image5.png)

> 详细可见：[《2024 Impeller：快速了解 Flutter 的渲染引擎的优势》](https://juejin.cn/post/7337898389450080306)

所以 Impeller 通过搞「拆迁补偿」，让着色器预编译可以依赖一组比 Skia 更简单的着色器，从而保持应用整体大小不会剧增的效果，得到更好的启动和预热效果。

所以到这里我们知道，**Impeller 不需要对 App 代码做着色器预热，因为它给自己找了个「干爹」**。



# Compose MultiPlatform

那么回到 Compose 和 Compose MultiPlatform 上，其实这个问题需要区别对待。

首先 Compose 也是使用 skia ，那么 Compose 是否也需要着色器预热？因为 Compose 本身不也是脱离默认 XML 的独立 UI 吗？那它是否也存在着色器加载问题？

首先这个问题其实很简单，**那就是 Compose 是直接使用系统自带的渲染管道**，尽管渲染模式和构建树变了，但是它还是在   `android.graphics.Canvas`  体系之下，Compose 在 Android 并没有内嵌自己的 skia  版本，本质上 View 和 Compose 都是通过 hwui - skia 的过程 。

> 在不考虑前面说过的  Honeycomb(3.0)  到 P(9.0) 开了硬件加速的情况下。

所以也许早期的 Compose 在 Android 会比较卡，但是作为亲儿子，随着版本迭代，卡的问题自然就会被底层解决，**从根本上来说，Android 上的 Compose 根本不需要着色器预热这种「小瘪三」**。

那么在 iOS 上呢？Compose Multiplatform 的 UI 是通过 Skiko（skia for Kotlin） 实现进行渲染，JetBrains 通过 Kotlin 语言对 skia 做了一层封装，让 Kotlin 在各个平台均可以通过统一的 Kotlin API 来调用 skia 进行图形绘制。

所以理论上  Compose Multiplatform 不直接使用 skia，而是使用 skiko 来访问 skia API，不过因为本质还是 skia 和 SKSL ，**所以从目前情况来看，对于 iOS 着色器问题同样是存在**。

![](http://img.cdn.guoshuyu.cn/20240629_S/image9.png)

那么 Compose iOS 在未来可能选的有几条路：

- 如 [#3141 ](https://github.com/JetBrains/compose-multiplatform/issues/3141)所说的，提供着色器预热支持
- KN 直接编译为 UIKit 
- 接入 Impeller 或者自研发另一个
- 配合 skia 推进着色器问题

目前 Compose Multiplatform 不管在 [SkSL ](https://github.com/JetBrains/compose-multiplatform/issues/363)还是在 [warm-up](https://github.com/JetBrains/compose-multiplatform/issues/3141) 的推动上都不是很上心，毕竟还有不少其他工作要推动，不过随着 KMP 的支持，Compose Multiplatform 在 iOS 上已经可以与 SwiftUI 和 UIKit 相互操作，所以理论上其实可以在 Swift/UIKit 中使用 Compose，也可以在 Compose 中使用 SwiftUI/UIKit。

所以目前来说  Compose Multiplatform 在 iOS 上还有不少路要走，现在没有“预热”，大概也只是还没走到需要“预热”的瓶颈。

# OpenGL & Vulkan & Metal

最后我们聊一聊渲染的底层管道 API，事实上底层渲染管管道 API 对于 App 的性能起到关键作用，以 OpenGL 为例子:

> 从顶点处理（vertex processing）、图元装配（triangle assembly）、光栅化（rasterization）、片段处理（fragment processing）、测试和混合（testing and blending）这样的 Graphics Pipeline 组成了一个简单的画面渲染流程。

![](http://img.cdn.guoshuyu.cn/20240629_1112/image1.png)

而在这个流程里，**光栅化是一个非常耗时的过程，一般是通过 GPU 来加速，而将数据从 CPU 传输到 GPU 的过程也是一个耗时过程。**

> 例如在 Android 里，RenderThread 主要就是从 UI 线程获取输入并将它们处理到 GPU ，RenderThread 是与 GPU 通信的单独线程。

![](http://img.cdn.guoshuyu.cn/20240629_1112/image2.png)

而到了 Metal 和 Vulkan ，它们的出现弥补了 OpenGL 很多历史问题，将渲染性能和执行效率提高了一个层级，举个例子：

- OpenGL 是单线程模型，所有的渲染操作都放在一个线程；而 Vulkan 中引入了 Command Buffer ，每个线程都可以往 Command Buffer 提交渲染命令，可以更多利用多核多线程的能力
- OpenGL 很大一部分支持需要驱动的实现，OpenGL 驱动包揽了一大堆工作，在简化上层操作的同时也牺牲了性能；Vulkan 里驱动不再负责跟踪资源和 API 验证，虽然这提高了框架使用的复杂度，但是性能得到了大幅提升

又比如前面 iOS 上的 OpenGL & Metal ，而 Metal 相比 OpenGL 可以“更接近”底层硬件，同时降低了资源开销，例如：

> Metal 里资源在 CPU 和 GPU 之间的同步访问是由开发者自己负责，它提供更快捷的资源同步 API，可以有效降低 OpenGL 里纹理和缓冲区复制时的耗时；另外 Metal 使用 GCD 在 CPU 和 GPU 之间保持同步，CPU 和 GPU 是共享内存无需复制就可以交换数据。

**可以看到 Vulkan 和 Metal 都给 Android 和 iOS 带来了巨大的性能提升，所以如果讨论渲染实现带来的性能差异，现阶段更多应该是 Vulkan 和 Metal 的差异。**

最后，因为 Vulkan 是一个通用的底层渲染 API ，它不止考虑 Android，而 Metal 专职于苹果设备，如果不需要很严谨的对比，那么可以说 Metal 其实更简单，绝大部分实际是 Metal 对 Vulkan 在概念上的合并和简化，例如：

> **Metal 会自动帮助开发者处理幕后管理工作，它会执行更多自动化操作来处理加速视觉效果和增强性能等后台管理，然而 Vulkan 是更多提供 API，主要取决于开发者自主的控制。**

**总体而言，Metal 更容易使用，而 Vulkan 更灵活可控，当然，对比 OpenGL 其实都变复杂，特别是 Vulkan ，因为更接近底层，所以复杂度更高。**

> 所以 Flutter 在 Impeller 的第一站选中支持 iOS 的 Metal ，在解决 iOS 问题的同时，Metal 相较于 Vulkan 对于平台更专注且“简单”。

# 最后

又是一篇「又臭又长」的干文，不知道看完是否对你有所帮助？想来从实用角度而言，这又是一篇没什么用的吃灰类型的内容，不过，话说回来，也许哪天你就突然想用上了呢？





