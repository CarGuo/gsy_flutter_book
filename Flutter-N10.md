# 给掘金 Logo 快速添加动画效果，并支持全平台开发框架

![](http://img.cdn.guoshuyu.cn/20220731_N10/image1.gif)

我正在参加「创意开发 投稿大赛」详情请看：[掘金创意开发大赛来了！](https://juejin.cn/post/7120441631530549284)

**如果需要在 Android、 iOS、Web、Desktop 等平台快速实现如上图所示的动画效果，你第一考虑会怎么做**？

也许你会说使用 Flutter ？不不不，如果还需要兼容多技术栈呢？例如支持 Flutter 、React、Vue、C++ 等不同语言和技术平台呢？

这时候也许你会想到 [Lottie](https://lottiefiles.com/) ，诚然 Lottie 的动画效果确实十分优秀，也支持 Android、 iOS、React Native、Web、 Windows 等平台，但是它的输入来源于 After Effects 动画特效，并且依赖于 `Bodymovin` 插件，这对于个人开发或者  UI 设计师来说，从 0 开始学习的门槛还是不低的。

![](http://img.cdn.guoshuyu.cn/20220731_N10/image2.gif)



**而本篇将给你推荐另外一个更简单又强大的动画开发平台： [rive](https://rive.app)**  ，对于 rive 可能大家会感觉比较陌生，做过 Flutter 开发的可能对 rive 会有所耳闻，因为 rive 在此之前叫 flare ，是 2dimensions 公司的开源动画产品，在发布之初由于和 Flutter 团队有深入合作，所以在初期一直是 Flutter 官方推荐的动画框架。

后来由于 flare 项目被合并所以升级为 rive ，**升级后的 rive 开始把动画效果拓展到全平台，这个全平台不只是物理设备的全平台，还包括了跨语言和框架的全平台，不过可惜和第一代 flare 存在断档不兼容**。

| ![](http://img.cdn.guoshuyu.cn/20220731_N10/image3.gif) | ![](http://img.cdn.guoshuyu.cn/20220731_N10/image4.png) |
| ------------------------------------------ | ------------------------------------------------------------ |

本篇之所以推荐 rive 来实现多端动画，主要有以下几个原因：

- 支持手机端、Web 端 和PC 端等平台支持
- 支持 React 、Flutter、Unity 等多种框架，Vue 和 Angular 也有社区支持
- 支持 JS、Dart、C++ 等多种语言
- **不用安装工具，直接 Web [Editor](https://editor.rive.app/) 就可以进行可视化开发，并附带工程管理**

| ![](http://img.cdn.guoshuyu.cn/20220731_N10/image5.png) | ![](http://img.cdn.guoshuyu.cn/20220731_N10/image6.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

**无需安装，打开即用，多平台多语言支持就是本次推荐 rive 的主要原因**，那么回到主体，接下来我们将通过 rive 来实现一个掘金动画 logo。

首先打开 rive 的  Web [Editor](https://editor.rive.app/)  ，这里需要你有账户登陆，注册登陆是免费的，在登陆之后我们就可以进入到 rive 的动画编辑界面。

因为我们是要基于掘金的 logo 实现一个动画，所以开始之前可以先拿到掘金 logo 的 svg ，这里**只需要直接从文件夹把 svg 文件拖拽到   Web  Editor 里就可以**，它会自己自动上传，上传成功之后就可以看到下图的界面效果。

![](http://img.cdn.guoshuyu.cn/20220731_N10/image7.png)

如果你说我没有 svg 文件怎么办？不用担心， rive 提供丰富又简单的绘制工具，如下图 1 所示，通过 Pen Tool 你就可以快速绘制出一些简单的图形，复杂的路径也可以如图 3 一样描绘出来。

| ![](http://img.cdn.guoshuyu.cn/20220731_N10/image8.png) | ![](http://img.cdn.guoshuyu.cn/20220731_N10/image9.gif) | ![](http://img.cdn.guoshuyu.cn/20220731_N10/image10.gif) |
| ------------------------------------------------------------ | -------------------------------------------------------- | ------------------------------------------------------------ |

回到上传完 svg 的界面，这时候主要看 3 部分：

- 红框 1 里的是 Artboards 画板(`brand-with-text.svg`) 和画板内的各种 Shape 图形
- 选中 Shape 图形，可以看到红框 2 里对应的图形进入可操作的状态
- 红框 3 是用于切换设计和动画界面，在设计（Design）界面下是调整 UI ，在动画（Animate）界面是调整动画效果。

![](http://img.cdn.guoshuyu.cn/20220731_N10/image11.png)

如下图所示，当我们选中一个 Shape 的时候，你就可以对图形进行移动、旋转、缩放等操作，从而来调整 UI 的变化，达到我们需要的动画效果。

![](http://img.cdn.guoshuyu.cn/20220731_N10/image12.gif)

接下来我们点击切换到 Animate 下，可以看到此时地步多了一个时间轴，**这个时间轴就是我们控制整个动画过程的关键**，这里为了实现前面的动画效果，首先需要把整个掘金 logo 挪动到了画布的外面，为后面的掉落动画做准备。

![](http://img.cdn.guoshuyu.cn/20220731_N10/image13.png)

接下开始我们的动画，开始之前我们随意调整 svg 里图形的位置或者角度 ，比如：

- 这里对【稀】字进行了55° 的旋转
- 对【掘】字进行了 -180°  的旋转
- 对 【金】字行了50° 的旋转
- 对 logo 上的小方块位置调整移动

![](http://img.cdn.guoshuyu.cn/20220731_N10/image14.png)

做完上面的操作之后，**可以看到时间轴上多了一排点，这些点就是当前动画 Shape 在这个时间戳上的状态** ，如果你觉得用鼠标控制不够精确，你也可以在右边的窗口上对参数进行精确调整。

| ![](http://img.cdn.guoshuyu.cn/20220731_N10/image15.png) | ![](http://img.cdn.guoshuyu.cn/20220731_N10/image16.png) | ![](http://img.cdn.guoshuyu.cn/20220731_N10/image17.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |

另外如上图 2 所示，在时间轴上可以通过调整 Duration 来设定动画的总时长，还可以调整动画循环播放等等。

接下来就是体力活了， 比如我们需要掘金 logo 从顶部掉下来，那么我们可以在时间轴上拖动蓝色的进度到合适位置，然后挪动图形，然后就可以看到时间戳上多了新的状态点，接着点击播放就可以看到动画效果。

![](http://img.cdn.guoshuyu.cn/20220731_N10/image18.gif)

如果你需要两个 Shape 之间掉落存在时间差，那么如下图所示，你可以直接调整时间轴上对应的点位，就可以轻松实现动画里 Shape 的移动时间差。

![](http://img.cdn.guoshuyu.cn/20220731_N10/image19.gif)



这里有一个需要注意的是，当你选中时间戳上的某个节点时，在右侧是可以调整动画的插值状态的，默认情况下是线性 Linear ，但是我们可以根据需要设置想要的 Cubic 计算方式。

![](http://img.cdn.guoshuyu.cn/20220731_N10/image20.png)

不同 Interpolation 效果如下图所示，其中 Cubic 状态下是可以自定义调整动画的插值计算方式，所以一般情况下都会选择 Cubic 来调整动画的插值计算。

| Linear                                           | Cubic                                           | Hold                                           |
| ------------------------------------------------ | ----------------------------------------------- | ---------------------------------------------- |
| ![](http://img.cdn.guoshuyu.cn/20220731_N10/image21.gif) | ![](http://img.cdn.guoshuyu.cn/20220731_N10/image22.gif) | ![](http://img.cdn.guoshuyu.cn/20220731_N10/image23.gif) |

通过调整动画的差值效果，就可以让生硬的动画过度变得更加自然，例如下图就通过调整 Cubic Points 之后，可以实现快进慢出的效果。

![](http://img.cdn.guoshuyu.cn/20220731_N10/image24.gif)

而在经历一系列【体力劳动】之后，你就可以看到类似下图的效果，通过对各种 Shape 进行移动，旋转，缩放，然后通过  Cubic Points  调整动画的丝滑程度，最后排布好时间戳，就可以完成最初的动画效果。

![](http://img.cdn.guoshuyu.cn/20220731_N10/image25.gif)

> 这不比你用代码和意念写来的香？

当然，这里还有一个需要注意的是，**如果你存在多个画板和动画，那么画板名字和动画名字的命名就很重要**，因为如可能会需要在代码里需要用它来指定动画效果，当然，**这也代表了你可以在一个 rive 文件你设置多组画板和多组动画效果**。

![](http://img.cdn.guoshuyu.cn/20220731_N10/image26.png)

然后你就可以导出 rive 文件到工程里去使用，同时 rive 文件是支持本地加载和远程加载的，官方贴心地提供了分享链接，你可以把动画通过 Embed link 或者 iframe 添加到 Web 里，甚至还贴心地提供了 React 代码复制。

| ![](http://img.cdn.guoshuyu.cn/20220731_N10/image27.png) | ![](http://img.cdn.guoshuyu.cn/20220731_N10/image28.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

例如在 Flutter 里，你可以通过  `RiveAnimation.network` 或者 `RiveAnimation.asset` 来加载动画文件，当然你也可以自定义 `RiveAnimationController`  来做一些自定义控制，比如通过  `animationName`  来指定对应的动画效果。

```js
class SimpleAnimation extends StatelessWidget {
  const SimpleAnimation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: RiveAnimation.network(
          'https://cdn.rive.app/animations/vehicles.riv',
        ),
      ),
    );
  }
}
```

当然，前面介绍的只是简单的动画效果，rive 其实可以实现很强的各种动画交互，比如：

- 通过 Bone 来设置骨骼交互
- 通过 Draw Order 动态设置层级交替

| ![](http://img.cdn.guoshuyu.cn/20220731_N10/image29.gif) | ![](http://img.cdn.guoshuyu.cn/20220731_N10/image30.gif) |
| -------------------------------------------------- | -------------------------------------------- |

甚至在 rive 里还有 **State Machine  模式，从而支持根据不同条件和逻辑状态触发不同的动画效果，节省可开发者需要在代码里进行逻辑判断的部分，并且这部分逻辑是可以跨平台跨语言支持**。

| ![](http://img.cdn.guoshuyu.cn/20220731_N10/image31.gif) | ![](http://img.cdn.guoshuyu.cn/20220731_N10/image32.gif) |
| -------------------------------------------- | ---------------------------------------------------- |

> 更多 rive 的丰富功能可查阅  https://help.rive.app

那么到这里，相信大家最关心的问题就是：**rive 能不白嫖 ？答案是可以的！** rive 默认对于 free 用户来说支持 3 个文件免费，这对于个人而言其实够用，因为前面说的，rive 支持一个文件下创建多个画板和多个动画，所以正常情况下个人使用 3 个免费的限制其实问题不大。

![](http://img.cdn.guoshuyu.cn/20220731_N10/image33.png)

同时 rive 社区也有很多免费开放的动画资源，对于懒癌患者来说也是不错的选择之一，**当然你也可以把文章转发给设计师，安利他们使用 rive，将开发成本“嫁接”给他们，你只负责岁月静安地用几行代码完成动画接入就可以了**。

![](http://img.cdn.guoshuyu.cn/20220731_N10/image34.gif)



**rive 就是这么一个将 “开发不行” 变成 “设计不行” 的工具，相比较 AE ，它不需要安装工具，而且操作更加简单支持，如果没有设计师也可以自己上手，这也是我最近喜欢上 rive 的原因**。

如果你对 rive 还有什么想法或者疑问，欢迎留言交流～

