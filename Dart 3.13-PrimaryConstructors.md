# Dart   大更新，新增语法糖和各种能力，真的难得了

## 私有命名参数

首先 Dart 3.12 新增加了 Private named parameters ，也就是私有命名参数，这个其实我们以前提过，就是在命名参数和私有字段结合使用时，形式化参数的初始化会有问题。

简单来说就是，以前 Dart 的类字段是私有的，命名参数又不能以下划线开头，所以不能直接写：

```dart
class User {
  final String _name;
  final int _age;

  // Dart 3.11 之前：不允许这样写
  User({required this._name, required this._age});
}
```

所以正常来说需要加一层公开参数，再用 initializer list 赋给私有字段：

```dart
class User {
  final String _name;
  final int _age;

  User({
    required String name,
    required int age,
  })  : _name = name,
        _age = age;
}
```

现在 Dart 3.12 开始可以直接写：

```dart
class User {
  final String _name;
  final int _age;

  User({
    required this._name,
    required this._age,
  });

  @override
  String toString() => 'User(name: $_name, age: $_age)';
}

void main() {
  final user = User(name: 'Asher', age: 18);
  print(user);
}
```

现在就是，**字段还是 `_name`、`_age`，但调用侧参数名不是 `_name`、`_age`，而是自动去掉下划线后的 `name`、`age`。** 

> 官方的文档也明确说，`this._x` 这种 private named parameter 会让调用者使用公开名 `x`。

这个改动很小，但还是很实用，尤其是 Flutter/Dart 里常见的不可变 model、DTO、配置类，以前经常因为私有字段需要手写 initializer list，现在可以直接保留私有字段，同时又让构造 API 是公开、干净的命名参数：

```dart
class ApiConfig {
  final String _baseUrl;
  final Duration _timeout;
  final Map<String, String> _headers;

  const ApiConfig({
    required this._baseUrl,
    this._timeout = const Duration(seconds: 15),
    this._headers = const {},
  });

  Uri endpoint(String path) => Uri.parse('$_baseUrl/$path');

  Map<String, String> get headers => Map.unmodifiable(_headers);
}

void main() {
  const config = ApiConfig(
    baseUrl: 'https://api.example.com',
    timeout: Duration(seconds: 10),
    headers: {'X-App': 'demo'},
  );

  print(config.endpoint('users'));
}
```

另外，新的 `prefer_initializing_formals` lint 会提示那些可以改成 private named parameters 的地方，可以通过 `dart fix --code=prefer_initializing_formals` 批量处理 ：

```
dart fix --dry-run --code=prefer_initializing_formals
dart fix --apply --code=prefer_initializing_formals
```

## Primary Constructors

**另外一个就是 Primary Constructors，虽然是实验性的，但 2026 Dart 终于新增了实用的语法糖特性 Primary Constructors**  ，简单来说就是：它允许你在 class header 里同时声明字段和构造函数，例如：

```dart name=point_classic.dart
// 传统写法：字段声明 + 构造函数 各写一遍
class Point {
  int x;
  int y;
  Point(this.x, this.y);
}
```

```dart name=point_primary.dart
// Primary Constructors 写法一行搞定
class Point(var int x, var int y);
```

怎么样？其实就是有一个很简单的语法糖，还有点烂大街的，但是 Dart 也是终于吃上了，这次核心特性主要有：

```dart name=modifiers_example.dart
// final 字段：不可变
class Person(final String name, final int age);

// var 字段：可变
class Counter(var int count);

// 混合：只有 x 成为字段，factor 只是普通参数
class Scaled(final int x, double factor) {
  final double scaled = x * factor; // factor 在初始化作用域内可用
}
```

另外还有「空类」可以用 `;` 代替 `{}` ：

```dart name=semicolon_body.dart
// 这两种写法完全等价
class A(final String name);
class A(final String name) {}
```

而如果是之前的 const， 那么就是如下命名构造函数 + `const` 的写法：

```dart name=named_const.dart
// 传统写法
class Point {
  final int x;
  final int y;
  const Point._(this.x, this.y);
}

// Primary Constructors 函数写法：const 放在类名前
class const Point._(final int x, final int y);
```

另外还有可选参数和命名参数，在 Primary Constructors  下会变成如下写法：

```dart name=optional_named.dart
// 带默认值的可选位置参数
class Point(var int x, [var int y = 0]);

// 命名参数（类型可从默认值推断）
class Config(var String host, {required var int port, var bool ssl = false});
```

继承和 super 的写法也有些变化：

```dart name=inheritance.dart
// 传统写法
class A {
  final int a;
  A(this.a);
}
class B extends A {
  B(super.a);
}

// Primary Constructors 函数写法
class A(final int a);
class B(super.a) extends A;
```

另外当需要初始化列表或函数体时，可以在 class 内用 `this` 声明：

```dart name=body_part.dart
// 传统写法
class DeltaPoint {
  final int x;
  final int y;
  DeltaPoint(this.x, int delta) : y = x + delta;
}

// Primary Constructors 函数写法 —— 使用 body part
class DeltaPoint(final int x, int delta) {
  final int y;
  this : y = x + delta; // 初始化列表放在这里
}

// 更简洁：利用"主初始化作用域"直接在字段声明处初始化
class DeltaPoint(final int x, int delta) {
  final int y = x + delta; // delta 在这个作用域内可见！
}
```

> 这里需要注意：**Primary Constructors  参数在 class 内非 `late` 字段的初始化表达式中是可见的，这是普通构造函数做不到的**。

最后就是断言，新的场景结合  `this` 声明：

