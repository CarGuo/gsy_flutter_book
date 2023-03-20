# Flutter - Dart 3α  新特性 Record 和 Patterns 的提前预览讲解

> 由于 Dart 3 还处于 alpha ，某些细节可能还会有所变化，但是总体设定和大部分细节应该不会变太多，大家可以提前尝鲜。
>
> 更多更新也可以关注官方的  [records-feature-specification](https://github.com/dart-lang/language/blob/master/accepted/future-releases/records/records-feature-specification.md) 和 [feature-specification.md](https://github.com/dart-lang/language/blob/master/accepted/future-releases/0546-patterns/feature-specification.md#patterns) 相关进展。

Record 和 Patterns 作为 Dart 3 的 Big Things ，无疑是 Flutter 和 Dart 开发者都十分关注的新特性。

简单来说，**Records 支持高效简洁地创建匿名复合值，不需要再声明一个类来保存，而在 Records 组合数据的地方，Patterns 可以将复合数据分解为其组成部分**。

![](http://img.cdn.guoshuyu.cn/20230126_FF/image14.png)

众所周知 Dart 语言本身一直都 “相对保守”，而这次针对 Records 和 Patterns 的支持却很“彻底”，属于全能力的模式匹配，能递归匹配，有 condition guards ，对于 Flutter 开发者来说无疑是生产力的大幅提升。

> 当然，也可能是 Bug 的大幅度提升。

# Records

如下方代码所示，**Records 属于是一种匿名的不可变聚合类型**  ，类似于 Map 和 List ，但是 Records 固定大小，组合更灵活，并且支持不同类型存储。

```dart
var record = (1, a: 2, 3, b: 4);
```

> 除了大小固定之外，Records 和 Map 和 List 最大不同就是它支持不同类型聚合存储，也就是你不用再写 `List<Object>` 之类的代码来承载数据多样性。

当然，可能你会觉得，这和我定义一个 Class 来承载不同数据对象有什么区别？其实还是有很大区别的：

- 定义了类，也就是说你的数据集合需要和特定类耦合
- 使用 Records  就不必声明对应类型，**只要具有相同字段集的记录， Dart 就会认为它们是相同类型**（这个后面会介绍）

> 所以从上面可以看到， Records 的出现对于Dart 来说是很重要的能力拓展，尽管对于其他语言这也许并不是什么新鲜特性。

## 简单介绍

对于 Records ，我们拓展前面的代码，通过打印对应的数值，可以清晰看到 Records 内数值的获取方式：**通过 `$` 位置字段或者命名字段的方式获取数据**。

```dart
  var record = (1, a: 2, 3, b: 4);
  print(record.$1); // Print "1"
  print(record.a);  // Print "2"
  print(record.$2); // Print "3"
  print(record.b);  // Print "4"
```

> 在 Records 的变更记录里：**现在 Records 开始位置记录是从 `$1` 开始，而不是 `$0`** ，但是 DartPad 上你可能还会遇到需要从  `$0`  开始。

而定义 Records 是通过 `()`  和 "`,`"  实现，为什么要有  "`,`"   ，如下代码所示：

```dart
  var num = (123);      // num
  var records = (123,); // record
```

- 如果没有 "`,`"  ，那么 `(123)` 就是一个 num 类型的对象
- 有  "`,`"  之后 `(123,)`  才会被识别为是一个 Records 类型

所以，作为一个集合类型，Records 也是可以用来声明变量，比如：

```dart
  (bool, num, {int n, String s}) records;
  records = (false, 1, n: 12, s : "xxx");
  print(records); 
```

当然，如果你如下代码一样赋值就会收获一个  ` can't be assigned to a variable of type`  的错误，因为它们类型不相同，Records 是固定大小的：

```dart
  records = (false, 1,  s : "xxx2");
  records = (false, 1,  n : 12);
```

而 Records 上的命名字段主要在于可以如下这样赋值：

```dart
  records = (false, 1, s : "xxx2",  n : 12);
  records = (s : "xxx2",  n : 12, false, 1, );
  print(records); 
```

最后，在 Records 的定义里需要遵循以下规则：

- 同一命名字段名称只能出现一次，这个不难理解，比如上面代码你不可能定义两个 `s` 。
- `(,)`  这样的表达式是不允许的，但是 `()`  可以是没有任何字段的常量空 Records
- 有参数但是只有 `()`  没有 "`,`"  也不是 Records ，如 `(6)`
- 命令为 `hashCode`、  `runtimeType`、  `noSuchMethod`, 、`toString` 的字段是不允许的
- 以下划线开头的命令字段是不允许的
- 与位置字段名称冲突的命令字段，比如  *`('pos', $1: 'named')`* 这样是不行的，但是 `($1: 'records')` 这样可以

知道了 Records 的大概逻辑之后，这里面有个有趣的设定，比如：

```dart
   var t = (int, String);
   print(t);                 
   print(t.$0.runtimeType);    
   print(t.$1.runtimeType); 
```

通过打印你会发现 `t` 里面的 `$0` 和 `$1`  是  `_Type` 类型，也就是如果后面再写 `   t = (1, "fff");`   ，就会收获这样的错误

![](http://img.cdn.guoshuyu.cn/20230131_D3/image1.png)

> 其实这个例子没什么实际意义，注意强调一下  `var t = (int, String);` 和  `(int, String) t`  的区别。

最后简单介绍下 Records  的类型关系：

- **`Record`  是 `Object` 、 `dynamic`  的子类和 `Never` 的父类**
- **所有的 Records 都是  `Record`   的子类和  `Never`  的父类**

如果拓展到 Records 之间进行比较，假设有 A、B 两个都是 Records 对象，而 **B 在和 A 具有相同 shape 的前提下，所有的字段都是 A 里字段的子类**，那么 Records B 可以认为是 Records A 的子类。

![](http://img.cdn.guoshuyu.cn/20230131_D3/image2.png)



## 进阶探索

前面我们介绍过，**在 Records 里，只要具有相同字段集的记录， Dart 就会认为它们是相同类型**，这怎么理解呢？

首先需要确定的是，**Records 类型里命名字段的顺序并不重要**，就是 `{int a, int b}` 与`{int b, int a} ` 的类型系统和 runtime 会完全相同。

> 另外位置字段不仅仅是名为 `$1` 、`$2` 这样的字段语法糖，`('a', 'b')` 和 `($1: 'a', $2: 'b') ` 从外部看是具有相同的 *members* ，只是具有不同的 *shapes*。

例如  `(1.2, name: 's', true, count: 3) `  的签名大概会是这样：

```dart
class extends Record {
  double get $1;
  String get name;
  bool get $2;
  int get count;
}
```

> **Records 里每个字段都有 getter ，并且字段是不可变的，所以不会又 Setter**。

所以由于 Records 本身数据复杂性等原因，所以设定上 Records 的标识就是它的内容，**也就是具有相同 shape 和字段的两条 Records 是相等的值**。

```dart
print((a: 1, b: 2) == (b: 2, a: 1)); // true
```

当然，如果是以下这种情况，因为位置参数顺序不一样，所以它们并不相等，因为 shape 不同，会输出 `false`。

```dart
print((true, 2, a: 1, b: 2,) == (2, true, b: 2, a: 1)); // false
```

同时，**Records 运行时的类型由其字段的运行时的类型确定**，例如：

```dart
(num, Object) pair = (1, 2.3);
print(pair is (int, double)); // "true".
```

这里**运行时 `pair`是 `(int, double)`，不是`(num, Object)`** ，虽然官方文档是这么提供的，但是 Dartpad 上验证目前却很有趣，大家可以自行体会：

![](http://img.cdn.guoshuyu.cn/20230131_D3/image3.png)

![](http://img.cdn.guoshuyu.cn/20230131_D3/image4.png)

我们再看个例子，如下代码所示， Records 是可以作为用作 Map 里的 key 值，因为它们的 shape 和 value 相等，所以可以提取出 Map 里的值。

```dart
  var map = {};
	map[(1, "aa")] = "value";
  print(map[(1, "aa")]); //输出 "value"
```

如果我们定义一个  `newClass` ， 如下代码所示，可以预料到输出结果会是 `null` ，因为两个  `newClass`  并不相等。

```dart

  class newClass  {

  }

  var map = {};
  map[(1, new newClass())] = "value";
  print(map[(1, new newClass())]); //输出 "null"
  
```

但是如果给 `newClass` 的 `==` 和 `hashCode  `进行` override `，就可以又看到输出 `"value"` 的结果。

```dart
class newClass  {
  
  @override
  bool operator ==(Object other) {
    return true;
  }

  @override
  int get hashCode => 1111111;
  
}
```

所以到这里，你应该就理解了“**只要具有相同字段集的记录， Dart 就会认为它们是相同类型**”这句话的含义。

最后再介绍一个 Runtime 时的特性， **Records 中的字段是从左到右计算的**，即使后续实现选择了重新排序命名字段也是如此，例如：

```dart
int say(int i) {
  print(i);
  return i;
}

var x = (a: say(1), b: say(2));
var y = (b: say(3), a: say(4));

```

上门结果一定是打印 *“1”、“2” /  “3”、“4”* ， 就算是下面代码的排列，也是输出  *“0”、“1”、“2” /  “3”、“4”、“5”*  。

```dart
var x = (say(0), a: say(1), b: say(2));
var y = (b: say(3), a: say(4), say(5));
```



## Records 带来的语法歧义

因为 Dart 3 的 Records 是在以前版本的基础上升级的，那么一些语法兼容就是必不可少的，这里整理一下目前官方罗列出来的常见调整。

### try/on

首先是 `try/on` 相关语法， 如果按照以前的设定，第二行的 `on` 应该是被识别为一个局部函数，但是在增加了 Records 之后，现在它是可以匹配的 `on` Records 类型。

```dart
  void recordTryOn() {
    try {
    } on String {
    } 
    
    on(int, String) {
    }
  }
```

> 这里声明的类型其实没什么意义，只是为了形象展示对比

鉴于消除歧义的目的，如果在早于 Records 支持版本里，`on  `关键字后带  `()`  这样的类型，将直接被语法解析为 Records 类型，提示为语法错误，因为该 Dart 版本不支持 Records 类型。

![](http://img.cdn.guoshuyu.cn/20230131_D3/image5.png)



### metadata 注解

如下代码所示，因为多了 Records 之后，注解的理解上可能就会多了一些语法歧义：

```dart
@metadata (a, b) function() {}
```

如果不约定好理解，这可能是：

-  `@metadata(a, b)` 与没有返回类型的函数声明关联的metadata 注解
-  `@metadata`与返回类型为 Records 类型的函数关联的metadata 注解 `(a, b)`

所以这里主要通过空格来约定，尽管这样很容易出现纰漏：

```dart
@metadata(a, b) function() {}

@metadata (a, b) function() {}
```

- 前者由于 `@metadata` 之后没有空格，所以表示为 `(a, b)` 的 metadata 注解
- 前者由于有空格，所以表示为 Records 返回类型

它们的不同之处可以参考下面的两种类型：

```dart
//  Records 和 metadata 是一起作用在 a 
@metadata(x, y) a;
@metadata<T>(x, y) a;
@metadata <T>(x, y) a;

//  Records 是直接作用在 a ，和 metadata 无关
@metadata (x, y) a;

@metadata
(x, y) a;

@metadata/* comment */(x, y) a;

@metadata // Comment.
(x,) a;
```

举个例子，比如下面这种情况 `@TestMeta(1, "2")` 没有空格，所以不会有语法错误

```dart
@TestMeta(1, "2")
class C {}


class TestMeta {
  final String message;
  final num code;

  const TestMeta(this.code, this.message);

  @override
  String toString() => "feature:  $code, $message";
}
```

但是如果是 `@TestMeta (1, "2")` ，就会有 `Annotations can't have spaces or comments before the parenthesis.` 这样的错误提示。

```dart
@TestMeta (1, "2") //Error
class C {}
```

> 所以有无空格对于 metadata 注解来说将会变得完全不一样，可能这对一些第三方插件的适配使用上会有一定 breaking change。

### toString

在 Debug 版本中，Records 的 `toString()` 方法会通过调用每个字段的 `toString()`值，并在其前面加上字段名称，后续是否添加 `: ` 字符取决于字段是否为命名字段，最终会将每个字段转换为字符串。

> 看下面例子可能会更形象。

每个字段会利用 `, ` 作为分隔符连接起来，并返回用括号括起来的结果，例如：

```
print((1, 2, 3).toString()); // "(1, 2, 3)".
print((a: 'str', 'int').toString()); // "(a: str, int)".
```

在 **Debug 版本中，命名字段出现的顺序以及它们如何与位置字段进行排列是不确定的，只有位置字段必须按位置顺序出现**。

> 所以 toString 内部实现可以自由地为命名字段选择规范顺序，而与创建记录的顺序无关。

而在发布或优化构建中，`toString()` 行为是更不确定的， 所以可能会有选择地丢弃命名字段的全名以减少代码大小等操作。

> **所以用户最好只将 Records 的 `toString()` 用于调试**，强烈建议不要解析调用结果 `toString()` 或依赖它来获得某些逻辑判断，避免产生歧义。

# Patterns

如果只是单纯 Records 可能还看不到巨大的价值，但是如果配合上 Patterns ，那开发效率就可以得到进一步提升，**其中最值得关注的就是多个返回值的支持**。

![](http://img.cdn.guoshuyu.cn/20230131_D3/image6.png)

## 简单介绍

**关于 Patterns 这里不会有太长的篇幅**，首先目前 Patterns 在 DartPad 上还是 disabled 的状态，其次 Patterns 的复杂度和带来的语法歧义问题实在太多，它目前还具有太多未确定性。

![](http://img.cdn.guoshuyu.cn/20230131_D3/image7.png)

> 从[提案](https://github.com/dart-lang/language/blob/master/accepted/future-releases/0546-patterns/feature-specification.md#summary)上看，未来感觉也不会一次性所有能力全部发布。

### 多返回值

回到主题，我们知道，使用 Records 可以让我们的方法实现多个返回值，例如下面代码的实现

```dart
(double, double) geoCode(String city) {
  var lat = // Calculate...
  var long = // Calculate...

  return (lat, long); // Wrap in record and return.
}
```

但是当我们需要获取这些值的时候，就需要 **Patterns 的解构赋值**，例如：

```dart
var (lat, long) = geoCode('Aarhus');
print('Location lat:$lat, long:$long');
```

**当然 Patterns 下的解构赋值不只是针对 Records** ，例如对 `List`  或者 `Map` 也可以：

```dart
var list = [1, 2, 3];
var [a, b, c] = list;
print(a + b + c); // 6.

var map = {'first': 1, 'second': 2};
var {'first': a, 'second': b} = map;
print(a + b); // 3.
```

更近一步还可以解构并分配给现有变量：

```dart
var (a, b) = ('left', 'right');
(b, a) = (a, b); // Swap!
print('$a $b'); // Prints "right left".
```

> 有没有觉得代码变得难阅读了？哈哈哈哈

### 代数数据类型

就如 Flutter Forward 介绍那样，现在类层次结构基本上已经可以对代数数据类型进行建模，Patterns 下提供了新的模式匹配结构，例如代码可以变成这样：

```dart
///before
double calculateArea(Shape shape) {
  if (shape is Square) {
    return shape.length + shape.length;
  } else if (shape is Circle) {
    return math.pi * shape.radius * shape.radius;
  } else {
    throw ArgumentError("Unexpected shape.");
  }
}

//after 
double calculateArea(Shape shape) =>
  switch (shape) {
    Square(length: var l) => l * l,
    Circle(radius: var r) => math.pi * r * r
  };
```

> 甚至 `switch `都不需要添加 `case` 关键字，并且用上了后面会简单介绍的可变模式。

### Patterns

目前 Dart 上 Patterns 的设定还挺复杂，简单来说是：

> **通过一些简洁、可组合的符号，排列后确定一个对象是否符合条件，并从中解构出数据，然后仅当所有这些都为 true 时才执行代码**。

也就是你会看到一系列充满操作符的简短代码，如 `"||"`、 `" && "`、 `"=="`、 `"<"`、 `"as"`、 `"?"`、 `"_"`、`"[]"`、`"()"`、`"{}"`等的排列组合，并尝试逐个去理解它们，例如：

```dart
var isPrimary = switch (color) {
  Color.red || Color.yellow || Color.blue => true,
  _ => false
};
```

用  `"||" `可以在 switch 中让多个 case 共享一个主体，`"_"` 表示默认，甚至如下代码所示，你还可以在绑定 `s` 之后，多个共享一个 `when` 条件：

```dart
switch (shape) {
  case Square(size: var s) || Circle(size: var s) when s > 0:
    print('Non-empty symmetric shape');
  case Square() || Circle():
    print('Empty symmetric shape');
  default:
    print('Asymmetric shape');
}
```

这种写法可以大大优化 `switch` 的结构 ，如下所示可以看到，类似写法代码得到了很大程度的精简：

```dart
String asciiCharType(int char) {
  const space = 32;
  const zero = 48;
  const nine = 57;

  return switch (char) {
    < space => 'control',
    == space => 'space',
    > space && < zero => 'punctuation',
    >= zero && <= nine => 'digit'
    // Etc...
  }
}
```

当然，还有一些很奇葩的设定，比如利用 `?  `匹配非空值，很明显这样的写法很反直觉，最终是否这样落地还是要看社区讨论的结果：

```dart
String? maybeString = ...
switch (maybeString) {
  case var s?:
    // s has type non-nullable String here.
}
```

更进一步还有在解构的 position 赋值时通过 `!` 强制转为非空，还有在 switch 匹配时第一个列为 `'user'` 时 `name` 不为空。

```dart
(int?, int?) position = ...

// We know if we get here that the coordinates should be present:
var (x!, y!) = position;


List<String?> row = ...

// If the first column is 'user', we expect to have a name after it.
switch (row) {
  case ['user', var name!]:
    // name is a non-nullable string here.
}
```

如果搭配上 Records 就更难理解了，比如下代码，可变 pattern 将匹配值绑定到新变量，这里的 `var a  `和 `var b ` 是可变模式，最终分别绑定到 `1` 和 `2`  上。

```dart
switch ((1, 2)) {
  case (var a, var b): ...
}


switch (record) {
  case (int x, String s):
    print('First field is int $x and second is String $s.');
}
```

其实就类似于 Flutter Forword 介绍的能力，`case` 下可以做对应的绑定，如上 `switch (record)` 也是类似这种绑定。

![](http://img.cdn.guoshuyu.cn/20230131_D3/image6.png)

> 如果使用变量的名称是 `_`，那么它不绑定任何变量

更多的可能还有如 List、 Map 、 Records、 Object 等相关的 pattern 匹配等，**可以看到  Patterns 将很大程度改变 Dart 代码的编写和逻辑组织风格**：

```dart
var list = [1, 2, 3];
var [_, two, _] = list;


var [a, b, ...rest, c, d] = [1, 2, 3, 4, 5, 6, 7];
print('$a $b $rest $c $d'); // Prints "1 2 [3, 4, 5] 6 7".


// Variable:
var (untyped: untyped, typed: int typed) = ...
var (:untyped, :int typed) = ...

switch (obj) {
  case (untyped: var untyped, typed: int typed): ...
  case (:var untyped, :int typed): ...
}

// Null-check and null-assert:
switch (obj) {
  case (checked: var checked?, asserted: var asserted!): ...
  case (:var checked?, :var asserted!): ...
}

// Cast:
var (field: field as int) = ...
var (:field as int) = ...
  
  
class Rect {
  final double width, height;

  Rect(this.width, this.height);
}

display(Object obj) {
  switch (obj) {
    case Rect(width: var w, height: var h): print('Rect $w x $h');
    default: print(obj);
  }
}
```

> 从目前看来，**这会是一种自己写起来很爽，别人看起来可能很累的特性**，同时也可能会带来不少的 breaking change ，更多详细可见：[patterns-feature-specification](https://github.com/dart-lang/language/blob/master/accepted/future-releases/0546-patterns/feature-specification.md)

好了，关于 Patterns 的这里就不再继续展开，它落地会如何最终还不完全确定，但是从我的角度来看，它绝对会是一把双刃剑，希望 Patterns 到来的同时不会引入太多的 Bug。

# 最后

其实我相信大多数人可能都只关心 Records 和解构赋值，从而实现函数的多返回值能力，这对我们来说是最直观和最实用的。

至于 switch 如何匹配和 Patterns 如何精简代码结构，这都是后话了。

现在，或者你可以选择 Dart 3 尝尝鲜了～