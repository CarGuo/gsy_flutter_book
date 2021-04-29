## 多余的前言

Flutter 2.0 发布时，其中最受大家关注之一的内容就是 `Add-to-App` 相关的更新，因为除了**热更新**之外，Flutter 最受大家诟病的就是**混合开发体验**不好。

> 为什么不好呢？因为 **Flutter 的控件渲染直接脱离了原生平台，也就是无论页面堆栈和渲染树都独立于平台运行**，这固然给 Flutter 带来了较好的跨平台体验，但是也造成了在和原生平台混合时存在高成本的问题。


且不说在已有的原生项目中集成 Flutter ，就是现阶段在 Flutter 中集成原生控件的 [PlatformView 和  Hybrid Composition](https://juejin.cn/post/6858473695939084295) 体验也是有待提升，当然“有支持”和“能用”就已经是很不错的进展。


**所以 Flutter 2.0 在千呼万唤中发布了 `FlutterEngineGroup` 用于支持官方的 `Add Flutter to existing app` 方案。**

在此方案出现之前，类似的第三方支持有 `flutter_boost` 、 `mix_stack` 、 `flutter_thrio` 等等 ，它们是否好用这里不讨论，但是这些方案都要面对的问题是：

> 非官方的支持必然存在每个版本需要适配的问题，而按照 Flutter 目前的 `issue closed` 和 `pr merge` 的速度，很可能每个季度的版本都存在较大的变动，**所以如果开发者不维护或者维护不及时，那么侵入性极强的这类框架很容易就成为项目的瓶颈**。

而官方提供的 `FlutterEngineGroup` 方案有没有缺陷？肯定有的，它目前看起来更像是被催生出来的状态，各方面的问题还是有的，比如某些地方还存在不能 `destroy` 的问题。 （当然这个问题以及在 `master` 分支 merge 了）

![image.png](http://img.cdn.guoshuyu.cn/20210429_Flutter-Group/image1)

但是官方提供的方案，就意味着这个设计得到了 Flutter 官方的保证，**在未来的版本中会有兼容的优势**。

**`FlutterEngineGroup` 方案使用了多 Engine 混合模式，官方宣称除了一个 Engine 对象之外，后续每个 Engine 对象在 Android 和 iOS 上仅占用 180kB** 。

> 以前的方案每多一个Engine ，可能就会多出 19MB Android 和 13MB iOS 的占用。

从 Flutter 官方提供的例子上看，`FlutterEngineGroup`  的 API 十分简单，**多个 Engine 实例的内部都是独立维护自己的内部导航堆栈**，所以可以做到每个 Engine 对应一个独立的模块。



 所以使用 `FlutterEngineGroup` 之后，`FlutterEngine` 都将由 `FlutterEngineGroup`  去生成，生成的 `FlutterEngine` 可以独立应用于 `FlutterActivity`/`FlutterViewController`，甚至是 `FlutterFragment` ：


> 所以就像例子上所示，你可以在一个 `Activity` 上显示两个独立的 FlutterView 。


这其实得益于通过 `FlutterEngineGroup` 生成的 `FlutterEngine` 可以**共享 GPU 上下文， font metrics  和 isolate group snapshot** ，从而实现了更快的初始速度和更低的内存占用。

> **下图是使用官方实例打开16个页面之后的内存使用情况，并且每个页面成功返回且没有出现黑屏。**

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-Group/image2)

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-Group/image3)
 
## 简单的使用介绍

使用 `FlutterEngineGroup` 首先需要创建一个 `FlutterEngineGroup` 单例对象，之后每当需要创建 Engine 时，就通过它的 `createAndRunEngine(activity, dartEntrypoint)` 来创建对应的 `FlutterEngine` 。


```kotlin
        val app = activity.applicationContext as App
        // This has to be lazy to avoid creation before the FlutterEngineGroup.
        val dartEntrypoint =
            DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(), entrypoint
            )
        engine = app.engines.createAndRunEngine(activity, dartEntrypoint)
        this.delegate = delegate
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, "multiple-flutters")
```

以官方 Demo 的这段代码为例子：

1、首先通过 `findAppBundlePath` 和  `entrypoint` 创建出 `DartEntrypoint` 对象，这里的  **`findAppBundlePath` 主要就是默认的 `flutter_assets` 目录**；而 **`entrypoint` 其实就是 dart 代码里启动方法的名称**；也就是绑定了在 dart 中 `runApp` 的方法。

```dart

///kotlin
app.engines.createAndRunEngine(pathToBundle, "topMain")


///dart
@pragma('vm:entry-point')
void topMain() => runApp(MyApp());
```

2、通过上面创建的 `dartEntrypoint` 和 `context` ，使用  `FlutterEngineGroup` 就可以创建出对应的 `FlutterEngine` ，其实在内部就是通过`FlutterJNI.nativeSpawn` 和原有的引擎交互，得到新的 Long 地址 id。

> 在 C++ 层类似于原有的 `RunBundleAndSnapshotFromLibrary` 方法，但是它不能更改包路径或者 asset ，所以只能加载同一份 AOT 文件，这里得到的指针地址就是一个新的 `AndroidShellHolder` 。


3、最后利用生成的 `FlutterEngine` 的 `binaryMessenger` 来得到一个 `MethodChannel` 用于原生和 dart 之间的通信。


通过上述流程得到的 Engine ，自然就可以直接用于渲染运行新的 Flutter UI，比如直接继承 `FlutterActivity` ，然后 override  `provideFlutterEngine` 方法返回得到的 Engine 。


```kotlin

class SingleFlutterActivity : FlutterActivity()

    ·······

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return engine
    }


}
```

是不是很简单？这么简单的接入后：

- 在 dart 层面可以通过 `MethodChannel` 打开原始页面；
- 在原生层可以通过新建 `FlutterEngine` 打开新的 Flutter 页面；
- 甚至你还可以在原生层打开一个 `FlutterView` 的 Dialog；



当然，到这里你可能已经注意到了，因为每个 Flutter 页面都是一个独立的 Engine ，由于 dart isolate 的设计理念，**每个独立 Engine 的 Flutter 页面内存是无法共享的**。

也就是说，当你需要共享数据时，只能在原生层持有数据，然后注入或者传递到每个 Flutter 页面中，就像官方所说的，**每个 Flutter 页面更像是一个独立 Flutter 模块**。

> 当然这也造成了一些不必要的麻烦，比如：**同一张图片，在原生层、不同 Flutter Engine 会出现多次加载的问题**，这种问题可能就需要你针对 Flutter 的图片加载使用外界纹理，来实现在原生层统一的内存管理等。


另外目前我发现问题还有： [Android 11 上的  ARM TBI 问题](https://github.com/flutter/flutter/issues/78389) ，不过通过这次尝试，相信 `FlutterEngineGroup` 的进展将会越来越明朗，更早的被应用到生产环境中。

