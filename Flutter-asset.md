# Flutter 里的 Asset  Transformer 和 Hooks ，这个实验性功能有什么用

Transformer  和 Hooks 的支持可能现在大家还不会用到，特别是 Hooks，目前它暂时还是 Dart 里的实验功能，并且还未完全在 Flutter 里开发支持，那么它们到底具备什么能力？为什么今天要聊到它？

> Hooks  主要来自 Dart Native 相关，**而 Dart Native  涉及到 Flutter 3.22 和 Dart 3.8 更新里提到的「直接互操作」的未来支持**，为了让 Dart 可以使用  FFIgen  直接同步调用  Objective-C 和 Swift ，JNIgen 直接同步调用 Java 和 Kotlin 支持，并且配套 codegen  解决方案， Dart Native 就是基础能力集合。

# Transformer 

Flutter 的 Asset Transformation 功能主要是为了让开发者可以在构建时转化项目内的 Asset  ，例如最经典的就是 ：

- 使用 `vector_graphics_compiler`  ，它可以将 SVG 文件转换为一种优化的二进制格式
- 之后可以使用 `vector_graphics` 包进行高效渲染，预编译的方式相较于运行时解析 SVG（例如 `flutter_svg` ），可以带来显著的渲染性能提升

实际使用上，大概就是增加对应配置，然后  `assets/logo.svg`  在复制到构建输出时就会由 `vector_graphics_compiler` 包进行转换：

```yaml
flutter:
  assets:
    - path: assets/logo.svg
      transformers:
        - package: vector_graphics_compiler
          args: ['--tessellate', '--font-size=14']
```

之后就可以通过  `vector_graphics` 来进行加载渲染：

```dart
import 'package:vector_graphics/vector_graphics.dart';

const Widget logo = VectorGraphic(loader: AssetBytesLoader('assets/logo.svg'));
```

另外类似的还有 `png_optimizer` 、 `grayscale_filter` 等，并且 Asset transformers  可以按声明的顺序执行，比如 `bird.png` 由 `grayscale_filter` 进行转换，然后再由 `png_optimizer` 包进行优化：

```yaml
flutter:
  assets:
    - path: assets/bird.png
      transformers:
        - package: grayscale_filter
        - package: png_optimizer
```

那么从这里看，**Asset Transformer 本质上就是一个 Dart 命令行工具**，在 Flutter 构建  `pubspec.yaml` 里面的 Asset 时，会为配置了 Transformer 的 Asset 调用相应的 Dart  CLI，也就是，除了 SVG 预编译，Transformer  功能也可以用于比如：

- **图像优化**：在构建时自动压缩图片，减小应用体积
- **代码生成**：根据 Asset 内容（如 JSON Schema）生成 Dart 代码
- **数据文件预处理**：转换或验证数据文件格式
- ····

只要有对应的 transformers ，就可以在执行时处理对应转换，比如前面的   `png_optimizer`  ，就是一个很简单的利用 Dart 实现 Image 处理的示例：

```dart
import 'dart:io';

import 'package:args/args.dart';
import 'package:image/image.dart';

const inputOptionName = 'input';
const outputOptionName = 'output';

int main(List<String> arguments) {
  // The flutter tool will invoke this program with two arguments, one for
  // the `--input` option and one for the `--output` option.
  // `--input` is the original asset file that this program should transform.
  // `--output` is where flutter expects the transformation output to be written to.
  final parser = ArgParser()
    ..addOption(inputOptionName, mandatory: true, abbr: 'i')
    ..addOption(outputOptionName, mandatory: true, abbr: 'o');

  ArgResults argResults = parser.parse(arguments);
  final String inputFilePath = argResults[inputOptionName];
  final String outputFilePath = argResults[outputOptionName];

  try {
    final Image image = decodeImage(File(inputFilePath).readAsBytesSync())!;
    File(outputFilePath).writeAsBytesSync(encodeJpg(image));

    return 0;
  } catch (e) {
    // The flutter command line tool will see a non-zero exit code (1 in this case)
    // and fail the build. Anything written to stderr by the asset transformer
    // will be surfaced by flutter.
    stderr.writeln('Unexpected exception when producing the image.\n'
        'Details: $e');
    return 1;
  }
```

