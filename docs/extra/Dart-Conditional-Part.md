---
title: "感人，Flutter 居然有了一个超实用提案，期待落地"
---

# 感人，Flutter 居然有了一个超实用提案，期待落地

[Dart language #4827：First version of conditional part feature specification](https://github.com/dart-lang/language/pull/4827?utm_source=chatgpt.com) PR 就很赞，特别是对 Flutter 跨平台插件、FFI、平台适配层的开发来说，就很实用。

提案主要提出两个变化：

- Conditional Parts（条件 Part）：**让 Dart 的 `part` 和现有的条件 `import` 一样，可以根据 Android/iOS、Web 等编译环境选择不同的实现文件**
- 新增 `concrete` 修饰符：**允许类提前声明一个有具体实现的方法，但实际方法体由平台对应的 `augment` 代码补齐**

**等于 Dart 想让不同平台共享同一套静态类型和 API 检查结果，只在编译时替换具体实现**，什么 Kotlin 实现这是，哈哈哈哈。

目前 PR 仍然刚刚 Open 状态，规范标记为 Draft，新增了 624 行提案文档，还没有正式修改 Dart SDK 代码，但是确实值得期待一下。

比如Dart 目前已经支持：

```dart
import 'channel_stub.dart'
    if (dart.library.io) 'channel_io.dart'
    if (dart.library.js_interop) 'channel_web.dart';
```

但是问题是 `channel_io.dart` 和 `channel_web.dart` 属于不同的 Library，比如你有一个 `Channel` 类，内部维护 `_name`、`_handle`  之类的私有状态，想让 IO 和 Web 分别实现它的 `close()` 方法。

现有方案就需要把接口、实现类拆开，再通过工厂或代理进行调用，而且 Dart 不会自动保证两份条件导入文件的 API 完全一致。

但是如果是新提案，就可以直接这样写：

```dart
// channel.dart
part 'channel_stub.dart'
    if (dart.library.io) 'channel_io.dart'
    if (dart.library.js_interop) 'channel_web.dart';

abstract class Channel {
  final String _name;

  Channel(this._name);

  concrete void close();
}
```

然后在原生平台的文件里面：

```dart
// channel_io.dart
part of 'channel.dart';

import 'dart:io';

augment class Channel {
  augment void close() {
    stdout.writeln('Closing $_name');
  }
}
```

实际上这里有三个变化：

- `channel_io.dart` 还是属于 `channel.dart` 的 Library，可以直接访问 `_name`
- 通过 `augment` 补充原来 `Channel` 类的方法体，不需要创建额外的实现类
- 平台 Part 可以拥有自己的 `import`，比如只在 IO 平台引用 `dart:io`

为什么还要专门引入 `concrete`？我觉得这是也这份提案最有意思的点，比如在 Dart 里，抽象类中的：

```dart
abstract class Channel {
  void close();
}
```

意味着 `close()` 是抽象方法，那么子类执行 `super.close();`就会发生编译错误，因为父类没有可以调用的方法体。

但如果父类的方法体通过 Conditional Part 提供，那 Analyzer 在分析公共声明时又不读取平台实现，那它怎么知道 `close()` 最终是不是抽象方法？

所以提案引入：

```dart
abstract class Channel {
  concrete void close();
}
```

> 这就明确告诉 Analyzer：这个方法会有具体实现，可以被子类继承，也允许 `super.close()`。

等到编译某个平台时，再检查对应的 `augment` 有没有真的补齐方法体，如果没有，就报编译错误，又是什么 Kotlin 即视感？

另外 `concrete` 还支持非 `const` 的生成式构造函数，让平台 Part 提供对应的初始化逻辑。

**最重要的是，平台可以换实现，但不能随便改变类型结构**，为了保证不同平台的静态分析结果一致，提案对 Conditional Part 设置了比较严格的限制：

| 行为                                 | Conditional Part 是否允许 |
| ------------------------------------ | ------------------------- |
| 给已有方法补充实现                   | 允许                      |
| 访问同 Library 的私有成员            | 允许                      |
| 独立 `import` 平台依赖               | 允许                      |
| 新增顶层声明，包括私有声明           | 禁止                      |
| 给类引入新的成员声明                 | 禁止                      |
| 增加 `extends`、`implements`、`with` | 禁止                      |
| 添加 enum 枚举值                     | 禁止                      |
| 修改可选参数默认值                   | 禁止                      |
| 在条件 Part 中完成 `const` 构造函数  | 禁止                      |

> 虽然不能引入新的成员声明，但还是允许某些符合规则的 `augment` 变量声明补齐已有属性并提供底层存储，不是说完全禁止平台差异化的实例状态。

**也就是 Analyzer 可以先只分析公共声明，得到稳定的类型关系、方法签名、枚举集合和常量结果**，所以当编译器选中具体平台以后，再将对应 Part 的 `augment` 应用到声明上，就可以进行实现完整性和类型检查，这样能保证不同平台不会偷偷改变公共 API 的静态结构。

对 Flutter 来说就很有用了，比如：

- Flutter 原生和 Web 双端插件：同一个 Dart API 中直接放置原生和 JS 的实现，减少抽象类、工厂和代理代码
- FFI、JS Interop 封装：公共类保留一致的方法和私有状态，平台 Part 负责调用对应的底层 API
- 代码生成：利用 Augmentations，在不改变外部接口的前提下，生成不同环境的实现代码

所以很期待这个方向，尤其是 Dart 现在越来越需要同时兼顾 Flutter Native、Web、Wasm 和各种平台扩展，维护一套一致的 Dart API 挺重要的。

如果后面 Augmentations 也正式落地，那么 Dart 的 `part` 就不再只是一个简单的文件拆分机制，可以有机会成为一套比较完整的跨文件、跨平台实现组合机制。

完美！
