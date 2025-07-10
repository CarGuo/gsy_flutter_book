在移动开发中图文混排是十分常见的业务需求，如下图效果所示，本篇将介绍在 Flutter 中的图文混排效果与实现原理。


![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image1)


事实上，针对如上所示的图文混排需求，Flutter 官方提供了十分便捷的实现方式: **`WidgetSpan`** 。

如下代码所示，**通过 `Text.rich` 接入 `TextSpan` 和 `WidgetSpan` 就可以快速实现图文混排的需求，并且可以看出 `WidgetSpan` 不止支持图片控件**，它可以接入任何你需要的 `Widget` ，比如 `Card` 、`InkWell` 等等。


```
Text.rich(TextSpan(
      children: <InlineSpan>[
        TextSpan(text: 'Flutter is'),
        WidgetSpan(
            child: SizedBox(
          width: 120,
          height: 50,
          child: Card(
              color: Colors.blue,
              child: Center(child: Text('Hello World!'))),
        )),
        WidgetSpan(
            child: SizedBox(
          width: size > 0 ? size : 0,
          height: size > 0 ? size : 0,
          child: new Image.asset(
            "static/gsy_cat.png",
            fit: BoxFit.cover,
          ),
        )),
        TextSpan(text: 'the best!'),
      ],
    )
```

也就是说  **`WidgetSpan` 支持在文本中插入任意控件**，这大大提升了 Flutter 中富文本的自定义效果，比如上述演示效果中随意改变图片的大小。

**那为什么 `WidgetSpan` 可以如何方便地实现文本和 Widget 混合效果呢？这就要从 `Text` 的实现说起**。

## 实现原理

我们常用的 `Text` 控件其实只是 `RichText` 的封装，而 `RichText` 的实现如下图所示，主要可以分为三部分：**`MultiChildRenderObjectWidget`** 、 **`MultiChildRenderObjectElement`** 和 **`RenderParagraph`** 。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image2)

正如我们知道的， Flutter 控件一般是由 `Widget`、`Element` 和 `RenderObeject` 三部分组成，而在 `RichText` 中也是如此，其中：

- `RenderParagraph` 主要是负责文本绘制、布局相关；
- `RichText` 继承 `MultiChildRenderObjectWidget` 主要是需要通过 `MultiChildRenderObjectElement` 来处理  `WidgetSpan` 中 children 控件的插入和管理。

#### 那 `WidgetSpan` 究竟是如何混入在文本绘制中呢？

在前面的使用中，我们首先是传入了一个 `TextSpan` 给 `RichText` ，并在 `TextSpan` 的 `children` 中拼接我们需要的内容，那就从 `RichText`  开始挖掘其中的原理。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image3)

如上代码所示，这里我们首先看 `RichText` 的入口，可以看到 `RichText` 开始是有一个 `_extractChildren` 方法，这个方法主要是将传入 `TextSpan` 的 `children` 里，所有的 `WidgetSpan` 通过 `visitChildren` 方法给递归筛选出来，然后传入给父类 `MultiChildRenderObjectWidget`。

> 为什么需要这么做？在 [《十六、详解自定义布局实战》](https://mp.weixin.qq.com/s/zwKG0ehMRPoRidRPtGGUpQ) 中介绍过，`MultiChildRenderObjectWidget` 的 children 最终会通过 `MultiChildRenderObjectElement` 作为桥梁，然后被插入到需要管理和绘制的 child 链表结构中，这样在 `RenderObject` 中方便管理和访问。

另外我们知道 `RichText` 传入的 `text` 其实是一个 `InlineSpan`  ，而 `TextSpan` 就是 `InlineSpan` 的子类，`WidgetSpan` 也是 `InlineSpan` 的子类实现，它们的关系如下图所示：

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image4)

对于 `InlineSpan` 系列我们主要关注两个方法：**`visitChildren` 和 `build`** 方法，它的子类 `TextSpan` 和 `WidgetSpan` 都对这两个方法有自己对应的实现。

```
  void build(ui.ParagraphBuilder builder, { double textScaleFactor = 1.0, List<PlaceholderDimensions> dimensions });

  bool visitChildren(InlineSpanVisitor visitor);
```

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image5)


接着看 `RenderParagraph` ，如上代码所示，`RichText` 中的 `text`（`InlineSpan`） 会继续被传入到 `RenderParagraph` 中，`RenderParagraph` 继承了 `RenderBox` 并混入的 `ContainerRenderObjectMixin` 和 `RenderBoxContainerDefaultsMixin` 等。

> 混入的对象这部分在内容在 [《十六、详解自定义布局实战》](https://mp.weixin.qq.com/s/zwKG0ehMRPoRidRPtGGUpQ)  也介绍过，这里只需要知道通过混入它们， `RenderParagraph`  就可以获得前面通过 `WidgetSpan` 传入到 `MultiChildRenderObjectElement` 的 children 链表，并且布局计算大小等。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image6)

之后 `RenderParagraph` 中的 `text` 之后会被放置到 `TextPainter` 中使用，并且通过 `_extractPlaceholderSpans` 方法将所有的 `PlaceholderSpans` 筛选出来。

`TextPainter` 主要用于实现文本的绘制，这里我们暂时不多分析，**而 `_extractPlaceholderSpans` 挑选出来的所有 `PlaceholderSpans` ，其实就是 `WidgetSpan`**。

>  `WidgetSpan` 是通过继承 `PlaceholderSpans` 从而实现了 `InlineSpan`，而目前暂时 `PlaceholderSpans` 实现的类只有  `WidgetSpan`。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image7)


