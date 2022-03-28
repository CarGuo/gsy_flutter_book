> hello 大家好，我是《Flutter开发实战详解》的作者郭树煜，看标题就知道今天我要给大家分享的是 Flutter 相关的主题，分享内容是也比较直接简单，就是关于 **Flutter 布局相关的知识点**。

相信大家可能都听说过或者用过 Flutter ，对这部分内容可能有一定了解，但是正如标题所示，本次的主题是带你了解不一样的 Flutter ，**或者说经常性被萌新忽略的东西** ，所以这次将通过不一样的角度，带你看看 Flutter 的尺寸布局有趣的地方。


## 一、开始之前

在聊 Flutter 的布局之前，*首先大家觉得 Flutter 是什么？*

**Flutter 其实主要是跨平台的 UI 框架，它核心能力是解决 UI 的跨平台**，和别的跨平台框架不一样的地方在于：**它在性能接近原生的同时，做到了控件和平台无关的实现**。


但如果大家用过 Flutter ，应该知道 Flutter 里的我们写的界面都是通过 `Widget` 完成，并且可能会看起来嵌套得很多层，为什么呢？

这里就要先简单说一下 Flutter 的一些基础信息，**在 Flutter 里有 `Widget` 、 `Element`、 `RenderObject` 、 `Layer` 等关键的核心设定**。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image1)

其中我们最常写的 **`Widget` 并不是真正的 View 实例**，它需要转化为对应的 `RenderObject ` 才能绘制，而 `Element` 是 `Widget` 和 `RenderObject` 关键的中间实例，我们日常 Flutter 开发里用到的 **`BuildContext` 就是 `Element` 的抽象对象**。

> 也就是大致 `Widget` -> `Element` -> `RenderObject` 这样的过程。

**所以在 Flutter 里 `Widget` 代码只是“配置文件”的作用，真正工作的实例是它内部对应的 `Element` 和 `RenderObject` 实体**。

这也是 `Widget` 为什么可以是不可变的原因，它可以在使用时的被频繁构建，因为它不是真正干活的，**`Widget` 承载的是 `RenderObject` 里绘制时需要的各种状态信息**。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image2)


这里举个简单例子，如图代码所示，我们定义了一个 text 的 Widget，然后分别在 4 个地方添加，并成功运行，如果是一个真正的 View ，是不可以同时在 4 个地方被加载。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image3)


通过这个例子可以看到 `Widget` 并不是真正干活的，而主要负责绘制和布局的逻辑都在 `RenderObject` 。 **因为布局和绘制的主要逻辑都在 `RenderObject` ，所以今天我们主要的内容也是在 `RenderObject`**。

在 Flutter 里 `RenderObject` 作为绘制和布局的实体，主要可以分为两大子类：`RenderBox` 和 `RenderSliver` ，其中 `RenderSliver` 主要是在可滑动列表这种场景中使用，所以本次我们主要讨论的是 `RenderBox` 这种布局场景。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image4)

## 二、Flutter 的布局


**一般情况 Flutter 里的大小布局是从上往下传递 `Constraints` ，从下往上返回 `Size` 这样的流程**。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image5)

简单理解这句话就是：父容器根据布局需要往下传递一个约束信息，而最子容器会根据自己的状态返回一个明确的大小，如果自己没有就继续往下的 child 递归。


> 更粗旷一些说就是：从上往下传递约束，传入的约束一般是有 `minHeight`、 `maxHeight` 、 `minWidth` 和 `maxWidth` 等等，但是从下往上返回的 size 时，就会是一个固定 `width` 和 `height` 尺寸。

而对于 Flutter ，**布局的逻辑主要在对应 `RenderObject` 的 `performLayout`**。

> 所以一般如果对于 `Widget` 的布局感兴趣或者有疑惑，就可以先找到这个 `Widget` 的 `RednerObject` ，看这个 `RednerObject` 的 `performLayout` 逻辑是怎么实现。

