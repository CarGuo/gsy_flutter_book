# Flutter Web 的发展历程：Dart、Flutter 与 WasmGC

Flutter Web 应该是 Flutter 开发者里最不“受宠”的平台了，但是其实 Flutter 和 Dart 团队对于 Web 的投入一直没有减少，这也和 Flutter 还有 Dart 的"出生"有关系，今天就借着 Dart 团队的 Ömer Ağacan 和 Martin Kustermann 在油管的访谈视频来聊一聊 Flutter Web 这一路过来的变化。

其实在以前我们聊过很多次，Flutter 早期的项目代号是 “Sky” ，诞生于 Google 内部的 Chrome 团队，**早期定位其实是一个「前端项目」**，本身是为了探索更优秀的 Web 渲染技术而存在，所以起初 Flutter 的创始人和整个团队几乎都是来自 Web ：

![](https://img.cdn.guoshuyu.cn/image-20250715101459913.png)

而 **Dart 最初的宏大愿景是在 Chrome 的 V8 引擎中内置一个专门的 Dart 虚拟机（VM）** ，目的是为 Web 提供一个比 JavaScript 更结构化、性能更强的替代方案。

当然，**众所周知这个计划最终凉了**，而后 Dart 团队将战略重心转向了  `dart2js` 编译器，也就是将 Dart 代码转译为 JavaScript，这也是一开始的 Flutter Web 打下来基础。

> 所以 Flutter 选择 Dart 其中一个原因不难理解，大家都是同一个团队内的，并且 Dart 没什么其他选择，**它也可以一心一意成为 Flutter 的形状**。

当然，另外一个原因则是 Flutter 当时希望有一种语言同时支持 JIT 和 AOT，并且支持 Hotload ，而 Dart 恰好具备这两种编译模式的基础能力。

所以，对于 Dart 来说，它的演进路径其实可以说是“一路坎坷”，从 “Dart VM in V8” 的失败，再到 `dart2js` 的“苟活”，再到后面 Flutter Web 的落地，以及之后的 WasmGC 提案，再到现在的 `dart2wasm` ，其实 Dart 一直心系 Web 平台，因为这是它曾经目标的延续。

而对于 Flutter 来说，  `dart2js`  将 Flutter 转译为 JavaScript 的实现，让 Flutter 在 Web 平台变得“不那么一致”，特别是在处理复杂动画和大量 UI 元素时会遇到性能瓶颈，此时的 Web  平台的特殊性也成了 Flutter 的技术债务。

所以 WebAssembly (Wasm)  平台最终成了 Flutter Web 的新目标，它能够让 Flutter 在 Web 平台和其他平台上渲染效果对齐，并且还能提供不错的性能，只是 Wasm 的初始版本（CanvasKit）缺少垃圾回收（GC）机制，不适合像 Dart 这样的托管语言：

> Wasm MVP 只提供了一个单一的、连续的内存块，Wasm 模块必须手动管理这块内存，包括对象的分配和释放；并且没有 GC 支持，也就是其他语言必须将它们自己的整个垃圾回收器实现打包进 Wasm 模块，这不仅降低了效率，还极大地增加了代码体积。

最经典的问题是，这会导致在一个进程中同时运行两个 GC 的尴尬局面：**一个是打包在 Wasm 模块内的 GC，另一个是浏览器用于管理 JavaScript 对象的 GC** 。

> 所以早期 CanvasKit 在 Flutter Web 里并没有什么优势，大家还是更愿意基于   `dart2js`  ，这也导致了 Flutter Web 一直处于两种模式的尴尬局面。

因此 ，**Dart 和 Flutter 团队开始加入 WasmGC 的推动与落地工作**，其实这是一项吃力不讨好的过程，Google 从一开始就深度参与了标准的制定，好处就是确保了这个标准能尽可能满足 Dart 的需求。

> **当然，最终受惠的还有 Kotlin/Wasm**  ，JetBrains 也率先基于 WasmGC 开发了全新的 Kotlin/Wasm 编译器验证了相对应的可行性，也是早期的积极实践者之一。

**WasmGC 从根本上将 WebAssembly 从一个“Web 上的更好的 C++ 平台”转变为一个“通用的高级语言虚拟机”**，而 WasmGC 提案也为 WebAssembly 引入了一系列新的功能：

- WasmGC 引入了新的堆类型，用于创建结构化数据（`struct`）和数组（`array`），让虚拟机能够了解它们的内存布局，从而高效地访问字段，减少复杂的地址计算
- WasmGC 为托管对象定义了一个类型系统，包含了子类型化（`sub`）的概念，也就是 Wasm 代码能够表示源语言中的类继承关系，编译器可以将语言的类型层次结构直接映射到 Wasm 的类型系统上
- WasmGC 引入了一套新指令，例如用于创建实例的 `struct.new` 和 `array.new`，用于字段访问的 `struct.get` 和 `struct.set`，以及用于类型转换和检查的指令，如 `ref.cast`（类型转换）和 `br_on_cast`（带类型检查的分支）

**编译器不再是将语言的对象模型编译到线性内存中，而是将语言的对象模型映射到 WasmGC 的对象模型上** ，而 WasmGC  相较于传统的将 GC 捆绑到 Wasm 模块中的方法，主要好处在于：

- 代码体积的急剧减小，由于不再需要捆绑内存管理代码（无论是 `malloc` 还是一个完整的 GC），最终的 Wasm 二进制文件可以小得多 
- WasmGC 实现了 Wasm 和 JavaScript 之间真正细粒度的对象互操作，一个 WasmGC 对象可以持有对一个 JavaScript 对象的引用，反之也是，这让宿主的 GC 能够正确地追踪和回收跨越这两个环境的循环引用
- 由于虚拟机了解 Wasm 堆上的对象结构，浏览器开发者工具（如堆分析器）能够检查 Wasm 内存，并显示有意义的对象类型和字段信息

所以，基于 WasmGC 推进的顺路，Flutter 官方在 Flutter 3.10 终于对于 Web 的未来有了明确的定位：

> **“Flutter Web 是第一个围绕 CanvasKit 和 WebAssembly 等新兴 Web 技术进行架构设计的框架。”**

Flutter 团队表示，**Flutter Web 的定位不是设计为通用 Web 的框架**，类似的 Web 框架现在有很多，比如 Angular 和 React 等在这个领域表现就很出色，而 Flutter 应该是围绕 CanvasKit 和 WebAssembly 等新技术进行架构设计的框架。

而对于 Dart，**也从 Dart 3 开始，对于 Web 的支持将逐步演进为 WebAssembly 的 Dart native 的定位**：

> 什么是 WebAssembly 的 Dart native 现在应该很好理解了吧？一直以来 Flutter 对于 WebAssembly 的支持都是：使用 Wasm 来处理CanvasKit 的 runtime，而 Dart 代码会被编译为 JS，而这对于 Dart 团队来时，其实是一个「妥协」的过渡期，**而基于 WasmGC， Dart 已经开始支持直接编译为原生的 Wasm 代码**。



![](https://img.cdn.guoshuyu.cn/image-20250715112911201.png)

从 `dart2js` 切换到 `dart2wasm` 带来了显著的性能飞跃，例如 WasmGC 编译的应用在帧渲染速度上平均提升了 2 倍，而在衡量卡顿情况的第 99 百分位帧上，性能提升高达 3 倍 ，另外  wasm 构建的 Flutter Web 应用还支持了使用多个线程场景，**而 HTML renderer 也在 3.29 版本正式移除**。

> `skwasm` 支持通过一个专用的 Web Worker 在独立线程上进行渲染，可以将部分渲染工作负载分流，利用多核 CPU 来减少卡顿并提高响应性，前提是服务器必须配置特定的 COOP 和 COEP HTTP 标头，从而满足 `SharedArrayBuffer` 的安全要求 。

当然，WasmGC 目前还是存在浏览器兼容性问题，比如：

- **Chromium (Chrome, Edge)**: 从 119 版本稳定支持 WasmGC 
- **Firefox**: 尽管从 120 版本开始支持 WasmGC，但存在一些特定错误，某些情况可以会导致 Flutter 的 `skwasm` 渲染器无法正常工作 
- **Safari/WebKit**: 同样已经支持 WasmGC，但也存在阻碍 Flutter 渲染的错误，特别是 iOS 上的 WebKit 兼容问题

目前 WebKit 已经默认支持了 WasmGC ，但是历史版本依然存在需要兼容的场景：

![](https://img.cdn.guoshuyu.cn/image-20250715112948536.png)

而回归到 Flutter Web 上，就是 `canvaskit`  和 `skwasm`  有什么区别？简单说：

-  `canvaskit`  使用 `dart2js`，兼容性更广
- `skwasm`  使用  `dart2wasm` ，性能更好体积更小，但是依赖 WasmGC 环境

所以，也许 Flutter Web 在开发者领域并不是很受宠，但是 Flutter 和 Dart 对它的投入并不少，因为 Wasm 的潜力已经远远超出了浏览器的范畴 ，例如 WASI（WebAssembly System Interface）就是未来的重要趋势之一，作为新兴的标准，它的目的是为 Wasm 模块提供一种安全、可移植的方式来与系统资源（如文件系统）进行交互 。

> WASI 的目标是定义一套标准的 API，让 Wasm 代码可以“一次编译，在任何（支持 WASI 的）运行时上运行”，无论是服务器、边缘设备还是桌面应用。

例如：

- WASI 可以让 WebAssembly 成为 Node.js 和 Python 等传统服务器运行时的高性能替代品
- 借助 WASI，Wasm 模块将能够和传感器、本地文件系统交互来处理边缘设备上的数据，从而实现边缘的实时决策
- WASI 的系统级功能能让 WebAssembly 在传统容器领域成为轻量级替代品

而 `dart2wasm` 编译器目前是主要针对浏览器中的 JS 环境，但未来它也许可以被扩展以支持非 JS 的、符合 WASI 标准的运行时，例如 Wasmtime 或 Wasmer ，从而支持更多场景，这也是为什么 Flutter 和 Dart 对于 Wasm 持续投资的原因之一。

> 这也是访谈里 Ağacan 和 Kustermann 未来愿景：在一个通用的、高性能的、可移植的运行时的驱动下，原生应用和 Web 应用之间的界限会更加模糊，尽管挑战依然存在，但其发展轨迹已经为一类全新的 Web 体验设定了方向。

而回归的目前的 Flutter Web 和当前推进的情况，未来大概会有：

- Flutter Web Hotload 的稳定版发布
- 基于 Flutter Web 的 IDE 内 Widget Preview 稳定版
- 基于语义树实现 SEO 优化，例如 [#145954](https://github.com/flutter/flutter/issues/145954#issuecomment-2616539670) 就提到过，通过将无障碍的 `Semantics Tree` 翻译成 HTML 结构的管线，让 Web 可以满足搜索引擎爬虫读取的需求

虽然 Flutter Web 现在还不够好用，不够通用，但是它也确确实实撑起了 Flutter 在 Web 平台的能力，对比起刚刚才合并到 master 的桌面端多窗口的情况，其实 Web 的投入在每个版本都有目共睹，未来 Flutter Web 应该也不会往通用领域发展，但是在 WebAssembly 领域，Flutter 和 Dart 应该还是可以有一席之地。





# 参考链接

- https://www.youtube.com/watch?v=vgOABOvtBT8 



