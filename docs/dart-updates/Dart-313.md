---
title: "Dart 3.13 大更新，感觉比 Flutter 更带劲"
---

# Dart 3.13 大更新，感觉比 Flutter 更带劲

小版本大更新，一开始以为 Dart 3.13 没什么大更新，结果一看直接应激了，我感觉这两个版本 Dart 都比 Flutter 团队靠谱多了。

# Primary Constructors

比较有意思的就是 Primary Constructors 正式转正，这个我们之前聊过两次了，比如以前写一个很普通的数据类，经常需要把同一套信息重复两遍：

```dart
class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}
```

3.13 可以直接写成：

```dart
class Point(final int x, final int y);
```

这里的 `final int x` 同时定义了构造参数和实例字段，`var` 则可以声明可变字段，而如果只写 `int x`，它只是构造参数，不会自动变成字段。

不过 AI 目前还是不大习惯写这玩意，你不强制声明的话，AI 还是会写会老的写法为了搞定这个，官方甚至一口气更新了一堆 lint：

![](https://img.cdn.guoshuyu.cn/image-20260816171615512.png)

3.13 甚至连传统 constructor 都增加了 concise syntax，在类里面可以用 `new` 代替重复写类名：

```dart
////以前
class Point {
  double x;
  double y;

  Point(this.x, this.y);

  Point.origin()
      : x = 0,
        y = 0;

  factory Point.clone(Point other) {
    return Point(other.x, other.y);
  }
}

////现在
class Point {
  double x;
  double y;

  new(this.x, this.y);

  new origin()
      : x = 0,
        y = 0;

  factory clone(Point other) {
    return Point(other.x, other.y);
  }
}
```

大概对应关系：

```dart
Point(...)              → new(...)
Point.origin(...)       → new origin(...)
factory Point.clone(...)→ factory clone(...)
```

官方这一口气配了多个 lint 和 IDE Refactor，包括自动把旧 constructor 转成 primary constructor，要的就是尽可能让你换到新的写法上。

# Native Tree Shaking

另外一个就是 Native Tree Shaking，以前 Flutter/Dart 的 Tree Shaking 到 FFI 边界基本就没了，比如一个 Flutter 包通过 FFI 带了一整套 SQLite、加密库、图片解码器或者 Rust library，Dart AOT 能知道你只用了其中几个 Dart wrapper，然后没用到的 Dart 代码可以被裁掉，但底下真正打进 APK、IPA 或桌面程序里的 native library 可能还是一大坨完整二进制。

> 因为 Dart 编译器知道“这些 Dart FFI 函数到底有没有被真正调用”，native linker 却不知道 Dart 那边发生了什么。

然后 3.13 加入的 `@RecordUse`、`package:record_use` 和 link hook，专门把这条信息链打通。

```dart
import 'dart:ffi';
import 'package:meta/meta.dart';

@RecordUse()
@Native<Int32 Function(Int32, Int32)>()
external int sqlite3_open(
  Pointer<Utf8> filename,
  Pointer<Pointer<sqlite3>> ppDb,
);

@RecordUse()
@Native<Int32 Function(Pointer<sqlite3>)>()
external int sqlite3_close(Pointer<sqlite3> db);

```

AOT 编译时，编译器会记录最终可达代码到底调用了哪些标记过的 FFI binding，然后通过  `LinkInput.recordedUses`  把这些信息交给 package 的 `hook/link.dart`，link hook 再把 Dart binding 映射到真正的  C/Rust symbol，最后让 native linker 只保留这些符号。

> 比如一个 native library 暴露了 300 个 API，你的 App 最终只用 20 个，理论上剩下那些没有引用到的 native 代码也能一起裁掉，如果一个 native library 一个函数都没被使用，整个 library 都可以不进入最终 Bundle，这里 `ffigen` 也会配合生成相应的信息。

```dart
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:record_use/record_use.dart';
import 'package:my_package/src/c_library.dart';
import 'package:my_package/src/record_use_mapping.dart';

void main(List<String> arguments) async {
  await link(arguments, (input, output) async {
    // Extract symbols for functions called in reachable Dart code:
    final symbolsToKeep = input.recordedUses?.calls.keys
        .cast<Method>()
        .map((method) => recordUseMapping[method.name]!);

    await cLibrary.link(
      input: input,
      output: output,
      linkerOptions: LinkerOptions.treeshake(
        symbolsToKeep: symbolsToKeep,
      ),
    );
  });
}

```

这个东西对于 Flutter 后面推 Code Assets 还挺重要的，Code Assets 一直在解决「Dart Package 怎么自然地携带、编译和绑定 C/C++/Rust 代码」，现在 Dart 又开始解决另外半个问题：

> 这些 native assets 最后怎么参与 Dart 的 whole-program optimization。

**以前 Dart 编译和 native 编译就像是两段独立流水线，现在 build hook 负责编 native code，Dart AOT 负责计算代码可达性，link hook 再拿着 Dart 编译器给出的使用信息处理 native library**。

> *如果继续发展下去，Flutter Package 带 Rust/C++ 依赖的成本会比现在低很多，包作者可以暴露一整套 native API，App 最终只为真正用的那一部分付体积成本*。

# Web

Web 这变主要就是  `dart2wasm` 的 deferred loading，这个我们在 Flutter 更新里也提到过了，对于大型 Flutter Web App 最大的问题就是首次加载，所以 3.13 现在可以通过 `--enable-deferred-loading` 把 `deferred` 的 Dart 代码真正拆成独立 Wasm module，需要的时候再加载。

不过目前还属于早起试验性阶段，而且 embedder 需要自己提供加载 Wasm module bytes 的 callback，所以离完全无感还有些距离。

# Runtime

![](https://img.cdn.guoshuyu.cn/image-20260816172603564.png)

Runtime 这次也有一些变动，比如有意思的是：

- 一个是 Dart heap 外面开始加入 memory cage，用来加强 native runtime 的内存安全
- 一个是 Dynamic Modules 实验，Dart 团队已经开始研究运行期间动态链接 Dart 代码，并且明确提到团队内部快速共享 prototype 这种开发工作流

惊不惊喜，意不意外？虽然还远远谈不上 Flutter Code Push，但是这个确实有意思，因为 Dart AOT 一直高度依赖 closed-world assumption，编译时默认整个程序已经确定，这也是它能够做激进 Tree Shaking 和优化的重要原因。

Dynamic Modules 目前主要是想解决**没有 JIT 的移动环境里的开发工作流**，也就是 iOS 的 JIT 在 iOS 26 上的问题，现在的做法还是比较黑客，不过官方也说了，**目前没有优先做 production 里的 server-driven UI**，当然，未来就不好说了。



# Pub

现在 dartdoc 可以用 `{@example}` 直接引用  `example/`  目录中的真实代码片段，还可以用 `#hide` 隐藏为了让示例能够实际运行而存在的样板代码，比如：

```dart
// example/foo.dart
void main() {
  // #region abc
  // Included in documentation
  foo();
  assert(false); // #hide
  // #endregion
}

```

然后在你的 Dart 文档注释中引用该区域：

```dart
/// This is a great function.
///
/// Example usage:
/// {@example /example/foo.dart#abc}
void foo() {}

```

这个设计其实挺实用，因为以前 API 文档里的示例经常是复制进去的一份代码，时间久了文档示例和真正 example 很容易漂移，现在可以共用同一个源文件：

![](https://img.cdn.guoshuyu.cn/ae042789-aba8-47c9-8f95-10217438eb93.png)

而且 pub.dev 还换了新的两级 Hash Index 来处理 dartdoc 文件查找，官方特意提到对拥有 10 万级生成文件的大型 package，文档渲染延迟能明显下降：

![a5d35a5b-5e0c-45db-817f-fa963611b679](https://img.cdn.guoshuyu.cn/a5d35a5b-5e0c-45db-817f-fa963611b679.png)



# Tool

`dart format` 这次也有几处肉眼可见的调整，主要在 method chain 和 import 之类的，比如：

之前的方法调用格式错误修复问题 ，之前的错误会导致优化有时会错误地触发并导致代码格式错误：

```dart
// Before:
await MethodChannelContainer()
    .onMethodChannelInvoke('reportCrash', <String, Object?>{
      'time': nowTime,
      'errorValue': errorName,
      'reason': reason,
      'stacktrace': stacktrace,
    });

// After:
await MethodChannelContainer().onMethodChannelInvoke(
  'reportCrash',
  <String, Object?>{
    'time': nowTime,
    'errorValue': errorName,
    'reason': reason,
    'stacktrace': stacktrace,
  },
);

```

以前一些 `function(argument).method().another()` 换行时会把前面的 function call 撕得很碎，现在更倾向保持简单 target 完整，然后把调用链逐行展开。

另外还改了格式化决定「在句点处」还是「在参数列表内部拆分方法调用链」的启发式算法， `.` 如果方法链的目标是集合字面量或者具有单个元素或参数的函数调用，现在优先拆分调用链而不是目标：

```dart
// Before, split the target:
function(
  argument,
).method().another();

// After, split the chain:
function(argument)
    .method()
    .another();

```

`dart:`、`package:` 和项目自己的 import 之间也会自动加入空行 ：

```dart
// Before:
import 'dart:io';
import 'dart:math';
import 'package:args/args.dart';
import 'package:test/test.dart';
import 'my_library.dart';

// After:
import 'dart:io';
import 'dart:math';

import 'package:args/args.dart';
import 'package:test/test.dart';

import 'my_library.dart';

```

# 最后

怎么样，是不是感觉 Dart 这个小版本更新比 Flutter 更带感，感觉 Dart  3.13 还挺符合我的喜好的，特别 Tree Shaking 更灵活了，而且全新的 Dynamic Module 也值得期待下，至少可以不用忍受 JIT 那种延迟 hotload 了。