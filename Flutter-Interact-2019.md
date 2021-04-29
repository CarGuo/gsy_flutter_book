 昨天谷歌为在 `Flutter Interact` 上为我们带来了 `Flutter 1.12` ，这是 1.9.x 的版本在经历 6 次 `hotfix` 之后，才带来的 stable 大版本更新。**该版本解决了 4,571 个报错，合并了 1,905 份 pr，同时本次发布也是 Flutter 一年内的第五个稳定版本。**

 结合本次 `Flutter Interact` ，可以总结出几个关键词是: **`Platform` 、 `DartPad` 、`Spuernova` 、`AdobeXD`、`Hot UI` 和 `Layout Explorer` 。**


![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image1)

 ## 一、更多的平台

 本次 `Flutter Interact` 提出了让开发者更聚焦于精美的应用开发，从**以设备为中心转变为以应用为中心的开发理念**，Flutter 将帮助开发者忽略 Android、iOS、Web、PC 等不同平台差异，如下图所示是现场一套代码同时调试 7 台设备的演示。

 本次 Flutter 也开始兑现当初的承诺，目前 **Web 的支持已经发布到 Beta 分支，而 MacOS 的支持已经发布到 Master** 分支。虽然进度不算快，但是作为“白嫖党”表示还是很开心能看到有所推进。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image2)

使用 `Flutter Web` 和 `Flutter MacOS` 需要通过如下命令行打开配置，并且执行 `flutter create xxxx` 就可以创建带有 Web 和 MacOS 的项目（如果已有项目也可以执行 `flutter create` 补全），并且需要注意**调试 MacOS 平台应用需要本地 Flutter SDK 要处于 `master` 分支，如果仅测试 Web 可以使用 `beta` 分支。**

```
flutter config --enable-macos-desktop
flutter config --enable-web

///其他平台的支持
flutter config --enable-linux-desktop
flutter config --enable-windows-desktop
```

最后可以通过 `run` 或者 `build` 命令运行和打包程序，同时需要注意这里提到的 `linux` 和 `window` 平台目前还未合并到主项目中，如果想测试可在 [Desktop-shells](https://github.com/flutter/flutter/wiki/Desktop-shells) 查看对应配置项目：[flutter-desktop-embedding](https://github.com/google/flutter-desktop-embedding)。

```
///调试运行
flutter run -d chrome
flutter run -d macOS

///打包
flutter build web 
flutter build macos

```

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image3)

## 二、更多开发工具

### 1、DartPad

`DartPad` 是用于在线体验 Dart 功能的平台，而本次更新后 `DartPad`  也支持 Flutter 的在线编写预览，这代表着开发者可以在没有 `idea` 的情况下也能实时测试自己的 Flutter 代码，算是补全了 Flutter 的在线用例测试。

> DartPad 的官方地址：[dartpad.dev](https://dartpad.dev)  和国内镜像地址 [ dartpad.cn](https://dartpad.cn) 

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image4)

### 2、Spuernova

[`Spuernova`](https://supernova.io) 可以说是本次  `Flutter Interact` 的亮点之一，通过导入设计师的 `Sketch` 文件就可以生成 Flutter 代码，这无疑提升了 Flutter 的生产力和可想象空间，**虽然这种生成代码的方法并不罕见，完整实用程度有待考验，但是这也让开发者可以更聚焦于业务逻辑和操作逻辑。**

> 放心，这个坑不是谷歌 Flutter 团队开的，它属于另外一家商业公司。

使用 `Spuernova` 可以从 [https://supernova.io](https://supernova.io) 下载 `Supernova Studio` ，之后需要注册用户信息（可能需要科学S网），最后就可以看到如下图所示的界面。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image5)

在导入 `Sketch` 文件后可以看到设计师完成的界面效果，同时选中 `"</>"` 按键，可以在右侧看到对应的 Flutter 代码，左侧可以看到对应的层级设计，但是这时候的代码看起来还比较简单和笨重，并且不具备交互能力。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image6)

如果进一步配置，用户需要在对应的控件上，使用右键的弹出框配置控件的功能，比如 `List`、`Button`、`TextField` 等组件去 Convert 原有的控件，让控件更新具备交互能力，同时还可以为控件配置布局属性和动画效果等。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image7)

当然， `Spuernova`  并不是什么完全的公益项目，目前只有对于 Flutter 的简单支持上是免费的，其他项目支持还是处于收费状态。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image8)

另外类似的还有 `AdobeXD`， Adobe 的 Creative Cloud 添加了 Flutter 支持，只需一个插件，用户就可以将 `AdobeXD` 导出到 Flutter，目前处于[注册参加优先体验计划](https://xd.adobelanding.com/xd-to-flutter) 的进度。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image9)

### 3、Hot UI

Hot UI 就是大家盼星盼月的预览功能，如下图所示，在 Android Studio 的 Flutter 插件中在开发 widget 开发的过程中，直接在 IDE 的镜像里进行预览并与之进行交互。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image10)

在官方的 [HotUI-Getting-Started-instructions](https://github.com/flutter/flutter-intellij/wiki/HotUI-Getting-Started-instructions) 中可以看到相关的描述：**This feature is currently experimental. To enable, go to Preferences > Languages & Frameworks > Flutter Then check "Enable Hot UI" under "Experiments".** 目前该功能还处于实验阶段，在 Android Studio 的设置中，如图所示底部勾选启动这个功能。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image11)

但是如下图所示，开启后会发现和官方宣传的不一样？因为目前预览的 `Screen mirror` 处于 `coming soon` 的状态。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image12)

现阶段的 Hot UI 如下 GIF 所示，暂时只支持用户动态调试和配置控件的属性等逻辑，让我们期待官方填坑吧。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image13)


