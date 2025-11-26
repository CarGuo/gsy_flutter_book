# Dart 3.10 发布，快来看有什么更新吧

和 [Flutter 3.38](https://juejin.cn/post/7571693273728696356) 一起更新的还有 Dart 3.10 ，同 Flutter 3.38 一样，Dart 3.10 也带来比较丰富的更新，其中包括 dot shorthands、Analyzer plugins、Build hooks、Deprecation annotations 和 pub.dev 更新。

# Dot shorthands

Dart 3.10 引入了 [**dot shorthands**](https://dart.dev/language/dot-shorthands)，这项新特性允许开发者在编译器能够从上下文推断出类型时，省略冗余的类名或枚举名，例如：

```dart
/************************3.10 之前*************************/

enum LogLevel { info, warning, error, debug }

void logMessage(String message, {LogLevel level = LogLevel.info}) {
  // ... implementation
}

// Somewhere else in your app
logMessage('Failed to connect to database', level: LogLevel.error);


/************************Dot shorthands*************************/

enum LogLevel { info, warning, error, debug }

void logMessage(String message, {LogLevel level = .info}) {
  // ... implementation
}

// Somewhere else in your app
logMessage('Failed to connect to database', level: .error);
```

Dot shorthands 不仅仅用于枚举类型，你还可以将它们用于构造函数、静态方法和静态字段，例如：

```dart
// Use dot shorthand syntax on enums:
enum Status { none, running, stopped, paused }

Status currentStatus = .running; // Instead of Status.running

// Use dot shorthand syntax on a static method:
int port = .parse('8080'); // Instead of int.parse('8080')

// Uses dot shorthand syntax on a constructor:
class Point {
  final int x, y;
  Point(this.x, this.y);
  Point.origin() : x = 0, y = 0;
}

Point origin = .origin(); // Instead of Point.origin()

class _PageState extends State<Page> {
  late final AnimationController _animationController = .new(vsync: this);
  final ScrollController _scrollController = .new();
  final GlobalKey<ScaffoldMessengerState> scaffoldKey = .new();
  Map<String, Map<String, bool>> properties = .new();
  // ...
}
```

> 更多可见：https://dart.dev/language/dot-shorthands ，这个我们在之前的 [《Flutter 合并 'dot-shorthands' 语法糖》](https://juejin.cn/post/7500234308432445451)也聊过。

# Analyzer plugins

Dart 3.10 为 Dart 分析器引入了全新插件系统，开发者现在可以编写和使用自己的静态分析规则，并将其直接集成到 IDE 和命令行工具（例如 `dart analyze` 和 `flutter analyze`） 中，例如：

- 强制执行项目特定的规则，例如定制的代码检查和警告，以维护团队代码库中的规范
- 避免常见陷阱，并遵循开发者所在领域的最佳实践
- 通过提供快速修复和辅助功能，实现代码更改自动化，从而帮助自动纠正问题或迁移到新的 API

要使用分析器插件，只需将配置添加到 `analysis_options.yaml` 文件中即可：

```yaml
analyzer:
  plugins:
    - some_plugin
    - another_plugin
```

Analyzer plugins扩展了 [Dart Analyzer的](https://dart.dev/tools/analysis)功能，从而能够报告自定义信息，诊断功能（包括代码检查和警告）提供快速修复方案。，并提供辅助功能。



> 详细可见：https://dart.dev/tools/analyzer-plugins

# Build hooks 

这个我们在之前的 [《Flutter 里的 Asset Transformer 和 Hooks》](https://juejin.cn/post/7521356618174545962) 我们也聊过，它支持将原生代码（例如 C++、Rust 或 Swift）集成到 Dart 包中通常需要管理复杂的、特定于平台的构建文件，例如 CMake 或 Gradle，而 Dart 3.10 大大简化了这一过程。

目前 Build hooks  已经稳定，可以使用 hooks 编译原生代码或下载原生资源（例如动态库），并将它们直接打包到的 Dart 包中。

> 这项功能让开发者在包内重用现有的原生代码或库，无需为不同的操作系统编写单独的构建文件，例如 SPM、Gradle 或 CMake。

```
example_project/
	// Project with hooks.
	hook/
		// Add hook scripts here.
		build.dart
	lib/
		// Use your assets here.
		example.dart
	src/
		// Add native sources here.
		example_native_library.c
		example_native_library.h
	test/
	// Test your assets here.
		example_test.dart
```

Build hooks  在每个包含原生代码的 Dart 包，会根据 Dart/Flutter 构建系统提供的配置，对包内的原生源代码（例如 C、C++、Rust 代码）进行编译、构建成目标平台可用的 Asset ，而这些 Asset 通常是动态链接库（如 `.so`, `.dll`, `.dylib`）或静态链接库（`.a`, `.lib`）

> 也就是可以在插件里提供原生代码，然后最终跟随 App 再编译成平台库，这对于原生互操作场景也很重要。

例如下方就是一个简单的 hook build 示例，其中构建了 3 个原生库，并且还存在依赖关系：

```dart
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final logger =
        Logger('')
          ..level = Level.ALL
          ..onRecord.listen((record) => print(record.message));

    final builders = [
      CBuilder.library(
        name: 'debug',
        assetName: 'debug',
        sources: ['src/debug.c'],
      ),
      CBuilder.library(
        name: 'math',
        assetName: 'math',
        sources: ['src/math.c'],
        libraries: ['debug'],
      ),
      CBuilder.library(
        name: 'add',
        assetName: 'add.dart',
        sources: ['src/add.c'],
        libraries: ['math'],
      ),
    ];

    // Note: These builders need to be run sequentially because they depend on
    // each others output.
    for (final builder in builders) {
      await builder.run(input: input, output: output, logger: logger);
    }
  });
}

```

> 更多详细可见：https://dart.dev/tools/hooks

# 移除弃用项 lint

发布软件包的新主要版本（例如 1.0.0 或 0.2.0）时，最佳实践是移除之前标记为已弃用的 API，这可以保持软件包的整洁，并防止开发人员使用过时的代码，然而在发布过程中很容易忘记这一步骤。

为了解决这个问题，Dart 3.10 引入了一个新的代码检查工具： `remove_deprecations_in_breaking_versions` ，当软件包版本更新到新的主要版本时，该工具会检测遗留的已弃用元素，通过标记这些情况，该工具可以帮助确保软件包的 API 保持现代化，并易于用户理解。

![](https://img.cdn.guoshuyu.cn/image-20251113091223260.png)

# Deprecated annotation

现有的 **@Deprecated** 注解过于简单粗暴，它虽然告知开发者某个 API 已不再推荐使用，但无法体现细微差别，例如：

> 如何表明某个类不应再被扩展，但仍然可以被实例化？

为了让软件包作者能够更精确地控制其 API 的演变，Dart 3.10 引入了一套新的、更具体的弃用注释：

- [@Deprecated.extend()](https://api.dart.dev/dev/latest/dart-core/Deprecated/Deprecated.extend.html): 扩展类的功能已弃用
- [@Deprecated.implement()](https://api.dart.dev/dev/latest/dart-core/Deprecated/Deprecated.implement.html): 实现类或 mixin 的功能已弃用
- [@Deprecated.subclass()](https://api.dart.dev/dev/latest/dart-core/Deprecated/Deprecated.subclass.html): 继承（扩展或实现）类或 mixin 的功能已被弃用
- [@Deprecated.mixin()](https://api.dart.dev/dev/latest/dart-core/Deprecated/Deprecated.mixin.html): 类中使用 mixin 功能已被弃用
- [@Deprecated.instantiate()](https://api.dart.dev/dev/latest/dart-core/Deprecated/Deprecated.instantiate.html): 实例化类的功能已弃用

此外，现在可以使用 [@Deprecated.optional()](https://api.dart.dev/dev/latest/dart-core/Deprecated/Deprecated.optional.html) 来表明可选参数在未来的版本中将成为必需参数。

# Pub 更新

在 pub.dev 上管理收藏的软件包的功能迎来了重大升级，现在可以通过搜索功能或个人资料中的  [Likes tab](https://pub.dev/my-liked-packages) 进行管理， 可以使用与常规搜索相同的熟悉控件来搜索、排序和筛选收藏的软件包。

排序方式包括按点赞数、pub 积分和受欢迎程度排序，此外还改进了取消收藏软件包的界面，让用户能够更轻松地保持收藏软件包列表的整洁和最新状态。

![](https://img.cdn.guoshuyu.cn/image-20251113091612163.png)

如果选择使用搜索功能查找 liked packages，只需在查询中添加 `is:liked-by-me` 即可：![](https://img.cdn.guoshuyu.cn/image-20251113091642375.png)

另外，为了增强安全性并防止意外发布，现在可以禁用软件包的手动发布（pub publish）功能，这对于已启用自动发布工作流程，或不再积极发布的软件包来说非常理想。

可以在软件包的 **Admin**  Tab 中使用 “Enable manual publishing”  来控制这个功能：![](https://img.cdn.guoshuyu.cn/image-20251113091748609.png)

# 最后

这次更新，除了诚意满满的  [Flutter 3.38](https://juejin.cn/post/7571693273728696356)  之外， Dart 3.10 看起来也是非常不错，至少为了 Dot shorthands 和 Build hooks 就很值得更新，你觉得呢？