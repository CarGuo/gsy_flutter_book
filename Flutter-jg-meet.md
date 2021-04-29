![](http://img.cdn.guoshuyu.cn/27151571552226_.pic_hd.jpg)

> 大家好，我是郭树煜，掘金 *《Flutter 完整开发实战详解》* 系列的作者，Github GSY 系列开源项目的维护人员，系列包括 [GSYVideoPlayer](https://github.com/CarGuo/GSYVideoPlayer)  、`GSYGitGithubApp` ([Flutter](https://github.com/CarGuo/gsy_github_app_flutter) \ [ReactNative](https://github.com/CarGuo/GSYGithubAPP) \ [Kotlin]() \ [Weex](https://github.com/CarGuo/GSYGithubAPPWeex) 四大版本)、[GSYFlutterBook](https://github.com/CarGuo/gsy_flutter_book) 电子书等，系列总 star 数在 25k 左右，目前 Github 中国区粉丝数暂居 67 名，主要负责移动端项目开发，大前端方向，主要涉及领域有 Android、Flutter、React Native、Weex 、小程序等等。


这次分享的主题主要涉及：**移动端跨平台开发的发展**、**Flutter Widget 的实现原理** 、 **Flutter 的实战技巧** 、**Flutter Web的现状** 四个方面，而整体主题将围绕 Widget 为中心展开。

## 一、移动端跨平台开发的发展

按照惯例，我们先介绍历史进程，随着用户终端种类的百花齐放，如今跨平台开发已然成为移动领域的热门话题之一，移动端跨平台开发技术的发展，也代表着开发者对于**性能、复用、高效**上不断的追求。

移动端的跨平台开发主要有三个阶段，这些阶段的代表框架主要有：**`Cordova` 、`React Native` 、`Flutter`** 等，如下图所示，是移动端的跨平台发展历程：

![](http://img.cdn.guoshuyu.cn/231571552717_.pic_hd.jpg)

#### Cordova

`Cordova` 作为早期跨平台领域应用最广泛的框架，为前端人员所熟知，其主要原理就是：

**将 web 代码打包到本地，利用平台的 WebView 进行加载，通过内部约定好的 JS 通讯协议，加载和调用具备平台原生能力的插架。**

![](http://img.cdn.guoshuyu.cn/241571552808_.pic_hd.jpg)

`Cordova` 让前端开发人员可以快速的构建移动应用，获取平台入口，对早期 web 上欠缺的如**摄像机、本地缓存、文件读写**等能力进行快速支持。 

> 早期的移动开发市场除了 Android 和 iOS 之外，还有 WindowPhone、黑莓等，`Cordova` 简单又实用的理念，使得它成为早期热门的跨平台框架，至今仍在更新的 **`ionic`** 框架，也是在其基础上进行了封装发展。

#### React Native

`Cordova` 虽然实用方便，但是由于 `WebView` 的性能瓶颈，开发者开始追求**更高性能，且具备平台特色**的跨平台能力，这时候由 Facebook 开源的 `React Native` 框架开始引领新潮流。

**`React Native` 让 JS 代码运行在框架内置的 JS 引擎（JavaScriptCore）上，利用 JS 引擎实现了跨平台能力，同时又将 JS 控件，对应解析为平台原生控件进行渲染，从而实现性能的优化与提升。**

![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image1)

由于 `React` 框架的盛行， `React Native` 也开始成为 `React` 开发人员，将自身能力拓展到应用开发的最佳选择之一。同时 `React Native` 也是应用开发人员，接触前端的不错尝试。

> 后来阿里开源的 `Weex` 框架设计相似，利用了 V8 引擎实现跨平台，不过使用了 `Vue` 的设计理念，而 `Weex` 因为种种原因，最终还是没能大面积推广开来。

#### Flutter

事实上 `JS Bridge` 同样存在性能等限制，Facebook 也在着力优化这一问题，比如 `HermesJS` 、底层大规模重构等 ，而 JS -> 平台控件映射，也导致了框架和平台耦合过多，在版本兼容和系统升级等问题上让框架维护越发困难。

这时候谷歌开源了 `Flutter` ，**它另辟蹊径，只要求平台提供一个 `Surface` 和一个 `Canvas` ，剩下的 `Flutter` 说：“你可以躺下了，我们来自己动”。**

![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image2)

`Flutter` 的跨平台思路快速让他成为“新贵”，**连跨平台界的老大哥 “JS” 语言都“视而不见”，大胆的选择 `Dart` 也让 `Flutter` 在前期的推广中饱受争议。**

> 短短两年，不算 PR ，`Flutter` 的 issue 已经有近 1.8 万的 closed 和 8000+ open , 这代表了它的热度，也代表着它需要面对的问题和挑战。
> 不支持 Release 模式下的热更新，也让用户更多徘徊于 React Native 不愿尝试。
> 
> **不过有一点可以确定的，那就是 `Flutter` 的版本号上是彻底战胜了 `React Naitve` 。**


总结起来，我们可以看到，移动端跨平台的发展，**从单纯的套壳打包，到提供高性能的跨平台控件封装，再到现在的控件与平台脱离的发展。** 整个发展历程，就是对 **性能、复用、高效** 的不断追求。


#### 题外话，什么要学习跨平台？

**1、开发成本**

我直接学 `Java`/`Kotlin` 、`Object-C`/`Swift` 、`JavaScript`/`CSS` 去写各平台的代码可以吗？

**当然可以，这样的性能肯定最有保证，但是跨平台的主要优势在于代码逻辑的复用，减少各平台同一逻辑，因人而异的开发成本。**

**2、学习机会**

一般情况下，各平台开发者容易局限在自己的领域开发，**而作为应用开发者，跨平台是接触另一平台或领域的过渡机会。**


> 下面开始今天的主题 Flutter ，Flutter 整体涉及的内容很多，由于篇幅问题，本篇我们的主题整体都围绕一个 `Widget` 展开。**Flutter 作为跨平台 UI 框架，`Widget` 是其灵魂设定之一。**


## 二、Flutter Widget 的实现原理

**Flutter 是 UI 框架，Flutter 内一切皆 `Widget` ，每个 `Widget` 状态都代表了一帧，`Widget` 是不可变的。** 那么 `Widget` 是怎么工作的呢？ 

如下图可以看到，是一个简单的 Flutter `Widget` 页面代码，页面包含了一个标题和容易，那在页面 `build`  时，它是怎么表绘制出来的呢？同时它是如何保证性能？ 而`Widget` 又是怎么样的一个概念？后面我们将逐步揭晓。

![](http://img.cdn.guoshuyu.cn/17411570522658_.pic.jpg)

首先看上图代码，其实如图的代码并不是真正的 `View` 级别代码，它们更像是配置文件。

而要知道 `Widget` 是如何工作的，这就涉及到 Flutter 的三大金刚： **`Widget` 、 `Element` 、`RenderObject` 。** 事实上，这三大金刚才能组成了 Flutter Framework 的基础渲染闭环。

![](http://img.cdn.guoshuyu.cn/251571552926_.pic_hd.jpg)

如上图所示，当一个 `Widget` 被“加载“的时候，它并不是马上被绘制出来，而是会对应先创建出它的 `Element` ，然后通过 `Element` 将 `Widget` 的配置信息转化为 `RenderObject` 实现绘制。

**所以，在 Flutter 中大部分时候我们写的是 `Widget` ，但是  `Widget` 的角色反而更像是“配置文件” ，真正触发工作的其实是 `RenderObject`。**

小结一下这里的关系就是：

- `Widget` 是配置文件。
- `Element` 是桥梁和仓库。
- `RenderObject` 是解析后的绘制和布局。

对应详细的解释就是：

 - **所以我们写的 `Widget`，它需要转化为相应的 `RenderObject` 去工作；** 
 - `Element` 持有 `Widget` 和  `RenderObject` ，作为两者的桥梁，并保存着一些状态参数，**我们在 Flutter 框架中常见到的 `BuildContext` ，其实就是 `Element` 的抽象** ； 
 - 最后框架会将 `Widget` 的配置信息，转化到 `RenderObject` 内，告诉 `Canvas` 应该在哪个 `Rect` 内，绘制多大 `Size` 的数据。

所以 `Widget` 和我们以前的布局概念不一样，因为 `Widget` 是不可变的（`immutable`），且只有一帧，且不是真正工作的对象，每次画面变化，都会导致一些 `Widget` 重新 `build` 。

那到这里，我们可能就会关心性能的问题，**Flutter 是如何保证性能呢？**

![](http://img.cdn.guoshuyu.cn/27181571554485_.pic_hd.jpg)

### 1.1、Widget 的轻量级

其实就是回归到了 `Widget` 的定位，作为“配置文件”，**`Widget` 的变化，是否也会导致 `Element`  和 `RenderObject` 也会重新创建？**

**答案是不一定会**，`Widget` 只是一个 “配置文件” 的作用，是非常轻量级的，**它的存在，只是起到对 `RenderObject` 的数据进行配置的作用。**

但是 `RenderObject` 就不一样了，**它涉及到了 `layout`、`paint`** 等真实
的绘制操作，可以认为是一个真正的 “View” ，如果频繁创建就会导性能出现问题。

所以在 Flutter 中，**会有一系列的判断，来处理 `Widget` 到 `RenderObject` 转化的性能问题 ，这部分操作通常是在 `Element` 中进行的** ，例如 `updateChild` 时，会有如下图所示的判断：

![](http://img.cdn.guoshuyu.cn/%E6%88%AA%E5%B1%8F2019-10-1121.44.22.png)

- 当 `element.child.widget == widget.build()` 时，就不会触发 `update` 操作；

- 在 `update` 时，`canUpdate(element.child.widget, newWidget)` 返回 true， `Element` 才会被更新；*（这里代码中的 `slot` 一般为 `Element` 对象，有时候会传空）*

- 其他还有利用 `isRelayoutBoundary` 、 `isRepaintBoundary` 等参数，来实现局部的更新判断，比如：**当执行 markNeedsPaint() 触发绘制时，会通过 `isRepaintBoundary` 是否为 `true` ， 往上确定了更新区域，通过 `requestVisualUpdate` 方法触发更新往下绘制。**

> 通过  `isRepaintBoundary`  参数， 对应的 `RenderObject` 可以组成一个 `Layer` 。

*所以这就可以解答一些初学者的疑问，嵌套那么多 `Widget` ，性能会不会有问题？*

**这也体现出 Flutter 在布局上和其他框架不同的地方，你写的 `Widget` 只是配置文件，堆叠嵌套了一堆控件，对最终的 `RenderObject` 而言，可能只是多几个 `Offset` 和 `Size` 计算而已。**

结合上面的理解，可以知道 `Widget`  大部分时候，其实只是轻量级的配置，对于性能问题，**你更需要关心的是 `Clip` 、`Overlay` 、透明合成等行为，因为它们会需要产生 `saveLayer` 的操作，因为 `saveLayer` 会清空GPU绘制的缓存。**


最后总结个面试点：

- 同一个 `Widget` 可以同时描述多个渲染树中的节点，**作为配置文件是可以复用的。 `Widget` 和 `RenderObject` 一般情况是一对多的关系。** （ 前提是在 `Widget` 存在 `RenderObject` 的情况。）

- `Element` 是 `Widget` 的某个固定实例，与 `RenderObject` 一一对应。（前提是在 `Element` 存在 `RenderObject` 的情况。）

- `RenderObject` 内 `isRepaintBoundary` 标示使得它们组成了一个个 `Layer` 区域。

当 **`isRepaintBoundary` 为 `true` 时，该区域就是一个可更新绘制区域，而当这个区域形成时，就会新创建一个 `Layer` 。** 但不是每个 `RenderObject` 都会有 `Layer` ， 因为这受 `isRepaintBoundary` 的影响。

![](http://img.cdn.guoshuyu.cn/1121212121212121.png)


![](http://img.cdn.guoshuyu.cn/27161571552227_.pic_hd.jpg)

> 注意，Flutter 中常见的 `BuildContext` ，其实就是 `Element` 的抽象，通过 `BuildContext` ，我们一般情况就可以对应获得  `Element` ，也就是拿到了“仓库的钥匙” ，通过 `context` 就可以去获取  `Element` 内持有的东西，比如前面所说的 `RenderObject` ，还有后面我们会谈到 `State` 等。

### 1.2 Widget 的分类

这里我们将 `Widget` 分为如下图所示分类：是否存在 `State` 、是否存在`RenderObject` 。

 ![](http://img.cdn.guoshuyu.cn/321571568999_.pic_hd.jpg)

> 其实还可以按照 `RenderBox` 和 `RenderSliver` 分类，但是篇幅原因以后再介绍。

#### 1.2.1 是否存在 State

Flutter 中我们常用的 `Widget` 有： `StatelessWidget` 和 `StatefulWidget` 。

如下图， `StatelessWidget` 的代码很简单，因为 `Widget` 是不可变的，传入的 `text` 决定了它显示的内容，并且 `text` 也算是 `final` 的。

![](http://img.cdn.guoshuyu.cn/%E6%88%AA%E5%B1%8F2019-10-1122.00.18.png)

> 注意图中 `DemoPage` 有个黄色警告，这是因为我们定义了 `int i = 0` 不是 final 导致的，在  `StatelessWidget` 中， **非 final 的变量起始容易产生误解，因为 `Widget` 本事就是不可变的。**

前面我们说过 `Widget` 都是不可变的，在这个基础上， **`StatefulWidget` 的 `State` ，帮我们实现了 `Widget` 的跨帧绘制**  ，也就是在每次  `Widget` 重构时，可以通过 `State` 重新赋予 `Widget` 需要的配置信息，而这里的 **`State` 对象，就是存在每个 `Element` 里的。**

> 同时，前面我们说过，Flutter 内的 `BuildContext` 其实就是 `Element` 的抽象，这说明我们可以通过 `context` 去获取 `Element` 内的东西，比如 `State` 、`RenderObject` 、 `Widget` 。

```
 Widget ancestorWidgetOfExactType
 State ancestorStateOfType
 State rootAncestorStateOfType
 RenderObject ancestorRenderObjectOfType
```

如下图所示，保存在 `State` 中的 `text` ，当我们点击按键时，`setState` 时它被标志为 `"变化了"` ， **它可以主动发生改变，保存变量，不再只是“只读”状态了**。

![](http://img.cdn.guoshuyu.cn/%E6%88%AA%E5%B1%8F2019-10-1122.02.50.png)

#### 1.2.2、容器 Widget/渲染 Widget

在 Flutter 中还有 **容器 Widget** 和 **渲染Widget** 的区别，一般情况下:

- `Text`、`Slider` 、`ListTile` 等都是属于渲染 `Widget` ，其内部主要是 `RenderObjectElement` ，对应有 `RenderObject` 参数。

- `StatelessWidget` / `StatefulWidget` 等属于容器 `Widget` ，其内部使用的是 `ComponentElement` ， **`ComponentElement` 本身是不存在 `RenderObject` 的。**

所以作为容器  `Widget`， 获取它们的 `RenderObject` 时，获取到的是 `build` 后的树结构里，最上面**渲染 Widget**的 `RenderObject` 。

![](http://img.cdn.guoshuyu.cn/20190902_Flutter-17/image11)

> 如上图所示 `findRenderObject` 的实现，最终就是获取 `renderObject`，**在遇到 `ComponentElement` 时，执行的是 `element.visitChildren(visit);`** , 递归直到找到  `RenderObjectElement` ，再返回它的 `renderObject`。

**获取 `RenderObject` 在 Flutter 里很重要的，因为获取控件的位置和大小等，都需要通过  `RenderObject` 获取。**

### 1.3、RenderObject

Flutter 中各类 `RenderObject` 的实现，大多都是颗粒度很细，功能很单一的存在 ：

![](http://img.cdn.guoshuyu.cn/261571553040_.pic_hd.jpg)

然而接触过 Flutter 的同学应该知道 **`Container`** 这个 `Widget` ，**`Container`** 的功能却不显单一，这是为什么呢？

如下图，因为 **`Container` 其实是容器 Widget** ，它只是把其他“单一”的 Widget 做了二次封装，然后通过配置参数来达到 “多功能的效果” 而已。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-7/image1)

**所以 Flutter 开发中，我们经常会根据功能定义出各类如 `Continer`、`Scaffold` 等脚手架模版，实现灵活与复用的界面开发。**

回归到 `RenderObject` ，事实上 `RenderObject` 还属于比较“低级”的阶段，因为绘制到屏幕上我们还需要坐标体系和布局协议等，所以 **大部分 `Widget` 的 `RenderObject` 会是子类 `RenderBox` (`RenderSliver` 例外)** ，因为 `RenderObject` 本身只实现了基础的 `layout` 和  `paint` ，而绘制到屏幕上，我们需要的坐标和大小等，这些内容是在 `RenderBox` 中开始实现。

> `RenderSliver` 主要是在滚动控件中继承使用。


比如控件被绘制在 `x=10,y=20` 的位置，然后大小由 `parent` 对它进行约束显示，**`RenderBox` 继承了 `RenderObject`，在其基础上实现了 `笛卡尔坐标系` 和布局协议。**

这里我们通过 **`Offstage`** 这个 `Widget` ，看下其 `RenderBox` 子类的实现逻辑， **`Offstage`** 是用于控制 `child` 是否显示的作用，如下图，可以看到 `RenderOffstage` 对于  `offstage` 标志位的内部逻辑：

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-7/image3)

*那么 Flutter 中的布局协议是什么呢？*

简单来说就是 `child` 和 `parent` 之间的大小应该怎么显示，由谁决定显示区域。 *相信从 Android 到接触 Flutter 的同学有这样的疑惑， Flutter 中的 `match_parent` 和 `wrap_content` 逻辑需要怎么设置？*

就我们从一个简单的代码分析，如下图所示，*`Row` 布局我们没有设置任何大小，它是怎么确定自身大小的呢？*

![](http://img.cdn.guoshuyu.cn/17671570608508_.pic.jpg)

我们翻阅源码，可以发现其实 Flutter 中常用的 `Row` 、`Column` 等其实都是 `Flex` 的子类，只是对 `Flex` 做了简单默认配置。

![](http://img.cdn.guoshuyu.cn/17681570608836_.pic_hd.jpg)

那按照我们前面的理解，**看一个 `Widget` 的实现逻辑，就应该看它的 `RenderObject`** ，而在 `Flex` 布对应的 `RenderFlex` 中，我们可以看到如下一段代码：

![](http://img.cdn.guoshuyu.cn/17691570609290_.pic_hd.jpg)

可以看到在布局的时候，`RenderFlex` 首先要求 `constraints != null` ，**`Flex` 布局的上层中必须存在约束，不然肯定会报错。**

之后，在布局时，`Row` 布局的 `direction` 是横向的，所以 `maxMainSize` 为上层布局的最大宽度，然后根据我们配置的 `mainAxisSize` 的参数：

- 当 `mainAxisSize` 为 `max` 时，我们 `Row`  的横向布局就是 `maxMainSize` ；
- 当 `mainAxisSize` 为 `min` 时，我们 `Row`  的横向布局就是 `allocatedSize` ；

前面 `maxMainSize` 我们知道了是父布局的最大宽度，而 `allocatedSize ` 其实就是 child 的宽度之和。所以结果很明显了：

**对于 `Row` 来说， `mainAxisSize` 为 `max` 时就是  `match_parent` ；`mainAxisSize` 为 `min` 时就是  `wrap_content ` 。**

而高度 `crossSize` ，**其实是由 `math.max(crossSize, _getCrossSize(child));` 决定，也就是 `child` 中最高的一个作为其高度。**

最后小结一个知识点：

**布局一般都是由上层往下传递 `Constraints` ，然后由下往上返回 `Size`。**

![](http://img.cdn.guoshuyu.cn/18511571125034_.pic.jpg)


*那如何直接自定义 `RenderObject` 布局？*

抛开 Flutter 为我们封装的好的，三大金刚 `Widget` 、`Element` 、`RednerObject` 一个不少，当然， Flutter 内置了很多封装帮我们节省代码。

一般情况下自定义 `RenderObject` 布局：

- **我们会继承 `MultiChildRenderObjectWidget` 和 `RenderBox` 这两个 `abstract` 类，实现自己的`Widget` 和 `RenderObject` 对象；**
- **然后利用 `MultiChildRenderObjectElement` 关联起它们；** 
- 除此之外，还有几个关键的类： **`ContainerRenderObjectMixin`** 、 **`RenderBoxContainerDefaultsMixin`** 和  **`ContainerBoxParentData`** 等可以帮你减少代码量。

![](http://img.cdn.guoshuyu.cn/271571553217_.pic_hd.jpg)

**总结起来， 对于 Flutter 而言，整个屏幕都是一块画布，我们通过各种 `Offset` 和 `Rect` 确定了位置，然后通过 `Canvas` 绘制上去，目标是整个屏幕区域，整个屏幕就是一帧，每次改变都是重新绘制。**


> 这里没有介绍 `RenderSliver` 相关，它的输入和输出和 `Renderbox` 又不大一样，有机会我们后面再详细介绍。


## 三、Flutter 的实战技巧

### 3.1、InheritedWidget

`InheritedWidget` 是 Flutter 的灵魂设定之一。

**`InheritedWidget` 共享的是  `Widget` ，只是这个  `Widget` 是一个 `ProxyWidget ` ，它自己本身并不绘制什么，但共享这个 `Widget` 内保存有的数据，从而到了共享状态的目的。** 

如下图所示，是 Flutter 中常见的 `Theme` ，其内部就是使用了 `_InheritedTheme` 这个 `InheritedWidget` 来实现主题的全局共享的。那么 `InheritedWidget` 是如何实现全局共享的呢？

![](http://img.cdn.guoshuyu.cn/17831570674242_.pic.jpg)


其实在 `Element` 的内部有一个 `Map<Type, InheritedElement> _inheritedWidgets;` 参数，**`_inheritedWidgets` 一般情况下是空的，只有当父控件是 `InheritedWidget` 或者本身是 `InheritedWidget` 时，它才会被初始化，而当父控件是 `InheritedWidget`  时，这个 `Map` 会被一级一级往下传递与合并。**

所以当我们通过 `context` 调用 `inheritFromWidgetOfExactType` 时，就可以通过这个 `Map`  往上查找，从而找到这个上级的 `InheritedWidget ` 。（毕竟 `context` is  `Element`）

![](http://img.cdn.guoshuyu.cn/17821570674022_.pic_hd.jpg)

如我们的 `Theme`/`ThemeData` 、`Text`/`DefaultTextStyle`、`Slider` / `SliderTheme` 等，如下代码所示，我们可以定义全局的 `ThemeData` 或者局部的 `DefaultTextStyle` ，从而实现全局的自定义和局部的自定义共享等。

![](http://img.cdn.guoshuyu.cn/17451570525169_.pic.jpg)

![](http://img.cdn.guoshuyu.cn/17461570525306_.pic_hd.jpg)


> **其实，Flutter 中大部分的状态管理控件，其状态共享方法，也是基于 `InheritedWidget` 去实现的。**


### 3.2、支持原生控件

前面我们说过， Flutter 既然不依赖于原生控件，那么如何集成一些平台已有的控件呢？比如 `WebView` 和 `Map` ？

我们这里以 `WebView ` 为例子：

**在官方 `WebView` 控件支持出来之前** ，第三方是直接在 FlutterView 上覆盖了一个新的原生控件，利用 Dart 中的占位控件**传递位置和大小**。

如下图，在 Flutter 端 `push` 出一个 **设定好位置和大小** 的 `SingleChildRenderObjectWidget` ，从而得到需要显示的大小和位置，将这些信息通过 `MethodChannel` 传递到原生层，在原生层 `addContentView` 一个指定大小和位置的 `WebView` 。

这时候  `WebView` 和 `SingleChildRenderObjectWidget` 处于一样的大小和位置，而空白部分则用 FLutter 的 `Appbar` 显示。

![](http://img.cdn.guoshuyu.cn/281571553300_.pic_hd.jpg)

这样看起来就像是在 Flutter 中添加了 `WebView` ，但实际这脱离了 Flutter 的渲染树，其中一个问题就是，当你跳转 Flutter 其他页面的时候，会被 `WebView` 挡住；并且打开页面的动画，`Appbar` 和  `WebView` 难以保持一致。

![](http://img.cdn.guoshuyu.cn/291571553328_.pic_hd.jpg)

后面 官方 `WebView` 控件支持出来后，这时候官方是利用 `PlatformView` 的设计，完成了不脱离 Flutter 渲染堆栈，也能集成平台原生控件的功能。

以 Android 为例，Android 上是利用了副屏显示的底层逻辑，使用 `VirtualDisplay` 类，创建一个虚拟显示器，需要调用 `DisplayManager` 的 `createVirtualDisplay()` 方法，将虚拟显示器的内容渲染在一个内存的 `Surface` 上 ，生成一个唯一的 `textureId` 。

如下图，之后渲染时将 `textureId` 传递给 `Dart` 层，渲染引擎会根据 `textureId` , 获取到内存里已渲染数据，绘制到 `AndroidView` 上进行显示。

![](http://img.cdn.guoshuyu.cn/1570459981248.jpg)


### 3.3、错误处理

Flutter 中比较有趣的情况是，在 Dart 中的一些错误，并不会导致应用闪退，而是通过如下的红色堆栈 UI ，错误区域不同，可能是全屏红，也可能局部红，这种状态就和传统 APP 的“崩溃”状态不大一样了。 

![](http://img.cdn.guoshuyu.cn/17481570526055_.pic_hd.jpg)

在开发过程中这样的显示没太大问题，但事实发布线上版本就不合适了，所以我们一般会选择自定义错误显示。

如下图所示，一般我们可以通过如下处理，自定义我们的错误页面，并且收集错误信息。

![](http://img.cdn.guoshuyu.cn/17491570526190_.pic.jpg)

重写 `ErrorWidget` 的 `builder` 方法，然后将信息收集到 `Zone` 中，返回自己的自定义错误显示，最后在 `Zone` 内利用 `onError` 统一处理错误。

> ps 图中的 `Zone` 等概念这里就不展开了，有兴趣的可以去以前的文章详细查看。

## 四、Flutter Web

最后简单说下 Flutter Web ，Flutter 在支持 Web 平台上的优势在于 Flutter UI 与平台的耦合度很低，而 Dart 起初就是为了 Web 而生，一拍即合下 Flutter 支持 Web 并不是什么意外。

但是 Web 平台就绕不过 JS ，在 Web 平台，实际上 `Image` 控件最后会通过 dart2js 转化为 `<img>` 标签并通过 `src` 赋值显示。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image30)

同时，多了一个平台就多了需要兼容的，目前 Flutter 的 issue 仍然不少，而 Web 支持虽然已经合并到主项目中，但是在兼容、性能等问题上还需要继续优化，比如 Flutter Web 中 ` canvas.drawColor(Colors.black, BlendMode.clear);` 是会出现运行错误的，因为不支持 `BlendMode.clear` 。

![](http://img.cdn.guoshuyu.cn/301571553548_.pic_hd.jpg)

## 资源推荐

* Github ： https://github.com/CarGuo
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**
* 开源 React Native 项目：https://github.com/CarGuo/GSYGithubApp

## 其他文章

[《Flutter完整开发实战详解系列》](https://juejin.im/user/582aca2ba22b9d006b59ae68/posts)

[《移动端跨平台开发的深度解析》](https://juejin.im/post/5b395eb96fb9a00e556123ef)

[《全网最全Flutter与React Native深入对比分析》](https://juejin.im/post/5d0bac156fb9a07ec56e7f15)

![](https://avatars2.githubusercontent.com/u/10770362?s=460&v=4)
