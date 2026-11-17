---
title: "Flutter 开始支持 Jetpack Compose Platform View"
---

# Flutter 开始支持 Jetpack Compose Platform View

 [PR #195523](https://github.com/flutter/flutter/pull/195523)  居然开始支持  Jetpack Compose 的 `ComposeView`  了，看起来是 Flutter 在给默认 `FlutterActivity` 补齐 AndroidX 的三个 ViewTree Owner，让 Compose 能找到生命周期、状态恢复和 ViewModel 的宿主。

> 理论上后面应该会直接支持 Compose 放进 HC、TLHC、VD 和 HCPP 四个场景里里面。

其实之前用 AndroidView 接 ComposeView 一直不太行，比如一个 Flutter App 要复用 Android 团队写好的 Compose 设备控制面板，然后 Flutter 侧放一个 `AndroidView(viewType: 'device_controls')`，原生插件通过 `PlatformViewFactory` 创建 `ComposeView`，再用 `setContent { DeviceControls() }` 绘制界面。

**一般来说普通 Android View 到这里就能显示了，但 Compose 在创建 Composition 时，还需要沿着当前 View 的父层级查找 AndroidX 提供的宿主信息**。

这里需要三个 Owner：

- `LifecycleOwner` 告诉 Compose 宿主什么时候启动、暂停和销毁
- `SavedStateRegistryOwner` 提供状态保存和恢复入口
- `ViewModelStoreOwner` 让 Compose 里的 ViewModel 有地方存放和复用

问题是，Flutter 默认的 `FlutterActivity` 直接继承的是 Android `Activity`，虽然它很早就实现了 `LifecycleOwner`，但是一直没有把它发布到 DecorView 的 ViewTree 上，也没有提供完整的 SavedStateRegistry 和 ViewModelStore。

> 也就是 ComposeView 往上查，就可能遇到 `ViewTreeLifecycleOwner not found`，之前在普通 ViewTree 下，可以通过 `FlutterFragmentActivity` 或者手动提供 Owner 来解决部分场景，因为它继承的 `FragmentActivity` 本身就具备 AndroidX 这些能力。

不过这次算是开始正式扶正了，看草稿，这次 `FlutterActivity` 新增 `SavedStateRegistryOwner`、`ViewModelStoreOwner` 接口，然后在 `setContentView(createFlutterView())` 之后，把三个 Owner 设置到 DecorView。

同时 `onCreate()` 会在 Lifecycle 进入 `ON_CREATE` 前恢复 SavedStateRegistry，`onSaveInstanceState()` 负责保存，而 ViewModelStore 会通过 `onRetainNonConfigurationInstance()` 尝试跨旋转等配置变更复用，Activity 真正销毁时再清理。

大概情况类似：

| Compose 需要的对象 | 以前默认 FlutterActivity 的问题 | 这次补上的能力 |
| --- | --- | --- |
| `LifecycleOwner` | Activity 有生命周期，但 ViewTree 不一定能查到 | 发布到 DecorView |
| `SavedStateRegistryOwner` | 缺少 AndroidX 状态保存入口 | 接入 Activity 的保存与恢复 |
| `ViewModelStoreOwner` | 缺少 ViewModel 作用域 | 创建、复用和清理 ViewModelStore |

> 这里的 SavedState 是 AndroidX 的机制，和 Flutter Widget 自己通过 Restoration Channel 恢复状态是两条路径。

## 真正麻烦的是 Virtual Display

而且只补 `FlutterActivity` 还不够，Virtual Display 这个老古董还在服役呢，而不同的 Platform View 合成方式，Android View 所处的位置并不一样。

HC、TLHC 和 HCPP 的这组场景里，ComposeView  可以沿所在的 Android ViewTree 找到宿主，但 Virtual Display 会把原生 View 放进 `SingleViewPresentation`，那是一个单独的 Window，和 Activity 的 DecorView 没有共同的父 View。

也就是就算 DecorView 已经设置了 Owner，里面的 ComposeView 还是看不到：

![](/article-assets/14fde54d7ba1141aefac8aa7.webp)

所以 PR 新增了 `ViewTreeOwners`：

> 在创建 Presentation 的时候，通过 `ViewTreeOwners.findFrom(flutterView)` 读取当前 FlutterView 能找到的三个 Owner，再在 `SingleViewPresentation.onCreate()` 的 `setContentView(rootView)` 之前调用 `installOn(rootView)`。

这样 ComposeView 附着到虚拟窗口的时候，也可以沿自己的父 View 往上找，就能从 Presentation 根节点找到对应的宿主。

另外比如你还缓存了一个 FlutterEngine，先把它挂在 Activity A，A 退出以后再把同一个 Engine 挂到 Activity B，这种场景也需要兼容，要是 Owner 在 Platform View 首次创建时就永久缓存，那 B 里的 ComposeView 可能还拿着已经销毁的 A 的 Lifecycle。

所以这个 PR 用回调在 Presentation 创建和重新创建时获取当前 FlutterView 的 Owner，`resize` 和 `resetSurface()` 路径也会重新设置，避免后面一直绑定旧宿主。

从目前提交的情况看，估计赶不上下个月的新版本，不过 2027 的版本应该没问题。
