

# Flutter 又为 AI 时代添砖加瓦：全新 ComponentLibrary 提议

近日，Flutter 开了一个新的提议，就是**给 Flutter 增加一个标准原语：`ComponentLibrary`。**

`ComponentLibrary` 的主要想法是：**给 Flutter 提供一个统一的“组件注册表 / 组件目录数据协议”**，让 GenUI、Stac、Widgetbook、OpenUI 这类工具可以用同一套方式发现、描述、调用组件。

在之前的 GenUI 我们应该就聊过，作为运行时 Agent 动态 UI 生成 lib，它支持的  A2UI  协议生成的是一套框架无关的 UI 元数据，而 Flutter 需要针对这份协议数据做 GenUI 实现，本来其实也没什么问题，但是架不住现在场景不止 GenUI ：

| 场景                        | 它需要什么                                        |
| --------------------------- | ------------------------------------------------- |
| GenUI                       | AI 需要知道有哪些组件、组件 ID 是什么、怎么传参数 |
| Server-driven UI，例如 Stac | 服务端 payload 需要映射到 Flutter widget          |
| Widgetbook / showcase       | 工具需要枚举组件，生成组件目录和 playground       |
| 自动化测试 / storyboarding  | 工具需要知道组件参数、示例、可变状态              |

但目前这些工具都需要在项目做自己的自定义支持：

- Stac 实现了自己的 custom widget registry
- GenUI catalog items 通过 `json_schema` 解析执行
- Widgetbook v3 叫 knobs，v4 叫 args
- OpenUI Library 也通过 `json_schema` 处理参数

所以如果同一个企业设计系统想同时接 GenUI、Stac、Widgetbook、自动化测试，就得写多套重复的 wrapper / registry / adapter，这就造成生态割裂：

> 同一批组件，需要不同工具用不同结构描述，但是 AI 时代来说，这种结构化能力本身就是必须的。

不得不说，这段时间让 AI  e2e 项目测试的时候确实很烦，Compose 、iOS 和鸿蒙都没有标准的 MCP 注入支持，像鸿蒙和 Android 都是 adb 和 hdc 注入加截图识别获取点位，效率和性能都太难受了，Flutter 能走 MCP 执行相对效率还还一点点，但是对 AI 不够友好。

而且随着 Material / Cupertino 逐步解耦落地，Flutter 的整体设计风格会越来越中立，所以 Flutter core 未来应该会更倾向设计系统无关方向，不把某个具体设计系统深度绑在核心层里，而是：

> “这个 App / 公司 / package 有一组组件，它们叫什么、怎么构造、怎么被工具发现。”

这个就是 `ComponentLibrary` 提议想要支持的场景，特别 GenUI / SDUI 也在推动这个需求，因为传统 Flutter 是开发者手写 widget tree 是这样的：

```dart
Column(
  children: [
    Text(...),
    ProfileCard(...),
  ],
)
```

但是在 GenUI / SDUI 里面 widget tree 可能来自：

```dart
{
  "type": "cards.profile",
  "args": {
    "name": "Asher",
    "avatarUrl": "..."
  }
}
```

也可能来自其他 LLM tool calling 或者工具渲染，这时候系统就必须知道：

> `cards.profile` 对应哪个 Flutter widget，参数怎么传，构建失败怎么报错。

所以 `ComponentLibrary` 最重要的就是**提供一个统一的组件库契约，让这些工具可以共用**。

对此，Flutter 官方这次主要设计了两个类： `Component` 和 `ComponentLibrary` ，其中 `Component` 主要用于描述单个组件，一个 `Component` 大概包含：

```dart
@immutable
class Component {
  final String id;
  final String description;
  final Widget Function(
    BuildContext context,
    Map<String, dynamic> arguments,
  ) builder;
}
```

也就是：

| 字段          | 作用                                               |
| ------------- | -------------------------------------------------- |
| `id`          | 组件唯一标识，比如 `text.primary`、`cards.profile` |
| `description` | 给 AI / 工具 / 文档看的语义描述                    |
| `builder`     | 真正把参数转换成 Flutter Widget 的函数             |

比如下面代码，`Component`  是 widget 的“注册描述和构造入口” ，这一套感觉就是从 GenUI 剥离出来的即视感：

```dart
Component(
  id: 'cards.profile',
  description: 'Displays user details alongside avatar layouts within standard dashboard feeds.',
  builder: (context, args) {
    return ProfileCard(
      displayName: args['name'] as String,
      avatarUrl: args['avatarUrl'] as String?,
    );
  },
)
```

而 `ComponentLibrary` 主要是管理一套组件的概念，大概如下：

