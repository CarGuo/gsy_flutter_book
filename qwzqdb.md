作为 GSY 开源系列的作者，在去年也整理过 [《移动端跨平台开发的深度解析》](https://juejin.im/post/5b395eb96fb9a00e556123ef) 的对比文章，时隔一年之后，本篇将重新由 **环境搭建、实现原理、编程开发、插件开发、编译运行、性能稳定、发展未来** 等七个方面，对当前的 **React Native** 和 **Flutter** 进行全面的分析对比，希望能给你更有价值的参考。

> 是的，这次没有了 Weex，**超长内容预警，建议收藏后阅。** 


## 前言

临冬之际，移动端跨平台在经历数年沉浮之后，如今还能在舞台聚光灯下雀跃的， 也只剩下 **React Native** 和 **Flutter** 了，作为沉淀了数年的 “豪门” 与 19 年当红的 “新贵” ，它们之间的 “针锋相对” 也成了开发者们关心的事情。

> 过去曾有人问我：*“他即写 Java 又会 Object-C ，在 Android 和 IOS 平台上可以同时开发，为什么还要学跨平台呢？”*
> 
> 而我的回答是：**跨平台的市场优势不在于性能或学习成本，甚至平台适配会更耗费时间，但是它最终能让代码逻辑（特别是业务逻辑），无缝的复用在各个平台上，降低了重复代码的维护成本，保证了各平台间的统一性，** 如果这时候还能保证一定的性能，那就更完美了。


类型 | React Native |Flutter
-------- |  --- | --- 
语言 |JavaScript | dart
环境|JSCore|Flutter Engine
发布时间|2015|2017
star|78k+|67k+
对比版本|0.59.9|1.6.3
空项目打包大小| Android  20M(可调整至 7.3M) /  IOS 1.6M |   Android 5.2M / IOS 10.1M
GSY项目大小| Android 28.6M / IOS 9.1M |   Android  11.6M /  IOS  21.5M
代码产物| JS Bundle 文件 | 二进制文件
维护者|Facebook| Google
风格|响应式，Learn once, write anywhere| 响应式，一次编写多平台运行
支持|Android、IOS、(PC)|Android、IOS、(Web/PC)
使用代表|京东、携程、腾讯课堂|闲鱼、美团B端


## 一、环境搭建

无论是 **React Native** 还是 **Flutter** ，都需要 *Android* 和 *IOS* 的开发环境，也就是 *JDK 、Android SDK、Xcode* 等环境配置，而不同点在于 ：

- **React Native** 需要 `npm`  、`node` 、`react-native-cli`  等配置 。
- **Flutter** 需要 `flutter sdk ` 和 *Android Studio* / *VSCode* 上的 **Dart** 与 **Flutter** 插件。

从配置环境上看， **Flutter** 的环境搭配相对简单，而 **React Native** 的环境配置相对复杂，而且由于 `node_module` 的“黑洞”属性和依赖复杂度等原因，目前在个人接触的例子中，**首次配置运行成功率 Flutter 是高于 React Native 的，且 Flutter 失败的原因则大多归咎于网络。** 

> 同时跨平台开发首选 Mac ，没有为什么。

## 二、实现原理

在 *Android* 和 *IOS* 上，默认情况下 **Flutter** 和 **React Native** 都**需要一个原生平台的
`Activity` / `ViewController` 支持，且在原生层面属于一个“单页面应用”，** 而它们之间最大的不同点其实在于 UI 构建 ：

- **React Native** ：

**React Native**  是一套 UI 框架，默认情况下 **React Native**  会在 `Activity` 下加载 JS 文件，然后运行在 `JavaScriptCore` 中解析 *Bundle* 文件布局，最终堆叠出一系列的原生控件进行渲染。

简单来说就是 **通过写 JS 代码配置页面布局，然后 React Native 最终会解析渲染成原生控件**，如 `<View>` 标签对应 `ViewGroup/UIView` ，`<ScrollView>` 标签对应 `ScrollView/UIScrollView` ，`<Image>` 标签对应 `ImageView/UIImageView` 等。

![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image1)


所以相较于如 `Ionic` 等框架而言， **React Native** 让页面的性能能得到进一步的提升。

- **Flutter** ：

*如果说 **React Native** 是为开发者做了平台兼容，那 **Flutter** 则更像是为开发者屏蔽平台的概念。*


> **Flutter** 中只需平台提供一个 `Surface` 和一个 `Canvas` ，剩下的 **Flutter** 说：*“你可以躺下了，我们来自己动”。*

**Flutter** 中绝大部分的 `Widget` 都与平台无关， 开发者基于 `Framework` 开发 App ，而 `Framework` 运行在 `Engine` 之上，由 `Engine` 进行适配和跨平台支持。这个跨平台的支持过程，其实就是将 **Flutter UI 中的 `Widget` “数据化” ，然后通过 `Engine` 上的 `Skia` 直接绘制到屏幕上 。**

![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image2)


所以从以上可以看出：**React Native 的 *Learn once, write anywhere* 的思路，就是只要你会 *React* ，那么你可以用写 *React* 的方式，再去开发一个性能不错的App；而 Flutter 则是让你忘掉平台，专注于 Flutter UI 就好了。**

- **DOM：**

额外补充一点，React 的虚拟 *DOM* 的概念相信大家都知道，这是 React 的性能保证之一，而 Flutter 其实也存在类似的虚拟  *DOM*  概念。

> 看过我 **Flutter** 系列文章可能知道，**Flutter** 中我们写的 `Widget` ， 其实并非真正的渲染控件，这一点和 **React Native** 中的标签类似，`Widget`  更像配置文件， 由它组成的 `Widget` 树并非真正的渲染树。

**`Widget` 在渲染时会经过 `Element` 变化， 最后转化为 `RenderObject` 再进行绘制， 而最终组成的 `RenderObject` 树才是 *“真正的渲染 Dom” ，*** 每次 `Widget` 树触发的改变，并不一定会导致`RenderObject`  树的完全更新。


**所以在实现原理上 React Native 和 Flutter 是完全不同的思路，虽然都有类似“虚拟 *DOM* 的概念” ，但是React Native 带有较强的平台关联性，而 Flutter UI 的平台关联性十分薄弱。**

## 三、 编程开发

**React Native** 使用的 *JavaScript* 相信大家都不陌生，已经 24 岁的它在多年的发展过程中，各端各平台中都出没着它的身影，在 Facebook 的 React 开始风靡之后，15 年移动浪潮下推出的 **React Native** ，让前端的 JS 开发者拥有了技能的拓展。

**Flutter** 的首选语言 *Dart* 语言诞生于 2011 年，而 2018 年才发布了 2.0，原本是为了用来对抗 *JavaScript* 而发布的开发语言，却在 *Web* 端一直不温不火，直到 17年 才因为 **Flutter** 而受关注起来，之后又因为 **Flutter For Web** 继续尝试后回归 *Web* 领域。

编程开发所涉及的点较多，后面主要从 **`开发语言` 、`界面开发` 、`状态管理` 、`原生控件`** 四个方面进行对比介绍。

> 至于最多吐槽之一就是为什么 **Flutter** 团队不选择 *JS* ，有说因为 *Dart* 团队就在 **Flutter** 团队隔壁，也有说谷歌不想和 **Oracle** 相关的东西沾上边。
> 同时 **React Native** 更新快 4 年了，版本号依旧没有突破 1.0 。

#### 3.1、 语言

**因为起初都是为了 *Web* 而生，所以 *Dart* 和 *JS* 在一定程度上有很大的通识性。**

如下代码所示， 它们都支持通过 `var` 定义变量，支持 `async/await` 语法糖，支持 `Promise`(`Future`) 等链式异步处理，甚至 `*`/`yield` 的语法糖都类似(虽然这个对比不大准确)，但可以看出它们确实存在“近亲关系” 。


```

/// JS

    var a = 1

    async function doSomeThing() {
        var result = await xxxx()
        doAsync().then((res) => {
            console.log("ffff")
        })
    }
	function* _loadUserInfo () {
    	console.log("**********************");
    	yield put(UpdateUserAction(res.data));
	}


/// Dart

  var a = 1;

  void doSomeThing() async {
    var result = await xxxx();
    doAsync().then((res) {
      print('ffff');
    });
  }
  _loadUserInfo() async* {
    print("**********************");
    yield UpdateUserAction(res.data);
  }


```

但是它们之间的差异性也很多，而最大的区别就是： **JS 是动态语言，而 Dart 是伪动态语言的强类型语言。**

如下代码中，在 `Dart` 中可以直接声明 `name` 为 `String` 类型，同时 `otherName` 虽然是通过 `var` 语法糖声明，但在赋值时其实会通过自推导出类型 ，而 `dynamic` 声明的才是真的动态变量，在运行时才检测类型。


```
// Dart

String name = 'dart'; 
var otherName = 'Dart';
dynamic dynamicName = 'dynamic Dart'; 

```

如下图代码最能体现这个差异，在下图例子中：

- `var i` 在全局中未声明类型时，会被指定为 `dymanic` ，从而导致在 `init()` 方法中编译时不会判断类型，这和  JS 内的现象会一致。

- 如果将  `var i = "";`  定义在  `init()` 方法内，这时候 `i` 已经是强类型 `String`了 ，所以编译器会在 `i++`报错，**但是这个写法在 JS 动态语言里，默认编译时是不会报错的。**

![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image3)




**动态语言和非动态语言都有各种的优缺点，比如 JS 开发便捷度明显会高于 Dart ，而 Dart 在类型安全和重构代码等方面又会比 JS 更稳健。**


#### 3.2、界面开发

**React Native** 在界面开发上延续了 *React* 的开发风格，**支持 scss/sass 、样式代码分离、在 0.59 版本开始支持 *React Hook* 函数式编程** 等等，而不同  *React*  之处就是更换标签名，并且样式和属性支持因为平台兼容做了删减。

如下图所示，是一个普通 **React Native**  组件常见实现方式，**继承 `Component` 类，通过 `props` 传递参数，然后在 `render` 方法中返回需要的布局，布局中每个控件通过 `style` 设置样式** 等等，这对于前端开发者基本上没有太大的学习成本。 

![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image4)

如下所示，如果再配合 *React Hooks* 的加持，函数式的开发无疑让整个代码结构更为简洁。

![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image5)



**Flutter** 最大的特点在于： **Flutter 是一套平台无关的 UI 框架，在 Flutter 宇宙中万物皆 `Widget`。**

如下图所示，**Flutter** 开发中一般是通过继承 **无状态 `StatelessWidget`** 控件或者 **有状态 `StatefulWidget` 控件**  来实现页面，然后在对应的 **` Widget build(BuildContext context)` 方法内实现布局，利用不同 `Widget` 的 `child` / `children` 去做嵌套，通过控件的构造方法传递参数，最后对布局里的每个控件设置样式等。** 

![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image6)

而对于 **Flutter**  控件开发，目前最多的吐槽就是 **控件嵌套和样式代码不分离** ，样式代码分离这个问题我就暂不评价，这个真要实际开发才能更有体会，而关于嵌套这里可以做一些 “洗白” ：

**Flutter** 中把一切皆为 `Widget` 贯彻得很彻底，**所以 `Widget` 的颗粒度控制得很细** ，如 `Padding` 、`Center` 都会是一个单独的 `Widget`，甚至**状态共享都是通过 `InheritedWidget` 共享 `Widget` 去实现的**，而这也是被吐槽的代码嵌套样式难看的原因。 

**事实上正是因为颗粒度细，所以你才可以通过不同的 `Widget` ， 自由组合出多种业务模版，** 比如 Flutter 中常用的 `Container` ，它就是官方帮你组合好的模板之一， **`Container`  内部其实是由 `Align`、 `ConstrainedBox` 、`DecoratedBox` 、`Padding` 、`Transform`  等控件组合而成** ，所以嵌套深度等问题完全是可以人为控制，甚至可以在帧率和绘制上做到更细致的控制。


当然，**官方也在不断地改进优化编写和可视化的体验**，如下图所示，从目前官方放出的消息上看，未来这个问题也会被进一步改善。

![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image7)


![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image8)


最后总结一下，抛开上面的开发风格，**React Native 在 UI 开发上最大的特点就是平台相关，而 Flutter 则是平台无关，比如下拉刷新，在 React Native 中， `<RefreshControl>` 会自带平台的不同下拉刷新效果，而在 Flutter 中，如果需要平台不同下拉刷新效果，那么你需要分别使用 `RefreshIndicator` 和 `CupertinoSliverRefreshControl` 做显示，不然多端都会呈现出一致的效果。** 


#### 3.3、状态管理


前面说过， **Flutter** 在很多方面都借鉴了 **React Native** ，所以在状态管理方面也极具“即视感”，比如**都是调用 `setState` 的方式去更新，同时操作都不是立即生效的** ，当然它们也有着差异的地方，如下代码所示：

- 正常情况下 **React Native** 需要在 `Component` 内初始化一个 `this.state` 变量，然后通过 `this.state.name` 访问 。
- **Flutter** 继承 `StatefulWidget` ，然后在其的 `State` 对象内通过变量直接访问和 `setState` 触发更新。


```
/// JS

    this.state = {
       name: ""
    };
    
    ···
	 
    this.setState({
    	name: "loading"
    });
    
    ···
    
    <Text>this.state.name</Text>
    
    
/// Dart

    var name = "";

    setState(() {
       name =  "loading";
    });
    
    ···
    
    Text(name)

```


当然它们两者的内部实现也有着很大差异，比如 **React Native 受 React diff 等影响，而 Flutter 受 `isRepaintBoundary` 、`markNeedsBuild` 等影响。**


而在第三方状态管理上，两者之间有着极高的相似度，如早期在 Flutter 平台就涌现了很多前端的状态管理框架如：[flutter_redux](https://pub.flutter-io.cn/packages/flutter_redux) 、[fish_redux](https://pub.flutter-io.cn/packages/fish_redux) 、 [dva_flutter](https://pub.flutter-io.cn/packages/dva_flutter) 、[flutter_mobx](https://pub.flutter-io.cn/packages/flutter_mobx) 等等，它们的设计思路都极具 *React* 特色。

同时 **Flutter** 官方也提供了 [scoped_model](https://pub.flutter-io.cn/packages/scoped_model) 、[provider](https://pub.flutter-io.cn/packages/provider) 等具备 **Flutter** 特色的状态管理。


**所以在状态管理上 React Native 和 Flutter 是十分相近的，甚至是在跟着 React 走。**

#### 3.4、原生控件

在跨平台开发中，就不得不说到接入原有平台的支持，比如 *在 Android 平台上接入 x5 浏览器 、接入视频播放框架、接入 Lottie 动画框架等等。* 

这一需求 **React Native** 先天就支持，甚至在社区就已经提供了类似 [lottie-react-native](https://github.com/react-native-community/lottie-react-native)  的项目。  **因为 React Native 整个渲染过程都在原生层中完成，所以接入原有平台控件并不会是难事**  ，同时因为发展多年，虽然各类第三方库质量参差不齐，但是数量上的优势还是很明显的。

而 **Flutter** 在就明显趋于弱势，甚至官方在开始的时候，连 `WebView` 都不支持，这其实涉及到  **Flutter** 的实现原理问题。

因为  **Flutter 的整体渲染脱离了原生层面，直接和 GPU 交互，导致了原生的控件无法直接插入其中** ，而在视频播放实现上， **Flutter**  提供了外界纹理的设计去实现，但是这个过程需要的数据转换，很明显的限制了它的通用性， **所以在后续版本中 **Flutter** 提供了 `PlatformView` 的模式来实现集成。** 

> 以 *Android* 为例子，在原生层 **Flutter** 通过 `Presentation` 副屏显示的原理，利用 `VirtualDisplay` 的方式，让 *Android* 控件在内存中绘制到  `Surface` 层。 `VirtualDisplay ` 绘制在 `Surface` 的 **textureId** ，之后会通知到 *Dart* 层，在 *Dart* 层利用 `AndroidView` 定义好的 `Widget` 并带上 **textureId** ，那么 **Engine** 在渲染时，就会在内存中将 **textureId** 对应的数据渲染到  `AndroidView` 上。

 `PlatformView`  的设计必定导致了性能上的缺陷，最大的体现就是内存占用的上涨，同时也引导了诸如键盘无法弹出[#19718](https://github.com/flutter/flutter/issues/19718)和黑屏等问题，甚至于在 *Android* 上的性能还可能不如外界纹理。

**所以目前为止， Flutter 原生控件的接入上是仍不如 React Native 稳定。**

### 四、 插件开发

**React Native** 和 **Flutter** 都是支持插件开发，不同在于 **React Native 开发的是 [npm](https://www.npmjs.com) 插件，而 Flutter 开发的是 [pub](https://pub.flutter-io.cn) 插件。**

**React Native** 使用 *npm* 插件的好处就是：可以使用丰富的  *npm* 插件生态，同时减少前端开发者的学习成本。

但是使用  *npm* 的问题就是太容易躺坑，**因为  *npm* 包依赖的复杂度和深度所惑，以至于你都可能不知道 *npm* 究竟装了什么东西**，抛开安全问题，这里最直观的感受就是 ：*“为什么别人跑得起来，而我的跑不起来？”* 同时每个项目都独立一个 **node_module** ，对于硬盘空间较小的 Mac 用户略显心酸。


**Flutter** 的 *pub* 插件默认统一管理在 *pub* 上，类似于 *npm* 同样支持 *git* 链接安装，而 `flutter packages get` 文件一般保存在电脑的统一位置，多个项目都引用着同一份插件。


> - win 一般是在 C:\Users\xxxxx\AppData\Roaming\Pub\Cache 路径下
> - mac 目录在 ~/.pub-cache

如果找不到插件目录，也可以通过查看 `.flutter-plugins` 文件，或如下图方式打开插件目录，至于为什么需要打开这个目录，感兴趣的可以看看这个问题 [13#](https://github.com/CarGuo/GSYGithubAppFlutter/issues/13#issuecomment-496960086) 。

![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image9)


最后说一下 **Flutter** 和 **React Native** 插件，在带有原生代码时不同的处理方法：

-  **React Native** 在安装完带有原生代码的插件后，需要执行 `react-native link` 脚本去引入支持，具体如 *Android* 会在 `setting.gradle` 、 `build.gradle` 、`MainApplication.java` 等地方进行侵入性修改而达到引用。

-  **Flutter** 则是通过 `.flutter-plugins` 文件，保存了带有原生代码的插件 *key-value* 路径 ，之后 **Flutter** 的脚本会通过读取的方式，动态将原生代码引入，最后通过生成 `GeneratedPluginRegistrant.java` 这个忽略文件完成导入，这个过程开发者基本是无感的。


![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image10)


**所以在插件这一块的体验， Flutter 是略微优于 React Native 的。**

### 五、 编译和产物

**React Native** 编译后的文件主要是 `bundle` 文件，在 *Android* 中是 `index.android.bunlde` 文件，而在 *IOS* 下是 `main.jsbundle` 。

**Flutter** 编译后的产物在 *Android* 主要是 ：
- `isolate_snapshot_instr`  应用程序指令段 
- `isolate_snapshot_data`应用程序数据段 
- `vm_snapshot_data` 虚拟机数据段 
- `vm_snapshot_instr` 虚拟机指令段等产物 

> **⚠️注意，1.7.8 之后的版本，Android 下的 Flutter 已经编译为纯 so 文件。**

在 IOS 主要是 **App.framework** ，其内部也包含了 ` kDartVmSnapshotData` 、` kDartVmSnapshotInstructions`  、 `kDartIsolateSnapshotData` 、` kDartIsolateSnapshotInstructions`  四个部分。


接着看完整结果，如下图所示，是空项目下 和 GSY 实际项目下， **React Native** 和 **Flutter**  的 Release 包大小对比。

可以看出在 **React Native 同等条件下， Android 比 IOS 大很多** ，这是因为 *IOS* 自带了 **JSCore** ，而 *Android* 需要各类动态 **so** 内置支持，而且这里 *Android* 的动态库 **so** 是经过了 `ndk` 过滤后的大小，不然还会更大。

**Flutter** 和 **React Native** 则是相反，因为 *Android* 自带了 **skia** ，所以比没有自带 **skia** 的 *IOS* 会小得多。

**以上的特点在 GSY 项目中的 Release 包也呈同样状态。**

类型 | React Native |Flutter
-------- |  --- | --- 
空项目 Android |![Rn Android ndk abiFilters arm64-v8a](http://img.cdn.guoshuyu.cn/20190621_qwzq/image11)| ![Flutter Android](http://img.cdn.guoshuyu.cn/20190621_qwzq/image12)
空项目 IOS|![Rn IOS](http://img.cdn.guoshuyu.cn/20190621_qwzq/image13)|![Flutter IOS](http://img.cdn.guoshuyu.cn/20190621_qwzq/image14)
GSY Android|![GSYGIthubApp.apk](http://img.cdn.guoshuyu.cn/20190621_qwzq/image15)|![GSYGithubAppFlutter.apk](http://img.cdn.guoshuyu.cn/20190621_qwzq/image16)
GSY IOS |![GSYGithubAPP.ipa](http://img.cdn.guoshuyu.cn/20190621_qwzq/image17)|![GSYGithubAppFlutter.ipa](http://img.cdn.guoshuyu.cn/20190621_qwzq/image18)



值得注意的是，Google Play 最近发布了 [《8月不支持 64 位，App 将无法上架 Google Play！》](https://juejin.im/post/5cff1843e51d4510774a8844) 的通知 ，同时也表示将停止 *Android Studio* 32 位的维护，而 `arm64-v8a` 格式的支持，**React Native** 需要在 0.59  以后的版本才支持。

至于 **Flutter** ，在打包时通过指定 `flutter build apk --release --target-platform android-arm64` 即可。


### 六、性能

说到性能，这是一个大家都比较关心的概念，但是有一点需要注意，**抛开场景说性能显然是不合适的，因为性能和代码质量与复杂度是有一定联系的。**


先说理论性能，**在理论上 Flutter 的设计性能是强于 React Native ** ，这是框架设计的理念导致的，Flutter 在少了 **OEM Widget** ，直接与 CPU / GPU 交互的特性，决定了它先天性能的优势。


> 这里注意不要用模拟器测试性能，特别是IOS模拟器做性能测试，因为 Flutter 在 IOS模拟器中纯 CPU ，而实际设备会是 GPU 硬件加速，同时只在 Release 下对比性能。

![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image19)


> 代码的实现方式不同，也可能会导致性能的损失，比如 **Flutter** 中 **skia** 在绘制时，`saveLayer` 是比较消耗性能的，比如 *透明合成、clipRRect* 等等，都会可能需要 `saveLayer` 的调用， 而 `saveLayer` 会清空GPU绘制的缓存，导致性能上的损耗，从而导致开发过程中如果掉帧严重。


最后如下图所示，是去年闲鱼用 GSY 项目做测试对比的数据，原文在[《流言终结者- Flutter和RN谁才是更好的跨端开发方案？》](https://www.jianshu.com/p/20c30834f137) ，可以看出在去年的时候， **Flutter的整体帧率和绘制就有了明显的优势。** 

![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image20)


> 额外补充一点，*JS* 和 *Dart* 都是单线程应用，利用了协程的概念实现异步效果，而在 **Flutter** 中 *Dart* 支持的 `isolate` ，却是属于完完全全的异步线程处理，可以通过 Port 快捷地进行异步交互，这大大拓展了 **Flutter** 在 *Dart* 层面的性能优势。


### 七、发展未来

之前一篇 [《为什么 Airbnb 放弃了 React Native?》](https://www.colabug.com/3238051.html) 文章，让众多不明所以的吃瓜群众以为 **React Native** 已经被放弃，之后官方发布的 
[《Facebook 正在重构 React Native，将重写大量底层》](https://www.oschina.net/news/97129/state-of-react-native-2018) 公示，又再一次稳定了军心。

 同时 **React Native** 在 0.59 版本开始支持 *React Hook* 等特性，并将原本平台的特性控件从 **React Native** 内部剥离到社区，这样控件的单独升级维护可以更加便捷，同时让  **React Native** 与 **React** 之间的界限越发模糊。

**Flutter** UI 平台的无关能力，让 **Flutter** 在跨平台的拓展上更为迅速，尽管 **React Native** 也有 *Web* 和 *PC* 等第三方实现拓展支持，但是由于平台关联性太强，这些年发展较为缓慢， 而 **Flutter** 则是短短时间又宣布 *Web* 支持，甚至拓展到 *PC* 和嵌入式设备当中。

这里面对于 **Flutter For Web** 相信是大家最为关心的话题， 如下图所示，在 **Flutter** 的设计逻辑下，开发 **Flutter Web** 的过程中，你甚至感知不出来你在开发的是 Web 应用。

**Flutter Web 保留了 大量原本已有的移动端逻辑，只是在 Engine 层利用 Dart2Js 的能力实现了差异化，** 不过现阶段而言，Flutter Web 仍处在技术预览阶段，不建议在生产环境中使用 。

![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image21)

**由此可以推测，不管是 Flutter 或者 React Native，都会努力将自己拓展到更多的平台，同时在自己的领域内进一步简化开发。**


- 其他参考资料 ：

[《Facebook 正在重构 React Native，将重写大量底层》](https://www.oschina.net/news/97129/state-of-react-native-2018)

[《React Native 的未来与React Hooks》](https://juejin.im/post/5cb34404f265da0384127fcd)

[《庖丁解牛！深入剖析 React Native 下一代架构重构》](https://www.infoq.cn/article/EJYNuQ2s1XZ88lLa*2XT)

[《Flutter 最新进展与未来展望》](https://mp.weixin.qq.com/s/dC2C1jpDrQSsip6wjiejBw)



> 自此，本文终于结束了，长呼一口气。

### 资源推荐

* Github ： [https://github.com/CarGuo/](https://github.com/CarGuo)
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**

* 开源 React Native 项目：https://github.com/CarGuo/GSYGithubApp


##### 文章

[《Flutter完整开发实战详解系列》](https://juejin.im/user/582aca2ba22b9d006b59ae68/posts)

[《移动端跨平台开发的深度解析》](https://www.jianshu.com/p/7e0bd4708ba7)


![](http://img.cdn.guoshuyu.cn/20190621_qwzq/image22)
