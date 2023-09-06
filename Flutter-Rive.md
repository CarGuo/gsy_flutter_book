# Flutter 最优秀动画库「完全商业化」，Rive 2 你全面了解过吗？

说到 **[rive](https://rive.app)** ，非 Flutter 开发者可能会感觉比较陌生，而做过 Flutter 开发的可能对 rive 会有所耳闻，因为 rive 在一开始叫 flare ，是 2dimensions 公司的开源动画产品，在发布之初由于和 Flutter 团队有深入合作，所以在初期一直是 Flutter 官方推荐的动画框架之一。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image1.gif)

# 前言

rive 作为一个面向设计师的动画框架，他支持在 **Web Editor** 里进行 UI 编排和动画绘制，当然现在他也支持 PC 客户端开发，整体开发环境需求上相对 Lottie 会轻量化很多。

| ![](http://img.cdn.guoshuyu.cn/20230905_Rive/image2.gif) | ![](http://img.cdn.guoshuyu.cn/20230905_Rive/image3.png) |
| -------------------------------------------------------- | -------------------------------------------------------- |

另外， rive 是通过导出矢量的动画数据文件（也可以包含一些静态资源），然后利用平台的 `Canvas `来实现动画效果，所以它的资源占用体积也不会很大。

当然，rive 其实并不是只针对 Flutter， rive 现在也是全平台支持， **Android、 iOS、Web、Desktop、Flutter 、React、Vue、C++** 等等都在支持范围之内。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image4.png)

关于 rive 的设计端的简单使用，可以看我之前的 [《给掘金 Logo 快速添加动画效果》](https://juejin.cn/post/7126661045564735519) ，其实对于程序员来说，rive 其实很好上手，打开一个 WebEdit 就可以编辑调整。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image5.gif)

>  PS，第二代 rive 和第一代 flare 存在断档不兼容，而且基本可以忽略迁移的可能，当然， **flare 和 rive 其实可以同时存在一个项目不会冲突，所以也不需要当心旧动画的升级问题**。

# Rive Flutter

开始进入主题，其实 rive 比 flare 使用起来更加简单，如下代码所示，只需要通过 `RiveAnimation.asset`  就可以实现一个下图里炫酷的动画效果，

```dart
dependencies:
  rive: 0.9.0
    
import 'package:rive/rive.dart';
RiveAnimation.asset('static/file/launch.riv'),
```

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image6.gif)

当然，除了上面的 `asset` ，还可以通过 `file` 还有 `network` 等方式这加载，这也算是比较常规的集成方式。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image7.png)

那么使用 rive ，作为开发者端，需要简单知道的几个概念：

- Artboards：画布，rive 里至少会有一块画布，当然一个 riv 动画文件可以有多个画布
- animations：需要播放的动画
- StateMachine：状态机，可以将动画连接在一起并定义切换条件的支持
- Inputs：StateMachine 的输入，然后可用于与 StateMachine 交互并修改动画切换的状态

如下代码所示，**一般情况下我们不需要关心上述设定，因为只要在设计时考虑好默认情况**，那么只需要简单引入就可以播放动画。

```dart
RiveAnimation.asset('assets/33333.riv')
```

**但是如果你需要更灵活的控制时，就需要理解上述这些设定的作用，后续才能和动画设计师进行有效的沟通和对接**。

如下图所示就是对应的设定解读，例如：

- 知道了画布名称，就可以通过 `artboard` 切换画布
- 知道动画名称，就可以通过  `animations` 指定动画
- 知道了状态机名称，就可以通过 `stateMachines` 切换状态机
- 知道了状态条件，就可以通过 `findInput` 来切换条件变量

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image8.png)

## animations

我们先看 animations ，默认情况下 `33333.riv`   这个 riv 动画播放的是 `Shaking`  效果，从上图左下角可以看到 `Shaking` 是一个有循环♻️标识的动画，所以如下图所示车辆动画处于都懂状态。

```dart
RiveAnimation.asset('assets/33333.riv')
```

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image9.gif)

接着我们更新代码，添加了 `animations` 选择播放 `"Jump"` ，可以看到，车辆播放到了 Jump 效果的动画，并停留不动，因为 Jump 不是循环动画，所以只会播放一次，然后可以看到 `Shaking`  也没有了，因为我们只选中了  `Jump` 。

```dart
RiveAnimation.asset(
  'assets/33333.riv',
  animations: [
    "Jump",
  ],
)
```

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image10.gif)

同样，如果我们多选中一个 `Wheel` 动画，可以看到车轮开始动起来，因为 `Wheel` 也是一个循环♻️动画，所以车轮可以一直滚动。

```dart
RiveAnimation.asset(
  'assets/33333.riv',
  animations: [
    "Jump",
    "Wheel",
  ],
)
```

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image11.gif)

