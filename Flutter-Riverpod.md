
随着 Flutter 的发展，这些年  Flutter 上的状态管理框架如“雨后春笋”般层出不穷，而**近一年以来最受官方推荐的状态管理框架无疑就是 `Riverpod`** ，甚至已经超过了 `Provider` ，事实上 `Riverpod` 官方也称自己为 “`Provider`，但与众不同”。

> `Provider` 本身用它自己的话来说是 “`InheritedWidget` 的封装，但更简单且复用能力更强。” ，而 `Riverpod` 就是在 `Provider` 的基础上重构了新的可能。

关于过去一年状态管理框架的对比可以看 [《2021 年的 Flutter 状态管理：如何选择？》](https://juejin.cn/post/7061784793150652452) ， **本文主要是带你解剖 `RiverPod` 的内部是如何实现，理解它的工作原理，以及如何做到比 `Provider` 更少的模板和不依赖 `BuildContext` 。**

## 前言

如果说 `Riverpod`  最明显的特点是什么，那就是外部不依赖  `BuildContext` (其实就是换了另外一种依赖形态)，因为不依赖 `BuildContext` ，所以它可以比较简单做到类似如下的效果：

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image1)

也就是 **`Riverpod` 中的 `Provider` 可以随意写成全局，并且不依赖 `BuildContext` 来编写我们需要的业务逻辑**。

> ⚠️ 提前声明下，**这里和后续的 `Provider` ，和第三方库 [*`provider`*](https://pub.flutter-io.cn/packages/provider) 没有关系**。


那  `Riverpod` 具体内部是怎么实现的呢？接下来让我们开始探索 `Riverpod` 的实现原理。

> `Riverpod` 的实现相对还是比较复杂，所以还耐心往下看，因为本篇是逐步解析，**所以如果看的过程有些迷惑可以先不必在意，通篇看完再回过来翻阅可能就会更加明朗**。



## 从 ProviderScope 开始

在 Flutter 里只要使用了状态管理，就一定避不开 `InheritedWidget` ， Riverpod 里也一样，**在 Riverpod 都会有一个 `ProviderScope`， 一般只需要注册一个顶级的 `ProviderScope`。**

> 如果对于 InheritedWidget 还有疑问，可以看我掘金：[《全面理解State与Provider》](https://juejin.cn/post/6844903866706706439#heading-5)


先从一个例子开始，如下图所示，是官方的一个简单的例子，可以看到这里：

- 嵌套一个顶级 `ProviderScope` ；
- 创建了一个全局的 `StateProvider`；
- 使用 `ConsumerWidget` 的 `ref` 对创建的 `counterProvider` 进行 `read` 从而读取 State ，获取到 `int` 值进行增加 ；
- 使用另一个 `Consumer` 的 `ref` 对创建的 `counterProvider` 进行 `watch` ，从而读取到每次改变后的 `int` 值； 

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image2)

很简单的例子，**可以看到没有任何 `of(context)` ， 而全局的 `counterProvider` 里的数据，就可以通过 `ref` 进行 read/watch，并且正确地读取和更新。**

> 那这是怎么实现的呢？`counterProvider` 又是如何被注入到 `ProviderScope` 里面？为什么没有看到 `context`？ 带着这些疑问我们继续往下探索。

首先我们看 `ProviderScope` ，它是唯一的顶级  `InheritedWidget` ，所以 `counterProvider` 必定是被存放在这里： 


> 在 RiverPod 里， **`ProviderScope` 最大的作用就是提供一个 `ProviderContainer`** 。

更具体地说，就是通过内部嵌套的 `UncontrolledProviderScope` 提供，所以到这里我们可以知道：**`ProviderScope` 可以往下提供状态共享，因为它内部有一个  `InheritedWidget` ，而主要往下共享的是 `ProviderContainer` 这个类**。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image3)


所以首先可以猜测：**我们定义的各种 Providers， 比如上面的 `counterProvider` ， 都是被存到 `ProviderContainer` 中，然后往下共享。**


> 事实上官方对于 `ProviderContainer` 的定义就是：*用于保存各种 Providers 的 State ，并且支持 override 一些特殊 Providers 的行为*。

## ProviderContainer

这里出现了一个新的类，叫 `ProviderContainer` ，其实一般情况下使用 RiverPod 你都不需要知道它，**因为你不会直接操作和使用它，但是你使用 RiverPod 的每个行为都会涉及到它的实现**，例如 ：