当然，Asset Transformation 主要聚焦在纯粹的 Asset 到 Asset 的转换 ，这意味着 Transformer 的输入是 Asset ，输出是也是 Asset ，一般不会涉及代码编译结果的支持。

> 另外 Asset Transformation  居然[支持 hot reload](https://github.com/flutter/flutter/issues/143348) 场景，这个倒是意料之外。

# Hooks

而另外一个要聊的就是 Hooks，它就是之前的 native_assets_cli  ，只是现在被称为 Hooks ，它其实就是 [dart-lang/native](https://github.com/dart-lang/native) 在的核心之一，dart-lang/native属于是 Dart 官方维护的一系列包的集合，**核心就是让 Dart 代码与原生代码（如 C、C++、Rust、Swift、Java/Kotlin 等）之间支持直接互操作**，并管理原生 Asset 的构建与打包 ：  

![image-20250520133547766](https://img.cdn.guoshuyu.cn/image-20250520133547766.png)

一个典型的支持场景就是 ：  

- `lib/`：包含使用 `dart:ffi`/`ffigen` 与原生代码交互的 Dart 代码
- `src/`：包含通过 `dart:ffi` 调用的原生源代码（例如 C、C++ 或 Rust 代码）
- `hook/build.dart`：实现与 Dart/Flutter SDK 通信的 CLI，用于告诉框架如何构建和捆绑原生 Asset

而在 Dart Native Assets 里有几个关键概念：

- Asset 类型
  - **`CodeAsset`**：代表已编译的原生代码，例如动态链接库（ `.so`、`.dll`、`.dylib` 文件）或静态链接库（ `.a`、`.lib` 文件）
  - **`DataAsset`**：代表原生代码可能产生或需要的其他数据文件，例如配置文件、预处理数据等 

- CLI 协议：在构建过程需要和原生 Asset Hooks（ `hook/build.dart` 和 `hook/link.dart` ）进行的通信，协议通常依赖 JSON 格式来交换构建配置和结果 ，例如输入（如 `BuildConfig`、`LinkConfig` ）和输出（如 `BuildOutput`、`LinkOutput` ）等

所以，实际上  Dart Native Assets 在构建过程中定义好输入，然后就可以通过使用各类原生构建工具（如 CMake、Cargo、Make，甚至是自定义脚本）执行定制构建，只要它们的 `hook/build.dart` 脚本能够遵守 Hooks 定义的协议即可。

## hook/build.dart

那么说回 Hooks，`hook/build.dart` 脚本是 Dart Native Assets 的核心执行单元，它在每个包含原生代码的 Dart 包，会根据 Dart/Flutter 构建系统提供的配置，对包内的原生源代码（例如 C、C++、Rust 代码）进行编译、构建成目标平台可用的 Asset ，而这些 Asset 通常是动态链接库（如 `.so`, `.dll`, `.dylib`）或静态链接库（`.a`, `.lib`）

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

另外，可以看到上面使用了 `native_toolchain_c` ，原因是为了编译原生代码，`hook/build.dart` 脚本需要和相应的原生构建工具（如 C/C++ 编译器、CMake、Rust 的 Cargo 等）进行交互，而 `dart-lang/native` 生态系统提供了一系列 "toolchain" 包，这些包封装了调用这些原生工具的 Dart API，从而简化了 `hook/build.dart` 的实现：

- `package:native_toolchain_c`：提供了与设备上安装的 C/C++ 编译器（如 GCC, Clang, MSVC）交互的 API，例如通过 `CBuilder` 
- `package:native_toolchain_cmake`：封装了调用 CMake 构建系统的逻辑，通过 `CMakeBuilder` 实现
-  `package:native_toolchain_rust`：用于与 Rust 的构建工具 Cargo 交互
- ····

而一般的交互流程会是：

- hook/build.dart 脚本启动，解析传入的 `BuildInput` 对象，获取 `BuildConfig`

- 脚本根据 `BuildConfig` 中的信息（特别是目标平台、架构、构建模式等）来配置选定的工具链，例如如果使用 CMake，则会实例化一个 `CMakeBuilder`，并向它提供 CMakeLists.txt 文件的路径、输出目录、目标平台参数等

- 工具链（如 `CBuilder` 或 `CMakeBuilder`）负责执行实际的原生构建命令，这可能包括调用 `gcc`、`clang` 编译 C/C++源文件，或执行 `cmake` 生成构建脚本并随后执行 `make` 或 `ninja` 等

- 原生构建过程完成后，会生成相应的输出（如动态库 `.so`/`.dll`/`.dylib` 或静态库 `.a`/`.lib`）

- `hook/build.dart` 脚本获取这些输出的路径（通常位于 `BuildConfig.outputDirectory` 内），然后创建相应的 `NativeCodeAsset`（或 `DataAsset`）对象，并将它们添加到 `BuildOutput` 对象中，同时声明相关的源文件依赖

## hook/link.dart 

在 Hooks 里还有一个 link.dart 角色，`hook/link.dart` 是 Dart Native Assets 系统中的一个可选脚本，它为 Dart 包提供了一个**在原生 Asset 构建完成（由 `hook/build.dart` 执行）之后，但是在应用最终打包之前，进行最后处理或链接操作的机会** 。

它的核心作用，大概就是对原生代码进行优化，特别是 Tree-Shaking 场景，例如`hook/build.dart` 产出的是静态库（`.a` 或 `.lib` 文件）时，这些静态库可能包含了大量未被 Dart 代码实际调用的原生函数。

而 `hook/link.dart` 可以在链接阶段（一般是在 Release 构建模式下，这时候 Dart AOT 编译器能提供哪些 Dart FFI 符号被实际使用的信息）将这些静态库链接成一个最终的动态库，并且只包含那些被 Dart 代码（直接或间接）引用的原生代码部分，从而有效减小最终应用的体积 ，例如：

```dart
import 'dart:convert'; 
import 'dart:io';      

import 'package:data_assets/data_assets.dart'; // 导入处理数据资产（如图片、字体等文件）的库
import 'package:hooks/hooks.dart';           // 导入Dart构建系统钩子（hooks）的库，允许在构建过程的特定阶段执行自定义逻辑
import 'package:record_use/record_use.dart'; // 导入用于记录代码使用情况的库，这对于“树摇”（tree-shaking）优化很有用

// 定义一个标识符，用于在代码使用记录中查找特定的“资产使用”实例。
// 它指定了该实例的来源URI和名称。
const multiplyIdentifier = Identifier(
  importUri: 'package:package_with_assets/package_with_assets.dart', // 资产定义的包URI
  name: 'AssetUsed', // 资产使用记录的名称，例如一个代表资产引用的类或常量
);

void main(List<String> args) async {
  // `link` 函数是hooks库提供的核心功能，它将当前逻辑注册为Dart构建过程中的一个“链接钩子”。
  // 这意味着它将在应用程序被链接（即打包成最终可执行文件）时执行。
  await link(args, (input, output) async {
    // 获取输入中包含的记录用法信息。
    // 这个`usages` getter是在下面的`LinkInput`扩展中定义的，它会读取并解析一个JSON文件。
    final usages = input.usages;

    // 筛选出所有被实际使用的资产的名称。
    // 1. `usages.instancesOf(multiplyIdentifier)`: 查找所有匹配`multiplyIdentifier`的记录实例。
    //    这些实例代表了应用程序代码中对`AssetUsed`的引用。
    // 2. `(e) => (e.instanceConstant.fields.values.first as StringConstant).value`:
    //    假设每个`AssetUsed`实例的第一个字段是一个`StringConstant`（字符串常量），
    //    这个字符串常量的值就是资产的名称（例如，'image.png', 'config.json'）。
    //    这里提取出这些资产的名称，形成一个`usedAssets`集合。
    final usedAssets = (usages.instancesOf(multiplyIdentifier) ?? []).map(
      (e) => (e.instanceConstant.fields.values.first as StringConstant).value,
    );

    // 将实际被使用的资产添加到输出中，这样它们才会被打包到最终的应用程序中。
    // 1. `input.assets.data`: 获取所有可用的数据资产。
    // 2. `.where((dataAsset) => usedAssets.contains(dataAsset.name))`:
    //    过滤这些资产，只选择那些名称包含在`usedAssets`集合中的资产。
    // 3. `output.assets.data.addAll(...)`: 将过滤后的资产添加到`output`对象的`assets.data`列表中。
    //    `output`对象代表了链接阶段的输出，添加到这里的资产将成为应用程序包的一部分。
    output.assets.data.addAll(
      input.assets.data.where(
        (dataAsset) => usedAssets.contains(dataAsset.name),
      ),
    );
  });
}

// 为`LinkInput`类添加一个扩展，以便于获取记录的用法信息。
extension on LinkInput {
  // `usages` getter负责读取并解析包含用法记录的JSON文件。
  RecordedUsages get usages {
    // 获取记录用法文件的URI。
    final usagesFile = recordedUsagesFile;
    // 读取文件内容为字符串。
    final usagesContent = File.fromUri(usagesFile!).readAsStringSync();
    // 将字符串内容解码为JSON Map。
    final usagesJson = jsonDecode(usagesContent) as Map<String, Object?>;
    // 从JSON数据构建`RecordedUsages`对象。
    final usages = RecordedUsages.fromJson(usagesJson);
    return usages;
  }
}
```

这段代码功主要用于根据应用程序的实际使用情况，智能地过滤和打包数据资产（Data Assets），按需打包，实现了 数据资产的 Tree-Shaking 。

> 一般在 Debug 构建模式下，通常不会运行 `hook/link.dart` ，因为 JIT 环境下缺乏精确的树摇信息

所以，反过来可以看到：**`hook/link.dart` 的主要驱动力是优化**，特别是通过 Tree-Shaking 减小原生代码的二进制体积。

那么，`hook/link.dart` 的条件执行，意味着具有原生 Asset 的包必须能够设计成：在 JIT/Debug 场景下仅通过 `hook/build.dart` 就能产生可用的输出，同时也要支持通过 `hook/link.dart` 路径进行优化的 Release 构建。

> 而为了方便在 `hook/build.dart` 和 `hook/link.dart` 脚本中操作这些 Asset，`dart-lang/native` 还提供了 `code_assets` 和 `data_assets` 两个包，它们分别包含了处理这两种 Asset 类型的 Dart API 

所以，对于 Hooks ，你甚至可以实现：

- 从预设的来源（ GitHub Releases）下载针对当前目标平台预编译好的动态库或静态库压缩包
- 在 `build.dart` 里存储这些文件的指纹（hashes）确保下载的完整性和安全性 
- 提供二次本地构建或者链接支持
- 生成的 Dart FFI 绑定文件
- 通过 Tree-Shaking  优化代码

另外，针对 [#164094]( https://github.com/flutter/ flutter/pull/164094) 扩展 Flutter 的 Hooks 的场景支持里，希望通过这个 PR 支持处理由 Dart Native Asset Hooks 生成或处理的 Data Asset ，也就是支持非代码文件的场景，例如：

- 由原生代码生成的配置文件
- 经过原生工具预处理或转换的数据集
- 原生数据库文件（如 SQLite 数据库的初始副本）
- ····

也就是 Hooks 未来不只是针对代码，还可以针对非代码文件资源进行处理支持，甚至可以在插件编译时进行需要的数据处理。

> 不得不说，作为构建支持脚本的钩子，在场景上确实还不错。

# 最后

可以看到，不管是  Transformer 还是 Hooks 都属于构建时的能力扩充，可能对于大部分人来说，这并不是一个常用的支持场景，但是对于灵活构建有需求时，它们将十分有用，虽然 Hooks 还处于实验性阶段，但是它们也在为未来 Dart 与原生互操作的通用性打下一个更好的基础支持。

另外，在一些场景上这两者还存在相互作用的可能，例如：

- 一个包的 `hook/build.dart` 脚本执行原生代码，生成了一个数据文件，例如一个复杂的 JSON 配置文件或预处理的文本资源
- 通过 [#164094]( https://github.com/flutter/ flutter/pull/164094)  的机制，这个由原生钩子生成的 Data Asset 被 Flutter 构建识别并准备打包到应用的 Asset Bundle 中
- 如果这个由原生钩子生成的 Data Asset 的路径恰好也被声明在了 `pubspec.yaml` 的 `flutter.assets` 部分，并且还为其配置了一个 Asset Transformer，那么理论上这个 Transformer 也会对这个来自原生钩子的 Data Asset 进行进一步处理

> 当然，其实更直接的做法是通过 hook/link.dart，这里只是展示路径上的可能。

那么，你觉得 ransformer/Hooks 对你来说，是不是一个有用的支持？

# 参考链接

- https://docs.flutter.dev/ui/assets/asset-transformation

- https://github.com/dart-lang/native/

