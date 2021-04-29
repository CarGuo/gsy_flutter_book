谷歌大会之后，有不少人咨询了我 **Flutter** 相关的问题，其中有不少是和面试相关的，如今一些招聘上也开始罗列 **Flutter** 相关要求，最后想了想还是写一期总结吧，也算是  **Flutter**  的阶段复习。

```
⚠️系统完整的学习是必须需要的，这里只能帮你总结一些知识点，更多的还请查阅 Dart/Flutter 官网。
```

本篇主要是知识点总结，如有疑问可点击各文章链接了解详情，或者查阅我 [掘金专栏](https://juejin.im/user/582aca2ba22b9d006b59ae68/posts)。


## Dart 部分

其实学习过 `JavaScript` 或者 `Java/Kotlin` 的人，在学习 `Dart` 上几乎是没什么难度的，**Dart 综合了动态语言和静态语言的特性,** 这里主要提供一些不一样，或者有意思的概念。


- 1、`Dart` 属于是**强类型语言** ，但可以用 `var`  来声明变量，`Dart` 会**自推导出数据类型**，`var` 实际上是编译期的“语法糖”。**`dynamic` 表示动态类型**， 被编译后，实际是一个 `object` 类型，在编译期间不进行任何的类型检查，而是在运行期进行类型检查。


- 2、`Dart` 中 `if` 等语句只支持 `bool` 类型，`switch` 支持 String 类型。

- 3、`Dart` 中**数组和 `List` 是一样的。**

- 4、`Dart` 中，**`Runes` 代表符号文字** ,  是 UTF-32 编码的字符串, 用于如 ` Runes input = new Runes('\u{1f596}  \u{1f44d}');`

- 5、**`Dart` 支持闭包。**

- 6、`Dart` 中 number 类型分为 **int 和 double ，没有 float 类型。**

- 7、`Dart` 中 **级联操作符** 可以方便配置逻辑，如下代码：

```
event
  ..id = 1
  ..type = ""
  ..actor = "";
```

- 8、赋值操作符

比较有意思的赋值操作符有：

```
AA ?? "999"  ///表示如果 AA 为空，返回999
AA ??= "999" ///表示如果 AA 为空，给 AA 设置成 999
AA ~/999 ///AA 对于 999 整除
```

- 9、可选方法参数

`Dart` 方法可以设置 **参数默认值** 和 **指定名称** 。

比如： `getDetail(Sting userName, reposName, {branch = "master"}){}` 方法，这里 branch 不设置的话，默认是 “master” 。参数类型 可以指定或者不指定。调用效果： `getRepositoryDetailDao(“aaa", "bbbb", branch: "dev");` 。


- 10、作用域

**`Dart` 没有关键词 `public` 、`private` 等修饰符，`_` 下横向直接代表 `private` ，但是有 `@protected` 注解 。**

- 11、构造方法

`Dart` 中的多构造方法，可以通过命名方法实现。

默认构造方法只能有一个，而通过 `Model.empty()` 方法可以创建一个空参数的类，其实方法名称随你喜欢，而变量初始化值时，只需要通过 `this.name` 在构造方法中指定即可：

```
class ModelA {
  String name;
  String tag;
  
  //默认构造方法，赋值给name和tag
  ModelA(this.name, this.tag);

  //返回一个空的ModelA
  ModelA.empty();
  
  //返回一个设置了name的ModelA
  ModelA.forName(this.name);
}
```

- 12、getter setter 重写

`Dart` 中所有的基础类型、类等都继承 `Object` ，默认值是 `NULL`， 自带 `getter` 和 `setter` ，而如果是 `final` 或者 `const` 的话，那么它只有一个 `getter` 方法，`Object`  都支持 getter、setter 重写：

```
  @override
  Size get preferredSize {
    return Size.fromHeight(kTabHeight + indicatorWeight);
  }
```

- 13、Assert(断言)

`assert` 只在检查模式有效，在开发过程中，` assert(unicorn == null);` 只有条件为真才正常，否则直接抛出异常，一般用在开发过程中，某些地方不应该出现什么状态的判断。

- 14、重写运算符，如下所示重载 `operator` 后对类进行 +/- 操作。


```
class Vector {
  final int x, y;

  Vector(this.x, this.y);

  Vector operator +(Vector v) => Vector(x + v.x, y + v.y);
  Vector operator -(Vector v) => Vector(x - v.x, y - v.y);
  
  ···
}

void main() {
  final v = Vector(2, 3);
  final w = Vector(2, 2);

  assert(v + w == Vector(4, 5));
  assert(v - w == Vector(0, 1));
}
```

支持重载的操作符 ：

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-msjj/image1)



