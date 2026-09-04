---
title: "Flutter 3.47 发布，快来看看有什么更新吧"
---

# Flutter 3.47 发布，快来看看有什么更新吧

随着 Google I/O China 的召开，Flutter 3.47 如约而至，这次更新的主要有 **Material / Cupertino 正式从 Flutter SDK 解耦、Impeller 成为 PC 端全系默认渲染器、Widget Preview 转 Stable、Wasm 默认化继续推进、 给 Xcode 27 / iOS 27 / macOS 27  适配做迁移**，属于一个不大不小的更新，但是至少 PC 端得到了加强。

![](https://img.cdn.guoshuyu.cn/20260812/hero_image.049a8f4d89d8082a040f98f1d74b91b2-a96973.gif)



# 解耦包

首先就是独立版本的  [`material_ui`](https://pub.dev/packages/material_ui) 和 [`cupertino_ui`](https://pub.dev/packages/cupertino_ui)  1.0 版本终于发布了，以前的：

```dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
```

现在可以都转移到：

```dart
import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
```

![](https://img.cdn.guoshuyu.cn/94254f08-b795-4c9f-866b-9381614f232a.png)

当然，最重要的是 **Material / Cupertino 脱离 Flutter 季度 Stable 节奏独立更新**，Flutter 目前计划这些 UI package 可以按照**周级别 cadence** 发布修复和新功能。

当然  3.47  版本不会强迫你一定要转移，老的导入方式还在，你可以通过 Flutter 的自动 migration 进行迁移：

```shell
dart fix --apply --code=migrate_design_widgets
```

App 里的迁移其实都没什么问题，主要还是第三方 package 里的，比如：

```
你的 App
 ├── material_ui
 │
 └── plugin A
      └── package:flutter/material.dart
```

这种时候新旧 Material 类型有可能产生迁移期兼容问题，所以 Flutter 提供了 `MaterialUiCompatibilityBridge`  用来跨过生态迁移期，例如：

```dart
MaterialApp(
  builder: (context, child) {
    return MaterialUiCompatibilityBridge(
      child: child!,
    );
  },
)
```

`MaterialUiCompatibilityBridge` 的主要作用是：*负责 bridge `ThemeData` 和 `MaterialLocalizations`，让还依赖 `package:flutter/material.dart` 的 legacy widget 能在新的 widget tree 里正常工作，适配类似 `Theme.of(context)` 场景下， `flutter.material.Theme` 和  `material_ui.Theme` 的对应关系*。

> 当然，实际上包开发者也需要注意，比如你维护的是一个 pub.dev package，把 package 从旧 Material/Cupertino API 迁到 standalone design package，那这时候也应该发布为 major release ，做一个大版本的断档更新，因为这个对用户来说也是类似。

这里还需要注意， `Localizations `也拆了，以前的是：

```dart
import 'package:flutter_localizations/flutter_localizations.dart';

localizationsDelegates: [
  GlobalCupertinoLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
]
```

现在  Material / Cupertino 自己对应的 localization 也迁到了各自 package，**然后官方给出的时间是，今年 11 月就准备正式 Deprecated 内置 package 的导入，所以最好还是关注下依赖的包还有没有在维护，需不需要做迁移**。

# Impeller 

Flutter 3.47 开始三个 PC 端也全面默认切换到 Impeller 了，也就是 Flutter GPU 和我们之前提到各种 3D 渲染和游戏能力，正式在除了 Web 平台全系列支持了，不过目前还是提供了降级接口：

- macOS： `FLTEnableImpeller = false`

- Windows：

  ```c++
  project.set_impeller_switch(
    flutter::ImpellerSwitch::Disabled
  );
  ```

- Linux：

  ```
  fl_dart_project_set_enable_impeller(
    project,
    FALSE
  );
  ```

之前我们提到的 Desktop 文本问题也改了一波，Flutter 3.47 的 Impeller Desktop 开始用 SDF(Signed Distance Function) 来做文字和矢量曲线相关渲染，**因为桌面通常 GPU 性能更好，但是 DPI 普遍偏低，所以字体模糊之类的问题更多，而 SDF 可以利用更多 GPU 计算换取比较锐利、稳定的边缘表现**。

同时也在针对 Desktop 的视觉特征重新做一些 renderer 优化，同时 macOS 这次还默认开启了 Wide Gamut Color，支持硬件上可以直接使用更宽的色域进行渲染。

> 这波 PC 端终于来了一波大加强。

# Flutter 多窗口

多窗口继续有新进展，比如 Windows / Linux 支持 popup window，所以一些以前很难做得真正“桌面原生”的东西，例如：

- Context Menu
- Floating palette
- Tool window
- Popup

![](https://img.cdn.guoshuyu.cn/9cd6538d-1c1e-429e-be5f-ee767f57ae3b.png)

现在这些场景都支持通过真正独立 native window 做，甚至可以直接拿到底层 native window，现在 platform-specific controller 可以拿到：

- Windows ：HWND 
- macOS ： NSWindow 
- Linux  ：GtkWindow

这个能力其实非常实用，我们之前的文章也聊过，因为这意味着 Flutter Desktop 遇到框架 API 覆盖不到的能力，可以直接进入：

```
Flutter
   ↓
windowHandle
   ↓
Win32 / AppKit / GTK
```

比如官方展示的 Windows Dockable Pane demo，对于真正复杂的 Desktop App，这是一个很关键的 escape hatch。

![](https://img.cdn.guoshuyu.cn/20260812/dockable_panes.e811d4a87b2cea412e5f2aae2e0ad60d-c6ec48.gif)

另外多窗口的几个老问题也修了，例如之前我们提到过的， Windows 以前一个窗口激活时，可能会把其他 background window 拉到前面，或者 App resume 后窗口重新抢焦点，这类问题已经被修复。

![](https://img.cdn.guoshuyu.cn/20260812/focus_realization_fix.a761e0e36f940d273960bc65677a148f-625ffb.gif)

Linux 也修改了 window realization 顺序，避免第一帧时期的 warning / assertion，另外还新增 `sized-to-content` ，让普通 Window / Dialog 根据 Flutter content 自动计算窗口尺寸。

>  不过唯一可惜的是，还是属于 experimental。

最后，**Windows / Linux 终于支持 Flavors** ，现在可以：

```sh
flutter build windows --flavor flavor_a
```

和

```sh
flutter build linux --flavor flavor_a
```

asset 也可以按 flavor 区分：

```yaml
flutter:
  assets:
    - path: assets/flavor_a/images
      flavors:
        - flavor_a
    - path: assets/flavor_b/images
      flavors:
        - flavor_c
```

#  Xcode 27 / iOS 27 / macOS 27

Flutter 3.47 开始新的最低支持版本提升到了 15，macOS 也提到了 12 ：

| 平台  | 原来  | Flutter 3.47+ |
| ----- | ----- | ------------- |
| iOS   | 13    | 15            |
| macOS | 10.15 | 12            |

**同时 UIScene 变成了强制要求，Xcode 27  没有适配 UIScene 会直接起动失败。**

**另外 Intel Mac 也停止适配，Flutter 3.47 已经停止 Intel Mac 的自动化测试**，Intel Mac 也开始进入退出阶段，所以推荐直接通过 `flutter config --enable-macos-arm64-only`  打包。

最后 SwiftPM 迁移已经接近完成，Top 100 iOS Flutter Plugins 中已经有 **92 个迁移 Swift Package Manager**：

> Flutter 3.44 起 SwiftPM 已经成为 iOS/macOS native dependency management 的默认方案，CocoaPods 还会继续支持，但处于 maintenance mode。

当然，更重要的是， **CocoaPods Registry 将在 2026 年 12 月 2 日 permanently read-only**

而 3.47 还优化了一次 SwiftPM build pipeline，提前过滤掉没有必要构建的 package schemes，所以使用 SwiftPM 的 Flutter iOS/macOS 项目，构建时间也有进一步优化。



# Web

Wasm 开始支持 Deferred Loading ，3.47 在 main channel 上提供 experimental：

```
flutter build web \
  --release \
  --wasm \
  --enable-wasm-deferred-loading
```

目标就是一个超大的 Wasm，可以拆成多个模块，然后启动只加载核心，其他代码按需加载，这可以尽可能解决页面打开太慢的问题。

另外官方也表示了，后续  `flutter build web --release --wasm` 会变成默认，以后 Flutter Web 应该会完全转向 wasm 的唯一 render 。

# Android 

android 这次主要是就是更新了基线，主要是：

| 项目                  | Flutter 3.47     |
| --------------------- | ---------------- |
| Java                  | **17，最低要求** |
| Kotlin Gradle Plugin  | **2.4.0**        |
| Android Gradle Plugin | **9.1.0**        |
| Gradle                | **9.3.1**        |

另外 Flutter SDK 提供的默认 Android API 参数是：

```
compileSdkVersion = API 36
targetSdkVersion  = API 36
minSdkVersion     = API 24
```

也就是 **3.47 SDK 当前提供的默认变量值 mini 建议是 24**。



# 其他

其他更新还有：

- Widget Preview 正式 Stable ，算是正式毕业了，虽然我一次也没用过

- GenUI 更新到了 0.10.0， a2ui_core 抽成了独立的核心 package ，同时支持 A2UI client-side functions ，Agent 可以告诉 Flutter Client 调用客户端函数做某些逻辑，不需要每件事都问大模型

- Android 还有一个键盘 Bug 修复，现在 key responder 对虚拟键盘输入不会继续伪造 physical key event 

- Accessibility 这次也补了一些 API 更新，Android 高对比度和颜色反转设置现在可以自动检测（ `MediaQueryData.highContrast` 和 `MediaQueryData.invertColors` ），Text.rich 内部 `Text.rich` 嵌套文本跨度现在可以和在语义树中的布局顺序相匹配，同时给  `BlockSemantics`  添加了键盘焦点阻塞

  ![](https://img.cdn.guoshuyu.cn/20260812/android_accessibility.81103bd2ca901ede0f5f72605733eb96-db4f59.gif)

- `Text Selection`  修了一批细节，比如移动端轻微滚动时 Selection Handle 不会乱跳（下面第一章 gif 就乱跳），Keyboard shortcut 可以关闭当前 selection menu 等细节支持

![](https://img.cdn.guoshuyu.cn/20260812/selection_handle_before.26d847d79d066427635ade8ac0d5e4a0-85e31f.gif)

![](https://img.cdn.guoshuyu.cn/20260812/selection_handle_after.b403b66363976dd6c06c2c6fefc31923-711a3a.gif)

- `Text Selection`   在空的可滚动容器里进行选择时 `SelectableRegion` 中的崩溃问题也没修复了，同时还解决了淡化的可选文本上的视觉高亮显示问题：

  ![](https://img.cdn.guoshuyu.cn/image-20260813075637066.png)

- PlatformView 手势也继续修，Flutter Gesture 和 UIKit View Gesture 之间的 gesture propagation 做了优化， `EdgeDraggingAutoScroller` 现在遵循  `ScrollPhysics` 的设置 ，比如 `NeverScrollableScrollPhysics `之类锁住的列表，不会因为 edge dragging 又偷偷 auto-scroll 

- 、![](https://img.cdn.guoshuyu.cn/20260812/edge_scroller_demo.539918009f0660a1ec13c79d1302efbf-61730b.gif)

- `ImageIcon` 的 `seOriginalColors: true` 可以保留原图片颜色，不会强制按 Icon tint 处理

- `AnimatedCrossFade` 可以显式指定 clipping behavior

- `ImageStreamListener`  现在可以直接跟踪 image stream error

- Graphics 还有一个 Breaking Change，Flutter 3.47 调整了 OpenGL ES render-to-texture 的坐标处理，以前 fragment shader 读取 texture 时可能需要自己 `Y coordinate flip`，现在这一步被移到 vertex shader 处理，fragment shader 不需要再自己做 conditional coordinate flipping

# 最后

这次更新属于是比较小的版本更新了，核心就是包解构正式逻辑，然后 PC 端得到了一波大加强，当然多窗口虽然有大突破，但是它就是不进入 stable ，不过问题不大，我都用了一段时间了，普通日常多窗口基本问题不大。

所以骚年，开始吃新螃蟹咯。

![](https://img.cdn.guoshuyu.cn/371b3a6501ed7025bb0c341244b3b2bd.jpg)