```dart
@immutable
class ComponentLibrary {
  final String name;
  final Map<String, Component> components;

  const ComponentLibrary({
    required this.name,
    required this.components,
  });

  factory ComponentLibrary.compose(
    String name,
    List<ComponentLibrary> libraries,
  ) {
    final aggregated = <String, Component>{};
    for (final lib in libraries) {
      aggregated.addAll(lib.components);
    }
    return ComponentLibrary(name: name, components: aggregated);
  }

  Widget buildComponent(
    BuildContext context,
    String componentId,
    Map<String, dynamic> arguments,
  ) {
    final component = components[componentId];
    if (component == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('Component resolution failed within library: $name'),
        ErrorDescription('The componentId "$componentId" was not registered.'),
      ]);
    }
    return component.builder(context, arguments);
  }
}
```

 `ComponentLibrary`  主要做三件事：

- 保存一套组件
- 支持多个 library 组合 `ComponentLibrary.compose(...)` ，比如可以把 `coreDesignSystem` \ `adminDashboardComponents` \  `marketingComponents` 合成一个总库
- 根据 `componentId` 构建 widget，如果找不到组件，就抛出 Flutter 风格的 `FlutterError`

```dart
library.buildComponent(
  context,
  'cards.profile',
  {
    'name': 'Asher',
    'avatarUrl': '...',
  },
)
```

比如对应 App 企业的设计系统可以统一注册，例如：

```dart
final acmeDesignSystem = ComponentLibrary(
  name: 'AcmeCorporate',
  components: [
    Component(
      id: 'text.primary',
      description: 'Primary body text used when text is information or descriptive...',
      builder: (context, args) {
        return AcmeText(
          content: args['content'] as String,
        );
      },
    ),
    Component(
      id: 'cards.profile',
      description: 'Displays user details alongside avatar layouts within standard dashboard feeds.',
      builder: (context, args) {
        return ProfileCard(
          displayName: args['name'] as String,
          avatarUrl: args['avatarUrl'] as String?,
        );
      },
    ),
  ],
);
```

这个方向就是，设计系统的维护者把组件集中声明出来，形成一个标准 library。

另外一个方向就是给 GenUI / Server-driven UI 用，比如对于这种场景，通常需要：

```dart
Widget buildDynamicNode(
  BuildContext context,
  Map<String, dynamic> remotePayload,
) {
  return Renderer(
    context,
    library: acmeDesignSystem,
    payload: remotePayload,
  );
}
```

也就是服务端或 AI 返回 payload，Renderer 根据 payload 里的 component id 去 `ComponentLibrary` 里找对应组件，不过 Flutter 不负责做这个 `Renderer`，也不负责定义 JSON 协议，Flutter 只提供组件库结构。

另一个场景就是给 Widgetbook  之类的项目使用，例如：

```dart
Widget buildDevelopmentPlayground() {
  return Widgetbook.fromLibrary(
    library: acmeDesignSystem,
  );
}
```

也就是说，Widgetbook 这类工具可以直接读取 `ComponentLibrary`，自动生成侧边栏、组件目录、参数面板、预览页面，以前每个工具都要自己定义，以后理论上可以统一消费 `ComponentLibrary`。

当然， `ComponentLibrary` 的目标是抽象出一套 Flutter 统一的控件描述协议，但是它不做完整的链路，因为这个设计本身不是 Remote UI Parsing Engine  ：

- 不做 JSON-to-Widget parser
- 不做 AI SDK，它只是一个 layout container primitive
- 不接管 accessibility ，`Component` 不改变 rendering tree、layout behavior 和 semantics nodes
- 不接管国际化，`Component.description` 和 `ComponentLibrary.name` 主要是开发期、调试、工具索引用的，不要求 runtime localization，真正用户可见的多语言文案，还是要在 builder 里实现

当然，目前这个设计还处于草稿阶段，一些问题还需要后续解决，比如：

- 多个库合并时，ID 冲突策略还需要考虑怎么处理
- 是否需要 `InheritedComponentLibrary` ，提供类似 `Theme.of(context)` 还没定
- 它应该进 Flutter framework，还是应该先做 package？
- 安全边界也还没选好，毕竟虽然不做 JSON parser，但典型使用场景就是远程 payload / LLM payload 决定组件构建，这会带来一些安全风险
- ·····

所以 `ComponentLibrary` 的核心是暴露一个干净、独立的注册协议，第三方库可以渐进式采用，不会破坏已有的设计 ，同时又把组件设计支持提升成 Flutter framework  的统一实现，这在 AI 时代来说还是蛮有用的。

就是不知道下个版本能不能落地。

# 链接

flutter.dev/go/introduce-component-library