# Dart 3.5 发布，全新 Dart  Roadmap Update

紧随 [Flutter 3.24 的发布](https://juejin.cn/post/7399952146236571685) ，Dart 也迎来了 3.5 的迭代，虽然这个版本依然没有正式 release 宏编程，但是目前来说也有不错的进展。



# Web 平台与 JS 的相互调用

在  Dart 3.4   中开始，[Dart 支持编译为 WASM Native](https://juejin.cn/post/7368820207576383498) ，也就是 Flutter Web 应用可以编译为原生 WebAssembly ，而这需要新的 Dart 到 JS 上新的   interop 模型，而这个模型现在在 3.5 开始，它属于稳定版本状态。

从 3.5 开始，[package:web ](https://pub.dev/packages/web) 中的 browser API 绑定（替换旧`dart:html`库）更新为 1.0 版，同时也希望 Plugin 开发者可以升级迁移到 package:web ，**因为计划在下一个 Dart 版本中会弃用旧的 interop  API（dart:html、dart:js、package:js 等）**。



# Dart 原生交互

3.5 还对 Native 的 interop 进行了一系列改进，**现在全面支持`直接`从 Dart 调用 C、Java、Kotlin、Objective-C 和 Swift 等操作，而不通过 Method Channel**。

FFI 库一直以来都支持对 C 的相互调用，而在 Dart 3.5 开始，FFI 进行了渐进式改进，支持将指针通过  Dart `TypedData` 对象直接传递，避免必须先将内存从 Dart 复制到 Native，这也会大大加速使用 [upd](https://github.com/protocolbuffers/upb) 进行 protobuf 解析的速度。

```dart
Pointer<NativeFunction<Void Function(Pointer<Int8>)>> functionPointer;

final myFunction = functionPointer.asFunction<void Function(Uint8List)>(isLeaf: true);
// or
final myFunction = functionPointer.asFunction<void Function(ByteBuffer)>(isLeaf: true);
```

Java 和 Kotlin 直接互相调用的 [JNIgen 生成器](https://pub.dev/packages/jnigen) 也开始正式启用（目前为预览版），它可自动创建绑定代码，从而通过 Java 原生接口 ( [JNI](https://developer.android.com/training/articles/perf-jni) )  让Dart 调用到 Java 和 Kotlin。

这里主要是提高了性能，并增加了对 Java 异常和 Kotlin 顶级函数的支持，另外本次还停止了以前[基于 C 的绑定](https://github.com/dart-lang/native/issues/660)，并且更易于使用。

Objective-C  interop 建立在 [ FFI 和 FFIgen](https://pub.dev/packages/ffigen)生成器之上（目前为预览版），本次添加了对 Objective-C 协议和常见类型的支持如`NSString`，有关使用 FFIgen 构建的包的大型示例可以参考 [cupertino_http](https://github.com/dart-lang/http/tree/master/pkgs/cupertino_http)，它展示了 Dart 与 Apple 的 URL 网络库直接相互调用的过程。

未来还将进一步的优化 interop ——无论是在完成度方面，还是在支持 Swift 方面。

# Pub.dev package 存储库

Pub.dev 是 Dart 的 package 存储库，社区可以在这里共享和查找具有丰富功能的软件包。

本次针对 Pub 进行了许多改进，首先改进了对 [**topics **](https://dart.dev/tools/pub/pubspec#topics)的支持：package 作者可以使用其所属类别（例如 Widget）标记其软件包的机制。

> 现在 Pub [整合了](https://github.com/dart-lang/pub-dev/blob/master/doc/topics.yaml) 涵盖同一类别但在措辞上略有差异的常见主题（例如 widgets 与 widget）。

其次还添加了一个新 `pub unpack` 命令，这提供了一种快速简便的方法将包下载到本地，例如想在本地运行包的示例 Demo，可以使用命令：

```
$ dart pub unpack path
Downloading path 1.9.0 to `./path-1.9.0`...

$ cd path-1.9.0/example/

$ dart run example.dart
Current path style: posix
Current process path: /Users/mit/tmp/path-1.9.0/example
```

第三还添加了一个新 `pub downgrade --tighten` 命令，该命令可用于检查包依赖项中的所有版本约束，运行时，它会将较低的约束更新为 pub 能够解决的最低版本。

# Roadmap 更新

## monorepo

“monorepo”  是一种在单个存储库中构建一组相关软件包和应用源代码的常用方法，monorepo 不仅方便将所有源代码“紧密放在一起”，而且还是确保存储库中各个软件包和应用相互兼容的重要工具。

目前我们的 tools（特别是 analyzer ）的性能可能不足，而根本问题是最终为每个包及其所有依赖项加载了多个重叠的 analysis contexts ，预计将在下一个 Dart 版本中解决并分享更多的内容，目前它已经在 Flutter Engine 上被应用 ：https://github.com/flutter/engine/pull/54157/files

## Pub.dev 

pub.dev  的用户长期以来一直要求改进每个 Package 的[使用/下载情况](https://github.com/dart-lang/pub-dev/issues/2714)的指标，这可以帮助作者了解有多少用户从他们的工作中受益，也有助于使用者了解其他开发人员正在使用哪些软件包。

本次可以很高兴地告诉大家，目前在这项功能方面取得了良好的进展，并有望在年底前推出预览版。

## Dart interop

对于 Java/ Kotlin 与 JNIgen 的 interop，预计将在未来两个季度内完成核心支持，并从实验版本升级到稳定版本 1.0：https://github.com/orgs/dart-lang/projects/69/

对于 ObjectiveC 互操作，也有一个类似的目标：https://github.com/orgs/dart-lang/projects/87

接下来将进一步研究 Dart 与 Swift 代码的 interop，初步实验看起来很有希望，预计明年年初能增加实验支持。

## Native interop 和捆绑  native 源码

在许多情况下，interop 作用于调用操作系统中存在的 API，这意味着这些 API 在这些 Native 平台上始终可用。

但是在某些情况下，Dart interop 的代码是没有直接包含在主机上的本机源代码，这对使用这些 interop 的 package 作者来说，如何捆绑和构建 native 源代码是一个实际挑战。

为了支持这一点，目前 Dart 正在探索一个  [native assets system](https://github.com/dart-lang/sdk/issues/50565),，它可以支持发布包含本机源代码的 Dart  package，以及一个标准化协议，用于启用 `dart` 和 `flutter` CLI 工具来自动构建和捆绑该源代码。 

目前设想这将启用一组新的 interop 用例，同时为使用依赖 native 源代码的 package 的开发人员提供简单的用户体验。

## macros 宏

目前，Dart 语言和编译器团队的大部分时间都花在了宏的开发上，在之前的 [Dart 3.4 ](https://juejin.cn/post/7368820207576383498)中就介绍了这些宏，正如当时的情况，这对于Dart 是一项艰巨的任务，可能会导致一些核心用例（如热重载）出现倒退，因此未来还需要采取更多手段来完成落地。

除了宏之外，目前还在同时探索一些其他较小的语言特性，如 [Dart funnel ](https://github.com/orgs/dart-lang/projects/90/views/1)中的：

- [Static extension methods](https://github.com/dart-lang/language/issues/723)
- [Wildcard variables](https://github.com/dart-lang/language/issues/3712)
- [Static Metaprogramming](https://github.com/dart-lang/language/issues/1482)
- [Primary constructor on classes](https://github.com/dart-lang/language/issues/2364)

目前 Dart 团队一直在重写 Dart formatter ，旧的设计多年来一直运行良好，但随着 Flutter 的成功， Dart team 希望转向一种[新的风格](https://github.com/dart-lang/dart_style/issues/1253)，以更好地适应 Flutter 用户经常编写的声明式代码，而重写即将完成，并将很快发布。

> 更多可见：https://github.com/dart-lang/dart_style/issues