挑选出来的 `List<PlaceholderSpan>` 们会在 `RenderParagraph` 计算宽高等方法中被用到，比如 `computeMaxIntrinsicWidth` 方法等，**其中主要有 `_canComputeIntrinsics` 、 `_computeChildrenWidthWithMaxIntrinsics` 、`_layoutText` 三个关键**方法，这三个方法结合处理了  `RenderParagraph` 中 Span 的尺寸和布局等。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image8)

- **`_canComputeIntrinsics`**：  `_canComputeIntrinsics` 主要判断了 `PlaceholderSpan` 只支持的 `baseline` 配置。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image9)

- **`_computeChildrenWidthWithMaxIntrinsics`**：   `_computeChildrenWidthWithMaxIntrinsics` 中会**通过 `PlaceholderSpan` 去对应得到 `PlaceholderDimensions`**，得到的  `PlaceholderDimensions`  会用于后续如 `WidgetSpan` 的大小绘制信息。

> 这个  `PlaceholderDimensions` 会通过 `setPlaceholderDimensions` 方法设置到 `TextPainter` 里面， 这样  `TextPainter` 在 `layout` 的时候，就会将 `PlaceholderDimensions` 赋予 `WidgetSpan` 大小信息。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image10)

- **`_layoutText`**: `_layoutText` 方法会调用 `_textPainter.layout`， 从而执行 `_text.build` 方法，这个方法就会触发 `children` 中的 `WidgetSpan` 去执行 `build` 。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image11)

所以如下代码所示，`_textPainter.layout` 会执行 Span 的 `build` 方法，将 `PlaceholderDimensions` 设置到 `WidgetSpan` 里面，然后还有**通过 `_paragraph.getBoxesForPlaceholders()` 方法获取到控件绘制需要的 `left`、`right` 等信息**，这些信息来源是基于上面 `text.build` 的执行。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image12)


> _paragraph.getBoxesForPlaceholders() 获取到的 `TextBox` 信息，是基于后面我们介绍在 Span 里提交的 `addPlaceholder` 方法获取。


这些信息会在 `setParentData` 方法中被设置到 `TextParentData` 里，关于 `ParentData` 及其子类的作用，在[《十六、详解自定义布局实战》](https://mp.weixin.qq.com/s/zwKG0ehMRPoRidRPtGGUpQ)  同样有所介绍，这里就不赘述了，简单理解就是  `WidgetSpan`  绘制的时候所需要的 `offset` 位置信息会由它们提供。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image13)

之后如下代码所示， `WidgetSpan` 的 `build` 方法被执行，这里会有一个 `placeholderCount`， `placeholderCount` 默认是从 0 开始，而在执行 `addPlaceholder` 方法时会通过 `_placeholderCount++` 自增，这样下一个 `WidgetSpan` 就会拿到下一个 `PlaceholderDimensions` 用于设置大小。

> `addPlaceholder` 之后会执行到 Flutter Engine 中的流程了。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image14)

最终 `RenderParagrash`  的 `paint` 方法会执行 `_textPainter.paint` 并把确定了大小和位置的 child 提交绘制。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image15)

是不是有点晕，结合下图所示，总结起来其实就是:

- `RichText` 中传入 `TextSpan` ， 在 `TextSpan` 的 children 中使用 `WidgetSpan` ，`WidgetSpan` 里的 `Widget` 们会转成 `MultiChildRenderObjectElement` 的 `children`， 处理后得到一个 child 链表结构；
- 之后 `TextSpan` 进入 `RenderParagrash` ，会抽取出对应 `PlaceholderSpan`（`WidgetSpan`），然后通过转化为 `PlaceholderDimensions` 保存大小等信息；
- 之后进去 `TextPainter` 会触发  `InlineSpan` 的 `build` 方法，从而将前面得到的 `PlaceholderDimensions` 传递到 `WidgetSpan` 中；
- `WidgetSpan` 中的控件信息通过  `addPlaceholder` 会被传递到 `Paragraph`；
- 之后 `TextPainter` 中通过 `addPlaceholder` 的信息获取，调用 `_paragraph.getBoxesForPlaceholders()` 获取去控件绘制需要的 `offset` ；
-  有了大小和位置，最终文本中插入的控件，会在 `RenderParagrash` 的 `paint` 方法被绘制。


![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image16)


**`RichText` 中插入控件的管理巧妙的依托到 `MultiChildRenderObjectWidget` 中，从而复用了原本控件的管理逻辑，之后依托引擎计算位置从而绘制完成。**

至此，简简单单的  `WidgetSpan` 的实现原理解析完成～


### 资源推荐

- Github ：https://github.com/CarGuo
- 开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter
- 开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo
- 开源 Flutter 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook
- 开源 React Native 项目：https://github.com/CarGuo/GSYGithubApp



![](http://img.cdn.guoshuyu.cn/20200316_Flutter-TWHP/image17)