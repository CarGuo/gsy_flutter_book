#  如何利用 Flutter 实现炫酷的 3D 卡片和帅气的 360° 展示效果



我正在参加「创意开发 投稿大赛」详情请看：[掘金创意开发大赛来了！](https://juejin.cn/post/7120441631530549284)

本篇将带你在 Flutter 上快速实现两个炫酷的动画特效，希望最后的效果可以惊艳到你。

这次灵感的来源于更新 MIUI 13 时刚好看到的卡片效果，其中除了卡片会跟随手势出现倾斜之外，内容里的部分文本和绿色图标也有类似悬浮的视差效果，恰逢此时灵机一动，**我们也来用 Flutter 快速实现炫酷的 3D 视差卡片，最后再拓展实现一个支持帅气的  360°  展示的卡片效果**。

> ❤️  **本文正在参加征文投稿活动，还请看官们走过路过来个点赞一键三连，感激不尽～**

![](http://img.cdn.guoshuyu.cn/20220723_N9/image1.gif)





既然需要卡片跟随手势产生不规则形变，我们第一个想到的肯定是**矩阵变换**，在 Flutter 里我们可以使用 `Matrix4` 配合 `Transform` 来实现矩阵变换效果。

开始之前，首先我们创建用  `Transform`  嵌套一个  `GestureDetector` ，并绘制出一个 300x400 的圆角卡片，用于后续进行矩阵变换处理。

```dart
Transform(
  transform: Matrix4.identity(),
  child: GestureDetector(
    child: Container(
      width: 300,
      height: 400,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueGrey,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  ),
);
```

![](http://img.cdn.guoshuyu.cn/20220723_N9/image2.png)

接着，如下代码所示，因为我们需要卡片跟随手势进行矩阵变换，所以我们可以直接在 `GestureDetector` 的  `onPanUpdate`  里获取到手势信息，例如 `localPosition` 位置信息，然后把对应的 `dx` 和 `dy`赋值到 `Matrix4` 的  `rotateX` 和 `rotateY` 上实现旋转。

```dart
child: Transform(
  transform: Matrix4.identity()
    ..rotateX(touchY)
    ..rotateY(touchX),
  alignment: FractionalOffset.center,
  child: GestureDetector(
    onPanUpdate: (details) {
      setState(() {
        touchX = details.localPosition.dx;
        touchY = details.localPosition.dy;
      });
    },
    child: Container(
```

这里有个需要注意的是：**上面代码里 `rotateX` 使用的是  `touchY` ，而 `rotateY` 使用的是 `touchX`** ，为什么要这样做呢？

> ⚠️举个例子，当我们手指左右移动时，是希望卡片可以围绕 Y 轴进行旋转，所以我们会把  `touchX`  传递给了 `rotateY` ，同样   `touchY`  传递给 `rotateX`  也是一个道理。

![](http://img.cdn.guoshuyu.cn/20220723_N9/image3.png)

但是当我们实际运行上述代码之后，如下图所示，可以看到基本上我们只是稍微移动手指，卡片就会陷入疯狂旋转的情况，并且实际的旋转速度会比 GIF 里快很多。

![](http://img.cdn.guoshuyu.cn/20220723_N9/image4.gif)



**问题的原因其实是因为 `rotateX` 和  `rotateY` 需要的是一个 `angle` 参数**，假设这里对 `rotateX` 和 `rotateY` 设置  `pi / 4` ，就可以看到卡片在 X 轴和 Y 轴上都产生了 45 度的旋转效果。

```dart
 Transform(
    transform: Matrix4.identity()
      ..rotateX(pi / 4)
      ..rotateY(pi / 4),
    alignment: FractionalOffset.center,
```

![](http://img.cdn.guoshuyu.cn/20220723_N9/image5.png)

所以如果直接使用手势的  `localPosition`  作用于 `Matrix4` 肯定是不行的，我们首先需要对手势数据进行一个采样，**因为代码里我们设置了 `FractionalOffset.center` ，所以我们可以用卡片的中心点来计算手指位置，再进行压缩处理**。

如下代码所示，我们通过以卡片中心点为原点进行计算，其中 `/ 2` 就是得到卡片的中心点，`/ 100` 是对数据进行压缩采样，*但是为什么 `touchX` 和  `touchY` 的计算方式是相反的呢*？

```dart
touchX = (cardWidth / 2 - details.localPosition.dx) / 100;
touchY = (details.localPosition.dy - cardHeight / 2 ) / 100;
```

如下图所示，**因为在设置 `rotateX` 和 `rotateY` 时，赋予 `> 0` 的数据时卡片就会以图片中的方向进行旋转**，由于我们是需要手指往哪边滑动，卡片就往哪边倾斜，所以：

- 当我们往左水平滑动时，需要卡片往左边倾斜，也就是图中绕 Y 轴转动的 `>0` 的方向，并且越靠近左边需要正向的 Angle 数值越大，由于此时 `localPosition.dx`  是越往左越小，所以需要利用 `CardWidth / 2 - details.localPosition.dx`  进行计算，得到越往左有越大的正向 Angle 数值
- 同理，当我们往下滑动时，需要卡片往下边倾斜，也就是图中绕 X 轴转动的  `>0` 的方向，并且越靠近下边需要正向 Angle 数值越大，由于此时 `localPosition.dy`  越往下越大，所以使用 `details.localPosition.dy - cardHeight / 2`  去计算得到正确数据

| ![](http://img.cdn.guoshuyu.cn/20220723_N9/image6.png) | ![](http://img.cdn.guoshuyu.cn/20220723_N9/image7.gif) |
| ----------------------------------------------------------- | ------------------------------------------ |

如果觉得太抽象，可以结合上边右侧的动图，和**大家买股票一样，图中显示红色时是正数，显示绿色时是负数**，可以看到：

- 手指往左移动时，第一行 TouchX 是红色正数，被设置给  `rotateY` ， 然后卡片绕 Y 轴正方向旋转
- 手指往下移动时，第二行 TouchY 是红色正数，被设置给  `rotateX` ， 然后卡片绕 X 轴正方向旋转

到这里我们就初步实现了卡片跟随手机旋转的效果，**但是这时候的立体旋转效果看起来其实“很别扭”，总感觉差了点什么，其实这是因为卡片在旋转时没有产生视觉上的深度感知**。

所以我们可以通过矩阵的透视变换调整视觉效果，而为了在 Z 方向实现深度感知，我们需要在矩阵中配置 `.setEntry(3, 2, 0.001)`   ，这里的 3 表示第 3 列，2 表示第 2 行，因为是从 0 开始排列，所以也就是图片中 Z 的位置。

![](http://img.cdn.guoshuyu.cn/20220723_N9/image8.png)

其实 `.setEntry(3, 2, 0.001)`  就是调整 Z 轴的视角，而在 Z 上的  0.001 就是需要的透视效果测量值，类似于相机上的对焦点进行放大和缩小的作用，这个数字越大就会让交点处看起来好像离你视觉更近，所以最终代码如下

```dart
Transform(
  transform: Matrix4.identity()
    ..setEntry(3, 2, 0.001)
    ..rotateX(touchY)
    ..rotateY(touchX),
  alignment: FractionalOffset.center,
```

运行之后，可以看到在增加了 Z 角度的视角调整之后，这时候看起来的立体效果就好了很多，并且也有了类似 3D 空间的感觉。

![](http://img.cdn.guoshuyu.cn/20220723_N9/image9.gif)



接着我们在卡片上放上一个添加一个 `13` 的 `Text` 文本，运行之后可以看到此时文本是跟随卡片发生变化，而接下来我们需要做的，就是**通过另外一个 `Transform` 来让  `Text` 文本和卡片之间产生视差，从而出现悬浮的效果**。

| ![](http://img.cdn.guoshuyu.cn/20220723_N9/image10.png) | ![](http://img.cdn.guoshuyu.cn/20220723_N9/image11.gif) |
| ----------------------------------------------------------- | ---------------------------------------- |

所以接下来需要给文本内容设置一个  `translate` 的 `Matrix4` ，让它向着倾斜角度的相反方向移动，然后对前面的 `touchX` 和  `touchY`  进行放大，然后再通过 `- 10` 操作来产生一个位差。

```dart
    Transform(
      transform: Matrix4.identity()
        ..translate(touchX * 100 - 10,
            touchY * 100 - 10, 0.0),
```
> `-10` 这个是我随意写的，你也可以根据自己的需求调节。

例如，这时候当卡片往左倾斜时，文字就会向右移动，从而产生视觉差的效果，得到类似悬浮的感觉。

| ![](http://img.cdn.guoshuyu.cn/20220723_N9/image12.png) | ![](http://img.cdn.guoshuyu.cn/20220723_N9/image13.gif) |
| ----------------------------------------------------------- | ----------------------------------------- |

完成这一步之后，接下来可以我们对文本内容进行一下美化处理，例如增加渐变颜色，添加阴影，更换字体，目的是让字体看起来更加具备立体的效果，**这里使用的 `shader` ，也可以让文字在移动过程中出现不同角度的渐变效果**。

| ![](http://img.cdn.guoshuyu.cn/20220723_N9/image14.png) | ![](http://img.cdn.guoshuyu.cn/20220723_N9/image15.gif) |
| ----------------------------------------------------------- | ----------------------------------------- |

最后，我们还需要对卡片旋转进行一个范围约束，这里主要是通过卡片大小比例：

- 在  `onPanUpdate` 时对  `touchX` 和 `touchY` 进行范围约束，从而约束的卡片的倾斜角度
- 增加了 `startTransform` 标志位，用于在 `onTapUp`  或者 `onPanEnd` 之后，恢复卡片回到默认状态的作用。

```dart
Transform(
  transform: Matrix4.identity()
    ..setEntry(3, 2, 0.001)
    ..rotateX(startTransform ? touchY : 0.0)
    ..rotateY(startTransform ? touchX : 0.0),
  alignment: FractionalOffset.center,
  child: GestureDetector(
    onTapUp: (_) => setState(() {
      startTransform = false;
    }),
    onPanCancel: () => setState(() => startTransform = false),
    onPanEnd: (_) => setState(() {
      startTransform = false;
    }),
    onPanUpdate: (details) {
      setState(() => startTransform = true);
      ///y轴限制范围
      if (details.localPosition.dx < cardWidth * 0.55 &&
          details.localPosition.dx > cardWidth * 0.3) {
        touchX = (cardWidth / 2 - details.localPosition.dx) / 100;
      }

      ///x轴限制范围
      if (details.localPosition.dy > cardHeight * 0.4 &&
          details.localPosition.dy < cardHeight * 0.6) {
        touchY = (details.localPosition.dy - cardHeight / 2) / 100;
      }
    },
    child:
```

到这里，我们只需要在全局再进行一些美化处理，运行之后就会如下图所示，在配合阴影和渐变效果，整体的视觉立体感会更强烈，此时我们基本就实现了一开始想要的功能，

![](http://img.cdn.guoshuyu.cn/20220723_N9/image16.gif)



> 完整代码可见： [card_perspective_demo_page.dart](https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/card_perspective_demo_page.dart)
>
> Web 体验地址，PC 端记得开 Chrome 手机模式：  [3D 视差卡片](http://guoshuyu.cn/home/web/#3D%20%E9%80%8F%E8%A7%86%E5%8D%A1%E7%89%87)  。

那有人可能就想问了： *学会了这个我们还可以实现什么*？ 

举个例子，比如我们可以实现一个 “伪3D” 的  360°  卡片效果，利用堆叠实现立体的电子银行卡效果。

依旧是前面的手势旋转逻辑，只是这里我们可以把具有前后画面的银行卡图片，通过 `IndexedStack` 嵌套起来，**嵌套之后主要是根据旋转角度来调整  `IndexedStack`  里需要展示的图片，然后利用透视旋转来实现类似 3D 物体的 360°   旋转展示**。

![](http://img.cdn.guoshuyu.cn/20220723_N9/image17.png)

**这里的关键是通过手势旋转角度，判断当前需要展示  `IndexedStack`   里的哪个卡片**，因为 Flutter 使用的 Skia 是 2D 渲染引擎，如果没有这部分逻辑，你就只会看到单张图片画面的旋转效果。

```dart
if (touchX.abs() % (pi * 3 / 2) >= pi / 2 ||
    touchY.abs() % (pi * 3 / 2) >= pi / 2) {
  showIndex = 0;
} else {
  showIndex = 1;
}
```

运行效果如下图所示，可以看到在视差和图片切换的作用下，我们用很低的成本在 Flutter 上实现了 “伪3D” 的卡片的  360°  展示，类似的实现其实还可以用于一些商品展示或者页面切换的场景，**本质上就是利用视差的效果，在 2D 屏幕上模拟现实中的画面效果，从而达到类似 3D 的视觉作用** 。

| ![](http://img.cdn.guoshuyu.cn/20220723_N9/image18.gif) | ![](http://img.cdn.guoshuyu.cn/20220723_N9/image19.gif) |
| ---------------------------------------------------- | ----------------------------------------- |

**最后我们只需要用 `Text` 在卡片上添加“模拟”凹凸的文字，就实现了我们现实中类似银行卡的卡面效果**。

![](http://img.cdn.guoshuyu.cn/20220723_N9/image20.gif)

> 完整代码可见： [card_3d_demo_page.dart](https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/card_3d_demo_page.dart) 
>
> Web 体验地址，PC 端记得开 chrome 手机模式：  [  360° 可视化 3D 电子银行卡](http://guoshuyu.cn/home/web/#3D%20%E5%8D%A1%E7%89%87%E6%97%8B%E8%BD%AC) 

好了，本篇动画特效就到为止，**如果你有什么想法，欢迎留言评论，感谢大家耐心看完，也还请看官们走过路过的来个点赞一键三连，感激不尽**～

