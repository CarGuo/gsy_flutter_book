# Flutter 小技巧之横竖列表的自适应大小布局支持

今天这个主题看着是不是有点抽象？又是列表嵌套？之前不是分享过[《 ListView 和 PageView 的各种花式嵌套》](https://juejin.cn/post/7116267156655833102)了么？那这次的自适应大小布局支持有什么不同？

> 算是某些奇特的场景下才会需要。

首先我们看下面这段代码，基本逻辑就是：我们希望  `vertical`  的 `ListView` 里每个 Item 都是根据内容自适应大小，并且 Item 会存在有  `horizontal` 的 `ListView`  这样的 child。

`horizontal` 的 `ListView`  我们也希望它能够根据自己的 `children` 去自适应大小。**那么你觉得这段代码有什么问题？它能正常运行吗？**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: new Text(""),
    ),
    extendBody: true,
    body: Container(
      color: Colors.white,
      child: ListView(
        children: [
          ListView(
            scrollDirection: Axis.horizontal,
            children: List<Widget>.generate(50, (index) {
              return Padding(
                padding: EdgeInsets.all(2),
                child: Container(
                  color: Colors.blue,
                  child: Text(List.generate(
                          math.Random().nextInt(10), (index) => "TEST\n")
                      .toString()),
                ),
              );
            }),
          ),
          Container(
            height: 1000,
            color: Colors.green,
          ),
        ],
      ),
    ),
  );
}
```

答案是不能，因为这段代码里 `vertical`  的 `ListView` 嵌套了  `horizontal` 的 `ListView` ，而横向的  `ListView`  并没有指定高度，并且垂直方向的  `ListView`  也没有指定 `itemExtent` ，所以我们会得到如下图所示的错误：

![](http://img.cdn.guoshuyu.cn/20230425_N24/image1.png)

为什么会有这样的问题，简单说一下，我们都知道 Flutter 是从上往下传递约束，从上往上返回 `Size` 的一个布局过程，也就是需要 child 通过通过 parent 的约束来决定自己的大小，然后 parent 根据 child 返回的 `Size` 决定自己的尺寸。

![](http://img.cdn.guoshuyu.cn/20230425_N24/image2.png)

> 对这部分感兴趣的可以看 [《带你了解不一样的 Flutter》](https://juejin.cn/post/7053777774707736613)

但是对于可滑动控件来说有点特殊，因为可滑动控件在其滑动方向的主轴上，理论是需要「无限大」的，所以对于可滑动控件来说，就需要有一个「窗口」的固定大小，也就是 `ViewPort` 这个「窗口」需要有一个主轴方向的大小。

比如 `ListView` ，一般情况下就是有一个  `ViewPort` ，然后内部的 `SliverList` 构建一个列表，然后通过手势在   `ViewPort`  「窗口」下相应产生移动，从而达到列表滑动的效果。

![](http://img.cdn.guoshuyu.cn/20230425_N24/image3.png)

> 如果感兴趣可以看 [《不一样角度带你了解 Flutter 中的滑动列表实现》](https://juejin.cn/post/6956215495440007175)

那么我们再回到上面  `vertical`  的 `ListView` 嵌套  `horizontal` 的 `ListView ` 的问题：

- 因为垂直的  `ListView`  没有设置  `itemExtent` ，所以它的每个 child 不会有一个固定高度，因为我们的需求是每个 Item 根据自己的需要自适应高度。
- 横向的   `ListView`  没有设置明确高度，作为 parent 的垂直  `ListView`  高度理论又是「无限高」，所以横向的     `ListView`   无法计算得到一个有效的高度。

另外，由于   `ListView`  不像 `Row`/`Column `等控件，它拥有的 `children` 理论也是「无限」的，并且没有展示的部分一般是不会布局和绘制，所以不能像  `Row`/`Column ` 一样计算出所有控件的高度之后，来决定自身的高度。

那么破解的方式有哪些呢？目前情况下可以提供两种解决方式。

# SingleChildScrollView

如下代码所示，首先最简单的就是把横向的  `ListView`  替换成  `SingleChildScrollView` ，因为不同于  `ListView`  ，  `SingleChildScrollView`  只有一个 child ，所以它的 `ViewPort` 也比较特殊。

```dart
return Scaffold(
  appBar: AppBar(
    title: new Text("ControllerDemoPage"),
  ),
  extendBody: true,
  body: Container(
    color: Colors.white,
    child: ListView(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List<Widget>.generate(50, (index) {
              return Padding(
                padding: EdgeInsets.all(2),
                child: Container(
                  color: Colors.blue,
                  child: Text(List.generate(
                          math.Random().nextInt(10), (index) => "TEST\n")
                      .toString()),
                ),
              );
            }),
          ),
        ),
        Container(
          height: 1000,
          color: Colors.green,
        ),
      ],
    ),
  ),
)
```

在   `SingleChildScrollView`   的 `_RenderSingleChildViewport` 里，布局时可以很简单的通过 `child!.layout` 之后得到 child 的大小，然后配合 `Row` 就计算出所有 child 的综合高度，这样可以实现横向的列表效果。

![](http://img.cdn.guoshuyu.cn/20230425_N24/image4.png)

运行之后结果入下图所示，可以看到此时在垂直的 `ListView `里，横向的   `SingleChildScrollView`    被正确渲染出来，但是此时出现「参差不齐」的高度布局。

![](http://img.cdn.guoshuyu.cn/20230425_N24/image5.png)

如下代码所示，这时候我们只需要在 `Row`  嵌套一个 `IntrinsicHeight`  ，就可以让其内部高度对齐，因为   `IntrinsicHeight`   在布局时会提前调用 child 的 `getMaxIntrinsicHeight`  获取 child 的高度，修改 parent 传递给 child 的约束信息。

```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: IntrinsicHeight(
    child: Row(
      children: List<Widget>.generate(50, (index) {
        return Padding(
          padding: EdgeInsets.all(2),
          child: Container(
            alignment: Alignment.bottomCenter,
            color: Colors.blue,
            child: Text(List.generate(
                    math.Random().nextInt(10), (index) => "TEST\n")
                .toString()),
          ),
        );
      }),
    ),
  ),
),
```

运行效果如下所示，可以看到此时所有横向 Item 的高度都一致，但是这个解决方法也有两个比较致命的问题：

-  `SingleChildScrollView`  里是通过 `Row` 计算的高度，也就是布局时会需要一次性计算所有 child ，如果列表太长就会产生性能损耗
- `IntrinsicHeight`  推算布局的过程会比较费时，可能会到 O（N²），虽然 Flutter 里针对这部分计算结果做了缓存，但是不妨碍它的耗时。

![](http://img.cdn.guoshuyu.cn/20230425_N24/image6.png)



# UnboundedListView

第二个解决思路就是基于 `ListView` 去自定义，前面我们不是说 `ListView` 不会像 `Row` 那样去统计 children 的大小么？那我们完全可以自定义一个 `UnboundedListView` 来统计。

> 这部分思路最早来自 Github ：https://gist.github.com/vejmartin/b8df4c94587bdad63f5b4ff111ff581c

首先我们基于 `ListView` 定义一个  `UnboundedListView `  ，通过  `mixin` 的方式` override` 对应的 `Viewport` 和 `Sliver` ，也就是：

- 把  `buildChildLayout` 里的 `SliverList` 替换成我们自定义的 `UnboundedSliverList`
- 把  `buildViewport`  里的 `Viewport` 替换成我们自定义的  `UnboundedViewport` 
- 在 `buildSlivers` 里处理` Padding` 逻辑，把 `SliverPadding` 替换为自定义的 `UnboundedSliverPadding` 

```dart
class UnboundedListView = ListView with UnboundedListViewMixin;


