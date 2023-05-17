# Google I/O 2023 - Dart 3 发布，快来看看有什么更新吧

> 核心原文链接： https://medium.com/dartlang/announcing-dart-3-53f065a10635

自从 Flutter Forword 发布了  [Dart 3α 预览](https://juejin.cn/post/7194741144482218045) 之后，大家对 Dart 3 的正式发布就一直翘首以待，这不仅仅是 Dart 版本号追上了 Flutter 版本号，更是 Dart 在 2.0 之后迎来的最大一次更新，主要包括了：

- 100% 空安全
- records
- patterns
- class modifiers
- Wasm 对 Web 的增加支持，可以预览 dart wasm native 了



# 100% 空安全支持

如下图所示，Dart 的 null safety 历经三年的时间，如今 Dart 终于有用了完善的类型系统，现在的 Dart 3 下，如果一个类型说一个值不是 `null`，那么它永远不可能是 `null` 。

![](http://img.cdn.guoshuyu.cn/20230511_D3/image1.png)

> 说起来，还真有不少用户的项目没升级到 null safety ，这次就不能再等了。

另外，目前 pub.dev 上排名前 1000 的包中有 99% 支持空安全，所以官方预计升级到 Dart 3 的兼容问题并不大，少数情况下，Dart 3 中的对一些历史代码的相关清理可能会影响某些代码的运行，例如

- 一些旧的核心库 API 已被删除（[#34233](https://github.com/dart-lang/sdk/issues/34233)、[#49529](https://github.com/dart-lang/sdk/issues/49529)）
- 一些工具已被调整（[#50707](https://github.com/dart-lang/sdk/issues/50707)）。

> 如果你在迁移到到 Dart 3  时遇到问题，可以查阅 https://dart.dev/resources/dart-3-migration

# Record, patterns 和 class modifiers

关于万众期待的 record 和 patterns 其实在之前的  [Dart 3α 新特性 Record 和 Patterns 的提前预览讲解](https://juejin.cn/post/7194741144482218045)上已经有个详细解释，这里主要重新根据官方内容简诉一些这些变化。

## 使用 record 构建结构化数据

在此之前 Dart 函数只能返回一个值，如果需要返回多个值，必须将这些值打包成其他数据类型，例如 Map 或 List，或者定义可以保存这些值的新类。

使用非类型化数据结构削弱了类型安全性，而定义新类来传输数据会增加编码过程中的工作量，但是现在，通过 record 就可以简洁明地构建结构化数据：

```dart
(String, int) userInfo(Map<String, dynamic> json) {
  return (json['name'] as String, json['height'] as int);
}
```

在 Dart 中，record 是一个通用功能，它们不仅可以用于函数返回值，还可以将它们存储在变量中，例如将它们放入 List 中或者它们用作 Map 中的键，或创建包含其他 record 的 record。

另外还可以添加未命名字段，就像我们在前面的示例中所做的那样，也可以添加命名字段，例如 `(42, description: ‘Meaning of life’)` 。

record 是值类型，没有标识，这让编译器能够在某些情况下完全擦除记录对象，记录还带有自动定义的 `==` 运算符和 `hashCode` 函数。

> 详细可以参考官方文档：https://dart.dev/language/records  或者之前相关的中文资料： https://juejin.cn/post/7194741144482218045

## 使用具有 pattern 和 pattern 匹配的结构化数据

record 简化了构建结构化数据的方式，这不会取代使用类来构建正式的类型层次结构的方式，它只是提供了另一种选择。

在任何一种情况下，你可能希望将结构化数据分解为单独的元素，这就是 pattern 匹配发挥作用的地方。

考虑 pattern 的基本形式，以下记录 pattern 将 record 解构为两个新变量 `name` 和 `height` ，然后可以像任何其他变量一样使用这些变量：

```dart
var (String name, int height) = userInfo({'name': 'Michael', 'height': 180});
print('User $name is $height cm tall.');
```

List 和 Map 存在类似的 pattern ，都可以使用下划线模式跳过单个元素：

```dart
var (String name, _) = userInfo(…);
```

在 switch 语法中， Dart 3 扩展了语句 switch 的支持，现在支持在这些情况下进行 pattern 匹配：

```dart
switch (charCode) {
  case slash when nextCharCode == slash:
    skipComment();

  case slash || star || plus || minus:
    operator(charCode);

  case >= digit0 && <= digit9:
    number();

  default:
    invalid();
}
```

还可以通过新的表达式进行微调，以下示例函数返回 switch 表达式的值以计算今天工作日的描述：

```dart
String describeDate(DateTime dt) =>
  switch (dt.weekday) {
      1 => 'Feeling the Monday blues?',
      6 || 7 => 'Enjoy the weekend!',
      _ => 'Hang in there.'
  };
```

**模式的一个强大功能是检查 “exhaustiveness” 的能力，此功能可确保 switch 处理所有可能的情况**。

在前面的示例中，我们正在处理工作日的所有可能值，这是一个`int` ，所以我们通过针对特定值 `1` 或 `6  `/`7` 的匹配语句的组合来穷尽所有可能的值，然后通过 `_` 对其余情况使用默认情况。

要对用户定义的数据层次结构（例如类层次结构）启用该能力，请在类层次结构的顶部使用 `sealed` 修饰符，如下例所示：

```dart
sealed class  Animal  { … } 
class  Cow  extends  Animal  { … } 
class  Sheep  extends  Animal  { … } 
class  Pig  extends  Animal  { … } 

String whatDoesItSay(Animal a) => 
    switch (a) { Cow c => ' $c says moo' , Sheep s => ' $s says baa' };
```

这将返回以下错误，提醒我们错过了最后一个可能的子类型 Pig 的处理：

```
line 6 • The type 'Animal' is not exhaustively matched by the switch cases
since it doesn't match 'Pig()'.
```

最后，`if ` 语句也可以使用 pattern ，在下面的例子里，我们使用 *if-case* 匹配映射模式来解构 JSON 映射，这里匹配常量值（字符串如 `'name'` and  `'Michael' `）和类型测试模式 `int h` 以读出 JSON 值，如果模式匹配失败，Dart 将执行该 `else` 语句。

```dart
final json = {'name': 'Michael', 'height': 180};

// Find Michael's height.
if (json case {'name': 'Michael', 'height': int h}) {
  print('Michael is $h cm tall.'); 
} else { 
  print('Error: json contains no height info for Michael!');
}
```

> 详细可以参考官方文档：http://dart.dev/language/patterns  或者之前相关的中文资料： https://juejin.cn/post/7194741144482218045



# classes with class modifiers

Dart 3 的第三个语言特性是类修饰符，与前两个支持不同的是，这更像是一个高级用户功能，它主要是为了满足了 Dart 开发人员制作大型 API 或构建企业级应用时的需求。

> 目前是基于 *constructed*、 *extended* 和 *implemented* 来实现处理，关键词有 

类修饰符使 API 作者能够仅支持一些特定的功能，而默认值保持不变，例如：`abstract`、`base` 、`final`、`interface`、`sealed`、`mixin` 。

> 只有`base `修饰符可以出现在 mixin 声明之前，修饰符不适用于其他声明如 `enum`、`typedef`或 `extension`。

```dart
class Vehicle {
  String make; String model;
  void moveForward(int meters) { … }
}

// Construct.
var myCar = Vehicle(make: 'Ford', model: 'T',);

// Extend.
class Car extends Vehicle {
  int passengers;
}

// Implement.
class MockVehicle implements Vehicle {
  @override void moveForward …
}
```

例如要强制继承类或 mixin 的实现，就可以使用 `base` 修饰符。 `base` 不允许在其自己的库之外实现，这保证：

- 每当创建类的子类型的实例时，都会调用基类构造函数
- 所有实现的私有成员都存在于子类型中
- 类中新实现的成 员`base `不会破坏子类型，因为所有子类型都继承了新成员

```dart
// Library a.dart
base class Vehicle {
  void moveForward(int meters) { ... }
}


// Library b.dart
import 'a.dart';

var myCar = Vehicle();            // Can be constructed

base class Car extends Vehicle {  // Can be extended
    int passengers;
    // ...
}

base class MockVehicle implements Vehicle {  // ERROR: Cannot be implemented
    @override
    void moveForward { ... }
}
```

如果要创建一组已知的、可枚举的子类型，就可以使用修饰符 `sealed` ，[sealed 允许在那些静态](https://dart.dev/language/branches#exhaustiveness-checking)子类型上创建一个 switch 。

```dart
sealed class Vehicle { ... }

class Car extends Vehicle { }
class Truck implements Vehicle { }
class Bicycle extends Vehicle { }

// ...

var vehicle = Vehicle();  // ERROR: Cannot be instantiated
var vehicle = Car();      // Subclasses can be instantiated

// ...

// ERROR: The switch is missing the Bicycle subtype or a default case.
return switch (vehicle) {
  Car() => 'vroom',
  Truck() => 'VROOOOMM'
};
```

类修饰符存在一些添加限制，例如：

- 使用 `interface class` ，可以定义 contract 给其他人去实现，但不能扩展接口类。
- 使用 `base class`，可以确保类的所有子类型都继承自它，而不是实现它的接口，这确保私有方法在所有实例上都可用。
- 使用 `final class`，可以关闭类型层次结构，以防止自己的库之外的任何子类。这样的好处是允许 API 所有者添加新成员，而不会出现破坏 API 使用者更改的风险。

> 是不是没看明白？有关详细信息，可以参考 https://dart.dev/language/class-modifiers

# 展望未来

Dart 3 不仅仅是是在这些新功能上向前迈出了重要的一步，还为大家提供了下一步的预览。

## Dart language

Records, patterns 和 class modifiers 是非常庞大的新功能，因此它们的某些设计可能还需要改进，所以接下来还会有一些更小、更增量的功能更新，这些功能完全不会中断，并且专注于在没有迁移成本的情况下提高开发人员的工作效率。

目前正在探索的还有  [primary constructors](https://github.com/dart-lang/language/issues/2364) 和  [inline classes](https://github.com/dart-lang/language/issues/2727)  包装，另外之前讨论过的宏（也称为[元编程](https://github.com/dart-lang/language/blob/main/working/macros/feature-specification.md)）也在进行探索，因为元编程的规模和固有风险，目前正在采取一种更有效和彻底的方法进行探索，因此没有具体的时间表可以分享，即使是最终确定的设计决策。

## native interop

移动和桌面上的应用通常依赖于 native 平台提供的大量 API，无论是通知、支付还是获取手机位置等。

在之前 Flutter 中，这些是通过构建插件来访问的，这需要为 API 编写 Dart 代码和一堆特定于平台的代码来提供实现。

目前已经支持与使用 `dart:ffi` 直接和原生语言进行交互，我们目前正在努力扩展它在Android 上的支持，再次之前可以看 [Java 和 Kotlin interop ](https://dart.dev/guides/libraries/java-interop)  以及 [Objective-C 和 Swift interop](https://juejin.cn/post/7137874832988831751) 。

> 请查看新的 Google I/O 23 的  [Android interop 视频](https://io.google/2023/program/2f02692d-9a41-49c0-8786-1a22b7155628/)。

## 编译为 WebAssembly——使用 native 代码定位 web

[WebAssembly （缩写为 Wasm）作为跨](https://webassembly.org/)[所有浏览器的](https://caniuse.com/wasm)平台的二进制指令格式，其可用性度一直在增长，Flutter 框架使用 Wasm 有一段时间了，这就是我们如何通过 Wasm 编译模块将用 C++ 编写的 SKIA 图形渲染引擎交付给浏览器的实现。

Flutter 也一直对使用 Wasm 来部署 Dart 代码很感兴趣，但是在此之前该实现被阻止了，与许多其他面向对象的语言一样，因为 Dart 需要使用垃圾回收。

在过去的一年里，Flutter 和 Wasm 生态系统中的多个团队合作，将新的 WasmGC 功能添加到 WebAssembly 标准中，目前在 Chromium 和 Firefox 浏览器中已经接近稳定。

将 Dart 编译为 Wasm 模块的工作有两个针对 Web 的高级目标：

- **加载时间：**我们希望我们可以使用 Wasm 交付部署有效负载，使浏览器可以更快地加载，从而缩短到达用户可以与 Web 交互的时间。
- **性能：**由  JavaScript  提供支持的 Web 应用需要即时编译才能获得良好的性能，Wasm 模块更底层，更接近机器代码，因此我们认为它们可以提供更高的性能、更少的卡顿和更一致的帧率。
- **语义一致性**：Dart  在我们支持的平台之间保持高度一致而自豪。但是，在 web 上有一些例外情况，例如 Dart web 目前在[数字表示](https://dart.dev/guides/language/numbers)方式上有所不同，而使用 Wasm 模块，我们可以将 web 视为具有与其他原生目标相似语义的“原生”平台。

**跟随 Dart3 的发布， Dart 到 Wasm 编译的第一个预览也一起发布**，这是最初的 Flutter Web 重点支持。虽然现在还早，后续还有很多工作要完成，但已经可以通过 https://flutter.dev/wasm 开始测试。