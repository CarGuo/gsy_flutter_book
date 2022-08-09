# Flutter 实现 “真” 3D 动画效果，用纯代码实现立体 Dash 和 3D 掘金 Logo



我正在参加「创意开发 投稿大赛」详情请看：[掘金创意开发大赛来了！](https://juejin.cn/post/7120441631530549284)

**本篇将给你带来更加炫酷动画效果，最后教你如何通过纯代码实现一只立体的 Flutter 的吉祥物 Dash 和 3D 的掘金 logo 动画**。

> ❤️ **本文正在参加征文投稿活动，还请看官们走过路过来个点赞一键三连，感激不尽～**

在之前的 [《炫酷的 3D 卡片和帅气的 360° 展示效果》](https://juejin.cn/post/7124064789763981326) 里，我们使用手势代码和角度切换，在 2D 画板里实现了“伪” 3D 的视觉效果，就在我觉得效果还不错时， 有一位掘友提出了一个关键性的问题：**卡片缺少厚度，也就是没有 3D 的质感** 。

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image1.gif) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image2.png) |
| -------------------------------------------- | ------------------------------------------------------------ |

确实，如下图所示，在之前的实现里，随着卡片角度的倾斜，有两个问题特别明显：

- 当卡片旋转到侧边时，卡片的缺少“厚度”的质感，**甚至出现了消失的情况**
- 卡片上的文字虽然做了类似凹凸的视觉效果，但是从侧面看时也是缺少立体质感

