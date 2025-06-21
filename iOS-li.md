# Flutter 应该如何实现 iOS 26 的 Liquid Glass ，它为什么很难？

iOS 26 的 Liquid Glass 发布至今，可以说是热度不减，在之前粗糙的 [《实现 iOS 26 的 “液态玻璃”》](https://juejin.cn/post/7514632455939358731)我们也聊过一些实现可能，抛开「液态玻璃」的 UI 效果好不好看等问题，这里主要是想在技术层面上聊聊它“充满细节”的“物理”实现，也是介绍为什么 Liquid Glass 不是单纯的“毛玻璃”和"水滴放大"渲染，例如：

> **每个「液态玻璃」元素的边缘高光会反射边界外的颜色，而不是仅仅来自内部玻璃效果的镜像扭曲**。

![](https://img.cdn.guoshuyu.cn/image-20250616085131208.png)![](https://img.cdn.guoshuyu.cn/image-20250616085605286.png)

所以，Liquid Glass 的核心特征和传统毛玻璃效果不同，它不仅仅是对背景进行模糊处理，它的颜色会「受周围内容的影响」，并且能在“明”“暗”环境中智能适应，也就是 Liquid Glass 除了通过实时采样背景内容，还会结合环境光和周边 UI 来动态计算。

这一细节还体现在“玻璃”对于亮光的“色散”上细节上，玻璃边缘遇到“亮光”的散射出来的彩虹效果和符号距离场（SDF ）的形状融合：

![](https://img.cdn.guoshuyu.cn/image-20250616091339712.png)![](https://img.cdn.guoshuyu.cn/ezgif-3c5fba644025bf.gif)![](https://img.cdn.guoshuyu.cn/ezgif-3a5803131a9700.gif)

这些都代表了不止是每个控件需要管理自己的渲染对象，还有更高层着色器会收集汇总信息进行处理，另外 Liquid Glass 除了 UI 的特质细节， UX 的变化也很大，例如**当没有相互作用时，玻璃似乎是固体，但当用户与其相互作用时，玻璃会变得更具流动性**：

![](https://img.cdn.guoshuyu.cn/455226575-adfd9eb2-8da4-4c25-a33a-89597369b3bb.gif)

动画像是液体放大镜，在被触碰时会像果冻一样反应，文字和线条会变得模糊：

![](https://img.cdn.guoshuyu.cn/ezgif-216d912bb5cec5.gif)

另外 Liquid Glass 还有“液态”融合的实现机制，SwiftUI 的 `GlassEffectContainer` 允许多个带有玻璃效果的视图“将其形状融合在一起”，并在过渡动画中“相互变形”  ，`glassEffectUnion` 可以让多个独立的视图共同构成一个统一的玻璃形状，这很概率是基于 SDF 的实现：

```swift
@State private var isExpanded: Bool = false
@Namespace private var namespace


var body: some View {
    GlassEffectContainer(spacing: 40.0) {
        HStack(spacing: 40.0) {
            Image(systemName: "scribble.variable")
                .frame(width: 80.0, height: 80.0)
                .font(.system(size: 36))
                .glassEffect()
                .glassEffectID("pencil", in: namespace)


            if isExpanded {
                Image(systemName: "eraser.fill")
                    .frame(width: 80.0, height: 80.0)
                    .font(.system(size: 36))
                    .glassEffect()
                    .glassEffectID("eraser", in: namespace)
            }
        }
    }


    Button("Toggle") {
        withAnimation {
            isExpanded.toggle()
        }
    }
    .buttonStyle(.glass)
}
```



![](https://img.cdn.guoshuyu.cn/ezgif-296375e50c9299.gif)



所以从设计风格上，整个 iOS 26 Liquid Glass 的一些关键特性和可能用到的技术支持：

| 特性效果                 | 表现                                                         | 视觉效果                                                     | 可能需要的技术支持                                           |
| ------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **半透明性与色彩自适应** | 半透明材质，颜色受周围内容的影响，并能在明暗环境中智能适应   | UI 元素呈现半透明状态，颜色会根据背景内容和系统主题（明/暗）发生变化 | 实时采样背景纹理，结合颜色叠加和自适应混合模式               |
| **折射**                 | 折射其周围环境，为内容带来更多焦点                           | 透过玻璃元素看到的背景内容会发生轻微的、符合物理的扭曲，产生厚度和体积感 | 屏幕空间坐标扰动，通常通过法线贴图（Normal Map）或程序化梯度计算来实现 |
| **反射与高光**           | 反射周围的内容和用户的壁纸……通过高光对运动做出动态反应       | 玻璃表面会反射周围环境（如壁纸）的颜色，并在用户交互或设备移动时出现流动的光斑 | 模拟三维光照模型，结合环境贴图和实时计算的镜面反射           |
| **流体变形**             | 控件可以动态变形……标签栏在滚动时会收缩，向上滚动时会流畅地展 | UI 元素（如按钮、滑块、标签栏）的形状和大小会根据上下文或用户操作平滑地、非线性地变化 | 基于物理的动画系统，结合元球或基于符号距离场（SDF）的形状混合技术 |



> 所以复刻的时候，需要考虑的细节就很多。

# Flutter 

## liquid_glass_example

就像之前在 [《实现 iOS 26 的 “液态玻璃”》](https://juejin.cn/post/7514632455939358731)聊的一样，实现这个效果基本避免不了实现着色器，比如 [liquid_glass_example](https://github.com/xhzq233/liquid_glass_example) 项目，就通过着色器实现了 Apple 的放大镜效果：

![](https://img.cdn.guoshuyu.cn/image-20250616092014653.png)

要实现这个效果，你需要：

- 放大/折射它下方的内容，尤其是在边缘附近
- 实现模拟光照，带有一个柔和的高光，能对一个固定的光源方向作出反应
- 需要微弱的环境光，看起来才有实体感
- 最后还需要一层淡淡的阴影

也就是，着色器需要通过模拟光照、折射和阴影，让这个“玻璃”看起来像是悬浮在背景内容之上的一个 3D 效果，而在这个项目的着色器实现上，核心在于：

- 有向距离场 (SDF) 计算  ：用于描述空间中任意点 `(x, y)` 到形状表面的最短距离，SDF 主要在创建平滑的几何形状以及轮廓、阴影等效果时引用：
  - 如果返回值是负数，说明点在形状内部
  - 如果返回值是正数，说明点在形状外部
  - 如果返回值是零，说明点正好在形状的表面上
- **smoothstep(edge0, edge1, x)** ：当 `x` 的值从 `edge0` 变化到 `edge1` 时，它会生成一个从 0 到 1 的平滑过渡，可以用于创建柔和的边缘、渐变和抗锯齿效果

![](https://img.cdn.guoshuyu.cn/ezgif-3834c87e967d2f.gif)

如下代码可见，这个着色器的核心就是：

- 调用 `RBoxSDF` 函数，根据 SDF 实现来获取当前像素 `uv` 的距离值 `box`
- 根据 `box` 位置创建遮罩：
  - 如果 `box` < 0 (在内部)，这个值会平滑地变为 1.0 (可见)
  - 如果 `box` > PX(1.5) (在外部)，这个值会是 0.0 (透明)
- 根据 `box` 创建边缘的渐变折射  `edgeRefraction`，在中心附近为 1.0，并向边缘平滑过渡到 0.0，实现了类似透镜的“凸起”效果
- 基于  `box`，计算出柔和的环境光、定向高光以及在形状外部的一圈微弱的投影
- 使用中心点指向当前像素的向量 `refractedUV` 乘以一个折射 `edgeRefraction` ，实现一个“拉向中心”的操作，得到像放大镜的效果
- 最后混合计算前面得到的环境光和投影

```js


// 用于将以像素为单位的长度 a 转换为基于屏幕高度的归一化值
// 在不同分辨率的屏幕上看起来大小一致
#define PX(a) a / u_resolution.y


// RBoxSDF: 计算一个点 p 到一个圆角矩形表面的最短有向距离（SDF）
// 输入:
//   p:      当前像素的坐标
//   center: 矩形的中心点坐标
//   size:   矩形的半宽和半高
//   radius: 矩形的圆角半径
// 返回值:
//   负数: 点在矩形内部
//   正数: 点在矩形外部
//   零:   点在矩形边框上
float RBoxSDF(vec2 p, vec2 center, vec2 size, float radius) {
    // 将坐标系原点移至矩形中心，并使用 abs() 将计算折叠到第一象限，以简化问题
    vec2 q = abs(p - center) - size + radius;
    // 这是计算圆角矩形 SDF 的公式
    // 结合了点到矩形直线边缘的距离和到圆角的距离
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}


void main() {
    ///····

    // 调用 SDF 函数，计算当前像素 uv 到圆角矩形表面的距离
    float box = RBoxSDF(uv, Mst, rectSize, radius);


    // 创建主体形状的遮罩 (Mask)
    // 利用 smoothstep 创建一个平滑的过渡。
    // 因为 SDF 内部为负，所以 smoothstep 的参数是反的 (PX(1.5), 0.)
    // 效果是：在矩形内部 (`box` < 0) `boxShape` 趋近于 1，在外部则趋近于 0
    float boxShape = smoothstep(PX(1.5), 0., box);
    
    // 创建边缘折射效果的强度渐变
    // 嵌套的 smoothstep 创造出一个在矩形边缘附近区域的平滑带状渐变
    // 这个值将控制折射（像素位移）的强度，中心强，边缘弱，产生凸透镜效果
    float edgeRefraction = smoothstep(-.7, 1., smoothstep(PX(15.), PX(-15.), box));

    // 计算模拟光照
    // 环境光 (Ambient Light): 给物体一个基础亮度，使其不会全黑。
    float ambientLight = boxShape * smoothstep(PX(-5.), PX(10.), box) * 0.1;

    // 模拟来自特定方向的光源
    // 定义一个从左上角照向右下角的光源方向（相对于矩形中心）
    vec2 lightDir = normalize(vec2(.5, 1.) - Mst);
    // 用一个从中心向外辐射的向量来“假装”是表面的法线向量
    vec2 boxNormal = uv - Mst;
    // 计算法线和光照方向的点积(dot product)，得到光照强度
    float diffuseLight = 2.3 * dot(boxNormal, lightDir);
    // 将漫反射光限制在形状内部
    diffuseLight *= boxShape - smoothstep(0., PX(-2.5), box);
    // 合并环境光和漫反射光
    vec3 light = vec3(ambientLight + abs(diffuseLight));

    // 阴影 (Shadow)
    // 1. - abs(box) 会在 box 等于 0 的地方（即边框）产生一个亮线
    float shadow = (1. - abs(box));
    // 通过减去 0.99 并乘以 10，只保留并放大了非常靠近边框的这条线，形成细微的投影
    shadow = max(0., (shadow - .99) * 10.);
 

    // 计算折射
    // 计算从中心点指向当前像素的向量
    vec2 refractedUV = uv - Mst;
    // 用前面计算的 edgeRefraction 渐变来缩放这个向量，实现扭曲效果
    refractedUV *= edgeRefraction;
    // 将扭曲后的向量加回中心点，得到最终采样背景纹理时使用的 UV 坐标
    refractedUV += Mst;

    // --- 最终颜色合成 ---

    // 使用 mix 函数进行混合。
    // boxShape 作为混合因子：
    // 如果 boxShape 是 0 (在矩形外)，结果是 texture(u_texture_input, uv).rgb` (原始背景)
    // 如果 boxShape 是 1 (在矩形内)，结果是 texture(u_texture_input, refractedUV).rgb (折射后的背景)
    vec3 color = mix(texture(u_texture_input, uv).rgb, texture(u_texture_input, refractedUV).rgb, boxShape);
    
    // 在混合后的颜色上疊加我们计算出的光照
    color += light;
    // 再减去阴影
    color -= shadow;

    // 将最终计算出的 RGB 颜色和一个完全不透明的 Alpha 值 (1.0) 赋给输出变量
    frag_color = vec4(color, 1.0);
    
}
```

可以看到，单从这个简单放大器实现上看计算量其实就并不小，而这对于 Apple 的 Liquid Glass Style 而言，这只是一个普通的特性效果。

## liquid_glass_renderer

而在另外一个项目 [liquid_glass_renderer](https://github.com/whynotmake-it/flutter_liquid_glass/tree/main/packages/liquid_glass_renderer)，可以看到它利用着色器实现了更丰富的 Liquid Glass  复刻效果，内部包括 SDF、物理折射模型、高级光照和色散效应等，主要支持有：

- `LiquidGlass` ：独立“玻璃”小部件 
- `LiquidGlassLayer` ：类似前面的 `GlassEffectContainer` ，可以讲多个“玻璃”可以像液体一样混合在一起
- `LiquidGlassSettings`：可调整厚度、色调、灯光
- `LiquidGlassSquircle`：支持的形状
- 支持背景模糊和折射

![](https://img.cdn.guoshuyu.cn/ezgif-3aaecf902d2c24.gif)![](https://img.cdn.guoshuyu.cn/ezgif-3da6759fd7741a.gif)

> 仅支持 Impeller 内核，因为 `ImageFilter.shader` 需要 Impeller 支持，而 `BackdropFilterLayer` 可以和 `ImageFilter` 结合：![](https://img.cdn.guoshuyu.cn/image-20250616113137550.png)![](https://img.cdn.guoshuyu.cn/image-20250616113208576.png)

目前这个效果是通过获取 `LiquidGlass` 背后内容的像素并对其进行扭曲”来实现的：  

- 开发者必须使用 `Stack` 布局，将背景内容放在底层，将 `LiquidGlass` 或 `LiquidGlassLayer` 放置在上层
- 在渲染 `LiquidGlass` 元素之前，Flutter 的渲染引擎会先将 `Stack` 中位于下方的所有内容渲染到一个离屏纹理（Framebuffer Object, FBO）
- 这个包含背景内容的纹理，连同 `LiquidGlassSettings` 中的参数，被一同传递给自定义的片段着色器
- 着色器对每一个像素进行计算，根据参数模拟折射（扭曲背景纹理采样坐标）、光照和融合效果

> 也就是，在绘制 Liquid Glass 元素之前，会有对背景的一次“截图”t的纹理提取（`BackdropFilterLayer`） 。

事实上，对于这个着色器里的 `uniform sampler2D uBackgroundTexture`，正是来自  `BackdropFilterLayer`：

```dart
BackdropFilterLayer(
   filter: ImageFilter.shader(_shader),
),
```

因为 `ImageFilter.shader` 允许开发者提供一个自定义的 `FragmentShader` ，而这个 shader 可以访问输入纹理（input texture），而对于 `BackdropFilter ` 这个输入纹理就是下方的背景内容：

![](https://img.cdn.guoshuyu.cn/image-20250616130025407.png)![](https://img.cdn.guoshuyu.cn/image-20250616151846192.png)

> 所以 `ImageFilter.shader` 着色器包含要至少一个 sampler2D 统一变量。

而在着色器的详细实现核心流程为：

- 通过 SDF 计算当前像素到所有玻璃形状融合后最终轮廓的距离
- 基于上述距离计算一个 `alpha` 值，用于在玻璃边缘创建平滑的过渡效果
- 计算出玻璃表面的法线向量和虚拟高度
- 计算光线穿过玻璃后的扭曲效果，如果启用了色散，会对红、绿、蓝三个颜色通道分别进行折射计算，以模拟棱镜效果
- 计算所有光照效果，包括环境反射、高光、轮廓光等
- 将折射后的背景色与玻璃自身的颜色进行混合

```js
id main() {

    ···
    // 1. 计算到场景SDF的距离
    float sd = sceneSDF(p);
    ···
        
    // 2. 根据距离计算alpha，实现边缘平滑过渡
    float alpha = smoothstep(-4.0, 0.0, sd);
    ···

    // 3. 如果在形状外或厚度为0，则提前返回
    if (alpha > 0.999 |
| uThickness < 0.01) {
        fragColor = texture(uBackgroundTexture, screenUV);
        return;
    }
    ····

    // 4. 计算法线和高度
    vec3 normal = getNormal(sd, uThickness);
    float height = getHeight(sd, uThickness);
    ····

    // 5. 计算折射和色散
    vec4 reflectColor = vec4(0.0);
    float reflectionIntensity = clamp(abs(refractionDisplacement.x - refractionDisplacement.y) * 0.001, 0.0, 0.3);
    reflectColor = vec4(reflectionIntensity, reflectionIntensity, reflectionIntensity, 0.0);
    ·····

    // 6. 计算光照
    vec3 lighting = calculateLighting(screenUV, normal, height, refractionDisplacement, uThickness);
    ····

    // 7. 混合颜色并叠加光照
    finalColor = clamp(finalColor, 0.0, 1.0);
    falloffColor = clamp(falloffColor, 0.0, 1.0);
    ·····

    // 8. 根据alpha值与背景混合，输出最终颜色
    vec4 backgroundColor = texture(uBackgroundTexture, screenUV);
    fragColor = mix(backgroundColor, finalColor, 1.0 - alpha);
}
```

首先，着色器直接使用符号距离场 (SDF) 来定义形状，主要是针对融合过程中创建平滑几何体的支持，也就是液态”融合效果的核心，这里不是简单地取两个形状距离的最小值（因为 `min()` 会产生尖锐的交角），而是使用一个平滑函数 `smoothUnion`，其中 `uBlend`  控制着融合的“粘滞”程度：值越大融合边缘越平滑、范围越广 ：

```js
// 平滑并集函数，k值越大融合越平滑
float smoothUnion(float d1, float d2, float k) {
    float e = max(k - abs(d1 - d2), 0.0);
    return min(d1, d2) - e * e * 0.25 / k;
}

// 组合场景中所有形状的SDF
float sceneSDF(vec2 p) {
    // 分别计算三个形状的SDF
    float d1 = getShapeSDF(uShape1Type, p, uShape1Center, uShape1Size, uShape1CornerRadius);
    float d2 = getShapeSDF(uShape2Type, p, uShape2Center, uShape2Size, uShape2CornerRadius);
    float d3 = getShapeSDF(uShape3Type, p, uShape3Center, uShape3Size, uShape3CornerRadius);
    // 将它们平滑地融合在一起
    return smoothUnion(smoothUnion(d1, d2, uBlend), d3, uBlend);
}
```

另外，为了进行真实的光照和折射计算，着色器需要知道玻璃表面每一点的朝向（法线）和厚度（高度）：

```js
// Calculate 3D normal using derivatives
vec3 getNormal(float sd, float thickness) {
    float dx = dFdx(sd);
    float dy = dFdy(sd);
    
    // The cosine and sine between normal and the xy plane
    float n_cos = max(thickness + sd, 0.0) / thickness;
    float n_sin = sqrt(max(0.0, 1.0 - n_cos * n_cos));
    
    // Return the normal directly without encoding
    return normalize(vec3(dx * n_cos, dy * n_cos, n_sin));
}

float getHeight(float sd, float thickness) {
    if (sd >= 0.0 || thickness <= 0.0) {
        return 0.0;
    }
    if (sd < -thickness) {
        return thickness;
    }
    
    float x = thickness + sd;
    return sqrt(max(0.0, thickness * thickness - x * x));
}

```

- `getNormal`：通过计算 SDF 在 x 和 y 方向上的偏导数（`dFdx(sd)` 和 `dFdy(sd)`）来实时生成法线向量,，因为 SDF 的梯度（由偏导数构成）天然地垂直于其等值线（即形状表面）
- `getHeight`：根据像素到形状表面的距离 `sd` 和玻璃总厚度 `uThickness`，计算出一个虚拟的表面高度，这样子就模拟了玻璃从边缘到中心逐渐变厚、表面呈弧形的物理形态

接着，就是使用  GLSL 内置的 `refract` 函数来计算光线穿过介质，根据计算出的虚拟高度 `height` 来决定光线在玻璃内部“行进”的距离，从而计算出背景纹理采样坐标的最终偏移量 `refractionDisplacement` ：

```js
// 如果开启了色散效果
if (uChromaticAberration > 0.001) {
    // 为R, G, B通道设置微小的折射率差异
    float iorR = uRefractiveIndex - uChromaticAberration * 0.04;
    float iorG = uRefractiveIndex;
    float iorB = uRefractiveIndex + uChromaticAberration * 0.08;

    // 分别计算每个通道的折射，并从背景纹理的不同位置采样
    vec3 refractVecR = refract(incident, normal, 1.0 / iorR);
    //... 计算红色通道的采样坐标和颜色...
    float red = texture(uBackgroundTexture, refractedUVR).r;

    //... 计算绿色通道...
    float green = texture(uBackgroundTexture, refractedUVG).g;

    //... 计算蓝色通道...
    float blue = texture(uBackgroundTexture, refractedUVB).b;

    // 重新组合成最终的折射颜色
    refractColor = vec4(red, green, blue, bgAlpha);
} else {
    // 如果不开启色散，则按正常路径计算一次折射
    vec3 refractVec = refract(incident, normal, 1.0 / uRefractiveIndex);
    float refractLength = (height + baseHeight) / max(0.001, abs(refractVec.z));
    refractionDisplacement = refractVec.xy * refractLength;
    vec2 refractedUV = screenUV + refractionDisplacement / uSize;
    refractColor = texture(uBackgroundTexture, refractedUV);
}
```

而为了模拟更高级的真实感，当 `uChromaticAberration` 参数大于零时，着色器会模拟色散效果，它通过为红、绿、蓝三个颜色通道设置略微不同的折射率，并分别计算它们的折射路径。最终，它会从背景纹理上三个不同的位置分别采样 R、G、B 分量，然后重新合成为一个带有彩色边缘的像素，从而实现光线通过棱镜后发生色散的现象 。

而  `calculateLighting` 是实现的光照和反射细节代码就更长了，它的主要目标是模拟光线与一个半透明、有厚度的玻璃状物体交互时产生的多种复杂效果，最终输出一个光照颜色值，用于叠加在最终颜色上，例如：

- 通过计算 Fresnel effect 公式来模拟物体边缘更亮的现象：

```js
float fresnel = pow(1.0 - max(0.0, dot(normal, viewDir)), 3.0);
vec3 rimLight = vec3(fresnel * uAmbientStrength * 0.5);
```

- 直接使用表面法线的 `xy` 分量作为反射方向，创造出一种向外扩散的反射效果，4-tap blur 对采样点周围进行简单的模糊处理，让反射看起来更柔和、更像环境光：

 ```js
 ec2 reflectionDir = normalize(normal.xy);
 vec2 baseSampleUV = uv + reflectionDir * reflectionSampleDistance / uSize;
 // ... (4-tap blur)
 reflectedColor = sampledColor / 4.0;
 ```

- 模拟两个主要的光源（一个主光源和一个微弱的副光源，方向相反），并创造了两种不同质感的高光：

```js
// 1. Sharp surface glint
vec3 sharpGlint = whiteGlint * reflectedColor;

// 2. Soft internal bleed
float internalIntensity = smoothstep(5.0, 40.0, displacementMag);
// ...
vec3 lighting = ... + sharpGlint + (softBleed * internalIntensity) + ...;
```

- 最后还增加了一层基础反射，确保了即使在没有被高光直接照射到的地方，玻璃表面依然能呈现出基础的反射质感：

```js
float reflectionIntensity = reflectionBase + reflectionFresnel * reflectionFresnelStrength;
vec3 environmentReflection = reflectedColor * reflectionIntensity;
```

最终的 `liquid_glass.frag` 有 350+ 行代码，当然最终运行后的色散效果还是不如原生的自然，但是整体还原度确实很高，不得不说大佬的动手能力就是强，目前测试的性能还可以：

![](https://img.cdn.guoshuyu.cn/ezgif-63975369dca532.gif)

> 可以看到这是一个相对复杂的着色器，如果没有 AI 帮忙解读，理解对应部分实现确实很吃力。

# 最后

所以，从目前来看 Liquid Glass  确实不是一个简单的“毛玻璃滤镜”，而是到很多因素的影响的“物理玻璃”效果，当没有相互作用时，“玻璃”类似是固体，但当用户与其相互作用时，“玻璃”会变得更具流动性的液体。

而其他框架复刻类似效果，基本逃不过自定义着色器支持，而这里面必定包含大量数学运算，对于性能不佳的老机型肯定是劝退，不过也可以看出来，复刻 80% 左右的可能性还是挺高的，至少 [liquid_glass_renderer](https://github.com/whynotmake-it/flutter_liquid_glass/tree/main/packages/liquid_glass_renderer) 给我们展示了这种可能。

而大部分时候，着色器代码是可以移植的，也就是当越来越多的大佬开始复刻时，我们将拥有越来越多可选择的实现途径。

当然，**未来 Flutter 肯定不会内置  Liquid Glass  风格**，目前 issue 讨论里，官方已经明确不会内置跟进 Material Expressive 风格，并且未来 Cupertino 和  Material Design 大概率也会抽离成外部依赖，其实这才是 Flutter 真正的路线，Framework 只专注于统一 UI 渲染的高性能渲染，平台风格控件通过外部依赖实现才是正轨。

另外抽离出来独立的平台特色 Package 也能更好推进特性开发，现在 Framework 里一个简单的 UI 性质调整 PR，光跑 test 可能都要 30 分钟，而且 merge 要应对的 CI 、 审查和冲突解决也十分繁琐，导致这类特性推进成本一直偏高，通过独立 Package  也能更好更快跟进支持。

所以，你觉得你的 App 未来会需要 Liquid Glass  风格吗？

# 参考链接

- https://github.com/flutter/flutter/issues/170310

- https://github.com/xhzq233/liquid_glass_example

- https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/

- https://github.com/whynotmake-it/flutter_liquid_glass/tree/main/packages
- https://www.reddit.com/r/FlutterDev/comments/1lb4tqv/just_released_a_flutter_package_for_liquid_glass/



