
回顾了这段时间解答关于 Flutter 的各种问题后，我突然发现很多刚刚接触 Flutter 的萌新，对于 Flutter 都有着不同程度的误解，而每次重复的解释又十分浪费时间，最终我还是决定写篇文章来做个总结。

> 内容有点长，但是相信能帮你更好地去认识 Flutter 。

### Flutter 的起源

Flutter 的诞生其实比较有意思，**Flutter 诞生于 Chrome 团队的一场内部实验**， 谷歌的前端团队在把前端一些“乱七八糟“的规范去掉后，发现在基准测试里性能居然提高了 20 倍，机缘巧合下 Flutter 就这么被立项。

所以 Flutter 是基于前端诞生，同时基于它的诞生缘由，可以看到 **Flutter 本身就不会有特别多的语法糖**，作为框架它比较“保守”，选择的 Dart 语言也是保守型的语言。**而它的编程模式，语法都带有浓厚的前端色彩，可是它却最先运用在移动客户端的开发。**

所以当 Flutter 面世的时候，就需要面对一个很尴尬的状态：

- **对于客户端原生开发而言，声明式的开发方式一上手就不习惯**，习惯了代码与布局分离（java\kotlin + xml ）和命令式的对象编程，声明式开发需要额外的学习成本；**同时也觉得 Flutter 的嵌套很“恶心”。**

- 对于前端开发而言，**Flutter 的环境配置很烦人**，除了 VSCode 和 Flutter SDK 之外，还需要原生的如 Java 、Gradle 、Android SDK 、XCode 等“出圈”的环境变量（时不时遇上网络问题），而且 **Flutter 所需要的原生平台知识点对前端来说很不友好**；**同时也觉得 Flutter 的嵌套很“恶心”。**


发现没有？我没有说 Dart 语言是学习成本，因为无论对于擅长 JS 的前端而言，还是对于掌握 Java\Kotlin\Swift 的客户端而言，**Dart 无论怎么看都是“弟弟”**。

另外不管是前端还是客户端，都会对 Flutter 的嵌套很“恶心”做出抨击，但是嵌套问题严重吗？这个我们后面会聊到。

综上所述， Flutter 对于前端入坑或者客户端入坑的萌新来说，都会有一定程度的门槛和心理抵触。**那对于前端或者客户端来说，有没有必须要学习 Flutter 呢？**


### 学习 Flutter 的理由

在我接触在大多 Flutter 萌新里，**有很大一部分其实是“被迫”使用 Flutter**，因为领导或者老板要求用 Flutter ，所以不得不“欲拒还迎”地开始学习 Flutter，这就是最“有力的”理由之一 ：“老板（领导）要”，除非你选择“跳槽”飞出三界。

#### 1、个人竞争力层面

其实开发这个圈子很有意思，我们经常在长时间使用一项技术后，很容易就觉得这项技术很火，因为周边的人都在用，而其他的框架要凉，因为没人用的错觉，特别是在“媒体”的煽动下，“孕妇效应”很容易就带来认知上的误解。

