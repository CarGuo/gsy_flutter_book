# Flutter  120hz 高刷新率在 Android 和 iOS 上的调研总结


## 一、无用的知识

首先科普无用的知识，说起高刷新率，就不得不提两个词汇： **ProMotion** 和 **LTPO**  。 ProMotion 是 iOS 在支持 120hz 之后出现的动态刷新率支持，也就是不同场景使用不同的屏幕刷新率，从而实现体验上提升的同时降低了电池的消耗。

![c64c73ef829cb88f10f35ae24e5a6c59](http://img.cdn.guoshuyu.cn/20220627_Flutter-120HZ/image1)



LTPO(low-temperature Polycrystalline oxide) 允许显示器动态改变屏幕刷新率 ，而早在三星S20 Ultra、OPPO Find X3系列、一加 9 Pro 等系列产品上都率先采用了这种显示技术，但是实际上大家在 LTPO 又有不同的技术调教，从而出现了我们后续要聊的问题。

![image-20220331153929592](http://img.cdn.guoshuyu.cn/20220627_Flutter-120HZ/image2)

例如 LTPO 1.0 时代可能大部分实现都只是强硬的根据场景锁死 60Hz/120Hz 的刷新率，而 LTPO 2.0 开始各大厂家则是升级了自适应策略，例如最常见的就是升级了滑动变频：

![0ecaee4af2444b87a73db171bd36ba3f](http://img.cdn.guoshuyu.cn/20220627_Flutter-120HZ/image3)

当然，除了最常见的滑动， LTPO 2.0 上厂家可能还会有对动画、视频、文字输入、应用切换等场景进行不同的升频和降频策略，而其实介绍上面这些的原因是：

- **苹果 ProMotion 是基于官方实现的统一方案**；
- **Android 的 LTPO 是基于供应商硬件后Android OEM 厂家自主调教的实现**；

> 以上部分资料来自[《LTPO到底是不是真的省电？-一加LTPO 2.0上手体验》](https://mobile.it168.com/a2022/0121/6612/000006612347.shtml) 

所以这也造就了 Flutter 需要在 Android 和 iOS 上进行单独适配的主要原因。

## 二、Android

前面介绍里引用了一加的 LTPO 2.0 实现是有原因的，首先知道**自适应屏幕刷新率是 OEM 厂商自主调教，也就是理论上作为 App 是不需要做任何适配，因为跟随 Android 就行，Android 本身也是使用 Skia 渲染。** 

但是往往事与愿违，在 Flutter 关于 [高刷问题 ](https://github.com/flutter/flutter/issues/35162) 最先被提及的就是一加，那时候基本都引用了 [《The OnePlus 7 Pro’s 90Hz Refresh Rate Doesn’t Support Every App 》](https://www.xda-developers.com/oneplus-7-pro-true-90hz-display-mode/) 这篇文章：

> 一加 7 Pro 的  90 fps 模式对于某些 App 而言只有 60 fps，要在所有 App 上都强制 90 fps，需要执行 `adb shell settings put global oneplus_screen_refresh_rate 0 ` 命令， 相比之下 Pixel 4 无需任何更改就直接可以支持渲染 90 fps   的 Flutter  App。

也就是问题最开始是在一加的 90 fps 上不支持，而社区通过和一加的沟通得到的回复是：

- 一加7 Pro 为了平衡性能和功耗，采用的是基于 Android 定制自己的帧率控制逻辑，一般屏幕会以高帧率工作，但在某些场景下系统会切回到低帧率，而由于引入了这种机制，可能会出现当 App 希望屏幕以高帧率运行时却被系统强制设置为低帧率的问题。

- 那如何通过 App 设置 fps ？ **如果应用程序需要设置帧速率，那首先需要通过 `getSupportedModes()` 获取目前屏幕支持的模式列表，然后遍历列表，根据找到想要使用的分辨率和刷新率的 `modeId`，赋值给窗口的`preferredDisplayModeId`**。

所以基于这个问题修复的方案，社区内提出了 [flutter_displaymode](https://github.com/ajinasokan/flutter_displaymode)  插件，插件主要提供了获取 `Display.Mode` 和设置 `preferredDisplayModeId` 的支持，用于临时解决类似 一加7 Pro 上的这种刷新率问题。

```dart
/// On OnePlus 7 Pro:
/// #1 1080x2340 @ 60Hz
/// #2 1080x2340 @ 90Hz
/// #3 1440x3120 @ 90Hz
/// #4 1440x3120 @ 60Hz
/// On OnePlus 8 Pro:
/// #1 1080x2376 @ 60Hz
/// #2 1440x3168 @ 120Hz
/// #3 1440x3168 @ 60Hz
/// #4 1080x2376 @ 120Hz
```

那什么是 `PreferredDisplayModeId` ？通过官方的 [《setframerate-vs-preferreddisplaymodeid》](https://developer.android.com/guide/topics/media/frame-rate#setframerate-vs-preferreddisplaymodeid) 可以了解：

> `WindowManager.LayoutParams.preferredDisplayModeId` 是 App 向平台设置所需帧率的一种方式，因为有时候 App 只想改变刷新率，但是不需要更改其他显示模式如分辨率等。类似设置还有 `setFrameRate()  ` ，使用 `setFrameRate()` 代替 `preferredDisplayModeId`会更简单， 因为`setFrameRate()`   可以自动匹配显示模式列表里具有特定帧速率的模式。

**那为什么不直接用 `setFrameRate` ？其中之一因为这是一个 Target  很高的 API**。

![image-20220331170424637](http://img.cdn.guoshuyu.cn/20220627_Flutter-120HZ/image4)

> PS：**这里和大家介绍一位 Flutter 大佬， 事实上这个 [问题](https://github.com/flutter/flutter/issues/93688) 作为 GDE 的  [AlexV525](https://github.com/AlexV525) 大佬跟进了很久，上面的插件也是他在参与维护，同时也恭喜🎉 大佬获得 [Google Open Source Peer Bonus Winners in 2022](https://opensource.googleblog.com/2022/03/Announcing-First-Group-of-Google-Open-Source-Peer-Bonus-Winners-in-2022.html) 的🏆**。

但是在安稳一段时间之后，[一加 9 pro 上了 LTPO 和 ColorOS](https://github.com/ajinasokan/flutter_displaymode/issues/10)，之前的 adb 命令在新来的 ColorOS 上也随之失效，不过不要担心，后续发现这个其实是官方的一个bug，在  ColorOS  `11_A.06` 版本后修复了该问题，也就是插件还可以继续生效。

而如今两年快过去了，对于此问题还是只能通过插件去临时解决，因为从官方的态度上好像并不是特别支持嵌入这种方式：

- Flutter 应该将刷新率控制交给 OS 处理， Flutter 不应该对单个刷新率去进行 hardcode；
- 处理类似 OEM 厂商问题最好通过插件解决而不是 Flutter Engine ；

> 在这方面的处理思路和决策感觉和 iOS 差异较大，大概也有平台限制的因素吧。

事实上不同厂商对于 LTPO 的实现逻辑确实差异性很大，比如下图是一加10pro 在 LTPO 渲染是会选择性压缩或者丢弃一些冗余的指令。

![8888](http://img.cdn.guoshuyu.cn/20220627_Flutter-120HZ/image5)

我们知道 Flutter 是把 ` Widget`  渲染到 `Surface` 上，在这点上和使用 ` SurfaceView` 和 `OpenGL` 实现的 Google Map 很类似，而经过测试 Google Map 在这些设备上，不特殊设置和 Flutter 一样也只能以 60hz 渲染运行。

> 对于 OEM 厂商，在调教的 LTPO 上有权决定是否允许 App 使用更高的刷新率，即使 App 要求更高的刷新率，这难道又是一个“白名单模式”？

所以如果需要让 `Surface`  在某些特殊设备支持 90/120 hz 运行，就需要使用  `preferredDisplayModeId`  或者  `setFrameRate` ， **同时前提是厂商没有强行锁死帧率**。

> **一些手机厂商，会因为 “驯龙” 和控温的需要，都有自己的“稳帧”策略，甚至强制锁死帧率并且显示假帧率**。

![22222](http://img.cdn.guoshuyu.cn/20220627_Flutter-120HZ/image6)

而在 [#78117](https://github.com/flutter/flutter/issues/78117) 讨论的最终讨论结果就是：**Flutter 并不会特别针对这部分厂商去特意做适配，如果需要，你可以通过第三方插件来解决，当然在我的测试中，目前大部分设备的刷新率支持上还是正常**。

同时在早期 Flutter 的 IntelliJ  插件也存在 bug ，即使应用程序以 90 fps 运行，Android Studio / IntelliJ 中的 Flutter 插件也会给出 60 fps ，当然这个问题在后续的 [#4289](https://github.com/flutter/flutter-intellij/pull/4289) 上得到了解决。

> 额外补充一种情况，厂家通常还会检测 `SurfaceView`/`TextureView ` 是否超过屏幕的一半，因为这时候可能代表着你正在看视频或者玩游戏，而这时候可能也会降低帧率。



最后，如果对 Flutter 在 Android 上关于刷新率部分的代码感性起，可以查阅：[vsync_waiter.cc](https://github.com/flutter/engine/blob/ebcd86f681b9421318b3b4a8abd75839e70000a5/shell/common/vsync_waiter.cc) 、[vsync_waiter_android.cc](https://github.com/flutter/engine/blob/266d3360a7babfb5f20d5e9f8ea84772b2a247dc/shell/platform/android/vsync_waiter_android.cc) 、[android_display.cc](https://github.com/flutter/engine/blob/266d3360a7babfb5f20d5e9f8ea84772b2a247dc/shell/platform/android/android_display.cc)



## 三、iOS

回到 iOS 上，ProMotion 的支持思路就和原生不大一样，因为在刚推出 ProMotion  时官方就在 [《刷新率优化上》](https://developer.apple.com/documentation/quartzcore/optimizing_promotion_refresh_rates_for_iphone_13_pro_and_ipad_pro) 对 ProMotion 的适配提及过：

如果使用的是以下这些默认框架的话，对于这些刷新率的变化 App 而无需进行任何更改：

- [UIKit](https://developer.apple.com/documentation/uikit)
- [SwiftUI](https://developer.apple.com/documentation/swiftui)
- [SpriteKit](https://developer.apple.com/documentation/spritekit)
- [CAAnimation](https://developer.apple.com/documentation/quartzcore/caanimation)

但是对于 Flutter 而言并没用使用系统所提供的原生控件，所以目前需要在  `Info.plist` 文件中配置以下参数，从而启用关于 `CADisplayLink`  和 `CAAnimation` 上高于 120Hz 的相关支持：

```
<key>CADisableMinimumFrameDurationOnPhone</key><true/>
```

而在 Flutter 官方的讨论记录 [flutter.dev/go/variable-refresh-rate](https://flutter.dev/go/variable-refresh-rate) 和 issue  [#90675](https://github.com/flutter/flutter/issues/90675)  相关回复里可以看到，官方目前的决策是先使用 [#29797](https://github.com/flutter/engine/pull/29797) 的实现解决，通过调整 [vsync_waiter_ios.mm](https://github.com/flutter/engine/blob/4a3e7a5b72363c1f363d3000d04719c6938d963f/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.mm) 相关的内容来实现高刷支持：

```objective-c
- (void)setMaxRefreshRateIfEnabled {
  NSNumber* minimumFrameRateDisabled =
      [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CADisableMinimumFrameDurationOnPhone"];
  if (!minimumFrameRateDisabled) {
    return;
  }
  double maxFrameRate = fmax([DisplayLinkManager displayRefreshRate], 60);
  double minFrameRate = fmax(maxFrameRate / 2, 60);

  if (@available(iOS 15.0, *)) {
    display_link_.get().preferredFrameRateRange =
        CAFrameRateRangeMake(minFrameRate, maxFrameRate, maxFrameRate);
  } else if (@available(iOS 10.0, *)) {
    display_link_.get().preferredFramesPerSecond = maxFrameRate;
  }
}

```

- 默认情况下帧率会是设置为 60；
- 在支持 ProMotion  的设备上会设置为显示器支持的最大刷新率；
- **在 iOS 15 及更高版本上，还增加了设置帧率范围**，其中 preferred 和 max 均为屏幕支持的最大值，min 为最大值的 1/2；

其实在之前的讨论中还有如 [#29692](https://github.com/flutter/engine/pull/29692) 这种更灵活的实现，**也就是探索让 Flutter Engine 根据渲染和使用场景去自己选择当前的帧率**，因为社区认为：*对于普通用户来说，在不知道平台、性能等的情况下让开发者自己选择正确的刷新并不靠谱，所以通过 Engine 完成适配才是未来的方向*。

**当然，基于社区里目前迫切地想让 Flutter 得到 120Hz 的能力，所以会暂时优先采用上述的 `CADisableMinimumFrameDurationOnPhone` 来解决目前的困境，这也是 iOS 官方提倡的方式**。

另外值得一提的是，iOS 15.4  上的苹果修复了导致 ProMotion 相关的 bug ，因为在这之前会出现 ProMontion 并不是完全开放第三方支持的诡异情况，**而在 iOS 15.4 后， iOS 会自动为 App 中所有自定义动画内容启用120Hz刷新率**，所以会出现一个神奇的情况：

- 在 iOS 15.4 上， App 可以兼容得到 120Hz 动画；
- 在 iOS 15.4 之前，部分动画支持 ProMotion；

![image-20220331182557253](http://img.cdn.guoshuyu.cn/20220627_Flutter-120HZ/image7)



## 四、最后

可以看到就目前来说，高刷对于 Flutter 仍旧是一个挑战，作为独立渲染引擎，这也是 Flutter 无法逃避的问题，就目前情况来看：

- 在 Android 上你不需要做任何调整，如果遇到特殊设备或者系统，建议通过  [flutter_displaymode](https://github.com/ajinasokan/flutter_displaymode)  来解决；
- 在 iOS 上你可以添加 `CADisableMinimumFrameDurationOnPhone` 来粗暴解决，然后等待  [#29797](https://github.com/flutter/engine/pull/29797)  相关内容的合并发布；

最后，如果关于高刷方面你还有什么资料或者想法，欢迎留言评论讨论。