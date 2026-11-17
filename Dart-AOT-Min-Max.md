# Flutter 下 AOT 一个你怎么都想不出来的 Bug ，JIT 正常的计算，在 AOT 居然算错了

最后有个 [dart-lang/sdk#64878](https://github.com/dart-lang/sdk/issues/64878) 的 Bug ，太抽象了，和我最近遇到的问题一样抽象，同一段合法的 Dart 数值计算代码，Debug 运行正常，AOT 编译后居然可能直接崩溃，或者不崩溃，但是直接算出来一个错误的结论。

比如下面这个例子

```dart
import 'dart:convert';
import 'dart:math';

num calculate(Map values) {
  final result = min(0.965, values['value']);
  return 0.035 + result;
}

void main() {
  print(calculate(jsonDecode('{"value":0}')));
}
```

正常情况下：

- `min(0.965, 0)` 应该返回 `0`。
- `0.035 + 0` 应该得到 `0.035`。

**但是 AOT 编译以后，程序竟然直接 SIGSEGV**，你没看错，直接就崩了。

而且第二个例子更离谱：

```dart
num calculate(Map values) {
  final result = max(0, values['value']);
  return result * 0.5;
}

void main() {
  print(calculate(jsonDecode('{"value":0.25}')));
}
```

同一份代码会两种执行结果：

- JIT 正常 0.125 ，符合预期

- AOT 居然是 2299087609772638200.0

那为什么第一个场景  `min()` 会崩溃？问题主要出在值的表示方式

在 Dart SDK 里的函数定义，这两个实现是：

```dart
external T min<T extends num>(T a, T b);
external T max<T extends num>(T a, T b);
```

然后这里有一个容易忽略的地方：`T extends num` ，也就是不是所有参数都会自动转换成 `double`，比如 `num` 可以是 `int`，也可以是 `double`。

而在 Dart VM 里的 min 实现里，相关实现大概是：

```c++
T min<T extends num>(T a, T b) {
  if (a > b) return b;
  if (a < b) return a;
  // NaN、正负零等特殊处理
  ...
}
```

比如 `min<num>(0.965, 0);` 比较之后会直接返回第二个参数 `0`，它可能是 `int`，这个行为没问题，但是问题发生在 AOT 编译器处理后面的计算的时候：

![](/article-assets/858a3bae6d59e288d5d7e9f6.webp)

这里最关键的是编译器 IR：

```dart
v74 <- phi(
  v18 T{<:X1?},
  v4 T{_Double},
  ...
) alive T{<:*}

v102 <- Unbox(v74 T{_Double}) double

v9 <- BinaryDoubleOp(+, v102, v104) double
```

大概意思就是：

- `phi` 是 SSA 中的分支合流节点，前面的不同执行路径，最终都要把计算结果交给它
- 但这个结果可能是 `int`，也可能是 `double`，所以不能简单认定它一定就是 `_Double`
- 后面的 `Unbox`  的时候，又直接按照 `_Double` 取值，准备执行浮点加法

也就是问题大概就在第 2 步到第 3 步之间：**编译器生成的代码使用了一个没有得到保证的类型假设**，然后到了 ARM64 汇编 `fldrd v2, [r0, #7]` 的时候，Dart VM 会把小整数（Smi）编码在带标签的机器字中，整数零的这种表示可以是 `0`。

但生成的汇编把这个值当成了指向 Double 对象的引用，然后尝试读取对象里的浮点数：

```
r0 = 0
读取位置 = r0 + 7
         = 0x7
```

这时候访问非法地址 `0x7`，直接就触发 SIGSEGV，其实就是：

> **这里不是数学计算出了一个非法数值，而是编译器把整数的表示当成了浮点对象的引用，最终生成了错误的内存读取指令。**

然后很有幸运，我也遇到了类似问题，但是不是 `min` ，还是 flutter 3.44.9 上面的，但是问题表现类似，就是编译器的“寄存器传参”（user_register_cc），然后传参的时候， Dart 在 AOT 的情况下，直接把一个 1.0 的默认值，直接当成地址读了，然后因为 1.0（高位刚好是 0x3ff00000）根本不是地址，所以就 Crash 了。

**所以这种问题太抽象了，而且更抽象的是，Dart 对 `min/max` 有专门的编译器优化**。

比如在 [call_specializer.cc](https://github.com/dart-lang/sdk/blob/main/runtime/vm/compiler/call_specializer.cc) 中，Dart 编译器有一个 `InlineMathMinMax`，专门处理 `min/max`，它会检查两个参数的类型：

- 如果都是 `double`，生成专门的浮点 `MathMinMaxInstr`
- 如果都是 `int`，在支持的 64 位目标上生成整数版本
- 如果不满足这些条件，就不能直接使用这条专门优化路径

但是 ARM64 后端又会针对整数和浮点分别生成不同指令，也就是开发者其实早就考虑过不同数值类型的优化问题，但问题在于：

```
min(0.965, values['value'])
```

这里 `values` 是没有指定泛型参数的 `Map`，同时 `values['value']` 的静态类型是 `dynamic`，而 `jsonDecode()` 对于 JSON 中的 `0` 会得到整数，而对于 `0.25` 会得到浮点数。

所以运行时有不同的值类型，**但编译阶段不能靠这个表达式就保证它一定是哪一种**，所以 Dart 的泛型实参也会根据调用上下文和参数推断，而显式写 `<num>` 会改变这种推断约束。

但是问题在于，还是没搞清楚，究竟哪里导致的这问题，不过可以肯定的是，AOT 在编译时如果认为某个值可以按 Double 处理，就会生成更直接的机器码，但运行时进入了返回 int 的分支，在机器码的时候，某个边界导致了没有正确处理这种情况。

**所以  `0.125` 被算成了 `2299087609772638200.0`。**

只能说，是真的抽象。