在 Flutter 最常用的就是应是 `Container` 了， `Container` 作为 Flutter 里最常用的抽象配置模版，它在宽高布局这一块用的是 `ConstrainedBox`，而不管是 `ConstrainedBox` 还是  `SizedBox`， 他们对应的 `RenderObject` 都是 `RenderConstrainedBox`。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image6)

**所以我们就以 `RenderConstrainedBox` 相关的例子来举例**，看看 `ConstrainedBox` 是如何大小布局。

### 2.1、ConstrainedBox 的约束布局

如下代码所示，可以看到 `ColoredBox` 没有指定大小，但是运行后 `ColoredBox` 得到的是一个 100 x 100 的红色正方形， 因为它的父级 `ConstrainedBox` 往下传递的是 100 x 100 大小的 `ConstrainedBox` 约束。


```dart
Scaffold(
  body: Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: 100, minHeight: 100, maxWidth: 100, minWidth: 100),
      child: ColoredBox(
        color: Colors.red,
      ),
    ),
  ),
)
```

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image7)


那如果这时候，把 `min` 的宽高改为 10 会发生什么事？

可以看到此时 `ColoredBox` 的大小变成和 `min` 的宽高一样大，为什么呢？


```dart
Scaffold(
  body: Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: 100, minHeight: 10, maxWidth: 100, minWidth: 10),
      child: ColoredBox(
        color: Colors.red,
      ),
    ),
  ),
)
```

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image8)

首先 `ColoredBox` 并没有实现自己的 `performLayout`，而是通过继承了 `RenderProxyBox` 默认的逻辑来实现，这种情况在 Flutter 里比较常见，可以看到默认 `RenderProxyBox` 下：

- **在没有 child 的时候，用的是 `constraints.smallest`** ，也就是传递下来约束的最小值宽高；
- 在有 child 的时候使用 child 的大小；

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image9)

所以我们知道了，当控件没有实现自定义的 `performLayout` 时，并且没有 child 时，它很可能就是跟着父级约束的 smallest 走。

继续测试，如果这时候给 `ColoredBox` 增加一个 80 的 child ，可以看到红色框变了，变成了 `ColoredBox` 的 child 的大小 80 而不是 smallest，因为这时候 `ColoredBox` 有了 child， 用的是 child 的大小。


```dart
Scaffold(
  body: Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: 100, minHeight: 10, maxWidth: 100, minWidth: 10),
      child: ColoredBox(
        color: Colors.red,
        child: SizedBox(
          width: 80,
          height: 80,
        ),
      ),
    ),
  ),
)
```


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image10)


那如果我把 `ColoredBox`  的 child 修改为 150 的大小呢？

可以看到运行后红色方块还是 100 的大小，并没有变成 150。

```dart
 Scaffold(
  body: Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: 100, minHeight: 10, maxWidth: 100, minWidth: 10),
      child: ColoredBox(
        color: Colors.red,
        child: SizedBox(
          width: 150,
          height: 150,
        ),
      ),
    ),
  ),
)
```


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image11)

这是为什么呢？

我们通过 Flutter 的调试工具看，可以看到我们虽然给 `SizedBox` 配置了 150 的参数，但是实际 `RenderConstrainedBox` 最终渲染时输出是 100 。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image12)

这里有两点：

- 第一就是 `Widget` 仅仅是作为配置信息，我们配置的宽高是 150 ，而实际 `RenderObject` 输出的是 100 ，所以我们写的并不是真实的 `View`， 真正的布局效果还是要看 `RenderObject` 的脸色；

-  从 `SizedBox` 的 `RenderConstrainedBox` 看， 它的 `performLayout` 的实现在没有 child时， 150 的大小会被 `enforce` 成 parent 的 100

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image13)

对应 `enforce` 内部是通过 `clamp` 这个 API 完成， `enforce` 执行效果等同于  `150.clamp(10, 100)`，所以会得到 100 的结果。

