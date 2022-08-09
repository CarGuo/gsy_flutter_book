# Flutter 小技巧之  MediaQuery  和 build 优化你不知道的秘密

**今天这篇文章的目的是补全大家对于 `MediaQuery`  和对应 rebuild 机制的基础认知，相信本篇内容对你优化性能和调试 bug 会很有帮助**。

Flutter 里大家应该都离不开 `MediaQuery ` ，比如通过 `MediaQuery.of(context).size` 获取屏幕大小 ，或者通过  `MediaQuery.of(context).padding.top`  获取状态栏高度，那随便使用 `MediaQuery.of(context)` 会有什么问题吗？

首先我们需要简单解释一下，通过 `MediaQuery.of` 获取到的  `MediaQueryData` 里有几个很类似的参数：

- `viewInsets` ： **被系统用户界面完全遮挡的部分大小，简单来说就是键盘高度**
- `padding` ： **简单来说就是状态栏和底部安全区域，但是 `bottom` 会因为键盘弹出变成 0**
- `viewPadding ` ：**和 `padding` 一样，但是 `bottom` 部分不会发生改变**

举个例子，在 iOS 上，如下图所示，在弹出键盘和未弹出键盘的情况下，可以看到 `MediaQueryData` 里一些参数的变化：

- `viewInsets`  在没有弹出键盘时是 0，弹出键盘之后 `bottom` 变成 336 
- `padding` 在弹出键盘的前后区别， `bottom` 从 34 变成了 0
- `viewPadding `  在键盘弹出前后数据没有发生变化

