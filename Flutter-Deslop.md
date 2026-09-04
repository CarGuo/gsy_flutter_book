# AI 时代，一个优化 Flutter 的重复代码工具  Deslop

现在基本都在用 AI 写代码，但是实际上 AI 经常缺少全局意识，甚至你就算写了规则，它也不一定遵守，比如一个昨天就看到一个网友发的这个，感觉就挺典型了：

![](https://img.cdn.guoshuyu.cn/image-20260826164704807.png)

这次情况下，你如果没有仔细 Review ，有可能不知不觉里项目就已经整了一大批相似代码，比如相同的 Loading、Error、Snackbar、日期格式化和 Repository 转换逻辑。

![](https://img.cdn.guoshuyu.cn/image-20260826164259480.png)

然后 [Deslop](https://apparencekit.dev/blog/deslop-duplicate-code-flutter/) 就是用在这个方面，它会解析 Dart 代码的语法结构，然后通过规则找到完全相同、变量改名后相同、局部修改后相似的代码，**同时通过 MCP 在 Agent 写代码之前提供一次“仓库里有没有类似实现”的查询**。

> 是的，最重要的就是这个提供查询。

它能把重复检测从代码提交后的质量检查，提前到了 Agent 的生成循环里，比如类似代码：

![](https://img.cdn.guoshuyu.cn/image-20260826164349245.png)

实际上如果直接让 AI 判断这两个实现，可能 AI 都不一定判断得出来是否重复，因为函数名、参数类型、变量名都不同，最终可能 出现两个实现开始独立演进，修复空字符串、国际化或者姓名顺序时，很容易只改到其中一个。

特别是 Flutter 项目更容易出现这种情况，因为声明式 Widget 树包含大量稳定结构，AI 很容易重复生成以下内容：

- `AsyncValue`、`FutureBuilder` 或自定义状态中的 loading/error/data 分支
- `Scaffold`、`SafeArea`、空状态和错误卡片
- DTO 到 Entity 的字段映射
- Repository 中相似的重试、异常转换和分页逻辑
- 日期、金额、文件大小等格式化函数
- Golden Test 的设备配置和 Provider override
- Snackbar、Dialog、BottomSheet 的包装函数

这些代码有时候其实只有十几行，但是经过几个月持续生成后，可能每种基础能力会可能出现三四套版本。

而 Deslop 的做法就有点意思了，它会用用 Tree-sitter 解析 Dart 的构造语法树，再经过标准化、指纹计算、近似匹配、聚类和排序，比如官方给出的完整流程是：

```
discover → parse → normalize → fingerprint → cluster
           → LSH → embed → fuse → rank → render
```

在这里，第一层会先把代码还原成语法结构，Tree-sitter 会把函数、调用、条件、属性访问、循环和表达式解析为 AST，然后 Deslop 对语法树做标准化处理：

- 标识符统一替换为 `__ident__`
- 字符串、数字和字符常量替换为 `__literal__`
- 删除注释、空格和其他语法 trivia

前面的 `formatUserLabel` 和 `buildAuthorName` 经过处理后，都会变成“函数声明、一个参数、字符串插值、两次属性访问”的相同结构，单纯改函数名和变量名，在这种情况也可以被检测出来。

> 所以 Deslop 的核心是关注代码的语法形状，变量重命名和格式化不会破坏结果。

然后第二层会用 Merkle Hash 找完全相同的子树，默认情况下，Deslop 会处理不少于 30 个 AST 节点的子树，从叶子向上计算 BLAKE3 Merkle Hash，节点类型和子节点顺序相同，最终便会得到相同指纹，这部分主要捕获 Type-1 和 Type-2 Clone：

| 类型   | 典型情况                   | Deslop 的识别方式          |
| ------ | -------------------------- | -------------------------- |
| Type-1 | 代码、变量名、常量都相同   | AST Merkle Hash            |
| Type-2 | 变量名、函数名或常量不同   | 标准化 AST 后再计算 Hash   |
| Type-3 | 增删了少量语句，主体仍相似 | AST k-gram、MinHash 和 LSH |
| Type-4 | 写法明显不同，行为接近     | 可选的代码 Embedding       |

> Deslop 还会对连续 2 到 8 个兄弟语句建立窗口指纹，这样后面就算两段函数外围结构不同，只要中间存在一组连续重复语句，也有机会被发现。

接着第三层会用 MinHash 和 LSH 找“近似复制”，完全相同的 Hash 不能处理局部增加一条判断、调整部分语句之类的情况，所以 Deslop 会把标准化后的 AST 节点类型组成宽度为 5 的 k-gram，再计算包含 128 个值的 MinHash 签名，并拆成 32 个 band，每个 band 包含 4 行。

**这个设计的目的是快速召回可能相似的代码对**，发生 band collision 后，Deslop 再根据完整签名估算 Jaccard 相似度，单独依靠这一路信号时，当前规则还要求：

- `token_jaccard ≥ 0.90`
- 两端都至少有 40 个 AST 节点

> 这样的目的是减少普通 Flutter Widget 结构带来的噪音，很多 Widget 都有 `build → Column → children`，只凭几个相同节点就判定重复，报告很快会失去价值。

最后是可选的语义 Embedding，Deslop 还支持通过代码向量寻找“行为接近、语法差异较大”的实现，例如命令式循环和函数式集合操作。

> 不过这一层默认关闭，目前只实现了 Ollama Provider，默认模型为 `nomic-embed-text`，需要显式启用 `--embeddings auto` 或 `--embeddings required`。

最后三种分数会合并，每一对候选代码都有三个独立信号：

- `structural`：完全结构匹配，取值为 0 或 1
- `token_jaccard`：近似语法序列相似度
- `embedding_cos`：代码向量余弦相似度

候选阶段的融合值采用三者中的最大值 `max(structural, token_jaccard, embedding_cos)`，达到 `FUSED_THRESHOLD = 0.85` 才会保留，然后就会通过传递闭包建立 Cluster：

> 如果 A 与 B 相似，B 与 C 相似，三者会进入同一组，即使 A 与 C 没有直接达到阈值。

这种聚类方式扩大了召回范围，当然也带来一个需要人工留意的问题：

> Cluster 内部其实不保证任意两个成员都同样相似，规模较大的 Cluster 可能由中间代码串联起来，不能看到一组结果便直接抽成公共基类。

Deslop 还会对结构相同但内容证据不足的结果进行 content gate，同时默认把 `structural_only` 和大块数据型重复降到 0.15 倍权重。

然后还有排序，Deslop 会用下面的公式给 Cluster 排序：

```
weight =
  clone_node_count
  × (cluster_size − 1)
  × log2(1 + spanned_bytes)
```

它主要考虑了三个维度：

- 重复片段包含多少 AST 节点
- 同一片段出现了多少份
- 这些代码在源码中占用了多少字节

比如 ：

- `cluster_size − 1`  可以近似理解为“有多少份可以删掉”
- `log2` 会压低超大文件的体积优势，避免一份巨大的生成文件占据整个榜单
- 最终报告优先展示收益最高的重复项

然后 Deslop 目前还提供的几种形态，形态之间共享同一个 `deslop-core` 分析引擎，但使用场景差异很大：

- **CLI 适合首次审计、CI 和冷扫描**，执行 `deslop .` 后，默认会在项目的 `.deslop/` 目录生成 JSON、TXT 和 HTML 报告，JSON 面向 Agent 和自动化处理，TXT 适合终端，HTML 用于人工查看。
- **VS Code 扩展会启动 LSP**，监听文件变化并增量更新结果，每个文件以内容 Hash 为缓存键，没有变化的文件可以跳过分析
- MCP 是给 Coding Agent 提供查询入口，这里的架构细节很有意思：
  - `deslop-mcp` 自身不重新分析整个仓库，它通过本地 IPC 向正在运行的 LSP 查询最新结果
  - macOS 和 Linux 使用 Unix Socket，Windows 使用带 Token 的本地 TCP Loopback
  - Agent 调用一次 `find-similar`，通常不需要重新遍历所有 Dart 文件
- CI 负责长期趋势，当重复率超过 `.deslop.toml` 中的阈值，CLI 返回退出码 3，报告还会生成，方便从失败的 Pipeline 中查看具体问题

```yaml
name: deslop
on: [push, pull_request]

jobs:
  duplication-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Nimblesite/Deslop@v0.32.0
        with:
          fail-over: "5.0"   # or omit to use [threshold] in .deslop.toml
```

如果你只运行 `deslop .`，那它和其他静态分析器的差别主要体现在 Dart 支持、AST 结构检测和排序，但是支持 MCP 就不一样了，它可以带进 Agent 的写入循环，比如：

```
Agent 准备写函数
        ↓
调用 find-similar
        ↓
查询当前仓库的结构索引
        ↓
找到近似实现
        ↓
复用、扩展或放弃新建
```

这相当于给 Agent 增加了一套本地代码检索，LLM 负责理解需求，Deslop 负责回答仓库里是否已有相似结构，检索结果是确定性的 AST、Token 和可选向量分析，不需要让模型先盲目 `grep` 一圈，再猜哪个函数可能相关，这个理论上其实更不容易幻觉。

不过安装 MCP 不会保证 Agent 主动调用它，所以官方专门提供了一段 `AGENTS.md`／`CLAUDE.md` 规则，要求 Agent 在创建超过几行的新函数、类、Fixture、Parser、Route 或 ViewModel 前调用 `find-similar`。

官方当前建议的判断区间是：

- `fused ≥ 0.85`：优先复用或抽取
- `0.6 ≤ fused < 0.85`：读取候选代码后判断
- `fused < 0.6`：结构距离较远，可以继续创建

作者还把 Deslop 封装成了一套更谨慎的 Dart/Flutter Agent Skill：

> 先只读扫描，再由用户确认，随后判断每个重复项是否值得合并，最后通过重构前后的测试进行验证：https://github.com/kevmoo/kevmoo_skills/blob/main/skills/deslop-duplication-audit/SKILL.md

不过也不是重复代码就都应该消失，比如两个函数可以拥有相同结构，同时承担完全不同的领域语义，比如价格格式化和重量格式化目前可能都是：

```
value.toStringAsFixed(2)
```

这里如果将它们合并成 `formatNumber()` 其实会抹掉领域含义，以后价格需要货币精度，重量需要单位转换，这个公共函数又会被拆开。

实际上在 Flutter 中还有几类常见的合理重复：

- iOS 与 Android 的平台实现需要保持隔离
- 多个页面遵循相同 Widget 骨架，但生命周期和交互正在分化
- 不同 Domain 的 Repository 恰好采用相同流程
- 测试用例刻意展开 Arrange/Act/Assert，方便独立阅读
- 性能敏感循环为了避免闭包、动态分发而保持专用实现
- 不同 package 需要独立发布，强行共享会制造反向依赖

**所以结构查重只是提供主要证据，架构边界还是需要开发者自己判断**。







# 链接

https://apparencekit.dev/blog/deslop-duplicate-code-flutter/