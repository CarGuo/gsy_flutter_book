
本篇主要帮助剖析理解 Flutter 里的列表和滑动的组成，用比较通俗易懂的方式，从常见的 `ListView` 到 `NestedScrollView` 的内部实现，帮助你更好理解和运用 Flutter 里的滑动列表。

> **本篇不是教你如何使用 API ，而是一些日常开发中不常接触，但是很重要的内容**。



## Flutter 滑动列表


在 Flutter 里我们常见的滑动列表场景，简单地说其实是由三部分组成：

- *`Viewport`* ： 它是一个 *MultiChildRenderObjectWidget* 的控件 ，**它提供的是一个“视窗”的作用，也就是列表所在的可视区域大小；**
- *`Scrollable`* ：**它主要通过对手势的处理来实现滑动效果** ，比如*VerticalDragGestureRecognizer* 和 *HorizontalDragGestureRecognizer；*
- *`Sliver`* ： 准确来说应该是 *RenderSliver*， **它主要是用于在 Viewport 里面布局和渲染内容；**

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-N-Scroll/image1)

以 `ListView` 为例，如上图所示是 `ListView` 滑动过程的变化，其中：

- 绿色的 `Viewport` 就是我们看到的列表窗口大小；
- 紫色部分就是处理手势的 `Scrollable`，让黄色部分 `SliverList` 在 `Viewport` 里产生滑动；
- 黄色的部分就是 `SliverList` ， 当我们滑动时其实就是它在 `Viewport` 里的位置发生了变化；


了解完这个基础理念后，就可以知道一般情况下 `Viewport`  和  `Scrollable` 的实现都是很通用的，所以一般在 **Flutter 里要实现不同的滑动列表，就是通过自定义和组合不同的 `Sliver` 来完成布局**。

> **准确说是完成 `RenderSliver` 的 `performLayout` 过程，通过 `SliverConstraints` 来得到对应的 `SliverGeometry`**。


所以在 Flutter 里：

- `ListView` 使用的是 `SliverFixedExtentList` 或者  `SliverList`；
- `GridView` 使用的是 `SliverGrid`；
- `PageView` 使用的是 `SliverFillViewport`；

> 当然这里有一个特殊的是 `SingleChildScrollView` ， 因为它是单个 `child` 的可滑动控件，它并没有使用 `RenderSliver`，而是直接自定义了一个 `RenderObject`（RenderBox） ，并且**在 `performLayout` 时直接调整 `child` 的 `offset` 来达到滑动效果**。



## RenderSliver

我们都知道 Flutter 中的整体渲染流程是 *Widget* -> *Element* -> *RenderObejct* -> *Layer* 这样的过程，而 **Flutter 里的布局和绘制逻辑都在 `RenderObejct`**。

而事实上 `RenderObejct` 也可以分为两大基础子类：

- `RenderBox` ： 我们**常用的布局控件都是基于 RenderBox** 来实现布局；
- `RenderSliver` ：**主要用在 Viewport 里实现布局**， *Viewport* 里的直属 *children* 也需要是 *RenderSliver*；


那到这里你可能会有一个疑问：既然前面 `SingleChildScrollView` 里没有使用 `RenderSliver` ，直接使用 `RenderBox` 也可以实现滑动，**为什么还要用 Viewport +  RenderSliver 的方式来实现列表滑动？** 

### RenderBox

在 `SingleChildScrollView` 内部使用的是 `RenderBox` ，那么在布局过程中自然而然会把整个 `child` 都进行布局和计算，绘制时主要也是通过 `offset` 和 `clip` 等来完成移动效果，这样的实现当 **`child` 比较复杂或者过长时，性能就会变差**。

### RenderSliver

`RenderSliver` 的实现相对 `RenderBox`  就复杂更多，前面介绍过 **`RenderSliver` 就是通过 `SliverConstraints` 来得到一个 `SliverGeometry`**，其中：

 - `SliverConstraints` 中有 *remainingPaintExtent* 可以用来表示剩余的可绘制具体的大小；

 - `SliverGeometry` 里也有 `scrollExtent` （可滑动的距离）、`paintExtent`（可绘制大小）、`layoutExtent` （布局大小范围）、`visible`(是否需要绘制)等参数；


所以通过这部分参数，**在 `Viewport` 里可以实现动态管理，节省资源，根据 `SliverGeometry` 判断需要绘制多大区域的内容，还剩多少内容可以绘制，需要加载的布局是哪些等等。**

