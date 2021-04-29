关于 Spuernova 我曾在 [《Flutter Interact 的 Flutter 1.12 大进化和回顾》](https://juejin.im/post/5df2366b6fb9a016510da009) 中介绍过：在 2019 年末的 Flutter Interact 大会上，Spuernova 发布了对 Flutter 的支持，**通过导入设计师的 Sketch 文件从而生成 Flutter 代码**，这无疑提升了 Flutter 的生产力和可想象空间。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Supernova/image1)

自动生成代码的方式并不罕见，可能不少有过类似经验的开发者会表示“不屑一顾”，也可能会有节奏党再一次拉起“开发药丸”的大旗，当然这次要分享的不会是这些，这次想要分享的是： **Spuernova 可以成为开发者和设计师之间另类的沟通桥梁**。

> **一般情况下设计师和程序员之间是存在某种程度的“生殖隔离”**，设计师产出的效果在开发手上很容易“难产”，那么如何给设计师解释“为什么做不了”和“需要怎么做”就是一件很费劲的事情，甚至关乎到“信任问题”。

**Spuernova 对 Flutter 的支持，可以让设计师很直观地知道 Flutter 能做到什么程度，从而让设计师能够更好地规范 UI 效果，提供沟通的友好度**。

举个例子，如下图所示，在设计过程中 *阴影*、*模糊* 和 *渐变* 是常见的效果，而这些效果在 Sketch 上也可以很容易地被实现。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Supernova/image2)

但是这些效果在 Flutter 中能够被完美还原吗？

如下图所示，这时候设计师只需要将 Sketch 文件导入到 Spuernova 中，就可以直观地看到设计稿在 Flutter 中的默认渲染效果。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Supernova/image3)

从上图可以看到，**Sketch 中的阴影效果被完美还原，但是模糊和渐变效果却发生了一些变化，说明了这个效果在 Flutter 上“并不支持”** 。

> **这时候并不是说 Flutter 就完全没办法还原出设计稿的效果，只是说默认情况下官方并没有支持，所以实现这种效果需要一定成本**。

首先如下图所示，在选择阴影框的时候，可以看到在设计稿中的阴影在 Flutter 可以使用 `boxShadow` 实现，而  `boxShadow`  对应的实现代码被放在 `shadows.dart` 文件中。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Supernova/image4)

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Supernova/image5)

接着查看 `shadows.dart`  文件，可以看到对应的 `primaryShadow` 实现代码，**这时候开发就可以直接 cv 样式代码，不需要对着设计稿一遍一遍的调整参数**，并且在 Supernova 的右侧还有对应给设计师调整参数的工具栏，从而提供了设计和开发之间另类的“沟通语言”。


![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Supernova/image6)

接着看模糊阴影实现，该效果在 Flutter 代码上直接消失了，其实高斯模糊的效果在 Flutter 上是可以实现，这里不过是单纯因为“纯色”效果而导致无法被正常“识别”。


![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Supernova/image7)


接着看渐变效果，渐变效果在 Flutter 上是用 `Gradient` 实现的，只是设计稿中的渐变效果在 Flutter 上被识别为 `LinerGradient` ，呈现效果出现了偏差。

> 这里应该被识别为 `RadialGradient` 更为贴切，只是想要完成实现设计稿的效果还是有些难度。


![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Supernova/image8)

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Supernova/image9)

从上述例子可以看到 Spuernova 并不完美，甚至在列表、点击、动画等常见效果上还需要做额外的配置，**但是对于我而言 Spuernova 是和设计师沟通的平台，它用更直观的方法告诉了设计师“能做什么”，并且快速让我知道“需要做什么”。**


另外还有一个惊喜就是：**Spuernova 还支持 Sketch “转译” 为 Android 、iOS 和 react-native 代码，但是另一个惊喜就是除了 Flutter 之外其他需要收费。**


![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Supernova/image10)


**总的来说 Spuernova 确确实实提升了 Flutter 工程师的生产力，能在一定程度上成为设计师和程序员之间的“桥梁”，虽然它并不完美，但是值得一试。**


![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Supernova/image11)