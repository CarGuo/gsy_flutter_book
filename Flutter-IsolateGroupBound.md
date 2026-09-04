

# Fluter 共享内存多线程正在落地，IsolateGroupBound 来了

很久之前，Dart 就开始给 isolate 增加共享内存的能力，做过 Flutter 的都知道，isolate 作为 Dart 的并行执行模型，最麻烦的地方就是普通 Dart 对象状态不能像 Java、C++ 线程那样直接共享。

![](https://img.cdn.guoshuyu.cn/image-20260714095200681.png)

所以后来  Dart 有了 isolate group，Flutter 也有 background isolate 相关支持，但一直缺少一种场景支持：**原生线程可以同步回调 Dart，同时又不用一定绑定并等待某一个具体 isolate**。

> 说人家话就是，不能直接随便调用。

所以现在这部分目前正在作为共享内存的一部分落地：

> **支持 Dart 代码存在 A Isolate Group 内、但可以在任何  Isolate 执行，只是这段代码只能访问该 Isolate Group 共享的静态或顶层状态。**


Isolate 一直以来都是 Dart 的并行执行模型，每个 Isolate 有自己独立的静态状态和可访问对象，Isolate 之间默认不能直接访问彼此的普通可变 Dart 对象，所以一直通过 `SendPort` 传递消息。

> 而后来  isolate group  来了之后，同一个 isolate group 里的多个 isolate ，可以共享代码、类型信息和一部分 VM 内部结构，并可能运行在同一个 managed heap 上，**但是 VM 还是维持对象访问边界，不能因为物理上处于同一个 heap，就直接拿到另一个 isolate 的普通对象**。


所以，**对于普通可变对象，跨 isolate 发送需要复制**，这么做的好处很明显，就是在默认 Dart 对象模型下，开发者基本不需要关注锁的问题，普通 Dart 对象不会被两个 isolate 同时修改，也就避免了传统共享内存模型里常见的数据竞争。

当然坏处也很明显：

- **大对象图和共享中间状态的并行成本高**：如果要并行解析一个很大的 Dart 语法树、加载大型 Kernel 二进制文件，或者多个 worker 需要反复访问同一份复杂中间结果，就很难避免跨 isolate 复制或者自行改用 native memory，因为跨 isolate 传输成本通常与传输数据大小呈线性关系
- **和原生代码互操作成本高**：原生代码（C/C++、Objective-C/Swift、Java/Kotlin）普遍基于线程模型，原生线程并不理解 Dart 的 isolate，也不知道回调应该进入哪一个 isolate

所以 Dart 团队的解题思路就是：**共享内存又不一定意味着立刻开放任意可变 Dart 对象，可以先在保留 isolate 消息传递模型的基础上，让一部分安全对象和 native memory 能够直接共享，同时解决原生线程同步回调 Dart 的问题。**

所以这短时间也发展出来一些支持：

- 一些不可变、可安全共享的对象可以直接共享
- `TransferableTypedData` 可以转移底层数据，发送后原发送方不再继续持有可用的数据内容
- `Isolate.exit` 可以在 isolate 退出时把结果发送出去，避免普通消息发送路径上的复制
- `Isolate.run` 内部利用了 isolate 退出返回结果的优化，结果通过 `exit` 发送，**不需要复制**

所以这个 Dart 多线程共享能力现在已经有了比较明确的实现形态：

- 通过 `@pragma('vm:shared')`，可以把静态字段或顶层变量标记为 isolate group 共享状态，只是目前必须是 `final`、不能是 `late`，保存的值必须属于 deeply immutable / trivially shareable 范围
- 可共享范围包括字符串、数字、编译期常量、部分 deeply immutable 类型、`SendPort` 的内部实现、静态方法 tear-off、`TypedData`、`Struct`，以及满足捕获约束的闭包，而任意普通可变对象例如 `List`、`Map` 等还是不能直接共享
- `dart:concurrent`  已经有部分雏形，包括 `Mutex` 和 `ConditionVariable` 的实现

> `@pragma('vm:shared')` 字段本身在当前方案中必须是 `final`，但它可以引用 `TypedData`、`Struct` 或 native memory 之类的共享二进制状态，对这些可变内容的并发读写不会自动获得完整的顺序一致性，所以还是需要 mutex、condition variable、原子操作之类来避免数据竞争。

目前进度主要有：
- `NativeCallable.isolateGroupBound` 已经进入 Dart SDK 和 Dart 3.12.2 的 API  ：**原生代码可以从任意线程同步调用它，回调会在创建者所属的 isolate group 中执行，但不进入某个具体 isolate**
- 回调访问普通的非 shared 静态或顶层字段时，会报错 `AccessError`
- `dart:concurrent` 的 `Mutex`、`ConditionVariable` 已经有实现和测试
- 未来确实可能继续扩展到 “share everything”，支持共享普通 Dart 对象，不过和当前 shared native memory 阶段是分开推进


实际上，`isolateGroupBound` 和 shared native memory 可以减少数据在 isolate / native thread 之间来回复制和桥接的成本，例如 `Uint8List`、`Struct`、native buffer、不可变配置值等，但它还不能直接让多个 isolate 共享任意 AST、`List`、`Map` 或业务对象。

比如大 JSON 场景里，可以把原始 UTF-8 字节保留在 `Uint8List` 或 native buffer 中，让不同执行上下文读取同一份二进制输入，但是比如：

```dart
final Object? decoded = jsonDecode(utf8.decode(bytes));
```

这个时候，`jsonDecode` 产生的通常还是普通 `Map` / `List` 对象图，这些结果在当前阶段还是 isolate-local，不会因为有了 `isolateGroupBound` 就被多个 isolate 直接共同访问。

另外，这套能力未来可以让 Dart 更接近普通 C 库的调用模型：Dart AOT 代码被静态或动态链接进原生应用后，任意原生线程调用导出符号时，可以有一个明确的 isolate-group-bound 执行语义。

> 比如可以让 Dart 代码像普通 C 库一样被静态/动态链接进原生应用，任意原生线程可以直接调用 Dart 导出符号（`@ffi.Export()`），不再需要"进入/离开 isolate"的限制。

如果完成了的话， `dart:io` 的 C++ 实现甚至可以迁移回纯 Dart ，拆分成独立 package.

当然目前还是有一些问题，比如 isolate-group-bound 上下文里的隐藏状态访问问题：

> 如果第三方依赖代码里悄悄读取了普通全局变量或静态缓存，那么它在 isolate-group-bound 回调中执行到这一步时，就可能抛出比较难定位的 `AccessError`，想在类型系统里静态区分“只访问 shared 状态的函数”和“可能访问 isolate 状态的函数”，会涉及很大的语言改动。

比如下面这段老的 isolate 代码：

```dart
import 'dart:isolate';

int global = 0;

void main() async {
  global = 42;
  await Isolate.run(() {
    print(global); // => 0，注意不是 42
    global = 24;
  });
  print(global); // => 42，主 isolate 的 global 没有被修改
}
```


这里 `Isolate.run` 会创建新的 isolate，新的 isolate 不会继承主 isolate 中 `global = 42` 的当前状态，而是重新按照顶层初始化器把自己的 `global` 初始化为 `0`，子 isolate 怎么修改自己的字段，都不会影响主 isolate 中的那一份。

> 这段代码单独看很容易理解，因为能一眼看出每个 isolate 有自己独立的一份状态，但真实行为可能藏在第三方依赖内部，例如日志库缓存、单例、懒加载字段或平台库内部状态，就会更难发现。

**如果这段访问 `global` 的代码不是你自己写的，而是出现在某个第三方 package 内部，或者 AI 生成的代码里，就可能成为一个很诡异的 bug。**

然后引入 isolate-group-bound 执行后，又会产生另一类问题。

```dart
import 'dart:concurrent';
import 'dart:ffi';
import 'dart:typed_data';

@pragma('vm:shared')
final counter = Uint32List(1);

@pragma('vm:shared')
final mutex = Mutex();

void increment() {
  mutex.runLocked(() {
    counter[0]++;
  });
}

void main() {
  final callback =
      NativeCallable<Void Function()>.isolateGroupBound(increment);

  // 把 callback.nativeFunction 交给原生库，原生代码可以从任意线程同步调用。

  callback.close();
}
```

**isolate-group-bound 代码只能访问 shared 静态或顶层状态。一旦访问普通非 shared 静态状态，规范要求抛出 `AccessError`。**

比如你的应用架构大概是这样的：

- 某个原生库，例如音频引擎或 UI 框架的 native 层，通过 FFI 的 `NativeCallable.isolateGroupBound`，从任意原生线程同步回调 Dart
- 这个回调不会进入创建它的普通 isolate，而是在对应 isolate group 中、具体 isolate 之外执行
- 你的回调内部调用了某个第三方 Dart package 的函数，例如日志格式化、解析工具或同步算法
- 这个第三方包内部恰好使用普通非 shared 静态变量做缓存、单例或懒加载状态
- 执行到这部分代码时，运行时就会因为访问 isolate-local 状态而失败

这里最主要的问题主要就在于：

- 报错发生在第三方库内部，不是你自己直接写的那一行，那么这到底算原生库、第三方 Dart 库，还是调用方没有正确划分执行上下文的问题？
- 普通开发者未必能直接意识到“这段函数不属于任何普通 isolate”：native thread → FFI trampoline → isolate-group-bound callback → 第三方函数，这个运行上下文是由 API 语义决定的，不是你显式写了一个 `Isolate.runShared(...)`
- 第三方库作者写静态变量时，原来的 isolate 模型里这完全是合规代码；但它不一定适合在 isolate-group-bound 环境中调用

一个理想解决方案，是在编译期就能区分“这个函数只碰 shared 状态”还是“这个函数可能碰 isolate 状态”，类似 Swift 通过 `Sendable` 和 actor isolation 做静态检查。

> 但要把这套静态区分塞进现有 Dart 类型系统，需要非常大的语言改动。尤其遇到高阶函数，例如 `List.map`、`List.forEach` 等接受回调的 API 时，闭包可能捕获任意状态，函数效果还会在多层调用中传播，静态分析和类型标注都会变得复杂。


**所以当前实现采用的是混合检查：**

- `@pragma('vm:shared')` 字段必须 `final`、不能 `late`，以及明显不可能 deeply immutable 的静态类型，可以在编译期拦截
- `NativeCallable.isolateGroupBound` 的闭包或捕获值不满足 trivially shareable 约束时，可以在创建 callback 时抛出 `ArgumentError`
- 代码通过前面的检查后，如果真正执行时触碰了隐藏在调用链深处的非 shared 静态状态，仍然只能在运行时通过 `AccessError` 暴露

另外， `dart:async` 相关能力还不能在 isolate-group-bound 上下文中正常使用，`Future`、`Stream`、`Timer`、`Completer`、`Zone` 等依赖事件循环和 microtask queue 的 API 会直接报错，所以它现阶段更适合同步、短时、可预测的 FFI 回调。

> 只能说有好有坏，一旦开放可变 `TypedData`、`Struct` 或 native memory 的跨线程访问，就会出现数据竞争风险，同时生态里的大量 package 默认自己总是在某个正常 isolate 和事件循环里运行，因此 isolate-group-bound 语义引入后，平台库和第三方库都还需要一段兼容和验证时间。


# 链接

- https://github.com/dart-lang/sdk/issues/55991
- https://github.com/dart-lang/sdk/issues/56841
- https://github.com/orgs/dart-lang/projects/110
- https://api.dart.dev/dart-ffi/NativeCallable/NativeCallable.isolateGroupBound.html
- https://github.com/dart-lang/sdk/blob/main/sdk/lib/ffi/ffi.dart
- https://github.com/dart-lang/sdk/blob/main/sdk/lib/concurrent/concurrent.dart
- https://github.com/dart-lang/sdk/blob/main/runtime/tests/vm/dart/isolates/shared_fail_without_flag_test.dart
- https://github.com/dart-lang/sdk/blob/main/tests/ffi/isolate_group_bound_callback_test.dart
- https://github.com/dart-lang/sdk/issues/61287
- https://github.com/dart-lang/sdk/issues/63559
