# Flutter 小技巧之不一样的思路实现炫酷 3D 翻页折叠动画

今天聊一个比较有意思的 Flutter 动画实现，如果需要实现一个如下图的 3D 折叠动画效果，你会选择通过什么方式？

![](http://img.cdn.guoshuyu.cn/20231031_GLSL/image1.gif)

相信可能很多人第一想法就是：**在 Dart 里通过矩阵变换配合 Canvas 实现**。

因为这个效果其实也算「常见」，在目前的小说阅读器场景里，类似的翻页效果基本都是通过这个思路完成，而这个思路以前我也「折腾」过不少，比如 [《炫酷的 3D 卡片和帅气的 360° 展示效果》](https://juejin.cn/post/7124064789763981326) 和 [用纯代码实现立体 Dash 和 3D 掘金 Logo](https://juejin.cn/post/7129239231473385503) ，就是在 Dart 里利用矩阵变换实现的视觉 3D 效果。

![](http://img.cdn.guoshuyu.cn/20231031_GLSL/image2.gif)

但是今天通过一个叫 [riveo_page_curl](https://github.com/Rahiche/riveo_page_curl) 的项目，提供了不一样的实现方式，**那就是通过自定义 Fragment Shaders 实现动画** ，使用自定义 shaders 可以直接使用 GLSL 语言来进行编程，最终达到通过 GPU 渲染出更丰富图形效果。

![](http://img.cdn.guoshuyu.cn/20231031_GLSL/image3.gif)

解释这个项目之前，我们先聊聊 Fragment Shader  ，**Flutter 在 3.7 开始提供 Fragment Shader API** ，顾名思义，它是一个作用于片段的着色器，也就是通过 Fragment Shader API ，开发者可以直接介入到 Flutter 渲染管道的渲染流程中。

![](http://img.cdn.guoshuyu.cn/20231031_GLSL/image4.png)

**那么直接使用  Fragment Shader 而不使用 Dart 矩阵变换的好处是什么**？简单来说就是可以减少 CPU 的耗时，直接通过图形语言（GLSL）直接给 GPU 发送指令，从性能上无疑可以得到提升，并且实现会更简洁。

> 不过加载着色器这个行为的开销可能会比较大，所以必须在运行时将它编译为适当的特定于平台的着色器。

当然，在 Flutter 里使用  Fragment Shader  也是有条件限制的，例如一般都需要引入 `#include <flutter/runtime_effect.glsl>`  这个头文件，因为在编写着色器代码时，我们都需要知道当前片段的局部坐标的值，而  `flutter/runtime_effect.glsl` 里就提供了  `FlutterFragCoord().xy;` 来支持访问局部坐标，而这并不是标准 GLSL 的 API 。

另外， Fragment Shader 只支持 `.frag` 格式文件， 不支持顶点着色文件 `.vert` ，同时还有以下限制：

- 不支持 UBO 和 SSBO
- sampler2D 是唯一受支持的 sampler 类型
- texture 仅支持（ sampler 和 uv）的两个参数版本
- 不能声明额外的可变输入
- 不支持无符号整数和布尔值

所以如果需要搬运一些已有的 GLSL 效果，例如 [shadertoy](https://www.shadertoy.com/) 上的代码时，那么一些必要的「代码改造」还是逃不掉的，例如下方代码是一段渐变动画的着色器：

```glsl
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
		float strength = 0.4;
    float t = iTime/3.0;
    
    vec3 col = vec3(0);
    vec2 fC = fragCoord;

    for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {

            fC = fragCoord+vec2(i,j)/3.0;
            vec2 pos = fC/iResolution.xy;
            pos.y /= iResolution.x/iResolution.y;
            pos = 4.0*(vec2(0.5) - pos);
            for(float k = 1.0; k < 7.0; k+=1.0){ 
                pos.x += strength * sin(2.0*t+k*1.5 * pos.y)+t*0.5;
                pos.y += strength * cos(2.0*t+k*1.5 * pos.x);
            }
            col += 0.5 + 0.5*cos(iTime+pos.xyx+vec3(0,2,4));
        }
    }
    col /= 9.0;
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col,1.0);
}
```

![](http://img.cdn.guoshuyu.cn/20231031_GLSL/image5.gif)

而在 Flutter 里，就需要转化为如下代码所示：

- 首先就是必不可少的  `flutter/runtime_effect.glsl`
- 其次定义 `main() ` 函数
- 然后我们需要将 `mainImage`  里定义的  `out vec4 fragColor;`  移到全局声明
- 因为在 GLSL 里 iResolution 用于表示画布像素高宽，iTime 是程序运行的时间，而这里通过 `uniform` 定义 `resolution` 和  `iTime` 直接用于接受 Dart 端的输入，其余逻辑不变
- 对应 `fragCoord` 可以在 Flutter 里通过 `FlutterFragCoord ` 获取坐标

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>

out vec4 fragColor;

uniform vec2 resolution;
uniform float iTime;

void main(){
    float strength = 0.25;
    float t = iTime/8.0;
    vec3 col = vec3(0);
    vec2 pos = FlutterFragCoord().xy/resolution.xy;
    pos = 4.0*(vec2(0.5) - pos);
    for(float k = 1.0; k < 7.0; k+=1.0){
        pos.x += strength * sin(2.0*t+k*1.5 * pos.y)+t*0.5;
        pos.y += strength * cos(2.0*t+k*1.5 * pos.x);
    }
    col += 0.5 + 0.5*cos(iTime+pos.xyx+vec3(0,2,4));
    col = pow(col, vec3(0.4545));
    fragColor = vec4(col,1.0);
}

```

>  第一行 `#version 460 core` 指定所用的 OpenGL 语言版本。

可以看到转换一段 GLSL 代码并不特别麻烦，主要是坐标和输入参数的变化，而通过这些已有的片段着色器，却可以给我们提供极其丰富的渲染效果，如下代码所示：

- 在 `pubspec.yaml`  里引入上面的  shaders 代码

- 通过 `ShaderBuilder` 加载对应 `'shaders/warp.frag'` 文件，获得 `FragmentShader`
- 利用  `FragmentShader` 的  `setFloat` 传递数据
- 通过 `Paint()..shader ` 添加着色器进行绘制，就可以完成渲染

```dart
flutter:
  shaders:
    - shaders/warp.frag

·············
  
  late Ticker _ticker;

  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsed = elapsed;
      });
    });
    _ticker.start();
  }

  @override
  Widget build(BuildContext context) => ShaderBuilder(
        assetKey: 'shaders/warp.frag',
        (BuildContext context, FragmentShader shader, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Warp')
          ),
          body: CustomPaint(
            size: MediaQuery.of(context).size,
            painter: ShaderCustomPainter(shader, _elapsed) 
          ),
        ),
      );

class ShaderCustomPainter extends CustomPainter {
  final FragmentShader shader;
  final Duration currentTime;

  ShaderCustomPainter(this.shader, this.currentTime);

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, currentTime.inMilliseconds.toDouble() / 1000.0);
    final Paint paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
```

这里唯一需要解释的就是  `shader.setFloat` 流程，因为它其实是通过索引来对应到我们在  `.frag` 文件里的变量，简单来说：

> 这里我们在 GLSL 里定义了 `uniform vec2 resolution;` 和 `uniform float iTime;` ，那么 vec2 resolution 就占据了索引 0 和 1 ，float iTime 就占据了索引 2 。

大概理解就是，vec2 就是两个 float 类型的值保存在了一起的意思，所以先声明的 vec2 resolution 就占据了 索引 0 和 1 ，举个例子，如下图所示，此时的 vec2 和 vec3 分了就占据了 0-4 的索引。

![](http://img.cdn.guoshuyu.cn/20231031_GLSL/image6.png)

而通过  `uniform ` 在 GLSL 着色器中定义值，然后在 Dart 中就可以通过 `setFloat` 的索引来传递对应数据过去，从而形成了数据交互的完整闭环。

> 这里的渐变动画在 Flutter 的完整代码可以参考 Github  https://github.com/tbuczkowski/flutter_shaders 里的 [warp.frag](https://github.com/tbuczkowski/flutter_shaders/blob/master/shaders/warp.frag) ，

同时针对前面整个渐变动画，作者在仓库内还提供了对应纯 Dart 代码实现一样效果的对比，通过数据可以看到，利用着色器的实现在性能上得到了巨大的提升。

![image-20231031175152699](http://img.cdn.guoshuyu.cn/20231031_GLSL/image7.png)

那么回过头来， [riveo_page_curl](https://github.com/Rahiche/riveo_page_curl) 的项目里的折叠着色器如下所示，除了一堆不懂的矩阵变化，如 `scale` 缩放、`translate` 平移和 `project` 投影转换之外，就是各种看不明白的三角函数计算，简单的核心就是在矩阵变化时计算弯曲部分的弧度，以及增加阴影投影来提高视觉效果。

```glsl
#include <flutter/runtime_effect.glsl>

uniform vec2 resolution;
uniform float pointer;
uniform float origin;
uniform vec4 container;
uniform float cornerRadius;
uniform sampler2D image;

const float r = 150.0;
const float scaleFactor = 0.2;

#define PI 3.14159265359
#define TRANSPARENT vec4(0.0, 0.0, 0.0, 0.0)

mat3 translate(vec2 p) {
    return mat3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, p.x, p.y, 1.0);
}

mat3 scale(vec2 s, vec2 p) {
    return translate(p) * mat3(s.x, 0.0, 0.0, 0.0, s.y, 0.0, 0.0, 0.0, 1.0) * translate(-p);
}

vec2 project(vec2 p, mat3 m) {
    return (inverse(m) * vec3(p, 1.0)).xy;
}

struct Paint {
    vec4 color;
    bool stroke;
    float strokeWidth;
    int blendMode;
};

struct Context {
    vec4 color;
    vec2 p;
    vec2 resolution;
};


bool inRect(vec2 p, vec4 rct) {
    bool inRct = p.x > rct.x && p.x < rct.z && p.y > rct.y && p.y < rct.w;
    if (!inRct) {
        return false;
    }
    // Top left corner
    if (p.x < rct.x + cornerRadius && p.y < rct.y + cornerRadius) {
        return length(p - vec2(rct.x + cornerRadius, rct.y + cornerRadius)) < cornerRadius;
    }
    // Top right corner
    if (p.x > rct.z - cornerRadius && p.y < rct.y + cornerRadius) {
        return length(p - vec2(rct.z - cornerRadius, rct.y + cornerRadius)) < cornerRadius;
    }
    // Bottom left corner
    if (p.x < rct.x + cornerRadius && p.y > rct.w - cornerRadius) {
        return length(p - vec2(rct.x + cornerRadius, rct.w - cornerRadius)) < cornerRadius;
    }
    // Bottom right corner
    if (p.x > rct.z - cornerRadius && p.y > rct.w - cornerRadius) {
        return length(p - vec2(rct.z - cornerRadius, rct.w - cornerRadius)) < cornerRadius;
    }
    return true;
}

out vec4 fragColor;

void main() {
    vec2 xy = FlutterFragCoord().xy;
    vec2 center = resolution * 0.5;
    float dx = origin - pointer;
    float x = container.z - dx;
    float d = xy.x - x;

    if (d > r) {
        fragColor = TRANSPARENT;
        if (inRect(xy, container)) {
            fragColor.a = mix(0.5, 0.0, (d-r)/r);
        }
    }

    else
    if (d > 0.0) {
        float theta = asin(d / r);
        float d1 = theta * r;
        float d2 = (3.14159265 - theta) * r;

        vec2 s = vec2(1.0 + (1.0 - sin(3.14159265/2.0 + theta)) * 0.1);
        mat3 transform = scale(s, center);
        vec2 uv = project(xy, transform);
        vec2 p1 = vec2(x + d1, uv.y);

        s = vec2(1.1 + sin(3.14159265/2.0 + theta) * 0.1);
        transform = scale(s, center);
        uv = project(xy, transform);
        vec2 p2 = vec2(x + d2, uv.y);

        if (inRect(p2, container)) {
            fragColor = texture(image, p2 / resolution);
        } else if (inRect(p1, container)) {
            fragColor = texture(image, p1 / resolution);
            fragColor.rgb *= pow(clamp((r - d) / r, 0.0, 1.0), 0.2);
        } else if (inRect(xy, container)) {
            fragColor = vec4(0.0, 0.0, 0.0, 0.5);
        }
    }
    else {
        vec2 s = vec2(1.2);
        mat3 transform = scale(s, center);
        vec2 uv = project(xy, transform);

        vec2 p = vec2(x + abs(d) + 3.14159265 * r, uv.y);
        if (inRect(p, container)) {
            fragColor = texture(image, p / resolution);
        } else {
            fragColor = texture(image, xy / resolution);
        }
    }

}

```

![](http://img.cdn.guoshuyu.cn/20231031_GLSL/image8.png)

其实我知道大家并不关心它的实现逻辑，更多是如何使用，这里有个关键信息就是 `uniform sampler2D image` ，通过引入 `sampler2D` ，我们就可以在 Dart 通过 `setImageSampler(0, image); ` 将  `ui.Image` 传递到 GLSL 里，这样就可以对 Flutter 控件实现上述的折叠动画逻辑。

对应在 Dart 层，就是除了  `ShaderBuilder` 之外，还可以通过 [flutter_shaders](https://pub.dev/packages/flutter_shaders) 的   `AnimatedSampler` 来实现更简洁的 `shader` 、`image` 和  `canvas` 的配合，其中 `AnimatedSampler` 的最大作用，就是将整个 child  通过 `PictureRecorder` 进行截图，转化成  `ui.Image`  传递给 GLSL，完成 UI 传递交互效果。

```dart
  Widget _buildAnimatedCard(BuildContext context, Widget? child) {
    return ShaderBuilder(
      (context, shader, _) {
        return AnimatedSampler(
          (image, size, canvas) {
            _configureShader(shader, size, image);
            _drawShaderRect(shader, size, canvas);
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: cornerRadius),
            child: widget.child,
          ),
        );
      },
      assetKey: 'shaders/page_curl.frag',
    );
    
    void _configureShader(FragmentShader shader, Size size, ui.Image image) {
    shader
      ..setFloat(0, size.width) // resolution
      ..setFloat(1, size.height) // resolution
      ..setFloat(2, _animationController.value) // pointer
      ..setFloat(3, 0) // origin
      ..setFloat(4, 0) // inner container
      ..setFloat(5, 0) // inner container
      ..setFloat(6, size.width) // inner container
      ..setFloat(7, size.height) // inner container
      ..setFloat(8, cornerRadius) // cornerRadius
      ..setImageSampler(0, image); // image
  }

  void _drawShaderRect(FragmentShader shader, Size size, Canvas canvas) {
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width,
        height: size.height,
      ),
      Paint()..shader = shader,
    );
  }
    
```

> 完整项目可见：https://github.com/Rahiche/riveo_page_curl

所以可以看到，**相比起在 Dart 层实现这样的 3D 翻页折叠，利用 `FragmentShader` 实现的代码会更简洁，并且性能体验上会更优于纯 Dart 实现**，最重要的是，类似 [ShaderToy](https://www.shadertoy.com/) 里的一些着色器代码，通过简单的移植适配，就可以在直接被运用到 Flutter 里，这对于 Flutter 在游戏场景的实现来无疑说非常友好。

最后，Flutter 3.10 之后， Flutter Web 同样支持了 fragment shaders，所以着色器在 Flutter 的实现目前已经相对成熟，那么如果是之前的我通过 Flutter 实现的《[霓虹灯文本的「故障」效果的实现](https://juejin.cn/post/7214858677173289017?searchId=202310311754299E224DB054AADBBC6AE2)》的逻辑转换成  fragment shaders 来完成，是不是性能和代码简洁程度也会更高？