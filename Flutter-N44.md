# Flutter 小技巧之面试题里有意思的异步问题

很久没更新小技巧系列了，本次简单介绍一下 Flutter 面试里我认为比较有意思的异步基础知识点。

首先我们简单看一段代码，如下代码所示，是一个循环定时器任务，这段代码里：

- `testFunc` 循环每 1 秒执行一次 `asyncWork` 
- `asyncWork`  每次执行前判断  `list` 里是否还有数据
- 如果存在数据，就做一些前置处理（延迟两秒模拟 do something）
- 之后通过 removeAt 提取数据，完成输出

```dart
 List<String> list = ["1"];

  testFunc() {
    Timer.periodic(const Duration(seconds: 1), asyncWork);
  }

  asyncWork(t) async {
    if (list.isNotEmpty) {
      ///do something
      await Future.delayed(const Duration(seconds: 2));

      var item = list.removeAt(0);

      if (kDebugMode) {
        print("############ complete $item ############");
      }
    }
  }
```

那么上面这段代码有没有问题呢？实际上述代码在运行后是会出现报错，报错原因是 `list` 数组里是 empty ，但是我们调用了 `removeAt(0)` 。

![](http://img.cdn.guoshuyu.cn/20240618_N44/image1.png)

这就很“奇怪”了，我们不是在 `asyncWork` 一开始就通过 `isNotEmpty` 判断了吗？为什么还会出现  `removeAt(0)`  的时候数组是空的情况？

> 这里就不得不说我们模拟 “do something” 时 `await`  的延迟 2s 的操作。

实际上对于 `Timer.periodic` 而言，他是固定以**「大概」** 1 秒的速度循环执行 `asyncWork` ，但是对于 `asyncWork` 而言，它需要等待 “do something”  操作，这里是固定两秒的时间，**所以其实在 `await` 的时候，  `asyncWork`  其实已经被从后面进入多次**。

所以虽然我们前面有  `isNotEmpty`  的判断，但是因为 “do something” 时 `await`  的延迟 2s 的操作，以至于最后执行  `removeAt(0)`  的时候，数组里的内容已经在一次被 remove 了，第二和第三次触发执行  removeAt 的时候，其实 list 里面已经没有数据了，所以会抛出异常。

为什么聊这个问题，**因为这里是模拟问题执行，固定 2s 的情况很容易被推断出来问题，但是如果是在逻辑复杂的情况下，不同机器处理速度不一致的常见下，这种异步问题的定位就会变得“很模糊”**。

> 所以到这里你明白了为什么虽然前面做了  `isNotEmpty` 判断，但是后面 `removeAt` 还是会出现 `RangeError(index)` 的原因了吧。

那么有人可能会疑惑，Dart 里面不是单线程轮询的任务机制吗？为什么这里 `await`  之后，还会多次同时进入呢？

其实这里恰恰是因为 Dart 是单线程轮询的机制，所以才会出现这样多次进入的场景，所以我们要搞清楚， `Timer` 的定时机制实现， **`Timer`  的底层定时能力是依赖于 isolate 实现的定时执行**。

我们知道 Flutter 里 Dart 是单线程轮询的机制，但是我们可以通过 isolate 去开启全新的隔离线程去实现真异步任务，而对于 Dart VM 来说，它是通过 isolate 的 port 机制实现的定时任务，所以在定时任务这里，他是通过 isolate 实现，然后通过 SendPort 去触发  callback 执行。

![](http://img.cdn.guoshuyu.cn/20240618_N44/image2.png)

而在执行 callback 的时候，如下代码所示，`callback(timer) ` 就是一次普通调用，它并没有 `await` 等操作，所以对于前面的  `Timer.periodic` 来说，它不管  `asyncWork` 是不是 `Future` ，也不管这个 `async` 是否已经执行完成，它只负责执行一下，然后进入下一次，所以最终造就了一开始代码里的逻辑判断出现问题：多次进入等待。

![](http://img.cdn.guoshuyu.cn/20240618_N44/image3.png)

另外，还记得前面我们说过， **`Timer.periodic`  是固定以「大概」1 秒的速度循环执行 `asyncWork`**   ，为什么这里用「大概」？因为  **`Timer.periodic`  不是一个“可靠”的定时操作**，在官方的注释里明确说明了：

> The exact timing depends on the underlying timer implementation. No more than `n` callbacks will be made in `duration * n` time, but the time between two consecutive callbacks can be shorter and longer than `duration`.

![](http://img.cdn.guoshuyu.cn/20240618_N44/image4.png)

其实原因也很简单，因为对于 VM 而言，定时器的操作是一个「批量处理」，不同运行环境下机器的处理能力存在差异，所以他最多保证 “duration * n 时间内最多会进行 n 次回调” ，但是无法保证 “两次连续回调之间的时间”，对于最终执行效果而言，这个时间可以短于或长于 duration 。

![](http://img.cdn.guoshuyu.cn/20240618_N44/image5.png)

所以你将 `Timer` 的周期设置为 50 毫秒，但执行间隔时间可能会落在 40 -500 毫秒范围内，是的，有时候多个定时器可能会导致某次执行间隔“夸张”到 500 毫秒。

所以对于需要更精准的执行定时的任务，你可以选择使用：

- Ticker ，因为对于 Flutter 来说，Flutter 会通过 ticker 每秒 60 帧的速度去渲染屏幕，所以可以将 `Ticker` 看作是一个**特殊的周期计时器**
- 使用更短的 `Timer.periodic` ，例如开启一个全新的 isolate ，然后使用  `microseconds:500` 启动 Timer，之后在回调里自己判断 tickRate 去触发定时回调，[reliable_periodic_timer](https://github.com/1nf0rmatix/reliable_interval_timer) 就是采用这种方式实现。

**最后借助 Timer 这个例子，我们再聊聊 Flutter 里的异步模型**，前面也提到说， Dart 默认都说单线程轮询机制，那他会是怎么样的一个轮询机制？

简单不严谨，但是好理解的解释：**Dart 运行时 ，Root isolate 就是一个循环的线程，在执行 Dart 代码遇到 `await Future`（`async`）的时候，Dart 事件循环可以先完成其他 Dart 代码，然后再 Future 完成后在返回执行原本下一步的代码**。

> 这就是上面 `asyncWork` 多次进入，每次进入都判断了 `list.isNotEmpty` ，  因为 do something 需要  `await`  2 秒，所以都跳过了  `list.removeAt` ，导致最终执行 `removeAt` 的时候出现 `RangeError(index)` 的原因。

```dart
  asyncWork(t) async {
    if (list.isNotEmpty) {
      ///do something
      await Future.delayed(const Duration(seconds: 2));

      var item = list.removeAt(0);

      if (kDebugMode) {
        print("############ complete $item ############");
      }
    }
  }
```

但是在 Dart 里，**异步等待也是分类型，简单可以分为微任务(MicroTask) 和 事件(Event) 两种**。

在 Dart 事件循环里首先会考虑微任务队列，如果微任务队列为空，才会转到事件队列中，这个机制主要是确保 MicroTask 异步操作优先于用户输入等事件。

![](http://img.cdn.guoshuyu.cn/20240618_N44/image6.png)

对于 Flutter 而言：

- MicroTask 是用来做一些及时和重要的内部操作，当时要保证 MicroTask 队列尽可能短
- Event 是用于处理一些常规异步或者用户交互事件，例如当用户与应用交互时，可以创建一个点击事件并将其添加到 Event 队列中，Dart 事件循环去执行与点击事件相关的事件处理代码。

对于 MicroTask ，我们可让应用更精确地执行一些任务，而不会让 Event 队列负担过重导致 UI 不响应，例如用 MicroTask 来异步解析 json 数据到实体 object ，可以更好防止操作 UI 卡顿。

> 👆在不考虑新开 isolate 操作的情况下。 

那么关于微任务和事件队列的关系，我们举个例子，将前面的  `asyncWork` 修改为如下代码所示，可以看到这里执行了一个 `Future` 和 一个   ` Future.microtask` ，那么它的输出结果会是什么样？

```dart
asyncWork(t) async {
    print('starts');
    Future(() => print('This is a new Future'));
    Future.microtask(() => print('This is a micro task'));
    print('ends');
}
```

如下图所示，可以看到 `microtask` 虽然是后加入的，但是因为它是 MicroTask ，所以它会优选于 `Future` 执行，虽然  `Future` 和 `Future.microtask`  是先后被执行，但是它们的 callback 触发存在优先级关系。

![](http://img.cdn.guoshuyu.cn/20240618_N44/image7.png)

那么，再来一个升级本的，如下代码所示，可以看到现在是 Future 和 MicroTask 的各种嵌套异步：

```dart
asyncWork(t) async {
    print('main #1 of 2');
    scheduleMicrotask(() => print('microtask #1 of 3'));

    Future.delayed(Duration(seconds: 1), () => print('future #1 (delayed)'));

    Future(() => print('future #2 of 4'))
        .then((_) => print('future #2a'))
        .then((_) {
      print('future #2b');
      scheduleMicrotask(() => print('microtask #0 (from future #2b)'));
    }).then((_) => print('future #2c'));

    scheduleMicrotask(() => print('microtask #2 of 3'));

    Future(() => print('future #3 of 4'))
        .then((_) => Future(() => print('future #3a (a  future)')))
        .then((_) => print('future #3b'));

    Future(() => print('future #4 of 4'));
    scheduleMicrotask(() => print('microtask #3 of 3'));
    print('main #2 of 2');
  }
```

从结果我们可以看到：

- main 的两个打印最先被执行，没毛病
- 之后第一层的 3 个 Microtask 最先被执行，因为它们有 VIP
- 然后第一层的 Future 开始被执行，首先被执行的是  `future #2 of 4` 和它后面打印，因为它们算一个 Future，这里有个有趣的地方，那就是穿插了一个 `microtask #0 (from future #2b)'`
- 可以看到，` microtask #0 (from future #2b)'`  其实是在 Future 被执行完之后，才被执行，因为至少要保证一个 Future 完整执行
- 之后剩下执行完第一层 Future 之后， delayed 被触发，然后执行完二层 Future，这里第二次 Future 因为它是 return 了一个  Future ，所以它会最后执行。

> ⚠️ 这里的 delayed 何时被执行并不是一定的，也可能是最后被执行。

![](http://img.cdn.guoshuyu.cn/20240618_N44/image8.png)

通过上面的例子，可以看到整个异步以 MicroTask 为核心的运作，但是也需要保证 Future 执行完成之后再执行。

> 另外，而对于一些老版本的 Dart ，可能会存在需要第一层 Future 执行完成之后，才会触发 `microtask #0 (from future #2b)` 的情况。

最后，这里有个有趣的知识点，那就是其实 `Future()` 的 `factory` 其实是通过 `Timer` 实现 ，包括 `Future.delayed`  也是一样，是不是很有趣，又回到了 Timer ，所以当有很多 `Future.delayed`   或者  `Future()`  构建的 callback 执行，其实本质上还是回归到了`Timer`  的「批量回调」。

![](http://img.cdn.guoshuyu.cn/20240618_N44/image9.png)

**所以用 Timer 为切入点去理解异步是一个很有意思的事情，特别一开始前面的例子，能很好的帮助去理解异步和 Timer 的工作机制，同时后面的 MicroTask 也可以细化大家对于 Flutter 里异步任务的认知，用来作为面试题也是一个很好的选择**。