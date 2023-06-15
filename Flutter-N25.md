# Flutter 小技巧之 3.10 全新的  MediaQuery 优化与 InheritedModel 

关于 `MediaQuery` 我们介绍过不少，比如在之前的[《MediaQuery 和 build 优化你不知道的秘密》](https://juejin.cn/post/7114098725600903175)里就介绍过，**要慎重在 `Scaffold` 之外使用 `MediaQuery.of(context)`** ，这是因为  `MediaQuery.of`  对  `BuildContext` 的绑定可能会导致一些不必要的性能开销，例如键盘弹起时，会导致相关的  `MediaQuery.of(context)` 绑定的页面出现重构。

比如下面这个例子，我们在 `MyHomePage` 里使用了 `MediaQuery.of(context).size` 并打印输出，然后跳转到 `EditPage` 页面，弹出键盘 ，这时候会发生什么情况？

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

如下图 log 所示 ， 可以看到在键盘弹起来的过程，因为 bottom 发生改变，所以 `MediaQueryData` 发生了改变，从而导致上一级的 `MyHomePage` 虽然不可见，但是在键盘弹起的过程里也被不断 build 。

![](http://img.cdn.guoshuyu.cn/20230602_N25/image1.png)

虽然在之前的[小技巧](https://juejin.cn/post/7114098725600903175)里我们介绍了解决方式，但是 3.10 开始有更优雅的做法，同时也更方便我们自足控制更细的颗粒度地去管理  `InheritedWidget`  里的绑定关系，那就是使用 `InheritedModel` 。



# MediaQuery

在 3.10 里 `MediaQuery` 增加了需要针对特定参数的 `****of` 方式，例如 `MediaQuery.platformBrightnessOf(context);` ，这些方法对应在 `_MediaQueryAspect`  里都有一个枚举类型，而在 Flutter Framework 里，这些参数的调用都修改成了新的  `****of` 类型方法。

![](http://img.cdn.guoshuyu.cn/20230602_N25/image2.png)

例如一开始的例子，只需要将 `MediaQuery.of(context).size` 修改为 `MediaQuery.sizeOf(context)` ，那么跳转到 `EditPage` 页面，弹出键盘 ，在键盘弹起来的过程中不会再导致  `MyHomePage`  rebuild 输出 log。

而之所以会这样的原因，其实是因为这些 `MediaQuery.******Of(context);` 内部调用的是 `InheritedModel.inheritFrom` 实现。

是的，3.10 开始  [`MediaQuery` 继承从 `InheritedWidget` 变成  `InheritedModel`](https://github.com/flutter/flutter/commit/73cb7c2fc5ecab0476ef5d41d1227ed09f73db56) ，而    **`InheritedModel` 的  `inheritFrom` 方法可以让开发者可以通过  `aspect` 来决定数据改变时是否调用对应更新**。

![](http://img.cdn.guoshuyu.cn/20230602_N25/image3.png)

![](http://img.cdn.guoshuyu.cn/20230602_N25/image4.png)

> 小技巧一：**3.10 现在可以通过将  `MediaQuery.of`  获取参数的方式替换成   `MediaQuery.******Of(context);`  来减少不必要的 rebuild** 。



# InheritedModel

使用  `InheritedModel`  只需要继承它就可以，之后**需要重点关注的是  `updateShouldNotifyDependent`  方法，它用于决定应该什么时候 rebuild** 。

如下图所示是 `MediaQuery` 的实现，在  `updateShouldNotifyDependent`   里我们可以通过 `dependencies` 里的类型来进行区分，比如调用时是通过  `InheritedModel.inheritFrom<MediaQuery>(context, aspect: _MediaQueryAspect.size)`  输入，那么判断时就会进入到   `_MediaQueryAspect. size` 这个 ` case` 。

![](http://img.cdn.guoshuyu.cn/20230602_N25/image5.png)

如果此时 `size`  参数发生了改变，就返回 `true` ，从而产生 rebuild，反之返回放 false，这就是  `InheritedModel` 可以根据绑定具体变量来更新页面的原因。

> 当然这里你不一定要传枚举，你喜欢的话传 String 也可以，具体可以根据你的爱好来设定。

那为什么 `InheritedModel`  的 `inheritFrom`   方法可以达到这样的效果？

我们简单看一下  `inheritFrom`  的源码实现，如下图所示：

- 在没有  `aspect` 的时候直接调用 `dependOnInheritedWidgetOfExactType()`   那就是和之前普通的 `of(context)` 没什么区别
- 在有  `aspect` 的时候，会先通过  `_findModels`  找到对应的 `InheritedElement` ，然后调用  `dependOnInheritedElement()`  绑定

![](http://img.cdn.guoshuyu.cn/20230602_N25/image6.png)

可能这时候你有些疑问，不要急慢慢来，我们先看  `dependOnInheritedWidgetOfExactType()`   和   `dependOnInheritedElement()`  ， 其实  `dependOnInheritedWidgetOfExactType()`   内部也是调用  `dependOnInheritedElement()`   来完成绑定，那么这里前后的区别是什么？

如果你仔细看，**这里的区别在于 `dependOnInheritedElement()`  多使用了 `aspect`** ，对应到 `MediaQuery` 里就是如 `_MediaQueryAspect.size` 这个 `aspect`  ，这样在后续  `updateShouldNotifyDependent` 时就会被用上。

如下图所示是   `InheritedModel`   的  `InheritedModelElement`  ，可以看到 **`inheritFrom`  传入的  `aspect` 会变成  `dependencies`** ，而这个` dependencies` 就是我们在  `updateShouldNotifyDependent`    里用来判断的类型依据。

![](http://img.cdn.guoshuyu.cn/20230602_N25/image7.png)

最后，在  `notifyDependent`  方法里可以看到，只有   `updateShouldNotifyDependent`   返回 `true` 时，才会调用 `didChangeDependencies` 去更新。

所以   `inheritFrom`   的特殊之处在于：**当存在 `aspect` 时，该 `aspect` 会变成  `dependencies` 集合，然后通过    `updateShouldNotifyDependent`    来决定是否触发更新**。

至于 `_findModels`  方法其实你无需纠结，虽然它是传入一个 List，但是一般情况下你只会获取到一个。什么时候会可能有多个，就是你 override 了  `InheritedModel`   的  `isSupportedAspect` 方法，并且会根据  `aspect` 条件有不同判断返回时可能会有多个。

![](http://img.cdn.guoshuyu.cn/20230602_N25/image8.png)

例如都是继承 `InheritedModel` ，但是  `isSupportedAspect` 可以根据条件来决定你这个实例是否支持 `Aspect` 绑定。

```dart
  @override
  bool isSupportedAspect(Object aspect) {
    return aspects == null || aspects!.contains(aspect);
  }
```

另外  `_findModels`   里用的是 `getElementForInheritedWidgetOfExactType()`，它和 `dependOnInheritedWidgetOfExactType()`  的区别就是前者会注册依赖关系，而后者不会，所以  `_findModels`    顾名思义只是找出符合条件的   `InheritedModel` 。

![](http://img.cdn.guoshuyu.cn/20230602_N25/image9.png)

# 最后

最后总结一下，今天的小技巧其实很简单，**就是更新你的 `MediaQuery.of` 到对应参数的 `MediaQuery.*****of` 从而提升应用性能**，并且了解到  `InheritedModel` 的实现逻辑和自定义支持，从而学会优化你现在的 `InheritedWidget ` 的使用。

如果你还有什么问题，欢迎留言评论交流。