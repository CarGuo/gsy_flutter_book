# Dart 3.15 新特性：this 终于支持类型提升了

这次 Dart 3.15 有个改动虽然不大，但我感觉算是解决了 Dart 类型系统里一个存在多年的不合理限制：

> **编译器明明已经知道当前对象是什么类型，但是就是不给开发者直接按照这个类型用它。**

![](/article-assets/3bee0d129f4f85c915475563.webp)

从 3.15 开始，`this`  终于可以像局部变量一样，根据  `is`  判断、空值检查之类条件，也可以自动改变自己的静态类型：

```dart
class Shape {
  void describe() {
    var self = this;
    if (self is Circle) {
      print('radius ${self.radius}');
    }
  }
}

class Circle extends Shape {
  final double radius;
  Circle(this.radius);
}
```

比如这里 `Shape` 是父类，`Circle` 是子类，子类独有一个 `radius` 属性，如果执行：

```dart
Circle(10).describe();
```

虽然 `describe()` 定义在 `Shape` 里面，但是实际执行它的对象是 `Circle`，所以进入方法的时候：

- `this` 的声明静态类型是 `Shape`
- `this` 在运行时指向的对象是 `Circle`
- 经过 `is Circle` 判断之后，编译器知道当前对象确实是 `Circle`

实际上以前的问题刚好就是出在第三点，以前的 Dart 就算知道判断结果，也不会修改 `this` 的静态类型，所以如果直接写，会变异错误：

```dart
class Shape {
  void describe() {
    if (this is Circle) {
      print(this.radius); // 旧版本：编译错误
    }
  }
}
```

> 编译器还是按照 `Shape` 查找 `radius`，自然就会报错，因为 `Shape` 根本没有这个字段。

而为了绕过限制，开发者必须先写  `var self = this`，然后让 `self` 参与类型提升，这是因为 Dart 以前只支持特定变量的类型提升，不支持直接提升 `this`。

而到了 Dart 3.15 ，现在这个代码终于可以正常工作了，在 `if` 成立的分支里，`this` 的静态类型可以由 `Shape` 提升为 `Circle`。

```dart
class Shape {
  void describe() {
    if (this is Circle) {
      print('radius $radius');
    }
  }
}
```

而且不只是 `this.radius` 可以访问，直接写 `radius` 也可以，因为类实例方法里，`radius` 这样的隐式实例成员访问，编译器也会考虑已经提升的 `this` 类型，也就是父类方法可以直接访问经过类型判断确认的子类成员，不用反复强制转换。

![](/article-assets/a9e424d10ebf5d7b0bea741b.webp)

> 其实就是变化的是编译器在对应代码分支中理解的静态类型，不是对象本身的实际类型。

另一个更实用的场景是 Nullable Extension，Dart 允许给可空类型添加 Extension，例如 `int?` ：

```dart
extension NullableInt on int? {
  bool get isEvenOrNull {
    final self = this;

    if (self == null) {
      return true;
    }

    return self.isEven;
  }
}
```

这里 `this` 的类型是 `int?`，也就是既可能是整数，也可能是 `null`，按照常规的空安全规则，检查 `self == null` 并提前返回以后，后面的 `self` 就会从 `int?` 提升成 `int`，可以直接使用 `isEven`。

> 但是以前直接检查 `this`，编译器不会完成这种提升，必须额外定义一个 `self`。

而现在 Dart 3.15 可以直接写：

```dart
extension NullableInt on int? {
  bool get isEvenOrNull {
    if (this == null) return true;

    return isEven;
  }
}

void main() {
  int? a = 4;
  int? b = 3;
  int? c;

  print(a.isEvenOrNull); // true
  print(b.isEvenOrNull); // false
  print(c.isEvenOrNull); // true
}
```

这里有两个变化：

- 首先，`if (this == null) return true` 之后，编译器知道剩余路径的 `this` 必然是非空 `int`
- 其次，`return isEven`  里面隐式使用的 `this` 也会享受到这次提升

最重要的是， **Extension 的接收对象完整参与 Dart 的空安全控制流分析， 以前局部变量能做到的事情，现在 Extension 里的 `this` 也能做了**。

类似专业的场景，这里的 `debugInfo` 写在父类 `PageState` 里面，但是能够通过 `this is Loaded` 和 `this is Failed` 直接访问子类的 `items`、`message` 属性：

```dart
sealed class PageState {
  const PageState();

  String get debugInfo {
    if (this is Loaded) {
      return '加载成功: ${items.length} 条数据';
    }

    if (this is Failed) {
      return '加载失败: $message';
    }

    return '加载中';
  }
}

class Loading extends PageState {
  const Loading();
}

class Loaded extends PageState {
  final List<String> items;
  const Loaded(this.items);
}

class Failed extends PageState {
  final String message;
  const Failed(this.message);
}
```

这种机制对 Flutter 中的状态基类、事件体系、插件扩展、基于继承的组件封装都挺有帮助的，尤其是存在大量类型分支判断的代码。

> 当然上面的例子只是为了演示类型提升，实际业务如果已经用 `sealed class`、`switch` 模式匹配，或者可以通过多态完成状态处理，一般其实不需要为了用这个新特性而改回一大堆 `if (this is Xxx)`。

至于为什么 Dart 到 3.15 才支持？这里其实涉及 Dart 类型系统长期以来对类型提升的谨慎，因为 Dart 的类型提升不是看到一个判断就无条件修改类型，实际上编译器还需要确认，被检查的值在后续代码中是否足够稳定，比如：

```dart
class Test {
  int? value;

  void run() {
    if (value != null) {
      // value 仍然可能变化
    }
  }
}
```

`value` 是一个可变成员，编译器不能因为检查过一次就永远假定它非空，对 Getter 来说，连续两次调用甚至可能返回不同结果。

而 `this` 本质上有个明显优势：**一个实例方法执行期间，当前接收对象不会突然变成另一个对象**，所以只要条件能够证明当前对象满足某个类型，编译器就可以在相应控制流中安全地使用这个信息。

这里和 Dart 3.2 的字段类型提升还是有区别的：

| 对比                             | Dart 3.2 | Dart 3.15 |
| -------------------------------- | -------- | --------- |
| 局部变量类型提升                 | 支持     | 支持      |
| 私有 `final` 字段提升            | 支持     | 支持      |
| `this is SubType` 后提升 `this`  | 不支持   | 支持      |
| Nullable Extension 中提升 `this` | 不支持   | 支持      |
| 隐式 `this` 成员访问使用提升结果 | 不支持   | 支持      |

等于是Dart 3.2 解决的是一部分稳定字段的类型提升问题，3.15 进一步补上了当前对象本身的类型提升。