/// BoxScrollView 的基础上
mixin UnboundedListViewMixin on ListView {
  @override
  Widget buildChildLayout(BuildContext context) {
    return UnboundedSliverList(delegate: childrenDelegate);
  }

  @protected
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) {
    return UnboundedViewport(
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
      cacheExtent: cacheExtent,
    );
  }

  @override
  List<Widget> buildSlivers(BuildContext context) {
    Widget sliver = buildChildLayout(context);
    EdgeInsetsGeometry? effectivePadding = padding;
    if (padding == null) {
      final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
      if (mediaQuery != null) {
        // Automatically pad sliver with padding from MediaQuery.
        final EdgeInsets mediaQueryHorizontalPadding =
            mediaQuery.padding.copyWith(top: 0.0, bottom: 0.0);
        final EdgeInsets mediaQueryVerticalPadding =
            mediaQuery.padding.copyWith(left: 0.0, right: 0.0);
        // Consume the main axis padding with SliverPadding.
        effectivePadding = scrollDirection == Axis.vertical
            ? mediaQueryVerticalPadding
            : mediaQueryHorizontalPadding;
        // Leave behind the cross axis padding.
        sliver = MediaQuery(
          data: mediaQuery.copyWith(
            padding: scrollDirection == Axis.vertical
                ? mediaQueryHorizontalPadding
                : mediaQueryVerticalPadding,
          ),
          child: sliver,
        );
      }
    }

    if (effectivePadding != null)
      sliver =
          UnboundedSliverPadding(padding: effectivePadding, sliver: sliver);
    return <Widget>[sliver];
  }
}
```

接下来首先是实现 `UnboundedViewport` ，一样的套路：

- 首先基于  `Viewport` 的基础上，通过 `createRenderObject` 将 `RenderViewPort` 修改为我们的 `UnboundedRenderViewport`
- 基于 `RenderViewport`  增加 `performLayout` 和 `layoutChildSequence` 的自定义逻辑，实际上就是增加一个 `unboundedSize` 参数，这个参数通过 child 的 `RenderSliver`  里去统计得到

```dart

