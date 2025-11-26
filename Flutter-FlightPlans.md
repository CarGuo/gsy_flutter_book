

#  回顾  Flutter Flight Plans  ，关于 Flutter 的现状和官方热门问题解答

在 Flutter 官方刚举行的 Flutter Flight Plans 直播里，除了发布 [Flutter 3.38](https://juejin.cn/post/7571693273728696356) 和 [Dart 3.10](https://juejin.cn/post/7571693273728942116) 之外，其实还有不少值得一聊的内容，例如企业级的 Flutter 案例展示，Flutter + AI 的场景，**重点还有针对大量热门问题的 Q&A（多窗口、GenUI、PC\Web 插件） 等**。

![](https://img.cdn.guoshuyu.cn/image-20251113171614115.png)

# NotebookLM 

首先，在经典案例展示上，本次 Flutter 官方展示的是今年谷歌刚发布的 Notebook LM ，这是一款由谷歌开发的 AI 驱动研究助手，核心是可以是基于用户提供的资料（如 PDF、网站、YouTube 视频等）生成信息，**并提供准确的引用来源**。

> 提供准确和有效的引用来源这个在 AI 使用里很重要。

![](https://img.cdn.guoshuyu.cn/image-20251114085255080.png)

年初，**NotebookLM  桌面版应用因为它提供的 “音频概览”（Audio Overview，可生成逼真的双人对话播客）功能迅速走红**，随着用户对移动应用的需求激增，团队决定加速开发，并选择了 Flutter ，这个案例展示了几个特点：

- **团队仅 4 名工程师**
- 基于社区插件，几乎不需触及原生层
- 全球 170 多个国家多语言同步上线
- **7 个月内完成了产品的上线发布**
- 在 Google Play Store 和 Apple App Store 上均**获得 4.8  的高分**，同时成为 Apple App Store 推荐精品应用

![](https://img.cdn.guoshuyu.cn/image-20251114090333051.png)

> 这也是继 Google Pay、Google Earth、Google Ads、Google Classroom、Google Cloud 、YouTube Create、Google One、Google Analytics 之后谷歌采用 Flutter 开发的另一个经典应用。

# Flutter + AI

在 Flutter + AI 的展示上，官方首先展示了 Gemini CLI + Flutter Extension for Gemini CLI （MCP）如何通过 AI 自动化从零开发一个 App 。

![](https://img.cdn.guoshuyu.cn/image-20251114091808629.png)

其核心主要是：

- 利用 Gemini CLI 的“思维链” (Chain of Thought) 推理来执行任务 
- 利用 Flutter  Extension  的  Dart 和 Flutter MCP 服务提供检查 Dart 错误、连接运行中的应用进行热重载、最佳实践rules，以及 **`/create app`, `/modify`, `/commit`** 等命令来驱动规范化应用开发。

整个流程从 `/create app`  开始，生成应用规格说明 (`design.md`) 和实现计划 (`implementation.md`)，然后逐步构建应用，这个过程 AI Agent 能自动执行任务、使用 `launch app` 工具启动应用，并在应用运行时进行热重载 。

![](https://img.cdn.guoshuyu.cn/image-20251114091738981.png)

最后，团队还是演示了如何使用 Google 的另一款 AI 工具 Stitch 生成设计稿 HTML 和截图，然后将文件输入 Gemini CLI，Gemini 能够基于图像生成和更新 Dart 源代码，并自动触发热重载更新 App 。

![image-20251114091720980](https://img.cdn.guoshuyu.cn/image-20251114091720980.png)

接着官方展示了两个 AI 驱动的 Demo ：

- **Gemini Live API** 实现人性化的实时语音对话，技术栈依赖 Firebase AI Logic 和 pub 插件，仅仅通过更新 System Prompt 零代码，将一个原型转化为植物识别应用 ![](https://img.cdn.guoshuyu.cn/image-20251114092938949.png)

- 另外一个是展示 AI 驱动的数独游戏，AI 代理通过 Firebase AI Logic 逐步分析、提取数据并解出答案 ![](https://img.cdn.guoshuyu.cn/image-20251114093244577.png)

最后，Flutter 团队还展示了  Flutter Gen UI ，这个我们在之前的 [《Flutter 官方 LLM 动态 UI 库 flutter_genui 发布，让 App UI 自己生成 UI》](https://juejin.cn/post/7547639458385313855) 有聊到过，**Flutter Gen UI 包可以让 AI   Agent  直接生成 Widget 而非纯文本，从而实现更动态、个性化的应用体验**。

其核心理念就是，允许 AI Agent 使用开发者提供的一个 Widget 目录 (Catalog)，然后让 AI 根据用户需求生成和展示相应的 UI 组件 ，在展示里，官方演示了如何将 Gen UI 核心包和 Firebase 适配器集成到应用中，并创建了一个 自定义 Widget Catalog Item (WorkoutCard)，让 AI 代理能够根据用户提示生成包含自定义 UI 的健身计划 。

![](https://img.cdn.guoshuyu.cn/image-20251114093831962.png)

> 实际上， Flutter Gen UI 确实是一个不错的应用场景，特别是在 AI Chat 客服的场景下。

# Q&A

接着就是本次大家最关心的 Q&A 环节，这里也问出了一些大家比较在意的热门问题。

## 1、GenUI 可以支持服务端实现吗？

官方回答是可以的，这其实这也是他们已经考虑并支持的模式，Flutter 团队预计许多开发者希望在服务端运行自己的 Agent，因为这样可以：

- 动态更新模型和逻辑
- 接入自定义数据源或私有 API
- 控制版本与安全
- 减少客户端负担

而为了这个，目前正在尝试研发一种新协议：**A2UI (Agent-to-UI Protocol)** ，Gen UI 设计为模块化，可通过 **A2UI 协议 (Agent-to-UI)** 连接到服务器端代理，它允许服务端 Agent 将生成的 UI “片段”（Widget 树结构）直接推送到客户端，实现类似“前端由 AI 驱动的 “UI Streaming” 。

A2UI 协议会与 A2A (Agent-to-Agent) 协议协同开发（Google Labs 的 Opal 团队也参与），在目前已有官方示例项目就有一个 VUA demo（Python 服务端 + Flutter 客户端）。

> 当然，Gen UI 理论上可以与本地 LLM API 一起使用，从而支持本地离线应用，但是建议用较小的 Widget 目录。

## 2、Multi-window 功能进展如何？

官方表示， 目前正在进行中，并且进展很大，桌面端多窗口功能持续有 Canonical 开发者推进：

- **Windows 平台**：已有可用的实验性 API
- **Linux / macOS**：正在适配合并中

虽然其实现在已经有可用的 API，但是还是有很多底层基础需要打包，后续的重点包括：可访问性（accessibility）、文本输入、子窗口（child windows）与模态对话框（modal dialogs）的优化。

> 目标肯定是希望桌面端最终能提供原生应用那样弹出独立窗口（例如浮动菜单、调试面板等）。

## 3、什么时候桌面和 Web 平台的核心插件能与移动端保持一致？

官方表示，其实他们知道这是一直以来的痛点，而团队正在通过  Federated Plugins 来填补平台支持的空来尝试解决：

- 允许社区/厂商分别维护平台子实现
- 官方提供统一接口与验证

这样的话社区可为 macOS / Web / Linux 等补齐实现，而目前官方正优化相关的发布流程、代码审核和质量标准。



## 4、Native Interop (FFI Gen) 什么时候可用

官方表示 Native Interop 明年将进入 Beta，提供更自动化、更安全的跨语言互操作，那 FFI Gen 解决什么？主要有：

- 自动把 C/C++/Objective-C/Swift/Java/Kotlin 的声明转换成 Dart API
- 减少手写 FFI binding 的痛苦
- 更少错误（类型对齐、内存泄漏等）
- 有官方 workflow 和安全约束检查
- 主要用于：
  - 多媒体库
  - 原生渲染器
  - 加密库
  - 自研底层 SDK

## 5、ARM Windows/Linux 支持

官方表示，这个没有稳定时间表，因为 ARM Windows 市占不高，并且 QA 成本极高，多平台 CI 支持还需要需要扩容，从目前来看，不大可能有新的投入。

## 6、Flutter Web 未来 (Wasm/SEO)

官方表示，目前重点工作在于改善 Web 集成（滚动、文本输入），以及 Wasm 方面的工作，包括支持延迟加载 (Deferred Loading)*和将生态系统迁移到新的 JS Interop 。

总结起来，Web SEO 仍是 Flutter Web 的弱项（结构化 HTML），这个也是未来需要调整的，但是看起来不会是近期的目标，而 Wasm-first 架构主要改善的是性能、内存和启动速度。

## 7、BuildRunner 性能

官方表示，建议更新到最新版本 (2.10+) 可以得到增量改进，最重要的新特性是 **AOT 编译 BuildRunner 代码** (通过 opt-in 标志开启)，某些情况下可提速 **5-10 倍** ，新特性包括：

- 对其 codegen 执行 AOT 编译
- 大幅减少重复扫描
- “增量构建” 重度优化

## 8、设计解耦 (Design Decoupling)

官方表示，Material 和 Cupertino 解构，计划是年底拆底层、明年初正式独立包，将 Material 和 Cupertino 库从核心 SDK 移出 。

## 9、Swift Package Manager (SPM)

官方表示，Cocoapods 进入维护期，SPM 将成为未来默认的 iOS 包管理工具，这也是 Apple 的强推方向，当然，后续 Plugin 生态需要全部迁移一遍，这也是成本。

## 10、**AI 会不会取代开发者？**

结论是不会，AI 是增强而不是取代，Gemini CLI 这种工具是开发者加速器，可以对比：

- AI 擅长：重复、枯燥、批量修改
- 人类擅长：结构、决策、设计、交互体验

Flutter 开发者未来更多时间应该花在：架构、交互、Prompt 设计和 AI 协同流程上。

## 11、Native Assets / Hooks

原 Native Assets 功能在 3.38 已正式发布，但改名为 Hooks，Hooks 解决的问题：

- 提供构建期钩子
- 可接入：
  - 自定义构建脚本
  - 原生资产构建
  - 自定义编译器
  - 生成 binding 文件等

Dart 团队内部认为 “Hooks” 比 “Native Assets” 更准确（因为用途不止于资产）。

## 12、其他问题

### 为什么 Flutter 不推自己的状态管理框架

因为这等于官方认定了某个方向才是对的，而现在状态管理框架百花齐放，你可以选择你自己的喜好，这才是官方认为最好的状态。

### Flutter GPU 是否还在继续

是的，但是目前暂停了，因为需要让 Impeller 在对应平台更稳定更成熟，才能给 Flutter GPU 提供更实用的场景支持。

### CanvasKit 还能继续缩小吗？

暂时给不出来时间表。

### Flutter 是否使用 Gemini 处理和分类 Github 问题

是的，但是还是需要有人监督。

### augmentations 有时间表吗

augmentations  就是一个新语言特性，可以把一个类拆分到多个文件，目前还在推进，目前还剩一些细节问题在调整，应该很快可以推出。

### Dart  可以和 Kotlin 一样使用多线程吗？

Dart 其实有多线程，支持多 isolate 、isolate background 、isolate group ，但是要不要实现内存共享，这个目前还没有计划。

### jaspr 是官方支持的吗？

这是一个 GDE 维护的项目，一个基于 Dart 的 DOM Web 框架，Flutter 团队已将其迁移用于文档基础设施。



# 最后

其实本次 Flutter Flight Plans 里，除了发布了全新版本的 Flutter 和 Dart 之外，就是本次 Q&A 环节最有意义，至少在官方的角度解答了许多大家关心的问题，当然，等 2026 Flutter 官方发布 Roadmap 后，我们就可以看看接下来的承诺是什么。

![](https://img.cdn.guoshuyu.cn/image-20251114103339161.png)

