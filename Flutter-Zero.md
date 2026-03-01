# Flutter Zero 是什么？它的出现有什么意义？为什么不少人对它抱有期待

**`flutter_zero`**  是一个由 [`knopp`](https://github.com/knopp) 发起的实验性项目，它的核心目的是**利用新的 Dart 特性（主要是 FFI）重新构想 Flutter 的架构，将 Flutter 的底层 Engine 从 C++ 迁移到 Dart，并解耦 `dart:ui`** 。

![](https://img.cdn.guoshuyu.cn/image-20260206212953529.png)

> 如果你对 Knopp 陌生，那么现在认识下，Flutter PC 端和多窗口等功能，不少是他在参与维护。

对于 `flutter_zero`， 这个项目的核心目标是：

- 重写和瘦身： `flutter_zero` 试图通过全新 Dart   FFI  等能力来替代原本由 C++ 实现的 Flutter 引擎的大部分功能
- **解耦 `dart:ui`** ： 目前的 Flutter 中 `dart:ui` 是一个深度耦合的单体式库，充满了各种抽象层，而`flutter_zero` 试图将 `dart:ui`  模块化，让它不再强依赖于底层的 C++ 引擎，**我相信你在看源码和 Debug 问题时，一定经历过  `dart:ui`   的痛** 
- **Dart 优先**  ：尽可能用 Dart 代码替换原本的 C++、Objective-C 或 Java 引擎代码，而不是通过传统的 Platform Channels，并且这并不会带来性能问题

那为什么会有这样的想法？其实来自很多方面，比如：

- 由于 Flutter 引擎是用 C++ 写的，构建成功高，而且没有 Hot Reload，修改容易崩溃，**这导致引擎层的贡献者远少于框架层**（Framework），而如果引擎逻辑更多地由 Dart 编写，社区开发者就能更容易地贡献代码，并且底层也能享受到 Dart 的 Hot Reload 支持
- 目前 Dart 生态被分为 “纯 Dart 项目” 和 “Flutter 项目” ，**纯 Dart 包不能使用 Flutter 的类型（如 `Listenable`），因为它们绑定在  `dart:ui`  里**，这导致库作者必须维护两套代码（例如 `signals_core` 和 `signals`），而如果将核心类型从 SDK 中剥离出来，变成独立的包（如 `package:flutter/ui.dart`），这样纯 Dart 项目也可以依赖这些基础类型，统一生态
- `dart:ui` 为了跨平台，只提供了“最小公分母”的 API，要访问特定平台的 API（如 iOS 的特定视图或输入法），必须使用 Platform Channels，但是写过的知道 ，Channel 麻烦不说，性能还不好，而如果内部直接使用 Dart 通过 FFI 直接与平台 API 交互，甚至是将原本在引擎里的底层功能（如无障碍功能、文本输入）移到 Dart 层来实现，这对性能也是一大提升

**FFI 对比 Channel 能快多少，如果做过大数据频繁交互的应该有所体会，如果没有，看这个图也可以直观对比** ：

![](https://img.cdn.guoshuyu.cn/ezgif-40ce8ffc82c11313.gif)

能看出区别吗：

- 左边 Channel 模式获取系统电量，启动后可以看到先显示 0， 之后才显示电量
- 右边 FFI 启动时看到 UI 就是已经获取完电量显示了

另外还有一个点，不管是[小米系统应用切换成 Flutter+Rust](https://juejin.cn/post/7602512064977207359) ，又或者之前 Oppo 的负一平和灵动岛使用的 Flutter ，甚至微信小程序渲染引擎 skyline 使用 Flutter ，它们都不是正常使用，而是各种魔改定制，但是目前的耦合加大了这种定制的成本。

![](https://img.cdn.guoshuyu.cn/2ea953d6-0e1f-4e85-8eef-0ddb44e2d5b5.png)![](https://img.cdn.guoshuyu.cn/image-20260206220145267.png)

例如嵌入式场景，遇到过一些在嵌入式系统，或者之前的 LG 电视 WebOS 使用 Flutter 等场景，它们都是需要一些特殊定制的去嵌入，特别是在一些嵌入式 Linux 设备上，并没有标准的 GPU 或屏幕（单色 OLED 屏或 LED 阵列），这时候完整 Flutter 太重了，**而 `flutter_zero` 这种“无偏见（un-opinionated）”的构建方式，允许开发者只使用 Dart 的逻辑层，而不必背负完整的图形渲染引擎，非常适合这种特殊的硬件场景**。

> 这个 Zero 代表了，引擎只需要处理跨平台的嵌入逻辑，而不必像现在这样作为一个巨大的单体存在。

这种将 Flutter 剥离成一个极简的“内核”，移除 `dart:ui` 层和 C++ 的场景，还可以让 Flutter 的跨平台逻辑层面更好被其他框架利用，例如去年底的时候，**Avalonia 久宣布投资 Impeller ， 和 Flutter 团队合作[将他们的 GPU 优先渲染器 Impeller 移植到 .NET 平台](https://avaloniaui.net/blog/avalonia-partners-with-google-s-flutter-t-eam-to-bring-impeller-rendering-to-net)** ，这也是一种需求方向：

> 让 Flutter 成为更底层的基建，而为了这样，就必须让 Flutter 有更 Zero 的架构。

那为什么这个行为只能让社区发起呢？

因为这是一个非常庞大的重构，这种将的将 Flutter 剥离成一个极简的“内核” 的方式，属于是试图将 Flutter "Dart 化"和"模块化"的激进尝试，如果由官方发起，肯定会带来大量的稳定性忧虑的反对声，而由社区发起则不一样，发起人即是 Flutter 的底层维护人员，又是活跃的社区人员，他的尝试既不代表官方，又可以一定程度获得官方的支持。

不过有一点可以明确，**在 Framework 抛弃 Channel 全面走向 FFI 是必然的目标，而 Zero 更多只是一个实验性尝试，但它激发的讨论可能会影响 Flutter 官方未来的架构演进方向，让  Flutter 未来更适合跑在更多非标准硬件上**。

那么，现在你理解为什么 Flutter Zero 值得关注了吧？



