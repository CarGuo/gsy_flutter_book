作为系列文章的第七篇，本篇主要在前文的基础上，再深入了解 Widget 和布局中的一些常识性问题。

## 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)


在第六篇中我们知道了 `Widget`、`Element`、`RenderObject` 三者之间的关系，其中我们最为熟知的 `Widget` ，作为“配置文件”的存在，在 Flutter 中它的功能都是比较单一的，属于 *“颗粒度比较细的存在”*  ，写代码时就像拼乐高“积木”，那这“积木”究竟怎么拼的？下面就 **深入** 去挖挖有意思的东西吧。(￣▽￣)

## 一、单子元素布局


在 Flutter 单个子元素的布局 Widget 中，**`Container`** 无疑是被用的最广泛的，因为它在“功能”上并不会如 `Padding` 等 Widget 那样功能单一，这是为什么呢？

究其原因，从下图源码可以看出，**`Container`** 其实也只是把其他“单一”的 Widget 做了二次封装，然后通过配置来达到“多功能的效果”而已。

![Container源码](http://img.cdn.guoshuyu.cn/20190604_Flutter-7/image1)

接着我们先看 `ConstrainedBox` 源码，从下图源码可以看出，它是继承了 `SingleChildRenderObjectWidget`，关键是 override 了 `createRenderObject` 方法，返回了 **`RenderConstrainedBox`** 。

>  这里体现了第六篇中的 Widget 与 RenderObject 的关系

是的，**`RenderConstrainedBox`**  就是继承自 `RenderBox`，从而实现`RenderObject` 的布局，这里我们得到了它们的关系如下 ：

| Widget        | RenderObject                                    |
| --------- |  --------- |
| ConstrainedBox | RenderConstrainedBox |

![ConstrainedBox](http://img.cdn.guoshuyu.cn/20190604_Flutter-7/image2)


然后我们继续对其他每个 Widget 进行观察，可以看到它们也都是继承`SingleChildRenderObjectWidget` ，而“简单来说”它们不同的地方就是 `RenderObject ` 的实现了：

| Widget        | RenderBox  （RenderObject）                                  |
| --------- | ---------------------------------------- |
| Align | RenderPositionedBox |
| Padding | RenderPadding |
| Transform | RenderTransform |
|Offstage|RenderOffstage|

所以我们可以总结：**真正的布局和大小计算等行为，都是在 `RenderBox` 上去实现的。** 不同的 Widget 通过各自的 `RenderBox ` 实现了“差异化”的布局效果。**所以找每个 Widget 的实现，找它的 `RenderBox ` 实现就可以了。**（当然，另外还有 `RenderSliver`，这里暂时不讨论）

这里我们通过 **`Offstage`** 这个Widget 小结下，**`Offstage`** 这个 Widget 是通过 `offstage` 标志控制 **child** 是否显示的效果，同样的它也有一个 `RenderOffstage ` ，如下图，通过 `RenderOffstage ` 的源码我们可以“真实”看到  `offstage` 标志位的作用：

![RenderOffstage](http://img.cdn.guoshuyu.cn/20190604_Flutter-7/image3)

所以大部分时候，我们的 Widget 都是通过实现 `RenderBox` 实现布局的 ，**那我们可不可抛起 Widget 直接用 `RenderBox`呢？答案明显是可以的，如果你闲的🥚疼的话！**

Flutter 官方为了治疗我们“🥚疼”，提供了一个叫 **`CustomSingleChildLayout `** 的类，它抽象了一个叫 `SingleChildLayoutDelegate ` 的对象，让你可以更方便的操作  `RenderBox`  来达到自定义的效果。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-7/image4)

如下图三张源码所示，`SingleChildLayoutDelegate ` 的对象提供以下接口，并且接口 **前三个** 是按照顺序被调用的，通过实现这个接口，你就可以轻松的控制RenderBox 的 *布局位置、大小* 等。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-7/image5)

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-7/image6)

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-7/image7)


## 二、多子元素布局

事实上“多子元素布局”和单子元素类似，通过“举一反三”我们就可以知道它们的关系了，比如：

