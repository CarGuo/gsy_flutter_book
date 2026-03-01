# Flutter 的真正价值是什么？深度解析再结合鸿蒙，告诉你 Flutter 的真正优势

这会是一篇帮你深入理解 Flutter 真正优势的内容，同时也解答了：*为什么 Flutter 在鸿蒙这个全新平台上适配可以完成得那么快*。

> 内容较长，不建议 AI 总结。

其实，一直以来 **Flutter 的最大的优势都不是它的上层 UI，而是它的底层 Embedder** ，就像 KMP 最大的优势是 Kotlin 的强大的编译器支撑一样，Flutter 的最大价值其实是它的  Flutter Embedder ：**通过 Embedder 你可以在任何「非官方」平台跑起来 Flutter **。

> 这也是为什么 Flutter 会是鸿蒙最早发布的跨平台框架 ，也是为什么「宝马」和「丰田」可以在自家车机系统使用 Flutter 、LG 的 WebOS 电视系统可以使用 Flutter、 Raspberry Pi （树莓派）和三星 Tizen  等  IoT 也使用 Flutter 的根本原因。

当然，这个场景对于一般的应用开发者来说难度较高，**因为 Embedder 的 API 虽然稳定，但 API 很底层，不适合新手直接从零开始**，所以它更多体现在企业价值，比如最近的[丰田进一步开发 Flutter ，推出全新 3D 游戏引擎 Fluorite](https://juejin.cn/post/7607112994061549595)这种情况，**它的价值在于为企业提供一套成熟的可迁移渲染架构支持**。

# Flutter Embedder 

那所谓的 Flutter Embedder 它到底“嵌入”了什么？

简单来说，Flutter 的  Engine 通常以动态库形式交付，而对外提供一个稳定 ABI 的 C 接口，所以真正把 Flutter 跑起来的，是平台侧那层很薄的 Embedder ，你可以这么理解：

- **Flutter Engine** ：Dart VM + 渲染管线（Skia/Impeller 等）、文本排版、动画、合成、语义（无障碍）等「UI 引擎本体」

- **Embedder**：负责把引擎接到真正的设备层，包括图形上下文/交换链、输入事件、VSync、线程模型、文件与资源、平台消息通道（platform channel）、可选的外部纹理/原生视图合成等。

> 为了确保 Embedder 与 Engine 版本之间的解耦，Flutter 定义了一套严格的 ABI 规则，所有的配置信息通过 `embedder.h` 中的结构体进行传递，而这些结构体的**新成员只能添加在末尾，且每个结构体的第一个成员必须是 `size_t struct_size` 的存在** ，这种设计让 Engine  可以在运行时根据传入的大小判断 Embedder 支持的 API 版本，从而实现向前和向后兼容 。

![](https://img.cdn.guoshuyu.cn/image-20260226142644077.png)

那么如果使用 Embedder 层，一般需要做什么？为什么说它对新手难度比较高？简单来说，Flutter 的 Embedder 可以按能力分成 6 个部分来理解。

## 启动和资源

核心是 `FlutterEngineRun(...)` ，它是通用的嵌入层入口，开发者要提供 `FlutterRendererConfig`（渲染后端配置）和 `FlutterProjectArgs`（资源、回调、快照等）来满足 Flutter 运行的环境，例如 `FlutterProjectArgs` 里最常见是：

- `assets_path`：Flutter 资源目录
- `icu_data_path`：`icudtl.dat`（国际化/文字相关）
- `platform_message_callback`：平台消息回调
-  AOT/JIT 所需的快照相关字段（AOT 需要提供一组 snapshot 指针；JIT 需要 assets 里有 kernel blob）

## 渲染

另外就是如何把 Flutter 画到屏幕上，`FlutterRendererConfig` 支持多种后端：OpenGL / Vulkan / Metal / Software ，一般在第三方平台，最常见的就是 OpenGL  ，对于 OpenGL  会需要实现一组回调：

- `make_current / clear_current`：切换/清理上下文
- `fbo_callback`：告诉引擎往哪个 FBO 画
- `present` 或 `present_with_info`：提交到屏幕（可带 damage 信息做局部刷新优化）
- `make_resource_current`：给后台线程的资源上下文（纹理异步上传性能很关键）

> 如果还要做更高级的合成（比如硬件 overlay plane、原生视图/多层合成），还会用到 compositor（`FlutterCompositor`）接口：引擎把 layer 信息交给平台，平台负责最终上屏合成。

当然，鸿蒙平台现在也已经实现了 Vulkan + Impeller 的默认支持。

## 线程和任务

如果对应平台，类似嵌入式里经常没有现成的消息循环模型或者多线程模型，开发者就要提供自己实现的自定义 task runner：

- `FlutterTaskRunnerDescription`：至少要实现 `post_task_callback`
- `FlutterCustomTaskRunners`：可分别指定 platform / render task runner（也可以合并到同一线程）

这部分决定了 Flutter 能否稳定跑在设备的主循环（systemd event loop、glib、Qt event loop、裸循环等）上。

## VSync

Flutter 引擎还需要在平台 VSync 同步信息来时通知 `FlutterEngineOnVsync(...)`，并且有明确线程要求（必须在调用 `FlutterEngineRun` 的线程上），没有正确 VSync，你可能会遇到：

- 帧率不稳、输入/动画延迟
- 合成节奏和显示器不同步导致抖动/撕裂风险（取决于你的 present 实现）

这个在一些嵌入式平台确实会有这个问题，所以需要开发者自己处理。

## 输入

Embedder 还需要把设备输入转成 Flutter 的事件并送入引擎，例如：

- `SendPointerEvent`（触摸/鼠标）
- `SendKeyEvent`（键盘）
- `SendWindowMetricsEvent`（大小、devicePixelRatio 变化等）

## 其他

其他的主要看你是否有哪些对应的需要，例如：

- Platform Channels 交互实现，通过 Platform Channels 把 Dart 侧调用转成平台侧实现（例如电量、蓝牙、相机等），在 embedded 平台你一样可以用 platform channels 去封装 native 能力，在 embedder C API 里对应的是：

  - 提供 `platform_message_callback` 接收来自 Dart 的消息 

  - 可以向 Dart 回复 `FlutterEngineSendPlatformMessageResponse(...)` 

- 外部纹理（External Texture），通常是用于视频流/相机/解码器/硬件图层等，例如：

  - 注册：`FlutterEngineRegisterExternalTexture`

  - 有新帧：`FlutterEngineMarkExternalTextureFrameAvailable`

  - 取消：`FlutterEngineUnregisterExternalTexture` 

- 无障碍/语义（Semantics），`FlutterProjectArgs` 里有语义更新回调，引擎也有启用/派发语义动作的接口（用于屏幕阅读、无障碍输入等）

简单总结一下，大致有：

| API 分类     | 关键函数/结构体                             | 平台对接职责                                   |
| ------------ | ------------------------------------------- | ---------------------------------------------- |
| 生命周期管理 | `FlutterEngineRun`, `FlutterEngineShutdown` | 控制引擎的启动时机与资源回收                   |
| 渲染配置     | `FlutterRendererConfig`                     | 指定 OpenGL、Vulkan 或软件渲染的回调函数       |
| 消息传递     | `FlutterEngineSendPlatformMessage`          | 实现 Dart 与原生代码的双向异步通信             |
| 事件注入     | `FlutterEngineSendPointerEvent`             | 将硬件层产生的触摸/鼠标事件转换为 UI 事件      |
| 任务调度     | `FlutterTaskRunnerDescription`              | 定义任务发布回调，将引擎任务整合进系统事件循环 |

![](https://img.cdn.guoshuyu.cn/image-20260226144444677.png)

所以，可以看出来，**从 0 实现一个 Embedder 的工作量还是不小的**，但是也可以看出，在这个过程中，你只需要专注于 如何用 Embedder 接口让 Flutter 成功运行起来，不需要关心 Engine 和 Framework 的相关实现，况且，**也没有让你真的从  0  开始写**。

比如你需要在嵌入式设备上实现 Embedder ，而嵌入式上系统大多数时候都是精简的 Linux 魔改，那么你完全可以基于  Linux embedded  稍微调整来实现对接即可，比如  `flutter-pi` 和 Sony 的 `flutter-embedded-linux` 方向：

> `flutter-pi` 就是 “轻量 Linux Embedded embedder、无需 X11/Wayland”，这种直接渲染模块（DRM）和通用缓冲管理（GBM）实现，通过“直接入屏”的渲染路径跳过了 X11 或 Wayland 等合成器，可以降低显存占用和显示延迟，非常适合一些嵌入式场景。

Flutter 的 Embedded Linux 就是目前被二次定制最多的 Embedded ，特别是它已经有的：

- 一个可以接入 Wayland 或 DRM 进行渲染的 C++ embedder
- 集成了 OpenGL 图形功能
- 支持触摸屏或遥控器等输入设备

比如鸿蒙内核，它的内核是兼容 Linux 的，基础三大件：

- POSIX 兼容 ：提供标准的类 Unix 应用编程接口，对应的内核抽象层（KAL）+  musl libc  就可以满足大部分场景
- ABI ：支持预编译 Linux 二进制程序的执行
-  HDF ：实现跨内核、跨平台的驱动开发与复用，支持 Linux 驱动

> 我们假设不是手机鸿蒙，而是 OpenHarmony ，在没有官方支持的情况下，也可以通过 Linux Embedded 去尝试接入 Flutter 。

当然，如果需要运行的平台真的很特殊，你需要从头开始，那么实现路线也很清晰：

- 首先就是获得一个可用的 Flutter Engine ，也就是能在目标设备上运行的引擎产物（常见是 `libflutter_engine.so`/类似动态库 + `icudtl.dat` 等），一般这种情况下就需要你自己编译  engine 
- 其次就是实现上面说的 Embedder，例如一个最小可运行的 MVP 大概需要：
  - 实现一个渲染对接，如果是基于 DRM/GBM，需要调用 `libdrm` 打开显示节点，通过 `libgbm` 创建缓冲区，并初始化 EGL Surface ，建立 swapchain / framebuffer / surface，实现 `FlutterRendererConfig` 对应回调和配置
  - 确定 platform channels 模型，提供 `TaskRunners` ，实现一个基于 `epoll` 或 `glib` 的消息循环，当 Flutter Engine 有任务需要执行时，通过 `post_task_callback` 通知启动器，启动器需将该任务排入系统事件队列
  - 实现  vsync  对接
  - 实现输入系统，例如利用 `libinput` 或驱动，实时获取事件并调用 `FlutterEngineSendPointerEvent` 
  - 建立 patform message
  - ···

> 在这方面三星  [Tizen 系统](https://github.com/flutter-tizen/embedder)的集成也是一个很好的例子，flutter-tizen 的 Embedder  实现，让开发者能够利用同一套代码给三星的电视、冰箱屏幕甚至手表开发应用。

# 鸿蒙

**当然， 要说 Flutter 嵌入层最成功的典型例子，那肯定是鸿蒙 Flutter** ：华为实现的 `flutter_flutter` 现在已经有 `3.35.7`的 dev 分支，也就是 framework 和 engine 已经完全合并的 Monorepo，项目在标准 Flutter 仓库的基础上进行了扩展，具体包括：

- 位于 `engine/src/flutter/shell/platform/ohos/` 的 C++ OHOS 平台 shell
- 位于 `engine/src/flutter/shell/platform/ohos/flutter_embedding/` 的嵌入实现
- `packages/flutter_tools/` 中的 OHOS 特定构建命令
- 引擎 `bin/internal/engine.ohos.version` 和 `bin/internal/engine.ohos.har.version`
- ····

首先我们前面说的`FlutterEngineRun` 是通用 Embedder API，在鸿蒙上会通过 ArkTS -> NAPI -> native 路径调用，而`FlutterRendererConfig` 在鸿蒙上与 `XComponent` 强绑定，由 `XComponentBase` 实现具体渲染回；`FlutterProjectArgs` 中的资源路径、AOT 数据、任务运行器等会结合鸿蒙文件系统与线程模型配置，通过 `FlutterNapi` 将 ArkTS 层配置转换为 native 层 `FlutterEngineRun` 所需参数：

![](https://img.cdn.guoshuyu.cn/image-20260226133512157.png)

具体层级关系如下图所示：

![](https://img.cdn.guoshuyu.cn/image-20260226125356701.png)

在这里，Embedding 的实现具体有：

1、`FlutterAbility` 继承自鸿蒙的 `UIAbility`，是独立页面的入口，主要负责：

- 持有并初始化 `FlutterAbilityAndEntryDelegate` （包括   `doInitialFlutterViewRun()` 、生命周期映射和 `FlutterEngineCache` 、 `FlutterEngineGroup` 等逻辑）
- 向下转发所有系统生命周期事件

而这里 `FlutterEngine` 就是 Flutter 在  Embedding 的  ArkTS  执行环境的实现，管理所有系统通道和插件，主要包括：

- `LifecycleChannel`：应用生命周期
- `NavigationChannel`：路由导航
- `TextInputChannel`：文字输入
- `PlatformChannel`：平台能力
- `SettingsChannel`：系统设置（亮度/字体/时钟格式）
- `LocalizationChannel`：国际化/语言
- `AccessibilityChannel`：无障碍
- `RestorationChannel`：状态恢复
- `NativeVsyncChannel`：原生垂直同步

![](https://img.cdn.guoshuyu.cn/image-20260226134845156.png)

2、FlutterNapi 是 ArkTS 与 C++ 原生引擎之间的核心沟通实现：

- ArkTS 层会调用 `FlutterNapi.init()` ，传入`bundlePath （应用包路径）、`appStoragePath`（应用存储路径）、`engineCachesPath` （引擎缓存路径）、`args`（命令行参数）、`initTimeMillis`（初始化时间戳）、`productModel` （设备型号） 等参数
-  `FlutterNapi.xComponentAttachFlutterEngine()` 将 `XComponent `和 native Shell 绑定，核心是将 `xcomponentId` 与 `nativeShellHolderId` ![](https://img.cdn.guoshuyu.cn/image-20260226135223515.png)

> 一般路径： engine/src/flutter/shell/platform/ohos/flutter_embedding/flutter/src/main/cpp/types/libflutter/index.d.ets

3、渲染上， `FlutterPage` 是鸿蒙特有的渲染容器， 用 `XComponent` 作为 Flutter 渲染的承载 ，`FlutterPage.ets` 中的 ArkUI `XComponent` 指定了 `libraryname: 'flutter'` ，所以会加载 `libflutter.so` 并触发 `library_loader.cpp` 中的 NAPI 注册 ：

![](https://img.cdn.guoshuyu.cn/image-20260226135445073.png)

然后每个 Flutter 实例对应一个 `OHOSShellHolder`，持有完整的 Flutter Shell：` ohos_shell_holder`，OHOS 通过自己的抽象层（`OHOSContext`/`OHOSSurface`）和 NAPI 桥接，不直接构造 `FlutterRendererConfig`，而是由 `PlatformViewOHOS` 的 `CreateRenderingSurface()` 返回对应的 `Surface` 和 `CreateOHOSContext` 返回渲染上下文

![](https://img.cdn.guoshuyu.cn/image-20260226130432338.png)

4、`OH_NativeVSync` 原生 VSync 信号驱动帧渲染，`VsyncWaiterOHOS` 负责等待信号并触发帧调度，同时支持帧缓存模式的 Dvsync 开关：

![](https://img.cdn.guoshuyu.cn/image-20260226135819625.png)

5、最后通过 `EmbeddingNodeController`（继承 `NodeController`）实现，利用 `BuilderNode` 和 `FrameNode` 完成混合渲染，这个我们在之前的 [《深入理解 Flutter 的 PlatformView 如何在鸿蒙平台实现混合开发》](https://juejin.cn/post/7559875444817526847)有聊过 。

最后简单总结的话，类似如下结构：

| Class                     | File                                          | Role                                                  |
| ------------------------- | --------------------------------------------- | ----------------------------------------------------- |
| `FlutterAbility`          | `embedding/ohos/FlutterAbility.ets`           | `UIAbility` 子类；应用程序生命周期入口点              |
| `FlutterEntry`            | `embedding/ohos/FlutterEntry.ets`             | OHOS 页面级入口点；封装了 `FlutterPage`               |
| `FlutterView`             | `view/FlutterView.ets`                        | 拥有 `ViewportMetrics` ，路由触摸/键盘/生命周期事件   |
| `FlutterNapi`             | `embedding/engine/FlutterNapi.ets`            | 调用 `libflutter.so` 导出；持有 `nativeShellHolderId` |
| `TextInputPlugin`         | `plugin/editing/TextInputPlugin.ets`          | API 将 Flutter IME 协议桥接到 OHOS `inputMethod` API  |
| `PlatformViewsController` | `plugin/platform/PlatformViewsController.ets` | 管理嵌入在 Flutter 中的 OHOS 原生视图                 |

| Class / File                                          | Role                                                         |
| ----------------------------------------------------- | ------------------------------------------------------------ |
| `PlatformViewOHOSNapi`                                | 将 C++ 函数导出为 NAPI 符号；处理 `nativeInit` 、 `nativeAttach` 、 `nativeDispatchPlatformMessage` 、 `nativeSetViewportMetrics` |
| `PlatformViewOHOS`                                    | 实现引擎的 `PlatformView` 接口；创建渲染上下文和表面。       |
| `OHOSXComponentAdapter`                               | 接收`XComponent  Surface 生命周期回调和触摸事件              |
| `OHOSExternalTextureGL` / `OHOSExternalTextureVulkan` | GL 和 Vulkan 路径的外部纹理支持                              |

整体流程如果在鸿蒙视角下流程如下图所示：

![](https://img.cdn.guoshuyu.cn/image-20260226131906420.png)

我们回顾一下，可以发现，Flutter 在适配鸿蒙的实现上接入十分干净，就是拓展了：

- **`engine/src/flutter/shell/platform/ohos/`**：C++ 原生层实现，包含平台适配、渲染后端、NAPI 桥接等
- **`engine/src/flutter/shell/platform/ohos/flutter_embedding/`**：ArkTS 嵌入层实现，提供 Flutter 应用在鸿蒙上的运行时环境

其中 `flutter_embedding/` 主要提供 ArkTS 的环境嵌入支持：

- **入口与生命周期**：`FlutterAbility.ets`、`FlutterEntry.ets` 提供两种宿主模式 FlutterAbility.ets:43-60
- **引擎管理**：`FlutterEngine.ets`、`FlutterEngineGroup.ets` 管理引擎实例与复用 FlutterEngine.ets:69-120
- **通道系统**：各类系统通道（PlatformChannel、TextInputChannel 等）实现 PlatformChannel.ets:25-47
- **插件架构**：`FlutterPlugin.ets` 接口与插件注册机制 FlutterPlugin.ets:18-60

`flutter_embedding/` 之外主要提供平台嵌入的底层 C++ 支持，通过 NAPI 与上层 ArkTS 交互

- **平台视图**：`PlatformViewOHOS` 实现 Flutter 的 PlatformView 接口 platform_view_ohos.h:58-100
- **渲染后端**：`OHOSSurface` 系列类封装 Vulkan/OpenGL/软件渲染
- **NAPI 桥接**：`platform_view_ohos_napi.cpp` 暴露 native 接口给 ArkTS
- **XComponent 适配**：`ohos_xcomponent_adapter.cpp` 处理 XComponent 生命周期

所以从整个鸿蒙的适配实现上，**我们就可以很直观看到  Flutter Embedder 的价值，它可以让一个全新的系统和平台，用非常干净的方式接入 Flutter** ，并且平台只需要专注于 Embedder  层的实现即可，这也是为什么 Flutter 在鸿蒙平台跟进速度最快的原因。

# 最后 



从这里可以看出来，Flutter 的 Embedder  实现才是发挥 Flutter 最大价值的地方，只是它的门槛较高，一般情况只有企业才能发挥它的价值，这也是为什么 Flutter 会出现在越来越多的产品里的原因，甚至出现在小米核心应用层、OPPO 负一屏和微信小程序 skyline 的原因，因为它确实很好迁移到不同平台，甚至是特殊平台，你不用 Dart ，也需要用它跨平台的渲染管道和 UI 编排能力。

> 当然，如果社区的 [flutter_zero 项目](https://juejin.cn/post/7603769956976377897)能做起来的话，那 Flutter 的解耦和跨平台能力就可以进一步得到放大，不过这估计是很遥远之后的事情了。

而现在，在有清晰的结构分层和已有的实现例子上，本身 AI 就可以很快的帮你实现一层 Embedder  ，这也是 Flutter 在 AI 时代更容易被小众平台接入为渲染框架的原因。

所以，Flutter 更多的价值体现在于 Embedder 的设计，还有 Impeller 的发布，这些才是 Flutter 的核心资产。

































