

# Flutter 小技巧之强大的 UI 骨架屏框架 skeletonizer 

很久没有更新过小技巧系列，今天简单介绍一个非常好用的骨架屏框架 skeletonizer ，它主要是通过将你**现有的布局自动简化为简单的骨架，并添加动画效果**来实现加载过程，而使用成本则是简单的添加一个  `Skeletonizer` 作为 parent ：

```dart
Skeletonizer(
  enabled: _loading,
  child: ListView.builder(
    itemCount: 7,
    itemBuilder: (context, index) {
      return Card(
        child: ListTile(
          title: Text('Item number $index as title'),
          subtitle: const Text('Subtitle here'),
          trailing: const Icon(Icons.ac_unit),
        ),
      );
    },
  ),
)
```

![=](https://img.cdn.guoshuyu.cn/skeletonizer_demo_1.gif)

当然，在实际使用场景中，一般情况在列表返回之前我们是没有数据的，所以可以在加载过程中，通过 skeletonizer  提供的 `BoneMock` 来组装一个你需要长度的数据列表：

```dart
 final fakeUsers = List.filled(7, User(
      name: BoneMock.name,
      jobTitle: BoneMock.words(2),
      email: BoneMock.email,
      createdAt: BoneMock.date, 
    ),
  );
  final users = _loading ? fakeUsers : realUsers;
  return Skeletonizer(
    enabled: _loading,
    child: UserList(users: users),
  );
    
```

那 skeletonizer 是如何做到这个自动转换控件为骨架屏的呢？**核心就是在绘制 child 时，通过自定义 context 来替换默认 `PaintingContext`** ：

![](https://img.cdn.guoshuyu.cn/image-20250729095426043.png)

> 在  skeletonizer  内部，它的 `RenderSkeletonizer` 是一个  `RenderProxyBox` 实现，作为一个 `RenderProxyBox` 的子类，它在布局阶段表现得像一个透明代理，但在绘制阶段会接管控制权，决定是绘制真实的子节点还是绘制骨架。

简单来说，**skeletonizer 就是通过自定义 `PaintingContext` 来拦截处理 child 的渲染** ，这里我们先简单看看它的核心代码的作用：

- **`render_skeletonizer.dart`**:
  - 它是 `RenderObject` 的实现，也就是实际负责渲染的对象， `RenderSkeletonizer`  和 `RenderSliverSkeletonizer`  的核心就是 override `paint` 方法，当 `Skeletonizer` 被激活时，它们不会像平常一样绘制 `child`，而是创建一个自定义的 `SkeletonizerPaintingContext` 来接管绘制工作

- **`skeletonizer_painting_context.dart`**:
  - 骨架屏效果的关键，继承自 `PaintingContext`，但是提供了一个自定义的 `Canvas` 对象` SkeletonizerCanvas`，这个自定义的 `Canvas` 会拦截所有来自 child  的绘制，然后用骨架的样式来替代它们

- **`uniting_painting_context.dart`**:
  - 在 paint 里对应 `Skeleton.unite`  的特殊实现，它提供了一个名为 `UnitingCanvas` 的特殊 `Canvas`，当 `child` 在这个 `Canvas` 上绘制时，它不会真的去绘制每个元素，而是计算所有绘制操作的区域，并将它们合并成一个大的矩形（`unitedRect`），最终这个合并后的大矩形会被统一渲染成一个骨架块
- **`/effects/\*.dart`**:
  - 这个目录主要用于定义骨架屏的视觉动画效果，其中 `painting_effect.dart` 定义了所有效果必须遵守的抽象基类 `PaintingEffect`，主要是通过构建 `Paint` 来构建动画，默认的对应实现有：
    - `shimmer_effect.dart`: 实现了最常见的“微光”或“闪烁”效果，通过一个滑动的 `LinearGradient` (线性渐变) 来实现
    - `pulse_effect.dart`: 实现了“脉冲”效果，在两种颜色之间来回渐变
    - `sold_color_effect.dart`: 纯色效果，没有动画

![](https://img.cdn.guoshuyu.cn/mermaid-diagram-2025-07-29-102959.png)

所以，整个骨架屏的渲染流程如上图所示，可以总结为：

- **启用 Skeletonizer**:
  - 当 `Skeletonizer(enabled: true, child: ...)` 被构建时，它会启动一个动画控制器（`AnimationController`），并根据配置选择一个 `PaintingEffect` (例如 `ShimmerEffect`)

- **创建 RenderObject**:
  - `Skeletonizer` 会创建一个 `RenderSkeletonizer` (或 `RenderSliverSkeletonizer`) 对象，这个 `RenderObject` 会将自己标记为 `isRepaintBoundary = true`，这意味着它会创建一个独立的绘制层 (Layer)

- **接管绘制上下文**:
  - 在 `paint` 阶段，`RenderSkeletonizer` 不会像普通 `RenderObject` 那样直接调用 `super.paint` 来绘制 `child`，相反它会创建一个 `SkeletonizerPaintingContext` 实例，用于拦截绘制

- **拦截绘制指令**:
  -  `SkeletonizerPaintingContext` 内部包含一个 `SkeletonizerCanvas`，当 Flutter 引擎尝试绘制 `child` 时（比如 `Text`、`Container`、`Icon` 等），所有对 `canvas` 的操作（如 `drawParagraph`, `drawRect`, `drawImage`）都会被 `SkeletonizerCanvas` 拦截

- **替换为骨架样式**:
  - `SkeletonizerCanvas` 会根据拦截到的绘制指令的类型和位置，绘制出相应的骨架形态，并实现一些系列绘制方法，比如：
    - **文本 (`drawParagraph`)**: 它会计算出文本的每一行在哪里，然后用一系列矩形来代替真实的文字，矩形的圆角、是否对齐等：![](https://img.cdn.guoshuyu.cn/image-20250729102231322.png)
    - **矩形/圆角矩形 (`drawRect`/`drawRRect`)**: 它会检查这个矩形是否被标记为“叶子节点”（比如一个没有子节点的 `Container` 或被 `Skeleton.leaf` 包裹的 Widget），如果是，它就会使用从 `PaintingEffect` (如 `ShimmerEffect`) 创建的 `shaderPaint` (带有闪烁效果的画笔) 来填充这个区域，如果不是，它可能会根据配置绘制一个纯色背景，或者干脆忽略它：![](https://img.cdn.guoshuyu.cn/image-20250729102326225.png)
    - ······

- **应用动画效果**:
  - 所有用于绘制骨架的 `shaderPaint` 都来自于当前的 `PaintingEffect`，`Skeletonizer` 的 `AnimationController` 会不断更新动画值 (`animationValue`)，**`PaintingEffect` 根据这个值来创建每一帧的 `Paint` 对象**，对于 `ShimmerEffect` 来说，这就表现为一个不断移动的渐变，从而产生了微光流动的效果：![](https://img.cdn.guoshuyu.cn/image-20250729102513322.png)![](https://img.cdn.guoshuyu.cn/image-20250729102603563.png)

而在使用使用中，skeletonizer   也提供了丰富的可配置细节，例如：

- **`skeleton.dart`**: 提供了一系列控制场景：

  - `Skeleton.ignore`: 忽略某个子 Widget，不对其进行骨架化

    ```dart
    Card(
      child: ListTile(
        title: Text('The title goes here'),
        subtitle: Text('Subtitle here'),
        trailing: Skeleton.ignore( // the icon will not be skeletonized
          child: Icon(Icons.ac_unit, size: 40),
        ),
      ),
    )
    ```

    ![](https://img.cdn.guoshuyu.cn/ignored_skeleton_demo.gif)

  -  `Skeleton.leaf` : 容器标记为叶子控件，直接还用  shader paint 绘制

    ```dart
    Skeleton.leaf(
       child : Card(
        child: ListTile(
            title: Text('The title goes here'),
            subtitle: Text('Subtitle here'),
            trailing: Icon(Icons.ac_unit, size: 40),
          ),
      )
    )
    ```

    ![](https://img.cdn.guoshuyu.cn/leaf_skeleton_demo.gif)

  - `Skeleton.keep`: 在骨架化时，保持某个子 Widget 的原始样貌

    ```dart
    Card(
      child: ListTile(
        title: Text('The title goes here'),
        subtitle: Text('Subtitle here'),
        trailing: Skeleton.keep( // the icon will be painted as is
          child: Icon(Icons.ac_unit, size: 40),
        ),
      ),
    )
    ```

    ![](https://img.cdn.guoshuyu.cn/kept_skeleton_demo.gif)

  - `Skeleton.replace`: 在骨架化时，用一个替代的 Widget (比如一个简单的灰色方块) 来显示，比如遇到需要 `Image` 空间的场景

    ```dart
        Card(
          child: ListTile(
            title: Text('The title goes here'),
            subtitle: Text('Subtitle here'),
            trailing: Skeleton
                .replace( // the icon will be replaced when skeletonizer is enabled
                width: 50, // the width of the replacement
                height: 50, // the height of the replacement
                replacement: // defaults to a DecoratedBox
                child: Icon(Icons.ac_unit, size: 40),),
          ),
        );
    ```

    ![](https://img.cdn.guoshuyu.cn/replaced_skeleton_demo.gif)

  - `Skeleton.unite`: 将多个子 Widget 合并成一个大的骨架块

    ```dart
    Card(
      child: ListTile(
        title: Text('Item number 1 as title'),
        subtitle: Text('Subtitle here'),
        trailing: Skeleton.unite(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.ac_unit, size: 32),
              SizedBox(width: 8),
              Icon(Icons.access_alarm, size: 32),
            ],
          ),
        ),
      ),
    )
    ```

    ![](https://img.cdn.guoshuyu.cn/united_skeleton_demo.gif)

  |                           | 作用                 | 场景                                                     |
  | ------------------------- | -------------------- | -------------------------------------------------------- |
  | `Skeleton.ignore`         | 完全跳过骨架化       | 在加载时也需原样显示的 Logo 或品牌元素                   |
  | `Skeleton.leaf`           | 将容器标记为终端骨骼 | 将一个 `Card` 组件显示为一整个实心骨架块                 |
  | `Skeleton.keep`           | 保持自身，骨架化子孙 | 保持一个带特殊边框的容器，但骨架化其内部的文本和图标     |
  | `Skeleton.shade`          | 为自定义绘制应用效果 | 骨架化一个使用 `CustomPainter` 绘制的图表或图形          |
  | `Skeleton.replace`        | 在骨架化时替换组件   | 处理 `Image.network`，用一个占位方块替换加载中的网络图片 |
  | `Skeleton.unite`          | 将多个骨骼合并为一个 | 将一行紧邻的多个 `Icon` 合并成一个连续的长条形骨架       |
  | `Skeleton.ignorePointers` | 禁用指针事件         | 防止用户点击处于加载状态的按钮或列表项                   |

- **`bone.dart`**:  支持通过  `Skeletonizer.zone`  场景，手动自定义提供了一系列预设的“骨骼”Widget，用于手动搭建骨架屏布局，支持：

  - `Bone.text()` 
  - `Bone.multiText()` 
  - `Bone.circle()` 
  - `Bone.square()`
  - `Bone.icon()` 
  - `Bone.button()` 
  - `Bone.iconButton()` 

  ```dart
  Skeletonizer.zone(
      child: Card(
        child: ListTile(
          leading: Bone.circle(size: 48),  
          title: Bone.text(words: 2),
          subtitle: Bone.text(),
          trailing: Bone.icon(), 
        ),
      ),
   );
  ```

![](https://img.cdn.guoshuyu.cn/image-20250729110356210.png)

- **`effects/*.dart`**， 主要用于定义了骨架屏的视觉动画效果，其中 `painting_effect.dart` 定义了抽象基类 `PaintingEffect`：

  - `shimmer_effect.dart`: 实现了最常见的“微光”或“闪烁”效果，通过一个滑动的 `LinearGradient` (线性渐变) 来实现

  - `pulse_effect.dart`: 实现了“脉冲”效果，在两种颜色之间来回渐变

  - `sold_color_effect.dart`: 纯色效果，没有动画

![](https://img.cdn.guoshuyu.cn/loading_effects_demo.gif)

当然，在一些复杂嵌套场景，或者某些特殊控件，比如  `SwitchListTile` ，还有比如  `RoundedSuperellipseBorder` 这样的自定义边框形状 等，框架在便利和处理时会无法处理对应的状态或者复现形状，这也算是它的局限性。

但是瑕不掩瑜，除了需要处理的 fake 数据部分，整体使用还是相当便捷，**skeletonizer 的自动化能力可以极大地减少样板代码，并保证 UI 占位的一致性**，这也是它值的推荐的原因。

那么，你会在你的应用里使用骨架屏吗？

# 参考链接

- https://github.com/Milad-Akarie/skeletonizer