-  类、接口、继承

`Dart` 中没有接口，类都可以作为接口，把某个类当做接口实现时，只需要使用 `implements` ，然后复写父类方法即可。

`Dart` 中支持 `mixins` ，按照出现顺序应该为` extends` 、 `mixins` 、`implements` 。

- ### Zone

`Dart` 中可通过 `Zone` 表示指定代码执行的环境，类似一个沙盒概念，在 `Flutter` 中 **C++** 运行 `Dart` 也是在 `_runMainZoned` 内执行 `runZoned` 方法启动，而我们也可以通过 `Zone` ，在运行环境内捕获全局异常等信息:

```
  runZoned(() {
    runApp(FlutterReduxApp());
  }, onError: (Object obj, StackTrace stack) {
    print(obj);
    print(stack);
  });
```

同时你可以给 `runZoned` 注册方法，在需要时执行回调，如下代码所示，这样的在一个 `Zone` 内任何地方，只要能获取 `onData` 这个 `ZoneUnaryCallback`，就都可以调用到 `handleData`

```
///最终需要处理的地方
handleData(result) {
  print("VVVVVVVVVVVVVVVVVVVVVVVVVVV");
  print(result);
}

///返回得到一个 ZoneUnaryCallback 
var onData = Zone.current.registerUnaryCallback<dynamic, int>(handleData);

///执行 ZoneUnaryCallback 返回数据
Zone.current.runUnary(onData, 2);

```

异步逻辑可以通过 `scheduleMicrotask` 可以插入异步执行方法：

