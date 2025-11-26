#  Fluttercon EU 2025 ：Let's go far with Flutter 

![](https://img.cdn.guoshuyu.cn/image-20250929091135681.png)

这个主题是由 Kevin Moore 在 Fluttercon EU 2025 分享， Kevin Moore  是 Google Flutter 和 Dart 团队的产品经理，而本次主题也是向大家展示了 Flutter 未来的规划，比如开放性、可扩展性、强大的生态系统和持续演进等。

![](https://img.cdn.guoshuyu.cn/image-20250929101558097.png)

在分享 Flutter 主题之前，他先是介绍 Linux 、WebAssembly  和 RISC-V ：

- “Linus Torvalds 在 1991年创建了Linux，而几十年来人们一直在说「今年是Linux桌面年」，而如今 Linux 在桌面市场的占有率终于超过了 6%，这是一个了不起的成.....微软（WSL）和苹果（apple/container）这两大巨头如今都积极拥抱 Linux....**如果在 20 年前有人告诉他微软和苹果会如此自豪地宣传他们对 Linux 的支持，他会觉得那人疯了**....”
- Wasm 诞生于2015年，在短短几年内就从一个概念发展到了V3规范，支持了垃圾回收（WasmGC）等重要特性，并且 Wasm 的潜力远不止于前端，在 Wasm 的会议上，大多数议题都集中在如何将 Wasm 用于后端和云服务，Kevin  引用了 Docker 创始人的话：“**如果WebAssembly早出现10年，我们根本不会创造Docker**。”
- RISC-V始于2010年伯克利大学的一个项目，其核心思想是创建一个完全开放、免费的指令集标准，与需要昂贵授权费的x86（英特尔/AMD）和ARM架构形成对比，可能多人没听说过，但全球已有超过 100 亿颗集成电路采用了 RISC-V，例如 Nvidia 的所有 GPU（无论高端AI芯片还是桌面显卡）都内置了 RISC-V 核心，西部数据（Western Digital）的硬盘多年来也一直在使用它，Google的 TPU 也是基于 RISC-V ·····

![image-20250929103625191](https://img.cdn.guoshuyu.cn/image-20250929103625191.png)

Kevin 他之所以提到上面三项技术，其目的主要是为了引出后面的技术产生“持久影响力”的主要因素：

- 技术本身必须足够优秀和强大
- 必须是开源的，无论是代码还是标准
- 平台必须允许开发者在其之上构建和扩展，而不仅仅是封闭
- 需要有公司、个人和机构的共同投入，形成一个积极的、自我促进的生态圈。
- 技术不能停滞不前，必须不断改进和发展

![](https://img.cdn.guoshuyu.cn/image-20250929103759374.png)

这五个要素的结合，才能创造出能改变行业、经久不衰的技术，而回归到 Flutter 上，在上述几个领域 Flutter 和 Dart 也是有所涉及，另外，除了常规介绍 Dart 和 Flutter  在生产力、多平台支持和性能等方便的出色表现之外，**在 GitHub 上也是首次达到贡献者数量排名前十的成就**。

![](https://img.cdn.guoshuyu.cn/image-20250929103715002.png)![](https://img.cdn.guoshuyu.cn/image-20250929103818097.png)

另外在生态系统方面，Flutter 已经拥有超过 60,000 个 Pub package、活跃的 GDEs 社区和众多支持 Flutter 公司支持（VGV、Serverpod、Shorebird、FlutterFlow、Fluttercon等），而对于 Flutter 未来的发展，特别是可扩展性的支持上，Flutter 也实现了：

- **Web Proxy Support**: Flutter Web 项目支持配置本地开发服务器的 Web 代理
- **Featherlight**: 未来将 **Cupertino 和 Material widget 从核心框架移至独立的 package**，以便更快地迭代和社区贡献
- **新的 Analyzer 插件系统**: 将允许同时运行多个分析器插件，提高性能和稳定性 
- **Augmentations (增强功能)**: 正在开发类似 C# 部分类的功能，**允许在多个文件中定义一个类**，减少 mixin 或复杂继承的需求。
- **持续演进 (Evolving)**: Dart 经历了从非健全类型系统到健全类型系统 (Sound Type System) 的转变，引入了 Null Safety 和对 WebAssembly 的编译支持，甚至交叉编译等，而 Impeller 渲染引擎的重写以及**未来的 Web Impeller 都是其持续进步的体现**。

![](https://img.cdn.guoshuyu.cn/image-20250929103850791.png)

当然，Kevin  也提到了 **关于宏 (Macros) 的中止**: 这对于 Flutter 来说属于是这是一个“特性”而非“失败”，因为它表明团队愿意承担风险去尝试有巨大影响力的功能，但同时也会在发现“收益不值得付出代价”时果断停止，以保护Dart和Flutter的核心优势（性能、开发者体验等）。

除此之外，Kevin Moore 也分享了他使用 Gemini AI 作为 vibe coding 的经验，解释了 AI 在快速启动项目和解决已知问题方面的能力，特别是这次 Flutter 团队新开源的 Gen UI ，旨在提供比传统聊天体验更具交互性的UI生成方式：

> 详细可见：[《Flutter 官方 LLM 动态 UI 库 flutter_genui 发布，让 App UI 自己生成 UI》](https://juejin.cn/post/7547639458385313855)

![](https://img.cdn.guoshuyu.cn/image-20250929104919569.png)

**Kevin 认为 AI 不是一时风潮，但也不是万能的**，AI 将改变开发者的工作方式，提升能利用 AI 的开发者的竞争力，也建议开发者可以通过“深入技术 (Go Deep Technically)”和“广泛协作 (Go Broad Collaboratively)”来应对 AI 带来的变革：

**深入技术 **：

- **AI的局限**: AI 擅长解决那些网上有大量现成代码和解决方案的“已解决问题”，但你无法让 AI 去“重写 Flutter 的图形引擎”或“设计一个新的元编程系统”，这些是需要深度思考和创新的“未解难题”
- **给开发者的建议**:  鼓励开发者挑战自己，向技术栈的更深层次探索，从易到难：
  - 不仅仅是提Bug，而是提交一个带有最小可复现示例的高质量 Issue
  - 尝试在本地修改 Flutter 框架的源代码（比如改一个 Widget），然后运行看看效果
  - 尝试在本地编译 Flutter 引擎（Engine）
  - 尝试为分析器（Analyzer）编写一个自定义的Lint规则
  - 尝试编译整个 Dart SDK

**拓宽合作**：

- **合作的重要性**:  Linux、Wasm 和 RISC-V 的成功，不仅仅是因为创始人的天才想法，更是因为有无数人在社区、标准制定、商业推广等方面进行合作，扩大了生态，大型语言模型（LLM）无法做到“建立一个社区”或“打造一个生态系统”，这是人类的工作。

- **给开发者的建议**:

  - **成立特殊兴趣小组 (SIGs)**:  呼吁社区自发地围绕特定行业（如娱乐、嵌入式、汽车、教育、医疗、政府等）成立兴趣小组
  - **集体发声**: 与其个人在社交媒体上抱怨，不如由一个代表 10 家或 20 家公司的兴趣小组联合起来，向 Flutter 团队提交一份正式的需求文档，说明他们在特定领域需要哪些功能，这样的集体声音会更有分量，更容易推动团队去解决特定问题。
  - **与竞争对手交谈**: 他甚至鼓励在场的竞争对手们互相交流，因为共同的目标应该是“把整个蛋糕做大”，而不是只争夺自己眼前的一小块。目前全球有约 5000 万开发者，而 Flutter 开发者只有一两百万，增长空间巨大。

  

![](C:\Users\Asher.Guo\Desktop\image-20250929091204245.png)

最后，Kevin Moore 总结：要想让Flutter成为像 Linux、Wasm 和 RISC-V 那样具有持久影响力的技术，同时在 AI 的浪潮中立于不败之地，唯一的答案就是社区中的每一个人都努力做到：

- **深入技术 (Go Deep)**
- **拓宽合作 (Go Broad)**
- **携手并进 (Go Together)**

这样才能 Go Far with Flutter 。