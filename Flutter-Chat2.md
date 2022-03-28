聊天列表是一个很扣细节的场景，在之前的 [《Flutter 实现完美的双向聊天列表效果，滑动列表的知识点》](https://juejin.cn/post/7029517821004480549) 里，通过 `CustomScrollView` 和配置它的 `center` 从而解决了数据更新时的列表跳动问题，但是这时候又有网友提出了新的问题：


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Chat2/image1)

如下动图所示，可以看到虽然列表在添加新数据后虽然没有发生跳动，但是在列表数据长度足够的情况下，顶部会有一篇空白。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Chat2/image2)


如下代码所示，这个问题的起因正是在解决跳动问题而增加的 `center` ，因为列表是  `reverse` ，并且红色的  `SliverList` 长度只有 3 条，高度不够导致顶部留空白。



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

如下图结合图片理解更形象：

- `center` 其实就是列表的起始锚点，我们把锚点给了  `SliverPadding` ，而因为列表是 `reverse`，所以起始位置是在屏幕下方；
-  红色的 old 数据 `SliverList` ，在代码里是处于 `center` 的下方，而因为 `reverse` 所以它实际就是黄色的部分；
- 所以虽然绿色的  `SliverList` 虽然新增了数据，但是从  `center` 往上的高度还是不够，所以就出现了黄色 `SliverList` 顶部空白的问题；


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Chat2/image3)


结合这个问题，这里可以发现关键的点就在于  `reverse`  ，而对比微信和QQ的聊天列表需求，在没有数据时，消息数据应该是从顶部开始，所以这时候就需要我们调整列表实现，参考微信/QQ 的实现模式。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Chat2/image4)

如下代码所以，这里针对新交互场景做了优化调整：

- 去除 `CustomScrollView` 的  `reverse` ；
- 对调两个 `SliverList` 的位置，把加载 old 数据的  `SliverList` 放到 `center` 的前面；


```dart
CustomScrollView(
  controller: scroller,
  center: centerKey,
  slivers: [
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
    SliverPadding(
      padding: EdgeInsets.zero,
      key: centerKey,
    ),
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
  ],
)
```

是不是很简单，就这？运行后也如下图所示，可以看到运行后的代码不会再有空白的情况，也没有新增数据跳动的情况，双向滑动也正常，那你知道为什么吗？

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Chat2/image5)


如下图所示，调整后从结构上变成了右边的逻辑：

- 数据起始锚点在页面顶部，所以不会存在顶部留空问题；
- 在 `center` 下面的 `SliverList` 按照正向排序正常显示，用于显示新数据；
- 在 `center` 上面的 `SliverList` 列表会被变成以 `center` 为起点反向顺序显示，用于加载旧数据；


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Chat2/image6)

当然，这里有一点需要注意的局就是：**起始进来时加载的第一页数据应该是用绿色的正向 `SliverList` ，因为起始点在顶部，如果不用下面绿色的正向 `SliverList` ，就会导致第一次数据看不到的情况**。

这时候就有人可能会说，如果是下图所示场景，只加载旧数据，不加载新数据，那不就出现底部留空了吗？

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Chat2/image7)

是的，**我们其实是把顶部留空的问题转移到了底部，但是这个问题在实际业务场景是不成立**，进入聊天列表首先就需要先加载满一页的数据，所以：

- 如果 old 数据本来就不够，例如例子里只有3条，那也就不会有加载更多 old 数据的场景，所以不会产生滑动；
- 如果 old 数据足够，那默认就足以撑满列表；

而随着 new 数据的增加，页面也会被填满从而可以正常滑动并且充满，所以从这个实现上看会更加合理。

那有人可能会说，就这？还有什么可以优化的小技巧？ 比如增加**判断列表是否处于底部，决定在接受到新数据时是否滑动到最新消息。**


实现这个优化也很简单，首先我们可以嵌套一个  `NotificationListener` ， 在这里我们主要是获取  `notification.metrics.extentAfter` 这个参数。

```dart
NotificationListener(
  onNotification: (notification) {
    if (notification is ScrollNotification) {
      if (notification.metrics is PageMetrics) {
        return false;
      }
      if (notification.metrics is FixedScrollMetrics) {
        if (notification.metrics.axisDirection == AxisDirection.left ||
            notification.metrics.axisDirection == AxisDirection.right) {
          return false;
        }
      }
      
      ///取到这个值
      extentAfter = notification.metrics.extentAfter;
    }
    return false;
  },
)
```

> 这里的 `if` 判断，只是为了规避其他控件的影响，比如列表里的 `PageView` 或者 `TextFiled` 的影响。

那 `extentAfter` 参数的作用是什么？ 事实上在 `FixedScrollMetrics` 里有  `extentBefore` 、 `extentInside` 和 `extentAfter` 三个参数，它们的关系类似下图所示：

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Chat2/image8)

一般情况下：

- `extentInside` 就是视图窗口大小；
- `extentBefore` 就是前面还可以滑动距离；
- `extentAfter` 就是后面还可以滑动距离；

**所以我们只需要判断  `extentAfter`  是否为 0 ，就可以判断列表是不是处于底部** ，从而针对场景首先不同的业务逻辑，例如下图所示，针对列表是否处于底部，在接收到新数据时是直接跳到最新数据，还是弹出提示用让用户点击跳转。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Chat2/image9)

```dart
if (extentAfter == 0) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text("你目前位于最底部，自动跳转新消息item"),
    duration: Duration(milliseconds: 1000),
  ));
  Future.delayed(Duration(milliseconds: 200), () {
    scroller.jumpTo(scroller.position.maxScrollExtent);
  });
} else {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: InkWell(
      onTap: () {
        scroller.jumpTo(scroller.position.maxScrollExtent);
      },
      child:Text("点击我自动跳转新消息item")
    ),
    duration: Duration(milliseconds: 1000),
  ));
}
```

所以从聊天列表的场景上看，实现一个聊天列表并不难，但是需要优化的细节可能会很多，如果你在这方面还有什么问题，欢迎评论交流。


> 实例代码可见：https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/chat_list_scroll_demo_page_2.dart