- `ref.read` 会需要它的 `Result read<Result>` ；
- `ref.watch` 会需要它的 `ProviderSubscription<State> listen<State>` ；
- `ref.refresh` 会需要它的 `Created refresh<Created>`

就算是各种 `Provider` 的保存和读取基本也和它有关系，所以它作为一个对各种 `Provider`  的内部管理的类，实现了 RiverPod 里很关键的一些逻辑。

## “Provider” 和 “Element”

那前面我们知道 `ProviderScope` 往下共享了 `ProviderContainer`  之后，**`Provider` 又是怎么工作的呢？为什么 `ref.watch`/ `ref.read` 会可以读取到它 `Provider` 里的值？**

继续前面的代码，这里只是定义了 `StateProvider` ，并且使用了 `ref.watch` ，为什么就可以读取到里面的 `state` 值？

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image4)

首先 `StateProvider` 是一个特殊的 `Provider` ，在它的内部还有一个叫 `_NotifierProvider` 的帮它实现了一层转换，**所以我们先用最基础的  `Provider` 类作为分析对象**。


基本是各种类似的 `Provider` 都是 `ProviderBase` 的子类，所以我们先解析 `ProviderBase`。


在 RiverPod 内部，**每个 `ProviderBase` 的子类都会有其对应的 `ProviderElementBase` 子类实现** ，例如前面代码使用的  `StateProvider` 是 `ProviderBase` 的之类，同样它也有对应的   `StateProviderElement` 是 `ProviderElementBase` 的子类；


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image5)


**所以 RiverPod 里基本是每一个 “Provider” 都会有一个自己的 “Element” 。**

> ⚠️**这里的 “Element”  不是 Flutter 概念里三棵树的 `Element`，它是 RiverPod 里 `Ref` 对象的子类**。`Ref` 主要提供 RiverPod 内的 “Provider” 之间交互的接口，并且提供一些抽象的生命周期方法，所以它是 RiverPod 里的独有的 “Element” 单位。

那 “Provider” 和 “Element” 的作用是什么？

首先，在上面例子里我们**构建 `StateProvider` 时传入的 `(ref) => 0` ，其实就是 `Create<State, StateProviderRef<State>>`** 函数，我们就从这个 `Create` 函数作为入口来探索。

## Create<T, R extends Ref> = T Function(R ref)

RiverPod 里构建 “Provider” 时都会传入一个 `Create` 函数，而这个函数里一遍我们会写一些需要的业务逻辑，比如 `counterProvider` 里的 `()=> 0` 就是初始化时返回一个 `int` 为 0 的值，**更重要的是决定了 `State` 的类型**。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image6)


如果在上面代码的基础上增加了 `<int>` 就更明显，**事实上前面我们一直在说的 `State` 就是一个泛型，而我们定义 “Provider” 就需要定义这个泛型 `State` 的类型，比如这里的 `int`** 。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image7)


回归到普通 `Provider` 的调用，**我们传入的 `Create` 函数，其实就是在 `ProviderElementBase` 里被调用执行**。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image8)

如上图所示，简单来说当 **`ProviderElementBase` 执行 “setState” 时，就会调用  `Create` 函数，从而执行获取到我们定义的泛型 `State`，得到 `Result` 然后通知并更新 UI**。

> ⚠️ 这里的 “setState” 也不是 Flutter Framework 里的 `setState` ，而是 RiverPod 内自己首先的一个 “setState” 函数，和 Flutter 框架里的 `State` 无关。


所以每个 “Provider” 都会有自己的 “Element” ，而构建 “Provider” 时是传入的 `Create` 函数会在 “Element” 内通过 `setState` 调用执行。


**“Element” 里的 `setState` 主要是通过新的 newState 去得到一个 RiverPod 里的 `Result` 对象，然后通过  `_notifyListeners` 去把得到 `Result` 更新到 `watch` 的地方。**


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image9)

`Result` 的作用主要是通过 `Result.data` 、`Result.error`、 `map` 和 `requireState` 等去提供执行结果，一般情况下状态都是通过 `requireState` 获取，具体在  RiverPod 体现为:

> **我们调用 `read()` 时，其实最后都调用到 `element.readSelf();` ，也就是返回 `requireState`** （其实一般也就是我们的泛型 `State`） 。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image10)


是不是有点乱？ 

简单点理解就是：构建出 “Provider” 之后， “Element” 里会执行`setState(_provider.create(this));` 调用我们传入的  `Create` 函数，并把 “Element”  自己作为 `ref` 传入进入，**所以我们使用的 `ref` 其实就是 `ProviderElementBase`**。


