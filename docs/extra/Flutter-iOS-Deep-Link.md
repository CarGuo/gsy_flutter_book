---
title: "Flutter iOS Deep Link 为什么会突然失效：一系列难以言喻的问题"
---

# Flutter iOS Deep Link 为什么会突然失效：一系列难以言喻的问题

这段时间应该有不少人遇到了，Flutter 项目升级之后，iOS Universal Link 可以正常把 App 拉起来，Associated Domains、AASA 文件看起来也都没有问题，但进入应用之后，`app_links` 会收不到链接，`getInitialLink()` 也返回空，Router 最后正常进入首页。

> 整个过程中没有异常也没有报错，就是静默失败。

但是实际上这是 Flutter 3.38 之后，特别是到了 Flutter 3.41，UIScene  正式成为 iOS App 的默认生命周期方案之后才会出现，**其中一个原因是旧插件和旧原生代码还在只监听 AppDelegate ，导致一部分 URL、OAuth、通知和生命周期事件开始静默丢失**。

因为 Universal Link 从用户点击到 Flutter 页面跳转，中间其实经过两套完全独立的流程。

第一段完全发生在 iOS 系统层，用户点击：`https://example.com/product/123`

iOS 会检查：

- AASA 文件
- Associated Domains
- Bundle ID
- Team ID
- entitlement
- 域名配置

这些条件满足以后，iOS 就会把 App 拉起来，到这里说明系统级匹配成功，但是真正将 URL 送进 Flutter 的工作还在后面，整个链路更接近：

