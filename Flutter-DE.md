 # 什么？Flutter 可能会被 SwiftUI/ArkUI  化？全新的 Flutter Roadmap 

在刚刚过去的 [FlutterInProduction](https://juejin.cn/post/7449373647255535666) 活动里，Flutter 官方除了介绍「历史进程」和「用户案例」之外，也着重提及了未来相关的 roadmap ，其中就有 [3.27 里的 Swift Package Manager](https://juejin.cn/post/7447097960011923506) 、[ Widget 实时预览](https://juejin.cn/post/7441006286765064218) 和 Dart 与 native 平台原生语言直接互操作支持等 case ，但是在最后  Flutter 还提到了一个有趣的点：*“Make Flutter Code quicker to write and easier to read”* 。

![](http://img.cdn.guoshuyu.cn/20241218_De/image1.png)

让 Flutter 代码变得更好写好读，这个点为什么有趣呢？如下图所示，可以看到 **Flutter 提出了一个 Decorators 的支持的例子**，也就是让左边的代码可以通过右边的组织方式去实现：

![](http://img.cdn.guoshuyu.cn/20241218_De/image2.png)

这就很有意思了，**我们对比现有 SwiftUI 和 ArkUI 的实现，好家伙，Flutter 这是在准备把自己 SwiftUI/ArkUI  化吗**？

![](http://img.cdn.guoshuyu.cn/20241218_De/image3.png)

其实对于 SwiftUI 开发者而言，Decorator 模式应该并不陌生，因为 SwiftUI 的设计本身就支持 Decorator 模式，开发者应用于视图的每个 modifier 行为都是一个 view wraps， 其实如果你再对比 Compose 里的 Modifier ，大家看起来也是“殊途同归”：

![](http://img.cdn.guoshuyu.cn/20241218_De/image4.png)

而回到 Flutter 里，这种代码被  “SwiftUI/ArkUI  化”的行为体现就在于：

- 原本应该是： `Padding(padding: EdgeInsets.all(10), child: MyButton())` 
- Decorator 之后是：  `MyButton().padding(EdgeInsets.all(10))` 

当然，喜欢 Decorator 这种编排方式的人不少，在此之前就有一个叫 [niku](https://github.com/SaltyAom/niku) 的项目做了类似事情，只是它已经有一段时间没有更新了，这个项目通过 `typedef` 和抽象拓展，利用语法对官方控件进行二次封装，提前实现了  Flutter UI 的 Decorator 化：

![](http://img.cdn.guoshuyu.cn/20241218_De/image5.png)

当然，也并不是所有人都喜欢这种 “SwiftUI/ArkUI  化”的行为， 比如  [Flock](https://juejin.cn/post/7431032490284236839) 的负责人就表现的相当抗拒：

![](http://img.cdn.guoshuyu.cn/20241218_De/image6.png)

他在过去就曾表示过，Flutter widget 树一直是声明性的，开发者是 “声明” 了树的结构，而不是 “生成” 了树，而 Decorator 这种 widget 组合方式，他称之为 builder 模式，他更多觉得所谓的“干净”是风格偏好，而不是客观问题，“干净”的感觉并不能帮助理解问题，也不能提供“解决方案”。

```dart
Widget build(BuildContext context) {
  return const Text("Hello, world")
    .padding([Edge.leading, Edge.vertical], 20)
    .padding([Edge.trailing], 8);
}

Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Padding(
      padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20),
      child: Text("Hello, world"),
    ),
  );
}
```

例如对于下面代码的 widget tree ，在每行代码后面的注释都有一个数字，而这些 tree 里每个 widget 的相对后代级别。

```dart
Widget build(BuildContext context) {
  return Scaffold( // 1
    body: Container( // 2
      child: const Text("Hello, world") // 5
        .padding([Edge.leading, Edge.vertical], 20) // 4
        .padding([Edge.trailing], 8), // 3
      ),
    ),
  );
}
```

也就是在一个普通的声明式 widget 树中，开发者是可以总是从外面向内读取，可以通过单调递增的深度顺序阅读；而在  Decorator 组合下，读取顺序是相反的，实际 tree 需要从内到外阅读，以一个单调递减的深度顺序。

另外他也认为，构建器会创建不可预测的深度顺序，从而损害可读性并增加混乱，而一旦这种模式流行起来，它们将感染包、包内、包内的代码，而随着这种复杂性在 package 生态系统中深入，这种模式的直接复杂性将乘以数量级。

**不过从我的角度上感受，Flutter 如果能完成 “SwiftUI/ArkUI  化”，那么其实大多数开发者应该还是欢迎的**，就像开始说的，这个调整的核心是 *“Make Flutter Code quicker to write and easier to read”* ，我是觉得这种模式里，大多场景下开发效率和可观性还是能提升不少。

当然，目前 Decorator 还是评估阶段，还处于「进行用户研究」的情况，**目前官方也担心，同时保持两个 Widget 模型的复杂性大于好处**。

![](http://img.cdn.guoshuyu.cn/20241218_De/image7.png)



除此之外，还有其他一些相关的新特性被提到，例如 **Enum shorthands**，未来 Flutter 开发者可能只需要做使用 `.spaceEvenly` 而不是 `MainAxisAlignment.spaceEvenly`，这对于效率提升上来说还是很可观的：

![](http://img.cdn.guoshuyu.cn/20241218_De/image8.png)

还有一个就是  **Primary Constructors**  ，它支持隐式创建变量，从这个角度看，代码简洁的程度也得到了不少提升，特别如果后续在宏开发和 JSON 序列化上，整体代码感受会更不一样：

![](http://img.cdn.guoshuyu.cn/20241218_De/image9.png)

当然，可能你就会觉得，**这又是什么 Kotlin 化的行为**～只能说是，殊途同归，殊途同归～～～

![](http://img.cdn.guoshuyu.cn/20241218_De/image10.png)

最后，你觉得 Decorators 这种  “SwiftUI/ArkUI 化” 的实现是否更符合你的喜好？如果最终落地保持了两种 Widdget 模式，你会选择哪一种呢？

> 我觉得倒是不错，至少不管是写 Flutter、SwiftUI 还是 ArkUI ，“割裂感”会更低。



# 参考链接

- https://andrewzuo.com/live-widget-previews-39ed9c86cc80

- https://www.reddit.com/r/FlutterDev/comments/1hglmas/is_there_a_flutter_decorator_design_documentation/

- https://blog.flutterbountyhunters.com/the-builder-pattern-is-a-terrible-idea-for-your-widget-tree/

- https://x.com/SuprDeclarative/status/1869105836779590113

