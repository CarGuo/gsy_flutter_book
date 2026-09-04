# Flutter  Starling : 用 Swift和 Flutter 写了一个 Linux 桌面系统，震惊我一整年

这该死的即视感，又有一个用 Swift 和 Flutter Engine 组合的项目，不过 Starling 这个项目，**除了把 Flutter  的 Dart Framework  直接重写移植成了 Swift 后，还在保留 Flutter Engine 的渲染引擎，最后居然整出来了一个 Linux 桌面系统环境支持**：

![](https://img.cdn.guoshuyu.cn/image-20260730151509752.png)

没错，他用 Flutter 写了一个独立的 Linux 桌面 UI 系统，**Starling  这个就类似鱼用 Flutter 的 `Widget`、`Element`、`RenderObject`、`Layer` 和 GPU 渲染体系，重新弄了一个类似 GNOME、KDE、COSMIC 的完整桌面环境**。

因为它会自己接管 DRM/KMS、显示器、鼠标键盘、Wayland 客户端、X11 客户端、窗口管理、Dock、Spaces、Mission Control 和桌面 Portal。

另外，外部应用的窗口 Surface，也被 Starling  包装成 Flutter 的 `TextureWidget`，和标题栏、阴影、圆角、模糊、动画一起进入同一棵 Flutter Layer Tree。

![](https://img.cdn.guoshuyu.cn/image-20260730152054858.png)

碉堡了有木有？？？？没想到 Flutter 终于还是走到完整桌面这一步了，隔壁 Canonical 也才用 Flutter 做系统 App 而已，这边直接做了个新的桌面环境。

目前仓库主要分为两部分，其中 `starling-build/starling`  就是 Swift  Framework、桌面 Shell 和应用的主仓库：

| 目录        | 作用                                               |
| ----------- | -------------------------------------------------- |
| `sdk/`      | Flutter Dart Framework 到 Swift 的移植             |
| `shell/`    | 桌面 Shell、窗口管理器、Wayland 合成器、X11 Server |
| `apps/`     | 设置、文件管理器、终端、计算器、应用商店等         |
| `registry/` | 应用注册表和商店目录                               |
| `build/`    | Session、Deb 包、运行和安装工具                    |
| `docs/`     | 构建、安装、移植和设计文档                         |

> 这里的 `sdk/` 就是完整的 Flutter 版本 Swift Framework port 实现，没有 Dart VM，而 `shell/`  主要包含 compositor、window manager、Dock、Spaces 和 Portal 的桌面支持。

然后就是 `starling-build/starling-engine` ，这个是 Flutter Engine 的 Fork，主要添加两部分：

```
Flutter Engine
├── linux_drm/
│   └── DRM/KMS、GBM/EGL、libinput、libseat、多显示器 Embedder
│
└── lib/ui/swift/
    └── Flutter Engine ↔ Swift Framework 桥接层
```

> 这个仓库是基于 Flutter 3.38.6  的  fork，Starling 增量大概涉及 184 个文件。

**目前 Starling 已经支持安装到 Ubuntu 26.04、可以在 GDM 登录界面切换成真实桌面 Session**，类似于：

```
gdm3
  ↓
gdm-wayland-session
  ↓
/usr/libexec/starling-session
  ↓
DesktopShellApp --drm
```

整个项目几乎实现了完整的能力支持，比如：

- 直接进行 DRM/KMS modeset
- 使用 GBM/EGL 创建 GPU 渲染 Surface
- 通过 libinput 接收鼠标键盘输入
- 运行自己的 Wayland Server
- 运行自己的 X11 Server
- 启动 Chrome、VS Code、Slack、Discord、IntelliJ、GIMP、Blender 等普通 Linux 应用
- 提供浮动窗口和 master-stack 平铺
- 提供 Spaces、Mission Control、Dock、Launchpad
- 运行设置、文件管理、终端、计算器和应用商店等 Swift 第一方应用
- 提供一部分 `xdg-desktop-portal`，目前主要是 Settings 和 FileChooser

![](https://img.cdn.guoshuyu.cn/image-20260730155733092.png)

**也就是 Starling 本身就是一套 Wayland Compositor 和 X Server**，整个框架可以简单大致看成：

```
                         Linux 用户空间
┌───────────────────────────────────────────────────────────┐
│                    DesktopShellApp                         │
│                         Swift                             │
│                                                           │
│  ┌────────────────── FlutterSwift Framework ───────────┐  │
│  │ Widgets → Elements → RenderObjects → Layers         │  │
│  │ Gestures / Animation / Scheduler / Semantics        │  │
│  │ Fluent UI / Macos UI / Shell UI                     │  │
│  └─────────────────────────┬────────────────────────────┘  │
│                            │ Scene                         │
│  ┌──────────────┐    ┌─────▼──────────┐   ┌────────────┐  │
│  │ Wayland      │    │ External       │   │ X11 Server │  │
│  │ Server       │───▶│ Texture        │◀──│ DRI3/      │  │
│  │ xdg-shell    │    │ Registry       │   │ Present    │  │
│  └──────────────┘    └─────┬──────────┘   └────────────┘  │
│         dma-buf / wl_shm    │ EGLImage / GL Texture       │
└─────────────────────────────┼─────────────────────────────┘
                              │
                    Flutter Engine C/C++
              Scene → Rasterizer → GPU Compositor
                              │
                         GBM / EGL
                              │
                          DRM / KMS
                              │
                         显示器 CRTC
```

**其实这里可以看到一个非常关键的反转**，因为普通 Flutter 架构是：

```
Flutter 应用 → Wayland/X11 → 桌面合成器 → 显示器
```

但是现在 Starling 的实现是：

```
Wayland/X11 应用 → Starling → Flutter Layer Tree → 显示器
```

**在这里 Flutter  已经不是 App UI 框架了，它直接变成了桌面系统的服务端与最终合成层，Starling  把这个叫做 client-to-server inversion**。

![](https://img.cdn.guoshuyu.cn/image-20260730160141508.png)

所以 Starling  实际上就是把 Dart 换成了 Swift ，而且它没有改造成 SwiftUI 风格，反而保留 Flutter 原有模型了，比如Swift  版 `Widget` 还是 Element 的配置对象：

```swift
open class Widget {
    let key: Key?

    func createElement() -> Element

    static func canUpdate(
        _ oldWidget: Widget,
        _ newWidget: Widget
    ) -> Bool
}
```

更新规则依然是 `runtimeType  && key`  ，基础还是 `StatelessWidget` 创建 `StatelessElement`，`StatefulWidget` 创建 `StatefulElement` ，就连 Swift 版 `setState` 的核心也没有变化：

```swift
func setState(_ mutation: () -> Void) {
    mutation()
    element.markNeedsBuild()
}
```

甚至多子节点更新算法也被移植了，**所以看起来作者只是单纯不喜欢 Dart，不过这里面还是有一些麻烦，比如 Dart mixin 怎么映射到 Swift ？**

这算是移植 Flutter Framework 最麻烦的地方之一，因为 Flutter 大量依赖 Dart mixin，目前它的做法是：

- 无状态 mixin：Swift `protocol` + `extension` 默认实现
- 作为继承基础的有状态 mixin：转换成 class
- 无法作为基础类的有状态 mixin：拆成 Host Protocol、状态存储和 extension 实现
- 必须保留继承关系的渲染类，就用 Swift class hierarchy 表达

> 所以类似这些场景就只能通过映射来模仿，反正作者就是宁愿用 Swift 重写也不用 Dart。

接着就是 Starling  的核心，比如「桌面是怎么直接显示到屏幕上的？」，在  Starling 里面就是 `DesktopShellApp --drm` 启动，整个启动流程就类似：

```dart
runApp(
    FluentApp(
        home: DesktopShell()
    )
)

var callbacks = createRuntimeCallbacks()

let drmView = fl_drm_view_create(
    assetsPath,
    icuPath,
    &callbacks
)

let engine = fl_drm_view_get_engine(drmView)

setupWayland(engine)
setupX11(engine)
setupTextures(engine)

fl_drm_view_run(drmView)
```

当然这段是简化代码，实际入口会先建立 Widget Tree，然后再通过 `fl_drm_view_create` 初始化显示器、EGL 和 Flutter Engine，`fl_drm_view_create`  负责：

```dart
打开 /dev/dri/card*
    ↓
申请 DRM Master / libseat 会话
    ↓
枚举 Connector / CRTC / Plane
    ↓
选择显示模式
    ↓
建立 GBM Surface
    ↓
建立 EGL Display / Context
    ↓
初始化 Flutter Engine
    ↓
启动 libinput
```

> 这部分它的公共 C API 只暴露一个 `fl_drm_view.h` 给 Swift，一定程度降低了 Swift Shell 和 Engine Fork 的耦合，Shell 只依赖稳定 C API。

**然后就是 Starling 最有意思的部分，在 Starling  桌面下， 比如 Chrome、VS Code、GIMP 这些普通 Linux 应用的窗口，也会被 Starling 当成 Flutter Widget 来摆放、裁剪和做动画效果**。

**当然，在这里变成 Widget 的不是 Chrome 程序本身，只是 Chrome 窗口输出的画面而已**，Chrome 还是一个独立进程，内部还是用 Chromium、Blink 和自己的 GPU 渲染管线，Starling 只是把 Chrome 最终画好的窗口画面拿过来，包装成一个 `TextureWidget`，可以把它理解成：

```text
Chrome 负责画网页内容
        ↓
得到一张不断更新的 GPU 画面
        ↓
Starling 把这张画面放进 TextureWidget
        ↓
Flutter 再负责窗口位置、圆角、阴影、缩放和动画
```

> 类似于 Flutter 里的视频播放器，Flutter 不负责解码视频，只负责把播放器提供的每一帧纹理显示出来。

Starling 对 Chrome 窗口做的事情实际很像 Flutter 显示视频纹理：*把一个真实 Linux 应用不断提交的窗口画面，当成持续更新的外部 Texture 放进 Widget Tree*。

因为在 Wayland 里面 Chrome 不是直接往显示器上画东西。它会先在自己的 GPU Buffer 里完成网页渲染，比如：

```text
Chrome GPU 进程
    ↓
绘制标签栏、网页、文字和图片
    ↓
得到一块完整的窗口 Buffer
```

然后 Chrome 告诉 Wayland 合成器 「`这是我刚画好的新窗口画面，请显示它`」，协议上大致对应：

```c
wl_surface.attach(buffer); //给窗口挂上新的画面；
wl_surface.damage(...); //告诉合成器哪些区域发生了变化；
wl_surface.commit(); //正式提交这一帧。
```

> 普通 GNOME 桌面收到这块 Buffer 后会交给 Mutter 合成，而 Starling 收到后，会把这块 Buffer 交给 Flutter Engine。

不过 Starling 不会把 Chrome 的画面复制成一张图片， Starling 在支持 `linux-dmabuf` 的情况下，会接收一个 DMA-BUF 文件描述符，可以把 DMA-BUF 理解成：

> 一个可以在不同进程和不同 GPU 组件之间共享的缓存句柄。

所以 Chrome 给 Starling 的是  GPU Buffer 的句柄和格式信息，相关信息会包括：

```text
fd          共享 Buffer 的文件描述符
width       宽度
height      高度
stride      每行占多少字节
fourcc      像素格式，例如 XRGB8888
modifier    GPU Buffer 的内存排列方式
```

然后 Starling 把这块 GPU Buffer 注册成 Flutter Texture ，进而进入熟悉的 Flutter 的渲染流程。

如果不支持 DMA-BUF，Starling 目前大致存在四种情况：

```text
Wayland + linux-dmabuf
→ GPU Buffer 直接导入，主要走零拷贝路径

Wayland + wl_shm
→ 应用提供 CPU 共享内存，Starling 再上传为 GPU Texture

X11 + DRI3/Present
→ 获取 DMA-BUF，走 GPU 导入路径

X11 + PutImage/ShmPutImage
→ 获取 CPU 像素，再上传到 GPU
```

所以最理想的是 GPU → GPU，而兼容路径是 CPU 像素 → GPU Texture，正常来说 Chrome、Electron、GTK4、Qt6  通常都走 DMA-BUF 路径，除非一些老 App 才会走 CPU 上传路径。

而且，既然 Chrome 的窗口内容已经变成 `TextureWidget` ，你甚至可以给它包上一系列比如标题栏、阴影、圆角和缩放手柄甚至 Flutter 动画，Chrome 最终输出的窗口画面，成为了 Flutter 场景树中可以随意变换的一层。

最后，**Starling 有一个几千行 C 实现的 Wayland Server**，然后 Swift 的 `WaylandIntegration` 负责把协议事件转换为窗口系统行为，主要支持：

- `xdg-shell`
- `linux-dmabuf`
- `wl_shm`
- fractional scale
- viewporter
- pointer constraints
- relative pointer
- text-input-v3
- presentation-time
- primary selection
- idle inhibit
- xdg-decoration
- xdg-activation
- data-control 

> 也就是它没有使用 wlroots，反而是在项目内自己实现自己的协议。

**而项目也内置了一个最小 X11 Server**，监听 `:1`，支持 DRI3/Present GPU Buffer，以及 PutImage/ShmPutImage 软件路径，X11 窗口映射时同样注册 External Texture，收到 PresentPixmap 后将 DMA-BUF 导入 Texture Registry。

> **所以 X11 也不是通过 XWayland，它更接近一个面向 Starling 合成模型的内置 X Server。**

真的是一个很重的行为，甚至他已经完成了多窗口和多显示器支持，传统方案是桌面合成器自己实现一套 Scene Graph，然后应用 Framework 再实现一套，而 Starling 的想法确实骚：

> **既然 Flutter 已经有完整 Scene Graph、Layout、Animation 和 GPU Compositor，为什么不能让外部窗口也成为 Widget？**

他这也是把 Flutter 用出了新高度？**不在 Compositor 里嵌入 UI Framework，直接让 UI Framework 成为 Compositor。**

目前项目 33.5 万行  Swift/C/C++ 代码，其中约 27.3 万行属于 Flutter 到 Swift 框架移植，桌面 Shell、Wayland/X11 服务器和应用大概 6.2 万行，这基本是我见过最大的 Flutter 社区开源项目，也是做的最骚气的，没有之一。

# 链接

https://starling.build/

https://github.com/starling-build/starling