大家好，我是郭树煜，Github GSY 系列开源项目的作者，系列包括有 GSYVideoPlayer 、GSYGitGithubApp(Flutter\ReactNative\Kotlin\Weex)四大版本，目前总 star 在 17
k+ 左右，主要活跃在掘金社区，id 是恋猫的小郭，主要专栏有《Flutter完整开发实战详解》系列等，平时工作负责移动端项目的开发，工作经历从 Android 到 React Native 、Weex 再到如今的 Flutter ，期间也参与过 React 、 Vue 、小程序等相关的开发，算是一个大前端的选手吧。

> 这次主要是给大家分享 Flutter 相关的内容，主要涉及做一些实战和科普性质的内容。


![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image1)

## 一、移动开发的现状

恰逢最近谷歌 IO 大会结束，大会后也在线上线下和大家有过交流，总结了下大家最关系的问题有：

### 1、谷歌在 Kotlin-First 的口号下又推广 Dart + Flutter 冲突吗？

这个问题算是被问得最多的一个，先说观点：我个人认为其实这并不冲突，因为有个 **误区就是认为跨平台开发就可以抛弃原生开发！**

如果从事过跨平台开发的同学应该知道，平台提供的功能向来是有限的，而面对产品经理的各种 *“点歪技能树”* 的需求，很多时候你是需要基于框架外提供支持，常见的就是 **混合开发或者原生插件支持** 。

所以这里我表达的是，目前 **`Kotlin` 和 `Dart` 更多是相辅相成**  ，而一旦业务复杂度到一定程度，跨平台框架还可能存在降低工作效率的问题，比如针对新需求，需要重复开发 `Android/IOS` 的原生插件做支持，这也是 Aribnb 曾经选择放弃 `React Native` 的原因之一。

与我而言，**跨平台的意义在于解决的是端逻辑的统一** ，至少避免了逻辑重复实现，或者 `IOS` 和 `Android` 之间争论 *谁对谁错* 的问题，甚至可以统一到 web 端等等。


![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image2)


### 2、React Native 和 Flutter 之间的对比

`Flutter` 作为后来者，难免会被用来和 `React Native` 进行对比，在这个万物皆是 `JS` 的时代，`Dart` 和 `Flutter` 的出现显得尤为扎眼。

在设计上它们有着许多相似之处，*响应式设计/async支持/setState更新* 等等，同时也有着各种的差异，而大家最为关心的，无非 **性能、支持、上手难易、稳定性程度** 这四方面：

- **性能上 Flutter 的确实会比 React Native 好** ，如下图所示，这是由框架底层决定的，当然目前 `React Native` 也在进行下一代的优化， 而对此最直观的数据就是：**GSY系列 在18年用于闲鱼测试下的对比数据了** 。

![image10.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image3)

![image11.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image4)

> 同时注意不要用模拟器测试性能，特别是IOS模拟器做性能测试，因为 Flutter 在 IOS模拟器中纯 CPU ，而实际设备会是 GPU 硬件加速，同时只在 Release 下对比性能。

- 支持上 Flutter 和 React Native ， 都存在第三方包质量参差不齐的问题，而目前在这一块 **Flutter 是弱于 React Native 的** ，毕竟 `React Native` 发展已久，虽然版本号一直不到 1.0，但是在 `JS` 的加持下生态丰富，同时也是因为平台特性的原因，诸如 WebView 、地图等控件的支持上现在依旧不够好，这个后面也会说道。

- 上手难易度上，**`Flutter` 配置环境和运行的“成功率”比 React Native 高不少** ，这里面有 `node_module` 黑洞这个坑，也有 `React Native` 本身依赖平台控件导致的，至少我曾经试过接手一个  `React Native` 跑了一天都没跑起来的经历，同时 `Flutter` 在运行和SDK版本升级的阵痛也会少很多。

- 稳定性：**`Flutter` 中大部分异常是不会引起应用崩溃** ，更多会在 Debug 上体现为红色错误堆栈，Release 上 UI 异常等等。

