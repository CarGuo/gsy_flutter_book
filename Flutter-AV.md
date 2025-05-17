# Android Vulkan 官宣转正并统一渲染堆栈 ，这对 Flutter 又有什么影响？

虽然从 2016 年的 7.0 开始 Android 就已经支持 Vulkan ，并且在之后 Vulkan 逐步作为首选 GPU 接口，但是现在从 2025 开始， **Vulkan 将正式官宣成为 Android 上的官方图形 API** 。

![](http://img.cdn.guoshuyu.cn/20250315_AV/image1.png)

那「转正」后和之前有什么区别？核心就是 **Vulkan 将正式作为 Android 的唯一 GPU 硬件抽象层 （HAL），Google 会要求所有应用和游戏都必须基于 Vulkan 来实现**，包括：游戏引擎、middleware 和  HWUI/Skia/WebGPU/ANGLE 等 layered API：

![](http://img.cdn.guoshuyu.cn/20250315_AV/image2.png)

这里就不得不说  ANGLE (Almost Native Graphics Layer Engine) ，虽然 Google 打算强制开发者使用 Vulkan ，但是让大家全部迁移明显不现实，毕竟 Vulkan 和 OpenGLES 的差异还是很大的，而这时候 ANGLE 就开始体现它作用。

ANGLE 作为兼容层，它支持让 GLES 应用运行到 Vulkan ，ANGLE 通过将 GLES API 调用翻译为 Vulkan API 调用，从而让 GLES 能够兼容运行到 Vulkan ，而事实上 ANGLE 在 Android 10 开始就开始尝试支持 Vulkan，但是从 Android 15 之后，**新的 Android 设备将开始转为仅通过 ANGLE 支持 OpenGL** ：

![](http://img.cdn.guoshuyu.cn/20250315_AV/image3.png)

其实做出这个决定也挺合理，从数据上看，目前超过 85% 的活跃 Android 手机都已经支持 Vulkan，而基于 Unity 引擎构建的新 Android 游戏里超过 45% 使用 Vulkan，所以 Vulkan only 确实是一个必然的选择。

![](http://img.cdn.guoshuyu.cn/20250315_AV/image4.png)

那为什么 Google 会想要替换到 OpenGL？主要也是因为 OpenGL 存在很多历史问题，例如：

- OpenGL 默认是单线程模型，而 Vulkan 中引入了 Command Buffer ，每个线程都可以往 Command Buffer 提交渲染命令，可以更方便利用多核多线程的能力
- OpenGL 很大一部分支持需要驱动的实现，OpenGL 驱动包揽了一大堆工作，在简化上层操作的同时也牺牲了性能；而 Vulkan 里驱动不再负责跟踪资源和 API 验证，虽然这提高了框架使用的复杂度，但是性能得到了大幅提升
- 还有 swapchain 差异，后面我们会聊到。

而对于即将到来的 Android 版本：

-  Android 16 将要求一些较新的设备对某些 App 使用 ANGLE
-  Android 17 将要求新设备为大多数 App 使用 ANGLE

**也就是 Android 17 开始，除了特定列表中的 App 外，所有应用都需要使用 ANGLE** 。

![](http://img.cdn.guoshuyu.cn/20250315_AV/image5.png)

另外，虽然 Vlukan 的一致性比起 OpenGL 好很多，但是为了进一步提高 Android 上的 Vulkan 实际可用功能一致性，Google 推出了适用于 Android 的 Vulkan 配置文件 （VPA）。

> VPA 是芯片组必须支持的 Vulkan 功能的集合，只有适配了，才能通过 Google 针对特定 Android 版本的认证要求，例如 Android 16 的 VPA 要求芯片组至少支持这些 Vulkan 功能：https://github.com/KhronosGroup/Vulkan-Profiles/blob/main/profiles/VP_ANDROID_16_minimums.json 。

**通过强制支持较新版本的 Vulkan，也会加速淘汰较旧的 GPU 设备**，因为使用这些较旧 GPU 的设备会不允许更新到较新的 Android 版本，这也意味着随着时间的推移， Vulkan 在未来的一致性会越来越高。

![](http://img.cdn.guoshuyu.cn/20250315_AV/image6.png)

除此之外，Google 还和 Unity Technologies 合作，让 Vulkan 和 Unity 游戏引擎的集成变得更加容易，**从而进一步降低 PC 游戏移植到 Android 的难度**。

另外，谷歌还与联发科达成合作，为联发科芯片提供 Android 动态性能框架 （ADPF），支持让开发人员根据设备的热状态实时调整游戏的性能需求：

![](http://img.cdn.guoshuyu.cn/20250315_AV/image7.png)

最后，**Java/Kotlin 开发者后续可能无需切换到 C/C++ 和 NDK 来直接访问  Vulkan**，未来 Java/Kotlin 开发者也许可以通过  Java/Kotlin 下利用 WebGPU 来“直接”体验 Vulkan 场景，从而做到相对 “直接” 的 GPU 访问：

![](http://img.cdn.guoshuyu.cn/20250315_AV/image8.png)

所以，到这里有没有一种感觉：**就像当年 Apple 全面转向 Metal 的感觉，现在 Google 终于开始也跟上这个步伐**。

![](http://img.cdn.guoshuyu.cn/20250315_AV/image9.png)

# Flutter 

**那么这些 Flutter 有什么影响？答案肯定就是 All In Impeller** ，这是 Flutter 正在做的事情，当然这也是一个「充满坎坷」的过程，因为 Android 的碎片化让 Impeller 在 Android 的落地比 iOS 复杂很多。

比如 Flutter 3.29 才发布了 Android 平台正式全面启用 Impeller ，但是 3.29.2 版本就开始「回退」，原因是 Impeller 在某些不支持 Vlukan 的低版本设备上使用 Impeller GLES 作兼容时会 Crash ，所以只能暂时再次转为 Skia GLES ：

![](http://img.cdn.guoshuyu.cn/20250315_AV/image10.png)

> 其实这也一定程度体现了 OpenGL 在兼容上的难度。。。。。

甚至在之前我们聊过的  [《全新 PlatformView 实现 HCPP》](https://juejin.cn/post/7471979172115152932) 支持上，也可能需要考虑针对 OpenGLES 增加一个 AHB swapchain 来帮助没有 Vulkan 的设备支持 HCPP ：

![](http://img.cdn.guoshuyu.cn/20250315_AV/image11.png)

甚至在 Vulkan 相关的 swapchain 支持上， AHBSwapchainVK  实现也并非在所有 Android 版本上都可用，如果不支持还需要会回退到 KHR swapchain ，例如：

- API 26 之前不支持 AHB
- AHB 某些功能和 API ，比如  AHardwareBuffer_isSupported 需要 API 29

![](http://img.cdn.guoshuyu.cn/20250315_AV/image12.png)

所以可以看到，**就算存在 Vulkan 场景，在 Android 上 Impeller 也需要根据实际场景使用不同支持**，说到这里可能大家就有点懵，**swapchain 是什么？AHB 又是什么？这里顺便简单介绍下**。

**什么是 swapchain ?  ** swapchain 简单说就是一种用于管理多个缓冲区的机制，从而确保平滑渲染和显示画面，进而防止画面撕裂，比如 swapchain 通常会有双缓冲或三缓冲，通过实现类似一个缓冲区显示的同时，另一个缓冲区正在准备渲染一下帧。

> 通俗又不严谨的说法：现在的 GPU 渲染效率很高，而系统显示的速度跟不上 GPU 渲染的速度，所有可以通过多重 buffer 的作用，提前在 GPU 渲染画面，等待提交，而提交给系统显示的过程中，就是在 buffer 之间进行交换 (Swap)。

所以也可以理解为：**swapchain 是一系列图像队列，队列会顺序交替将图像提交到系统显示**。

所以，其实当你在 Android 启用 Impeller 后会发现，如果在特定设备上出现如下图所示这种画面撕裂的问题，一般首先会怀疑 swapchain 问题，这里其实就是 Impeller 使用了 AHB swapchain 的 bug 导致：

![](http://img.cdn.guoshuyu.cn/20250315_AV/image13.gif)

那么 AHB（Android Hardware Buffer） 又是什么？简单说，**AHB 是 Android 上一种高效共享缓冲区的机制，属于进程间高效共享缓冲区的场景，支持零拷贝操作**，而 AHB 可以绑定到 EGL/OpenGL 和 Vulkan ，从而适合跨进程图形数据共享。

前面我们说过，swapchain 是一系列图像队列，队列会顺序交替将图像提交到系统显示，而如果配合  AHB ，就可以起到性能优化的作用，因为 AHB 可以做到**零拷贝意味着数据在进程间共享时无需复制** ，也就是在高帧率应用里，渲染进程生成的帧可以直接由显示进程使用而无需额外拷贝。

> 也就是，当应用渲染新帧时，AHB 确保显示进程能立即访问。

那么回到 Vulkan，对于  Vulkan 来说 swapchain 就是它的标准实现，所以它本来就是基于 swapchain 模式工作，但是由于 Android 平台存在 AHB ，所以是否使用 AHB 来加速性能对于 Impeller 就是一个需要衡量的情况：

> 至少目前看来 AHB 确实给 Impeller 带来不少问题。

所以简单总结下，对于 Vulkan 而言：

- 默认有 vkSwapchainKHR 的相关 swapchain 实现
- Android 上通过  AHBSwapchainVK 自定义可以让 Vulkan 使用 AHB 来得到性能提升，对应逻辑就是 issue 和代码里经常提到的  SurfaceControl AHB Swapchain

而对于 OpenGL 来说，它并没有标准的  swapchain 实现 ，所以如果 HCPP 模式想要支持 AHB swapchain，也就是需要上面所说的自定义来完成。

那么从 Flutter 角度看，Vulkan 和 OpenGL 的同时存在，确实也让 Impeller 在 Android 上的稳定性成本大大提高，那么未来  ANGLE 的强势介入，也许就不在会再有这种问题存在。

也许到那个时候，Flutter GPU 和 sence 场景，也能开始正式落地。



# 参考资料



- https://www.androidauthority.com/porting-pc-games-to-android-3534575/

- https://android-developers.googleblog.com/2025/03/building-excellent-games-with-better-graphics-and-performance.html







