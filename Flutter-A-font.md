# Flutter  在 Android  出现随机字体裁剪？其实是图层合并时的边界计算问题

字体问题在 Flutter 里已经是老生常谈的 bug ，而这次要聊的是 issue [#161721](https://github.com/flutter/flutter/issues/161721) 下的老问题，如下代码所示，具体问题表现为： **“Text 在被 `Opacity` / `ShaderMask` 这类需要 `saveLayer` 的效果的控件包裹后，绘制缓冲层的 bounds 算的太“精细”，导致字形上下（尤其是 descender，比如 `g` 的尾巴）被裁掉”** ：

```dart
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 47);
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.black,
                      Colors.red,
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: Text("g", style: style),
              ),
              Opacity(
                opacity: 0.9,
                child: Text("g", style: style),
              ),
              Text("g", style: style)
            ],
          ),
        ),
      ),
    );
  }
}
```



![](https://img.cdn.guoshuyu.cn/image-20260126091219185.png)

> 问题主要出现在 Android 上。

当然，这个问题还有其他条件，他和系统还有字号也有很大关系，例如：

- Android（Pixel 7/8、API 34 等）可稳定复现， `fontSize: 47` 时，`Opacity` / `ShaderMask` 下的 `g` 一定会被上下裁剪
- 字号到 48 或更大裁剪消失
-  Inter variable font 在 Android/Web 也见过类似现象
- 和更古老的 [#96322](https://github.com/flutter/flutter/issues/96322)  类似，字体在 desktop/web 裁剪/ellipsis 时底部被切掉，本质也是 “line/glyph bounds” 边界算得过“精细”

实际上从下面表格可以直观看出来问题的点，在 41 和 42 的时候，字变大了，但底层算出来边界高度没变 ：

| fontSize | bounds height |
| -------- | ------------- |
| 40       | 30            |
| 41       | 31            |
| 42       | 31            |
| 43       | 33            |

那这种 bounds 高度离散跳变，那为什么会和  `Opacity` / `ShaderMask`  有关系？主要还是和  `saveLayer` 有一定关系：

- `Opacity` 在 0/1 以外会把 child paint 到一个 intermediate buffer 再混合回去，**而  `saveLayer(bounds, paint)` 时， bounds 是“裁剪边界”** ，如果 bounds 只按布局尺寸/行高算，没把某些字体在某些字号下的“真实像素级溢出”算进去，就会被裁掉
- `ShaderMask` 也是通过对 child 建 layer 再用 shader+blendMode 做合成，所以它和 `Opacity` 一样，会放大任何 “layer bounds 偏小” 的问题

而恰好对于 `g` 这种有 descender 的字形，底部伸出 baseline 会比较多，在叠加：

- 字体 hinting/栅格化导致的像素对齐取整
- 行高（ascent/descent/leading）与真实 glyph 像素覆盖范围不完全一致
- 浮点到整数边界的 `ceil/floor` 差 1px

就容易出现， **虽然只差不到 1px，但被 layer 直接裁掉”的现象** ，而字号大于 48 的时候，恰好让这些取整结果趋向正常，所以“看起来好了”。

![](https://img.cdn.guoshuyu.cn/image-20260126091417382.png)

所以问题**不是 Text 自己在 clip，而是 `Layer` 在 clip** ，是  `SkTextBlob::bounds()`  过程做了裁剪导致：

-  DisplayList 里有一个 `drawTextBlob` 命令

- `drawTextBlob` 的 bounds 来自 `SkTextBlob::bounds()`

- `SkTextBlob::bounds()` 来源于 Skia/FreeType 在构建 TextBlob 时给的 glyph bounding boxes

更具体的落点在于 `SkScalerContext_FreeType::getBoundsOfCurrentOutlineGlyph` ，也有人提出过猜测：

- Skia 有两套 bounds：
  - **tight bounds**：尽量紧，可能更容易切
  - **conservative bounds**：更保守，理论上不容易切

所以是否 `SkTextBlobBuilder::updateForeBounds` 强制用 conservative bounds 就不会裁剪了？但是最后证实，在这个 case 里 **TightRunBounds 和 ConservativeRunBounds 算出来是同一个矩形，也就是不是选错 bounds 类型的问题，而是“更底层给的 bounds 数据就已经偏小”** 。

目前测试的推论，更多是猜测是是底层  `getBoundsOfCurrentOutlineGlyph` 这个  OutlineGlyph 的问题，因为

- bounds 来自 `getBoundsOfCurrentOutlineGlyph`

- Outline bounds 是“矢量轮廓”的边界

- **但启用 hinting 后，真正被栅格化出来的像素可能会超出轮廓边界**

  - hinting 会把笔画对齐到像素栅格

  - 这种对齐可能产生 1px 的 overshoot（尤其是 descender、上/下 overshoot、抗锯齿 coverage）

- DisplayList / Opacity 拿 outline bounds 当作 layer clip bounds , 所以切掉那 1px

> 这里的 hinting  其实就是 Font Hinting ，因为字体本质是连续的矢量轮廓，像素是离散的网格，简单说就是：字体在小尺寸或特定像素网格下，对字形轮廓进行“像素级对齐和修正”的规则集合 ，目的就是让字在屏幕的离散像素网格上，看起来更清晰更锐利。

对应到代码里的现象就是：**把 `TextStyle::getFontHinting()` 强制改成始终返回 `SkFontHinting::kNone` 问题就消失了** ，因为没 hinting 时，outline bounds 和实际像素覆盖范围更一致，`SkTextBlob::bounds()` 就不会低估，所以问题应该是在于：

> **“bounds 计算口径”和“实际绘制口径”不一致**（尤其在 hinting 下），导致 `SkTextBlob::bounds()` 偏小，Opacity 的 layer clip 把溢出像素切掉。

那有人说，拿掉 hinting  不行吗？直接粗暴拿掉还真的不行，**实际上问题的核心不是 hinting  ，而是底层算的不准**，如果直接拿掉 hinting  ，就可能会出现以前在 Android Compose 上类似这样的情况：

![](https://img.cdn.guoshuyu.cn/image-20260126095940798.png)

所以实际问题本质在于：**Skia 在 FreeType 后端中使用了 glyph 的 outline bounds 作为 TextBlob bounds，而在 hinting 开启时，这种 bounds 并不能代表真实像素覆盖范围**。

> 说人话就是： Skia 在构建 TextBlob 时，从 FreeType 拿到的 glyph bounds 本身就偏小，`SkScalerContext_FreeType::getBoundsOfCurrentOutlineGlyph` 。

那么又有人要问了，Flutter 不都是 Impeller 了吗？为什么还会说 Skia ？这就需要说到，在 Flutter 里，**Impeller 更多是“GPU 渲染后端” ，但是 Impeller 对文本渲染依赖 SkParagraph 以及对图像处理依赖 Skia 编解码器**：

- Flutter 的文本渲染和功能集（如复杂脚本支持、排版准确性）从根本上受制于 SkParagraph 的能力，而 Impeller 更多在于高效地光栅化和合成 SkParagraph 提供的字形

![img](https://img.cdn.guoshuyu.cn/image-20250508110356113.png)

实际上 “渲染”（Rendering ）不等于“排版” (Typography) ，在 Flutter 里， 负责测量文字大小、断行、字形选择（Glyph Selection）等都还是依赖于 Libtxt / SkParagraph  等，所以真实情况一般是：

- Skia 生成 SkTextBlob
- Flutter 把 SkTextBlob 封装成 DisplayList command
- Impeller 执行这个 command

所以目前来看，即使是 Impeller，但是 TextBlob 仍然是 Skia 的活，**所以问题还是在于 Skia 上，文本的 bounds 仍然由 Skia/FreeType 计算**，这也是为什么这个 Bug 这么久了还是慢慢悠悠的原因之一。

因为一旦启用了 hinting，**排版（shape）和绘制（draw）时就必须在“单位矩阵（identity matrix）”下完成**，否则就会出现现在这种问题，因为 **Hinted glyph 是为某一个具体像素尺寸量身定做的，Hinting 会把笔画宽度、边界位置、对齐规则全部对齐到当前像素网格** 。

> 如果在此之后再对它做矩阵缩放，那么 hinting 时的“像素对齐”就可能会被破坏。

而对于 hinting 来说，Hinted 的字形和度量**几乎天生就不是线性可缩放的**，所以如果要修这个 Bug ，就需要把所有 scale（DPR、transform）**提前 bake 进 text size** ，然后 shape ，之后 draw 时使用 identity matrix ，这个对文本实现复杂度无疑提高了很多，所以这个修复不会很快。

> 当然，底层上也可以做个开关支持， 如果你非要用放矩阵变换，那就支持用户把 Hinting 关掉，也是一个思路。

所以，知道问题之后，如果遇到这个场景，尽量避开有问题的字号（边界跳变），同时尽量减少 `saveLayer` 的粗发，比如：

- 不要用 `Opacity` 包文字，而是把透明度放到 TextStyle Color
- 不用 `ShaderMask` ，尽量用 `TextStyle.foreground` + shader（直接在文字 paint 上做，不走遮罩 layer）
- 在 `Opacity/ShaderMask` 内部给 `Text` 上下加 1~2 px padding，让布局 bounds 变大，从而 layer bounds 也变大

**当然，也有说可以通过设置 `FontWeight.xxx` ，这样 variable font  就会变成静态字体**：

![](https://img.cdn.guoshuyu.cn/image-20260201193016920.png)

实际上知道问题后，规避的方式也很多，只能说 Skia 很强，但是 Skia 带来的字体问题一直也是居高不少，特别是在中文支持上，谁还没踩过几个坑？`