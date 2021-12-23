本篇主要针对 Flutter 里 Dart 的一些语法糖实现进行解析，让你明显简单声明的关键字背后，**Dart 究竟做了什么？**

如下图所示，**起因是昨天在群里看到一个很基础的问题**，问： *“这段代码为什么不能对 `user` 进行判空？”* 。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image1)

其实这个问题很简单：

- 1、在 Dart 的 **Sound Null Safety** 下声明了非空的对象是不需要判空；（你想判断也行，会有警告⚠️）
- 2、使用了 `late` 关键字声明的对象，如果在没有初始化的时候直接访问，就会报错；


所以这个问题其实很简单，只需要改成 `User? user` 就可以简单解决，**但是为什么本来不可以为空的对象，加了  `late`  就可以不马上初始化呢？**


## late

首先如下图所示，我们写一段简单的代码，通过 `late` 声明了一个 `playerAnimation` 对象，然后在运行代码之后，通过 `dump_kernel.dart` 对编译后的 `app.dill` 进行提取。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image2)


如下图所示，通过提取编译后的代码，**可以看到 `playerAnimation` 其实被转变成了 `Animation?` 的可空对象**，而当 `playerAnimation` 被调用时，通过 `get playerAnimation()` 进行判断，如果此时  `playerAnimation == null` ， 直接就抛出 `LateError` 错误。

**所以当我们访问 `late` 声明的对象是，如果对象还没有初始化，就会返回一个异常。**


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image3)


## typedef

介绍完 `late` 接下介绍下 `typedef`，  `typedef` 在 Dart 2.13 开始可以用于**新的类型别名功能** ，比如：


```dart
// Type alias for functions (existing)
typedef ValueChanged<T> = void Function(T value);

// Type alias for classes (new!)
typedef StringList = List<String>;

// Rename classes in a non-breaking way (new!)
@Deprecated("Use NewClassName instead")
typedef OldClassName<T> = NewClassName<T>;

```

那么 `typedef` 是如何工作的？如下图所示，可以看到 `_getDeviceInfo` 方法在编译后，其实直接就被替换为 `List<String>` ，所以**实际上 `StringList` 是不参与到编译后的代码运行**，所以也不会对代码的运行效率有什么影响。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image4)

再举个例子，如下图所示，可以看到通过 `SelectItemChanged` 声明的 `selectItemChanged`，在编译后其实直接就是 `   final field (dynamic) →? void selectItemChanged;` 。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image5)


接着我们通过 Dart 的 `tear-off` 来看另外一个现象，如下图所示，可以看到我们从一个任意对象中 `x `中提取了 `toString`方法，通过闭包，就可以像调用常规实例一样调用 `x`。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image6)

> 如果在一个对象上调用函数并省略了括号， Dart 称之为 `”tear-off”` ：一个和函数使用同样参数的闭包，当调用闭包的时候会执行其中的函数，比如：`names.forEach(print);` 等同于 `names.forEach((name){print(name);});`

那么编译后的 `getToString` 方法会是怎么样的？

如下图所示，可以看到 `getToString` 方法在编译后成了一个 `static` 的静态方法，并且 `ToStringFn` 也没有实际参与运行，也是被替换成了对应的 `()-> core:String` 。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image7)


**所以对于编译后的代码，`typedef` 并不会对性能和运行结果产生影响。**


## extension

在 Dart 里，通过 `extension` 可以很便捷地为对象进行拓展，**那 `extension` 关键字是如何在原对象基础上实现拓展呢？**


如下图所示，我们声明了一个 `Cat` 的枚举，并且对 `Cat` 进行了拓展，从而为枚举的每个值赋值，并且加了 `talk` 方法。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image8)



如下图所示，**编译后 `Cat` 里的枚举值对应变成了一个 `static final` 的固定地址**，并且 `CatExtension` 里的 `talk` 和 `value` 也被指向了新的位置。 


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image9)

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image10)

找到对应的实现处发现，**`CatExtension` 里的 `name` 和 `talk` 都变了所在文件下的 `static method`** ，并且 `talk` 方法是先定义了 `method` 实现，之后再通过 `tearoff` 的 `get` 实现去调用，**基本上所有在 `extension` 里定义的方法都会有对应的  `method` 和 `tearoff`。**

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image11)

如下图所示，在 `Cat` 的使用处，编译后可以看到  `cat.talk()` 其实就是执行了 `main::CatExtension|talk` 。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image12)
![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image13)


## async / await

最后聊聊  `async / await` ，我们都知道这是 Dart 里 `Future` 的语法糖，那这个语法糖在编译后是如何运行的呢？

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image14)


可以看到，`loadmore` 方法在编译后被添加了很多的代码，其中定义了一个 `_Future<void> async_future` 并在最后返回，同时我们需要执行的代码被包装到 `async_op` 里去执行，而这里有一个很关键的地方就是，**`async_op` 对执行的内容进行了 `try catch` 的操作，并通过 `_completeOnAsyncError` 返回**。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image15)

**这也是为什么我们在外部对一个 `Future` 进行 `try catch` 不能捕获异常的原因**，所以如下图所示，对于  `Future` 需要通过 `.onError((error, stackTrace) => null)` 的方式来对异常进行捕获处理。

![](http://img.cdn.guoshuyu.cn/20211223_Flutter-SU/image16)

明白了这些关键字背后的实现后，相信可以更好地帮助你在 Flutter 的日常开发中更优雅地组织你的代码，从而避免很多不必须要的问题。

**当然，如果用不上，拿去面试“装X”其实也挺不错的不是么？**