class UnboundedViewport = Viewport with UnboundedViewportMixin;
mixin UnboundedViewportMixin on Viewport {
  @override
  RenderViewport createRenderObject(BuildContext context) {
    return UnboundedRenderViewport(
      axisDirection: axisDirection,
      crossAxisDirection: crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      anchor: anchor,
      offset: offset,
      cacheExtent: cacheExtent,
    );
  }
}

class UnboundedRenderViewport = RenderViewport
    with UnboundedRenderViewportMixin;
mixin UnboundedRenderViewportMixin on RenderViewport {
  @override
  bool get sizedByParent => false;

  double _unboundedSize = double.infinity;

  @override
  void performLayout() {
    BoxConstraints constraints = this.constraints;
    if (axis == Axis.horizontal) {
      _unboundedSize = constraints.maxHeight;
      size = Size(constraints.maxWidth, 0);
    } else {
      _unboundedSize = constraints.maxWidth;
      size = Size(0, constraints.maxHeight);
    }

    super.performLayout();

    switch (axis) {
      case Axis.vertical:
        offset.applyViewportDimension(size.height);
        break;
      case Axis.horizontal:
        offset.applyViewportDimension(size.width);
        break;
    }
  }

  @override
  double layoutChildSequence({
    required RenderSliver? child,
    required double scrollOffset,
    required double overlap,
    required double layoutOffset,
    required double remainingPaintExtent,
    required double mainAxisExtent,
    required double crossAxisExtent,
    required GrowthDirection growthDirection,
    required RenderSliver? advance(RenderSliver child),
    required double remainingCacheExtent,
    required double cacheOrigin,
  }) {
    crossAxisExtent = _unboundedSize;
    var firstChild = child;

    final result = super.layoutChildSequence(
      child: child,
      scrollOffset: scrollOffset,
      overlap: overlap,
      layoutOffset: layoutOffset,
      remainingPaintExtent: remainingPaintExtent,
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
      growthDirection: growthDirection,
      advance: advance,
      remainingCacheExtent: remainingCacheExtent,
      cacheOrigin: cacheOrigin,
    );

    double unboundedSize = 0;
    while (firstChild != null) {
      if (firstChild.geometry is UnboundedSliverGeometry) {
        final UnboundedSliverGeometry childGeometry =
            firstChild.geometry as UnboundedSliverGeometry;
        unboundedSize = math.max(unboundedSize, childGeometry.crossAxisSize);
      }
      firstChild = advance(firstChild);
    }
    if (axis == Axis.horizontal) {
      size = Size(size.width, unboundedSize);
    } else {
      size = Size(unboundedSize, size.height);
    }

    return result;
  }
}
```

接下来我们继承 `SliverGeometry` 自定义一个 `UnboundedSliverGeometry` ，主要就是增加了一个 `crossAxisSize` 参数，用来记录当前统计到的副轴高度，从而让上面的 `ViewPort` 可以获取得到。

```dart
class UnboundedSliverGeometry extends SliverGeometry {
  UnboundedSliverGeometry(
      {SliverGeometry? existing, required this.crossAxisSize})
      : super(
          scrollExtent: existing?.scrollExtent ?? 0.0,
          paintExtent: existing?.paintExtent ?? 0.0,
          paintOrigin: existing?.paintOrigin ?? 0.0,
          layoutExtent: existing?.layoutExtent,
          maxPaintExtent: existing?.maxPaintExtent ?? 0.0,
          maxScrollObstructionExtent:
              existing?.maxScrollObstructionExtent ?? 0.0,
          hitTestExtent: existing?.hitTestExtent,
          visible: existing?.visible,
          hasVisualOverflow: existing?.hasVisualOverflow ?? false,
          scrollOffsetCorrection: existing?.scrollOffsetCorrection,
          cacheExtent: existing?.cacheExtent,
        );