![](https://img.cdn.guoshuyu.cn/01-universal-link-to-router.png)

如果这个过程里有任何一层中断，最终都有可能表现成：

![](https://img.cdn.guoshuyu.cn/02-click-link-open-home.png)

所以这类问题排查起来会很麻烦，有时候可能会需要花大量时间检查 AASA、GoRouter、Navigator、重定向规则等等，但实际上 URL 可能早就在 iOS Native lifecycle 那一层丢了。

那 UIScene 到底改了啥？主要是过去绝大多数 iOS Flutter 插件都依赖 `UIApplicationDelegate`，例如 Universal Link 通常监听：

```swift
application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: ...
)
```

Custom URL Scheme 常见的是：

```swift
application(
    _ app: UIApplication,
    open url: URL,
    options: ...
)
```

Flutter 插件也经常这样注册：

```swift
registrar.addApplicationDelegate(instance)
```

这套方式已经工作了很多年，所以 Flutter 插件生态里积累了大量基于 AppDelegate 生命周期的实现，而切换到 UIScene 以后，URL 相关 callback 会进入另一套生命周期。

Custom Scheme 对应：

```swift
scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
)
```

Universal Link 对应：

```swift
scene(
    _ scene: UIScene,
    continue userActivity: NSUserActivity
)
```

Flutter 官方迁移文档给出的映射就很明确：

![](https://img.cdn.guoshuyu.cn/03-appdelegate-useractivity-to-scene.png)

> 图片资源缺失：application:openURL:options: → scene:openURLContexts:



也就是一旦 App 采用 UIScene，一部分过去通过 AppDelegate 接收的 UI 生命周期事件就不会继续按照旧路径调用，这就产生了一个兼容性问题，某个 Flutter 插件只注册了：

```swift
registrar.addApplicationDelegate(instance)
```

但是没有注册：

```swift
registrar.addSceneDelegate(instance)
```

那么 App 已经完成 UIScene 迁移之后，插件就可能完全收不到 URL，系统知道链接应该打开你的 App，App 也确实被打开了，只有插件不知道用户点了什么。

这个问题在 app_links 6.x  就有了，然后 `app_links 7.0.0`  才重点处理了 Flutter 3.38 的 iOS Scene lifecycle 变化，同时增加了 `UISceneDelegate` 的支持。

不过最低 Flutter 版本也被提升到了 3.38.1 ，**也就是实际上插件开发者需要面临一个问题，是直接断档支持新版本，还是兼容支持新旧版本**。

Flutter 给插件作者提供的新生命周期接口包括：

```text
FlutterSceneLifeCycleDelegate
FlutterPluginSceneLifeCycleDelegate
FlutterSceneLifeCycleProvider
```

插件注册阶段也新增了：

```swift
registrar.addSceneDelegate(instance)
```

所以如果需要同时兼容旧工程和 UIScene 工程的插件，通常会同时注册：

```swift
registrar.addApplicationDelegate(instance)
registrar.addSceneDelegate(instance)
```

所以如果你的插件或者原生代码有类似：

- Universal Link
- Custom Scheme
- OAuth Callback
- 登录回调
- Shortcut
- Notification
- 第三方 SDK URL 回调
- App 前后台状态

那就必须有 `addSceneDelegate` ，因为 UIScene 已经是强制要求了。

**当然如果是这样还好，核心是 Flutter 自带 Deep Link 处理器还会制造第二层冲突** ，比如 `FlutterDeepLinkingEnabled` ，实际上 Flutter 在 3.27 左右就已经将内置 Deep Link handler 默认开启，如果项目本身用 Flutter Router 直接处理 Deep Link，这个机制很方便。

问题在于很多项目已经用了第三方插件，比如：

- app_links
- uni_links
- flutter_branch_sdk

这时候就可能出现两个 Deep Link handler 同时工作，所以如果用了第三方 Deep Link 插件，实际上你是需要关闭 Flutter 默认 Deep Link handler，比如在 Info.plist ：

```xml
<key>FlutterDeepLinkingEnabled</key>
<false/>
```

不然它导致的现象会更加诡异的情况，比如：

![](https://img.cdn.guoshuyu.cn/05-flutter-handler-fallback-to-safari.png)

那为什么 Universal Link 可能重新跳到 Safari ？

实际上这部分从 Flutter iOS Embedder 的实现可以直接看出来，Flutter AppDelegate 会先询问已经注册的插件是否处理了 `continueUserActivity` ，如果没有插件消费，Flutter 会继续尝试把 Deep Link 交给 Framework。

Framework 最终也没有成功处理时，Universal Link 存在一条 fallback 路径：`把 URL 再交还给 iOS`，然后浏览器就可能被打开，然后如果网页里又存在：

```text
myapp://xxx
```

或者 Branch、AppsFlyer、Firebase、JavaScript redirect 一类二次跳转逻辑，就可能又再拉起 App，然后最终用户看到的是：

![](https://img.cdn.guoshuyu.cn/07-app-safari-bounce.png)

**这看起来就像是 AASA 配错、Safari 行为异常，但是实际问题其实是 Deep Link handler 没有正确消费 URL**。

主要事情到这样还没结束，就算插件适配了 UIScene，Dart 层依旧可能因为监听时机太晚而丢失 Deep Link，惊不惊喜，意不意外？因为很多 Flutter 项目的启动逻辑现在越来越复杂，比如：

![](https://img.cdn.guoshuyu.cn/08-startup-init-chain.png)

如果 App 是通过 Deep Link 冷启动，URL 很可能在非常早就已经到达，然后等所有初始化完成以后再执行：

```dart
uriLinkStream.listen(...)
```

事件窗口可能早就过去了，所以`app_links` 官方现在也明确建议，`AppLinks` 应该尽早创建捕获第一个链接，所以更稳妥的方式是把 Deep Link 当成 App 的基础事件输入源，需要在应用启动后尽快监听：

```dart
late final AppLinks appLinks;

void initDeepLinks() {
  appLinks = AppLinks();

  appLinks.uriLinkStream.listen((uri) {
    handleOrQueue(uri);
  });
}
```

如果 Router、Auth 或数据库暂时没有准备好，就先存起来，这样 cold start、warm start、登录恢复这些场景会更加统一。

![](https://img.cdn.guoshuyu.cn/09-pending-link-queue.png)

还有另外一个更隐蔽的问题：URL 收到了，但 Startup 永远没有 Ready ，比如  `await FirebaseMessaging.instance.getInitialMessage();` 可能在某些情况下不返回，而启动流程又类似：

![](https://img.cdn.guoshuyu.cn/10-startup-ready-chain.png)

于是结果就会变成如下所示，而这时候日志甚至已经可以看到 URL。

![](https://img.cdn.guoshuyu.cn/11-pending-link-stuck.png)

**这时候你看 Universal Link、app_links 或 Router 都很难找到真正问题，因为链接传输链已经完全正常，真正卡住的是整个启动状态机**。

这种设计其实在现在的 Flutter 项目里非常常见，很多项目的 `main()` 或 Splash 初始化逻辑类似：

```dart
await initFirebase();
await initRemoteConfig();
await initMessaging();
await initDatabase();
await initAuth();
await initAnalytics();
await initFeatureFlags();
await initRouter();
```

这条链上只要一个 SDK 出现 callback 没返回、网络超时、权限状态异常，后面的所有功能就一起停住，所以对于不得不等待的第三方 SDK，也最好设置 timeout 和 fallback：

```dart
try {
  await FirebaseMessaging.instance
      .getInitialMessage()
      .timeout(const Duration(seconds: 2));
} catch (_) {
  // fallback
} finally {
  markStartupReady();
  drainPendingLinks();
}
```

所以，实际上 iOS Deep Link 本身就很恶心了，系统成名就是一条相当长的事件链，加上 Flutter ，大概类似：

![](https://img.cdn.guoshuyu.cn/12-deeplink-debug-chain.png)

然后这里从第 2 步到第 10 步中的任意一步出问题，就会看到结果拿不到，然后根据不同问题，就需要排查不同方向：

如果第 2 步失败，就需要检查：

```text
AASA
Associated Domains
Bundle ID
Team ID
```

如果第 4、5 步失败，就需要重点检查：

```text
UIScene
FlutterSceneDelegate
Scene lifecycle
```

如果第 6 步失败，就要检查：

```text
插件版本
addSceneDelegate
FlutterSceneLifeCycleDelegate
```

如果第 7 步失败，就需要检查：

```text
Platform Channel
EventChannel
listener 初始化时机
```

如果第 8 到第 10 步失败，问题已经进入应用自己的状态管理：

```text
Pending Link
Auth
Startup Ready
Router
Navigation
```

所以 DeepLink 那问题，需要优先确认 URL 到底走到了哪一层，排查起来也很费时费力，加上 SDK 和系统冲突，还有初始化卡死，这类问题确实很让人难顶。