> **如果你是前端，我会推荐你先学 `React Native`，如果你是原生开发，我推荐你学 `Flutter` 。**
>
> 在 React Native 0.59.x 版本开始，React 已经将许多内置控件和库移出主项目，希望模糊 React 和 React Native 的界线，统一开发，这里的理念和 Flutter 很像。
>
> Flutter 暂时不支持热更新！！！！！！！！



## 二、Flutter 实战

### 1、Dart 中有意思的一些东西

#### 1.1、var 的语法糖和 dynamic 

`var` 的语法糖是在赋值时才**自推导出类型的** ，而 `dynamic` 是动态声明，在运行时检测，它们的使用有时候容易出现错误。

如下图所以说，
- `var` 初始化时被指定为 `dynamic` 类型的。
- 然后赋值的时候初始化为 `String` 类型，这时候进行 ++ 操作就会出现运行时报错，
- 如下图2如果在初始化指定类型的，那么编译时就会告诉你错误了。

![图1](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image5)

![图2](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image6)


#### 1.2、各类操作符

如下图所示，`Dart` 支持很多有意思的操作符，如下图：
- 执行的时候首先是判断 `AA` 如果为空，就返回 `999` ；
- 之后如果 `AA` 为空，就为 `AA` 赋值 `999`；
- 之后对 `AA` 进行整除 `999` ，输出结果 `10` 。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image7)


#### 1.3、支持操作符重载

如下图所示，`Dart` 中是支持操作符重载的，这样可以比较直观我们的代码逻辑，并且简化代码时的调用。

![image15.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image8)

#### 1.4、方法当做参数传递

如下图所示，在 `Dart` 中方法时可以作为参数传递的，这样的形式可以让我们更灵活的组织代码的逻辑。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image9)

#### 1.5、async await / async* yield

在 `Dart` 中 `async await / async* yield` 等语法糖，代表 `Dart` 中的 `Future` 和 `Stream` 操作，它们对应 `Dart` 中的异步逻辑支持。

> sync* / yield  对应 `Stream`  的同步操作。

#### 1.6、Mixins

在 `Dart` 中支持混入的模式，如下图所示，混入时的基础顺序是从右到左依次执行的，而且和 `super` 有关，同时 `Dart`  还支持 `mixin` 关键字的定义。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image10)

> Flutter 的启动类用的就是 mixins 方式

#### 1.7、isolate

`Dart` 中单线程模式中增加了 `isolate` 提供跨线程的真异步操作，而因为 `Dart` 中线程不会共享内存，所以也不存在死锁，从而也导致了 `isolate` 之间数据只能通过 `port` 的端口方式发送接口，类似于 `Scoket` 的方式，同时提供了 `compute` 的封装接口方便调用。


#### 1.8 call

Dart 为了让类可以像函数一样调用，默认都可以实现 `call()` 方法，同样 `typedef` 定义的方法也是具备 `call()` 条件。

比如我定义了一个 `CallObject` 


```
class CallObject {

  List<Widget> footerButton = [];

  call(int i, double e) => "$i xxxx $e";
}

```

就可以通过以下执行


```
CallObject callObject = CallObject();
print(callObject(11, 11.0));
print(callObject?.call(11, 11.0));
```

然后我定义了 

```
typedef void ValueFunction(int i);

  ValueFunction vt = (int i){
    print("zzz $i");
  };

```

就可以通过直接执行和判空执行处理


```
 vt(666);
 vt?.call(777);

```




### 2、Flutter 中常见的

#### 2.1、ChangeNotifier

如下图所示，`ChangeNotifier` 模式在 `Flutter` 中是十分常见的，比如 `TextField` 控件中，通过 `TextEditingController` 可以快速设置值的显示，这是为什么呢？


![image18.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image11)


如下图所示，这是因为 `TextEditingController` 它是 `ChangeNotifier` 的子类，而 `TextField` 的内部对其进行了 `addListener`，同时我们改变值的时候调用了`notifyListener`，触发内部 `setState`。

