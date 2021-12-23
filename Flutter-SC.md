---
theme: smartblue
---

> **本文将通过一个需求场景，介绍一个非常实用的 Flutter 列表滑动知识点，该问题来源于网友的咨询**。

如何在 Flutter 上实现一个聊天列表，相信大家都不会觉得有什么困难，不就是一个 `ListView` ，然后根据类型显示渲染数据吗？这有什么困难的？


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SC/image1)

理论上确实没什么问题，但是有一个需求场景，却会出现一个无法修复的问题，那就是：**聊天列表需要双向插入数据**。


**双向插入数据会导致 `ListView` 什么问题？** 举个例子，首先我们使用常见的 `ListView` 绘制出一个模拟聊天列表，这里使用了 `reverse` 反转列表满足 UI 需求，让列表从底部开始网上布局滑动：

```dart
ListView.builder(
        controller: scroller,
        reverse: true,
        itemBuilder: (context, index) {
          var item = data[index];
          if (item.type == "Right")
            return renderRightItem(item);
          else
            return renderLeftItem(item);
        },
        itemCount: data.length,
      )
```

运行后效果如下图所示：


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SC/image2)

- 首先添加红色的，模拟加载旧数据 `list.add` ，可以看到上面的数据出现了，没有问题；
- 接着我们滑动一段距离，没有问题；
- 接着添加绿色数据，模拟新收到新消息 `list.insert`，**可以看到列表出现了跳动，没有停留在我们之前滑动的位置**；
- 我们继续滑动，模拟新收到新消息，**列表继续出现跳动；**


有问题没有？如果这个效果产品可以接受，那就没问题。但是如果产品拿着 QQ 聊天问你，为什么别人收到新消息，列表不会跳动？这问题不就来了吗～

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SC/image3)


首先分析问题，为什么列表会出现跳动？在 [《不一样角度带你了解 Flutter 中的滑动列表实现》](https://juejin.cn/post/6956215495440007175) 我们讲过，Flutter 的滑动列表效果主要有三部分组成：

- `Viewport` ： 它提供的是一个“视窗”的作用，也就是列表所在的可视区域大小；
- `Scrollable` ：它主要通过对手势的处理来实现滑动效果；
- `Sliver` ： 准确来说应该是 `RenderSliver`， 它主要是用于在 `Viewport` 里面布局和渲染内容，比如 `SliverList`；

也许这些看着太抽象，结合下图：

- 绿色的 `Viewport` 就是我们看到的列表窗口大小；
- 紫色部分就是处理手势的 `Scrollable`，让黄色部分 `SliverList` 在 `Viewport` 里产生滑动；
- 黄色的部分就是 `SliverList` ， 当我们滑动时其实就是它在 Viewport 里的位置发生了变化；

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SC/image4)


本来一切正常，但是当我们通过 `insert` 添加绿色部分的数据时，插入头部的数据就会
（绿色部分），就会把原本的 `SliverList` 数据往后顶上去，从而产生了 `SliverList` 的位置发现变化。

**所以本质上是 `SliverList` 变长了，起点变了，从而在 `Viewport` 里的位置发生了变化**。


那如何去解决这个问题呢？有人可能就会说，那我们让他 `jump` 回原来的位置不就行了吗？

如下图所示，我们通过记录原本位置，然后添加数据，之后得到添加数据的大小，之后 jump 到原来的位置，效果就是会出现闪动～


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SC/image5)


所以如何解决这个问题呢？**这就涉及到 Flutter 列表滑动的一个关键知识点：`center`**。


什么是列表的 `center` ？


其实在 `center` 是 `ViewPort` 里的一个关键参数，**默认是第一个`RenderSliver`，决定了 `scrollOffset = 0` 的位置**。


另外 `center` 是一个 `Key`对象， 也就是除了默认之外，我们可以通过 `Key` 来指定我们想要的 `center` 位置。

也就是，**如果我们旧数据插入到  `center` 之前，新数据插入到  `center` 之后，那岂不是列表就不会发现滑动了？**


那我们如何配置  `center` ？ **这时候就需要使用到 `CustomScrollView`**，`CustomScrollView` 支持配置 `center`， 另外对于 `CustomScrollView` 是直接配置你需要的 `slivers` 数组。


也就是说，不像 `ListView` 那样只有一个 `SliverList`，我们可以直接配置两个 `SliverList`，然后按照上面的思路，中间放一个 `center` 。


如下面代码所示，因为聊天列表的场景，我们的列表是 `reverse` 的，所以需要将新数据的 `SliverList` 放在 `centerKey` 的上面，把旧数据的 SliverList` 放在 ` `centerKey` 下面。


```dart
CustomScrollView(
        controller: scroller,
        reverse: true,
        center: centerKey,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                var item = newData[index];
                if (item.type == "Right")
                  return renderRightItem(item);
                else
                  return renderLeftItem(item);
              },
              childCount: newData.length,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.zero,
            key: centerKey,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                var item = loadMoreData[index];
                if (item.type == "Right")
                  return renderRightItem(item);
                else
                  return renderLeftItem(item);
              },
              childCount: loadMoreData.length,
            ),
          ),
        ],
      )
```

运行后效果如图所示，可以看到即使在绿色数据新增的时候，列表也没有发生跳转，其实现在的布局滑动效果，就是从原本的 0 ～ xxx 的滑动范围，变成了 -AAA ～ BB 这样的滑动范围。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SC/image6)




前面我们说过 `center` 决定了 `scrollOffset = 0` 的位置，所以当我们如上面那样布局后，就等于有了从 0 ～ ♾️ 和从 -♾️ ～ 0 的范围，所以当我们 `insert` 数据到头部时，其实是往 `minScrollExtent` 的方向插入数据，增加的是负数的 `Offset`，从而不会导致列表产生位移。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SC/image7)



虽然实现很简单，但是如果不去对 Flutter 的滑动列表机制有所了解，就很容易对着 `ListvView` 陷入僵局，这篇文章也是为了给大家打开思路，提高对 `ViewPort` 和 `Sliver` 的了解。


如果你对 Flutter 还有什么疑问或者想法，欢迎留言交流～。