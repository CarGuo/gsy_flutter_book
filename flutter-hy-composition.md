在以前的 [《Android PlatformView 和键盘问题》](https://mp.weixin.qq.com/s/nVBzSynBPuffpEW6cGUWHQ) 一文中介绍过混合开发上 Android `PlatformView` 的实现和问题，原本 Android 平台上为了集成如 `WebView`、`MapView`等能力，使用了 `VirtualDisplays` 的实现方式。

如今 1.20 官方开始尝试推出和 iOS `PlatformView` 类似的新 `Hybrid Composition` 模式，本篇将通过三小节对比介绍 `Hybrid Composition` 的使用和原理，一起来吃“螃蟹”吧～

> **反复提醒，是 1.20 不是 1.2 ～～～**

## 一、旧版本的 VirtualDisplay

**1.20 之前在 Flutter 中通过将 `AndroidView` 需要渲染的内容绘制到 `VirtualDisplays` 中
，然后在 `VirtualDisplay` 对应的内存中，绘制的画面就可以通过其 `Surface` 获取得到**。

 > `VirtualDisplay` 类似于一个虚拟显示区域，需要结合 `DisplayManager` 一起调用，一般在副屏显示或者录屏场景下会用到。`VirtualDisplay` 会将虚拟显示区域的内容渲染在一个 `Surface` 上。


![](http://img.cdn.guoshuyu.cn/20200810_flutter-hy-composition/image1)

如上图所示，**简单来说就是原生控件的内容被绘制到内存里，然后 Flutter Engine 通过相对应的 `textureId` 就可以获取到控件的渲染数据并显示出来**。

这种实现方式最大的问题就在与触摸事件、文字输入和键盘焦点等方面存在很多诸多需要处理的问题；在 iOS 并不使用类似 `VirtualDisplay` 的方法，而是**通过将 Flutter UI 分为两个透明纹理来完成组合：一个在 iOS 平台视图之下，一个在其上面**。

所以这样的好处就是：需要在“iOS平台”视图下方呈现的Flutter UI，最终会被绘制到其下方的纹理上；而需要在“平台”上方呈现的Flutter UI，最终会被绘制在其上方的纹理。**它们只需要在最后组合起来就可以了**。

通常这种方法更好，因为这意味着 Native View 可以直接参与到 Flutter 的 UI 层次结构中。

## 二、 接入 Hybrid Composition

官方和社区不懈的努力下， 1.20 版本开始在 Android 上新增了 `Hybrid Composition` 的 `PlatformView` 实现，该实现将解决以前存在于 Android 上的大部分和  `PlatformView` 相关的问题，比如**华为手机上键盘弹出后 Web 界面离奇消失等玄学异常**。

使用 `Hybrid Composition` 需要使用到 [PlatformViewLink](https://api.flutter.dev/flutter/widgets/PlatformViewLink-class.html)、 [AndroidViewSurface](https://api.flutter.dev/flutter/widgets/AndroidViewSurface-class.html) 和 [PlatformViewsService](https://api.flutter.dev/flutter/services/PlatformViewsService-class.html) 这三个对象，首先我们要创建一个 dart 控件：

- 通过 `PlatformViewLink` 的 `viewType` 注册了一个和原生层对应的注册名称，这和之前的 `PlatformView` 注册一样；
- 然后在 `surfaceFactory` 返回一个 `AndroidViewSurface` 用于处理绘制和接受触摸事件；
- 最后在 `onCreatePlatformView` 方法使用 `PlatformViewsService` 初始化 `AndroidViewSurface` 和初始化所需要的参数，同时通过 Engine 去触发原生层的显示。

```dart
Widget build(BuildContext context) {
  // This is used in the platform side to register the view.
  final String viewType = 'hybrid-view-type';
  // Pass parameters to the platform side.
  final Map<String, dynamic> creationParams = <String, dynamic>{};

  return PlatformViewLink(
    viewType: viewType, 
    surfaceFactory:
        (BuildContext context, PlatformViewController controller) {
      return AndroidViewSurface(
        controller: controller,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      );
    },
    onCreatePlatformView: (PlatformViewCreationParams params) {
      return PlatformViewsService.initSurfaceAndroidView(
        id: params.id,
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: StandardMessageCodec(),
      )
        ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
        ..create();
    },
  );
}
```

接下来来到 Android 原生层，在原生通过继承 `PlatformView` 然后通过 `getView` 方法返回需要渲染的控件。

```dart
package dev.flutter.example;

import android.content.Context;
import android.graphics.Color;
import android.view.View;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.platform.PlatformView;

class NativeView implements PlatformView {
   @NonNull private final TextView textView;

    NativeView(@NonNull Context context, int id, @Nullable Map<String, Object> creationParams) {
        textView = new TextView(context);
        textView.setTextSize(72);
        textView.setBackgroundColor(Color.rgb(255, 255, 255));
        textView.setText("Rendered on a native Android view (id: " + id + ")");
    }

    @NonNull
    @Override
    public View getView() {
        return textView;
    }

    @Override
    public void dispose() {}
}
```

之后再继承 `PlatformViewFactory` 通过 `create` 方法来加载和初始化 `PlatformView` 。

```dart
package dev.flutter.example;

import android.content.Context;
import android.view.View;
import androidx.annotation.Nullable;
import androidx.annotation.NonNull;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import java.util.Map;

class NativeViewFactory extends PlatformViewFactory {
  @NonNull private final BinaryMessenger messenger;
  @NonNull private final View containerView;

  NativeViewFactory(@NonNull BinaryMessenger messenger, @NonNull View containerView) {
    super(StandardMessageCodec.INSTANCE);
    this.messenger = messenger;
    this.containerView = containerView;
  }

  @NonNull
  @Override
  public PlatformView create(@NonNull Context context, int id, @Nullable Object args) {
    final Map<String, Object> creationParams = (Map<String, Object>) args;
    return new NativeView(context, id, creationParams);
  }
}
```


最后在 `MainActivity` 通过 `flutterEngine` 的 `getPlatformViewsController` 去注册 `NativeViewFactory`。

```dart
package dev.flutter.example;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterActivity {
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        flutterEngine
            .getPlatformViewsController()
            .getRegistry()
            .registerViewFactory("hybrid-view-type", new NativeViewFactory(null, null));
    }
}
```

当然，如果需要在 Android 上启用 `Hybrid Composition` ，还需要在 `AndroidManifest.xml` 添加如下所示代码来启用配置：

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="dev.flutter.example">
    <application
        android:name="io.flutter.app.FlutterApplication"
        android:label="hybrid"
        android:icon="@mipmap/ic_launcher">
        <!-- ... -->
        <!-- Hybrid composition -->
        <meta-data
            android:name="io.flutter.embedded_views_preview"
            android:value="true" />
    </application>
</manifest>
```

另外，官方表示 `Hybrid composition` 在 Android 10 以上的性能表现不错，在 10 以下的版本中，Flutter 界面在屏幕上呈现的速度会变慢，这个开销是因为 Flutter 帧需要与 Android 视图系统同步造成的。

**为了缓解此问题，应该避免在 Dart 执行动画时显示原生控件，例如可以使用placeholder 来原生控件的屏幕截图，并在这些动画发生时直接使用这个 placeholder**。


## 三、 Hybrid Composition 的特点和实现原理

要介绍 `Hybrid Composition` 的实现，就不得不介绍本次新增的一个对象：`FlutterImageView` 。

> `FlutterImageView` 并不是一般意义上的 `ImageView` 。

事实上 `Hybrid Composition` 上混合原生控件所需的图层合成就是通过 `FlutterImageView` 来实现。`FlutterImageView` 本身是一个普通的原生 `View`, 它通过实现了 `RenderSurface` 接口从而实现如 `FlutterSurfaceView` 的部分能力。

在 `FlutterImageView` 内部主要有 `ImageReader`、`Image` 和 `Bitmap` 三种类，其中：

- `ImageReader` 可以简单理解为就是能够存储 `Image` 数据的对象，并且可以提供 `Surface` 用于绘制接受原生层的  `Image` 数据。
- `Image` 就是包含了 `ByteBuffers` 的像素数据，它和 `ImageReader` 一般用在原生的如 `Camera` 相关的领域。
-  `Bitmap` 是将 `Image` 转化为可以绘制的位图，然后在 `FlutterImageView` 内通过 `Canvas` 绘制出来。

可以看到 **`FlutterImageView` 可以提供 `Surface` ，可以读取到  `Surface` 的 `Image` 数据，然后通过`Bitmap` 绘制出来。**

而在 `FlutterImageView` 中提供有 `background` 和 `overlay` 两种 `SurfaceKind` ，其中：

- `background` 适用于默认下 `FlutterView` 的渲染模式，也就是 Flutter 主应用的渲染默认，所以  `FlutterView` 其实现在有 `surface` 、`texture` 和 `image` 三种 `RenderMode` 。

- `overlay`  就是用于上面所说的 `Hybrid Composition` 下用于和 `PlatformView` 合成的模式。


另外还有一点可以看到，在 `PlatformViewsController` 里有 `createAndroidViewForPlatformView` 和 `createVirtualDisplayForPlatformView` 两个方法，这也是 Flutter 官方在提供 `Hybrid Composition` 的同时也兼容 `VirtualDisplay` 默认的一种做法。

>  `Hybrid Composition`  Dart 层通过 `PlatformViewsService` 触发原生的 `PlatformViewsChannel` 的 `create` 方法，之后发起一个 `PlatformViewCreationRequest` 就会有  `usesHybridComposition` 的判断，如果为 ture 后面就是走的 `createAndroidViewForPlatformView`。


**那么 `Hybrid Composition` 模式下 `FlutterImageView` 是如何工作的呢？**

首先我们把上面第二小节的例子跑起来，同时打开 Android 手机的布局边界，可以看到屏幕中间出现了一个包含 `Re` 的白色小方块。通过布局边界可以看到， `Re` 白色小方块其实是一个原生控件。

![](http://img.cdn.guoshuyu.cn/20200810_flutter-hy-composition/image2)

接着用同样的代码在不同位置增加一个 `Re` 白色小方块，可以看到屏幕的右上角又多了一个有布局边界的 `Re` 白色小方块，所以可以看到  `Hybrid Composition` 模式下的 `PlatformView` 是通过某种原生控件显示出来的。

![](http://img.cdn.guoshuyu.cn/20200810_flutter-hy-composition/image3)

**但是我们就会想了，在 `Flutter` 上放原生控件有什么稀奇的？这就算是图层合成了**？那么接着把两个  `Re` 白色小方块放到一起，然后在它们上面不用  `PlatformView` 而是直接用默认的 `Text` 绘制一个蓝色的 `Re`文本。

![](http://img.cdn.guoshuyu.cn/20200810_flutter-hy-composition/image4)

看到没有？在不用 `PlatformView` 的情况下，`Text` 绘制的蓝色的 `Re`文本居然可以显示在白色不透明的原生 `Re` 白色小方块上！！！

> 也许有的小伙伴会说，这有什么稀奇的？但是知道 `Flutter` 首先原理的应该知道，`Flutter` 在原生层默认情况下就是一个 `SurfaceView`，然后 Engine 把所有画面控件渲染到这个 `Surface` 上。
>
> 但是现在你看到了什么？我们在 Dart 层的 `Text` 蓝色的 `Re` 文本居然可以现在到 `Re` 白色小方块上，这说明 `Hybrid Composition` 不仅仅是把原生控件放到 Flutter 上那么简单。

然后我们又发现了另外一个奇怪的问题，**用 Flutter 默认 `Text` 绘制的蓝色的 `Re` 文本居然也有原生的布局边界显示**？所以我们又用默认 `Text` 增加了黄色的 `Re` 文本和红色的 `Re` 文本 ，可以看到**只有和 `PlatformView` 有交集的 `Text` 出现了布局边界。**

![](http://img.cdn.guoshuyu.cn/20200810_flutter-hy-composition/image5)

接着将黄色的 `Re` 文本往下调整后，可以看到黄色 `Re` 文本的布局边界也消失了，所以可以判定 `Hybrid Composition`  下 Dart 控件之所以可以显示在原生控件之上，是因为在和 `PlatformView` 有交集时通过某种原生控件重新绘制。

![](http://img.cdn.guoshuyu.cn/20200810_flutter-hy-composition/image6)


所以我们通过 `Layout Inspector` 可以看到，**重叠的 `Text` 控件是通过 `FlutterImageView` 层来实现渲染**。


![](http://img.cdn.guoshuyu.cn/20200810_flutter-hy-composition/image7)


另外还有一个有趣的现象，那就是当 **Flutter 有不只一个默认的控件本被显示在一个 `PlatformView`  区域上时，那么这几个控件会共用一个 `FlutterImageView` 。**

![](http://img.cdn.guoshuyu.cn/20200810_flutter-hy-composition/image8)

而如果他们不在一个区域内，那么就会各自使用自己的 `FlutterImageView` 。另外可以注意到，**用 `Hybrid Composition` 默认接入的 `PlatformView` 是一个 `FlutterMutatorView`**。

![](http://img.cdn.guoshuyu.cn/20200810_flutter-hy-composition/image9)


其实 `FlutterMutatorView` 是用于调整原生控件接入到 `FlutterView` 的位置和 `Matrix` 的，一般情况下 `Hybrid Composition`  下的 `PlatformView` 接入关系是：

![](http://img.cdn.guoshuyu.cn/20200810_flutter-hy-composition/image10)


**所以 `PlatformView` 是通过 `FlutterMutatorView` 把原生控件 `addView` 到 `FlutterView` 上，然后再通过 `FlutterImageView` 的能力去实现图层的混合**。

那么 Flutter 是怎么判断控件需要使用 `FlutterImageView` ？

事实上可以看到，在 Engine 去 `SubmitFrame` 时，会通过 `current_frame_view_count` 去对每个 view 画面进行规划处理，然后会通过判定区域内是否需要 `CreateSurfaceIfNeeded` 函数，最终触发原生的 `createOverlaySurface` 方法去创建 `FlutterImageView`。

```
    for (const SkRect& overlay_rect : overlay_layers.at(view_id)) {
      std::unique_ptr<SurfaceFrame> frame =
          CreateSurfaceIfNeeded(context,               //
                                view_id,               //
                                pictures.at(view_id),  //
                                overlay_rect           //
          );
      if (should_submit_current_frame) {
        frame->Submit();
      }
    }
```

至于在 Dart 层面 `PlatformViewSurface` 就是通过 `PlatformViewRenderBox` 去添加 `PlatformViewLayer` ，然后再通过在  `ui.SceneBuilder` 的  `addPlatformView` 调用 Engine 添加 `Layer` 信息。（这部分内容可见 [《 Flutter 画面渲染的全面解析》](https://mp.weixin.qq.com/s/aVdZVMqnrdy2vdATU9jBVg)）


其实还有很多的实现细节没介绍，比如：

- `onDisplayPlatformView`  方法，也就是在展示 `PlatformView` 时，会调用 `flutterView.convertToImageView` 方法将 `renderSurface` 切换为 `flutterImageView`；
- 在 `initializePlatformViewIfNeeded` 方法里初始化过的 `PlatformViews` 不会再次初始化创建；
- `FlutterImagaeView` 在 `createImageReader` 和 `updateCurrentBitmap` 时， Android 10 上可以通过 GPU 实现硬件加速，这也是为什么  `Hybrid Composition` 在  Android 10 上性能较好的原因。

因为篇（tou）幅(lan)剩下就不一一展开了，目前 `Hybrid Composition`  已经在 1.20 stable 版本上可用了，也解决了我在键盘上的一些问题，当然 Hybrid Composition 能否经受住考验那只能让时间决定了，毕竟一步一个坑不是么～


## 资源推荐

* Github ： https://github.com/CarGuo
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**