- `Row`、`Colum` 都继承了 `Flex`，而 Flex 继承了`MultiChildRenderObjectWidget` 并通过 `RenderFlex ` 创建了 `RenderBox`；
- `Stack` 同样继承 `MultiChildRenderObjectWidget`  并通过 `RenderStack ` 创建了 `RenderBox`；

| Widget        | RenderBox  （RenderObject）                                  |
| --------- | ---------------------------------------- |
| Row/Colum/Flex | RenderFlex |
| Stack | RenderStack |
| Flow | RenderFlow |
| Wrap|RenderWrap|

同样“多子元素布局”也提供了 `CustomMultiChildLayout` 和 `MultiChildLayoutDelegate` 满足你的“🥚疼”需求。


## 三、多子元素滑动布局


滑动布局作为 “多子元素布局” 的另一个分支，如 `ListView` 、`GridView`、`Pageview` ，它们在实现上要复杂的多，从下图一个的流程上我们大致可以知道它们的关系：


![](http://img.cdn.guoshuyu.cn/20190604_Flutter-7/image8)

由上图我们可以知道，流程最终回产生两个 *RenderObject* ：

-  `RenderSliver` ：*Base class for the render objects that implement scroll effects in viewports.*

-  `RenderViewport` ：*A render object that is bigger on the inside.*

```dart
/// [RenderViewport] cannot contain [RenderBox] children directly. Instead, use
/// a [RenderSliverList], [RenderSliverFixedExtentList], [RenderSliverGrid], or
/// a [RenderSliverToBoxAdapter], for example.
```

并且从 `RenderViewport `的说明我们知道，`RenderViewport `内部是不能直接放置 `RenderBox `，需要通过 `RenderSliver` 大家族来完成布局。而从源码可知：**`RenderViewport ` 对应的 Widget `Viewport` 就是一个 `MultiChildRenderObjectWidget`。** （你看，又回到 `MultiChildRenderObjectWidget ` 了吧。）


再稍微说下上图的流程：

- `ListView`、`Pageview`、`GridView` 等都是通过 `Scrollable`  、 `ViewPort`、`Sliver`大家族实现的效果。这里简单不规范描述就是：*一个“可滑动”的控件，嵌套了一个“视觉窗口”，然后内部通过“碎片”展示 children* 。

- 不同的是 `PageView` 没有继承 `SrollView`，而是直接通过 `NotificationListener` 和 `ScrollNotification` 嵌套实现。
> 注意 `TabBarView` 内部就是：`NotificationListener` + `PageView` 


是不是觉得少了什么？哈哈哈，有的有的，官方同样提供了解决“🥚疼”的自定义滑动 **`CustomScrollView `** ，它继承了 `ScrollView`，可通过 slivers 参数实现布局，这些 `slivers` 最终回通过 `Scrollable` 的 `buildViewport` 添加到 `ViewPort` 中，如下代码所示：


```dart
CustomScrollView(
  slivers: <Widget>[
    const SliverAppBar(
      pinned: true,
      expandedHeight: 250.0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('Demo'),
      ),
    ),
    SliverGrid(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200.0,
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        childAspectRatio: 4.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Container(
            alignment: Alignment.center,
            color: Colors.teal[100 * (index % 9)],
            child: Text('grid item $index'),
          );
        },
        childCount: 20,
      ),
    ),
    SliverFixedExtentList(
      itemExtent: 50.0,
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Container(
            alignment: Alignment.center,
            color: Colors.lightBlue[100 * (index % 9)],
            child: Text('list item $index'),
          );
        },
      ),
    ),
  ],
)
```

-------

#### 不知道你看完本篇后，有没有对 Flutter 的布局有更深入的了解呢？*让我们愉悦的堆积木吧！*

>自此，第七篇终于结束了！(///▽///)

### 资源推荐

* Github ： [https://github.com/CarGuo/](https://github.com/CarGuo)
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**

##### 完整开源项目推荐：

* [GSYGithubApp Flutter](https://github.com/CarGuo/GSYGithubAppFlutter ) 
* [GSYGithubApp React Native](https://github.com/CarGuo/GSYGithubApp ) 
* [GSYGithubAppWeex](https://github.com/CarGuo/GSYGithubAppWeex)

![我们还会再见吗？](http://img.cdn.guoshuyu.cn/20190604_Flutter-7/image9)