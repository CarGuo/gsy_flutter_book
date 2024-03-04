# Flutter 3.19 发布，快来看看有什么更新吧？

> 参考链接：https://medium.com/flutter/whats-new-in-flutter-3-19-58b1aae242d2

新年假期的尾巴，Flutter 迎来了 3.19 更新，该版本带来了 **Gemini（Google's most capable AI ） 的 Dart SDK，更好控制动画颗粒度的 Widget ，Impeller 的性能增强和 Android 优化支持，deep links 工具支持，Android 和 iOS 上的特定平台新支持，Windows Arm64 支持**等等。

> 普遍优化修复居多。

#  Gemini  Dart SDK

Google 的 AI Dart SDK Gemini 目前已经发布，pub 上的 [google_generative_ai](https://pub.dev/packages/google_generative_ai)  将 Gemini 的生成式 AI 功能支持到 Dart 或 Flutter 应用里，Google Generative AI SDK 可以更方便地让 Dart 开发人员在 App 里集成 LLM  的 AI 能力。

```dart
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  // Access your API key as an environment variable (see first step above)
  final apiKey = Platform.environment['API_KEY'];
  if (apiKey == null) {
    print('No \$API_KEY environment variable');
    exit(1);
  }
  // For text-and-image input (multimodal), use the gemini-pro-vision model
  final model = GenerativeModel(model: 'gemini-pro-vision', apiKey: apiKey);
  final (firstImage, secondImage) = await (
    File('image0.jpg').readAsBytes(),
    File('image1.jpg').readAsBytes()
  ).wait;
  final prompt = TextPart("What's different between these pictures?");
  final imageParts = [
    DataPart('image/jpeg', firstImage),
    DataPart('image/jpeg', secondImage),
  ];
  final response = await model.generateContent([
    Content.multi([prompt, ...imageParts])
  ]);
  print(response.text);
}
```

![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image1.png)

![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image2.png)

# Framework

## 滚动优化

在 3.19 之前，使用两根手指在 Flutter 列表上进行滑动时，Flutter 的滚动速度会加快到两倍，这一直是一个饱受争议的问题，现在，从 3.19 开始，**开发者可以使用 `MultiTouchDragStrategy.latestPointer`  来配置默认的 `ScrollBehavior`** ，从而让滑动效果与手指数量无关。

`ScrollBehavior.multitouchDragStrategy` 默认情况下会防止多个手指同时与可滚动对象进行交互，从而影响滚动速度，如果之前你已经依赖老板本这个多指滑动能力，那么可以通过 `MaterialApp.scrollBehavior` / `CupertinoApp.scrollBehavior` 去恢复：

```dart
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like multitouchDragStrategy
  @override
  MultitouchDragStrategy get multitouchDragStrategy => MultitouchDragStrategy.sumAllPointers;
}

// Set ScrollBehavior for an entire application.
MaterialApp(
  scrollBehavior: MyCustomScrollBehavior(),
  // ...
);
```

或者通过  `ScrollConfiguration` 进行局部配置：

```dart
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like multitouchDragStrategy
  @override
  MultitouchDragStrategy get multitouchDragStrategy => MultitouchDragStrategy.sumAllPointers;
}

// ScrollBehavior can be set for a specific widget.
final ScrollController controller = ScrollController();
ScrollConfiguration(
  behavior: MyCustomScrollBehavior(),
  child: ListView.builder(
    controller: controller,
    itemBuilder: (BuildContext context, int index) {
      return Text('Item $index');
    },
  ),
);
```

> 详细可参考：https://docs.flutter.dev/release/breaking-changes/multi-touch-scrolling

另外，本次 3.19 还修复了 [SingleChildScrollView#136871](https://github.com/flutter/flutter/pull/136871) 和 [ReorderableList#136828](https://github.com/flutter/flutter/pull/136828) 相关的崩溃问题，同时 [two_dimensional_scrollables](https://pub-web.flutter-io.cn/packages/two_dimensional_scrollables) 也修复了一些问题，比如在任一方向上正在进行滚动时出现拖动或者点击，scroll activity 将按预期停止。

最后，two_dimensional_scrollables 上的 TableView 控件也进行了多次更新，提供了需要改进，例如添加了对合并单元格的支持，并在上一个稳定版本 3.16 之后适配了更多 2D foundation。

## AnimationStyle

来自社区 [@TahaTesser](https://github.com/TahaTesser) 的贡献，现在 Flutter 开发者使用 AnimationStyle ，可以让用户快速覆盖 Widget 中的默认动画行为，就像 `MaterialApp` 、 `ExpansionTile` 和  `PopupMenuButton` ：

```dart
   popUpAnimationStyle: AnimationStyle(
            curve: Easing.emphasizedAccelerate,
            duration: Durations.medium4,
          ),
```

```dart
return MaterialApp(
      themeAnimationStyle: AnimationStyle.noAnimation,
```



## SegmentedButton.styleFrom 

来自社区成员 [@AcarFurkan](https://github.com/AcarFurkan) 的贡献，该静态方式就像其他按钮类型提供的方法一样。可以快速创建分段按钮的按钮样式，可以与其他分段按钮共享或用于配置应用的分段按钮主题。

![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image3.png)

![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image4.png)



## Adaptive Switch

Adaptive Switch 可以让 Widget 在 macOS 和 iOS 上看起来和感觉是原生的效果，并且在其他地方具有 Material Design 的外观和感觉，它不依赖于 Cupertino 库，因此它的 API 在所有平台上都完全相同。

```dart
import 'package:flutter/material.dart';

/// Flutter code sample for [Switch.adaptive].

void main() => runApp(const SwitchApp());

class SwitchApp extends StatefulWidget {
  const SwitchApp({super.key});

  @override
  State<SwitchApp> createState() => _SwitchAppState();
}

class _SwitchAppState extends State<SwitchApp> {
  bool isMaterial = true;
  bool isCustomized = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = ThemeData(
        platform: isMaterial ? TargetPlatform.android : TargetPlatform.iOS,
        adaptations: <Adaptation<Object>>[
          if (isCustomized) const _SwitchThemeAdaptation()
        ]);
    final ButtonStyle style = OutlinedButton.styleFrom(
      fixedSize: const Size(220, 40),
    );

    return MaterialApp(
      theme: theme,
      home: Scaffold(
        appBar: AppBar(title: const Text('Adaptive Switches')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            OutlinedButton(
              style: style,
              onPressed: () {
                setState(() {
                  isMaterial = !isMaterial;
                });
              },
              child: isMaterial
                  ? const Text('Show cupertino style')
                  : const Text('Show material style'),
            ),
            OutlinedButton(
              style: style,
              onPressed: () {
                setState(() {
                  isCustomized = !isCustomized;
                });
              },
              child: isCustomized
                  ? const Text('Remove customization')
                  : const Text('Add customization'),
            ),
            const SizedBox(height: 20),
            const SwitchWithLabel(label: 'enabled', enabled: true),
            const SwitchWithLabel(label: 'disabled', enabled: false),
          ],
        ),
      ),
    );
  }
}

class SwitchWithLabel extends StatefulWidget {
  const SwitchWithLabel({
    super.key,
    required this.enabled,
    required this.label,
  });

  final bool enabled;
  final String label;

  @override
  State<SwitchWithLabel> createState() => _SwitchWithLabelState();
}

class _SwitchWithLabelState extends State<SwitchWithLabel> {
  bool active = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
            width: 150,
            padding: const EdgeInsets.only(right: 20),
            child: Text(widget.label)),
        Switch.adaptive(
          value: active,
          onChanged: !widget.enabled
              ? null
              : (bool value) {
                  setState(() {
                    active = value;
                  });
                },
        ),
      ],
    );
  }
}

class _SwitchThemeAdaptation extends Adaptation<SwitchThemeData> {
  const _SwitchThemeAdaptation();

  @override
  SwitchThemeData adapt(ThemeData theme, SwitchThemeData defaultValue) {
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return defaultValue;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.yellow;
            }
            return null; // Use the default.
          }),
          trackColor: const MaterialStatePropertyAll<Color>(Colors.brown),
        );
    }
  }
}

```

> 详细可见：https://main-api.flutter.dev/flutter/material/Switch/Switch.adaptive.html



### SemanticsProperties 可访问性标识符

3.19 里`SemanticsProperties` 添加了新的可访问性标识符，为 native 可访问性层次结构中的语义节点提供标识符。

- 在 Android 上，它在辅助功能层次结构中显示为 “resource-id”

- 在 iOS 上是设置里  `UIAccessibilityElement.accessibilityIdentifier`



## MaterialStatesController

 `TextField` 和 `TextFormField` 添加了  `MaterialStatesController` ，因为在此之前，开发者无法确定 `TextFormField`  当前是否处于错误状态，例如：

- 它显示错误消息并使用了`errorBorder`
- 确定它是否 foucs，但前提是提供自己的 `FocusNode`

而现在允许开发者提供自己的 `MaterialStatesController`（类似于`ElevatedButton`），以便开发者可以完全访问有关这些控件的状态信息。

```dart
final MaterialStatesController statesController = MaterialStatesController();
statesController.addListener(valueChanged);

TextField(
  statesController: statesController,
  controller: textEditingController,
)
```



## UndoHistory stack

修复了 undo/redo 历史在日语键盘上可能消失的问题，并使其现在可以在将条目推送到 UndoHistory 堆栈之前对其进行修改。

`UndoHistory` 是一个提供撤消/重做功能的 Widget，它还具有绑定到特定于平台的实现的底层接口，监听了键盘事件以实现 undo/redo 操作。

从 Flutter 3.0.0 开始，可以将 `UndoHistoryController` 传递给 `TextField`它附带了  `UndoHistoryValue` 。

对于一个非常简单的展示，我将创建一个 UndoHistoryController 实例，将其传递给 TextField，使用 ValueListenableBuilder 监听该实例，并在构建器中的按钮上返回一行以执行撤消/重做操作。

```dart
import 'package:flutter/material.dart';

/// Flutter code sample for [UndoHistoryController].

void main() {
  runApp(const UndoHistoryControllerExampleApp());
}

class UndoHistoryControllerExampleApp extends StatelessWidget {
  const UndoHistoryControllerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final UndoHistoryController _undoController = UndoHistoryController();

  TextStyle? get enabledStyle => Theme.of(context).textTheme.bodyMedium;
  TextStyle? get disabledStyle =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              maxLines: 4,
              controller: _controller,
              focusNode: _focusNode,
              undoController: _undoController,
            ),
            ValueListenableBuilder<UndoHistoryValue>(
              valueListenable: _undoController,
              builder: (BuildContext context, UndoHistoryValue value,
                  Widget? child) {
                return Row(
                  children: <Widget>[
                    TextButton(
                      child: Text('Undo',
                          style: value.canUndo ? enabledStyle : disabledStyle),
                      onPressed: () {
                        _undoController.undo();
                      },
                    ),
                    TextButton(
                      child: Text('Redo',
                          style: value.canRedo ? enabledStyle : disabledStyle),
                      onPressed: () {
                        _undoController.redo();
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

```



# Engine

## Impeller 进度

### Android OpenGL 预览

在 3.16 稳定版本中，Flutter 官方邀请了用户在支持 Vulkan 的 Android 设备上试用 Impeller，覆盖了该领域 77% 的 Android 设备，而在过去的几个月里，Flutter 官方团队让 Impeller 的 OpenGL 达到了与 Vulkan 同等的功能，例如添加[支持 MSAA](https://github.com/flutter/engine/pull/47030)。

这意味着几乎所有 Android 设备上的 Flutter 应用都有望支持 Impeller 渲染，除了少数即将推出的剩余功能除外，例如自定义着色器和对外部纹理的完全支持，目前官方团队表示在今年晚些时候 Androd 也会将 Impeller 作为默认渲染器。

另外，Impeller 的 Vulkan 在“调试”构建中启用了超出 Skia 的附加调试功能，并且这些功能会产生额外的运行时开销。因此，有关 Impeller 性能的反馈你许来自 profile 或 release 版本，并且需要包括 DevTools 的时间表以及与同一设备上的 Skia 后端的比较。

### 路线

在实现了渲染保真度之后，在 Impeller Android 预览期间的主要关注点是性能，另外一些更大的改进也正在进行，例如能够利用 [Vulkan subpasses](https://github.com/flutter/flutter/issues/128911) 大大提高高级混合模式的性能。

此外，Flutter 官方还期望渲染策略发生变化，不再总是将 CPU 上的每条路径细分为[先模板后覆盖](https://github.com/flutter/flutter/issues/137714) ，这样的实现将大大降低 Android 和 iOS 上 Impeller 的 CPU 利用率。

最后，Flutter 还期望新的[高斯模糊](https://github.com/flutter/flutter/issues/131580)实施能匹配 Skia 实现的吞吐量，并改进 iOS 上模糊的惯用用法。

## API 改进

### 字形信息

3.19 版本包括两个新的 dart:ui 方法：`Paragraph ` 的 `getClosestGlyphInfoForOffset`  和 `getGlyphInfoAt`，这两个方式都会返回一个新类型的对象字形信息，包含段落内字符（或视觉上相连的字符序列）的尺寸。

- [Paragraph.getGlyphInfoAt](https://main-api.flutter.dev/flutter/dart-ui/Paragraph/getGlyphInfoAt.html)，查找与文本中的代码单元关联的 [GlyphInfo ](https://main-api.flutter.dev/flutter/dart-ui/GlyphInfo-class.html)
- [Paragraph.getClosestGlyphInfoForOffset](https://main-api.flutter.dev/flutter/dart-ui/Paragraph/getClosestGlyphInfoForOffset.html)，查找屏幕上最接近给定 Offset 的字形的 GlyphInfo

### GPU追踪

Metal 下的 Impeller（iOS、macOS、模拟器） 和在支持 Vulkan 的 Android 设备上，Flutter 引擎现在将在调试和 profile 构建中报告时间线中每个帧的 GPU 时间，可以在 DevTools 中的 “GPUTracer”  下检查 GPU 帧时序。

![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image5.png)

请注意，由于非 Vulkan Android 设备可能会误报其对查询 GPU 计时的支持，因此只能通过在 AndroidManifest.xml 设置标志来启用 Impeller 的 GPU 跟踪：

```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableOpenGLGPUTracing"
    android:value="true" /> 
```

## 性能优化

### Specialization Constants

Impeller 添加支持  [Specialization Constants](https://github.com/flutter/flutter/issues/119357) ，利用 Impeller 着色器中的这一功能，减少了 Flutter 引擎的未压缩二进制大小 350KB。

### Backdrop Filter 加速

3.19 版本包含一些不错的性能改进，其中就包括了 Impeller 的 Backdrop Filter 和模糊优化，特别是开源贡献者 [knopp](https://github.com/knopp) [noticed](https://github.com/flutter/flutter/issues/131567#issuecomment-1678210475) 注意到 Impeller 错误地请求了读取屏幕纹理的功能，[删除这个](https://github.com/flutter/engine/pull/47808)功能支持，在基准测试中，根据复杂程度，将包含多个背景滤镜的场景改进了 20-70%。

 同时，Impeller 在每个背景滤镜上[不再无条件存储模板缓冲区](https://github.com/flutter/engine/pull/47397)，相反，任何影响操作的剪辑都会被记录下来，并在恢复背景滤镜的保存层时重播到新的模板缓冲区中。

![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image6.png)

通过这一更改，在运行具有 Vulkan 的 Impeller 的 Pixel 7 Pro 上进行动画高级混合模式基准测试时，将平均 GPU 帧时间从 55 毫秒改进到 16 毫秒，并将 90% 的光栅线程 CPU 时间从大约 110 毫秒改进到 22 毫秒。

# Android

## Deeplinking web 验证器

3.19 开始，Flutter 的 Deeplinking web 验证器的早期版本将被推出使用。

在该版本中，Flutter Deeplinking 验证器支持 Android 上的 Web 检查，这意味着可以验证 assetlinks.json 文件的设置。

![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image7.png)

开发者可以打开DevTools，单击 “Deep Links” 选项，然后导入包含 Deeplinking 的 Flutter 项目，Deeplinking 验证器将告诉你配置是否正确。 

Flutter 希望这个工具能够成为简化的 Deeplinking ，后续将继续补全 iOS 上的 Web 检查以及 iOS 和 Android 上的应用检查的支持。

![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image8.png)

> 更多可以查阅 ：https://docs.google.com/document/d/1fnWe8EpZleMtSmP0rFm2iulqS3-gA86z8u9IsnXjJak/edit

## 支持 Share.invoke

Android 平台上 Flutter 之前缺少默认 “share” 按钮，而本次 3.19 里将开始支持它，作为 Flutter 持续努力的一部分，以确保所有默认上下文菜单按钮在每个平台上都可用。

![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image9.png)

> 更多相关进度可见：https://github.com/flutter/flutter/issues/107578

## Native assets

如果需要 Flutter 代码中与其他语言的其他函数进行互操作，现在可以在 Android 上通过执行 FFI 来处理 Native assets 。

简单来说就是，在此之前， Dart interop 一直在全面支持与 [Java 和 Kotlin](https://link.juejin.cn/?target=https%3A%2F%2Fdart.dev%2Fguides%2Flibraries%2Fjava-interop) 和 [Objective C 和 Swift](https://link.juejin.cn/?target=https%3A%2F%2Fdart.dev%2Fguides%2Flibraries%2Fobjective-c-interop) 的直接调用支持，例如在 Dart 3.2 开始，Native assets 就作为实验性测试支持，一直在解决与依赖于 Native 代码的 Dart 包分发相关的许多问题，它通过提供统一的钩子来与构建 Flutter 和独立 Dart 应用所涉及的各种构建需要。

Native Assets 可以让 Dart 包更无缝依赖和使用 Native 代码，通过 `flutter run`/`flutter build `和 `dart run`/`dart build` 构建并捆绑 Native 代码 。

> 备注：可通过 `flutter config --enable-native-assets` 和 `flutter create --template=package_ffi [package name]` 启用。

![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image10.png)

Demo [`native_add_library`](https://github.com/dart-lang/native/tree/main/pkgs/native_assets_cli/example/native_add_library)  就展示了相关使用，当 Flutter 项目依赖 `package:native_add_library` 时， 脚本会自动在 `build.dart` 命令上调用：

```dart
import 'package:native_add_library/native_add_library.dart';

void main() {
  print('Invoking a native function to calculate 1 + 2.');
  final result = add(1, 2);
  print('Invocation success: 1 + 2 = $result.');
}
```

> 更多可见：https://github.com/flutter/flutter/issues/129757

## 纹理层混合合成 (THLC) 模式

现在使 Google 地图 SDK 和文本输入框的放大镜功能时，他们都是工作在 TLHC 模式下，这会让 App 的性能得到不错的提升。

## 自定义 system-wide text selection toolbar 按键

Android 应用可以添加出现在所有文本选择菜单（长按文本时出现的菜单）中的自定义文本选择菜单项， Flutter 的 TextField 选择菜单现在包含了这些项目。

![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image11.png)

> 在 Android 上，一般可以编写一个应用，将自定义按钮添加到系统范围的文本选择工具栏上。例如上图这里 Android 应用 AnkiDroid 在文本选择工具栏中添加了 “Anki Card ”按钮，并且它可以出现在任何应用中。

# iOS

## Flutter iOS 原生字体

Flutter 文本现在在 iOS 上看起来更紧凑、更像 native，因为根据苹果设计指南，iOS 上较小的字体应该更加分散，以便在移动设备上更容易阅读，而较大的字体应该更加紧凑，以免占用太多空间。

在此之前，我们在所有情况下都错误地使用了更小、间距更大的字体，现在默认情况下 Flutter 将为较大的文本使用紧凑字体。

![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image12.png)

# 开发工具

## 开发工具更新

3.19 版本的 DevTools 的一些亮点包括：

● 在 DevTools 中添加了新功能以进行验证 Deeplinking

● 在 “Enhance Tracing” 菜单中添加了一个选项，用于跟踪平台 channel activity，这对于带有插件的应用很有用

![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image13.jpg)

●  当没有连接的应用时，性能和 CPU 分析器现在也可以使用，可以重新加载之前从 DevTools 保存的性能数据或 CPU 配置文件

● VS Code 中的 Flutter 侧边栏现在能够在当前项目未启用的情况下启用新平台，并且侧边栏中的 DevTools 菜单现在有一个在外部浏览器窗口中使用 DevTools 的选项



# 桌面

## Windows Arm64 支持

Windows 上的 Flutter 现在开始初步支持 Arm64 架构，目前仍处于开发阶段， 可以在GitHub [#62597 ](https://github.com/flutter/flutter/issues/62597)上查看进度，虽然目前对于 Flutter 开发者来说可能用处不是特别明显，但是也算是一个难得的桌面增强。





# 生态系统

## 隐私清单

**Flutter 现在包含 iOS 上的隐私清单以满足[即将推出的 Apple 要求](https://juejin.cn/post/7311876701909549065) ，所以看来一般情况下，这个 Flutter 3.19 非升不可**。

## 包生态的进展

2023 年，pub package 生态增长了 26%，从 1 月份的 38,000 个 package 增加到 12 月底的 48,000 个，截至 2024 年 1 月，Pub.dev 现在每月活跃用户超过 700,000 名，



![](http://img.cdn.guoshuyu.cn/20240216_Flutter-319/image14.png)







# 弃用和重大变更

## 放弃 Windows 7 和 8 支持

Dart 3.3 和 Flutter 3.19 版本停止对 Windows 7 和 8 的支持

## Impeller Dithering flag

正如 3.16 发布时所说的，现在全局标志 `Paint.enableDithering` 已经[删除](https://github.com/flutter/engine/pull/46745)。

## 弃用 iOS 11

Flutter 不再支持 iOS 11，由于调用某些网络 API 时会发生[运行时崩溃](https://github.com/flutter/flutter/issues/136060)， Flutter 3.16.6 及更高版本构建的应用将不再支持 iOS11 ，详细可见 ：https://juejin.cn/post/7321410906427359258。


# 最后

目前看来 Flutter 3.19 并没有什么大更新，属于季度正常迭代，主要是问题修复和性能高优化的版本，还是老规矩，坐等 3.19.6 版本。

最后，新年快乐～准备开工咯。