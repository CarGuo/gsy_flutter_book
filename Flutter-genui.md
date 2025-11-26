# Flutter 官方 LLM 动态 UI 库 flutter_genui 发布，让 App UI 自己生成 UI 

今日，Flutter 官方正式发布了它们关于 AI 大模型的 package 项目： [genui](https://github.com/flutter/genui) ，它是一个非常有趣和前沿的探索类型的项目，它的目标是**帮助开发者构建由生成式 AI 模型驱动的动态、对话式用户界面**：

> 也就是它与传统 App 中“写死的”静态界面不同，是一个可以基于 AI 模型，支持由 AI 根据与用户的实时对话动态生成 UI 的 SDK 。

![](https://img.cdn.guoshuyu.cn/image-20250909102224405.png)

当然，它并不是一个完全 Free 的动态 UI 项目，虽然看起来它是动态的，甚至可以用来做热更新，但是实际上也是存在限制条件。

首先它的作用是：**应用能够实时渲染由 AI 返回的结构化数据** ，也就是 JSON 数据，所以实际上 flutter_genui  是一个基于文本描述，然后经过 AI 返回结构化数据进行渲染驱动的过程:

> 在 SDK 里，主要是通过一个名为 `UiAgent` 的接口，它负责管理与 AI 之间的交互循环，简化了开发流程

而对于 UI ，开发者可以定义一个 AI "允许使用" 的 Flutter Widget 词汇表 Catalog ，AI 将基于这个 Catalog 来构建 UI，比如官方的 Demo 就提供了类似的 catalog 目录来限制 UI 风格：

![](https://img.cdn.guoshuyu.cn/image-20250909103412587.png)

具体来说，就是定义好的各种 `CoreCatalogItems` 通过 `GenUiManager` 的  `catalog` 配置，让 AI 知道应该用哪些组件来生成需要的 UI ：

![](https://img.cdn.guoshuyu.cn/image-20250909103614539.png)![](https://img.cdn.guoshuyu.cn/image-20250909103627749.png)

这其中 `CatalogItem` 就像是每个 Widget 的“角色卡”，它核心规定了三件重要的事情：

- **`name`**: Widget 的名字（例如 "Column", "Text", "ElevatedButton"），这是给 AI 看的，AI 会通过这个名字来指定使用哪个 Widget
- **`dataSchema`**: 一个 `Schema` 对象，它用 JSON Schema 的格式，精确定义了这个 Widget 需要的所有参数，包括参数名、类型（字符串、数字、布尔等）和是否必需，这为 AI 提供了结构化的指令
- **`widgetBuilder`**: 它负责接收 AI 返回的、符合 `dataSchema` 规范的 JSON 数据，并将其**真正地渲染**成一个 Flutter Widget

> 如果么有定义任何自定义组件，而是直接使用了 `CoreCatalogItems.asCatalog()` ，那么 AI 在生成 UI 时就只能使用 `flutter_genui` 内置的最核心的几个基础组件。

具体效果如下图所示，甚至在整个过程中，**flutter_genui  能够捕捉用户的交互行为（如按钮点击、文本输入）**，并将这些事件作为上下文信息发送回 AI，以便 AI 在下一轮对话中做出响应：

![](https://img.cdn.guoshuyu.cn/ezgif-443af9737545b2.gif)![](https://img.cdn.guoshuyu.cn/ezgif-4d8914aeada5ef.gif)

而对于 flutter_genui，主要的核心对象有：

- **`UiAgent` (门面)**: 这是开发者主要交互的入口点，它封装了 `GenUiManager` 和 `AiClient`，是整个流程的协调者。
- **`Catalog` (Widget 目录)**: 定义了 AI 可以使用的 Widget 集合，每个 `CatalogItem` 包含 Widget 的名称、数据结构（Schema）和渲染它的构建函数
- **`AiClient` (AI 客户端)**: 负责与大语言模型通信的接口，`GeminiAiClient` 是其针对 Gemini 模型的具体实现，可以拓展支持其他模型
- **`GenUiManager` (UI 状态管理器)**: 管理所有动态生成的 UI 界面（称为 "Surfaces"）的状态，它提供了 `addOrUpdateSurface` 和 `deleteSurface` 等工具供 AI 调用，并通过流（Stream）将更新通知给 UI
- **`GenUiSurface` (UI 渲染器)**: 一个 Flutter Widget，负责根据 `GenUiManager` 提供的 `UiDefinition` 递归地构建和渲染整个 UI 树

比如以下是一个简单的例字，展示了如何使用 `UiAgent`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_genui/flutter_genui.dart';

void main() {
  // 初始化 Firebase 等
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final UiAgent _uiAgent;
  final List<GenUiUpdate> _updates = [];

  @override
  void initState() {
    super.initState();
    _uiAgent = UiAgent(
      'You are a helpful AI assistant that builds UIs.',
      catalog: CoreCatalogItems.asCatalog(),
      onSurfaceAdded: _onSurfaceAdded,
    );
  }

  void _onSurfaceAdded(SurfaceAdded update) {
    setState(() {
      _updates.add(update);
    });
  }

  void _sendPrompt(String text) {
    if (text.trim().isEmpty) return;
    _uiAgent.sendRequest(UserMessage.text(text));
  }

  @override
  void dispose() {
    _uiAgent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('GenUI Demo')),
        body: Column(
          children: [
            Expanded(
              //  渲染动态 UI 界面
              child: ListView.builder(
                itemCount: _updates.length,
                itemBuilder: (context, index) {
                  final update = _updates[index];
                  return GenUiSurface(
                    host: _uiAgent.host,
                    surfaceId: update.surfaceId,
                    onEvent: (event) {
                      // UiAgent 会自动处理事件
                    },
                  );
                },
              ),
            ),
            // 聊天输入框 Widget ，调用 _sendPrompt
            // ····
          ],
        ),
      ),
    );
  }
}
```

![](https://img.cdn.guoshuyu.cn/ezgif-438ab18a0e1545.gif)

另外，在前面我们说过，AI 返回的是一个结构化的 JSON 数据，而对于 genui 来说，他底层会有一个`dart_schema_builder`   的基础工具包支持，它的核心作用是**让你能够用 Dart 代码来创建和验证 JSON Schema**：

> 可以把它理解成一个“翻译器”，在 `flutter_genui` 的世界里，AI 需要知道它有哪些 UI 组件 (Widgets) 可以使用，以及每个组件需要哪些参数，这些规则就是通过 JSON Schema 来定义

简单说，它的作用是：

- **用 Dart 构建 JSON Schema**: 开发者不需要手动编写复杂的 JSON 文件来定义规则，而是可以通过 Dart 的链式调用来构建，例如，你可以定义一个“卡片”组件，规定它必须有一个 `title` (字符串类型) 和一个 `description` (也是字符串)，还有一个可选的 `imageUrl`
- **数据验证**: 它可以根据你定义的 Schema 来验证一个 JSON 对象是否合法，这在接收 AI 返回的数据时至关重要，可以确保 AI 给出的 UI “指令”是完整且格式正确的，避免程序因数据格式错误而崩溃
- **为 AI 提供“工具”的蓝图**: `flutter_genui` 会将使用 `dart_schema_builder` 创建的 Schema 发送给大语言模型，这等于告诉 AI：“你可以使用这些工具（Widget），每个工具的参数和格式必须遵守这份说明书。”

也就是，对于 genui 底层，会使用 `dart_schema_builder` 为 Flutter Widgets (例如 `InformationCard`, `ItineraryDay`) 定义好 Schema，将这些定义好的 Widgets 注册到 `flutter_genui` 的 `Catalog` 。

之后用户输入文本，`UiAgent` 启动，`AiClient` 将对话和从 `Catalog` 中提取的 Schemas 发送给 LLM，LLM 返回一个符合某个 Schema 的 JSON 指令，`UiAgent` 和 `GenUiManager` 解析该指令，更新 UI 状态。

最后 `GenUiSurface` 监听到状态变化，使用 `Catalog` 中的构建函数，将 JSON 数据渲染成用户可见的 Flutter 界面。

**所以最终 UI 是通过 `GenUiManager` + `GenUiSurface`** 渲染出来，具体大概流程为：

- `GenUiManager` 负责管理所有 UI 界面的当前状态，内部有一个 `_surfaces` map，用来存储所有 UI 界面（`Surface`）的定义，每个 `Surface` 都有一个唯一的 `surfaceId`，其对应的值是一个 `ValueNotifier<UiDefinition?>`，这意味着当 `UiDefinition` 改变时，可以通知监听者
- 在 AI 更新时，`GenUiManager` 会更新 `_surfaces` map 中对应 `surfaceId` 的 `UiDefinition`，然后通过一个 `StreamController` (`_surfaceUpdates`) 发出 `SurfaceAdded` 或 `SurfaceUpdated` 事件，这个广播是 UI 能够自动重建的关键。

- `GenUiSurface` 是一个 `StatefulWidget`，它是将抽象的 `UiDefinition` 渲染为用户可见界面的最终执行者，它监听了 `surfaceId` 的 `ValueNotifier` ，并有一个递归 `_buildWidget` 函数
-  `GenUiSurface` 会从根 widget ID 开始，从 `UiDefinition` 中查找 widget 的 JSON 数据，然后调用 `widget.host.catalog.buildWidget` 方法，`buildWidget` 方法会找到对应的 `CatalogItem` 并执行其 `widgetBuilder`，从而创建出 Flutter Widget

所以可以看到，genui 的核心是利用 AI 大模型的 UI 组织能力，让它通过用户的描述和已有的控件目录，动态渲染和生成所需的 UI 控件。

> 话说回来，这里说到 AI 生成的核心产物是 `UiDefinition` 对象，它本质上是一个 JSON 结构，JSON 作为纯文本数据其实是可以保存的，比如我们对这部分数据进行拦截缓存，并在启动时加载渲染，**实际上这也是一个有限能力的热更新模型**。

另外，目前使用 `flutter_genui` 最方便的默认实现是基于 Firebase 使用默认的   **`FirebaseAiClient`** ，它实现了与 Firebase AI（特别是 Gemini 模型）进行通信的支持，官方默认提供的 `simple_chat` 和 `travel_app` 都是使用它。

> 你也可以在通过 **`AiClient`** 抽象接口实现自己自定义的 client 。

所以，你觉得 genui 有前景吗？





















