# Flutter 小技巧之 3.13 全新生命周期 AppLifecycleListener 

Flutter 3.13 在 Framework 里添加了 `AppLifecycleListener`  用于监听应用生命周期变化，并响应退出应用的请求等支持，那它有什么特殊之处？和老的相比又有什么不同？

简单说，在 Flutter 3.13 之前，我们一般都是用  `WidgetsBindingObserver` 的 `didChangeAppLifecycleState`  来实现生命周期的监听，只是 `didChangeAppLifecycleState`  方法比较「粗暴」，直接返回 `AppLifecycleState` 让用户自己处理，使用的时候需要把整个 `WidgetsBindingObserver`  通过 `mixin` 引入。

![](http://img.cdn.guoshuyu.cn/20230821_FL/image1.png)

而  `AppLifecycleListener`  则是在  `WidgetsBindingObserver.didChangeAppLifecycleState`  的基础上进行了封装，再配合当前 `lifecycleState` 形成更完整的生命周期链条，对于开发者来说就是使用更方便，并且 API 相应更直观。

![](http://img.cdn.guoshuyu.cn/20230821_FL/image2.png)

首先 `AppLifecycleListener`  是一个完整的类，所以使用它无需使用 `mixin` ，你只需要在使用的地方创建一个  `AppLifecycleListener` 对象即可。

```dart
late final AppLifecycleListener _listener;
late AppLifecycleState? _state;
@override
void initState() {
  super.initState();
  _state = SchedulerBinding.instance.lifecycleState;
  _listener = AppLifecycleListener(
    onShow: () => _handleTransition('show'),
    onResume: () => _handleTransition('resume'),
    onHide: () => _handleTransition('hide'),
    onInactive: () => _handleTransition('inactive'),
    onPause: () => _handleTransition('pause'),
    onDetach: () => _handleTransition('detach'),
    onRestart: () => _handleTransition('restart'),
    // This fires for each state change. Callbacks above fire only for
    // specific state transitions.
    onStateChange: _handleStateChange,
  );
}
void _handleTransition(String name) {
  print("########################## main $name");
}
```

其次，`AppLifecycleListener`  根据  `AppLifecycleState` 区分好了所有 Callback 调用，调用编排更加直观。

最后，`AppLifecycleListener`   可以更方便去判断和记录整个生命周期的链条变化，因为它已经帮你封装好回调方法，例如：

- 从 `inactive` 到 `resumed` 调用的是 `onResume` 
- 从 `detached` 到 `resumed` 调用的是 `onStart`

![](http://img.cdn.guoshuyu.cn/20230821_FL/image3.png)

现在通过 `AppLifecycleListener`   的回调，我们可以更方便和直观的感知到整个生命周期变化的链条，并且 3.13 正式版中还引入了一个全新的状态 ： 「`hidden`」，当然它其实在 Android/iOS 上是不工作的。

![](http://img.cdn.guoshuyu.cn/20230821_FL/image4.png)

因为  `hidden` 这个概念在移动  App 上并不实际存在，例如它定义在这里只是为了对齐统一所有状态。

虽然在移动 App 平台虽然没有 `hidden` 这个状态，但是例如你在  Android 平台使用 `AppLifecycleListener`  ，却还是可以收到  `hidden`  的状态回调，为什么会这样我们后面解释。

首先我们简单看下  `AppLifecycleState`  的几个状态：

#### detached

App 可能还存有 Flutter Engine ，但是视图并不存在，例如没有 `FlutterView` ，Flutter 初始化之前所处的默认状态。

也就是其实没有视图的情况下 Engine 还可以运行，一般来说这个状态仅在 iOS 和 Android 上才有，尽管所有平台上它是开始运行之前的默认状态，一般不严谨要求的情况下，可以简单用于退出 App 的状态监听。

#### resumed

表示 App 处于具有输入焦点且可见的正在运行的状态。

例如在 iOS 和 macOS 上对应于在前台活动状态。

Android 上无特殊情况对应 `onResume` 状态，但是其实和 `Activity.onWindowFocusChanged ` 有关系。

例如当存在多 Activity 时：

- 只有 Focus 为 true 的 Activity ，进入  `onResume`  才会是 `resumed`
- 其他 Focus 为 false 的 Activity，进入  `onResume`  会是 `inactive`

只要还是看 `Activity.onWindowFocusChanged `  回调里是否 Foucs，只是默认情况下 Flutter 只有单 Activity ，所以才说无特殊情况对应 `onResume` 状态。

![](http://img.cdn.guoshuyu.cn/20230821_FL/image5.png)



#### inactive

App 至少一个视图是可见的，但没有一个视图具 Focus。

- 在非 Web 桌面平台上，这对应于不在前台但仍具有可见窗口的应用。
- 在 Web ，这对应没有焦点的窗口或 tab 里运行的应用。
- 在 iOS 和 macOS 上，对应在前台非活动状态下运行的 Flutter 视图，例如出现电话、生物认证、应用切换、控制中心时。
- 在 Android 上，这对应 Activity.onPause 已经被调用或  `onResume`   时没有 Focus 的状态。（分屏、被遮挡、画中画）

> 在 Android 和 iOS 上， inactive 可以认为它们马上会进入 hidden 和 paused 状态。

#### paused

App 当前对用户不可见，并且不响应用户行为。

当应用程序处于这个状态时，Engine 不会调用 `PlatformDispatcher.onBeginFrame` 和`PlatformDispatcher.onDrawFrame`  回调。

> 仅在 iOS 和 Android 上进入此状态。

![](http://img.cdn.guoshuyu.cn/20230821_FL/image6.png)

#### hidden

App 的所有视图都被隐藏。

- 在 iOS 和 Android 上说明马上要进入 paused。

- 在 PC 上说明最小化或者不再可见的桌面上。
- 在 Web 上说明在不可见的窗口或选项卡中。



所以从上面可以看到，其实不同平台的生命周期还是存在差异的，而   `AppLifecycleState`   的作用就是屏蔽这些差异，并且由于历史原因，目前 Flutter 的状态名称并不与所平台上的状态名称一一对应，例如 ：

> 在 Android 上，当系统调用  Activity.onPause 时，Flutter 会进入 inactive 状态；但是当 Android 调用 Activity.onStop，Flutter会进入 paused 状态。

![](http://img.cdn.guoshuyu.cn/20230821_FL/image7.png)

> 当然，如果 App 被任务管理器、crash、kill signal 等场景销毁时，用户是无法收到任何回调通知的。

那么这时候，你再回过头来看 `hidden` ，就会知道为什么它在 Android 和 iOS 上并没有实际意义，因为它是为了 PC 端（最小化/不可见）而存在，但是如果你通过  `AppLifecycleListener`  进行监听，你会发现其实是可以收到 `hidden`  的回调，例如在 Android 和 iOS 上 ：

- 前台到后台： inactive - hide - pause

- 后台回前台：restart - show - resume

明明在原生 Android 和 iOS 上并没有  `hidden`  ，那为什么 Dart 里又会触发呢？

这是因为 Flutter 在 Framework 为了保证 Dart 层面生命周期的一致性，会对生命周期调用进去「补全」。

例如在退到后台时，native 端只发送了 `inactive` 和 `pause` 两个状态，但是收到  `pause` 时，在 `_generateStateTransitions` 方法里，会根据 `pause` 在  `AppLifecycleState` 里的位置（pause 和 inactive 之间还有 hidden） ，在代码里「手动」加入 `hidden`  从而触发 `onHide` 调用。

![](http://img.cdn.guoshuyu.cn/20230821_FL/image8.png)

![](http://img.cdn.guoshuyu.cn/20230821_FL/image9.png)

所以，在 Android 和 iOS 端使用  `AppLifecycleState`  时，我们一般不要去依赖  `onHide` 回调，因为本质上它并不适用于移动端的生命周期。

最后，`AppLifecycleState`   还提供了 `onExitRequested` 方法，但是它并不支持类似 Android 的 back 返回拦截场景，而是需要通过  `ServicesBinding.instance.exitApplication(AppExitType exitType)` 触发的退出请求，才可以被 `onExitRequested`  拦截，前提是调用时传入了 `AppExitType.cancelable` 。

> 也就是 `ServicesBinding.instance.exitApplication(AppExitType.cancelable);` 这样的调用才会触发  `onExitRequested` ，另外目前 `System.exitApplication` 的响应只在 PC 端实现，移动端不支持。

```dart
@override
void initState() {
  super.initState();
  _listener = AppLifecycleListener(
    onExitRequested: _handleExitRequest,
  );
}

Future<AppExitResponse> _handleExitRequest() async {
  var result = await showDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
            title: const Text('Exit'),
            content: const Text('Exit'),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          ));
  final AppExitResponse response =
      result ? AppExitResponse.exit : AppExitResponse.cancel;
  return response;
}
```

最后做个总结：

- `AppLifecycleListener`  的好处就是不用 mixin ，并且通过回调可以判断生命周期链条。
- `AppLifecycleState`  的状态和命名与原生端并不一定对应。
- Flutter 在单页面和多页面下可能会出现不同的状态相应。
- hidden 在 Android 和 iOS 端并不存在，它仅仅是为了统一而手动插入的中间过程。
- `onExitRequested` 只作用于 PC 端。