> `clamp` 便是如果数据时在区间内就返回该数值，否则返回离其最近的边界值。

**所以通过 enforce `RenderConstrainedBox` 不会超出父容器的大小。**

那么为了实验，我们接下来把 `SizeBox` 换成 `ConstrainedBox` ，并且调整为约束为 10 - 150  的大小。


```dart
Scaffold(
  body: Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: 100, minHeight: 10, maxWidth: 100, minWidth: 10),
      child: ColoredBox(
        color: Colors.red,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: 150, minHeight: 10, maxWidth: 150, minWidth: 10),
        ),
      ),
    ),
  ),
)
```

可以看到红色正方形又变成了 10 的大小，为什么呢？

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image14)

通过源码可以看到：

- 首先 `enforce` 执行是 `150.clamp(10, 100)` 和 `10.clamp(10, 100)` ，等到的自然就是 `10-100`；
- 之后再到 `constrain` 里 0.clamp(10, 100)，所以输出的是 10 这个最小值；

> 先前是 100.clamp(10, 100) 自然就是 100 的大小，而现在是 0.clamp(10, 100) ，自然就成了 10 。

从上面的例子，可以看到父布局约束影响 child 的大小的过程，甚至是变相局限住了 child 的大小返回，但是这都是在 `child.layout` 之后取得的大小。

**那如果想要在 child.layout 之前就获取到 child 的大小呢？也就是 child 布局之前就获取到 child 的大小？**

可以这样吗？当然可以！一般在官方的 RenderBox 都会有这四个方法：

- `computeMaxIntrinsicWidth`
- `computeMinIntrinsicWidth`
- `computeMaxIntrinsicHeight`
- `computeMinIntrinsicHeight`

为什么说一般呢？

因为你不写一般也不报错，并且这四个方法其实一般很少被调用，**官方对它的描述是开销昂贵**，并且我们调用时也不是直接调用它，而是通过对应的 get 方法：

- `getMaxIntrinsicWidth`
- `getMinIntrinsicWidth`
- `getMaxIntrinsicHeight`
- `getMinIntrinsicHeight`

在默认规范里，一般你只能 override `compute` 开头的 API 去实现需要的逻辑，然后调用只能通过 get 对应的方法去调用，最后会执行到 `compute` 开头的 API ，它们之间时一一对应的。

> 也就是通过 `getMinIntrinsicWidth` 来调用，比如：`child.getMinIntrinsicWidth` 最终调用到  `computeMinIntrinsicWidth`。


看到这里大家有没想过： **RenderBox 如何拿到 child ？child 如何从 Widget 变成 RenderObject?**

这里就是 Element 起到的作用，当 `Widget` 被加载时：

- 就会调用 `inflateWidget` 去创建它的 `Element`，然后通过 `mount` 用 `createRenderObject` 创建出它的 `RenderObject`；
- 之后再执行 `attachRenderObject `， 这时候这个 child 会通过  `_findAncestorRenderObjectElement` 去找到它的 parent ，也就是离他最近的一个 `RenderObjectElment`；
- 最后执行  parent  的 `insertRenderObjectChild` ，这时 child 就被插入进去 `RenderObject`，在 `RenderObject` 里就可以获取到 `Widget`；


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image15)


也就是 child 在 `Element` 里被加载后，创建出对应的 `RenderObject` ，并且找到自己的 parent 然后将自己加入进去。


> Flutter 既然有具备 `RenderObject` 的 `Element` ，那同样也就有没有  `RenderObject` 的 `Element` ，比如 `ComponentElement` ，也就是我们常用的  `StatelessWidget` 等。

**这里可以看到 Element 得连接作用**。

## 三、多个 Child 的布局

前面介绍了单个 Child 的布局，这里简单介绍下多个 Child 主要有什么不同。

其实多个 Child 和单个一样，都会是从上往下传递 `Constraints` ，从下往上返回 `Size` 这样的流程。

