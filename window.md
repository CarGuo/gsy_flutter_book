# Flutter 官方多窗口体验 ，为什么 Flutter  推进那么慢，而 CMP 却支持那么快

随着 Flutter 多窗口的推进，现在已经可以在 [PR#167393](https://github.com/flutter/flutter/pull/167393/) 体验到对应的 Demo ，而多窗口的功能现在主要是 Canonical(Ubuntu) 在负责推进，分支里已经支持了 Windows 和 macOS 平台的基础能力，另 Linux 的支持还在开发，**这两天体验下来多窗口的基础效果还算将就**：

![](https://img.cdn.guoshuyu.cn/image-20250529161225144.png)![](https://img.cdn.guoshuyu.cn/image-20250529161904608.png)

而最近恰好又在评论区看到类似下方的问题，其实这个问题被问了不止一次，干脆就顺便简单展开聊聊：

![](https://img.cdn.guoshuyu.cn/image-20250527100512184.png)

确实 Flutter 的 PC 多窗口支持进度一直很缓慢，还是直到 [Canonical 接手推进](https://juejin.cn/post/7431894641426202636)之后才有了实质性进展，那为什么 Flutter 的多窗口支持这么坎坷？而“晚到”的 Compose Multiplatform 早早就支持了多窗口？

# Compose Multiplatform 

**事实上 Compose Multiplatform 之所以能快速支持多窗口，核心就在于 JVM** ，基于 JVM 的桌面端让 Compose Multiplatform 在多窗口支持上无需「从零开始」，甚至很多桌面功能都不需要从头实现。

![](https://img.cdn.guoshuyu.cn/compose-multiple-windows.animated.gif)

Compose Multiplatform 的桌面端依赖于 JVM，而其在底层又利用了 AWT (Abstract Window Toolkit) 和 Swing 技术来实现，例如 `ComposeWindow` 对象本身就是一个 Swing `JFrame`：

![](https://img.cdn.guoshuyu.cn/image-20250527131627201.png)

所以，基于 JVM 和 Swing 生态，对于多窗口和对话框的支持其实已经十分完善，比如关于窗口焦点和路由切换，很大程度上底层可以由 AWT/Swing 处理兼容，实质上简化了 CMP 在事件转换和窗口内部分发等方面的工作：

![](https://img.cdn.guoshuyu.cn/image-20250526171627863.png)

例如：

- CMP 无需在对应的顶层窗口之间实现复杂的内部焦点路由系统
- 只需通过`ComposeSceneMediator` 将 AWT 事件（鼠标、键盘）转换为 Compose 事件，并分发到该特定焦点窗口内的 Composable 层级
- 所有窗口都在同一个 JVM 进程中运行，它们可以共享对象并通过已建立的机制进行通信

而最终 CMP 需要处理的就是利用 Skiko 为每个窗口的独立 Surface 进行渲染，所以站在“巨人肩膀”的好处在这里完美体现。

> 这其实也是为什么不在 PC 采用 Kotlin/Native 的原因之一，对于 JetBrains 来说，离开 JVM 很多已有支持会变成「崎岖难行」，OKHttp 也是基于此原因没有支持  Kotlin/Native （iOS）。

当然，JVM 机制也带来了一些负面，比如对性能和内存的跟踪问题，例如:

- [#CMP-6570](https://youtrack.jetbrains.com/issue/CMP-6570) 提到，在没内存泄露的情况下，出现内存无法被跟踪，导致 Java NMT 和实际内存相差过大，导致后续性能持续下滑
- [CMP-7079](https://youtrack.jetbrains.com/issue/CMP-7079/Extremely-high-retained-memory-usage-for-path-animation) 也提到了内存使用问题，在 JVM 之外的内存异常增长且无法释放：![](https://img.cdn.guoshuyu.cn/ezgif-4a168cbe191747.gif)
- [CMP-7070](https://youtrack.jetbrains.com/issue/CMP-7070) 下也提到桌面窗口的大小调整导致的内存异常跳跃且不释放问题，并且渲染出现异常![](https://img.cdn.guoshuyu.cn/ezgif-4e67c5aa14d03e.gif)

> 内存、性能、线程和字符问题在 CMP 桌面端是比较常见的瓶颈部分。

# Flutter

而对于 Flutter 来说，很明显在早期它的设计主要是贴合移动端，**所以属于常见的单窗口设计**，Flutter 的用户界面是渲染在单一 Surface 上，原有的 Engine 架构（包括 Shell、PlatformView、Engine、Animator 和 Rasterizer ）也是专为单引擎单 Surface  设计，并且它采用的是自己独立的 DartVM，**这也导致了它在后续 PC 多窗口支持上大量功能需要从零开始**，也是直到 Canonical 接手推进之后，Flutter 上的多窗口才有了新的实质性变化：

![](https://img.cdn.guoshuyu.cn/image7.gif)

> 虽然在此之前社区存在 `desktop_multi_window ` 的多窗口方案，但是它创建的每个窗口都运行在不同的 Flutter 引擎实例上 ，所以它更接近于一个多引擎的实现，这会导致大量的内存占用和数据隔离，从实际使用角度出发，只适用于临时救急的场景。

而在 Canonical 的方案里，**单引擎、多视图模型**才是多窗口的实现方向，只有支持了单个引擎和单个 Dart isolate 支持多窗口渲染的场景，才能避免高内存占用和数据隔离问题。

多视图模型的核心在于**单个引擎和单个 Dart isolate 能够渲染到多个窗口或 Surface 上**，这意味着 Flutter 实质上需要在 Engine 内部创建一套全新的窗口管理系统，而不是像 CMP 可以通过 AWT/Swing  依赖已有的成熟体系，例如：

- 来自上层的 PointerEvents 需要包含视图 ID 等相关信息，在 Engine 层需要清楚“感知”并区分事件来自不同视图
- 光栅化管线需要重构，`Animator`  等组件需要支持多个 layer tree 并进行分发 ，`Rasterizer` 的结构也必须进行调整兼容多视图 
- 需要处理多视图下「光栅化阻塞了另一个视图」、「多个视图的 UI 线程工作序列化效率低下」等相关问题
- 每个视图可能位于具有不同刷新率的不同显示器上时的  VSync 问题
- ·····

所以，支持多窗口容易，但是落地一个「能用」的多窗口支持，将单一视图支持调整为多视图支持，需要从 Framework、Engine 和 Embedder 层进行大量调整。

而根据目前 [#167393](https://github.com/flutter/flutter/pull/167393/) 的推进情况看，后续多窗口会是基于 FFI 实现的支持，进而提升性能和简化调用：

![](https://img.cdn.guoshuyu.cn/ezgif-24305874b8ba4b.gif)

根据当前 PR，在启动时 Engine 会为根 isolate 提供引擎句柄，然后 Dart 代码可以将句柄传递给 FFI 调用：

- iOS, macOS - `[FlutterEngine engineForHandle:handle]`.
- Windows - `FlutterDesktopEngineForHandle(handle)`
- Linux - `fl_engine_for_handle(handle)`.
- Android - `io.flutter.embedding.engine.FlutterEngine.forHandle(handle)` (static method).

![](https://img.cdn.guoshuyu.cn/image-20250527101857428.png)![](https://img.cdn.guoshuyu.cn/image-20250527102036566.png)

这代表着当前 Flutter 引擎实例的句柄可以从 Dart 通过 FFI 传递给原生代码，原生代码随后可以使用这个句柄获取对实际 `FlutterEngine` 对象的引用（例如 Windows 上的 `FlutterDesktopEngineForHandle`，Linux 上的 `fl_engine_for_handle`），从而让 FFI 调用能够关联到正确的引擎实例，也让 View Id 可以和 Engine Id 关联工作：

![](https://img.cdn.guoshuyu.cn/image-20250527103100761.png)![](https://img.cdn.guoshuyu.cn/image-20250527103352453.png)

另外，类似 [#168376](https://github.com/flutter/flutter/issues/168376) 提交的，`Animator` 需要为多个 layer tree 并进行分发 ，`Rasterizer` 的结构也必须进行调整从而兼容多视图，`ExternalViewEmbedder` 需要能够处理多个视图任务，并将内容呈现到正确的视图上 ，**这些调整也容易导致出现如光栅时间过长、FPS 过低的问题**。

因为单一 Engine 在渲染多个视图时，**光栅线程、UI 线程和 GPU 访问权限等资源必须被共享或复用**，这导致了在处理多个渲染目标时内部存在「竞争」或「低效调度」等问题，比如一个视图的光栅化阻塞了另一个视图等情况，所以需要设计全新的 ["Stream" scenes #145712](https://github.com/flutter/flutter/issues/145712) 来改进 UI 和光栅线程之间的并行化支持。

可以理解，从零开始支持多窗口不难，但是实现一个可用的多窗口就需要解决很多细节问题，目前通过 [#167393](https://github.com/flutter/flutter/pull/167393/) 的 Demo，我们也可以看到一些多窗口的使用示例：

```dart
import 'package:flutter/material.dart';
import 'app/main_window.dart';

void main() {
  final RegularWindowController controller = RegularWindowController(
    contentSize: WindowSizing(
      size: const Size(800, 600),
      constraints: const BoxConstraints(minWidth: 640, minHeight: 480),
    ),
    title: "Multi-Window Reference Application",
  );
  runWidget(
    RegularWindow(
      controller: controller,
      child: MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Home(),
      useWindowingApi: true  // When true, material widgets will use the windows API where appropriate
    );
  }
}


```

目前看起来多窗口的 API 设计和基础支持基本已经完成，核心挑战在于如何在单 Engine 下实现有效的多视图渲染优化，并发处理不同窗口的事件切换和渲染阻塞，这也是多窗口最终落地的核心挑战。

> 目前想体验多窗口可以自己根据  https://github.com/flutter/flutter/pull/167393/ 的  PR 分支或者 https://github.com/canonical/flutter 的对应分支编译引擎体验。

前段时间也刚好有人再问编译的事情，这里就一并说了，我在这里是基于 https://github.com/knopp/flutter/tree/multiwindow_ffi 分支在 **windows** 进行本地引擎编译，简单来说，如果你想提前体验，就需要编译 engine ：

- python3 环境
- git clone  https://chromium.googlesource.com/chromium/tools/depot_tools.git，并将路径配置到环境变量
- git  clone [knopp/flutter](https://github.com/knopp/flutter) ，然后切换到 multiwindow_ffi 分支
- 将 `flutter\engine\scripts` 下的 `standard.gclient` 复制到根目录，并改名为 `.gclient` 
- 执行 `gclient sync -D` ，等到一个漫长的事件，这里对网络环境和能力很考验
- 切换到 `engine/src/` 目录，执行 `python .\flutter\tools\gn --unoptimized`
- 执行 `nijia -C .\out\host_debug_unopt ` 等待编译，这个过程考验电脑 cpu 和硬盘空间，算上前面同步的，大概会 30-40 G 的占用：![](https://img.cdn.guoshuyu.cn/image-20250529164340520.png)![](https://img.cdn.guoshuyu.cn/image-20250529170834440.png)
- 切换到 `flutter\examples\multi_window_ref_app` 目录，执行运行命令 `flutter run -d windows --local-engine C:\Users\xxxx\flutter\engine\src\out\host_debug_unopt --local-engine-host C:\Users\xxxx\flutter\engine\src\out\host_debug_unopt  --local-engine-src-path C:\Users\xxxx\flutter\engine\src` ，核心就是让 engine 指向本地，运行本地 engine 项目

这里你可能会遇到一些问题，例如：

- 本地 flutter 命令行需要指向 knopp/flutter 项目，不是官方的 flutter 环境，不然会找不到 flutter/package 下的代码，因为目前 `window.dart` 等代码是在 `flutter\packages\flutter\lib\src\widgets`
- 如果遇到说 dart 版本不对，可以将 `host_debug_unopt ` 在的 `dart-sdk` 替换到 `flutter\bin\cache` 下
- 如果遇到提示你因为 flutter 版本 unknow 不对，可以简单在 `\flutter\bin\cache\flutter.version.json` 将 `frameworkVersion` 和 `flutterVersion` 修改为 3.32.0 直接解决

而正常配置后，打开项目可以看到此时对应新增对象可以被成功识别：

![](https://img.cdn.guoshuyu.cn/image-20250529164326613.png)

还可以将需要运行的参数配置到 `Run Configuratons` ：

![](https://img.cdn.guoshuyu.cn/image-20250529164641271.png)

最后通过 ide 或者前面的命令行，指定本地 engine 运行，就可以体验到目前最新的 Flutter 多窗口支持了，目前 windows 下 demo 的体验还过得去：

![](https://img.cdn.guoshuyu.cn/ezgif-2af5c58e96f9c7.gif)

至于 **macOS** ，你依然需要一个优秀的处理器和足够的磁盘空间，流程类似，但是不同在于：

- 如果你是 M 系列芯片，需要执行的是 `./flutter/tools/gn --unoptimized --mac-cpu=arm64` ，如果你是 intel 芯片，那么就和 windows 一样
- M 系列芯片需要执行的编译是 `ninja -C out/host_debug_unopt_arm64` ![](https://img.cdn.guoshuyu.cn/image-20250529172235189.png)
- M 系列芯片运行的时候是： `flutter run -d macos  --local-engine /Users/XXXX/workspace/mmflutter/engine/src/out/host_debug_unopt_arm64 --local-engine-host /Users/XXXX/workspace/mmflutter/engine/src/out/host_debug_unopt_arm64 --local-engine-src-path /Users/guoshuyu/workspace/mmflutter/engine/src/` ，主要是指向了  host_debug_unopt_arm64 

> 另外需要注意，同样是如果提示 dart sdk 版本问题，那么 M 系列芯片需要复制的 dart-sdk 是来自 `host_debug_unopt_arm64`  下的 dart-sdk，也就是之后你的 flutter doctor 提示不是 darwin-arm64 (Rosetta) ，而是 darwin-arm64 才对，不然 run 的时候会遇到  Unable to find a device matching 问题

最后在 macOS 上运行起来的效果如下所示，可以看到还是存在一点闪烁问题（因为debug），整体体验逊色于 windows：

![ezgif-859890bc651c77](https://img.cdn.guoshuyu.cn/ezgif-859890bc651c77.gif)

> 至于为什么 linux 会是最迟？想想 Canonical 自家的 Ubuntu  UI 系统也许就可以理解了·····

# 最后

目前体验下来，多窗口的基础能力还行，当然之前说的 Dialogs 、Satellites 、Popup 等场景都还在调整，设计的各种底层改动不少，所以完全落地应该还需要点时间。

另外，关于开头的问题，基于 JVM 和 Swing 的 Compose Multiplatform 站在了巨人的肩膀上，它在多窗口支持有着天然优势，而 Flutter 需要自己从零开始，并且还需要重构自己原本的单视图模型，所以在多窗口上属于「步履维艰」，一个改不好，可能就把原有功能改崩了也说不定，只不过现在这口锅是 Ubuntu 的 Canonical 在接手。

# 参考资料



- https://www.jetbrains.com/help/kotlin-multiplatform-dev/compose-desktop-top-level-windows-management.html
- https://github.com/flutter/flutter/pull/167393/
- https://github.com/flutter/flutter/issues/142845



