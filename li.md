# Flutter 小技巧之：实现 iOS 26 的“液态玻璃”

随着 iOS 26 发布，「液态玻璃」无疑是热度最高的标签，不仅仅是因为设计风格大变，更是因为 iOS 26 beta1 的各种 bug 带来的毛坯感让 iOS 26 冲上热搜，比如通知中心和控制中心看起来就像是一个半成品：

![](https://img.cdn.guoshuyu.cn/image-20250612160347449.png)

当然，很多人可能说，不就是一个毛玻璃效果吗？实际上还真有些不大一样，**特别是不同控件的“模糊”和“液态”效果都不大一样**，效果好不好看一回事，但是液态玻璃确实不仅仅只是一个模糊图层，至少从下面这个锁屏效果可以看到它类似液态的扭曲变化：

![image-20250612150709296](https://img.cdn.guoshuyu.cn/image-20250612150709296.png)

所以，在实现上就不可能只是一个简单的 `blur` ，类似效果肯定是需要通过自定义着色器实现，而恰好在 [shadertoy](https://www.shadertoy.com/view/WftXD2) 就有人发布了类似的实现，可以比较方便移植到 Flutter ：

![](https://img.cdn.guoshuyu.cn/ezgif-46685370b62c01.gif)

针对这个 shader ，其中 `LiquidGlass` 部分是实现磨砂玻璃效果的核心：

- `vec2 radius = size / R;` 计算模糊的半径，将其从像素单位转换为标准化坐标。

- `vec4 color = texture(tex, uv);` 获取当前像素 `uv` 处的原始颜色

- `for (float d = 0.0; d < PI; d += PI / direction)`: 外层循环，确定采样的方向，从 0 到 180 度进行迭代。

- `for (float i = 1.0 / quality; i <= 1.0; i += 1.0 / quality)` 内层循环，沿着当前方向 `d` 进行多次采样， `quality` 越高，采样点越密集

- `color += texture(tex, uv + vec2(cos(d), sin(d)) * radius * i);` 在当前像素周围的圆形区域内进行采样， `vec2(cos(d), sin(d))` 计算出方向向量，`radius * i` 确定了沿该方向的采样距离，通过累加这些采样点的颜色，实际上是在对周围的像素颜色进行平均

- `color /= (quality * direction + 1.0);` 将累加的颜色值除以总采样次数（以及原始颜色），得到平均颜色，这个平均过程就是实现模糊效果的过程

```glsl

vec4 LiquidGlass(sampler2D tex, vec2 uv, float direction, float quality, float size) {
    vec2 radius = size / R;
    vec4 color = texture(tex, uv);

    for (float d = 0.0; d < PI; d += PI / direction) {
        for (float i = 1.0 / quality; i <= 1.0; i += 1.0 / quality) {
            color += texture(tex, uv + vec2(cos(d), sin(d)) * radius * i);
        }
    }

    color /= (quality * direction + 1.0); // +1.0 for the initial color
    return color;
}
```

而在着色器的入口，它会将所有部分组合起来渲染，其中关键在于下方代码，这是实现边缘液体感的处理部分：

```glsl
#define S smoothstep

vec2 uv2 = uv - uMouse.xy / R;
uv2 *= 0.5 + 0.5 * S(0.5, 1.0, icon.y);
uv2 += uMouse.xy / R;
```

它不是直接用 `uv` 去采样纹理，而是创建了一个被扭曲的新坐标 `uv2` ，`icon.y` 是前面生成的位移贴图，`smoothstep`  函数利用这个贴图来计算一个缩放因子。

在图标中心（`icon.y` 接近 1），缩放因子最大，使得 `uv2` 的坐标被推离中心，产生放大/凸起的效果，就像透过一滴水或一个透镜看东西一样，从而实现视觉上的折射效果。

最后利用  mix 把背景图片混合进来，其中  `LiquidGlass(uTexture, uv2, ...)` 通过玻璃效果使用被扭曲的坐标 `uv2`  去采样并模糊背景：

```glsl
vec3 col = mix(
    texture(uTexture, uv).rgb * 0.8,
    0.2 + LiquidGlass(uTexture, uv2, 10.0, 10.0, 20.0).rgb * 0.7,
    icon.x
);
```

所以里实现的思路是扭曲的背景 + 模糊处理，我们把中间的 icon 部分屏蔽，换一张人脸图片，可以看到更明显的边缘扭曲效果：

![image-20250612151557905](https://img.cdn.guoshuyu.cn/image-20250612151557905.png)

当然，这个效果看起来并不明显，我们还可以在这个基础上做修改，比如屏蔽 `uv2 *= 0.5 + 0.5 * S(0.5, 1.0, icon.y)`，调整为从中间进行放大扭曲：

```glsl
//uv2 *= 0.5 + 0.5 * S(0.5, 1.0, icon.y);

// 使用 mix 函数，以 icon.x (方块形状) 作为混合因子
// 在方块外部 (icon.x=0)，缩放为 1.0 (不扭曲)
// 在方块内部 (icon.x=1)，缩放为 0.8 (最大扭曲)
uv2 *= mix(1.0, 0.8, icon.x);
```

通过调整之后，实际效果可以看到变成从中间放大扭曲，从眼神扭曲上看起来更接近锁屏里的效果：

![](https://img.cdn.guoshuyu.cn/image-20250612152654135.png)

当然，我们还可以让扭曲按照类似水滴从中间进行扭曲，来实现非平均的液态放大：

```glsl

 //vec2 uv2 = uv - uMouse.xy / R;
 //uv2 *= 0.5 + 0.5 * S(0.5, 1.0, icon.y);
 //uv2 += uMouse.xy / R;

// ================== 新的水滴扭曲 ==================

// 1. 计算当前像素到鼠标中心点的向量 (在 st 空间)
vec2 p = st - M;

// 2. 计算该点到中心的距离
float dist = length(p);

// 3. 定义水滴效果的作用半径 (应与方块大小一致)
float radius = PX(100.0);

// 4. 计算“水滴凸起”的强度因子 (bulge_factor)
//    我们希望中心点 (dist=0) 强度为 1，边缘点 (dist=radius) 强度为 0。
//    使用 1.0 - smoothstep(...) 可以创造一个从中心向外平滑衰减的效果，模拟水滴的弧度。
float bulge_factor = 1.0 - smoothstep(0.0, radius, dist);

// 5. 确保该效果只在我们的方块遮罩 (icon.x) 内生效
bulge_factor *= icon.x;

// 6. 定义中心点的最大缩放量 (0.5 表示放大一倍，值越小放大越明显)
float max_zoom = 0.5;

// 7. 使用 mix 函数，根据水滴强度因子，在 "不缩放(1.0)" 和 "最大缩放(max_zoom)" 之间插值
//    中心点 bulge_factor ≈ 1, scale ≈ max_zoom (放大最强)
//    边缘点 bulge_factor ≈ 0, scale ≈ 1.0 (不放大)
float scale = mix(1.0, max_zoom, bulge_factor);

// 8. 应用这个非均匀的缩放效果
vec2 uv2 = uv - uMouse.xy / R; // 将坐标中心移到鼠标位置
uv2 *= scale;                  // 应用计算出的缩放比例
uv2 += uMouse.xy / R;          // 将坐标中心移回

```

使用这个非均匀的缩放效果，可以看到效果更接近我们想象中的液态 “放大”：

![](https://img.cdn.guoshuyu.cn/image-20250612153254079.png)

如下图所示，最终看起来也会更想水面的放大，同时边缘的“高亮”也显得更加明显：

![](https://img.cdn.guoshuyu.cn/ezgif-1892016952e2d1.gif)

当然，这里的实现都是非常粗糙的复刻，仅仅只是自娱自乐，不管是性能还是效果肯定和 iOS 26 的液态玻璃相差甚远，就算不考虑能耗，想在其他平台或者框架实现类似效果的成本并不低，所以单从技术实现上来说，**能用液态玻璃风格作为系统 UI，苹果应该是对于能耗控制和渲染成本控制相当自信才是**。

最后，如果感兴趣的可以直接通过下方链接获取 Demo ：

- https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/liquid_glass_demo.dart

- https://github.com/CarGuo/gsy_flutter_demo/blob/master/lib/widget/liquid_glass_demo2.dart

- https://github.com/CarGuo/gsy_flutter_demo/tree/master/shaders



# 参考链接：

- https://www.shadertoy.com/view/WftXD2

- https://rive.app/marketplace/20904-39287-liquid-glass/