去年中旬我在 [《国内大厂在移动端跨平台的框架接入分析》](https://juejin.cn/post/6844904177949212680) 就针对 53 个样本做过简单的数据分析，可以看到其中 *flutter（19) 、weex（17）、react-native（22）* ，同时下图是在个人手机用 `libChecker` 统计出来使用 Flutter 的生产应用。

![](http://img.cdn.guoshuyu.cn/20210429_Flutter-WHAT/image1)

介绍这个只要是想表达：**Flutter 现在已经不是曾经的小众框架，这两年里它已经逐步成为主流的跨平台开发框架之一。**

所以 Flutter 确确实实可以成为你找工作的一个帮助，当然我并不推荐你从零开始学习 Flutter ，**因为 Flutter 本身只是一个跨平台 UI 框架。**

> **理解上面这句话很重要，因为他可以避免你被“贩卖焦虑”**， Flutter 尽管支持移动端、Web 端和 PC 端，但是作为 UI 框架，它主要帮助我们解决的是 UI 和部分业务逻辑的“跨平台”， 而**和平台相关的诸如蓝牙、平台交互、数据存储、打包构建等等都离不开原生的支持**。

现阶段的跨平台框架，不管的 Flutter 还是 react-native 和 weex ，它们的定位都是 UI 框架，**它们解决的是 UI 业务跨平台的成本**，它们的发展都离不开原生平台开发的支持。

如果原生平台都挂了，那还跨个蛋？比如现在谁还会说要跨 WinPhone ？**所以 Flutter 和原生平台应该是相互成长的局势，而不是那些《xxx制霸，###要凉的》的“节奏党”**，都是寄生和共生的关系，没有对应平台的开发经验，是很难把 Flutter 用得“愉悦”。


**不过现在 Flutter 确确实实可以帮助到你的职业发展，因为通过 Flutter 放大你的业务开发能力，让你参与到更多的平台开发中，不过是大前端还是KPI**。当然这些 react-native、 uni-app 也可以带给你，甚至对于前端开发来说可能更低，那为什么还要选择 Flutter 呢？

> 事实上还有一个有意思的点，对于 Android 原生开发来说，学会 Flutter 等于学会了 70% 以上的 Jetpack Compose 。


#### 2、Flutter 的一致性

**事实上从我个人一直比较推荐客户端学 Flutter ，因为对于前端来说 react-native、 uni-app 确实是性价更高的**，当然好像各位的领导和老板们不是这么觉得。

那么使用 Flutter 有什么额外的好处呢？**那就是 Flutter 的性能和一致性**。

**因为 Flutter 作为 UI 框架，它是真的跨平台！** 为什么要强掉 *“真·跨平台”* ，因为和 react-native 、 weex 不同，Flutter 的控件不是通过原生控件去实现的渲染，而是由 Flutter Engine 提供的平台无关的渲染能力，也就是 **Flutter 的控件和平台没关系**。


> 简单来说，原生平台提供一个 `Surface` 作为画板，之后剩下的只需要由 Flutter 来渲染出对应的控件，而这个过程最终是打包成 AOT 的二进制完成。


所以 **Flutter 的 UI 控件可以做到所见即所得**，这个对我个人来说是很重要的进步。为什么这么说呢？这时候就需要拿 react-native 来做对比。


因为 react-native 是通过将 JS 里的控件转化为原生控件进行渲染，所以 rn 里的控件是需要依赖原生平台的控件，**所以不同系统之间原生控件的差异，同个系统的不同版本在控件上的属性和效果差异**，组合起来在后期开发过程中就是很大的维护成本。


![](http://img.cdn.guoshuyu.cn/20210429_Flutter-WHAT/image2)


在我 react-native 开发生涯中，就经常出现：

- 在 iOS 上调试好的样式，在 Android 上出现了异常；
- 在 Android 上生效的样式，在 iOS 上没有支持；
- 在 iOS 平台的控件效果，在 Android 上出现了不一样的展示，比如下拉刷新，`Appbar`等；

当然，这些问题最终都可以通过 `if` `else` 和自定义平台控件来解决，但是随着项目的发展，这样的结果无疑违背了我使用跨平台的初衷。

而 Flutter 的控件特性决定了它没有这些问题，**我甚至经常只在 iOS 模拟器上开发测试所有界面逻辑，而不用担心 Android 上的兼容**，当然屏幕大小的适配是不可避免的。

> 从这个角度上不严谨地说， Flutter 更像是一个类 unity 的轻度游戏引擎，不过它提供的是 2D 的控件。

当然，Flutter 这样实现也有坏处，**那就是当你需要使用平台的控件作为混合开发时，Flutter 的成本和体验无疑被放大** ，这一点上  react-native  反而有着先天的优势。

#### 3、Flutter 的性能

其实前面也介绍过 Flutter 的性能一般情况下是比 react-native 好，关于这个也有 [《Flutter vs React Native vs Native：深度性能比较》](https://juejin.cn/post/6845166890524868615) 的文章做深入的对比，这里主要介绍几个误区：

- 1、Flutter 在 debug 和 release 下的性能差距是巨大的，因为它们之间是 JIT 和 AOT 的区别。

- 2、不要在模拟器上测试性能，这个根本没有意义，因为在手机上 Flutter 会更多依赖 GPU 的能力。

- 3、混合开发 Flutter 是有性能有影响的，比如在原有 Android 项目里，把某个模块业务逻辑改用 Flutter 实现，这对性能和内存会有很大的考验，至于为什么？就是前面说过 Flutter 独立的控件渲染和堆栈管理带来的负面效果。

- 4、同一个框架在不同人手下会写出不一样的结果，一般情况下**对于普通开发者来说，流行的框架一般不会带来很大的性能瓶颈，反而是开发能力比较多导致项目的瓶颈。**


### 怎么学 Flutter ？

当你快速搭建好环境，简单了解 Flutter 的 API 之后，学习 Flutter 在我看来主要有两个核心点：**响应式开发和 Widget 的背后是什么？**

#### 1、响应式开发

响应式开发相信对于前端来说再熟悉不过，**这部分内容对于前端开发来说其实可以略过**，响应式编程也叫做声明式编程，这是现在前端开发的主流，当然对于客户端开发的一种趋势，比如 Jetpack Compose 、SwiftUI 。

> Jetpack Compose 和 Flutter 的相似程度绝对让你惊讶。

什么是响应式开发呢？简单来说其实就是**你不需要手动更新界面，只需要把界面通过代码“声明”好，然后把数据和界面的关系接好，数据更新了界面自然就更新了**。

从代码层面看，对于原生开发而言，**响应式开发中没有 xml 的布局，布局完全由代码完成，所见即所得，同时你也不会需要操作界面“对象”去进行赋值和更新，你所需要做的就是配置数据和界面的关系**。

举个例子：

- 以前在 Android 上你需要写一个 xml ，然后布局一个 `TextView` ，通过 `findViewById` 得到这个对象，再调用 `setText` 去赋值；
- 现在 Flutter 里，你只需要声明一个 `Text` 的 `Widget` ，并把 `data.title` 这样的数据配置给 `Text` ，当数据改变了， `Text` 的显示内容也随之改变；

![](http://img.cdn.guoshuyu.cn/20210429_Flutter-WHAT/image3)

对于 Android 开发而言，大家可能觉得这不就是 `MVVM` 下的 `DataBinding` 也一样吗？其实还不大一样，更形象的例子，这里借用扔物线大佬在谷歌大会关于 Jetpack Compose 的分享，为什么 `Data Binding` 模式不是响应式开发：


> 因为 `Data Binding`（不管是这个库还是这种编程模式）并不能做到「声明式 UI」，或者说 声明式 UI 是一种比数据绑定更强的数据绑定，比如在 Compose 里你除了简单地绑定字符串的值，还可以用布尔类型的数据来控制界面元素是否存在，例如再创建另外一个布尔类型的变量，用它来控制你的某个文字的显示：


![](http://img.cdn.guoshuyu.cn/20210429_Flutter-WHAT/image4)


> 注意，当 `show` 先是 `true` 然后又变成 `false` 的时候，不是设置了一个 `setVisibility(GONE)` 这样的做法，而是直接上面的 `Text()` 在界面代码中消失了，每次数据改变所导致的界面更新看起来就跟界面关闭又重启、并用新的数据重新初始化了一遍一样，这才叫声明式 UI，这是数据绑定做不到的。
> 
> 当然 Compose 并不是真的把界面重启了，它只会刷新那些需要刷新的部分，这样的话就能保证，它自动的更新界面跟我们手动更新一样高效。


在 Flutter 中也类似，当你通过这样的 `ture` 和  `false` 去布局时，是直接影响了 `Widget` 树的结构乃至更底层的渲染逻辑，所以作为 Android 开发在学习 Flutter 的时候，就需要习惯这种开发模式，“放弃” 在获取数据后，想要保存或者持有一个界面控件进行操作的想法。另外**在 Flutter 中，持有一个 Widget 控件去修改大部分时候是没意义的，也是接下来我们要聊的内容**。


#### 2、Widget 的背后

**Flutter 内一切皆 `Widget` ，`Widget` 是不可变的（immutable），每个 `Widget` 状态都代表了一帧。**

理解这段话是非常重要的，这句话也是很多一开始接触 Flutter 的开发者比较迷惑的地方，因为 Flutter 中所有界面的展示效果，在代码层面都是通过 `Widget` 作为入口开始。


`Widget` 是不可变的，说明页面发生变化时 `Widget` 一定是被重新构建， `Widget` 的固定状态代表了一帧静止的画面，当画面发生改变时，对应的 Widget 一定会变化。


举个我经常说的例子，如下代码所示定义了一个 `TestWidget`，`TestWidget` 接受传入的 `title` 和 `count` 参数显示到 `Text` 上，同时如果 `count` 大于 99，则只显示 99。

```dart

/// Warnning
/// This class is marked as '@immutable'
/// but one or more of its instance fields are not final
class TestWidget extends StatelessWidget {

  final String title;

  int count;

  TestWidget({this.title, this.count});

  @override
  Widget build(BuildContext context) {
    this.count = (count > 99) ? 99 : count;
    return Container(
      child: new Text("$title $count"),
    );
  }
}
```

这段代码看起来没有什么问题，也可以正常运行，但是在编译器上会有 *“This class is marked as '@immutable'，but one or more of its instance fields are not final”* 的提示警告，这是因为 `TestWidget` 内的 `count` 成员变量没有加上 `final` 声明，从而在代码层面容易产生歧义。

> 因为前面说过 `Widget` 是 `immutable` ，所以它的每次变化都会导致自身被重新构建，也就是 `TestWidget` 内的 `count` 成员变量其实是不会被保存且二次使用。

如上所示代码中 `count` 成员没有 `final` 声明，所以理论是可以对 `count` 进行二次修改赋值，造成 `count` 成员好像被保存在 `TestWidget` 中被二次使用的错觉，容易产生歧义，比如某种情况下的 `widget.count`，所以需要加这个 `final` 就可以看出来 `Widget` 的不可变逻辑。

如果把 `StatelessWidget` 换成 `StatefulWidget` ，然后把 `build` 方法放到 `State` 里，`State` 里的 `count` 就可以就可以实现跨帧保存。

```dart
class TestWidgetWithState extends StatefulWidget {
  final String title;

  TestWidgetWithState({this.title});

  @override
  _TestWidgetState createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidgetWithState> {
  int count;

  @override
  Widget build(BuildContext context) {
    this.count = (count > 99) ? 99 : count;
    return InkWell(
      onTap: () {
        setState(() {
          count++;
        });
      },
      child: Container(
        child: new Text("${widget.title} $count"),
      ),
    );
  }
}
```

所以这里最重要的是，首先要理解 **`Widget` 的不可变性质，然后知道了通过 `State` 就可以实现数据的跨 `Widget` 保存和恢复，那为什么 `State` 就可以呢？**

这就涉及到 Flutter 中另外一个很重要的知识点，`Widget` 的背后又是什么？事实上在 Flutter 中 Widget 并不是真正控件，**在 Flutter 的世界里，我们最常使用的 `Widget` 其实更像是配置文件，而在其后面的 `Element` 、`RenderObject` 、`Layer` 等才是实际“干活”的对象。**

> `Element` 、`RenderObject` 、`Layer` 才是需要学习理解的对象。

简单举个例子，如下代码所示，其中 `testUseAll` 这个 `Text` 在同一个页面下在三处地方被使用，并且代码可以正常运行渲染，如果是一个真正的 `View` ，是不能在一个页面下这样被多个地方加载使用的。

![](http://img.cdn.guoshuyu.cn/20210429_Flutter-WHAT/image5)


在 Flutter 设定里，`Widget` 是配置文件告诉 Flutter 你想要怎么渲染， `Widget` 在 Flutter 里会经过 `Element` 、`RenderObject`、乃至 `Layer` 最终去进行渲染，所以作为配置文件的 `Widget` 可以是 `@immutable`，可以每次状态更新都被重构。


所以回到最初说过的问题：**Flutter 的嵌套很恶心？是的 Flutter 设定上确实导致它会有嵌套的客观事实，但是当你把 `Widget` 理解成配置文件，你就可以更好地组织代码，比如 Flutter 里的 `Container` 就是一个抽象的配置模版。**

> 参考 `Container` 你就学会了 Flutter 组织代码逻辑的第一步。

同时因为 `Widget` 并不是真正干活的，所以嵌套事实上并不是嵌套 `View` ，一般情况下 `Widget` 的嵌套是不会带来什么性能问题，因为它不是正式干活的，嵌套不会带来严重的性能损失。

举个例子，当你写了一堆的 `Widget` 被加载时，第一次会对应产生出 `Element` ，之后  `Element` 持有了 `Widget` 和 `RenderObject` 。

简单的来说，一般情况下画面的改变，就是之后 `Widget` 的变化被更新到  `RenderObject` ，而在 Flutter 中能够跨帧保存的 `State` ，其实也是被 `Element` 所持有，从而可以用来跨 `Widget` 保存数据。

> 所以 `Widget` 的嵌套一般不会带来性能问题，每个 `Widget` 状态都代表了一帧，可以理解为这个“配置信息”代表了当前的一个画面，在 `Widget` 的背后，嵌套的 `Padding` 、`Align` 这些控件，最后只是 `canvas` 时的一个“偏移计算”而已。

所以理解 `Widget` 控件很重要，`Widget` 不是真正的 `View` ，它只是配置信息，只有理解了这点，你才会发现 Flutter 更广阔的大陆，比如：

- Flutter 的控件是从 `Elemnt` 才开始是真正的工作对象；
- 要看一个 `Widget` 的界面效果是怎么实现，应该去看它对应的 `RenderObejcet` 是怎么绘制的；
- 要知道不同堆栈或者模块的页面为什么不会互相干扰，就去看它的 `Layer` 是什么逻辑；
- 是不是所有的 `Widget`  都有 `RenderObejcet` ？ `Widget` 、 `Elemnt` 、`RenderObejcet` 、`Layer` 的对应关系是什么？

**这些内容才是学 Flutter 需要如理解和融汇贯通的，当你了解了关于 `Widget` 背后的这一套复杂的逻辑支撑后，你就会发现 Flutter 是那么的简单，在实现复杂控件上是那么地简单，`Canvas` 组合起来的能力是真的香。**

当然具体展开这部分内容不是三言两语可以解释完，在我出版的 **《Flutter开发实战详解》** 中第三章和第四章就着重讲解的内容，也是这出版本书主要的灵魂之处，这部分内容不会因为 Flutter 的版本迭代而过时的内容。

> 这算做了个小广告？？


### Flutter 是个有坑的框架

最后讲讲 Flutter 的坑，事实上没有什么框架是没有坑的，如果框架完美得没有问题，那我们竞争力反而会越来越弱，可替换性会更高。

> 这也是为什么一开始 Andorid 和 iOS 开发很火热，而现在客户端开发招聘回归理性的原因，因为这个领域已经越来越成熟，自然就“卷”了。

事实上我一直觉得使用框架的我们并没有什么特殊价值，而解决使用框架所带来的问题才是我们特有的价值。

而 Flutter 的问题也不少，比如:

- `WebView` 的问题：Flutter 特有的 UI 机制，导致了 Flutter 需要通过特殊的方式来接入比如 `WebView` 、`MapView` 这样的控件，而这部分也导致了接入后不断性能、键盘、输入框等的技术问题，具体可以参考：[《Hybrid Composition 深度解析》](https://juejin.cn/post/6858473695939084295) 和 [《 Android PlatformView 和键盘问题》](https://juejin.cn/post/6844904070906380296) 。

- 图片处理和加载：**在图片处理和加载上 Flutter 的能力无疑是比较弱的**，同时对于单个大图片的加载和大量图片列表的显示处理上，**Flutter 很容易出现内存和部分 GPU 溢出的问题**。而这部分问题处理起来特别麻烦，如果需要借用原生平台来解决，则需要通过外界纹理的方式来完成，而这个实现的维护成本并不低。

- 混合开发是避免不了的话题：因为 Flutter 的控件和页面堆栈都脱离原生平台，所以混合开发的结果就会导致维护成本的提高，现在较多使用的 `flutter_boost` 和 `flutter_thrio` 都无法较好的真正解决混合开发中的痛点，所以对于 Flutter 来说这也是一大考验。


![](http://img.cdn.guoshuyu.cn/20210429_Flutter-WHAT/image6)


**然而事实上在我收到关于 Flutter 的问题里，反而大部分和 Flutter 是没有关系的**，比如：

- “`flutter doctor` 运行之后卡住不动”
- “`flutter run` 运行之后出现报错”
- “`flutter pub get` 运行之后为什么提示 dart 版本不对”
- “运行后出现 Gradle 报错，显示 timeout 之类问题”
- “iOS 没办法运行到真机上”
- “xxx这样的控件有没有现成的”
····

说实话，如果是这些问题，我觉得这并不是 Flutter 的问题，大部分时候是看 log 、看文档和网络的问题，甚至仅仅是搜索引擎检索技术的问题。。。。

![](http://img.cdn.guoshuyu.cn/20210429_Flutter-WHAT/image7)


虽然 Flutter 有着这样那样的问题，但是综合考虑下来，它对我来现阶段确实是最合适的 UI 框架。


### 最后

很久没写这么长的内容了，一般写这么长的内容能看完的人也不多，只是希望这篇文章能让你更全面地去理解 Flutter ，或者能帮你找到 Flutter 学习的方向，最后借用某位大佬说过的一句话：

> “能大规模商用的技术，都不需要太高的智商，否则这种技术就不可能规模化。某些程序员们，请停止你们的蜜汁自信。”















