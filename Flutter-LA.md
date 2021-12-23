APP 启动页在国内是最常见也是必备的场景，其中启动页在 iOS 上算是强制性的要求，其实配置启动页挺简单，因为在 Flutter 里现在只需要：


- iOS  配置 `LaunchScreen.storyboard`；
- Android 配置 `windowBackground`;

一般只要配置无误并且图片尺寸匹配，基本上就不会有什么问题，**那既然这样，还有什么需要适配的呢？**

事实上大部分时候 iOS 是不会有什么问题，**因为 `LaunchScreen.storyboard` 的流程本就是 iOS 官方用来做应用启动的过渡；而对于 Andorid 而言，直到 12 之前 `windowBackground` 这种其实只能算“民间”野路子**，所以对于 Andorid 来说，这其中就涉及到一个点：

> [Flutter's first frame] + [time needed to jump from raster to main thread and get a next Android vsync] = [Android's first frame]. 


所以下面主要介绍 Flutter 在 Android 上为了这个启动图做了哪些骚操作～


 ## 一、远古时期

**在已经忘记版本的“远古时期”**， `FlutterActivity` 还在 `io.flutter.app.FlutterActivity` 路径下的时候，那时启动页的逻辑相对简单，主要是通过 App 的 `AndroidManifest` 文件里是否配置了 `SplashScreenUntilFirstFrame` 来进行判断。


 ```xml
  <meta-data
     android:name="io.flutter.app.android.SplashScreenUntilFirstFrame"
     android:value="true" />
 ```

**在 `FlutterActivity` 内部 `FlutterView` 被创建的时候，会通过读取 `meta-data` 来判断是否需要使用 `createLaunchView` 逻辑**：

 - 1、获取当前主题的 `android.R.attr.windowBackground` 这个 `Drawable` ；
 - 2、创建一个 `LaunchView` 并加载这个 `Drawable`；
 - 3、将这个 `LaunchView` 添加到 `Activity` 的 `ContentView`；
 - 4、在Flutter `onFirstFrame` 时将这个 `LaunchView` 移除；


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-LA/image1)


 ```java
     private void addLaunchView() {
        if (this.launchView != null) {
            this.activity.addContentView(this.launchView, matchParent);
            this.flutterView.addFirstFrameListener(new FirstFrameListener() {
                public void onFirstFrame() {
                    FlutterActivityDelegate.this.launchView.animate().alpha(0.0F).setListener(new AnimatorListenerAdapter() {
                        public void onAnimationEnd(Animator animation) {
                            ((ViewGroup)FlutterActivityDelegate.this.launchView.getParent()).removeView(FlutterActivityDelegate.this.launchView);
                            FlutterActivityDelegate.this.launchView = null;
                        }
                    });
                    FlutterActivityDelegate.this.flutterView.removeFirstFrameListener(this);
                }
            });
            this.activity.setTheme(16973833);
        }
    }
 ```


是不是很简单，那就会有人疑问为什么要这样做？我直接配置 `Activity` 的 `android:windowBackground` 不就完成了吗？

这就是上面提到的时间差问题，**因为启动页到 Flutter 渲染完第一帧画面中间，会出现概率出现黑屏的情况，所以才需要这个行为来实现过渡**。


 ## 2.5 之前


经历了“远古时代”之后，`FlutterActivity` 来到了 `io.flutter.embedding.android.FlutterActivity`， 在到 2.5 版本发布之前，Flutter 又针对这个启动过程做了不少调整和优化，其中主要就是 `SplashScreen`。


自从开始进入`embedding` 阶段后，`FlutterActivity` 主要用于实现了一个叫 `Host` 的 `interface`，其中和我们有关系的就是 `provideSplashScreen`。 

**默认情况下它会从 `AndroidManifest` 文件里是否配置了 `SplashScreenDrawable` 来进行判断**。

```xml
 <meta-data
      android:name="io.flutter.embedding.android.SplashScreenDrawable"
      android:resource="@drawable/launch_background"
      />
```

默认情况下当 AndroidManifest 文件里配置了 `SplashScreenDrawable`，那么这个 Drawable 就会在 `FlutterActivity` 创建 `FlutterView` 时被构建成 `DrawableSplashScreen`。


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-LA/image2)


`DrawableSplashScreen` 其实就是一个实现了 `io.flutter.embedding.android.SplashScreen` 接口的类，它的作用就是：

