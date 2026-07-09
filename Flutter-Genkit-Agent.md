# Flutter 开发怎么做 Agent ？从工程实战详细给你解读下

之前发 Angent 文章的时候，有人提过几次说有没有工程实战的，这次就干脆通过 Flutter 的 Agent 实现来聊一聊实战实现。

> 全文还是很长。

Flutter 开发做 Agent 几乎绕不开 GenKit ，**因为 Genkit-Dart 是谷歌官方针对 Flutter 实现的 Agent SDK** ，几乎是唯一选择，GenKit 的整体能力比较接近 LangChain，核心都是帮助应用开发把 *模型、Prompt、工具、RAG、结构化输出、观测、评测、部署* 串起来，当然能力相对 LangChain 的进阶 LangGraph 全家桶肯定弱了不少。

![](https://img.cdn.guoshuyu.cn/e09e616c31018a21c4556a8d12143205.png)

不过 **Genkit 的核心能力页不是 Chain ，在 Genkit 里一切都是围绕 Flow 展开** ，Flow 的定位主要是：

> **把一段 AI 业务逻辑包装成可类型能校验、调试、追踪、部署、评测的函数**。

大概类似这样，这个就是我自己的 GenKit Agent 项目里单次 turn 的数据流图，也是今天我们要聊的内容：

![](https://img.cdn.guoshuyu.cn/mermaid-diagram-2026-07-05-152611.png)

> 比如在我这里，***整个 Agent 项目在这一整套 Flow 里定义了 21 个 lifecycle step 编排时序**，同时 trace 里会看到对应的 `stepName`，用户的每个提交请求都会在整个 Flow 内进行状态流转*。

因为 AI workflow 在 Agent 场景不是说一次模型调用就完事了，现在一个普通正常的 Agent ，一般来说都需要：

- 检索上下文
- 管理会话历史
- 格式化输入
- 校验输出
- 组合多个模型响应
- ····

这都还只是基础，还没有各种细节和工程管理，**而 GenKit 的 Flow 就是提供工程上的*类型安全输入输出、流式输出、Developer UI 调试* 的能力**。

更具体的说， Genkit 的关键能力可以分几个层面：

- **模型统一调用**：通过 Genkit 的 provider/plugin 体系统一调用，类似 LangChain 的 model abstraction，项目里可以通过一份 `ai.generateStream(...)` 同时挂本地 gemma、LiteRT-LM 或者远端  LLM 兼容 endpoint 协议，切换只是换一个 model resolver
- **结构化输出和类型安全**：Genkit 很强调 schema，类似  JS/TS 里用 Zod 定义 inputSchema、outputSchema，整个 Flow 不只是约束 LLM 输出，同时也是在规范 Flow 变成一个稳定的可验证 API，**实际上这个点对生产系统很重要，因为如果你开发过 Agent ，就会发现真实业务里最怕模型输出 JSON 不稳定**，比如 GenKit 项目里，所有跨边界的数据结构（TraceReport、ToolResultEnvelope、ClaimExtraction、QueryRewritePlan）都带一个 `schema = "xxx.v1"` 版本号，方便未来 v2 breaking change 并存
- **工具调用**：Genkit 支持流程化和结构化的 tool calling，在 GenKit 里，**核心是怎么把工具调用安全地接进业务后端**，也就是工具怎么在 Flow 里流转
- **RAG 抽象**：Genkit 官方 RAG 抽象包括 Indexer、Embedder、Retriever 的支持，也是帮助构建 RAG flow，比如我的 Agent 项目里做了 5 种 retriever 模式（hashLexical / bm25 / hybrid / embedding / hybridEmbedding）和 384 维 n-gram embedding + BM25 + RRF 融合，全部落在 GenKit 的 retriever 抽象上
- **开发调试和观测**：可以在 Flow 里添加和查看一系列 trace、调试执行链路、看每一步模型调用和工具调用，**trace 这个如果没有，基本上 Agent 找 Bug 是不可能**

> 而 GenKit 的核心作用就在于提供了这样一套规范化的工程化能力，把 *调用模型、取业务数据、结构化输出、工具调用、RAG 检索、日志/trace、调试部署* 集成一体化的 SDK 。

**所以 GenKit 也可以看成是 Agent 的协议化编排系统**，它的定位类似 LangChain ，但是没有 LangChain 那么重，也没有 LangGraph 那么丰富的状态管理和协同能力，所以也有不少东西需要我们自己实现，比如状态机、human on Loop 这些就需要我们单独实现。

那么回到实战项目里，如下表格所示，是我用 GenKit 项目实现的一个简单 Flutter Agent 的结构，也是一个企业级的普通 Agent 需要具备的能力场景，也就是虽然已经有了 GenKit SDK，但是你要做的也不是就调调 API 就完事，更多是如何在 GenKit 上面设计一套完整的 Agent Flow 流转机制：

| 分组            | 功能和技术点                      |
| --------------- | --------------------------------- |
| **Agent 内核**  | Agent Loop                        |
|                 | Trace 包装 + TurnExecutor         |
|                 | 11 态 FSM + GenKit Flow           |
|                 | 会话可变性受控                    |
|                 | Turn Plan（意图 + 工具集合）      |
|                 | ReAct / Plan-Execute Planner      |
| **Tool**        | 11 个内置工具声明                 |
|                 | 执行、审批、超时、重试            |
|                 | 内置 handler + MCP client         |
|                 | 宿主注入的工具                    |
|                 | 工具路由投影                      |
|                 | 三种 provider 私有格式归一化      |
|                 | MCP 白名单策略结果 schema         |
|                 | 远端主题转发                      |
| **RAG**         | BM25 / Embedding / ANN / Reranker |
|                 | 知识库编排                        |
|                 | 三类物料 → chunk                  |
|                 | 5 类 query 改写协议               |
|                 | 历史摘要                          |
|                 | 数据事实上下文                    |
|                 | 数据消息持久化                    |
|                 | DDG / SearxNG / Open-Meteo        |
| **Prompt**      | 分段拼装 + 预算裁剪               |
| **能力/权限**   | 能力快照                          |
|                 | 技能声明                          |
|                 | 意图路由（中立）                  |
| **审计**        | Grounding 审计                    |
|                 | Claim 抽取与核对                  |
| **可观测**      | Trace 数据结构                    |
|                 | Eval dataset                      |
|                 | 动态回归                          |
|                 | 版本对比                          |
|                 | 观测器接口                        |
| **存储**        | 会话主库                          |
|                 | 长期记忆                          |
|                 | 附件二进制                        |
| **安全**        | 脱敏                              |
|                 | 取消令牌                          |
|                 | 上下文溢出重试                    |
| **模型**        | Chat 消息 & Model 定义            |
|                 | OpenAI 兼容客户端                 |
|                 | 本地推理运行时                    |
|                 | 多模态 content part               |
|                 | Token 估算                        |
| **GenKit 资源** | GenKit runtime/tool 注册          |

上面的那些功能在工程里表达出来，大概就会是如下所示的一个工程结构形态和能力依赖，如果图没被压小的话，应该可以看得清楚：

![](https://img.cdn.guoshuyu.cn/mermaid-diagram-2026-07-05-155705.png)

从这张图能看出来：**所有语义决策路径最后都需要收敛到 GenKit runtime 上**，而 Dart 侧的模块只是往里塞 schema、tool、prompt、evidence，然后通过模型基于这些"结构化输入"去做决策，业务都需要在 Flow 里流转。

# Plan

所以在工程上一个可用的企业级 Agent 需要考虑的点很多，**比如 Turn Plan，你不可能直接就把用户的话发给大模型去执行吧**，你需要把用户的自然语言拆分成真实意图，需要分成几步执行，需要调用哪些工具，有什么前后因果关系：

```dart
class AgentTurnPlan {
  final String intent;                       // 意图（由模型/routing plan 决定）
  final Set<String> requiredToolNames;       // 本轮必须用到的工具
  final Set<String> forbiddenToolNames;      // 本轮禁止用的工具（隐私/权限）
  final Set<String> candidateToolNames;      // 本轮候选工具
  final List<String> activeSkillIds;         // 激活的技能
  final LocalAiModelCapabilities modelCapabilities;
  // ...
}
```

> 对于模型最终输入来看到的是："*这几个工具你必须至少调一个*"、"*这些工具你不能用*"、"*这些是可以用的*"，不需要模型去猜权限或隐私是否允许。

比如在我的 Agent 实现里，**TurnPlan 用“三集合模式”表达工具边界（required / forbidden / candidate），模型不需要在自然语言层面猜"*我这个场景是不是不能调 device_control*"，因为它根本看不到 device_control 这个工具**，实际上模型看到的是：

- **能力快照**：宿主注入的能力，比如当前模型支不支持 tool_call、支不支持 image input
- **技能声明**：一个「客服 skill」可以声明"*只允许 knowledge_search + web_search + memory_get*"
- **隐私 / 审批策略**：某些工具需要用户点确认才能跑
- **意图路由**：默认返回 `modelToolChoice`，也就是"由模型基于 tool schema 自己决定"

**而且这个「意图识别」也不是直接让大模型拆分就完事了，更专业的需要分层设计**，比如：

- 第一层通过关键词和正则过滤出来一些业务意图，通过业务规则层，来处理高频、明确、无歧义的请求
- 再经过小模型进行语意拆分，处理一些常规意图
- 最后才让大模型负责意图整合和兜底

> **而且每一层还需要有置信度判断、降级策略和澄清机制等等**。

在 TurnPlan 之上，一般还会再展开出一层 `ExecutionPlan`，把 TurnPlan 分解成一序列  `ExecutionStep` ，每一步都带 `goal / toolName / required / readOnly / parallelSafe / reason`，这时候整体会有三种策略：

- `directAnswer`：不需要工具，直答
- `react`：ReAct 模式（思考-行动交替），也就是这个问题需要推理
- `planAndExecute`：先规划再执行（复杂多工具场景）

**不过 ExecutionPlan 也不是"写死的脚本"**，它是给模型的 hint，主要是写进 prompt 里，GenKit 生成过程中，模型完全可能偏离这个 plan（比如临时决定不用某工具），代码也不强制。

> **真正的"必须调用"是通过 `forceToolUse=true` 和后置的 `_ensureRequiredToolsWereUsed()` 校验来保证**，这种"soft plan + hard invariant"的组合，可以折中做到既尊重了模型的推理自由度，又保证了工程约束不被破坏。

#  prompts 模板

**接着是前面流程里的 prompts 模板**，在这里是把不同的 Dotprompt 模板融合到 Flow 流程里，主要提供这些场景：

- 主 system 指令
- 工具指导 block     
- Query 改写        
- 路由计划           
- Claim 抽取         
- Claim 核对         
- 审计失败后重生成   
- 输出质量重写       
- 工具结果综合       
- 直答提交           
- 预填工具结果       
- 缺失工具补选       
- 截断续写           
- 长期记忆行         
- 历史 turn 行       
- 通用 section block 
- 截断标记           
- 截断 turn 块       

**这些 prompt 全部走 GenKit Dotprompt（YAML frontmatter + 模板体），运行时通过 `AiPromptMessages` 接口注入 locale/上下文变量，不会在 prompt 里写死特定语言，同时也可以根据状态对 prompt 进行组装** ：

![](https://img.cdn.guoshuyu.cn/mermaid-diagram-2026-07-05-162925.png)

> **所以在 Agent 项目里 prompt 模版管理也是很重要的模块**，比如某个 locale 在流转里错乱或者丢失了，可能就会出现 prompt 模版语言选错，然后会话突然就变成了其他语言输出。

Dotprompt 的写法上，绝大多数模板体只有一句 `{{systemInstruction}}` 这种极简注入，真正的字符串在 Dart 端由 `PromptMessages.systemInstruction()` 生成后传入，这么做的原因主要是：

- **i18n 强制解耦**：模板本身不含任何自然语言，locale 从外面注入，避免"写死中文"这种反模式
- **让 Dotprompt 保持声明式**：YAML frontmatter 声明 schema 契约，模板体只是"格式化容器"，避免在模板里塞逻辑
- **利于 GenKit Developer UI 使用**：Dotprompt 可以在 UI 里预览、编辑、对比历史版本

**这里有个细节就是「双预算裁剪」，因为字符和 token 不是线性关系**，比如 CJK 单字符可能占 2-3 个 token，英文单词一个 token，所以 prompt builder 里需要两级处理，先跑一个字符预算做廉价的粗过滤（不跑 tokenizer），再跑一个  token 预算做终审（一定要跑 tokenizer），裁剪时的 fallback 优先级也是固定的：

```
conversation_turns → memory → web → knowledge → data → （user_turn 永不裁）
```

也就是，**当前用户的 user_turn 永远保留完整**，这是"用户意图不可以失真"的关键边界：

> *你可以砍历史，可以砍长期记忆，可以砍 web 搜索结果，但绝对不能砍用户这句话本身*。

# 状态机

**接着就是状态机，又分粗状态和细状态**，比如这里我在 Agent 项目里就定义了一个 9 态的粗粒度状态机，主要用来处理：

- `notInitialized`：进程刚起，尚未扫描本地 asset
- `missingModel / missingRuntime`：模型是否就绪
- `downloading`：本地模型二进制或 tflite 权重在下载
- `starting / ready`：加载完成，可以接单
- `running / stopping`：正在处理一次会话或正在关停
- `error`：不可恢复的启动失败

![](https://img.cdn.guoshuyu.cn/mermaid-diagram-2026-07-05-161022.png)

> 这个 9 态状态机关心的是"进程能不能用"，比如 manifest 存在但对应二进制模型，就要触发下载，远程模型的 Provider 是否配置，健康检查 OK 才能进 running。

**然后会有每个业务 Flow 的状态机，11 个状态按分成 3 个正常阶段**、**2 个错误/中断分支**，同时用 `composite state ` 标注 4 种终态的映射关系，**最重要的是每条迁移边界都标注触发源**（哪个方法/异常），这样可以在出问题的时候通过 trace 回溯：

![](https://img.cdn.guoshuyu.cn/mermaid-diagram-2026-07-05-161418.png)

11 态里每个状态都有明确的 Actor 标记（`fsm / llm / genkit`），这个标记极其关键：

> 它在 trace 里显式地告诉用户"*这一步的失败是模型问题还是工程问题*"，避免回归时把责任不清晰，比如 `generateOrTool` 是 llm actor，`executeTools` 是 fsm actor，`regenerateFromEvidence` 又回到 llm actor。

**因为 Agent 是一个天然多态的对象，比如：answer 会边跑边增长，thinking 也是，tool result 也可能随时加入 Flow**，如果这些"可变"缓冲区如果不加约束，很容易就在 UI 层和持久化层之间发生数据竞争，比如 UI 拿到半截 answer 就直接输出。

**所以需要给每个 Turn 都有独立的任务管理，只有状态到达 `commitTurn` 或 `interruptedCommit` 状态时，通过统一的 committer 一次性把最终 session 回复，才不至于输出错乱**。

> 比如我项目里的具体做法是「immutable session 对象 配合  replace assistantTurn」，也就是 `answerBuffer` / `thinkingBuffer` / `processSteps` 都是 controller 内部的追加式字段，每次 mutation 都产生一个新的 session 对象，只在状态到达  `commitTurn` 时由 committer 一次性把最终 session 输出。

**还有一个非常重要的约束是终态的不变量校验**，比如四种终态（committed / interruptedCommitted / stopped / failed）有严格的不变量：

```dart
switch (output.terminalOutcome) {
  case committed:            // 必须 !errorPresent && state==commitTurn
  case interruptedCommitted: // 必须 committed && errorPresent
  case stopped:              // 必须 !committed && stopped
  case failed:               // 必须 !committed
}
```

> **任一不变量违反直接 `throw StateError`**，宁可让上层看到明显的 crash，也能有"看起来 committed 但其实有 error"这种沉默污染。

# Agent Loop

**接着就是 Agent Loop**，它承担的是「从收到 request 到吐出 response」的完整流程，核心就是把 Planner 的所有计划都执行完，在 GenKit 里就是：

> **"工具循环"通过 GenKit `generateStream(maxTurns:)` 内部完成**。

![](https://img.cdn.guoshuyu.cn/pako_eNqNVm1vE0cQ_iuri4QS4Ti-O_t8dhuq4IR-aCpQCKpUXFnnu7V9ynnXvVuThChSSsgLNChAKUhAKS-lUAnxon5IVCWNxE9BOSf-lP6Ezu367IuNEaco593ZeWZ25pmZW5BMamEpK5UcOmtWDJeh6dN5guAxHcPzxnEJYcLceVSyHSc7UCqVFNOMecylMzg7YGlFLaXFTOpQNzuQSCS6VMuYzNispWsZWC91dDVTx8V.png)

这里其实有一个和很多"*自己写 ReAct 循环*"实现完全不同的关键选择：

> **Dart 侧不写 `while (needsTool)` 循环**，工具循环是通过 GenKit `generateStream(maxTurns: x)` 内部完成。

**这也是使用 Genkit 的核心，你要让 Loop 都在 GenKit 里流转，能让 GenKit 做的事绝不在本地重复实现**，因为你自己写 `while` 循环意味着你要重新处理 tool_call parsing、tool_result 回填、maxTurns 上限、cancellation、streaming chunking 等等，这其实就脱离了使用 GenKit 的意义。

另外， LLM 肯定会有执行出错的时候，所以在我项目里，我主要用了三条 recovery 路径解决这三类问题，**所有 recovery 都通过「抛异常 → 上层再次调用 `_streamWithGenkitTools`」完成链路循环**：

- **Required tool missing**：当模型输出的文本里检测到 "*疑似 tool_call 但没走正规通道*"，比如把 `<execute_tool>` 塞在自然语言里，那就抛 `_GenkitToolRequiredException`，上层捕获后通过  `forceToolUse=true`  递归重试，让 GenKit 用  `toolChoice: required` 强制走 tool schema，这样语义决策还保留在模型
- **Context overflow**：捕获到 model API "*context too long*" 时，触发 `_runCompleteContextOverflowRetries`，按 compactLevel 阶梯递增地压缩 prompt 重试，每一层压缩都对应 "*删掉历史 turn / 缩短 grounding / 剪掉 memory*" 这样的结构性动作，**从不删除当前用户 question 或 grounding facts 的核心字段**
- **Truncated answer（finishReason=length）**：如果生成被最大 token 数截断，就用 `stream_continuation_instruction` 让模型继续写，如果已经有 tool result，就调用 `_synthesizeAnswerFromToolResults`  让模型基于 tool result 重新总结，**这两条路径都是把控制权交还给模型**，本地只做 prompt 组装

这里还有一个有意思的是 **Prefill 机制** ：

> **Agent Loop 开始之前就会把已经能确定的 required 工具（比如 knowledge_search、current_time 这类无副作用工具）预跑一遍，把结果作为"已完成的 tool_call"塞进 prompt 里**。

这么做的好处是：

- 减少 GenKit maxTurns 内部循环轮数，节省 latency
- 让模型第一次生成就能看到 grounding facts，避免多轮反复
- 对副作用工具（mutating / externalAction）绝不预跑，严格遵循"*工具副作用只能由明确的模型工具调用触发*"的边界

所以整个 Agent Loop 这要有几个原则：

- **循环靠 GenKit，边界靠 Dart** ：比如 `maxTurns=6` 由 GenKit 承担，Dart 只做输入准备、边界后校验、结构性错误重试

- **异常即控制流** ：三条 recovery 都通过"*异常 → 上层再次调*"完成，trace 里能明确看到"*这一 turn 走了几次重试*"

- **语义决策会回归模型** 

# 工具

**然后就是工具层，核心就是要定义好工具的描述，然后做好数据流向和信任分级**，要定义好什么工具有风险，什么工具可以执行，工具的业务能力是什么，从工具注入、工具执行和工具结果的流转，要是可追溯而且是安全的：

![](https://img.cdn.guoshuyu.cn/mermaid-diagram-2026-07-05-163141.png)

具体到项目里，比如我的项目里内置声明了 11 个工具，比如*本地数据摘要、知识库检索、当前时间、web 搜索、URL 抓取、CLI 命令、MCP、设备控制、长期记忆的读/写/遗忘*等等，每个工具都不是说简单写个 「name 和 description」就行，我们需要的是定义一组完整的能力标签：

| 维度 | 字段 | 语义 |
|---|---|---|
| Schema | `inputJsonSchema` + `validateInput()` | 严格 `additionalProperties:false` |
| 副作用 | `sideEffectLevel` | readOnly/idempotent/mutating/externalAction |
| 并行 | `parallelSafe` + `canRunInParallel` | 只有 readOnly + parallelSafe 才并行 |
| 风险 | `riskLevel` | low/medium/high |
| 隐私 | `resultMayContainPrivateData` | 决定是否可回注远端模型 |
| 网络 | `usesNetwork` | 决定信任等级降级 |
| 预算 | `resultCharBudget` + `trimResultContent` | 结果字符预算 |

这些标签是 **runtime 决策依据**，ToolBroker 在执行前会读这些字段决定：

> 是否可以并行发起、结果是否要脱敏后回传给模型、是否要走审批流、结果超出预算是 truncate 还是 error out，这就是 Agnet 里常说的 "schema = 契约" ，**所有语义决策都基于声明式元数据，本地代码不用 hard-code 分支**。

还可以再叠加一个**信任 × 副作用矩阵**：

| Trust ＼ SideEffect | readOnly | idempotent | mutating | externalAction |
|---|:---:|:---:|:---:|:---:|
| **localTrusted** | ✅ 自动 | ✅ 自动 | ⚠️ 审批 | ❌ 拒绝 |
| **hostTrusted** | ✅ 自动 | ✅ 自动 | ⚠️ 审批 | ⚠️ 审批 |
| **externalUntrusted** | ✅ 自动 | ⚠️ 审批 | ❌ 拒绝 | ❌ 拒绝 |

> 信任等级其实也很重要，比如我把在线内置工具自动降级为 externalUntrusted ，那即便 `web_search` 是内置工具，只要它 `usesNetwork=true `，对应的结果也需要被认为为"外部不可信"，必须先脱敏再返回给模型。

整个工具执行流程在 GenKit 类似如下所示，从模型 tool_call 到落地 tool result 需要有全流程管理：

![](https://img.cdn.guoshuyu.cn/mermaid-diagram-2026-07-05-163457.png)

这里其实也有几个点值得展开说：

- **Provider 格式归一化**：不同的 LLM provider 用不同的 tool-call 输出格式，比如 OpenAI 标准 JSON、`<execute_tool>...</execute_tool>` XML 块、`<|tool_call|>call:` 前缀格式，**这些格式需要一个归一化层，任一格式无法归一化就直接抛异常，不能做字符串关键词兜底**，如果连 tool call 都解析不出来，就该让上层看到 error

- **并行策略**：只有  `sideEffectLevel=readOnly && parallelSafe=true`  的工具才能并行调用，写操作 `mutating` / `externalAction` 强制串行，避免竞态，**高危工具（`cli`、`device_control`）都强制非并行和高风险预警**，且默认需要审批

- **三级 recovery 之外还可以有个 replan**：当工具执行返回  `status: failed` 时，可以从 `ExecutionPlan` 里剔除该步骤，把失败的 tool result envelope **作为 evidence 保留**（供审计和后续 replan 使用），**但不重新生成 execution plan 的语义**，因为语义需要由模型下一轮决定

# RAG

RAG 也是很重要的一环，**它决定了能否输出有事实依据的答案**，比如我项目里的 RAG 有 4 条 grounding 通路 + 5 种检索模式 + RRF 融合：

- **knowledge_search**：静态语料检索
- **local_data_summary**：外部动态注入的实时数据（订单、日志等）
- **web_search + fetch_url**：联网信息
- **memory_get**：长期记忆

> 这四条通路完全解耦，各自维护自己的 provider 接口，Host 可以按业务替换任一路而不影响其他路。

举个例子：一个客服场景可能关掉联网通路（隐私敏感），但打开 DataContext 通路把订单表实时喂进来，而检索器（Retriever）本身是多态的，有 5 种模式：

| Mode | 打分方式 | 场景 |
|---|---|---|
| `hashLexical` | 64 维 hash embedding 的 cosine | 小语料、快速回退 |
| `bm25` | 经典 BM25(k1=1.2, b=0.75) | 关键词匹配为主 |
| `hybrid` | hashLexical + normalized BM25 相加 | 默认稳态 |
| `embedding` | 384 维 n-gram embedding 的 cosine | 语义匹配 |
| `hybridEmbedding` | embedding + 归一化 lexical | 最高质量，最慢 |

> **BM25 常量 `k1=1.2, b=0.75`** 是信息检索领域的经验默认值，对短文档语料非常合适，但 BM25 天然对中文不友好，空格 split 对中文完全无效，所以对中文可以按 unigram/bigram/trigram 全部生成 token 来弥补，**实际上具体还是看你场景和需求**。

**另外再往上一层还有  Query Rewrite**，比如我就做了 5 类 query 变体：

| Kind | 语义 | 例子（原查询："如何检测大文件读写卡顿"） |
|---|---|---|
| `originalNaturalLanguage` | 原查询 | 如何检测大文件读写卡顿 |
| `keywordTerms` | 关键词化 | 大文件 读写 卡顿 检测 |
| `technicalTerms` | 技术术语 | file I/O latency detection benchmark |
| `codeApiConfig` | 代码/API/配置名 | Dart:File.readAsBytes / iostat / fsync |
| `synonymExpression` | 同义扩展 | 检查磁盘写入延迟 观测 IO 阻塞 |

生成方式是让模型输出规范化 JSON，本地按 schema 校验，这里不写死同义词表，让模型基于当前 query 动态生成，也就是"模型=路由器"的另一个表现，5 类变体分别查询后用 RRF（Reciprocal Rank Fusion）融合：

```dart
for each variant q:
    hits[q] = retriever.search(q, limit*2)
    for hit at rank r in hits[q]:
        mergedScore[hit.chunkId] += hit.score + 1/(r+1)
sort by mergedScore
```

> 这里没有纯 RRF（纯 RRF 只用 `1/(rank+k)`），用的是**混合了原始分数 + rank 倒数**，避免完全丢失原来的语义相似度信息。

Query Rewrite 配合 RRF 的组合是项目 RAG 的基础质量能力，因为单查询 BM25 对"术语错位"（用户说"卡顿"，文档说"latency"）无解，5 类变体基本能枚举到检索失败的大部分情况。

**融合完之后还有一个 Source Diversity Reranker**：每个 sourceId 最多贡献 K 个 chunk，避免命中集中在一个文档，这个 reranker 不改变单条 chunk 的分数排序，只保证**结果的多样性**。

> 这对 grounding 非常关键：模型看到 3 个相似 chunk 反而不利于推理，看到 3 个不同角度的 chunk 才能形成有效 context。

# Trace

然后就是 trace，**它是非常重要的标准，也是 Agent 出问题时的回放支持**，通过 trace 可以知道"*Agent 做了什么、为什么这么做*"，把整个链路变成完全可审计的流程，比如我这里整个 trace 栈有 5 层，视角是"数据从生产到消费的流水线"：

![](https://img.cdn.guoshuyu.cn/image-20260705163721362.png)

> 比如 GenKit Flow 里每次 `ai.run(name, fn)` 都会自动产生一个 span，所以 TurnFlow 定义了 21 个 span name。

具体到 TraceReport 的结构：

```dart
class AgentTraceReport {
  final String schema;                 // "local_agent.trace_v1"
  final String turnId;
  final String sessionId;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<AgentTraceSpan> spans;    // 21 个 lifecycle step
  final AgentTraceModelCall? modelCall;
  final List<AgentTraceToolCall> toolCalls;
  final AgentTraceAuditor? auditor;
  final Map<String, dynamic> metrics;
}
```

> schema 名字带 `v1` 是为未来 breaking change 留后路（未来 v2 可以并存），`attributes` 是 open map，每个 lifecycle step 可以塞自己关心的 attribute，不用改结构；`logs` 支持事件日志，不只是 span 的 start/end。

然后在 Trace 上面还有可以用做几层配套：

- **Replay Harness**：把一次 turn 的所有依赖（user query、capability snapshot、tool schemas、KB 命中、模型配置）打包，可以在别的机器上完全离线重放，这样用户反馈"Agent 回答错了"，我们只要拿到 support bundle（就是 replay 包），开发者可以在自己机器上复现
- **EvalDataset**：把已标注过的 trace 转成 dataset item，提交到 git，未来有任何改动都跑 dataset 回归，dataset item 对比新 trace vs golden 时会看：tool calls 顺序/名字/参数是否匹配、auditor 判定是否一致、答案是否语义等价（可选 LLM judge）

> 通过 **DynamicRegression 配合 ReleaseDashboard**，定期跑 EvalDataset，输出 pass rate 趋势、各 tag 的分组通过率、slowest span 排行、变差的 case 列表 和 trace diff，这样在持续维护上才能一直推进。

# 脱敏

这是上面 Trace 的后续，因为 Trace 是双刃剑，它记录所有细节，也就意味着它可能泄露密钥、路径、个人信息，**所以就必须要有一套统一脱敏机制，防止 support bundle、trace 落盘、tool result 回注模型等场景把敏感信息带出去**。

比如我的项目里用的是三层策略：

- **Key-based**：命中"结构化敏感字段"名（比如 apiKey / authorization / bearer / token / secret / password / cookie）就直接 mask value 为 `[secret]`
- **Text-based**：无论 key 是否敏感，**对任何字符串内容都跑一遍 6 条串行 replace 链**，抓字符串里的隐式密钥（`api_key=xxx` / `sk-xxxx` / `ghp_xxxx` / `Authorization:` / 长 base64 / 本地路径 / stack trace 等）
- **长度限制**：单条字符串默认最长 1200 字符，防止意外泄露的大 blob

除了信息脱敏，还有两类"运行时安全"：

- **Cancellation**：CancellationToken 全程贯穿，主要用户点"停止"后所有 in-flight 的 tool call、model call、retriever query 都会立即抛 `CancelledException`，避免"用户已经放弃但 Agent 还在偷偷跑"
- **Context Overflow Guard**：在检测到 model API 返回 "context too long" 时，触发预算收紧重试，不直接 fail

# Auditor

**最后还有 Auditor 审核**，因为 LLM 在执行过程中，可能会出错，会调用错误，会输出错误结果，所以需要有对应的事实审核：

![](https://img.cdn.guoshuyu.cn/mermaid-diagram-2026-07-05-164131.png)

Auditor 有一条**极其重要的职责边界**：

> **Auditor 只能校验和拒绝，不能生成领域答案。**

**Auditor 绝不会页不能改写模型的答案**，它只能判 pass/fail 并触发 model regenerate，举个例子：

> *模型说"订单金额是 100"，evidence 显示"订单金额是 120"，那么你只能报错，不能直接修改*。

**这个边界看起来"低效"，但坚持这个边界能保持系统的可追溯性**，因为所有答案都是模型生成的，本地代码不参与语义决策，这样 trace 里的 answer 100% 反映模型能力，评估结果更可信。

**另外审计结论用最好是用结构化枚举（IssueCode）表达**：

| Code | 语义 |
|---|---|
| `emptyAnswer` | 答案脱敏/去噪后为空 |
| `missingFactReference` | 需要 fact binding 但缺失 |
| `missingGroundingFact` | 有 trusted current-tool fact 但答案没引用 |
| `exactValueMismatch` | 数值/精确值和 tool 返回不匹配 |
| `numericOutOfRange` | 数值超出 fact 允许范围 |
| `structurallyIncomplete` | 答案结构性不完整（如 JSON 破损） |
| `claimGroundingFailed` | 模型抽取的 claim 无法在 evidence 中定位 |

> 上层决策只看 `code` / `severity` / `factKind`，不看  "rendered issue text"，text 只是给用户展示用。

**Auditor 内部真正核心主要是 Claim Extraction & Grounding**：

- 让模型 A（answer model）先生成答案

- 让模型 B（可能是同一个模型的另一次调用）**从答案中抽取每一条 factual claim**，通过 tool call 提交结构化结果

- 让模型 B **对每条 claim 在 evidence 里定位**，通过另一个 tool call 提交裁决

- 任一 `verdict != grounded` 就产出 `claimGroundingFailed`

> 这么做不能保证 100% 无幻觉，但是可以显著降低"*答案里出现了 evidence 里根本没提到的事实*"的概率。

然后 Auditor 判 fail 后就可以进入 **Regenerate 循环**：

- Engine 捕获 audit issue

- 用 `audit_failure_regeneration_instruction` 组装恢复 prompt，包含**具体的 issue code + evidence**

- 让模型基于反馈重新生成

- 重新走 audit

- 然后比如最多 3 次，都失败则 hard fail（把 audit issues 结构化返回给上层）

> **Regenerate 是基于结构化反馈**，不是"让模型再试一次"这种单纯的 prompt 指令，反馈里会明确告诉模型"*你的 claim X 在 evidence 里找不到，请修正或删除*"，这样模型就有了明确的改进方向。

# GenKit 的工程总结

到这里就把 Genkit 的工程话里需要了解的大模块聊完了，不过这里没有聊更多细节，因为篇幅已经很长，不过回过头看，**前面这些模块能落地，其实很大程度是因为 GenKit 在项目里的”工程地盘“作用**，比如在我项目对 GenKit 的使用大致有几个点是刻意的：

- **共享 Runtime + Registry**：整个进程共享一个 `Genkit` 实例，所有 Flow、Tool、Prompt 都注册在同一个 registry 里，好处是 replay harness 和真实运行时用**同一份注册表**，避免"replay 时 tool 没注册"这种漂移

- **每个 Tool 都是 GenKit Tool**：11 个内置工具都通过  `ai.tool()` 注册为真实的 `genkit.Tool`，带完整的  ` JSON Schema（input）`+ `description（i18n）`，`generateStream(tools: [...])` 直接把这些 tool 传给模型，模型走标准的 tool_calls 通道，GenKit 内部完成「call → execute → feedback」循环，Dart 侧唯一要做的就是提供 tool executor 函数

- **每个 Prompt 都是 Dotprompt**： 所有 prompt 全部走 Dotprompt 格式，通过 `ai.prompt('local_agent/system_instruction')` 加载，**也就是 prompt 是版本化 asset**，可以在不动代码的前提下改文案，同时保留可回归性（asset 会打进 support bundle 供 replay 用），同时 prompt 有 YAML frontmatter，可以声明 schema、model、config，让 GenKit Developer UI 直接调试

- **每个 Turn 都是 GenKit Flow**：每次 turn 都注册成 `agent_turn_flow`，这样对 Trace 天然可视化（Developer UI 打开就能看到 21 个 lifecycle step 时间线）、Eval 天然可跑（GenKit eval harness 可以直接对 Flow 跑 dataset）、Replay 天然可行（Flow 是纯函数，只要输入相同 + 冻结模型响应，输出相同）

- **lifecycle step 都是真 span**：**凡是 GenKit 可承载的，都需要做成了真实 GenKit step/tool/span**，这样发生问题时 trace 能精确指到"哪一步生命周期出现失败"

然后一些设计原则也比较重要，前面也提到了：

- **Schema 即契约**，从工具 inputJsonSchema 到 TraceReport 的 `schema="local_agent.trace_v1"` ，整个系统的每一个"跨边界数据结构"都有 schema 名字，这样 Trace 可以 replay（schema 变了旧数据不会被误读）、Tool 能做强验证（模型输出的 tool_call 参数必须符合 schema）、Prompt 页可以复用（同一个 schema 可以喂给不同模型）

- **模型即路由器**，IntentRouter 中立不做关键词匹配，Query rewrite 通过模型生成 5 类变体，Tool 选择由模型基于 schema 决定，Audit 结论由模型基于 evidence 判定，长期记忆的写入由模型主动 memory_write，**我们本地代码只提供能力、schema、权限、隐私边界，语义决策全部交给模型**

- **Auditor 只校验不生成**，Auditor 有能力拒绝、有能力触发 regenerate、有能力返回结构化 issue，但不能替模型写答案

- **所有观测都是可 replay 的一等公民**，TraceReport 需要可序列化的，Support bundle 打包所有依赖，Replay Harness 能离线复现，EvalDataset 能定期回归

- **i18n**，Dotprompt 不写死自然语言，所有 label/description 走 messages 接口，locale 从外面注入，甚至 `<truncated>` 标记都按 locale 渲染

# 最后

所以，这就是一个很普通的、基于 GenKit 实现一个本地化 Agent 的常见工程化场合就是这样，其实这已经是一个很基础的企业 Agent 实现现场了。

> **用 GenKit 的好处是它支持的语言多，同时比如 GenKit Dart 既可以在客户端，也可以在服务端，甚至可以 GenKit Dart 和 GenKit Python/TS 交互，通过 GenKit 用在 Flutter 也可以做全平台 App 场景，所以某种程度上，这也是 Agent 时代之后，Flutter 又增长了一些的原因**。

**事实上也有人说，有 OpenCode 了为什么还要自己写 Agent**？

因为场景不同啊，**企业内 Agent 最大的意义就是你的特殊业务 Flow、你的特殊流转流程，你的意图边界不是通用的，你的工具集合不是通用的，你的隐私策略更不是通用的**，你不能用一个通用产品去把这些"边界"塞进去，或者说塞进去就变成了一堆开关、规则、if/else，这样反而更难维护。

还有人说为什么要 RAG ，比如 Claude Code 为什么不用 RAG？然后我们做 Agent 业务又一直提 RAG 的重要性？这里就是场景的区分：

- 因为代码仓库本身就是一个结构化、可搜索、能执行和验证的上下文环境，它可以直接 grep 文件、读代码、跑测试、看报错，再一步步定位问题
- **而企业业务 Agent 面对的是分散在文档库、数据库、CRM、工单、权限系统里这些私有知识和实时业务事实**，这种情况下 RAG 就更有价值、有一套检索增强层，把正确的数据在正确权限下取出来，再交给模型判断，各种图片，PPT，PDF，word ，通过多层拆分，把 tag，摘要，原文，附件都规划成一个知识库系统

> 所以场景不同，Claude Code 的核心是“在代码环境里搜索和验证”，而企业 Agent 的核心是“连接企业真实知识和业务系统”，所以企业 Agent 要 RAG，**但这个 RAG 不只是向量库，还对应有文档检索、SQL/API、权限过滤、规则校验和证据引用组成的广义外部知识系统**。

**Agent SDK 给到的价值也正好在这里**，而 GenKit 它不像 LangGraph 那么强的状态编排，也不像 LangChain 那么杂，它就是把 Flow / Tool / Prompt / Trace 这几件核心用一套规范抽好了，你需要的就是围绕它构建你自己的 FSM、Planner、Auditor、RAG 通路、Skill 系统、隐私边界。

所以，Agent 的作用从来都不是让模型变聪明，我们要做的是把 LLM 能力约束在我们的业务范围内，同时可以回溯和验证，这就是做独立 Agent 的意义。

