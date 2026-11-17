---
title: "Flutter GSoC 2026 提案进度解读，补上 DevTools、FFI 和原生平台的关键缺口"
---

# Flutter GSoC 2026 提案进度解读，补上 DevTools、FFI 和原生平台的关键缺口

今年的  Google Summer of Code 2026 关于 Flutter 的结果终于出来了，官方收到接近 100 份项目提案，这次重点介绍了 5 个项目：WebSocket 网络调试、C++ FFI、IntelliJ 插件通信、Android 加密后端和 Dart FFI 的原生内存调试支持。

![](/article-assets/dfbd623d90891bd715e8121a.webp)

虽然这五点看起来貌似有些分散，不过放在一起其实有个很明显的共同点：**它们都在处理 Dart 与外部世界连接时留下的工程缺口，这对 AI 场景也很重要**：

- WebSocket 是应用和服务端之间的边界
- FFIgen 和 `dart:ffi` 是 Dart 与 C/C++ 之间的边界
- JCA 是 Flutter 与 Android 系统能力之间的边界
- IntelliJ 插件连接的是 IDE 与 Dart VMDart Tooling Daemon 之间的边界

先总结一下，大概类似：

| 项目                      | 核心问题                                | GSoC 结束时的状态                                           |
| :------------------------ | :-------------------------------------- | :---------------------------------------------------------- |
| DevTools WebSocket / gRPC | Network 面板缺少完整 WebSocket 可观测性 | WebSocket 已经完成合入，gRPC 留作后续                       |
| FFIgen C++                | C++ 类需要大量手写 C glue code          | 类、继承、所有权等基础能力已合入，暂时还属于实验性 C++ 支持 |
| IntelliJ WebSocket        | Dart/Flutter 插件依赖老旧 Weberknecht   | 迁移完成，改用 JDK WebSocket                                |
| Android JCA webcrypto     | Android App 额外携带 BoringSSL          | 大部分算法完成，生产集成还有后续工作                        |
| DevTools native memory    | `Pointer<T>` 基本只能看到地址           | 安全读取、typed value、raw bytes 主体已经合入               |

## WebSocket 和 native memory

**实际上这次最有用的两个“盲区”就是 WebSocket 和 native memory**，以前 Flutter DevTools 的 Network 面板主要围绕 HTTP 请求组织，虽然 HTTP 很适合「一次 Request 对应一次 Response」的展示方式，但是 WebSocket 的一条连接可能存在几分钟甚至几个小时，中间持续双向交换 frame。

这时候以前 DevTools 虽然可以看到最开始的连接，但是对于类似下面这种问题会很不友好，比如：

- 现在到底有没有继续收消息
- 谁先断了
- 发送和接收了多少数据
- 哪一帧出现了错误

**所以这次把 WebSocket profiling 一直做到 `dart:io` 里面，实现沿用了原有 HTTP profiling 的基础设施，扩展 `HttpClient.enableTimelineLogging`，现在开启现有网络 profiling 时，WebSocket 的 Connect、Send、Receive、Ping、Pong、Close 和 Error 等事件也会进入采集链路**。

随后增加 `WebSocketProfiler`，按照 connection ID 长期维护一条连接的状态，再通过 VM Service 暴露给 DevTools：

![Flutter DevTools Network 面板中的 WebSocket](/article-assets/75fd64a424e72bfd3bab31e4.webp)

> 比如 HTTP 与 WebSocket 已经出现在同一个 Network 列表中，WebSocket 会保持 open / Pending 状态。

另外 DevTools 也没有另外搞一个孤立的 WebSocket 工具，现在的 WebSocket connection 是接进了现有 Network 模型，这样搜索、过滤、selection、polling 和离线数据等能力都可以直接复用，选中 WebSocket 之后再进入专门的 Overview 和 Frames 两个视图。

![WebSocket Overview](/article-assets/56814aa1744878919d9e5def.webp)

> Overview 可以看到连接状态、收发字节、frame 数量、Ping/Pong、开始时间和结束时间。

![WebSocket Frames](/article-assets/f60340816810158c954e934c.webp)

> Frames 按时间列出 Connect、Open、Send、Receive，同时显示方向、opcode 与 payload 大小。

对做实时业务的场景来哦说，这个变化可以说是非常直接了，比如 IM、实时行情、IoT 控制、AI streaming、在线协作之类的场景，以前经常要在业务层自己打印 WebSocket 生命周期和消息日志，现在 DevTools 就能够运行时层面观察这些信息。

