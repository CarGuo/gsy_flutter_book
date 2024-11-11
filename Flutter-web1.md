# Flutter Web 正式官宣弃用 HTML renderer ， Canvas 路线成为唯一

**Flutter Web 团队计划在 2025 年的第一个 Flutter  stable 版本中弃用 HTML renderer，当然在 master 和 beta 中会更早合并这一更改**。

关于这个话题，其实在年初的我就曾发布过 [《Flutter 即将放弃 Html renderer 》](https://juejin.cn/post/7355011549827121179)， Html renderer 从 2018 年开始作为 Flutter Web 的第一个渲染器，虽然它有着可以更接近原生 Web 和相对更小 size 等特点，**但是其发展方向一直以来都不贴合 Flutter 的核心路线** ：

> 由于 Flutter 一直以来都是以 Canvas 为基准通过 Engine 来实现跨平台，并且保证不同平台上的控件得到一致的渲染效果，而 Html renderer 的渲染方式明显违背了初衷，在兼容适配的过程中产生了许多额多的开发成本和兼容问题。

其次，将 HTML、CSS、Canvas 2D、SVG 和 WebGL 组合到单个渲染器的效果并不好，对于 Flutter 本身的 API ，它丧失了很多原本应该具备的能力如 saveLayer、Path.combine、strokeMiterLimit 等。

另外，由于 HTML renderer 无法支持 Flutter 的 API，这就会让 Framework 、 Plugin 和 App 需要在开发时兼容和维护一些特殊的代码如 `kIsWeb` 检查。

>所以在此之后，Flutter 发布了   `CanvasKit`  渲染来贴合原有路线，但是不管是大小还是加载速度等问题，都成了  `CanvasKit`   早期最大的痛点，而接下来一段时间，Flutter Web 长期摇摆在 HTML renderer 和     `CanvasKit`   之间。

而在经过几年的时间调整维护之后，通过成功推进 Wasm GC 的实现，Flutter Web 团队最终也确定了自己的定位：

> **“Flutter Web 的定位不是设计为通用 Web 的框架，Flutter  Web 是一个围绕 CanvasKit 和 WebAssembly 等新兴 Web 技术进行架构设计的框架。”**

在此之后， Wasm Native  路线得到了快速的推进：

-  [Dart 3.4 正式发布了 Wasm Native](https://juejin.cn/post/7368820207576383498) 
-  [Dart 3.5 package:web 中的 browser API 绑定（替换旧dart:html库）正式发布 ](https://juejin.cn/post/7399984522094116891)

而随着 Wasm Native 的完善，事实上  CanvasKit 和 WASM 基本趋向吻合，不同之处就是  Wasm Native  模式下项目会更小且更贴合 WebAssembly 的路线发展。

![](http://img.cdn.guoshuyu.cn/20240821_web1/image1.png)

同时，最近 WebKit 也合并了 Wasm GC 默认开启的支持，也就是未来 Webkit 默认能够支持 Wasm GC 和  Wasm Native  的场景会越来越多，所以这也为 Flutter Web 未来进一步落地提供了基础。

![](http://img.cdn.guoshuyu.cn/20240821_web1/image2.png)

现在，随着 SkWasm 相关问题的推进和解决，**Flutter Web 团队表示有望在 2024 年底之前解决关于 SkWasm 的剩余问题**，所以现在开始计划从代码库中删除 HTML 渲染器，也就是未来 `--web-renderer=html` 和 `--web-renderer=auto`  将不在生效。

> 默认情况下，在弃用 HTML 的版本里会直接选择 CanvasKit ，如果应用以及它使用的所有插件都支持 WebAssembly ，那也可以尝试开启 --wasm 选项。

在大多数情况下，从 HTML renderer 直接转换到 CanvasKit 的都是可以正常工作，但是也有一些局限性问题：

- 从 Flutter 3.24 开始，`Image.network` 不支持 CORS 图像，常见的解决方法是使用 `HtmlElementView` 将图像加载到 `<img>` 元素中，后期计划在完全删除 HTML renderer 之前修复该问题
- **CanvasKit  会附带一个额外的 1.5MB wasm 文件，SkWasm 附带一个 1.1MB 的额外 wasm 文件**，后续将继续推进 size 的减小。
- 在 CanvasKit 中，某些情况下 Flutter 需要创建额外的 `<canvas>` 元素来在 Flutter  和 `HtmlElementView`  内容之间合成 HTML 内容，如果同时使用过多的 PlatformView，则额外的画布可能会变得昂贵并降低性能，推荐减少画布数量的常见策略包括：
  - 减少应用对 HTML 内容的依赖。
  - 将多个 `HtmlElementView` 合二为一。
  - 减少 HTML 和 Flutter  Widget 之间的重叠，在没有重叠时，Flutter 可以通过对图片和 PlatformView 进行分组来优化，以最大程度地减少额外画布的数量。
  - 如果存在很多 HTML 场景，或者可以考虑将 [Flutter 嵌入](https://docs.flutter.dev/platform-integration/web/embedding-flutter-web#embedded-mode)到 HTML 中，而不是将 HTML 嵌入到 Flutter 中，目前 Flutter 3.24 支持 [Multi-view](https://juejin.cn/post/7399952146236571685?searchId=202408210918207064CCA650BC87378A23#heading-15)

所以从去年我就非常笃定，Flutter 肯定会最终选择弃用 HTML ，就类似今年的 [Flutter 正在迁移到 Swift Package Manager](https://juejin.cn/post/7399592120128978970) ，随着 [CocoaPods 官宣进入维护模式，不在积极开发新功能 ](https://juejin.cn/post/7402832701668507675)，未来 Flutter 也会逐步弃用  CocoaPods。

最后，**Flutter Web 一直以来都不是一个让你为了用 Web 而去使用它的框架**，Flutter 团队曾经就表示过，**Flutter Web 的定位不是设计为通用 Web 的框架**，类似的 Web 框架现在有很多，比如 Angular 和 React 等在这个领域表现就很出色，而 Flutter Web 的作用，从我的角度更多是：

> **提供 Flutter 渲染到 Web 的能力，并探索渲染器（Flutter GPU）的更多可能**，可以无缝将 App 端的渲染效果，无差别的渲染到 Web 里，某些某块可以直接「变现」成 Web 成品，这就是我心里的 Flutter Web 。

当然，在 WebAssembly 路线上，Flutter 还需要解决很多问题，例如：

- 是否可以通过使用语义树作为 SEO 数据的来源来解决 SEO 问题
- 是否可以让 wasm 文件更小
- 是否可以让 canvaskit 模式下也支持翻译插件
- 更好的图像解码支持
- ···

总的来说，Flutter Web 自从确定路线之后，它的整体推进速度确实快了许多，也许 2025 年 Flutter GPU 和游戏也能会 Web 上结出全新的果实。 

> 参考链接：https://groups.google.com/g/flutter-announce/c/JqkMe7cPkQo
