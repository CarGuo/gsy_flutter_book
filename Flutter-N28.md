# Flutter 小技巧之滑动控件即将“抛弃” shrinkWrap 属性

相信对于 Flutter 开发的大家来说， ListView 的 `shrinkWrap` 配置都不会陌生，如下图所示，每当遇到类似的 `unbounded error ` 的时候，总会有第一反应就是给 `ListView` 加上  `shrinkWrap: true`  就可以解决问题，那为什么现在会说  `shrinkWrap`  即将被“抛弃”呢？

![](http://img.cdn.guoshuyu.cn/20230718_N28/image1.png)

其实说完全“抛弃”也不大严谨，从目前官方的规划来看， `shrinkWrap` 配置将从滑动控件里弃用，因为团队觉得**现阶段的开发人员大多数时候不知道它的实际含义，只是单纯使用它解决问题，在使用过程中容易出现错误的性能损耗而不自知**。

![](http://img.cdn.guoshuyu.cn/20230718_N28/image2.png)

当然，这个提议并不是说完全废除  `shrinkWrap`  的支持，而且类似通过全新的 `Widget` 来替代，用更形象的命名，例如 `NonLazyListView` 等。

![](http://img.cdn.guoshuyu.cn/20230718_N28/image3.png)

> **目前这个提议的等级是 P1 ，所以如果不意外的话，它的推进会很快**。

那么  `shrinkWrap`  为什么会带来性能问题？它常用在什么场景？为什么会需要被提高到 P1 来进行调整？

首先我们需要简单理解 Flutter 滑动列表的实现和 `shrinkWrap` 的作用，在[《带你了解 Flutter 中的滑动列表实现》](https://juejin.cn/post/6956215495440007175)里我们介绍过，**Flutter 里的滑动列表是由 *`Viewport`* 、*`Scrollable`* 和相应的  *`Sliver`*   三部分组成**。

以 `ListView` 为例，如下图所示是 `ListView` 滑动过程的变化，其中：

- 绿色的 `Viewport` 就是我们看到的列表窗口大小；
- 紫色部分就是处理手势的 `Scrollable`，让黄色部分 `SliverList` 在 `Viewport` 里产生滑动；
- 黄色的部分就是 `SliverList` ， 当我们滑动时其实就是它在 `Viewport` 里的位置发生了变化；

![](http://img.cdn.guoshuyu.cn/20230718_N28/image4.png)

所以 `ListView` 之所以可以“无限”滑动，就是因为首先有一个固定大小「窗口」， 只有在进入和靠近「窗口」的 Item 才会被布局渲染，从而保证了列表的性能。

但是这也带来了一个问题，如下图 1 的代码所示，它就因为 ` Column`  的特性，没办法直接计算得到  `Viewport`  的大小，所以会抛出错误。

| ![](http://img.cdn.guoshuyu.cn/20230718_N28/image5.png) | ![](http://img.cdn.guoshuyu.cn/20230718_N28/image6.png) | ![](http://img.cdn.guoshuyu.cn/20230718_N28/image7.png) |
| ------------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------- |

有时候我们会如上图 2 所示，通过给 `ListView` 加一个 `Expanded`  来解决，这样  `ListView` 会充满  ` Column`  的剩余空间，从而得到一个固定的    `Viewport`  大小。

但是当我们希望此时 `ListView` 不充满，还可以居中显示的时候，就会采用如上图 3 所示那样，添加一个 `shrinkWrap: true` 。

> 虽然这个例子没有意义，但是它展示了  `shrinkWrap` 的“主要”场景，**另外    `shrinkWrap`  也常被用于   `ListView`  嵌套  `ListView`  这种不规范使用的场景中**。

那 `shrinkWrap`   的实现原理是什么？简单来说，现阶段 `shrinkWrap:true` 的时候，在滑动控件内部会采用一个特殊的 `ShrinkWrappingViewport` 「窗口」进行实现。 

![](http://img.cdn.guoshuyu.cn/20230718_N28/image8.png)

`ShrinkWrappingViewport`  和 `Viewport` 的不同之处在于 ：

- `Viewport`  是填充满主轴方向的大小
- `ShrinkWrappingViewport`   是调整自身大小去匹配主轴方向中 Item 的大小，而这种“收缩”的行为成本会变高，因为窗口大小需要通过 child 去“确定”。

例如，如下图所示，在 `ListView` 里，我们将 ` itemCount`  修改为 400 ，然后打印每个 Item 的 build ，由于 `shrinkWrap` 的作用，可以看到 400 个 child 都被输出。

![](http://img.cdn.guoshuyu.cn/20230718_N28/image9.png)

同样，在  Inspector 的 Widget Tree 里可以看到 400 个 child 都构建完成，尽管他们还远没有在 `ViewPort` 展示出来，所以  `shrinkWrap`  让  `ListView` 失去了懒加载的作用。

相反，如下图代码所示，如果去掉  `shrinkWrap` ，在 `Expand` 的作用下 ` ListView` 有了固定大小的  `ViewPort` ，此时就算是  ` itemCount`  是 400 ，但是也只会根据   `ViewPort`  构建所需的 19 个 child 。

![](http://img.cdn.guoshuyu.cn/20230718_N28/image10.png)

就算是因为滑动产生变化，正常情况下的 `ListView` 也保持着「固定」的长度，例如滑动到 160 的 index 的时候，此时开始的 `ListTitle`  的 index 是 135 ，而不会像   `shrinkWrap`  一样保持着全员 child 的构建。

![](http://img.cdn.guoshuyu.cn/20230718_N28/image11.png)

如何要深究的话，**其中关键点之一就在于 `updateOutOfBandData` 方法实现的不同**，在普通 `Viewport` 里， `updateOutOfBandData`  方法只是用于计算 `maxScrollExtent `  ，而如下图 1 所示，`ShrinkWrappingViewport` 里会对每个 child 的 `maxPaintExtent`  进行累计。

| ![](http://img.cdn.guoshuyu.cn/20230718_N28/image12.png) | ![](http://img.cdn.guoshuyu.cn/20230718_N28/image13.png) |
| -------------------------------------------------------- | -------------------------------------------------------- |

累计之后的得到的 `_shrinkWrapExtent` 最终会转化为 `ShrinkWrappingViewport`  自己的  `size` ，这也是 `ShrinkWrappingViewport` 为什么可以根据 child 调整「窗口」大小的原因。

所以，在此之前可能**开发者经常通过简单的  `shrinkWrap`  来解决问题，而比较少思考  `shrinkWrap`  的实现原理，或者说缺乏理解它的作用，从而带来了一些隐形的性能问题而不自知**，所以这也是为什么这次会有该调整的原因：

> 将  `shrinkWrap`   迁移到全新控件可以更直观让大家理解其作用，而其实大部分使用    `shrinkWrap`  的场景可以被其他实现替代。

- 例如前面提到的 `ListView` 嵌套 `ListView` 的场景，与其对通过配置   `shrinkWrap`   来实现，不如通过 `CustomScrollView` 结合不同 `SliverList` 或者其他 `Sliver` 组建完成组合。

- 而如果 child 并不多，其实也可以直接通过 `SingleChildScrollView` + `Column` 来实现，它在一定程度上效果和     `shrinkWrap`   类似。

所以，到这里你应该知道了  `shrinkWrap`   的实现逻辑和作用，其实本次主要也是想通过这个 new feature 变动，带大家重新认识下   `shrinkWrap`    ，**因为接下来，它就不再叫   `shrinkWrap`   了，或者你以后也应该很少用到它**。