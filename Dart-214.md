> 原文链接： https://medium.com/dartlang/announcing-dart-2-14-b48b9bb2fb67

Dart 2.14 的发布对 Apple Silicon 处理器提供了更好的支持，并新增了更多提升生产力的功能，例如通过代码样式分析捕获 lint 错误、更快的发布工具、更好的级联代码格式以及一些细小的语言特性更新。


## Dart SDK 对 Apple Silicon 支持

自从在 2020 年末 Apple 发布了新的 [Apple Silicon](https://support.apple.com/en-us/HT211814)  处理器以来， Dart SDK 一直致力于增加对该处理器上的 Native 执行支持。

现在从 Dart 2.14.1 正式增加了对 Apple Silicon 的支持，当 [下载](https://dart.dev/get-dart) MacOS 的 Dart SDK时，一定要选择 ARM64 选项，**这里需要额外注意， Flutter SDK 中的 Dart SDK 还没有绑定这一项改进**。

本次更新支持在 Apple Silicon 上运行 SDK/Dart VM 本身，以及对 `dart compile` 编译后的可执行文件在 Apple Silicon 上运行的支持，**由于 Dart 命令行工具使用原生 Apple Silicon ，因此它们的启动速度会快得多** 。

## Dart 和 Flutter 共享的标准 lint

开发人员通常会需要他们的代码遵循某种风格，其中许多规则不仅仅是风格偏好（如众所周知的制表符与空格的问题），还涵盖了可能导致错误或引入错误的编码风格。


比如 **Dart 风格指南要求对所有控制流结构使用花括号**，例如 `if-else` 语句，这可以防止经典的 [dangling else](https://en.wikipedia.org/wiki/Dangling_else) 问题，也就是在多个嵌套的 `if-else` 语句上会存在解释歧义。

![](http://img.cdn.guoshuyu.cn/20211223_Dart-214/image1)

另一个例子是类型推断，虽然在声明具有初始值的变量时使用类型推断没有问题，但**在[声明未初始化的变量](https://dart-lang.github.io/linter/lints/prefer_typing_uninitialized_variables.html) 时指定类型很重要，因为这可以确保类型安全**。

![](http://img.cdn.guoshuyu.cn/20211223_Dart-214/image2)

良好代码风格的通常是通过代码审查来维持，但是通过在编写代码时，运行静态分析来强制执行规则通常会更有效得多。

在 Dart 中，这种静态分析规则是高度[可配置的](https://dart.dev/guides/language/analysis-options)，Dart 提供了有[数百条样式规则](https://dart.dev/tools/linter-rules)（也称为*lints*），有了如此丰富的选项，选择启用这些的规则时，一开始可能会有些不知所措。

> 配置支持： https://dart.dev/guides/language/analysis-options
>
> lint 规则： https://dart.dev/tools/linter-rules

Dart 团队维护了一个 [Dart 风格指南](https://dart.dev/guides/language/effective-dart/style)，它描述了 Dart 团队认为编写和设计 Dart 代码的最佳方式。

> 风格指南: https://dart.dev/guides/language/effective-dart/style

许多开发人员以及 pub.dev 站点[评分](https://pub.dev/help/scoring)引擎都使用了一套叫 [Pedantic](https://github.com/google/pedantic) 的 lint 规则， Pedantic 起源于 Google 内部的 Dart 风格指南，由于历史原因它不同于一般的 Dart 风格指南，此外 Flutter 框架也从未使用过 Pedantic 的规则集，而是拥有自己的一套规范规则。

这听起来可能有点混乱，但是在本次的 2.14 发布中，Dart 团队很高兴地宣布**现在拥有一套全新的 lint 集合来实现代码样式指南**，并且 Dart 和 Flutter SDK 默认情况下将这些规则集用于新项目：

-   [`package:lints/core.yaml`](https://github.com/dart-lang/lints/blob/main/lib/core.yaml)： **所有 Dart 代码都应遵循的 Dart 风格指南中的主要规则，pub.dev 评分引擎已更新为 lints/core 而不是 Pedantic。**

-   `package:lints/recommended.yaml` ：核心规则之外加上推荐规则，建议将它用于所有通用 Dart 代码。

-   `package:flutter_lints/flutter.yaml`：核心和推荐之外的 Flutter 特定推荐规则，这个集合推荐用于所有 Flutter 代码。

如果你已经存在现有的 Dart 或者 Flutter项目，强烈建议升级到这些新规则集，从 pedantic 升级只需几步：https://github.com/dart-lang/lints#migrating-from-packagepedantic 。

## Dart 格式化程序和级联

Dart 2.14 对 Dart 格式化程序如何使用[级联](https://dart.dev/guides/language/language-tour#cascade-notation) 格式化代码进行了一些优化。

以前格式化程序在某些情况下出现一些令人困惑的格式，例如 `doIt()` 在这个例子中调用了什么？

```dart
var result = errorState ? foo : bad..doIt();
```

它看起来像是被 `bad` 调用 ，**但实际上级联适是用于整个 `?` 表达式上的**，因此级联是在该表达式的结果上调用的，而不仅仅是在 false 子句上，新的格式化程序清晰地描述了这一点：

```dart
 var result = errorState ? foo : bad\
..doIt();
```


Dart 团队还大大提高了格式化包含级联的代码的速度；在[协议缓冲区](https://developers.google.com/protocol-buffers/docs/reference/dart-generated)生成的 Dart 代码中，可以看到格式化速度提高了 10 倍。

## Pub 支持忽略文件

目前当开发者将包[发布](https://dart.dev/tools/pub/publishing)到[pub.dev](https://pub.dev/)社区时，pub 会抓取该文件夹中的所有文件，但是会跳过隐藏文件（以 . 开头的文件）和`.gitignore` 文件。

Dart 2.14 中更新的 pub 命令支持新 `.pubignore` 文件，开发者可以在其中列出不想上传到 pub.dev 的文件，此文件使用与 `.gitignore` 文件相同的格式。

> 有关详细信息，请参阅包发布文档 https://dart.dev/tools/pub/publishing#what-files-are-published 

## Pub and "dart test" 性能

虽然 pub 最常用于管理代码依赖项，但它还有第二个重要的用途：驱动工具。

比如 Dart 测试工具通过 `dart test` 命令运行，而它实际上只是 `command pub run test:test` 命令的包装， `package:test` 在调用该 `test` 入口点之前，pub 首先将其编译为可以更快运行的本机代码。

在 Dart 2.14 之前对 pubspec 的任何更改（包括与 `package:test` 无关的更改）都会使此测试构建无效，并且还会看到一堆这样的输出，其中包含“预编译可执行文件”：

```
$ dart test\
Precompiling executable... (11.6s)\
Precompiled test:test.\
00:01 +1: All tests passed!
```

在 Dart 2.14 中，pub 在构建步骤方面更加智能，让构建仅在版本更改时发生，此外还使用并行化改进了执行构建步骤的方式，因此可以完成得更快。


## 新的语言功能

Dart 2.14 还包含一些语言特性变化。

首先添加了一个新的 [三重移位](https://github.com/dart-lang/language/issues/120) 运算符 ( `>>>`)，这类似于现有的移位运算符 ( `>>`)，但 `>>` 执行算术移位，`>>>` 执行逻辑或无符号移位，其中零位移入最高有效位，而不管被移位的数字是正数还是负数。

此次还删除了对类型参数的旧限制，该限制不允许使用泛型函数类型作为类型参数，以下所有内容在 2.14 之前都是无效的，但现在是允许的：

```dart
late List<T Function<T>(T)> idFunctions;
var callback = [<T>(T value) => value];
late S Function<S extends T Function<T>(T)>(S) f;
```

最后对注释类型进行了小幅调整，（诸如 `@Deprecated` 在 Dart 代码中常用来捕获元数据的注解）以前注解不能传递类型参数，因此 `@TypeHelper<int>(42, "The meaning")` 不允许使用诸如此类的代码，而现在此限制现已取消。

## 包和核心库更改

对核心 Dart 包和库进行了许多增强修改，包括：

-   `dart:core`： 添加了静态方法 `hash`、`hashAll` 和 `hashAllUnordered`。

-   `dart:core`： `DateTime` 类现在可以更好地处理本地时间。

-   `package:ffi`：添加了对使用 [arena](https://pub.dev/documentation/ffi/latest/ffi/Arena-class.html) 分配器管理内存的支持（[示例](https://github.com/dart-lang/sdk/blob/master/samples/ffi/resource_management/arena_sample.dart)）。Arenas 是一种[基于区域的内存管理](https://en.wikipedia.org/wiki/Region-based_memory_management)形式，一旦退出 arena/region 就会自动释放资源。

-   `package:ffigen`：现在支持从 C 类型定义生成 Dart 类型定义。


## 重大变化

Dart 2.14 还包含一些重大更改，预计这些变化只会影响一些特定的用例。

### [#46545](https://github.com/dart-lang/sdk/issues/46545)：取消对 ECMAScript5 的支持

[所有浏览器都](https://caniuse.com/es6)支持最新的 ECMAScript 版本，因此两年前 Dart 就[宣布](https://groups.google.com/a/dartlang.org/g/announce/c/x7eDinVT6fM/m/ZSFl2a9tEAAJ?pli=1) 计划弃用对 ECMAScript 5 (ES5) 的支持，这使 Dart 能够利用最新 ECMAScript 中的改进并生成更小的输出，**在 Dart 2.14 中，这项工作已经完成，Dart Web 编译器不再支持 ES5。因此不再支持较旧的浏览器（例如 IE11）**。

### [#46100](https://github.com/dart-lang/sdk/issues/46100)：弃用 stagehand、dartfmt 和 dart2native

在 2020 年 10 月的 [Dart 2.10 博客文章中](https://medium.com/dartlang/announcing-dart-2-10-350823952bd5) 宣布了将所有 Dart CLI 开发人员工具组合成一个单一的组合`dart`工具（类似于该`flutter`工具），而现在 Dart 2.14 弃用了 `dartfmt` 和 `dart2native` 命令，并停止使用 `stagehand` ，这些工具在统一在 `dart-tool` 中都有等价的替代品。

### [#45451](https://github.com/dart-lang/sdk/issues/45451)：弃用 VM Native 扩展

Dart SDK 已弃用 Dart VM 的 Native 扩展，这是从 Dart 代码调用 Native 代码的旧机制，Dart [FFI](https://dart.dev/guides/libraries/c-interop)（外来函数接口）是当前用于此用例的新机制，正在积极[发展](https://medium.com/dartlang/announcing-dart-2-13-c6d547b57067) 以使其功能更加强大且易于使用。