# Flutter 上的 Platform 和 UI 线程合并是怎么回事？它会带来什么？

Flutter 在 3.29 发布了一个「重大」调整：**从 [3.29 开始](https://juejin.cn/post/7470457106844827687)，Android 和 iOS 上的 Flutter 将在应用的主线程上执行 Dart 代码，并且不再有单独的 Dart UI 线程**

也许一些人对于这个概念还比较陌生，有时间可以看看以前发过的 [《深入理解 Dart 异步实现机制》](https://juejin.cn/post/7383281753145475099)  的相关内容，这里面主要涉及 isolate、 Thread、Runner 等概念。

简单说就是：

- **Dart 代码都是运行在某个 isolate 里面**，比如我们入口的 `main` 就是运行在 root isolate 里，也是我们 Dart 代码的「主线程」
- isolate 和线程之间的关系并非 1:1 ，只是执行的时候需要一个线程来完成
- **而 Runner 其实是 Flutter 上的抽象概念，它和 isolate 其实并没有直接关系**，实际上 Engine 并不在乎 Runner 具体跑在哪个线，对于 Flutter Engine 而言，它可以往 Runner 里面提交 Task ，所以 Runner 也被叫做 TaskRunner，例如 Flutter 里就有四个 Task Runner（UI、GPU、IO、Platform）

![](http://img.cdn.guoshuyu.cn/20250216_Thread/image1.png)

而在  Android 和 iOS 上，以前会为 UI，GPU，IO 分别创建一个线程，其中 UI Task Runner 就是 Dart root isolate，也就是 Dart 主线程， Platform Runner 其实就是设备平台自己的主线程。

所以，在过去 **Flutter 的 UI Runner 和 Android/iOS 平台的 Platform Runner 是处于不同线程**，其中 Dart 的  root isolate  会在被关联到 UITaskRunner 上。

所以在过去 Flutter 里会有异步 platform channels 的存在，因为 UI Runner 和 Platform Runner  分属不同线程，所以 Dart 和 Native 互相调用时需要序列化和异步消息传递。

而在 3.29 里，作为改进移动平台上 Native 和 Dart 互操作系列调整中的一部分，两个线程被合并了，说人话就是： `UI Runner  =  Platform Runner ` ：

![](http://img.cdn.guoshuyu.cn/20250216_Thread/image2.png)

是的，默认情况下现在 `merged_platform_ui_thread` 会是 `true` ，也就是 **UI Runner 现在等同于 Platform Runner  ，那么自然 Dart 的  root isolate  就关联到 Platform Runner  上**：

![](http://img.cdn.guoshuyu.cn/20250216_Thread/image3.png)

另外，过去  Dart 的  root isolate 是在 ` SetMessageHandlingTaskRunner`  的时候关联上 UI Runner 的，而现在是直接 post_directly_to_runner ：

![](http://img.cdn.guoshuyu.cn/20250216_Thread/image4.png)

那为什么可以这样简单切换？实际上就是我们前面讲过的， Engine 并不在乎 Runner 具体跑在哪个线程，对于 Flutter Engine 而言，它可以往 Runner 里面提交 Task，只要最终有执行的地方就行了。

对于 Dart 来说，在内部 VM 会使用  `dart::ThreadPool`  这样的线程池来管理系统线程，并且代码是围绕 `dart::ThreadPool::Task` 概念构建的，而不是围绕系统线程：

>  例如用于处理  isolate message 的 event loop  的默认实现，实际就是没有一个专用的事件循环线程，而是在有新消息到达时将 `dart::MessageHandlerTask`  发布到线程池。

同时，由于过去 UI  和 Platform 线程是分开的，那时的 UI Runner 都是通过独立的 `MessageLoopTaskQueues`  来处理 microtask 的，而现在线程合并后，UI Runner  变成了 Platform Runner ，自然也就没有关联的任务队列，所以需要在运行任务后需要手动刷新 microtask 。

![](http://img.cdn.guoshuyu.cn/20250216_Thread/image5.png)

> microtask 就是  isolate 事件循环队列任务的一种，具有更高优先级。

另外，基本上所有 PostTask 都变成了  RunNowOrPostTask ，主要也是通过判断 MessageLoop 的初始化情况来判断执行位置：

![](http://img.cdn.guoshuyu.cn/20250216_Thread/image6.png)

这里再结合前面我们 merged 两个线程时 platform runner 的初始化逻辑，可以看到  MessageLoop 不会是空，所以 `IsInitializedForCurrentThread` 会是 `true` ，也就是在当前线程直接运行 `task()` ：

![](http://img.cdn.guoshuyu.cn/20250216_Thread/image7.png)

另外在 iOS 上也是同样道理，直接用了当前的 MessageLoop ：

![](http://img.cdn.guoshuyu.cn/20250216_Thread/image8.png)

> 其实合并线程后，Flutter 单独的光栅线程还是在的，所以一般来说，并不用担心 Flutter 的动画会「直接」影响到 Native UI 线程造成卡顿。

那么合并线程的好处是什么？最直接的就是 iOS 可以做到支持渲染 PlatformView 而无需合并光栅线程。

另外一个情况就是文本输入，因为在此之前都是需要通过 Platform Channel 进行通信，这个异步行为造成了许多问题，例如；

> 在 iOS 上的 IME 生成快速事件序列，然后在 UI 线程处理事件并发送回平台线程之前读取文本，很多时候逻辑上是需要同步响应，但是由于 Platform Channel  的限制，最终需要通过一些额外成本来达成这个需求（不断在事件处理中抽取 CFRunLoop）。

Platform Channel  的核心在于异步，当平台的文本输入需要某些东西（选择坐标、当前文本）时，它需要接口可以立即给出答案，而通过 Platform Channel  只能是主动将所有状态推送给客户，以便在需要时能够用到。

而如果合并到一个线程上，那么 FFI 就可以同步执行平台交互，可以简单地调用 dart 代码并立即返回答案，甚至在文本输入上可以更好保留住某些平台差异的效果，而不是像现在一样只能在 Channel 抽象出统一的文本输入 API。

> 还可以减少文本和状态在内存里的多处缓存的情况。

另外还有在 Android  WebView 的拦截响应上，如 `shouldOverrideUrlLoading`  需要「直接」同步响应返回一个结果的情况变得简单。

当然，也许这个改动会带来一些负面影响，例如插件如果没适配好，可能会导致某些行为对平台线程造成 ANR 等极端情况，所以如果你希望延迟这个逻辑，可以增加以下配置：

```xml
<meta-data
    android:name="io.flutter.embedding.android.DisableMergedPlatformUIThread"
    android:value="true" />
```

这个配置会执行 `--no-enable-merged-platform-ui-thread` ，从而修改 `settings.merged_platform_ui_thread` 的标志位为 false 。

**当然，在整个 Flutter 团队的目标里，完全剔除 platform/message channels 是必然的方向，未来整个异步 channel 肯定会被彻底“消灭”** ，所以合并线程对于 Flutter 来说是大势所趋，和 RN 一样，同步调用和互操作是跨平台的趋势。

# 参考链接：

- https://github.com/flutter/flutter/pull/162944

- https://github.com/flutter/flutter/issues/150525



