作为系列文章的第五篇，本篇主要探索下 Flutter 中的一些有趣原理，帮助我们更好的去理解和开发。

## 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)

#### 1、Mixins 

混入其中(￣.￣)！，是的，Flutter 使用的是 Dart 支持 Mixin ，而 Mixin 能够更好的解决**多继承**中容易出现的问题，如：**方法优先顺序混乱、参数冲突、类结构变得复杂化**等等。

Mixin 的定义解释起来会比较绕，我们直接代码从中出吧。如下代码所示，在 Dart 中 `with` 就是用于 mixins。可以看出，`class G extends B with A, A2` ，在执行 G 的 a、b、c 方法后，输出了 `A2.a()、A.b() 、B.c()` 。所以结论上简单来说，就是**相同方法被覆盖了，并且 with 后面的会覆盖前面的**。 

```
class A {
  a() {
    print("A.a()");
  }

  b() {
    print("A.b()");
  }
}

class A2 {
  a() {
    print("A2.a()");
  }
}

class B {
  a() {
    print("B.a()");
  }

  b() {
    print("B.b()");
  }

  c() {
    print("B.c()");
  }
}

class G extends B with A, A2 {

}


testMixins() {
  G t = new G();
  t.a();
  t.b();
  t.c();
}

/// ***********************输出***********************
///I/flutter (13627): A2.a()
///I/flutter (13627): A.b()
///I/flutter (13627): B.c()

```

接下来我们继续修改下代码。如下所示，我们定义了一个 `Base` 的抽象类，而`A、A2、B` 都继承它，同时再 `print` 之后执行 `super()` 操作。

从最后的输入我们可以看出，`A、A2、B `中的**所有方法都被执行了，且只执行了一次，同时执行的顺序也是和 with 的顺序有关**。如果你把下方代码中 class A.a() 方法的 super 去掉，那么你将看不到 `B.a()` 和 `base a()` 的输出。


```

abstract class Base {
  a() {
    print("base a()");
  }

  b() {
    print("base b()");
  }

  c() {
    print("base c()");
  }
}

class A extends Base {
  a() {
    print("A.a()");
    super.a();
  }

  b() {
    print("A.b()");
    super.b();
  }
}

class A2 extends Base {
  a() {
    print("A2.a()");
    super.a();
  }
}

class B extends Base {
  a() {
    print("B.a()");
    super.a();
  }

  b() {
    print("B.b()");
    super.b();
  }

  c() {
    print("B.c()");
    super.c();
  }
}

class G extends B with A, A2 {

}

testMixins() {
  G t = new G();
  t.a();
  t.b();
  t.c();
}

///I/flutter (13627): A2.a()
///I/flutter (13627): A.a()
///I/flutter (13627): B.a()
///I/flutter (13627): base a()
///I/flutter (13627): A.b()
///I/flutter (13627): B.b()
///I/flutter (13627): base b()
///I/flutter (13627): B.c()
///I/flutter (13627): base c()

```

#### 2、WidgetsFlutterBinding

说了那么多，那 Mixins 在 Flutter 中到底有什么用呢？这时候我们就要看 Flutter 中的“胶水类”： `WidgetsFlutterBinding` 。 

**WidgetsFlutterBinding** 在 Flutter启动时`runApp`会被调用，作为App的入口，它肯定需要承担各类的初始化以及功能配置，这种情况下，Mixins 的作用就体现出来了。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-5/image1)

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-5/image2)

从上图我们可以看出， **WidgetsFlutterBinding** 本身是并没有什么代码，主要是继承了 `BindingBase`，而后通过 with 黏上去的各类 **Binding**，这些 **Binding** 也都继承了 `BindingBase`。

看出来了没，这里每个 **Binding** 都可以被单独使用，也可以被“黏”到 **WidgetsFlutterBinding** 中使用，这样做的效果，是不是比起一级一级继承的结构更加清晰了?

最后我们打印下执行顺序，如下图所以，不出所料ヽ(￣▽￣)ﾉ。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-5/image3)


### 二、InheritedWidget

**InheritedWidget** 是一个抽象类，在 Flutter 中扮演者十分重要的角色，或者你并未直接使用过它，但是你肯定使用过和它相关的封装。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-5/image4)

