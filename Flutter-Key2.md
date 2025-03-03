# Flutter 的 Widget Key 提议大调整？深入聊一聊 Key 的作用

在 Flutter 里，**Key 对象存在的目的主要是区分和维持 Widget 的状态，它是控件在渲染树里的「复用」标识之一**，这一点在之前的[《深入 Flutter 和 Compose 在 UI 渲染刷新时 Diff 实现对比》](https://juejin.cn/post/7458927663538487350) 聊到过，可以说 Key 的存在关乎了 Flutter 的性能，因为它的作用就是提高 Element Tree 的复用效率，例如减少匹配阶段所需的 Widget 比较次数。

![](http://img.cdn.guoshuyu.cn/20250127_Key/image1.png)

另外通过 Key 还可以提高如 `AnimatedList`、`ListView` 里重新排序时对应 Item  widget 的效率，通过将 Key 分配给 Item ，Flutter 可以更有效地识别何时添加、删除或更新列表并执行动画，在这个时候， Key 可以确保每个 Item 即使在对列表进行排序时也保持其状态。

**大多数情况下，无状态的 Widget 是不需要 Key**，而默认情况下，我们在不主动配置 Key 的时候，它会是 null ：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image2.png)

![](http://img.cdn.guoshuyu.cn/20250127_Key/image3.png)

**也就是在没有 Key 的情况下，framewok 一般只判断 runtimeType 去决定是否「复用」**，举个很老的官方例子，如下图片代码里的 `StatelessColorfulTile` 所示，它是一个无状态的  StatelessWidget ，显示了一个随机颜色的 200x200 大小的正方形，通过点击右下角按键，每次调整两个方块的位置，可以看到方块可以正常切换：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image4.gif)

因为此时没有 Key ，**在 Element Tree 只需要判断 runtimeType ，明显此时 Element 符合复用条件**，而代码里又是直接使用 `StatelessColorfulTile`  的 Widget 实例对象进行 `tiles.insert(1, tiles.removeAt(0))` ，所以在 Widget 切换位置之后，Element 和 RenderObject 只需要 update 一下新位置 Widget 实例的颜色即可：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image5.png)

但是，如果我们修改为 StatefulWidget ，此时我们再点击右下角按键，可以看到此时颜色方块不会切换了：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image6.gif)

因为此时颜色 color 被保存在 State 下，在 Widget 切换位置之后，因为 runtimeType 符合条件，所以 Element 复用，但是颜色被保存在 State 下，State 又是保存在 Element 里，从而导致颜色并没有按照需求被更新切换：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image7.png)

但是，如果这时候我们给两个 StatefulWidget 添加上 Key ，就可以看到它们可以被切换了，因为 `canUpdate` 判断条件会增加 Key 判断：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image8.gif)

![](http://img.cdn.guoshuyu.cn/20250127_Key/image9.png)

也就是，在有了 Key 之后，新 Widget 的 key 就可以在老 Element 列表里进行匹配，从而更新 Element 的位置并刷新 RenderObject，两个 Element 在状态保留的情况下，被 Tree 里调换了位置进行更新，从而实现了切换的效果：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image10.png)

所以，从这个简单的例子，可以直观看到 Key 在有状态的情况下能够发挥的作用，当然，**目前在 Flutter 里的 Key 类型很丰富，但是大致可以简单分为两类： Local Keys 和 Global Keys** 。

![](http://img.cdn.guoshuyu.cn/20250127_Key/image11.png)

顾名思义就是它的作用范围，举个例子，如果我们给  `StatelessColorfulTile`  增加了一个 Padding ，再点击切换按键，可以看到此时点击后  Element 一直被重构：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image12.gif)

因为此时在 `Row` 里面，此时处于“一级”位置 children 是两个 Padding，而 Padding 没有 Key，所以它在 runtimeType 条件的情况下，是直接被复用：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image13.png)

而对于 `StatelessColorfulTile`   而言，它处于 Padding 之下，Padding 不是一个 Multi Child 的控件，所以在 canUpdate 为 false 的时候，Flutter 内部会认为它需要被重新创建：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image14.png)

从这里我们就可以很直观体验到 Local Keys 这个概念：**它只作用于标识同一父 Widget 中的 Widget，不能用于识别其父 Widget 之外的 Widget**。

同时，我们也可以是直观感受到：**Multi Child  和  Single Child 的 Element 对于 Diff 更新时的策略差别**。

另外，**我们还可以感受到 Widget 作为「配置文件」的存在**，要知道，代码里我们操作的一直都是 `tiles.insert(1, tiles.removeAt(0));` ，也就是 Widget 的实例化都的对象，**虽然 Widget 实例没变，但是 Element 层面还是会根据情况「重新创建」对应的 Element** ，由于颜色是在 State 里，所以也就会跟着 Element 重新随机变化。

