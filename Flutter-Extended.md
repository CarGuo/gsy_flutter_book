# Google I/O Extended | Flutter 游戏和全平台正式版支持下 Flutter 的现状

Hello，大家好，我是《Flutter开发实战详解》的作者，Github GSY 系列项目的负责人郭树煜，本次 Google I/O Extended 我主要是给大家回顾一下本次 I/O 大会关于 Flutter 的一些亮点。

> 其实本次 I/O 大会对我来说也有特别的意义，因为本次 I/O 大会之后，**我参加了 Dart/Flutter GDE 的最后一轮面试，有幸顺利通过了**，这对于我个人来说也是一个里程碑。 - [《从台下到台上，我成为 GDE（谷歌开发者专家） 的经验分享》](https://juejin.cn/post/7102242694755254279)

## 游戏

如果要说本次 I/O 里 Flutter 有什么亮点，那其中之一必定就是官方的 Flutter 小游戏 [pinball](https://pinball.flutter.dev/#/) 。

![image-20220525145827978](http://img.cdn.guoshuyu.cn/20220528_未命名/image1.png)

其实这不是第一次 Flutter 和游戏领域有交集，例如：

- Unity 就有 Flutter 相关的 [UIWidgets](https://github.com/Unity-Technologies/com.unity.uiwidgets) ，它是 Unity 编辑器的一个插件包，可帮助开发人员通过 Unity 引擎来创建、调试和部署高效的跨平台应用；
- 腾讯的 PUBG 吃鸡游戏，其中一些游戏的非游戏 UI 已经开始转向 Flutter ；

因为 Flutter 拥有平台无关的渲染引擎 Skia ，而 Skia 的 2D 渲染能力从手机端、Web 端到 PC 端的支持，经过这么多年的发展已经很成熟，**所以在一定程度上，Flutter 本身就是一个 2D 版的“游戏引擎”** 。

**Flutter 其实一直有针对游戏引擎有一个关于游戏的 [Toolkit](https://flutter.dev/games)** ，一般情况下我们可以把游戏分为两类：

- 射击游戏、赛车游戏等的动作游戏；
- 棋盘游戏、卡牌游戏、拼图、策略游戏等休闲游戏；

而其实上述这些休闲游戏和 App 十分接近，所以从场景上，它挺更适合使用 Flutter 来进行开发。

甚至在官方的 ToolKit 里，还包含了如`google_mobile_ads`, `in_app_purchase`, `audioplayers`, `crashlytics`, 和`games_services` 等工具包，**提前为广告和应用内购进行和内置集成支持**。

![image-20220525112604487](http://img.cdn.guoshuyu.cn/20220528_未命名/image2.png)

当然，如果你需要实现更复杂的游戏场景，例如 [pinball](https://pinball.flutter.dev/#/) 这样的游戏效果，那么你可能就需要第三方的   [Flame ](https://pub.dev/packages/flame)包来完成，这里 GIF 有些掉帧，但是实际使用过程中，如果我不说，你不会发现这是一个 Flutter Web 写的游戏。

![TT](http://img.cdn.guoshuyu.cn/20220528_未命名/image3.gif)

**Pinball 本身是基于 Flame SDK ，通过 Flutter 和 Firebase 开发的一个具备完成功能的弹珠游戏**。

**其中 Flame 提供了各类游戏相关的开箱即用功能，例如动画、物理、碰撞检测等**，同时 Flame 还可以利用了 Flutter framework 的基础内容，所以如果你是 Flutter  的开发者，那么其实你已经具备使用 Flame 构建游戏所需的基础。

> 其实 Flame 仓库创建于在 2017，并且此之前也有一些使用 Flame 开发的样例子，只是这次 I/O 官方通过 Pinball  游戏，给 Flame 做了一些背书。

在官方的例子就提供了游戏里关于 Camera 的相关示例，在点击屏幕时会添加一个比萨，摄像头会跟随移动，另外在这个例子中还有一些多米诺牌排列在一起，在它会和比萨产生碰撞，从而使瓷砖倾斜，并且引起一些列的物理连锁反应。

![rrr](http://img.cdn.guoshuyu.cn/20220528_未命名/image4.gif)

```dart
class CameraExample extends DominoExample {
  static const String description = '''
    This example showcases the possibility to follow BodyComponents with the
    camera. When the screen is tapped a pizza is added, which the camera will
    follow. Other than that it is the same as the domino example.
  ''';

  @override
  void onTapDown(TapDownInfo details) {
    final position = details.eventPosition.game;
    final pizza = Pizza(position);
    add(pizza);
    pizza.mounted.whenComplete(() => camera.followBodyComponent(pizza));
  }
}
```

另外，其实在 2020 年也有一些开发者使用Flutter&Flame在游戏上进行实践，例如掘金上的 [吉哈达](https://juejin.cn/post/6857049079000760334) 在 2020 年就发布过基于 Flame 的坦克大战游戏，本身也是一个比较完整的开源小游戏。

![](http://img.cdn.guoshuyu.cn/20220528_未命名/image5.webp)

回到 Pinball  ，如果你去看 Pinball  游戏的代码，你就会发现它使用的是 Flutter Web 里的 CanvasKit 作为渲染，也就是通过 WebAssembly + Skia 实现的绘制。

![image-20220525101651021](http://img.cdn.guoshuyu.cn/20220528_未命名/image6.png)

了解过 Flutter 的同学可能知道，Flutter Web 默认在 PC 使用 CanvasKit  渲染 UI ，而在手机端默认会使用 Html 来绘制 UI ，但是如果你使用了 Flame  ，那么在手机端也会是 CanvasKit  ，**因为从设计上考虑，只有 CanvasKit  更符合游戏的设计思想和保持运行效果的一致性**。

![image-20220525102914789](http://img.cdn.guoshuyu.cn/20220528_未命名/image7.png)

当然，这也带来了加载太慢的问题，可以看到打开 pinball 大概花费了 3.6 min，这确实是 Flutter Web 在 CanvasKit  下的通病之一。

而 Flutter 开发游戏和在传统 App 中不同的点主要在：

- 一般传统 App 通常屏幕在视觉上是静态的，直到有来自用户的事件或交互才会发生变化；
- 对于游戏这一情况正好相反——UI 需要不断更新，游戏状态会不断发生变化；

所以 在 I/O Pinball 中，游戏通过 loop 循环对球在赛场上的位置和状态做出反应，例如球与物体发生碰撞或球脱离比赛，从而做出相应。

```dart
@override
void update(double dt) {
  super.update(dt);  final direction = -parent.body.linearVelocity.normalized();
  angle = math.atan2(direction.x, -direction.y);
  size = (_textureSize / 45) * 
    parent.body.fixtures.first.shape.radius;
}
```

另外还有，在构建 I/O Pinball 下，可以看到界面是有明显的类 3D 效果，那如何仅使用 2D 元素创建 3D 效果？

![image-20220525152706873](http://img.cdn.guoshuyu.cn/20220528_未命名/image8.png)

**其实就是通过对组件进行排序和堆叠资源的层级，以此来以确定它们在屏幕上的呈现位置**，例如当球在斜坡上发射时，球的所在的层级顺序增加，因此它看起来在斜坡的顶部。

```dart
/// Scales the ball's body and sprite according to its position on the board.
class BallScalingBehavior extends Component with ParentIsA<Ball> {
  @override
  void update(double dt) {
    super.update(dt);
    final boardHeight = BoardDimensions.bounds.height;
    const maxShrinkValue = BoardDimensions.perspectiveShrinkFactor;    final standardizedYPosition = parent.body.position.y +   (boardHeight / 2);
    final scaleFactor = maxShrinkValue +
        ((standardizedYPosition / boardHeight) * (1 - maxShrinkValue));parent.body.fixtures.first.shape.radius = (Ball.size.x / 2) * scaleFactor;final ballSprite = parent.descendants().whereType<SpriteComponent>();
    if (ballSprite.isNotEmpty) {
      ballSprite.single.scale.setValues(
        scaleFactor,
        scaleFactor,
      );
    }
  }
}
```

另外弹球游戏场上有一些元素，如 Android、Dash、Sparky 和 Chrome Dino，它们都是有动画效果。

对于这些使用的是 sprite sheets，它包含在带有 `SpriteAnimationComponent` ，对于每个元素都有一个文件，其中包含不同方向的图像、文件中的帧数以及帧之间的时间。

使用这些数据，`SpriteAnimationComponent` 在 Flame 内将所有图像循环编译在一起，从而使元素看起来具有动画效果。

![image-20220525115124190](http://img.cdn.guoshuyu.cn/20220528_未命名/image9.png)

```dart
final spriteSheet = gameRef.images.fromCache(
  Assets.images.android.spaceship.animatronic.keyName,
);const amountPerRow = 18;
const amountPerColumn = 4;
final textureSize = Vector2(
  spriteSheet.width / amountPerRow,
  spriteSheet.height / amountPerColumn,
);
size = textureSize / 10;animation = SpriteAnimation.fromFrameData(
  spriteSheet,
  SpriteAnimationData.sequenced(
    amount: amountPerRow * amountPerColumn,
    amountPerRow: amountPerRow,
    stepTime: 1 / 24,
    textureSize: textureSize,
  ),
);
```

最后 Flame 代码库还附带一个组件沙箱，类似于 UI 组件库，可以在开发游戏时，这是一个有用的工具，因为它允许开发者单独开发游戏组件，并确保它们在将它们集成到游戏中之前的外观和行为符合预期。

![1*zAjKICKgCTiEiiMTou9MJQ](http://img.cdn.guoshuyu.cn/20220528_未命名/image10.gif)







## 全平台

Flutter 3.0 另外一个重点就是**增加了对 macOS 和 Linux 应用程序的稳定支持，这是 Flutter 的一个里程碑，现在借助 Flutter 3.0，开发者可以通过一个代码库为六个平台构建应用**。

![image-20220525115916985](http://img.cdn.guoshuyu.cn/20220528_未命名/image11.png)



自此 Flutter 终于全平台 stable 支持了，这种支持不是说添加对应平台的UI 渲染致支持就可以：**它包括新的输入和交互模型、编译和构建支持、accessibility 和国际化以及特定于平台的集成等等，Flutter 团队的目标是让开发者能够灵活地利用底层操作系统，同时根据开发者的选择尽可能多的共享 UI 和逻辑**。

> 例如在 macOS 上，现在支持 Intel 和 Apple Silicon，提供 [Universal Binary](https://link.juejin.cn/?target=https%3A%2F%2Fdeveloper.apple.com%2Fdocumentation%2Fapple-silicon%2Fbuilding-a-universal-macos-binary) 支持，允许应用打包支持两种架构上的可执行文件，Flutter 利用了 [Dart 对 Apple 芯片的支持](https://link.juejin.cn/?target=https%3A%2F%2Fmedium.com%2Fdartlang%2Fannouncing-dart-2-14-b48b9bb2fb67) 在基于 M1 的设备上更快地编译并支持 macOS 应用程序的 [Universal Binary](https://link.juejin.cn/?target=https%3A%2F%2Fdeveloper.apple.com%2Fdocumentation%2Fapple-silicon%2Fbuilding-a-universal-macos-binary) 文件。

本次 I/O 官方就提供了一个 Flutter 合作伙伴的案例：[Superlist](https://link.juejin.cn/?target=https%3A%2F%2Fsuperlist.com%2F) ，它是 Flutter 如何实现 Desktop 应用的一个很好的例子，它在 I/O 当天发布了测试版。

![RR](http://img.cdn.guoshuyu.cn/20220528_未命名/image12.gif)

Superlist 将列表、任务和自由格式内容，组合成全新的待办事项列表和个人计划，提供协作能力，同时 Superlist 也是开源项目 [super_editor](https://github.com/superlistapp/super_editor) 的维护组织，所以社区的支持其实对于 Flutter 来说很重要。

**每个 Flutter 正式版的发布都包含了大量来自社区的 PR ，例如本次 Flutter 3.0 版本发布就合并了 5248 个 PR**。

**当然，本次在 PC 端还有做了一定的取舍：放弃 Windows 7/8**。

在 Flutter 3.0 中推荐将 Windows 的版本提升到 Windows 10，虽然目前 Flutter 团队不会阻止在旧版本（Windows 7、Windows 8、Windows 8.1）上进行开发，但 [Microsoft 不再支持](https://link.juejin.cn/?target=https%3A%2F%2Fdocs.microsoft.com%2Fen-us%2Flifecycle%2Ffaq%2Fwindows) 这些版本，虽然 Flutter 团队将继续为旧版本提供“尽力而为”的支持，但还是鼓励开发者升级。

> **注意**：目前还会继续为在 Windows 7 和 Windows 8 上能够正常*运行* Flutter 提供支持；此更改仅影响开发环境。

另外，Flutter 在 PC 领域虽然目前不像 App 端那么丰富，但是社区也涌向了一批优质的第三方支持，例如 [leanflutter.org](https://github.com/leanflutter) 目前发布了很多关于 PC 端相关的内容，大家可以在 pub 或者 github 看到相关的内容，其中比如

- **window_manger 就在 PC 领域备受关注**，它本身是用于调整窗口的桌面应用的大小和位置，支持 macOS、Linux、WIndows等平台，所以这个包在桌面端领域就相当实用；
- flutter_distributor 可以帮助你在多个平台上实现自动构建和定制化的发布

![image-20220528215030023](http://img.cdn.guoshuyu.cn/20220528_未命名/image13.png)

**类似  leanflutter 等作者已经在 Pub 发布了很多关于 PC 端能力拓展的插件**，所以大家对于 PC 端支持的忧虑可以开始放下，尝试一些 Flutter 的 PC 端开发。

> **注意是 leanflutter 不是 learnflutter**。

最后，目前 Flutter PC 端在国内也开始被越来越多的大厂所接纳，比如知名的钉钉、字节、企业微信都在 Flutter PC 端进行投入开发，它们的投入使用也可以反向推动 Flutter PC 端的健康成长。![image-20220525135033045](http://img.cdn.guoshuyu.cn/20220528_未命名/image14.png)

就比如官方的 2022 roadmap 提到：**无论一个 SDK 有多么优秀，如果只有少数人在使用它，它都不能反映出它的价值； 而如果 SDK 很普通但是却被大量开发人员使用，它也会有一个健康和有价值的框架，使用这个框架的人才能真正从社区和框架中受益**。

![image-20220528215500266](http://img.cdn.guoshuyu.cn/20220528_未命名/image15.png)





dff