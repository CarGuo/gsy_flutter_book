# Flutter 小技巧之霓虹灯文本的「故障」效果的实现

如下图所示，最近通过群友的问题在 [codepen.io ](https://codepen.io/mattgrosswork/pen/VwprebG) 上看到了一个文本「抽动」的动画实现，看起来就像是生活中常见的「霓虹灯招牌」故障时的「抽动」效果，而本篇的目标通过「抄袭」这个实现，帮助大家理解 Flutter 里的一些实现小技巧。

![](http://img.cdn.guoshuyu.cn/20230322_N21/image1.gif)

这个效果在 codepen 上是通过 CSS 实现的，实现思路 codepen 上的 [Glitch Walkthrough](https://codepen.io/mattgrosswork/pen/VwprebG) 大致有提示，但是 Flutter 没有强大的 CSS，那么如何将它「复刻」到 Flutter 上就是本篇的核心要点。

> 不得不说 CSS 很强大，要在 Flutter 上实现类似的效果还是比较「折腾」。

而要在 Flutter 上实现类似 Glitch Walkthrough 的效果，大致上我们需要处理：

- 类似霓虹灯效果的文本
- 文本内容撕裂的效果
- 文本变形闪动的效果

那么接下来我们就按照这个流程来实现一个 Flutter 上的 Glitch Walkthrough 。

# 霓虹灯文本

这一步其实相对简单，Flutter  的 `TextStyle`  提供了  `shadows`  配置，通过它可以快速实现一个「会发光」的文本。

我们这里通过两个 `Shadow`  来实现「发光」的视觉效果，核心就是利用  `Shadow`   的 `blurRadius`  来让背景出现一定程度的模糊发散，然后两个 `Shadow`  形成不一样的颜色深度和发散效果，从而达到看起来「发亮」的效果。

> 如下图是没有填充文本颜色时  `Shadow`   的效果。

![](http://img.cdn.guoshuyu.cn/20230322_N21/image2.png)

最后，如下代码所示，我们只需要通过 `foreground` 给文本补充下颜色，就可以看到如下图所示的类似「霓虹灯」效果的文本。

> 当然这里你不想用  `foreground`  ，只用简单的 `color`  也可以。

```dart
Text(
  widget.text,
  style: TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    foreground: Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 5
      ..color = Colors.white,
    shadows: [
      Shadow(
        blurRadius: 10,
        color: Colors.white,
        offset: Offset(0, 0),
      ),
      Shadow(
        blurRadius: 20,
        color: Colors.white30,
        offset: Offset(0, 0),
      ),
    ],
  ),
)
```

![](http://img.cdn.guoshuyu.cn/20230322_N21/image3.png)

这里提个题外话，其实类似的思路用在图片上也可以实现「发光」的效果，如下代码所示，通过 Stack 嵌套两个  `Image` ，然后中间通过  `BackdropFilter`  的 `ImageFilter` 做一层模糊，让底下的图片模糊后发散产生类似「发光」的效果。

```dart
 var child = Image.asset(
   'static/test_logo.png',
   width: 250,
 );
 return Stack(
      children: [
        child,
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blurRadius,
              sigmaY: blurRadius,
            ),
            child: Container(color: Colors.transparent),
          ),
        ),
        child,
      ],
    )
 );
```

如下图所示，图片最终可以通过自己的色彩产生类似「发光」的效果，当然这部分只是额外的拓展内容，和我们要实现的效果无关。

![](http://img.cdn.guoshuyu.cn/20230322_N21/image4.png)





# 文本撕裂

这部分可以说是需求效果的核心，这里我们需要用到 `ClipPath` 和  `Polygon` ，通过 `Polygon`  来实现随机的多边形路径，然后利用   `ClipPath`  对文本内容进行随机的路径裁剪。

虽然说用   `Polygon`  ， 但是 Flutter 官方并没有直接提供类似前端 CSS 的  `Polygon`  多边形 API 支持，但是社区总有「好心人」，我们可以直接使用 Flutter 上类似的第三方库： `polygon: ^0.1.0`  。

>简单说    `Polygon`   就是按照 step 对 `Path` 的  `moveTo` 和  `quadraticBezierTo` 等 API 进行了封装。

Flutter 上的   `Polygon`   取值范围是 -1 ～ 1 ，也就是按照比例决定位置，比如 - 1 就是起始点， 1 就是最大宽高， 更具体如下面的代码所示，这里利用 `Polygon` 添加了三个点，最终这三个点形成的 Path 会绘制出一个三角形。

```dart
List<Offset> generatePoint() {
  List<Offset> points = [];
  points.add(Offset(-1, -1));
  points.add(Offset(-1, 0));
  points.add(Offset(0, -1));
  return points;
}
```

![](http://img.cdn.guoshuyu.cn/20230322_N21/image5.png)

如下代码所示，那如果如果 point 的数量多了，就可以形成一系列不规则的形状，比如下面代码随机添加了 60 个点的位置，可以看到此时屏幕上的白色 `Container` 被裁剪成「凌乱」的形状。

```dart
List<Offset> generatePoint() {
  List<Offset> points = [];

  points.add(Offset(-1.00, -0.76));
  points.add(Offset(0.06, -0.76));
  points.add(Offset(0.06, -0.48));
  points.add(Offset(-0.50, -0.48));
  points.add(Offset(-0.50, 0.72));
  points.add(Offset(-0.38, 0.72));
  points.add(Offset(-0.38, -1.00));
  points.add(Offset(0.06, -1.00));
  points.add(Offset(0.06, 0.67));
  points.add(Offset(0.84, 0.67));
  points.add(Offset(0.84, 0.63));
  points.add(Offset(0.39, 0.63));
  points.add(Offset(0.39, -0.42));
  points.add(Offset(0.56, -0.42));
  points.add(Offset(0.56, 0.30));
  points.add(Offset(0.37, 0.30));
  points.add(Offset(0.37, 0.32));
  points.add(Offset(0.54, 0.32));
  points.add(Offset(0.54, -0.09));
  points.add(Offset(0.70, -0.09));
  points.add(Offset(0.70, -0.48));
  points.add(Offset(0.94, -0.48));
  points.add(Offset(0.94, -0.43));
  points.add(Offset(0.67, -0.43));
  points.add(Offset(0.67, -0.31));
  points.add(Offset(0.08, -0.31));
  points.add(Offset(0.08, 0.78));
  points.add(Offset(-0.40, 0.78));
  points.add(Offset(-0.40, 0.15));
  points.add(Offset(0.65, 0.15));
  points.add(Offset(0.65, 0.00));
  points.add(Offset(0.36, 0.00));
  points.add(Offset(0.36, -0.28));
  points.add(Offset(0.24, -0.28));
  points.add(Offset(0.24, -0.80));
  points.add(Offset(-0.76, -0.80));
  points.add(Offset(-0.76, -0.31));
  points.add(Offset(0.19, -0.31));
  points.add(Offset(0.19, 0.13));
  points.add(Offset(0.96, 0.13));
  points.add(Offset(0.96, 0.65));
  points.add(Offset(-0.80, 0.65));
  points.add(Offset(-0.80, 0.06));
  points.add(Offset(0.82, 0.06));
  points.add(Offset(0.82, 0.67));
  points.add(Offset(0.60, 0.67));
  points.add(Offset(0.60, 0.65));
  points.add(Offset(-0.19, 0.65));
  return points;
}
```

![](http://img.cdn.guoshuyu.cn/20230322_N21/image6.png)

如果这时候把白色 `Container` 换成文本内容，那么我们就可以如下图所示的效果，看起来像不像一帧状态下文本的「错乱」效果？后面我们只需要每次生成一帧这样的 Path ，就可以实现文本动态「撕裂」的需求。

![](http://img.cdn.guoshuyu.cn/20230322_N21/image7.png)

> 我们只需要把这个实现做成随机输出，然后每次生成一个 `Path` 就可以了。

如下代码所示，我们通过 `generatePoint`  方法，每次随机生成 60 个点，然后将这些点通过 `computePath` 转化为 Path，然后继承   `CustomClipper` 配置到 `getClip` 方法里，在需要的时候（`tear` ）对 child 按 Path 进行裁剪。

> 注意这里的  `i % 2` ，为的是让上次的 x 或者 y 可以是同一个位置，在连接上能连续。

```dart
class RandomTearingClipper extends CustomClipper<Path> {
  bool tear;

  RandomTearingClipper(this.tear);

  List<Offset> generatePoint() {
    List<Offset> points = [];
    var x = -1.0;
    var y = -1.0;
    for (var i = 0; i < 60; i++) {
      if (i % 2 != 0) {
        x = Random().nextDouble() * (Random().nextBool() ? -1 : 1);
      } else {
        y = Random().nextDouble() * (Random().nextBool() ? -1 : 1);
      }
      points.add(Offset(x, y));
    }
    return points;
  }

  @override
  Path getClip(Size size) {
    var points = generatePoint();
    var polygon = Polygon(points);
    if (tear)
      return polygon.computePath(rect: Offset.zero & size);
    else
      return Path()..addRect(Offset.zero & size);
  }

  @override
  bool shouldReclip(RandomTearingClipper oldClipper) => true;
}
```

接着，我们只需要设置一个定期器，然后将前面的「霓虹灯文本」和「故障裁剪效果」配置到  `ClipPath` 上，如下图所示，我们就可以看到文本的随机撕裂效果。

```dart
timer = Timer.periodic(Duration(milliseconds: 400), (timer) {
  tearFunction();
});

return ClipPath(
   child: Center(
     child: Text(
       widget.text,
       style: TextStyle(
         fontSize: 48,
         fontWeight: FontWeight.bold,
         foreground: Paint()
           ..style = PaintingStyle.fill
           ..strokeWidth = 1
           ..color = Colors.white,
         shadows: [
           Shadow(
             blurRadius: 10,
             color: Colors.white,
             offset: Offset(0, 0),
           ),
           Shadow(
             blurRadius: 20,
             color: Colors.white30,
             offset: Offset(0, 0),
           ),
         ],
       ),
     ),
   ),
   clipper: RandomTearingClipper(tear),
 );
```

![](http://img.cdn.guoshuyu.cn/20230322_N21/image8.gif)

> 此时看起来还不够形象。

# 变形闪动

为了达到我们预期的效果，最后我们还需要做一些特殊处理，比如再实现两个形状、颜色和位置不一样「霓虹灯文本」，为的就是实现「变形和闪动」的效果替换。

比如如下代码所示，通过 `ShaderMask`  可以实现一个渐变效果的的文本，这是用来在闪动的时候，提供一个短暂替换和色彩加深的作用。

```dart
ShaderMask(
  blendMode: BlendMode.srcATop,
  shaderCallback: (bounds) {
    return LinearGradient(
      colors: [Colors.blue, Colors.green, Colors.red],
      stops: [0.0, 0.5, 1.0],
    ).createShader(bounds);
  },
  child:
```

![](http://img.cdn.guoshuyu.cn/20230322_N21/image9.png)

类似的我们还可以实现一个「变形」的文本，在之前的白色「霓虹灯」文本基础上增加「斜体」和「颜色变淡」等处理，用来闪动的时候提供「变形」的作用。

![](http://img.cdn.guoshuyu.cn/20230322_N21/image10.png)

最后我们再将之前的 ` ClipPath`添加到它们上面，并增加一个  `transform` 实现文本四周随意移动的效果支持，如下图所示，此时的效果已经肉眼可见的接近我们的需求。

```dart
transform:
    Matrix4.translationValues(randomPosition(4), randomPosition(4), 0),

double randomPosition(position) {
  return Random().nextInt(position).toDouble() *
      (Random().nextBool() ? -1 : 1);
}
```

| ![](http://img.cdn.guoshuyu.cn/20230322_N21/image11.gif) | ![](http://img.cdn.guoshuyu.cn/20230322_N21/image12.gif) |
| -------------------------------------------------------- | -------------------------------------------------------- |

最后我们将这几个文本效果用 `Stack` 组合起来，然后再在定时器里不停去切换「故障」和「正常」的文本状态，并且随机选择展示不同的 「故障」状态。

```dart
timer = Timer.periodic(Duration(milliseconds: 400), (timer) {
  tearFunction();
});
timer2 = Timer.periodic(Duration(milliseconds: 600), (timer) {
  tearFunction();
});

tearFunction() {
  count++;
  tear = count % 2 == 0;
  if (tear == true) {
    setState(() {});
    Future.delayed(Duration(milliseconds: 150), () {
      setState(() {
        tear = false;
      });
    });
  }
}

@override
Widget build(BuildContext context) {
  var status = Random().nextInt(3);
  return Stack(
    children: [
      if (tear && (status == 1)) renderTearText1(RandomTearingClipper(tear)),
      if (!tear || (tear && status != 2))
        renderMainText(RandomTearingClipper(tear)),
      if (tear && status == 2) renderTearText2(RandomTearingClipper(tear)),
    ],
  );
}
```

最终效果如下图所示，这里还额外对后面两个文本做了一个 `ClipRect` 处理，闪动切换的时候只展示部分内容，这样在「故障」时的切换不会显得太过生硬，可以看到简单的 CSS 效果在 Flutter 上的实现成本其实并不低。

![](http://img.cdn.guoshuyu.cn/20230322_N21/image13.gif)

当然，这里的实现没考虑性能问题，所以代码也比较糙，不过这里主要是为了展示了 `ClipPath  `和  `Shadow`  的使用技巧，相信通过这个例子，可以帮助大家更好地发掘 Flutter 里对于路径绘制和阴影的使用场景，这才是本篇的主要目的。

那么本篇小技巧到这里就结束了，如果你还有什么想说的，欢迎留言评论。

> 完整代码可见：https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/tear_text_demo_page.dart