![image19.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image12)

#### 2.2、InheritedWidget

在 `Flutter` 中所有的状态共享都是通过它实现的，如自带的 `Theme` ，`Localizations` ，或者状态管理的 `scoope_model` 、 `flutter_redux` 等等，都是基于它实现的。

如下图是 `SliderTheme` 的自定义实现逻辑，默认  `Theme`  中是包含了 `SliderTheme`，但是我们可以通过覆盖一个新的 `SliderTheme` 嵌套去实现自定义，然后通过 `SliderTheme theme = SliderTheme(context);` 获取，其中而 `context` 的实现就是 `Element`。


![image20.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image13)


在 `Element` 的 `inheritFromWidgetOfExactType` 方法实现里，有一个 `Map<Type, InheritedElement> _inheritedWidgets` 的对象。


`_inheritedWidgets` 一般情况下是空的，只有当父控件是 `InheritedWidget` 或者本身是 `InheritedWidgets` 时才会有被初始化，而当父控件是 `InheritedWidget`  时，这个 `Map` 会被一级一级往下传递与合并 。
所以当我们通过 `context` 调用 `inheritFromWidgetOfExactType` 时，就可以往上查找到父控件的 `Widget` 。


#### 2.3、StreamBuilder

`StreamBuilder` 一般用于通过 `Stream` 异步构建页面的，如下图所示，通过点击之后，绿色方框的文字会变成 `addNewxxx`，因为 `Stream` 进行了 `map` 变化，同时一般实现 `bloc` 模式的时候，经常会用到它们。

![image21.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image14)

> 类似的还有 FutureBuilder



#### 2.4、State 中的参数使用

一般 `Widget` 都是一帧的，而 `State` 实现了 `Widget` 的跨帧绘制，一般定义的时候，我们可以如下图一样实现，而如下图尖头所示，这时候我们点击 `setState` 改变的时候，是不会出现效果的，为什么呢？

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image15)

其实 State 对象的创建和更新时机导致的：

- 1、createState 只在 StatefulElement 创建时才会被创建的。

- 2、StatefulElement 的 createElement 一般只在 inflateWidget 调用。

- 3、updateChild 执行 inflateWidget 时， 如果 child 存在可以更新的话，不会执行 inflateWidget。


![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image16)

### 3、四棵树

Flutter 中主要有
`Widget` 、`Element` 、`RenderObject` 、`Layer` 四棵树，它们的作用是：

- **`Widget`** ：就是我们平常写的控件，`Flutter` 宇宙中万物皆 `Widget` ，它们都是不可变一帧，同时也是被人吐槽很多的嵌套模式，当然换个角度，事实上你把他当作 `Widget` 配置文件来写或者就好理解了。

- **`Element`** ：它是 `BuildContext` 的实现类，`Widget` 实现跨帧保存的 `state` 就是存放在这里，同时它也充当了 `Widget` 和 `RenderObject` 之间的桥梁。

- **`RenderObject`** ：它才是真正干活（layout、paint）等，同时它才是真实的 “dom” 。

- **`Layer`** ：一整块的重绘区域（isRepaintBoundary），决定重绘的影响区域。


> `skia` 在绘制的时候，`saveLayer` 是比较消耗性能的，比如透明合成、`clipRRect` 等等都会可能需要 `saveLayer` 的调用， 而 `saveLayer` 会清空GPU绘制的缓存，导致性能上的损耗，所以开发过程中如果掉帧严重，可以针对这一块进行优化。


![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image17)


### 4、手势

`Flutter` 在手势中引入了竞技的概念, `Down` 事件在 `Flutter` 中尤为重要。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image18)


- `PointerDownEvent` 是一切的起源，在 `Down` 事件中一般不会决出胜利者。

- 在 `MOVE` 和 `UP` 的时候才竞争得到响应。

- 以点击为例子：`Down` 时添加进去参与竞争，`UP` 的时候才决定谁胜利，胜利条件是：

