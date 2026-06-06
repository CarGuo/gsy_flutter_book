# Flutter GenUI 0.9 和 A2UI 0.9 发布，全动动态 UI 支持，AI 在 App 里直出界面

在之前的 [《Flutter 官方 LLM 动态 UI 库 flutter_genui 发布，让 App UI 自己生成 UI》](https://juejin.cn/post/7547639458385313855) 我们就聊过，**Flutter 已经支持让 Agent 在 App 运行中动态生成控件，而现在 GenUI 和对应的 A2UI 这次都更新了全新协议**，所以这波我们也整体来回顾下这一整套全新的 AI 动态 UI 方案。

![](https://img.cdn.guoshuyu.cn/image-20260516140826476.png)



目前在 Flutter 上整个 AI 生成 UI  可以分为两层：

- **Agent 负责生成受协议约束的 UI 意图**
- **客户端负责用组件目录和运行时把它渲染成真实 UI**

也就是这里 A2UI **模型输出的也不是 Dart、JS、HTML 这种具体代码，实际上输出的是一种结构化的 UI 描述**，因为协议是通用的，然后这里 GenUI 对接后渲染成 Flutter 的控件。

# A2UI

**所以我们还是需要聊一聊这个协议，因为它不是仅仅 Flutter 专用**。

正常流程上，Flutter 需要通过 A2UI 得到的描述，Flutter 端会通过 GenUI runtime 解析这些描述，再结合 Catalog、DataModel、SurfaceController 等机制，把它变成一套可以「*交互、更新、回流*」给 Agent 的 Flutter Widget：

![](https://img.cdn.guoshuyu.cn/a2ui_process_flow_diagram.png)

> 所以其实这里 **A2UI 就是 Agent-to-UI 的协议层**，它可以用在 Flutter ，也可以用在 CMP ，RN ，Vue 等各种场景。

我一直觉得它最大的用处就是做 Agent 应用，比如在 AI 会话或者客户场景，A2UI 可以直接给出结果而不是文字，当用户说：

- “帮我规划旅行预算”
- 然后 Agent 可以直接*生成卡片、日期选择器、预算图表、可选列表*等等，让用户直接交互和选择

**那你说这和让 AI 生成代码有什么区别**？其实还真没太大本质区别，只是如果你输出的是代码，那么可用性就低了，并且还需要额外的编译渲染。

而 A2UI 是模型生成受 schema 约束的 UI 指令，客户端再用「已经注册的组件」完成渲染，整体性能和速度会好不少，当然灵活性也会差一些：

![](https://img.cdn.guoshuyu.cn/code_generation_vs_controlled_ui_rendering.png)



那这次 A2UI v0.9 有什么特别？主要是这个版本做了很多核心调整：



#### 1、 “Standard components” 改成 “Basic components”

在这次的 *A2UI v0.9* 把原来的 「Standard components」 改为 「Basic components」，也就是 A2UI 现在不会内置什么标准设计，因为「前端、移动端、企业应用」一般都有自己的设计风格，比如  Flutter App 里会有自己的  `ProductCard`、`OrderStatusView`、`MetricChart`、`PermissionNotice`、`DeviceControlPanel` 等设计场景。

所以 A2UI 这次调整成  「Basic components”」，**核心是想提供一套参考组件和基础组件和示例组件**，所以这次协议变也明确了一个标准：

- A2UI 不绑定某一个前端框架
- A2UI 也不强制某一套 UI 组件
- A2UI 只定义 Agent 如何表达 UI 意图



#### 2、Web renderer 统一

*A2UI v0.9*  版本还引入 shared web-core，同时更新了 *React、Flutter、Angular* 等 renderer，所以 A2UI  在 0.9  版本开始生态不再是 Flutter-only 或者 React-only 方案，而是同一份 A2UI 输出，可以被不同 renderer 解析并渲染：

![](https://img.cdn.guoshuyu.cn/cross_platform_ui_portability_overview.png)

> 这个其实很重要，**因为这代表了 A2UI 逻辑可以在不同语言和框架下多端适配**，这对于现阶段的 AI Coding 场景来说很实用。

---

#### 3、Agent SDK

当然，**最重要的是 *A2UI v0.9* 提供了 Agent SDK**，而  Agent  支持生成「*合法、支持解析和校验*」的 A2UI 输出， Agent 的整体核心围绕 *schema、prompt、解析、修复、校验* 来完成工程化闭环：

![](https://img.cdn.guoshuyu.cn/a2ui_agent_sdk_workflow_diagram.png)

这里的关键点在于，A2UI 解决了「*模型输出不稳定*」问题，**输出的结果在工程里可以通过 Agent SDK 自己修复问题**， 比如生成 system prompt、描述组件 catalog、解析模型输出、修复部分格式等场景，最钟输出转换成客户端可以消费的 A2UI message。

#### 4、新增 

其他部分 A2UI v0.9 还新增和强化了几类能力：

- client-defined functions：客户端可以暴露一组受控函数给 Agent 调用，例如校验表单、计算价格、检查本地状态、触发某个有限能力，**当然这里必须强调“受控”，因为客户端不能随便把任意高风险能力暴露给模型**，这是血的教训
- client-to-server data syncing：用户在 UI 里操作表单、进度条、选择器后，状态可以**同步给服务端 Agent**，Agent 可以基于最新状态继续推理，而不是每一轮都重新让用户用文字描述
- improved error handling： 模型输出结构化 UI 时一定会出现格式错误、属性缺失、组件不存在、状态引用错误等问题，协议和 runtime 必须能够处理这些错误
- simplified modular schema：让不同组件集、不同 renderer、不同 Agent 能力更容易组合到一起

当然，**最重要的是这次修改后 Transport 更开放了** ，现在  transport interface  可以运行在 *MCP、WebSocket、REST、AG-UI、A2A* 等不同传输方式上，比如：

- A2A / WebSocket / REST / MCP / AG-UI 主要解决怎么传
- A2UI  负责“传的 UI 语义是什么”
- Flutter / React / Angular renderer   负责“最终怎么渲染”

所以也可以看出来， **A2UI 的定位更像是 Agentic UI 的中间协议层** ，主要用在  Agent 和 UI runtime 之间的语义表达。



# Flutter GenUI

那到这里就很清晰了，Flutter GenUI  就是 A2UI 在 Flutter 的运行时 SDK ，**它主要负责把 Agent 输出的结构化 UI 指令解析成 Flutter 的 可渲染的 UI**，当然，除此之外它还支持了 *用户交互、数据绑定、Surface 生命周期、下一轮 Agent 对话* 等场景，GenUI 算是 A2UI 上的一套完整实现架构：

![](https://img.cdn.guoshuyu.cn/flutter_genui_architecture_flowchart_diagram.png)

如果从使用链路上看其实链条还是很长的，不过这里主要需要关注的是三个点：

- **流式解析**  ： LLM 不一定要一次性返回完整 UI，transport adapter 可以接收 chunks，再由 parser 转成事件
- **状态驱动** ： 输出后的 UI 不只是静态输出，而是和 DataModel 绑定，用户操作可以更新状态重新渲染
- **交互回流** ： 用户在 UI 上的点击、输入、选择，不只是单纯本地事件，还可以成为下一轮 Agent 推理的上下文

![](https://img.cdn.guoshuyu.cn/ui_flowchart_with_end_to_end_process.png)

所以可以看出来，**GenUI 不是一套简单的 UI 生成，甚至你可以认为它是一套 App 端的 SSR 都行**，而这次 GenUI 0.9 也做了大更新，开始从耦合演变成分层结构。

因为旧的 GenUI 思路更像是一个集中的  `GenUiConversation`  加  `ContentGenerator` 处理，AI 输出、A2UI 消息、文本流、错误流的处理逻辑会被放在较强耦合的臭象里，而新方案根据职责对实现进行了拆分：

![](https://img.cdn.guoshuyu.cn/architecture_evolution_comparison_diagram.png)

事实上这个调整还是很重要的，因为它让 Flutter GenUI  更方便接入到不同*模型、 Agent 后端和传输协议*里，比如现在你可以接：

- Firebase AI Logic
- Gemini API
- 自建 Python Agent
- A2A server
- WebSocket Agent
- REST Agent
- 本地模型
- 其他 LLM provider

> 因为现在 GenUI 没有把「模型怎么调用」写死在SDK，而是把模型接入、协议解析、状态管理和 Flutter 渲染分开。

**而 0.9 的另外一个变化就是 Prompt First**，也就是现在不只是单纯的依赖 structured output  ，因为并不是所有*模型、 provider、和运行环境*都能稳定支持严格 structured output。

所以为了让更多模型可以支持 GenUI ，这次 GenUI 选择通过 PromptBuilder 把 Catalog、A2UI schema、生成规则注入 system prompt，让模型按 A2UI 格式输出，同时 GenUI runtime 也围绕 Surface 生命周期定义了几类场景：



![](https://img.cdn.guoshuyu.cn/system_design_flow_and_actions_infographic.png)

> 实际上 Prompt First 的优势是**兼容性更好，能适配更多 LLM provider**，当然代价是 system prompt 会变得更长，token 成本会升高。

**那实际上整个 GenUI 是怎么工作的**？首先第一个要理解的就是  Catalog。

#### Catalog

Catalog 是 Flutter GenUI 里非常重要定义，**它定义了 AI 可以使用哪些组件，以及每个组件有哪些属性、事件和渲染方式**，简单来说类似：

```text
CatalogItem
  组件名字
  组件属性 schema
  Flutter builder function
  可选描述 / 示例
```

因为模型生成的不是 Dart 代码，而是类似这样的 UI 意图：

```json
{
  "type": "Button",
  "properties": {
    "label": "确认",
    "action": "submit"
  }
}
```

而 Flutter 客户端看到这个数据后，会去 Catalog 里 找 `Button`  对应的 builder，再渲染成真实 Flutter Widget。

所以 Catalog 最重要的作用就是：

- 模型不能随便生成任意代码，只能只能使用你开放的组件和属性
- 设计风格一致，UI 组合都是用的你定义好的控件
- 只开放业务上允许的组件，比如订单卡片、设备图表、权限说明、配置面板，权限可控

> 所以它也不是传统意义上的热更新，**GenUI 的 A2UI message 只是让 UI 做 `createSurface`、`updateComponents`、`updateDataModel`、`deleteSurface` 这类动作，本质是运行时状态和组件树描述的变化**。

你需要引入 GenUI SDK，提前提前注册 Catalog，之后 LLM 生成结构化 UI 描述，这些描述进入 SurfaceController 更新内部状态，然后通过 Flutter rebuild 去渲染，也就是：

> **运行时读取 JSON 数据，然后用你 App 里已经 AOT 编译好的 Dart 代码去创建 Widget 对象，Catalog 本质就是一张「字符串  - 已编译 builder」的注册表**。

简单来说就是， GenUI 的 Catalog 可以简化理解成这样：

```dart
final catalog = {
  'text': (props) => Text(props['value']),
  'button': (props) => ElevatedButton(
        onPressed: () {},
        child: Text(props['label']),
      ),
  'slider': (props) => Slider(
        value: props['value'],
        min: props['min'],
        max: props['max'],
        onChanged: (_) {},
      ),
  'chart': (props) => MyChart(data: props['data']),
};
```

然后服务端返回：

```json
{
  "type": "slider",
  "props": {
    "value": 50,
    "min": 0,
    "max": 100
  }
}
```

最后客户端做：

```dart
final builder = catalog['slider'];
return builder(props);
```

大概就是这样的一个流程，所以也不违反上架要求。

####  DataModel

如果说前面的 Catalog 是 UI 核心，**那么  DataModel 层的实现就是交互核心，DataModel 的作用就是提供生成 UI 的交互能力**，用户可以通过按键、进度条和表单，把状态变成下一轮 Agent 推理的一部分：

![](https://img.cdn.guoshuyu.cn/interactive_data_model_feedback_loop_diagram.png)

这也是 GenUI  和传统 chatbot 场景的区别，传统 chatbot 只能等用户的输入，而 **GenUI 可以让用户通过图形界面修改状态，然后把状态回流给 Agent，所以可以在操作过程里实时更新和创建新的 UI**。

#### genui_core

最后 genui_core 就是整个 GenUI 的基础实现，而这次 0.9 爷明确了 genui_core 的长期方向：**把协议处理、状态树维护、JSON Pointer、表达式求值等能力放到更纯粹的 `genui_core` 中，而 Flutter package 只负责 Flutter 渲染**，大概类似：

![](https://img.cdn.guoshuyu.cn/genui_core_processing_flow_diagram.png)

**目的其实页很简单，就是减少 Flutter 渲染层和 A2UI 协议乘的耦合，让不同端的实现更一致**，因为 Web 侧已经有 shared web-core，Flutter 如果也能把 core 层抽出来，协议行为就更容易统一。

**所以客户端也许真的不需要开发一个完整的页面功能，开发者在 App 里可能更多在维护组建库**，然后剩下的就是 AI  负责渲染和组合维护，例如：

- AI 助手里的动态卡片和动态表单
- 内部工具和运营后台
- 数据分析结果的交互式展示
- 理财、旅行、健康、设备配置等规划类场景
- IoT / 硬件控制面板的动态生成
- 开发者工具里的诊断、配置、修复向导
- 教育类、问答类场景

这些都都可以用在 A2UI 场景下得到能力提升，如果你要说问题是什么？？问题肯定是  Token ，有人说生成速度太慢，那是因为你没上 AI 满倍率速度，只要舍得上，你看效果怎么样？

> 所以核心其实还是 Token 消耗会很高，用户的操作都会变成企业的 Token 支出。

当然， GenUI 也明确，开发者可以在自己的 LLM/Agent 接入层缓存 A2UI 输出或业务状态，而对于已经得到的  Json ，你也可以自己管理缓存，什么时候需要生成，什么时候给已经有的，具体就看业务设计了。

那么，你觉得 A2UI 对你来说有用吗？



# 链接

https://docs.flutter.dev/ai/genui/get-started
