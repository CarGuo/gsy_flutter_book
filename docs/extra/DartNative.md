---
title: "Flutter 的另外一种形态？社区 DartNative 要来了。"
---

Flutter 的另外一种形态？社区 DartNative 要来了。

最近有个  dartnative.com  的项目在 Flutter 社区 还挺热闹的，但是它和 Flutter 完全没关系，怎么说呢，有点一言难尽。

它在保留 Dart 和 Flutter 开发习惯的同时，把底层渲染路线换掉了，直接把 UI  回流到 UIKit 和 Android Views 上，大概类似：

![](https://img.cdn.guoshuyu.cn/image-20260807203827773.png)

从架构上看大概会是这样：

![](https://img.cdn.guoshuyu.cn/50044fa8-6064-4b55-a542-31b89bf64f34.png)

不过这里有个小细节，DartNative  说自己是 `No bridge` 和  ` 0 abstraction layers` ，也就是它不会是 RN 那种模态，大概率还是直接编译成 Native 运行，这种方式这两年也出来过好几个其他框架。

所以这玩意和 Flutter 上层差别不大，主要就是最后画到谁那里，实际上从官网给出的 Android 和 iOS 渲染效果看，确实风格直接是走的原生渲染：

![](https://img.cdn.guoshuyu.cn/ezgif-5f083f48a3e49d11.gif)



不过 Dart Native 核心还不是跨平台 UI 框架，它的卖点是针对用户场景的特调支持，比如键盘联动，DartNative 在 iOS 上会尝试直接加入键盘所在的 Core Animation transaction，在 Android 上用  `WindowInsetsAnimation`，让底部输入栏和键盘由系统动画一起移动。

![](https://img.cdn.guoshuyu.cn/ezgif-4b66cf925257bbe0.gif)

DartNative 的说法是，只用要它，就可以直接享受到键盘同步动画的支持，比起 Flutter 会快几帧。

长列表也做了优化，在帧率和性能上进行过特定优化出来：

![](https://img.cdn.guoshuyu.cn/ezgif-55d94717983b9579.gif)

然后 Camera、Video、WebView  也做了场景适配，比如 DartNative 提供了一个内置缓存和预缓存的原生视频播放器，可以做到零加载延迟，无缝播放下一个视频：

![ezgif-8d14e0667ba63c56](https://img.cdn.guoshuyu.cn/ezgif-8d14e0667ba63c56.gif)

然后在这个基础上，DartNative 保留了 CustomPaint ，提供一个 **Skia Graphite island**，主体 UI 使用 DartNative 原生 Views，那个动态 Blob / Shader 可以单独交给 Skia。

所以实际上 DartNative 的想法是，把一些觉得 Flutter 不好用的用户抢过来，针对现在已有的 Flutter 项目，实际迁移大概会变成下面这样：



![](https://img.cdn.guoshuyu.cn/347bce6f-1cc6-4639-9672-7d4abc0b8984.png)

**这里最麻烦的还是 Plugin ，目前 DartNative 说有 34 个 first-party plugins**，包括 camera、video、audio、webview、ONNX Runtime、Lottie、notifications、Google Maps、RevenueCat、Supabase、Social Sign-in 等这些常见的，但是还是太少了，这个短板还是太明显了，所以 DartNative 大概率还是会是一个小众的垂类社区项目风格。

![](https://img.cdn.guoshuyu.cn/image-20260807204203896.png)

当然，最主要还是，没想到 2026 年还会有人做一个这样的项目，为的居然是抢点 Flutter 的用户，实际上还真不如 Flutter 社区的分叉 Flocker 分支，至少 Flocker 分支已经用上了 Graphite ：

![](https://img.cdn.guoshuyu.cn/c579775c-8938-4d52-acdd-b57a021ede81.png)

至少 Flocker 分叉在 Flutter 上基于 WebGPU 纹理的播放器实现效果确实还挺不错的：

![](https://img.cdn.guoshuyu.cn/ezgif-32c61beeadd97975.gif)