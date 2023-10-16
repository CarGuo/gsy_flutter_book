# Harmony 开始支持 Flutter ，聊聊 Harmony 和 Flutter 之间的因果

相信大家都已经听说过，明年的 [Harmony Next 版本将正式剥离 AOSP 支持](https://juejin.cn/post/7264237761158643773) ，基于这个话题我已经做过一期问题汇总 ，当时在[现有 App 如何兼容 Harmony Next ](https://juejin.cn/post/7266703104112607284#heading-5)问题上提到过：

> 华为内部也主导适配目前的主流跨平台方案，主动提供反向适配支持，估计后面就会有类似 Flutter for harmony 的社区支持。

![](http://img.cdn.guoshuyu.cn/20230918_HF/image1.png)

没想到 HDC 大会才刚过去一个多月，就有网友提醒，针对 OpenHarmony 的 Flutter 版本已经开源：https://gitee.com/openharmony-sig/flutter_flutter ，这既让人惊喜又是「情理之中」，**因为在众多框架里，Harmony 和 Flutter 之间的联系可以说是最密不可分**。

![](http://img.cdn.guoshuyu.cn/20230918_HF/image2.png)

# 关系

**为什么说 Harmony 和 Flutter 之间的联系很密切？因为不管是 ArkUI 还是 ArkUI-X ，它们的底层支持里都或多或少存在 Flutter 的身影**。

例如 ArkUI 的 framework  [arkui_ace_engine ](https://gitee.com/openharmony/arkui_ace_engine)，里面就可以看到很多熟悉的 Flutter 代码，**不过这里面有点特殊在于，这些代码都是用 C++ 实现的**，例如下图中的 `Stack` 的控件。

![](http://img.cdn.guoshuyu.cn/20230918_HF/image3.png)

![](http://img.cdn.guoshuyu.cn/20230918_HF/image4.png)

另外，除了 ArkUI 华为还开源了  [ArkUI-X](https://gitee.com/arkui-x) ，**ArkUI-X 扩展了 ArkUI 框架让其支持跨平台开发，而这部分跨平台的底层逻辑，同样来自 Flutter 和 Skia 的支持**。

![](http://img.cdn.guoshuyu.cn/20230918_HF/image5.png)

与 Flutter 不同的是，OpenHarmony 上层开发用的是 ArkTS 和 ArkUI，调用走的是 NAPI（Native API），NAPI 是一套基于 Node.js 规范开发的原生模块扩展开发框架。

NAPI 可以实现 JS 与 C/C++ 代码之间相互访问，也就是 ArkTS 可以直接和  C/C++  无缝调用，类似 dart ffi 效果。

![](http://img.cdn.guoshuyu.cn/20230918_HF/image6.png)

举个例子，例如通过 ArkUI-X 里的 `getDefaultDisplaySync` 获取设备屏幕信息， 对于 Android 系统而言， ets 下的代码通过 napi 会调用到 C++ 层的 DisplayInfo 对象，从而再通过 jni 调用 java 下的 DisplayInfo 对象。

```ts
 var dsp = display.getDefaultDisplaySync();
```

| ![](http://img.cdn.guoshuyu.cn/20230918_HF/image7.png) | ![](http://img.cdn.guoshuyu.cn/20230918_HF/image8.png) | ![](http://img.cdn.guoshuyu.cn/20230918_HF/image9.png) | ![](http://img.cdn.guoshuyu.cn/20230918_HF/image10.png) | ![image-20230918165856863](http://img.cdn.guoshuyu.cn/20230918_HF/image11.png) |
| ------------------------------------------------------ | ------------------------------------------------------ | ------------------------------------------------------ | ------------------------------------------------------- | ------------------------------------------------------------ |

其实这一点对于 Flutter 来说很重要，因为对于 Flutter 兼容 Harmony OS 的支持上， napi 是必不可少的一部分。

![](http://img.cdn.guoshuyu.cn/20230918_HF/image12.png)

因为在 Flutter 里，Dart 除了可以直接和 C/C++ 调用之外，还支持和 Objective-C/Swift 与 Java/Kotlin 直接调用而不需要通过 Channel 。

- 其中 [Objective-C / Swift interop](https://dart.dev/guides/libraries/objective-c-interop) 是通过 package:ffigen :

```yaml
ffigen:
  name: AVFAudio
  description: Bindings for AVFAudio.
  language: objc
  output: 'avf_audio_bindings.dart'
  headers:
    entry-points:
      - '/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioPlayer.h'
```

- [Java / kotlin](https://dart.dev/guides/libraries/java-interop) 是通过 jnigen 支持调用，不过目前还属于 **experimental** 的状态：

```yaml
output:
  c:
    library_name: example
    path: src/example/
  dart:
    path: lib/example.dart
    structure: single_file

source_path:
  - 'java/'
classes:
  - 'dev.dart.Example'
```

所以，**后续在 Harmony OS 上，就会有多一个类似 napi gen 支持的需要**。

# 兼容

本次开源支持 OpenHarmony 的 flutter 社区版本来自 [openharmony-sig]( https://gitee.com/openharmony-sig/) ，该组织主要用于孵化 OpenHarmony 相关开源生态项目。

![](http://img.cdn.guoshuyu.cn/20230918_HF/image13.png)

> 另外，在 openharmony 组织下 [sig_crossplatformui](https://gitee.com/openharmony/community/blob/master/sig/sig_crossplatformui/sig_crossplatformui_cn.md) 也有 Taro 主导的一些跨平台支持计划。

OpenHarmony 的 flutter （简称 OP Flutter ）版本目前所用的分支应该是 3.7 版本，因为是刚开源，目前 flutter tools 指令仅支持 linux 下使用 ，但是相信后续跟上节奏应该不成问题。

![](http://img.cdn.guoshuyu.cn/20230918_HF/image14.png)

> **以下分析基于 2023-09-18 的部分内容，后续肯定会有新的变化，这里主要提供一些思路和方向**。

SIG 社区适配的主要有 [OP flutter](https://gitee.com/openharmony-sig/flutter_flutter) 和 [OP flutter engine](https://gitee.com/openharmony-sig/flutter_engine) 两个项目，根据目前的提交，OP flutter 目前主要是添加了 flutter tools 对于构建 hap 的支持，例如：

- 添加环境检测

  ![](http://img.cdn.guoshuyu.cn/20230918_HF/image15.png)

  

- 实现 tools 下的自定义的 `build_hap.dart` ，还有识别鸿蒙设备的支持等。

  ![](http://img.cdn.guoshuyu.cn/20230918_HF/image16.png)

  ![](http://img.cdn.guoshuyu.cn/20230918_HF/image17.png)

- 提供 create 时对应的 ets 模版

  ![](http://img.cdn.guoshuyu.cn/20230918_HF/image18.png)

而关于运行支持，主要是通过 OP flutter engine 来实现，主要代码新增在对应的 `ohos/` 目录下：

![](http://img.cdn.guoshuyu.cn/20230918_HF/image19.png)

从  OP flutter engine 变更的内容上看，主要是从原有 `shell/platform/android` 下的代码拷贝一份进行调整，例如 GL Context 代码部分目前几乎太大区别。

![](http://img.cdn.guoshuyu.cn/20230918_HF/image20.png)

![](http://img.cdn.guoshuyu.cn/20230918_HF/image21.png)

另外，**大家比较关心的应该就是 Impeller 在 OP 上是否支持，目前看来 OP Flutter Engine 里对于 Impeller 有一定预设，但是并没有启用**，因为 Flutter 官方目前对于 Android 上的 Impeller 也没有正式发布，所以这个目前看来也不需要着急。

![](http://img.cdn.guoshuyu.cn/20230918_HF/image22.png)

![](http://img.cdn.guoshuyu.cn/20230918_HF/image23.png)

关于字体部分， **目前看来 OP 上 Flutter 默认会使用  `sans-serif`**  ，这个应该是和 鸿蒙上的 [**HarmonyOS Sans**](https://developer.harmonyos.com/cn/docs/design/des-guides/font-0000001157868583) 保持一致。 

![](http://img.cdn.guoshuyu.cn/20230918_HF/image24.png)

![](http://img.cdn.guoshuyu.cn/20230918_HF/image25.png)

**关于刷新率部分，目前暂时可以看到是默认写死了 60hz** ，后续应该可以通过 napi 等支持获取实际刷新率，支持动态刷新率这个大家不用担心。

![](http://img.cdn.guoshuyu.cn/20230918_HF/image26.png)

另外，因为版本问题，目前 OP Flutter Engine 里还保留了  partial repaint  操作，但是其实 Flutter 官方已经在 Android 上 Disable  了 partial repaint  ，因为 Android 上的部分重绘存在太多问题，所以该功能被直接屏蔽。

**Flutter 官方之后打算与 Vulkan Impeller 单独适配后再重新开放  partial repaint，这对 OP Flutter Engine 来说也许也是一个历史包袱，猜测 OP Flutter 后续会跟随 Impeller 同步**。

当然，因为不同平台，所以 OP Flutter  Engine 也有自己需要单独实现的逻辑，例如数据的类型转化处理，在 Android 上对应的是 [shell/platform/android/platform_view_android_jni_impl.cc](https://github.com/flutter/engine/blob/1603fa1bb41271366dceedaaf0663715576e18f2/fml/platform/android/jni_util.cc) ， 而在 OP 上对应的就是 [shell/platform/ohos/napi/platform_view_ohos_napi.cpp ](https://gitee.com/openharmony-sig/flutter_engine/blob/e5ff895ce905afd8f9f85f105f41da6c6d9ef8a5/fml/platform/ohos/napi_util.cc) :

![](http://img.cdn.guoshuyu.cn/20230918_HF/image27.png)

最后，**Flutter 适配不只是 embedding 和 tools 的适配，还有新的 channel 和 plugin 的支持**，目前看来 SIG 也在致力与这点，一些常用或者知名的 plugin  社区都会逐步增加支持，这看起来是一个苦力活，但是对于 Harmony 脱离 AOSP 构建自己的生态来说，无疑会是历史性的一步。

![](http://img.cdn.guoshuyu.cn/20230918_HF/image28.png)

# 最后

通过本篇，相信你应该能简单理解到 Flutter 和 Harmony 之间的「因果关系」，**对于 Flutter 开发来说，Harmony Next 会是一个相对较好的新平台**。

当然，**这不代表这你可以不学 ArkTS 和 ArkUI** ，因为不管是打包构建或者 napi 都离不开 Harmony 平台本身的支持，而且在于这样一个「百废待兴」的社区环境下，完全靠社区支撑明显不现实，关键时刻还得是「自己动手」才能「丰衣足食」。

![](https://img.cdn.guoshuyu.cn/WechatIMG1818.jpg)