```dart name=assertions.dart
// 传统写法
class Point {
  int x, y;
  Point(this.x, this.y) : assert(0 <= x && x <= y * y);
}

// Primary Constructors 函数写法
class Point(var int x, var int y) {
  this : assert(0 <= x && x <= y * y);
}
```

其实这个 `this` 还是有点意思的，因为现在  Primary Constructors  现在引入了 declaring parameter （用 `var`/`final` 标记），那 `this.xxx` 这种旧语法在 Primary Constructors 函数里还能用吗？

实际上  `this.xxx` 在所有构造函数中的语义还是一样的，实际上规范里声明参数 `var T p` 在语义上等价于把它替换成 `this.p`，并在 class 内添加字段声明 `T p;` 或 `final T p;`。

所以这两种写法在 Primary Constructors 函数中都是合法且语义明确的：

```dart name=this_field_in_primary.dart
// 用 var/final（声明参数）—— 同时声明字段
class A(final int x, var String name);

// 用 this.field（字段形参）—— 字段已在类体中声明，构造函数只赋值
class B(this.x) {
  late int x; // 字段单独声明（例如需要 late 修饰符时）
  external double d;
}
```

那么这个语法好处就很明显了，比如数据类：

```dart name=data_class.dart
// 传统写法（11 行）
class User {
  final String id;
  final String name;
  final String email;
  final int age;
  User({required this.id, required this.name, required this.email, required this.age});
}

// Primary Constructors 函数（1 行）
class User({required final String id, required final String name, required final String email, required final int age});
```

带计算字段的类（利用主初始化作用域）：

```dart name=computed_field.dart
class Rectangle(final double width, final double height) {
  final double area = width * height;         // 直接用构造参数！
  final double perimeter = 2 * (width + height);
}
```

甚至 extension type：

```dart name=extension_type.dart
extension type const Meters(double value);
extension type const UserId(int id);

// 使用
final m = Meters(3.14);
final uid = UserId(42);
```

跟典型的例子是：

```dart name=verbose_before.dart
// 传统写法
class E extends A {
  LongTypeExpression x1;
  LongTypeExpression x2;
  LongTypeExpression x3;
  LongTypeExpression x4;
  LongTypeExpression x5;
  LongTypeExpression x6;
  LongTypeExpression x7;
  LongTypeExpression x8;
  late int y;
  int z;
  final List<String> w;

  E({
    required this.x1, required this.x2, required this.x3, required this.x4,
    required this.x5, required this.x6, required this.x7, required this.x8,
    required this.y,
  })  : z = y + 1,
        w = const <Never>[],
        super('Something') {
    // 构造函数体...
  }
}
```

```dart name=concise_after.dart
// Primary Constructors 函数写法
class E({
  required var LongTypeExpression x1,
  required var LongTypeExpression x2,
  required var LongTypeExpression x3,
  required var LongTypeExpression x4,
  required var LongTypeExpression x5,
  required var LongTypeExpression x6,
  required var LongTypeExpression x7,
  required var LongTypeExpression x8,
  required this.y,   // y 需要 late，单独声明
}) extends A {
  late int y;
  int z = y + 1;               // 直接写在字段声明处！
  final List<String> w = const <Never>[];

  this : super('Something') {
    // 构造函数体...
  }
}
```

可以看到，虽然这个语法并不复杂，但是整体实用性还是挺不错的，只是来的有点晚，最后总结可见：

| 特性                                   | 说明                                                    |
| -------------------------------------- | ------------------------------------------------------- |
| **声明参数** `var`/`final`             | 同时声明字段 + 构造函数参数，核心新语法                 |
| **`this.field` 兼容**                  | 在Primary Constructors 函数中与辅助构造函数语义完全相同 |
| **`;` 空类体**                         | 语法糖，等价于 `{}`                                     |
| **`const` 位置**                       | 写在类名前：`class const Foo(...)`                      |
| **Body Part `this:`**                  | 在类体内补充初始化列表/函数体                           |
| **主初始化作用域**                     | 参数在非 `late` 字段初始化表达式中可见                  |
| **限制**                               | 不能有其他非重定向生成式构造函数                        |
| **"Convert to a declaring parameter"** | 已在 `analysis_server` 中实现，可批量重构整个文件       |

## Git Large File Storage

另外一个就是终于支持   Git Large File Storage (LFS) ，这个提了好多年，终于终于适配了，从 Dart 3.12 开始， `dart pub` 原生支持使用 Git 大文件存储 (LFS) 的 Git 依赖 ：

```yaml
dependencies:
  kittens:
    git: https://github.com/munificent/kittens.git
```

这样，对于直接在 Git 仓库里用对大型资产、数据模型或二进制文件进行版本控制的团队来说，现在拉依赖可以快很多，管理也更合理，之前接 unity lib 的时候，每次更新和拉取的痛苦啊，等了这么久，终于来了 LFS 。

## Agentic Hot Reload

最有一个有趣的就是  Agentic Hot Reload，通过使用 Dart MCP 服务器，现在 AI 可以 Hot Reload，在后台 Dart Tooling Daemon 会自动通过 MCP 服务器运行的 CLI 命令公开连接详细信息。

也就是，你的 AI 知道应该 Hot Reload 哪个项目，可以直接找到正在 Debug 的项目进行修改后和 Hot Reload。

![](https://img.cdn.guoshuyu.cn/ezgif-18d28986d0f96071.gif)

# 最后

这也是 Dart 近期比较有意思的更新了，整体来说虽然中规中矩，但是还是可以的，配合 Flutter 3.44 ，也算是一个整体的大更新。