> 所以 RiverPod 里的起名是有原因的，这里的 “Provider” 和 “Element” 的关系就很有  Flutter 里 `Widget` 和 `Element` 的即视感。


分步骤来说就是：

- 构建 Provider 时我们传入了一个 `Create` 函数；
- `Create` 函数会被 `ProviderElementBase` 内部的 `setState` 所调用，得到一个 `Reuslt`；
- `Reuslt` 内的 `requireState` 就可以让我们在使用  `read()` 的时候，获取到我们定义的 泛型 `State` 的值。


## WidgetRef

前面介绍了那么多，但还是没有说  `StateProvider` 怎么和  `ProviderScope` 关联到一起，也就是 “Provider” 怎么和  `ProviderContainer` 关联到一起，**凭什么 `ref.read` 就可以读到 `State` ？**

那么前面代码里，我们用到的 `ConsumerWidget` 和 `Consumer` 都是同个东西，**而这个 `ref` 就是前面我们一直说的 “Element” ，或者说是  `ProviderElementBase`** 。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image11)

在源码里可以看到， `ConsumerWidget` 的逻辑主要在 `ConsumerStatefulElement`， 而`ConsumerStatefulElement` 继承了 `StatefulElement `，并实现了 `WidgetRef` 接口。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image12)


如上代码就可以看到前面很多熟悉的身影了： `ProviderScope` 、`ProviderContainer` 、 `WidgetRef` 。

首先我们看 `ProviderScope.containerOf(this)` ，终于看到我们熟悉的 `BuildContext` 有没有，**这个方法其实就是以前我们常用的 `of(context)` ，但是它被放到了 `ConsumerStatefulElement` 使用，用于获取  `ProviderScope`  往下共享的 `ProviderContainer`**。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image13)


所以我们看到了，`ConsumerWidget` 里的 `ConsumerStatefulElement` 获取到了  `ProviderContainer` ，所以 **`ConsumerStatefulElement` 可以调用到 `ProviderContainer` 的 read/watch** 。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image14)


然后回过头来看，`ConsumerStatefulElement` 实现了 `WidgetRef` 接口，所以 我们使用的  `WidgetRef` 就是 `ConsumerStatefulElement` 本身


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image15)

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image16)

**也就是 `ref.read` 就是执行 `ConsumerStatefulElement` 的 `read` ， 从而执行到 `ProviderContainer` 的 `read`。**

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image17)


所以我们可以总结： **`BuildContext` 是 `Element` ， 然后 `Element` 又实现了 `WidgetRef` ，所以此时的 `WidgetRef` 就是 `BuildContext` 的替代**。


> 这里不要把 Flutter 的 `Element` 和 RiverPod 里的 “`ProviderElementBase`” 搞混了。


所以 `WidgetRef` 这个接口成为了 `Element` 的抽象，替代了 `BuildContext` ，所以这就是 Riverpod 的“魔法”之一 。


## read


所以前面我们已经理清了 `ProviderScope` 、 `Provider` 、 `ProviderElementBase`、 `ProviderContainer` 、 `ConsumerWidget`（*`ConsumerStatefulElement`*）  和 `WidgetRef` 等的关系和功能，那最后我们就可以开始理清楚 `read` 的整个工作链条。

我们理清和知道了  的概念与作用之后，结合 `ref.read` 来做一个流程分析，那整体就是：

- `ConsumerWidget` 会通过内部的 `ConsumerStatefulElement` 获取到顶层 `ProviderScope` 内共享的  `ProviderContainer` ；
- 当我们通过 `ref` 调用 `read`/`watch` 时，其实就是通过    `ConsumerStatefulElement` 去调用 `ProviderContainer` 内的 `read ` 函数；


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image18)


那最后就是  `ProviderContainer` 内的 `read ` 函数如何读取到 `State`？ 

这就要结合前面我们同样介绍过的 `ProviderElementBase` ， 事实上 `ProviderContainer` 在执行  `read ` 函数时会调用 `readProviderElement` 。

`readProviderElement` 顾名思义就是通过 `Provider` 去获取到对应的 `Element`，例如 ：


```dart
ref.read(counterProvider),
```

一般情况下 read/watch 简单来说就是从 `ProviderContainer` 里用 `proivder` 做 key 获取得到 `ProviderElementBase` 这个 “Element”，**这个过程又有一个新的对象需要简单介绍下，就是：`_StateReader`**。


