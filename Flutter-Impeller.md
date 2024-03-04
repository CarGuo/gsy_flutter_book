# 2024 Impeller：快速了解 Flutter 的渲染引擎的优势

> 参考原文 ：https://tomicriedel.medium.com/understanding-impeller-a-deep-dive-into-flutters-rendering-engine-ba96db0c9614

最近，在 [Flutter 2024 路线规划](https://juejin.cn/post/7335067315452428297)里明确提出了，**今年 Flutter Team 将计划删除 iOS 上的 Skia 的支持，从而完成 iOS 到 Impeller 的完全迁移**，Android 上的 Impeller 今年预计将完成 Vulkan 和 OpenGL 支持，目前[ Flutter 发布的 3.19 ](https://juejin.cn/post/7334503381200781363)上 Android 就完成了 OpenGL 的预览支持。

> 所以现在我们有必要了解下 Impeller 是什么，它和 Skia 的区别在哪里。

Impeller 作为 Flutter 新一代的渲染引擎，**它的核心就是负责绘制应用的界面，包括布局计算、纹理映射和动画处理等等**，它会将代码转换为像素、颜色、形状，所以 Impeller 是会直接影响到应用的性能和渲染效果，这也是很多早期 Flutter 开发者从 Skia 升级到 Impeller 经常遇到的痛点，例如：

- 字体加载异常，字形和排版与之前不对，如 [#142974 ](https://github.com/flutter/flutter/issues/142974)、[#140475](https://github.com/flutter/flutter/issues/140475) 、[#138670 ](https://github.com/flutter/flutter/issues/138670)、[#138386](https://github.com/flutter/flutter/issues/138386)
- 线条渲染或裁剪不一致，如 [#141563 ](https://github.com/flutter/flutter/issues/141563)、 [#137956](https://github.com/flutter/flutter/issues/137956)
- 某些纹理合成闪烁/变形，如 [#143719](https://github.com/flutter/flutter/issues/143719) 、[#142753](https://github.com/flutter/flutter/issues/142753) 、[#142549](https://github.com/flutter/flutter/issues/142549) 、[#141850](https://github.com/flutter/flutter/issues/141850)
- ····

可以看到，Impeller 在替换 Skia 这条路上有许多需要处理的 bug ，甚至很多问题在 Skia 上修复过了，在 Impeller 上还要重新修复，那为什么 Flutter 团队还要将 Skia 切换到 Impeller 呢？是 Skia 不够优秀吗？

首先 Skia 肯定是一个优秀的通用 2D 图形库，例如 Google Chrome 、Android、Firefox 等设备都是用了 Skia ，但是也因为它的「通用性」，所以它不属于 Flutter 的形状，它无法专门针对 Flutter 的要求去进行优化调整，例如 Skia 附带的许多功能超出了 Flutter 的要求，其中一些可能会导致不必要的开销并导致渲染时间变慢，而目前来看，**Skia 的通用性给 Flutter 带来了性能瓶颈**。

而 Impeller 是专门为  Flutter 而生，它主要核心就是优化 Flutter 架构的渲染过程，它渲染方法在 Flutter 上可以比 Skia 能更有效地利用 GPU ，**让设备的硬件以更少的工作量来渲染动画和复杂的 UI 元素，从而提高渲染速度**。

另外 **Impeller 还会采用 tessellation 和着色器编译来分解和提前优化图形渲染**，这样 Impeller 就可以减少设备上的硬件工作负载，从而实现更快的帧速率和更流畅的动画。

> 着色器可以在 GPU 上运行从之控制图形渲染，与 Skia 不同的是，Flutter 上 Skia 会动态编译着色器，这可能导致渲染延迟，而在 Impeller 会提前编译大部分着色器，这种预编译可以显着降低动画过程中出现卡顿，因为 GPU 不必在渲染帧时暂停来编译着色器。

**Impeller 还采用了新的分层架构来简化渲染过程**，架构允许 Engine 的每个组件以最大效率执行其特定任务，从而减少将 Flutter  Widget 的转换为屏幕上的像素所需的步骤。

所以，Impeller 的设计采用了分层结构，每一层都建立在下一层的基础上执行专门的功能，这种设计使引擎更加高效，并且更易于维护和更新，因为它分离了不同的关注点。

首先，**Impeller 架构的顶层是 Aiks**，这一层主要作为绘图操作的高级接口，它接受来自 Flutter 框架的命令，例如绘制路径或图像，并将这些命令转换为一组更精细的 “Entities”，然后转给下一层。

![](http://img.cdn.guoshuyu.cn/20240221_Impeller/image1.png)

Aiks 的下一层下是  Entities Framework，它是 Impeller 架构的核心组件，当 Aiks 处理完命令时生成 Entities 后，**每一个 Entity 其实就是渲染指令的独立单元，其中包含绘制特定元素的所有必要信息**。

每个 Entity 都带有 transformation 矩阵（编码位置、旋转、缩放）等属性，以及保存渲染所需 GPU 指令的content object ，这些内容对象非常灵活，可以管理许多 UI 效果，如纯色、图像、渐变和文本，当时现在 Entities 还不能直接作用于 GPU， 因为 Engine 还需要和 Metal 或者 Vulkan 进行通信。

![](http://img.cdn.guoshuyu.cn/20240221_Impeller/image2.png)

所以 HAL（Hardware Abstraction Layer） 出现了，它构成了 Impeller 架构的基础，它为底层图形硬件提供了统一的接口，抽象了不同图形 API 的细节，该层确保了 Impeller 的跨平台能力，它将高级渲染命令转换为低级 GPU 指令，充当 Impeller 渲染逻辑和设备图形硬件之间的桥梁。

![](http://img.cdn.guoshuyu.cn/20240221_Impeller/image3.png)

大家都知道，**渲染引擎中最耗时的任务就是渲染管道和着色器编译**，渲染管线是 GPU 执行渲染图形的一系列步骤，这些是由 HAL 生成处理，所以在性能上 HAL 也当任和很重要的角色。

> 对渲染管道感兴趣的也可以简单了解下：https://juejin.cn/post/7282245376424345656

另外就像前面说的， Impeller 提前预编译大部分着色器，这种策略可以显着减少渲染延迟并消除与动态着色器编译相关的卡顿，而**这个预编译发生在 Flutter 应用的构建过程中**，确保着色器在应用启动后立即可用

> 并且一般情况下，预编译的着色器会导致应用启动时间变成和 App 大小剧增，但是因为 Impeller 专为 Flutter 而生，所以 Impeller 的着色器预编译可以依赖一组比 Skia 更简单的着色器，从而保持应用的启动时间较短且整体大小不会剧增的效果。

最后，如果你使用 Flutter 有一些时间，那么你应该知道，抗锯齿（Anti-Aliasing）和裁剪（Clip）是一种比较昂贵的操作，而这些在 Impeller 里也得到了底层优化。

在 Impeller 里抗锯齿是通过多重采样抗锯齿 (MSAA) 来解决， MSAA 的工作原理是在像素内的不同位置对每个像素进行多次采样，然后对这些样本进行平均以确定最终颜色，最后将对象的边缘与其背景平滑地融合，减少其锯齿状外观。 

![](http://img.cdn.guoshuyu.cn/20240221_Impeller/image4.gif)

对于裁剪操作，Impeller 利用模板缓冲区 stencil buffer（GPU 的一个组件）来管理剪切过程，当 Impeller 渲染 UI 时，它会先让 GPU 使用模板缓冲区，该缓冲区主要充当过滤器，根据 clipping  蒙版确定应改显示哪些像素，最后通过优化模板缓冲区，Impeller 可确保快速执行剪切操作。

所以，现在你理解 Impeller 的优势了吗？

虽然从 Skia 到 Impeller 的切换还有需要细节需要优化，但是 2024 年 Impeller 应该毫不意外会成为 Flutter 在 Android 和 iOS 的默认引擎，而 Skia 也大概率会在 2024 和我们说再见，那么，你准备好了迎接 Impeller 的洗礼了吗？