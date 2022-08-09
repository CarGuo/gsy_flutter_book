# Flutter 小技巧之优化你使用的 BuildContext

Flutter 里的  `BuildContext`  相信大家都不会陌生，虽然它叫 Context，但是它实际是  Element 的抽象对象，而在 Flutter 里，它主要来自于 `ComponentElement` 。

关于  `ComponentElement`  可以简单介绍一下，在 Flutter 里根据 Element  可以简单地被归纳为两类：

- `RenderObjectElement` ：具备 `RenderObject` ，拥有布局和绘制能力的 Element
- `ComponentElement` ：没有 `RenderObject` ，我们常用的 `StatelessWidget`  和 `StatefulWidget`  里对应的 `StatelessElement` 和 `StatefulElement` 就是它的子类。

所以一般情况下，我们在 `build` 方法或者  State 里获取到的   `BuildContext`   其实就是  `ComponentElement` 。

*那使用  `BuildContext`   有什么需要注意的问题*？

首先如下代码所示，在该例子里当用户点击 `FloatingActionButton` 的时候，代码里做了一个 2秒的延迟，然后才调用  `pop` 退出当前页面。

```dart
class _ControllerDemoPageState extends State<ControllerDemoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Future.delayed(Duration(seconds: 2));
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
```

正常情况下是不会有什么问题，但是当用户在点击了 `FloatingActionButton`  之后，又马上点击了  `AppBar`  返回退出应用，这时候就会出现以下的错误提示。

