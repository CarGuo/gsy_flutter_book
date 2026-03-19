# Flutter Beta 版本引入 ScrollCacheExtent ，并修复长久存在的 shrinkWrap NaN 问题

在最近发布的 Flutter 3.43.0-0.1.pre 这个 Beta 版本里，官方在 Framework 层面对 ScrollView / Viewport / ShrinkWrappingViewport 做了一个比较有意思的修改：

- 引入 `ScrollCacheExtent`，废弃 `cacheExtent + cacheExtentStyle`
- 修复 `RenderShrinkWrappingViewport` 在无约束下 cacheExtent 可能变成 NaN 的问题
- 重构 Viewport cache 计算路径

这次修改涉及 rendering 层核心代码，属于 **Viewport  底层重构**，暂时看来修改的作用是正向的，应该不至于引起类似之前[《Flutter 3.41 iOS 键盘负优化：一个代码洁癖引发的负优化》](https://juejin.cn/post/7615894702423900223) 的问题。

根据 [#181092](https://github.com/flutter/flutter/pull/181092) 的修改内容，这次修改范围主要涉及：

```dart
rendering/viewport.dart
widgets/scroll_view.dart
widgets/page_view.dart
widgets/list_view.dart
widgets/grid_view.dart
```

对应源码的影响有：

```dart
RenderViewportBase
RenderViewport
RenderShrinkWrappingViewport
Viewport
ShrinkWrappingViewport
ScrollView
ListView
PageView
```

所以，虽然看起来只是一个小 feature 和一个 bug fix，但是其实这个调整并不是 Widget 层的小改动，而是 **Viewport 渲染路径修改**。

> 所以才会需要挑出来聊一聊。

首先是  `ScrollCacheExtent` ，在之前的实现里，Viewport cache 主要由这两个字段控制：

```dart
double cacheExtent
CacheExtentStyle cacheExtentStyle
```

相关逻辑为：

```dart
switch (cacheExtentStyle) {
  case CacheExtentStyle.pixel:
    calculatedCacheExtent = cacheExtent;
  case CacheExtentStyle.viewport:
    calculatedCacheExtent = mainAxisExtent * cacheExtent;
}
```

涉及的关键变量是：

```dart
mainAxisExtent = viewport size
```

而问题也就出现在这里，因为 `ShrinkWrappingViewport` 的特殊性，当 `ScrollView` 设置 `shrinkWrap = true`  的时候，`ScrollView.buildViewport`  就会会创建 `ShrinkWrappingViewport` ：

```dart
ScrollView.buildViewport
 -> ShrinkWrappingViewport
 -> RenderShrinkWrappingViewport
```

而 `ShrinkWrappingViewport ` 的特点就是 viewport size 由子节点决定，而不是通过父约束，这就意味着`mainAxisExtent` 可能不是y一个有限的值 ，也就是类似以下的场景：

```dart
SingleChildScrollView
  -> ListView(shrinkWrap: true)
```

```dart
Column
  -> ListView(shrinkWrap: true)
```

这些情况下父布局在主轴方向是 unbounded ，所以 `ShrinkWrappingViewport` 会得到 `constraints.maxExtent = infinity` 的情况，也就是最终：

```dart
mainAxisExtent = infinity
```

这乍一看没什么问题，但 `cacheExtent` 逻辑没有考虑这个情况，因为在旧逻辑里：

```dart
viewport cache mode
= cacheExtentStyle.viewport
```

也就是

```dart
calculatedCacheExtent = mainAxisExtent * cacheExtent
```

如果这时候 `mainAxisExtent = infinity` ，那就会 `infinity * 0.5 = infinity` ，以至于在后续布局计算里`paintExtent `\ `layoutOffset`  \ `scrollOffset `都可能出现 `infinity - infinity` ，也就是结果为 NaN ，比如：

```dart
SingleChildScrollView(
  child: ListView.builder(
    shrinkWrap: true,
    cacheExtent: 0.5,
    cacheExtentStyle: CacheExtentStyle.viewport,
    itemBuilder: ...
  ),
)
```

而在新 API 下，`cacheExtent` 和 `cacheExtentStyle` 现在变成  `ScrollCacheExtent` ，并且内部做了适配，所以这种情况现在不会再报错了：

```dart
SingleChildScrollView(
  child: ListView.builder(
    shrinkWrap: true,
    scrollCacheExtent: ScrollCacheExtent.viewport(0.5),
  ),
)
```

所以这里的  `ScrollCacheExtent` 不是简单的把两个参数编程一个，而是内部做了重构，首先是在 viewport.dart 内部提供了：

```dart
ScrollCacheExtent.pixels()
ScrollCacheExtent.viewport()
```

对应内部实现了新的 Viewport  计算逻辑：

```dart
_calculateCacheOffset(mainAxisExtent)

_calculatedCacheExtent =
  _scrollCacheExtent._calculateCacheOffset(mainAxisExtent)
```

**这个情况下 cache 集中计算，并且避免 style + value 分离**，其中「NaN 修复」的关键在于 `RenderShrinkWrappingViewport` ，对应核心修改为：

```dart
if (!mainAxisExtent.isFinite)
  cacheExtent = 0
```

因为对于  infinite viewport 来说，实际上 already builds all children ，所以根本不需要 Cache ，而这个修改也会涉及 `PageView` \ `ListView` \ `GridView` \ `CustomScrollView` 等常用控件。

> 所以这也是一个相对昂贵的性能配置选项。

所以这个 `ScrollCacheExtent ` 的修改，本质上是：

- 重构 Viewport cache API
- 修复 `ShrinkWrappingViewport` 在无约束下 `cacheExtent` 计算 NaN 的问题
- 统一 `ScrollView `/ `Viewport` / `RenderViewport` 的缓存逻辑

虽然逻辑改动看起来好像改的不多，但是涉及的文件和地方还是挺多的，从长远来看，这个修改还是比较有意义的，至少之前经常遇到的 NaN 问题终于不要自己处理了。



# 链接

https://github.com/flutter/flutter/pull/181092