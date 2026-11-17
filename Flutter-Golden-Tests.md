# Flutter Golden Tests：给 AI Agent 的 UI 测试系统

最近 `ASO.dev` 发了一个  Flutter Golden Test ，开源了两个工具：

- `ff_golden` 负责**场景执行、变体矩阵、截图与比较**
- `ff_golden_presenter` 负责**Diff 审查、报告和发布**

**Golden Test 本身来说没什么新东西，Flutter 原生  `matchesGoldenFile`  很早就能做逐像素比较，这套东西主要是在工程上补上了「大型 Flutter App 怎么把 Golden Test 工程化」的能力** ，比如：

- 把设备、主题、语言、字体缩放组合变成一个正式的 coverage matrix
- 把页面截图提升成“状态场景”
- 把确定性的测试入口交给 Coding Agent，作为修改 UI 后的自动 verifier

![](/article-assets/8211896d0de7d2c429e34686.webp)

> **也就是一个 Scenario，覆盖关键 Variants**。

一般来说，Flutter 原生 Golden Test 其实很简单：

> 渲染一个 widget，然后拿 PNG 和基准图逐像素比较。

因为麻烦的地方根本不在 `matchesGoldenFile()`，就简单问题一句：“到底要截哪几张图”？比如同一个页面至少会受到 window size、DPR、safe area、Android/iOS platform、Light/Dark、locale、RTL、text scale、high contrast 之类这些条件影响，其中字体和 Flutter 版本不同都可能导致 Golden 结果变化。

这其实也是 `ff_golden` 做得比较有意思的地方，它是直接把这些东西建模成 `GoldenCoverage`，也就是设备、语言、主题、字体缩放、高对比度等这些先做笛卡尔积，再经过 `require` / `excludeWhen` 这类约束过滤，最后才进行采样。

**采样提供 `full`、`smoke`、`pairwise` 和 `priority` 四种策略，特别是尤其 `pairwise` 很实用**：

> 你不用真的把所有维度全部排列组合跑一遍，但能保证任意两个维度值之间的重要组合都被覆盖。

```dart
coverage: GoldenCoverage(
  devices: const [
    GoldenDevice.iPhone11,
    GoldenDevice.iPad,
  ],
  locales: const [Locale('en'), Locale('ar')],
  themes: [GoldenTheme.light, GoldenTheme.dark],
  textScales: const [1, 1.5, 2],
  highContrasts: const [false, true],
  sampling: GoldenSampling.pairwise,
  maxCombinations: 24,
)
```

这里还有一个我挺喜欢的设计：**coverage budget 不够会直接报错，不会偷偷降低覆盖率** ，在 `full / smoke / pairwise`  下，如果 `maxCombinations` 无法满足要求，会直接抛 `GoldenCoverageBudgetExceeded` ，这个小细节其实很重要的，不然 CI 看起来一片绿，实际上你以为自己跑了 pairwise，工具可能少跑了一半。

之前也有不少 Golden Test 新范式，比如：

- `golden_toolkit` 很早就有 `DeviceBuilder`、`multiScreenGolden` 和多状态 Golden
- Alchemist 也已经支持 scenario、text scale、平台/CI Golden、diff threshold 等能力

`ff_golden` 特别在于，**它把这些零散能力继续往“测试矩阵调度器”方向走了一层**，加入组合约束、pairwise/risk sampling、hard budget 和 CI metadata。

**其次就是 *we test states, not just pages***，`ASO.dev`对一个页面不会只留一张 loaded PNG，它是会固定 loading、empty、error、权限受限、dialog 打开、最大列数、长文本、筛选状态等 fixture，然后让这些状态继续经过前面的 device/theme/locale matrix。

> 比如一个 API error，在这里不光验证“代码处理了异常”，还会验证错误标题有没有消失、长错误消息有没有撑爆布局、按钮有没有在窄屏被挤出屏幕等等，`ASO.dev` 甚至把真实 Sentry 里遇到过的错误固化成 JSON fixture，再回灌到 Golden 场景。

**然后另一个很工程化的点是，他们没有无脑依赖 `pumpAndSettle()`**，因为在复杂 Flutter 页面里，只要有一个不停跑的动画或者后台 ticker，`pumpAndSettle()` 就可能一直等，但是写死 `Future.delayed()` 又会导致 CI 慢且不稳定。