I、`UP` 的时候如果只有一个，那么就是它了。

II、`UP` 的时候如果有多个，那么强制队列里第一个直接胜利。


- 这里包含了有趣的点就是，**都在 `UP` 的时候才响应，那么 Down 事件怎么先传递出去了？**

**`FLutter` 在这里做了一个 `didExceedDeadline` 机制  ，事实上在上面的 `addPointer` 的时候，会启动了一个定时器，默认 100 ms，如果超过指定时间没 `UP` ，那就先执行这个 `didExceedDeadline` 响应 `Down` 事件。**

- 那问题又来了，如果这时候队列里两个呢?

**它们的 `onTapDown` 都会被触发，但是 `onTap` 只有一个获得。**

- 如果有两个滑动 `ScrollView` 嵌套呢？

举个简单的例子，两个 `SingleChildScrollView` 的嵌套时，在布局会经历：

> `performLayout` -> `applyContentDimensions` -> `applyNewDimensions` -> `context.setCanDrag(physics.shouldAcceptUserOffset(this));`

只有 `shouldAcceptUserOffset` 为 `ture` 时，才会添加 `VerticalDragGestureRecognizer` 去处理手势。

而判断条件主要是 `return math.max(0.0, child.size.height - size.height);` ，也就是**如果 child Scroll 的 height 小于父控件 Scroll 的时候，就会出现 child 不添加 VerticalDragGestureRecognizer 的情况，这时候根本就没有竞争了。**




### 5、动画

`Flutter` 中的动画是怎么执行的呢？

我们先看一段代码，然后这段代码执行的效果如下图2所示。

那既然 `Widget` 都是一帧，那么动画肯定有 `setState` 的地方了。

首先这里有个地方可以看下，这时候 200 这个数值执行后是会报错的，因为白框内可见 `Tween` 中的 `T` 在这时候会出现既有 `int` 又有 `double` ，无法判断的问题，所以真实应该是 200.0 。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image19)

![image28.GIF](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image20)


同时你发现没有，代码中 `parent` 的 `Container` 在 只有100的情况下，它的 `child` 可以正常的画 200，这是因为我们的 `paint` 没有跟着 `RenerObjcet` 的大小走， 所以一般情况下，整个屏幕都是我们的画版，**Canvas 绘制与父控件大小可以没关系。**


同时动画是通过 `vsync` 同步信号去触发的，就是我们 mixin 的 `SingleTickerProviderStateMixin`，它内部的 `Ticker`  会通过 `SchedulerBinding` 的 `scheduleFrameCallback` 同步信号触发重绘 。 

> 动画后的控件的点击区域，和你的动画数据改变的是 paint 还是 layout 有关 。


### 6、状态管理

`scope_model` 、`flutter_redux`、`fish_redux` 、甚至还有有 `dva_flutter` 等等，可以看出状态管理在 `flutter` 中和前端十分相近。

这里简单说说 `scope_model` ，它只有一个文件，但是很巧妙，它利用的就是 `AnimationBuilder` 的特性。

如下图是使用代码，在前面我们知道，状态管理使用的是 `InheritedWidget` 实现共享的，而当我们对 `Model` 进行数据改变时，通过调用 `notifyListeners` 通知页面更新了。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image21)

这里的原理是什么呢？

- 其实 `scope_model` 内部利用了 `AnimationBuilder` ，而 `Model` 实现了 `Listenable` 接口。

- 当 `Model` 设置给了  `AnimationBuilder` 时， `AnimationBuilder` 会执行 `addListener` 添加监听，而监听方法里会执行 `setState`。

- 所以我们改变 `set` 方法时调用 `notifyListeners` 就触发了 `setState` 去更新了，这样体现出了前面说的 `FLutter` 常见的开发模式。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image22)



## 三、混合开发


以 `Android` 的角度来说，从方便调试和解耦集成上，我们一般会以 `aar` 的形式集成混合开发，这里就会涉及到 `gradle` 打包的一个概念。

