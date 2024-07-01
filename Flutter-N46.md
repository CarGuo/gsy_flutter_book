# Flutter 小技巧之为什么推荐 Widget 使用 const 

今天收到这个问题，本来想着简单回复下，但是感觉这个话题又可以稍微展开讲讲，干脆就整理成一篇简单的科普，这样也能更方便清晰地回答这个问题。

![](http://img.cdn.guoshuyu.cn/20240627_N46/image1.png)

聊这个问题之前，我们需要把一个“老生常谈”的概念拿出来说，那就是：**Flutter 里 Widget 是不可变的，它不是真正的 View，Widget 只是一个「配置文件」的作用**。

后面只有基于这个概念，结合 const 的「深度不变性」 ，才能更全面理解为什么 Flutter 中推荐 Widget 使用 const 。

# Dart 里的 final & const

我们先简单过一遍 Dart 里的 final 和 const 的区别，要解答开头那个问题，只讲 const 明显是不够，在 Dart 里：

- final ：变量只能赋值一次，值在**运行时**确定

- const：变量必须是编译时常量，值在**编译时**已知

虽然都是「不可变」声明，但是对于 Dart 来说，final 和 const 最大的区别就在于一个是运行时确定，一个是编译时确定。

## final

针对 final ， final 虽然也不可变 ，但是它的值可以在运行时确定，同时它还允许延迟初始化(late)，如下代码所示：

- 变量 `a ` 可以是 `late final`
- `result` 的数可以是通过 `doSomeThing` 返回

```dart
late final String a;

void runResult() {
 final int result = doSomeThing(); 
} 
```

也就是 final 可以在运行时赋值，之后就不可以改变，类似场景就可以对应在 Widget 的构造函数上，通过 final 关键字创建不可变的实例变量，这些变量在构造函数级别初始化，并且对于每个类实例都是唯一的：**因为 Flutter 里 Widget 是不可变的，所以对于 Widget 来说，它内部的变量也应该是不可变**。 

```dart
class MyHomePage extends StatelessWidget {
  MyHomePage({super.key, this.title});
  final String? title;
}
```

## const

const 属于编译时不可变声明，可以理解为它是比 final 更高级的 「深度不变」，也就是编译时就确定了它的值，所以它会有更好的性能优势，例如：

- 作为编译时常量的， const 变量在编译时已知，因此它在编译期间只会被“评估”一次，这意味着 Dart 编译器可以对它们进行优化，从而节省内存并缩短需要的启动时间
- 当 const 变量在不同位置使用时，Dart 编译器只会给它分配一次空间，并且该值将在引用它的其他位置重复使用。

从这个角度理解，**const 确实可以一定程度提高性能和节约内存** ，再举个典型例子解释下 「深度不变」，如下代码所示：

> 可以看到通过  const 声明的  list， 它内部的 item 也是在编译时确定，并且是不允许被修改，不仅列表本身是一个编译时常量，它内部每个元素也是编译时常量。

```dart
const List<int> list = [0,0,0,0,0,0];

list[2] = 3;
```

![](http://img.cdn.guoshuyu.cn/20240627_N46/image2.png)

而对于 class 而言，const 声明的构造函数，会被要求内部变量需要使用 final 声明，从而确保对象是可传递的不可变的，这样就可以保证静态数据的完整，并且对象一旦设置就无法被篡改。

```dart
class Test {
 final int a;
 const Test(this.a);
}

void runTest() {
 const Test test = Test(0);
 test.a = 100;  /// error
} 
```

这个看起来是不是很眼熟？对，没错，就是 Flutter 里的 Widget，当 Widget 的构造函数是 const 的时候，它内部的变量都需要时 final ，不然就会在编译时报错。

```dart
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, this.title});
  final String? title;
}
```

> 如果没有 const ，默认规则下只会是警告：*This class (or a class that this class inherits from) is marked as '@immutable', but one or more of its instance fields aren't final* 。

另外，const 声明的构造函数，对于 class 来说也会在编译时优化，如下代码所示，可以看到它们都在编译期得到了优化：

- test 1 和 test 2 的 hashCode 是一样的
- test 3 和 test 4 的 hashCode 是一样的

```dart
  class Test {
    final int a;
    final int b;

    const Test(this.a, this.b);
  }

  void runTest() {
    const Test test1 = Test(0, 0);
    print("test1 hash code is: ${test1.hashCode}");
    const Test test2 = Test(0, 0);
    print("test2 hash code is: ${test2.hashCode}");
    const Test test3 = Test(1, 1);
    print("test3 hash code is: ${test3.hashCode}");
    const Test test4 = Test(1, 1);
    print("test4 hash code is: ${test4.hashCode}");
    const Test test5 = Test(2, 2);
    print("test5 hash code is: ${test5.hashCode}");
  }
```

![](http://img.cdn.guoshuyu.cn/20240627_N46/image3.png)



# Flutter

那么回到最初的问题，因为 Flutter 里的 Widget 不是真正的 View ，它只是个配置文件，背后是 Element 和 RenderObject 实体在工作，所以对于「不可变」的 Widget 来说，const 去声明一个「配置文件」做优化，明显可以提高性能和减少内存占用。

至于为什么说   Widget 不是真正的 View ， 详细的可以看我以前的文章，这里简单展示一个我经常提到的例子，如下代码所示，`textUseAll` 如果是一个真正的 View ，它是不能同时被多个地方添加，从这个例子可以更直观体现 Widget 是配置信息的作用。

![](http://img.cdn.guoshuyu.cn/20240627_N46/image4.png)

对于 Flutter 来说，**Flutter 会严重依赖 Widget 树的 「配置信息」来表示 UI，在 rebuild 期间遇到标记为const 的 Widget 时，Flutter 会将其识别为预构建且不可变的对象** ，这个情况下， Flutter 可以重复使用现有对象，而不必创建新对象，这种重复使用可避免不必要的计算和对象分配。

> 同时前面提到过，const 在编译时会执行优化，这些优化包括前面提到的预分配内存和常量折叠，这意味着在运行时可以更快地创建对象并减少垃圾回收触发。

另外，对于 Widget Tree 来说，const 可以确保只有当它们的引用实际发生变化时才会 rebuild，进而减少了不必要的 Widget 创建和重构。

所以，是不是无用知识又增长了？