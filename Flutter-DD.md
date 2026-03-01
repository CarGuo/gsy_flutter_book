# Flutter 设计包解耦新进展，material_ui 和 cupertino_ui  发布预告

近日，Flutter 官方突然发布了 [material_ui](https://github.com/flutter/packages/tree/main/packages/material_ui) 和 [cupertino_ui](https://github.com/flutter/packages/tree/main/packages/cupertino_ui) ，不过包内暂时没有真实代码，只是作为预告和占位发布，根据预告内容：

- 对于 material_ui ，核心会包含：
  - **Structure:** `Scaffold`, `AppBar`, `Drawer`
  - **Inputs:** `FloatingActionButton`, `TextField`, `Slider`
  - **Display:** `Card`, `Chip`, `ListTile`
  - **Theming:** `ThemeData`, `ColorScheme`
- 对于 cupertino_ui ，核心会包括：
  - **Structure:** `CupertinoPageScaffold`, `CupertinoNavigationBar`
  - **Inputs:** `CupertinoButton`, `CupertinoTextField`, `CupertinoSwitch`
  - **Dialogs:** `CupertinoAlertDialog`, `CupertinoActionSheet`

![](https://img.cdn.guoshuyu.cn/0904a264709eb2b55ef8284f66a514c8.png)

同时，最重要的是，**这两个包都提及了  Material 3 Expressive  和 iOS 26 风格支持，也就是全新的样式适配，会跟随包一起发布**。

![](https://img.cdn.guoshuyu.cn/59276643455877a83d29e97529f86cc3.png)

而根据  [Decoupling Design #projects/220](https://github.com/orgs/flutter/projects/220)，目前大约 30 多个关键任务情况，目前：

- **已完成 (Done):** 约 11 项（约 31%）
- **正在进行 (In Progress):** 约 10 项（约 29%）
- **待处理/未开始 (Todo):** 约 14 项（约 40%）

所以整体阶段处于 **“基础设施搭建”** 与 **“代码清理/预重构”** 的中期阶段，目前看来 2026 年中后期完成迁移的可能性很高，根据任务情况，目前**已完成**的有：

- 任务评估： 完成了对文本栈 (Text Stack) 和基础颜色集 (Basic Color Set) 解耦的评估
- 发布支持：确定了全新新发布流程，并基本完成了 batch-release（批量发布）相关的 GitHub Action 工具链支持
- 某些组件：类似 Codeshare 的 Tooltip 控件已提前完成重构

而**正在进行**的任务主要是解决技术债，重点是消除内部耦合：

- 单元测试解耦：正在处理 Framework 单元测试不跨包导入的问题
- 测试基础设施： 正在为 `flutter/packages` 添加 Skia Gold 支持，以确保迁移后的组件仍能进行  Golden file 测试
- **核心逻辑抽取**  ：正在研究将平台特定的页面过渡动画移出设计包，以及在 `Widgets` 库中添加主题化选项支持

**未完成**，也就是还没开始工作的大多都是“搬运”工作：

- 在 `flutter/packages` 中建立正式的 Material/Cupertino 包（**实际上以发布空包**）
- 实际迁移大量的代码库
- 实现 `dart fix` 迁移工具，帮助开发者平滑过渡
- 最终在 SDK 中弃用旧的路径

所以整体看下来，整个流程还是相当清晰的：

- 前提条件：必须先完成禁止 Material 等包在单元测试里跨包导入，否则代码一旦物理移动，数千个测试将直接崩溃

- 基础设施准备：在代码移动前，必须先在目标仓库 (`flutter/packages`) 配置好发布流程和测试工具

- 开始阶段：在剥离设计语言前，需要先将原本混在 Material 里的通用基础组件迁移到  Widgets/Core 框架层 

- 迁移：只有上述工作完成，才能开始  Land material and cupertino library code 

- 最后通过自定义模板 和 dart fix 确保开发者能无缝使用新的包

所以，未来 Flutter 在 Framework 内将不带任何 material 和 cupertino 样式，你可以根据需要选择样式库，甚至觉得使用哪个样式库版本，最重要的是：

> **不升级 Flutter 版本也可以更新最新的设计样式，同时控件 Bug 也可以得到更快的修复和发布**。