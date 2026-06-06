# 实用性 Max ，新  Flutter  &  Dart Agent  Skills  深度解读

虽然之前在刚发布那会，我们就在 [《Flutter 发布官方 Skills 》](https://juejin.cn/post/7613318336118882323) 聊过 Flutter 的 Skills ，但是经过几轮测试之后，**官方发现之前单纯文档型的 Skills 作用并不明显，所以后续开始调整了策略，增加了“任务导向型”的 Skills**，这个调整让 Skills 的实用性大大提高。

![](https://img.cdn.guoshuyu.cn/ezgif-5c063f622e3007ce.gif)

在深入聊这次更新之前，**其实 Flutter 官方这套 Skills 的本身的生产逻辑就很有意思**，基于文档驱动，通过文档定时更新 Skills ，这样可以做到在生成文档的时候，Skills 也能保持最新。

# Skills 流水线

官方的这些 Skills 基本都不是手写的，它们有一条自动化生成流水线，核心是 `tool/generator`：

![](https://img.cdn.guoshuyu.cn/ChatGPT%20Image%202026%E5%B9%B45%E6%9C%887%E6%97%A5%2014_07_33.png)

其中对应的配置文件长这样：

```yaml
- name: flutter-layout
  description: "..."
  resources:
    - https://docs.flutter.dev/ui/widgets/layout
    - https://docs.flutter.dev/ui/layout
    - ../packages/flutter/lib/src/widgets/layout.md
```

而 Generator 工具会爬取 `resources` 里列出的  URL ，然后把文档内容喂给 AI，让 AI 按照 Skill 规范生成 `SKILL.md` ，然后有三个子命令：

- `generate-skill`：首次生成
- `update-skill`：基于现有内容 + 新文档更新
- `validate-skill`：重新生成并与现有版本对比，用来测试 prompt 稳定性

最后还有一个  dart_skills_lint ，会在 presubmit  阶段校验每个 Skill 的格式合规性，校验项包括：

- `name` 字段必须与目录名完全一致（最多 64 字符，纯小写字母+连字符）
- `description` 不超过 1024 字符
- Markdown 内联链接不能使用绝对路径（保证可移植性）
- 不能有多层嵌套目录
- 支持自定义 Rule 扩展

**所以其实在我们日常的 harness 工程里，本身就可以配置这样一套 CI 工具，通过我们的需求文档，spec 或者代码，自动迭代出每个提交和修改的记录和 skills 给项目**。

# Flutter Skills

这里主要介绍这次更新的一些有意思的 skills，这次增加的几个都是很垂直领域的实用性支持。

### `flutter-fix-layout-issues`

主要用来做布局报错自动修复，核心是解决 Flutter 最高频的布局报错，比如 `RenderFlex overflowed`、`Vertical viewport was given unbounded height`、`An InputDecorator cannot have an unbounded width` 等。

这个 Skill 的核心思路是「**错误码 to 诊断 to 对应修复方案的确定性映射**」，因为Flutter 的布局系统主要是基于 "*Constraints go down, Sizes go up, Parent sets position*" 这个基础，所有布局错误都是基于这条规则被违反的表现，所以Skill 把每种违反场景都写成明确的 if-else 处理分支：

![](https://img.cdn.guoshuyu.cn/ChatGPT%20Image%202026%E5%B9%B45%E6%9C%887%E6%97%A5%2014_16_06.png)

因为这些错误的错误消息是固定的字符串，AI 可以直接匹配，所以能够针对性做到：

> 「当看到黄黑条纹溢出报错时，它知道精确的修复步骤，包括热重载验证的反馈循环」。

### `flutter-add-widget-test`

添加 Widget 测试，用 `WidgetTester` 写组件级 UI 测试，验证渲染、tap、scroll、文字输入等交互行为。

这个 Skill 的其实并不复杂，但是它**把测试流程细化成了明确步骤的决策流程**，并且对每种交互场景都给了明确的 API 选择指引：

![](https://img.cdn.guoshuyu.cn/42b03f86-f684-452b-8bce-63a8f2eabb67.png)

甚至还帮你区分了用 `pump()` 还是  `pumpAndSettle()`  ，Skill 把这些决策显式化了，也就是 AI 写出的测试代码，可以基于明确依据，同时 SKILL.md 里附带了一个完整的 TodoList 增删测试示例，展示了类似遇到 `Dismissible` 滑动删除这种复杂交互怎么怎么测试。

> 这在 AI 场景下，做回归测试还是很实用的。

### `flutter-add-integration-test` 

这个节能主要做集成测试，特别是配置 Flutter Driver，并把 MCP 工具的交互 action 转化为持久化的集成测试代码。

**这个技能最有趣的是先探索，后固化**，流程大概是：

- 探索阶段（通过 MCP 交互）：

  - `launch_app` 启动应用，获取 DTD URI

  - `get_widget_tree` 扫描 widget 树，发现可用的 Key、Text、Type

  - `tap`、`enter_text`、`scroll` 模拟用户操作，验证交互路径可行

- 固化阶段（生成静态测试）：
  - 把探索过程中验证通过的操作序列翻译成 `integration_test/` 里的 `testWidgets` 代码

所以它主要解决了 AI 对你的项目每次都是从 0 探索的问题，把能固化的东西固化成代码，这样后续测试流程里可以更加稳定，也节省 token 。

这个 Skill 还有一些非常的细节处理：

- **懒加载 widget 找不到的问题：** 明确指出如果 `get_widget_tree` 找不到目标 widget，可能是因为它在 `SliverList`/`ListView` 里还没被挂载，应该先 `scroll`/`scrollIntoView`
- **`PumpAndSettleTimedOutException`：** 反馈循环里明确标注，遇到这个错误要检查是否有无限动画

> 其实这才是 AI 辅助测试的正确姿势，不是让 AI 盲猜 UI 结构，而是先用 MCP 工具"看"到真实的 app，再把所见转化为测试代码。

### `flutter-build-responsive-layout` 

这个也是很实用，核心是用 `LayoutBuilder`、`MediaQuery`、`Expanded/Flexible`  组合构建适配不同屏幕尺寸的布局。

这个 Skill 最核心的作用是**纠正了 Flutter 响应式开发中最常见的几个反模式**，通过明确"不要做什么"规则来减少性能损失，比如：

- **不要用 `MediaQuery.orientationOf` 或 `OrientationBuilder`** 来切换布局，因为设备方向不等于可用空间（折叠屏、分屏、画中画） 
- **不要检测硬件类型**（手机 vs 平板），Flutter 运行在可调整大小的窗口里 
- **不要锁定屏幕方向**，因为在折叠设备上会导致 letterboxing（黑边）

同时给出正面教程：

- 用 `LayoutBuilder` + `constraints.maxWidth` 做断点判断 

- 大屏上用 `ConstrainedBox(constraints: BoxConstraints(maxWidth: 800))` 防止内容过度拉伸 

- 列表用 `GridView.builder` + `SliverGridDelegateWithMaxCrossAxisExtent`自动根据宽度调整列数

> 实际上这些规则很难通过 Flutter 基础文档直接让 AI 理解，而这个技能就可以很好让 AI 在适配时规避这些问题。

### `flutter-setup-localization` 

这个是国际化多语言配置，用来配置 `flutter_localizations` + `intl`，实现 `.arb` 多语言支持。

因为 Flutter 的 i18n 涉及多个协同步骤，而 Skill 把这个步骤做成了严格有序的检查清单：

- `flutter pub add flutter_localizations --sdk=flutter` + `flutter pub add intl:any`

- `pubspec.yaml` 里加 `flutter: generate: true`

- 根目录创建 `l10n.yaml` 配置文件

- `MaterialApp` 注入 `localizationsDelegates` 和 `supportedLocales`

进阶部分还覆盖了容易出错的高级 ARB 语法：

- **Placeholders（参数插值）：** `"hello": "Hello {userName}"`
- **Plurals（复数形式）：** `{count, plural, =0{...} =1{...} other{...}}`
- **Selects（条件选择，如性别）：** `{gender, select, male{he} female{she} other{they}}`

> 这些语法在 AI 生成时很容易写错，比如漏掉 `other` 分支会导致运行时崩溃，所以这个技能可以很好支持多语言生成的稳定性。

------

### `flutter-implement-json-serialization` 

JSON 序列化这个不用多说了把，这个一直是大家吐槽的点，这个技能用 `dart:convert` 手动实现 `fromJson`/`toJson`，不依赖代码生成。

在这里官方设定了一些类型安全原则：

- `jsonDecode()` 返回 `dynamic`，必须立即 cast 为 `Map<String, dynamic>`

- 使用 Dart 3 的 pattern matching 来做 `fromJson`，类型不匹配时直接抛 `FormatException`，而不是返回 null

```dart
factory User.fromJson(Map<String, dynamic> json) {
  return switch (json) {
    {'id': int id, 'name': String name, 'email': String email} =>
      User(id: id, name: name, email: email),
    _ => throw const FormatException('Failed to load User.'),
  };
}
```

另外还有**大 payload 的后台解析**：

- 如果解析时间 > 16ms，用 `compute()` 把解析函数转移到后台 isolate
- 传给 `compute()` 的函数**必须是顶层函数或静态方法**，不能是闭包或实例方法（跨 isolate 限制）

> 这些也是 AI 生成 JSON 代码时的常见错漏。

### `flutter-add-widget-preview` 

这是一个使用 Flutter 3.38+ 的 Widget Previewer，实现给 UI 组件添加实时预览的技能。

这个技能主要添加核心约束：

- Previewer 运行在 Web 环境，**不能用 `dart:io`、`dart:ffi` 或原生插件**
- 资源路径必须用 package-based 路径（`packages/my_pkg/assets/img.png`）
- 预览注解的 callback 参数必须是 public const

比如 **@Preview 注解的使用方式：**

```dart
@Preview(name: 'My Sample Text', group: 'Typography')
Widget mySampleText() => const Text('Hello, World!');
```

**进阶：MultiPreview**"  ：一个注解自动生成多个预览实例（比如同时生成亮色/暗色主题预览）：

```dart
final class MultiBrightnessPreview extends MultiPreview {
  @override
  List<Preview> get previews => [
    Preview(brightness: Brightness.light),
    Preview(brightness: Brightness.dark),
  ];
}
```

> 这个 Skill 的意义主要是可以让 AI 在帮你写 UI 组件时，同步给组件挂上预览注解，也是一个实用的支持场景。

# Dart Skills

而这次 Dart 本身也更新了一批实用 Skill，比如纯文档解释也实用了不少。

### `dart-fix-runtime-errors` 

比如 `dart-fix-runtime-errors`  ，实际上是**静态分析错误的系统修复工作流**，涵盖类型系统、Null Safety、错误处理三个维度：

| 问题           | 错误做法                                    | 正确做法                             |
| -------------- | ------------------------------------------- | ------------------------------------ |
| 子类参数类型   | 缩窄参数类型（`Mouse` 替代 `Animal`）       | 用 `covariant` 关键字                |
| 动态列表赋值   | `final list = []`（推导为 `List<dynamic>`） | `final list = <int>[]`               |
| 非空字段初始化 | 字段不初始化直接声明                        | 加 `late` 关键字延迟初始化           |
| 捕获错误       | `catch (Error e)`                           | 永远不要 catch `Error`，那是编程 bug |

然后依赖反馈循环来修正 Dart 的一些错误：

![](https://img.cdn.guoshuyu.cn/ChatGPT%20Image%202026%E5%B9%B45%E6%9C%887%E6%97%A5%2014_37_21.png)

### `dart-use-pattern-matching` 

**这是一个让 Dart 代码直接实用 Dart 3 新特性的技能说明**，在适当场景使用 switch 表达式和模式匹配替代传统 if-else 链，这也是 Dart Skills 里目前技术含量最高的一个，在 Pattern 选择策略里有 ：

| 场景                         | 推荐 Pattern                     |
| ---------------------------- | -------------------------------- |
| 验证并解构 JSON              | Map + List pattern               |
| 处理多返回值                 | Record pattern                   |
| 代数数据类型（sealed class） | Object pattern                   |
| 数值范围匹配                 | Relational + Logical-and pattern |
| 多 case 共享逻辑             | Logical-or pattern               |
| 忽略特定值                   | Wildcard `_`                     |

**Switch 表达式 vs Switch 语句的选择：**

- 产出一个值 ： 用 **switch expression**（`switch (v) { pattern => expr }`）
- 执行副作用 ： 用 **switch statement**（`switch (v) { case p: stmts; }`）

例如实用 sealed class 穷举性检查：

```Dart
sealed class Shape {}
class Square implements Shape { final double length; ... }
class Circle implements Shape { final double radius; ... }

// 编译器保证穷举——漏掉任何子类都是编译错误
double calculateArea(Shape shape) => switch (shape) {
  Square(length: var l) => l * l,
  Circle(:var radius)   => math.pi * radius * radius,
};
```



### `dart-migrate-to-checks-package` 

这个技能也算是实用性技能，主要把 `package:matcher` 的 `expect()` 断言迁移到 `package:checks` 的 `check()` 风格。

为什么要迁移？因为 `package:checks` 提供了更贴近自然语言的链式 API，并且错误信息更丰富：

```dart
// 旧风格（matcher）
expect(someList.length, 1);
expect(someString, startsWith('a'));

// 新风格（checks）
check(someList).length.equals(1);
check(someString).startsWith('a');
```

比如异步断言的语法差异：

```dart
// Future
await check(Future.value(10)).completes((it) => it.equals(10));

// Stream（需要 StreamQueue）
await check(stdout).emitsThrough((it) => it.equals('Ready'));
```

> 另外这个 Skill 还明确了让 AI 优先使用 MCP 工具（`run_tests`、`analyze_files`）而不是 shell 命令。

# 最后

可以看到这次更新的 Skills 实用性提高了不少，**每个 Skill 都不是在描述一个功能或者说明一个文档，而是在提供决策逻辑，让 AI 不需要多想，而是通过明确指令来解决问题**。

另外反馈循环（Feedback Loop）也很重要，很多 Skill 的工作流末尾都有显式的反馈循环：

![](https://img.cdn.guoshuyu.cn/image-20260507144515253.png)

**也就是每个技能的结果都需要做检验**，而不是执行完了之后让用户自己判断，比起单纯的文档，这次 Skills 的方向明显更加实用，这也是之前我们聊过 [《compose_skill 和 android skills》](https://juejin.cn/post/7628587639852630052) 的对比：

> 相比去官方 android skills 的泛化性支持，第三方用户提供的这个 compose_skill 实用性强了不少，因为他带了大量明确的实践判断和针对性产出，在提高项目性能和项目合理性上更有帮助。

**所以 Skills 现在更多不应该只是「告诉 AI 这个 API 怎么用，用什么」，而是更需要告诉 AI 「在什么情况下用哪种方式，遇到什么问题怎么修，如何验证结果」。**

所以，现在你可以把这个两个 Skills 用起来，因为它们现在确实能提供不错的生产力。

# 链接

https://github.com/flutter/skills

https://github.com/dart-lang/skills

