# 基于 Dart 的 Terminal UI ，pixel_prompt 这个 TUI 库了解下

今天介绍一个特殊的 Dart 开源库 [pixel_prompt](https://github.com/primequantuM4/pixel_prompt) ，`PixelPrompt` 是 **Dart 的终端 UI (Terminal UI TUI) 框架** ，它属于参考了 Flutter 的响应式 UI 实现，利用 Dart 实现的声明式 TUI ：

![](https://img.cdn.guoshuyu.cn/snake_demo.gif)

是的，**`PixelPrompt` 和 Flutter 没有直接关系，是一个纯 Dart 实现，实现的 UI 也是运行在终端的 TUI ，而非 App UI ，如果非要说的话，类似你现在用的 Claude Code 或者 Gemini Cli 上呈现的某些 “UI”** 。

> `PixelPrompt` 将 Dart 声明性 UI 样式引入到了 Terminal ，让开发者可以使用**布局、状态组件和键盘/鼠标事件**来构建交互式、样式化的终端应用。

既然是一个终端 UI 框架，那么 `PixelPrompt` 的实现就不是我们常规认真的“像素 UI”，`PixelPrompt` 的渲染不是直接基于像素，而是**基于字符单元格 (Character Cells - BufferCell)** ，这也是它和一般应用 UI 实现的区别。

在 `PixelPrompt` 的内部， UI 是由一个个“组件 (Component)”构成，这在概念上和 Flutter 的 Widget 非常相似，项目定义了 `Component` 抽象类作为所有 UI 元素的基类，它有两种核心组件类型：

- `BuildableComponent`: 类似于 Flutter 的 `StatelessWidget`，用于构建静态、无状态的 UI 部分，它通过一个 `build` 方法返回一组子组件。
- `StatefulComponent`: 类似于 Flutter 的 `StatefulWidget`，用于需要维护和更新内部状态的动态 UI 部分，它通过 `createState` 方法创建一个 `ComponentState` 对象来管理状态，当状态改变时，可以调用 `setState` 来触发 UI 重绘。

> 这就很 Flutter 了。

当然，在渲染机制上它会使用一个名为 `CanvasBuffer` 的类，**这个类在内存中维护一个二维网格（`List<List<BufferCell>>`）**，代表终端屏幕的每一个字符位置：

- 每个 `BufferCell` 存储了该位置要显示的字符、前景色、背景色和字体样式（如粗体、斜体）
- 当组件需要被渲染时，它会调用 `render` 方法，将自己的内容（字符和样式）绘制到 `CanvasBuffer` 的指定区域
- 最后，**`RenderManager` 会高效地将 `CanvasBuffer` 中的内容与前一帧进行比较，只将有变化的部分通过 ANSI 转义序列 (ANSI escape codes)** 输出到终端，从而更新屏幕显示、移动光标和改变颜色

> 在这里有一个重点：ANSI ， TUI 程序之所以能在 macOS、Linux 和 Windows 的终端里运行，关键在于一个**通用的标准：ANSI 转义序列 (ANSI escape codes)**。

在 TUI 领域里并不会为每个操作系统编写特定的图形代码，这里可以将 ANSI 转义序列想象成一种**终端世界的“通用语言”**，它是一些特殊的文本命令，当终端程序（如 iTerm2, Windows Terminal）接收到这些命令时，它不会把它们当成普通字符显示出来，而是会执行相应的操作，比如：

- 移动光标到屏幕的任意位置
- 改变后续文本的颜色（前景和背景）
- 改变文本样式（如加粗、下划线）
- 清空屏幕的一部分或全部

所以在 TUI 领域，**渲染 = 把 UI 变成 ANSI** ，绝大多数 ANSI 码都遵循一个通用格式：

- **转义字符 (ESC)**：所有命令都以一个特殊的“转义”字符开始，在  `PixelPrompt` 的代码中通常表示为 `\x1B`

- **控制序列引导符 (CSI)**：紧跟在 ESC 后面的是一个左方括号 `[`，`ESC` 和 `[` 的组合被称为 CSI (Control Sequence Introducer)

- **参数 (Parameters)**：在 CSI 和结束符之间，可以有一个或多个由分号 `;` 分隔的数字，这些数字是命令的具体参数。

- **结束符 (Final Byte)**：一个字母，用来定义这个命令的类型。

比如在 `PixelPrompt` 代码中的例子：

- **移动光标**：
  - 格式：`\x1B[<行号>;<列号>H`
  - `PixelPrompt` 在 `CanvasBuffer` 的 `render` 和 `moveCursorTo` 方法中大量使用它，来精确地将光标定位到要更新的字符格
  - 例如 `\x1B[10;20H` 的意思是：“把光标移动到第 10 行，第 20 列”
- 设置图形样式 ：
  - 格式：`\x1B[<参数>m`
  - 用来改变颜色和样式的命令`，PixelPrompt` 在 `TextComponentStyle` 的 `getStyleAnsi()` 方法中生成这些代码。
  - **颜色**：`\x1B[31m` 设置前景色为红色（30-37 是标准前景色），`\x1B[42m` 设置背景色为绿色（40-47 是标准背景色）
  - **样式**：`\x1B[1m` 设置为粗体
  - **24位真彩色**：`\x1B[38;2;<r>;<g>;<b>m` 设置前景色的 RGB 值，如 `\x1B[38;2;255;100;50m`。
  - **重置**：`\x1B[0m` 清除之前所有的颜色和样式设置，恢复到终端的默认状态

举个例子，比如在 window 里输入 `Write-Host "$([char]27)[2J$([char]27)[5;10H$([char]27)[93mThis is a complex"` ，如下图所示，可以看到终端被清屏，不过你的输出文本的颜色和光标位置都发生了变化，因为：

- `[2J` 清空整个屏幕 
- `[5;10H` 移动到第5行第10列 
-  `[93m` 设置为亮黄色 

![](https://img.cdn.guoshuyu.cn/ezgif-18ee306ce7c06a.gif)

> 而后续去掉 `[2J`  后，可以看到命令就没有清屏，而是只执行了光标移动和文本输出。

而在布局支持上，`PixelPrompt`  自定义了一个 `LayoutEngine`，它负责计算和定位所有组件在终端屏幕上的位置和大小，目前它提供了类似于 Flutter 的 `Row` 和 `Column` 组件，用于水平和垂直方向的布局，这些布局组件会根据其子组件的大小和指定的 `childGap`（间距）来计算自身的尺寸：

> 整个布局过程是递归实现，主要是从根组件 `App` 开始，引擎会遍历整个组件树，测量（`measure`）每个组件的尺寸，并为它们分配一个矩形区域（`Rect`）用于渲染。

详细来说，`LayoutEngine` 主要是针对组件进行布局整理，方便后续转移渲染：

#### 测量

在开始测量时，它首先会调用根组件的 `measure` 方法，询问在给定的最大可用空间 (`maxSize`) 下，整个应用大概需要多大的空间，然后它会以根组件和其计算出的边界 (`rootBounds`) 为起点，调用 `_layoutRecursiveCompute` 方法，开始递归地为每一个子组件分配位置。

`_layoutRecursiveCompute` 方法是布局的核心，它自上而下 (Top-Down) 地为组件树中的每一个节点分配一个精确的矩形区域 (`Rect`)，实际上就是在为一个子组件完成测量和定位之后，引擎会以这个子组件和它刚刚被分配到的 `Rect` 为参数，**递归地调用 `_layoutRecursiveCompute` 方法**，从而开始对这个子组件的下一层子孙进行布局。

#### 输出

当 `compute` 方法的递归过程全部结束后，它会返回一个 `List<PositionedComponentInstance>`，其中 `PositionedComponentInstance` 是一个简单的数据结构，它将一个组件实例 (`componentInstance`) 和它最终被计算出的位置与尺寸 (`rect`) 绑定在一起。

**这个列表就是整个 UI 的控件级别的最终布局蓝图**，前面我们讲到的渲染系统 (`AppInstance` 中的 `render` 方法) 会接收这个列表，遍历它，并告诉每个组件：“好了，你的位置和大小已经确定了（就是这个 `Rect`），现在请在这个区域内把自己画到 `CanvasBuffer` 上吧！”

####  UI 蓝图

`List<PositionedComponentInstance>` 作为 `LayoutEngine` 的最终产物，可以把它理解为一份极其详细的 **“UI 施工蓝图”**，其中：

- **`componentInstance`**: **要画什么？**例如具体的某个组件实例，比如一个 `TextComponent` 实例或一个 `ButtonComponent` 实例

- **`rect`**: **要画在哪里，画多大？** 一个 `Rect` 对象，精确地定义了这个组件在终端屏幕上的矩形区域，包含了它的左上角 `x, y` 坐标以及它的 `width` 和 `height`

所以，这个 UI 蓝图列表的含义可以理解为：

> “渲染系统，请按照这个列表进行施工：
>
> - 把**这个文本组件**画在 `(x:5, y:2, width:10, height:1)` 的区域里
> - 接着，把**这个按钮组件**画在 `(x:5, y:4, width:15, height:3)` 的区域里
> - 再接着，把**那个容器组件**画在 `(x:0, y:0, width:30, height:10)` 的区域里
> - ...”

#### CanvasBuffer

最终，“蓝图”需要通过内部的 `AppInstance` 和 `CanvasBuffer` 协同工作进行转移渲染。

首先，`App` 的实例 (`AppInstance`) 在拿到 `LayoutEngine` 给出的这份“施工蓝图” (`List<PositionedComponentInstance>`) 之后，它会开始遍历这个列表，然后调用对应 `componentInstance` 自身的 `render` 方法，并把两个关键参数传给它：

- `CanvasBuffer` 对象：这就是我们之前提到的那个**内存中的虚拟屏幕**。

- `rect` 对象：这就是蓝图中为这个组件分配好的**矩形区域**。

接着就是在内存里的虚拟屏幕（`CanvasBuffer`）进行绘制，比如每个组件实例都收到了自己的施工任务后，就会在自己的 `render` 方法内部，根据自己的内容（比如 `TextComponent` 的文本）和被分配的 `rect`，计算出应该在 `CanvasBuffer` 的哪些单元格里填上什么内容。

然后，它会调用 `buffer.drawAt()` 或 `buffer.drawChar()` 方法，把自己的字符、颜色和样式信息“画”到内存中的 `CanvasBuffer` 里。例如，`TextComponent` 的 `render` 方法可能会进行：

> “`rect` 是从 `(x:5, y:2)` 开始，文本是 'Hello'，所以对应是 `buffer.drawAt(5, 2, "Hello", ...)`。”

而之所以会有 `CanvasBuffer` ，主要是为了实现高效的内容同步，例如：

- `CanvasBuffer` 的基石是两个二维列表（`List<List<BufferCell>>`），它们充当了**双缓冲**：

  - `_screenBuffer`: 代表**当前帧**要绘制的内容。所有 `draw` 操作都会更新这个缓冲区。

  - `_previousFrame`: 存储**上一帧**已经绘制到终端的内容。

- **差分渲染**，由 `render()` 方法完成。它的目标是**用最少的操作来更新终端屏幕**，从而实现高性能和无闪烁的刷新，核心思想是，它只更新从上一帧到当前帧发生变化的单元格。

####  ANSI 

在所有组件都画完之后，主程序会调用 `canvasBuffer.render()` 方法，这个方法会遍历内存中的 `_screenBuffer`，**比较每个单元格与 `_previousFrame` 中对应单元格的差异**，对有差异的单元格生成 ANSI 指令，将所有这些指令和字符拼接成一个巨大的字符串，最后通过 `stdout.write()` 将这个字符串一次性输出到终端，从而呈现出 UI ，例如在终端最终通过相应用户输入，渲染出对应的效果：

![](https://img.cdn.guoshuyu.cn/image-20250905153335957.png)![](https://img.cdn.guoshuyu.cn/image-20250905153343487.png)

整个过程总结如下图所示：

![](https://img.cdn.guoshuyu.cn/%E5%98%8E%E5%98%8E%E5%90%84%E7%A7%8D%E8%B5%84%E8%B4%A8%E5%9C%A8%E7%BA%BF%E5%92%A8%E8%AF%A2.png)

可以看到，pixel_prompt 将 Dart 带到了一个新的小众领域，也在桌面领域补全了 Dart 的小短板，当然大多数时候你可能并不会有到，但是这不乏为一个有趣的尝试。

当然，目前 pixel_prompt  还处于实验性阶段，所以 **API 尚不稳定** ，另外关于菜单 (menus)、表格 (tables) 和多行文本输入区 (textfield area)这些还处于实现阶段，也暂不支持滚动视图 ，一些高级功能例如可视化调试器也还在完善，但是总体来说，pixel_prompt  还是属于一个非常有意思的项目。

