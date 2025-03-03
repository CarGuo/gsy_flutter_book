# 深入 Flutter  和  Compose 在 UI 渲染刷新时 Diff  实现对比

众所周知，不管是什么框架，在前端 UI 渲染时，都会有构造出一套相关的渲染树，并且在 UI 更新时，为了尽可能提高性能，一般都只会进行「差异化」更新，而不是对整个 UI Tree 进行刷新，所以每个框架都会有自己的 Diff 实现逻辑，而本篇就是针对这部分实现进行一个简单对比。

# Flutter

首先聊聊 Flutter ，众所周知，Flutter 里有三棵树：Widget Tree 、Element Tree 和 RenderObject Tree ，**由于 Flutter 里 Widget 是不可变(类似 React 的 immutable) 的设定，所以 Widget 在变化时会被重构成新 Widget ，从而导致 Widget Tree 并不是真正 Flutter 里的渲染树**。



![](http://img.cdn.guoshuyu.cn/20250110_frc/image1.png)

所以 Widget Tree 在 Flutter 里更多只是「配置信息树」，实际工作的还是 Element Tree ，或者说，Element Tree 才是正式的 UI Tree 实体，只是它并不负责渲染，负责布局和渲染的是对应的 RenderObject Tree 。

当然，今天我们聊的是 「 Diff  实现」 ，所以我们的核心需要聚焦在 Element ，因为正是它负责了控件的「生命周期」和「创建/更新」逻辑，**Element 作为 “大脑” 沟通着整个 UI 渲染流程**。

![](http://img.cdn.guoshuyu.cn/20250110_frc/image2.png)

所以今天 Flutter 主要的话题应该是围绕在 Element ，我们知道 Widget 在加载之初就会创建出一个 Element ，然后根据传入的 key 和 runtimeType ，会决定 Widget 变化时 Element 是否可以复用，而**复用 Element   就是 Flutter 里 「Diff 机制」 的关键**：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image3.png)

我们先简单看一个时序图，大致就是 `setState() ` 所作用的一个流程，其中：

-  `setState()` 过程就是记录所有的脏 Element 的过程，它会执行 Element  内的 `_dirty = true`
-  然后 Element 会添加自己到 `BuildOwner` 对象的 `_dirtyElements` 成员变量
- 最后  `buildScope`  会对  `_dirtyElements` 进行 `Element._sort` 排序，然后触发 `rebuild` ：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image4.png)

**所以整个更新流程，会跳过干净的 Element，只处理脏 Element**，同时在构建阶段，信息在 Element 树中单向流淌，每个 Element 最多被访问一次，而一旦被“清理”，Element 就不会再次变脏，因为可以通过归纳，它的所有祖先元素也是干净的。

然后就是 Flutter 里经典的 Linear reconciliation ，**在 Flutter 里没有采用树形差异算法，而是通过使用 O(N) 算法独立检查每个 Element 的子列表来决定是否复用 Element**。

>  当框架能够复用一个 Element 时，用户界面的逻辑状态将被保留，并且之前计算的布局信息也可以被重用，从而避免整个子树遍历。

是否复用 Elmenet 主要是在 Element 的 `updateChildren` 里去判断，而在整个 `updateChildren`  的实现里，首先我们需要理解下面这段代码：

```dart
  if (oldChild == null || !Widget.canUpdate(oldChild.widget, newWidget)) {
      break;
  }

  static bool canUpdate(Widget oldWidget, Widget newWidget) {
    return oldWidget.runtimeType == newWidget.runtimeType
        && oldWidget.key == newWidget.key;
  }

```

这里的判断逻辑很好理解：

- 没有 oldChild 存在，那还更新什么，肯定不用更新了，直接走创建
- `canUpdate`  主要是判断  runtimeType 或者 key 是否一致，如果不一致那就不是同一个 Widget 了，那也没办法复用

![](http://img.cdn.guoshuyu.cn/20250110_frc/image5.png)

剩下的基本就是基于这判断条件的细分查找实现，在  `updateChildren`  函数里主要是处理两个列表的更新，即 `List<Element> oldChildren`  和 `List<Widget> newWidgets` ，当然，本质上其实是处理这两个 Element 列表的 Diff ，整体流程上：

- 从顶部和尾部进行快速扫描和同步：

  - 先从头部往下，直到「没有 `oldChild`  或者 `canUpdate`  条件不满足」的地方就停止，在这个过程里符合更新的通过 `updateChild` 得到一个能更新的 newChild Element 列表

  - 从底部往上，快速扫描到没有「 `oldChild`  或者 `canUpdate` 条件不满足」的地方，停止扫描，底部扫描这里不处理更新，只是为了快速确定到中间区域

- 处理中间区域

  - 在中间区域还存在的 oldChild 放到一个 `<Key, Element>{}` 的 oldKeyedChildren 对象里，用于后续快速匹配，因为只要 Key 相同，即使后面位置发生变化，也可以继续复用对应的 `Element`

  - 扫描中间区域，根据前面得到的  oldKeyedChildren 提取出来 oldChild， 如果 oldChild 不存在就直接创建新 Element ，如果存在且符合 `canUpdate` ，则更新 Element 

- 直接更新剩下未处理的底部区域，因为剩下的这部份肯定是能更新的

- 清理掉前面的 oldKeyedChildren 残留
- 返回全新 Element 列表

如果你觉得这样说比较抽象，那么我们看一个简单的例子，首先我们有 new 和 old 两个列表，按照上面流程，一开始从上往下更新，当 new 的 top 指针遍历到 a 时，因为不符合条件会停下来，然后我们得到了一个  newChildren 列表，里面是前面已经遍历更新的  1 和 2 ：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image6.png)