  final double crossAxisSize;
}
```

如下代码所示，最终我们基于 `SliverList` 实现一个  `UnboundedSliverList` ，这也是核心逻辑，主要是实现 `performLayout` 部分的代码，我们需要在原来代码的基础上，在某些节点加上自定义的逻辑，用于统计参与布局的每个 Item 的高度，从而得到一个最大值。

> 代码看起来很长，但是其实我们新增的很少。

```dart
class UnboundedSliverList = SliverList with UnboundedSliverListMixin;
mixin UnboundedSliverListMixin on SliverList {
  @override
  RenderSliverList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element =
        context as SliverMultiBoxAdaptorElement;
    return UnboundedRenderSliverList(childManager: element);
  }
}

class UnboundedRenderSliverList extends RenderSliverList {
  UnboundedRenderSliverList({
    required RenderSliverBoxChildManager childManager,
  }) : super(childManager: childManager);

  // See RenderSliverList::performLayout
  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double scrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;
    BoxConstraints childConstraints = constraints.asBoxConstraints();
    int leadingGarbage = 0;
    int trailingGarbage = 0;
    bool reachedEnd = false;

    if (constraints.axis == Axis.horizontal) {
      childConstraints = childConstraints.copyWith(minHeight: 0);
    } else {
      childConstraints = childConstraints.copyWith(minWidth: 0);
    }

    double unboundedSize = 0;

    // should call update after each child is laid out
    updateUnboundedSize(RenderBox? child) {
      if (child == null) {
        return;
      }
      unboundedSize = math.max(
          unboundedSize,
          constraints.axis == Axis.horizontal
              ? child.size.height
              : child.size.width);
    }

    unboundedGeometry(SliverGeometry geometry) {
      return UnboundedSliverGeometry(
        existing: geometry,
        crossAxisSize: unboundedSize,
      );
    }

