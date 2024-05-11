# Flutter 即将放弃 Html renderer ，你是否支持这个提议？

在之前的[《Flutter Web 的未来，Wasm Native 即将到来》](https://juejin.cn/post/7352527589246599178) 中我们知道，Flutter 通过推进  WasmGC  的落地来支持 Dart Native ，从而让 Flutter  Web 在浏览器上实现原生的  Wasm Native  的支持， 这也是 Flutter Web 最终决定的技术路线，也就是   `CanvasKit`  才是Flutter Web 的未来 。

![](http://img.cdn.guoshuyu.cn/20240408_rm/image1.png)

> 因为将 Flutter Widget 转化为 Html 标签渲染的方式，其实本质上违背了 Flutter Engine 的跨平台方式。

在这个基础上，官方认为与基于 WebGL 的  `CanvasKit`   和 `Skwasm` 渲染器相比，**HTML 渲染器复杂、性能表现不佳且图形表现力有限等原因**，同时 CanvasKit 渲染器又即将引来突破性的更新，**而未来 Html renderer 能提供的价值远低于维护成本和开发人员面临的复杂性**，毕竟在多个渲染器之间进行兼容和解决问题的成本太高，所以官方提议弃用并删除 Flutter Web 的 Html renderer。

在历史问题上，Html renderer 经常会出现渲染效果和其他平台不一致的问题，因为 HTML renderer 必须通过 HTML 的方式去模拟其他平台的某些功能，如渐变、文本布局、像素着色器等，而这些适配十分占用开发资源，并且效果也存在微妙的差异。

# 为什么要移除 Html renderer

事实上 Html renderer  是从 2018 年开始作为 Flutter Web 的第一个渲染器，HTML renderer 其实是 HTML、CSS、Canvas 2D、SVG 和 WebGL 的组合产品，在早期它也具备了一些优势：

- Size 更小，加载更快，并且可以通过[deferred-components 的方式进行懒加载拆包 ](https://juejin.cn/post/7095294020900880420?searchId=202404080745068491EC83C34CCF434866#heading-4)。
- PlatformView 的支持零成本，因为支持介入更多的 “HTML” 而已，在 HTML 中嵌套 HTML 很简单。
- 支持 CORS 图像 ，因为是基于 `<img>` 标签实现，但是这对于 Flutter 而言有好有坏，因为 Flutter 没有处理图像的像素，所以和其他平台相比，无法控制帧和应用一些像素效果
- HTML 可以更轻松访问本地字体，无需从网络获取字体，这对比 WebGL 是一个比较大的优势，目前从长远来看，W3C 提案例如[[canvas-formatted-text](https://github.com/WICG/canvas-formatted-text)](https://github.com/WICG/canvas-formatted-text) 理论可以彻底解决这个问题。

那既然有这么多优势，为什么还要移除？

前面提到过，由于 Flutter 一直以来都是以 Canvas 为基准通过 Engine 来实现跨平台，并且保证不同平台上的控件得到一致的渲染效果，而 Html renderer 的渲染方式明显违背了初衷，在兼容适配的过程中产生了许多额多的开发成本。

其次，将 HTML、CSS、Canvas 2D、SVG 和 WebGL 组合到单个渲染器中并不容易，对于 Flutter 本身的 API ，他丧失了很多原本应该具备的能力，比如：

- Path.combine
- drawAtlas, drawRawAtlas
- dilate, erode, compose image filters
- conic path segments
- linearToSrgbGamma, srgbToLinearGamma color filters
- saveLayer
- FragmentProgram, FragmentShader
- strokeMiterLimit
- Paint.imageFilter
- Scene.toImage, Scene.toImageSync
- Image features that require access to pixel data

而有些功能虽然有实现，但它们的实现存在着性能缺陷，例如：

- BlendMode
- Gradient
- drawVertices
- drawPoints
- drawPicture
- Picture.toImage
- MaskFilter.blur (throws in Safari)

由于 HTML renderer 无法支持 Flutter 的 API，这就会让 Framework 、 Plugin 和 App 需要在开发时兼容和维护一些特殊的代码如 `kIsWeb` 检查。

最后，Flutter 团队需要对 HTML 特定问题进行分类，它还使非 HTML 问题的分类变得更加复杂，因为处理问题的第一步经常需要区分是哪个渲染器受到影响。

当然，在此之前社区对于 HTML renderer 还存在一些误解，例如：

- **HTML 支持 Accessibility**：事实上，Flutter 得 Semantic DOM 设计完全支持 Flutter 的辅助功能，对于全部渲染器  CanvasKit、Skwasm 和 HTML 都是一样可以适配支持无障碍能力。
- **它提供 SEO**：与 Accessibility 一样，渲染树不适合作为 SEO 的来源，因为它不以逻辑方式呈现内容，爬虫最多只能看到一些使用 HTML 或 SVG 绘制的文本片段，但最终出现在 2D 画布中的文本对于爬虫来说是不可见的，所以目前 Flutter 官方也正在研究使用语义树作为 SEO 数据的来源。



# 新的 CanvasKit

在此之前， `CanvasKit`   最饱受争议的就是它的大小和加载速度，最初引入 CanvasKit 时，Flutter 需要 3.2MB 的额外负载才能渲染第一帧，并且很多移动端设备并不支持 WebGL 2。

例如有人提到了，他们的网站是使用  CanvasKit 构建，而在跟踪用户流失情况是发现 33% 的潜在客户在加载应用是离开，这三个罪魁祸首似乎是 `dart.main.js 1.6mb`、`canvaskit.wasm 1.5mb` 以及启动 Engine 所需的时间：

![](http://img.cdn.guoshuyu.cn/20240408_rm/image2.png)

而现在在经过多次优化和时间沉淀后：

- **`CanvasKit`   的大小已经缩小到 1.5MB，新的渲染器  Skwasm 还可以其进一步缩小到 1MB 左右**

- WebGL 2.0 在每个主要浏览器中[至少支持3个版本](https://caniuse.com/?search=WebGL 2.0) 

  ![](http://img.cdn.guoshuyu.cn/20240408_rm/image3.png)

- 新的 Web API 可提高基于 WebGL 的渲染效率，包括：

  - 支持 WebCodecs（特别是 ImageDecoder）
  - [SharedArrayBuffer](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer)，启用共享内存多线程
  - WasmGC

> 预计在 10 mbps 网速下，启动开销为 0.8 秒，并且由于 `CanvasKit` 是可缓存资源，因此它可以在开始时与其他资源并行加载，实践使用中的开销可以小于 0.8 秒。

而在新的 `CanvasKit`  下，Flutter 正在推动进一步的优化支持，例如：

- 可以在获取静态资源时支持并行加载，在获取 `canvaskit.wasm` 的同时同步获取数据 `main.dart.js`

- Bootstrap API 支持在后台加载 Flutter 时为应用创建纯 HTML 登录页面，当用户完成与登陆页面的交互时，大部分 Flutter Web loading 已经完成
-  iOS 中的大部分缓慢都是由于缺乏 `ImageDecoder` API，因此目前还需要找到比当前单线程 wasm 编解码器解决方案更好的图像解码器。

当然，对于 `CanvasKit`    来说，目前还需要推进的问题还有：

- CORS 图像
- 更好的 PlatformView
- iOS （即 Safari/WebKit）适配

而对于  `CanvasKit`   来说，**无法解决的问题就是不支持没有 GPU 的硬件**，因为对于 Flutter 来说，GPU 是至关重要的一环，特别未来对于 Impeller 的支持上。



# 最后

其实 Flutter 一直是 Flutter 里的另类而有特殊的存在，Flutter 来源于前端 Chrome 团队，起初 Flutter 的创始人和整个团队几乎都是来自 Web，但是由于前期技术局限的原因，为了适配 Web，Flutter Web 成了 Flutter 所有平台里“最另类又奇葩”的落地。

![](http://img.cdn.guoshuyu.cn/20240408_rm/image4.png) 

> 而如今官方在明确了以 `CanvasKit` 和 Wasm Native 为核心路线的情况下看，Html Renderer 退出历史舞台是必然的趋势，而差别就在于它的过渡期需要多久？

目前看来 `CanvasKit`  还有诸多这样那样的不足，例如原生层面还不支持 SVG ，需要通过 `flutter_svg` 来做支持，对于 Web 来说其实支持 SVG 应该是一件“非常简单”的事情。

另外例如 `CanvasKit`   还有一些比较边缘的兼容问题，例如这个页面是采用 wasm 渲染的 Flutter Web 页面，但是当我们用插件翻译页面内容时，可以看到只有标题被翻译了，主体内容并没有，因为此时 Flutter Web 的主体内容都是 Canvas 绘制，没有 html 内容，所以无法被识别翻译，另外如果你保存或者打印网页，也是输出不了完整 body 内容。

![](http://img.cdn.guoshuyu.cn/20240408_rm/image5.png)

所以目前来看，`CanvasKit`  还是有许多需要打磨的地方，不过不可否认的是，它正在变得更好。

**那么，你支持这次移除并启用 Html renderer 的提议吗**？



更多可见：https://github.com/flutter/flutter/issues/145954


