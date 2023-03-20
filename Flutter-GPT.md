# 面向 ChatGPT 开发 ，我是如何被 AI 从 “逼疯” 到 “觉悟” ，未来又如何落地



对于  ChatGPT  如今大家应该都不陌生，经过这么长时间的「调戏」，相信大家应该都感受用 ChatGPT 「代替」搜索引擎的魅力，例如写周报、定位 Bug、翻译文档等等，而其中不乏一些玩的很「花」的场景，例如：

- [ChatPDF](https://www.chatpdf.com/) ：使用 ChatPDF 读取 PDF 之后，你可以和 PDF 文件进行「交谈」，就好像它是一个完全理解内容的「人」一样，通过它可以**总结中心思想，解读专业论文，生成内容摘要，翻译外籍，并且还支持中文输出等**。

  ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image1.png)

- [BiBiGPT](https://b.jimmylv.cn/video/BV1uM411P7oA?spm_id_from=333.1007.tianma.2-1-4.click) :  **一键总结视频内容**，主要依赖字幕来做总结，绝对是「二创」作者的摸鱼利器。

  ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image2.png)

所以把 ChatGPT 理解为「搜索引擎」其实并不正确，从上述介绍的两个落地实现上看， **ChatGPT 不是单纯的统计模型，它的核心并不是完全依赖于它的「语料库」，更多来自于临场学习的能力「 in-context learning」，这就是 ChatGPT 不同于以往传统 NLP「一切都从语料的统计里学习」的原因**。

> 当然，我本身并非人工智能领域的开发者，而作为一个普通开发者，我更关心的是 ChatGPT 可以如何提升我的开（mo）发（yu）效率，只是没想到随手一试，我会被 ChatGPT 的 「 in-context learning」 给「逼疯」。



# ChatGPT & UI

相信大家平时「面向」 ChatGPT 开发时，也是通过它来输出「算法」或者「 CURD」 等逻辑居多，因为这部分输出看起来相对会比较直观，而用 ChatGPT 来绘制前端 UI 的人应该不多，因为 UI 效果从代码上看并不直观 ，而且 ChatGPT 对与 UI 的理解目前还处于 「人工智障」的阶段。

>但是我偏偏不信邪。。。。。

因为近期开发需求里恰好需要绘制一个具有动画效果的 ⭐️ 按键，面对这么「没有挑战性」的工作我决定尝试交给 ChatGPT 来完成，所以我向 ChatGPT 发起了第一个命令：

> 「用 Flutter 画一个黄色的五角星」

| ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image3.png) | ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image4.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |

结果不负众望，关键部分如下代码所示，Flutter 很快就提供了完整的 Dart 代码，并且还针对代码提供了代码相关实现的讲解，不过运行之后可以看到，这时候的 ⭐️ 的样式并不满足我们的需求。

> 此时顶部的角也太「肥」了 。

| ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image5.png) | ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image6.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |

所以我随着提出了调整，希望五角星的五个角能够一样大，**只是没想到我的描述，开始让 ChatGPT 放飞自我** 。

> 也许是我的描述并不准确？

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image7.png)

在我满怀期待的 `cv`  代码并运行之后，**猝不及防的「五角星」差点没让我喷出一口老血**，虽然这也有五个角，但是你管这个叫 「五角星」 ？？？

> 这难道不是某个红白机游戏里的小飞机？？

| ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image8.png) | ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image9.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |

甚至于在看到后续 ChatGPT 关于代码的相关讲解时，**我觉得它已经开始在「一本正经的胡说八道」，像极了今天早上刚给我提需求的产品经理**。

> 哪里可以看出五个角相同了？？？

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image10.png)

接着我继续纠正我的需求，表示我要的是 `「一个五个角一样大的黄色五角星」` ，我以为这样的描述应过比较贴切，须不知·····

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image11.png)

如下代码所示，其实在看到代码输出  `for`  循环时我就觉得不对了，但是秉承着「一切以实物为准」的理念，在运行后不出意外的发生了意外，确实是五个角一样大，不过是一个等边五边形。

> 算一个发胖的 ⭐️ 能解（jiao）释（bian）过去不？

| ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image12.png) | ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image13.png) |
| -------------------------------------------------------- | -------------------------------------------------------- |

再看 ChatGPT 对于代码的描述，我发现我错了，**原来它像的是「理解错需求还在嘴硬的我」，只是它在说「这是一个五角星」的时候眼皮都不会眨一下**。

> AI：确实五个角一样大，五个角一样大的五边形为什么就不能是五角星？你这是歧视体型吗？

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image14.png)

所以我继续要求：`「我要的是五角星，不是五边形」`，还好 ChatGPT 的临场学习能力不错，他又一次「重新定义五角星」，**不过我此时我也不抱希望，就是单纯想看看它还能给出什么「惊喜」**。

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image15.png)