```
Zone.current.scheduleMicrotask((){
  //todo something
});
```
更多可参看 ：[《Flutter完整开发实战详解(十一、全面深入理解Stream)》](https://juejin.im/post/5cc2acf86fb9a0321f042041)


- ### Future

`Future` 简单了说就是对 `Zone` 的封装使用。

比如 `Future.microtask` 中主要是执行了 `Zone` 的 `scheduleMicrotask` ，而 `result._complete` 最后调用的是 `_zone.runUnary` 等等。

```
  factory Future.microtask(FutureOr<T> computation()) {
    _Future<T> result = new _Future<T>();
    scheduleMicrotask(() {
      try {
        result._complete(computation());
      } catch (e, s) {
        _completeWithErrorCallback(result, e, s);
      }
    });
    return result;
  }

```

**`Dart` 中可通过 `async`/`await` 或者 `Future` 定义异步操作，而事实上 `async`/`await` 也只是语法糖，最终还是通过编译器转为 `Future`。**


> 有兴趣看这里 ：
>
> [generators](https://dart.dev/guides/language/language-tour#generators)
>
> [code_generator.dart](https://github.com/dart-lang/sdk/blob/master/pkg/dev_compiler/lib/src/analyzer/code_generator.dart) 
>
> [Flutter完整开发实战详解(十一、全面深入理解Stream)](https://juejin.im/post/5cc2acf86fb9a0321f042041)

- ### Stream

`Stream` 也是有对`Zone` 的另外一种封装使用。

**Dart 中另外一种异步操作， `async*` / `yield` 或者 `Stream` 可定义 `Stream` 异步，  `async*` / `yield` 也只是语法糖，最终还是通过编译器转为 `Stream`。**
**Stream 还支持同步操作。**

1）、`Stream` 中主要有 `Stream` 、 `StreamController` 、`StreamSink` 和 `StreamSubscription` 四个关键对象，大致可以总结为：

- **`StreamController`** ：如类名描述，用于整个  `Stream` 过程的控制，提供各类接口用于创建各种事件流。

- **`StreamSink`** ：一般作为事件的入口，提供如 `add`   ，   `addStream`   等。

- **` Stream`** ：事件源本身，一般可用于监听事件或者对事件进行转换，如 `listen` 、`where` 。

- **`StreamSubscription`** ：事件订阅后的对象，表面上用于管理订阅过等各类操作，如 `cacenl` 、`pause` ，同时在内部也是事件的中转关键。

2)、**一般通过 `StreamController` 创建 `Stream`；通过 `StreamSink` 添加事件；通过 `Stream` 监听事件；通过 `StreamSubscription` 管理订阅。**

3）、`Stream` 中支持各种变化，比如`map` 、`expand` 、`where` 、`take` 等操作，同时支持转换为 `Future` 。


更多可参看 ：[《Flutter完整开发实战详解(十一、全面深入理解Stream)》](https://juejin.im/post/5cc2acf86fb9a0321f042041)


## Flutter 部分

Flutter 和 React Native 不同主要在于 **Flutter UI是直接通过 skia 渲染的 ，而 React Native 是将 js 中的控件转化为原生控件，通过原生去渲染的**  ，相关更多可查看：[《移动端跨平台开发的深度解析》](https://juejin.im/post/5b395eb96fb9a00e556123ef)。

- Flutter 中存在 `Widget` 、 `Element` 、`RenderObject` 、`Layer` 四棵树，其中 **`Widget` 与 `Element` 是一对多的关系** ，

- `Element`  中持有`Widget` 和 `RenderObject` ， 而 **`Element` 与 `RenderObject` 是一一对应的关系（除去 `Element`  不存在 `RenderObject` 的情况，如 `ComponentElement` 是不具备 `RenderObject`)** ，

- 当 `RenderObject` 的 `isRepaintBoundary` 为 `true` 时，那么个区域形成一个 `Layer`，所以**不是每个 `RenderObject` 都具有 `Layer` 的，因为这受 `isRepaintBoundary` 的影响。** 

> 更多相关可查阅 [《Flutter完整开发实战详解(九、 深入绘制原理)》](https://juejin.im/post/5ca0e0aff265da309728659a)

- Flutter 中 `Widget` 不可变，每次保持在一帧，如果**发生改变是通过 `State` 实现跨帧状态保存**，而**真实完成布局和绘制数组的是 `RenderObject` ，**  `Element` 充当两者的桥梁， **`State` 就是保存在 `Element` 中。**


- **Flutter 中的 `BuildContext` 只是接口，而  `Element`  实现了它。**

- Flutter 中 **`setState`  其实是调用了 `markNeedsBuild`**  ，该方法内部**标记此`Element ` 为 `Dirty`** ，然后在下一帧 `WidgetsBinding.drawFrame` 才会被绘制，这可以看出 **`setState` 并不是立即生效的。**

- Flutter 中 `RenderObject` 在 `attch`/`layout` 之后会通过 `markNeedsPaint();`  使得页面重绘，流程大概如下：

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-msjj/image2)

**通过isRepaintBoundary 往上确定了更新区域，通过 requestVisualUpdate 方法触发更新往下绘制。**

- 正常情况 `RenderObject ` 的布局相关方法调用顺序是 ： **`layout` ->  `performResize` -> `performLayout` -> `markNeedsPaint` ,**  但是用户一般不会直接调用  `layout`，而是**通过  `markNeedsLayout`** ，具体流程如下：

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-msjj/image3)


- Flutter 中一般 **json** 数据从 `String` 转为 `Object` 的过程中都需要先经过 `Map` 类型。

- Flutter 中 `InheritedWidget` 一般用于**状态共享**，如`Theme` 、`Localizations` 、 `MediaQuery` 等，都是通过它实现共享状态，这样我们可以通过 `context` 去获取共享的状态，比如 `ThemeData theme = Theme.of(context);`

> 在 `Element` 的 `inheritFromWidgetOfExactType` 方法实现里，有一个 `Map<Type, InheritedElement> _inheritedWidgets` 的对象。
>
>`_inheritedWidgets` 一般情况下是空的，只有当父控件是 `InheritedWidget` 或者本身是 `InheritedWidgets` 时才会有被初始化，而当父控件是 `InheritedWidget`  时，这个 `Map` 会被一级一级往下传递与合并 。
>
> 所以当我们通过 `context` 调用 `inheritFromWidgetOfExactType` 时，就可以往上查找到父控件的 `Widget` 。

- Flutter 中默认主要通过 **`runtimeType` 和 `key`** 判断更新：

```
static bool canUpdate(Widget oldWidget, Widget newWidget) {
    return oldWidget.runtimeType == newWidget.runtimeType
        && oldWidget.key == newWidget.key;
  }
}
```

### Flutter 中的生命周期

- **`initState()`** 表示当前 `State` 将和一个 `BuildContext` 产生关联，但是此时`BuildContext` 没有完全装载完成，如果你需要在该方法中获取 `BuildContext` ，可以 `new Future.delayed(const Duration(seconds: 0, (){//context});` 一下。

-  **`didChangeDependencies()`** 在 `initState()` 之后调用，当 `State` 对象的依赖关系发生变化时，该方法被调用，初始化时也会调用。

-  **`deactivate()`** 当 `State` 被暂时从视图树中移除时，会调用这个方法，同时页面切换时，也会调用。

-  **`dispose()`**  Widget 销毁了，在调用这个方法之前，总会先调用 deactivate()。

-  **`didUpdateWidge`** 当  `widget` 状态发生变化时，会调用。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-msjj/image4)

------


- 通过 `StreamBuilder` 和 `FutureBuilder` 我们可以快速使用 `Stream` 和 `Future` 快速构建我们的异步控件:  [《Flutter完整开发实战详解(十一、全面深入理解Stream)》](https://juejin.im/post/5cc2acf86fb9a0321f042041)


- Flutter 中 `runApp` 启动入口其实是一个 `WidgetsFlutterBinding` ，它主要是通过 `BindingBase` 的子类 `GestureBinding`  、`ServicesBinding`  、 `SchedulerBinding`  、`PaintingBinding`  、`SemanticsBinding`  、 `RendererBinding`  、`WidgetsBinding` 等，通过 `mixins` 的组合而成的。

- Flutter 中的 Dart 的线程是以**事件循环和消息队列**的形式存在，包含两个任务队列，**一个是 microtask 内部队列，一个是 event 外部队列，而 microtask 的优先级又高于 event 。**

> 因为 microtask 的优先级又高于 event， 同时会阻塞event 队列，所以如果 microtask 太多就可能会对触摸、绘制等外部事件造成阻塞卡顿哦。

- Flutter 中存在**四大线程，分别为 `UI Runner`、`GPU Runner`、`IO Runner`， `Platform Runner` （原生主线程）** ，同时在 Flutter 中可以通过 `isolate` 或者 `compute` 执行真正的跨线程异步操作。


### PlatformView

Flutter 中通过 `PlatformView` 可以嵌套原生 `View` 到 `Flutter` UI 中，这里面其实是使用了 `Presentation` + `VirtualDisplay` + `Surface` 等实现的，大致原理就是：

使用了类似副屏显示的技术，`VirtualDisplay` 类代表一个虚拟显示器，调用 `DisplayManager` 的 `createVirtualDisplay()` 方法，将虚拟显示器的内容渲染在一个 `Surface` 控件上，然后将 `Surface` 的 id 通知给 Dart，让 engine 绘制时，在内存中找到对应的 `Surface` 画面内存数据，然后绘制出来。em...  **实时控件截图渲染显示技术。**

-----

- **Flutter 的 Debug 下是 JIT 模式，release下是AOT模式。**

- Flutter 中可以通过 `mixins AutomaticKeepAliveClientMixin`  ，然后重写 `wantKeepAlive` 保持住页面，记得在被保持住的页面 `build` 中调用 `super.build` 。（因为 mixins 特性）。


- **Flutter 手势事件主要是通过竞技判断的：**

主要有 `hitTest` 把所有需要处理的控件对应的 `RenderObject` ， 从  `child` 到 `parent` 全部组合成列表，从最里面一直添加到最外层。

然后从队列头的 child 开始 for 循环执行 `handleEvent ` 方法，执行 `handleEvent` 的过程不会被拦截打断。

一般情况下 Down 事件不会决出胜利者，大部分时候是在 MOVE 或者 UP 的时候才会决出胜利者。

**竞技场关闭时只有一个的就直接胜出响应，没有胜利者就拿排在队列第一个强制胜利响应。**

同时还有 `didExceedDeadline` 处理按住时的 Down 事件额外处理，同时手势处理一般在 `GestureRecognizer` 的子类进行。

> 更多详细请查看：[《Flutter完整开发实战详解(十三、全面深入触摸和滑动原理)》](https://juejin.im/post/5cd54839f265da03b2044c32)


- Flutter 中 `ListView` 滑动其实都是通过改变 `ViewPort` 中的 `child` 布局来实现显示的。


- 常用状态管理的：目前有 `scope_model` 、` flutter_redux` 、`fish_redux` 、`bloc + Stream` 等几种模式，具体可见 : [《Flutter完整开发实战详解(十二、全面深入理解状态管理设计)》](https://juejin.im/post/5cc816866fb9a03231209c7c)

### Platform Channel

Flutter 中可以通过 `Platform Channel` 让 Dart 代码和原生代码通信的：

> - `BasicMessageChannel` ：用于传递字符串和半结构化的信息。
> - `MethodChannel` ：用于传递方法调用（method invocation）。
> - `EventChanne` l: 用于数据流（event streams）的通信。

**同时 `Platform Channel` 并非是线程安全的** ，更多详细可查阅闲鱼技术的 [《深入理解Flutter Platform Channel》](https://www.jianshu.com/p/39575a90e820)

其中基础数据类型映射如下：

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-msjj/image5)

-------


### Android 启动页

Android 中 `Flutter` 默认启动时会在 `FlutterActivityDelegate.java ` 中读取 AndroidManifset.xml 内 `meta-data` 标签，其中 `io.flutter.app.android.SplashScreenUntilFirstFrame` 标志位如果为 ture ，就会启动 Splash 画面效果（类似IOS的启动页面）。

启动时原生代码会读取 `android.R.attr.windowBackground`  得到指定的 `Drawable` ， 用于显示启动闪屏效果，之后并且通过 `flutterView.addFirstFrameListener`，在`onFirstFrame` 中移除闪屏。

> 好了，暂时都这里了，有问题修改会或则补充的，后面再加上。

### 资源推荐

* Github ： [https://github.com/CarGuo/](https://github.com/CarGuo)
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**

##### 完整开源项目推荐：

* [GSYGithubApp Flutter](https://github.com/CarGuo/GSYGithubAppFlutter ) 
* [GSYGithubApp React Native](https://github.com/CarGuo/GSYGithubApp ) 
* [GSYGithubAppWeex](https://github.com/CarGuo/GSYGithubAppWeex)

##### 文章

[《Flutter完整开发实战详解(一、Dart语言和Flutter基础)》](https://juejin.im/post/5b631d326fb9a04fce524db2)

[《Flutter完整开发实战详解(二、 快速开发实战篇)》](https://juejin.im/post/5b685a2a5188251ac22b71c0)

[《Flutter完整开发实战详解(三、 打包与填坑篇)》](https://juejin.im/post/5b6fd4dc6fb9a0099e711162)

[《Flutter完整开发实战详解(四、Redux、主题、国际化)》](https://juejin.im/post/5b79767ff265da435450a873)

[《Flutter完整开发实战详解(五、 深入探索)》](https://juejin.im/post/5bc450dff265da0a951f032b)

[《Flutter完整开发实战详解(六、 深入Widget原理)》](https://juejin.im/post/5c7e853151882549664b0543)

[《Flutter完整开发实战详解(七、 深入布局原理)》](https://juejin.im/post/5c8c6ef7e51d450ba7233f51)

[《Flutter完整开发实战详解(八、 实用技巧与填坑)》](https://juejin.im/post/5c9e328251882567b91e1cfb)

[《Flutter完整开发实战详解(九、 深入绘制原理)》](https://juejin.im/post/5ca0e0aff265da309728659a)

[《Flutter完整开发实战详解(十、 深入图片加载流程)》](https://juejin.im/post/5cb1896ce51d456e63760449)

[《Flutter完整开发实战详解(十一、全面深入理解Stream)》](https://juejin.im/post/5cc2acf86fb9a0321f042041)

[《Flutter完整开发实战详解(十二、全面深入理解状态管理设计)》](https://juejin.im/post/5cc816866fb9a03231209c7c)

[《Flutter完整开发实战详解(十三、全面深入触摸和滑动原理)》](https://juejin.im/post/5cd54839f265da03b2044c32)

[《跨平台项目开源项目推荐》](https://juejin.im/post/5b6064a0f265da0f8b2fc89d)

[《移动端跨平台开发的深度解析》](https://juejin.im/post/5b395eb96fb9a00e556123ef)

![我们还会再见吗？](http://img.cdn.guoshuyu.cn/20190604_Flutter-msjj/image6)