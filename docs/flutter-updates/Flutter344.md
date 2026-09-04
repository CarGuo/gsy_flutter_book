---
title: "Flutter 3.44 发布啦，超级大版本更新！！！"
---

![](https://img.cdn.guoshuyu.cn/20260520/1_vZ-dmpSHSo3nF0ChZDb02A-bf5943.gif)



# Flutter 3.44 发布啦，超级大版本更新！！！

虽然 Flutter 3.44 的版本已经发布两天了，但是今天才是真正的官宣 Flutter 3.44 发布哦，3.44 虽然看起来版本号不大，但是这确实是一个超级大版本更新。

> 也不知道为什么 Flutter 对于 3.x 这个版本号这么热爱，就和 RN 热爱 0.x 一样。

这次 3.44 核心包括 **Android HC++ 功能落地、iOS/MacOS 默认使用 Swift PM、多窗口功能落地、Material 和 Cupertino 解耦、各种 AI 场景支持、Widget Previewer 更新和各种功能优化**。

![](https://img.cdn.guoshuyu.cn/20260520/1_gz1il93fimwoqoeeWXnROA.opt-74edee.gif)

首先还是按照惯例，Flutter 先公布了近期的一些数据情况，其中 **pub.dev  在过去 30 天内， Package 下载量超过 13 亿次  ，Flutter 两大应用商店下月活开发者超过 150 万 ，一年内增长了 50%**。

> 这算是惯例对于 「Flutter 凉了没」的回覆。

# 工具更新

## Widget Previewer

虽然我基本没怎么用过，但是 Flutter 官方一直很热衷 Widget Previewer 的优化，这次主要有两个内容：

- 预览检测的逻辑重写了，使用 analysis server 做 widget preview detection，**降低了 Flutter 工具的内存占用，对于 IDE 用户而言，整体内存占用最多可降低 50%**
- **自定义 preview annotation 支持 collections 和 records**，现在可以按组、名称、脚本和包 URI 筛选预览

![](https://img.cdn.guoshuyu.cn/20260520/1_AWOBIU0sytlgElyB3n-x9w-ba46da.gif)

3.44 的 Previewer 其实就是接入了更底层的 analysis server 检测链路，主要涉及：

- IDE 能准确知道哪些函数、构造器、静态方法可以 preview
- Previewer 要能处理真实项目里的 wrapper、theme、localization、状态注入
- 依赖真实 analyzer 级别的语义信息

> 可以看出来官方对于 Widget Previewer 很重视，大概在 AI 时代，Widget Previewer 可以在开发过程中，有不错的事实预览效果。

## 不需要 Rosetta

这个我们提前聊过，在之前的 [《Flutter iOS 又修复了一个构建问题》](https://juejin.cn/post/7637433660883714090) 就提到过，以前 Flutter 本身的构建工具还是需要 Rosetta 进行适配支持，这次所有的 macOS 命令行工具都已经通过 **Fat Binary，从而同时支持 `x86_64` 和 `arm64` 两种架构**。

因为下个版本 Rosetta 就要开始推出历史舞台了，所以这也算事一个重要的跟进升级，当然，*这个能力的 PR 的过程很抽象，没看过的可以了解下，是真的草台*。。。。

![](https://img.cdn.guoshuyu.cn/image-20260521050005001.png)



# AI

Flutter 官方真的很热衷跟进各种 AI 能力，而且跟进的贼快。

## Agentic Hot Reload

3.44 官方推出了全新的 Agentic Hot Reload 功能，Flutter 在 AI 支持能力上一直很热衷，这次的  Agentic Hot Reload 也是。

![](https://img.cdn.guoshuyu.cn/20260520/1_6n-KEHq1VjiglHNYTPV-yQ-cb9970.gif)

从 3.44 开始，**一些 MCP 服务器和 Coding Agnet 支持自动查找并连接到正在运行的 Flutter App** ，也就是类似 Antigravity 这样的 Coding Agnet  可以支持使用 Hot Reload， 同时还有配置前面的 Previewer ，整体 AI 开发体验会更好。

另外，Agent 现在可以通过服务，直接读取本地 pub 包依赖，不需要去取搜索本地 pub 缓存，同时 MCP 相关的 Tools 也得到了更新。

> 实际上这个能力以前也能做到，AI 通过命令行的 `r` 输入也可以，但是这次的是让 agent 有官方路径去发现运行中的 Flutter session，agent 可以知道是哪个 App 正在运行，因为是一整套的 MCP 协议支持。

## Skills

关于 skills 在不久前我们也刚聊过，[《新 Flutter & Dart Agent Skills 深度解读》](https://juejin.cn/post/7637046499474538559) ，现在官方的 skills 都是**“任务导向型”的 Skills**，每个 Skill 都不是在描述一个功能或者说明一个文档，而是在提供一套决策逻辑，让 AI 可以通过明确指令来解决问题，并且提供对应的 反馈循环（Feedback Loop）。

![](https://img.cdn.guoshuyu.cn/20260520/1_qw6H8YVAmVFUWuI0b38bZg-d6d591.gif)

**每个技 Skill 的结果都需要做检验**，类似  `flutter-fix-layout-issues`、`flutter-add-widget-test` 、`flutter-add-integration-test` 、`flutter-build-responsive-layout`、`flutter-setup-localization` 、`flutter-implement-json-serialization` 、`flutter-add-widget-preview` 、`dart-fix-runtime-errors` 、`dart-use-pattern-matching` 都是很实用的技能。

## Genkit Dart

关于 GenKit 我们之前也一样在 [《谷歌 Genkit Dart 正式发布》](https://juejin.cn/post/7615551904538755114) 聊过，基于Genkit 可以构建全栈式 AI 驱动的智能体应用：

> **Flutter 使用 Dart 可以直接原生实现 AI 编排框架，支持不同模型和本地场景，提供 agent workflow / tool calling / RAG 等能力** 。

通过 Genkit Dart 你可以实现一整套的 Agent 的服务端和客户端能力，支持 Google、Anthropic 、 OpenAI 甚至本地模型的能力，包括类型安全的结构化输出、工具调用、多轮对话和内置的可观测性能力等等。

```dart
import 'package:genkit/genkit.dart';
import 'package:genkit_google_genai/genkit_google_genai.dart';

void main() async {
 final ai = Genkit(plugins: [googleAI()]);

 final response = await ai.generate(
   model: googleAI.gemini('gemini-flash-latest'),
   prompt: 'Why is Dart a great language for AI
            applications?',
 );

 print(response.text);
}
```



## Gemma 4 

Flutter 也支持直接跑 Gemma 4  本地模型，通过 `flutter_gemma`  插件，App 可以和 Gemma 深度集成，插件底层支持 LiteRT-LM ，支持 GPU 和 NPU 加速，最重要是支持全平台 ：

![](https://img.cdn.guoshuyu.cn/8feeb40d-76dd-40f6-8457-30249b948a6e.png)



## GenUI

这个大家应该也不陌生吧，我们在 [《Flutter GenUI 0.9 和 A2UI 0.9 发布》](https://juejin.cn/post/7640409934489010230) 才刚刚聊过，官方表示：`Flutter + A2UI = GenUI`

![](https://img.cdn.guoshuyu.cn/20260520/1_ZEXlGLmZ6hccimLUin4Jow-3fdc92.gif)

作为基于 AI 的生成式  UI 支持，Flutter 算是在 A2UI 领域最早的支持项目之一，它提供了一套完整的协议实现，**可以让 Agent 在 App 运行中动态生成控件，客户端不需要开发一个完整的页面功能，开发者只需要维护组建库**，剩下的都交给 AI 。

> 官方统计，自从推出 Flutter GenUI SDK 以来，软件包下载量自年初以来增长了 500%。

官方特别提到了 *Catagay Ulusoy* 开发的 *Finnish it* （ 可在 Google Play 商店和 Apple Store 下载 ）例子，这款应用不仅能为用户创建定制化的课程计划来学习芬兰语，还能根据每节课的需要动态生成完美的界面：

![](https://img.cdn.guoshuyu.cn/3538b20b-f230-4771-b239-5f7df425a930.png)

另外还有官方提供的 Demo ，也分享了 DeepMind 使用 Flutter 构建 Gemini App “可视化布局”的效果 ：

![](https://img.cdn.guoshuyu.cn/20260520/1_WEch_2CJNkOt1NChpXZlZw-144249.gif)

# Android

首先就是 Googlebook 支持，**我都还没用上，Flutter 就宣布了 Googlebook 已经适配完成**，核心是适配了 Gemini 处理器的全新 Googlebook 笔记本电脑，不过具体支持的如何，还需要看真的发布后才知道。

**另外还有 Android 17 的适配**， Flutter 3.44 也正在完成 Android 17 的适配，包括本地网络保护和安全动态代码加载等场景 。

## Hybrid Composition++

另外还有一个重点就是 Hybrid Composition++ 终于落地了，这个我们再去年的 [《Flutter 正在推进全新 PlatformView 实现 HCPP》](https://juejin.cn/post/7471979172115152932) 就提到过，这是一套全新的 PlatformView 实现，可以提供更好的 PlatformView 新能：





![](https://img.cdn.guoshuyu.cn/20260520/1_xNy4ENkOUVx7fotyFcG8_A-9c931a.gif)



**HCPP 不再依赖屏幕外缓冲区或强制 Flutter 引擎处理原生视图**，而是将图层合成直接委托给 Android 本地，然后利用 Vulkan 图形库的底层访问能力，通过硬件缓冲区交换链和 `SurfaceControl` 事务将 Flutter UI 与原生 Android 视图同步。

简单来说就是，**HCPP 主要就是通过 `SurfaceControl` 来构造一个高层级的 `Surface` 从而实现最终绘制时混合覆盖的问题**，这和 [《深入 Flutter 和 Compose 的 PlatformView 实现对比》](https://juejin.cn/post/7461597205342928936) 里 Compose 可以在 PlatformView 里直接使用 `SurfaceView` 的道理类似，都是 `SurfaceFlinger` 合成时的层级操作。

> 只是**需要 Vulkan 和 API 34 的环境才支持使用** 。

所以 HCPP 对 [Android API 和硬件有一定要求 ](https://docs.flutter.dev/platform-integration/android/platform-views#hcpp)，可以通过在 `run` 中添加 `--enable-hcpp`  或者在 `AndroidManifest.xml` 文件中添加相应的配置标志来启用：

```xml
<meta-data
  android:name="io.flutter.embedding.android.EnableHcpp"
    android:value="true" />
```

## Android 显示屏圆角

Android 设备圆角支持，`PredictiveBackPageTransitionsBuilder` 新增对 `MediaQuery.displayCornerRadiiOf(context)` 的使用。

简单说，Android 设备真实屏幕圆角可以参与页面返回转场的裁剪效果，让转场更贴合物理设备边界。

如果你的应用自己覆盖了 Android 页面转场，可以显式使用这个 builder；设备圆角会由 `MediaQuery.displayCornerRadiiOf(context)` 自动参与裁剪，拿不到设备圆角时走 fallback：

```dart
MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(
          fallbackColor: Colors.black,
        ),
      },
    ),
  ),
  home: const HomePage(),
)
```

## AGP 9 和 built-in Kotlin

在 AGP 9 版本之前，Android 应用和插件需要手动将 Kotlin Gradle 插件 (KGP) 添加到构建文件，系统才能识别并编译 Kotlin 代码。

从 AGP 9.0 开始，Android 构建系统已原生支持 Kotlin，由于构建系统已经处理了 Kotlin，**手动添加单独的 KGP 会导致冲突并造成构建失败**，所以这个情况需要 Flutter 进行适配，所以：

- 如果你是开发 Flutter App，这里需要更新 Android 构建文件，删除单独的 Kotlin Gradle 插件 (KGP)
- 如果是插件的话，就需要对 Gradle 进行修改兼容

> 设置   AGP 9.0 的插件必须  `pubspec.yaml`  里将 Flutter 的最低版本限制设置为 3.44 。

这个问题主要还是 AGP 和 Kotlin 的破坏性更新带来的，以前 Flutter Android 项目里常见的是：

```groovy
plugins {
    id "com.android.application"
    id "kotlin-android"
}
```

或者老写法：

```groovy
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
```

而到了 AGP 9.0，Android Gradle Plugin 自己内置了 Kotlin 支持同时默认启用，也就是说普通 Android app/library 模块里不再需要显式 apply `org.jetbrains.kotlin.android` 或 `kotlin-android` 插件。

> Google 官方说法是：AGP 9.0 introduces built-in Kotlin support and enables it by default，不再需要 apply `org.jetbrains.kotlin.android` / `kotlin-android` 来编译 Kotlin 源码。

所以迁移后的 Flutter Android app 大致会从：

```groovy
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }
}
```

变成：

```groovy
plugins {
    id "com.android.application"
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    // ...
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
```

> 也就是 **删掉 `kotlin-android`，删掉 `android { kotlinOptions {} }`，改用顶层 `kotlin { compilerOptions {} }`。** 

Flutter 3.44 也不是强行让所有项目马上完全迁到 AGP 9 + built-in Kotlin，所以也加了两个 flag 做缓冲：

```
android.newDsl=false
android.builtInKotlin=false
```

> 而为了支持还没迁移的项目，Flutter 默认使用 legacy Kotlin Gradle Plugin 和 old AGP DSL types，Flutter migrator 会自动把这两个 flag 加到 `gradle.properties`。

## ABI 

Flutter 之前的做法是帮你按构建类型动态塞 ABI 过滤器，现在改成「在 `defaultConfig` 里统一塞一次」，这个变化也是遇到 AGP 9 的合并规则后。

以前一般是 `flutter build apk --target-platform android-arm64` 或者 `flutter build apk --split-per-abi` ，而现在为了 AGP9 ， Flutter 把 ABI filter 放到了 `defaultConfig` ：

```groovy
android {
    defaultConfig {
        ndk {
            abiFilters ...
        }
    }
}
```

所以，如果在特定构建类型或产品风格中使用自定义 `abiFilters` ，现在需要在构建或运行应用时传递 `-Pdisable-abi-filtering=true` 标志。



# iOS

## Swift PM 默认

这个我们其实也已经在 [《Flutter 3.44 发布前夕，官方宣布 SwiftPM 将完全取代 CocoaPods》](https://juejin.cn/post/7635969457790648383) 聊过，从  Flutter 3.44 开始，**Swift Package Manager 成为是 iOS/macOS 的默认包管理器 ，同时这个包含了大量SwiftPM 的修复**，例如：

> *CocoaPods 与 SwiftPM 冲突提示、SwiftPM 最低平台版本诊断、SwiftPM 下载太慢的慢提示、SwiftPM cache 集中化处理、SwiftPM Add-to-App 工具等*。  

现在 Flutter CLI 会自动处理迁移。构建或运行应用时，CLI 会将 Xcode 项目更新为使用 SwiftPM，如果依赖暂时不支持 SwiftPM，Flutter 会 fallback 到 CocoaPods，同时发出警告。

如果在 add-to-app 场景下，新的 `flutter build swift-package`  也会支持对应命令，如果 SwiftPM 是在无法兼容，页可以通过在 `pubspec.yaml` 文件中设置 `--enable-swift-package-manager: false` 来回退禁用。



> 图片资源缺失：881580a2-1a33-40bd-b4d3-0e81464ee33a.png





## UIScene

由于 Apple 已经强制了 UIScene 要求， **所以这里是想提醒你，如果还么迁移适配，那就要抓紧了**。

## predictive text

这是 iOS 上一个新的实验性支持，`TextField`、`CupertinoTextField`、`EditableText` 和 `TextInputConfiguration` 增加了 `enableInlinePrediction` 相关配置。

也就是  iOS 文本输入接入 inline prediction 提供了 opt-in 配置，并把配置从高层 `TextField` 传到底层 text input channel，Material 风格输入框可以这样显式打开：

```dart
TextField(
  controller: titleController,
  enableInlinePrediction: true,
  textInputAction: TextInputAction.done,
  decoration: const InputDecoration(
    labelText: '标题',
  ),
)
```

Cupertino 风格输入框也有同名参数：

```dart
CupertinoTextField(
  controller: titleController,
  enableInlinePrediction: true,
  placeholder: '标题',
  textInputAction: TextInputAction.done,
)
```

> 默认功能是关闭的，它目前只对 iOS 17 及以上的 inline predictive text 有用。

# Web

这个版本主要都是一个简单优化，例如：

- 支持  `prefers-reduced-motion` ，也就是现在浏览器/系统说要“少动画”，Flutter Web 能够适配，然后 Web 还把这个偏好同步到 Flutter engine 的 accessibility 配置里，让 Flutter 侧的 `disableAnimations` / `reduceMotion` 生效。

- 另外现在 Flutter Web 表单错误能更快被屏幕阅读器读到，也算是无障碍的一个优化。

- 支持  iOS 26 Safari autofill ，Flutter Web 在 iOS 26 Safari 上不会再频繁销毁/重建用于 autofill 的隐藏 DOM form，而是尽量复用同一个 form，这样 Safari/密码管理器才能识别“这是一组连续的登录/注册表单字段”，从而正常自动填充。

# Desktop

Flutter 这次不装了，直接宣布 **Canonical 将成为 Flutter Desktop 的主要维护者和战略合作伙伴**  ，这是什么意思？就是 Desktop 完全交给 Canonical 维护和主导了。



![](https://img.cdn.guoshuyu.cn/e079feb8-abfe-4f0f-8f18-742f41930833.png)

结果这次还是失望了， **虽然新增加了功能，但是多窗口功能还是只仅在 master 可以用**，依然没有合并到 stable 。

![](https://img.cdn.guoshuyu.cn/20260520/1_jge3MA91e1nbNjncqu9dtA-d5d241.gif)

这次多窗口新增加了  Tooltips 、Popups 和  Dialogs 的落地，同时 Linux 现在也支持了 content-sized 视图，可以根据窗口内容动态调整窗口大小。

另外这次更新里 showRawDialog / showDialog 可以走原生 dialog window ，如果通过 `flutter config --enable-windowing` 启用了 windowing，那么 dialog 会通过 windowing system 显示在自己的窗口中，而不是当前窗口内的 modal overlay，平台不支持时，会 fallback 到普通 dialog route。

其他还有 `_window.dart` 有了多类 controller 和 widget：

- `RegularWindowController` / `RegularWindow`
- `DialogWindowController` / `DialogWindow`
- `TooltipWindowController` / `TooltipWindow`
- `PopupWindowController` / `PopupWindow`
- `SatelliteWindowController` / `SatelliteWindow`

# 嵌入式

这里官方主要介绍了一些案件，例如丰田的车机， RAV4 在 2025 年是全球最畅销的车型 ，而 **2026 款 RAV4 正在使用 Flutter 构建车机系统** ：

![](https://img.cdn.guoshuyu.cn/image-20260521060513898.png)

LG 的基于 Flutter 的 WebOS SDK 页要更新发布了，webOS SDK 将包含对 Firebase、视频播放器、游戏手柄等插件的支持。

![](https://img.cdn.guoshuyu.cn/f0684822-d4b4-4d74-8221-0111b8b0452d.png)

# Impeller

3.44 版本包含多个 Vulkan 优化，包括「更好的缓存内存管理」，还有在丢帧情况下更高效的 GPU/CPU 同步，**使用 SDF 可以实现更清晰的圆圈** ：

![](https://img.cdn.guoshuyu.cn/e5b41281-da83-43f4-8fed-6d346a3f5c61.png)

> 这个圈我看了是真头晕。

同时也改进了 Impeller 处理透视矩阵的方式，修正了阴影和透视投影变换的渲染行为，支持  *Get Uniform by Name API*  ，可以在着色器中按名称绑定 uniform 变量：

```
    void setUp(ui.FragmentShader shader) {
      shader.getUniformFloat('foobar').set(1.234);
    }
```

# Framework

## 解耦

3.44 开始，**Material 和 Cupertino  就是独立的  `material_ui` 和 `cupertino_ui`  了，而下个版本发布的时候，框架内当前兼容的样式框就会被完全弃用兼容**，整整 60 多万行代码的 PR ：

![](https://img.cdn.guoshuyu.cn/image-20260507131705665.png)

## 弹框

这次新增的 `CupertinoMenuAnchor` / `CupertinoMenuItem`  就是基于 widgets 层的 `RawMenuAnchor` 实现， Flutter 正在把“菜单锚点、打开/关闭、overlay、焦点和手势”这类共性逻辑放在更低层，让 Material 和 Cupertino 分别负责自己的视觉和交互风格。



![](https://img.cdn.guoshuyu.cn/20260520/1_7uz0MAnNLfnKOmRGweNcgg-f8f8da.gif)

3.44 新增 `CupertinoMenuAnchor` 和 `CupertinoMenuItem`，它们提供 Cupertino 风格的菜单 popup，支持 controller、open/close 回调、动画状态、overlay padding、长按打开、swipe 选择、focus/hover、destructive action 等能力：

```dart
CupertinoMenuAnchor(
  menuChildren: <Widget>[
    CupertinoMenuItem(
      leading: const Icon(CupertinoIcons.doc_on_doc),
      subtitle: const Text('创建一个副本'),
      trailing: const Icon(CupertinoIcons.right_chevron),
      onPressed: duplicateItem,
      child: const Text('复制'),
    ),
    const CupertinoMenuDivider(),
    CupertinoMenuItem(
      leading: const Icon(CupertinoIcons.delete),
      isDestructiveAction: true,
      onPressed: deleteItem,
      child: const Text('删除'),
    ),
  ],
  builder: (BuildContext context, MenuController controller, Widget? child) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        controller.isOpen ? controller.close() : controller.open();
      },
      child: const Icon(CupertinoIcons.ellipsis_circle),
    );
  },
)
```

如果你不需要自己控制打开/关闭，也可以传 `child` 并配合外部 `MenuController`：

```dart
final MenuController controller = MenuController();

CupertinoMenuAnchor(
  controller: controller,
  menuChildren: <Widget>[
    CupertinoMenuItem(
      onPressed: () => controller.close(),
      child: const Text('完成'),
    ),
  ],
  child: CupertinoButton(
    onPressed: controller.open,
    child: const Text('更多'),
  ),
)
```

> 这里和 `PlatformMenuBar` 不一样：`CupertinoMenuAnchor` 是 Flutter 自己绘制的 Cupertino-style popup menu，适合控件附近的上下文菜单；`PlatformMenuBar` 则是交给宿主平台渲染的顶层菜单栏。

Material 的 `MenuAnchor`  也新增了 Material 3 动画， `SubmenuButton` 上的新 `hoverOpenDelay` 参数可以控制子菜单的交互，默认动画处于禁用状态，可以通过 animated 设置为 true 来启用 ：

![](https://img.cdn.guoshuyu.cn/20260520/1_VdQhRElD22jiVdNmjLllhw-8f961f.gif)

另外， `CupertinoSheetRoute`  里面的可滚动内容现在可以和拖拽动画无缝协作，对于需要自定义拖拽区域的开发者来说，新的 `scrollableBuilder` 支持将托管的 `ScrollController` 传递给 body 的可滚动区域：



![](https://img.cdn.guoshuyu.cn/20260520/1_BbFM0AsTzm5tN8ZSbC-6Aw-5281bb.gif)



## CarouselView 支持 infinite

CarouselView 这也也进行了大调整，最重要就是支持了 infinite：

![](https://img.cdn.guoshuyu.cn/20260520/1_lx61h88hYLIWaeSYuIQ14g-3dc55d.gif)

Material `CarouselView` 新增 `infinite` 参数，开启后 Carousel 可以在两个方向连续循环滚动。

这个能力覆盖普通 `CarouselView`、`CarouselView.weighted` 和 lazy builder 场景，当 `infinite` 为 true 时，carousel 支持无限循环，双向连续滚动：

```dart
CarouselView(
  itemExtent: 280,
  infinite: true,
  children: List<Widget>.generate(6, (int index) {
    return Card.filled(
      child: Center(child: Text('推荐内容 $index')),
    );
  }),
)
```

## SelectableRegion

不得不说，这个玩意一直都没完全支持好，这次 3.44 主要解决了两个问题：

- Web 布局约束保留 ： 之前  `SelectableRegion` 在网页上渲染时可能会导致对应子元素意外缩小，现在它会将所有布局约束原封不动地传递给子元素，从而确保一致的尺寸行为

- 多行复制精度，现在 `SelectableRegion` 中的文本选择更加精确，当用户选择并复制跨越多行的文本时，复制的输出中会正确保留换行符，不会丢失换行符

## Superellipse

另外，Superellipse 现在覆盖更多 iOS 风格形状：

- `CupertinoFocusHalo.withRoundedSuperellipse` 用 `RoundedSuperellipseBorder` 绘制更接近 iOS 的平滑圆角 focus halo
- `ShapedInputBorder` 可一配合 `RoundedSuperellipseBorder` 做 iOS-style shape
- Cupertino 的 dialog、context menu、sheet、list section、picker、segmented control 等路径已经基本采用 `ClipRSuperellipse` / `RoundedSuperellipseBorder`。

```dart
ClipRSuperellipse(
  borderRadius: BorderRadius.circular(28),
  child: Image.asset(
    'assets/cover.jpg',
    width: 160,
    height: 160,
    fit: BoxFit.cover,
  ),
)
```

## ExpansionTile

最后， `ExpansionTileController`  页做了优化，作为 Material 组件 `ExpansionTile` 底层基础的 `Expansible` 组件， `ExpansibleController` 和 `ExpansibleController` 都新增了切换方法，Material 的列表图块 `RadioListTile` 、 `CheckboxListTile` 和 `SwitchListTile`  也支持了 `WidgetStatesController` 。

```dart
import 'package:flutter/material.dart';

class ExpansibleControllerDemo extends StatefulWidget {
  const ExpansibleControllerDemo({super.key});

  @override
  State<ExpansibleControllerDemo> createState() =>
      _ExpansibleControllerDemoState();
}

class _ExpansibleControllerDemoState extends State<ExpansibleControllerDemo> {
  final ExpansibleController _controller = ExpansibleController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExpansibleController.toggle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Expansible(
          controller: _controller,
          headerBuilder: (context, animation) {
            return Card(
              child: ListTile(
                title: const Text('自定义 Expansible Header'),
                subtitle: const Text('底层展开组件，不限制 Material 样式'),
                trailing: RotationTransition(
                  turns: Tween<double>(
                    begin: 0,
                    end: 0.5,
                  ).animate(animation),
                  child: const Icon(Icons.expand_more),
                ),
                onTap: () {
                  _controller.toggle();
                },
              ),
            );
          },
          bodyBuilder: (context, animation) {
            return SizeTransition(
              sizeFactor: animation,
              child: const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '这里是展开内容。'
                    'Expansible 更适合做完全自定义 UI，'
                    '而 ExpansionTile 是 Material 风格的封装。',
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _controller.toggle();
        },
        label: const Text('toggle'),
        icon: const Icon(Icons.swap_vert),
      ),
    );
  }
}
```





#  无障碍

## ProgressIndicator

`ProgressIndicator` 的 `semanticsValue` 现在支持类似 `50%` 的百分比字符串，之前 progress bar 语义检查更偏向数值区间，现在对百分比文本有了明确支持：

```dart
const LinearProgressIndicator(
  value: 0.5,
  semanticsLabel: '文件上传进度',
  semanticsValue: '50%',
)
```

同样适用于 `CircularProgressIndicator`：

```dart
const CircularProgressIndicator(
  value: 0.75,
  semanticsLabel: '同步进度',
  semanticsValue: '75%',
)
```

## Slider

`Slider` 修复了语义节点尺寸问题， `_RenderSlider.assembleSemanticsNode` 会把语义 rect 设置为以 thumb center 为中心、大小为 `kMinInteractiveDimension` 的区域：

```dart
Slider(
  value: volume,
  min: 0,
  max: 100,
  divisions: 20,
  label: '${volume.round()}',
  onChanged: (double value) {
    setState(() => volume = value);
  },
  semanticFormatterCallback: (double value) {
    return '音量 ${value.round()}%';
  },
)
```

其他还有：

- `PopupMenuButton` 和 `DropdownButton` 的 expanded state 语义更新修复，避免展开状态没有正确同步
- `PinnedHeaderSliver` 修复语义焦点捕获问题
- 不可见 semantics 节点从语义树中移除时的崩溃被修复
- 自动播放视频预览：通知用户是否已禁用视频预览的自动播放
- 优先使用不闪烁光标：允许 App 为那些觉得闪烁光标分散注意力或难以跟踪的用户提供稳定的、不闪烁的文本指示器
- 自动播放动画图像 ：检测用户何时选择暂停自动播放 GIF 或其他动画内容



# 最后

可以看出来，这个版本更新了很多，最核心就是样式库已经完成初步解耦落地，后续样式跟进和液态玻璃效果就能快很多了，同时这也是一个充满 AI Coidng 场景的更新，当然最可惜的还是桌面的依然不合并到 Stable ，虽然我已经用了一段时间了。

> 貌似关注过我的，基本已经提前看到大半的 3.44 更新了吧？

那么，更新吧骚年，是时候勇敢的吃螃蟹了。