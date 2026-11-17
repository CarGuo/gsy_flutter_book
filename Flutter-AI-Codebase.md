# Flutter 官方表示：AI 时代代码越来越容易写，为什么还要一套代码库？

最近不管是 Shopify 或者这两个月的舆论，貌似都在说：既然 AI 已经能低成本出 Swift 和 Kotlin 的原生代码，那企业为什么还要用 Flutter？直接让两个 Agent 分别维护 iOS 和 Android 不就好了？![](/article-assets/85bb9e867fd96116b76aba5d.webp)

对于这个，Flutter 官方的回答是：**持续维护成本**。

**大家理解的 AI 降低成本，实际上降低的是第一次把代码写出来的成本，但 App 上线几年的持续维护成本，比如让不同平台一直能保持相同的行为，一个 Bug 在多个代码仓库能都正常修复，这些都是成本。**

简单来说官方的角度是：

- **一套代码库积累的不只是代码，还有大量产品决策和故障修复的历史**，AI 同时维护两套原生实现，但是可能把一个需求理解成两种行为落地都不同仓库里。
- **写代码确实不慢，但是 AI 时代验收成本才是问题和瓶颈**，比如 Flutter 把热重载、Widget 测试、Analyzer 和运行时 Widget Inspector 接到 Agent 工具链，就是在试图缩短「修改—运行—检查」这样的循环
- **Flutter 目前已经把 Agent 的工作流程当成工程基础设施维护**，包括 MCP、Skills、包作者提供的规则，还有真实插件里的测试门禁，也就是 Flutter 已经转型成面相 AI 的开发框架，这些其实我们之前都聊过了

其实这几个还挺好理解的，比如第一个，两套原生代码 AI 当然可以写，但行为偏差还是会在过程累积，一个结账状态机的例子：

- iOS Agent 用异步流处理网络回包，发现旧请求过期就丢弃
- Android Agent 用 Flow 实现时，但是反而把旧事件排队继续处理

> **这两边代码其实都合理，本地单元测试也可能通过，但是当用户在网络不稳定时触发重试，就有可能出现一端忽略旧结果，另一端又把旧结果写回状态的情况**。

![](/article-assets/a04964543713aac9b110fee9.webp)

也就是，**AI 可以降低 Swift 和 Kotlin 的生产成本，但不是零成本就可以消除两套实现之间的需求理解、重试时序和边界行为差异**， 比如需求以后每改一次，两端还是需要各自实现和对照验证。

**这就是 Flutter 还存在的意义，特别是中小团队，Flutter 用一套 Dart 业务逻辑和状态机，至少可以让这部分行为只定义一次，UI 完整性也只需要验收一次，再共享到 iOS、Android 甚至鸿蒙等平台**。

当然，最重要还是，是 Flutter 开始给 Agent 建立验证闭环，比如 Flutter Stateful Hot Reload 可以走到低于 200 毫秒、Widget 测试低于 500 毫秒，对比传统原生构建需要 2～5 分钟，所以实际上 Agent  可以做到每修改一次代码，能直接看到确定性反馈，可以在相同时间里尝试和修正更多问题。

![](/article-assets/d3843f359fc9b76e2188cfad.webp)

不过涉及原生插件这部分不可能也这么快，但是这部分才是 AI 时代最有价值的地方，以前你写 Flutter 最怕就是原生插件，没人适配，你自己又不懂，写起来就很烧心。

> 但是现在 AI 时代后，插件有问题直接改，这反而是一种优势。

目前官方维护了 [Flutter Agent Plugins](https://github.com/flutter/agent-plugins) 和 [Dart Skills](https://github.com/dart-lang/skills)，分别有 10 个 Flutter Skills 和 14 个 Dart Skills，配合 `dart mcp-server` 就能把静态分析、测试执行和运行时检查接进 Codex、Claude Code、Cursor 之类的开发工具。

> 甚至现在包作者可以直接把对应 Skill 跟着 `pub.dev` 依赖发布，开发者运行 `dart run skills@ get` 就能发现当前依赖提供的规则。

其他的  [A2UI](https://a2ui.org/) 和 [GenUI SDK for Flutter](https://docs.flutter.dev/ai/genui) ，还是有 GenKit Agent SDK 什么的，这些都是 Flutter 围绕 AI 的适配和基建能力。

![](/article-assets/aeac3ac847e22499891de429.webp)

**所以 Flutter 不只是跨平台框架，在 AI 时代它也进一步围绕 AI 在进化，这也是 Flutter 在 AI 时代的意义**。





## 链接



https://flutter.dev/blog/ai-makes-it-easy-to-migrate-flutter-makes-it-easy-to-scale
