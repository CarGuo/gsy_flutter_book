# Flutter 新一代状态管理框架 signals ，它究竟具备什么魔法和优势

在上一篇[《Riverpod 的注解模和发展方向》](https://juejin.cn/post/7479474972849143844)里就有很多人提到 signals ，对比 riverpod 部分人更喜欢 signals 的 “简单”和“直接”，那 signals 真的简单吗？再加上前段时间 signals 和 riverpod 的性能对比风波，也让大家更加关注 signals ，那它究竟有什么「魔力」？

![](http://img.cdn.guoshuyu.cn/20250323_rs/image1.png)

# 开始

signals.dart 有多“简单”？大概就是它的状态管理可以“简单”到甚至和 Flutter 没有关系，如下代码所示：

- 通过 `signal` 创建一个信号对象
- 通过 `computed`  可以合并多个 `signal`
- 通过  `effect`  可以监听响应数据变化

```dart
import 'package:signals/signals.dart';

final name = signal("N");
final surname = signal("M");
final fullName = computed(() => name.value + "-" + surname.value);

// Logs: "Jane Doe"
effect(() => print(fullName.value));

// Updating one of its dependencies will automatically trigger
// the effect above, and will print "John Doe" to the console.
name.value = "D";
```

上述代码会先打印 `N-M`  ，然后会打印 `D-M`  ，因为在最后执行 `name.value = "D";` 时：

- `effect` 里的函数会被调用，因为它内部有  `fullName.value` ，signals 内部会自动跟踪 `fullName` 的状态变化
- `computed` 会被调用，因为 `computed` 的 `fullName.value`  在 `effect` 内被访问，所以 `name` 的数值发生改变，从而让  `computed` 需要刷新状态

是不是有点懵？这其实就是 signals 的 「魔法」，它的独特之处在于，**它是「自动状态绑定」和「自动依赖跟踪」** ：

> 和其他传统的状态管理模型不同在于，**signals 支持开发者精确地跟踪状态变化并仅更新依赖于这些变化的部分 UI** ，就像上面的代码，「自动化」的实现看起来就像是「魔法」。

但是，**事实上当你觉得某个框架是「魔法」时，那其实这个框架并不适合你使用**，毕竟当遇到「咒语」失灵时，「魔法师」就很容易成为「脆皮的废物」，所以搞清楚 signals 的「魔法」实现原理尤为重要。

# 前言

开始解析在聊 signals.dart 之前，需要快速介绍 signals 的前置概念，附带还有 Preact、Preact Signals 、SolidJS 等关键词。

首先需要说明一点，**「Signals」 是业内通用的一种状态管理模式，而  signals.dart  项目就是 Preact Signals 的一个 Dart 移植版本**，所以在最底层源码里你可以看到 Preact Signals 的核心原语，自然也就是包含了 **Signal 的细粒度、惰性求值和自动依赖追踪等能力**。

那么 Preact、 Preact Signals  又是什么，还有一开始图片提到的「类似 solidjs 状态管理」，它们和 signals.dart 有什么关系？

首先我们说过，「Signals」 是一种概念模式，它并不限制与任何语言还有款架，而在这个基础上：

- Preact 是一个轻量级的 React 替代方案
- Preact Signals 是  Preact 团队基于 Signals 概念提供的可用于 Preact 和 React 状态管理
- SolidJS 是一个围绕 Signals 模式实现的 UI 框架，它是完全基于 Signals 驱动的框架

所以在  signals.dart  的源码和资料里都能看到它们的身影，而事实上 **signals.dart 的实现就深受 Preact Signals 的影响**，比如最底层的基础代码结构上：

![](http://img.cdn.guoshuyu.cn/20250323_rs/image2.png)

而对于  Signals 而言，**它的主要优势在于更高校的颗粒度更新、自动化实现依赖跟踪、延迟计算等特点**，其中我们最需要理解的，就是自动化实现依赖跟踪的「魔法」。

# 解析

要搞清楚「魔法」，首先我们需要知道 `effect` 是如何工作，如下代码所示，可以看到先打印输出了 `N` ，然后在 `value` 被改变的时候，又输出了 `D`，那为什么在 `name.value`  改变的时候，effect 就会被调用呢？

![](http://img.cdn.guoshuyu.cn/20250323_rs/image3.png)

这就不得不提，**在 signals  里  `.value` 的 setter 和 getter 方法都是有特殊处理的**，简单来说，就是当 value 被调用时，就会触发相应的逻辑，比如：「创建出对应的 `Node` 」，其实对于 signals 来说，内部  `Node`  是一个很重要的概念，**因为它的实现基础，都是基于这个内部  `Node`  双链表来完成**。

![](http://img.cdn.guoshuyu.cn/20250323_rs/image4.png)

其实，在  `signals.dart` 中  `Node`  一直扮演着核心角色，它是自动跟踪依赖和管理状态结构的基础模块 ，比如 `Node` 类通过将 `ReadonlySignal`（数据源）连接到对应的 `Computed` 和 `Effect` 等数据「消费者」来完成依赖：

```dart
class Node {
  // 目标依赖的源。
  final ReadonlySignal _source;
  Node? _prevSource;
  Node? _nextSource;

  // 依赖源并在源改变时应被通知的目标, 是消费者
  final Listenable _target;
  Node? _prevTarget;
  Node? _nextTarget;

  // 目标上次看到的 _source 的版本号，使用版本号而不是存储源值，
  // 因为源值可能占用任意大小的内存，并且计算可能会因为惰性求值而永远持有它们，
  // 使用特殊值 -1 来标记可能未使用但可回收的节点。
  int _version;
```

## 抽象概念

先聊它的抽象概念，**本质上  `Node`  就是在 `Signal`、`Computed` 和 `Effect`  等对象里被创建，并集成到一个双向链表中**，当开始建立依赖关系时，比如在 `Computed` / `Effect`  访问 `Signal`  的值时，新的 `Node` 对象久会被创建，并添加到依赖项 (`_prevSource`/`_nextSource`)  和消费者 (`_prevTarget`/`_nextTarget`)  列表里。

也就是当你在 `Computed`/ `Effect`  调用  `.value`  的 setter 和 getter  时，依赖追踪就会自动完成，从而创建一个新的  `Node` ，而后续的更新和触发执行，都是通过这个 `Node` 链表的遍历来完成。

> 所以 `Node` 不仅仅是一个简单的数据结构，它通过将 `Signal`（数据源）连接到  `Computed` / `Effect`  消费者从而连接形成了一个图谱，其中一个节点的变化可以传播到其他节点，最终确保状态的一致更新。  

所以在 signals 里，会利用 `Node`  对象来通知存储在 `targets`  列表中的所有依赖者 ，当信号的值发生改变时，会遍历依赖者列表，并根据 ` _version`  对比结果来触发更新。  

因为比对详细数据太过费时费力，通过  `_version`  来代表数据版本，不一致版本则更新，这样更有效率：

> 当 `Signal` 的值被设置时，它的版本号会递增，当依赖的 `computed` / `effect` 运行时，它会记录其读取的每个 `Signal` 的版本，在重新评估之前可以检查记录的版本是否更改，如果没有则可以跳过重新评估，从而节省资源。

所以在这些链表遍历时，`_version`  可以在值改变时更高效地通知依赖者。

是不是觉得有些抽象？没事，我们接下来通过源码来理解。

## Effect 

首先， **`Effect` 会使用 `Node` 对象来订阅其依赖的 `Signal`，而首次  `Effect`  都会被立即运行，并在每次依赖项更改时被运行**，那么这里有两个关键流程：

- 首先 `Effect` 就自己执行一次
- 然后 `Effect` 内的 `.value` 的调用就完成了数据的跟踪绑定

那么我们看  `Effect`  首先执行的时候经历了什么，通过源码可以知道，   `Effect`   每次执行内部都会执行一个 `start` 函数，**它其中一个关键的作用就是  `evalContext = this`** ：

![](http://img.cdn.guoshuyu.cn/20250323_rs/image5.png)

**这里的  `evalContext`  其实就是  `Computed` / `Effect`  的抽象上下文**，它代表的是当前的执行环境，它是存在于 `global.dart` 里的全局变量，决定当前执行的上下文环境， `evalContext = this`  大概意思就是 ：

> Signal 现在执行到当前这个  `Effect`   了。

也就是当  `Effect`  被执行的时候，  `evalContext`   就代表了当前的这个 `Effect`  ，这就是  `Effect`   首次执行时的关键作用。

接下来就是  `Effect`  里的 `.value` 调用，让你调用 `Signal` 里 value 的 getter 时，其实内部就会对应调用 `addDependency` 给这个 `Signal` 添加依赖：

![](http://img.cdn.guoshuyu.cn/20250323_rs/image6.png)

此时这个  `Effect`   就会创建出对应的 `Node` ，这个 `Node`  的 target 消费者  `evalContext` 正是当前  `Effect`   ，可以看到，这就是自动跟踪的开始：

![](http://img.cdn.guoshuyu.cn/20250323_rs/image7.png)

因为   `Effect`    首先被执行时，全局的   `evalContext`  会指向当前    `Effect`     ，然后在    `Effect`    调用 `.value` 时，就会创建出     `Effect`     的对应 `Node` ，并添加到链表里。

> 所以自动跟踪的「魔法」，就在于 get value 里执行的依赖操作，通过读取当前执行环境  `evalContext` 来判断需要依赖的位置。

那么，当我们执行 `.value =xxx` 的时候，同理就会触发 value 的执行 setter ，可以看到，此时相关 target ( `Effect`  ) 就会被 `notify` 并最终执行 `endBatch`：

![](http://img.cdn.guoshuyu.cn/20250323_rs/image8.png)

 `notify`  的作用就是把通过  ` batchedEffect` ，把所有需要触发的 `Effect` 形成一个可访问链表，这里的头部 ` batchedEffect` 也是一个全局对象： 

![](http://img.cdn.guoshuyu.cn/20250323_rs/image9.png)

而最终通过  `endBatch` 执行批处理，执行就会触发对应的   `Effect`    的 callback，进而再次执行到我们需要让他消费的地方，也就是   `effect`    里的函数因为 value 改变被再次执行：

![](http://img.cdn.guoshuyu.cn/20250323_rs/image10.png)

这里有个叫  `needsToRecompute` 的函数，其实他就是分析数据源里面的所有 `version` 是否改变，如果有改变了，才执行  `Effect`   的 callback ：

![](http://img.cdn.guoshuyu.cn/20250323_rs/image11.png)

那么到这里，应该就可以简单理解  `Effect`   如何实现自动跟踪依赖和刷新：

- 执行时通过全局对象指定当前   `evalContext` 
- value 的 getter 和 setter 方法通过   `evalContext`  实现自动依赖跟踪
- version 版本号判断是否更新

## Computed

那么对于  `Computed` 来说也类似，不同的是 Computed 也是一个「特殊信号」，在获取它的 value 的时候同样会添加依赖，只是这里会有多一步  `internalRefresh` 操作：

![](http://img.cdn.guoshuyu.cn/20250323_rs/image12.png)

![](http://img.cdn.guoshuyu.cn/20250323_rs/image13.png)

`internalRefresh ` 其实就是一个判断是否需要更新的过程，比如用到前面的 `needsToRecompute` 会分析所有依赖项的  source version ，从而判断是否需要更新，还有 `evalContext = this` 切换到当前执行环境：

![](http://img.cdn.guoshuyu.cn/20250323_rs/image14.png)

所以可以看到，**对于  `Computed` 来说，更新数据其实不是主动的**，它是在 value 被 getter 的时候，才会执行刷新计算，也就是它其实是懒加载的。

比如，在下面  `counter`  的 value 被调用之前，每次 `counter` 变化时，其实并不会主动触发 `computed`， 而是当 `data.value`  被调用到时，有数据改变才会触发 `computed` 的的执行：

```dart
final data = computed(() {
  return counter.value + 12;
});
```

所以到这里，  `Computed`  的「魔法」实现你也了解了吧？除了自动依赖跟踪，应该也理解了为什么 signals 可以做到「颗粒度控制」和「性能优化」了吧？那接下来我们继续聊 Flutter Signals 。

# Flutter

实际上，通过前面我们可以看出， signals 的状态管理可以说和 Flutter 没有「直接」关系，那它在 Flutter 上又是如何工作的？

首先我们看下方代码，这是一个最简单的 Flutter 使用 signals 的例子，这里的核心就是 `SignalsMixin` ：

```dart
class _CounterExampleState extends State<CounterExample> with SignalsMixin {
  late final Signal<int> counter = createSignal(0);

  void _incrementCounter() {
    counter.value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Counter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

通过 `SignalsMixin` ，我们可以看到：

- 首先是  `createSignal(0)` 创建信号而不是 `signal(0);`
- 直接使用  '$counter'  直接渲染数据
- 改变 ` counter.value` ，进而让 UI 更新

是不是很简单？这里的关键点就是   `createSignal(0)` ，在  `SignalsMixin` 里调用 `createSignal `的时候，内部会执行一个 ` _watch` 操作，最终会在 `_setup` 的时候，在一个 effect 里订阅对应的 signal 的 value ：

![](http://img.cdn.guoshuyu.cn/20250323_rs/image15.png)

也就是说，**当着 `value` 被改变时，它的 `effect` 就会被执行，从而触发 `_rebuild` ，进而执行 `setState` 更新控件**。

也就是 `createSignal` 是通过 `effect` 来让 UI 更新，这就是 signals 在 Flutter 里的最基础用法，类似的还有 `createEffect` 、`createComputed` 等，**如果你需要实现自动监听和释放的话，那么在 Flutter 里最好就是使用   `SignalsMixin`  的各种 createXXX 方法**，因为这样就可以做甩手掌柜：

> 为什么这么说？如果我们直接用 `effect(() {xxx});` ，其实我们是需要手动执行 dispose ，不然比如页面销毁时， `effect` 还会继续存在并且被执行。

另外 Flutter 还可以用的就是 signals 里的 `Watch` 控件，使用  `Watch` 就可以直接使用原始 `signal` 而不需要 createXXX ：

```dart
final counter = signal(0);

Watch.builder(builder: (context) {
  return Text('$counter');
});
```

**其实  `Watch`  内部是利用了  `createComputed`  做依赖跟踪**，你在  `widget.builder` 的使用的 signal 都会被自动依赖到 `Computed` ，因为  `Watch`  内部是 `return result.value` ，所以在每次变化时，`Computed`  都会重新刷新：

```dart
  late final result = createComputed(() {
    return widget.builder(context, widget.child);
  }, debugLabel: widget.debugLabel);



  @override
  Widget build(BuildContext context) {
    return result.value;
  }
```

另外还有  `counter.watch(context)`  方法，这个方法它会判断你是否存在  `SignalsMixin`  ：

- 如果是直接监听即可
- 如果不是，就获取 Flutter 的  `BuildContext`  并将当前的 `Element` 注册为 `Signal` 的监听器

![](http://img.cdn.guoshuyu.cn/20250323_rs/image16.png)

而实际 `watch` 其实就是让  `value` 再变化时通过 `subscribe` 触发 `rebuild` ，另外这里它会使用 `signal.peek()`  来避免 value 调用时的 subscribing 监听。

![](http://img.cdn.guoshuyu.cn/20250323_rs/image17.png)

而  `peek()` 之所以不会被跟踪依赖，其实就是在返回 value 之前，先临时清空了 `evalContext`  ，也就是没有执行环境了：

![](http://img.cdn.guoshuyu.cn/20250323_rs/image18.png)

同样道理的还有  `batch` 批处理，其实也就是将全局的  `batchedEffect` 临时处理为空，并且判断 `batchDepth` 等操作：

![](http://img.cdn.guoshuyu.cn/20250323_rs/image19.png)

> 所以可以看到，其实 signals 虽然在 Flutter 还是会需要到 context ，但是依赖程度很低，并且支持程度也很多样，有通过 effect 的，也有通过 computed 的，当然最终触发 UI 变化的时候，本质还是要回归到 setState 。

举个例子，这里通过 signals 自己的  `SignalProvider` 实现将一个信号通过 `InheritedWidget` 往下共享，当然你可以也创建一个全局的 Signal ，这里展示的是：

- 因为 ` listen: false` ，所以不会主动更新
- 所以此时 `counter.value ++` 并不会触发 Flutter 本身  `InheritedWidget`  的更新，自然也就不会更新到 UI
- 但是此时 `effect `里是可以正常打印

```dart
class _CounterExampleState extends State<CounterExample> with SignalsMixin {

  void _incrementCounter() {
    final counter = SignalProvider.of<Counter>(context, listen: false)!;
    counter.value ++;
  }

  @override
  Widget build(BuildContext context) {
    final counter = SignalProvider.of<Counter>(context, listen: false)!;
    effect(() {
      /// Register to $id AsyncSignal
      print('counter id: ${counter.value}');
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Counter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

从这里你也可以看到  signals 和 Flutter 之间的一个关系，signals 是一种数据跟踪和管理模式，而如何更新 Flutter UI ，就看你的颗粒度和使用需要，最方便的肯定是直接采用前面介绍的 API 。

> 毕竟手动销毁还是挺“麻烦”的。

同时，针对 Flutter 上的支持，signals 也提供了 `SignalProvider` 用于需要实现往下共享 Signal 的场景，但是本身 Signal 就支持 context 无关定义，所以实际上不用  `SignalProvider`  也可以，毕竟 Signal 本身的颗粒度控制会比 `InheritedWidget` 更细腻。

**另外， signals  也并不强求什么写什么顶层容器，甚至也不需要 `InheritedWidget`  的支持，它单纯就是依赖自己内部驱动的概念**，不管是局部状态管理，还是全局状态管理，它都可以很灵活。

最后，signals 也提供了 DevTools 上的数据可视化结构，这其实也是现在状态管理框架的标配之一了：

![](http://img.cdn.guoshuyu.cn/20250323_rs/image20.png)

# 总结

到这里我们就可以做个简单的总结了，在 signals 里最基础就是 `Signal`、`Computed` 和 `Effect`，它们的实现逻辑可以简单总结为：

- `Computed` / `Effect`  运行时会通过全局 `evalContext` 标注当前运行环境
- `Signal` 的 value 对 getter 和 setter 有特殊处理，一般 getter 会根据 `evalContext`  自动添加依赖，而 setter 会刷新数据 `version` 并更新所有依赖  `Effect`  
- `Computed`  是一种特殊信号，它的懒加载决定了它只有在 value 被调用时才会触发刷新计算
- `peek` 和 `batched` 其实都是对全局环境变量的临时清空操作
- `version` 作为判断数据版本的主要依据

所以， 当 `Computed` / `Effect` 函数运行时， 可以做到追踪在函数中访问 value 的任何信号变化，对于每个被访问的信号，都会创建一个新的 `Node` 对象（或者重用现有的对象），从而将信号链接到当前的 `Computed`  / ` Effect` ，`Node` 会被添加到  `Computed`  / ` Effect`  的依赖项列表和信号的依赖者列表中。

这种自动订阅机制就是 signals  的关键「魔法」，通过消除手动声明依赖项的需求，简化了状态管理，甚至在 Flutter 可以一定程度”脱离“ Context 实现状态更新的实现原理。

那么，你会选择 signals.dart 吗？