**简单地说就是可以实现“懒加载”，按需绘制，从而得到更流畅的滑动体验。**



![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-N-Scroll/image2)


以 `ListView` 为例，如上图所示是一个高为 701 的 `ListView` ，实际布局渲染之后，对于 `SliverList` 输出的 `SliverGeometry`  而言：

- 设定里每个 item 的高度为 114；
- `scrollExtent` 是 2353，也就是整体可滑动距离等于 2353；
- `paintExtent` 是 701 ， 因为 `ListView` 的 `Viewport` 是 701 ，所以从 `SliverConstraints` 得到的 `remainingPaintExtent` 是 701，**所以默认只需要绘制和布局高度为 701 的部分；** （因为默认 paintExtent = layoutExtent ）
- 对 item 多出的蓝色 8-9 部分，这是因为在  `SliverConstraints` 内会有一个叫 `remainingCacheExtent` 的参数，它表示了需要提前缓存的布局区域， 也就是“预布局”的区域，这个区域默认大小是 **defaultCacheExtent= 250.0；**

> `ListView` 高度为 701，`defaultCacheExtent` 为默认的 250，也就是得到**第一次需要布局到底部的距离其实为 951**，按照每个 item 高度是 114 ，那么其实是有 8.3 个 item 高度，取整数也就是 9 个 item ，最终得到整体需要处理的区域大小为 114 * 9 = 1026 ，在 **`SliverList` 内部就是 `endScrollOffset`  参数**。

所以根据以上情况，**`ListView` 会输出一个 `paintExtent` 为 701 ，`cacheExtent` 为 1026 的  `SliverGeometry`**。


从这个例子可以看出，**`RenderSliver` 在实现可滑动列表的开销和逻辑上，会比直接使用 `RenderBox` 好和灵活很多**，同时也是为什么 `Viewport` 里需要使用 `RenderSliver` 而不是 `RenderBox` 的原因。


> ⚠️注意，这里比较容易有一个误区，那就是 `ListView` 是由 `Viewport` + `Scrollable` 和一个`RenderSliver` 组成，所以在 **`ListView` 里只会有一个 `RenderSliver` 而不是多个**，想使用多个  `RenderSliver` 需要使用 `CustomScrollView` 。


最后顺便聊下 `CustomScrollView` ，事实上就是一个**开放了可自定义配置 `RenderSliver` 数组的滑动控件**，例如：

- 通过利用 `SliverList` + `SliverGrid` 就可以搭配出多样化的滑动列表；
- 通过 `CupertinoSliverRefreshControl` +  `SliverList` 实现类似 iOS 原生的下拉刷新列表；

其他可用的内置 `Sliver` 还有：`SliverPadding` 、`SliverFillRemaining` 、`SliverFillViewport` 、`SliverPersistentHeader` 、`SliverAppbar` 等等。


## NestedScrollView


为什么会把 `NestedScrollView` 单独拿出来说呢？这是因为 `NestedScrollView` 和前面介绍的滑动列表实现不大一样。

### 内部组成

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-N-Scroll/image3)


如上图所示，`NestedScrollView` 内部主要是通过继承 `CustomScrollView` ，然后自定义一个 `NestedScrollViewViewport` 来实现联动的效果。

那这有什么特别的呢？如下代码所示，这是使用 `NestedScrollView` 常用的模式，那有看出什么特别的地方了吗？

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-N-Scroll/image4)

代码里 `NestedScrollView` 的 `body` 嵌套的是 `ListView` ， 前面我们介绍了 `ListView` 本身就是 `Viewport` + `Scrollable` + `SliverList` 组合，而 `NestedScrollView` 本身也有 `NestedScrollViewViewport`。

**所以 `NestedScrollView` 的实现本质上其实就是 `Viewport` 嵌套 `Viewport`，会有两个 `Scrollable` 的存在** ，并且嵌套的  `ListView` 是被放在了 `NestedScrollView` 的 `Sliver` 里面，大致如下图所示。

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-N-Scroll/image5)



这里面有几个关键的对象，其中：

- `SliverFillRemaining` ：用于充满 `Viewport` 的剩余空间，在  `NestedScrollView` 里面就是充满 `header` 之外的剩余空间；

