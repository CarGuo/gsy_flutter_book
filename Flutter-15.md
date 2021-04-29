本篇将带你深入理解 Flutter 中 State 的工作机制，并通过对状态管理框架 **Provider** 解析加深理解，看完这一篇你将更轻松的理解你的 “State 大后宫” 。

## 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)


```

⚠️第十二篇中更多讲解状态的是管理框架，本篇更多讲解 Flutter 本身的状态设计。

```

## 一、State 

### 1、State 是什么？

我们知道 Flutter 宇宙中万物皆 `Widget` ，而 **`Widget` 是 `@immutable` 即不可变的，所以每个 `Widget` 状态都代表了一帧。**

在这个基础上， **`StatefulWidget` 的 `State` 帮我们实现了在 `Widget` 的跨帧绘制**  ，也就是在每次  `Widget` 重绘的时候，通过 `State` 重新赋予  `Widget` 需要的绘制信息。

### 2、State 怎么实现跨帧共享？

这就涉及 Flutter 中  `Widget` 的实现原理，在之前的篇章我们介绍过，这里我们说两个涉及的概念：

- Flutter 中的 `Widget` 在一般情况下，是需要通过 `Element` 转化为 `RenderObject` 去实现绘制的。

- `Element` 是 `BuildContext` 的实现类，同时 `Element` 持有 `RenderObject` 和 `Widget` ，**我们代码中的 `Widget build(BuildContext context) {}` 方法，就是被 `Element` 调用的。**

了解这个两个概念后，我们先看下图，在 Flutter 中构建一个 `Widget` ，首先会创建出这个 `Widget` 的  `Element` ，**而事实上 `State` 实现跨帧共享，就是将 `State` 保存在`Element` 中，这样 `Element` 每次调用 `Widget build()` 时，是通过 `state.build(this);` 得到的新 `Widget` ，所以写在 `State ` 的数据就得以复用了。**