> 在 Activity  创建 FlutterView 的时候，将 `AndroidManifest` 里配置的 `SplashScreenDrawable` 加载成 `splashScreenView`(ImageView)；，并提供 `transitionToFlutter` 方法用于执行。


之后 `FlutterActivity` 内会创建出 `FlutterSplashView`，它是个 FrameLayout。

`FlutterSplashView` 将 `FlutterView` 和 `ImageView` 添加到一起， 然后通过 `transitionToFlutter` 的方法来执行动画，最后动画结束时通过 `onTransitionComplete` 移除 `splashScreenView` 。


所以整体逻辑就是：

- 根据 meta 创建 `DrawableSplashScreen` ； 
- `FlutterSplashView` 先添加了 `FlutterView` ；
- `FlutterSplashView` 先添加了 `splashScreenView` 这个 ImageView；
- 最后在 `addOnFirstFrameRenderedListener` 回调里执行 `transitionToFlutter` 去触发 animate ，并且移除 `splashScreenView`。


当然这里也是分状态：

- 等引擎加载完成之后再执行  `transitionToFlutter`；
- 引擎已经加载完成了马上执行 `transitionToFlutter`；
- 当前的 `FlutterView` 还没有被添加到引擎，等待添加到引擎之后再 `transitionToFlutter`;

 ```java
    public void displayFlutterViewWithSplash(@NonNull FlutterView flutterView, @Nullable SplashScreen splashScreen) {
        if (this.flutterView != null) {
            this.flutterView.removeOnFirstFrameRenderedListener(this.flutterUiDisplayListener);
            this.removeView(this.flutterView);
        }

        if (this.splashScreenView != null) {
            this.removeView(this.splashScreenView);
        }

        this.flutterView = flutterView;
        this.addView(flutterView);
        this.splashScreen = splashScreen;
        if (splashScreen != null) {
            if (this.isSplashScreenNeededNow()) {
                Log.v(TAG, "Showing splash screen UI.");
                this.splashScreenView = splashScreen.createSplashView(this.getContext(), this.splashScreenState);
                this.addView(this.splashScreenView);
                flutterView.addOnFirstFrameRenderedListener(this.flutterUiDisplayListener);
            } else if (this.isSplashScreenTransitionNeededNow()) {
                Log.v(TAG, "Showing an immediate splash transition to Flutter due to previously interrupted transition.");
                this.splashScreenView = splashScreen.createSplashView(this.getContext(), this.splashScreenState);
                this.addView(this.splashScreenView);
                this.transitionToFlutter();
            } else if (!flutterView.isAttachedToFlutterEngine()) {
                Log.v(TAG, "FlutterView is not yet attached to a FlutterEngine. Showing nothing until a FlutterEngine is attached.");
                flutterView.addFlutterEngineAttachmentListener(this.flutterEngineAttachmentListener);
            }
        }

    }

    private boolean isSplashScreenNeededNow() {
        return this.flutterView != null && this.flutterView.isAttachedToFlutterEngine() && !this.flutterView.hasRenderedFirstFrame() && !this.hasSplashCompleted();
    }

    private boolean isSplashScreenTransitionNeededNow() {
        return this.flutterView != null && this.flutterView.isAttachedToFlutterEngine() && this.splashScreen != null && this.splashScreen.doesSplashViewRememberItsTransition() && this.wasPreviousSplashTransitionInterrupted();
    }

 ```

 **当然这个阶段的 FlutterActivity 也可以通过 `override` `provideSplashScreen`  方法来自定义  SplashScreen**。

 > 注意这里的 SplashScreen 不等于 Android 12 的 SplashScreen。

看到没有，做了这么多其实也就是为了弥补启动页和 Flutter 渲染之间，**另外还有一个优化，叫  `NormalTheme`**。


> 当我们设置了一个 `Activity` 的 `windowBackground` 之后，其实对性能还是多多少少会有影响，所以官方就增加了一个 `NormalTheme` 的配置，**在启动完成之后将主题设置为开发者自己配置的 `NormalTheme`**。

通过该配置 `NormalTheme` ，在 `Activity` 启动时，就会首先执行 `switchLaunchThemeForNormalTheme();` 方法将主题从 `LaunchTheme` 切换到 `NormalTheme`。


```xml
    <meta-data
        android:name="io.flutter.embedding.android.NormalTheme"
        android:resource="@style/NormalTheme"
        />
       
```

