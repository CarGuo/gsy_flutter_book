# 谷歌 Genkit Dart 正式发布：现在可以使用 Dart 和 Flutter 构建全栈 AI 应用

Flutter 和 Dart 团队再次证明了它在 AI 场景的决心， 继 Flutter MCP 、GenUI 、Plugin Assets AI 和 Flutter Skills 之后，现在 Genkit 也正式支持 Dart ，它的最大意义在于：

> **Flutter 使用 Dart 可以直接原生实现 AI 编排框架，支持不同模型和本地场景，提供 agent workflow / tool calling / RAG 等能力** 。

因为 AI  App 并不只是包含一个 LLM 请求这种简单场景，它还会涉及 **Prompt 管理、工具调用、RAG、工作流编排、调试、监控和部署**等组合的场景，而  Genkit 的提供一个解决这样一个生产级的场景的能力。

> **`genkit-dart` 的核心目标就是将 LLM 的组织能力工程化**。

简单来说，在正常的 AI 应用开发场景，开发者通常需要自己实现：

- Prompt 组织与版本管理
- 多步骤 AI workflow
- 工具调用（function calling）
- RAG（检索增强生成）
- LLM provider 管理
- tracing 和调试
- 生产部署

而 Genkit  就是把这些能力整合成一个统一框架，本质上就是 **AI 应用的 runtime + 编排 framework** ：

```
Frontend (Web / Mobile / Flutter)
        ↓
Genkit Runtime
        ↓
LLM / Tools / Vector DB
```

对应 `genkit-dart`  的整体结构就是：