- `NestedScrollViewViewport` ： 在原 `Viewport` 的基础上增加了一个 `SliverOverlapAbsorberHandle` 参数，`SliverOverlapAbsorberHandle`  本身是一个 `ChangeNotifier` ， 主要是用来当 `markNeedsLayout` 时对外发出通知，比如对 header 部分；

所以 `NestedScrollView` 本质上两个 `Viewport` 之间的嵌套，那他们之间是滑动关系是如何处理的？**这就要说到 `NestedScrollView` 里的 `_NestedScrollCoordinator` 对象。**

### _NestedScrollCoordinator


`_NestedScrollCoordinator` 的实现比较复杂，简单地说 `_NestedScrollCoordinator` 内部创建了两个 `_NestedScrollController`：

- `_outerController` ：属于 `_NestedScrollViewCustomScrollView` 的 *controller* ，也就是它自己 *controller*；
- `_innerController` ：属于 `body` 的 *controller*；


![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-N-Scroll/image6)

> 在 `ListView` 的父类 `ScrollView` 内部，默认情况下使用的就是 `PrimaryScrollController.of(context)` 这个 *controller* ，因为 `PrimaryScrollController` 是一个 `InheritedWidget` 。

而整个联动滑动的流程，主要就是 `_NestedScrollCoordinator` 里和它创建的两个 `_NestedScrollController` 有关系：

- `_NestedScrollController` 的主要作用就是使用 `_NestedScrollPosition` 来替换 `ScrollPosition` ；

- `_NestedScrollCoordinator` 将 _outer 和 _inner 两个 `_NestedScrollController` 组合起来(_outer 和 _inner 分别被应用到 `NestedScrollView` 和 `body`);

-  `_NestedScrollPosition` 内部将 `Drag` 等手势操作传递回 `_NestedScrollCoordinator` 里。

- 最后在 `_NestedScrollCoordinator` 的 `drag` 和 `applyUserOffset` 等方法里进行内外滚动的分配；

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-N-Scroll/image7)


### SliverPersistentHeader

了解完 `NestedScrollView` 的布局和联动实现之外，最后简单介绍一下  `SliverPersistentHeader` ， 因为经常在  `NestedScrollView` 里使用的  `SliverAppBar`，本质上 **`SliverAppBar` 的实现靠的就是 `SliverPersistentHeader`**。


`SliverPersistentHeader` 主要是具备 `floating` 和  `pinned` 两个属性，它们的区别主要在于使用了不同的 `RenderSliver` 实现，而**最终不同的地方其实就是输出 `SliverGeometry` 的不同**。

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-N-Scroll/image8)

以第一个 `_SliverFloatingPinnedPersistentHeader` 和最后一个 `_SliverScrollingPersistentHeader` 之间的对比为例子，如下代码所示，在需要 `floating` 和  `pinned` 的 `Sliver` 上，可以看到 `paintExtent` 和 `layoutExtent` 都有一个最小值。

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-N-Scroll/image9)

**所以 `Sliver`  被固定住的原理，其实就是 `Viewport` 得到了它的 `paintExtent` 和 `layoutExtent` 并不为 0，所以会继续为这个 `Sliver` 绘制对应区域的内容。**


最后需要注意的是，**当你使用 `SliverPersistentHeader` 去固定住头部的时候，作为 `body` 的列表是不知道顶部有个固定区域。** 所以如果这时候不额外做一些处理，那么对于 `body` 而言，它的 `paintOrigin` 还是从最顶部开始而不是固定区域的下方。


![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-N-Scroll/image10)

> 如上动图所示，可以看到 item0 并没有在橙色区域停止滑动，而是继续往上滑动，这就是因为作为 `body` 的列表不知道顶部有固定区域。

这时候就可以通过使用 `SliverOverlapAbsorber` + `SliverOverlapInjector` 的组合来解决这个问题：

- 在 `SliverPersistentHeader` 的外层嵌套一个 `SliverOverlapAbsorber` 用于吸收 `SliverPersistentHeader` 的高度；

- 使用 `SliverOverlapInjector` 将这个高度配置到 `body` 列表中，让列表知道顶部存在一个固定高度的区域；


![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-N-Scroll/image11)


这部分例子可见：https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/sliver_list_demo_page.dart


好了，本篇关于 Flutter 滑动列表的实现原理就介绍完了，如果你还有什么想说的，欢迎留言讨论。