最后如下图所示，对于 Local Keys 来说，左侧这样的写法是可以的，而右侧这样的写法是违规的：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image15.png)

所以，在 Widget 的 Key 注释里也有这样一句描述：**通常情况下，作为另一个 widget 的唯一子项的 widget 不需要显式 Key**。

![](http://img.cdn.guoshuyu.cn/20250127_Key/image16.png)

# GlobalKey

那么，除开 Local Keys ，Flutter 里还有一个特殊的 GlobalKey，允许开发者在 Widget 树里去「唯一」标识 Widget，并提供 BuildContext(Element)/State 的全局访问：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image17.png)

> 这里的「唯一」更多体现在当前这一帧里的「唯一」。

比如前面的例子，我们只需要把对应的 Local Keys 换成 GlobalKey ，就可以看到，虽然 Key 所在的   `StatelessColorfulTile`   还是在 Padding 下的“二级” child ，但是现在点击切换时，它不会被「重新创建」导致颜色发生变化：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image18.gif)

这是因为，**虽然在 `updateChild ` 的时候，逻辑依然会走到 `inflateWidget` 去创建 Element ，但是由于是 GlobalKey，所以会从全局保存的 Map 里获取到当前 GlobalKey 绑定的 Element** ，从而 retake 复用：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image19.png)

> 从这里可以看出来， **如果 Element  在同一帧中移动或者删除，并且它具有  GlobalKey，那么它仍然可能被重新激活使用**。

所以  GlobalKey 不仅可以作为 Key 区分 Widget ，帧内还可以在  BuildOwner  里“全局”保持住 Element 、State 和关联 RenderObject  的“状态”，即使它出现移动或者删除。

同时，通过 GlobalKey ，我们也可以访问对应的 BuildContext 和 State 数据，甚至是直接给  `MaterialApp` 添加 GlobalKey 来操作导航：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image20.png)![](http://img.cdn.guoshuyu.cn/20250127_Key/image21.png)

那么 GlobalKey 这么好用，它又存在什么问题呢？其实在注释里已经有对应说明：

> GlobalKey 在使用的过程中可能会出现需要重新设置 [Element] 父级的情况，而这个操作会触发对关联的 [State] 及其所有后代 [State.deactivate] 的调用，还会强制重建所有依赖于 [InheritedWidget] 的控件。

![](http://img.cdn.guoshuyu.cn/20250127_Key/image22.png)

具体就体现在这下面两段代码：

- `_retakeInactiveElement` 内可能会触发所有关联 State 的 `deactivate`
- `_activateWithParent` 会触发 Element 的 `activate` ，从而通过 `didChangeDependencies` 强制重建所有依赖于 [InheritedWidget] 的控件

![](http://img.cdn.guoshuyu.cn/20250127_Key/image23.png)

当然，GlobalKey 也有一些注意事项，例如：

> 使用 GlobalKey  不能频繁创建，通常应该是让它和 State 对象拥有类似的“生命长度”，因为新的 GlobalKey 会丢弃与旧 Key 关联的子树的状态，并为新键创建一个新的子树，频繁创建会导致状态丢失和性能损耗。

# 变更提议

前面我们主要介绍了 Key 的作用和分类下的职能，**而本次 PR 提议的调整，则是在于打算简化 Local Keys 相关的实现上**，可以看到在以往的实现里，关于 LocalKey 的实现有好几种类型，但是其中一些职能其实「相对重复」：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image24.png)

在 [#159225](https://github.com/flutter/flutter/pull/159225) 的 PR 里，将打算把 Key 对象切换到 Object ，从而“消灭”过往这些 Local Keys 的“重叠”，让 Key  API 更加灵活：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image25.png)

另外，除了灵活和简化之外，针对目前存在的 Local Keys ，它和 Dart 的 Extension Types 不同，比如使用  ValueKey() 多多少少会有一点点点点点点 wrapper 成本，而如果这个提议合并后，大概会是如下所示的情况，或多或少对性能还是有那么一点点点点点点帮助：

![](http://img.cdn.guoshuyu.cn/20250127_Key/image26.png)

> 事实上对于 LocalKey ，大多数人应该都只会使用到 `ValueKey` 居多。

当然，**这个 PR 整体来说还是属于底层大调整，而目前看起来提议应该是暂时搁置了**，不过就算推进落地，相信对于大多数上层 Flutter 开发者来说，应该也不会有明显的感知，毕竟大多数时候 Flutter 开发者对 Key 并不敏感：

![](http://img.cdn.guoshuyu.cn/20250201_333333333/image1.png)

所以，你是喜欢现在的 Local Keys 分类还是提议里的 Object ？



## 参考链接：

- https://github.com/flutter/flutter/pull/159225
- https://api.flutter.dev/flutter/foundation/Key-class.html









