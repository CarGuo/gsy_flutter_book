# Flutter 小技巧之  OverlayPortal  实现自限性和可共享的页面图层

大家对于 Overlay 可能不会陌生，那么 `OverlayPortal` 呢？

在 Flutter 中可以通过向 `MaterialApp`  下的  `Overlay` 添加“图层”，来实现比如「增加一个全局悬浮控件」或者「页面指引」之类的实现，这是因为 `Overlay`  在 Flutter 里类似于一个“图层管理器”，它的内部有一个 `_Theater`（剧院），默认情况下每个「Route 页面」都是通过  `OverlayEntry`  被加入到“剧院”里去展示。

![](http://img.cdn.guoshuyu.cn/20241107_vp/image1.gif)

例如我们常用的 `Navigator`  其实就是使用了 `Overlay` 来承载「路由页面」，**每个打开的 `Route` 默认情况下是向 `Overlay`  插入 `OverlayEntry`** 来增加“图层”，每个  `OverlayEntry`  在层级上互相独立，这也是买个 Route 互不影响的原因之一。

![](http://img.cdn.guoshuyu.cn/20241107_vp/image2.png)

> 感兴趣可以看以前的老文章 [《Flutter 的导航解密和性能提升》](https://juejin.cn/post/6844904183028514824)

也就是说，之前我们一般都是通过  `Overlay`  和  `OverlayEntry`  来实现增加新图层的需要，那这次提到的  `OverlayPortal` 又是什么东西？

**事实上 `OverlayPortal`  也是用来向   `Overlay`   添加图层的实现，但是它和  `OverlayEntry`   又有很大不一样，最大的不一样在于它的「可共享页面状态」和「具有页面自限性」**。

前面我们聊到，因为每个  `OverlayEntry`  在  `Overlay`  下都是平级且“互不影响”，所以当你在页面 A 内唤起一个 新的   `OverlayEntry`  B ， 那么 A 是没办法直接通过 InheritedWidget 共享各种状态，因为新的  `OverlayEntry` B 不属于页面 A ，而是互为平级的   `OverlayEntry` ，例如下方 `Text('Hello')` 无法共享“隔壁”的 `Theme` 。

![](http://img.cdn.guoshuyu.cn/20241107_vp/image3.png)

那么  `OverlayPortal`  就不一样了，**它可以做到「状态和父级相关联」，但是「在图层结构上又相互独立」**，从而实现更简单的页面内「屏幕图层」操作，比如页面内的浮动窗口，弹出框等。

> Flutter 内置的 `OverlayPortal` 是受到 flutter_portal 的启发，在去年的 [flutter/flutter#105335](https://github.com/flutter/flutter/pull/105335) 中合并 。

举个例子，如下代码所示：

- 在页面内定义了一个 `DefaultTextStyle` 用于往下共享修改后的全局文本样式 `fontSize: 20` 
- 增加一个 `OverlayPortal` 并绑定  `OverlayPortalController` 用于控制 show 或者 hide 
- 在  `overlayChildBuilder`  里返回一个「提示文本」，「提示文本」可以随机出现在屏幕任何位置
- 添加 child 显示一个正常的 `Text` 文本
- 点击 `onPressed` 通过 `_tooltipController.toggle` 显示和隐藏「提示文本」 

```dart
class ClickableTooltipWidgetState extends State<ClickableTooltipWidget> {
  final OverlayPortalController _tooltipController = OverlayPortalController();

  final Random random = Random();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 300,
      decoration: BoxDecoration(
          color: Colors.blue, borderRadius: BorderRadius.circular(10)),
      child: TextButton(
        ///点击 OverlayPortalController 实现展示和隐藏
        onPressed: _tooltipController.toggle,
        child: DefaultTextStyle(
          //// 共享了 DefaultTextStyle 的 fontSize: 20 修改
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 20),
          /// 使用了 OverlayPortal 
          child: OverlayPortal(
            controller: _tooltipController,
            /// 通过 overlayChildBuilder 增加图层
            overlayChildBuilder: (BuildContext context) {
              return Positioned(
                right: random.nextInt(200).toDouble(),
                bottom: random.nextInt(500).toDouble(),
                child: const ColoredBox(
                  color: Colors.amberAccent,
                  child: Text('Text Everyone Wants to See'),
                ),
              );
            },
            /// 页面内的 child 
            child: const Text('Press to show/hide'),
          ),
        ),
      ),
    );
  }
}
```

可以看到，在点击屏幕中间的按键之后， `overlayChildBuilder`  内的「提示文本」可以随意在屏幕任意位置出现和隐藏，也就是：

- 「提示文本」的布局和绘制不受页面 `Container` 的布局约束，因为它是被加入到  `Overlay` 到“独立图层”
- 「提示文本」的样式继承了   `DefaultTextStyle` 往下共享的样式，所以它的状况又可以和当前页面渲染树同步。

![](http://img.cdn.guoshuyu.cn/20241107_vp/image4.gif)

再举个例子，比如在  `OverlayPortal` 显示 「提示文本」 文本的时候，我们关掉页面，此时因为   `OverlayPortal`  和页面是相关联的，所以它会被“直接销毁”，这也是它页面自限性的体现：

![](http://img.cdn.guoshuyu.cn/20241107_vp/image5.gif)

那到这里，有没有觉得「很神奇」，  `OverlayPortal`  是如何做到状态和父级相关联，但是在图层结构上又相互独立的呢？

简单来说就是这样一张图，它通过 `_RenderLayoutSurrogateProxyBox`  存在页面 tree 里面，但是又通过 `_RenderDeferredLayoutBox`  “布局和绘制” 在全局的 `OverLay` 里：

![](http://img.cdn.guoshuyu.cn/20241107_vp/image6.png)

就是一个  `OverlayPortal` 内部都有这两个实现对象：

- 每个页面的 `OverlayEntry`  都有持有一个 `LinkedList<_OverlayEntryLocation> _sortedTheaterSiblings`  的列表

- 每个有   `OverlayPortal`  显示就会有一个  `_OverlayEntryLocation` ，它相当于是一个 `slot` ，  `OverlayPortal#overlayChildBuilder`  相当于是向当前页面的  `OverlayEntry`   的 `_sortedTheaterSiblings`  添加了一个   `_OverlayEntryLocation` 
- 最后这个 slot 会通过如  `_theater._addDeferredChild(child);` 触发布局更新

![](http://img.cdn.guoshuyu.cn/20241107_vp/image7.png)

再稍微捋一捋，大概就是：  **`OverlayPortal#overlayChildBuilder`   的最终布局和绘制，其实都是通过 `Overlay` 的内部统一的  `_Theater`（剧院）完成，所以它在这个层面上其实和   `OverlayEntry`  相似，只是 `Overlay` 是通过 `slot`  等方式 “间接” 参与，本身它还是存在于页面的 tree 下面**。

![](http://img.cdn.guoshuyu.cn/20241107_vp/image8.png)

而从层级上来说：

- 在 Overlay 中， `OverlayPortal` 通常位于最靠近它的 `OverlayEntry`(一般就是页面 Route) 之后，并在下一个 `OverlayEntry` 之前，所以它可以存在于当前页面任意位置，又不会遮挡到下一个页面

  ![](http://img.cdn.guoshuyu.cn/20241107_vp/image9.gif)



- 当 `OverlayEntry` 具有多个关联的 `OverlayPortal` 时，它们之间的绘制顺序是调用 `verlayPortalController.show` 的顺序

所以可以看到， **`OverlayPortal`  主要是为我们补充了「页面内全局图层」的场景，因为它可以做到状态和父级相关联，但是在图层结构上又相互独立** ，适当使用  `OverlayPortal`   替代   `OverlayEntry`  ，可以让我们更灵活搭配各种页面内的渲染场景，比如图层，指引，甚至通过局部图层来实现切换动画：

![](http://img.cdn.guoshuyu.cn/20241107_vp/image10.gif)

当然，这个动画怎么实现，那就是另外一个故事了： [《Shader 实现酷炫的粒子动画》](https://juejin.cn/post/7435659292868476964)





