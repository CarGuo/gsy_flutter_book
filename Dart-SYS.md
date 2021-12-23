
> 原文链接： https://recipes.tst.sh/docs/faq/type-system.html 

## 什么是类型？

类型是用于描述实例接口的节点，如下示例和注释所示：

```dart

// Foo is now an interface type.
class Foo {}

// FooFn is now an alias of the `Foo Function()` type.
typedef FooFn = Foo Function();

// You can now create interface types of Bar with any subtype of Foo as the type argument.
class Bar<T extends Foo> {
  // T is a subtype of Foo in this context.
}
```

在最顶层的级别里，只有少数几种类型：

- `dynamic`
- `void`
- `interface` 类型
- `function` 类型
- `parameter` 类型

最常见的是 `interface` 类型，它描述了类和决定了类型参数。

`dart:core` 包含了一堆具有特殊类型属性的类，下面将介绍这些类。

> https://github.com/dart-lang/sdk/blob/master/pkg/kernel/binary.md

## 实例

在对象的整个生命周期中，它只有一个类型，该类型在构造时确定并且永远不能更改：

```dart
int x = 2;
num y = x;
print(x is int); // true
print(y is int); // true
int z = y as int; // works
```

用于声明变量类型的只是 `interface` ，它可以存储任何实现了该  `interface` 的子类型。

## 方法

当在实例上调用方法时，创建实例的类型始终决定了该方法的实现，例如：


```dart
class Foo {
  void hi() => print("i am foo");
}

class Bar implements Foo {
  void hi() => print("i am bar");
}

void callHi(Foo foo) => foo.hi();

void main() {
  callHi(Bar()); // prints "i am bar"
}

```

如上述例子所示，`Bar` 实现的 `hi` 将始终覆盖来自其实例的调用结果，而不管它在什么上下文中。

**在 Dart 代码所有可见的类型，都是 `Object` 的子类型，并继承其默认实现的 `interface`** 。

**Dart 是强类型的语言**，这意味着编译器可以在运行时，对值的类型做出强有力的保证。

当然，**强类型并不意味着方法一定存在**，如果调用时缺少方法，Dart 会调用默认情况下调用 `noSuchMethod` 会抛出 `NoSuchMethodError`。


```dart
(42 as dynamic).foo(); // throws NoSuchMethodError
```

实例上在 Dart 里的所有字段访问，都是通过对 `setter` 和 `getter` 方法的调用来完成，当在类中声明一个字段时，它隐式声明了读取和写入内部变量的 `setter` 和 `getter `方法。

```dart
class Foo {
  // This declares both set:a and get:a
  int a;
}

class Bar extends Foo {
  // This overrides get:a without touching set:a
  int get a => super.a * 2; 
}

main() {
  var foo = Bar();
  foo.a = 2;
  print(foo.a); // prints 4
}
```

## 子类型

变量可以包含不是其声明类型的实际子类型的值，除了 `null` ：

```dart
int x;
print(x is int); // false
```

这段代码会打印 `false` ，**因为 `is` 运算符是子类型检查，而不是可分配性检查**。

而另一方面，**`as` 操作会进行可分配性检查**：

```dart
int x;
print(x as int); // null, works
```

这是因为，在以下情况下 `x` 可以是 `T` 的子类型：

- `x` 的运行时类型是 `T `的子类型。
- `x` 为空并且 `T` 可以为空。


## Null vs void vs dynamic vs Object

`Null` 对象是特殊的，当不是 `get:hashCode`，`get:runtimeType` 和 `operator==` 的方法被调用，它抛出一个格式为 `NoSuchMethodError` 的异常。

`dynamic` 和 `void` 类型都是 `Object` 的有效别名，但它们改变了一些可见的方法：

- 使用 `Object`，只能方法 `Object` 的接口（如普通类），例如 `hashCode`。
- 使用 `void`，可以存储和转换，但不能访问任何方法。
- 使用 `dynamic`，可以访问任何方法，并使用任何参数调用它，这些返回值也被视为 `dynamic` 。

## 闭包

提取是将实例方法转换为闭包的过程，这通常称为 `tear-off`。

> 如果在一个对象上调用函数并省略了括号， Dart 称之为 `”tear-off”` ：一个和函数使用同样参数的闭包，当调用闭包的时候会执行其中的函数，比如：`names.forEach(print);` 等同于 `names.forEach((name){print(name);});`


可以通过调用名称为 `getter` 的方法来提取方法：

```dart
typedef ToStringFn = String Function();
ToStringFn getToString(Object x) => x.toString;
```

在这个例子中，我们从一个任意对象中 `x `中提取了 `toString`方法，通过闭包，就可以像调用上的常规实例一样调用 `x`。

```dart
typedef ToStringFn = String Function();
ToStringFn getToString(Object x) => x.toString;
main() {
  var foo = 111;
  var a = getToString(foo);
  print(a());
}
```


实际上，上面的代码与以下代码相同，除了前者效率更高一些。

```dart
typedef ToStringFn = String Function();
ToStringFn getToString(Object x) => () => x.toString();
```

`Functions` 非常特殊，它们实际上可以指两个不同的东西：

- 用参数和返回类型声明的函数类型，即 `void Function() foo;`。
- `Function` 类作为接口类型，任何方法的父类。

`Function` 类型类似于泛型接口类型，但可以描述参数名称和类型。

所有函数类型都是 `Function` 的子类型，无论它们的返回类型和参数如何：

```dart
print(print is Function); // true
```

这里做一个有趣的实验，如下代码所示：


```dart

void main() {
  void foo() {}
  int bar([int aaa]) {}
  Null biz({int aaa}) {}
  int baz(int aa, {int aaa}) {}
  
  print(foo is void Function());
  print(bar is void Function());
  print(biz is void Function());
  print(baz is void Function());
}
```

打印结果是 

```
true
true
true
false
```

这是因为 Dart 类型系统比较灵活，**只要函数采用相同位置的参数，并具有兼容的返回类型，它就是有效的函数子类型**，所以除了 `baz` 打印 `false` 之外所有的结果都是 `true`。

换个方式，如下代码所示：


```
void main() {
  int foo({int a}) {}
  int bar({int a, int b}) {}
  
  print(foo is int Function());
  print(foo is int Function({int a}));
  print(bar is int Function({int a}));
  print(bar is int Function({int b}));
  print(bar is int Function({int b, int c}));
}
```

输出的结果会是：


```
true
true
true
true
false
```

**因为当函数具有命名参数的子集时，代码检查函数是否具有有效的子类型**，所以除最后一个之外的所有函数都打印 `true`。

如果最后一个修改为 `print(bar is int Function({int b, int a}));` ，也会打印出 `true` 。



## 可调用对象

类是可以被调用的，例如：

```
class Foo {
  void call() => print('hi');
}

void main() {
  Foo()(); // prints "hi"
}

```

这实际上是一种欺骗，`Foo` 实例本身实际上是不可调用的，出现这样的结果是因为 `call` 隐式提取了该方法。

例如：

```dart
void callFoo(void Function() x) {
  print(x is Foo); // false
  print(x is Function); // true
  x();
}

void main() {
  var x = Foo();
  print(x is Foo); // true
  print(x is Function); // false
  callFoo(x);
}
```

在这里 `x` 似乎是在 `Foo` 和 `Function` 之间转变，这是因为 `x` 被传递到 `callFoo`  之前，被隐式转换成一个 `Closure`。