# Flutter Windows 开始支持 Impeller ，还修复了多窗口 bug 

因为这段时间一直在使用  Flutter  多窗口的原因，有一个  windows 多窗口的 bug  一直挺难受的，就是在切换到项目子窗口的时候，会默认激化主窗口，之后才能再次点击回到子窗口：

![](https://img.cdn.guoshuyu.cn/ezgif-4b18d3203ec88578.gif)

> 更准确说是，就是激活一个 child `RegularWindow` 后，主窗口会重新回到前台并盖住它。

这个问题的诱因很多，但是实际上主要就是代码写的太草台。 

原因之一是在 Engine 里，Engine 收到 Windows 的 `WM_ACTIVATE` 消息时，不管窗口是激活还是失活，都会执行：

```c++
FocusRootViewOf(this);
```

也就是让当前窗口里的 Flutter view 获得焦点，**但是问题在于，当主窗口正在失去焦点时，它也会执行这句**，然后就导致主窗口本来应该退到后面，然后又主动 `SetFocus` 自己，然后 Windows 又把主窗口重新激活并拉到最前面。

这个 Bug 就算了，**主要是 Flutter framework 还把多个窗口的 focus tree 挂错了层级**，Flutter 的多窗口里，每个窗口都有自己的 `View` ，但 Framework 里子窗口的 `FocusScope` 居然还会有挂在父窗口的 `FocusScope` 下面的情况，这样会造成一个新问题：

> 子窗口获得焦点时，主窗口的 focus scope 也被认为“有焦点”，然后主窗口又又又通知 engine：“我有焦点了，把我的 native window 激活”，然后又又又又会把主窗口拉到前面····

而且整个过程，**也没有判断是否已经有另一个窗口拿到焦点**，这就导致这个  Bug  是综合好几个地方导致，之前好久一直没能根本修复问题。

> 一直只能写兜底代码来强切。

不过针对这三个问题，最近终于修复了：

- 如果收到的是 `WA_INACTIVE`，也就是窗口正在失活，就直接返回，不再抢焦点
- 每个 `View` 的 focus subtree 直接挂到全局 root scope 下
- 只有在没有其他窗口申请焦点时，才恢复旧焦点

**然后在我合并完这部分代码之后，马上又躺了另外一个坑：Flutter windows 开始启用 Impeller 了**，是的，Flutter 开始在 Windows 上用 OpenGLESSDF 适配 Impeller 了：

![](https://img.cdn.guoshuyu.cn/image-20260708114539642.png)

然后问题又出现了，**在绘制 canvas 的时候，出现了细线看起来比 Skia 粗约 1.3–1.6 个物理像素的情况，而且更暗**：

![](https://img.cdn.guoshuyu.cn/image-20260708114452360.png)

**如果叠加 alpha ，还会直接失效**，这些以前在我项目里若隐若现的细线，在 Impeller 出来后直接就变成又大又粗：

![](https://img.cdn.guoshuyu.cn/image-20260708114655180.png)

根据 issue 的计算，目前不同的粗细在 Impeller 上变化倍率也不一样：

| 笔画宽度 (logical→physical) | Skia 覆盖度 | Impeller 覆盖度 | 倍数      |
| --------------------------- | ----------- | --------------- | --------- |
| 0.5 → 0.75 px               | 0.75        | 2.00            | **2.7×**  |
| 1.0 → 1.5 px                | 1.50        | 2.78            | **1.9×**  |
| 2.0 → 3.0 px                | 3.00        | 4.59            | **1.5×**  |
| 4.0 → 6.0 px                | 6.00        | 7.50            | **1.25×** |

而且粗细还不是主要问题，主要问题是：

- 在 canvas transform 缩放下，AA  边缘也跟着被放大，导致缩放比例越大线条越糊（zoom=4 时 0.5px 线变成 12px 宽模糊带）
- Alpha 值被完全忽略：`0xCC` 和 `0x66` 渲染结果像素完全一致
- 极细线在某些情况下整条消失

这个问题看起来像是 Impeller 的 `SDFAlpha` 实现有问题， `smoothstep` 范围是固定的物理像素宽度，比如 `smoothstep(-fade_size, fade_size, sdf)` 会在笔画边缘两侧分别产生约半个 `pixel_size * aa_pixels` 的渐变过渡带，而这个过渡带是固定宽度（取决于 `aa_pixels` 参数，代码中设置为常量）。

> 然后对于 Skia 这样的解析式 AA，覆盖度 = 笔画宽度，但是对于 SDF 的 smoothstep，覆盖度 = 笔画宽度 **+ 固定边缘过渡带**，所以当笔画只有 0.75 物理像素宽时，这个固定的 ~1.2px 过渡带就变得很明显，导致渲染出来的线是"实心宽线 + 两侧晕染"。

另外 `float half_stroke = max(stroke_width, base_pixel_size) * 0.5`  的最小宽度钳制没有补偿 alpha ，当 `stroke_width < 1` 像素时，这里会把宽度强制钳制到至少 1 个像素（`base_pixel_size`），但没有按比例降低 alpha 来补偿。

> 而Skia 的做法是亚像素线宽： 把线变成 1 像素宽但按比例降低 alpha（0.75px 线 ≈ 38% 不透明的 1px 线），Impeller 的 SDF 实现直接给了满 alpha 的 1px+ 宽线，所以看起来更暗更粗。

也就是 `SDFStroke` 根本没有把 alpha 纳入计算，alpha 值到 fragment shader 时已经在别处处理，没有和宽度钳制联动。

目前暂时缓解的办法有：

- **用 `drawRect` 替代 `drawLine`** ：用高度等于期望线宽的 filled rect 代替 stroked line，fill 路径的 UberSDF 覆盖度是正确的
- **强制使用 Skia**：`--no-enable-impeller`
- **1px 整像素线宽**：用 1.0 物理像素宽的线

目前看来，Impeller 在 Windows 上估计还是要经历一次 Android 的问题，不得不说，自渲染的维护成本确实高，不过多窗口在 Windows 上确实也可以用了，自从 bug 解决之后，基本没什么大问题了。



# 链接

https://github.com/flutter/flutter/issues/187436

https://github.com/flutter/flutter/issues/188911