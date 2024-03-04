# Dart 3.3 发布：扩展类型、JavaScript Interop 等

> 参考链接：https://medium.com/dartlang/dart-3-3-325bf2bf6c13

跟随 [Flutter 3.19 发布](https://juejin.cn/post/7334503381200781363)的还有 Dart 3.3 ，Dart 3.3 主要包含扩展类型增强，性能优化和 native 代码交互推进，例如本次改进的**JavaScript Interop** 模型就引入了类型安全，[所以这一切都为 WebAssembly 支持铺平了道路](https://juejin.cn/post/7232164444985622588)。

>在[《Flutter 2024 路线规划里》](https://juejin.cn/post/7335067315452428297) ，**Web 平台上未来  CanvasKit 将成为默认渲染**，所以未来 Dart 在 Web 上肯定是 Wasm Native 的路线。



# 扩展类型

扩展类型是一种编译时抽象，它用不同的纯静态接口来 “Wrapper” 现有类型，同时它们也是 Dart 和[静态 JS 互操作](https://dart.dev/go/next-gen-js-interop)的主要实现基础，因为它们可以轻松修改现有类型的接口（对于任何类型的相互调用都至关重要），而不会产生实际 Wrapper 的成本。

```dart
extension type E(int i) {
  // Define set of operations.
}
```

扩展类型引入了类型的零成本 wrappers，使用它们来优化性能敏感的代码，尤其是在与 native 平台交互时，扩展类型提供了具有特定成员自定义类型的便利性，同时消除了典型的 wrappers 分配开销。

```dart
extension type Wrapper(int i) {
  void showValue() {
    print('my value is $i');
  }
}

void main() {
  final wrapper = Wrapper(42);
  wrapper.showValue(); // Prints 'my value is 42'
}
```

上面的例子实现了一个 **`Wrapper`** 扩展类型，但将其用作普通的 Dart 类型，在实际使用里，开发者可以实例化它并调用函数。

这里的主要区别在于 Dart 将其编译为普通 Dart **`int`** 类型，扩展类型允许创建具有唯一的成员类型，而无需分配典型 wrappers 类型的间接成本，例如以下例子包装了对应的 `int` 类型以创建仅允许对 ID 号有意义的操作的扩展类型。

```dart
extension type IdNumber(int id) {
  // Wraps the 'int' type's '<' operator:
  operator <(IdNumber other) => id < other.id;
  // Doesn't declare the '+' operator, for example,
  // because addition does not make sense for ID numbers.
}

void main() {
  // Without the discipline of an extension type,
  // 'int' exposes ID numbers to unsafe operations:
  int myUnsafeId = 42424242;
  myUnsafeId = myUnsafeId + 10; // This works, but shouldn't be allowed for IDs.

  var safeId = IdNumber(42424242);
  safeId + 10; // Compile-time error: No '+' operator.
  myUnsafeId = safeId; // Compile-time error: Wrong type.
  myUnsafeId = safeId as int; // OK: Run-time cast to representation type.
  safeId < IdNumber(42424241); // OK: Uses wrapped '<' operator.
}
```

因此，虽然  [extension members](https://dart.dev/language/extension-methods)  功能（Dart 2.7 开始）允许向现有类型添加函数和属性，但扩展类型功能也可以执行相同的操作，**并且还允许定义隐藏底层表示的新 API**。

这对于与 native code 的相互调用特别有用。可以直接使用原生类型，无需创建 Wrapper 和相关间接的成本，同时仍然提供干净的生产 Dart API。

> 扩展类型与 Wrapper 具有相同的用途，但不需要创建额外的运行时对象，当开发者需要包装大量对象时，Wrapper 这个行为可能会变得昂贵，由于扩展类型仅是静态的并且在运行时编译，因此它们本质上是零成本。
>
> [**扩展方法**](https://dart.dev/language/extension-methods)（也称为“扩展”）是类似于扩展类型的静态抽象。但是扩展方法是**直接**向其基础类型的每个实例添加功能；扩展类型不同，**扩展类型的接口仅适用于静态类型为该扩展类型的表达式**。
>
> 默认情况下它们与其基础类型的接口不同。

扩展类型有两个同样有效但本质上不同的核心用例：

- **为现有类型提供扩展接口**，当扩展类型实现其表示类型时，一般可以认为它是“透明的”，因为它允许扩展类型“看到”底层类型。

  透明扩展类型可以调用表示类型的所有成员（[未重新声明的](https://dart.dev/language/extension-types#redeclare)），以及它定义的任何辅助成员，这将为现有类型创建一个新的扩展接口，新接口可用于静态类型为扩展类型的表达式，例如如下代码里，`v1.i` 可以正常调用，但是 int 类似的` v2` 不可以调用 `v2.i`：

```dart
extension type NumberT(int value) 
  implements int {
  // Doesn't explicitly declare any members of 'int'.
  NumberT get i => this;
}
void main () {
  // All OK: Transparency allows invoking `int` members on the extension type:
  var v1 = NumberT(1); // v1 type: NumberT
  int v2 = NumberT(2); // v2 type: int
  var v3 = v1.i - v1;  // v3 type: int
  var v4 = v2 + v1; // v4 type: int
  var v5 = 2 + v1; // v5 type: int
  // Error: Extension type interface is not available to representation type
  v2.i;
}
```
![](http://img.cdn.guoshuyu.cn/20240216_Dart-303/image1.png)

- **为现有类型提供不同的接口**，[不透明](https://dart.dev/language/extension-types#transparency)的扩展类型（不是 [`implement `](https://dart.dev/language/extension-types#implements)其表示类型）被静态地视为全新类型，与其表示类型不同，所以无法将其分配给其表示类型，并且它不会公开其表示类型的成员，例如 `NumberE` 不能为 int ，并且 ：

```dart
extension type NumberE(int value) {
  NumberE operator +(NumberE other) =>
      NumberE(value + other.value);

  NumberE get next => NumberE(value + 1);
  bool isValid() => !value.isNegative;
}

void testE() { 
  var num1 = NumberE(1);
  int num2 = NumberE(2); // Error: Can't assign 'NumberE' to 'int'.
  
  num1.isValid(); // OK: Extension member invocation.
  num1.isNegative(); // Error: 'NumberE' does not define 'int' member 'isNegative'.
  
  var sum1 = num1 + num1; // OK: 'NumberE' defines '+'.
  var diff1 = num1 - num1; // Error: 'NumberE' does not define 'int' member '-'.
  var diff2 = num1.value - 2; // OK: Can access representation object with reference.
  var sum2 = num1 + 2; // Error: Can't assign 'int' to parameter type 'NumberE'. 
  
  List<NumberE> numbers = [
    NumberE(1), 
    num1.next, // OK: 'i' getter returns type 'NumberE'.
    1, // Error: Can't assign 'int' element to list type 'NumberE'.
  ];
}
```

  ![](http://img.cdn.guoshuyu.cn/20240216_Dart-303/image2.png)

另外需要注意，**扩展类型是编译时包装构造，在运行时绝对没有扩展类型的踪迹**，任何类型查询或类似的运行时操作都适用于表示类型，在任何情况下，扩展类型的表示类型都不是其子类型，因此在需要扩展类型的情况下表示类型不能互换使用。

# JavaScript Interop 

Dart 3.3 引入了一种与 JavaScript 和 Web 相互调用的新模型，它从一组用于与 JavaScript 交互的新 API 开始：[dart:js_interop](https://api.dart.dev/dart-js_interop/dart-js_interop-library.html) 。

现在，**Dart 开发人员可以访问类型化 API 来与 JavaScript 交互**，该 API 通过静态强制明确定义了两种语言之间的边界，在编译之前消除了许多问题。

除了用于访问  JavaScript 代码的新 API 之外，Dart 现在还包含一个新模型，用于使用扩展类型在 Dart 中表示 JavaScript 类型，如下代码就是前面拓展类型的实际使用实例：

```dart
import 'dart:js_interop';

/// Represents the `console` browser API.
extension type MyConsole(JSObject _) implements JSObject {
  external void log(JSAny? value);
  external void debug(JSAny? value);
  external void info(JSAny? value);
  external void warn(JSAny? value);
}
```

基于扩展类型的语法比扩展成员允许更多的表达和健全性。这简化了 Dart 中 JavaScript API 的利用，更多详细信息可以查看：https://dart.dev/interop/js-interop 。

# 改进 browser libraries

从 1.0 版本开始，Dart SDK 就包含了一套全面的 browser libraries，其中包括核心 [dart:html](https://api.dart.dev/dart-html/dart-html-library.html) 库以及 SVG、WebGL 等库。

改进后的 JavaScript 调用模型提供了重新构想这些库的机会，未来 browser libraries 支持将集中在 [package:web](https://pub.dev/packages/web)上，这简化了版本控制、加速了更新并与[MDN](https://developer.mozilla.org/)资源保持一致，这一系列的改进推动了[将 Dart 编译为 WebAssembly](https://juejin.cn/post/7232164444985622588)。

# 从今天开始，开启 WebAssembly 的未来

Dart 3.3 为WebAssembly 的 Web 应用奠定基础，虽然 Flutter Web 中的 WebAssembly 支持仍处于试验阶段，但是这对于 Dart 和 Flutter 是明显的方向。

要使用 WebAssembly 在 Web 上运行 Flutter 应用，需要使用新的 JavaScript Interop 机制和 `package:web` ，旧版 JavaScript 和 browser libraries 保持不变，并支持编译为 JavaScript 代码。但是，如果编译为 WebAssembly 需要迁移，例如：

```dart
import 'dart:html' as html; // Remove
import 'package:web/web.dart' as web; // Add

dependencies:
  web: ^0.5.0
```

>  更多可见：https://dart.dev/interop/js-interop/package-web