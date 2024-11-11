# Flutter Color 大调整，需适配迁移，颜色不再是 0-255，而是 0-1.0，支持更大色域

在之前的 3.10 里， Flutter 的  Impeller 在 iOS  上支持了 P3 广色域图像渲染，但是当时也仅仅是当具有广色域图像或渐变时，Impeller 才会在 iOS 上显示 P3 的广色域的颜色，而如果你使用的是 `Color`  API，会发现使用的还是 sRGB 色域的绘制。

> ⚠️ 如果对原因和调整不感兴趣的，可以直接看后面的适配。

那么实现 sRGB 和 P3 有什么区别？简单来说，最直观的感受就是如下图所示的区别，在具备 P3 色域的设备屏幕上， **P3 拥有更广的色域，所以可以看到更鲜艳的颜色**，而在如今 2024 来看，其实大部分移动设备都已经具备了 P3 色域的硬件支持。

![](http://img.cdn.guoshuyu.cn/20241025_wide/image1.png)



简单看下如下图所示 sRGB（白色三角形）与 Display P3（橙色三角形）的色域对比，从比例上说，P3 广色域可以比 sRGB 多出至少 25% 的颜色支持。

![](http://img.cdn.guoshuyu.cn/20241025_wide/image2.png)

当然， 3.10 中 Flutter 只是为 Impeller 开启了图像渲染是的广色域支持，对于使用 `Color`  类 API 的情况，依然还停留在 sRGB 下，它没有对在 Flutter Widget 中渲染广色域提供 API 的支持。

所以 Flutter Team 在 2023 年开启了重构 `Color` 对象的提案，让 `Color`  也调整为支持 P3 广色域的能力，最直观的就是，**原本参数的有效范围 [0, 255] 的整形，而现在颜色分量调整为 [0,1.0] 的浮点**。

你是不是奇怪，为什么  [0, 255] 变成  [0,1.0] ，但是色域居然还变大了？这其实是因为整形变成了浮点之后，精度带来的可用位数增加：

> 在此之前，整形的  [0, 255]  颜色也就是每个颜色只有 8 位，从 Dart 层传递到引擎的方式是：ARGB(4x8) 被打包成一个 32 位 alpha-red-blue-green 的 Dart 整数 ，每个 color 有 8 位(255)，之后 color 会被转化为  Skia 的 `SkColor`，然后被处理为引擎中绘制需要的 `DlColor` ，都是整形数据。
>
> 在 Impeller 中，`DlColor` 会进一步被转换为 `impeller::Color` ，  `impeller::Color`  是 128 位，每个颜色都具有 32 位标准化浮点，也就是精度让位数变高了。

那为什么提高位数对支持色域很重要？**因为 P3 覆盖的颜色较多，8bit/channel 已经不能表达所有 P3 颜色了，所以至少需要用 10bit/channel 来表示**。

而很明显，在此之前 Flutter 的 sRGB  [0, 255] 的整形表示，每个颜色只有 8 位，合起来一个整体 x4 也只有 32 位，而使用浮点 [0-1.0] 表示，则改变了这一格局：

> 从 3.27 beta 版本开始， `dart:ui` 中  Color  从最大 64 位变为最大 320 位。

![](http://img.cdn.guoshuyu.cn/20241025_wide/image3.png)

为什么说是从 64 位变为 320 位？因为原本只有一个整型 int ，int 在 dart 里是 64 位，所以原本 Color 最大只有 64 位，而现在增加了 a、r、g、b 四个 double ，也就是多了四个 64 位精度的参数，所以 Color 现一共有 5 个参数，变成了最大 320 位，不过未来 value 会被弃用：

> 也就是每个  a、r、g、b 每个理论可用为 64 位之多，如果不考虑 value ，Color 就是从原本的 64 位整数更改为 256 位浮点数。

![image-20241024163722126](http://img.cdn.guoshuyu.cn/20241025_wide/image4.png)

之后，组件将颜色的 TypedData 发送到 C++，而前面说过，在 Engine 层的 `DlColor` 也调整到 128 位适配   `impeller::Color` ， 也就是 DlColor 是 4 个 32 位的 float 组成，同时往后兼容 sRGB 色彩空间。

> 不要在意 Dart/64 => C++/32 ，只是语言特性导致的差异。

![](http://img.cdn.guoshuyu.cn/20241025_wide/image5.png)

![](http://img.cdn.guoshuyu.cn/20241025_wide/image6.png)

另外，`ColorSpace`  也新增了  `displayP3`  选项，至此整个 Color 广色域支持初步完成，**但是真实的 P3 渲染效果目前只在 iOS 上可以看到，后续 Android 需要等  Vulkan Impeller 支持的成熟才能在底层进一步适配支持**。

![](http://img.cdn.guoshuyu.cn/20241025_wide/image7.png)

# 代码兼容调整

随着 Color 底层支持的变化，Color 上层 API 也发生了不少调整，其实本次调整算是比较大的 break ，因为色域变化后其实上层 API 调整还是很明显的， 例如最明显的就是不再推荐用  `fromARGB` ，而是用 `Color.from` 。

```dart
// Before
final magenta = Color.fromARGB(0xff, 0xff, 0x0, 0xff);
// After
final magenta = Color.from(alpha: 1.0, red: 1.0, green: 0.0, blue: 1.0)
```

另外，在以前 Color 具有  “opacity”  的概念，所有会有 `opacity`  和 `withOpacity（）`  的存在，以前引入 Opacity 是为了让  `Color`  具有浮点的 alpha 通道，而现在 alpha 是一个浮点值，所以 opacity 显得多余，未来`opacity` 和 `withOpacity` 已被弃用并计划删除：

```dart
// Before
final x = color.opacity;
// After
final x = color.a;


// Before
final x = color.withOpacity(0.0);
// After
final x = color.withValues(alpha: 0.0);
```

![](http://img.cdn.guoshuyu.cn/20241025_wide/image8.png)

另外，如果有对于 Color 的继承最好暂时换成 `implements` ，也就是不需要再实现 `super`  相关部分逻辑，另外为什么说是暂时，因为目前 **Flutter 团队计划未来 Color 会锁定并通过 `sealed` 封闭，所以如果通过  `sealed` 封闭 ，那以后基本不会有 Color 的外部实现了**：![](http://img.cdn.guoshuyu.cn/20241025_wide/image9.png)

```dart
class Foo implements Color {
  int _red;

  @override
  double get r => _red * 255.0;
}
```

其次，现在使用 `Color` 并对颜色执行任何类型的计算，都需要首先检查颜色的 ColorSpace ，然后再执行计算逻辑，这里推荐使用新的 `Color.withValues` 方法来执行颜色空间转换：

```dart
// Before
double redRatio(Color x, Color y) => x.red / y.red;

// After
double redRatio(Color x, Color y) {
  final xPrime = x.withValues(colorSpace: ColorSpace.extendedSRGB);
  final yPrime = y.withValues(colorSpace: ColorSpace.extendedSRGB);
  return xPrime.r / yPrime.r;
}
```

使用颜色进行计算，如果不对齐色彩空间可能会导致细微的意外结果，例如在上面的示例中，如果使用不同的颜色空间与对齐的颜色空间进行计算时，`redRatio` 的差异为 0.09。

# 最后

事实上，本次调整虽然看起来就像是一个简单的 `toDouble `过程，但是它对于 Flutter 的 UI 影响确实不小，不管是颜色 API 的适配，还是计算方式的变化，甚至是色域的支持等场景，如果单从影响效果看，这个合并可以说是影响广泛，整出边界渲染问题其实并非不可能，所以这个合并也是憋了这么久才被合并到 beta ，也许不久之后，我们就可以在正式版本中看到它了。





![](http://img.cdn.guoshuyu.cn/20241025_wide/image10.png)



参考资料：

https://github.com/flutter/flutter/issues/55092

https://github.com/dart-lang/sdk/issues/56363

https://github.com/flutter/flutter/issues/127852

https://github.com/flutter/flutter/issues/127855

https://docs.flutter.dev/release/breaking-changes/wide-gamut-framework