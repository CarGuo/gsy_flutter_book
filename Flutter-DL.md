# 聊聊 Flutter & Dart 里的内存泄漏和优化，也许没你想的那么复杂

内存泄漏一直以来都是程序员无法回避的话题，但是其实你想在 Flutter 的 Dart 层面里真的制造出「完全无法回收」内存泄漏，其实也并不是那么容易。

我们先聊点八股的，简单来说，应用会创建一个根对象，根对象会直接或间接地引用 App 创建的所有其他对象，一般可以把整个关系视为对象之间的链，如果链中的某个链接断开，那么当它不存在引用时，则会被回收：

```
root -> A -> B -> C
root -> A -> B -/- C (Signals GC to de-allocate memory of C)
```

更直观的例子可以参考 Flutter 文档提供的，可以看到 `myFunction`  里  `child` 最终会不变成“不可达”，然后被回收：

```dart
class Child{}

class Parent {
  Child? child;
}

Parent parent1 = Parent();

void myFunction() {

  Child? child = Child();

  // The `child` object was allocated in memory.
  // It's now retained from garbage collection
  // by one retaining path (root …-> myFunction -> child).

  Parent? parent2 = Parent()..child = child;
  parent1.child = child;

  // At this point the `child` object has three retaining paths:
  // root …-> myFunction -> child
  // root …-> myFunction -> parent2 -> child
  // root -> parent1 -> child

  child = null;
  parent1.child = null;
  parent2 = null;

  // At this point, the `child` instance is unreachable
  // and will eventually be garbage collected.

  …
}
```

而我们常说的内存泄漏，一般是指**不再需要的内存被程序占用无法回收时，就可能会导致内存泄漏，而Dart GC 无法阻止所有内存泄漏，因为它只能释放不再引用的对象**。

> 一般来说，当使用构造函数创建对象时，相关的内存会由 Dart VM（虚拟机）在堆中分配，Dart VM 负责在创建对象时为对象分配内存，并在不再使用对象时取消分配内存。

在 Dart 里，如果不需要的对象还存在某些引用，例如全局变量或者静态变量，那么垃圾回收器就会无法识别它们，从而导致内存泄漏，常见的场景大概有：

- 被全局/静态变量持有
- 被闭包捕获
- 对象未 dispose
- ···

**而对于这些场景里，最容易出现的泄漏大部份依赖于 `BuildContext`**  ，为什么 `BuildContext`  容易泄漏？因为很多操作都和  `BuildContext` 相关，例如： `Theme.of(context)` 、`Provider.of(context)` 、 `context.read`  、`context.pop() `等等。

**而  `BuildContext` 一旦泄漏，基本就代表着整个控件或者页面完全无法回收**，因为 `BuildContext`  是 `Element`  的抽象，而  `Element` 又作为“桥梁”管理和沟通着 `Widget`  和 `RenderObject` 。

因为 `Element`  里强引用了  `Widget`  和 `RenderObject` ，这两者的 GC 依赖于  `Element` 的 `unmount` ，甚至 `StatefulWidget`  对应的  `State` 回收，也同样依赖其   `Element`  的 `unmount` ：