不出意外，这个「离谱」的多边形让我心头一紧，就在我想着是否放弃的时候，身为人类无法驯服 AI 「既爱又恨」的复杂情绪，让我最终坚持一定要让 ChatGPT 给我画出一个 ⭐️。

| ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image16.png) | ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image17.png) |
| -------------------------------------------------------- | -------------------------------------------------------- |

不过心灰意冷之下，我选择让 ChatGPT 重新画一个黄色五角星，没想道这次却有了意外的惊喜，从下面的图片可以看到，此时的 ⭐️ 除了角度不对，形状已经完全满足需求。

> 所以一个问题我多问几遍，也许就能接近我要的答案？

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image18.png)

事实上这也是目前 ChatGPT 的现状，因为「临场学力」能力等因素影响，**同一个问题它可能会给出不同的答案，而有的答案其实和我们要的根本不沾边**。

| ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image19.png) | ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image20.png) |
| -------------------------------------------------------- | -------------------------------------------------------- |

那么，接下来只要让 ChatGPT 把 ⭐️ 旋转一下角度，应该就可以完成需求····了吧？所以我提出`「帮我旋转 180度」`的要求。

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image21.png)

结果不出意外的还是发生了意外，可能 ChatGPT 理解的 180 度和我不大一样，如下图所示，确实旋转了，只是还是歪的，而基于前面的尝试，我觉得有必要再给它一次机会。

| ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image22.png) | ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image23.png) |
| -------------------------------------------------------- | -------------------------------------------------------- |

终于，在我换了以下描述之后，ChatGPT 似乎「开窍」了，终于让我如愿以偿的得到了我想要的 ⭐️ 代码。

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image24.png)

可以看到，其实这段代码并不复杂，你自己写或者去搜索引擎扒一扒大概会比用 ChatGPT 更快，但是 ChatGPT 的魅力就在于：**它也许会错，但是总有一次它会「蒙对」，如果现在还不对，那么未来也会有算对的时候，这就是我感受到的 AI 魅力所在**。

| ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image25.png) | ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image26.png) |
| -------------------------------------------------------- | -------------------------------------------------------- |

既然五角星都出来，那么接下来我们来完成最后一步的动画效果，我们希望的是点击 ⭐️ 的时候可以有一个爆炸粒子的动画，所以我提出了：

> 「希望加上一个动画效果，就是点击的时候星星爆炸成颗粒的动画效果」

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image27.png)

结果还是「一口老血」，如下图所示，「星星确实爆炸了」，**只是这个爆炸动画看起来是那么的「一言难尽」**，感兴趣的可以 cv 下面的源代码自己体验下，不出意外接下来又是新的一轮人类和 AI 的「斗智斗勇」。

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image28.gif)



```dart

class YellowStar extends StatefulWidget {
  @override
  _YellowStarState createState() => _YellowStarState();
}

class _YellowStarState extends State<YellowStar> with TickerProviderStateMixin {
  bool _isExploded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isExploded = true;
      _animationController.forward(from: 0.0);
    });
  }

  void _resetStar() {
    setState(() {
      _isExploded = false;
      _animationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTap: _resetStar,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: _isExploded
              ? BorderRadius.circular(50)
              : BorderRadius.zero,
        ),
        child: _isExploded
            ? _buildParticles()
            : Container(
          width: 100,
          height: 100,
          child: CustomPaint(
            painter: YellowStarPainter(),
          ),
        ),
      ),
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          child: Stack(
            children: List.generate(
              50,
                  (index) {
                double radius = _animation.value * 50;
                double angle = 2 * pi * index / 50;
                double x = 50 + cos(angle) * radius;
                double y = 50 + sin(angle) * radius;
                return Positioned(
                  left: x,
                  top: y,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.yellow,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}



class YellowStarPainter extends CustomPainter {
  final double starSizeRatio = 0.4;
  final double centerOffsetRatio = 0.2;
  final double rotationOffset = -pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    double starSize = min(size.width, size.height) * starSizeRatio;
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double centerOffset = starSize * centerOffsetRatio;

    Path path = Path();
    Paint paint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      double radians = 2 * pi / 5 * i + rotationOffset;
      double x = centerX + cos(radians) * starSize / 2;
      double y = centerY + sin(radians) * starSize / 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      radians += 2 * pi / 10;
      x = centerX + cos(radians) * centerOffset;
      y = centerY + sin(radians) * centerOffset;
      path.lineTo(x, y);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
```

经过一轮「鏖战」如下图所示，面对同一个问题，ChatGPT 总能找到不同的实现方式来回答你，只是这些实现里有的无法运行的，有的是运行没有效果的，有的甚至是给你输出了一个 `//TODO 爆炸动画`  ，总之就是让你「血压飙升」。

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image29.png)



![](http://img.cdn.guoshuyu.cn/20230315_GPT/image30.png)

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image31.png)