![](https://img.cdn.guoshuyu.cn/image-20260311143622546.png)

简单来说，以前你做 AI App 需要适配不同模型厂商，比如同时支持 OpenAI、Gemini 和 Claude ，你就需要在本地写不同的调用方式，或者在服务端做一层独立的 adapter 层去转换，而如果通过  Genkit ，现在你只需要：

```ts
import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:genkit_anthropic/genkit_anthropic.dart';

void main() async {
  // Initialize Genkit with plugins
  final ai = Genkit(plugins: [
    googleAI(),
    anthropic(),
  ]);

  // Call Google Gemini
  final geminiResponse = await ai.generate(
    model: googleAI.gemini('gemini-3.1-pro-preview'),
    prompt: 'Hello from Gemini',
  );

  // Call Anthropic Claude
  final claudeResponse = await ai.generate(
    model: anthropic.model('claude-opus-4.6'),
    prompt: 'Hello from Claude',
  );
}
```

在 Genkit 里整个 AI 流程都是一个 Flow ，类似一个现成的  AI pipeline ，使用 Genkit 可以将 AI 逻辑封装成能测试、能够观察和支持独立部署的函数，类似以下这种感觉：

```dart
import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';
import 'package:schemantic/schemantic.dart';

part 'travel_flow.g.dart';

// Define flow input schema with schemantic
@Schema()
abstract class $TripRequest {
  String get destination;
  int get days;
}

// Define tool input schema
@Schema()
abstract class $WeatherRequest {
  @Field(description: 'The city name')
  String get city;
}

void main() async {
  // Initialize Genkit and register the Google AI plugin
  final ai = Genkit(plugins: [googleAI()]);

  // Define a tool the model can invoke to fetch live data
  ai.defineTool(
    name: 'fetchWeather',
    description: 'Retrieves the current weather forecast for a given city',
    inputSchema: WeatherRequest.$schema,
    fn: (request, _) async => request.city.toLowerCase() == 'seattle' ? 'Rainy' : 'Sunny', 
  );

  // Construct a strongly-typed, observable flow
  final tripPlannerFlow = ai.defineFlow(
    name: 'planTrip',
    inputSchema: TripRequest.$schema,
    outputSchema: .string(),
    fn: (request, _) async {
      // Generate content using the model and tool
      final response = await ai.generate(
        model: googleAI.gemini('gemini-3.1-pro-preview'),
        prompt: 'Build a ${request.days}-day travel itinerary for ${request.destination}. '
                'Make sure to check the weather forecast first to suggest appropriate activities.',
        toolNames: ['fetchWeather'],
      );
      
      return response.text;
    },
  );

  // Run the flow
  final itinerary = await tripPlannerFlow(
    TripRequest(destination: 'Seattle', days: 3)
  );
  print(itinerary);
}
```

而对于 Genkit，它提供的核心能力主要有：

- Prompt 管理：从 Genkit 整体能力设计来看，Prompt 在 Genkit 中是结构化资源，开发者可以将 prompt 定义为独立文件，并支持：
  - 参数化
  - 类型校验
  - 版本管理

```dart
// 基本 Prompt 定义  
serverAi.definePrompt<PromptInput>(  
  name: 'echoPrompt',  
  description: 'Returns a simple prompt with one user message.',  
  inputSchema: PromptInput.$schema,  
  fn: (input, _) async {  
    return GenerateActionOptions(  
      messages: [  
        Message(  
          role: Role.user,  
          content: [TextPart(text: 'prompt says: ${input.input}')],  
        ),  
      ],  
    );  
  },  
);

// 获取远程 Prompt  
final prompts = await client.getActivePrompts(clientAi);  
final prompt = prompts.firstWhere(  
  (p) => p.name == 'example-client/echoPrompt',  
);  
final request = await prompt.call({'input': 'hello'});

```

- Genkit 内置支持 LLM 工具调用，自带了 Agent 能力的适配场景，也是用一个 Agent 开发框架 ，通过 `Action` 和 `Tool` 的抽象，你可以定义一系列函数（比如查询数据库、发邮件、搜索网页），模型可以根据用户意图自主决定调用哪些工具

```dart
@Schema()  
abstract class $WeatherInput {  
  String get location;  
}  
  
final weatherTool = ai.defineTool(  
  name: 'getWeather',  
  description: 'Gets the current weather for a location',  
  inputSchema: WeatherInput.$schema,  
  fn: (input, _) async {  
    // 调用天气 API  
    return 'Weather in ${input.location}: 72°F and sunny';  
  },  
);

genkit.defineTool(  
  name: 'transferFunds',  
  description: 'Transfers funds between accounts. Requires user approval.',  
  inputSchema: .map(.string(), .string()),  
  fn: (input, context) async {  
    final from = input['from'];  
    final to = input['to'];  
    return 'SUCCESS: Transferred funds from $from to $to';  
  },  
);
```

- Genkit 内置支持 RAG pipeline，包括有向量嵌入 (Embedding)**、**向量搜索 (Vector Search) 、检索流水线 (Retrieval Pipeline)

```dart
// 在 agentic_patterns 应用中定义 RAG 流程  
final agenticRagFlow = defineAgenticRagFlow(ai, geminiFlash);  
  
// 使用示例  
final result = await agenticRagFlow(AgenticRagInput(question: question));


final embeddings = await ai.embedMany(  
  documents: [  
    DocumentData(content: [TextPart(text: 'Hello world')]),  
  ],  
  embedder: googleAI.textEmbedding('text-embedding-004'),  
);  
  
print(embeddings.first.embedding);

```

- Genkit 提供统一模型接口，可以连接不同模型 Provider 抽象，你可以调用远程模型，也适配本地模型场景
- Observability 与调试，Genkit 提供完整的 Dev UI，用户可以看到：
  - Prompt
  - Flow execution trace
  - token 使用
  - latency
  - LLM response

![](https://img.cdn.guoshuyu.cn/image-20260311135228426.png)

- 中断机制支持人机交互场景，支持流程暂停等待外部输入

```dart
@Schema()  
abstract class $AskUserInput {  
  String get question;  
}  
  
// 在工具中触发中断  
fn: (input, context) async {  
  context.interrupt({'question': input.question});  
  // 等待外部输入后继续执行  
}
```

所以，使用 Genkit 你可以完全定制自己的 Flow，一个 Flow 可以包含多步推理、多次工具调用以及复杂的逻辑分支，这也是构建 Agent 的基石，实际上就是：

> **使用  Genkit + Flutter ，你可以让 AI + Agent 实现在不同平台一次性完成**。

```dart
/// 编排 flow
ai.defineFlow(  
  name: 'weatherFlow',  
  inputSchema: .string(defaultValue: 'What is the weather like in Boston?'),  
  outputSchema: .string(),  
  fn: (prompt, context) async {  
    final response = await ai.generate(  
      model: googleAI.gemini('gemini-3-flash-preview'),  
      prompt: prompt,  
      toolNames: ['getWeather'],  
    );  
    return response.text;  
  },  
);

final streamStory = ai.defineFlow(  
  name: 'streamStory',  
  inputSchema: .string(),  
  outputSchema: .string(),  
  streamSchema: .string(),  
  fn: (topic, context) async {  
    final stream = ai.generateStream(  
      model: googleAI.gemini('gemini-2.5-flash'),  
      prompt: 'Write a story about $topic',  
    );  
  
    await for (final chunk in stream) {  
      context.sendChunk(chunk.text);  
    }  
    return 'Story complete';  
  },  
);


// Flow 是一种 Action  
final flow = Flow(name: 'myFlow', fn: ..., actionType: 'flow');  
registry.register(flow);  // 存储在 _actions['flow']['myFlow']  
  
// Tool 也是一种 Action  
final tool = Tool(name: 'myTool', fn: ..., actionType: 'tool');  
registry.register(tool);  // 存储在 _actions['tool']['myTool']


// 查找已注册的工具  
final tool = await genkit.registry.lookupAction('tool', 'testTool');  
  
// 查找已注册的流程  
final flow = await genkit.registry.lookupAction('flow', 'testFlow');


/// Action 调用
final remoteAction = defineRemoteAction(  
  url: 'http://localhost:3400/my-flow',  
  inputSchema: .string(),  
  outputSchema: .string(),  
);  
  
final response = await remoteAction(input: 'Hello from Dart!');


```

> 所以可以看到，`genkit-dart` 就是通过可观察的 Flows  和统一的模型抽象层，让  AI 开发变得更像传统的软件工程一样简单。

我们可以简单总结下，所以在 Genkit 里，它主要定义了 AI 应用的基础构建块：

- **Actions & Flows** ： Genkit 的核心抽象，`Flow` 是一个可追踪、可观测的工作流单元，通过 `Flow` 封装的 AI 逻辑可以自动生成追踪数据，方便在 Genkit 开发 UI 中进行调试，不管是 Flow 还是 Tool，本质上都是一种可被调用的 Action
- **Registry**：通过单例模式管理所有的模型、工具、索引器等资源
- **Model 抽象层** ：定义了统一的 `GenerateRequest` 和 `GenerateResponse` 接口，可以在不改变业务逻辑的情况下，通过配置轻松切换底层模型（如从 Gemini 切换到 OpenAI）
- **Tooling (工具调用)** ：实现了函数调用（Function Calling）的封装，允许大模型调用本地 Dart 代码

其次 Genkit 还自带了丰富的插件体系，可以提供了用户的第三方集成：

- **模型支持**：`genkit_google_genai` (Gemini), `genkit_vertexai`, `genkit_openai`, `genkit_anthropic` (Claude)
- **Web 服务**：`genkit_shelf` 支持将 AI 流程直接挂载到 Dart 的标准 Web 服务器 `shelf` 上，作为 API 提供服务
- **生态适配**：`genkit_firebase_ai` 提供了与 Firebase 生态的深度集成，方便移动端开发者

最重要的是，在 `packages/genkit_mcp` 同样实现了 MCP 协议，并且还有 `packages/genkit_middleware`  文件系统中间件提供例如存储、审核或者重试支持:

``` dart
final ai = Genkit(
  plugins: [
    googleAI(),
    RetryPlugin(), // Required for retry middleware
  ],
);

final response = await ai.generate(
  model: googleAI.gemini('gemini-2.5-flash'),
  prompt: 'Reliable request',
  use: [
    retry(
      maxRetries: 3,
      retryModel: true, // Retry model validation errors (default: true)
      retryTools: false, // Retry tool execution errors (default: false)
      statuses: [StatusCodes.UNAVAILABLE], // Retry only on specific errors
    ),
  ],
);

```

例如 Demo 里的 `agentic_patterns` 也展示了如何构建 RAG  系统，实现更专业的智能体场景，比如迭代细化逻辑，让模型生成内容后，通过另一个 Action 进行自我纠错：

```dart
  final iterativeRefinementFlow = defineIterativeRefinementFlow(
    ai,
    geminiFlash,
  );
  final storyWriterFlow = defineStoryWriterFlow(ai, geminiFlash);
  final marketingCopyFlow = defineMarketingCopyFlow(ai, geminiFlash);
  final routerFlow = defineRouterFlow(ai, geminiFlash);
  final toolCallingFlow = defineToolCallingFlow(ai, geminiFlash);
  final researchAgent = defineResearchAgent(ai, geminiFlash);
  final agenticRagFlow = defineAgenticRagFlow(ai, geminiFlash);
  final statefulChatFlow = defineStatefulChatFlow(ai, geminiFlash);
  final imageGeneratorFlow = defineImageGeneratorFlow(ai, geminiFlash);


Flow<IterativeRefinementInput, String, void, void>
defineIterativeRefinementFlow(Genkit ai, ModelRef geminiFlash) {
  return ai.defineFlow(
    name: 'iterativeRefinementFlow',
    inputSchema: IterativeRefinementInput.$schema,
    outputSchema: .string(),
    fn: (input, _) async {
      var content = '';
      var feedback = '';
      var attempts = 0;

      // Step 1: Generate the initial draft
      final draftResponse = await ai.generate(
        model: geminiFlash,
        prompt:
            'Write a short, single-paragraph blog post about: ${input.topic}.',
      );
      content = draftResponse.text;

      // Step 2: Iteratively refine the content
      while (attempts < 3) {
        attempts++;

        // The "Evaluator" provides feedback
        final evaluationResponse = await ai.generate(
          model: geminiFlash,
          prompt:
              'Critique the following blog post. Is it clear, concise, and engaging? Provide specific feedback for improvement. Post: "$content"',
          outputSchema: Evaluation.$schema,
        );

        final evaluation = evaluationResponse.output;
        if (evaluation == null) {
          throw Exception('Failed to evaluate content.');
        }

        if (evaluation.satisfied) {
          break; // Exit loop if content is good enough
        }

        feedback = evaluation.critique;

        // The "Optimizer" refines the content based on feedback
        final optimizationResponse = await ai.generate(
          model: geminiFlash,
          prompt:
              'Revise the following blog post based on the feedback provided.\nPost: "$content"\nFeedback: "$feedback"',
        );
        content = optimizationResponse.text;
      }

      return content;
    },
  );
}
```

最重要的是，**虽然 Genkit 是 Google 开发的，而且和 Firebase 集成度很高（如 `genkit_firebase_ai`），但它的设计是解耦的**：

- `genkit_shelf` package 支持你使用标准的 Dart Web 框架 `shelf` 来运行 AI 逻辑，完全不依赖 Firebase
- 用户可以接入 `genkit_openai`、`genkit_anthropic` 等非 Google 的模型插件，并在任何支持 Dart 运行时的环境下部署

更有趣的是，你可以在 Flutter App 中直接使用 Genkit 执行 AI 逻辑，直接使用本地模型，也可以把 Flutter App 作为 Client 调用远端的 Genkit 服务，远程的 Genkit 服务可以用 Python，TS ，GO 甚至 Dart 来写：

![](https://img.cdn.guoshuyu.cn/image-20260311143939081.png)

最后，虽然 Genkit 只提供了  OpenAI、Claude、Gemini  等部分 Provider ，但是你完全可以通过 OpenAI 协议接入  DeepSeek、豆包、Qwen 等的支持，例如：

```dart
final ai = Genkit(  
  plugins: [  
    // DeepSeek 集成  
    openAI(  
      name: 'deepseek',
      apiKey: Platform.environment['DEEPSEEK_API_KEY'],  
      baseUrl: 'https://api.deepseek.com',  
    ),  
    // 豆包集成
    openAI(  
      name: 'doubao',
      apiKey: Platform.environment['DOUBAO_API_KEY'],  
      baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',  
    ),  
  ],  
);  
```

> 而对于没有兼容协议的模型，就需要实现自己的 `GenkitPlugin ` 。

所以，可以看到 Genkit Dart 对于 Flutter 来说是 AI 时代非常重要的提升，它让 Flutter 也能很快在多平台实现 Agent 能力，进一步放大了 Flutter 的多平台优势。

那么，你觉得 GenKit 对你来说有用吗？



# 链接

https://blog.dart.dev/announcing-genkit-dart-build-full-stack-ai-apps-with-dart-and-flutter-2a5c90a27aab

https://github.com/genkit-ai/genkit-dart









