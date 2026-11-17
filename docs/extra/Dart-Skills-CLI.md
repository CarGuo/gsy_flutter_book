---
title: "Dart Skills CLI 1.0 ：AI 时代的 Dart 交付支持"
---

# Dart Skills CLI 1.0 ：AI 时代的 Dart 交付支持

最近 Dart  发布了 `skills` CLI 1.0 版本，这个工具其实最早由 Serverpod 团队开发，一个做后端的 Dart 框架，最近看也看到一些不错的 Dart 全栈式框架，现在这个 CLI  正式转交给了 Dart 团队维护和发布。

![](/article-assets/81ac1e2169fb223fee1ebdaa.webp)

表面上看这个 CLI 做的事情还挺简单的，主要就是 Dart、Flutter package 可以在根目录增加一个 `skills/` 文件夹，package 发布到 pub.dev 时会把这些 Agent Skills 一起带出去，**用户只要执行一次 `dart run skills@ get`，Claude Code、Cursor、Codex、Cline、Copilot 之类的 coding agent 就能加载到这个 package 提供的使用说明**。

> 所以这一点 Flutter 和 Dart 又开始激进走在 AI 浪潮上，现在 Dart 已经把  AI  如何使用一个库作为  package 本身需要交付的内容。

以前发布一个 package 主要发布源码、类型定义、README、API 文档、example 之类，现在可以再加上一层面向 Agent 的程序化知识，包括：

- 什么时候应该采用某种 API
- 推荐的工程结构
- 容易踩坑的组合
- 错误处理方式
- 可以执行的辅助脚本
- 复杂任务应该按照什么流程完成

**以前其实也可以在 package 里放 skills ，但是过去 Skill 最大的问题，主要还是它和依赖版本脱节**，一般 Skills 的格式很轻：

> 一个目录、一份 `SKILL.md`，再按需要加入 `scripts/`、`references/`、`assets/`。

比如 Dart 和 Flutter 官方之前就已经分别维护自己的 Skills 仓库，然后可以通过类似下面的方式进行安装：

```bash
npx skills add dart-lang/skills --skill '*' --agent universal
npx skills add flutter/agent-plugins --skill '*' --agent universal
```

但是这种方式只适合安装「怎么开发 Flutter」「怎么写 Dart 单元测试」之类的通用技能，如果是在一个 package 生态里就很麻烦了，**因为 Git 仓库里的 Skill 和项目正在使用的 package 版本没有天然对应关系**。

比如项目依赖的是某个库的 `3.2.1`：

```yaml
dependencies:
  some_package: ^3.2.1
```

模型自身可能见过 `2.x` 的代码，网上文档可能已经更新到 `4.x`，GitHub 上独立维护的 Skill 又可能按照 `main` 分支写，这种情况下最后 Agent 可能会同时拿到了三套时代不同的信息，时不时就写出一些奇怪的组合。

> 就算开发者已经安装 Node.js、能够正常使用 `npx skills`，还是存在 discoverability 和 package version support 两个缺口，特别是后者，用户怎样保证 Agent 使用的 Skill 与当前项目实际使用的 package 版本一致？

**所以 Dart CLI 的 `skills` 1.0 给出的办法就是把 Skill 就放进 package 发行物**，比如：

```text
my_package/
├── lib/
├── skills/
│   ├── my-package-routing/
│   │   ├── SKILL.md
│   │   ├── scripts/
│   │   ├── references/
│   │   └── assets/
│   └── my-package-testing/
│       └── SKILL.md
└── pubspec.yaml
```

package 作者升级 API 的时候，需要同时修改对应 Skill，然后在执行 `dart pub publish` 的时候，`skills/` 会随着 package 一起进入发布归档，这时候项目解析到哪个 package 版本，本地就拿到的就是那个版本附带的 Skill。

> 这里其实就有了一个很有意思的变化，比如以前 package 的版本号约束的是“代码和 API”，现在同一个版本号开始间接约束 **AI 应该怎样理解和操作这套 API。**

