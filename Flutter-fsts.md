#  Flutter 开始支持   'dot-shorthands' 语法糖，实现自动类型推断

最近在 Dart  在  main 3.9 合并了一项名为 「dot-shorthands」 的语法糖提议，该提议主要是为了简化开发过程中的相关静态固定常量的写法，通过上下文类型推断简化枚举值和静态成员的访问：

![](https://img.cdn.guoshuyu.cn/image-20250505153733942.png)



简单来说，就是在之前你可能需要写 `SomeEnum.someValue` ，而在此之后，你只需要写  `.someValue`  ，简写语法不仅限于枚举值，还可用于访问静态 getter、构造函数和函数等：

```dart

///之前
SomeEnum getValue() => SomeEnum.someValue;


///之后
SomeEnum getValue() => .someValue;


```

如果回到 Flutter 场景下，那就是如下代码所示，不管是各类 `Flex` 控件的 `Axis` ，还是类似 `Offset` 等的 `Zero` ，以后都可以通过如 `.zero` 、`.center` 来实现简化写法：

![](https://img.cdn.guoshuyu.cn/image-20250505152033510.png)

如下图所示，通过上下文推断，最终 center 可以被正常识别并打印：

![](https://img.cdn.guoshuyu.cn/image-20250505153144191.png)

当然，既然说了是类型推断，那么 dynamic 肯定是不行，比如此时的 `test` 根本无法推断出其类型：

![](https://img.cdn.guoshuyu.cn/image-20250505155024600.png)

当然，如果在初始化时赋值，那么 test 的类型就可以被推断并确认：

![](https://img.cdn.guoshuyu.cn/image-20250505154858826.png)

不过如果你强行指定了 `dynamic` 类型肯定还是不行的：

![](https://img.cdn.guoshuyu.cn/image-20250505155209012.png)

另外，在内置的 `Color` 和 `Colors` 场景也不适用，这类场景下，因为它们的静态类型和本身的类型并不是同一个，所以也会出现无法简化的情况：

![](https://img.cdn.guoshuyu.cn/image-20250505153308849.png)

![](https://img.cdn.guoshuyu.cn/image-20250505153328083.png)

而根据 'dot-shorthands'  的语法糖效果，大致常用的简化支持可以如下代码所示：

```dart
void main() {
  print(getterArrow); 
  print(getterBody);  
  print(Methods().getterArrow);  
  print(Methods().getterBody);  
  print(Methods.getterArrowStatic);  
  print(Methods.getterBodyStatic); 
}

enum Color { red, blue, green }

Color get getterArrow => .red;
Color get getterBody { return .red; }

class Methods {
  static Color get getterArrowStatic => .red;
  static Color get getterBodyStatic { return .red; }
  Color get getterArrow => .red;
  Color get getterBody { return .red; } 
}
```

![](https://img.cdn.guoshuyu.cn/image-20250505153620935.png)

最后，因为目前该语法糖仅在 main 分支可用，需要 Dart 3.9 下在运行时执行 `flutter run --enable-experiment=dot-shorthands` 才能运行：

![](https://img.cdn.guoshuyu.cn/image-20250505153033429.png)

可以看到这是一个非常简单的语法糖，整体来说对于开发简化还是挺不错的，那么你会喜欢这个写法吗？







