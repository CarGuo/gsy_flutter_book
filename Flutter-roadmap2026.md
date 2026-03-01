# Flutter 2026  Roadmap 发布，未来计划是什么？

Flutter 在 2025 基本完成了 Impeller 移动端的过渡，其中 iOS 已经完全取消了 Skia 支持，而 Android API 29 及以上版本也默认使用 Impeller ，很大程度解决了这些平台上复杂动画的着色器编译卡顿问题，并且 hotload 也完全支持到了 Web 端 。

> 另外，根据统计已有近 30% 的全新免费 iOS 应用使用 Flutter 构建 ，高于 2021 年的约 10% ；而在 2025 的[LeanCode Flutter CTO 报告](https://leancode.co/blog/flutter-pros-and-cons-summary?utm_campaign=state-of-flutter-2026&utm_medium=referral&utm_source=devnewsletter.com)显示，Flutter 开发者在桌面平台的使用率在 macOS 上达到 24.1%，Windows 上达到 20.1%，Linux 上达到 11.2%。

![](https://img.cdn.guoshuyu.cn/image-20260224152802235.png)

那么，2026 官方在 Flutter 的重点又是什么呢？

## Impeller、Wasm 及其他

Impeller 依然是官方 2026 的重点，Impeller 可以说是 Flutter 最突出的技术成就，对于 Flutter 本身来说：

- 复杂动画中的卡顿帧减少了 30-50%
- 文本渲染速度提升了 20-40%
- 实测 Skia 的丢帧率为 12%，而 Impeller 仅为 1.5%

![](https://img.cdn.guoshuyu.cn/image-20260224153127985.png)

> 另外，Avalonia 在于和谷歌合作，计划将将 Impeller 引入.NET 平台，所以 Impeller 到现在，无疑是成功的

而官方 2026 的目标包括**完成 Android 平台的  Impeller 渲染器的迁移，并在 Android 10 及更高版本中移除旧版 Skia 后端**，另外还需要确保对 Android 17 和即将发布的 iOS 版本提供首日支持，同时持续改进 Web 和多窗口桌面环境的辅助功能。

> 此外，官方还与 [Jaspr](https://jaspr.site/) 等社区主导的框架合作，为基于传统 DOM 的高性能 Web 开发者提供支持，不过这个属于外部社区支持了。

在桌面端， Canonical 正在不断改进多窗口支持，对于 Web 端的 Flutter，官方计划将 WebAssembly (Wasm) 转正为提供原生体验和性能的默认框架。

> 可以看出来，从 3.41 多窗口体验来看，今年 stable 问题不大。

## GenUI 和  AI

官方在 2025 发布了  Flutter GenUI SDK 和 A2UI 协议 ，让 App 能用借助 AI 模型提供动态生成 UI 的用户体验，而为了继续深入支持这一点， Flutter 正在研究通过「**在 Dart 运行时中添加对解释型字节码**」的支持来改进 Dart 语言，这将实现“临时”代码交付，即应用的特定部分可以按需加载。

> 感觉这个可以为热更新提供新的官方口子？

解释执行的字节码部分可以让其和 JS一样，由已经在 App 里的解释器（Interpreter）读取并运行，这在技术上不违反 iOS  和 GP 的政策限制，从而让 GenUI 也可以动态加载一些 AI 生成的 UI 。

> 实际上 Shorebird 的原理就是**在 AOT 编译的 App 中嵌入了一个 Dart 解释器**。

此外， Flutter 也正与和 Genkit 团队合作，实现 Dart 支持，帮助开发者使用 Dart 构建更复杂的 AI 功能。

另外一个重点是为  Firebase 开发 **Dart Cloud Functions**  ，实现10 毫秒的冷启动支持，确保后端逻辑的高性能运行，同时也在研究如何为 **Google Cloud SDK** 添加 Dart 支持，从而让开发者能够轻松地在 Google Cloud 上连接和构建后端。

同时，为了确保高质量的开发者体验，Flutter 将继续与 Google 内部团队合作，确保 Dart 和 Flutter 在 Gemini CLI 和 Antigravity  有更好的开发体验，并继续投资 Dart MCP Server ，让 Flutter 在 AI 开发里可以更加精准。

> 一句话，**AI 是 Flutter 绕不过去的话题，只有和 AI 沾边了才有新的未来**。

## 现代语法和编译性能

对于 Dart 本身，**官方计划在 2026 年推出 Primary Constructor 来简化类声明，并推出 Augmentations 以简化代码生成**，从而进一步改进 `build_runner` 。

Primary Constructor  的效果大概如下，主构造函数允许在声明类名时直接定义字段和构造函数：

```dart
/// 原始的写法
class User {
  final String name;
  final int age;

  User(this.name, this.age);
}

/// Primary Constructor 的写法
// 一行直接定义了两个字段和一个构造函数
class User(String name, int age);

// 如果你想添加方法或额外的逻辑：
class Point(double x, double y) {
  double get distance => (x * x + y * y);
}

/// Primary Constructor 用法
class Person(String name);

// 继承时使用主构造函数
class Employee(String name, int id) : super(name);

// 也可以带可选参数和默认值
class Vector(double x, {double y = 0.0});
```

Augmentations 允许一个文件“增强”另一个文件中的类、方法或字段，而不需要继承：

```dart
class Calculator {
  void calculate() {
    print("Base calculation");
  }
}

import augment 'base.dart';

augment class Calculator {
  // 1. 添加一个新字段
  int lastResult = 0;

  // 2. 增强（包装）现有方法
  augment void calculate() {
    print("Starting calculation...");
    augment super(); // 调用原始方法
    print("Calculation finished.");
  }

  // 3. 添加一个新方法
  void reset() => lastResult = 0;
}
```

此外，官方还在改进 **Dart/Wasm** 在浏览器中的编译，并重构分析器以提升大规模应用的性能。

# 最后

可以看到，Flutter 的 2026 Roadmap 还是相对保守，**但是 Dart 新语法改进和解释型字节码确实值得期待下**，另外 Impeller 实现 PC 支持或者也可以小小期待下，不过 2026 Flutter 很大一部分资源肯定会和 AI 相关，毕竟 AI 才是 2026 的真正浪潮。

# 参考链接

- https://github.com/flutter/flutter/blob/main/docs/roadmap/Roadmap.md
- https://devnewsletter.com/p/state-of-flutter-2026/
- https://digitaloneagency.com.au/flutter-in-2026-the-road-ahead-key-upgrades-and-how-to-prepare-your-app-strategy