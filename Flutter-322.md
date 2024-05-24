# Flutter 3.22 发布，快来看看有什么更新吧？

本次 Flutter 跟随 Google I/O 发布的版本是 3.22 ，该版本主要还是带来了 Vulkan backend 和 Wasm Native 的落地，另外还有一个重点就是 Dart macros ，但是它更多只是一个预览作用，那么就让我们来快速看看究竟有什么更新吧。

# Dart macros

Dart 宏开发终于千呼万唤始出来，虽然他不完全属于 Flutter 更新，但是感觉有必要在这里提一下，毕竟在之前的 [《Dart 宏（Macros）编程开始支持，JSON 序列化有救》](https://juejin.cn/post/7330528367354282034) 大家就对这个功能的期待很高。

![](http://img.cdn.guoshuyu.cn/20240515_Flutter-322/image1.gif)

本次发布的 [JsonCodable](https://dart.dev/go/json-codable)  作为一种用于 JSON 序列化和反序列化的全新方法预览，它可以通过在编译时内省其他代码来生成更多代码，这算是 Dart 宏编程的第一个切入点实现。

```dart
@JsonCodable()
class Vehicle {
  final String description;
  final int wheels;
  Vehicle(this.description, this.wheels);
}
void main() {
  final jsonString = Vehicle('bicycle', 2).toJson();
  print('Vehicle serialized: $jsonString');
}
```

对于宏支持，Dart 团队也考虑未来在 Dart 中添加对数据类的内置支持，这是一项长久的任务，目前正在按照阶段的落地：

- 在今天的版本中提供了单个宏的预览，`JsonCodable`  可以让开发者开始体验和熟悉 Dart 宏。
- 如果进展顺利，后续将推进 JSON 宏变得稳定。
- 最终目标将是让 Dart 开发者社区能够自定义自己的宏。

> `JsonCodable` 宏目前还不稳定，处于实验性阶段，仅适用于 Dart `3.5.0-152`或更高版本，更多可见：https://dart.dev/go/json-codable

# WebAssembly

正如前面 [《Flutter Web 的未来，Wasm Native 即将到来》](https://juejin.cn/post/7352527589246599178) 介绍过的那样，Flutter 的 Wasm Native 在 3.22 开始正式落地，现在 Wasm 现在已经可以在 stable 上使用，在测试中可以体验到显着的性能提升。



![](http://img.cdn.guoshuyu.cn/20240515_Flutter-322/image2.gif)

> 官方在 M1 MacBook 上使用 Chrome 进行内部基准测试时，其中 [Wonderous](https://flutter.gskinner.com/wonderous/) 应用的帧渲染时间平均提高了 2 倍，在最坏情况下提高了 3 倍。

Wasm Native 增强功能对于具有动画和页面过渡效果的应用提升明显，特别是保持平滑稳定的帧率，而 Wasm Native 是通过减少性能瓶颈来实现这个效果。

在 Flutter 3.22 开始，运行 `flutter build web --help` 就可以看到：

```
Experimental options
    --wasm                       Compile to WebAssembly (with fallback to JavaScript).
                                 See https://flutter.dev/wasm for more information.
    --[no-]strip-wasm            Whether to strip the resulting wasm file of static symbol names.
                                 (defaults to on)
```

通过 `flutter build web --wasm` 即可构建 Wasm Native 的 Flutter 应用，

![](http://img.cdn.guoshuyu.cn/20240515_Flutter-322/image3.png)

当然，作为第一版的 WebAssembly 支持，目前还存在一些限制，例如：

1. 需要支持（[WasmGC](https://developer.chrome.com/blog/wasmgc/)）的浏览器，Chromium 和 V8 在 Chromium 119 中发布了对 WasmGC 的 stable 支持， Firefox 在 Firefox 120 中支持 WasmGC （还有点问题），另外 Safari 尚不支持 WasmGC 。
2. 编译后的 Wasm 输出当前只支持 JavaScript 环境（例如浏览器），不支持在标准 Wasm 运行时环境（如 wasmtime 和 wasmer）中执行，详细问题可见 [#53884](https://github.com/dart-lang/sdk/issues/53884)
3. 编译为 Wasm 时仅支持 Dart 3.3 新版本的 [JavaScript Interop](https://juejin.cn/post/7335463274619273266)



# Engine

Flutter 3.22 下， Impeller 在 Android 上完成 Vulkan backend 支持和性能改进，对模糊效果和复杂路径渲染的进行了优化，以及使用 Impeller 的新实验性 API，包括有：

- [fast advanced blends](https://github.com/flutter/engine/pull/50154)
- [FragmentProgram API](https://github.com/flutter/engine/pull/49543) 自定义片段着色器的支持
- [PlatformView](https://github.com/flutter/engine/pull/50730)  支持
- [all blur styles](https://github.com/flutter/flutter/issues/134178)

## Android

在 3.19 的时候发布了 Impeller OpenGL backend 改进后，团队工作的重点切换到了 Vulkan backend 支持上，其中包括解决了 Impeller 着色器编译卡顿的问题，目前测试认为 Vulkan backend 在 Android 上的性能是可以接受的，所以在 3.22 开始加入 了 Impeller 的对 Vulkan backend 的选项支持。

> **在未来的版本中，Impeller Vulkan backend  也会成为 Android 的的默认设置**，当然，对于在不支持 Vulkan 的设备上运行时，Flutter 将自动优雅地回退到使用 OpenGL ES 和 Skia。

现在你可以通过 `flutter run --enable-impeller`  或者通过如下配置启动 Impeller Vulkan ：

```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="true" />
```

对于 Flutter 来说这是大趋势，例如今年的  [2024 Roadmap](https://juejin.cn/post/7335067315452428297) 里也提到了：**今年 Flutter Team 将计划删除 iOS 上的 Skia 的支持，从而完成 iOS 到 Impeller 的完全迁移**。

## Blur 性能改进

Blur 渲染在 3.22 已在 iOS 和 Android 的 Impeller 中被重新实现[#47576](https://github.com/flutter/engine/pull/47576)，在和 Skia 对比的[基准测试](https://flutter-flutter-perf.skia.org/e/?begin=1699468487&end=1710262311&keys=X01fc3d52ebd6fbf38afef91d82ab8d2b&requestType=0&selected=commit%3D38815%26name%3D%2Carch%3Dintel%2Cbranch%3Dmaster%2Cconfig%3Ddefault%2Cdevice_type%3DiPhone_11%2Cdevice_version%3Dnone%2Chost_type%3Dmac%2Csub_result%3Daverage_frame_rasterizer_time_millis%2Ctest%3Dbackdrop_filter_perf_ios__timeline_summary%2C&xbaroffset=38815)里将 Blur 的 CPU 和 GPU 时间使用减少了将近一半。

![](http://img.cdn.guoshuyu.cn/20240515_Flutter-322/image4.png)

> 上图显示了 iPhone 11 设备上最坏情况、在重写 Impeller 的模糊后，背景滤镜模糊的 CPU 和 GPU 成本几乎减半。

## Stencil-then-Cover

iOS 和 Android 上的 Impeller 已经转向([#51219](https://github.com/flutter/engine/pull/51219)) 基于 Stencil-then-Cover 方法的新渲染策略，如 [OpenGL Redbook](http://www.opengl-redbook.com/) 里的 “Drawing Filled, Concave Polygons Using the Stencil Buffer” ，更多可见[#123671](https://github.com/flutter/flutter/issues/123671)。

这个实现主要解决了「光栅线程花费过多时间计算 CPU 上复杂路径」，如 SVG 和[Lottie 动画](https://github.com/flutter/flutter/issues/141961)的曲面细分的问题，从 3.22 开始，对于包含复杂路径的帧，总帧时间（CPU 上的 UI 线程 + CPU 上的光栅线程 + GPU 工作）会低很多，用户会注意到 Lottie 动画和其他复杂路径渲染更加流畅，CPU 利用率变低，GPU 利用率变高等情况。

![](http://img.cdn.guoshuyu.cn/20240515_Flutter-322/image5.gif)



# Framework

本次 Framework 主要包含了一些 API 调整和优化，并没有什么大更新：

- `MaterialState ` 已移出 Material 并被重命名为 `WidgetState` ，从而可以更好支持 Cupertino、基础 Flutter Framework 和包作者而避免歧义，详细可见：https://docs.flutter.dev/release/breaking-changes/material-state

  ![](http://img.cdn.guoshuyu.cn/20240515_Flutter-322/image6.png)

- [#140918](https://github.com/flutter/flutter/pull/140918) 的动态调整视图大小可以更好支持构建响应式布局和适配不同尺寸屏幕，主要增加了 `BoxConstraints.fromViewConstraints`   和调整 `ViewConfiguration`  来支持视图自行调整大小。

- [#135578](https://github.com/flutter/flutter/pull/135578) 为 Flutter 3.22 提供了更灵活的表单验证方法，允许开发人员创建更强大的用户输入处理。

- 减少了 2D 图形 API 中对类型转换的需求，可以简化开发工作流程并提高性能，对于游戏和复杂动画来说比较重要。

- Flavor-conditional asset 绑定，使用  [flavors](https://docs.flutter.dev/deployment/flavors) 功能的开发人员，现在可以配置仅在构建特定 flavors 时捆绑的资产，更多可见：https://docs.flutter.dev/deployment/flavors#conditionally-bundling-assets-based-on-flavor ：

  ```
  flutter:
    assets:
      - assets/common/
      - path: assets/free/
        flavors:
          - free
      - path: assets/premium/
        flavors:
          - premium
  ```

- 使用 Dart 包转换 assets，开发者可以配置 Dart 包在构建时自动转换资源，更多可见：https://docs.flutter.dev/ui/assets/asset-transformation：

  ```
  flutter:
    assets:
      - path: assets/logo.svg
        transformers:
          - package: vector_graphics_compiler
          
  import 'package:vector_graphics/vector_graphics.dart';
  
  const Widget logo = VectorGraphic(
    loader: AssetBytesLoader('assets/logo.svg'),
  );   
  ```

# Android

## Deep linking

在 3.19 中， DevTools 中引入了 Deep linking 验证器工具，支持检查 Android 应用的 Web 配置，而 3.22 版本里添加了一组新功能来帮助验证 Android 清单文件中的设置。

![](http://img.cdn.guoshuyu.cn/20240515_Flutter-322/image7.png)

## 预测返回手势

3.22 增加了对 Android 预测返回手势的更多支持，用户可以在返回手势期间查看之前的路线，甚至是之前的应用。

![](http://img.cdn.guoshuyu.cn/20240515_Flutter-322/image8.gif)

```dart
return MaterialApp(
  theme: ThemeData(
    brightness: Brightness.light,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        // Use PredictiveBackPageTransitionsBuilder to get the predictive back route transition!
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
  ),
  home: const MyApp(),
);
```

> 更多可见：https://github.com/flutter/flutter/issues/132504#issuecomment-2025776552

## 环境版本要求

3.22 开始 Flutter 工具强制执行有关支持的 Gradle、Android Gradle 插件 (AGP)、Java 和 Kotlin 版本的策略，目前该工具仅提供警告，支持的版本范围如下：

- Gradle — 完全支持 7.0.2 到当前版本，否则发出警告
- AGP — 完全支持 7.0.0 到当前版本，否则发出警告
- Java — 完全支持 Java 11 到当前版本，否则发出警告
- Kotlin — 完全支持 1.5.0 到当前版本，否则发出警告

而在下一个主要版本中，这些警告会变成错误，可以使用 `--android-skip-build-dependency-validation` 标志覆盖。

## 支持 Gradle Kotlin DSL

Flutter 现在支持 Gradle Kotlin DSL，这种支持可以带来更好的代码编辑体验，包括自动完成、快速访问文档、源代码导航和上下文感知重构。

更多可见：https://github.com/flutter/flutter/pull/140744

## PlatformView 改进

由于 Android 14 本身系统 API 的错误，使用旧版本 Flutter 构建的应用可能会无法正常渲染，在之前的 [《2024 Flutter 一季度热门 issue》](https://juejin.cn/post/7366149991159808010#heading-1) 里介绍过相关问题，大概就是：

> **PlatformView 在内存修剪时，因为会停止从 Android 获取绘制信息，从而导致底层视图虽然存在并且可以交互，但是平台视图会出现透明的情况**，

Flutter 3.22 修复了这个问题，并提高了 Android 应用中这些 native 组件的整体性能，并且此更新还包括 behind-the-scenes，让 Android 上的 PlatformView 整体更加可靠。

## 终止对 KitKat 的支持

Flutter 支持的最低 Android 版本现在是 Lollipop (API 21)，从 Flutter 3.22 稳定版开始，Flutter 将不再在运行 Android KitKat (API 19) 的设备上运行。



# iOS

## PlatformView  性能

iOS 上的 PlatformView 性能一直是许多 Flutter 开发人员的痛点，当使用 PlatformView 时，这在滚动列表中问题尤其明显， 3.22  的更新直接解决了这些问题，特别是在嵌入多个广告等场景进行了重大改进，在[基准测试中](https://github.com/flutter/flutter/pull/144745)：

- **减少 GPU 使用量：** GPU 使用量减少了 50%，从而降低了功耗并带来更流畅的用户体验。
- **改进的帧渲染：**平均帧渲染时间减少了 1.66 毫秒 (33%)。
- **最小化卡顿：**最坏情况下的帧渲染时间减少了 3.8 毫秒 (21%)。

![](http://img.cdn.guoshuyu.cn/20240515_Flutter-322/image9.png)

![](http://img.cdn.guoshuyu.cn/20240515_Flutter-322/image10.png)

# 生态

## Vertex AI for Firebase Dart SDK 预览版

Vertex AI for Firebase 产品已发布预览版，并包含 Dart SDK，Flutter 开发者现在可以更方便使用 Gemini API ，该 SDK 与 [Firebase App Check](https://firebase.google.com/docs/app-check) 集成。

![](http://img.cdn.guoshuyu.cn/20240515_Flutter-322/image11.png)

原生的 Google [AI Dart SDK](https://ai.google.dev/gemini-api/docs/get-started/dart)仍然可使用，但建议仅用于原型设计，如果你已使用 Google AI Dart SDK 进行原型设计，并准备迁移到 Vertex AI for Firebase.

> 迁移指南：https://firebase.google.com/docs/vertex-ai/migrate-to-vertex-ai?platform=flutter

## 开发工具更新

3.22 包括了性能改进、总体改进和新功能，例如在时间线中包含 CPU 示例、高级过滤以及对导入和导出内存快照的支持。

另外 `devtools_app_shared` 添加了对将扩展连接到新的 Dart Tooling Daemon (DTD) 的支持，允许 DevTools 扩展访问由其他 DTD 客户端（例如 IDE）注册的公共方法，并允许访问最小文件系统 API 以与开发项目。

更多可见：https://docs.flutter.dev/tools/devtools/release-notes/release-notes-2.34.1

## 适用于 Flutter 的 Google 移动广告 SDK

Google Mobile Ads for Flutter 刚刚发布了版本 5.0.1 的重大更新，嗯，就这样。

# 重大变更和弃用

## ColorScheme.fromSeed

如果 `seedColor` 使用的 `ColorScheme.fromSeed` 色度值较高，则 `ColorScheme` 可能会产生缺乏活力的柔和调色板，为了确保输出颜色与 Seed 颜色的预期感觉紧密匹配，请考虑设置 `dynamicSchemeVariant` 为 `DynamicSchemeVariant.fidelity` 或 `DynamicSchemeVariant.content` ，这些选项生成的调色板与原始 Seed 颜色更加一致。

## 删除 v1 Android embedding

计划在下一个版本中完全删除 v1 Android embedding，**届时包含具有此签名的方法的插件将不再编译**（因为它引用 v1 android embedding中的类型）。



# 最后

总的来说，这个版本没有什么重大更新，如果要说比较大的变化，应该就是 Android 可以体验到比较好的 Impller   渲染，另外 Wasm Native 正式落地也算是一大变动，不过按照其设计理念，想要完全铺开估计路还远着，还有Dart 宏支持算一个，不过还没正式落地。

另外这次还是没有 PC 的多窗口，具体原因可见 ：https://juejin.cn/post/7366149991159808010#heading-2 。

那么，勇士们，是时候开始吃螃蟹了～。
