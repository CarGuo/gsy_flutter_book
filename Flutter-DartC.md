# 你为什么需要了解 Dart AST？一个简单的 bug 带你快速认识下 Dart  Kernel AST 

事情的起因是最近在 Github 收到了一个 issue ，内容是在获取 `l10n ` 多语言相关实现时找不到该方法，从而导致 `NoSuchMethodError` 的问题：

![](http://img.cdn.guoshuyu.cn/20250402_3332/image4.png)

而出现问题的地方是通过 `context.l10n` 方式获取当前的多语言文本内容，但是这个用法在同个文件内的其他地方又是正常：

![](http://img.cdn.guoshuyu.cn/20250402_8999/image1.png)

而  `context.l10n`  这个实现，是通过 Dart 的 `extension`  拓展 `BuildContext`  来完成，并且返回时为了方便会通过  `!`  来强行忽略空问题：

![](http://img.cdn.guoshuyu.cn/20250402_3332/image5.png)

但是虽然知道了问题的点在于   `context `  获取不到 `l10n`，但是一时半会也没看出来代码哪里有问题，因为这是一个正常的  `context` ，使用的位置也正常，通过这个  `context ` 没理由获取不到 `AppLocalizations`  多语言对象，并且  `l10n`  在同个文件其他地方都是正常，甚至 debug 时通过这个 context 执行 `AppLocalizations.of(context)` 是可以正常获取 ，那为什么在这里就不行？

接着我用 Cursor 和 Trae 针对这个问题做了一系列提问，但是 AI 们给出的答案基本毫无帮助，基本是让你做个判空处理，甚至还有严重跑偏和幻觉的情况：

![](http://img.cdn.guoshuyu.cn/20250402_3332/image1.png)

> 深度嵌套明显就是一个瞎编的思路，因为 `InheritedWidget`  的共享是通过 Element 内的一个 map 来存储。

解决问题不难，但是我们需要知道这个  `NoSuchMethodError`  的根本原因，从根上去 fix 才是我们的目标，所以既然代码看不到问题，那就只能通过编译后的 Kernel AST 代码来看看是否有灵感，而通过 dump  调试模式下的 dill 文件，然后找到对应方法，还真就发现了端倪：

![](http://img.cdn.guoshuyu.cn/20250402_3332/image8.png)

可以看到，因为  `_renderUserInfo`  函数在声明时没有给 context 指定 `BuildContext` ，所以编译后它是一个 `dynamic`  类型，从而导致后续 `context.l10n`  也出现类型不对，无法正确被编译为  `AppLocalizations`  导致的一系列问题：

![](http://img.cdn.guoshuyu.cn/20250402_3332/image6.png)

那么知道问题就简单了，给  `_renderUserInfo`   函数的  context  指定 `BuildContext`  之后，如下图所示，编译后可以看到，对应的  `context.l10n`  拓展引用，在 AST 里变成了 `LocalizationExtension` 和 `Applocalizations` 的相关实现：

![](http://img.cdn.guoshuyu.cn/20250402_3332/image7.png)

从 Kernel 代码里可以看到，对应的 `extension`  拓展 `BuildContext`  实现能匹配上前面的引用，**所以在添加了明确的 `BuildContext` 声明之后，  `context.l10n`  的灵异 `NoSuchMethodError`  问题得以解决**。

![](http://img.cdn.guoshuyu.cn/20250402_3332/image3.png)

![image-20250402214515337](http://img.cdn.guoshuyu.cn/20250402_3332/image2.png)

**其实这个问题很简单，更多是在编写函数时不规范声明导致**，因为这里需要用到的是 context 的  `extension`   实现，但是如果不对函数的 context 给予显式的 `BuildContext` 声明，那就算我们使用时传入的是   `BuildContext`  ，但是编译时 context 因为没有明确类型声明，就会被判断成 dynamic ，从而无法正确匹配它的  `extension`   实现。

虽然这种 bug 很简单，但是很容易让人忽略问题的本质，而**通过 AST 来验证问题，就是发现问题根本的手段之一**，所以接下来，我们也简单快速地认识下 Dart 的 Kernel AST 。

#  Dart Kernel AST

在过去的内容里，我们一直说因为 Dart 2.0 之后就不再支持直接从源码运行，对于 Dart 代码现在会统一编译成一种「预处理」形式的二进制 dill 文件，一般称它会 Kernel AST 文件，那么其实这个二进制文件究竟是什么？要如何查看？

![](http://img.cdn.guoshuyu.cn/20250225_Async2/image2.png)

首先 dill 文件本身已经是二进制文件，所以如果想要查看具体内容，我们还是需要将其 dump 成文本才方便查看，在 Dart SDK 里就有对应的 [ast_to_text.dart](https://github.com/dart-lang/sdk/blob/ee32a22712b64006b98a3923ff77f4d9476e2f84/pkg/kernel/lib/text/ast_to_text.dart#L5) 的相关工具，而 Dart 也给我们提供了对应的脚本 dump_kernel.dart。

通过下方命令，我们可以将 dill 文件反编译为 Kernel 代码文本，从而方便查阅，但是使用这个脚本也有相对应的前提：

```sh
dart pkg/vm/bin/dump_kernel.dart xxxxxx/app.dill xxxxxx/app.dill.txt 
```

因为  dump_kernel.dart 需要在全量的原始 Dart SDK 里才能运行，并且想要使用 dump_kernel，你就需要 depot_tools 工具，depot_tools 是 Chromium 的源码管理工具，同时也需要对应的环境支持：

- python3 环境
- git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git ，并将路径配置 `export PATH=/Users/xxxxx/workspace/depot_tools:$PATH`
- 创建一个目录，并执行 `fetch dart` ，会比较耗时，大概几个 G 的大小
- 进入 sdk 目录，执行 git checkout xxxx ，切换到对应 dart 版本 tag ，因为一般情况下，**你 debug 运行的 dart 版本和 sdk 的 dart 版本需要一致**
- 执行 gclient sync -D
- 现在你就可以通过 `dart pkg/vm/bin/dump_kernel.dart xxxxxx/app.dill xxxxxx/app.dill.txt `去 dump kernel ，这里的 `pkg/vm/bin/dump_kernel.dart` 路径就是前面 sdk 下的路径。

之后你就可以通过 dump_kernel 查看对应的 dill 文件了，我们先看一个简单案例，以下是一个很普通的 Dart 代码：

```dart
add(int a, int b) async{
  await Future.delayed(Duration(seconds: 1));
  return a + b;
}
void main() {
  print(add(1, 2));
}
```

而下方是上面代码编译后的 dill 文件的反编译输出：

```dart
library from "file:///Users/guoshuyu/workspace/main.dart" as main {

  import "dart:async";

  static method add(core::int a, core::int b) → dynamic async /* emittedValueType= dynamic */ {
    await asy::Future::delayed<dynamic>(new core::Duration::•(seconds: 1));
    return a.{core::num::+}(b){(core::num) → core::int};
  }
  static method main() → void {
    core::print(main::add(1, 2));
  }
}
```

可以看到，此时的 kernel 其实并没有什么编译优化，例如  async 语法糖就没有被展开为状态机，从 dill 代码上看，它基本保留了原始代码的信息，仅仅只是针对添加了一些信息补充，例如：

- `library from`  针对说明了这部分代码的来源，这些在源代码中是隐式的，但在内核中需要显式声明
- 参数类型从 int 补充为 `core::int`，也就是完全限定名称，明确来自 `dart:core` 库，在 Kernel dill 里所有类型和函数都使用完全限定名称
- 加法操作 `a + b` 在内核中表示为 `a.{core::num::+}(b){(core::num) → core::int}`，明确了操作符的来源和类型，加法操作符来自 `num` 类，类型签名为 `(core::num) → core::int` 
- 顶级函数会显性都加上  `static method `

所以可以看出来，AST 一般是源代码的抽象语法结构的树状表现形，而转化为 AST 是为了更适合程序分析，在 Dart 里，Kernel AST 因为不包含解析后的各种类和函数，所以它虽然是二进制，但是包含详细信息，从而可以在不同平台之间移植。

> 这么看，**Dart 的 Kernel AST 是更精确的 IR (中间表示)** 。

另外， Kernel AST 在这里属于 IR 的存在，在后续还有 IL 和 Optimized SSA IL 等处理才会变成 Machine Code ，例如上面的 a+b ，在 Optimized SSA IL 阶段理论上会处理为 smi (small integers) ：

> smi 的作用是优化性能，它是  Dart VM 的直接对象，使用 smi 表示 Dart VM 可以避免创建完整对象，从而减少内存分配和垃圾回收的开销，特别是在「加减乘除」上可以直接在这些标记指针上执行从而显著提升执行速度。

另外，在 dill 文件里你还会看到很多 `@#C1` 、 `@#C200`  之类的标记，其中 C 就是 constants 的意思，也就是在 Kernel 文件里，它会把一些可以常量化的特定值通过标记统一起来，在使用的地方只留下标记，从而尽可能缩减大小，例如这里的 `override` ：

![](http://img.cdn.guoshuyu.cn/20250307_DartC/image1.png)

![](http://img.cdn.guoshuyu.cn/20250307_DartC/image2.png)

另外我们再看一个代码，这里主要是在  `Cat` 里通过 covariant 显式声明参数是协变的，允许子类方法接受更具体的类型：

```dart
class Animal {
  void chase(Animal x) {  }
}

class Mouse extends Animal {  }

class Cat extends Animal {
  @override
  void chase(covariant Mouse x) {  }
}
```

编译后可以看到，此时 dill 多了一些其他东西：

- `synthetic constructor` 主要是标识合成构造器，是指由编译器自动生成的构造器，因为我们没有对类显式声明构造器
- 而 Cat 的 chase 方法标记为 `covariant-by-declaration`，表明它在声明时使用了` covariant`，确保运行时类型检查遵循协变规则

```dart
class Animal extends core::Object {
  synthetic constructor •() → main::Animal
    : super core::Object::•()
    ;
  method chase(main::Animal x) → void {}
}
class Mouse extends main::Animal {
  synthetic constructor •() → main::Mouse
    : super main::Animal::•()
    ;
}
class Cat extends main::Animal {
  synthetic constructor •() → main::Cat
    : super main::Animal::•()
    ;
  @#C1
  method chase(covariant-by-declaration main::Mouse x) → void {}
}
```

同理还有下面的 `covariant Cat? child;` ，通过显式的协变声明，可以让代码在编译时限定更小范围，**省略类似 `x is Mouse` 之类的检查**：

```dart
class Animal {
  Animal? child;
}

class Cat extends Animal {
  @override
  covariant Cat? child;
}

--------------------------------------------------------------------------

class Animal extends core::Object {
  field main::Animal? child = null;
  synthetic constructor •() → main::Animal
    : super core::Object::•()
    ;
}
class Cat extends main::Animal {
  @#C1
  covariant-by-declaration field main::Cat? child = null;
  synthetic constructor •() → main::Cat
    : super main::Animal::•()
    ;
}
```

> 其实这里指出这个例子，是因为日常开发里很少人会用到 `covariant` ，而在 Kernel 文件里会有很多 `covariant-by-declaration` 标记，而通过上面例子，你就知道它的来源和作用。

相对应的还是有 ` covariant-by-class ` ，如下代码所示，在 Dart 里，当子类继承泛型父类并特化其类型参数，会导致方法参数类型在子类中协变时，编译器会在 Kernel AST 中生成 `covariant-by-class` 声明：

```dart
class Animal {}
class Cat extends Animal {}

class Handler<T extends Animal> {
  void handle(T obj) {}
}

class CatHandler extends Handler<Cat> {
  @override
  void handle(Cat obj) {} // 隐式协变，编译为 covariant-by-class
}
```

如下所示就是编译后的情况，这种情况主要发生在父类方法参数的类型由泛型参数定义，而子类通过指定更具体的泛型类型，使得参数类型发生隐式协变：

- 泛型父类定义：`Handler<T>` 的 `handle` 方法接受类型 `T`（约束为 `Animal` 的子类）

- 子类特化泛型参数：`CatHandler` 继承 `Handler<Cat>`，将 `T` 特化为 `Cat`

- 参数类型协变：子类 `handle` 方法的参数类型 `Cat` 是父类泛型参数 `T` 的具体化，当通过父类引用（如 `Handler<Animal>`）调用时，传入的参数需动态检查是否为 `Cat`

所以 **Dart 编译器自动标记此参数为 `covariant-by-class`，从而在启用运行时类型检查，确保类型安全**：

```dart
class Animal extends core::Object {
  synthetic constructor •() → main::Animal
    : super core::Object::•()
    ;
}
class Cat extends main::Animal {
  synthetic constructor •() → main::Cat
    : super main::Animal::•()
    ;
}
class Handler<T extends main::Animal> extends core::Object {
  synthetic constructor •() → main::Handler<main::Handler::T>
    : super core::Object::•()
    ;
  method handle(covariant-by-class main::Handler::T obj) → void {}
}
class CatHandler extends main::Handler<main::Cat> {
  synthetic constructor •() → main::CatHandler
    : super main::Handler::•()
    ;
  @#C1
  method handle(covariant-by-class main::Cat obj) → void {}
}
static method add(core::int a, core::int b) → core::int {
  return a.{core::num::+}(b){(core::num) → core::int};
}
static method main() → void {
  core::print(main::add(1, 2));
}
```

另外，在如下所示代码里，因为传递的是 Function ，所以会生成了一个  tearoff，从而在编译时会出现一些变化：

```dart
extension FutureExtensions on Future {
  void onError(Function handler) {
    catchError(handler);
  }
}

void main() {
  var future = Future.value(42);
  var fn = future.onError; 
}
```

可以看到，`onError` 多了 `method tearoff ` 的声明，`#get` 表示可以直接引用，而 `method tearoff`  在这里提供了一种简洁的方式 get 来传递方法引用，从而在这里显性声明了对应的 tearoff：

```dart
library from "file:///Users/guoshuyu/workspace/main.dart" as main {

  import "dart:async";

  extension FutureExtensions on asy::Future<dynamic> {
    method onError = main::FutureExtensions|onError;
    method tearoff onError = main::FutureExtensions|get#onError;
  }
  static extension-member method FutureExtensions|onError(lowered final asy::Future<dynamic> #this, core::Function handler) → void {
    #this.{asy::Future::catchError}(handler){(core::Function, {test: (core::Object) →? core::bool}) → asy::Future<dynamic>};
  }
  static extension-member method FutureExtensions|get#onError(lowered final asy::Future<dynamic> #this) → (core::Function) → void
    return (core::Function handler) → void => main::FutureExtensions|onError(#this, handler);
  static method main() → void {
    asy::Future<core::int> future = asy::Future::value<core::int>(42);
    (core::Function) → void fn = main::FutureExtensions|get#onError(future);
  }
}
```

另外，可以看到 `extension `后的  `FutureExtensions` ，也是通过显式创建出来了两个 `static extension-member ` 方法，其中一个 `get#onError` 是返回函数的 tear-off 而存在。

所以在 dill 文件里，也可以看到不少平时你很少接触的东西，最后，通过以下代码我们也可以快速理解 dill 文件的层级结构顺序：

![](http://img.cdn.guoshuyu.cn/20250307_DartC/image3.png)

所以，到这里我们可以看出来，**二进制的 Kernel AST 文件更多只是在原有代码的基础上补充了更多详细信息**，然后编译为二进制 IR ，等待被处理为特定平台如 arm64 的 IL (中间语言) 文件。

在 VM 处理 Kernel 文件的时候，会有 AST  转为  CFG(control flow graph)  的过程，其中 CFG 会由填充了 IL 指令的基本块组成，这个阶段使用的 IL 指令类似于基于堆栈的虚拟机的指令，而后经历对应的优化，比如前面说的 smi ，最终才转化为对应的机械码：

![](http://img.cdn.guoshuyu.cn/20250307_DartC/image4.png)

在这个过程里很多代码和指令都是动态生成，这也导致[过去在 iOS 18.4 beta1 的时候](https://juejin.cn/post/7476743827202736143)，由于 Apple 突然封杀了运行时通过 mprotect 动态修改内存访问权限，导致 Flutter 的 debug 和 hotload 无法工作的愿意，当然这个问题 iOS 18.4 beta2  的时候 Apple 又放开了。

> 而如果是 AOT 模式，基本 snapshot 里就包含有了所有需要生成的指令和代码。

**所以看懂 Kernel AST 没什么太大作用，它更多是让你知道更详尽的代码结构而已**，不像以前曾经「上古时代」编译后的代码，在 dill 里  `late` 、` extension`  、`async` 都可以更直观看到它的优化结构：

![](http://img.cdn.guoshuyu.cn/20250307_DartC/image5.png)

![](http://img.cdn.guoshuyu.cn/20250307_DartC/image6.png)

![](http://img.cdn.guoshuyu.cn/20250307_DartC/image7.png)

所以，这个角度考虑，**现在的 dill 其实只是源代码的二进制表现形式**，所以虽然它是二进制，但是还是需要 JIT 运行时的预热和动态生成，最终才可以达到运行峰值。

> 当然，JIT 运行慢绝大多数问题不是因为这个，**实际上导致慢的主要原因是因为 Flutter 框架里有着许多一致性检查/断言**，而这些导致性能极具下降的检查/断言仅在 debug 模式下启用，这才是缓慢的主要来源，从理论峰值性能考虑，JIT 性能其实并不会输于 AOT，只是它需要预热这个性质，在 UI 场景导致的不可预测性和等待时间并不合适。

不过就像最初的问题一样，一些实现其实也能在 AST 里体现，比如 `extension` 展开支持，**所以理解 AST 一般灭什么特别作用，但是也许哪天你就用上了呢**～







