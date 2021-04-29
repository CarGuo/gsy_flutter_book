## 一、前言

相信做过移动端视频开发的同学应该了解，想要实现视频从普通播放到全屏播放的逻辑并不是很简单，比如在 [GSYVideoPlayer](https://github.com/CarGuo/GSYVideoPlayer) 中的动态全屏切换效果，就使用了创建全新的 `Surface` 来替换实现:

- 创建全新的 `Surface` ，并将对于的 `View` 添加到应用顶层的 `DecorView` 中；
- 在全屏时将新创建的 `Surface` 并设置到 Player Core ; 
- 同步两个 `View` 的播放状态参数和旋转系统界面;
- 退出全屏时移除 `DecorView` 中的 `Surface`，切换 List Item 中的 `Surface` 给 Player Core ，同步状态。


![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Player-Full/image1)

当然，不同的播放内核可能还需要做一些额外操作，**但是这一切在 Flutter 中就变得极为简单。**

```!
事实上 Flutter 中实现全屏切换效果很简单，后面会一并介绍为什么在 Flutter 上实现会如此简单。
```

## 二、实现效果

如下图所示是 Flutter 中实现后的全屏效果，而实现这个效果的关键就是**跳堆栈就可以了！是的，Flutter 中简单地跳页面就能够实现无缝的全屏切换。**

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Player-Full/image2)

如下代码所示，首先在正常播放页面下加入官方 `video_player` 插件的 `VideoPlayer` 控件，并且初始化 `VideoPlayerController` 用于加载需要播放的视频并初始化，另外此处还用了 `Hero` 控件用于实现页面跳转过渡的动画效果。

```
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(
        'https://res.exexm.com/cw_145225549855002')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
  }
  
 Container(
   height: 200,
   margin: EdgeInsets.only(
       top: MediaQueryData.fromWindow(
               WidgetsBinding.instance.window)
           .padding
           .top),
   color: Colors.black,
   child: _controller.value.initialized
       ? Hero(
           tag: "player",
           child: AspectRatio(
             aspectRatio: _controller.value.aspectRatio,
             child: VideoPlayer(_controller),
           ),
         )
       : Container(
           alignment: Alignment.center,
           child: CircularProgressIndicator(),
         ),
 ))
```

如下代码所示，之后在全屏的页面中同样使用 `Hero` 控件和 `VideoPlayer` 控件实现过渡动画和视频渲染。

这里的 `VideoPlayerController` 可以通过构造方法传递进来，也可以通过 `InheritedWidget` 实现共享传递，只要是和前面普通播放界面的 `controller` 是同一个即可。

```
Container(
     color: Colors.black,
     child: Stack(
       children: <Widget>[
         Center(
           child: Hero(
             tag: "player",
             child: AspectRatio(
               aspectRatio: widget.controller.value.aspectRatio,
               child: VideoPlayer(widget.controller),
             ),
           ),
         ),
         Padding(
           padding: EdgeInsets.only(top: 25, right: 20),
           child: IconButton(
             icon: const BackButtonIcon(),
             color: Colors.white,
             onPressed: () {
               Navigator.pop(context);
             },
           ),
         )
       ],
     ),
    )
```

另外在 Flutter 中，只需要通过 ` SystemChrome.setPreferredOrientations` 方法就可以快速实现应用的横竖屏切换。

最后如下代码所示，只需要通过 `Navigator` 调用页面跳转就可以实现全屏和非全屏的无缝切换了。

```
  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) {
                    return VideoFullPage(_controller);
                  }));
```

是不是很简单，只需要 `VideoPlayer` 、`Hero` 和 `Navigator` 就可以快速实现全屏切换播放的效果，**那为什么在 Flutter 上可以这样简单的实现呢？**


## 三、实现逻辑

之所以可以如此简单地实现动态化全屏效果，其实主要涉及到  `video_player` 插件在 Flutter 上的实现：**外接纹理 `Texture`** 。

因为 Flutter 中的控件基本上是平台无关的，而其控件主要是由 Flutter Engine 直接绘制，简单地说就是：**原生平台仅仅提供了一个 `Activity` / `ViewController` 容器, 之后由容器内提供一个 `Surface` 给 Flutter Engine 用户绘制。**

所以 Flutter 中控件的渲染堆栈是独立的，没办法和原生平台直接混合使用，这时候为了能够在 Flutter 中插入原生平台的部分功能，**Flutter 除了提供了 `PlatformView` 这样的实现逻辑之外，还提供了 `Texture`作为 外接纹理的支持。**

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Player-Full/image3)

如上图所示，在[《Flutter 完整实战详解》](https://juejin.im/user/582aca2ba22b9d006b59ae68/collections) 中介绍过，**Flutter 的界面渲染是需要经历 `Widget` -> `RenderObject` -> `Layer` 的过程**，而在 `Layer`  的渲染过程中，当出现一个 `TextureLayer` 节点时，说明这个节点使用了 Flutter 中的 `Texture` 控件，那么这个控件的内容就会由原生平台提供，而**管理 `Texture` 主要是通过 `textureId` 进行识别的**。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Player-Full/image4)

举个例子，在 Android 原生层中 `video_player` 使用的是 `exoplayer` 播放内核，那么如上图所示，**`VideoPlayerController` 会在初始化的时候通过 `MethodChannel` 和原生端通信，之后准备好播放内核和 `Surface`，最后将对应的 `textureId` 返回到 Dart 中**。

**所以在前面的代码中，需要在全屏和非全屏页面使用同一个 `VideoPlayerController`，这样它们就具备了同一个 `textureId`**。

具备同一个 `textureId` 后，那么只要原生层不停止播放， `textureId`  对应的原生数据就一直处于更新状态，而这时候虽然跳转路由页面，但不同的 `VideoPlayer` 内部的 `Texture` 控件用的是同一个 `VideoPlayerController`，也就是同一个 `textureId` ，所以它们会呈现出通用的画面。

如下图所示，这个过程简单总结就是： **Flutter 和原生平台通过 `PixelBuffer` 为介质进行交互，原生层将数据写入 `PixelBuffer` ，Flutter 通过注册好的 `textureId` 获取到 `PixelBuffer` 之后由 Flutter Engine 绘制**。


![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Player-Full/image5)

**最后需要注意的是，在 iOS 上在实现页面旋转时， `SystemChrome.setPreferredOrientations` 方法可能会出现无效**，这个问题在 issue [#23913](https://github.com/flutter/flutter/issues/23913) 和 [#13238](https://github.com/flutter/flutter/issues/13238) 中有提及，这里可能需要自己多实现一个原生接口进行兼容，当然在 [auto_orientation](https://pub.flutter-io.cn/packages/auto_orientation) 或者 [orientation](https://pub.flutter-io.cn/packages/orientation) 等第三方库也进行了这方面的兼容。

**另外 iOS 的页面旋转还确定是否打开了旋转配置的开关**。

![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Player-Full/image6)


## 资源推荐

* 本文 Demo ： [flutter_video_full_controller](https://gitee.com/CarGuo/flutter_video_full_controller)
* Github ： https://github.com/CarGuo
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**
* 开源 React Native 项目：https://github.com/CarGuo/GSYGithubApp


![](http://img.cdn.guoshuyu.cn/20200316_Flutter-Player-Full/image7)