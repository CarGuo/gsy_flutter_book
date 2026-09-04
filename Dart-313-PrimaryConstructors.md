# Dart 3.13 的到底改了什么？为什么很重要？有什么坑？

感觉 Dart 3.13 对外可能只是多了一个新语法，但是 Dart  的核心设计者甚至针对 Primary Constructors  写了一篇超长文章来聊这事，因为如果只看 Demo 上的例子，这个改动好像也没什么，比如加了 Primary Constructors  之后是这样 ：

```dart
class Point(final int x, final int y);
```

然后以前我们是这样：

```dart
class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}
```

看起来就是少了几行代码，好像 Dart 又从 Kotlin、Scala 借了一点语法糖设计的感觉，**但是实际对于 Dart 设计者来说，这是 Dart 语法的一次重构过程**。

![](https://img.cdn.guoshuyu.cn/b56b6701-1ea5-4b96-84de-02580f960b5e.png)



**这次变动其实是 Dart 团队借 Primary Constructors 实现的过程，重新整理了一遍 Dart 的「类、字段、参数、构造函数」之间的关系，也是 Dart 一次重要的重构**。

所以 Dart 3.13 最终落地的东西可比一行 `class Point(...)` 大很多，它包括：

- declaring parameters
- primary constructor body
- 新的字段初始化作用域
- `new()`、`factory()` 这套新的普通构造函数声明语法

> **实际上从 Dart 3.13 开始，构造函数这块的写法，会导致整个 Dart 和 Flutter 出现一次比较明显的风格迁移**。

那为什么这么多年一直有人在说 Dart 不提供类似 Kotlin 的 Data Class，然后现在反而做成了  Primary Constructor ？

确实 Dart language repository 这么多年来最热门的 feature request 一直是 Data Class，类似 Kotlin 的：

```kotlin
data class User(
    val name: String,
    val age: Int
)
```

> 既可以自动声明字段和构造函数，又会提供 `equals()`、`hashCode()`、`toString()`、`copy()` 等一系列 value semantics。

但 Dart 团队整理了整个历史讨论之后发现，其实很多 Dart 用户最想解决的其实是前半部分：**定义一个装数据的 class 太麻烦了**，比如传统 Dart 数据对象类似：

```dart
class Point {
  final int x;
  final int y;

  Point(int x, int y)
      : x = x,
        y = y;
}
```

这个一个  `x`  的概念在一个简单的 class 里可能出现四次，所以后来 Dart 加了 initializing formal：

```dart
class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}
```

这时候已经简化了一些，但字段还是要声明一次，构造参数再出现一次，所以 Dart 团队随即把问题拆成两件事：

- 一个是怎样更简洁地声明「constructor parameter + instance field」
- 一个是怎样获得 value equality、hashCode、copy 等 Data Class 能力

**所以 Dart 3.13 的  Primary Constructors  目标就是先解决第一个问题，在进行一次代码表达方式的压缩**。

实际上 Primary Constructor 的核心其实是 Declaring Parameter ，Primary Constructor  最简单的理解，就是把构造函数挪到 class header：

```dart
class Point(int x, int y);
```

不过这里其实有个比较容易忽略的问题，这段代码里的 `int x`  和 `int y`  只是 constructor parameter，**它们不会自动变成字段**，真正关键的是 Dart 3.13 引入的 declaring parameter：

```dart
class Point(
  final int x,
  final int y,
);
```

这里的 `final` 同时表达两层信息： `constructor parameter` 和  `final instance field` ，也就是等价于：

```dart
class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}
```

如果字段需要可变，那就用 `var`：

```dart
class Point(
  var int x,
  var int y,
);
```

这时候实际上等价于：

```dart
class Point {
  int x;
  int y;

  Point(this.x, this.y);
}
```

所以其实 Dart 团队实际上把 primary constructor parameter 分成了几种角色：

```dart
class Example(
  final int a,
  var int b,
  int c,
);
```

其中：

- final int a ： parameter + final field
- var int b   ：parameter + mutable field
- int c       ：普通 parameter

**这点非常重要，因为 Primary Constructor  没有规定「header 里的所有参数都是字段」，参数还是可以只参与初始化计算**，比如：

```dart
class Rectangle(
  final double width,
  final double height,
  double scale,
) {
  final double area = width * height * scale;
}
```

> 这里 `width` 和 `height` 会成为 instance field，`scale` 只存在于构造阶段。

所以实际上可能理解上会比过去稍微复杂一点点，官方 specification 甚至增加了一套新的 scope，叫 **primary initializer scope**，让普通 primary constructor parameter 可以被字段 initializer 使用，比如以前：

```dart
class DeltaPoint {
  final int x;
  final int y;

  DeltaPoint(this.x, int delta)
      : y = x + delta;
}
```

现在可以写：

```dart
class DeltaPoint(
  final int x,
  int delta,
) {
  final int y = x + delta;
}
```

> 这里 `delta` 没有成为字段，但字段 initializer 可以直接读取。

也就是很多以前只能放在 constructor initializer list 里的简单计算，现在甚至可以直接回到字段声明旁边。

那为什么 Dart 不直接照抄 Kotlin 就好呢？这套东西明显就有 Kotlin 的影子啊，比如 ：

Kotlin：

```kotlin
class Point(
    val x: Int,
    val y: Int
)
```

Dart：

```dart
class Point(
  final int x,
  final int y,
);
```

实际上  Dart 团队在这个问题上确实纠结和挺久，就是到底应该从「字段」推导 constructor，还是从「constructor parameter」推导字段。

比如 Swift 更倾向于另外一个方向：「先声明 fields」 ，然后「compiler 生成 memberwise initializer」 。

然后 Dart 最终选择了 「先声明 constructor API」 ，然后「部分 parameter 顺便生成 fields」 ，原因其实也很直接，因为 Constructor 本身经常就是一个公开 API，开发者可能需要更精确控制：

```text
named / positional
required / optional
default value
parameter order
constructor name
const
```

这些东西都天然属于 constructor signature ，如果从 fields 自动推导 constructor，就会有更多问题需要处理，比如：

- 字段顺序怎么算？
- 哪些字段应该 exposed？
- 哪些是 named parameter？
- 哪些 required？
- 默认值放在哪里？

> **所以 Dart 最后认为，让开发者明确写 constructor signature，再用  `var` / `final` 标记哪些参数同时产生字段，组合起来更自然。**

这也是为什么 Dart 的 Primary Constructor 看起来比某些语言稍微“重”一点的原因，它没有追求 `class Point(int x, int y)` 自动猜测 `x` 和 `y` 是字段，你必须明确写：

```dart
class Point(final int x, final int y);
```

或者：

```dart
class Point(var int x, var int y);
```

字段的存在和可变性需要都直接暴露在源码里。

当然，实际上这里还有一个必须提的就是 `this {}` ，Dart 团队说的是 **syntactic cliff，语法悬崖**。

比如最开始有一个很简单的 class：

```dart
class FormatterOptions({
  final int indent = 0,
  final int pageWidth = 80,
});
```

但是后来需求慢慢增加，变成了：

```dart
class FormatterOptions({
  final int indent = 0,
  final int pageWidth = 80,
  final bool followLinks = false,
  final bool setExitIfChanged = false,
});
```

然后有一天你突然需要在 constructor 里打印一行 log，如果 Primary Constructor 只支持「没有 body 的简单 class」，你可能就需要把整个 class 改回：

```dart
class FormatterOptions {
  final int indent;
  final int pageWidth;
  final bool followLinks;
  final bool setExitIfChanged;

  FormatterOptions({
    this.indent = 0,
    this.pageWidth = 80,
    this.followLinks = false,
    this.setExitIfChanged = false,
  }) {
    log.write('Created options.');
  }
}
```

语义只增加了一行 `log.write(...)` ，但是实际上 Git diff  会突然变成十几二十行，这就是 syntactic cliff：

> **一个很小的功能变化，让代码突然从一种简洁语法掉进另一套非常冗长的语法。**

所以 Dart 给 Primary Constructor 又设计了一块 constructor body：

```dart
class FormatterOptions({
  final int indent = 0,
  final int pageWidth = 80,
}) {
  this {
    log.write('Created options.');
  }
}
```

这里的 `this ` 就是 Primary Constructor 的 body，如果需要 initializer list，同样可以写：

```dart
class Point(
  final int x,
  final int y,
) {
  this : assert(x >= 0);
}
```

甚至你可以写成：

```dart
class B(
  int x,
  int y,
  {required final String s2},
) extends A {
  final String s1;

  this
      : s1 = y.toString(),
        super.someName(x + 1);
}
```

所以 Primary Constructor 没有被限制成「只能写 DTO」，你同样可以处理：

```text
parameters
fields
default values
assert
initializer list
super constructor call
constructor body
```

这也是 Dart 团队为什么花了这么久设计它，如果只是做 `class Point(final int x, final int y);` 其实没有那么复杂。

不过 Primary Constructor 确实带来了一个问题，**有了 Primary Constructor 之后，这个 constructor 在语义上真的是 primary**，官方 specification 有一条很重要的规则：

> **一个 class 如果拥有 primary constructor，那么其他 generative constructor 必须最终 redirect 到这个 primary constructor。**

原因和前面提到的字段 initializer scope 有直接关系，比如：

```dart
class C(
  int value,
) {
  final int result = value * 2;
}
```

这里 `result = value * 2` 成立的前提，是每次创建 `C` 时一定都会执行这个 primary constructor，如果同时允许 `C.other()` 完全绕过 primary constructor，那么 `value`  从哪里来就没办法定义了。

**所以 Dart 强制所有 generative constructor 都经过 primary constructor**，这也是 Primary Constructor 和「普通 constructor 的另一种写法」之间真正存在的结构差异。

> 如果一个 class 本来就有很多地位平等、初始化路径完全不同的 constructor，那么继续使用传统 in-body constructor 反而更清楚。

Dart 团队也明确说，并没有打算让 Primary Constructors 取代所有 constructor，对于 constructor 很多、class header 已经很复杂，或者核心 constructor 是 private 的情况，传统写法才更合理。

当然，其实 Dart 3.13 其实也改了普通 Constructor 的写法，从 Dart 3.13 开始普通 constructor  其实可以不再重复 class name，比如以前是：

```dart
class AnimatedFractionallySizedBox {
  AnimatedFractionallySizedBox();

  AnimatedFractionallySizedBox.create();

  factory AnimatedFractionallySizedBox.fromJson() {
    ...
  }
}
```

然后现在可以写：

```dart
class AnimatedFractionallySizedBox {
  new();

  new create();

  factory fromJson() {
    ...
  }
}
```

从对应关系可以看出来：

```text
Old                              Dart 3.13

ClassName()                      new()
ClassName.name()                 new name()

const ClassName()                const new()
const ClassName.name()           const new name()

factory ClassName()              factory()
factory ClassName.name()         factory name()
```

这项变化其实反而很 Dart，因为传统 C++ / Java / C# 风格 constructor 最大的问题就是：

```dart
class SomeExtremelyLongClassName {
  SomeExtremelyLongClassName();
}
```

class name 在上下文里已经非常明确，再写一遍基本没有提供额外信息，**而且这个问题在 Dart 将来准备做的 static extension members 里会更加麻烦**，比如：

```dart
class SomeClass {}

typedef OtherName = SomeClass;

extension on OtherName {
  // constructor?
}
```

如果 extension 将来允许增加 constructor，那么这里到底应该写 `OtherName() `还是 `SomeClass()` ，这就会出现 typedef identity、封装和名称解析问题，**所以 Dart 团队最后选择直接把这个历史包袱拆掉，`new()` 就是 generative constructor declaration，`factory()` 就是 factory constructor declaration。**

这样 constructor 就不再需要知道 class 的文本名字，当然比较搞笑的是它会产生：

```dart
const new();
```

这种  `const new` 第一眼看确实有点违和哈。

然后整套语法，如果放到 Flutter 里，以前典型 Widget 会是：

```dart
class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.name,
    required this.avatarUrl,
    this.showBadge = false,
  });

  final String name;
  final String avatarUrl;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    ...
  }
}
```

如果改成 Primary Constructor ，风格可以写成类似：

```dart
class const UserCard({
  super.key,
  required final String name,
  required final String avatarUrl,
  final bool showBadge = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ...
  }
}
```

这里 `super.key` 继续是 super parameter，而三个  `final` parameter 直接产生 fields，官方 specification 明确支持 super parameters：

```dart
class A(final int a);

class B(super.a) extends A;
```

更有意思的是，阅读的时候 class 的「输入 API + 保存的状态」集中到了顶部：

```dart
class UserCard({
  super.key,
  required final String name,
  required final String avatarUrl,
  final bool showBadge = false,
}) extends StatelessWidget {
```

看到这一段，基本就知道这个 Widget 保存了什么状态，**所以实际上这个语法糖的价值也不只是减少字符数而已，它还能让代码更直接地暴露意图。**

同时 Dart 官方也明确这将是未来 Dart 的主流风格，Dart 3.13 甚至开始通过 lint 推动这种新风格，也就是从官方配套来看， Dart 官方显然没有把 Primary Constructors 当成一个「想用就用的边缘语法」状态，这里 Dart 3.13 一次加入了六个相关 lint：

```text
empty_container_bodies
initialize_in_field_declaration
unnecessary_const_in_enum_constructor
unnecessary_primary_constructor_body
unnecessary_type_name_in_constructor
use_declaring_parameters
```

这些 lint 都围绕一个方向：让代码向更短的 rimary constructor 表达方式迁移，IDE 还直接增加了：

```text
Convert to primary constructor
Convert to in-body constructor
Convert to declaring parameter
Move initialization to the field declaration
```

特别值得注意的是 `unnecessary_type_name_in_constructor` ，这个 lint 会认为：

```dart
class C {
  C();
  C.name();
}
```

应该改成：

```dart
class C {
  new();
  new name();
}
```

官方文档甚至直接把旧写法标成 BAD、新写法标成 GOOD，也就是所以从长期趋势看，`new()` constructor declaration 大概率会慢慢成为 Dart 官方推荐风格，**所以你不要觉得这个只是加了一个新语法，实际上这很可能是一次断代的开始。**

另外还有两个升级到 Dart 3.13 时值得注意的小坑，因为 Primary Constructors 虽然官方强调没有增加新的运行时 semantics，但因为语法空间发生了变化，还是产生了少量 source compatibility 问题。

这里第一个是 `final parameter` ，过去 Dart 可能有人会写：

```dart
void foo(final int value) {
  ...
}
```

这里会把 `final` 当作「不允许 parameter 被重新赋值」的语法，而 Dart 3.13 以后 `final` 和 `var` 在 parameter 上会被赋予了 declaring parameter 的特殊含义，所以普通 function parameter 上使用它们大概率会成为 compile-time error。

> **这个坑是真的坑，如果团队希望继续限制 parameter assignment，官方建议使用 `parameter_assignments` lint。**

另一个比较冷门的情况是 `factory() {}` ， 以前如果你恰好定义了一个没有显式 return type、名字就叫 `factory` 的 method，Dart 3.13 的 parser 可能会把它理解成 factory constructor。

当然，普通 Flutter 项目里这两种情况一般都不算高频，但是还是需要注意下。

所以 Dart 3.13 实际上是另一次 null safety 变动的开始，估计再有两个版本， Dart 可能就会有全新的断档了，所以还是有必要关注下的。