![image-20220624115935998](http://img.cdn.guoshuyu.cn/20220628_N7/image1.png)

> **可以看到   `MediaQueryData`  里的数据是会根据键盘状态发生变化**，又因为   `MediaQuery `  是一个 `InheritedWidget` ，所以我们可以通过 `MediaQuery.of(context)` 获取到顶层共享的  `MediaQueryData` 。

那么问题来了，**`InheritedWidget`  的更新逻辑，是通过登记的 `context` 来绑定的，也就是  `MediaQuery.of(context)`  本身就是一个绑定行为**，然后   `MediaQueryData`  又和键盘状态有关系，所以：键盘的弹出可能会导致使用 `MediaQuery.of(context)`   的地方触发 rebuild，举个例子：

如下代码所示，我们在 `MyHomePage` 里使用了 `MediaQuery.of(context).size` 并打印输出，然后跳转到  `EditPage` 页面，弹出键盘 ，这时候会发生什么情况？

```dart

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("######### MyHomePage ${MediaQuery.of(context).size}");
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
              return EditPage();
            }));
          },
          child: new Text(
            "Click",
            style: TextStyle(fontSize: 50),
          ),
        ),
      ),
    );
  }
}

class EditPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: new Text("ControllerDemoPage"),
      ),
      extendBody: true,
      body: Column(
        children: [
          new Spacer(),
          new Container(
            margin: EdgeInsets.all(10),
            child: new Center(
              child: new TextField(),
            ),
          ),
          new Spacer(),
        ],
      ),
    );
  }
}
```

如下图  log 所示 ，  可以看到在键盘弹起来的过程，因为 bottom 发生改变，所以    `MediaQueryData`  发生了改变，从而导致上一级的 `MyHomePage` 虽然不可见，但是在键盘弹起的过程里也被不断 build 。

![image-20220624121917686](http://img.cdn.guoshuyu.cn/20220628_N7/image2.png)

> 试想一下，如果你在每个页面开始的位置都是用了  `MediaQuery.of(context)`  ，然后打开了 5 个页面，这时候你在第 5 个页面弹出键盘时，也触发了前面 4 个页面 rebuild，自然而然可能就会出现卡顿。

**那么如果我不在 `MyHomePage` 的 build 方法直接使用   `MediaQuery.of(context)` ，那在  `EditPage`  里弹出键盘是不是就不会导致上一级的  `MyHomePage`  触发 build** ？

> 答案是肯定的，没有了    `MediaQuery.of(context).size`  之后， `MyHomePage`  就不会因为   `EditPage`   里的键盘弹出而导致 rebuild。

所以小技巧一：**要慎重在 `Scaffold` 之外使用 `MediaQuery.of(context)`** ，可能你现在会觉得奇怪什么是  `Scaffold` 之外，没事后面继续解释。

那到这里有人可能就要说了：我们通过    `MediaQuery.of(context)`  获取到的   `MediaQueryData`  ，不就是对应在  `MaterialApp`  里的 `MediaQuery`  吗？那它发生改变，不应该都会触发下面的 child 都 rebuild 吗？

> **这其实和页面路由有关系，也就是我们常说的 `PageRoute`  的实现**。

如下图所示，因为嵌套结构的原因，事实上弹出键盘确实会导致  `MaterialApp`   下的 child 都触发 rebuild ，因为设计上 `MediaQuery` 就是在 `Navigator` 上面，**所以弹出键盘自然也就触发  `Navigator`  的  rebuild**。

![image-20220624141749056](http://img.cdn.guoshuyu.cn/20220628_N7/image3.png)

**那正常情况下   `Navigator`   都触发 rebuild 了，为什么页面不会都被 rebuild 呢**？

这就和路由对象的基类 `ModalRoute` 有关系，因为在它的内部会通过一个 `_modalScopeCache` 参数把 	`Widget` 缓存起来，正如注释所说：

> **缓存区域不随帧变化，以便得到最小化的构建**。

![](http://img.cdn.guoshuyu.cn/20220628_N7/image4.png)

举个例子，如下代码所示：

- 首先定义了一个 `TextGlobal`  ，在 build 方法里输出 `"######## TextGlobal"` 
- 然后在 `MyHomePage` 里定义一个全局的 ` TextGlobal globalText = TextGlobal();`
- 接着在  `MyHomePage`  里添加 3 个 globalText
- 最后点击 `FloatingActionButton` 触发 ` setState(() {});`

```dart
class TextGlobal extends StatelessWidget {
  const TextGlobal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("######## TextGlobal");
    return Container(
      child: new Text(
        "测试",
        style: new TextStyle(fontSize: 40, color: Colors.redAccent),
        textAlign: TextAlign.center,
      ),
    );
  }
}
class MyHomePage extends StatefulWidget {
  final String? title;
  MyHomePage({Key? key, this.title}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextGlobal globalText = TextGlobal();
  @override
  Widget build(BuildContext context) {
    print("######## MyHomePage");
    return Scaffold(
      appBar: AppBar(),
      body: new Container(
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            globalText,
            globalText,
            globalText,
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {});
        },
      ),
    );
  }
}
```

那么有趣的来了，如下图 log 所示，`"######## TextGlobal"` 除了在一开始构建时有输出之外，剩下  ` setState(() {});` 的时候都没有在触发，也就是没有 rebuild ，这其实就是上面 `ModalRoute`  的类似行为：**弹出键盘导致了  `MediaQuery` 触发  `Navigator`  执行 rebuild，但是 rebuild 到了 `ModalRoute` 就不往下影响**。

![](http://img.cdn.guoshuyu.cn/20220628_N7/image5.png)

其实这个行为也体现在了  `Scaffold` 里，如果你去看 `Scaffold` 的源码，你就会发现 `Scaffold` 里大量使用了  `MediaQuery.of(context)` 。

比如上面的代码，如果你给 `MyHomePage` 的  `Scaffold`  配置一个 3333 的 `ValueKey` ，那么在 `EditPage` 弹出键盘时，其实 `MyHomePage` 的  `Scaffold`  是会触发 rebuild ，但是因为其使用的是  `widget.body` ，所以并不会导致 `body` 内对象重构。

![](http://img.cdn.guoshuyu.cn/20220628_N7/image6.png)

> 如果是 `MyHomePage` 如果 rebuild ，就会对 build 方法里所有的配置的 `new` 对象进行 rebuild；但是如果只是  `MyHomePage`  里的   `Scaffold`   内部触发了 rebuild  ，是不会导致  `MyHomePage`   里的 body 参数对应的 child 执行 rebuild 。

是不是太抽象？举个简单的例子，如下代码所示：

- 我们定义了一个  `LikeScaffold` 控件，在控件内通过 `widget.body` 传递对象
- 在   `LikeScaffold`  内部我们使用了  `MediaQuery.of(context).viewInsets.bottom ` ，模仿 `Scaffold` 里使用 `MediaQuery`
- 在  `MyHomePage` 里使用 `LikeScaffold`   ，并给 `LikeScaffold`   的 body 配置一个 `Builder` ，输出 `"############ HomePage Builder Text "` 用于观察
- 跳到 `EditPage`  页面打开键盘

```dart
class LikeScaffold extends StatefulWidget {
  final Widget body;

  const LikeScaffold({Key? key, required this.body}) : super(key: key);

  @override
  State<LikeScaffold> createState() => _LikeScaffoldState();
}

class _LikeScaffoldState extends State<LikeScaffold> {
  @override
  Widget build(BuildContext context) {
    print("####### LikeScaffold build ${MediaQuery.of(context).viewInsets.bottom}");
    return Material(
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [widget.body],
      ),
    );
  }
}
····
class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    var routeLists = routers.keys.toList();
    return new LikeScaffold(
      body: Builder(
        builder: (_) {
          print("############ HomePage Builder Text ");
          return InkWell(
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(builder: (context) {
                return EditPage();
              }));
            },
            child: Text(
              "FFFFFFF",
              style: TextStyle(fontSize: 50),
            ),
          );
        },
      ),
    );
  }
}
```

可以看到，最开始  `"####### LikeScaffold build  0.0` 和  `############ HomePage Builder Text ` 都正常执行，然后在键盘弹出之后，`"####### LikeScaffold build` 跟随键盘动画不断输出 `bottom`   的 大小，但是 `"############ HomePage Builder Text ")` 没有输出，因为它是 `widget.body` 实例。

![](http://img.cdn.guoshuyu.cn/20220628_N7/image7.png)

**所以通过这个最小例子，可以看到虽然 `Scaffold`  里大量使用    `MediaQuery.of(context)`   ，但是影响范围是约束在  `Scaffold`   内部**。

接着我们继续看修改这个例子，如果在 `LikeScaffold` 上嵌套多一个  `Scaffold`   ，那输出结果会是怎么样？

```dart

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    var routeLists = routers.keys.toList();
    ///多加了个 Scaffold
    return Scaffold(
      body:  new LikeScaffold(
        body: Builder(
        ·····
        ),
      ),
    );
}
```

答案是  `LikeScaffold`  内的  `"####### LikeScaffold build`   也不会因为键盘的弹起而输出，也就是：     **`LikeScaffold`  虽然使用了   `MediaQuery.of(context)`   ，但是它不再因为键盘的弹起而导致 rebuild** 。

因为此时   `LikeScaffold`   是 `Scaffold` 的 child ，所以在     `LikeScaffold`    内通过    `MediaQuery.of(context)`   指向的，其实是  `Scaffold`  内部经过处理的 `MediaQueryData`。

![image-20220624150712453](http://img.cdn.guoshuyu.cn/20220628_N7/image8.png)

> 在   `Scaffold`  内部有很多类似的处理，例如 `body` 里会根据是否有 `Appbar` 和 `BottomNavigationBar`  来决定是否移除该区域内的 paddingTop 和 paddingBottom 。

所以，看到这里有没有想到什么？**为什么时不时通过    `MediaQuery.of(context)`   获取的 padding ，有的 top 为 0 ，有的不为 0 ，原因就在于你获取的 context 来自哪里**。

举个例子，如下代码所示， `ScaffoldChildPage`  作为 `Scaffold` 的 child ，我们分别在 ` MyHomePage `和 `ScaffoldChildPage` 里打印  `MediaQuery.of(context).padding` ：

```dart
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("MyHomePage         MediaQuery padding: ${MediaQuery.of(context).padding}");
    return Scaffold(
      appBar: AppBar(
        title: new Text(""),
      ),
      extendBody: true,
      body: Column(
        children: [
          new Spacer(),
          ScaffoldChildPage(),
          new Spacer(),
        ],
      ),
    );
  }
}
class ScaffoldChildPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("ScaffoldChildPage  MediaQuery padding: ${MediaQuery.of(context).padding}");
    return Container();
  }
}
```

如下图所示，可以看到，因为此时 `MyHomePage` 有 `Appbar`  ，所以  `ScaffoldChildPage` 里获取到 paddingTop 是 0 ，因为此时  `ScaffoldChildPage`  获取到的 `MediaQueryData` 已经被    `MyHomePage`  里的 `Scaffold` 改写了。

![image-20220624151522429](http://img.cdn.guoshuyu.cn/20220628_N7/image9.png)

如果此时你给  `MyHomePage`  增加了 `BottomNavigationBar` ，可以看到  `ScaffoldChildPage`  的 bottom 会从原本的 34 变成 90 。

![image-20220624152008795](http://img.cdn.guoshuyu.cn/20220628_N7/image10.png)

到这里可以看到   `MediaQuery.of`  里的 context 对象很重要：

- **如果页面   `MediaQuery.of`   用的是  `Scaffold` 外的 `context ` ，获取到的是顶层的 `MediaQueryData` ，那么弹出键盘时就会导致页面 rebuild** 
- **`MediaQuery.of`   用的是  `Scaffold` 内的 `context `  ，那么获取到的是   `Scaffold`  对于区域内的  `MediaQueryData`**  ，比如前面介绍过的 body ，同时获取到的 `MediaQueryData`   也会因为   `Scaffold`  的配置不同而发生改变

所以，如下动图所示，**其实部分人会在 push 对应路由地方，通过嵌套 `MediaQuery`  来做一些拦截处理，比如设置文本不可缩放，但是其实这样会导致键盘在弹出和收起时，触发各个页面不停 rebuild** ，比如在 Page 2 弹出键盘的过程，Page 1 也在不停 rebuild。

![1111333](http://img.cdn.guoshuyu.cn/20220628_N7/image11.gif)

所以，如果需要做一些全局拦截，推荐通过 `useInheritedMediaQuery` 这种方式来做全局处理。

```dart
return MediaQuery(
  data: MediaQueryData.fromWindow(WidgetsBinding.instance!.window).copyWith(boldText: false),
  child: MaterialApp(
    useInheritedMediaQuery: true,
  ),
);
```

所以最后做个总结，本篇主要理清了：

-  `MediaQueryData` 里 `viewInsets`  \ ` padding`  \ `viewPadding ` 的区别
-  `MediaQuery` 和键盘状态的关系
-  `MediaQuery.of`   使用不同 context 对性能的影响
- 通过  `Scaffold` 内的 `context `  获取到的  `MediaQueryData`   受到   `Scaffold`  的影响

那么，如果看完本篇你还有什么疑惑，欢迎留言评论交流。