    // This algorithm in principle is straight-forward: find the first child
    // that overlaps the given scrollOffset, creating more children at the top
    // of the list if necessary, then walk down the list updating and laying out
    // each child and adding more at the end if necessary until we have enough
    // children to cover the entire viewport.
    //
    // It is complicated by one minor issue, which is that any time you update
    // or create a child, it's possible that the some of the children that
    // haven't yet been laid out will be removed, leaving the list in an
    // inconsistent state, and requiring that missing nodes be recreated.
    //
    // To keep this mess tractable, this algorithm starts from what is currently
    // the first child, if any, and then walks up and/or down from there, so
    // that the nodes that might get removed are always at the edges of what has
    // already been laid out.

    // Make sure we have at least one child to start from.
    if (firstChild == null) {
      if (!addInitialChild()) {
        // There are no children.
        geometry = unboundedGeometry(SliverGeometry.zero);
        childManager.didFinishLayout();
        return;
      }
    }

    // We have at least one child.

    // These variables track the range of children that we have laid out. Within
    // this range, the children have consecutive indices. Outside this range,
    // it's possible for a child to get removed without notice.
    RenderBox? leadingChildWithLayout, trailingChildWithLayout;

    RenderBox? earliestUsefulChild = firstChild;

    // A firstChild with null layout offset is likely a result of children
    // reordering.
    //
    // We rely on firstChild to have accurate layout offset. In the case of null
    // layout offset, we have to find the first child that has valid layout
    // offset.
    if (childScrollOffset(firstChild!) == null) {
      int leadingChildrenWithoutLayoutOffset = 0;
      while (earliestUsefulChild != null &&
          childScrollOffset(earliestUsefulChild) == null) {
        earliestUsefulChild = childAfter(earliestUsefulChild);
        leadingChildrenWithoutLayoutOffset += 1;
      }
      // We should be able to destroy children with null layout offset safely,
      // because they are likely outside of viewport
      collectGarbage(leadingChildrenWithoutLayoutOffset, 0);
      // If can not find a valid layout offset, start from the initial child.
      if (firstChild == null) {
        if (!addInitialChild()) {
          // There are no children.
          geometry = unboundedGeometry(SliverGeometry.zero);
          childManager.didFinishLayout();
          return;
        }
      }
    }

    // Find the last child that is at or before the scrollOffset.
    earliestUsefulChild = firstChild;
    for (double earliestScrollOffset = childScrollOffset(earliestUsefulChild!)!;
        earliestScrollOffset > scrollOffset;
        earliestScrollOffset = childScrollOffset(earliestUsefulChild)!) {
      // We have to add children before the earliestUsefulChild.
      earliestUsefulChild =
          insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);
      updateUnboundedSize(earliestUsefulChild);
      if (earliestUsefulChild == null) {
        final SliverMultiBoxAdaptorParentData childParentData =
            firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
        childParentData.layoutOffset = 0.0;

        if (scrollOffset == 0.0) {
          // insertAndLayoutLeadingChild only lays out the children before
          // firstChild. In this case, nothing has been laid out. We have
          // to lay out firstChild manually.
          firstChild!.layout(childConstraints, parentUsesSize: true);
          earliestUsefulChild = firstChild;
          updateUnboundedSize(earliestUsefulChild);
          leadingChildWithLayout = earliestUsefulChild;
          trailingChildWithLayout ??= earliestUsefulChild;
          break;
        } else {
          // We ran out of children before reaching the scroll offset.
          // We must inform our parent that this sliver cannot fulfill
          // its contract and that we need a scroll offset correction.
          geometry = unboundedGeometry(SliverGeometry(
            scrollOffsetCorrection: -scrollOffset,
          ));
          return;
        }
      }

      final double firstChildScrollOffset =
          earliestScrollOffset - paintExtentOf(firstChild!);
      // firstChildScrollOffset may contain double precision error
      if (firstChildScrollOffset < -precisionErrorTolerance) {
        // Let's assume there is no child before the first child. We will
        // correct it on the next layout if it is not.
        geometry = unboundedGeometry(SliverGeometry(
          scrollOffsetCorrection: -firstChildScrollOffset,
        ));
        final SliverMultiBoxAdaptorParentData childParentData =
            firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
        childParentData.layoutOffset = 0.0;
        return;
      }

