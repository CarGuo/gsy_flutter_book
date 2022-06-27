# Flutter 小技巧之有趣的动画技巧

**本篇分享一个简单轻松的内容： 剖析 Flutter 里的动画技巧** ，首先我们看下图效果，如果要实现下面的动画切换效果，你会想到如何实现？



![](http://img.cdn.guoshuyu.cn/20220619_N4/image1.gif)



# 动画效果

事实上 Flutter 里实现类似的动画效果很简单，甚至不需要自定义布局，只需要通过官方的内置控件就可以轻松实现。

首先我们需要使用 `AnimatedPositioned` 和  `AnimatedContainer` ：

- `AnimatedPositioned`  用于在 `Stack` 里实现位移动画效果
- `AnimatedContainer` 用于实现大小变化的动画效果

接着我们定义一个 `PositionItem` ，将 `AnimatedPositioned` 和 `AnimatedContainer` 嵌套在一起，并且通过 `PositionedItemData` 用于改变它们的位置和大小。

```dart
class PositionItem extends StatelessWidget {
  final PositionedItemData data;
  final Widget child;

  const PositionItem(this.data, {required this.child});

  @override
  Widget build(BuildContext context) {
    return new AnimatedPositioned(
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
      child: new AnimatedContainer(
        duration: Duration(seconds: 1),
        curve: Curves.fastOutSlowIn,
        width: data.width,
        height: data.height,
        child: child,
      ),
      left: data.left,
      top: data.top,
    );
  }
}
class PositionedItemData {
  final double left;
  final double top;
  final double width;
  final double height;

  PositionedItemData({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
```

之后我们只需要把 `PositionItem` 放到通过 `Stack`  下，然后通过 `LayoutBuilder` 获得 `parent` 的大小，根据 `PositionedItemData` 调整 `PositionItem` 的位置和大小，就可以轻松实现开始的动画效果。

```dart
child: LayoutBuilder(
  builder: (_, con) {
    var f = getIndexPosition(currentIndex % 3, con.biggest);
    var s = getIndexPosition((currentIndex + 1) % 3, con.biggest);
    var t = getIndexPosition((currentIndex + 2) % 3, con.biggest);
    return Stack(
      fit: StackFit.expand,
      children: [
        PositionItem(f,
            child: InkWell(
              onTap: () {
                print("red");
              },
              child: Container(color: Colors.redAccent),
            )),
        PositionItem(s,
            child: InkWell(
              onTap: () {
                print("green");
              },
              child: Container(color: Colors.greenAccent),
            )),
        PositionItem(t,
            child: InkWell(
              onTap: () {
                print("yello");
              },
              child: Container(color: Colors.yellowAccent),
            )),
      ],
    );
  },
),
```

如下图所示，只需要每次切换对应的 index ，便可以调整对应 Item 的大小和位置发生变化，从而触发  `AnimatedPositioned` 和 `AnimatedContainer` 产生动画效果，达到类似开始时动图的动画效果。

| 计算大小                                                     | 效果                                                       |
| ------------------------------------------------------------ | ---------------------------------------------------------- |
| ![image-20220611180815516](http://img.cdn.guoshuyu.cn/20220619_N4/image2.png) | ![6666](http://img.cdn.guoshuyu.cn/20220619_N4/image3.gif) |

>  完整代码可见： https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/anim_switch_layout_demo_page.dart

如果你对于实现原理没兴趣，那到这里就可以结束了，通过上面你已经知道了一个小技巧：

> **改变  `AnimatedPositioned` 和 `AnimatedContainer`  的任意参数，就可以让它们产生动画效果**，而它们的参数和  `Positioned` 与 `Container`  一模一样，所以使用起来可以无缝替换  `Positioned` 与 `Container` ，只需要简单配置额外的  `duration` 等参数。

# 进阶学习

**那  `AnimatedPositioned` 和 `AnimatedContainer`  是如何实现动画效果 ？这里就要介绍一个抽象父类 `ImplicitlyAnimatedWidget`** 。

> 几乎所有 Animated 开头的控件都是继承于它，既然是用于动画 ，那么 `ImplicitlyAnimatedWidget` 就肯定是一个 `StatefulWidget` ，那么不出意外，它的实现逻辑主要在于 `ImplicitlyAnimatedWidgetState` ，而我们后续也会通过它来展开。

首先我们回顾一下，一般在 Flutter 使用动画需要什么：

- `AnimationController` ： 用于控制动画启动、暂停
- `TickerProvider`  ： 用于创建  `AnimationController`  所需的  `vsync`  参数，一般最常使用 `SingleTickerProviderStateMixin`
- `Animation` ： 用于处理动画的 value ，例如常见的 `CurvedAnimation` 
- 接收动画的对象：例如 `FadeTransition` 

简单来说，Flutter 里的动画是从 `Ticker` 开始，当我们在 `State` 里 `with TickerProviderStateMixin`  之后，就代表了具备执行动画的能力：

> 每次 Flutter 在绘制帧的时候，`Ticker` 就会同步到执行  ` AnimationController` 里的  `_tick` 方法，然后执行 `notifyListeners`  ，改变 `Animation`  的 value，从而触发 State 的  `setState` 或者 RenderObject 的  `markNeedsPaint` 更新界面。

举个例子，如下代码所示，可以看到实现一个简单动画效果所需的代码并不少，而且**这部分代码重复度很高，所以针对这部分逻辑，官方提供了 `ImplicitlyAnimatedWidget` 模版**。

```dart
class _AnimatedOpacityState extends State<AnimatedOpacity>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat(reverse: true);
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: FadeTransition(
        opacity: _animation,
        child: const Padding(padding: EdgeInsets.all(8), child: FlutterLogo()),
      ),
    );
  }
}
```

例如上面的 Fade 动画，换成 `ImplicitlyAnimatedWidgetState` 只需要实现 `forEachTween` 方法和  `didUpdateTweens` 方法即可，而不再需要关心 `AnimationController` 和 `CurvedAnimation` 等相关内容。

```dart
class _AnimatedOpacityState extends ImplicitlyAnimatedWidgetState<AnimatedOpacity> {
  Tween<double>? _opacity;
  late Animation<double> _opacityAnimation;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _opacity = visitor(_opacity, widget.opacity, (dynamic value) => Tween<double>(begin: value as double)) as Tween<double>?;
  }

  @override
  void didUpdateTweens() {
    _opacityAnimation = animation.drive(_opacity!);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      alwaysIncludeSemantics: widget.alwaysIncludeSemantics,
      child: widget.child,
    );
  }
}
```

**那  `ImplicitlyAnimatedWidgetState` 是如何做到改变 `opacity` 就触发动画？** 

关键还是在于实现的 `forEachTween` ：当  `opacity` 被更新时，`forEachTween` 会被调用，这时候内部会通过 `_shouldAnimateTween` 判断值是否更改，如果目标值已更改，就执行基类里的  `AnimationController.forward` 开始动画。

![image-20220611170418125](http://img.cdn.guoshuyu.cn/20220619_N4/image4.png)

> 这里补充一个内容：`FadeTransition` 内部会对  `_opacityAnimation` 添加兼容，当   `AnimationController`   开始执行动画的时候，就会触发   `_opacityAnimation`  的监听，从而执行  `markNeedsPaint` ，**而如下图所示， `markNeedsPaint` 最终会触发 RenderObject 的重绘**。

![image-20220611173533772](http://img.cdn.guoshuyu.cn/20220619_N4/image5.png)

所以到这里，我们知道了：**通过继承  `ImplicitlyAnimatedWidget` 和   `ImplicitlyAnimatedWidgetState` 我们可以更方便实现一些动画效果，Flutter 里的很多默认动画效果都是通过它实现**。

> 另外   `ImplicitlyAnimatedWidget` 模版里，除了   `ImplicitlyAnimatedWidgetState`  ，官方还提供了另外一个子类 `AnimatedWidgetBaseState`。

事实上 Flutter 里我们常用的 Animated 都是通过   `ImplicitlyAnimatedWidget`  模版实现，如下图所示是 Flutter 里常见的  Animated  分别继承的  State ：

| `ImplicitlyAnimatedWidgetState`                              | `AnimatedWidgetBaseState`                                    |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| ![image-20220611194943083](http://img.cdn.guoshuyu.cn/20220619_N4/image6.png) | ![image-20220611195244152](http://img.cdn.guoshuyu.cn/20220619_N4/image7.png) |

关于这两个 State 的区别，简单来说可以理解为：

- `ImplicitlyAnimatedWidgetState`  里主要是配合各类 `*Transition` 控件使用，比如：  `AnimatedOpacity`里使用了 `FadeTransition` 、`AnimatedScale` 里使用了 `ScaleTransition`  ，**因为 `ImplicitlyAnimatedWidgetState`   里没有使用 setState，而是通过触发 RenderObject 的  `markNeedsPaint` 更新界面。**

- **`AnimatedWidgetBaseState` 在原本 `ImplicitlyAnimatedWidgetState`   的基础上增加了自动 `setState` 的监听**，所以可以做一些更灵活的动画，比如前面我们用过的   `AnimatedPositioned` 和 `AnimatedContainer`   。

  ![image-20220611164819853](http://img.cdn.guoshuyu.cn/20220619_N4/image8.png)

其实 `AnimatedContainer`  本身就是一个很具备代表性的实现，如果你去看它的源码，就可以看到它的实现很简单，**只需要在 `forEachTween` 里实现参数对应的 `Tween`  实现即可**。

![image-20220611200938194](http://img.cdn.guoshuyu.cn/20220619_N4/image9.png)

例如前面我们改变的 `width` 和 `height` ，其实就是改变了`Container` 的  `BoxConstraints` ，所以对应的实现也就是 `BoxConstraintsTween` ，**而  `BoxConstraintsTween`  继承了 `Tween` ，主要是实现了  `Tween` 的 `lerp` 方法**。

![image-20220611201159887](http://img.cdn.guoshuyu.cn/20220619_N4/image10.png)

在 Flutter 里 `lerp` 方法是用于实现插值：例如就是在动画过程中，在 `beigin` 和 `end` 两个 `BoxConstraint`  之间进行线性插值，其中 t 是动画时钟值下的变化值，例如：

> 计算出 100x100 到 200x200 大小的过程中需要的一些中间过程的尺寸。

如下代码所示，通过继承 `AnimatedWidgetBaseState` ，然后利用  `ColorTween` 的  `lerp`  ，就可以很快实现如下文字的渐变效果。

| 代码                                                         | 效果                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| ![image-20220611203715556](http://img.cdn.guoshuyu.cn/20220619_N4/image11.png) | ![66644](http://img.cdn.guoshuyu.cn/20220619_N4/image12.gif) |

# 总结

最后总结一下，本篇主要介绍了：

- 利用  `AnimatedPositioned` 和 `AnimatedContainer`  快速实现切换动画效果
- 介绍  `ImplicitlyAnimatedWidget` 和如何使用  ``ImplicitlyAnimatedWidgetState`  /    `AnimatedWidgetBaseState` 简化实现动画的需求，并且快速实现自定义动画。

那么，你还有知道什么使用 Flutter 动画的小技巧吗？