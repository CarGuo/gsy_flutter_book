# Flutter 又迎大坑修改？iOS 26 键盘变化可能带来大量底层改动

又是一个小问题可能带来的大改动，感觉官方在评估的时候，有点过分细节了。

这个问题来自去年底的 [#179482](https://github.com/flutter/flutter/issues/179482)  issue ，Flutter 在 iOS 26 上，某些场景会因为出现半透明键盘，而页面底下本来应该被键盘遮挡的 Widget，由于默认没有被绘制，从而出现键盘背景颜色 UI 异常：

![](https://img.cdn.guoshuyu.cn/84b84f03-e44f-4bc5-915a-44165e5f874a.png)

虽然问题看起来是一个圆角问题，但是实际上这是 **iOS 26 系统键盘增加了“半透明”后带来的问题，Flutter 在键盘后面那一层在某些场景下没有正确渲染内容**，导致键盘半透明区域透出来的不是底下 BottomSheet 的真实内容，而是一整块黑色区域。

> issue 提到问题，问题最明显的场景主要出现在 iOS 26 的 `showModalBottomSheet()` 下。

![](https://img.cdn.guoshuyu.cn/b7050f5b-0f38-4e8c-a091-d28f439a7cd1.png)

为什么会这样？首先就是你的 App 目前是否使用了最新 Xcode 26 ，以及在  `Info.plist` 里有没有使用 `UIDesignRequiresCompatibility = YES` 让 App **继续使用旧的系统设计风格** ：

| ![8b13916c1c0c6339201a1a9f3e797b2e](https://img.cdn.guoshuyu.cn/8b13916c1c0c6339201a1a9f3e797b2e.jpg) | ![](https://img.cdn.guoshuyu.cn/ce07c5b30aca25245ce4ba5bcfddcca0.jpg) | ![](https://img.cdn.guoshuyu.cn/f85eb5b7a5d97c730989b8f3a8c29be1.png) | ![](https://img.cdn.guoshuyu.cn/114b4e43b4a45a3fc04d00ca810f9220.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |

通过上面前两张图我们可以看到，iOS 26 正常情况下，系统键盘其实是会出现半透明效果并且具备圆角，虽然透明效果不是特别明显，但是对比后两张图里，可以看到微信和淘宝还是保留着原本的 iOS 18 的直角效果。

> 如果还是保留原本风格，其实并不会遇到这个问题。

**所以这个 issue 首先是需要在 Xcode 26 下，并且没有关闭 Liquid Glass 适配的情况下才会遇到**，当然，就算是 iOS 26 场景，一般情况下也不会有什么大问题，比如下图直接在界面内使用一个  `TextField` ，其实并不会有明显问题：

| ![](https://img.cdn.guoshuyu.cn/image-20260118173939510.png) | ![](https://img.cdn.guoshuyu.cn/image-20260118171041669.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

问题还是主要出现在类似 `showModalBottomSheet` 的场景，特别是在背景色透明的时候，虽然我们设置了 `backgroundColor: Colors.transparent` ，**但是在 Flutter 里，某些时候 UI 并不会“在键盘背后继续画” ** ，因为在 iOS 26 之前，Flutter（以及很多跨平台框架）都默认：

> **系统键盘 = 完全不透明的遮挡物**，所以 Flutter 的 pipeline 会认为键盘区域背后不需要特殊关注。

| ![](https://img.cdn.guoshuyu.cn/image-20260118174226878.png) | ![](https://img.cdn.guoshuyu.cn/image-20260118174154571.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

实际上类似同样的问题，在 RN 里也是存在，甚至对于 CMP 来说也是存在不一样的问题，所以对于 CMP 来说，才会有 [1.10 Interop views 新特性 Overlay ](https://juejin.cn/post/7594863660280496147)，用于支持 UIKit 的半透明/blur 可以采样到 Skia 的内容的实验性 API ：

![](https://img.cdn.guoshuyu.cn/image-20260118182146053.png)

![](https://img.cdn.guoshuyu.cn/image-20260118182308193.png)

![](https://img.cdn.guoshuyu.cn/image-20260118181407179.png)

**所以这个问题实际上的本质不是圆角**，比如我把 `showModalBottomSheet` 背景改成红色，此时你可以看到键盘是可以采集到背景色的，甚至我把 `Container` 也改成红色，你也看不出来异常：

| ![](https://img.cdn.guoshuyu.cn/image-20260118175158145.png) | ![](https://img.cdn.guoshuyu.cn/image-20260118175317990.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

**所以问题更多出现在透明色上**，随着  `showModalBottomSheet`  弹出并带有透明色的时候，由于 Flutter 认为被键盘这挡住的下层 Widget 并不需要绘制，所以导致系统键盘采集不到对应的像素点，从而出现了一开始的黑色背景。

所以其实这个 Bug 如果想临时解决，只需要在  `Info.plist` 里配置 `UIDesignRequiresCompatibility = YES` 就可以了，只是此时 App UI 会是 iOS 18 的风格：

| ![](https://img.cdn.guoshuyu.cn/image-20260118171041669.png) | ![](https://img.cdn.guoshuyu.cn/image-20260118171135503.png) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

如果再对比抖音和 Github App ，就可以看到 iOS 26 新键盘风格对于整体应用的风格影响还是挺大的，所以不少 App 目前会选择通过关闭适配拖延时间。

| ![](https://img.cdn.guoshuyu.cn/e61e6647161b3dc5da7a983d67054c05.jpg) | ![](https://img.cdn.guoshuyu.cn/06dc77d24d88136742d677e1d254b1a6.jpg) |
| ------------------------------------------------------------ | ------------------------------------------------------------ |

那为什么会说，这个 Bug 会导致整个底层生态的重构？**因为 iOS 26 改变了“系统键盘会完全遮挡 App 内容”这一长期不变的底层假设**，而 Flutter 的渲染 / 布局 / Insets / 事件系统，几乎全都建立在旧假设之上，这套逻辑几乎渗透在：

- `RenderObject` 的 `layout`
- `Scaffold` / `BottomSheet` / `Navigator`
- `MediaQuery`
- `TextInputPlugin`
- Engine 中的 view hierarchy 
- ···

![](https://img.cdn.guoshuyu.cn/image-20260118180129255.png)

也就是如果想完全适配这个新场景（多层嵌套下还提供键盘场景的透明支持），一旦需要完全支持“键盘下内容需要绘制”，就要系统性重构多个核心层，例如

：

### Framework 层（Dart）

- `MediaQuery.viewInsets`
  - 现在代表“不可见区域”
  - 未来要不要拆成多个：`coveredInsets` 、`obscuredInsets` 、`visualInsets`
- Scaffold / BottomSheet
  - 是否仍然自动 resize？
  - 还是只做布局、不做裁剪？
- Clip 行为
  - 现在大量 widget 默认不 clip

### Engine 层（iOS embedder）

- FlutterView / UIView hierarchy
- CALayer 合成顺序
- 系统 keyboard window vs Flutter window
- 是否需要：
  - 在被遮挡区域继续 raster
  - 或改变 backing store 策略

### 输入系统 & Hit Test

- 键盘下的 widget：
  - 画出来了
  - 但不能响应触摸
- Flutter 目前的 hit-test 假设：
  - “看得见 = 可点”

### 插件 & 三方生态

- 各种：
  - bottom sheet 插件
  - keyboard avoiding 插件
  - 聊天 UI
- 各种涉及“手搓” viewInsets 的场景

**所以这个“语义场景”如果发生比变化，那么涉及的将是大量底层改动，甚至一些性能指标都会需要调整，从长远来看，这还会是一个 iOS 平台特有的差异化适配场景，并且引入大量 bread change**。

# 最后

最后总结下，**正常大家使用输入框输入文本内容不会有什么问题**，甚至如果你用 Dialog 场景也不会有什么问题，甚至你看下方最后一张图片，在 dialog 下的键盘依然可以正常透视工作：

| ![](https://img.cdn.guoshuyu.cn/image-20260118183109671.png) | ![](https://img.cdn.guoshuyu.cn/ezgif-855b2c1cb5f1e709.gif) | ![](https://img.cdn.guoshuyu.cn/image-20260118184027043.png) |
| ------------------------------------------------------------ | ----------------------------------------------------------- | ------------------------------------------------------------ |

所以问题主要还是存在于  `BottomSheet` 这种场景，因为 `BottomSheet` 默认行为是认为底部对齐，高度有限，所以对于 `BottomSheet` 会认为底部高度区域在键盘下不渲染，所以导致最后采集不到像素出现黑色。

**针对问题其实可以选择配置 `UIDesignRequiresCompatibility = YES`  来解决，或者替换为 Dialog 来绕过场景**，但是如果要等官方修复这个场景，可能会需要等待评估是否真的有必要大规模底层改动。

![](https://img.cdn.guoshuyu.cn/image-20260118193903692.png)

> 从我的角度看，这完全没必要，毕竟真这么修改，带来的就是生态的大量 break change。



# 参考链接



https://github.com/flutter/flutter/issues/179482