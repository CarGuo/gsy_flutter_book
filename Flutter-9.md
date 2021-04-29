作为系列文章的第九篇，本篇主要深入了解 Widget 中绘制相关的原理，探索 Flutter 里的 RenderObject 最后是如何走完屏幕上的最后一步，结尾再通过实际例子理解如何设计一个 Flutter 的自定义绘制。

## 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)

在第六、第七篇中我们知道了 `Widget`、`Element`、`RenderObject` 的关系，同时也知道了`Widget` 的布局逻辑，最终所有 `Widget` 都转化为 `RenderObject` 对象， 它们堆叠出我们想要的画面。

所以在 Flutter  中，最终页面的 `Layout`、`Paint` 等都会发生在 Widget  所对应的 `RenderObject` 子类中，而 `RenderObject`  也是 Flutter 跨平台的最大的特点之一：**所有的控件都与平台无关** ，这里简单的人话就是： **Flutter 只要求系统提供的 “Canvas”，然后开发者通过 Widget 生成 `RenderObject` “直接” 通过引擎绘制到屏幕上。**

> ps 从这里开始篇幅略长，可能需要消费您的一点耐心。

## 一、绘制过程

我们知道 `Widget` 最终都转化为 `RenderObject` ， 所以了解绘制我们直接先看 `RenderObject` 的 `paint` 方法。

如下图所示，所有的  `RenderObject` 子类都必须实现 `paint` 方法，并且该方法并不是给用户直接调用，需要更新绘制时，你可以通过 `markNeddsPaint` 方法去触发界面绘制。

![image.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image1)

那么，按照“国际流程”，在经历大小和布局等位置计算之后，最终 `paint`  方法会被调用，该方法带有两个参数： `PaintingContext`  和  `Offset`  ，它们就是完成绘制的关键所在，那么相信此时大家肯定有个疑问就是：

- `PaintingContext` 是什么？
- `Offset` 是什么？

通过飞速查阅源码，我们可以首先了解到有 ：

- `PaintingContext` 的关键是 **A place to paint**  ，同时它在父类 `ClipContext `  是包含有 `Canvas` ，并且  `PaintingContext`  的构造方法是  `@protected`，只在 `PaintingContext.repaintCompositedChild` 和 `pushLayer` 时自动创建。

- `Offset` 在 `paint` 中主要是提供当前控件在屏幕的相对偏移值，提供绘制时确定绘制的坐标。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image2)


OK，继续往下走，那么既然 `PaintingContext` 叫 Context ，那它肯定是存在上下文关系，那它是在哪里开始创建的呢？

通过调试源码可知，项目在 `runApp` 时通过 `WidgetsFlutterBinding` 启动，而在以前的篇幅中我们知道， `WidgetsFlutterBinding` 是一个“胶水类”，它会触发 *mixin* 的 `RendererBinding` ，如下图创建出根 node 的 `PaintingContext` 。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image3)


好了，那么`Offset` 呢？如下图，对于 `Offset` 的传递，是通过父控件和子控件的 offset 相加之后，一级一级的将需要绘制的坐标结合去传递的。

目前简单来说，**通过 `PaintingContext` 和 `Offset` ，在布局之后我们就可以在屏幕上准确的地方绘制会需要的画面。**

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image4)

#### 1、测试绘制

这里我们先做一个有趣的测试。

我们现在屏幕上通过 `Container` 限制一个高为 60 的绿色容器，如下图，暂时忽略容器内的 `Slider` 控件 ，我们图中绘制了一个 *100 x 100* 的红色方块，这时候我们会看到下图右边的效果是：*纳尼？为什么只有这么小？*

事实上，因为正常 Flutter 在绘制 `Container ` 的时候，`AppBar` 已经帮我们计算了状态栏和标题栏高度偏差，但我们这里在用 `Canvas` 时直接粗暴的 `drawRect`，绘制出来的红色小方框，**左部和顶部起点均为0，其实是从状态栏开始计算绘制的。** 

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image5)

那如果我们调整位置呢？把起点 top 调整到 300，出现了如下图的效果：*纳尼？红色小方块居然画出去了，明明 `Container` 只有绿色的大小。* 

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image6)

其实这里的问题还是在于 `PaintingContext` ，它有一个参数是 `estimatedBounds` ，而 `estimatedBounds` 正常是在创建时通过 `child.paintBounds`  赋值的，但是对于  `estimatedBounds` 还有如下的描述：**原来画出去也是可以。**

```
The canvas will allow painting outside these bounds.
The [estimatedBounds] rectangle is in the [canvas] coordinate system.
```

所以到这里你可以通俗的总结， **对于 Flutter 而言，整个屏幕都是一块画布，我们通过各种 `Offset` 和 `Rect` 确定了位置，然后通过 `PaintingContext `  的`Canvas` 绘制上去，目标是整个屏幕区域，整个屏幕就是一帧，每次改变都是重新绘制。**

