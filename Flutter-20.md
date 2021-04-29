作为系列文章的第二十篇，本篇将结合[官方的技术文档](https://github.com/flutter/flutter/wiki/Android-Platform-Views#text-input)科普 Android 上 `PlatformView` 的实现逻辑，并且解释为什么在 Android 上 `PlatformView` 的键盘总是有问题。

> 为什么 iOS 上相对稳定，文中也做了对应介绍。


## 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)

 
## 1、为什么有 PlatformView

因为 Flutter 的实现在概念上类似于 Android 上的 `WebView`，Flutter 是通过将 `Widget Tree` 转化为纹理后通过 Skia 实现控件绘制，这造就了优秀的跨平台效果的同时，也带来了不可逆的兼容问题。

### 1.1、无法集成原生平台控件

**这就像 WebView 一样，Flutter UI 不会转换为 Android 控件，而是由 Flutter Engine 使用 Skia 直接在 `SurfaceView` 上渲染出来**。

这意味着默认情况下 Flutter UI 永远不会包含 Android Native 的控件，也就是说无法在 Flutter 中集成如 `WebView` 或 `MapView` 这些常用的控件。

**所以为解决这个问题，Flutter 创建了一个叫 `AndroidView` 的控件逻辑， 开发者使用该 Widget 可以将 Android Native 组件嵌入到 Flutter UI 中**。

### 1.2、AndroidView 的实现

`AndroidView` 这个 Widget 需要和 Flutter 相结合才能完整显示：**在 Flutter 中通过将 `AndroidView` 需要渲染的内容绘制到 `VirtualDisplays` 中
，然后在 `VirtualDisplay` 对应的内存中，绘制的画面就可以通过其 `Surface` 获取得到**。
 
 > `VirtualDisplay` 类似于一个虚拟显示区域，需要结合 `DisplayManager` 一起调用，一般在副屏显示或者录屏场景下会用到。`VirtualDisplay` 会将虚拟显示区域的内容渲染在一个 `Surface` 上。
 

![](http://img.cdn.guoshuyu.cn/20200225_Flutter-20/image1)
 
如上图所示，**简单来说就是原生控件的内容被绘制到内存里，然后 Flutter Engine 通过相对应的 `textureId` 就可以获取到控件的渲染数据并显示出来**。

通过从 `VirtualDisplay` 输出中获取纹理，并将其和 Flutter 原有的 UI 渲染树混合，使得 Flutter 可以在自己的 Flutter Widget tree 中以图形方式插入 Android 原生控件。

### 1.3、 有其他可以实现的方式吗？

在 iOS 平台上就不使用类似 `VirtualDisplay` 的方法，而是**通过将 Flutter UI 分为两个透明纹理来完成组合：一个在 iOS 平台视图之下，一个在其上面**。

所以这样的好处就是：需要在“iOS平台”视图下方呈现的Flutter UI，最终会被绘制到其下方的纹理上；而需要在“平台”上方呈现的Flutter UI，最终会被绘制在其上方的纹理。**它们只需要在最后组合起来就可以了**。

通常这种方法更好，因为这意味着 Android Native View 可以直接添加到 Flutter 的 UI 层次结构中。

但是，Android 平台并不支持这种模式，因为在 iOS 上框架渲染后系统会有回调通知，例如：*当 iOS 视图向下移动 `2px` 时，我们也可以将其列表中的所有其他 Flutter 控件也向下渲染 `2px`*。

但是在 Android 上就没有任何有关的系统 API，因此无法实现同步输出的渲染。**如果强行以这种方式在 Android 上使用，最终将产生很多如   `AndroidView` 与 Flutter UI 不同步的问题**。

> 有关此替代方法的详细讨论，详见 https://flutter.dev/go/nshc 

## 2、相关问题和解决方法

尽管前面可以使用 `VirtualDisplay`  将 Android 控件嵌入到 Flutter UI 中 ，但这种 `VirtualDisplay` 的介入还有其他麻烦的问题需要处理。

### 2.1、触摸事件

**默认情况下， `PlatformViews` 是没办法接收触摸事件**。

因为 `AndroidView` 其实是被渲染在 `VirtualDisplay` 中 ，而每当用户点击看到的 `"AndroidView"` 时，其实他们就真正”点击的是正在渲染的 `Flutter`  纹理 。**用户产生的触摸事件是直接发送到 Flutter  View 中，而不是他们实际点击的 `AndroidView`**。

#### 2.1.1、解决方法

- `AndroidView` 使用 Flutter Framework 中的点击测试逻辑来检测用户的触摸是否在需要特殊处理的区域内。

> 类似可见：[《Flutter完整开发实战详解(十三、全面深入触摸和滑动原理)》](https://juejin.im/post/5cd54839f265da03b2044c32)

- 当触摸成功时会向 [Android embedding](https://github.com/flutter/flutter/blob/068fa84/packages/flutter/lib/src/rendering/platform_view.dart#L595) 发送一条消息，其中包含 touch 事件的详细信息。

- 在 [Android embedding](https://github.com/flutter/flutter/blob/068fa84/packages/flutter/lib/src/rendering/platform_view.dart#L595) 中，该事件的坐标最后会匹配到 `AndroidView` 在 `VirtualDisplay` 中的坐标，然后会创建一个 `MotionEvent` 用于 描述触摸的新控件，并将其转发到内部 `VirtualDisplay` 中真实的 `AndroidView` 中进行响应。

#### 2.1.2、局限性

- 该实现逻辑会将新的 `MotionEvent` 直接分发给 `AndroidView` ，如果这个 View 又派生了其他视图，那么就可能会出现触摸信息被发送到错误的位置。

- `MotionEvent` 的转化过程中可能会因为机制的不同，存在某些信息没办法完整转化的丢失。


### 2.2、文字输入

**通常，`AndroidView` 是无法获取到文本输入，因为 `VirtualDisplay` 所在的位置会始终被认为是 `unfocused` 的状态**。

Android 目前不提供任何 API 来动态设置或更改的焦点 `Window`，`Flutter` 中`focused` 的 `Window` 通常是实际持有“真实的” Flutter 纹理和 UI ，并且对于用户直接可见。

而 **`InputConnections`（如何在 Android 中 输入文本）在 `unfocused` 的 View 中通常是会被丢弃**。

#### 2.2.1、解决方法

- **Flutter 重写了 `checkInputConnectionProxy` 方法，这样 Android 会认为 Flutter View 是作为 `AndroidView` 和输入法编辑器（IME）的代理**，这样 Android 就可以从 Flutter View 中获取到 `InputConnections` 然后作用于 `AndroidView` 上面。

- **在 Android Q 开始 `InputMethodManager`（IMM）改为每个 `Window` 自己实例化而不是全局单例**。因此之前幼稚的“设置代理”的模式在 Q 开始不起作用。为了进一步解决这个问题，**Flutter 创建了一个 `Context` 的子类， 该子类返回的内容与 Flutter View 中的 `IMM` 相同，这样就不会需要在查询 `IMM` 时需要返回的真实的  `Window`**。这意味着当 Android 需要 `IMM` 时，`VirtualDisplay` 仍然会使用  Flutter View 的 `IMM` 作为代理。

- 当要求 `AndroidView` 提供 `InputConnection` 时，它会检查 `AndroidView` 是否确实是输入的目标。如果是，那 [`AndroidView` 中的 `InputConnection` 将被获取并返回给 Android  ](https://github.com/flutter/engine/blob/036ddbb0ee6858ae532df82a2747aa93faee4487/shell/platform/android/io/flutter/plugin/editing/TextInputPlugin.java#L206) 。

- Android 认为 Flutter View 是 `focused` 且可用的，因此 `AndroidView` 的  `InputConnection` 可以成功被获取并使用。

#### 2.2.2、 Platforview 中的 WebView 键盘输入

**在 Android N 之前的版本上 `WebView` 输入比较复杂，因为它们具有自己内部的逻辑来创建和设置输入连接，而这些输入连接并没有完全遵循 Android 的协议**。在 `flutter_webview` 插件中，还需要添加其他解决方法以便在可以在  `WebView` 启用文本输入。

- [设置一个代理 View ，该 View 与 `WebView` 在相同的线程上侦听输入连接](https://github.com/flutter/plugins/blob/27f3de3/packages/webview_flutter/android/src/main/java/io/flutter/plugins/webviewflutter/InputAwareWebView.java#L113)。如果没有此功能，`WebView` 将在内部消耗所有 `InputConnection` 的呼叫，而不会通知 Flutter View 代理。
- [在代理线程中，返回 Flutter View  以创建输入。](https://github.com/flutter/plugins/blob/27f3de3e1e6ed1c0f2cd23b0d1477ff3f0955aaa/packages/webview_flutter/android/src/main/java/io/flutter/plugins/webviewflutter/ThreadedInputConnectionProxyAdapterView.java#L67)。
- [`WebView` 失去焦点时，将输入连接重置回 Flutter 线程](https://github.com/flutter/plugins/blob/27f3de3/packages/webview_flutter/android/src/main/java/io/flutter/plugins/webviewflutter/InputAwareWebView.java#L128)。这样可以防止文本输入“卡”在 WebView 内。

#### 2.2.3、局限性

- 通常这个逻辑取决于 Android 的内部行为，并且可能会十分脆弱，比如： *[1.12 版本下针对华为等设备出现的键盘输入异常等问题](https://github.com/flutter/flutter/issues/51254)*。

- 某些文本功能仍然不可用，例如：*“复制”和“共享”对话框当前不可用*。


## 3、总结

`PlatformView` 的实现模式增加了 Flutter 的生命力和活力，但是相对的也引出了很多问题，比如 [#webview-keyboard](https://github.com/flutter/flutter/labels/p%3A%20webview-keyboard)、[#webview](https://github.com/flutter/flutter/labels/p%3A%20webview)、[#platform-views](https://github.com/flutter/flutter/labels/a%3A%20platform-views) 相关的 issue 专题高居不下，并且如 [webview_flutter](https://pub.dev/packages/webview_flutter) 插件的文档所述：

> 该插件依赖 Flutter 的新机制来嵌入 Android 和 iOS 视图。由于该机制当前处于开发人员预览中，因此该插件也应被视为开发人员预览。
> 
> `webview_flutter` 的键盘支持也尚未准备好用于生产，因为 Webview 中的键盘支持目前还处于实验性的阶段。

**所以到这里相信你应该知道，为什么 Flutter 中的 `PlatforView` 在 Android 上如此之难兼容，并且键盘输入问题会那么多坑了**。

> 自此，第二十篇终于结束了！(///▽///)

### 资源推荐

* Github ： https://github.com/CarGuo
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**
* 开源 React Native 项目：https://github.com/CarGuo/GSYGithubApp



![](http://img.cdn.guoshuyu.cn/20200225_Flutter-20/image2)