比如下图，这是我们前面看到的例子，这里使用了 `Column` 控件对多个 `Text` 进行布局。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image16)

而其实 `Column` 和 `Row` 都是 `Flex` 的子类，我们按照思路去看 `RenderFlex` 的实现，就可以看到，对于多个 Child 的布局主要有这么几个关键点：

- `MultiChildRenderObjectWidget`；
- `MultiChildRenderObjectElement`；
- `ParentData`；

`Widget` 和 `Element` 的逻辑我们这里暂时不深入展开，主要讲解不同的就是在 `RenderBox` 的 `ParentData`。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image17)

如上图所示，基本上所有 Multi Child 的实现都有自己特有的 `ParentData` ，并且他们还不是直接继承 `ParentData`， 而是继承他们的子类 `ContainterBoxParentData`。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image18)


如图所示，他们的作用就是：

- `BoxParentData` 具备 `Offset` 参数，是用来觉得 Child 在控件的位置；
- `ContainterBoxParentData` 带有两个 `Sibling` 参数，主要是 `RenderBox` 里访问 children 就是通过这个双链表的方式访问的；
- `FlexParentData` 就是当前 `RenderFlex` 布局所需的参数；


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image19)


可以看到这就是 `RenderFlex` 布局时关键的参数所在，我们添加的 children `Widget`，在经过 `Element` 加载后，在前面说过的 `insert` 步骤会从一个 `List<Widget>` 变成通过 `ParentData` 的两个 `Sibling` 参数连接在一起的双向链表，访问时就是通过它进行访问的。

**所以在 children 布局时，我们通过对应的 `ParentData` 子类返回 child，然后通过给 `ParentData` 配置 `Offset` 来决定 child 的位置**。


> 官方提供了更方便的自定义布局 `CustomMultiChildLayout` ，不需要你一步一步实现，比如常用的默认页面脚手架 `Scaffold` 就是用它实现。


## 四、有趣的知识点

既然聊到这个，我们在深入聊聊一些有趣的知识点，比如前面代码里的一直出现的 Scaffold ，这个是我们 Flutter 开发里最常用到的页面脚手架，也是一个页面布局的开始。

如果这时候把 `Scaffold` 给去掉，运行最初的代码，可以看到整个屏幕都红了，也即是 `ConstrainedBox` 铺满了整个屏幕。


```dart
MaterialApp(
  title: 'GSY Flutter Demo',
  theme: ThemeData(
    primarySwatch: Colors.blue,
  ),
  home: ConstrainedBox(
    constraints: BoxConstraints(
        maxHeight: 100, minHeight: 10, maxWidth: 100, minWidth: 10),
    child: ColoredBox(
      color: Colors.red,
    ),
  ),
);
```


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image20)

为什么呢？

我们通过 Flutter 的调试工具可以看到，此时上级给你的约束就是屏幕大小，没有区间，而 `enforce` 等于 `10.clamp(392.72, 392.72)`

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image21)

看到了没有，你没得选，`clamp(392.72, 392.72)` 也就是强行都变成了屏幕的宽度。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image22)


那如果这时候，我们加了一个 `Center` 控件呢？

可以看到约束大小又有了！

```dart
MaterialApp(
  title: 'GSY Flutter Demo',
  theme: ThemeData(
    primarySwatch: Colors.blue,
  ),
  home: Center(
	  child:ConstrainedBox(
	    constraints: BoxConstraints(
	        maxHeight: 100, minHeight: 10, maxWidth: 100, minWidth: 10),
	    child: ColoredBox(
	      color: Colors.red,
	    ),
	  )
  ),
);
```

可以看到约束变成了 `0-392.72` 的约束，也就是 `10.clamp(0, 392.72)`

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image23)

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image24)

为什么呢？

