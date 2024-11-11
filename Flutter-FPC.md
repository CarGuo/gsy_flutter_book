# 快讯，Flutter PC 多窗口新进展，已在  Ubuntu/Canonical 展示

相信 Flutter 开发者对于 Flutter  PC 多窗口的支持一直是「望眼欲穿」，而根据 [#142845](https://github.com/flutter/flutter/issues/142845) 相关内容展示， 在上月 27 号的 Ubuntu 峰会，Flutter 展示了多窗口相关进展。

![](http://img.cdn.guoshuyu.cn/20241101_FPC/image1.png)

事实上 Ubuntu 和 Flutter 的进一步合作关系应该是在 2021 年就开始了，当时在谈到 Canonical 对 Flutter 的贡献时，Ken 就指出过，Ubuntu 团队将努力在所有桌面平台上为 Flutter 提供完整的多窗口支持。

![](http://img.cdn.guoshuyu.cn/20241101_FPC/image2.png)

虽然是在 Ubuntu/Canonical 上发布，但是多窗口支持肯定是会把它带到所有平台的，只是需要从某个平台开始进行：

![](http://img.cdn.guoshuyu.cn/20241101_FPC/image3.png)

目前对应的支持草稿和 API 方案已经公布，例如：

- 需要一个类似  `window.dart` 的 library 来让开发者可以通过它创建、更新和销毁窗口，提供了与窗口系统交互的全局方法，窗口小部件树必须包装在 `MultiWindowApp` 窗口小部件等。
- 需要一个 `flutter/windowing` 的 MethodChannel API，位于 window.dart 和 embedder 之间协调交互
- 为多窗口运行环境增加对应的 runner 等

```dart
///举个例子：
void main() {
  runWidget(
    MultiWindowApp(initialWindows[j][k]: <Future<Window> Function(BuildContext)>[
      (BuildContext context) => createWindow(
        context: context,
        size: const Size(640, 480),
        builder: (BuildContext context) {
          return const MyApp();
        })
  ]));
}
```

![](http://img.cdn.guoshuyu.cn/20241101_FPC/image4.png)

在大会上展示的多窗口支持 Window、Dialog、Satellites、Popup 等形式，还支持自定义定位器与约束调整的相关能力：

![](http://img.cdn.guoshuyu.cn/20241101_FPC/image5.png)

例如，最常规的多窗口场景，支持子窗口打开新窗口，窗口在任务管理中心可以看到：

![](http://img.cdn.guoshuyu.cn/20241101_FPC/image6.gif)

![](http://img.cdn.guoshuyu.cn/20241101_FPC/image7.gif)

支持多种 Dialogs 对话框模式，例如模态对话框、非模态对话框、作为对话框父级的对话框等：

![](http://img.cdn.guoshuyu.cn/20241101_FPC/image8.gif)

![](http://img.cdn.guoshuyu.cn/20241101_FPC/image9.gif)

支持 Satellites ，可以使用预设进行放置，显示随父级移动，在顶级窗口不活动时显示自动隐藏和显示 Satellites 父级对话框等：

![](http://img.cdn.guoshuyu.cn/20241101_FPC/image10.gif)

支持 Popup 窗口，可以自定义定位器，可以锚定到视图、锚定到窗口等：

![](http://img.cdn.guoshuyu.cn/20241101_FPC/image11.gif)

支持约束调整，可以滑动、翻转、调整大小：

![](http://img.cdn.guoshuyu.cn/20241101_FPC/image12.gif)

根据设计文档显示，这些在 API 里也有类似支持，例如创建窗口的方法会返回与窗口原型相对应的特定子类，如： TopLevel、PopupWindow、DialogWindow、SatelliteWindow 和 TipWindow 等。

而在支持多窗口正常运行，就需要更改支持多窗口的每个平台的 runner 代码，对于单窗口应用，默认的 runner 代码将保持不变，但用户在运行 flutter create * 时应该能够选择加入多窗口 runner 。

同时，来自 Material API 的许多核心 Widget 和方法需要迁移以支持使用新的多窗口功能，例如是：

- showDialog
- showMenu 
- MenuAnchor 
- ····

可以看到，本次分享的 Flutter 多窗口支持从设计到例子已经比较完善了，虽然还不支持什么时候可以正式看到它，毕竟从实现上看它涉及的底层修改并不少，但是总体来看落地的希望还是很大的。

> PS：除了现在可以在鸿蒙 next 手机端看到 Flutter 之后，也许你也有机会在以后的鸿蒙 PC 看到 Flutter ，目前 Flutter 在鸿蒙 next 支持上也有一些 App 上架了，例如在 ArkUI Inspector 下可以看到微信的朋友圈是 Flutter 实现：
>
> ![](http://img.cdn.guoshuyu.cn/20241101_FPC/image13.png)

更多可见：

- https://docs.google.com/document/u/0/d/1eQG-IS7r4_S9_h50MY_hSGwUVtgSTRSLzu7MLzPNd2Y/mobilebasic?tab=t.0&_immersive_translate_auto_translate=1

- https://github.com/flutter/flutter/pull/157525

- https://github.com/flutter/flutter/issues/142845#issuecomment-2435738214