      final SliverMultiBoxAdaptorParentData childParentData =
          earliestUsefulChild.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = firstChildScrollOffset;
      assert(earliestUsefulChild == firstChild);
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout ??= earliestUsefulChild;
    }

    assert(childScrollOffset(firstChild!)! > -precisionErrorTolerance);

    // If the scroll offset is at zero, we should make sure we are
    // actually at the beginning of the list.
    if (scrollOffset < precisionErrorTolerance) {
      // We iterate from the firstChild in case the leading child has a 0 paint
      // extent.
      while (indexOf(firstChild!) > 0) {
        final double earliestScrollOffset = childScrollOffset(firstChild!)!;
        // We correct one child at a time. If there are more children before
        // the earliestUsefulChild, we will correct it once the scroll offset
        // reaches zero again.
        earliestUsefulChild =
            insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);
        updateUnboundedSize(earliestUsefulChild);
        assert(earliestUsefulChild != null);
        final double firstChildScrollOffset =
            earliestScrollOffset - paintExtentOf(firstChild!);
        final SliverMultiBoxAdaptorParentData childParentData =
            firstChild!.parentData! as SliverMultiBoxAdaptorParentData;
        childParentData.layoutOffset = 0.0;
        // We only need to correct if the leading child actually has a
        // paint extent.
        if (firstChildScrollOffset < -precisionErrorTolerance) {
          geometry = unboundedGeometry(SliverGeometry(
            scrollOffsetCorrection: -firstChildScrollOffset,
          ));
          return;
        }
      }
    }

    // At this point, earliestUsefulChild is the first child, and is a child
    // whose scrollOffset is at or before the scrollOffset, and
    // leadingChildWithLayout and trailingChildWithLayout are either null or
    // cover a range of render boxes that we have laid out with the first being
    // the same as earliestUsefulChild and the last being either at or after the
    // scroll offset.

    assert(earliestUsefulChild == firstChild);
    assert(childScrollOffset(earliestUsefulChild!)! <= scrollOffset);

    // Make sure we've laid out at least one child.
    if (leadingChildWithLayout == null) {
      earliestUsefulChild!.layout(childConstraints, parentUsesSize: true);
      updateUnboundedSize(earliestUsefulChild);
      leadingChildWithLayout = earliestUsefulChild;
      trailingChildWithLayout = earliestUsefulChild;
    }

    // Here, earliestUsefulChild is still the first child, it's got a
    // scrollOffset that is at or before our actual scrollOffset, and it has
    // been laid out, and is in fact our leadingChildWithLayout. It's possible
    // that some children beyond that one have also been laid out.

    bool inLayoutRange = true;
    RenderBox? child = earliestUsefulChild;
    int index = indexOf(child!);
    double endScrollOffset = childScrollOffset(child)! + paintExtentOf(child);
    bool advance() {
      // returns true if we advanced, false if we have no more children
      // This function is used in two different places below, to avoid code duplication.
      assert(child != null);
      if (child == trailingChildWithLayout) inLayoutRange = false;
      child = childAfter(child!);
      if (child == null) inLayoutRange = false;
      index += 1;
      if (!inLayoutRange) {
        if (child == null || indexOf(child!) != index) {
          // We are missing a child. Insert it (and lay it out) if possible.
          child = insertAndLayoutChild(
            childConstraints,
            after: trailingChildWithLayout,
            parentUsesSize: true,
          );
          updateUnboundedSize(child);
          if (child == null) {
            // We have run out of children.
            return false;
          }
        } else {
          // Lay out the child.
          child!.layout(childConstraints, parentUsesSize: true);
          updateUnboundedSize(child!);
        }
        trailingChildWithLayout = child;
      }
      assert(child != null);
      final SliverMultiBoxAdaptorParentData childParentData =
          child!.parentData! as SliverMultiBoxAdaptorParentData;
      childParentData.layoutOffset = endScrollOffset;
      assert(childParentData.index == index);
      endScrollOffset = childScrollOffset(child!)! + paintExtentOf(child!);
      return true;
    }

    // Find the first child that ends after the scroll offset.
    while (endScrollOffset < scrollOffset) {
      leadingGarbage += 1;
      if (!advance()) {
        assert(leadingGarbage == childCount);
        assert(child == null);
        // we want to make sure we keep the last child around so we know the end scroll offset
        collectGarbage(leadingGarbage - 1, 0);
        assert(firstChild == lastChild);
        final double extent =
            childScrollOffset(lastChild!)! + paintExtentOf(lastChild!);
        geometry = unboundedGeometry(
          SliverGeometry(
            scrollExtent: extent,
            paintExtent: 0.0,
            maxPaintExtent: extent,
          ),
        );
        return;
      }
    }

    // Now find the first child that ends after our end.
    while (endScrollOffset < targetEndScrollOffset) {
      if (!advance()) {
        reachedEnd = true;
        break;
      }
    }

    // Finally count up all the remaining children and label them as garbage.
    if (child != null) {
      child = childAfter(child!);
      while (child != null) {
        trailingGarbage += 1;
        child = childAfter(child!);
      }
    }

    // At this point everything should be good to go, we just have to clean up
    // the garbage and report the geometry.

    collectGarbage(leadingGarbage, trailingGarbage);

    assert(debugAssertChildListIsNonEmptyAndContiguous());
    double estimatedMaxScrollOffset;
    if (reachedEnd) {
      estimatedMaxScrollOffset = endScrollOffset;
    } else {
      estimatedMaxScrollOffset = childManager.estimateMaxScrollOffset(
        constraints,
        firstIndex: indexOf(firstChild!),
        lastIndex: indexOf(lastChild!),
        leadingScrollOffset: childScrollOffset(firstChild!),
        trailingScrollOffset: endScrollOffset,
      );
      assert(estimatedMaxScrollOffset >=
          endScrollOffset - childScrollOffset(firstChild!)!);
    }
    final double paintExtent = calculatePaintOffset(
      constraints,
      from: childScrollOffset(firstChild!)!,
      to: endScrollOffset,
    );
    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: childScrollOffset(firstChild!)!,
      to: endScrollOffset,
    );
    final double targetEndScrollOffsetForPaint =
        constraints.scrollOffset + constraints.remainingPaintExtent;
    geometry = unboundedGeometry(
      SliverGeometry(
        scrollExtent: estimatedMaxScrollOffset,
        paintExtent: paintExtent,
        cacheExtent: cacheExtent,
        maxPaintExtent: estimatedMaxScrollOffset,
        // Conservative to avoid flickering away the clip during scroll.
        hasVisualOverflow: endScrollOffset > targetEndScrollOffsetForPaint ||
            constraints.scrollOffset > 0.0,
      ),
    );

    // We may have started the layout while scrolled to the end, which would not
    // expose a new child.
    if (estimatedMaxScrollOffset == endScrollOffset)
      childManager.setDidUnderflow(true);
    childManager.didFinishLayout();
  }
}
```

别看上面这段代码很长，其实很多都是 `RenderSliverList`  自己的源码，如下图所示，真正我们修改添加的只有这么点：

- 在开始前增加 `updateUnboundedSize` 和  `unboundedGeometry` 用于记录布局高度和生成 `UnboundedSliverGeometry` 
- 将所有原来的 `SliverGeometry ` 修改为 `UnboundedSliverGeometry`  
- 在所有涉及 `layout` 的位置后面调用  `updateUnboundedSize` ，因为 child 在布局之后我们就可以获取到它的 `Size` ，然后我们统计得到他们的最大值，就可以通过 `UnboundedSliverGeometry` 返回给 `ViewPort` 。

![](http://img.cdn.guoshuyu.cn/20230425_N24/image7.png)

最后如下代码所示，将 `UnboundedListView` 添加到一开始的垂直 `ListView `里，运行之后可以看到，随着横向滑动，列表的自身高度在发生变化。

```dart
return Scaffold(
  appBar: AppBar(
    title: new Text("ControllerDemoPage"),
  ),
  extendBody: true,
  body: Container(
    color: Colors.white,
    child: ListView(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              children: List<Widget>.generate(50, (index) {
                return Padding(
                  padding: EdgeInsets.all(2),
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    color: Colors.blue,
                    child: Text(List.generate(
                            math.Random().nextInt(10), (index) => "TEST\n")
                        .toString()),
                  ),
                );
              }),
            ),
          ),
        ),
        UnboundedListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 100,
            itemBuilder: (context, index) {
              print('$index');
              return Padding(
                padding: EdgeInsets.all(2),
                child: Container(
                  height: index * 1.0 + 10,
                  width: 50,
                  color: Colors.blue,
                ),
              );
            }),
        Container(
          height: 1000,
          color: Colors.green,
        ),
      ],
    ),
  ),
);
```



![](http://img.cdn.guoshuyu.cn/20230425_N24/image8.gif)

那么这是否达到了我们的需求？如下代码所示，假如我将代码修改成如下所示，运行之后可以看到，此时的横向列表变成了参差不齐的状态。

```dart
UnboundedListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: 100,
    itemBuilder: (context, index) {
      print('$index');
      return Container(
        padding: EdgeInsets.all(2),
        child: Container(
          width: 50,
          color: Colors.blue,
          alignment: Alignment.bottomCenter,
          child: Text(List.generate(
                  math.Random().nextInt(15), (index) => "TEST\n")
              .toString()),
        ),
      );
    }),
