# Flutter 3.10 之 Flutter Web 路线已定，可用性进一步提升，快来尝鲜 WasmGC

随着 [Flutter 3.10 发布](https://juejin.cn/post/7231565908631633979)，Flutter Web 也引来了它最具有「里程碑」意义的更新，**这里的「里程碑」不是说这次 Flutter Web 有多么重大的更新，而是 Flutter 官方对于 Web 终于有了明确的定位和方向**。

# 提升

首先我们简单聊提升，这不是本篇的重点，只是顺带。

本次提升主要在于两个大点：**Element 嵌入支持和 fragment shaders 支持 **。

首先是 Element 嵌入，**Flutter 3.10 开始，现在可以将 Flutter Web嵌入到网页的任何 HTML 元素中，并带有 `flutter.js` 引擎和 `hostElement`   初始化参数**。 

简单来说就是不需要  `iframe` 了，如下代码所示，只需要通过 `initializeEngine ` 的 `hostElement` 参数就可以指定嵌入的元素，**灵活度支持得到了提高**。

```html
<html>
  <head>
    <!-- ... -->
    <script src="flutter.js" defer></script>
  </head>
  <body>

    <!-- Ensure your flutter target is present on the page... -->
    <div id="flutter_host">Loading...</div>

    <script>
      window.addEventListener("load", function (ev) {
        _flutter.loader.loadEntrypoint({
          onEntrypointLoaded: async function(engineInitializer) {
            let appRunner = await engineInitializer.initializeEngine({
              // Pass a reference to "div#flutter_host" into the Flutter engine.
              hostElement: document.querySelector("#flutter_host")
            });
            await appRunner.runApp();
          }
        });
      });
    </script>
  </body>
</html>
```

> PS ：如果你的项目是在 Flutter 2.10 或更早版本中创建的，要先从目录中删除 `/web`  文件 ，然后通过  `flutter create . --platforms=web` 重新创建模版。

fragment shaders 部分一般情况下大家可能并不会用到，shaders 就是以  `.frag`  扩展名出现的 GLSL 文件，在 Flutter 里是在 `pubspec.yaml`  文件下的 `shaders` 中声明，现在它支持 Web 了：

```yaml
flutter:
  shaders:
    - shaders/myshader.frag
```

> 一般运行时会把 frag 文件加载到 `FragmentProgram  ` 对象中，通过 program 可以获取到对应的 `shader `，然后通过 `Paint.shader` 进行使用绘制， 当然 Flutter 里 shaders 文件是存在限制的，比如不支持 UBO 和 SSBO 等。

**当然，这里不是讲解 shaders ，而是宣告一下，Flutter Web 支持 shaders 了**。

# 未来

**其实未来才是本篇的重点**，我们知道 Flutter 在 Web 领域的支持上一直在「妥协」，Flutter Web 在整个 Flutter 体系下一直处于比较特殊的位置，因为它一直存在两种渲染方式：[html 和 canvaskit](https://juejin.cn/post/7095294020900880420)。

简单说 html 就是转化为 [JS + Html Element](https://juejin.cn/post/7095294020900880420) 渲染，而 canvaskit 是采用 [Skia + WebAssembly](https://skia.org/docs/user/modules/canvaskit/)  的方式，**而 html 的模式让 Web 在 Flutter  中显得「格格不入」，路径依赖和维护成本也一直是 Flutter Web 的头痛问题**。

![](http://img.cdn.guoshuyu.cn/20230512_IOW/image1.png)

面对这个困境，官方在年初的 [Flutter Forword](https://juejin.cn/post/7192646390948823098)  大会上提出重新规划 Flutter Web 的未来，而随着 Flutter 3.10 的发布，官方终于对于 Web 的未来有了明确的定位：

> **“Flutter 是第一个围绕 CanvasKit 和 WebAssembly 等新兴 Web 技术进行架构设计的框架。”**

Flutter 团队表示，**Flutter Web 的定位不是设计为通用 Web 的框架**，类似的 Web 框架现在有很多，比如 Angular 和 React 等在这个领域表现就很出色，而 Flutter 应该是围绕 CanvasKit 和 [WebAssembly](https://webassembly.org/) 等新技术进行架构设计的框架。

所以 Flutter Web 未来的路线更多会是 CanvasKit ，也就是 WebAssembly + Skia ，同时在这个领域 Dart 也在持续深耕：**从 Dart 3 开始，对于 Web 的支持将逐步演进为  WebAssembly 的 Dart native 的定位**。

![](http://img.cdn.guoshuyu.cn/20230512_IOW/image2.png)

什么是  WebAssembly 的 dart native ？一直以来 Flutter 对于 WebAssembly 的支持都是：使用 Wasm 来处理CanvasKit 的 runtime，而 Dart 代码会被编译为 JS，而这对于 Dart 团队来时，其实是一个「妥协」的过渡期。

而随着官方与 WebAssembly 生态系统中的多个团队的深入合作，**Dart 已经开始支持直接编译为原生的 wasm 代码，一个叫 [WasmGC]((https://github.com/WebAssembly/gc/blob/main/proposals/gc/Overview.md))  的垃圾收集实现被引入标准**，该扩展实现目前在基于 Chromium 的浏览器和 Firefox 浏览器中在趋向稳定。  

> 目前在基准测试中，执行速度提高了 3 倍

要将 Dart 和 Flutter 编译成 Wasm，你需要一个支持 [WasmGC ](https://github.com/WebAssembly/gc/tree/main/proposals/gc) 的浏览器，目前 [Chromium V8](https://chromestatus.com/feature/6062715726462976) 和 Firefox 团队的浏览器都在进行支持，比如 Chromium 下：

> 通过结构和数组类型为 WebAssembly 增加了对高级语言的有效支持，以 Wasm 为 target 的语言编译器能够与主机 VM 中的垃圾收集器集成。在 Chrome 中启用该功能意味着启用类型化函数引用，它会将函数引用存储在上述结构和数组中。

![](http://img.cdn.guoshuyu.cn/20230512_IOW/image3.png)

现在在 Flutter master 分支下就可以提前尝试 wasm 的支持，运行 `flutter build web --help` 如果出现下图所示场， 说明支持 wasm 编译。

![](http://img.cdn.guoshuyu.cn/20230512_IOW/image4.png)

之后执行 `flutter build web --wasm` 就可以编译一个带有 native dart wasm 的 web 包，命令执行后，会将产物输出到 `build/web_wasm` 目录下。

之后你可以使用 pub 上的  [`dhttpd`](https://pub.dev/packages/dhttpd)  包在 `build/web_wasm`目录下执行本地服务，然后在浏览器预览效果。

```
> cd build/web_wasm
> dhttpd
Server started on port 8080
```

目前需要版本 112 或更高版本的 Chromium 才能支持，同时需要启动对应的 Chrome 标识位：

- `enable-experimental-webassembly-stack-switching`
- `enable-webassembly-garbage-collection`

![](http://img.cdn.guoshuyu.cn/20230512_IOW/image5.png) 

当然，目前阶段还存在一些限制，例如：

> Dart Wasm 编译器利用了 [ JavaScript-Promise Integration (JSPI)  ](https://github.com/WebAssembly/js-promise-integration/blob/main/proposals/js-promise-integration/Overview.md)特性，Firefox 不支持 JSPI 提议，所以一旦 Dart 从 JSPI 迁移出来，Firefox 应启用适当的标志位才能运行。

另外还需要  JS-interop 支持，因为为了支持 Wasm，Dart 改变了它针对浏览器和 JavaScript  的 API 支持方式， 这种转变是为了防止把 `dart:html  `  或   `package:js`  编译为 Wasm 的 Dart 代码，大多数特定于平台的包如  url_launcher 会使用这些库。

![](http://img.cdn.guoshuyu.cn/20230512_IOW/image6.png)

最后，**目前  DevTools 还不支持 `flutter run`  去运行和调试 Wasm**。

# 最后

很高兴能看到 Flutter 团队最终去定了 Web 的未来路线，这让 Web 的未来更加明朗，当然，正如前面所说的，**Flutter 是第一个围绕 CanvasKit 和 WebAssembly 等新兴 Web 技术进行架构设计的框架**。

**所以 Flutter Web不是为了设计为通用 Web 的框架去 Angular 和 React 等竞争，它是让你在使用 Flutter 的时候，可以将能力很好地释放到 Web 领域**，而 CanvasKit 带来的一致性更符合 Flutter Web 的定位，当然，解决加载时长问题会是任重道远的需求。

**最后不得不提 WebGPU**， WebGPU 作为新一代的 WebGL，可以提供在浏览器绘制 3D 的全新实现，它属于 GPU硬件（显卡）向 Web（浏览器）开放的低级 API，包括图形和计算两方面相关接口。

WebGPU 来自 W3C 制定的标准，与 WebGL 不同，WebGPU 不是基于 OpenGL ，它是一个新的全新标准，发起者是苹果，目前由 W3C GPU 与来自苹果、Mozilla、微软和谷歌一起制定开发，不同于 WebGL (OpenGL ES Web 版本)，WebGPU 是基于 Vulkan、Metal 和 Direct3D 12 等，能提供更好的性能和多线程支持。

> WebGPU 已经被正式集成到 Chrome 113 中，首个版本可在会支持 Vulkan 的 ChromeOS 设备、 Direct3D 12 的 Windows 设备和 macOS 的 Chrome 113 浏览器，除此之外 Linux、Android 也将在 2023 年内开始陆续发布，同步目前也初步登陆了 Firefox 和 Safari 。

提及 WebGPU 的原因在于：**WebGPU + WebAssembly 是否在未来可以让 Web 也支持 Impeller 的可能？**。

> 详细可见：https://cohost.org/mcc/post/1406157-i-want-to-talk-about-webgpu 和 https://www.infoq.cn/article/qwawharqawdragtcoxqv