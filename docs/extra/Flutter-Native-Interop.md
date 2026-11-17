---
title: "Flutter Native Interop 稳定了，Platform Channel 要退场了"
---

# Flutter Native Interop 稳定了，Platform Channel 要退场了

Flutter 3.50 发布之后，Flutter Native Interop  也正是 stable 了，那接下来就是 Platform Channel 要直接退休了，感觉也就再过两个版本应该就差不都了，目前的情况大概是：

- **FFIgen 的 Objective-C 绑定和 JNIgen 的 Java/Kotlin 绑定正式稳定**，Dart 可以通过 FFI/JNI 直接调用原生 API
- **Pigeon 已把这两个工具接到代码生成流程里，30.0+ 会继续完善多 Engine 注册**，原来的跨端接口定义还可以继续用，但执行时不需要一定走 MethodChannel 的消息往返

之前 Dart 调一个原生方法，比如读取 Android 的系统配置，哪怕只需要返回一个整数，都要先把参数通过 Codec 编码，异步走 BinaryMessenger，原生侧收到消息、解码、执行方法，再把结果反向编码传回来。

虽然 Pigeon 能帮插件生成两边的类型安全接口，但是 Platform Channel 不管是性能上限还是操作都很麻烦，特别数据一大还经常容易卡死：

![](/article-assets/7ce4a0f961fdffc7d31f1489.webp)

**现在调用可以直接走 JNI 或 FFI，至少可以少掉消息派发和整包编解码，也能提供同步调用**，而且适配原生平台的 API 也方便也很多。

> 现在 FFIgen 可以根据 C/Objective-C 头文件生成 Dart 绑定，JNIgen 会根据 Java/Kotlin 的类、JAR 或 AAR 生成绑定，其实如果项目只在 Android 用某个系统服务，或者直接封装一个 C ABI 的库，你甚至都不需要 Pigeon，直接 dart 调用平台 API 就完事了。

不过 iOS 这边还是有点不爽，**FFIgen 还是不支持任意 Swift API 都能直接解析**，要先让 Swift 接口暴露 Objective-C 兼容入口，再通过生成的头文件调用，这个还是应该多学学 Kotlin。

而 Pigeon 其实是反过来做：先用一份 Dart 声明约定跨端 API，再生成 Dart 和 Swift/Kotlin 接口，原生平台的实际功能开发者自己实现，原本的 Channel 中间这层通信换成了 FFI/JNI。

![](/article-assets/c5c1d15b418a065e8d3c1327.webp)

同一份 Pigeon 定义还可以同时生成两套后端：Android、iOS、macOS 用 FFI/JNI，Windows 和 Linux 继续走 Platform Channel，不需要把业务接口拆成两份。

> 不过 FFI 本来就支持 C 接口了，其实也没必要。

**另外新模式比较实用的地方是同步调用和后台 Isolate**，以前从后台 Isolate 用 Platform Channel，需要处理 `BackgroundIsolateBinaryMessenger`，**现在 Pigeon Native Interop 的 Host API 可以直接从 Isolate 调用，也不用先拿到 RootIsolateToken**。

**不过调用会在发起调用的线程执行**，也就是 `@TaskQueue` 在这个模式下也不支持，所以如果 Dart 主 Isolate 里同步调用耗时的 JNI 方法，还是可能直接卡帧，后台 Isolate 调到需要操作 Android `Activity`、iOS UIKit 的接口的时候，原生实现也需要自己切回平台主线程，不过问题不大，整体性能绝对是提升的。

**所以，是时候让你项目里的 Channel 退休了**。