然后就是第二步，从下往上扫描，这里不做任何更新，之后遇到 c 位置后，不符合条件无法更新，停下来，此时 bottom 指针停在了 c：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image7.png)

接着开始处理中间部份，old 的 top 指针逐步遍历到 bottom 位置，先从 old 列表得到一个  `<Key, Element>{}`   的 oldKeyedChildren 对象用于后续快速匹配，过程中如果 key == null，则可以提前释放掉对应 old Element ：

![image-20250106233732147](http://img.cdn.guoshuyu.cn/20250110_frc/image8.png)



根据前面中间区域得到的  oldKeyedChildren 提取出来的 oldChild，在 new 的 top 指针继续往下遍历时， 如果 oldChild 不存在就直接创建新 Element ，如果存在且符合 `canUpdate` ，则更新 Element ：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image9.png)

最后更新之前没处理的底部的 Element ，然后清空 oldKeyedChildren 并释放 old Element ：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image10.png)

**这里为什么底部最后一开始遍历时不更新？因为此时需要的 slot 信息不存在**。

所谓 slot，主要是维护子元素在父元素中的逻辑位置，用于确保子元素的渲染顺序与逻辑顺序一致，并且在子元素顺序发生变化时，通过重新分配槽位触发 `RenderObject` 的位置更新。

```dart
Object? slotFor(int newChildIndex, Element? previousChild) {
  return slots != null
      ? slots[newChildIndex]
      : IndexedSlot<Element?>(newChildIndex, previousChild);
}
```

它主要出现在于每次 `updateChild(oldChild, newWidget, slotFor(newChildrenTop, previousChild))` 时的更新：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image11.png)

而前面开始扫描底部的时候，没有直接先 updateChild 的原因也是在于：那个时候是从底部开始扫描，而 slot 需要的是一个「previousChild」，也就是前一个节点的引用，**它需要自上而下的顺序迭代**，所以 一开始 bottom 扫描的时候，并没有前置节点 slot ，所以当时只能是扫描，没更新动作。

自此整个更新流程就 update 完成，另外如果是  `InheritedWidget`  的更新，框架会通过在每个 Element 上维护一个 `_inheritedElements` 哈希表来向下传递共享 Element 信息，从而避免避免父链的遍历。

可以看到，Flutter 主要是基于 Key 和 runtimeType 的线性对账处理。

# Compose

来到 Compose ，因为 Compose 的渲染更新逻辑更复杂，因为它涉及了很多模块系统，这里我们用最简洁的理解快速过一遍，详细参考后面放的链接。

我们知道 `@Composable`  注释是 Compose 的基本构建模块：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image12.png)

当然，在编译 Composable 函数时，Compose 编译器会更改所有 Composable 函数，它会在编译的 IR 阶段为函数参数添加  `Composer`，就像前面我们聊 [Kotlin suspend 生成 Continuation](https://juejin.cn/post/7456407906634825755#heading-1)  一样：

```kotlin
///我们的代码
@Composable
fun MyComposable(name: String) {
}
///编译后添加了 composer 
@Composable
fun MyComposable(name: String, $composer: Composer<*>, $changed: Int) {

```

> 所以也和  suspend  一样，普通函数也不能调用 Composable 函数，而 Composable 函数可以调用普通函数。

而这里就出现了两个参数：

- `Composer` ：创建 Node、通过操作 SlotTable 的来创建和更新 Composition
- `changed`： 根据 int 里的状态判断是否可以跳过更新，比如静态节点，还有是否状态变化情况

我们知道 @Composable 函数并不是和 Flutter 一样 return ，所以实际工作中，Compose 代码在编译时会给  @Composable 函数添加参数 ，而实际的 UI Node Tree 等的创建，都是从 Composer 开始：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image13.png)

简单解释下：

- changed 部份提前判断是否支持跳过，它的判断基本都是各种位的 `and` 操作，重点是它会影响后面 `$dirty`  判断是否参与重组
- State 会变成各种副作用
- Composer.startxxxxGroup ~ Composer.endxxxxGroup 会创建出 Node 和 SlotTable
- updateScope  部份记录生成 snapshot 用于 diff 对比

而在 Compose 里也有两颗树：

- 一颗 Virtual 树  `SlotTable`  用于记录 Composition 状态
- 一颗 UI 的树 `LayoutNode `  负责测量和绘制等逻辑

