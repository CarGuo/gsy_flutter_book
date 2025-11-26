# Flutter 3.38  发布，快来看看有什么更新吧

在 11 月 13 日的 FlutterFlightPlans 直播中，Flutter 3.38 如期而至，本次版本主要涉及 **Dot shorthands、Web 支持增强、性能改进、问题修复和控件预览等方面**。

![](https://img.cdn.guoshuyu.cn/82b5556a-f27f-4a51-b5de-4273d446f03b.png)

# Dot shorthands

在 Dart 3.10 + Flutter 3.38 中开始默认支持 Dot shorthands ，通过 Dot shorthands 可以使用简写方式省略类型前缀，例如使用 `.start` 而不是 `MainAxisAlignment.start`  ：

```dart
// With shorthands
Column(
  mainAxisAlignment: .start,
  crossAxisAlignment: .center,
  children: [ /* ... */ ],
),

// Without shorthands
Column(
  mainAxisAlignment: MainAxisAlignment.start,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [ /* … */ ],
),

```

类似的还有  `.all` 而不是 `EdgeInsets.all`：

```dart
Padding(
  padding: .all(8.0),
  child: Text('Hello world'),
),
```

> 详细可见我们在之前聊过的 [《Flutter 合并 'dot-shorthands' 语法糖》](https://juejin.cn/post/7500234308432445451) 。

# Web 增强

`flutter run` 命令现在支持设置 Web 的配置文件，可以在工程根目录放入 `web_dev_config.yaml` 来配置 web 主机、端口、证书、headers 等，例如：

```yaml
server:
  host: "0.0.0.0" # Defines the binding address <string>
  port: 8080 # Specifies the port <int> for the development server
  https:
    cert-path: "/path/to/cert.pem" # Path <string> to your TLS certificate
    cert-key-path: "/path/to/key.pem" # Path <string> to TLS certificate key
```

通过支持代理 (proxy) 设置，还可以将请求转发到配置的路径到另一台服务器：

```yaml
server:
  proxy:
    - target: "http://localhost:5000/" # Base URL <string> of your backend
      prefix: "/users/" # Path <string>
    - target: "http://localhost:3000/"
      prefix: "/data/"
      replace: "/report/" # Replacement <string> of path in redirected URL (optional)
    - target: "http://localhost:4000/"
      prefix: "/products/"
      replace: ""
```

最后 3.38 还增强了 Flutter Web 的 hot reload 并默认开启，当以 `-d web-server` 参数运行并在浏览器打开时，可以支持多个浏览器同时连接 hot reload 。

> 当然，和  `-d chrome` 一样，你也可以使用 `--no-web-experimental-hot-reload` 标志暂时禁用，不过禁用功能将在将来的版本中删除。

# Framework

本次 Framework 调整主要围绕交互优化相关，比如帮助开发人员可以更精细地控制 UI、导航和平台交互等。

首先是引入了新的 `OverlayPortal`，允许将子 Widget 渲染在任一 `Overlay` 上，通过 `overlayChildLayoutBuilder` 可以更灵活地显示弹出、对话框、通知等 UI ，例如：

```dart

class _OverlayPortalExampleState extends State<OverlayPortalExample> {
  final OverlayPortalController _controller = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OverlayPortal')),
      body: Center(
        child: OverlayPortal.overlayChildLayoutBuilder(
          controller: _controller,
          /// ****可以配置 root****
          overlayLocation: OverlayChildLocation.rootOverlay,
          child: ElevatedButton(
            onPressed: () => _controller.toggle(),
            child: const Text('点击显示浮层'),
          ),
          overlayChildBuilder: (context, info) {
            return Material(
              elevation: 4,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Text('这是一个浮层'),
              ),
            );
          },
        ),
      ),
    );
  }
}


```

**通过 `overlayChildLayoutBuilder` 可以拿到主 Widget 的位置信息**，可将浮层显示在任意屏幕位置，比如按钮下方、屏幕中心、或与鼠标位置对齐。

接着是在 Android 平台下，**使用 `MaterialApp` 时默认启用了预测后退路由转场 (predictive back route transitions)，后退手势时能看到当前界面预览**，此外默认页面转换已从 `ZoomPageTransitionsBuilder` 更新为 `FadeForwardsPageTransitionsBuilder` 。

然后就是久违的 PC 端更新，**针对 Windows 桌面开发增强**：可访问已连接显示器列表，并查询每个显示器的分辨率、刷新率、物理尺寸等属性，算是对多窗口模式的增强，例如 `PlatformDispatcher.displays `获取到 当前所有显示器：

```dart

void printDisplayInfos() {
  final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
  final displays = platformDispatcher.displays;

  for (final display in displays) {
    final id = display.id;
    final size = display.size; // Size in logical pixels
    final dpr = display.devicePixelRatio;
    final refreshRate = display.refreshRate;
  }
}
```



同时，现在如果在  Widget 生命周期回调中发生的错误（例如 `didUpdateWidget`）可以更优雅地处理，防止它们在元素树中导致级联故障 （[#173148](https://github.com/flutter/flutter/pull/173148)），以前如果开发者在这些回调中抛出了异常（哪怕只是一个小错误），**整个元素树可能会进入不一致状态或直接崩溃**。

而现在 Framework 在这些生命周期阶段调用时， **将内部异常捕获包装在更安全的范围内**，也就是说，如果你的某个子 Widget 在 `didUpdateWidget()` 抛出错误， Flutter 会：

- 捕获这个错误；
- 上报给 Flutter 的全局错误处理系统（`FlutterError.onError`）；
- 允许其他 widget 正常 rebuild；
- 避免整个 Element Tree 出现「级联错误」(cascade failure)

也就是让错误隔离更强，不再因为一个 widget 的生命周期异常破坏整个界面，而 IDE 中仍然能看到详细的异常栈，从而让应用的健壮性显著提升（尤其对热重载、动态组件更新等场景）。

最后是一些问题修复，例如：

- 修复了之前 `ResizeImage` 的 `==` 和 `hashCode` 实现不正确的问题，在之前即使两个 `ResizeImage` 指向同一底层图像和相同尺寸， Flutter 也认为它们不相等
- 在 Web 上继续修复 `RSuperellipse`，以防止在角半径大于 Widget 本身 （[#172254](https://github.com/flutter/flutter/pull/172254)） 时出现渲染错误
- 对于国际用户来说，检测浏览器的首选区域设置得到优化，引擎现在使用标准的 `Intl.Locale` Web API 来解析浏览器语言，取代了以前的手动实现 （[#172964](https://github.com/flutter/flutter/pull/172964)）
- 修复了 Android 的特定错误 （[#171973](https://github.com/flutter/flutter/pull/171973)） ，主要影响配备硬件键盘的三星设备，以前在用户与 `TextField` 交互后，Android 输入法编辑器 （IME） 可能会陷入过时状态，导致 IME 错误地拦截“Enter”或“Space”键按下，从而阻止非文本 Widget （如`复选框`或`单选`按钮）接收事件，而本次的修复可以确保在文本连接关闭时正确重置 `InputMethodManager`，清除 IME 的过时状态，并为用户还原可预测的硬件键盘交互



# Material 和 Cupertino  更新

在弃用 `MaterialState` 的基础上，3.38 继续内部迁移到更统一的 `WidgetState`，这提供了一种更一致的方式来定义控件在不同交互状态（例如按下、悬停或禁用）中的外观，并且开发这不需要对现有应用代码进行更改。

3.38 开始恰迁移已逐步应用在各种 Widget 及其主题，包括 `IconButton`、`ElevatedButton`、`Checkbox` 和 `Switch` （[#173893](https://github.com/flutter/flutter/pull/173893)），新的 API 还增加了功能和灵活性，例如：

- `IconButton` 现在包括一个 `statesController` 属性 （[#169821](https://github.com/flutter/flutter/pull/169821)），允许以编程方式控制其视觉状态
- `Badge.count` 构造函数现在包含一个 `maxCount` 参数 （[#171054](https://github.com/flutter/flutter/pull/171054)） ，可以限制显示的计数（例如，显示“99+”而不是“100”）
- 为了实现更细粒度的手势控制，`InkWell` 现在具有 `onLongPressUp` 回调 （[#173221](https://github.com/flutter/flutter/pull/173221)），可用于触发仅在用户抬起手指时才相应完成
- Cupertino 也继续朝着更好的 iOS 保真度迈进， `CupertinoSlidingSegmentedControl`  添加了`isMomentary` 属性 （[#164262](https://github.com/flutter/flutter/pull/164262)） 以允许控件触发而不保留选择，为了更好地匹配原生 iOS 行为，`CupertinoSheet` 在完全展开时向上拖动时具有微妙的“拉伸”效果 （[#168547](https://github.com/flutter/flutter/pull/168547)）![](https://img.cdn.guoshuyu.cn/ezgif-216e8a90fb3b17d6.gif)
- 修复 `DropdownMenuFormField` 在窗体重置时正确清除其文本字段 （[#174937](https://github.com/flutter/flutter/pull/174937)） 
- 更新 `SegmentedButton` 改进焦点处理 （[#173953](https://github.com/flutter/flutter/pull/173953)） 并确保其边框正确反映 Widget 的状态 （[#172754](https://github.com/flutter/flutter/pull/172754)）
- 滚动 (Scrolling) 和 Sliver 系列控件改进，例如 `SliverMainAxisGroup` / `SliverCrossAxisGroup` 在复杂滚动布局中手势处理、点击响应、焦点导航更可靠，例如：
  - 对多个 sliver 进行分组的开发人员会发现手势处理现在更加可靠，现在可以正确计算这些组中细片上的点击和其他指针事件的命中测试，确保用户交互按预期运行 （[#174265](https://github.com/flutter/flutter/pull/174265)）
  - 在 `SliverMainAxisGroup`  使用固定标题时过度滚动的问题已得到解决 （[#173349](https://github.com/flutter/flutter/pull/173349)），调用 `showOnScreen` 显示 sliver 现在可以正常工作 （[#171339](https://github.com/flutter/flutter/pull/171339)），并且内部滚动偏移量计算更加精确 （[#174369](https://github.com/flutter/flutter/pull/174369)）。
  - 对于构建自定义滚动视图的开发人员来说，新的 `SliverGrid.list` 构造函数 （[#173925](https://github.com/flutter/flutter/pull/173925)） 提供了一种更简洁的方法，可以从简单的子列表创建网格![](https://img.cdn.guoshuyu.cn/image-20251113054602411.png)
- 另外还改进了复杂布局中键盘和方向键用户的焦点导航，在具有不同滚动轴的嵌套滚动视图（例如水平轮播的垂直列表）中，定向焦点导航现在更具可预测性，可防止焦点在部分之间意外跳转 ![](https://img.cdn.guoshuyu.cn/ezgif-232f345088a73a38.gif)



最后， Material 和 Cupertino 与框架的解耦还在继续，核心内容就是，**解耦后需要作为第一方官方包发布**，需要自动化语义化版本管理，避免冲突，支持自定义发布（如跳过特定提交、批量破坏性变更），采用“批量发布”（Batch Release），使用 Cocoon cron job 每周生成合并 PR；开发者通过 “commit消息、PR 标签或独立changelog 文件标记变更，首选选项为 PR 独立 changelog 文件，由 bot 合并等。

另外就是 Widgets测试不导入Material/Cupertino；Cupertino不导入Material，Material负责所有多库导入测试，包括 Cupertino 兼容性和自适应等。

以下是一些关于Material 和 Cupertino 与框架的一些关键讨论地址：

- https://docs.google.com/document/u/1/d/18kjoP-4LAXEllugVOQRg6vZELyD6MuxlKilLD4lFxSY/edit
- https://docs.google.com/document/d/1jUoFaawutbYsCI5oY3pDP_l-xpv6FhDKlcI1-EoT02s/edit?tab=t.0

- https://docs.google.com/document/d/1y38TN9AUTyd0eTbu4kx4FiNgfsLDPvWvi92Fv5HWFjQ/edit?tab=t.0#heading=h.pub7jnop54q0

- https://docs.google.com/document/d/1UHxALQqCbmgjnM1RNV9xE2pK3IGyx-UktGX1D7hYCjs/edit?tab=t.0
- https://github.com/flutter/flutter/issues/177028

- https://docs.google.com/document/d/1oFezK5leJzTWA5lsw3BQGx7gLbhpSL8dMleU3HD7bNY/edit?tab=t.0



# Accessibility

对于构建复杂应用的开发人员，3.38 引入了使用 `WidgetsFlutterBinding.instance.ensureSemantics`   （[#174163](https://github.com/flutter/flutter/pull/174163)） 在 iOS 上默认打开辅助功能的功能，调试辅助功能问题现在变得更加容易，因为 `debugDumpSemanticsTree` 包含额外的文本输入验证结果信息，以帮助更快地诊断问题 （[#174677](https://github.com/flutter/flutter/pull/174677)）。

为了在基于 sliver 的滚动视图中实现高级可访问性，3.38 增加了新的 `SliverSemantics`  （[#167300](https://github.com/flutter/flutter/pull/167300)） ，与现有的 `Semantics`  非常相似，开发人员可以在 `CustomScrollView` 中使用 `SliverSemantics` 使用特定语义信息注释其 sliver 树的某些部分，这对于注释标题、分配语义角色以及为屏幕阅读器向 sliver 添加描述性标签特别有用，从而为用户提供更易于理解和访问的体验。

最后，核心 Widget 的可访问性不断完善，现在默认情况下可以访问 `CupertinoExpansionTile` （[#174480](https://github.com/flutter/flutter/pull/174480)），` AutoComplete ` 现在向用户宣布搜索结果的状态 （[#173480](https://github.com/flutter/flutter/pull/173480)）， `TimePicker` （[#170060](https://github.com/flutter/flutter/pull/170060)） 中有更大的触摸目标，有助于提供更易于访问的开箱即用体验。

# iOS

iOS 平台已经完整支持最新的 iOS 26、Xcode 26、macOS 26，特别是在命令行部署使用 `devicectl` 替代必须启动 Xcode App 的流程，现在 Flutter 3.38 可以在大多数情况下仅依赖于 Xcode26 命令行 构建工具，更多可见：

- [Flutter 在 iOS 26 模拟器跑不起来？其实很简单](https://juejin.cn/post/7560986017034190891)
- [Flutter 完成全新 devicectl + lldb 的 Debug JIT 运行支持](https://juejin.cn/post/7542461507402924075)

> 虽然官方说完全支持，但是 iOS26 问题还是有的，例如：[《来了解一下，为什么你的 Flutter WebView 在 iOS 26 上有点击问题？》](https://juejin.cn/post/7571306072423448618)

另外 Flutter 3.38 包括了对 Apple 强制的 [UIScene 生命周期](https://developer.apple.com/documentation/technotes/tn3187-migrating-to-the-uikit-scene-based-life-cycle)的基本支持，这是继 Apple 在 WWDC25 上宣布之后的一次关键的主动更新：“在 iOS 26 之后的版本中，任何使用最新 SDK 构建的 UIKit 应用都将需要使用 UIScene 生命周期，否则它将不会启动”。

> 详细可见：[iOS 26 开始强制 UIScene ，你的 Flutter 插件准备好迁移支持了吗？](https://juejin.cn/post/7565733796269981738) ，因为适配  UIScene 需要 迁移官方提供了手动迁移和自动迁移的支持，其中自动迁移需要配置 `flutter config --enable-uiscene-migration` ，更多迁移细节可见：https://docs.flutter.dev/release/breaking-changes/uiscenedelegate#migration-guide-for-flutter-apps

对于 UIScene 支持，更致命的主要还是插件开发者，对于插件作者而言 `UIScene` 迁移带来了更大的挑战：**必须确保插件既能在已经迁移到 `UIScene` 的新应用中正常工作，也要能在尚未迁移的旧应用或旧版 iOS 系统上保持兼容**，例如：

- 一个依赖生命周期事件的插件（例如，一个在应用进入后台时暂停视频播放的插件）不能简单地把监听代码从 `AppDelegate` 移到 `SceneDelegate`，这样做会导致它在未迁移的应用中完全失效，因此插件必须能够同时处理两种生命周期模型
- 具体插件迁移步骤：
  - **注册场景事件监听**：在插件的 `register(with registrar: FlutterPluginRegistrar)` 方法中，除了像以前一样通过 `registrar.addApplicationDelegate(self)` 注册 `AppDelegate` 事件监听外，还需要调用新的 API 来注册 `SceneDelegate` 事件的监听，Flutter 提供了相应的机制让插件可以接收到场景生命周期的回调
  - **实现双重生命周期处理**：插件内部需要实现 `UISceneDelegate` 协议中的相关方法，在实现时要设计一种优雅降级的逻辑。例如同时实现 `applicationDidEnterBackground` 和 `sceneDidEnterBackground`，当 `sceneDidEnterBackground` 被调用时，执行相应逻辑并设置一个标志位，以避免 `applicationDidEnterBackground`中的逻辑重复执行（如果它也被意外调用的话）
  - **更新废弃的 API 调用**：插件代码中任何对 `UIApplication.shared.keyWindow` 或其他与单一窗口相关的废弃 API 的调用都必须被替换

# Android

升级到 Flutter 3.38 是满足 [Google Play 16 KB 页面大小兼容性要求](https://developer.android.com/guide/practices/page-sizes)的重要准备工作， 因为 3.38 的更改可确保你的应用在高 RAM 设备上正常运行，并提供性能优势，例如启动速度提高多达 30%。

> Flutter 3.38 将默认的 Android ndkVersion 更新为 NDK r28，这是原生代码实现 16 KB 支持正确对齐所需的最低要求。

Flutter 3.38 还[修复（#173770）](https://github.com/flutter/flutter/issues/173770)了影响 Android 上所有 Flutter 应用的严重内存泄漏，该问题在 3.29.0 中引入，发生在退出时销毁 Activity 时出现。

对于 Flutter 3.38 版本，Android 环境目前的推荐配置：

- **Java 17**：Flutter 3.38 中 Android 开发所需的最低版本
- **KGP 2.2.20**：该工具已知且支持]的最大 Kotlin Gradle 插件版本
- **AGP 8.11.1**：与 KGP 2.2.20 兼容的最新 Android Gradle 插件版本
- **Gradle 8.14**：此版本适用于所选版本的 Java、KGP 和 AGP，请注意 Gradle 8.13 是 AGP 8.11.1 所需的最低版本。

为确保应用在 Flutter 版本之间无缝运行，强烈建议在构建文件中使用 Flutter SDK 提供的 API 级变量：

- `flutter.compileSdkVersion` (API 36)
- `flutter.targetSdkVersion` (API 36)
- `flutter.minSdkVersion` (API 24) or higher

# Engine

performance overlay  已经重构，现在提高效率的同时，减少了 Skia 和 Impeller 后端的渲染时间，这意味着可以以更少的开销获得更准确的性能数据。

对 Vulkan 和 OpenGL ES 后端的大量修复和改进提高了更广泛设备上的稳定性和性能，包括更好地处理管道缓存 （[#176322](https://github.com/flutter/flutter/pull/176322)）、fence waiters （[#173085](https://github.com/flutter/flutter/pull/173085)） 和 image layout transitions （[#173884](https://github.com/flutter/flutter/pull/173884)）。

另外对于 Web，继续统一 CanvasKit 和 Skwasm 渲染器的工作，3.38 包括了它们的重大重构，以在两者之间共享更多代码，这将在未来带来更一致的体验和更快的开发 （[#174588](https://github.com/flutter/flutter/pull/174588)）。

### 重点重点重点：iOS 和 Android 中已删除选择退出线程合并的功能。

# DevTools 和 IDE

Flutter 3.35 引入了 Widget Previews，而 Flutter 3.38 版本对 Widget Previews 进行了重大改进，包括 VSCode 和 Intellij / Android Studio 插件都已更新，初步支持 Widget Previews ，**可以直接在 IDE 中查看预览**：

![](https://img.cdn.guoshuyu.cn/fab31a5d-019c-45b9-908b-6f8222326da8.png)

在 IDE 中使用时，默认情况下  Widget Previews  环境配置为根据当前选定的源文件过滤显示的预览：

![](https://img.cdn.guoshuyu.cn/1_cvsiQjlzqc54_6D4HCsZCQ.gif)

另外，Widget Previews  现在支持浅色和深色模式，以及自定义 IDE 配色方案以匹配开发环境，控件预览环境中的控件也进行了调整，以使用更少的空间，从而为渲染预览留出更多空间。

![](https://img.cdn.guoshuyu.cn/2450e44b-3afa-4ef6-8b02-d87f10d55d9f.png)

此外，览批注类不再标记为最终批注，现在可以扩展以创建自定义预览批注，从而减少常见预览类型的样板：

![](https://img.cdn.guoshuyu.cn/1701c071-d38f-42ac-9b40-7fad74c949de.png)

并且新的 `MultiPreview` 基类允许从单个自定义注释创建多个预览变体：

![](https://img.cdn.guoshuyu.cn/ea689c0c-76e1-4319-bd81-8be5bd32b1ae.png)

`Preview` 类中的新 group 参数允许对相关预览进行分组，减少了对 `@Preview` 注释参数的限制，支持私有常量作为 `Preview` 注释的参数等。

![](https://img.cdn.guoshuyu.cn/b9e24bab-da55-4308-96ba-644ff7ab151a.png)

> 目前关于预览还有一些问题，例如 [#178317](https://github.com/flutter/flutter/issues/178317) ，例如 Widget 预览器可能会在 *flutter pub get*  后崩溃或停止更新。

其他关于 Tool 更新还有：

- Flutter DevTools Widget Inspector 正在增加支持适配预览
- IDE 中预览的多项目支持：预览目前仅支持显示单个项目或 Pub 工作区中包含的预览，多项目正在支持
- 正在推进预览的性能改进的机会，以减少初始启动时间
- Network Panel 的交互改进
- Flutter Inspector 修复了选择 Widget 有时会打开底层框架源代码而不是用户源代码的错误
- 修复了 Flutter Inspector  偶尔阻止与“检查器”面板中的顶部按钮交互的错误

# 弃用和重大变更

首先，3.38 进行了可能影响自定义生成脚本的关键生成和工具更改，**Flutter SDK 根目录的 `version` 文件已被删除**，取而代之的是位于 `bin/cache` （[#172793](https://github.com/flutter/flutter/pull/172793)） 中的新 `flutter.version.json` 文件，此外默认情况下不再生成 `AssetManifest.json` 文件 （[#172594](https://github.com/flutter/flutter/pull/172594)）。

另外还有：

- 对于  predictable behavior，包含作的 SnackBar 将不再自动关闭 （[#173084](https://github.com/flutter/flutter/pull/173084)）
- 前面介绍过的 `OverlayPortal.targetsRootOverlay` 构造函数已被弃用，取而代之的是更灵活的 `OverlayPortal`（ `overlayLocation: OverlayChildLocation.rootOverlay` ）
- `CupertinoDynamicColor` 上的几个属性（例如 `withAlpha` 和 `withOpacity`）现在已弃用，取而代之的是标准 `Color` 方法
- Flutter 3.38 要求 Java 17 作为 Android 的最低版本，符合 [Gradle 8.14](https://docs.gradle.org/current/userguide/compatibility.html)（2025 年 7 月版）的最低要求



# 最后

本次 3.38 的更新还是挺丰富的，同时也是一个不得不升级的版本，**不管是为了 iOS 26 适配和未来上架，还是为了安卓更稳定的 16KB 体验，这都是一个不得不升级的版本**。

那么大家准备好直接吃 3.38.0 的螃蟹还是等 3.38.6 ?