![](http://img.cdn.guoshuyu.cn/20220720_N8/image1.png)

可以看到此时 log 说，Widget 对应的 Element  已经不在了，因为在 `Navigator.of(context)` 被调用时，`context` 对应的 Element 已经随着我们的退出销毁。

一般情况下处理这个问题也很简单，**那就是增加 `mounted`  判断，通过  `mounted`   判断就可以避免上述的错误**。

```dart
class _ControllerDemoPageState extends State<ControllerDemoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Future.delayed(Duration(seconds: 2));
          if (!mounted) return;
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
```

上面代码里的 `mounted`  标识位来自于  `State` ，**因为  `State`  是依附于 Element 创建，所以它可以感知 Element 的生命周期**，例如 `mounted` 就是判断 `_element != null;` 。

![](http://img.cdn.guoshuyu.cn/20220720_N8/image2.png)

那么到这里我们收获了一个小技巧：**使用 `BuildContext` 时，在必须时我们需要通过  `mounted`   来保证它的有效性**。 

*那么单纯使用  `mounted`  就可以满足 context 优化的要求了吗*？

如下代码所示，在这个例子里：

- 我们添加了一个列表，使用 `builder` 构建 Item
- 每个列表都有一个点击事件
- 点击列表时我们模拟网络请求，假设网络也不是很好，所以延迟个 5 秒
- 之后我们滑动列表让点击的 Item 滑出屏幕不可见

```dart
class _ControllerDemoPageState extends State<ControllerDemoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        itemBuilder: (context, index) {
          return ListItem();
        },
        itemCount: 30,
      ),
    );
  }
}
class ListItem extends StatefulWidget {
  const ListItem({Key? key}) : super(key: key);
  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Container(
        height: 160,
        color: Colors.amber,
      ),
      onTap: () async {
        await Future.delayed(Duration(seconds: 5));
        if(!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Tip")));
      },
    );
  }
}
```

由于在 5 秒之内，Item 被划出了屏幕，所以对应的 Elment 其实是被释放了，从而由于 `mounted` 判断，`SnackBar` 不会被弹出。

*那如果假设需要在开发时展示点击数据上报的结果，也就是 Item 被释放了还需要弹出，这时候需要如何处理*？

我们知道不管是 `ScaffoldMessenger.of(context)` 还是 `Navigator.of(context)`  ，它本质还是通过 `context` 去往上查找对应的 `InheritedWidget`  泛型，所以其实我们可以提前获取。

所以，如下代码所示，在 `Future.delayed` 之前我们就通过 `ScaffoldMessenger.of(context);`  获取到 `sm` 对象，之后就算你直接退出当前的列表页面，5秒过后 `SnackBar` 也能正常弹出。

```dart
class _ListItemState extends State<ListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Container(
        height: 160,
        color: Colors.amber,
      ),
      onTap: () async {
        var sm = ScaffoldMessenger.of(context);
        await Future.delayed(Duration(seconds: 5));
        sm.showSnackBar(SnackBar(content: Text("Tip")));
      },
    );
  }
}

```

*为什么页面销毁了，但是  `SnackBar` 还能正常弹出* ？

因为此时通过 `of(context);` 获取到的  `ScaffoldMessenger` 是存在 `MaterialApp` 里，所以就算页面销毁了也不影响  `SnackBar`  的执行。

但是如果我们修改例子，如下代码所示，在 `Scaffold`  上面多嵌套一个  `ScaffoldMessenger`  ，这时候在 Item 里通过  `ScaffoldMessenger.of(context)`  获取到的就会是当前页面下的  `ScaffoldMessenger` 。

```dart
class _ControllerDemoPageState extends State<ControllerDemoPage> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        appBar: AppBar(),
        body: ListView.builder(
          itemBuilder: (context, index) {
            return ListItem();
          },
          itemCount: 30,
        ),
      ),
    );
  }
}
```

这种情况下我们只能保证Item 不可见的时候  `SnackBar`  还能正常弹出， 而如果这时候我们直接退出页面，还是会出现以下的错误提示，因为 `ScaffoldMessenger`   也被销毁了 。

![](http://img.cdn.guoshuyu.cn/20220720_N8/image3.png)

所以到这里我们收获第二个小技巧：**在异步操作里使用 `of(context)` ，可以提前获取，之后再做异步操作，这样可以尽量保证流程可以完整执行**。

*既然我们说到通过  `of(context)`  去获取上层共享往下共享的 `InheritedWidget` ，那在哪里获取就比较好*？

还记得前面的 log 吗？在第一个例子出错时，log 里就提示了一个方法，也就是 State 的  `didChangeDependencies`  方法。

![](http://img.cdn.guoshuyu.cn/20220720_N8/image1.png)

为什么是官方会建议在这个方法里去调用   `of(context)`   ？ 

首先前面我们一直说，通过   `of(context)`   获取到的是 `InheritedWidget`  ，而 当 `InheritedWidget`   发生改变时，就是通过触发绑定过的 Element 里  State 的`didChangeDependencies`  来触发更新，**所以在  `didChangeDependencies`   里调用   `of(context)`   有较好的因果关系**。

> 对于这部分内容感兴趣的，可以看 [Flutter 小技巧之 MediaQuery 和 build 优化你不知道的秘密](https://juejin.cn/post/7114098725600903175) 和 [全面理解State与Provider](https://juejin.cn/post/6844903866706706439#heading-5) 。

*那我能在 `initState`  里提前调用吗*？

当然不行，首先如果在  `initState`  直接调用如 `ScaffoldMessenger.of(context).showSnackBar`  方法，就会看到以下的错误提示。

![](http://img.cdn.guoshuyu.cn/20220720_N8/image4.png)

这是因为 Element 里会判断此时的 `_StateLifecycle`  状态，如果此时是 ` _StateLifecycle.created` 或者 ` _StateLifecycle.defunct` ，也就是在 `initState` 和 `dispose ` ，是不允许执行 `of(context)` 操作。

![](http://img.cdn.guoshuyu.cn/20220720_N8/image5.png)

>  `of(context)`  操作指的是 `context.dependOnInheritedWidgetOfExactTyp` 。

当然，如果你硬是想在   `initState`  下调用也行，增加一个  `Future` 执行就可以成功执行

```dart
@override
void initState() {
  super.initState();
  Future((){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("initState")));
  });
}
```

> 简单理解，因为 Dart 是单线程轮询执行，`initState` 里的  `Future` 相当于是下一次轮询，自然也就不在 ` _StateLifecycle.created`  的状态下。

*那我在 `build` 里直接调用不行吗*？

直接在  `build`  里调用肯定可以，虽然  `build`  会被比较频繁执行，但是   `of(context)`  操作其实就是在一个 map 里通过 key - value 获取泛型对象，所以对性能不会有太大的影响。

**真正对性能有影响的是 `of(context)`  的绑定数量和获取到对象之后的自定义逻辑**，例如你通过 ` MediaQuery.of(context).size` 获取到屏幕大小之后，通过一系列复杂计算来定位你的控件。

```dart
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var padding = MediaQuery.of(context).padding;
    var width = size.width / 2;
    var height = size.width / size.height  *  (30 - padding.bottom);
    return Container(
      color: Colors.amber,
      width: width,
      height: height,
    );
  }
```

例如上面这段代码，可能会导致键盘在弹出的时候，虽然当前页面并没有完全展示，但是也会导致你的控件不断重新计算从而出现卡顿。

> 详细解释可以参考  [Flutter 小技巧之 MediaQuery 和 build 优化你不知道的秘密](https://juejin.cn/post/7114098725600903175) 

所以到这里我们又收获了一个小技巧：  **对于 `of(context)`   的相关操作逻辑，可以尽量放到   `didChangeDependencies`  里去处理**。

最后，今天主要分享了在使用 `BuildContext` 时的一些注意事项和技巧，如果你对于这方面还有什么疑问，欢迎留言评论。