![](http://img.cdn.guoshuyu.cn/20250110_frc/image14.png)

其实从 .startxxxxGroup  到 endxxxxGroup 整个部分构造的两个树里，`SlotTable`  就是 Diff 渲染更新的重点。

> Composable 里所产生的所有信息都会存入 SlotTable， 如 State、 key  和 value 等 ，而 SlotTable 支持跨帧「重组」，「重组」的新数据也会重新更新 SlotTable。

事实上 SlotTable 的表现形式是用线性数组来表达一棵树的语义，因为它并不是一棵树的结构：

```kotlin
internal class SlotTable : CompositionData, Iterable<CompositionGroup> {

    /**
     * An array to store group information that is stored as groups of [Group_Fields_Size]
     * elements of the array. The [groups] array can be thought of as an array of an inline
     * struct.
     */
    var groups = IntArray(0)
        private set
 
    /**
     * An array that stores the slots for a group. The slot elements for a group start at the
     * offset returned by [dataAnchor] of [groups] and continue to the next group's slots or to
     * [slotsSize] for the last group. When in a writer the [dataAnchor] is an anchor instead of
     * an index as [slots] might contain a gap.
     */
    var slots = Array<Any?>(0) { null }
        private set
```

在 SlotTable 有两个数组成员，`groups`  数组存储 Group 信息，`slots` 存储数据，而 Group 信息根据 Parent anchor 模拟出一个树，而 Data anchor 则承载了数据部分，同时因为 groups 和 slots 不是链表，所以当容量不足时，它们可以进行扩容：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image15.png)

而这里的 key 其实非常重要，在插入 startXXXGroup 代码时，Compose 就会基于代码位置生成可识别的 `$key`，并在首次「组合」时 `$key` 会随着 Group 存入 SlotTable，而在「重组」里，Composer 可以基于 `$key` 的识别出 Group 的增、删或者位置移动等信息。

另外重组的最小单位也是 Group，比如在 SlotTtable 上，各种 Compose 函数或 lambda 会被打包位 RestartGroup 。

> Group 类型有很多。

而 Snapshot 则是观察状态变化的实现，因为  `state` 的变化会带来「重组」，比如当我们使用 `mutableStateOf` 创建一个 `MutableState` 时，会创建一个「快照」，它会在 Compose 执行时注册相关 Observer ：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image16.png)

有了快照，我们就有了所有状态的信息，也就是可以 diff 两个状态去对比更新，从而得到新的 SlotTable：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image17.png)

所以在「重组」时，就可以根据 changed 状态和 SlotTable 数据（key、data等）去判断，从而得到一个 change list ：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image18.png)

最后 applyChanges 会对 changes 遍历和执行， 生成新的 SlotTable，SlotTable 结构的变化最后会通过 Applier  更新到对应的 LayoutNode：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image19.png)

这里需要注意的是：

- 如果 Compose 的重组被中断，那么其实 Composable 中执行的操作并不会真正反映到 SlotTable，因为  applyChanges 需要发生在 composiiton 成功结束之后
- startXXXGroup 中会操作 SlotTable 中的 Group 进行 Diff，这个过程产生的「插入/删除/移动」等过程都是基于 Gap Buffer 实现，可以简单理解为 Group 中的未使用的区域，这段区域支持在 Group 里移动，从而提升 SlotTble 变化时的更新效率：![](http://img.cdn.guoshuyu.cn/20250110_frc/image20.png)

>  Gap Buffer 也就是减少每次操作 Node 时导致 SlotTable 中已有 Node 的移动。

如果单从 Diff 部分考虑，其实就是 startXXXGroup 会对 SlotTable 进行遍历和 Diff ，根据 Group 的位置，key，data 等信息进判断，而其更新来源在于状态变化时的 Snapshot 系统，最后得到的差异化 SlotTable 会更新到真实的 LayoutNode：

![image-20250110135241771](http://img.cdn.guoshuyu.cn/20250110_frc/image21.png)

可以看到整个流程上 Compose  的「重组」diff 涉及很多模块和细节，即比如 `$changed` 标识位都可以单独聊一整篇，而在 Compose 里，这里的一切开发者其实在外部都感受不到，而它的实现核心，**就是来自编译后的 Composer 内部构建的基于 gap 数组的 slotTable**，整体上感觉和 React 的 Virtual DOM 相似：

![](http://img.cdn.guoshuyu.cn/20250110_frc/image22.png)

> 如果你对详细的 Compose 渲染和更新实现好奇，建议再看看参考链接里的详细内容。

最后简单总结一下：

- Flutter 采用一套自定义线性对账算法替代树形对比，通过最小化查找把 Widget 配置信息更新到 Element 里

- Jetpack Compose 使用  gap buffer 数据结构更新所需的 SlotTable，并且 SlotTable 会是在重组完成后才被 applyChange，最终差异部分才会通过 Applier  更新到对应的 LayoutNode



# 参考链接

- https://docs.flutter.dev/resources/inside-flutter
- https://juejin.cn/post/7113736450968911908
- https://github.com/takahirom/inside-jetpack-compose-diagram/blob/main/diagram.png













