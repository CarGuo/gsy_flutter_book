# Dart 2.17 正式发布

随着 [Flutter 3](https://link.juejin.cn/?target=https%3A%2F%2Fmp.weixin.qq.com%2Fs%2FUZJX0HIi7ERW_ZNcz1hflg) 在本次 I/O 大会的发布，我们也同时正式发布了 Dart 2.17 稳定版 SDK。这个版本的发布是围绕着我们的核心主题构建的，即：领先的生产力和平台可移植性。

Dart 2.17 提供了新的语言特性：**枚举支持成员变量、改进的超类参数继承，以及更为灵活的命名参数**。我们同时为 `package:lints` 开启了 2.x 版本，这是一套官方的 lint 规则，是根据我们总结的 Dart 最佳实践整合而成的一个 lint 规则集。与此同时，我们也更新了核心库的 API 文档，为其带来了丰富的示例代码。并且，为了改善平台集成特性，我们在 Flutter 插件中提供了一个新的模版，使用 `dart:ffi` 与原生平台进行 C 语言的互操作、对 RISC-V 指令集提供实验性支持，以及对 macOS 和 Windows 可执行文件的签名支持。

![img](http://img.cdn.guoshuyu.cn/20220627_Dart-217/image1)

## 编程语言新特性助力生产力提升

我们一直在持续地改进 Dart 编程语言，不断添加新特性以及改进现有的特性，以助力开发者们工作效率的提升。Dart 2.17 增加了对枚举成员变量的支持，优化了在构造函数中使用命名参数的方式，并且开始使用继承超类的参数以减少冗长和重复的代码。

### 增强的支持成员变量的枚举

枚举非常适合表示一组离散的状态。例如，我们可以将水描述为 `enum Water { frozen, lukewarm, boiling }`。但如果我们想在 `enum` 上添加一些方法，例如，将每个状态转换为温度，并支持将 `enum` 转换为 `String`，该怎么办？或许我们可以使用扩展方法来添加一个 `waterToTemp()` 方法，但我们必须时刻注意它与 `enum` 的同步。对于 `String` 我们希望覆写 `toString()` 方法，但它不支持这么做。

在 Dart 2.17 中现已支持枚举类型的成员变量。这意味着我们可以添加保存状态的字段、设置状态的构造函数、具有功能的方法，甚至覆写现有的方法。社区中许多开发者一直有这样的需求，这是我们在 Dart 编程语言仓库的问题追踪中 [投票排名第三的问题](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fdart-lang%2Flanguage%2Fissues%3Fq%3Dis%3Aissue%2Bsort%3Areactions-%2B1-desc%2B)。

继续拿 `Water` 举例，我们可以添加一个保存温度的 `int` 字段，并添加接收 `int` 的默认构造函数：

```dart
enum Water 
  const Water(this.tempInFahrenheit);

  final int tempInFahrenheit;
}
```

为了确保在创建枚举时构造函数被正常调用，我们需要为每一个枚举值附以显式的调用：

```dart
enum Water {
  frozen(32),
  lukewarm(100),
  boiling(212);
}
```

想要支持从枚举转换为 `String`，我们可以很简单地覆写 `toString` 方法，因为 `enums` 也继承自 `Object`：

```dart
@override
String toString() => "The $name water is $tempInFahrenheit F.";
```

如此一来，你就有了一个可以轻松实例化完整功能的枚举类，并且可以在任意位置调用方法：

```dart
void main() {
  print(Water.frozen); // 打印内容为 “The frozen water is 32 F.”
}
```

这两种方法的完整示例如下所示，有了这些改动，新版本的代码更易于阅读和维护。

![img](http://img.cdn.guoshuyu.cn/20220627_Dart-217/image2)

### 超类的初始化构造

当你的代码存在类型继承关系时，一个常见的做法是将一些构造函数参数传递给超类的构造函数。为此子类需要 1) 在其构造函数中列出每个参数 2) 使用这些参数调用超类的构造函数。这导致了大量的代码重复，使代码难以阅读和维护。

几位 Dart 社区成员帮助 Dart 实现了这项语言目标。半年前，GitHub 用户 [@roy-sianez](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Froy-sianez) 提交了一个 [语言问题](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fdart-lang%2Flanguage%2Fissues%2F1855)。他的建议类似于 GitHub 用户 [@apps-transround](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fapps-transround) 先前的 [建议](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fdart-lang%2Flanguage%2Fissues%2F493%23issuecomment-879624528)：也许我们可以通过引入一个新的方式来表示在超类中指定了一个参数，来解决这个问题。我们认为这是一个好主意，因此已将其实现并添加到了 Dart 2.17 版本中。从以下示例中可以看出，这与 Flutter widget 的代码有很强的相关性。实际上当我们将这项特性应用到 Flutter 框架时，我们看到框架总共减少了 [近两千行代码](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fflutter%2Fflutter%2Fpull%2F100905%2Ffiles)！

![img](http://img.cdn.guoshuyu.cn/20220627_Dart-217/image3)

### 可在任意参数位置使用命名参数

最后，我们改进了方法调用时命名参数的方式。在此次更新之前，命名参数的调用必须出现在普通参数列表的后面。当你想要提升代码可读性，希望将命名参数写在靠前的位置但它无法工作时，会觉得非常惆怅。例如下方 `List<T>.generate` 构造函数的调用。此次更新之前 `growable` 参数必须放在最后，这会导致这个参数很容易被可能有很多内容的构造参数所影响而错过。现在你可以根据自己的喜好对它们进行排序，你可以先使用命名参数，最后使用生成器参数。

![img](http://img.cdn.guoshuyu.cn/20220627_Dart-217/image4)

更多有关这三项改进的示例，请参阅我们更新的 [枚举](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fdart-lang%2Fsamples%2Fblob%2Fmaster%2Fenhanced_enums%2Flib%2Fmembers.dart)、[超类的初始化构造](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fdart-lang%2Fsamples%2Fblob%2Fmaster%2Fparameters%2Flib%2Fsuper_initalizer.dart) 和 [命名参数](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fdart-lang%2Fsamples%2Fblob%2Fmaster%2Fparameters%2Flib%2Fnamed_parameters.dart) 示例代码。

## 生产力工具改进

回到生产力的主题，我们围绕生产力对核心工具进行了一些改进。

在 Dart 2.14 中，我们引入了 `package:lints`，它与 Dart 分析器一起工作以防止你编写错误的代码，并使用更规范的规则审查你的 Dart 代码。之后分析器中又新增了许多代码提示规则，我们对其进行了仔细分类，并从中选择了 [10 条新的用于所有 Dart 代码的代码提示规则](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fdart-lang%2Flints%2Fblob%2Fmain%2FCHANGELOG.md%23200) ，以及 [2 条新的专门用于 Flutter 代码的代码提示规则](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fflutter%2Fpackages%2Fblob%2Fmaster%2Fpackages%2Fflutter_lints%2FCHANGELOG.md%23200)。它们包括确保你导入的 package 中有正确地在你 pubspec 文件中声明、防止滥用对类型参数的空检查以及确保子属性格式一致的代码提示规则。你可以简单地使用命令升级到新的 `lints` package：

- 对 Dart package 可以使用: `dart pub upgrade —-major-versions lints`
- 对 Flutter package 可以使用: `flutter pub upgrade —-major-versions flutter_lints`

`SecureSockets` 通常用于启用使用 TLS 和 SSL 保护的 TCP 套接字连接。在 Dart 2.17 之前，因为没有办法检查安全数据流量，在开发过程中调试这些加密连接变得十分棘手。现在我们添加了对指定 `keyLog` 文件的支持，指定后，当与服务器交换新的 TLS 密钥时，[NSS 密钥日志格式](https://link.juejin.cn/?target=https%3A%2F%2Ffirefox-source-docs.mozilla.org%2Fsecurity%2Fnss%2Flegacy%2Fkey_log_format%2Findex.html) 中的一行文本将附加到文件中。这将使网络流量分析工具 (例如 [Wireshark](https://link.juejin.cn/?target=https%3A%2F%2Fgitlab.com%2Fwireshark%2Fwireshark%2F-%2Fwikis%2FTLS%23tls-decryption)) 能够解密通过套接字发送的内容。更多详细信息，请参阅`SecureSocket.connect()` 的 [API 文档](https://link.juejin.cn/?target=https%3A%2F%2Fapi.dart.cn%2Fstable%2F2.17.0%2Fdart-io%2FSecureSocket%2Fconnect.html)。

`dart doc` 生成的 API 文档是大多数 Dart 开发者学习新 API 的重要内容之一。虽然我们的核心库 API长期以来都有丰富的文本描述，但许多开发者告诉我们，他们更喜欢通过阅读示例代码来学习 API。在 Dart 2.17 中，我们检查了所有主要的核心库，为浏览量排名的前 200 个页面添加了详实的示例代码。你可以对比 `dart:convert` 在 [Dart 2.16](https://link.juejin.cn/?target=https%3A%2F%2Fapi.dart.cn%2Fstable%2F2.16.2%2Fdart-convert%2Fdart-convert-library.html) 和 [2.17](https://link.juejin.cn/?target=https%3A%2F%2Fapi.dart.cn%2Fstable%2F2.17.0%2Fdart-convert%2Fdart-convert-library.html) 的文档页面查看这些改变，希望这些改变可以帮助你更好地使用 API 文档。

助力生产力的提高不仅是做加法，做减法也同样重要，我们清理了一些堆积的内容，并删除了 SDK 里已弃用的的 API，这将帮助我们保持更小的代码体积，这对新上手的开发者们尤为重要。为此，我们从 `dart:io` 库中删除了 [231 行已弃用的代码](https://link.juejin.cn/?target=https%3A%2F%2Fdart-review.googlesource.com%2Fc%2Fsdk%2F%2B%2F236840)。如果你仍在使用这些已弃用的 API，你可以使用 `dart fix` 进行修复和替换。我们还在继续努力删除 [已弃用的 Dart CLI 工具](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fdart-lang%2Fsdk%2Fissues%2F46100)，本次更新删除了 `dartdoc` 工具 (使用`dart doc` 代替) 和 `pub` 工具 (使用 `dart pub` 或 `flutter pub` 代替)。

## 扩大平台集成和支持

第二个核心主题是平台集成和支持。Dart 是一种真正的多平台语言。虽然我们已经支持 [大量的平台](https://link.juejin.cn/?target=https%3A%2F%2Fdart.cn%2Foverview%23platform)，但我们仍在不断拓展新平台，以确保你可以与每个受支持的平台深度集成，同时也关注更新兴的平台。

我们 [与 C 语言或原生代码互操作](https://link.juejin.cn/?target=https%3A%2F%2Fdart.cn%2Fguides%2Flibraries%2Fc-interop) 的核心机制——Dart FFI，是一种将 Dart 代码与现有原生平台代码集成的流行方式。在 Flutter 上，FFI 是构建使用宿主平台原生 API (例如 Windows win32 API) 插件的好方法。在 Dart 2.17 和 Flutter 3 中，我们向 `flutter` 工具添加了 FFI 的模板，现在你可以轻松地创建 FFI 插件，这些插件具有通过 `dart:ffi` 调用原生代码支持的 Dart API。详细信息请参阅开发者文档 [开发 package 和插件](https://link.juejin.cn/?target=https%3A%2F%2Fflutter.cn%2Fdocs%2Fdevelopment%2Fpackages-and-plugins%2Fdeveloping-packages%23dart-only-platform-implementations) 页面。

FFI 现在支持特定于 ABI 的类型，可以在具有特定 [ABI (应用程序二进制接口)](https://link.juejin.cn/?target=https%3A%2F%2Fbaike.baidu.com%2Fitem%2FABI%2F10912305) 类型的平台上使用 FFI。例如，现在你可以使用 `Long` (C 语言中的 `long`) 正确表示具有特定于 ABI 大小的长整数，由于 CPU 架构的区别，结果可能是 32 位或 64 位。有关支持类型的完整列表，请参阅 [AbiSpecificInteger API 页面](https://link.juejin.cn/?target=https%3A%2F%2Fapi.dart.cn%2Fstable%2F2.17.0%2Fdart-ffi%2FAbiSpecificInteger-class.html) 中的 "Implementers" 列表。

在使用 Dart FFI 与原生平台深度集成时，有时需要将 Dart 分配的内存或其他资源 (端口、文件等) 的清理行为与原生代码对齐。长期以来，这个问题都十分棘手，因为 Dart 是一种会自动处理垃圾回收清理行为的语言。在 Dart 2.17 中，我们通过引入 Finalizer 的概念解决了这个问题，它包括一个 `Finalizable` 标记接口，用于「标记」不应过早终结或丢弃的对象，以及一个 `NativeFinalizer` 可以附加到 Dart 对象上，当对象即将被垃圾回收时提供回调运行。Finalizer 让原生代码和 Dart 代码中同时运行清理。更多详细信息请参阅 [NativeFinalizer API 文档](https://link.juejin.cn/?target=https%3A%2F%2Fapi.dart.cn%2Fstable%2F2.17.0%2Fdart-ffi%2FNativeFinalizer-class.html) 中的描述和示例，或 [WeakReferences](https://link.juejin.cn/?target=https%3A%2F%2Fapi.dart.cn%2Fstable%2F2.17.0%2Fdart-core%2FWeakReference-class.html) 以及 [Finalizer](https://link.juejin.cn/?target=https%3A%2F%2Fapi.dart.cn%2Fstable%2F2.17.0%2Fdart-core%2FFinalizer-class.html) 在 Dart 代码中的类似支持。

将 Dart 编译为本机代码的支持，也是使 Flutter 应用具有出色的启动性能和快速渲染的核心。除此之外，你还可以使用 `dart compile` 编译 Dart 文件为可执行文件。这些可执行文件可以在任何机器上独立运行，无需安装 Dart SDK。Dart 2.17 中的另一个新功能是支持对可执行文件进行签名，生成的产物可以在经常需要签名的 Windows 和 macOS 上进行部署。

我们还保持在新兴的平台前沿，继续扩大我们所支持的平台集。[RISC-V](https://link.juejin.cn/?target=https%3A%2F%2Friscv.org%2Fabout%2F) 是一个全新的指令集体系。RISC-V International 是一家全球性的非盈利组织，拥有 RISC-V 规范，使得指令集自由开放。这仍然是一个新兴的平台，但我们对其潜力感到兴奋，因此我们的 `2.17.0–266.1.beta` Linux 版本包含了对它的实验性支持。我们希望能够听到你的反馈，你可以 [提出问题](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fdart-lang%2Fsdk%2Fissues) 或 [分享](https://link.juejin.cn/?target=https%3A%2F%2Fgroups.google.com%2Fa%2Fdartlang.org%2Fg%2Fmisc) 你的体验！

## 开始使用 Dart 2.17！

我们希望 Dart 的 2.17 正式版能打动你并能助力你提高工作效率，也同时能够把你的应用带去更多的平台。即刻下载 Dart 2.17 并开始使用，也安装使用 Flutter 3，使用内置的 Dart SDK。