如上图所示，**InheritedWidget** 主要实现两个方法：

* 创建了 `InheritedElement` ，该 **Element** 属于特殊 Element，  主要增加了将自身也添加到映射关系表 **`_inheritedWidgets`**【注1】，方便子孙 element 获取；同时通过 `notifyClients` 方法来更新依赖。

* 增加了 `updateShouldNotify` 方法，当方法返回 true 时，那么依赖该 Widget 的实例就会更新。

所以我们可以简单理解：**InheritedWidget 通过  `InheritedElement`  实现了由下往上查找的支持（因为自身添加到 `_inheritedWidgets`），同时具备更新其子孙的功能。**

> 注1：每个 Element 都有一个 `_inheritedWidgets` ,它是一个 `HashMap<Type, InheritedElement>`，它保存了上层节点中出现的 **InheritedWidget** 与其对应 element 的映射关系。


![](http://img.cdn.guoshuyu.cn/20190604_Flutter-5/image5)

接着我们看 **BuildContext**，如上图，**BuildContext** 其实只是接口， **Element** 实现了它。`InheritedElement` 是 **Element** 的子类，所以**每一个 InheritedElement 实例是一个 BuildContext 实例**。同时我们日常使用中传递的 BuildContext 也都是一个 Element 。


所以当我们遇到需要共享 State 时，如果逐层传递 state 去实现共享会显示过于麻烦，那么了解了上面的 **InheritedWidget** 之后呢？

是否**将需要共享的 State，都放在一个 InheritedWidget 中，然后在使用的 widget 中直接取用**就可以呢？答案是肯定的！所以如下方这类代码：通常如 *焦点、主题色、多语言、用户信息* 等都属于 App 内的全局共享数据，他们都会通过 BuildContext（InheritedElement） 获取。

```
///收起键盘
FocusScope.of(context).requestFocus(new FocusNode());

/// 主题色
Theme.of(context).primaryColor

/// 多语言
Localizations.of(context, GSYLocalizations)
 
/// 通过 Redux 获取用户信息
StoreProvider.of(context).userInfo

/// 通过 Redux 获取用户信息
StoreProvider.of(context).userInfo

/// 通过 Scope Model 获取用户信息
ScopedModel.of<UserInfo>(context).userInfo

```

综上所述，我们从先 `Theme` 入手。

如下方代码所示，通过给 `MaterialApp` 设置主题数据，通过 `Theme.of(context)` 就可以获取到主题数据并绑定使用。当 `MaterialApp` 的主题数据变化时，对应的 Widget 颜色也会发生变化，这是为什么呢(ｷ｀ﾟДﾟ´)!!？


```
  ///添加主题
  new MaterialApp(
      theme: ThemeData.dark()
  );
  
  ///使用主题色
  new Container( color: Theme.of(context).primaryColor,
```

通过源码一层层查找，可以发现这样的嵌套： ` MaterialApp -> AnimatedTheme ->  Theme -> _InheritedTheme extends InheritedWidget ` ，所以通过 `MaterialApp` 作为入口，其实就是嵌套在 **InheritedWidget** 下。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-5/image6)

如上图所示，通过 ` Theme.of(context)` 获取到的主题数据，其实是通过 `context.inheritFromWidgetOfExactType(_InheritedTheme)` 去获取的，而 **Element** 中实现了 **BuildContext** 的 `inheritFromWidgetOfExactType` 方法，如下所示：

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-5/image7)

那么，还记得上面说的  **`_inheritedWidgets`**  吗？既然 `InheritedElement` 已经存在于 _inheritedWidgets 中，拿出来用就对了。

> 前文：InheritedWidget 内的 `InheritedElement` ，该 Element 属于特殊 Element，  主要增加了将自身也添加到映射关系表 _inheritedWidgets

最后，如下图所示，在 **InheritedElement** 中，`notifyClients` 通过 `InheritedWidget` 的 `updateShouldNotify` 方法判断是否更新，比如在 **Theme**的  `_InheritedTheme`  是：

```
bool updateShouldNotify(_InheritedTheme old) => theme.data != old.theme.data;
```

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-5/image8)

