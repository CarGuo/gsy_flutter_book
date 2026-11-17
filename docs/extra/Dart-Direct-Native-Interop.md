---
title: "Flutter 可以更直接地调用原生 API 了，Dart Direct Native Interop"
---

# Flutter 可以更直接地调用原生 API 了，Dart Direct Native Interop

最近刚好有网友聊这个，就展开聊聊吧，严格来说，`Direct Native Interop`  确实不算是最近更新的， 整个时间线大概类似：

- 2024 年：Dart 3.5 开始在完善 C、Java、Kotlin、Objective-C 的直接互操作能力
- 2025 年 5 月：Dart 3.8 正式宣布 FFIgen、JNIgen 的 Direct Native Interop 早期体验计划
- 2026 年：官方文档已经把 C、Java、Objective-C/Swift 和 JavaScript 的互操作方式整合到 [dart.dev/interop](https://dart.dev/interop?utm_source=chatgpt.com)，同时开始持续完善相关工具链

![](/article-assets/daf7e39eddcb1d8ff22d3253.webp)

当然这两年确实变化很多，比如：

- 调用路径变了：Dart 可以绕开传统 Platform Channel 的消息传递流程，直接通过 FFI/JNI 调用原生方法
- 代码生成方式变了：FFIgen 和 JNIgen 可以根据原生接口生成 Dart Binding，开发者不需要自己维护 Kotlin、Swift 桥接代码的工作
- Flutter 的线程架构也配合做了调整：UI 线程和 Platform 线程的合并，整个聊过很多次了

特别是 2026 年多了一个 Pigeon 29，这个版本正式加入了实验性的 FFI/JNI Direct Native Interop 支持，**也就是 Native Interop 调用系统的实现应该差不多要规模化落地了**。

> 也就是：Dart - 生成的 Binding - JNI / FFI - Kotlin / Swift 这个双向路径以后会是主流。

你现在其实也可以在 Pigeon 配置里开启：

```dart
@ConfigurePigeon(
  PigeonOptions(
    kotlinOptions: KotlinOptions(useJni: true),
    swiftOptions: SwiftOptions(
      useFfi: true,
      ffiModuleName: 'Runner',
    ),
  ),
)
```

然后运行 `dart run pigeon`,工具就会进一步调用 `jnigen` / `ffigen`，生成对应的 Kotlin、Swift 桥接代码和 Dart Binding。

所以其实 Direct Native Interop 很早就有了，不过 9 月之后，已经开始进入  Pigeon。

| 对比                    | MethodChannel / 传统 Pigeon                    | Direct FFI / JNI                   |
| ----------------------- | ---------------------------------------------- | ---------------------------------- |
| 调用方式                | 发送消息，等待结果                             | 调用生成的原生绑定方法             |
| 编解码                  | StandardMessageCodec                           | 原生类型、对象引用及必要转换       |
| Flutter Engine 消息通道 | 经过                                           | 不经过                             |
| 同步调用                | Dart 侧异步等待                                | 支持同步调用                       |
| 线程                    | 通过消息机制调度                               | 在调用者所在 OS 线程执行           |
| 数据传递                | 编码、解码，可能多次复制                       | 减少复制，但不保证零拷贝           |
| 开发难度                | 低，生态成熟                                   | 绑定生成、生命周期、构建更复杂     |
| Pigeon 直连支持         | Android、iOS、macOS、Windows、Linux 的传统通道 | 目前为 Android、iOS、macOS，实验性 |

比如用了 JNIgen 后，就可以直接根据 Java 接口生成 Dart Binding，你就可以像下面这样，这段 Dart 调用会通过 JNI 直接走到  Java VM 执行：

```kotlin
import 'example.dart'; // JNIgen 生成的 Binding

void main() {
  print(Example.sum(17, 25)); // 42
}
```

而且 FFIgen 可以把 Objective-C API 直接变成 Dart API  ，比如用  `AVAudioPlayer` 做例子，FFIgen 读取 `AVAudioPlayer.h`，生成对应 Dart Binding 后，就可以这样操作原生对象：

```swift
final fileUrl = NSURL.fileURLWithPath(
  NSString('/path/to/audio.mp3'),
);

final player =
    AVAudioPlayer.alloc().initWithContentsOfURL(fileUrl);

player?.play();
```

不过 Swift 比 Objective-C 麻烦一些，因为 Dart FFI 面向 C ABI，所以目前还是需要通过 Objective-C 兼容接口衔接 Swift：

```objective-c
@objc public class SwiftClass: NSObject {
    @objc public func sayHello() -> String {
        return "Hello from Swift!"
    }
}
```

**另外 Dart 3.13 之前也聊过，现在加入了 `@RecordUse` 和 `package:record_use`，可以让原生 FFI Binding 参与 到 AOT 编译期间的可达性分析**。

以前 Dart 层的没有用包装函数可以被 Tree Shaking 删除，但 Native Library 需要整体打包，现在配合 Link Hook 和支持裁剪的原生工具链，就可以进一步剔除没有用到的 Native Symbol，从而优化产物大小。

> 这对依赖 SQLite、加密库、音视频库的插件也有意义，不过它需要相应的构建和链接配置，不是说升级 Dart 后任何原生库都会自动完成裁剪。

总体里说这个功能支持是非常不错的，就是拖的有点久了。
