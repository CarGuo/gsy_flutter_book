# Flutter 面试八股之深入理解  Dart 异步实现机制

为什么写这一篇内容？因为在此之前关于 [《面试题里有意思的异步问题》](https://juejin.cn/post/7381673971836715018) 的文章收到一些「问题」，但是解释这些「问题」并不是“三言两语”就可以说清，所以干脆做一篇完整解析，相信本篇可以帮助你从头到尾理清 Flutter 里 Dart 的完整异步实现。

> ⚠️本篇内容可能较多，基于 Flutter 3.22+ 和 Dart 3.4+，请耐心品尝。

# isolate

如果要解释 Dart 里的异步机制，就不得不提到 isolate(隔离)，基本要全面理解异步，都需要从 isolate 作为入口，因为 Dart VM 中的 **Dart 代码都是运行在某个  isolate  里面**，比如我们入口的  `main`  就是运行在 root isolate 里，也是我们 Dart 代码的「主线程」，**Dart 代码在一个 isolate 里是「单线程模型」，主要通过事件循环来实现“异步”操作**，从开发者使用角度上看，**每个 isolate  在一定程度上代表了“一个线程”，当然严格意义上这样的说法是不对的**。

## isolate & isolate group



![](http://img.cdn.guoshuyu.cn/20240621_N45/image1.png)

说到 isolate ，就不得不「祭出」这张老图，我们先简单解释下一些基础概念：

- 每个 isolate 会有自己的全局状态（Global State） 、工作线程（mutator thread）和辅助线程（helper thread）
- isolate 会被分组到 isolate group 里，一个 group 会共享一个 GC managed Heap ，用于存储由 isolate 分配的对象，这里有一个需要注意的是， **同一个 group 内会共享堆**。

作为实现并发的对象， isolate 如它名字所言，一个 isolate 就是一个”隔离“，他们之间独立工作，相互隔离，不能共享内存，isolate 之间只能通过 port 来进行交互。

而 isolates group 是在 Dart 2.15 被引入的， **isolate groups 中的 isolate 共享正在运行的程序中的各种”内部数据结构“** 。

> Dart 2.15 之后，在 isolate groups 中启动额外的 isolate 比之前可以快近 100 倍，因为现在不需要初始化程序结构，并且产生新的 isolate 所需要的内存减少了 10 -100 倍。
>
> Isolate.spawn  可以在同一个 group 内生成一个 isolate， Isolate.spawnUri 启动一个新 group 。

**虽然 isolate groups 还是不允许 isolate 之间共享可变对象，但 group 内可以通过共享堆来实现，所以能够解锁更多功能**，比如可以将对象从一个 isolate 传递到另一 isolate，不再是只能传递基础类型。

所以关于 isolate 和 isolate group 自身的「基础概念设定」应该理解了，接下来聊聊 isolate 和外部的关系。

# isolate & Thread

我们知道 isolate 是可以实现线程操作，但是本质上还是要依赖系统的线程来执行，**那OS(系统)线程和 isolate 之间的关系是 1:1 吗？答案是否定的**。

简单解释下，OS 线程和 isolate 之间可以确定的关系：

- 一个 OS 线程一次只能进入一个 isolate，如果想进入另一个 isolate，必须离开当前 isolate
- 一个 OS 线程每次只和一个 isolate  的 mutator 关联，mutator 线程就是 isolate 执行 Dart 代码的线程

系统线程和  isolate 之间不确定的关系：

- 同一个 OS 线程可以先进入一个 isolate ，执行 Dart 代码，然后离开这个 isolate 并进入另一个 isolate
- 不同的 OS 线程可以进入同一个 isolate 并在其中执行 Dart 代码，但不能同时执行

**所以 isolate 和 OS 线程肯定不是严格的 1:1 对应，其实在 VM 在内部是用线程池（ThreadPool）来管理 OS 线程，而对于 isolate 来说，它不是一个长期「死循环」在线程上的存在，并且 Dart VM 的代码是围绕 `ThreadPool::Task` 逻辑来实现而不是 OS 线程**。

> 例如 isolate 内部处理事件循环时，会将 MessageHandlerTask 发送到线程池，然后看此时线程池会选择空闲线程或生成新线程来执行该 Task，线程处理完任务后，可能会接着处理另一个 isolate 的任务，具体看实际情况而定。 

所以总结下，**所有 Dart 代码都在 isolate 内运行，而不是直接在线程内运行，只是每个 isolate 可以在线程池里去处理事件循环的线程** 。

如下图所示，isolate 和线程之间的关系大概如下图所示，虽然这样并不是很严谨，但是也比较好理解。

![](http://img.cdn.guoshuyu.cn/20240621_N45/image2.png)

![](http://img.cdn.guoshuyu.cn/20240621_N45/image3.png)

## isolate & Runner

说到 Runner 大家可能也不会模式，比如 Xcode 上项目默认名称就是 Runner ，**而 Runner 其实是 Flutter 上的抽象概念，它和 isolate 其实并没有直接关系**。

对于 Flutter Engine 而言，它可以往 Runner 里面提交 Task ，所以 Runner 也被叫做 TaskRunner，例如 Flutter 里就有四个 Task Runner（UI、GPU、IO、Platform）。

![](http://img.cdn.guoshuyu.cn/20240621_N45/image4.png)

对于 Flutter Engine 来说，它并不在乎 Task Runner 具体跑在哪个线程，但是对于  Task Runner 来说，一个 Task Runner 最好始终保持在同一线程运行，例如 Android 和 iOS 会为 UI，GPU，IO 分别创建一个线程，其中 UI Task Runner 就是 Dart root isolate，也就是 Dart 主线程。

> 至于 Platform Runner 其实就是设备平台自己的主线程，移动平台上它属于共享线程，所有 Engine 实例会共享同一个Platform Runner和线程。

所以在 Flutter 里：

- Engine 里的 Task 被提交到 Runner ，由 Runner 所在的线程去执行
- isolate 是 Dart VM 管理执行，Flutter Engine  不会直接访问

尽管 Runner 和 isolate 没有直接关系，但是它们直接还是存在“交互”的情况，例如 root isolate  和 UI Runner 。

首先我们知道 UI Runner 就是 Flutter 在 Dart 的 UI 线程，而 root isolate 又是 Dart 代码的主线程，所以很明显， **UI Runner 和 root isolate 是在一个线程下**。

至于这个结论，如果你想深究，可以在 Flutter Engine 启动流程看到答案，如下图所示是创建 root isolate 的全过程，其中核心的点在于： `SetMessageHandlingTaskRunner` ：

![](http://img.cdn.guoshuyu.cn/20240621_N45/image5.jpg)

> Engine::Run -> RuntimeController::LaunchRootIsolate -> DartIsolate::CreateRunningRootIsolate  ->  DartIsolate::CreateRootIsolate ->  DartIsolate::CreateDartIsolateGroup -> DartIsolate::InitializeIsolate-> DartIsolate::Initialize -> SetMessageHandlingTaskRunner 

对于 root isolate ，它会在被关联到 UITaskRunner ，而 `SetMessageHandlingTaskRunner` 正是让 root isolate 运行到 UITaskRunner  线程上的关键，如下代码所示，对于 root isolate ，它的任务队列现在是在  UITaskRunner 上运行。

![](http://img.cdn.guoshuyu.cn/20240621_N45/image6.png)

**所以 root isolate 和其他 isolate 不同，它没有线程池，所以它的消息队列一直运行在 UI Runner 上**， 从这个角度看，Flutter 里 isolate 和 Runner 开始有了“联系”。

而 Dart isolate 和 Flutter Runner 是通过任务调度机制相互协作，例如：

- root isolate 通过 Dart 调用 C++ ， 把 UI 渲染相关的 Task 提交到 UI Runner 执行
- UI Runner  也可以通过事件通知调用 isolate

所以 isolate 和 Runner 的关系就很明朗了：**isolate 是 Dart VM 的概念，Runner 是 Flutter 的概念，它们理论上互不想干，而 root isolate 会和 UI Runner 共用一个 Thread** 。

最后不得不提 background isolate ，在 Flutter 3.7 之前， 只有 root isolate 可以和 Platform Channels 通信，原因通过上面我们也大概理解了，而从Flutter 3.7 开始， **Flutter 会通过新增的 BinaryMessenger 来实现非 root isolate 也可以和 Platform Channels 直接通信**，当然这里 background isolate 需要和 root isolate 通过 Token 建立关联。

![](http://img.cdn.guoshuyu.cn/20240621_N45/image7.png)

# 事件队列

前面我们简单介绍过，isolate 是在线程池里去处理事件循环的线程，对于 isolate 来说，它不是一个长期「死循环」在线程上的存在，而是由事件来驱动处理，而有事件自然就有事件队列。



![](http://img.cdn.guoshuyu.cn/20240618_N44/image6.png)

但是在 Dart 里，**我们可以把队列类型简单可以分为微任务(MicroTask) 和 事件(Event) 两种**。

在 Dart 的队列循环里，首先会考虑处理 MicroTask 队列，如果微任务队列为空，才会转到 Event 队列中，这个机制主要是可以确保 MicroTask 异步操作优先于用户输入等事件。

对于 Flutter 而言：

- MicroTask 是用来做一些及时和重要的操作，同事我们要保证 MicroTask 队列尽可能短，这个后面说到
- Event 是用于处理一些常规异步或者用户交互事件，例如当用户与应用交互时，可以创建一个点击事件并将其添加到 Event 队列中

> MicroTask 和 Event 最大的区别在于，**MicroTask 是需要异步执行但又不由外部事件触发的最小任务模块**，后面通过和 Future 的对比，也能体现这一点。

那么关于微任务和事件队列的关系，我们举个例子，如下代码所示，可以看到这里执行了一个 `Future` 和 一个   ` Future.microtask` 代表一个 Event 和一个 MicroTask，那么它的输出结果会是什么样？

```dart
test() async {
    print('starts');
    Future(() => print('This is a new Future'));
    Future.microtask(() => print('This is a micro task'));
    print('ends');
}
```

如下图所示，可以看到 MicroTask 虽然是后加入的，但是因为它是 MicroTask，所以它会优选于 Event 执行，**虽然  `Future` 和 `Future.microtask`  是先后被执行，但是它们的 callback 触发存在优先级关系**。

![](http://img.cdn.guoshuyu.cn/20240618_N44/image7.png)

**那么 MicroTask  优先级更高，为什么我们不更多使用它，而是需要尽量保证它的队列尽可能短？** 这其中和 Flutter 对于 MicroTask 的「定制」有关系。

**Flutter 运行时会把 Dart VM 的 `_scheduleMicrotask`  关联到 Engine** ，所以 Dart 的 MicroTask 处理会占用 Engine 的资源。

![](http://img.cdn.guoshuyu.cn/20240621_N45/image8.png)

其次，Flutter Engine 里对于 MicroTask 的「执行实际」也很巧妙，其中：

- 1、`BeginFrame`  的时候会触发 MicroTask 执行
- 2、root isolate 创建时对应会有一个 UIDartState  ，它会向 MessageLoop 中添加一个 TaskObserver ，用于在 MessageLoop 过程来消费 Microtask  

![](http://img.cdn.guoshuyu.cn/20240621_N45/image9.png)

所以可以看到，**如果 Microtask 的队列太长，那么很容易就引起掉帧和卡顿等问题，因为会影响帧绘制和 UI Runner Task 的处理周期**。

所以到这里，我们大致理解了 isolate 里面事件队列和微任务的实现，接下来进一步来聊聊它的使用。

![](http://img.cdn.guoshuyu.cn/20240621_N45/image10.png)

# Timer

为什么聊完事件队列是聊 `Timer`  ？因为除了 `Timer.periodic` 等操作之外，其实  ` Future`   和 `Future.delayed` 事实上其实都是属于 Timer 操作，可以说整个 Dart 开发里的异步行为很多基本都离不开 `Timer` 。

![](http://img.cdn.guoshuyu.cn/20240621_N45/image11.png)

当然，` Future`  和 `Future.delayed`  在底层实现逻辑上还是存在区别，因为它们一个不需要延时，一个需要延时，对这两种情况，Dart 的处理逻辑也是不一样:

- 对于  ` Future`   这样「不需要定时」（`_ZERO_EVENT`）的异步事件，它其实是在 Timer 内部就消化了，并不会有其他跨线程操作。
- 对于  `Future.delayed`  这种存在「定时」（`_TIMEOUT_EVNET`）的事件，它就需要依赖 EventHandler 去触发 epoll 操作。

整个流程如下图所示，简单描述下：

- 1、Timer 创建的时候，会创建一个 SendPort 和 ReceivePort

- 2、如果是 `_ZERO_EVENT` 的操作，它在被插入之后，在 `_enqueue` 时会直接用  SendPort 触发 callback 执行
- 3、如果是 `_TIMEOUT_EVNET` 操作，它在被插入之后，在  `_enqueue` 时需要通过  EventHandler ，把 SendPort 发送到 `dart:io` 的 C++ Engine 层面，通过 epoll 机制实现定时器触发 SendPort 回调。

![01](http://img.cdn.guoshuyu.cn/20240621_N45/image12.jpg)

这里有个注意的地方，那就是 Dart 3.4 开始 `eventhandler_android.cc` 被移除了，复用了 Linux 的`eventhandler_linux.cc` ，通过 linux 的 epoll 和 timerfd 来实现定时器任务。

![](http://img.cdn.guoshuyu.cn/20240621_N45/image13.png) 

> epoll(eventpoll) 是 linux 特有的一个 I/O 事件通知机制，在 Linux 内核下以一个文件系统模块的形式实现， timerfd 这是一种定时器 fd，使用 `timerfd_create` 创建，到时间点触发可读事件。

另外如果对于定时器的启动感兴趣，可以通过 Flutter 的 `DartVM::DartVM` 入口调用  `BootstrapDartIo`  作为入口，从 `EventHandler::Start` 开始了解。

> （这也是挺多人问到的问题）~

![](http://img.cdn.guoshuyu.cn/20240621_N45/image14.jpg)

另外还有个值得关注的地方，那么就是上面整个 Timer 的流程代码图里，其中 `_runnerTimers`  执行时，**Timer callback 每一个 for 循环都要调用  `_runPendingImmediateCallback` 去执行 Microtask 队列**，所以到这里你发现什么没有？

![](http://img.cdn.guoshuyu.cn/20240621_N45/image15.png)

**为什么 `scheduleMicrotask`  会比 `Future` 优先级更高，从上面 Timer 的实现也可以看出来** ，因为每个 callback 都要执行下  Microtask ，同时这也是为什么  **`Timer.periodic`  不是一个“可靠”的定时操作的愿意之一**，因为对于 VM 而言，定时器的操作是一个「批量处理」，同时还要兼顾 Microtask 存在的可能性，所以在官方的注释里明确说明了：

> The exact timing depends on the underlying timer implementation. No more than `n` callbacks will be made in `duration * n` time, but the time between two consecutive callbacks can be shorter and longer than `duration`.

![](http://img.cdn.guoshuyu.cn/20240618_N44/image4.png)

> 我总觉得，以 Timer 收尾是理解 Dart 异步最好的场景。

# 最后

最后，如果你看完了本篇，相信你应该已经搞清楚了这些问题：

- isoate 、Thread、Runner  之间的关系
- MicroTask 和 Event 的原理与区别
- 为什么 MicroTask 会更早被执行
- Future()  和   Future.microtask() 的区别和实现
- Timer 的实现原理和逻辑

相信从现在开始，你已经是对于 Flutter 和 Dart 的异步实现有了全面的认知，相信再遇到 Flutter 相关的异步面试内容是，一定可以和面试官进行不一样的深入交流。

当然，日常开发中你可能基本不需要了解这些，因此这也是这部分内容一直以来很少也很「稀散」 的原因，对于大部分人而言，可能这些都只是面试才需要的“八股”。
