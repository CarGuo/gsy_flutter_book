#  由于 iOS 26 的键盘变化，Flutter 又要重构键盘区域逻辑

在之前的 [《iOS 26 键盘变化可能带来大量底层改动》](https://juejin.cn/post/7596245612558319625) 我们就聊过，如下图所示，是由于 **iOS 26 系统键盘增加了“半透明”后带来的问题，Flutter 在键盘后面那一层在某些场景下没有正确渲染内容**，导致键盘半透明区域透出来的不是底下 BottomSheet 的真实内容，而是一整块黑色区域。

![](https://img.cdn.guoshuyu.cn/image-20260605143351083.png)

> 因为过去 Flutter 的 `Scaffold.resizeToAvoidBottomInset` 默认是 `true`， 所以键盘弹出来时，`Scaffold` 会把 body 缩到键盘上方，键盘区域一般由 `Scaffold.backgroundColor` 填充，这个模式在以前的 iOS 和 Android 上问题不大，因为**键盘一直都是一个不透明矩形**，即使后面颜色不对，用户也看不到。

所以，**过去 Flutter 的键盘避让模式默认键盘是不透明、非圆角的**，但 iOS 26 的 Liquid Glass 键盘变成半透明和圆角以后，问题就出现了，**针对问题其实可以临时选择配置 `UIDesignRequiresCompatibility = YES` 来解决，或者替换为 Dialog 来绕过场景**，但是问题还是需要解决，所以官方觉得重构实现。

是不是太抽象了？我们可以通过更具体的例子来理解，原本 Flutter 里的 `Scaffold.resizeToAvoidBottomInset` 默认是 `true`，所以当键盘弹出时，`Scaffold` 会根据 `MediaQueryData.viewInsets.bottom` 把 body 缩到键盘上方，正常来说应该是下面这样的：

![](https://img.cdn.guoshuyu.cn/01_scaffold_default_keyboard_avoidance.gif)

但是上面看起来没问题，只是刚好场景没遇到问题，如果是下面这种场景，在 iOS 26（图2）UI 就会变得很奇怪，因为正常交互上，他应该是图 3 那种情况：

![](https://img.cdn.guoshuyu.cn/image-20260605221447248.png)

很明显问题就出现在键盘下又多了一层的情况下，透明色和圆角就会让 UI 变得割裂，而且就算不是透明色，圆角也会暴露出现不友好的场景：

![](https://img.cdn.guoshuyu.cn/03_ios26_expected_vs_native.png)

**所以官方觉得需要重构 Flutter 的键盘区域逻辑来适应这个问题** ，主要也是因为以前一直把键盘下方当成不可见区域，所以设计上一直没管理这一块，所以这次官方定下重构的逻辑是：

> **layout 还是要避让键盘，但 paint 不能停在键盘上方，背景绘制必须延伸到键盘背后。**

说人话就是：**内容不要真的布局到键盘下面，但背景色要画到键盘下面**。

同时官方页归类出现目前的键盘问题主要有三类：

### 1、Flutter framework 自己的问题

类似 `Scaffold.bottomSheet` 、`showBottomSheet` 、`ScaffoldState.showBottomSheet` ，它们本来就和 `Scaffold` 深度绑定，而且视觉上应该从 sheet 一直延续到键盘区域。

但 iOS 26 下如果 sheet 前景色和 Scaffold 背景色不一样，键盘半透明后就会看到 Scaffold 背景色透出来，导致 sheet 和键盘区域断开，也就是前面我们看到问题。

> 所以这个问题应该 Flutter framework 自己处理，因为 Scaffold 本身就知道 persistent sheet 的存在，也能拿到 sheet 的背景色。

### 2、Scaffold body descendants / Overlay 

这类问题更麻烦，因为一般发生在业务自定义组件或第三方包，类似：

- 自定义 dialog/sheet/modal 作为 `Scaffold.body` 的 descendant
- 组件通过 `OverlayEntry` 显示，但不 push route 
- barrier、scrim、背景层只画到键盘上边缘
- 键盘区域背后露出 Scaffold 背景或其他底层颜色。

比如这个灰色 barrier 只覆盖到键盘顶部，键盘后面没有继续画灰色，所以 iOS 26 半透明键盘会透出不一致的底色：

![](https://img.cdn.guoshuyu.cn/04_body_bounded_barrier.png)

上图问题主要来自  `wolt_modal_sheet`，它 push 了自己的 route，但 route 内部又有一个带 persistent bottom sheet 的 Scaffold，而且 body 前景色和 Scaffold 背景色不同，所以还是会出现视觉断层。

实际上这类问题主要是第三方包自己实现的问题，比如

- 需要全屏 barrier 的 dialog/modal/sheet，尽量 push route，而不是直接塞进被键盘压缩后的 Scaffold body
- overlay-based 组件要显式处理 `viewInsets.bottom`
- 需要在键盘区域补背景

### 3、Modal padding 写法问题

最有一个问题也是最容易遇到的，很多人写 `showModalBottomSheet` 时，为了让内容避开键盘，会手动加 `.bottom`：

```dart
showModalBottomSheet<void>(
  context: context,
  builder: (context) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: ColoredBox(
      color: Colors.red,
      child: ...
    ),
  ),
);
```

问题在于，如果你把背景色放在这个 `Padding` 里面，颜色就只覆盖内容区域，不会覆盖键盘区域：

![](https://img.cdn.guoshuyu.cn/07_correct_color_wraps_padding.png)



这个结构的问题 是**Padding 在外，而颜色在内，内容被顶上去了，但颜色也跟着停在键盘上方**。

所以正确写法应该反过来，颜色在外，padding 在内，内容仍然避让键盘，但背景色会延伸到键盘背后：

```dart
showModalBottomSheet<void>(
  context: context,
  builder: (context) => ColoredBox(
    color: Colors.red,
    child: Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ...
    ),
  ),
);
```

![](https://img.cdn.guoshuyu.cn/06_wrong_padding_wraps_color.png)



这里官方还收集了一批有问题第三方生态包，包括：

- `modal_bottom_sheet`
- `wolt_modal_sheet`
- `smooth_sheets`
- `sliding_up_panel`
- `snapping_sheet`
- `flutter_smart_dialog`
- `motion_toast`
- `delightful_toast`
- `another_flushbar`
- `keyboard_actions`
- `shadcn_ui`
- `fluent_ui`
- `for_ui`

很多包都属于第二种情况，因为过去大多默认软键盘会继续是不透明、非圆角的，所以大家基本都没有认真处理「键盘背后的背景应该是谁来画」这个问题。

> 所以实际上的结果就是，官方要修 Flutter framework 这类第一种场景的情况，然后指导社区适配第二和第三方种写法。

针对 Flutter framework，官方初步是计划在 `Scaffold` 层增加一个新的绘制 slot ，用来在键盘区域画 backdrop，这个 backdrop 的行为大概是：

- 只在键盘弹出时启用
- 只在存在 persistent bottom sheet 时启用
- 只在 `resizeToAvoidBottomInset == true` 时启用
- 只在 sheet 有非透明背景色时启用
- backdrop 颜色来自当前 sheet 或 dismissing sheet 的 effective background color
- backdrop 放在 foreground widget 下面
- 用 `IgnorePointer` 包住，不改变点击命中行为

![](https://img.cdn.guoshuyu.cn/image-20260605223649071.png)

也就是 **Scaffold 还是把 body 缩到键盘上方，但额外把 sheet 的背景色画到键盘后面**，这样做的好处是兼容性强，对 Android 和 iOS 26 之前的平台几乎没有可见影响，因为旧键盘本来就会挡住这块区域。

当然，这种设计还是做不到原生 iOS 更理想的效果，如下图是原生 iOS 的一个效果，列表是会经过模糊的半透明键盘：

![](https://img.cdn.guoshuyu.cn/2026-unnamed.gif)

因为 `resizeToAvoidBottomInset` 存在根本性缺陷，它实际上是为了调整 Flutter  主体大小来保持在键盘上方的行为而添加的，理想的键盘解决方案不是将 Scaffold body  的大小限制在键盘上方的区域，而是让 Scaffold body   和所有 Scroll 视图内部使用 viewInsets.bottom 来填充对应内容，这样可滚动的内容在键盘下方也可以看到。

但是现在问题就出现在：

- 但是如果 Scaffold body 自己加了 `viewInsets.bottom` padding，里面的 `ListView` / `GridView` / `CustomScrollView` 也加 padding，就会变成两倍键盘高度。

- 如果 Scaffold 判断 child 是不是 scroll view，然后决定自己要不要 padding，又违反 Flutter 的设计原则：父 widget 不应该窥探子 widget 的内部类型。

- 如果完全让 scroll view 自己处理 padding，那么非滚动页面里的 TextField 又可能被键盘永久挡住。

所以目前官方最终选择了第三条路：

> **Scaffold 继续负责键盘避让，把键盘区域当成不可布局区域，但相关组件要把背景绘制延伸进去，保证视觉连续。**

**所以这个问题核心不只是 Flutter Framework 要修复，你用的库和代码也需要跟进跟进**，而且这个实现看起来貌似对于渐变背景、图片背景、blur / glass 效果的支持也不一定友好，所以只能算事一个折中的结果：

![](https://img.cdn.guoshuyu.cn/10_fix_plan_diagram.png)

# 链接

https://flutter.dev/go/ios-26-keyboard-bleed