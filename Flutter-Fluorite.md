# 丰田正在使用 Flutter 开发游戏引擎 Fluorite

近日，丰田汽车旗下子公司丰田互联北美公司宣布，即将开源基于 Flutter 的自主研发的游戏引擎 [Flourite](https://fluorite.game/) ，而实际上在此之前，Flutter 已经是丰田车机的开发 SDK 之一。

> Toyota Connected North America，TCNA，是丰田的北美子公司，专注于车载软件、AI 等。

Fluorite 是首款完全集成 Flutter 的主机级（console-grade）游戏引擎，主要针对车载数字座舱（digital cockpit）和嵌入式低端硬件设计，已在 2026 款丰田 RAV4 的信息娱乐系统上运行，并在 2026 年 2 月在 FOSDEM 2026 大会上公布 ：

![](https://img.cdn.guoshuyu.cn/image-20260217233545670.png)

**这是一个支持主机级 3D 渲染的项目** ，我们可以在演示中看到，官方展示的 3D 游戏 Demo 复线了一个相对完整的 3D 游戏场景：

![](https://img.cdn.guoshuyu.cn/ezgif-541173fead9e9873.gif)

TCNA 明确表示 Fluorite 将会作为开源项目独立发布，在 OpenEmbedded/Yocto 中目前已经有 Fluorite 示例场景的配方（recipes），而之所以选择采用 Flutter 自研 Fluorite，是因为丰田需要避免使用 Unity/Unreal 等专有引擎带来的费用高、资源重和许可问题，而不直接使用  `flutter_gpu `，则是目前整体成熟度还不够：

![](https://img.cdn.guoshuyu.cn/image-20260217233743993.png)

目前 Fluorite 的设计强调高性能、低资源占用，游戏逻辑/UI 用 Dart/Flutter 编写，底层 C++ 优化，核心架构是 ECS（Entity-Component-System），支持热 Hot Reload，包括场景、代码、资产生效：

![](https://img.cdn.guoshuyu.cn/ezgif-5bd69ef595b1d269.gif)

也就是 Fluorite 允许开发者直接用 Dart 写代码，从而降低了游戏开发的复杂度，同时可以使用 `FluoriteView`  控件添加多个 3D 场景视图，并且游戏实体和 UI 控件之间的状态共享：

![](https://img.cdn.guoshuyu.cn/image-20260217233936021.png)

| 组件            | 技术/工具                                                    | 作用/特点                                                    |
| --------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **UI/游戏逻辑** | Flutter + Dart                                               | 直接用 Dart 写游戏代码，可以利用 Flutter Widget 和状态管理（如 Provider/Riverpod），FluoriteView 小部件嵌入 3D 视图，与 UI 共享实体状态。 |
| **核心引擎**    | C++ ECS                                                      | 高性能实体-组件-系统架构，针对低端/嵌入式硬件优化。          |
| **渲染**        | Google Filament                                              | 主机级 3D 渲染（PBR 物理基渲染、Vulkan 后端、光照、后处理、自定义着色器），支持 glTF 2.0/GLB 模型。 |
| **输入/输出**   | SDL3                                                         | 跨平台 I/O 支持                                              |
| **物理**        | JoltPhysics（路线图）                                        | 未来集成                                                     |
| **资产工具**    | Blender                                                      | 模型定义触摸触发区（touch trigger zones），支持 onClick 事件 |
| **平台/OS**     | Embedded Linux (Yocto/AGL/Wayland)；桌面（Linux/Mac/Windows）；Android/iOS；主机；Web（探索中） | 车载优先，低启动时间                                         |

![](https://img.cdn.guoshuyu.cn/image-20260217234007868.png)

![](https://img.cdn.guoshuyu.cn/c40fea02-962b-4ffe-a2cc-50886bf75b47.png)

对于  Fluorite ，目前主要的集成方式就是用 `FluoriteView`  在 Flutter App 中添加多个 3D 视图，所以可以直接用 Flutter 生态，而 C++ 核心确保在低端硬件（如车载屏）实现主机级效果，避免 Godot 等开源引擎的启动慢/资源重问题，具体有：

> 物理准确光照、后处理效果、可访问性（accessibility）、着色器管道（shader pipeline）、Blender 中定义点击区触发事件等

**更具体的应用场景是在车载 3D 教程/娱乐/交互 UI，未来扩展游戏机/移动等**，官方表示 Fluorite 是开放的，并会以开源方式分发，即使未来丰田不使用它开发游戏，但引擎也会作为独立解决方案也存在，尤其对针对资源有限的设备场景。

![image-20260217234026451](https://img.cdn.guoshuyu.cn/image-20260217234026451.png)

这么看来，也是短时间内  Fluorite  可以成为 `flutter_gpu` 的替代，不得不说 Fluorite 也算是之前我们提到过的 [flame_3d](https://juejin.cn/post/7545699564176719914) 的另外一种补充。



# 更多可见

- https://fluorite.game
- https://github.com/toyota-connected