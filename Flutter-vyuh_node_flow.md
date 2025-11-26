

# Flutter 也有类 React Flow 的节点流程编辑器，快来了解下刚刚开源的 vyuh_node_flow 



**[vyuh_node_flow](https://github.com/vyuh-tech/vyuh_node_flow) 是一个刚刚开源的 Flutter  Flow 节点编辑器，这是一个基于 MIT 许可的全平台节点/图形编辑器工具** ，它提供了类似 React Flow 的一系列功能支持：

![](https://img.cdn.guoshuyu.cn/image-20251029152126253.png)

基于  vyuh_node_flow ，你可以实现：

- **可视化编程界面**: 创建像 Scratch 或 Unreal Engine Blueprints 那样的图形化编程环境![](https://img.cdn.guoshuyu.cn/image-20251029152618671.png)

- **工作流编辑器**: 设计和编辑业务流程、数据处理流程或自动化任务![](https://img.cdn.guoshuyu.cn/image-20251029125819557.png)

- **交互式图表**: 构建组织结构图、思维导图、状态机等

- **数据管道**: 可视化地定义和管理数据流和处理步骤

另外，作为一个纯粹的 Flutter SDK，它支持所有平台，提供大量开箱即用功能，例如：

- 支持为 100+ 个节点和无限画布提供高性能渲染
- 具有泛型的完全类型安全节点
- 支持响应式主题化，可以更改节点主题、连接主题、样式等
- 背景支持配置网格、点阵、层级网格或纯色
- 支持平移和自定义定位的大型图表迷你地图(Minimap) ，方便在复杂的流程图中导航![](https://img.cdn.guoshuyu.cn/ezgif-6241a031b45aa1.gif)
- 支持标记、便签、群组等注释功能， 可以在画布上添加标签、注释（如便签 `StickyAnnotation`、标记 `MarkerAnnotation`)和自定义覆盖物，注解可以跟随节点移动
- 可以创建自定义节点和节点容器![](https://img.cdn.guoshuyu.cn/ezgif-6a79209ec10570.gif)
- 支持自定义绘制连接线 ，内置对贝塞尔曲线、直线、阶梯和平滑阶梯绘图器的支持
- 支持多种端口形状（半胶囊、圆形、方形、菱形、三角形）、位置（上、下、左、右）和偏移量，并支持连接验证
- **支持将整个图（包括节点、连接、注解、视口状态）导出为 JSON 或从 JSON 加载**
- 支持丰富的键盘快捷键操作（如全选、复制、粘贴、删除、缩放、对齐等）
- 支持节点对齐
- **只读支持**，提供 `NodeFlowViewer` 组件，用于仅显示流程图，禁止编辑
- ·····

![](https://img.cdn.guoshuyu.cn/image-20251029125826707.png)

通过源码可以看到，这是一个相当完整的 Flow 编辑器，并且它的整体设计思路也很有意思，其中包括：

- **状态管理**: 它内置直接使用 MobX 自动处理状态更新和 UI 响应，如节点位置、选择状态的变化会自动触发相关 UI 的重绘
- **分层渲染**: 通过 `CustomPaint` 和 `Stack` 实现，编辑器将不同的元素（网格、背景注解、连接线、连接标签、节点、前景注解、交互元素）渲染在不同的层 (Layer) 中，例如连接标签在单独的层中渲染，避免连接线重绘时标签也重绘
- **可定制的节点渲染**: 通过 `nodeBuilder` 和 `nodeContainerBuilder` 允许用户完全自定义节点的内部内容和外部容器样式
- **连接线样式**: `ConnectionStyles` 提供了多种内置样式，并且路径计算逻辑 (`ConnectionPathCalculator`, `SmoothstepPathCalculator` 等) 也被抽象出来，便于扩展自定义样式
- **连接验证**: 提供了 `onBeforeStartConnection` 和 `onBeforeCompleteConnection` 回调，允许开发者在连接开始和完成前进行自定义逻辑验证，例如检查端口类型兼容性、防止循环连接等
- **注解系统**: 支持多种类型的注解，并且 `GroupAnnotation` 可以自动包围其依赖的节点并跟随移动，`StickyAnnotation` 和 `MarkerAnnotation` 也可以通过 `dependencies` 跟随节点
- **快捷键与动作系统**: 内置了丰富的快捷键操作 ( `NodeFlowShortcutManager`, `NodeFlowAction`)，并且易于扩展和自定义，并且提供了 `ShortcutsViewerDialog` 来显示所有可用的快捷键。
- **性能相关优化设计**:
  - 使用 `Observer` 包裹需要响应式更新的 Widget 部分，实现局部刷新
  - 使用 `RepaintBoundary` 隔离复杂的绘制层（如连接线层、节点层），避免不必要的重绘
  - 连接线路径和命中测试路径的缓存 (`ConnectionPathCache`)
  - 空间索引 (`SpatialIndex`) 用于优化大量节点的查询和命中测试
- **序列化与反序列化**: 提供了方便的方法 (`toJsonString`, `fromJsonString`, `fromUrl`, `fromAsset`) 来保存和加载图的状态

也就是，vyuh_node_flow  在项目里大量使用了  MobX 用于响应式状态管理 ，代码中广泛使用 `Observable`, `Computed`, `action`, `reaction`, `runInAction` 以及 `Observer`  来实现 UI 和状态响应，同时放大缩小和平移主要依赖 Flutter 内置的 **`InteractiveViewer`** 实现。

相对应的，vyuh_node_flow  也有比较复杂的 API 结果，其中核心 API 有:

- **`NodeFlowController<T>`**: 核心状态管理器，负责管理节点、连接、注解、视口、配置、主题和交互状态，它通过使用 MobX 的 `Observable` 来实现响应式更新
- **`NodeFlowEditor<T>`**: 主要的编辑器控件，接收 `NodeFlowController`，负责渲染画布、节点、连接、注解，并处理用户交互（拖拽、连接、选择、平移、缩放）
- **`NodeFlowViewer<T>`**: 只读模式的 Widget，基于 `NodeFlowEditor` 但禁用了编辑功能
- **`Node<T>`**: 代表画布上的一个节点，包含 ID、类型、位置、尺寸、数据 (`T` ) 以及输入/输出端口列表，而位置 (`position`) 和视觉位置 (`visualPosition`) 是分离的 `Observable`，后者用于应用网格吸附后的渲染
- **`Port`**: 定义节点的连接点，包含 ID、名称、位置 (`PortPosition`)、形状 (`PortShape`)、类型 (`PortType`，如 source/target/both)、是否允许多重连接等属性
- **`Connection`**: 代表节点间的一条连接线，包含 ID、源/目标节点 ID、源/目标端口 ID，以及可选的标签 (`label`, `startLabel`, `endLabel`) 和样式 (`style`)
- **`Annotation`**: 注解的基类，子类包括 `StickyAnnotation` (便签)、`GroupAnnotation` (节点分组)、`MarkerAnnotation` (标记)，注解可以有自己的位置、尺寸、样式，并且可以通过 `dependencies` 关联节点
- **`NodeFlowTheme`**: 定义编辑器所有视觉元素的样式，包括节点、连接线、端口、背景、网格、选择框等的颜色、大小、形状、字体等，包含 `NodeTheme`, `ConnectionTheme`, `PortTheme`, `LabelTheme`
- **`NodeFlowConfig`**: 控制编辑器的行为，如是否启用网格吸附、小地图、缩放范围、自动平移等
- **`NodeGraph<T>`**: 用于序列化和反序列化的数据结构，包含节点、连接、注解和视口状态
- ····

运行库提供的 MVP 示例，可以看到使用起来也不是很复杂，通过向 `controller` 添加两个 `Node` ，然后添加到 `NodeFlowEditor` ，并通过  `_buildNode` 渲染需要的节点，就可以得到一个可交互连接的 Flow 显示：

```dart
import 'package:flutter/material.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class SimpleFlowEditor extends StatefulWidget {
  @override
  State<SimpleFlowEditor> createState() => _SimpleFlowEditorState();
}

class _SimpleFlowEditorState extends State<SimpleFlowEditor> {
  late final NodeFlowController<String> controller;

  @override
  void initState() {
    super.initState();

    // 1. Create the controller
    controller = NodeFlowController<String>();

    // 2. Add some nodes
    controller.addNode(Node<String>(
      id: 'node-1',
      type: 'input',
      position: const Offset(100, 100),
      data: 'Input Node',
      outputPorts: const [Port(id: 'out', name: 'Output')],
    ));

    controller.addNode(Node<String>(
      id: 'node-2',
      type: 'output',
      position: const Offset(400, 100),
      data: 'Output Node',
      inputPorts: const [Port(id: 'in', name: 'Input')],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NodeFlowEditor<String>(
        controller: controller,
        theme: NodeFlowTheme.light,
        nodeBuilder: (context, node) => _buildNode(node),
      ),
    );
  }

  Widget _buildNode(Node<String> node) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(node.data),
    );
  }
}
```

![](https://img.cdn.guoshuyu.cn/bbttttttttttttt.gif)

根据前面的 API ，我们可以简单拼接出 vyuh_node_flow   的实现原理：

- **核心**: `NodeFlowController` 作为中心枢纽，存储所有状态 (节点、连接、视口等) 的 `Observable` 实例
- **渲染**: `NodeFlowEditor` 
  - 使用 `Stack` 组织不同的渲染层 (`GridLayer`, `ConnectionsLayer`, `NodesLayer`, `AnnotationLayer` 等)
  - `NodesLayer` 和 `AnnotationLayer` 使用 `Positioned` 和 `Observer` 来渲染每个节点/注解，只在位置等 `Observable` 变化时重绘
  - `ConnectionsLayer` 和 `GridLayer` 使用 `CustomPaint` 和 `Observer` 来绘制连接线和网格，响应节点位置和视口的变化
- **交互**: `NodeFlowEditor` 使用 `Listener`, `GestureDetector`, `MouseRegion` 监听原始指针事件
  - 事件发生时，它会进行命中测试 (`_performHitTest`) 以确定交互对象（画布、节点、端口、连接、注解），然后调用 `NodeFlowController` 中对应的内部方法 (`_startNodeDrag`, `_moveNodeDrag`, `_startConnection`, `_completeConnection`, `_updateSelectionDrag` 等）来更新 MobX 状态
  - 这些状态更新会自动触发相关 `Observer` Widget 的重绘
- **连接线绘制**: `ConnectionPainter` 负责绘制连接线
  - 它使用 `ConnectionPathCache` 来缓存计算出的 `Path` 对象
  - 当需要绘制或进行命中测试时，它会先检查缓存
  - 如果缓存无效（例如节点移动了），则重新计算路径（委托给具体的 `ConnectionStyle` 实现）并更新缓存
- **状态更新**: 所有状态变更都通过 `NodeFlowController` 的方法进行，内部使用 `runInAction` 来确保 MobX 的原子更新

![](https://img.cdn.guoshuyu.cn/image-20251029151844660.png)

从代码结构和使用的技术来看，`vyuh_node_flow`  也采用了多种提升性能的策略：

- **MobX**：仅在状态变化时更新必要的 UI 部分
- **分层渲染 (Layered Rendering)**：使用 `Stack` 将网格、连接线、节点、注解等分层绘制，并通过 `RepaintBoundary` 隔离复杂的绘制层，减少不必要的重绘范围
- **路径缓存 (`ConnectionPathCache`)**：缓存连接线的计算路径 (`Path`) 和用于命中测试的路径，避免在每次重绘或交互时重复计算
- **空间索引 (`SpatialIndex`)**: (`lib/shared/spatial_index.dart`, `lib/shared/node_spatial_adapter.dart`) 使用基于网格的空间索引，来快速查询可见区域内的节点或与特定区域重叠的节点，这对于节点数量较多时的性能至关重要，避免了遍历所有节点进行可见性判断或命中测试

总的来说，`vyuh_node_flow` 是一个功能丰富、设计良好且注重性能的 Flutter 节点编辑器库，特别适合需要高度自定义和交互性的可视化流程编辑场景，尽管目前还缺失一些复杂的图形自动布局算法，但是可用性已经相当成熟，至少对于 Flutter 开发者来说，这是一个不错的支持。

> 根据作者的说法，这也是一个致敬 React Flow 的项目![](https://img.cdn.guoshuyu.cn/image-20251029161027225.png)



# 参考链接

https://github.com/vyuh-tech/vyuh_node_flow

