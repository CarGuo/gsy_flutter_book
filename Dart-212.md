今天 Dart 2.12 发布了，该版本具有稳定的空安全声明和Dart FFI版本。

空安全是最新的关键生产力功能，旨在帮助开发者避免空错误，这是一项通常很难被发现的错误。

FFI是一种互操作性机制，可以让开发者调用 C 语言编写的现有代码，例如调用 Windows Win32 API。


![](http://img.cdn.guoshuyu.cn/20211223_Dart-212/image1)

### Dart平台的独特功能

在详细解释空安全声明和 FFI 之前，让我们先讨论一下 Dart 平台如何将它适合我们的目标平台上。

编程语言通常倾向于共享许多功能，例如许多语言支持面向对象的编程或在在 Web 上运行，真正使语言与众不同的是它们独特的功能组合。

![](http://img.cdn.guoshuyu.cn/20211223_Dart-212/image2)

Dart的独特功能涵盖了三个方面：

- 可移植性：高效的编译器为设备生成 x86 和 ARM 机器代码，并为 Web 生成优化后的JavaScript代码。所以 Dart 的持续目的就是支持：移动设备、台式机、应用后端等等。大量的库和软件包提供了可在所有平台上使用的一致性 API，从而进一步降低了创建真正的多平台应用程序的成本。

- 高效：Dart平台支持热重装，从而可以对本机设备和Web进行快速地迭代和开发。Dart提供了丰富的结构，如` isolates` 和 `async/await`，用于处理常见的并发和事件驱动的模式。

- 健壮：Dart 是健全的，null 安全系统会在开发过程中捕获错误。整个平台具有高度的可扩展性和可靠性，Dart 已经有十多年的历史被运用于生产开发，其中包括 Google Ads和Google Assistant等业务关键型应用程序。

> PS：事实上被大规模应用还是因为近几年的 Flutter 

可靠的空安全声明使类型系统更加强大，并具更好的性能，而 Dart FFI 可以让开发者用现有的 C 库来得到了更便捷的可移植性，可以选择对性能要求很高的任务使用经过C代码来调度实现。


###  空安全声明


自 Dart 2.0 引入空安全声明以来，空安全声明是 Dart 语言的最大补充。空安全性进一步增强了类型系统，使得开发者能够在开发阶段就捕获到空错误，这是过去应用程序崩溃的常见原因。

合理的空安全声明是围绕一些[核心原则设计](https://dart.dev/null-safety#null-safety-principles)的，接下来让我们了解下这对开发人员会有声明影响。

### 默认情况下不可为空

空安全声明之前的核心挑战是，开发者无法分辨**传递空值的代码与不能使用空值的代码之间的区别**。

几个月前，我们在 Flutter master channel 中发现了一个错误，该错误会在某些机器配置上会使得各种 flutter 工具命令崩溃，并出现 null 错误：`The method '>=' was called on null` ， 而根本的问题是这样的代码：

```
final int major = version?.major;
final int minor = version?.minor;
if (globals.platform.isMacOS) {
  // plugin path of Android Studio changed after version 4.1.
  if (major >= 4 && minor >= 1) {
  ...
```

发现错误的地方了吗？因为 `version` 可以为 `null` ，所以 `major` 和 `minor` 也可以为 null。

这样的独立错误看起来很容易被发现，但实际上即使是经过严格的代码审查过程（如Flutter Code Review），这样的代码也始终无处不在。所以出于安全考虑，静态分析会立即捕获此问题。

![](http://img.cdn.guoshuyu.cn/20211223_Dart-212/image3)

那是一个非常简单的错误，而在 Google 的内部，早期使用 null 安全性的过程中，我们发现了很多复杂的错误，其中一些是已经存在多年的 bug，但是如果没有 null 安全性的额外静态检查，团队就无法找到原因。

这里有一些例子：

- 一个内部团队发现，他们经常检查到永远不能为 null 的表达式得到了 null 值。使用protobuf 的代码中最经常出现此问题，其中可选字段在未设置时返回默认值，并且永远不会为null。如此一来，通过混淆默认值和空值，代码错误地检查了默认条件。

- Google Pay 小组在 Flutter 代码中发现了一些错误，这些错误会在 `State` 在上下文之外尝试访问 Flutter 对象的 `Widget` 。在实现 null 安全之前，这些对象将返回 null并掩盖错误；出于安全考虑，声明分析确定这些属性永远不会为空，并引发了分析错误。

- Flutter 小组发现了一个错误，如果将 `null` 的 `scene` 参数传递给 `Window.render()`，Flutter 引擎可能会崩溃。在进行 null 安全迁移期间，他们添加了一个提示，将 `Scene` 标记为 `non-nullable`，然后能够轻松地防止可能触发 null 的潜在应用崩溃。

### 默认情况下使用非空

一旦启用空安全，变量声明的基本行为会被改变，因为默认的类型是不可为空：

```
// In null-safe Dart, none of these can ever be null.
var i = 42; // Inferred to be an int.
String name = getFileName();
final b = Foo();
```

如果要创建一个可以包含值或 null 的变量，则需要通过 ? 在类型声明中添加后缀来使该变量在变量声明中显式显示：

```
// aNullableInt can hold either an integer or null.
int? aNullableInt = null;
```

空安全性的实现是健壮的，并且具有丰富的静态流分析功能，使用可空类型的工作变得更加容易。例如，在检查了null之后，Dart将局部变量的类型从 nullable 提升为 non-nullable ：

```
int definitelyInt(int? aNullableInt) {
  if (aNullableInt == null) {
    return 0;
  }
  // aNullableInt has now promoted to a non-null int.
  return aNullableInt; 
}
```

我们还添加了一个新关键字 `required ` ，当命名参数被标记为 `required`（在Flutter小部件API中经常发生）并且调用者忘记提供参数时，就会发生分析错误：

![](http://img.cdn.guoshuyu.cn/20211223_Dart-212/image4)

### 逐步迁移到空安全性

因为空安全性改变了我们的编码习惯，所以如果坚持强制采用，那将是极度破坏性的。所以我们决定让开发者在最需要的时候启用，所以空安全是一项可选功能：你可以用 Dart 2.12 而无需被迫启用空安全，你甚至可以依赖已经启用了空安全性的软件包，无论应用程序或软件包是否启用了空安全性。


为了帮助开发者将现有代码迁移到安全性状态，我们提供了迁移工具和迁移指南。这些工具首先将分析所有现有代码，然后开发者可以交互地查看该工具推断的可空性属性。

如果开发者不同意该工具的结论，则可以通过添加可空性提示以更改推断，添加一些迁移提示可能会对迁移的质量带来较大的影响。

![](http://img.cdn.guoshuyu.cn/20211223_Dart-212/image5)

目前使用 `dart create` 和 `flutter create` 不启用空安全性声明创建的新程序包和应用程序。使用 `dart migrate` 可以简单地启用空安全的功能。

### Dart 生态系统的空安全迁移状况

在过去的一年中，我们提供了几种空安全声明的预览版和 Beta 版，目的是为生态系统植入支持空安全的软件包。

这项准备工作很重要，因为我们建议按顺序迁移，以确保空安全声明不会影响开发者现有的应用，开发者在所以依赖完成迁移之前最好不要启动空安全配置。

Dart，Flutter，Firebase 和 Material 团队已经发布提供的数百个具备 null 安全的软件包的版本，而且我们已经从惊人的 Dart 和 Flutter 生态系统中获得了巨大的支持，因此pub.dev 现在有超过一千个支持 null 安全的软件包。

重要的是，最受欢迎的那些软件包已首先完成迁移，因此对于今天的发布而言，最流行的前100个软件包中有98％是支持 null safety，前250个顶级软件包中的 78％ 和前500个顶级软件包中的 57％ 也已经支持零安全性。

我们期待在未来几周内在 pub.dev 上看到更多具有空安全性的软件包。分析表明，pub.dev 上的绝大多数软件包已被解除阻止，可以开始迁移。


### 完全空安全性的好处

完全迁移后，Dart 的空安全性就可以启用了，这意味着 Dart 100％ 确保具有不可为 null 的类型的表达式不能为 null 。

当 Dart 分析开发者的代码并确定某个变量不可为空时，该变量将始终为不可为空，而 Dart 与 Swift 共享空安全声明，这在其他编程语言上很少见。

> PS ：Kotlin 有话要说


Dart 空安全声明的健壮性性还具有另一个意义：**这意味着您的程序可以更小，更快**。

由于 Dart 确保不可为空的变量永远不会为 null ，因此 Dart 可以进行优化。例如 Dart 提前（AOT）编译器可以生成更小，更快的本机代码，因为当知道变量不为 null 时，它不需要添加对 null 的检查。


### Dart FFI，用于将Dart与C集成

Dart FFI 让开发者能够利用 C 语言中的现有代码，以实现更好的可移植性，并且利用调整的 C 代码集成以执行对性能要求较高的任务。

从Dart 2.12 开始，Dart FFI 已脱离Beta阶段，现已被认为稳定并且可以投入生产，我们还添加了一些新功能，包括嵌套结构和按值传递结构。


#### 通过值传递结构

可以在C代码中按引用和按值传递结构，FFI 以前仅支持按引用传递，但从 Dart 2.12 开始开发者可以按值传递结构，例如：

```
struct Link {
  double value;
  Link* next;
};
void MoveByReference(Link* link) {
  link->value = link->value + 10.0;
}
Coord MoveByValue(Link link) {
  link.value = link.value + 10.0;
  return link;
}
```

####  嵌套结构

C API 通常使用嵌套结构-本身包含结构体的结构，例如以下示例：

```
struct Wheel {
  int spokes;
};
struct Bike {
  struct Wheel front;
  struct Wheel rear;
  int buildYear;
};
```


从Dart 2.12开始，FFI支持嵌套结构。


### API变更

为了完善 FFI 稳定并支持上述功能，我们进行了一些较小的API更改。

现在禁止创建空结构 ([#44622](https://github.com/dart-lang/sdk/issues/44622)) ，并产生弃用警告，开发者可以使用新的类型 `Opaque` 来表示空结构。

`dart:ffi`的 `sizeOf` 、 `elementAt` 以及 `ref` 现在需要编译时类型参数（[＃44621](https://github.com/dart-lang/sdk/issues/44621)）因为 `package:ffi` 已添加了新的便利功能，所以在常见情况下，不需要分配和释放内存。
```
// Allocate a pointer to an Utf8 array, fill it from a Dart string,
// pass it to a C function, convert the result, and free the arg.
//
// Before API change:
final pointer = allocate<Int8>(count: 10);
free(pointer);
final arg = Utf8.toUtf8('Michael');
var result = helloWorldInC(arg);
print(Utf8.fromUtf8(result);
free(arg);
// After API change:
final pointer = calloc<Int8>(10);
calloc.free(pointer);
final arg = 'Michael'.toNativeUtf8();
var result = helloWorldInC(arg);
print(result.toDartString);
calloc.free(arg);
```

### 自动生成FFI绑定

对于较大的 API 暴露，在编写与 C 代码集成的 Dart 绑定可能会非常耗时，为了减轻这种负担，我们构建了一个绑定生成器，用于根据 C 头文件自动创建 FFI 包装器 `package:ffigen`。

### FFI路线图

随着核心 FFI 平台的完成，我们将重点转移到扩展FFI功能上，使其具有在核心平台之上分层的功能，我们正在调查的一些功能包括：

- 特定于ABI的数据类型，例如int，long，size_t [＃36140](https://github.com/dart-lang/sdk/issues/36140)
- 内联结构中的数组 [＃35763](https://github.com/dart-lang/sdk/issues/35763)
- 打包的结构 [＃38158](https://github.com/dart-lang/sdk/issues/38158)
- 联合类型 [＃38491](https://github.com/dart-lang/sdk/issues/38491)
- 将 finalizers  暴露给 Dart[＃35770](https://github.com/dart-lang/sdk/issues/35770)

### FFI的示例用法

前面我们已经讲了 Dart FFI 的许多创造性用法，以与各种基于 C 的API集成，这里有一些例子：

- [open_file](https://pub.dev/packages/open_file) 是用于跨多个平台打开文件的单个API，它使用 FFI 来调用 Windows，macOS 和Linux上的本机操作系统API。https://pub.dev/packages/open_file

- [win32](https://pub.dev/packages/win32) 封装了最常见的Win32 API，从而可以直接从Dart调用各种Windows API。https://pub.dev/packages/win32

- [objectbox](https://pub.dev/packages/objectbox) 是由基于C的实现支持的快速数据库。https://pub.dev/packages/objectbox

- [tflite_flutter](https://pub.dev/packages/tflite_flutter) 使用FFI包装TensorFlow Lite API。

### Dart语言的下一步是什么？

空安全声明是我们几年来对 Dart 语言所做的最大改变，接下来我们将考虑在我们强大的基础上对语言和平台进行更多的增量更改。

我们在语言设计渠道中正在尝试的一些事情：

- Type aliases  [＃65](https://github.com/dart-lang/language/issues/65)：可以为非函数类型创建类型别名，例如可以创建一个 `typedef` 并将其用作变量类型：

```
typedef IntList = List <int>; 
IntList il = [1,2,3];
```

- Type aliases [＃120](https://github.com/dart-lang/language/issues/120)：添加了一个新的，完全可重写的 `>>>` 运算符，用于对整数进行无符号移位。

- Generic metadata annotations [＃1297](https://github.com/dart-lang/language/issues/1297)：扩展元数据注释以也支持包含类型参数的注释。

- Static meta-programming [＃1482](https://github.com/dart-lang/language/issues/1482)：支持静态元编程 — Dart程序在编译过程中会生成新的Dart 源代码，类似于 Rust 宏和 Swift 函数生成器（该功能仍处于早期探索阶段，但是我们认为它可以启用当今依赖于代码生成的用例。）


### Dart 2.12 is available now


Dart 2.12 和 Flutter 2.0 SDK 现已提供具有可靠的空安全性和稳定FFI的，所以请花点时间查看 Dart 和 Flutter 的已知的无效安全问题，如果你发现任何其他问题，请在 Dart tracker 中报告这些问题。

> https://github.com/dart-lang/sdk/issues

如果你已经在pub.dev上发布了软件包，请立即查看迁移指南，并了解如何迁移以达到安全性。迁移软件包可能会帮助解除阻止其他依赖于该软件包的软件包和应用程序，并且我们还要感谢已经迁移的人！