```



![](http://img.cdn.guoshuyu.cn/20230425_N24/image9.png)

但是这时候我们无法用类似 `IntrinsicHeight`  的方式来解决，因为 `ListView` 里的 Item 都是动态处理的，**也就是布局时需要处理特定便宜范围内的 Item 添加和销毁**，具体在 `performLayout` 里会通过 `scrollOffset` 和 `targetEndScrollOffset`  等来确定布局 Item 的范围。

> 这样就导致我们通过 `firstChild` 链表结构去访问的时候，我们无法在 `layout` 之前获取到 child ，因为此时它还没有被 add 到链表里，同时也受限于 `insertAndLayoutLeadingChild` 和  `insertAndLayoutChild` 的耦合实现和私有方法限制，这里不方便简单重写支持。

但是「天无绝人之路」，既然我们不能在 child `layout`  之前处理，那么我们可以在 `layout`  之后做多一次冗余布局，如下代码所示：

- 我们首先将 `unboundedSize` 提取为 `UnboundedRenderSliverList` 里的全局变量
- 在 `didFinishLayout` 之前，通过  `firstChild` 链表结构，重新通过 `layout(childConstraints.tighten(height: unboundedSize)`  布局多一次

```dart
  double unboundedSize = 0;

  // See RenderSliverList::performLayout
  @override
  void performLayout() {

    ····
    var tmpChild = firstChild;
    while (tmpChild != null) {
      tmpChild.layout(childConstraints.tighten(height: unboundedSize),
          parentUsesSize: true);
      tmpChild = childAfter(tmpChild);
    }

    childManager.didFinishLayout();
    ····
  }
```

运行之后可以看到，此时列表已经全部对齐，而损耗就是 child 会有 double 布局的情况，对于此处性能损耗，对比  `SingleChildScrollView` 的实现，可以根据实际场景来取舍使用哪种逻辑，**当然，为了性能考虑非必要还是给横向 `ListView` 一个高度，这样的实现才是最优解**。

![](http://img.cdn.guoshuyu.cn/20230425_N24/image10.png)

好了，本篇小技巧到这里就解决了，不知道对于类似实现，你是否还有什么想法，如果你有更好的解决方案，欢迎留言讨论。

> 完整代码可见：https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/un_bounded_listview.dart