# Flutter 正在计划提供 Packaged AI Assets 的支持，让你的包/插件可以更好被 AI 理解和选择

如何让开源项目能够持续获得资金支持，2025 - 2026 的答案肯定是紧跟 AI 。

2025 年 Dart/Flutter MCP 和 Flutter GenUI 的出现，无疑让 Flutter 在 AI 上刷新了存在感，特别是谷歌核心项目 NotebookLM 在 Flutter 上的成功，也让 Flutter 在 AI 应用场景证明了可行性，这从第三方 appfigures  提供的数据也可以有明显体现：



![](https://img.cdn.guoshuyu.cn/aefb36b6fa4a62a4da487f302271f517.png)

> 数据是 appfigures 分析数百万个 iOS 和 Android 应用和游戏，并根据 SDK 当前安装的应用数量对其进行排名 https://appfigures.com/top-sdks/development/apps

而这次新的 AI 提案，主要是为了： **让 Dart/Flutter 的 Package 可以把「给 AI Agent 用的资源（文档/指南）和 prompts」直接随包发布，并由  Dart/Flutter MCP Server  从「当前工程的依赖」中自动发现并暴露给 Agent 使用，从而避免额外安装 MCP server / node/npx / 单独 prompts 仓库等分裂的分发方式**。

说人话就是：让 AI 可以通过  Dart/Flutter MCP 更好地理解和使用 Flutter 的 Package ，而不是需要花费额外 token 去理解并让 AI 发挥想象力去接入。

> 也就是**把“AI 辅助能力”当作 Package 的一等公民** ，并且发现/更新还能自动化完成，让 Flutter 的 AI 生态更加完善。

实际上这确实当前趋势下比较迫切的需求之一，AI coding  越来越常用，而如果让 Agent 能更好理解 Flutter Package 自然就成新的刚需，例如：

> 最佳实践、典型坑位、推荐用法、命令化工作流等，**甚至让包能够更优先出现在 AI 的选择里**。

所以这个这不是「让 agent 读 README」的低级需求，而是「包作者提供 curated 的、面向 agent 的知识与操作入口」。

而 Flutter 这次提议的 Packaged AI Assets ，其实就是希望可以：**只装一个 Dart/Flutter MCP server**，然后在你加依赖/更依赖版本时，相关 agent features 会随之更新。

> 怎么简单怎么来。

![](https://img.cdn.guoshuyu.cn/image-20260214174453411.png)

提案的核心，是通过在包中添加一个特定格式的配置文件来描述该 Package 提供的 AI 资源，例如：

- 提供一个 `extensions/mcp/config.yaml` 的全新路径文件，让它成为  Packaged AI Assets 的入口
- 格式遵循 `package:extension_discovery` 格式，借用 `extension_discovery` 的既有机制
- 工作原理则是，Dart/Flutter MCP 会读取直接依赖项中的这些配置文件，并将定义的资源和提示词直接通过 MCP 协议暴露给 AI 代理

> 这里暂时使用的是 MCP 而不是 Skills ，核心也是希望直接依赖于已有的 Dart/Flutter MCP server ，这样也不需要额外配置；另外未来页可能会考虑，目前可以通过在 `bin/` 目录下添加 Dart 脚本，用户可以通过提示词执行 `dart run <package>:<script>` 来运行。

所以，在 Packaged AI Assets 的详细设计里，配置文件主要包含两个部分：`resources` (资源) 和 `prompts` (提示词) ：

```yaml
resources:
  - name: slivers_tutorial        # 默认为文件名
    title: "Slivers Tutorial"
    description: "Become a slivers expert with this doc!"
    path: resources/slivers/really_awesome_doc_on_slivers.md

prompts:
  - name: split_into_subwidgets   # 默认为文件名
    title: "Split into subwidgets"
    description: "Splits a widget up into multiple widgets"
    path: prompts/widgets/split_up_into_subwidgets.md
```

**resources** 列表里每个对象包含：

- name（可选，默认文件 basename）
- title
- description
- path（指向资源文件）

**prompts** 同理：

- name（可选）
- title
- description
- path（指向 prompt 文件）

> 这里的 `title/description` 支持 Agent UI 里展示，这样可以更直观。

在使用过程中：

- AI 代理可以通过 `@<resource>` 语法引用资源，系统会将路径转换为 URI 格式 `package-root://<package-name>/<path/from/package/root>`，例如 `@state` 自动引入状态管理文档
- 同样  Prompts 也是，prompts 通常以 slash commands 形式出现（`/<prompt-name>`），MCP 服务器在暴露提示词时会有 `/package-name/prompt-name` 的区分，例如 `/widget` 自动补全所有 widget 相关的命令 。

当然，提案里也说了一些限制：

- MCP prompts 支持参数，但**参数都是字符串**，且不支持 repeated arguments（MCP spec 限制）
- 如果 prompt 声明了 arguments，那么 prompt 文件会被当作 mustache 模板，用 `package:mustache_template` 注入参数

![](https://img.cdn.guoshuyu.cn/image-20260214174517008.png)

所以按照目前的规则，可以理解为：

- 必须定义「arguments 在 config.yaml 的写法」
- mustache 模板替换要有转义规则，否则 prompt 注入/模板注入风险更高
- 参数都是 string 而复杂结构需要 JSON string，这可能会影响复杂场景的通用性

另外，一些边缘情况处理也需要考虑，例如：

- 多包配置场景: 如果用户同时打开了多个包，且这些包依赖同一个包的不同版本，系统会使用在任何打开的包中找到的**最新版本的资源和提示词**，这样可以减少重复和保持 URI 简短
- 当依赖项发生变化（如添加新包）时，目前需要**重启 MCP 服务器**才能加载新的 AI 辅助功能，虽然未来可能会支持动态监听和更新，但由于许多 AI 代理本身不支持动态变更通知，应该暂时不会支持

> AI 辅助最怕“自信但错”，如果 agent 引用的是不匹配版本的文档，会直接误导代码修改，浪费更多 token。

同时安全性也是一个着重考虑的点，可能会面临提示词注入的风险，所以需要考虑：

- 由 MCP 客户端负责防范
- 所有 MCP 服务器应被视为不可信来源
- 计划在推进前研究缓解措施，例如在上传到 `pub.dev` 时进行安全扫描

最后，目前提案还存在一些需要解决的问题，例如：

- **文件干扰** :  Agnet 可能会同时看到原始文件和 MCP 资源，可能导致混淆，需要通过向 Agnet 隐藏 `extensions/` 目录来解决
- 是否需要将 `gemini` cli 扩展中的 Flutter 特性迁移到 `packages/flutter/extensions/ai`  
- 是否允许发布仅包含 AI 辅助功能而不含 Dart 代码的包？
- 是否应暴露传递依赖（间接依赖）的资源？目前 V1 版本不计划支持，但未来可考虑添加传递可见性选项。
- 是否可以不依赖手动编写，而是自动包含示例等资源？

总的来说，我还是很期待这个提案的落地，对我来说目前 AI 在使用和选择 Package 里，确实经常遇到使用了错误的 API ，或者更新了 Package 之后，它还保留上个版本的写法，当然这个提案就算落地，最终也需要作者愿意提供对应的 Packaged AI Assets ，我觉得这对于社区版本的 Flutter 也是很好的帮助，**例如鸿蒙版本的 Flutter 在后续跟进鸿蒙平台 Package 时，AI 可以更好的理解和实现鸿蒙平台的支持**。

那么，你觉得这个提案对你来说是否有帮助呢？



# 参考链接



https://docs.google.com/document/d/1k_X-Sp4GQyZP6k9lvZ1Itj0GvzQZuWl3iKzi5AIa69Q/