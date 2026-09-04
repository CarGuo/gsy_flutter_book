# Flutter 3D 渲染的全新选择和应用场景

昨天发布了[《Flutter 全新真 3D 实现，用 flutter_scene 能开发一个「我的世界」》](https://zhuanlan.zhihu.com/p/2063294112653129379) 之后，不少人觉得 Flutter 这是变成游戏引擎了？实际上目前的主要应用场景不是游戏，只是说确实可以做 3D 游戏，比如除了昨天说的  [bdero/flutter_scene](https://github.com/bdero/flutter_scene)  能做「我的世界」，还有一个叫 [redstone_dart](https://github.com/Norbert515/redstone_dart) 的项目，也实现用 Dart 重写的带 hot load 功能的 Minecraft 模组：

![](https://img.cdn.guoshuyu.cn/ezgif-313a904eae6c27de.gif)



实际上现在 3D 效果在 Flutter 里的应用更多类似下面这个，因为使用的是和 Flutter 同一套底层渲染，基于 `flutter_gpu` ，可以无缝地在同一个内存里渲染对应的 3D 模型：

![GIF 因为我抽帧了，所以有些扇动](https://img.cdn.guoshuyu.cn/ezgif-21647825ef2435b1.gif)

这其实才是目前 3D 能力在 Flutter 比较有用的场景，当然上图这个是另外一个 Flutter 3D 渲染库 [kiddo4/glint  ](https://github.com/kiddo4/glint) ，是的，这又是另外一个。

> ***所以虽然官方一直没自己宣传和推广  `flutter_gpu`  ，但是社区已经做了不少成功的案例，特别 Impeller 最后的桌面端 Windows 也补齐之后，  `flutter_gpu`   基本就完成了全平台 App 场景支持**。

这个  kiddo4/glint 也是一个 Flutter-first 的  3D 渲染引擎，也是基于   `flutter_gpu`    直接在 Widget 树中原生渲染 glTF/GLB 模型，只是它对比 bdero/flutter_scene 更直接一些：

> *它把 3D 场景当作普通 Flutter 状态来管理（`setState` 换材质、Widget 锚定到模型表面等），同时提供一套后端无关的物理、动画、粒子、音频契约，配合可选的原生 Box3D 物理后端和 SoLoud 音频后端组成一整套轻量游戏引擎*。

![](https://img.cdn.guoshuyu.cn/image-20260723211809174.png)

在 kiddo4/glint  的渲染核心 `GlintGpuFirstLight`  和 `GlintGameView`（多实例游戏循环）的主要实现类似：

- 先异步解码 GLB、纹理、HDR 环境图，并把顶点、索引、纹理**一次性上传为 GPU 常驻资源
- 随后每帧只更新  uniform（MVP 矩阵、光照、材质因子）并调用 `RenderPass.draw()`，把每帧开销压到最低
- 方向光阴影用独立的 CommandBuffer  和 RenderPass渲染到一张颜色纹理里，而且是把深度手写进红色通道，不采样原生 depth attachment，用来规避了当前 Flutter GPU 两个 RenderPass 共享一个 CommandBuffer 会原生崩溃的问题
- IBL 环境光通过 `.hdr` 解码 ，配合预过滤生成辐照度/镜面反射贴图供 PBR 着色器采样
- CPU 侧的三角形数据保留下来用在 Möller–Trumbore 光线相交做点击拾取和 Label3D 遮挡判断
- 物理/动画/粒子/音频都定义成纯 Dart 的**后端无关契约**，如 `GlintPhysicsWorld` ，`glint_box3d`/`glint_soloud`/`glint_basis`  可以作为可插拔的原生实现
- 通过 Dart 3.x 的  native assets 在构建期编译 C++ 扩展
- 着色器要么走内置的预编译 `.shaderbundle`，要么用户自己写 JSON Shader Graph，由 `shader_graph_build.dart` 在 `hook/build.dart` 中离线编译成 Impeller 着色器包

![](https://img.cdn.guoshuyu.cn/image-20260723211834602.png)

> *kiddo4/glint   整体确实会比  bdero/flutter_scene 轻量很多，毕竟  bdero/flutter_scene  真的是冲着游戏去的*。

所以 kiddo4/glint 是一个通用的场景图的设定，做不了游戏，但是更轻量，属于 Flutter-widget-first，场景可以声明为 Flutter 状态。

而  bdero/flutter_scene  会更重量级，虽然也可以作为一个 Widget 实现，但是 bdero/flutter_scene  还可以反过来，在游戏里直接塞 Flutter Widget ，毫无违和感：

![](https://img.cdn.guoshuyu.cn/ezgif-5318474f4397b224.gif)



比如下面就是我用  bdero/flutter_scene  和  kiddo4/glint  可以很轻松在 Flutter  App 里添加一只能自由控制的 Dash 的两个动画的效果：

![](https://img.cdn.guoshuyu.cn/ezgif-50bcd9e831829673.gif)

![demo](https://img.cdn.guoshuyu.cn/demo.gif)



**所以，是时候给你的 Flutter App 加强一下了**。





# 链接



https://glint.kiddobuild.dev/

https://fscene.dev/

https://github.com/Norbert515/redstone_dart