`readProviderElement` 其中一个关键就是获取 `_StateReader` ，在   `ProviderContainer` 里有一个 `_stateReaders` 的内部变量，它就是用于缓存  `_StateReader` 的 Map 。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image19)

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image20)



所以在 `ProviderContainer` 内部：

- 1、首先会根据 `read` 时传入的 `provider` 构建得到一个 `_StateReader`；
- 2、以 `provider` 为 key ， `_StateReader` 为 value 存入 `_stateReaders` 这个 Map，并返回 `_StateReader` ；
- 3、通过  `_StateReader` 的  `getElement()` 获取或者创建到 `ProviderElementBase`；

> 这里的以 `ProviderBase` 为 Key ， `_StateReader` 为 value 存入 `_stateReaders` ，**其实就是把 “provider” 存入到了  `ProviderContainer`，也就是和 `ProviderScope` 关联起来，也就是自此 “provider” 和 `ProviderScope` 就绑定到一起**。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image21)


没用使用到明面上的 `BuildContext` 和多余的嵌套，就让 `Provider` 和 `ProviderScope` 关联起来。
另外这里可以看到，**在 `ref.read` 时，如何通过 `provider` 构建或者获取到 `ProviderElementBase`**。



![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image22)


得到 `ProviderElementBase` 还记得前面我们介绍 “Provider” 和 "Element" 的部分吗？`ProviderElementBase` 会调用  `setState` 来执行我们传入的 `Create` 函数，得到 `Result` 返回 `State` 。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image23)


可以看到，这里获取的 `ProviderElementBase` 之后 `return element.readSelf()`  ，其实就是返回了 `requireState` 。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image24)

**自从整个 RiverPod 里最简单的 `ref.read` 流程就全线贯通了**：

- `ProviderScope` 往下共享 `ProviderContainer` ；

-  `ConsumerWidget` 内部的 `ConsumerStatefulElement` 通过 `BuildContext` 读取到  `ProviderContainer`， 并且实现 `WidgetRef` 接口；

- 通过 `WidgetRef` 接口的 `read(provider)` 调用到 `ProviderContainer` 里的 `read`；

- `ProviderContainer` 通过 `read` 方法的 `provider` 创建或者获取得到 `ProviderElementBase` 

- `ProviderElementBase` 会执行 `provider`  里的 `Create` 函数，来得到 `Result` 返回 `State` ；


其他的`watch`，`refresh` 流程大同小异，就是一些具体内部实现逻辑更复杂而已，比如刷新时：

> 通过 `ref.refresh` 方法， 其实触发的就是 `ProviderContainer` 的 `refresh` ，然后最终还是会通过 `_buildState` 去触发 ` setState(_provider.create(this))` 的执行。


**而从这个流程分析，也看到了 RiverPod 如何不暴露使用 `BuildContext` 实现全线关联的逻辑**。

## 额外分析

前面基本介绍完整个调用流程，这里在额外介绍一些常见的调用时如何实现，比如在  Riverpod 里面会看到很多 “Element” ，比如 `ProviderElement` 、`StreamProviderElement` 、 `FutureProviderElement` 等这些 `ProviderElementBase` 的子类。

我们结果过它们并不是 Flutter 里的 `Element` ，而是 Riverpod 里的的 State 单位，用于处理 `Provider` 的状态，比如 **`FutureProviderElement` 就是在 `ProviderElementBase` 的基础上提供一个 `AsyncValue<State>`，主要在 `FutureProvider` 里使用**。


## AsyncValue

在 RiverPod 里正常情况下的 create 方法定义是如下所示：

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image25)


而在 `FutureProvider` 下是多了一个 `_listenFuture`，这个  Function 执行后的 `value` 就会是 `AsyncValue<State>` 的 State 类型。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image26)
![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image27)

从 `_listenFuture` 的执行上看， 内部会对这个 `future()` 执行，会先进入 `AsyncValue<State>.loading()` 之后，根据 `Future` 的结果返回决定返回`AsyncValue<State>.data` 或者 `AsyncValue<State>.error`  。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image28)

**所以比如在 `read` / `watch` 时，返回的泛型 `requireState` 其实变成了 `AsyncValue<State>`**。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image29)

而针对 `AsyncValue` 官方做了一些 `extension` ，在 `AsyncValueX` 上，其中出了获取 `AsyncData` 的`data` \ `asData` 和 T value 之外，最主要提供了起那么所说的不同状态的构建方法，比如 `when` 方法：


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image30)


## autoDispose & family