大概配置完就是如下样子，**前面分析那么多其实就是为了告诉你，如果出现问题了，你可以从哪个地方去找到对应的点**。

```xml
<activity
    android:name=".MyActivity"
    android:theme="@style/LaunchTheme"
    // ...
    >
    <meta-data
        android:name="io.flutter.embedding.android.NormalTheme"
        android:resource="@style/NormalTheme"
        />
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
</activity>
```

 ## 2.5 之后


讲了那么多，**Flutter 2.5 之后 `provideSplashScreen` 和  `io.flutter.embedding.android.SplashScreenDrawable` 就被弃用了，惊不喜惊喜，意不意外，开不开心** ？


> Flutter 官方说： Flutter 现在会自动维持着 Android 启动页面的效显示，直到 Flutter 绘制完第一帧后才消失。

通过源码你会发现，当你设置了 `splashScreen` 的时候，会看到一个 log 警告：


```java
    if (splashScreen != null) {
      Log.w(
          TAG,
          "A splash screen was provided to Flutter, but this is deprecated. See"
              + " flutter.dev/go/android-splash-migration for migration steps.");
      FlutterSplashView flutterSplashView = new FlutterSplashView(host.getContext());
      flutterSplashView.setId(ViewUtils.generateViewId(FLUTTER_SPLASH_VIEW_FALLBACK_ID));
      flutterSplashView.displayFlutterViewWithSplash(flutterView, splashScreen);

      return flutterSplashView;
    }
```

为什么会弃用？
其实这个提议是在 https://github.com/flutter/flutter/issues/85292  这个 issue 上，然后通过 https://github.com/flutter/engine/pull/27645 这个 pr 完成调整。

大概意思就是：**原本的设计搞复杂了，用 `OnPreDrawListener` 更精准，而且不需要为了后面 Andorid12 的启动支持做其他兼容，只需要给 FlutterActivity 等类增加接口开关即可**。

也就是2.5之后 Flutter 使用 [ViewTreeObserver.OnPreDrawListener](https://developer.android.com/reference/android/view/ViewTreeObserver.OnPreDrawListener) 来实现延迟直到加载出 Flutter 的第一帧。

为什么说默认情况？**因为这个行为在 FlutterActivity 里，是在 `getRenderMode() == RenderMode.surface` 才会被调用，而 `RenderMode` 又和 `BackgroundMode` 有关心**。

> 默认情况下 BackgroundMode 就是 `BackgroundMode.opaque` ，所以就是 `RenderMode.surface`

所以在 2.5 版本后， FlutterActivity 内部创建完 FlutterView 后就会执行一个 `delayFirstAndroidViewDraw` 的操作。

```java

private void delayFirstAndroidViewDraw(final FlutterView flutterView) {
    if (this.host.getRenderMode() != RenderMode.surface) {
        throw new IllegalArgumentException("Cannot delay the first Android view draw when the render mode is not set to derMode.surface`.");
    } else {
        if (this.activePreDrawListener != null) {
            flutterView.getViewTreeObserver().removeOnPreDrawListener(this.activePreDrawListener);
        }

        this.activePreDrawListener = new OnPreDrawListener() {
            public boolean onPreDraw() {
                if (FlutterActivityAndFragmentDelegate.this.isFlutterUiDisplayed && terActivityAndFragmentDelegate.this.activePreDrawListener != null) {
                    flutterView.getViewTreeObserver().removeOnPreDrawListener(this);
                    FlutterActivityAndFragmentDelegate.this.activePreDrawListener = null;
                }

                return FlutterActivityAndFragmentDelegate.this.isFlutterUiDisplayed;
            }
        };
        flutterView.getViewTreeObserver().addOnPreDrawListener(this.activePreDrawListener);
    }
}

```

**这里主要注意一个参数：`isFlutterUiDisplayed`。** 

当 Flutter 被完成展示的时候，`isFlutterUiDisplayed` 就会被设置为 true。

**所以当 Flutter 没有执行完成之前，`FlutterView` 的 `onPreDraw` 就会一直返回 false**，这也是 Flutter 2.5 开始之后适配启动页的新调整。



## 最后


看了这么多，大概可以看到其实开源项目的推进并不是一帆风顺的，没有什么是一开始就是最优解，而是经过多方尝试和交流，才有了现在的版本，事实上开源项目里，类似这样的经历数不胜数：


![](http://img.cdn.guoshuyu.cn/20211223_Flutter-LA/image3)