> 所以通过 animations 我们可以快捷组合需要播放的动画效果。

## stateMachines &  Inputs

前面我们知道了可以通过 `animations` 配置动画，那么接下来再看看如何通过  `stateMachines` 来控制动画效果。

和  `animations` 一样，`stateMachines` 同样是一个`List<String>`，也就是可以配置多个状态，例如通过前面编辑器我们知道，此时 `33333.riv` 的状态机只有一个 `State Machine 1` ，所以我们只需要配置上对应的 `stateMachines` ，就可以看到此时车辆动起来，进入状态机动画模式，也即是 `Entry` 。

```dart
RiveAnimation.asset(
  'assets/33333.riv',
  stateMachines: [
    "State Machine 1"
  ], 
```



![](http://img.cdn.guoshuyu.cn/20230905_Rive/image12.gif)

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image13.png)

那配置 `stateMachines` 只是进入 `Entry`，如果要控制状态变化该怎么办？这就要说到 `Inputs` 。

获取  `Inputs`  我们需要在  `_onRiveInit` 回调里去获取，如下代码所示：

- 首先通过  `StateMachineController.fromArtboard` 获取到状态机的控制器，这样我们使用的是默认画板，所以直接使用初始化时传入的  `artboard` 即可
- `fromArtboard` 时通过 `State Machine 1` 指定了状态机，然后通过`onStateChange` 监听状态机变化
- 通过 `addController` 将获取到的状态机控制器添加到画布
- 通过  `findInput` 找到对应的控制状态  `SMIBool`
- 调用  `change` 改变 ` SMIBool`  的 value 来切换动画状态

```dart
RiveAnimation.asset(
  'assets/33333.riv',
  onInit: _onRiveInit,
)

SMIBool? _skin;
void _onRiveInit(Artboard artboard) {
  final controller = StateMachineController.fromArtboard(
    artboard,
    'State Machine 1',
    onStateChange: _onStateChange,
  );

  artboard.addController(controller!);
  _skin = controller.findInput<bool>('Boolean 1') as SMIBool;
}

void _onStateChange(String stateMachineName, String stateName) {
  print("stateMachineName $stateMachineName stateName $stateName");
}

void _swapSkin() {
  _skin?.change(!_skin!.value);
}
```

为什么这里是 `SMIBool` ？ 因为在该状态机设定里用的是 Bool 类型条件。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image14.png)

当然，除了 Bool 还可以用数字作为判断条件，对应的 Type 类型也会变成 `SMINumber`  。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image15.png)

另外还有 `SMITrigger` 类型， `SMITrigger`  只需要通过 `fire` 和 `advance` 去控制动画的前后切换，变化也只能单路径模式一个一个切换。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image16.png)

回到最初的设定里，通过 `_skin?.change(!_skin!.value);` 切换 Bool 值的变化，可以看到此时车辆开始在 Jump 和 Down 进行变化，这就是最简单的状态机和 Input 的示例效果。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image17.gif)

当然，如下图变高变胖的人就是通过 `SMINumber` 随意切换状态的效果，而小黑人换皮肤，就是通过 `SMITrigger`  单路径模式一个一个切换的动画效果。

| ![777777-2](http://img.cdn.guoshuyu.cn/20230905_Rive/image18.gif) | ![](http://img.cdn.guoshuyu.cn/20230905_Rive/image19.gif) |
| ------------------------------------------------------------ | --------------------------------------------------------- |

当然，动画里也可能会包含多个不同类型的 Input ，你可以通过  `StateMachineController` 的 `Inputs` 参数去获取所有你需要的  Input 去控制动画效果。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image20.png)



## 其他

### 布局调整

其实了解上面哪些，大致上你就基本学会完美使用 rive 了，剩下的一些参数支持就都是小事，例如：

```dart
RiveAnimation.network(
  'https://cdn.rive.app/animations/vehicles.riv',
  fit: BoxFit.fitWidth,
  alignment: Alignment.topCenter,
);
```

这里会用到 `fit` 和 `alignment` ，他们都是 Flutter 里常见的配置支持，这里就不多赘述，**默认情况下是  `BoxFit.Contain` 和 `Alignment.Center`** 。

### 文本支持

新版的 rive 支持运行过程中替换动画文件里的文本内容，**前提是使用新版导出，然后需要编辑器中手动设置名称的文本才能支持该能力**。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image21.png)

代码上简单说来说，就是在 `onInit` 的时候通过自定义的文本名称，然后通过  `artboard` 获取该节点，从而修改文本内容。

```dart
extension _TextExtension on Artboard {
  TextValueRun? textRun(String name) => component<TextValueRun>(name);
}

RiveAnimation.asset(
  'assets/hello_world_text.riv',
  animations: const ['Timeline 1'],
  onInit: (artboard) {
    final textRun = artboard.textRun('MyRun')!; // find text run named "MyRun"
     print('Run text used to be ${textRun.text}');
      textRun.text = 'Hi Flutter Runtime!';

  },

)
```