在 Riverpod 里应该还很常见一个叫 `autoDispose` 和 `family` 的静态变量，几乎每个 `Provider` 都有，又是用来干什么的呢？


举个例子，前面代码里我们有个 `FutureProvider`， 我们用到了里的 `autoDispose`：

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image31)

**其实 `FutureProvider.autoDispose` 主要就是 `AutoDisposeFutureProvider` ，以此类推基本每个 `Provider` 都有自己的 `autoDispose` 实现，`family`  也是同理**。


如果说正常的 `Provider` 是继承了 `AlwaysAliveProviderBase`，那 `AutoDisposeProvider` 就是继承于  `AutoDisposeProviderBase` :

从名字可以看出来：

- `AlwaysAliveProviderBase` 是一只活跃的；
- `AutoDisposeProviderBase` 自然就是不 `listened` 的时候就销毁；

也就是内部 `_listeners` 、`_subscribers`、`_dependents` 都是空的时候，当然它还有另外一个 `maintainState` 的控制状态，默认它就是 `false` 的时候，就可以执行销毁。

> **简单理解就是用“完即焚烧” 。**

比如前面我们介绍调用 `read` 的时候，都会调用 `mayNeedDispose` 去尝试销毁:


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image32)

> 销毁也就是调用 `element.dispose() `和从 `_stateReaders` 这个 `map` 里移除等等。


同样的 `family` 对应是 `ProviderFamily`，它的作用是：**使用额外的参数构建 provider ，也即是增加一个参数**。


例如默认是把 ：

```dart
final tagThemeProvider  = Provider<TagTheme> 
```
可以变成 

```dart
final tagThemeProvider2  = Provider.family<TagTheme, Color>
```


然后你就可以使用额外的参数，在 `read`/`watch` 的时候 ：

```dart
final questionsCountProvider = Provider.autoDispose((ref) {
  return ref
      .watch(tagThemeProvider2(Colors.red));
});
```


之所以可以实现这个功能，就要看它的实现 `ProviderFamily` ，对比一般 `Provider` 默认的 `create` ，`ProviderFamily` 的是：


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image33)

可以看到 `create` 的是新的一个 `Provider`，**也就是 `family` 下其实是 `Provider` 嵌套 `Provider`**。

所以从上面的例子出发，以前我们是通过 `ref.watch(tagThemeProvider); `就可以了，因为我们的 `tagThemeProvider` 的直接就是 `ProviderBase`。

但是如果使用 `ref.watch(tagThemeProvider2);` 就会看到错误提示

```dart
The argument type 'ProviderFamily<TagTheme, Color>' can't be assigned to the parameter type 'ProviderListenable<dynamic>'. 
```

是的，因为这里是 `Provider` 嵌套 `Provider` ，我们先得到是的 `ProviderFamily<TagTheme, Color>` ，所以我们需要改为 `ref.watch(tagThemeProvider2(Colors.red));` 。

**通过 `tagThemeProvider2(Colors.red)` 执行一次变为我们需要的 `ProviderBase `**。


那 `tagThemeProvider2` 这个 `ProviderFamily` 为什么是这样执行？ `ProviderFamily` 明明没有这样的构造函数。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image34)


>  这就涉及到 Dart 语言的特性，如果有兴趣可以看 ： https://juejin.cn/post/6968369768596242469

首先这里拿到的是一个 `ProviderFamily<TagTheme, Color>`  ，在 Dart 中所有函数类型都是 `Function` 的子类型，所以函数都固有地具有 `call` 方法。

我们执行 `tagThemeProvider2(Colors.red)` 其实就是执行了 `ProviderFamily` 得 `call `方法，从而执行了 `create` 方法，得到 `FamilyProvider<State>` ，`FamilyProvider` 也就是 `ProviderBase` 的子类 。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-Riverpod/image35)



> ⚠️注意这里有点容易看错的地方，**一个是 `ProviderFamily` ， 一个是 `FamilyProvider`**， 我们从 `ProviderFamily` 里面得到了  `FamilyProvider`， 作为 `ProviderBase` 给 `ref.watch` 。

## 最后

很久没有写这么长的源码分析了，不知不觉就写到了半夜凌晨，其实相对来说，整个 Riverpod 更加复杂，所以阅读起来也更加麻烦，但是使用起来反而会相对更便捷，特别是**没有了 `BuildContext` 的限制，但是同时也是带来了 `ConsumerWidget` 的依赖，所有利弊只能看你自己的需求，但是整体 Riverpod 肯定是一个优秀的框架，值得一试。**