这里 `ff_golden`  就提供 `pumpUntilFound`、`pumpUntil`、`pumpUntilGone`、`pumpFrames`、`elapse` 之类的有界虚拟时间接口，等一个明确可观察状态出现，然后再截屏，它还支持一个 scenario 中间截多张：

```dart
interact: (context) async {
  await context.capture(testName: 'empty');

  await context.tester.tap(find.text('Add item'));

  await context.capture(testName: 'with-item');
},
```

这样一个 checkout、dropdown、dialog、hover/pressed 之类的流程，也不需要拆成几个互相没有关系的测试，再加上默认的 pixel-perfect、`RenderFlex overflow`、文件名冲突、stale baseline 检查，**这套东西已经开始有点像Flutter UI 的状态快照测试 Harness了**。

然后这套工具还和 Coding Agent 有关系，比如 Agent 的任务是：

> “iPhone 5S 宽度下，这个 Table 右边 overflow 1px。”

一般来说 Computer Use 的路径通常是：

> 编译完整 App - 启动 - 登录 - 准备数据 - 导航到页面 - resize - 等状态 - 截图 - Agent 再用视觉判断有没有修好。

这里每一步都引入状态，账号、网络、窗口、数据、截图时间都会影响结果，但是 `ASO.dev` 的 Golden 路径选择直接把这个 bug 固化成一个 named scenario：

> 固定 fixture + 固定 device geometry + 固定 theme，然后 Agent 改代码、跑这一条测试，看 pixel diff，最后再补跑 matrix。

![](/article-assets/74351f73e1b8b80c97ad97e3.webp)

这对 Coding Agent 就很有用，**因为它把一个模糊的视觉任务变成了机器可以直接验证的测试目标**。

Agent 其实不需要每次都“看懂整张 UI”，测试 Harness 已经替它回答了“*修改以后，在 iPhone11 / dark / RU / 1.5x text 下结果是不是和批准过的基线一致*”之类的结果。

这其实和现在 Coding Agent 里越来越强调的 executable verifier 是同一条路：

> 单元测试验证 logic，benchmark 验证性能，Golden Test 验证视觉 contract，特别是 Flutter 这种自己控制 Rendering Pipeline 的框架，本来就非常适合干这个。

不过也有局限， Golden Test 运行的是 Flutter widget 的受控渲染路径，它看不到真正的系统输入法、原生 Dialog、Platform Channel UI、真实窗口管理、拖拽行为，也不能替代完整 E2E 场景，完整来说就是：

> **Golden Test 做 Agent 的快速局部 verifier，Computer Use / Patrol / integration_test 做最后的真实环境验证。**

最后还有前面提到的  `ff_golden_presenter` ，它补的是 Golden Test 的 Diff 审核和图片债务，因为当 Golden Test 真正规模化以后，最烦的很快就不再是写测试，更能麻烦的会是“ 谁来审核 100 张 PNG 到底哪些该更新**。

而 `ff_golden_presenter diff`  会在 `127.0.0.1` 起一个本地 Web UI，把 Git 中 baseline 和 working tree 图片放到一起，可以 side-by-side、highlight changed pixels、同步 zoom/pan，还能直接 stage / unstage、跑对应 test、查看 log、打开 Dart 文件。

![](/article-assets/0eaf7157ecf9dceac69c6f97.webp)

> 也就是 Presenter 里的 pixel diff 只是 review 工具。

Presenter 还能把所有 Golden 复制出来、压缩、生成无运行时依赖的静态 HTML gallery，然后直接作为 CI artifact、GitHub Pages 或 nginx 站点发布。

>  Golden Test 最大的坑之一就是：**PNG 会把 Git 仓库撑爆。**

`ASO.dev` 在只有  2000 张 baseline 的时候，当前 PNG 就三百多 MB，本地 `.git`  3.6 GB，三年后甚至为了继续用 GitLab 免费额度迁过一次活跃仓库，所以这个 Presenter  绝对会比你想象中实用。

总的来说，这套 FF Golden 工具链是真的挺不错的，特别是拿来做自动化测试就很贴合。

## 链接

https://aso.dev/blog/flutter-golden-tests/
