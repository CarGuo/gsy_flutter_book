# Dart 3.4 发布：Wasm Native & Macros（宏）

Google I/O 的结束，除了 [Flutter 3.22 的发布](https://juejin.cn/post/7368757335802331174) ，Dart 3.4 也迎来了它是「史诗级」的更新，之所以这么说，就是因为 Wasm Native 的落地和 Macros 的实验性展示。

在此之前，其实我也提前整理过一些对应的内容，例如：

- [Flutter 即将放弃 Html renderer ，你是否支持这个提议？](https://juejin.cn/post/7355011549827121179)
- [Flutter Web 的未来，Wasm Native 即将到来](https://juejin.cn/post/7352527589246599178)
- [2024 Flutter 重大更新，Dart 宏（Macros）编程开始支持，JSON 序列化有救](https://juejin.cn/post/7330528367354282034)

 虽然之前的内容都是基于 Flutter 的话题下去展开，但是其实根本上它更多是来自 Dart 的支持，而现在它们终于和我们见面了。

# WebAssembly 更新

从 Flutter 3.22 开始， Flutter Web 终于可以实现 Wasm Native 的支持，这得益于 Dart 团队一直在努力推进的 [WasmGC](https://developer.chrome.com/blog/wasmgc/) ，现在 Dart 终于正式支持编译为 Native 支持 Wasm 运行。

![](http://img.cdn.guoshuyu.cn/20240515_Flutter-322/image3.png)

这里面主要涉及 WasmGC 的落地，全新的 Dart 编译器生成  WasmGC 代码，以及 Dart 3.3 里发布的新一代的  JavaScript Interop 的支持。

下一步 Dart 团队将尝试在「纯 Dart 应用」层面全面支持 Wasm ，并完全一些目前趣事的能力，例如延迟加载 等等。

当然，作为第一版的 WebAssembly 支持，目前还存在一些限制，例如：

1. 需要支持 WasmGC 的浏览器，Chromium 和 V8 在 Chromium 119 中发布了对 WasmGC 的 stable 支持， Firefox 在 Firefox 120 中支持 WasmGC （还有点问题），另外 Safari 尚不支持 WasmGC 。
2. 编译后的 Wasm 输出当前只支持 JavaScript 环境（例如浏览器），不支持在标准 Wasm 运行时环境（如 wasmtime 和 wasmer）中执行，详细问题可见 [#53884](https://github.com/dart-lang/sdk/issues/53884)
3. 编译为 Wasm 时仅支持新版本的 [JavaScript Interop](https://juejin.cn/post/7335463274619273266)

> 总的来说，这个落地只是一个开始，它对于 Flutter  Web 来说是对自己核心路线承诺的落地：**“ Flutter Web 是围绕 CanvasKit 和 WebAssembly 等新兴 Web 技术进行架构设计的框架。”**



# Dart Macros（宏）

Dart 开发者其实长期以来的一个痛点就是：序列化和反序列化 JSON ，其实大家都知道 `build_runner`  有多讨厌，以至于很多开发者更愿意用插件生成一个 Dart 文件而不是用 `JsonSerializable` 。

今天，Dart 带来了一种基于 Macros 的 JSON 序列化和反序列化预览支持：[JsonCodable](https://dart.dev/go/json-codable) ，它可以通过在编译时内省其他代码来生成代码支持，例如：

```dart
@JsonCodable()
class Vehicle {
  final String description;
  final int wheels;
  Vehicle(this.description, this.wheels);
}
void main() {
  final jsonString = Vehicle('bicycle', 2).toJson();
  print('Vehicle serialized: $jsonString');
}
```

那么它是怎样工作的？ `toJson()`/  `fromJson()` 是从哪里来的？这就是 Dart Macros 的支持，当 Dart 编译器看到  `@JsonCodable()` 注释时，它会立即实时定位到 JsonCodable 宏的定义并开始执行它：

- 创建一个新的 “[augmentation class](https://github.com/dart-lang/language/blob/main/working/augmentation-libraries/feature-specification.md)”，这是一种新的语言构造，可以向现有类添加新声明，augmentation 可以分散在多个位置，无论是在单个文件内还是跨多个文件，都可以添加新的顶级声明，将新成员注入到类中，并将函数和变量包装在附加代码中。

- “阅读”开发人员对该`Vehicle`类的定义，以确定它有两个字段，`description` 和 `wheels` 

- `toJson` 向  augmentation class 添加新的方法签名

- 填写方法主体 `toJson` 以处理 `description` 和 `wheels`  字段的序列化

JsonCodable 集成支持现有的开发人员工作流程，例如热重载：

![](http://img.cdn.guoshuyu.cn/20240515_Flutter-322/image1.gif)

对于宏支持，Dart 团队也考虑未来在 Dart 中添加对数据类的内置支持，这是一项长久的任务，目前正在按照阶段的落地：

- 在今天的版本中提供了单个宏的预览，`JsonCodable` 可以让开发者开始体验和熟悉 Dart 宏。
- 如果进展顺利，后续将推进 JSON 宏变得稳定。
- 最终目标将是让 Dart 开发者社区能够自定义自己的宏。

> `JsonCodable` 宏目前还不稳定，处于实验性阶段，仅适用于 Dart `3.5.0-152`或更高版本，更多可见：https://dart.dev/go/json-codable

# 其他改进

Dart 3.4 还包含了其他一些改进，例如：

- 解决了超过 50% 的分析器代码完成错误。
- 改进了条件表达式、if-null 表达式和 switch 表达式的类型分析与语言规范 ：https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md#language-1
- 从 dart:cli 库中删除了不完整和不一致的工具。
- 解决了一些不足以改进  `dart:js_interop` 



> 参考原文：https://medium.com/dartlang/dart-3-4-bd8d23b4462a
