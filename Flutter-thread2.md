# Flutter 在全新 Platform 和 UI 线程合并后，出现了什么大坑和变化？

在两个月前，我们就聊过 3.29 上[《Platform 和 UI 线程合并》](https://juejin.cn/post/7474503566154219560)的具体原因和实现方式，而事实上 Platform 和 UI 线程合并，确实为后续原生语言和 Dart 的直接同步调用打了一个良好基础，在[《Flutter Roadmap 2025》](https://juejin.cn/post/7488582788673945634) 里官方也提到了：

> 直接从 Dart 调用 Objective C 和 Swift 代码（适用于 iOS）以及 Java 和 Kotlin（适用于 Android），2025 这种同步调用方式也许可以在 Framework 和 Plugin 层面大规模引入。

没有 `MethodChannel` 确实是好事，但是凡事皆有利弊，线程合并随着也带来了它的一些负面问题，首先最直观的就是，在 Android 断点开发时，断点 Dart 代码现在会导致 ANR 弹框：

![](https://img.cdn.guoshuyu.cn/image-20250418160115679.png)

![](https://img.cdn.guoshuyu.cn/image-20250418160221190.png)

其实这可以理解，因为现在 Dart 和平台主线程绑定在一起了，断点导致的无响应而出现 ANR 很合理，如果比较介意，而目前解决的办法也很简单，就是暂时关了线程合并，你可以选择的 Debug 的 AndroidManifest 关闭线程合并：

```xml
        <meta-data
            android:name="io.flutter.embedding.android.DisableMergedPlatformUIThread"
            android:value="true" />
```

那如果说上面这只是小问题，那么下面这个可以说是比较关键的问题了。

在 [#163064](https://github.com/flutter/flutter/issues/163064) 里，因为线程合并之后，启动引擎、应用和设置 Dart 代码都运行的平台线程上，会导致第一个可交互帧的时间变长，并且还看具体场景：

![](https://img.cdn.guoshuyu.cn/image-20250418160526242.png)

特别是，当平台线程在 Android （例如 Android Activity 的布局）和 Dart 执行工作之间分配时，就可能会有更多的延迟。

这其实也是可预见的情况，在合并线程这个 feature 提出来时，就有人担忧类似问题，而解决办法也很“简单”，那就是启动的时候多加一个启动线程：

![](https://img.cdn.guoshuyu.cn/image-20250418160913845.png)

> 所以，一个新功能修复了老 Bug，但是总会带来好几个新的 Bug ，所以两 issue 生四翔，四翔生 Bug 挂。

目前 [#166918](https://github.com/flutter/flutter/pull/166918) 这个 PR 已经成功合并，该 PR 将原本的简单 bool 合并线程启用状态修改为三种线程状态，其中就有全新的 `kMergeAfterLaunch` :

![](https://img.cdn.guoshuyu.cn/image-20250418161125072.png)

在  `kMergeAfterLaunch` 模式下，Engine 会在单独的 Dart UI 线程上启动引擎，然后在引擎初始化后会将 UI 任务移至平台线程合并，从而改善应用启动延迟的问题。

> 简单说，就是启动时还是走老的 Dart UI 线程，启动完成之后再合并到一起。

在启动之前，引擎通过设置让 root isolate 关联到原本的 UI Runner ，从而实现单独的启动线程：

![](https://img.cdn.guoshuyu.cn/image-20250418163508039.png)

而在启动之后，Dart 的主线程就会移动到平台线程，虽然说是“移动线程”，但是通过上面的代码我们可以看到，实际上就是将两个任务队列 `Merge` 合并成一个，也就是原本分别在两个任务队列中排队的任务，启动成功后会被放入同一个队列中，并由同一个线程来执行。

> 我们之前就讲过，UI Runner 都是通过独立的 `MessageLoopTaskQueues`  来处理任务，而 `MessageLoopTaskQueues`  又是 Flutter Engine 内部用于管理任务队列的类，它负责创建、维护和调度任务队列。

因为 Flutter Engine 不会直接控制线程的创建和销毁，而是通过控制任务队列的调度来间接影响线程的行为，通过合并任务队列，Engine 就可以让多个线程执行的任务集中到一个线程上，从而达到合并线程的作用。

而对应的还有 `Unmerge`  操作，`Unmerge`  会将之前合并的任务队列重新分离成两个独立的队列，这样在 Engine 需要关闭或者销毁的时候，就可以将合并的线程恢复到原始状态。

![](https://img.cdn.guoshuyu.cn/image-20250418164106078.png)

另外，目前在 `kMergeAfterLaunch` 模式下，禁止生成共享相同任务运行器的引擎，因为在线程合并后，生成新的引擎可能会导致死锁：

![](https://img.cdn.guoshuyu.cn/image-20250418164136666.png)

所以可以看到，增加启动线程的核心就是用原本的 Dart UI 线程进行启动，然后启动完成把任务队列合并到平台线程，回归平台线程的逻辑。

当然，说起来简单，事实上这个修改在 Engine 涉及了 36 个文件，所以会不会改出什么新的 bug，暂时不好评价：

![](https://img.cdn.guoshuyu.cn/image-20250418164334652.png)

另外，目前 maoOS 的线程合并也已经完成，所以下个版本开始 macOS 上也是统一的平台线程支持了，有了这个，似乎在 macOS 上使用 FFI 制作自己的图形 API 也不是不可能：

![](https://img.cdn.guoshuyu.cn/image-20250418164639976.png)

最后，顺带一提，Flutter 官方正式启动了 Widget 预览的开发推进，只是从我的角度，总觉得这个没太大必要，毕竟感觉就算出来了也不会很好用：

![](https://img.cdn.guoshuyu.cn/image-20250418164910673.png)

所以，你在 Flutter 3.29 上还有遇到过什么线程合并带来的问题吗？