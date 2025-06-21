# Dart 3.8发布，新格式化，新语法支持

其实在此之前，我们就介绍过[《Dart 3.8 开始支持 Null-Aware Elements 语法》](https://juejin.cn/post/7497178325158887460) ，而本次 Dart 版本更新，主要带来了新的格式化更新，Null-Aware Elements 语法和 Web hot reload 支持等，另外还有 FFigen 和 JNIgen  互操作的未来计划。

# Formatter updates

在上一个版本里，Dart 包含一个在很重写的格式化支持，它支持新的 [“tall”样式 ](https://github.com/dart-lang/dart_style/issues/1253)，而本次 Dart 3.8 版本包含了针对大家反馈问题的修复，并添加了其他改进。

在以前的版本里，尾部逗号会强制拆分周围的结构，新的格式化程序现在会根据实际情况，再决定是否应拆分结构，然后根据需要添加或删除尾部逗号：

```dart
// Before formatter
TabBar(tabs: [Tab(text: 'A'), Tab(text: 'B')], labelColor: Colors.white70);

// After formatter
TabBar(
  tabs: [
    Tab(text: 'A'),
    Tab(text: 'B'),
  ],
  labelColor: Colors.white70,
);
```

当然，如果你更喜欢旧行为，可以使用[配置](https://github.com/dart-lang/dart_style/wiki/Configuration)标志重新启用：

```yaml
formatter:
  trailing_commas: preserve
```

另外，关于样式还添加了许多样式更改，以收紧并改善输出，例如：

```dart
// Previously released formatter (functions)
function(
  name:
      (param) => another(
        argument1,
        argument2,
      ),
);

// Dart 3.8 formatter (functions)
function(
  name: (param) => another(
    argument1,
    argument2,
  ),
);

// Previously released formatter (variables)
variable =
    target.property
        .method()
        .another();

// Dart 3.8 formatter (variables)
variable = target.property
    .method()
    .another();

```

# 交叉编译

在之前的 [《Dart 开始支持交叉编译》](https://juejin.cn/post/7500234308432445451) 我们就聊到了，Dart 新增了对从 Windows、macOS 和 Linux 开发机器编译为原生 Linux 二进制文件的支持，现在可以使用 `dart compile exe` 或 `dart compile aot-snapshot` 命令以及 `--target-os` 和 `--target-arch` 标志来做到这一点：

- --target-os=linux
- --target-arch=value：目标体系结构，可以是 arm64（64 位 ARM 处理器）或 x64（64 位处理器）

> 例如 `dart compile exe --target-os=linux --target-arch=x64 hello.dart -o hello`

![image-20250521083103699](https://img.cdn.guoshuyu.cn/image-20250521083103699.png)

有了交叉编译，开发人员可以更方便在当前设备为嵌入式设备（例如 Raspberry Pi）进行更快的编译，在非 Linux 开发人员上更快地编译基于 Linux 的后端。

# Null-aware elements

Null-Aware Elements 语法糖可以用于在 List、Set、Map 等集合中处理可能为 null 的元素或键值对，简化显式检查 null 的场景：

```dart
/////////////////之前
var listWithoutNullAwareElements = [
  if (promotableNullableValue != null) promotableNullableValue,
  if (nullable.value != null) nullable.value!,
  if (nullable.value case var value?) value,
];

/////////////////之后
var listWithNullAwareElements = [
  ?promotableNullableValue,
  ?nullable.value,
  ?nullable.value,
];
```

自然，在 Flutter 的 UI 声明里，也可以简化之前控件的 if 判断，不得不说确实比起之前的写法优雅不少：

```js

Stack(
  fit: StackFit.expand,
  children: [
    const AbsorbPointer(),
    if (widget.child != null) widget.child!,
  ],
)

/////////////////之后
Stack(
  fit: StackFit.expand,
  children: [
    const AbsorbPointer(),
    ?widget.child,
  ],
)
```

而事实上，从以下例子可以看出来，在简化 `Map` 上 Null-Aware Elements 的作用尤为明显：

```js
js 体验AI代码助手 代码解读复制代码/////////////////之前
final tag = Tag()
  ..tags = {
    if (Song.title != null) 'title': Song.title,
    if (Song.artist != null) 'artist': Song.artist,
    if (Song.album != null) 'album': Song.album,
    if (Song.year != null) 'year': Song.year.toString(),
    if (comments != null)
      'comment': comms!
          .asMap()
          .map((key, value) => MapEntry<String, Comment>(value.key, value)),
    if (Song.numberInAlbum != null) 'track': Song.numberInAlbum.toString(),
    if (Song.genre != null) 'genre': Song.genre,
    if (Song.albumArt != null) 'picture': {pic.key: pic},
  }
  ..type = 'ID3'
  ..version = '2.4';

/////////////////之后
final tag = Tag()
  ..tags = {
    'title': ?Song.title,
    'artist': ?Song.artist,
    'album': ?Song.album,
    'year': ?Song.year?.toString(),
    if (comments != null)
      'comment': comms!
          .asMap()
          .map((key, value) => MapEntry<String, Comment>(value.key, value)),
    'track': ?Song.numberInAlbum?.toString(),
    'genre': ?Song.genre,
    if (Song.albumArt != null) 'picture': {pic.key: pic},
  }
  ..type = 'ID3'
  ..version = '2.4';
```

![](https://img.cdn.guoshuyu.cn/image-20250521083415851.png)

更多可见：[《Dart 3.8 开始支持 Null-Aware Elements 语法》](https://juejin.cn/post/7497178325158887460) 



# Doc imports

现在 3.8 支持 doc imports,，这是一种新的基于注释的语法，允许在文档注释中引用外部元素而无需实际导入它们，例如  `[Future]` 和 `[Future.value]` 是从 `dart：async` 库导入的：

```dart
/// @docImport 'dart:async';
library;

/// Doc comments can now reference elements like
/// [Future] and [Future.value] from `dart:async`,
/// even if the library is not imported with an
/// actual import.
class Foo {}
```

Doc imports 支持与常规 Dart 导入相同的 URI 样式，包括 `dart:` scheme、`package:` scheme 和相对路径。但是它们不能被延迟或配置 `as`、`show`、`hide`。

# pub.dev 上的 Trending 

pub.dev 将“Most Popular Packages”替换为“Trending Packages” ，并展示了最近在采用率和社区兴趣方面表现出显著增长的包：

![](https://img.cdn.guoshuyu.cn/image-20250521083722500.png)

# Web  Hot reload 

现在，在使用 Dart Development Compiler （DDC） 时，Web 上可以使用有状态的热重载，该功能仍在迭代中，但 Dart 3.8 提供了第一次尝试它的机会：`flutter run -d chrome --web-experimental-hot-reload`

# 直接 native 互作性

本次正式推出  FFigen 和 JNIgen 的早期访问计划，目的是简化原生平台 API 集成的 codegen 解决方案，不再需要 channel ，可以实现同步调用的场景。

在这里，FFIgen 将生成绑定来包装 Objective-C 和 Swift API，而同样，JNIgen 将对 Java 和 Kotlin API 执行相同的生成和绑定。

并且和 channel 不同的是，FFIgen 和 JNIgen 除了支持同步调用 API，还支持 tree-shaking（在编译期间删除未使用的代码），并允许更多数据存在于平台层。

# 最后

从本次看来，Dart 3.8 的更新比[平平无奇的 Flutter 3.32](https://juejin.cn/spost/7506408162736766991) 有意思不少。