![](http://img.cdn.guoshuyu.cn/20190616_Flutter-15/image1)


*那 `State ` 是在哪里被创建的？*

如下图所示，**`StatefulWidget` 的 `createState` 是在 `StatefulElement ` 的构建方法里创建的，** 这就保证了只要  `Element ` 不被重新创建，`State` 就一直被复用。

同时我们看 `update` 方法，当新的 `StatefulWidget` 被创建用于更新 UI 时，新的 `widget` 就会被重新赋予到 `_state` 中，而这的设定也导致一个常被新人忽略的问题。

![](http://img.cdn.guoshuyu.cn/20190616_Flutter-15/image2)

我们先看问题代码，如下图所示：

- 1、在 `_DemoAppState` 中，我们创建了 `DemoPage` , 并且把 `data` 变量赋给了它。
-  2、`DemoPage` 在创建 `createState` 时，又将 `data` 通过直接传入 `_DemoPageState ` 。
- 3、在 `_DemoPageState ` 中直接将传入的 `data` 通过 `Text` 显示出来。

运行后我们一看也没什么问题吧？ **但是当我们点击 4 中的 `setState` 时，却发现 3 中 `Text` 没有发现改变，** 这是为什么呢？

![](http://img.cdn.guoshuyu.cn/20190616_Flutter-15/image3)

问题就在于前面 `StatefulElement `  的构建方法和 `update` 方法：

**`State` 只在  `StatefulElement`  的构建方法中创建，当我们调用 `setState` 触发 `update` 时，只是执行了 `_state.widget = newWidget`，而我们通过  `_DemoPageState(this.data)` 传入的 *data* ，在传入后执行`setState` 时并没有改变。**

如果我们采用上图代码中 3 注释的 **`widget.data` 方法，因为 `_state.widget = newWidget` 时，`State`  中的 `Widget ` 已经被更新了，`Text` 自然就被更新了。**

### 3、setState 干了什么？

我们常说的 `setState`  ，其实是调用了 `markNeedsBuild` ，**`markNeedsBuild` 内部会标记 `element` 为 `diry`，然后在下一帧 `WidgetsBinding.drawFrame` 才会被绘制，这可以也看出 `setState` 并不是立即生效的。**

![](http://img.cdn.guoshuyu.cn/20190616_Flutter-15/image4)


### 4、状态共享

前面我们聊了 Flutter 中 `State` 的作用和工作原理，接下来我们看一个老生常谈的对象： **`InheritedWidget`**  。

状态共享是常见的需求，比如用户信息和登陆状态等等，而 Flutter 中 `InheritedWidget` 就是为此而设计的，在第十二篇我们大致讲过它：

 > 在 `Element` 的内部有一个 `Map<Type, InheritedElement> _inheritedWidgets;` 参数，**`_inheritedWidgets` 一般情况下是空的，只有当父控件是 `InheritedWidget` 或者本身是 `InheritedWidgets` 时，它才会有被初始化，而当父控件是 `InheritedWidget`  时，这个 `Map` 会被一级一级往下传递与合并。**
> 
 > 所以当我们通过 `context` 调用 `inheritFromWidgetOfExactType` 时，就可以通过这个 `Map`  往上查找，从而找到这个上级的 `InheritedWidget ` 。

噢，是的，**`InheritedWidget` 共享的是  `Widget` ，只是这个  `Widget` 是一个 `ProxyWidget ` ，它自己本身并不绘制什么，但共享这个 `Widget` 内保存有的值，却达到了共享状态的目的。** 


如下代码所示，Flutter 内 `Theme` 的共享，共享的其实是 `_InheritedTheme ` 这个 `Widget` ，而我们通过 `Theme.of(context)` 拿到的，其实就是保存在这个 `Widget` 内的 `ThemeData` 。

```
  static ThemeData of(BuildContext context, { bool shadowThemeOnly = false }) {
    final _InheritedTheme inheritedTheme = context.inheritFromWidgetOfExactType(_InheritedTheme);
    if (shadowThemeOnly) {
      /// inheritedTheme 这个 Widget 内的 theme
      /// theme 内有我们需要的 ThemeData
      return inheritedTheme.theme.data;
    }
    ···
  }
```

**这里有个需要注意的点，就是 `inheritFromWidgetOfExactType` 方法刚了什么？**

我们直接找到 `Element` 中的 `inheritFromWidgetOfExactType` 方法实现，如下关键代码所示：

- 首先从 `_inheritedWidgets ` 中查找是否有该类型的 `InheritedElement ` 。
- 查找到后添加到 `_dependencies` 中，并且通过 `updateDependencies` **将当前 `Element` 添加到 `InheritedElement` 的 `_dependents` 这个Map 里。**
- 返回 `InheritedElement ` 中的 `Widget` 。

```
  @override
  InheritedWidget inheritFromWidgetOfExactType(Type targetType, { Object aspect }) {
    /// 在共享 map _inheritedWidgets 中查找
    final InheritedElement ancestor = _inheritedWidgets == null ? null : _inheritedWidgets[targetType];
    if (ancestor != null) {
      /// 返回找到的 InheritedWidget ，同时添加当前 element 处理
      return inheritFromElement(ancestor, aspect: aspect);
    }
    _hadUnsatisfiedDependencies = true;
    return null;
  }

  @override
  InheritedWidget inheritFromElement(InheritedElement ancestor, { Object aspect }) {
    _dependencies ??= HashSet<InheritedElement>();
    _dependencies.add(ancestor);
   /// 就是将当前 element（this） 添加到  _dependents 里
   /// 也就是 InheritedElement 的 _dependents
   /// _dependents[dependent] = value;
    ancestor.updateDependencies(this, aspect);
    return ancestor.widget;
  }

  @override
  void notifyClients(InheritedWidget oldWidget) {
    for (Element dependent in _dependents.keys) {
      notifyDependent(oldWidget, dependent);
    }
  }
```

这里面的关键就是 **` ancestor.updateDependencies(this, aspect);`** 这个方法：

我们都知道，获取 `InheritedWidget ` 一般需要 `BuildContext `  ，如`Theme.of(context)` ，而 `BuildContext ` 的实现就是 `Element` ，**所以当我们调用 `context.inheritFromWidgetOfExactType` 时，就会将这个 `context` 所代表的 `Element` 添加到 `InheritedElement` 的 `_dependents` 中。**


*这代表着什么？*

比如当我们在   `StatefulWidget` 中调用 `Theme.of(context).primaryColor` 时，**传入的 `context`   就代表着这个 `Widget` 的 `Element`， 在  `InheritedElement`  里被“登记”到 `_dependents` 了。**


**而当  `InheritedWidget ` 被更新时，如下代码所示，`_dependents` 中的 `Element` 会被逐个执行 `notifyDependent ` ，最后触发 `markNeedsBuild`** ，这也是为什么当 `InheritedWidget` 被更新时，通过如 `Theme.of(context).primaryColor` 引用的地方，也会触发更新的原因。

![](http://img.cdn.guoshuyu.cn/20190616_Flutter-15/image5)


> 下面开始实际分析 **Provider** 。

## 二、Provider

*为什么会有 **Provider** ？*

因为 Flutter 与 React 技术栈的相似性，所以在 Flutter 中涌现了诸如` flutter_redux` 、`flutter_dva` 、 `flutter_mobx` 、 `fish_flutter` 等前端式的状态管理，它们大多比较复杂，而且需要对框架概念有一定理解。

而作为 Flutter 官方推荐的状态管理 `scoped_model` ，又因为其设计较为简单，有些时候不适用于复杂的场景。

所以在经历了一端坎坷之后，**今年 Google I/O 大会之后， [Provider](https://github.com/rrousselGit/provider) 成了 Flutter 官方新推荐的状态管理方式之一。**

它的特点就是： **不复杂，好理解，代码量不大的情况下，可以方便组合和控制刷新颗粒度** ， 而原 Google 官方仓库的状态管理 [flutter-provide](https://github.com/google/flutter-provide) 已宣告GG ， [provider](https://github.com/rrousselGit/provider) 成了它的替代品。

```
⚠️注意，`provider` 比 `flutter-provide` 多了个 `r`。
```

> 题外话：以前面试时，偶尔会被面试官问到“你的开源项目代码量也不多啊”这样的问题，每次我都会笑而不语，**虽然代码量能代表一些成果，但是我是十分反对用代码量来衡量贡献价值，这和你用加班时长来衡量员工价值有什么区别？**

### 0、演示代码

如下代码所示， 实现的是一个点击计数器，其中：

- `_ProviderPageState`  中使用`MultiProvider` 提供了多个 `providers` 的支持。
- 在 `CountWidget` 中通过 `Consumer` 获取的 `counter ` ，同时更新 `_ProviderPageState` 中的 `AppBar` 和  `CountWidget ` 中的 `Text ` 显示。

```
class _ProviderPageState extends State<ProviderPage> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(builder: (_) => ProviderModel()),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              var counter =  Provider.of<ProviderModel>(context);
              return new Text("Provider ${counter.count.toString()}");
            },
          )
        ),
        body: CountWidget(),
      ),
    );
  }
}

class CountWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderModel>(builder: (context, counter, _) {
      return new Column(
        children: <Widget>[
          new Expanded(child: new Center(child: new Text(counter.count.toString()))),
          new Center(
            child: new FlatButton(
                onPressed: () {
                  counter.add();
                },
                color: Colors.blue,
                child: new Text("+")),
          )
        ],
      );
    });
  }
}

class ProviderModel extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void add() {
    _count++;
    notifyListeners();
  }
}
```

所以上述代码中，我们通过 `ChangeNotifierProvider ` 组合了 `ChangeNotifier` (ProviderModel) 实现共享；利用了 ` Provider.of` 和 `Consumer ` 获取共享的 `counter` 状态；通过调用 `ChangeNotifier`  的 `   notifyListeners();` 触发更新。

这里几个知识点是：

- 1、 **Provider**  的内部 `DelegateWidget` 是一个 `StatefulWidget` ，所以可以更新且具有生命周期。

- 2、状态共享是使用了 `InheritedProvider` 这个 `InheritedWidget` 实现的。

- 3、巧妙利用 `MultiProvider` 和 `Consumer` 封装，实现了组合与刷新颗粒度控制。


接着我们逐个分析

### 1、Delegate

既然是状态管理，那么肯定有 `StatefulWidget` 和 `setState` 调用。

在 **Provider**  中，一系列关于  `StatefulWidget`  的生命周期管理和更新，都是通过各种代理完成的，如下图所示，上面代码中我们用到的 `ChangeNotifierProvider ` 大致经历了这样的流程：

- 设置到 `ChangeNotifierProvider ` 的 `ChangeNotifer` 会被执行 `addListener` 添加监听 `listener`。
- `listener` 内会调用 `StateDelegate` 的 `StateSetter` 方法，从而调用到   `StatefulWidget`  的 `setState`。
- 当我们执行 `ChangeNotifer` 的 `notifyListeners ` 时，就会最终触发 `setState` 更新。

![](http://img.cdn.guoshuyu.cn/20190616_Flutter-15/image6)

而我们使用过的 `MultiProvider` 则是允许我们组合多种 `Provider` ，如下代码所示，传入的 `providers` 会倒序排列，最后组合成一个嵌套的 Widget tree ，方便我们添加多种 `Provider` ：

```
  @override
  Widget build(BuildContext context) {
    var tree = child;
    for (final provider in providers.reversed) {
      tree = provider.cloneWithChild(tree);
    }
    return tree;
  }

  /// Clones the current provider with a new [child].
  /// Note for implementers: all other values, including [Key] must be
  /// preserved.
  @override
  MultiProvider cloneWithChild(Widget child) {
    return MultiProvider(
      key: key,
      providers: providers,
      child: child,
    );
  }
```

通过 `Delegate` 中回调出来的各种生命周期，如 `Disposer `，也有利于我们外部二次处理，减少外部 `StatefulWidget ` 的嵌套使用。

### 2、InheritedProvider

状态共享肯定需要 `InheritedWidget` ，`InheritedProvider ` 就是`InheritedWidget ` 的子类，所有的 `Provider` 实现都在 `build` 方法中使用 `InheritedProvider ` 进行嵌套，实现 `value` 的共享。

### 3、Consumer

`Consumer ` 是 `Provider` 中比较有意思的东西，它本身是一个 `StatelessWidget` ,  只是在  `build ` 中通过 ` Provider.of<T>(context)` 帮你获取到 `InheritedWidget` 共享的 `value` 。

```
  final Widget Function(BuildContext context, T value, Widget child) builder;

 @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Provider.of<T>(context),
      child,
    );
  }
```

那我们直接使用 `Provider.of<T>(context)` ，不使用 `Consumer ` 可以吗？ 

当然可以，但是你还记得前面，我们在介绍 `InheritedWidget`  时所说的：

>  传入的 `context`  代表着这个 `Widget` 的 `Element` 在  `InheritedElement`  里被“登记”到 `_dependents` 了。

`Consumer `  做为一个单独 `StatelessWidget` ，**它的好处就是 `Provider.of<T>(context)`  传入的 `context` 就是 `Consumer ` 它自己。** 这样的话，我们在需要使用 `Provider.value` 的地方用 `Consumer` 做嵌套， `InheritedWidget`  更新的时候，就不会更新到整个页面 , 而是仅更新到 `Consumer `  这个 `StatelessWidget`  。

**所以 `Consumer `  贴心的封装了 `context` 在 `InheritedWidget` 中的“登记逻辑”，从而控制了状态改变时，需要更新的精细度。**

同时库内还提供了  `Consumer2` ～ `Consumer6` 的组合，感受下 ：

```

  @override
  Widget build(BuildContext context) {
    return builder(
      context,
      Provider.of<A>(context),
      Provider.of<B>(context),
      Provider.of<C>(context),
      Provider.of<D>(context),
      Provider.of<E>(context),
      Provider.of<F>(context),
      child,
    );
```

这样的设定，相信用过 BLoC 模式的同学会感觉很贴心，以前正常用做 BLoC 时，每个 `StreamBuilder` 的 `snapShot` 只支持一种类型，多个时*要不就是多个状态合并到一个实体，要不就需要多个StreamBuilder嵌套。*

当然，如果你想直接利用 `LayoutBuilder` 搭配  `Provider.of<T>(context)` 也是可以的：

```
LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              var counter =  Provider.of<ProviderModel>(context);
              return new Text("Provider ${counter.count.toString()}");
            }
```

其他的还有 `ValueListenableProvider` 、`FutureProvider ` 、`StreamProvider ` 等多种 `Provider` ，可见整个 **Provider** 的设计上更贴近 Flutter 的原生特性，同时设计也更好理解，并且兼顾了性能等问题。

**Provider** 的使用指南上，更详细的 [Vadaski](https://juejin.im/user/5b5d45f4e51d453526175c06/posts) 的
[《Flutter | 状态管理指南篇——Provider》](https://juejin.im/post/5d00a84fe51d455a2f22023f) 已经写过，我就不重复写轮子了，感兴趣的可以过去看看。

>自此，第十五篇终于结束了！(///▽///)

### 资源推荐

* 本文Demo ：https://github.com/CarGuo/state_manager_demo
* Github ： [https://github.com/CarGuo/](https://github.com/CarGuo)
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**

##### 完整开源项目推荐：

* [GSY Flutter 实战系列电子书](https://github.com/CarGuo/GSYFlutterBook)

* [GSYGithubApp Flutter](https://github.com/CarGuo/GSYGithubAppFlutter ) 

* [GSYGithubApp React Native](https://github.com/CarGuo/GSYGithubApp ) 

* [GSYGithubAppWeex](https://github.com/CarGuo/GSYGithubAppWeex)

![ ](http://img.cdn.guoshuyu.cn/20190616_Flutter-15/image7)