1、如下代码所示，在项目中进行 `gradle` 脚本修改，组件化开发模式，用 `apk` 开发，用 `aar` 提供集成，正常修改 `gradle` 代码即可快速打包。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image23)


那如果 `Flutter` 的项目插件带有本地代码呢？

> 如果开发过 `React Native` 的应该知道，在原生插件安装时会需要执行 `react-native link` ，而这时候会修改项目的gradle 和java代码。

2、 和 `React Native` 很有侵入性相比， `Flutter` 就很巧妙了。

如下图所示，安装过的插件会出现在 `.flutter_plugins` 文件中，然后通过读取文件，动态在 `setting.gradle` 和 `flutter.gradle` 中引入和依赖：

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image24)

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image25)

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image26)

所以这时候我们可以参考打包，修改我们的gradle脚本，利用 fat-aar 插件将本地 projcet 也打包的 aar 里。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image27)



> ## 官方未来将有 `Flutter build aar` 的方法可提供使用。

3、混合开发的最大痛点是什么？

**肯定是堆栈管理!!!** 所以项目开发了 `flutter_boost` 来解决这个问题。

- 堆栈统一到了原生层。
- 通过一个唯一 `engine` ，切换 `Surface` 渲染显示。
- 每个 `Activity` 就是一个 `Surface` ，不渲染的页面通过截图缓存画面。

> `flutter_boost` 截止到我测试的时间 2019-05-16, 只支持 1.2之前的版本

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image28)


## 四、PlatformView

混合开发除了集成到原生工程，也有将原生控件集成到 Flutter 渲染树里里的需求。


首先我们看看没有 `PlatformView` 之前是如何实现 `WebView` 的，这样会有什么问题？

如下图所示，事实上 dart 中仅仅是用了一个 `SingleChildRenderObjectWidget` 用于占位，将大小传递给原生代码，然后在原生代码里显示出来而已。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image29)

这样的时候必定会代码画面堆栈问题，因为这个显示脱离了 Flutter 的渲染树，通过出现动画肯定会不一致。

### 4.1 AndroidView

AndroidView -> TextureLayer，利用Android 上的副屏显示与虚拟内存显示原理。

- 共享内存，实时截图渲染技术。

- 存在问题，耗费内存，页面复杂时慢。

> 这部分因为之前以前聊过，就不赘述了

## 三、Flutter Web

RN因为是原生控件，所以在react 和react native 整合这件事上存在难度。

flutter 作为一个UI 框架，与平台无关，在web上利用的是dart2js的能力。 比如Image

- 因为 Flutter 是一套 UI 框架，整体 UI 几乎和平台无关，这和 React Native 有很大的区别。（我在开发过程中几乎无知觉）
- 在 flutter_web 中 UI 层面与渲染逻辑和 Flutter 几乎没有什么区别，底层的一些区别如： flutter_web 中的 Canvas 是 EngineCanvas 抽象，内部会借助 dart2js 的能力去生成标签。
- React Native 平台关联性太强，而 Flutter 在多平台上优势明显。我们期待官方帮我们解决大部分的适配问题。

![image38.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image30)

![image39.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image31)

![image40.GIF](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image32)

### Flutter 的平台无关能力能带来什么？

- 1、某些功能页面，可以一套代码实现，利用插件安装引入，在web、移动app、甚至 pc 上，都可以编译出对应平台的高性能代码，而不会像 Weex 等一样存在各种兼容问题。

- 2、在应用上可以快速实现“降级策略”，比如某种情况下应用产生奔溃了，可以替换为同等 UI 的 h5 显示，而这些代码只需要维护一份。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image33)


![](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image34)


### 资源推荐

* RTC社区 ： https://rtcdeveloper.com
* Github ： [https://github.com/CarGuo/](https://github.com/CarGuo)
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**


![我们还会再见吗？](http://img.cdn.guoshuyu.cn/20190604_Flutter-rtc-meetup/image35)