官方给出的实现流程就是 `dart run skills@ get` ，CLI 会先确保项目依赖已经解析，然后读取项目生成的 `package_config.json ，这个文件本来就记录了当前项目每个 package 实际在硬盘里的位置，所以 `skills` CLI 可以直接定位当前项目真实使用的 package 目录。

然后它会进入 package 根目录找 `skills/`，扫描包含 `SKILL.md` 的 Skill 同时校验名称，比如 package 叫 `serverpod`，Skill 可以叫：

```text
serverpod-code-generation
serverpod-api-design
```

但是不能只写 `code-generation` ，原因是所有依赖最终可能把 Skill 安装进同一个 Agent Skill 空间，所以名称需要带 package 前缀避免冲突，所以对于名为 `my_package` 的 Dart package，应该用类似 `my_package-routing` 和 `my-package-routing`。

发现 Skill 后，CLI 不会每次全部覆盖，它会把当前 package 内的 Skill 与之前管理的状态进行比较，判断哪些是新增、更新、删除或者此前跳过的 Skill，然后让用户选择，状态记录在：

```text
.config/dart_skills/skills_config.json
```

所以再次运行 `dart run skills@ get` 的时候，实际上是承担了类似“同步 AI instructions”的作用，官方文档给出的完整过程可以概括成下面这张表：

| 阶段 | `skills` CLI 做的事情 |
|---|---|
| 依赖解析 | 根据 Dart 当前项目解析结果确定直接依赖 |
| Package 定位 | 从 `package_config.json` 找到当前实际使用的 package |
| Skill 发现 | 查找 package 根目录中的 `skills/*/SKILL.md` |
| 校验 | 检查 Skill 名称与 package 名称前缀 |
| 状态比较 | 对比已经安装、更新、删除或跳过的 Skill |
| Agent 适配 | 根据项目中的 Agent 安装到对应目录 |
| 状态记录 | 写入 `.config/dart_skills/skills_config.json` |
| 后续同步 | 再次执行 `get` 时进行增量更新 |

现在这个 CLI 已经支持了多种 coding agent 的实际目录，比如：

- Claude Code 用 `.claude/skills/`
- Cursor 用 `.cursor/skills/`
- Cline 用 `.cline/skills/`
- GitHub Copilot 用 `.github/skills/`
- Codex 和通用 Agent Skills 目录使用 `.agents/skills/`

> 一个 package 的开发者只要维护一份符合开放 Agent Skills 规范的 Skill，CLI 负责把它放到各个 Agent 能发现的位置。

另外有一个需要注意的是，**CLI 只会从项目的 直接依赖 immediate dependencies 安装 package Skills，没有把整个传递依赖树全部变成 Agent 指令来源，所以只会处理你直接依赖的 package ，间接依赖的不会自动处理**。

另外 `skills` CLI 1.0 也没有试图替代 Git Skill，比如官方就保留了：

```bash
dart run skills@ add <git_repository_url>
```

GitHub 上与 Dart package 无关的通用 Skills 还是可以安装，而且已经通过 `add` 添加的仓库，以后运行 `get` 时也可以一起检查更新，Dart 官方甚至专门做了兼容，很多 skills.sh 页面上原来写成 `npx skills add ...` 的命令，可以直接把前面的 `npx skills` 换成 `dart run skills@ `继续使用。

另外Dart 官方还明确区分了两个目录：

- `skills/` 主要用于 package 消费者，会随 package 发布
- `.agents/skills/` 用于维护 package 自己的开发团队，不会发布给消费者

所以也不需要担心项目里存在多个来源导致污染。

然后 Dart  你现在也可以通过下面命令直接生成模板：

```bash
dart run skills@ create \
  -n <skill_name> \
  -d "<skill_description>"
```

最后，`skills` 在 1.0 的开发过程里也加入 「安装时检查 package security advisories」 的机制，同时限制了 package Skill 来源到直接依赖， 不过从工程上看，团队还是需要把 Skill 当成依赖内容的一部分进行审查，特别是里面存在可执行脚本、修改项目文件或者调用外部命令时，不然还是容易存在安全风险。
