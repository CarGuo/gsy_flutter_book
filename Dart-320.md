# Dart 3.2 更新，Flutter Web 的未来越来越明朗

> 参考原文：https://medium.com/dartlang/dart-3-2-c8de8fe1b91f

本次跟随 [Flutter 3.16 发布](https://juejin.cn/post/7301574930869321779) 的 Dart 3.2 ，包含有：私有 final 字段的非空改进、新的 interop 改进、对 DevTools 中的扩展支持、以及对 Web 路线图的更新，包括对 Wasm 的Web 组件支持。

> 最重要的就是 Wasm 的Web 组件支持。

# private final 的非空类型提升

自 Dart 2.12 发布  sound null safety 以来，类型提升一直是空安全的核心部分之一，但仅限于局部变量里，字段和顶级变量无法处理，例如在这样的情况下会报错：

```dart
class Container {
  final int? _fillLevel;
  Container(this._fillLevel);
  check() {
    if (_fillLevel != null) {
      int i = _fillLevel; // Prior to Dart 3.2, causes an error.
    }
  }
}
```

这种限制是由于几个复杂的情况造成的，在这些情况下，flow analysis 无法确定字段何时会发生什么变化，例如，在字段提升的情况下，如果子类使用 getter 覆盖字段（有时会返回 null），这就可能会出现问题。

> 在 Dart 3.2 开始，Dart 改进了 flow analysis ，现在能够归类出 **private Final fields**。

现在 3.2 里上面的代码片段可以顺利通过检测：对于 private & final 的字段，它的值在初始分配后永远不会改变，因此仅检查一次就被认为是安全的。

# 包中的新代码分析选项：lints 3.0

3.2 还对 [package:lints](https://pub.dev/packages/lints) 中的标准代码分析规则进行了一些改进，package 包含了默认和推荐的静态分析规则集，这些规则随 `dart create` 或 `flutter create` 创建的新项目一起提供 （通过 [package:flutter_lints](https://pub.dev/packages/flutter_lints) ）。

该 lint 集的主要版本（3.0）目前已经发布，其中向核心集添加了 6 个 lint，向推荐集添加了 2 个 lint，它具有用于验证 pubspec URL、验证是否使用正确参数调用集合方法等相关的 lints 。

> 有关更改的完整列表，请查看 https://github.com/dart-lang/lints/blob/main/CHANGELOG.md#300, 3.0 版本将成为即将发布的新项目的默认版本。

# Dart  interop 更新

目前正在努力扩展 Dart  interop 以全面支持与 [Java 和 Kotlin](https://dart.dev/guides/libraries/java-interop)  和 [Objective C 和 Swift](https://dart.dev/guides/libraries/objective-c-interop) 的直接调用支持，从 Dart 3.2 开始进行了许多改进：

- 引入了 C FFI 的构造函数 `NativeCallable.isolateLocal` ，它可以从任意 Dart 函数创建一个 C 函数指针，这是 `Pointer.fromFunction` 提供的功能的扩展，它只能从顶级函数创建函数指针。

- 更新了 Objective-C  利用`NativeCallable.listener` 绑定生成器，生成器现在可以自动处理包含异步回调的 API，例如 [Core Motion](https://developer.apple.com/documentation/coremotion) 这种以前需要手动绑定的代码。

- 改进 [package:jnigen](https://dart.dev/guides/libraries/java-interop) 实现 Java 和 Kotlin 的直接调用支持，现在我们能够将 [package:cronet_http](https://pub.dev/packages/cronet_http)（Android Cronet HTTP 客户端的包装器）从手写绑定代码迁移到[自动生成的](https://github.com/dart-lang/http/blob/master/pkgs/cronet_http/jnigen.yaml)包装器。

- 在 [Native Assets](https://github.com/dart-lang/sdk/issues/50565) 功能上取得了重大进展，该功能旨在解决与依赖于 Native 代码的 Dart 包分发相关的许多问题，它通过提供统一的钩子来与构建 Flutter 和独立 Dart 应用所涉及的各种构建需要，详细可见 ：http://dart.dev/guides/libraries/c-interop#native-assets 

  > Native Assets 目前是一个**实验性的**功能，它可以让 Dart 包更无缝依赖和使用 Native 代码，通过  `flutter run`/`flutter build ` 和 `dart run`/`dart build`  构建并捆绑 Native 代码 。
  >
  > 备注：可通过 `flutter config --enable-native-assets` 和 `flutter create --template=package_ffi [package name]` 启用。

  ![](http://img.cdn.guoshuyu.cn/20231116_Dart32/image1.png)

  Demo  [`native_add_library`](https://github.com/dart-lang/native/tree/main/pkgs/native_assets_cli/example/native_add_library)  展示了相关使用，当  Flutter 项目依赖  `package:native_add_library` 时， 脚本会自动在 `build.dart` 命令上调用：

  ```dart
  import 'package:native_add_library/native_add_library.dart';
  
  void main() {
    print('Invoking a native function to calculate 1 + 2.');
    final result = add(1, 2);
    print('Invocation success: 1 + 2 = $result.');
  }
  ```



# Dart 包的 DevTools 扩展

在 Dart 3.2 和 Flutter 3.16 中发布了一个新的[扩展框架](https://pub.dev/packages/devtools_extensions)，该框架让包作者能够为它的 package 构建自定义工具，并直接在 DevTools 中显示。

它允许包含框架的 pub.dev 包提供特定用例的自定义工具，例如 [Serverpod](https://pub.dev/packages/serverpod) 的作者一直在努力为它的 package 构建开发人员工具，并且很高兴在即将发布的 [1.2 版本](https://github.com/orgs/serverpod/projects/4) 中提供 DevTools 扩展。

![](http://img.cdn.guoshuyu.cn/20231116_Dart32/image2.png)

# Dart Web 和 Wasm 更新

从 Chrome 119 开始，Chrome 会默认启用 [Wasm 垃圾收集支持（称为 Wasm-GC）](https://developer.chrome.com/blog/wasmgc/) ，Wasm-GC 支持也出现在 Firefox 120（他们的下一个稳定版本）中被支持，那么 Dart、Flutter 和 Wasm-GC 的现状如何？

Dart-to-Wasm 编译器的功能几乎已经完全实现，团队对性能和兼容性非常满意，现在的重点是边缘情况，以确保在广泛的场景中能同样完美运行。

对于 Flutter Web，这里类似于完成了一个全新的 “Skwasm” 渲染引擎。为了最大限度地提高性能，Skwasm 通过 wasm-to-wasm 绑定将编译后的应用代码，直接连接到自定义 [CanvasKit Wasm 模块](https://skia.org/docs/user/modules/canvaskit/) ，这也是 Flutter Web 多线程渲染支持的第一次迭代，进一步提高了帧时间。

在 Wasm 的 Flutter web 准备脱离当前的实验状态之前，还有一些事情要做：

- **双编译**：生成 Wasm 和 JavaScript 输出，并在运行时启用功能检测，以支持支持和不支持 Wasm-GC 的浏览器。
- **JavaScript interop**：一种基于[扩展类型](https://github.com/dart-lang/language/issues/2727)的新 JS 互操作机制，当针对 JavaScript 和 Wasm 时，可以在 Dart 代码、浏览器 API 和 JS 库之间进行简洁、类型安全的调用。
- **支持 Wasm 的浏览器 API**：一个新的 `package:web`，基于现代 JS 互操作机制，取代了 dart:html （和相关库），这将提供对浏览器 API 的更轻松访问，并支持 JS 和 Wasm 目标。

目前已经开始将一些内部项目迁移到 `package:web` 和新的 JS 互操作机制，并期望在下一个稳定版本中有更多更新。

> 可以在 https://flutter.dev/wasm 了解更多。



# 最后

本次更新最重要有两个点，第一就是 Dart  interop 越来越成熟，相信以后直接通过 flutter run 就可以完成所有 interop 的绑定和编译，第二就是 Web 路线随着 Dart  Wasm 支持的进展，越来越值得期待了。