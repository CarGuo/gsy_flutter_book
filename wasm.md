# Flutter Web 的未来，Wasm Native 即将到来

早在去年 Google I/O 发布 Flutter 3.10 的时候就提到过， Flutter Web 的未来会是  Wasm Native  ，当时 Flutter 团队就表示，[**Flutter Web 的定位不是设计为通用 Web 的框架**](https://juejin.cn/post/7232164444985622588?searchId=20240401103550C5FEC0A9E42337865CD2)，类似的 Web 框架现在有很多，而 Flutter 的定位会是

> **“第一个围绕 CanvasKit 和 WebAssembly 等新兴 Web 技术进行架构设计的框架。”**

如今一年之期将至，最近，Flutter Wasm Native 也迈出了它关键的一个 commit ：[b8cd317](https://github.com/flutter/flutter/commit/388f3217e4a89e383c4601576c44fdab1b8cd317) ，在 master 上  `flutter build web --wasm` 的支持不再是 Experimental 状态。

![](http://img.cdn.guoshuyu.cn/20240401_web/image1.png)

可以看到，目前 Flutter 和 Dart 已经支持在构建 Web 时添加 WebAssembly 作为编译目标 ，而目前如果要支持  Wasm 的 Flutter 应用，还需要一个支持 [WasmGC ](https://github.com/WebAssembly/gc/tree/main/proposals/gc)的浏览器：

> [Chromium 和 V8](https://chromestatus.com/feature/6062715726462976) 在 Chromium 119 中发布了对 WasmGC 的 stable 支持， Firefox 在 Firefox 120 中支持 WasmGC （还有点问题），另外  Safari 尚不支持 WasmGC 。

![](http://img.cdn.guoshuyu.cn/20240401_web/image2.png)

有的人可能疑惑， Flutter Web 不是一直都支持编译为 `CanvasKit`  的 WebAssembly 渲染方式吗？为什么现在又提到 WebAssembly 作为编译目标 ？

**这里就不得不说 Dart native** ， 在此之前， Flutter 对于 WebAssembly 的支持都是：使用 Wasm 来处理CanvasKit 的 runtime，而 Dart 代码会被编译为 JS，而现在，随着  [WasmGC](https://link.juejin.cn/?target=) 的垃圾收集实现的引入，**Dart 已经开始支持直接编译为原生的 Wasm 代码**。

如果你还无法理解，可以直观对比下面两张图，图1是以前  `CanvasKit`  的 WebAssembly 渲染方式，图 2 是全新的  Dart native 下的 Wasm 渲染方式，可以看到，**其中最大的变化就是 Size 变少了不少**，这对于老版   `CanvasKit`  来说一直是硬伤。

![](http://img.cdn.guoshuyu.cn/20240401_web/image3.png)

![](http://img.cdn.guoshuyu.cn/20240401_web/image4.png)

> 更小更快更强！

对于 Flutter Web，全新的 Dart Native 这里类似于完成了一个全新的 “Skwasm” 渲染引擎，为了最大限度地提高性能，Skwasm 通过 wasm-to-wasm 绑定将编译后的代码，直接连接到自定义 [CanvasKit Wasm 模块](https://link.juejin.cn/?target=https%3A%2F%2Fskia.org%2Fdocs%2Fuser%2Fmodules%2Fcanvaskit%2F) ，这也是 Flutter Web 多线程渲染支持的第一次迭代，进一步提高了帧时间。

另外随着 Dart 3.3 的发布，目前 Flutter Web 也完成了它之前承诺的一些功能：

- **双编译**：生成 Wasm 和 JavaScript 输出，并在运行时启用功能检测，以适配支持和不支持 Wasm-GC 的浏览器，**也就是 CanvasKit 本身支持过渡阶段的兼容运行** 。
- **JavaScript interop**：基于[扩展类型](https://juejin.cn/post/7335463274619273266)的新 JS 互操作机制，当针对 JavaScript 和 Wasm 时，可以在 Dart 代码、浏览器 API 和 JS 库之间进行简洁、类型安全的调用，**Dart 开发人员可以访问类型化 API 来与 JavaScript 交互**，API 通过静态强制明确定义了两种语言之间的边界，在编译之前消除了许多问题。
- **支持 Wasm 的浏览器 API**：一个新的 `package:web`，用于取代了 dart:html （和相关库），未来 browser libraries 支持将集中在 [package:web ](https://link.juejin.cn/?target=https%3A%2F%2Fpub.dev%2Fpackages%2Fweb)上。

![](http://img.cdn.guoshuyu.cn/20240401_web/image5.png)

为了支持 Wasm 编译，Dart 通过 [js-interop](https://dart.dev/interop/js-interop) 改变了与浏览器和 JavaScript API 互操作的方式，这种转变需要 Dart 支持 Wasm 的浏览器 API 来适配：

- [`package:web`](https://pub.dev/packages/web)，取代 `dart:html`（和其他网络库）
- [`dart:js_interop`](https://api.dart.dev/stable/dart-js_interop)， 取代 `package:js`和 `dart:js`

> 具体可以查看 https://dart.dev/interop/js-interop/package-web 和 https://dart.dev/interop/js-interop 进行迁移

总结一下，**虽然 Wasm Native 的支持目前还没普及，但是也决定了 Flutter Web 从「举棋不定」到「落子无悔」的变化，虽然不知道未来  Wasm Native  会怎么样？但是对于 Flutter Web 来说，看到是比现在更好**。

> 更多可参考 https://docs.flutter.dev/platform-integration/web/wasm

