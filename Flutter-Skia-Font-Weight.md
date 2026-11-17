# Flutter 的文字为什么比 SwiftUI 更细？问题主要在 Skia 的 256 项查找表里

最近看了一篇文章  [《Why Flutter Text Looks Lighter Than SwiftUI on iOS》](https://birju.dev/posts/looking-into-flutter-vs-swiftui-font-rendering/)，写的还挺好的，如果看我写 Flutter 比较早的，应该看我写过不少关于 Flutter 文本渲染的问题，他这篇聊的也是我们以前聊过的问题：**为什么 Flutter 里的字体和 iOS 原生会不大一样**？

明明用的是都同一套 SF Pro、也是相同字号和颜色，为啥 Flutter 的字怎么看起来就是浅了一点，还细了一点？如果你从 CoreGraphics 一路追到 Skia 和 Impeller，然后拿实际像素值核对了，**就会发现在在 17pt、3× 屏幕对照里，Flutter 文字的总 Ink 只有原生的 93.8%，而边缘像素平均值从 0.495 降到 0.413**，大概类似这样：

![](/article-assets/1cec9df904e966ce684220f7.webp)

> 这里其实就要聊一个被忽略的细节：**字体文件保存的不是一个个固定大小的位图，它保存的是字母的轮廓**。

这个问题我们在聊 Flutter 里的虚线问题的时候也聊过，**因为屏幕只能显示离散的像素**，比如字母 `a` 的曲边只覆盖某个像素的 40%，直接画黑色会形成锯齿，所以通常会把它画成较浅的灰色，**这个覆盖比例就是 Coverage**。

至于最后真正显示出来多少颜色，文章里用  Ink 作单位，比如普通灰度抗锯齿里，40% Coverage 就相当于 40% Ink。

![](/article-assets/fa0439d693bee82adc5d24ac.webp)

这也是为什么「字体平滑」解释不了所有问题，比如：

- 早年的 Subpixel 会分别用 RGB 子像素让边缘更锐利，但可能产生彩边
- Dilation 会让笔画稍微膨胀
- Coverage Curve 不改字形轮廓，只调整边缘覆盖率和最终颜色之间的关系

![](/article-assets/34902359fb0fc77bbe5c85e2.webp)

实际上 Flutter 在 iOS 上遇到的恰好是最后一种，**比如 SwiftUI `Text`、UIKit `UILabel`、CoreGraphics 在同一组条件下绘制文字，结果是逐像素一致。**

而在他的测试条件下面，原生文字直接采用灰度覆盖率，没有额外做这类让笔画变浅的曲线调整，甚至更有意思的是，Flutter 生成 iOS 字形时也绕不开苹果的 CoreGraphics：

> **Impeller 还是会通过 Skia 获取 CoreGraphics 栅格化之后的字形**，所以光说「Flutter 自绘，原生不是」也解释不了这次差异，因为两条路径在前半段已经拿到了同类的字形像素。

![](/article-assets/cc04efd526104a3cf855001b.webp)

这里的原因还是，**Skia 为了校正颜色，在进入 Glyph Atlas 之前把边缘改浅了**，就算你的 Impeller ，在字体这里还是绕不过 Skia，把一个字母在 Flutter iOS 中经历的步骤顺着看：

- 先从字体取到字形轮廓
- 再通过 CoreGraphics 生成灰度字形
- Skia 随后会修改部分像素的灰度值，然后把处理过的字形放进 Glyph Atlas
- 最后 Impeller 用 GPU 绘制到屏幕

![](/article-assets/32666325d530e4bb19548bb1.webp)

> Glyph Atlas 可以理解成一张预先收集好常用字形的纹理，缓存之后就不需要每次绘制文字都重新栅格化，**这次问题就在缓存前的 Skia 灰度处理**，所以后面换什么文字颜色，边缘像素也不一定能恢复。

**具体来说就是，Skia 会使用一张 256 项 Lookup Table**，A8 灰度字形的每个像素本来就在 0 到 255 之间，Skia 直接拿这个数查表，再把原值替换成新值。

而之所以需要这张表，是因为 sRGB 颜色值和实际发光亮度本来就不是线性关系：

> 直接按照 Coverage 混合像素颜色，不一定得到物理上对应的亮度，而 Skia 本身就是试图用 Gamma、Contrast 调整这个差异，但是在深色文字的路径里，中间灰度会向更浅的方向移动。

比如把公式生成的曲线和真实截图里的像素点放在一起比较，发现两者这样的情况：

![](/article-assets/4fec6d2045dd4ef749935d28.webp)

**60% Coverage 经过 Flutter 的曲线之后，只留下大概 43% Ink，当然需要注意这里说的是某个边缘像素的变化，不是说所有文字整体损失 17% 的颜色**，因为字形内部 100% 覆盖的区域基本不变，最后一整行 17pt 文字统计下来，总 Ink 减少的是约 6.2%。

如果你沿着源码还看 ，可以找到三个关键选择：

- 第一，Flutter 在 [`skia/BUILD.gn`](https://github.com/flutter/flutter/blob/master/engine/src/flutter/skia/BUILD.gn) 定义了 `SK_GAMMA_APPLY_TO_A8`，所以这个查表分支会生效，比如固定 Gamma 1.4、Contrast 0.0 配置的不是 iOS 的默认口径，**所以不能直接拿 Android 的设置解释 iPhone 的结果**
- 第二，[`font_glyph_pair.h`](https://github.com/flutter/flutter/blob/master/engine/src/flutter/impeller/typographer/font_glyph_pair.h) 的 `ComputeTone` 在 iOS 下始终返回 `Tone::kDark`，也就是没有给白字单独挑另一套字形
- 第三，Impeller iOS 的文字 Shader 没有启用一条可用来反向调整灰度的校正路径，缓存里已经被改过的边缘就继续沿用下去

> 所以到这里还有个挺反直觉的结果：**白字放在黑底上也会变浅**。

如果对颜色敏感的查表原本可以根据黑字、白字来选择不同曲线，但是 iOS 当前这条 Glyph Atlas 复用路径固定走暗色配置，也就是白字和黑字都会受到相同方向的边缘削弱，这和给 Text 简单设置更重的 `fontWeight` 不一样，因为后者直接改变字形笔画的几何轮廓：

![](/article-assets/04f0185eb6cd6eeaf6eef7d0.webp)

**而且同样的校正放在大字和小字上，肉眼感受是会完全不同的**：

- 大字内部完整覆盖的像素很多，损失一点边缘灰度，总体变化不算大
- 小字的笔画就几颗像素宽，边缘占的比重更高，结果看起来会更细。

原文里就用真实字形数据测试，同样一条校正曲线，**51px 的字保留 94% Ink，39px 保留 92%，17px 只剩 83%，13px  78%**，也就是在 3× 屏幕上，17pt 正文大致对应 51px，所以反而是备注、时间戳、辅助标签这些更小的内容，容易率先暴露问题：

![](/article-assets/56e3f1cdc0bc3c6dfc64775b.webp)

而且还有第二个独立问题：**SF Pro 的 Tracking（字间距）**。

iOS 会根据字号使用 SF Pro 的字距表，不同大小对应不同的收紧幅度，而 Flutter 的普通 `TextStyle` 不会自动套用这一整张表，**比如 17pt 例子，每个字符附近大需要收紧 0.43pt，一行 36 个字符积累下来，Flutter 就能比 iOS 宽出约 15pt**，也就是你就算把字形的灰度修好了，文字的实际宽度、换行位置、按钮布局也可能依旧不同：

![](/article-assets/35d63b258387611a10dd9ca9.webp)

当然 Flutter 不是完全没处理这个问题， Cupertino 正文样式里已经针对 17pt 硬编码了接近原生的 `letterSpacing: -0.41`，**但如果项目自己写 `TextStyle(fontSize: 17)`，或者用别的字号或另外维护 Design System，这份手工近似就不一定覆盖了**。

> 相应问题在 [#150824](https://github.com/flutter/flutter/issues/150824) 和更早的 [#22572](https://github.com/flutter/flutter/issues/22572) 里都有讨论，特别在做 Flutter 与原生的 Golden / Screenshot 对比的时候，实际上应该把字形灰度、字距、字体实际选型分开验证，不要把所有偏差都归结为「字体不一样」。

这么看其实有几个路线可以改：

- **让 Skia 的字体 Gamma/Contrast 配置在 iOS 上产生恒等映射**
- **在构建时为 iOS 取消 A8 Gamma 查表**
- **在 Impeller Shader 中做反向曲线补偿**

前两条更接近直接保留 CoreGraphics 生成的原始 Coverage，第三条算是事后近似补偿，当然如果去掉编译宏，还需要确认 Skia 在 iOS 上的其他调用路径会不会一同受影响。

![](/article-assets/9967f46d47787c987ad5a5f4.webp)

> 单改 Shader 可能可以得到接近的画面，但是不一定和原生逐像素相等。

上层 App 在代码现在能做的兼容其实比较有限，比如：

- 字间距可以按所用字号单独调整，尽量先利用 Cupertino 对典型字号已有的配置
- 灰度问题不改 Engine 就碰不到真正的 Glyph Atlas

大概类似于用同色、无模糊、极小位移的 Shadow 再叠画一次文字，第二遍把过浅的边缘补回来，用 75% 的 Shadow 透明度模拟恢复到接近原生：

```dart
Text(
  'Hamburgefonstiv',
  style: TextStyle(
    fontSize: 17,
    color: const Color(0xFF111111),
    shadows: [
      Shadow(
        color: const Color(0xFF111111).withValues(alpha: 0.75),
        offset: const Offset(0, 0.01),
      ),
    ],
  ),
)
```

> **不过这个“歪招”需要不透明文字颜色，不然两层透明度叠加会改变颜色，而且等于给文字增加了一遍绘制成本。**

当然，这是纠结 Flutter 一定要字体和原生一致的人会纠结的，比如你的设计值拿着 iPhone 设计稿找你逐字核对，不然其实也没太多影响，毕竟又不是不用看？
