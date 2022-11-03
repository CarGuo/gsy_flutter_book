# Flutter 小技巧之优化你的代码性能

又到了小技巧系列更新时间，今天我们分享一个比较轻松的内容：**Flutter 里的代码优化，优化的目的主要是为了提高性能和可维护性**，放心，本篇我们不讲深入的源码分析，就是分享最最最基础的布局代码优化。

我们先从一个简单的例子开始，相信大家对于 Flutter 的 UI 构建不会陌生，那么如下代码所示，日常开发过程中 `A` 和 `B`  这两种代码组织方式，你更常用的是哪一种？

| A （函数方式）                                          | B （Component Class 方式）                              |
| ------------------------------------------------------- | ------------------------------------------------------- |
| ![](http://img.cdn.guoshuyu.cn/20221021_N13/image1.png) | ![](http://img.cdn.guoshuyu.cn/20221021_N13/image2.png) |

如果是从代码运行之后的 UI 效果来看，这两个方式运行之后的布局效果并不会有什么差异，而**通常因为可以写更少代码和参数调用更方便等原因**，我们可能在编写页面的内部控件时，会更经常使用  `A （函数方式）` 这种写法，也有称之为 Helper Method 的叫法。

**那使用函数方式构建 UI 有没有问题？答案肯定是没问题，但是某些场景下，对比使用 `B （Component Class 方式）` ，可能性能表现上相对没那么优秀**。

举个例子，如下代码所示，在 `renderA` 函数里我们通过点击按键修改 `count`，在修改之后触发 UI 渲染时就需要用到 `setState` ，也就是我们每点一下，当前整个页面就是触发一次 rebuild ，但是我们只是想要改变当前  `renderA`  里的 `count` 文本而已。

| ![](http://img.cdn.guoshuyu.cn/20221021_N13/image3.png) | ![](http://img.cdn.guoshuyu.cn/20221021_N13/image4.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |

**这就是使用函数构建内部控件最常见的问题之一**，因为子控件更新时是通过父容器的  `setState`   ，所以每次子控件比如 `renderA`   发生变化时，就会触发整个 Widget 都出现 rebuild ，这其实并不是特别符合我们的预期。

> 科普一个众所周知的知识点， **`setState`   其实就是调用  `StatefulWidget` 对应的 `StatefulElement`  里的 `markNeedsBuild` 方法，也就是对 `Element` (`BuildContext`) 里的 `_dirty` 标识为设置为 `true` ，仅此而已， 然后等待下次渲染更新**。

当然，你说像  `renderA`   这种写法会引起很严重的性能问题吗？事实上并不会，**因为众所周知 Flutter 里的 UI 构建是通过多个不同的树来完成的，而 Widget 并不是真实的控件**，所以一般情况下   `renderA`   这种写法导致的 rebuild 是不会产生严重的性能缺陷。

但是，如果同级下你的  `renderB`   是如下所示这样的情况呢？虽然这段代码毫无意义，但是我们在   `renderA`    点击改变 `count` 的时候，其实并没有改变  `renderB`   的用到的 `status`  参数，但是因为    `renderA`     里调用了  `setState`   ，导致   `renderB`    每次都会进行重复进行浮点计算。

![](http://img.cdn.guoshuyu.cn/20221021_N13/image5.png)

当然你可以说我写个变量进行缓存提前判断也可以解决，但这并不是这个例子的关键，那如果把上面这个例子变成  Component Class 的方式会有什么好处：

- A 在点击更新 `count` 时不会影响其他控件
- B 控件通过 `didUpdateWidget` 可以用更优雅的方式决定更新条件

| ![](http://img.cdn.guoshuyu.cn/20221021_N13/image6.png) | ![](http://img.cdn.guoshuyu.cn/20221021_N13/image7.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |

> 这样看起来是不是更合理一些？另外 Component Class 的实现方式，也能在一定层度解决代码层级嵌套的问题，有时候实现一些  Component Class  的模版也可以成为 Flutter 里提高效率的工具，这个后面我们会聊到。

**当然使用  Component Class  在无形之中会需要你写更多的代码，同时控件之间的状态联动成本也会有所提高**，例如你需要在 B 控件关联 A 的 `count` 变化去改变高度，这时候可能就需要加入 `InheritedWidget` 或者 `ValueNotifier` 等方式来实现。

例如 Flutter 里 `DefaultTabController` 配合  `TabBar` 和  `TabBarView` 的实现就是一个很好的参考。

```dart
 Widget build(BuildContext context) {
     return DefaultTabController(
       length: myTabs.length,
       child: Scaffold(
         appBar: AppBar(
           bottom: TabBar(
             tabs: myTabs,
           ),
         ),
         body: TabBarView(
           children: myTabs.map((Tab tab) {
             final String label = tab.text.toLowerCase();
             return Center(
               child: Text(
                 'This is the $label tab',
                 style: const TextStyle(fontSize: 36),
               ),
             );
           }).toList(),
         ),
       ),
     );
  }
```

> 所以到这里我们理解一个小技巧：**在不偷懒的情况下，使用  Component Class  的方式实现子控件会比使用函数方式可能得到更好的性能和代码结构**。

当然，**使用  Component Class 实现的方式，在调试时也会比函数方式更方便**，如下图所示，当使用函数方式布局时，你在 Flutter Inspector 里看到的 Widget Tree 和 Details Tree 是完全铺平的情况，也没办法定制调试参数。

![](http://img.cdn.guoshuyu.cn/20221021_N13/image8.png)

**但是当你 Component Class  组织布局的时候，你就可以通过  `override debugFillProperties`  方法来可视化一些参数状态**，例如 `ItemA` 里可以把 count 添加到  `debugFillProperties` 里，这样在 Details Tree 里也可以直观看到目前的 `count` 状态信息。

| ![](http://img.cdn.guoshuyu.cn/20221021_N13/image9.png) | ![](http://img.cdn.guoshuyu.cn/20221021_N13/image10.png) |
| ------------------------------------------------------- | -------------------------------------------------------- |

> 所以这里又有一个小技巧：**通过  `override debugFillProperties`   ，可以定制一些 Debug 时的可视化参数来帮助我们更好调试布局**。

既然讲到利用  Component Class  组织布局，那就不得不聊一个典型的控件：`AnimatedBuilder`  。

`AnimatedBuilder` 可以是最常说到的一个性能优化的例子， 一般情况下在页面的子控件里使用动画，特别是循环动画的话，我们都会建议使用前面介绍的 Component Class 方式，不然动画导致当前页面不停 rebuild 肯定会导致性能影响。

但是有时候我就不想用 Component Class  该怎么办？我就是想写在当前 Page 里，那就可以使用 `AnimatedBuilder` ，你只要把需要执行动画的部分放到 `builder`  方法里就好了。

**因为 `AnimatedBuilder`  的内部会有一个  `_AnimatedState` 用于独立触发  `setState`，从而执行外部 builder 方法执行动画效果**。

![](http://img.cdn.guoshuyu.cn/20221021_N13/image11.png)

类似  `AnimatedBuilder`   的模版实现，可以在一定程度上解决使用  Component Class   的痛点，当然，在使用  `AnimatedBuilder`   还是有一些需要注意， **比如 child 如果不需要跟随动画进行其他变化，一般是要放到   `AnimatedBuilder`    的  `child`  配置里**，因为如果直接放在  `builder`  方法里，那就会出现 child 也跟随动画重新 rebuild 的情况，但是如果是放到   `child`   配置项里，那就是调用了  `child`    的对象缓存。

| 不正确使用                                               | 正确使用                                                     |
| -------------------------------------------------------- | ------------------------------------------------------------ |
| ![](http://img.cdn.guoshuyu.cn/20221021_N13/image12.png) | ![image-20221020175113790](http://img.cdn.guoshuyu.cn/20221021_N13/image13.png) |

> 如果对于这个缓存概念不理解，可以参考 [《MediaQuery 和 build 优化你不知道的秘密》](https://juejin.cn/post/7114098725600903175) 里的“**缓存区域不随帧变化，以便得到最小化的构建**”。

**当然类似   `AnimatedBuilder`   的构建方式还要注意 `context` 问题，不要拿错  `context`**  ，这也是很多时候会犯的潜在错误，特别是在调用 `of(context)` 的时候。

*那有的人可能到这里会觉得，那你之前一直说  Widget 很轻，Widget 不是真正的控件，那 rebuild 多几次有什么问题*？

一般情况下确实不会有太大问题，但是当你的控件有   ` Opacity `  、`ColorFilter` 、 `ShaderMash`  或者  `ClipRect`（`Clip.antiAliasWithSaveLayer`）时，就可能会有较大的性能影响，因为他们都是可能会触发  `saveLayer` 的操作。

> 为什么 `saveLayer` 对性能影响很大？因为需要在 GPU 绘制是需要增加额外的缓冲区域，粗俗点说就是需要做图层的保存和合成，这就会对 GPU 渲染时产生较大影响的耗时。

而这里面最常遇到的应该就是    ` Opacity `   带来的性能问题，因为它看起来是那么的轻便，但是从官方的介绍里，除非真的有必要，不然可以使用效果类似的实现去做场景替代，例如：

**你需要对图片做透明度相关的动画是，那么使用 `AnimatedOpacity` 或 `FadeInImage` 代替  ` Opacity `    会对性能更有帮助**。

> `AnimatedOpacity`  和  ` Opacity `    不一样吗？某种程度上还真不大一样，  ` Opacity  ` 的内部是 `pushOpacity ` 的操作，而  `AnimatedOpacity`  里虽然有 `OpacityLayer` ，但是变动时是 `updateCompositedLayer` ；而  `FadeInImage`  会使用 GPU 的 fragment shader 去处理透明度的问题，所以性能也会更好一些。

或者在类似有颜色透明度的场景时，可以通过 `Color.fromRGBO` 来替代  `Opacity` ，**除非你需要将不透明度应用到一大组较为复杂的 child 里，你才会需要使用  `Opacity`**  。

```dart
/// no
Opacity(opacity: 0.5, child: Container(color: Colors.red))
  
/// yes  
Container(color: Color.fromRGBO(255, 0, 0, 0.5))
```

另外还有 `IntrinsicHeight` / `IntrinsicWidth` 的场景，**因为它们是可以通过 child 的内部宽高来调整 child 的大小**，但是这个推算布局的过程会比较费时，可能会到 O（N²），虽然 Flutter 里针对这部分计算结果做了缓存，但是不妨碍它的耗时。

这么说可能有点抽象，举一个官方介绍过的例子，如下代码所示，当你在 `ListView` 里对 `Row` 的 `children`  进行 `Align` 排列时，你可能会发现它没有效果，因为此时通过 `Border` 可以看到，绿色和蓝色方框的父容器大小一致。

| ![](http://img.cdn.guoshuyu.cn/20221021_N13/image14.png) | ![](http://img.cdn.guoshuyu.cn/20221021_N13/image15.png) |
| -------------------------------------------------------- | -------------------------------------------------------- |

但是在加上 `IntrinsicHeight` 之后， 因为通过  `IntrinsicHeight`  的测算之后再返回 size，`Row` 里的三个 Item 现在高度一致，，这时候 `Align` 就可以生效了，但是正如前面所说，这个操作性对性能来说相对昂贵，虽然系统有缓存参数，但是如果出现动画 rebuild ，也会对性能造成影响。

| ![](http://img.cdn.guoshuyu.cn/20221021_N13/image16.png) | ![](http://img.cdn.guoshuyu.cn/20221021_N13/image17.png) |
| -------------------------------------------------------- | -------------------------------------------------------- |

> 对这部分感兴趣的可以看 ： [《带你了解不一样的 Flutter》](https://juejin.cn/post/7053777774707736613#heading-2)

**到这里我们就理解了 （函数方式） 和 （Component Class 方式）组织布局的不同之处，同时也知道了 Component Class 方式可以帮助我们更好地调试布局代码，也举例了一些 UI 布局里常见的耗时场景**。

那本篇的小技巧到这里就结束了，如果你还有什么感兴趣或者有疑惑的，欢迎留言评论～