### 4、Layout Explorer

[`Layout Explorer`](https://flutter.dev/docs/development/tools/devtools/inspector#flutter-layout-explorer) 是另外实验性的布局调试模式，`Layout Explorer` 主要是用于帮助开发者更直观地适配屏幕和调试如 `overflowed` 等场景的问题。

在最新的 `Dart DevTools` 工具添加了一个名为 `Layout Explorer` 的功能，它能够以可视化的方式呈现应用的布局信息，从而让检查器可以更好地发挥功，同时 `Layout Explorer`  不仅能以可视化的方式展现正在运行的应用中的 widget 布局，而且还允许以交互的方式更改布局选项。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image14)

启动 `Layout Explorer` 同样需要 Flutter SDK 处于 `master` 分支，然后在程序运行之后，点击 `DevTools` 在 chrome 打开，之后点击最右侧的按键进入 Flutter 调试模式。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image15)


如下 GIF 所示，当选中的控件是具备 `Flex` 的支持时，可以看到有  `Layout Explorer`  的面板，在面板中可以动态调整控件的显示逻辑和控件的布局情况。


![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image16)

比如当控件出现了  `overflowed` ，我们可以很直观的看到问题的根源并且进行调整。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image17)

另外可以在  `Layout Explorer`  中动态调整控件的 flex 等相关信息，实时预览修改情况。

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image18)


## 三、Flutter SDK 改进

Flutter SDK 相关的更新本次解决了 4,571 个报错，合并了 1,905 份 pr，同时包含了许多的新功能支持。

- 首先 Flutter 1.12 建议开发者将 Android 项目迁移到 AndroidX，SDK 的瘦身，增加了 [google_fonts](https://pub.flutter-io.cn/packages/google_fonts) 字体的支持等。

- Android 插件的改进 [Android plugins APIs](https://flutter.dev/docs/development/packages-and-plugins/plugin-api-migration)，相比起以前更为简单明了，分割了 `FlutterPlugin` and `MethodCallHandler` ,同时提供 `ActivityAware` 、 `ServiceAware` 作为独立支持。

- iOS 13 深色模式,支持使用 darkTheme 设置，同时还增加了如 `CupertinoContextMenu`、`CupertinoSlidingSegmentedControl`、`CupertinoAlertDialog`、`CupertinoDatePicker` 等 iOS 风格的控件支持。

```
 new MaterialApp(
    title: '',
    navigatorKey: navigatorKey,
    theme: model.themeData,
    darkTheme: model.darkthemeData,
    locale: model.locale,
```

- [Add-to-App](https://flutter.dev/docs/development/add-to-app) 混合集成模式的进一步的更新。

- 新增加了不兼容的 `breaking change`，比如: [PageView 启用  RenderSliverFillViewport](https://github.com/flutter/flutter/pull/37024) 、 [WidgetsBinding 中的 attachRootWidget 被替换为 scheduleAttachRootWidget](https://github.com/flutter/flutter/pull/39079/files) 、[Allow gaps in the initial route](https://github.com/flutter/flutter/pull/39440/files)、[TextField's minimum height from 40 to 48 ](https://github.com/flutter/flutter/pull/42449) 等需要开发者注意重新适配的修改，更多可查阅 [release-notes-1.12.13](https://flutter.dev/docs/development/tools/sdk/release-notes/release-notes-1.12.13)。

- 增加了 [MediaQuery.systemGestureInsets 支持 Android Q 的手势导航](https://github.com/flutter/flutter/pull/37416)；增加了 SliverIgnorePointer 、SliverOpacity、SliverAnimatedList 等控件支持；PageRouteBuilder 支持 fullscreenDialog。


- [Dart 2.7 的发布，支持扩展方法](https://medium.com/dartlang/dart-2-7-a3710ec54e97)。

```
extension ExtendsFun on String {
  int parseInt() {
    return int.parse(this);
  }  double parseDouble() {
    return double.parse(this);
  }
}


main() {
  int i = '42'.parseInt();
  print(i);
}

```


更多完整的 release-notes 可见 [release-notes-1.12.13](https://flutter.dev/docs/development/tools/sdk/release-notes/release-notes-1.12.13)


### 四、其他

本次 `Flutter Interact` 还推荐了 [flutter-d-art](https://github.com/Solido/flutter-d-art) 和
[gskinner](https://flutter.gskinner.com) 等精美的开源项目，同时
**Flutter 本次也表示了将在未来优化代码的开发模式，而 Flutter 在不断开新坑的同时，也需要面对目前层出的问题。** 


![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image19)

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image20)

Flutter 过去的一年无疑是火热的，所以暴露的问题也指数级出现，比如最近开发中就遇到了**在断网时加载图后之后，再打开网络无法继续显示图片的问题。** 

不过既然是开源项目，“白嫖”之余也得多靠自己，上述问题经过查找后，在自定义的 `ImageProvider` 里图片加载失败时，可以通过清除了 `ImageCache` 中的 `PendingImage` 来解决问题，同时因为 `Image` 的封装与 `DecorationImage` 的差异化，还需要对 `Image`  的 `didUpdateWidget` 做二次处理才解决了问题。

说这个问题其实就是想表达开源的意义，用一个框架不能够只是坐享其成的心态，开源的目的更是交流，不管什么框架都不可能尽善尽美，我们可以用更开放的心态去尝试和“批判”，而我们的岗位不就是解决这些问题的么？


### Flutter 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)


### 资源推荐

* Github ： https://github.com/CarGuo
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**
* 开源 React Native 项目：https://github.com/CarGuo/GSYGithubApp

![](http://img.cdn.guoshuyu.cn/20191224_Flutter-Interact-2019/image21)