![](http://img.cdn.guoshuyu.cn/20241221_DL/image1.png)

> 而  `Element`  又等于  `BuildContext` ，所以，  `BuildContext` 泄漏就约等于大家一起无法回收。

那么我们到这里就知道了，其实要让对象可以被 GC，那么就是让他不被其他对象所持有，**简单说就是对需要 GC 的对象赋 null** ，事实上 Flutter/Dart 里很多 `dispose` 操作，也就是给对应 Listener 设置为 null：

![](http://img.cdn.guoshuyu.cn/20241221_DL/image2.png)

那么，为什么我前面又要说 Flutter 在 Dart 层不容易造成“完全”泄漏呢？**因为 「可能造成泄漏≠一定会泄漏」，「暂时泄漏≠完全泄漏」**。

举个例子，这是一个 Flutter  里经常提到内存泄漏案例，因为 `Timer`  里的闭包，也就是函数对象持有了 context ，所以在闭包生命周期内， context 对应的控件或者页面会无法回收，出现泄漏：

```dart
Timer(Duration(seconds: 5), () {
  print(context.size); // 持有 context 的引用
});
```

但是它又不是「致命泄漏」，因为对于这个函数对象来说，它的生命周期也就是 5s ，5s 后这个闭包其实就没有外部引用，GC 其实就可以顺利清除掉它。

举个类似例子，以下代码里 `Future.delayed` 持有了  `context` ，所有在 `Navigator.pop` 之后，context 所在页面在刚返回时无法被回收，但是，如图所示，在等待 5s 后再手动执行 GC ，看 DevTools 下的 `Instances `  数量，最终对应的页面还是可以被成功回收：

```dart
ElevatedButton(
    onPressed: () {
      Future.delayed(const Duration(seconds: 5), () {
        print(this.context.widget);
      });
      Navigator.pop(context);
    },
    child: const Text("back")),
```

![](http://img.cdn.guoshuyu.cn/20241221_DL/image3.gif)

类似的代码还有这个，例如这里 `handler` 在闭包里因为 `Theme.of` 捕获了 `context` ，但是**因为闭包的生命周期没有超过了 Widget 的生命周期**，所以其实并不会实际造成回收问题：

```dart
@override
Widget build(BuildContext context) {
  final handler = () => print(Theme.of(context));

  return ElevatedButton(
    onPressed: handler,
    child: Text('Apply Theme'),
  );
}
```

接着我们再看一个例子，**我们每个页面都通过 `Timer` 开了一个定时器，然后我们在页面退出时不主动销毁它**，可以看到对应的页面都无法被销毁，因为此时 `Timer` 的 `callback` 闭包还被  Engine 里其他对象「外部持有」，而导致 State 无法被正常回收：

```dart
int _counter = 0;
Timer? _timer;
@override
void initState() {
  _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    print(this._counter);
    print(timer.tick);
  });
  super.initState();
}
```

![](http://img.cdn.guoshuyu.cn/20241221_DL/image4.gif)

但是，**如果你把代码修改为如下所示，`Timer` 的 callback 捕获了  `context`** ，然后在页面退出后，你认为会发生什么事情？

```dart
int _counter = 0;
Timer? _timer;
@override
void initState() {
  _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    print(context.size);
  });
  super.initState();
}
```

事实上会出现如 「`This widget has been unmounted, so the State no longer has a context (and should be considered defunct).`」 的报错，但是后续 context 所在页面还是可以被 GC，因为 callback 异常会打断 Timer 的后续定时执行：

![](http://img.cdn.guoshuyu.cn/20241221_DL/image5.png)

**所以对于 Timer ，虽然我们没有回收它，但是如果它的 callback 出现异常，循环被打断，那么相关闭包也会变成可被 GC 的情况**。

> 如果对于 Timer 机制感兴趣的，可以看到：https://juejin.cn/post/7383281753145475099#heading-5 ，其实异步 Future 和 Timer 也有关系。

还有一种是 `AnimationController` ，如下代码所示，通过创建 `AnimationController` 之后，不执行相关 cancel 操作，可以看到在页面退出后，也无法触发 GC ：

```dart
int _counter = 0;
late AnimationController animationController;

@override
void initState() {
  animationController =
      AnimationController(vsync: this, duration: const Duration(seconds: 60));
  animationController.addListener(() {
    print(this._counter);
  });
  animationController.repeat();
  super.initState();
}
```

![](http://img.cdn.guoshuyu.cn/20241221_DL/image6.gif)

当然，其实  `AnimationController ` 的问题更多是因为全局单例的 `SchedulerBinding.instance.scheduleFrameCallback`  在 tick 时持有了闭包。

最后就是典型的全局引用闭包导致的泄漏，如下代码所示，将  `test` 放到全局 `closures` 列表里，会导致闭包一直被外部持有无法回收，从而让闭包捕获的 context 和 state 都无法回收：

```dart
final List<Function> closures = [];

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  @override
  void initState() {
    var test = () {
      _counter++;
       print(context.widget);
    };
    closures.add(test);
    super.initState();
  }
```

类似的典型例子还有官方修复 `UndoHistory` 的内存泄漏问题，`UndoManager.client` 是一个静态变量，在失去焦点和控件销毁时，需要将 `UndoManager.client`  的引用清空，不然静态变量变量会一直持有  `UndoHistoryState` ，导致它无法被回收而出现内存泄漏：

![](http://img.cdn.guoshuyu.cn/20241221_DL/image7.png)

> `UndoHistory` 是 `TextField` 的内部控件之一。

所以，有没有和你想的不大一样？就是其实一不小心写的闭包就会导致内存泄漏，都是实际上也还兜得住，**主要还是看内存泄漏的严重程度**，只要不是存在静态和全局引用，一般来说闭包的生命周期不会很长，还是可以在最后被 GC。

当然，**良好的代码习惯可以加速内存回收**，同时避免内存泄漏的出现，因此正确使用 context 还是很有必要的，比如：

- 要尽可能不要让 context 出现在异步和闭包里面
- 要尽可能不让闭包被全局持有

总结起来就是：**小心静态和全局变量，注意 BuildContext 和闭包捕获**。

当然，有的时候，内存泄漏可能更多来自底层问题，比如过去就有[在异步操作里的闭包过度捕获#42457](https://github.com/dart-lang/sdk/issues/42457#issuecomment-705989814)，导致出现的内存泄漏问题：

![](http://img.cdn.guoshuyu.cn/20241221_DL/image8.png)

另外有时候还要避免内存膨胀，例如在大量数据操作时，使用 `BytesBuilder` 代替 `Uint8List` 频繁计算过程中的频繁 GC ，也是优化的一种方式。

最后，在适当场景使用 `WeakReference` 和 `Finalizer` ，也可以有效帮助优化内存场景。