### 播放控制

现在的 rive 自带的 `RiveAnimationController`  对比 flare 弱化了很多，基本上就是用来实现简单的 `play` 、`pause ` 和 `stop` 等，默认官方提供了 `SimpleAnimation` 和  `OneShotAnimation ` 两种  `RiveAnimationController`  默认实现。

> 一般用不上自定义。

 `SimpleAnimation`  主要是提供单个动画的简单播放控制，如 play、 pause （`isActive`） 和 reset ，以下是官方 Demo 的示例，

```dart
class PlayPauseAnimation extends StatefulWidget {
  const PlayPauseAnimation({Key? key}) : super(key: key);

  @override
  State<PlayPauseAnimation> createState() => _PlayPauseAnimationState();
}

class _PlayPauseAnimationState extends State<PlayPauseAnimation> {
  /// Controller for playback
  late RiveAnimationController _controller;

  /// Toggles between play and pause animation states
  void _togglePlay() =>
      setState(() => _controller.isActive = !_controller.isActive);

  /// Tracks if the animation is playing by whether controller is running
  bool get isPlaying => _controller.isActive;

  @override
  void initState() {
    super.initState();
    _controller = SimpleAnimation('idle');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Example'),
      ),
      body: RiveAnimation.asset(
        'assets/off_road_car.riv',
        fit: BoxFit.cover,
        controllers: [_controller],
        // Update the play state when the widget's initialized
        onInit: (_) => setState(() {}),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _togglePlay,
        tooltip: isPlaying ? 'Pause' : 'Play',
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
```

> 主要就是通过 `isActive` 来控制动画的暂停或者播放。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image22.gif)



`OneShotAnimation`  主要用于在播放完一次动画后自动停止并重置动画，以下是官方 Demo 的示例，其实  `OneShotAnimation` 就是继承了 `SimpleAnimation` ，然后在其基础上增加了监听，在播放结束时调用  `reset` 重制动画而已。

```dart
/// Demonstrates playing a one-shot animation on demand
class PlayOneShotAnimation extends StatefulWidget {
  const PlayOneShotAnimation({Key? key}) : super(key: key);

  @override
  State<PlayOneShotAnimation> createState() => _PlayOneShotAnimationState();
}

class _PlayOneShotAnimationState extends State<PlayOneShotAnimation> {
  /// Controller for playback
  late RiveAnimationController _controller;

  /// Is the animation currently playing?
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = OneShotAnimation(
      'bounce',
      autoplay: false,
      onStop: () => setState(() => _isPlaying = false),
      onStart: () => setState(() => _isPlaying = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('One-Shot Example'),
      ),
      body: Center(
        child: RiveAnimation.asset(
          'assets/vehicles.riv',
          animations: const ['idle', 'curves'],
          fit: BoxFit.cover,
          controllers: [_controller],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _isPlaying ? null : _controller.isActive = true,
        tooltip: 'Bounce',
        child: const Icon(Icons.arrow_upward),
      ),
    );
  }
}
```

上述代码就是在行驶过程中，点击是触发 `'bounce'` 的一次性跳跃效果，`OneShotAnimation` 主要就是用在类似的一次性动画场景上，

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image23.gif)

# 最后

可以看到 Rive 的使用其实很简单，但是因为状态机的实现，它又可以很灵活地去控制不同动画的效果。

一个 riv 文件内可以包含多个画板，画板里可以包含多个动画，多个状态机和输入条件，从而实现多样化的动画效果，甚至实现 Rive 版本的 Flutter 小游戏场景。

而且 Rive 并不只是支持 Flutter ，它如今几乎支持所有你能想到的平台，那么这样的一个优秀的平台有什么缺点呢？

**那就是 Rive 最近开始收费了**，完全的商业化产品， 其实不给钱你也可以用，**只是 Free 模式下已经不是以前那个眉清目秀的 Rive 了**。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image24.png)

Free 模式的 Rive 会有多个如下图所示的 `Make with Rive` 的水印，同时现在 Free 模式不支持 Share links 了，也就是你自己体验一下，要投入生产使用还是得付费。

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image25.png)

![](http://img.cdn.guoshuyu.cn/20230905_Rive/image26.png)

那么有机智的小伙伴可能就要说了， Rive 不是开源的吗？那我们可以自己弄一套免费的吗？

答案是可以，但是成本无疑巨大，**因为 Rive 的门槛不在于它开源的端侧 SDK ，而是在于设计端和产出端**，目前的水印是在导出时强制加上的，所以对于使用 Rive 的用户来说，自己搭一套明显不现实。

那么，最后，你会愿意为这样一套产品而付费吗？反正我是已经付费ing了。