![](http://img.cdn.guoshuyu.cn/20220806_N11/image3.gif)

而为了在 2D 平面实现三唯的质感，在查阅相关资料时我发现了前端的 [Zdog](https://zzz.dog) 框架，**Zdog 是一个使用 `Canvas` 实现的伪 3D 引擎， 它支持通过 2D 的  `Canvas`  API渲染出类似 3D 的效果**。

> [Zdog](https://zzz.dog)  作为一个 js 框架，它大概只有 2800 多行代码，并且其最小体积为 28KB ，可以说十分轻量级。

![](http://img.cdn.guoshuyu.cn/20220806_N11/image4.gif)



虽然 Zdog  是一个纯 js 框架， 但既然它是通过 `Canvas` 实现的逻辑，那就完全可以 “轻松” 迁移到 Flutter ，毕竟 Flutter 本身就是一个重度依赖于 `Canvas`  的框架，而恰巧在 Flutter 社区就有针对 Zdog 的移植版本： [zflutter](https://pub.flutter-io.cn/packages/zflutter) 。

> 虽然这个 package 作者已经两年不维护，也没有发布 null-safety 的 pub 支持，但是既然是开源项目，自己动手风衣足食，在经过一番“简单”的迁移适配之后， [zflutter 再次在 Flutter 3.0 下“焕发新春”](https://github.com/carguo/zflutter) 。

我们先看效果，在结合 zflutter 的实现之后，可以看到卡片的立体效果得到了全面的提升：

- **首先卡片有了厚度的质感，旋转到侧边也不会“消失”**
- **卡片上的字体在倾斜时也有了立体的效果**

![](http://img.cdn.guoshuyu.cn/20220806_N11/image5.gif)

那在讲解实现之前，我们要解决一个疑惑： **zflutter 究竟是如何在 2D 画板上实现 3D 的质感** ？而其实这个问题的关键就在于：**通过手势产生的矩阵变换是作用于画板还是作用于路径**  。

我们首先看一个例子，如下代码所示，我们创建了一个 `CustomPaint` ，然后在代码里绘制了 4 条相同红色直线，接着对其中 3 条直线的 `Canvas` 进行不同程度的矩阵旋转，如下图 2 可以看到有两条红线消失不见了：

- 当红线绕 Y 轴旋转 `pi / 2`（90°）时，因为此时画板恰好和我们呈垂直状态，所以会出现看不到的情况
- 当红线绕 XY 轴旋转  `pi / 4` 时，可以看到画板此时和我们视觉成 45° 的情况
- 当红线绕 XY 轴旋转   `pi / 2`（90°） 时，因为此时画板还是和我们呈垂直状态，所以出现看不到的情况

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image6.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image7.png) |
| :----------------------------------------------------------- | ------------------------------------------------------------ |

如果觉得上面的描述太抽象，那么结合下面动图，可以看到当红线在围绕 XY 轴做旋转时，如果画布(`Canavas`)和我们呈 90° 垂直的时候，此时就会出现消失不见的情况，**因为画布是 2D 的平面，这也是为什么之前实现的卡片没有“厚度”的原因** 。

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image8.gif) | ![](http://img.cdn.guoshuyu.cn/20220723_N9/image6.png) |
| --------------------------------------------- | ------------------------------------------------------------ |

**那如果不对 `Canavs` ，而是对绘制路径 `Path` 进行矩阵变换呢** ？不对画布进行旋转，不就不会出现消失的情况了吗？

如下代码所示，同样是围绕 XY 轴进行旋转，但是此时是直接对 `Path` 进行 `path.transform` 操作，也就是此时画布`Canvas` 不会出现角度变换，出现变化的是绘制的  `Path`  路径，可以看到：

- 当红线绕 Y 轴旋转 `pi / 2`（90°）时，此时红线成了红点，因为它此时它是“头正对着我们”
- 当红线绕 XY 轴旋转  `pi / 4` 时，可以看到此时红线整体成 45° 的情况对着我们
- 当红线绕 XY 轴旋转   `pi / 2`（90°） 时，可以看到此时红线是“垂直正对着我们”

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image9.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image10.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

结合下面的动图，可以看到对  `Path`  进行矩阵变换的旋转之后，整体的立体感就不一样了，**也就是一开始是调整我们和画布之间的角度，但是现在我们是改变了“笔”在画布上的绘制方式来产生的视差，这也是 zflutter 里实现 3D 立体感的关键：对 `Path` 做矩阵运算而不只是对 `Canvas`** 。

![](http://img.cdn.guoshuyu.cn/20220806_N11/image11.gif)

题外话，借着这个机会顺带普及个小知识点：**在前面的代码里可以看到会对矩阵进行 `leftTranslate` 和 `translate`  的操作** ，这是因为我们需要在不同位置绘制多条红线，所以它们的位置并非都在起点，而使用 `leftTranslate` 和 `translate`   来对矩阵进行平移，才能达到每次旋转时都是以红线的“中心”去旋转，举个例子：

- 如图 1 所示是红线没有绕 Z 轴旋转的情况
- 如图 2 所示是红线在绕 Z 轴旋转 `pi / 2` 时没有进行矩阵平移的情况，可以看到此时它们的中心点还在起始位置
- 如图 3 所示是红线在绕 Z 轴旋转  `pi / 2`  时，进行了  `leftTranslate` 和 `translate`  操作的情况

| ![](https://img.cdn.guoshuyu.cn/Simulator%20Screen%20Shot%20-%20iPhone%20SE%20(3rd%20generation)%20-%202022-08-04%20at%2010.18.23.png) | ![](https://img.cdn.guoshuyu.cn/Simulator%20Screen%20Shot%20-%20iPhone%20SE%20(3rd%20generation)%20-%202022-08-04%20at%2010.18.38.png) | ![](https://img.cdn.guoshuyu.cn/Simulator%20Screen%20Shot%20-%20iPhone%20SE%20(3rd%20generation)%20-%202022-08-04%20at%2010.18.12.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |

> 完整代码可见： https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/transform_canvas_demo_page.dart
>
> Web 体验地址，PC 端记得开 Chrome 手机模式：https://guoshuyu.cn/home/web/#%E5%B1%95%E7%A4%BA%20canvas%20transform  。

那么回到 zflutter 里，**在 zflutter 里就是通过组合各类图形和线条，然后利用对 `Path`  进行矩阵变换，从而实现类似 3D 立体的视觉效果** ，例如下面图 2 的立体正方形，就符合我们对增加厚度的需要。

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image12.gif) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image13.gif) |
| ----------------------------------------------- | ----------------------------------------- |

这里先简单介绍下 zflutter 里常用对象的作用：

- `ZIllustration`  类似于画板的作用，可以配置 `zoom` 属性来调整画板的缩放
- `ZPositioned` 用于配置位置和大小信息，例如 `scale` 、`translate` 、 `rotate` 等属性(其实它就是在内部将接收到的矩阵参数配置到 `ParentData` ，然后传递给 child)
- `ZDragDetector` 用于处理手势相关信息，主要是配置  `ZPositioned` 的  `rotate`  就可以快速实现上面的 360° 拖拽效果
- `ZGroup` 用于组合多个图形的层叠
- `ZToBoxAdapter` 用于嵌套普通的 Flutter 控件
- `ZRect` 、`ZRoundedRect` 、 `ZCircle` 、`ZEllipse` 、`ZPolygon`  、`ZCone` 、`ZCylinder` 、`ZHemisphere` 等是内置的形状，如下图
- `ZShape` 类似于 Canvas ，用于配合 `ZMove` 、`ZLine`  、`ZBezier` 、`ZArc` 等绘制自定义形状

![](http://img.cdn.guoshuyu.cn/20220806_N11/image14.png)

所以要实现卡片的 “真” 3D 效果，简单来说我们需要做的是：

- 添加一个 `ZIllustration` 画布
- 添加一个 `ZDragDetector `  配合 `ZPositioned` 用于处理手势旋转
- 添加一个 `ZGroup` ，然后在里面通过 `ZToBoxAdapter` 添加银行卡的前后两张 png 图片
- 在两张图片之间添加一个 `ZRoundedRect`  做边框，配置颜色为 ` Color(0x8A000000);` 实现厚度效果
- 利用 `ZShape` 绘制数字，这样绘制出现的数字就会有立体的感觉

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image15.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image16.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image17.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |

如上图所示，可以看到经过 zflutter 的处理之后，**不只是卡片本身有了“厚度”的质感，在倾斜也可以看到文字立体视觉，现在就算是如图 3 一样旋转到 90° 的情况，依然可以看到卡片和文字之间的层次关系** 。

> 完整代码可见： https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/card_real_3d_demo_page.dart
>
> Web 体验地址，PC 端记得开 Chrome 手机模式： https://guoshuyu.cn/home/web/#%E7%A1%AC%E6%A0%B8%203D%20%E5%8D%A1%E7%89%87%E6%97%8B%E8%BD%AC 。

详细源码可以直接看上方链接，那认识了 zflutter 之后，**我们还能利用 zflutter做什么呢**  ？其实在官方的 Demo 里就有一个很有典型的示例，那就是 Flutter 的吉祥物 Dash ，**接下来我们看如何利用 zflutter 开始实现一只立体质感的 Dash** 。

首先我们利用 `ZCircle` 画一个圆，用于实现 Dash  的身体

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image18.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image19.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

然后我们通过 3 个不同位置和角度的 ` ZEllipse` 椭圆来组成 Dash 的头发，事实上 zflutter 里很多效果就是通过类似这样的图形组合来实现的。

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image20.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image21.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

接着我们在 `ZShape`  里利用 `ZArc` 实现不同角度的弧形组合实现尾巴，这里的关键是 z 轴上需要有部分落差，如下图展示是尾巴在 3 个不同角度的可视效果。

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image22.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image23.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

再通过调整两个  ` ZEllipse`  椭圆的角度来实现 Dash 的手部效果，在这一点上 zflutter 确实很考验开发者对于图形在平面上的空间感。

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image24.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image25.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

接着通过 `ZCone` 就可以快速实现 Dash 的嘴巴。

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image26.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image27.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

然后这部分相信不用代码大家也知道，就是通过组合多个  `ZEllipse` 和 `ZCircle` 堆叠来实现 Dash 的眼睛。

![](http://img.cdn.guoshuyu.cn/20220806_N11/image28.png)

最后，把上面的零部件组合到一起，在配置上循环的动画参数，当当当～一只生动立体的 Dash 就完成了。

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image29.gif) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image30.gif) |
| ----------------------------------------- | ----------------------------------------- |

> 完整代码可见： https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/dash_3d_demo_page.dart
>
> Web 体验地址，PC 端记得开 Chrome 手机模式： https://guoshuyu.cn/home/web/#3D%20Dash 。

对比实物 Dash ，可以看到利用 zflutter 实现的 Dash ，乍看之下形似度还是蛮高的，同时 zflutter 本身也只有 82k 左右的大小，作为一个超轻量级的伪 3D 动画框架，它在接入成本很低的情况下，尽可能做到了我们对 3D 空间所需的视觉效果，这里面的关键还是在于：**矩阵变换是作用于画板还是作用于路径**  。

![](http://img.cdn.guoshuyu.cn/20220806_N11/image31.png)

那在知道原理之后，**我们接下来就可以通过三个简单的 `ZShape`  组合，利用  `ZMove` 和  `ZLine` 就能组合出具有 3D 质感的掘金 Logo ，里面的参数直接从 SVG 的 path 映射过来就可以了** 。

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image32.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image33.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image34.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image35.gif) |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ---------------------------------------------- |

因为我们的矩阵旋转改变的是 Path 而不是 Canvas ，所以 Logo 的立体效果可以通过 `skroke`  的粗细配合画布 `zoom`  放大来体现。

> 完整代码可见： https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/juejin_3d_logo_demo_page.dart
>
> Web 体验地址，PC 端记得开 Chrome 手机模式： https://guoshuyu.cn/home/web/#%E6%8E%98%E9%87%91%203d%20logo 。

**那可能就有人要说了，这个 logo 立体感还是不够强，因为它还是太扁平了** ～ 确实，受制于 `stroke` 参数的影响，在侧面的立体感上确实有所缺失，而为了提升立体感，我们可以通过 zflutter 里的 `ZBoxToBoxAdapter`  来实现。

在 zflutter 里， `ZBoxToBoxAdapter`  可以通过配置 `front` 、`rear` 、`left` 、`right` 、`top` 、`bottom` 等参数来配置长方体每个面的 UI，并且它本身就会根据 `width` 、`height` 、`depth`  参数生成一个立体长方形，如下图 1所示。

| ![](https://img.cdn.guoshuyu.cn/Simulator%20Screen%20Shot%20-%20iPhone%20SE%20(3rd%20generation)%20-%202022-08-05%20at%2016.34.37.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image36.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image37.gif) |
| ------------------------------------------------------------ | -------------------------------------------------------- | -------------------------------------------------------- |

接着我们简单通过图 2 的量角器确定掘金 logo 的角度，然后如下代码所示，利用不同位置和角度，通过  `ZBoxToBoxAdapter`   组合堆叠不同的长方体，从而形成如上图 3 所示的立体掘金 logo，**当然，这个组合过程很明显是体力活**。

| ![](http://img.cdn.guoshuyu.cn/20220806_N11/image38.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image39.png) | ![](http://img.cdn.guoshuyu.cn/20220806_N11/image40.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |



> 完整代码可见： https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/juejin_3d_box_logo_demo_page.dart
>
> Web 体验地址，PC 端记得开 Chrome 手机模式： https://guoshuyu.cn/home/web/#%E6%8E%98%E9%87%91%E6%9B%B4%203d%20logo 。



可以看到 zflutter 虽然没有之前 [用 rive 给掘金 Logo 快速添加动画效果 ](https://juejin.cn/post/7126661045564735519)来的强大和方便，**但是好在它体积够小，不需要加载任何资源，纯代码就可以实现各种立体的 3D 动画效果** ，这对于程序员来说更加可控，至少它不需要依赖于任何第三方设计工具，就是开发速度上确实不如 rive 来的高效，**需要一定的空间想象力** 。

好了，本篇动画特效就到此为止，**如果你有什么想法，欢迎留言评论，感谢大家耐心看完，也还请看官们走过路过的来个点赞一键三连，感激不尽** ～