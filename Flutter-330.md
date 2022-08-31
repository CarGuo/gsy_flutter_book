> 原文链接： https://medium.com/flutter/whats-new-in-flutter-3-3-893c7b9af1ff

**Flutter 3.3 正式发布啦，本次更新带来了 Flutter Web、桌面、文本性能处理等相关更新，另外，本次还为 `go_router` 、DevTools 和 VS Code 扩展引入了更多更新**。

# Framework


## Global Selection

Flutter Web 在之前的版本中，经常会有选择文本时与预期的行为不匹配的情况，因为与 Flutter  App 一样，原生 Web 是由 elements 树组成。

在传统的 Web 应用中，开发者可以通过一个拖动手势选择多个 Web 元素，但这在 Flutter Web 上无法轻松完成。

**但是从 3.3 开始，随着`SelectableArea` 的引入， `SelectableArea` Widget 的任何 Child 都可以自由启用改能力**。

![](http://img.cdn.guoshuyu.cn/20220831_Flutter-330/image1)

要利用这个强大的新特性，只需使用 `SelectionArea` 嵌套你的页面，比如路由下的 `Scaffold`，然后让 Flutter 就会完成剩下的工作。

> 要更全面地深入了解这个新功能，请访问 `SelectableArea` [API](https://api.flutter.dev/flutter/material/SelectionArea-class.html)


## 触控板输入

**Flutter 3.3 改进了对触控板输入的支持**，这不仅提供了更丰富和更流畅的控制逻辑，还减少了某些情况下的错误识别。

举个例子，在[  Flutter cookbook ](https://docs.flutter.dev/cookbook) 中[拖动 UI 元素](https://docs.flutter.dev/cookbook/effects/drag-a-widget)页面，滚动到页面底部，然后执行以下步骤：

- 1.  缩小窗口大小，使上部呈现滚动条
- 2.  悬停在上部
- 3.  使用触控板滚动
- 4.  在 Flutter 3.3 之前，在触控板上滚动会拖动项目，因为 Flutter 正在调度模拟的一般事件
- 5.  Flutter 3.3 后，在触控板上滚动会正确滚动列表，因为 Flutter 提供的是“滚动”手势，卡片无法识别，但滚动可以被识别。

有关更多信息，请参阅 [Flutter 触控板手势](https://docs.google.com/document/d/1oRvebwjpsC3KlxN1gOYnEdxtNpQDYpPtUFAkmTUe-K8/edit?resourcekey=0-pt4_T7uggSTrsq2gWeGsYQ) 设计文档，以及 GitHub 上的以下 PR：

-   PR 89944：[在框架中支持触控板手势](https://github.com/flutter/flutter/pull/89944)
-   PR 31591：[iPad 触控板手势](https://github.com/flutter/engine/pull/31591)
-   PR 34060：[“ChromeOS/Android 触控板手势”](https://github.com/flutter/engine/pull/34060)
-   PR 31594：[Win32 触控板手势](https://github.com/flutter/engine/pull/31594)
-   PR 31592：[Linux 触控板手势](https://github.com/flutter/engine/pull/31592)
-   PR 31593：[Mac 触控板手势macOS](https://github.com/flutter/engine/pull/31593)

## Scribble

感谢社区成员[fbcouch](https://github.com/fbcouch)的贡献，Flutter 现在支持在 iPadOS 上使用 Apple Pencil 进行 [Scribble](https://support.apple.com/guide/ipad/enter-text-with-scribble-ipad355ab2a7/ipados) 手写输入。

**默认情况下，此功能在 `CupertinoTextField`、`TextField` 和  `EditableText` 上启用，启用此功能，只需升级到 Flutter 3.3**。


![0_SlsnQUfdOTijdsyF.gif](http://img.cdn.guoshuyu.cn/20220831_Flutter-330/image2)


## Text input

为了改进对富文本编辑的支持，该版本引入了平台的 ` TextInputPlugin`，**以前，`TextInputClient` 只交付新的编辑状态，没有新旧之间的差异信息，而 `TextEditingDeltas` 填补了 `DeltaTextInputClient` 这个信息空白**。

通过访问这些增量，开发者可以构建一个带有样式范围的输入字段，该范围在用户键入时会扩展和收缩。

> 要了解更多信息，请查看[富文本编辑器演示](https://flutter.github.io/samples/rich_text_editor.html)。


# Material Design 3

Flutter 团队继续将更多 Material Design 3 组件迁移到 Flutter。此版本包括对`IconButton`、`Chips`以及`AppBar`.

要监控 Material Design 3 迁移的进度，请查看GitHub 上的[将 Material 3 带到 Flutter](https://github.com/flutter/flutter/issues/91605)。


## 图标按钮

![](http://img.cdn.guoshuyu.cn/20220831_Flutter-330/image3)

## Chip


![](http://img.cdn.guoshuyu.cn/20220831_Flutter-330/image4)

## Medium and large AppBar


![](http://img.cdn.guoshuyu.cn/20220831_Flutter-330/image5)


![](http://img.cdn.guoshuyu.cn/20220831_Flutter-330/image6)



# Desktop

## Windows


以前，Windows 的版本由特定于 Windows 应用的文件设置，但这个行为与其他平台设置其版本的方式不一致。

**但现在开发者可以在项目 `pubspec.yaml` 文件和构建参数中设置 Windows 桌面应用程序版本**。

> 有关设置应用程序版本的更多信息，请遵循 [docs.flutter.dev](https://docs.flutter.dev/deployment/windows#updating-the-apps-version-number)上的文档和 [迁移指南](https://docs.flutter.dev/development/platform-integration/windows/version-migration)

# Packages

## go_router

为了扩展 Flutter 的原生导航 API，团队发布了一个新版本的 `go_router` 包，它的设计使得移动端、桌面端和 Web 端的路由逻辑变得更加简单。

**`go router`包由 Flutter 团队维护，通过提供声明性的、基于 url 的 API 来简化路由**，从而更容易导航和处理深层链接。

> 最新版本 (5.0) 下应用能够使用异步代码进行重定向，并包括[迁移指南](https://docs.google.com/document/d/10l22o4ml4Ss83UyzqUC8_xYOv_QjZEi80lJDNE4q7wM/edit?usp=sharing&resourcekey=0-U-BXBQzNfkk4v241Ow-vZg)中描述的其他重大更改.有关更多信息，请查看 docs.flutter.dev 上的[导航和路由](https://docs.flutter.dev/development/ui/navigation)页面。

# VS Code 扩展增强

Flutter 的 Visual Studio Code 扩展有几个更新，包括添加依赖项的改进，**开发者现在可以使用Dart: Add Dependency**一步添加多个以逗号分隔的依赖项。


![](http://img.cdn.guoshuyu.cn/20220831_Flutter-330/image7)

# Flutter 开发者工具更新

自上一个稳定的 Flutter 版本以来，DevTools 进行了许多更新，包括对数据显示表的 UX 和性能改进，以便更快、更少地滚动大型事件列表 ( [#4175](https://github.com/flutter/devtools/pull/4175) )。

有关 Flutter 3.0 以来更新的完整列表，请在此处查看各个公告：

-   [Flutter DevTools 2.16.0 发布说明](https://docs.flutter.dev/development/tools/devtools/release-notes/release-notes-2.16.0)
-   [Flutter DevTools 2.15.0 发行说明](https://docs.flutter.dev/development/tools/devtools/release-notes/release-notes-2.15.0)
-   [Flutter DevTools 2.14.0 发布说明](https://docs.flutter.dev/development/tools/devtools/release-notes/release-notes-2.14.0)


# Performance


## 光栅缓存改进

**此版本通过消除拷贝和减少 Dart 垃圾收集 (GC) 压力来提高从资产加载图像的性能**。

以前在加载资产图像时，`ImageProvider` API 需要多次复制压缩数据，当打开 assets 并将其作为类型化数据数组公开给 Dart 时，它会被复制到 native 堆中，然后当该类型化数据数组会被它被第二次复制到内部 `ui.ImmutableBuffer`。

通过 [#32999](https://github.com/flutter/engine/pull/32999)，压缩的图像字节可以直接加载到`ui.ImmutableBuffer.fromAsset`用于解码的结构中，这种方法 [需要](https://github.com/flutter/flutter/pull/103496) 更改`ImageProviders`，这个过程也更快，因为它绕过了先前方法基于通道的加载器所需的一些额外的调度开销，**特别是在我们的微基准测试中，图像加载时间提高了近 2 倍**。


![](http://img.cdn.guoshuyu.cn/20220831_Flutter-330/image8)

> 有关更多信息和迁移指南，请参阅在 docs.flutter.dev 上[ImageProvider.loadBuffer 。](https://docs.flutter.dev/release/breaking-changes/image-provider-load-buffer)


# Stability

## iOS 指针压缩已禁用

在 2.10 稳定版本中，我们在 iOS 上启用了 Dart 的[指针压缩优化](https://medium.com/dartlang/dart-2-15-7e7a598e508a#0c15)，然而 GitHub 上的[Yeatse](https://github.com/Yeatse)[提醒我们](https://github.com/flutter/flutter/issues/105183) 优化的结果并不好。

Dart 的指针压缩通过为 Dart 的堆保留一个大的虚拟内存区域来工作，由于 iOS 上允许的总虚拟内存分配少于其他平台，因此这一大预留量减少了可供其他保留自己内存的组件使用的内存量，例如 Flutter 插件。

**虽然禁用指针压缩会增加 Dart 对象消耗的内存，但它也增加了 Flutter 应用程序的非 Dart 部分的可用内存，这总体上更可取的方向**。

Apple 提供了一项可以增加应用程序允许的最大虚拟内存分配的权利，但是此权利仅在较新的 iOS 版本上受支持，目前这并且不适用于运行 Flutter 仍支持的 iOS 版本的设备。

# API 改进

## PlatformDispatcher.onError

在以前的版本中，开发者必须手动配置自定义 `Zone` 项才能捕获应用程序的所有异常和错误，但是自定义 `Zone` 对 Dart 核心库中的一些优化是有害的，这会减慢应用程序的启动时间。

**在此版本中，开发者可以通过设置回调来捕获所有错误和异常，而不是使用自定义。** 

> 有关更多信息，请查看docs.flutter.dev 上 Flutter 页面中更新的 [PlatformDispatcher.onError](https://docs.flutter.dev/testing/errors)


## FragmentProgram changes

用 GLSL 编写并在 `shaders:` 应用文件的 Flutter 清单中列出的片段着色器，`pubspec.yaml` 现在将自动编译为引擎可以理解的正确格式，并作为 assets 与应用捆绑在一起。

通过此次更改，开发者将不再需要使用第三方工具手动编译着色器，未来应该是将 Engine 的`FragmentProgram` API 视为仅接受 Flutter 构建工具的输出，当然目前还没有这种情况，但计划在未来的版本中进行此更改，如 [FragmentProgram API 支持改进](http://flutter.dev/go/fragment-program-support)设计文档中所述。

> 有关此更改的示例，请参阅此[Flutter 着色器示例](https://github.com/zanderso/fragment_shader_example)。


## Fractional translation

以前，Flutter Engine 总是将 composited layers 与精确的像素边界对齐，因为它提高了旧款（32 位）iPhone 的渲染性能。

自从添加桌面支持以来，我们注意到这导致了可观察到的捕捉行为，因为屏幕设备像素比通常要低得多,例如，在低 DPR 屏幕上，可以看到工具提示在淡入时明显捕捉。

在确定这种像素捕捉对于新 iPhone 型号的性能不再必要后，[#103909](https://github.com/flutter/flutter/issues/103909) 从 Flutter 引擎中删除了这种像素捕捉以提高桌面保真度。

此外，我们还发现，去除这种像素捕捉可以稳定我们的一些黄金图像测试，这些测试会经常随着细微的细线渲染差异而改变。


# 对支持平台的更改

## 32 位 iOS 弃用

正如我们之前在3.0 版本里宣布的一样 ，由于使用量减少，该版本是[最后一个支持 32 位 iOS 设备和 iOS 版本 9 和 10](http://flutter.dev/go/rfc-32-bit-ios-unsupported)的版本。

此更改影响 iPhone 4S、iPhone 5、iPhone 5C 以及第 2、3d 和第 4 代 iPad 设备。

Flutter 3.3 稳定版本和所有后续稳定版本不再支持 32 位 iOS 设备以及 iOS 9 和 10 版本，这意味着基于 Flutter 3.3 及更高版本构建的应用程序将无法在这些设备上运行。

## 停用 macOS 10.11 和 10.12

在 2022 年第四季度稳定版本中，我们预计将放弃对 macOS 版本 10.11 和 10.12 的支持。

这意味着在那之后针对稳定的 Flutter SDK 构建的应用程序将不再在这些版本上运行，并且 Flutter 支持的最低 macOS 版本将增加到 10.13 High Sierra。


## Bitcode deprecation


[在即将发布的 Xcode 14 版本中，iOS 应用程序提交将不再接受](https://developer.apple.com/documentation/xcode-release-notes/xcode-14-release-notes) Bitcode ，并且启用了 bitcode 的项目将在此版本的 Xcode 中发出构建警告。鉴于此，Flutter 将在未来的稳定版本中放弃对位码的支持。

默认情况下，Flutter 应用程序没有启用 Bitcode，我们预计这不会影响许多开发人员。

但是，如果你在 Xcode 项目中手动启用了 bitcode，请在升级到 Xcode 14 后立即禁用它，可以通过打开 `ios/Runner.xcworkspace` 构建设置**Enable Bitcode**并将其设置为**No**来做到这一点，Add-to-app 开发者应该在宿主 Xcode 项目中禁用它。


![](http://img.cdn.guoshuyu.cn/20220831_Flutter-330/image9)