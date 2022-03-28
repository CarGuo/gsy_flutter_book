> 原文链接 ： https://medium.com/iecse-hashtag/flutter-for-web-in-2022-a-deep-dive-96cf1b5695a9 原文的意思是深入探索，但是个人觉得其实是简单探索。

跨平台开发已经成为过去几年的趋势之一，毫无疑问大多数时候开发人员对跨平台社区充满热情，而 Google 凭借着其 UI 框架—— Flutter 进入了这个市场。

但是将跨平台的支持也扩展到 Web 上其实并不容易，而 Flutter 的解决方案就是 *Flutter for Web*

# **简介：是什么和为什么**

*Flutter* 是一个 Google 的一个跨平台 UI 框架，旨在帮助开发人员创建更接近原生、高性能和更有吸引力的移动端应用，然而 **Flutter 的目标是为每个设备窗口创建用户界面，而不仅仅是在移动应用上**。

对于 Web 的支持，Flutter 提供了与其移动端相同的开发体验，这得益于便捷的 Dart 、Web 平台生态的强大、以及 Flutter 框架的灵活拓展， 现在开发者可以直接创建 iOS 和 Android 之外的 Web 应用。

由于对于 Web 来说，它和  iOS 和 Android 是使用同一个 Flutter 框架， Web 只是开发者项目里可支持的框架之一，所以一般情况下，**你可以将用 Dart 编写的原有 Flutter 项目直接编译成 Web 体验**。

在这里我们将分析 Flutter web（与 React、Angular 和 Vue 等 SPA 框架的对比）、桌面（与 Electron 和 Qt 对比）的当前状态，并希望在未来通过一些额外的努力实现兼容嵌入式设备等等。

# **但是..它是如何工作的？**

Flutter (Mobile) 拥有自己的渲染引擎 `Skia`，它为 Flutter SDK 提供了对屏幕上每个像素的完全控制能力，本身具备很高的精度和速度。

而 Flutter 在 Web 上通过构建 HTML 组件并将整个屏幕用作画布，从而实现完全控制每个像素。这里是使用 `HTML/CSS` 和 `Javascript` 创建的，它们都是目前主流的 Web 技术。因此 Flutter 在 Web 上可以使用 Flutter 的所有功能，例如动画和路由等，而无需额外编写任何的代码去适配。

目前 Flutter 对  Web 兼容，包括了在传统浏览器 API 之上构建 Flutter 的基础图形层，并将 Dart 编译为 `JavaScript`，而不是像移动应用中使用的 ARM 机器代码，通过结合 `DOM`、`Canvas ` 和 `WebAssembly` ，Flutter 可以在不同浏览器上提供高质量和高性能的用户体验。

# **重要的细节：优点和缺点**

**好的，那么 Flutter 是另一个试图降低 Web 市场上的 `Reacts` 和 `Angulars` 的框架吗 ？**

嗯，是的，也不是。

让我们看看 Flutter Web 带来了什么，并通过它的缺点去思考这个问题。

**优点：**

- 1. 支持 Flutter for Mobile 基本相同的控件。

- 2. 几乎所有比较知名的库，都支持在移动端和 Web 端上运行。

> 60.04% 的 pub.dev 包是 Web 兼容的。

- 3. 在三个平台开发的时间显着减少。

- 4. *定制：* Flutter 还提供了根据操作系统为 Web 开发定制版本的选项——就像它为 Android 和 iOS 所做的那样。

好的，**这是否意味着 Flutter Web 以及其 优势会成为构建跨平台应用（包括 Web 端）的理想工具** ？

不完全是，Flutter web 也有一些严重的***缺点*：**

- 1.  Flutter Web 的 SEO 能力支持不友好。
- 2.  无法修改生成的 HTML、CSS 和 JavaScript 代码。

> Flutter web 对 SEO 不友好，缺乏 SEO 也是它越来越难以用于大型商业产品的原因之一。

# **性能和渲染**

Flutter 为开发者提供了两个可选的渲染器：
- 1. HTML 渲染
- 2. Canvas Kit

*HTML* 渲染器优化的是下载大小而不是原始性能。

*Canvaskit* 优先考虑性能和像素完美的一致性，但是会影响下载大小，这会使得你的应用在首先运行速度会有点慢，同时 Canvaskit 呈现的总文件大小比原始文件大小增加了 400% 以上，但同时也突飞猛进地提高了性能。

*PS：* 默认渲染器是自动模式，它优先考虑移动浏览器的 HTML 和桌面浏览器的 CanvasKit。

如果要单独测试渲染器：

**HTML**

```
flutter run -d chrome — 网页渲染器 html
```

**Canvaskit：**

```
flutter run -d chrome — 网页渲染器 canvaskit
```


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-W2022/image1)

# 初始化和运行 Web 应用程序

**初始化 Web 的步骤：**

在 Flutter 2.0 及更高版本上创建的所有项目都内置了对 Flutter web 的支持，所以可以通过以下方式初始化和运行 Flutter Web 项目

```
flutter create app_name
flutter devices
```

devices 命令至少应该列出：

```
1 connected device:
Chrome (web) • chrome • web-javascript • Google Chrome 88.0.4324.150
```

然后在 chrome 上运行：

```
flutter run -d chrome
```

要为以前版本的 Flutter 创建添加 Web 支持，请从项目目录运行以下命令：

```
flutter create .
```

# **文件夹结构**

运行 *` flutter create . `* 命令会创建一个名为 “web” 的文件夹，并在其中填充在 Web 上运行所需的文件。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-W2022/image2)

> 顺便说一句，你不能编辑 `index.html` 或 `javascript` 文件。

# **Demo**

这是一个非常简单的待办事项列表应用，分别是运行之后在手机和 Web 上的比较效果：


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-W2022/image3)

代码：https://github.com/geekyprawins/Todo-List-App

# 结论

在当前阶段，使用 Flutter Web 来满足所有的 Web 开发需求是不大现实的，但如果你想使用它构建它 Web 应用，它还是有用且高效的：

-   支持集成渐进式 Web 应用 (PWA)。
-   实现一些内部应用，例如 dashboards。
-   在现有的 Flutter 移动应用代码下生成对应的 Web 版本，你可以使用**现有的逻辑和 UI 元素来更快地输出 Web 应用**，其中一般情况下 Web 版本不需要实现移动应用上的所有功能。

Flutter Web 允许开发者构建高性能和交互式的 Web 应用程序，但是 **它不适用于静态网页**。

> Flutter Web**非常适合带有动画和繁重 UI 元素的单页交互应用**，如果您的网站需要 SEO，请务必不要使用 Flutter Web（至少在当前状态下）。

对于具有大量密集文本的静态网页，传统的 Web 开发方法支持更快的加载时间和更容易维护。

> 总而言之 Flutter Web 是市场上所有框架的强大竞争对手之一，如上所述它有其优点和缺点，但它还没有完全达到成为标准的水平。