> **所以本质上 Theme、Redux 、 Scope Model、Localizations 的核心都是 `InheritedWidget`。**


### 三、内存

最近闲鱼技术发布了 [《Flutter之禅 内存优化篇》](https://yq.aliyun.com/articles/651005) ，文中对于 Flutter 的内存做了深度的探索，其中有一个很有趣的发现是：

> * Flutter 中 ImageCache 缓存的是 ImageStream 对象，也就是缓存的是一个异步加载的图片的对象。
> * 在图片加载解码完成之前，无法知道到底将要消耗多少内存。
> * 所以容易产生大量的IO操作，导致内存峰值过高。

![图片来自闲鱼技术](http://img.cdn.guoshuyu.cn/20190604_Flutter-5/image9)

如上图所示，是图片缓存相关的流程，而目前的拮据处理是通过：

* 在页面不可见的时候没必要发出多余的图片
* 限制缓存图片的数量
* 在适当的时候CG

更详细的内容可以阅读文章本体，这里为什么讲到这个呢？是因为 `限制缓存图片的数量` 这一项。

还记得 `WidgetsFlutterBinding` 这个胶水类吗？其中Mixins 了 `PaintingBinding` 如下图所示，被"黏“上去的这个 binding 就是负责图片缓存

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-5/image10)

在  `PaintingBinding` 内有一个 `ImageCache` 对象，该对象全局一个单例的，同时再图片加载时的 `ImageProvider` 所使用，所以设置图片缓存大小如下：

```
//缓存个数 100
PaintingBinding.instance.imageCache.maximumSize=100;
//缓存大小 50m
PaintingBinding.instance.imageCache.maximumSizeBytes= 50 << 20;
```

### 四、线程

在闲鱼技术的 [深入理解Flutter Platform Channel](https://www.jianshu.com/p/39575a90e820) 中有讲到：**Flutter中有四大线程，Platform Task Runner 、UI Task Runner、GPU Task Runner 和 IO Task Runner。**

其中 `Platform Task Runner` 也就是 Android 和 iOS 的主线程，而 `UI Task Runner` 就是Flutter的 UI 线程。

如下图，如果做过 Flutter 中 Dart 和原生端通信的应该知道，通过 `Platform Channel` 通信的两端就是 `Platform Task Runner`  和 `UI Task Runner`，这里主要总结起来是：

* 因为 Platform Task Runner 本来就是原生的主线程，所以尽量不要在 Platform 端执行耗时操作。

* 因为Platform Channel并非是线程安全的，所以消息处理结果回传到Flutter端时，需要确保回调函数是在Platform Thread（也就是Android和iOS的主线程）中执行的。

![图片来自闲鱼技术](http://img.cdn.guoshuyu.cn/20190604_Flutter-5/image11)


### 五、热更新

*逃不开的需求。*

* 1、首先我们知道 Flutter 依然是一个 **iOS/Android** 工程。

* 2、Flutter通过在 BuildPhase 中添加 shell （xcode_backend.sh）来生成和嵌入**App.framework** 和 **Flutter.framework** 到 IOS。

* 3、Flutter通过 Gradle 引用 **flutter.jar** 和把编译完成的**二进制文件**添加到 Android 中。

其中 Android 的编译后二进制文件存在于 `data/data/包名/app_flutter/flutter_assets/`下。做过 Android 的应该知道，这个路径下是可以很简单更新的，所以你懂的 ￣ω￣=。

> **⚠️注意，1.7.8 之后的版本，Android 下的 Flutter 已经编译为纯 so 文件。**

IOS？据我了解，貌似动态库 framework 等引用是不能用热更新的，除非你不需要审核！


>自此，第五篇终于结束了！(///▽///)


### 资源推荐

* Github ： [https://github.com/CarGuo/](https://github.com/CarGuo)
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**

##### 完整开源项目推荐：

* [GSYGithubAppWeex](https://github.com/CarGuo/GSYGithubAppWeex)
* [GSYGithubApp React Native](https://github.com/CarGuo/GSYGithubApp ) 

![我们还会再见吗？](http://img.cdn.guoshuyu.cn/20190604_Flutter-5/image12)