#### 2、RepaintBoundary

当然，**每次重新绘制并不是完全重新绘制** ，这里面其实是存在一些规制的。

还记得前面的 `markNeedsPaint` 方法吗 ？我们先从 `markNeedsPaint()` 开始， 总结出其大致流程如下图，可以看到 `markNeedsPaint` 在 `requestVisualUpdate` 时确实触发了引擎去更新绘制界面。

![绘制大致流程图](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image7)

接着我们看源码，如源码所示，当调用 `markNeedsPaint()` 时，`RenderObject` 就会往上的父节点去查找，根据 `isRepaintBoundary` 是否为 true，会决定是否从这里开始去触发重绘。换个说法就是，**确定要更新哪些区域。**

所以其实流程应该是：**通过`isRepaintBoundary` 往上确定了更新区域，通过 `requestVisualUpdate ` 方法触发更新往下绘制。**

![markNeedsPaint](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image8)

并且从源码中可以看出， `isRepaintBoundary` 只有 `get ` ，所以它只能被子类 `override` ，由子类表明是否是为重绘的边缘，比如 `RenderProxyBox` 、`RenderView` 、`RenderFlow` 等 `RenderObject` 的  `isRepaintBoundary` 都是 true。

**所以如果一个区域绘制很频繁，且可以不影响父控件的情况下，其实可以将 override `isRepaintBoundary` 为 true。**


#### 3、Layer

上文我们知道了，当 `isRepaintBoundary` 为 true 时，那么该区域就是一个可更新绘制区域，而当这个区域形成时， 其实就会新创建一个 **`Layer`** 。

不同的 `Layer` 下的 `RenderObject` 是可以独立的工作，比如 `OffsetLayer ` 就在 `RenderObject` 中用到，它就是用来做定位绘制的。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image9)

同时这也引生出了一个结论：**不是每个 `RenderObject` 都具有 `Layer` 的，因为这受 `isRepaintBoundary` 的影响。** 

其次在 `RenderObject` 中还有一个属性叫 `needsCompositing` ，它会影响生成多少层的 **`Layer`** ，而这些 **`Layer`**  又会组成一棵 **Layer Tree**  。好吧，到这里又多了一个树，实际上这颗树才是所谓真正去给引擎绘制的树。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image10)

到这里我们大概就了解了 `RenderObject` 的整个绘制流程，并且这个**绘制时机我们是去“触发”的，而不是主动调用，并且更新是判断区域的。** 嗯～有点 React 的味道！


### 二、Slider 控件的绘制实现

前面我们讲了那么多绘制的流程，现在让我们从 `Slider` 这个控件的源码，去看看一个绘制控件的设计实现吧。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image11)


整个 `Slider`  的实现可以说是很 `Flutter` 了，大体结构如下图。

在 `_RenderSlider` 中，除了 **手势** 和 **动画** 之外，其余的每个绘制的部分，都是独立的 *Component* 去完成绘制，而这些 *Component* 都是通过 `SliderTheme` 的 `SliderThemeData` 提供的。

巧合的是，`SliderTheme` 本身就是一个 `InheritedWidget` 。看过以前篇章的同学应该会知道， `InheritedWidget`  一般就是用于做状态共享的，所以如果你需要自定义  `Slider`  ，完成可以通过 `SliderTheme` 嵌套，然后通过 `SliderThemeData` 选择性的自定义你需要的模块。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image12)

并且如下图，在 `_RenderSlider`  中注册时手势和动画，会在监听中去触发 `markNeedsPaint` 方法，这就是为什么你的触摸能够响应画面的原因了。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image13)

同时可以看到  `_SliderRender `内的参数都重写了 `get` 、 `set` 方法， 在 `set` 时也会有  `markNeedsPaint()` ，或者调用 `_updateLabelPainter ` 去间接调用 `markNeedsLayout ` 。

![image.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image14)

至于 `Slider` 内的各种 Shape 的绘制这里就不展开了，都是 `Canvas` 标准的 `pathTo` 、`drawRect`、`translate`、`drawPath`等熟悉的操作了。


>自此，第九篇终于结束了！(///▽///)

### 资源推荐

* Github ： [https://github.com/CarGuo/](https://github.com/CarGuo)
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**

##### 完整开源项目推荐：

* [GSYGithubApp Flutter](https://github.com/CarGuo/GSYGithubAppFlutter ) 
* [GSYGithubApp React Native](https://github.com/CarGuo/GSYGithubApp ) 
* [GSYGithubAppWeex](https://github.com/CarGuo/GSYGithubAppWeex)



![我们还会再见吗？](http://img.cdn.guoshuyu.cn/20190604_Flutter-9/image15)