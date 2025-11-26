# 来了解一下，为什么你的 Flutter WebView 在 iOS 26 上有点击问题？

前段时间 [#175099](https://github.com/flutter/flutter/issues/175099) 又提出了一个  iOS 26  的问题，大概就是 `webview_flutter` 的点击事件又出现了“点不动”或“点了不触发” 的情况，源头还是 **WKWebView（WebKit）内部的手势识别器与 Flutter 在 Engine 里用于“阻止/延迟”手势的 recognizer 之间的冲突**。

针对和这个问题，去年 iOS 18.2  beta 里有出现类似情况，而那时候在 Engine 里，可以通过 [#56804](https://github.com/flutter/engine/pull/56804/files) 这个 PR，临时移除并再添加 `delayingRecognizer` 的实现来暂时绕过问题，**主要是通过刷新 WebKit 的内部状态从而临时修复**，但这个绕过在 iOS 26 上造成了另一个严重回归（overlay 的手势阻止失效、触摸穿透底下的 WebView），因此在最近被针对 iOS 26 的条件下回退（revert）了该提交。

![](https://img.cdn.guoshuyu.cn/ezgif-8d26e1b45a40b9.gif)

> 另外也是因为 Flutter 团队发现这是 Apple / WebKit 的 bug ，所以也已经同步上报请求和 Apple 协作。 

问题最开始出现在 iOS 18.2 beta 版本上，当页面上先触发了某些 Flutter widget（或者 overlay，比如 context menu / Drawer）后，**WKWebView 内的点击（链接、按钮）不再响应**（可高亮，但不会激活），需要重新加载 WebView 才恢复。

而具体原因在于，Flutter 在 iOS 的 PlatformView（例如承载 WKWebView 的视图）上实现了一套“手势拦截/延迟”机制：在需要时会把一个 `FlutterDelayingGestureRecognizer`（`delayingRecognizer` ）切到某些状态（`possible`, `ended`, `failed` 等）来告诉 UIKit 或者其他 recognizers 是否应该阻止/允许手势传递。

而 UIKit 的手势识别器有自己的状态机（`possible` → `recognized/failed` / `ended` ），不同 recognizer 相互之间会有阻塞/依赖关系：

![https://developer.apple.com/documentation/uikit/about-the-gesture-recognizer-state-machine](https://img.cdn.guoshuyu.cn/image-20251009134536282.png)

这里需要简单介绍一个背景知识：**Flutter + iOS 平台视图的手势处理机制**，在 iOS 上当你把一个原生控件（比如 WKWebView）嵌进 Flutter 时，实际上会经历以下层级：

```
[FlutterView]               ← 整个 Flutter 渲染层（Dart UI 层）
   ├─ Flutter widgets
   │     ↑
   │     │ 手势事件由 Flutter framework（Dart）处理
   │
   └─ PlatformView (e.g. WKWebView)
         ↑
         │ 手势事件由 UIKit / WebKit 内部 recognizer 处理
```

Flutter 和 UIKit 都各自有手势识别系统（GestureRecognizer），为了防止互相抢事件，Flutter engine 在 iOS 上加入了一个“**delaying gesture recognizer**”（延迟识别器）：

> 它的作用是：当 Flutter 框架检测到某个 widget 想“阻止”事件时（比如 `GestureDetector` 或 overlay 遮罩），Flutter 会让这个 `delayingRecognizer`  阻止 UIKit 里的 recognizer（例如 WKWebView 的点击识别器）响应。

这个系统在 Flutter → UIKit 手势交界处非常敏感，而问题就出现在：**WebKit（WKWebView）内部的某些 recognizer 会“缓存”或持有对  `delayingRecognizer`  的“旧状态”**，导致当 Flutter 在运行时切换 `delayingRecognizer`  状态（例如 blockGesture）时，WebKit 的部分识别器获取到了过时状态，从而无法触发正确的“激活 click”逻辑，例如：

> 它们可能只看到 `failed`/`possible` 的不一致组合，导致只高亮不执行动作。

针对这个问题，在 iOS 18.2 时，Flutter 团队进行了多种尝试，比如 toggle `enabled`、插入 dummy recognizer、异步 dispatch、重建 recognizer 实例等，最后发现**移除并重新添加同一个 `delayingRecognizer`  实例** 会触发 UIKit 重新刷新相关 recognizers 的关联，从而让 WebKit 的内部识别器看到“最新”状态并恢复点击功能：

> 在 blockGesture 的处理流程里把  `delayingRecognizer`  **移除后再添加回去**，以强制 UIKit/WebKit 刷新识别器关系，这个功能应该是在 3.29 的版本里发布了：
>
> ![](https://img.cdn.guoshuyu.cn/image-20251009135134198.png)



不过在 iOS 26 上，这个“移除再添加”的操作带来了新的严重问题：**Flutter 的手势阻塞系统在某些场景（比如 Drawer/overlay）里完全失效，触摸会穿透到下面的 WebView**，这比“点不动”更糟，因为会造成错点与功能错乱。

![](https://img.cdn.guoshuyu.cn/ezgif-8068b034bbc37f.gif)

所以，Flutter 在针对 **iOS 26（`@available(iOS 26.0, \*)`）上不再执行“移除再添加 `delayingRecognizer`  ” 的绕过逻辑**，但回退会让之前通过绕过解决的“WebView 点不动”问题在 iOS 26 上再次出现。

> 很明显这是一个 iOS 18.2 时 WKWebView 自身就存在的 bug，并且因为系统升级修改，WebKit 内部 recognizer 缓存行为在新版 iOS 上变化，所以如果要完成修复问题，还是需要和 Apple 一起修复处理。

![](https://img.cdn.guoshuyu.cn/image-20251009143217349.png)

所以问题主要出现的场景在于：“**必须在 WebView 上出现过 overlay 或类似触摸阻止的 widget” 才会触发 Bug** ，比如：

- 打开了一个半透明的 ModalBarrier
- 弹出了一个 Drawer
- 显示了一个半透明的 PopupMenu
- 使用了 `showDialog()`
- 甚至某些动画（Hero ）在内部也会临时创建 overlay 层

这些操作的里根本的诱饵就是：“要阻止触摸传递到底层 platform view” ，于是 engine 调用 `delaying_recognizer.blockGesture(true)`；，WKWebView 的内部 recognizer 因此暂停触发，然后 overlay 消失后，engine 再执行 `blockGesture(false)` ，但是 UIKit 没有恢复 WKWebView recognizer 的响应，从而导致问题。

> 而在 iOS18.2 可以通过 remove/add 的方式来重置刷新状态，但是在 iOS 26 上 Recognizer 重新添加后，看起来系统会重新建立默认的依赖关系，也就是当 Flutter 把 delaying recognizer 移除再添加时，UIKit 不仅刷新了它的依赖， 还重置了某些全局 recognizer 的 `delaysTouchesBegan` / `requiresFailureOf` 配置，这些配置正是 Flutter engine 用来防止 overlay 点击穿透的相关逻辑。

**而针对这个问题，目前社区层面的临时解决方法是通过 `pointer_interceptor ` 来规避 overlay 与 WebView 的事件竞争**，核心是在 iOS 26 上的 WebView ，只要在它上方有视图并点击就会导致它停止接受点击，而在此之前 WebView  一直可以正常工作，所以使用 PointerInterceptor 可以防止在与 WebView 上方的视图交互后中断 WebView，例如：

```dart
  // to know anytime if we are on top of navigation stack
  bool get _isTopOfNavigationStack => ModalRoute.of(context)?.isCurrent ?? false;

  // Wrapper for the webview
  Widget buildWebviewWithIOSWorkaround(BuildContext context) {
    return Stack(
      children: [
        buildWebView(context),
        if (Platform.isIOS)
          Positioned.fill(
            child: PointerInterceptor(
              intercepting: !_isTopOfNavigationStack, // the webview is not on top -> inhib click
              debug: false,
              child: const SizedBox.expand()
            ),
          )
      ],
    );
  }
```

另外，在和 Apple 进行问题推动修复的同时，Flutter 也在需求一些外部解决思路，例如通过全新的 `HitTest` 来规避问题：

![](https://img.cdn.guoshuyu.cn/image-20251009142503493.png)

根据   [#176597](https://github.com/flutter/flutter/pull/176597)  ，主要基于假设大多数用例平台视图只有一个重叠，如果触摸位置在 Flutter  Widget 和平台视图之间的“重叠”范围内，Flutter 会阻止平台视图上的所有 UIGestureRecognizer，具体为：

- 定义了一个新的拦截策略枚举值：`FlutterPlatformViewGestureRecognizersBlockingPolicyHitTestByOverlay`（ “通过 overlay 层的 hitTest 来阻止手势”）
- 在 platform view 的 touch / hitTest 逻辑里加入判断：如果某点落在 overlay 区域，就让 `hitTest:` 返回拦截自己（`self`），而不是默认走到底层 WebView，也就是说 **在 Flutter 层“用 hitTest”来屏蔽底层点击**
- 在 `blockGesture` 方法里，对于这种 overlay-hitTest 类型的策略，PR 把原来 `blockGesture` 的逻辑改为 “no-op”（什么都不做），因为在这个策略下，“拦截”是在 hitTest 层做了，不需要再在 delaying recognizer 层去干预
- 在 controller 更新 overlay 层（`bringLayersIntoView:`）时，把 overlay 视图引用记录下来，并赋给内部的 intercepting view（`interceptor.overlays = overlays;`）这样拦截逻辑有 overlay 区域信息可用

总的来说，**改动提供了一种 “hitTest 层面的 overlay 拦截” 策略，不依赖 delaying recognizer 的状态切换，以避免手势状态切换带来的复杂性**：

> 但是，如果多个重叠被合并到一个触摸阻挡区域时，blocking area 将是一个包含所有重叠的区域。

![](https://img.cdn.guoshuyu.cn/image-20251009145359360.png)

不过维护人员在进行到一半的时候发现，完整解决方案也许并不难推进（*我感觉是他的一厢情愿居多*），所以决定关闭临时的 MVP 方案：

![](https://img.cdn.guoshuyu.cn/image-20251014112238045.png)![](https://img.cdn.guoshuyu.cn/image-20251014112418731.png)

**完整的解决方案，是依赖于 FFI 从 Flutter 的手势竞技场同步查询来做出决定，不过这又是属于另外一个重大改动了**。

所以目前推进流程进入到了 [#177859](https://github.com/flutter/flutter/pull/177859) ，PR 将 **不再通过“延迟（delaying）手势识别器”来阻塞 platform view 的手势**，改成在 iOS 端对触点做 **同步 hit-test（利用 FFI 从 framework 查询是否应接受/阻止该手势）**，解决了 web_view / admob 等平台视图不可点按的问题，并新增一个可选的 blocking policy（`FlutterPlatformViewGestureRecognizersBlockingPolicyHitTest`）

具体调整有：

- **从“延迟识别器（delaying recognizer）”切换到“hit test”决策**
  - 以往的方案是把识别器设置成 delaying 类型，然后用延迟决策来阻塞/接受手势，本次 PR 直接改成直接做 hit test 判断是否应阻止该手势（在触点处是否落在应该被 platform view 拦截的区域）

- **FFI 同步调用框架（framework）以避免死锁**
  - 直接让 embedder 在主线程等待 framework 的异步回应会导致主线程互相等待（deadlock），利用 FFI 在 native 层**同步调用**框架中的函数（_platformViewShouldAcceptGesture` / `platformViewShouldAcceptGesture`）来获得是否接受手势的结果，从而避免线程死锁问题

- **新增/修改 policy 与 API 辅助**
  - 通过 `FlutterPlatformViewGestureRecognizersBlockingPolicyHitTest`，逐步采纳并降低全局回归风险（也就是说不把旧策略直接替换掉，而是增加新的策略供插件或内部使用）

PR 还涉及 engine 的 UI 层（ `engine/src/.../hooks.dart`、`platform_configuration.cc` 等）以及 iOS 平台 view / embedder 相关代码， 这些改动把 hit-test 的入口函数和 FFI 绑定、以及 platform view 手势决策路径连接起来 。

所以，这会是一个涉及很多地方的底层调整，也算是一个高风险的修改，特别是 iOS 平台 view（platform view）手势处理路径（尤其 web_view、admob、任何嵌入 UIView 的插件），目前建议事是需要插件作者（特别是官方 1P 插件）切换使用新 policy。

当然，PR 还需要等等，目前除此之外，我们也可以做的规避问题还有：

- **避免在 WebView 上方显示需要拦截手势的复杂 overlay（尽量减少交互型 overlay）**，如果能避免覆盖 WebView，问题就不会触发
- **在 overlay 关闭后重载或重建 WebView（重建 controller / reload）**，不过这种造成的闪烁其实并不友好

所以目前的方向，应该是先完成 [#176597](https://github.com/flutter/flutter/pull/176597) 的 PR，之后再实现 FFI 从框架中进行查询的完整解决方案，也就是从目前来说：

- 对于 iOS 18.2 上的因为重叠控件导致  WebView 点击问题，需要 3.29 以及以上版本解决
- 对于 iOS 26 上的因为重叠控件导致  WebView 点击问题
  - 3.35.4 之前，会出现触摸穿透问题
  - 3.35.4 之后，由于 cp revert，会恢复成点击无效问题
  - 以上两个问题可以使用  `pointer_interceptor ` 来尝试规避
- 等待官方内置 HitTest 和 FFI 解决方案发布

只能说，之前发布的线程合并为 FFI 提供了支持的基础，也为这次调整的方向提供了一种全新的思路，只是这个修改需要更加谨慎。

# 参考链接

- https://github.com/flutter/flutter/pull/176597

- https://github.com/flutter/flutter/issues/175099

- https://github.com/flutter/flutter/pull/177859