因为 `Center` 的 `RenderObject` 是 `RenderPositionedBox` ，**它在布局的时候会有一个 `constraints.loosen()` 的操作**，这也是为什么你有时候加多一个 `Center` 布局就突然生效的原因，因为 `loosen` 就成了 0-392.72 的约束。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image25)


```dart
BoxConstraints loosen() {
  assert(debugAssertIsValid());
  return BoxConstraints(
    minWidth: 0.0,
    maxWidth: maxWidth,
    minHeight: 0.0,
    maxHeight: maxHeight,
  );
}
```


如果不加 `Center`，像之前用的 `Scaffold` 为什么也能让  `BoxConstraints` 生效呢？

> 因为会出现虽然位置不对，所以这里调成了 100 比较好看到。

```dart
Scaffold(
  body: ConstrainedBox(
    constraints: BoxConstraints(
        maxHeight: 100, minHeight: 100, maxWidth: 100, minWidth: 100),
    child: ColoredBox(
      color: Colors.red,
    ),
  ),
)
```

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image26)


这其实是因为 `Scaffold` 的实现是一个叫 `CustomMultiChildLayout` 的控件。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image27)


**`Scaffold` 内的 `CustomMultiChildLayout` 布局时，对 `body` 使用了一个叫 `_BodyBoxConstraints` 的 `Constraints` 子类，这个类默认下所有 min 都是 0**。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image28)

所以对于 body 下的 child 而言，都会有 0 的 min 约束信息存在。

> 所以 10.clamp(0, 392.72) 可以生效。

**那可能还会有人就疑惑， child 返回的 size 是在哪里使用？**

答案肯定是在 `paint` 的时候了使用，那这个 `Offset` 又是什么？


举个例子，我们看之前用过的 `Center` 里面，它会在 `paintChild` 的时候，会添加 `Offset` 信息，所以 child 就会在绘制的时候有偏移，从而绘制到准确的地方。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image29)


所以最终如下图所示，**`ColoredBox` 在绘制 Rect 时，通过 `Offset` （决定位置） 和 `Size`（决定大小），而至绘制出对应位置的红色方框**。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image30)

那如果我画的时候不遵循这个 `Offset` 呢？

这里我们可以通过一个简单的例子，直接用 `CustomPaint` 画一个 Demo。

```dart
new Container(
  height: 200,
  width: 200,
  color: Colors.greenAccent,
  child: CustomPaint(
    ///直接使用值做动画
    foregroundPainter: _AnimationPainter(animation1),
  ),
)
```

可以看到，虽然 CustomPaint 是在 200 x 200 的大小下，但是动画绘制的圆可以很直接的超出这个大小。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image31)

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image32)

**所以可以看到 Flutter 本质是一块画板，通过各种 `Layer` 分层，在每个 `Layer` 上又根据约定好的 `Size` 和  `Offset` 绘制控件**。

> Layer 就是一群 `RenderObject` 的集合。

其实只要你拿到这个 `Layer` 上的 `Canvas` ，就可以会知道这个 `Layer` 上的任意位置，当然一般情况下为了正确布局绘制，还是要遵循这个规则的。

> 常见的每个 `Route` 就是一个独立的 `Layer` 。

### 总结

最后做个总结：

- `Widget` 只是配置文件，它不可变，每次改变都会重构，它并不是真正的 `View `；
- 布局逻辑主要在 `RenderBox` 子类的 `performLayout`，并且可以提前获取 `child.size` ；
- `Element` 的连接作用，`Widget` 被首次加载会创建 `Element` 和 `RenderObject` ，并连接到一起；
- 多 `child` 布局里是通过 `ContainerBoxParentData` 来访问多个 child；
- 约束布局时  `smallest`  和有没有 0 值（区间最小值）会影响约束的效果；
- 控件绘制时遵循对应的 `Size` 和 `Offset` ，也可以超出 `Size` 绘制，具体看所在 `Layer` 的 `Canvas` ；



![](http://img.cdn.guoshuyu.cn/20220328_Flutter-DevFest2021/image33)