当然，「胜利终将属于人类」，如下图所示，在经历了无数次「血压飙升」的场景之后，最终我还是得到了我想要的：点击 ⭐️，然后出现了💥的动画效果，尽管还是不完美，但是基本满足了我后续开发的需求。

> **这个代码完完全全由 ChatGPT 输出，我一句没改**，完整代码贴在了后面。

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image32.gif)



```dart

class YellowStarPage extends StatefulWidget {
  @override
  _YellowStarPageState createState() => _YellowStarPageState();
}

class _YellowStarPageState extends State<YellowStarPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExploded = false;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500))
          ..addListener(() {
            setState(() {});
          });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleStarTap() {
    if (!_isExploded) {
      _isExploded = true;
      _animationController.forward(from: 0);
      Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          _isExploded = false;
        });
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yellow Star')),
      body: Center(
        child: GestureDetector(
          onTap: _handleStarTap,
          child: Container(
            width: 300,
            height: 300,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: YellowStarPainter(_animationController.value,
                      isExploded: _isExploded),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class YellowStarPainter extends CustomPainter {
  final double starSizeRatio = 0.4;
  final double centerOffsetRatio = 0.2;
  final double rotationOffset = -pi / 2;

  final double animationValue;
  final bool isExploded;

  YellowStarPainter(this.animationValue, {this.isExploded = false});

  @override
  void paint(Canvas canvas, Size size) {
    double starSize = min(size.width, size.height) * starSizeRatio;
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    double centerOffset = starSize * centerOffsetRatio;

    Path path = Path();
    Paint paint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;

    if (isExploded) {
      double particleSize = starSize / 30;
      paint.strokeWidth = 1;
      paint.style = PaintingStyle.fill;
      paint.color = Colors.yellow;
      Random random = Random();

      for (int i = 0; i < 30; i++) {
        double dx = random.nextDouble() * starSize - starSize / 2;
        double dy = random.nextDouble() * starSize - starSize / 2;
        double x = centerX + dx * (1 + animationValue);
        double y = centerY + dy * (1 + animationValue);

        canvas.drawCircle(Offset(x, y), particleSize, paint);
      }
    } else {
      for (int i = 0; i < 5; i++) {
        double radians = 2 * pi / 5 * i + rotationOffset;
        double x = centerX + cos(radians) * starSize / 2;
        double y = centerY + sin(radians) * starSize / 2;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }

        radians += 2 * pi / 10;
        x = centerX + cos(radians) * centerOffset;
        y = centerY + sin(radians) * centerOffset;
        path.lineTo(x, y);
      }

      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

```

最后，给大家欣赏一下我让 ChatGPT 画一只米老鼠的「心路历程」，**很明显这一次「人类一败涂地」**，从目前的支持上看，让 ChatGPT 输出复杂图像内容并不理想，因为它不的笔画「不会拐弯」。

| ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image33.png) | ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image34.png) | ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image35.png) | ![](http://img.cdn.guoshuyu.cn/20230315_GPT/image36.png) |
| -------------------------------------------------------- | -------------------------------------------------------- | -------------------------------------------------------- | -------------------------------------------------------- |

> 真的是又爱又恨。

# 最后

经过上面的一系列「折腾」，**可以看到  ChatGPT 并没有我们想象中智能，如果面向 GPT 去开发，甚至可能并不靠谱，因为它并不对单一问题给出固定答案，甚至很多内容都是临场瞎编的**，这也是因为大语言模型本身如何保证「正确」是一个复杂的问题，但是 ChatGPT 的魅力也来自于此：

> **它并不是完全基于语料来的统计来给答案**。

当然这也和 ChatGPT 本身的属性有关系， ChatGPT 目前的火爆有很大一部分属于「意外」，目前看它不是一个被精心产品化后的 2C 产品，反而 [ChatPDF](https://www.chatpdf.com/) 和 [BiBiGPT](https://b.jimmylv.cn/video/BV1uM411P7oA?spm_id_from=333.1007.tianma.2-1-4.click) 这种场景化的包装落地会是它未来的方向之一。

而现在 OpenAI 发布了多模态预训练大模型 [CPT-4](https://mp.weixin.qq.com/s/kA7FBZsT6SIvwIkRwFS-xw) ，**GPT-4  按照官方的说法是又得到了飞跃式提升：强大的识图能力；文字输入限制提升至 2.5 万字；回答准确性显著提高；能够生成歌词、创意文本，实现风格变化等等**

![](http://img.cdn.guoshuyu.cn/20230315_GPT/image37.gif)



所以我很期待 ChatGPT 可以用 Flutter 帮我画出一只米老鼠， 尽管  ChatGPT 现在可能会让你因为得到 `1+1=3`  这样的答案而「发疯”」，**但是 AI 的魅力在于，它终有一天能得到准确的结果** 。