**然后同一届另外一个 DevTools 项目处理的是 FFI debugging**，以前在断点里展开一个 `Pointer<Int16>`、`Pointer<MyStruct>` 经常看到的只有地址、`hashCode` 和 `Pointer<Never>` 等信息，真正指向的数值根本看不到：

![Pointer inspection before](/article-assets/db81a0cb9d1855c1905d52dc.webp)

修改后现在可以直接显示 typed value、raw bytes，无效地址返回 I/O error：

![Pointer inspection after](/article-assets/fc0dfa96b8d84cd2416eb106.webp)

> 不过这里真正困难的是安全性问题，比如 Debugger 如果直接解引用一个已经释放或无效的地址，可能就会触发 segmentation fault。

最终 Dart VM 选择增加了安全 native memory 读取能力：

- Linux 和 Android 用 `pread64(/proc/self/mem)`
- Windows 使用 `ReadProcessMemory`
- macOS 和 iOS 用 `mach_vm_read_overwrite`

之后 DAP 再根据 `Pointer<T>` 的静态类型解释读取到的字节，所以调试器目前大概率能安全显示 typed value 和 raw bytes。

## FFIgen

FFIgen 以前最舒服的工作对象一直是 C API，因为 Dart FFI 本身就是围绕 C ABI 设计的，但是如果 C++ 一旦加入 class、constructor、destructor、inheritance、method、smart pointer 和 ownership，内容就会复杂很多，因为 Dart FFI 本身也不知道一个 C++ 对象应该怎样构造，也不知道什么时候应该执行 `delete`。

所以之前接入 C++ SDK 的时候，Flutter plugin 经常需要人工先写一层 C wrapper，比如：

> 一个有构造函数、析构函数和成员方法的 `Animal` 类，要先人为转成 `Animal_new()`、`Animal_getAge()`、`Animal_delete()` 这类 C-compatible function，FFIgen 才能继续生成 Dart binding。

```c++
class Animal {
public:
  int age;
  Animal(int age);
  ~Animal();
  void speak();
  int getAge() const;
  static int getCount();
};
```

这次工作的方向，就是让 FFIgen 自己理解部分 C++ class，再自动生成这层 glue code，这里比较棘手的部分是 ownership。

- 如果 C++ 返回 `Animal*`，谁拥有这个对象？
- Dart wrapper 被 GC 后需不需要 delete？
- 如果返回的是 `std::unique_ptr<Node>`，所有权什么时候发生转移？

这些地方处理错一次就可能造成 memory leak 或者  double free。，项目也因为这个加入了 `NativeFinalizer`，同时增加了 `retainOwnership()` / `releaseOwnership()`，同时还处理了如 class pointer、smart pointer 和 inheritance。

> 目前的实现已经覆盖 public inheritance，包括 single inheritance、multiple inheritance 和 diamond inheritance，在 GSoC 期间大量相关 PR 已经进入代码库，不过 STL type bridging、templates、namespaces 和更完整的端到端验证还没完全完成。

## 三、IntelliJ WebSocket 和 Android JCA

IntelliJ 那个项目解决的是 Flutter 日常开发工具链里一段存在多年的历史依赖。

Dart 和 Flutter IntelliJ 插件过去依靠 Weberknecht WebSocket library 和 Dart VM Service/Dart Tooling Daemon 通信，这个库版本其实很老了，而且已经基本停止维护。

所以这次迁移把底层替换成 Java 11 之后自带的 `java.net.http.WebSocket`，同时保留插件自己的 transport wrapper 来处理 Ping/Pong、fragment 重组、serialized send、连接生命周期和错误：

![](/article-assets/d7c76e42373492d0af8a631c.webp)

**另外 Android JCA 的修改就更底层了，`package:webcrypto`  在 Android 上目前会随 App 额外携带一份 BoringSSL native library，然后通过 Dart FFI 调用**。

> GSoC 项目尝试利用 Android 已经存在的 Java Cryptography Architecture，通过 `package:jni` 调用系统 cryptography provider，从而有机会减少 APK 中额外携带的 native cryptography code。

## 最后

实际上这次 GSoC 补的能力都挺实用的，特别是 AI 时代下，这些能力都是对稳定性和可观察性做了很不错的补充，也是对 Flutter 项目做工程化的补充，虽然有些能力还没完全走完，但是大部分都基础都弄完了，估计下个版本应该都可以看到。
