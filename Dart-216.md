
> 原文链接：https://medium.com/dartlang/dart-2-16-improved-tooling-and-platform-handling-dd87abd6bad1


今天 Dart  2.16 跟随 Flutter 2.10 正式发布，它不包含新的语言特性，但有**一堆错误修复（包括对安全漏洞的修复），改进了 Dart 包在特定平台的支持，以及 [pub.dev](https://pub.dev/) 的全新搜索体验**。

## Dart 2.16

今天与 Flutter 2.10 一起发布的 Dart 2.16 SDK 继续从传统的 Dart CLI 工具（`dartfmt`、`dartdoc` 等）过渡到新的组合 `dart` 开发工具，新的弃用工具是 `dartdoc`( use `dart doc`) 和 `dartanalyzer` (use `dart analyze`)。 

> 在 Dart 2.17 中我们计划完全删除 `dartdoc`、`dartanalyzer` 和 `pub` 命令（在 Dart 2.15 中已弃用；使用 `dart pub` 或者 `flutter pub`）。有关详细信息请参阅[#46100](https://github.com/dart-lang/sdk/issues/46100)。

2.16 版本还包括了一个安全漏洞的修复和两个小的重大更改：

-  `dart:io`  中的 `HttpClient` API  允许为 `authorization`、`www-authenticate`、`cookie` 和 `cookie2` 设置可选标头，Dart 2.16 之前的 SDK 中重定向逻辑的实现存在一个漏洞，当跨域重定向发生时，这些 headers（可能包含敏感信息）会被传递，在 Dart 2.16 中这些 headers 被删除了。

-   `dart:io` 中的 `Directory.rename` API 已更改了在 Windows 上的行为：它不再删除与目标名称匹配的现有目录（[#47653](https://github.com/dart-lang/sdk/issues/47653)）。

-   `Platform.packageRoot` 和 `Isolate.packageRoot` API—— 从 Dart 1.x 中遗留下来并且在 Dart 2.x 中不起作用，所以已被删除（issue # [47769](https://github.com/dart-lang/sdk/issues/47769)）。

> 要查找有关 Dart 2.16 更改的更多详细信息，请参阅更改日志: https://github.com/dart-lang/sdk/blob/master/CHANGELOG.md#2160。

## pub.dev 包新的平台声明支持

Dart 本身是为了可移植而设计的，我们努力使代码能够在更多的平台上运行，但是有时你可能会在 pub.dev 上创建和共享专为一个或几个平台设计的包，你可能有一个依赖于仅在特定操作系统上可用的 API 的包，或者一个使用 `dart:ffi` 仅在 Native 平台而非 Web 上受支持的库的包。

使用 Dart 2.16，你现在可以在包的 pubspec 中手动声明支持的平台集，例如如果你的包仅支持 Windows 和 macOS，则其 `pubspec.yaml` 文件可能如下所示：

```
name: mypackage
version: 1.0.0platforms:
  windows:
  macos:dependencies:
```

新 `platforms` 标签适用于正在开发 Dart 包的情况，如果你正在开发和共享的包含特定于主机的代码（例如 Kotlin 或 Swift）的 Flutter 插件，则 [Flutter 插件标签](https://docs.flutter.dev/development/packages-and-plugins/developing-packages#plugin-platforms) 通常会指定支持的平台。

## 新的 pub.dev 搜索 UI

响应开发人员的请求，我们为在 pub.dev 上搜索包提供了更好的支持，今天发布的更改的主要目标是帮助开发者更好地识别和搜索受支持的平台集，以下是新搜索体验的视图：

![](http://img.cdn.guoshuyu.cn/20220328_Dart-216/image1)

新的搜索 UI 在左侧有一个搜索过滤器侧边栏，你可以使用它来限制你的包搜索：

-   **Platforms**：选择一个或多个平台以，将搜索结果缩小到仅支持所有所选平台的软件包。
-   **SDKs**：选择 Dart 或 Flutter 以将结果限制为分别支持 Dart SDK 或 Flutter SDK 的包。
-   **Advanced**：附加搜索选项，例如过滤到 Flutter favorite包。

## 空安全更新

自从我们上次讨论 null 安全以来已经发布了几个版本，这是一年前在 [Dart 2.12](https://medium.com/dartlang/announcing-dart-2-12-499a6e689c87) 中推出的主要语言添加。

我们对 Dart 生态系统迁移包以支持 null 安全的速度感到惊讶：

> 截至今天，前 250 个包中的 100% 支持以及前 1000 个包中的 96% 支持 ！感谢所有为这一伟大成就做出贡献的包作者。

我们还看到应用程序迁移到健全的空安全已经方面取得了良好进展，根据我们的分析，Flutter 工具中 71% 的所有运行会话现在都具有完全可靠的 null 安全性，如果你是应用开发人员，但仍未迁移到 null 安全，那么现在是个好时机。

## 结束评论

我们希望新的 pub.dev 搜索 UI 会对你有用，也欢迎你提供[任何反馈](https://github.com/dart-lang/pub-dev/issues/)，请继续关注计划于 2022 年第二季度发布的下一个 Dart SDK 版本，我们正在开发一些[令人兴奋的语言功能](https://github.com/dart-lang/language/projects/1)，希望在今年晚些时候发布。

> https://github.com/dart-lang/language/projects/1