# 为什么跨平台框架可以适配鸿蒙，它们的技术原理是什么？

最近刚聊过腾讯开源的 [ovCompose  和 Kuikly 正式支持了鸿蒙平台](https://juejin.cn/post/7511525207480926227)之后，便收到了不少关于这些跨平台框架如何适配鸿蒙的问题，而目前支持鸿蒙的跨平台开源框架主要有 Flutter、React Native、uni -app x 和 KMP/CMP 等，所以本期也主要聊聊它们是如何适配的。

![](https://img.cdn.guoshuyu.cn/image-20250606103322554.png)

当然，这里不同之处在于 **Flutter、React Native、uni -app x 是华为主动发起的适配项目**，比如之前华为的大佬就分享过 Flutter 的 Impeller 是如何适配鸿蒙的；而 KMP/CMP 对于鸿蒙的适配案例，目前如 B站、腾讯、美团等大厂均有对应产品，只是暂时只有腾讯开源相关实现：

![](https://img.cdn.guoshuyu.cn/image-20250605085653936.png)

> 当然，**类 RN 的开源还有 lynx 和 taro 等，也都适配了鸿蒙**。

在此之前，虽然说鸿蒙 Next 没有了 AOSP，甚至说在微内核在技术层面也提到过是非 Linux 内核实现，但是之前的[文章我们从技术层面聊过](https://juejin.cn/post/7505977477115674687)：**鸿蒙的内核虽然不是标准 Linux 实现，但是它提供 Linux 兼容**，这也是「卓易通」可以通过类似 lxc 的方式实现一个 AOSP 环境的基础，具体原理在于：

>  musl libc + 内核抽象层 (KAL) 提供标准 POSIX 兼容，有 Shim Layer 和 lsyscall 提供执行支持。

当然，这些不是我们要聊的内容，它们只是一个基础前提，比如**鸿蒙 Next 有 musl libc，有标准 POSIX  API，有 Clang/LLVM，有 GN/ninja ，这些都是原有成熟的技术体系，也是这些跨平台能够适配鸿蒙 Next 的基础支撑**。

# Flutter

**Flutter 在鸿蒙社区支持上算是最早被开源的**，这里面有一定原因是 Flutter 本身的嵌入层设计很适合迁移，比如 LG 的 WebOS 和丰田车机就有使用 Flutter 的案例；而另外的原因就是，**Flutter 的构建和架构与鸿蒙的贴合度很高**，甚至 ArkUI 在一开始代码里都存在很有 Flutter 的影子：

![](https://img.cdn.guoshuyu.cn/image-20250606105225462.png)

另外，如果你编译过 Flutter Engine，**就会知道 Flutter Engine 的构建是依赖于 GN  和 Ninja 的，而在官方资料里，[鸿蒙编译子系统恰好也是基于 GN  和 Ninja 为基座](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-gn-adapts-to-harmonyos)，所以整体在构建支持上贴合度也很高**：

![](https://img.cdn.guoshuyu.cn/image-20250605154322453.png)

> Ninja 是借由 Google Chrome 项目而诞生的一个构建工具，它的诞生目标是为了编译速度，Ninja 可以看作是一个更好的 Make ，而 GN 是由 Google 开发，负责定义和生成构建规则输出 .ninja 文件，最终 Ninja 会根据这些 .ninja 文件，执行具体的编译和链接任务，**而 Flutter 又诞生于 Chrome 团队，所有使用 GN  和 Ninja 也很合情合理**。

所以，Flutter Engine 能在鸿蒙 Next 上运行起来的核心，在于拓展了一套 ohos 的嵌入层支持，逻辑上会集中在修改嵌入层对接 HarmonyOS 的系统服务 (如窗口管理、输入事件、生命周期管理)，以及调整引擎层以适应其图形、文本渲染和平台通道通信机制等。

> Flutter 引擎会被编译为 `libflutter.so` 并打包在 `flutter.har` 内。

最终相关的引擎代码会通过 Ninja 的构建系统，**通过鸿蒙 Next 定制的 Clang/LLVM 编程成可以在鸿蒙平台运行的二进制**，当然，对于 Engine 层也需要进行大量修改适配，比如针对第三方包的调整：

![](https://img.cdn.guoshuyu.cn/image-20250606092548259.png)

Flutter 的编译依赖 gclient sync 同步第三方包，而这里面会引用大量第三方包，其中就包括 dart sdk 和 skia 这种关键支持，而针对这部分不适合直接修改的内容，Flutter 鸿蒙版会在 `attachment` 目录下利用 git patch 来处理，比如：

![](https://img.cdn.guoshuyu.cn/image-20250606090243511.png)

> gclient 是 Google 开发的一个 Python 工具，主要用于管理多个 git 仓库的依赖关系，最初主要是为 Chromium 项目设计，可以看作是一个更高层次的版本控制工具，专门用于协调和同步多个 git 仓库，而 gclient 的 DEPS 文件可以指定仓库的特定提交（commit）、分支或标签，并且支持递归依赖管理。

所以鸿蒙版的 Flutter 会在 gclient sync 是利用 hook 来修改和 apply  patch ，比如 dart  sdk 的源码调整，skia 的增加  `FontConfig_ohos` 和 `SkFontMgr_ohos`  平台的字体相关支持：

![](https://img.cdn.guoshuyu.cn/image-20250606094119258.png)

另外还有比如针对 LiteOS 的 C 标准库（libc）使用了 musl C 库的本地化（locale）支持，因为 Next 使用的是 musl libc ：

![](https://img.cdn.guoshuyu.cn/image-20250606094341760.png)

所以可以看到，**整个 Engine 适配的核心就在于 LLVM 和 Clang，他们作为编译端让代码可以直接运行到鸿蒙 Next**  ，而事实上 Ark 编译器本身也是基于 LLVM 和 Clang 构建的，特别还定制了后端代码生成和优化方面的实现。

> 当然，由于鸿蒙对 LLVM 也进行可自己的定制化，所以它也不是一个完全标准的 LLVM 。

另外，一些资料也提到过，在鸿蒙上 `libc++.so` 和  `libc++_shared.so` 也存在不同命令空间， `libc++.so` 是系统使用的 C++ 标准库，符号命名空间为 `__h`，`libc++_shared.so` 是共享版本，符号命名空间为 `__n1` ，这也是运行时需要考虑的不同之处。

而对于 dart 代码，**由于 Dart 代码的编译前端和编译后端都是自己实现，所以并不直接经过 LLVM  处理**，例如：

- Dart 源代码首先通过 Dart 前端编译器（CFE）编译成平台无关的 `kernel IR`（通常是`.dill`文件）的二进制文件，也叫做 Kernel AST
- 后续在 AOT 的时候，会通过适配了鸿蒙平台的 `gen_snapshot ` 工具读取这些`kernel IR`文件，然后将这些 `kernel IR`  AOT 编译成适用于鸿蒙目标架构（如ARM64）的机器码快照

这里的  gen_snapshot 工具，就是在编译 engine 时，通过 gclient sync 同步下来在 third_part的 dart 源码，正如前面所说，鸿蒙版会对这部分代码进行调整，比如增加 `HOST_ARCH_ARM64`  支持，最终会通过对  `third_party\dart\runtime\` 进行编译得到所需的   gen_snapshot  工具。

> **所以虽然作为一个全新的系统环境，但是鸿蒙还是在已有的编译体系进行拓展，从而让跨平台工具能更低成本进行适配**。

而在绘制支持上，现在鸿蒙版 Flutter 已经支持了 skia 和 Impeller 渲染，核心是通过 `XComponent` 支持，并且 Impeller 在安卓平台上的主要后端是 Vulkan ，而在鸿蒙 Next 上，ArkGraphics 也同样支持 Vulkan  后端：

![](https://img.cdn.guoshuyu.cn/image-20250606113745176.png)

> `XComponent` 提供了一个用于渲染的表面（`NativeWindow`）

`XComponet` 可以直接获取到系统底层的 `OHNativeWindow` 实例, 然后通过鸿蒙提供的扩展 `VK_OHOS_surface`，将这个窗口转成一个 `Vulkan` 中的 `VKSurface`, 进而通过 `VKSwapchain` 实现了窗口绘制。

另外，`XComponent` 还会在混合开发被用来承载这些原生视图的渲染内容，并通过纹理（Texture）与 Flutter 的渲染层集成，核心就是利用 ArkUI 的相关 C API ，将过  `ArkUI_NodeHandle`  附加到 `OH_NativeXComponent`，从而将原生 ArkUI 组件树嵌入到 `XComponent` 中，然后 Flutter 可以将其作为 `PlatformView` 进行管理。

> `ArkUI_NodeHandle` 代表了 ArkUI 原生组件对象的指针，可以在 C++ 代码中操作原生 UI 组件，对于类 RN 跨平台框架也是非常重要的支持。

最后，在调用原生代码支持上，引擎的 `@ohos/flutter_ohos` 部分提供了 `MethodChannel` 的支持，而 `Dart -> C++ (Flutter Engine/Embedder) -> NAPI -> ArkTS` 的调用，也注定了平台交互的调用性能会比较一般。

当然，鸿蒙 Flutter 也计划推出一种成本更低的方案，即通过一种统一接口描述，自动生成各端调用代码，省去开发者的编码工作，同时也可以提升互操作的整体性能：

![](https://img.cdn.guoshuyu.cn/image-20250606130030247.png)

所以，通过上述应该可以很好理解 Flutter 是如何运行到全新的鸿蒙 Next 平台，**核心离不开 GN/Ninjia 、Clang/LLVM 、libc++ 、musl lib 等相关的支持**，而你最终通过 `flutter doctor` 同步的鸿蒙平台 Flutter  SDK，指向的是也是托管在鸿蒙平台 `FLUTTER_OHOS_STORAGE_BASE_URL` 的定制化 SDK：

![image-20250605112013517](https://img.cdn.guoshuyu.cn/image-20250605112013517.png)

> 例如 https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com/flutter_infra_release/flutter/90702dc896c0de508dfbd24900f284a27bb9af1f/ohos-arm64-profile/artifacts.zip

所以，可以看出来，Flutter 的适配成本其实相对并不高，当然，这也是相对后面的框架而言。

# react native

相比较 Flutter 而言，其实在鸿蒙适配上的 React Native for OpenHarmony  就好理解很多，因为 JS 并不需要编译成二进制，所以本质上类 RN 的实现就是将 React 控件 OEM 成 ArkUI ，而成本其实在于将 RN 的新架构如 JSI、Hermes Engine 在鸿蒙 Next 上运行起来：

![](https://img.cdn.guoshuyu.cn/image-20250606130923449.png)

例如在新架构里，JSI 作为一套 C++ API，允许 JS 代码直接持有 C++ 对象的引用并同步调用其方法，而在鸿蒙里，则是通过 `RNOHAppNapiBridge.cpp`  处理 JSI 层的交互，并将其转换为 NAPI 调用 。

> **其实鸿蒙社区版 ohos_react_native 也是在官方的 react native 基础上做拓展支持，比如创建工程还是基于原有 的 rn cli ，只是在项目创建成功之后，添加对应的 `react-native bundle-harmony` 依赖和脚本支持**。

同时，为了避免直接修改第三方库的原始代码而影响其在其他平台（如 iOS、Android）上的使用，RNOH 也采用了补丁 (patch) 的方式进行适配 。

而对于适配鸿蒙上，如上图所示，OpenHarmony 适配代码主会接收并处理 React Common 传过来的数据，对接原生的代码，调用 ArkUI 的原生组件与 API。

所以类 RN 的实现核心在于 OEM UI 的映射支持，而这里有个特殊的点在于，**类 RN 的实现不是直接使用 ArkUI 的 ArkTS 控件**，因为使用  ArkTS 控件的性能太差，所以有了 ArkUI C API (`ArkUI_NativeModule`) 相关的支持：

> **ArkUI 的 C API允许原生 C++ 代码与 ArkUI 框架进行深度交互，包括创建和销毁UI组件、操作节点树、设置属性、监听事件以及通过 FrameNode 和 RenderNode 进行自定义绘制等**。

![](https://img.cdn.guoshuyu.cn/image-20250606131024612.png)

所以在类 RN 的实现里，大家都默契的采用了 C API ，例如下图是 Taro 的鸿蒙适配实现，运行时逻辑下沉至 C++，将 TaroElement 的大部分内容都下沉到了 C++ 侧，并在 ArkVM 层取消了他们之间父子关系的绑定，极大地提升了 TaroElement 相关逻辑的性能：

![](https://img.cdn.guoshuyu.cn/image-20250606130749923.png)

并且在现在最新的实现指导了，推荐用 ContentSlot 做占位组件管理 Native API 创建的组件，因为 ContentSlot 在内存和性能方面都优于 NODE 类型的 XComponent：

![](https://img.cdn.guoshuyu.cn/image-20250606131749447.png)

同样，在混合开发里，基于 C API 的原生渲染，混合 ArkTS 控件的实现也不再是什么难点，而在原生互操作上，TurboModule 的鸿蒙上也提供了相应实现，根据是否依赖鸿蒙上系统相关的能力，可以分为两类： cxxTurboModule 和 ArkTSTurboModule ：

- ArkTSTurboModule：

  - ArkTSTurboModule 为 React Native 提供了调用 ArkTS 原生 API 的方法，可以分为同步与异步两种

  - ArkTSTurboModule 依赖 NAPI 进行原生代码与 CPP 侧的通信，包括 JS 与 C 之间的类型转换，同步和异步调用的实现等

- cxxTurboModule：

  - cxxTurboModule 主要提供的是不需要系统参与的能力，例如 `NativeAnimatedTurboModule`  主要提供了数据计算的相关能力

  - cxxTurboModule 不依赖于系统的原生 API，为了提高相互通信的效率，一般是在 cpp 侧实现，这样可以减少 native 与 cpp 之间的通信次数，提高性能

![](https://img.cdn.guoshuyu.cn/image-20250606132548916.png)

所以，可以看出来，**类 RN 的实现核心是完成 ArkUI C API 的对接和 NAPI 的接入，整体来看适配的工作量更多是在体力活上**。

# uni-app x

而这个问题来到 uni-app x 上，理解起来就更简单了，因为  uni-app x 使用的是 uts ，而它是被编译成 ArkTS ，你可以理解在这个层面，其实就是 ATS to BTS 的过程：

![](https://img.cdn.guoshuyu.cn/image-20250606153000386.png)

uni-app x 的核心其实就是在于如何把 Vue 在前端编译成 ArkUI ，因为后端编译就是 ArkUI 本身，具体点说，就是 uni-app x  里的 uvue 实现：

> uvue是一套基于uts的、兼容vue语法的、跨平台的、原生渲染引擎

**通俗来说，uvue 就是“翻译工具”，负责翻译 uts 版的 vue 框架（组件、数据绑定）、 ui 编排 和 css 等**。

不过对应的 uvue 没看找到开源，而实际上 uni-app x  的适配核心也主要在于前端部分，所以在概念里上也属于比较好理解的部份，实际上可以它甚至可以和 ArkTS 直接混编：

```ts
import settings from '@ohos.settings';
const context: Context =  getContext();
settings.getValue(context, settings.display.SCREEN_BRIGHTNESS_STATUS, (err, value) => {
  if (err) {
    console.error(`Failed to get the setting. ${err.message} `);
    return;
  }
  console.log(`SCREEN_BRIGHTNESS_STATUS: ${JSON.stringify(value)}`)
});
```

> 所以 uni-app x 在跨平台支持像是一个翻译官的角色。

# KMP & CMP

而关于 KMP 和 CMP 适配鸿蒙就比较零散了，支持鸿蒙的能力基本是靠自己内部方案，而目前而言，只有腾讯的 Kuikly  和 ovCompose 开源了适配方案：

- B站： Android、iOS、鸿蒙三端采用 KMP 逻辑跨平台，并使用了 CMP
- 腾讯：开源有 ovCompose、Kuikly 等框架
- 快手：快手鸿蒙版应用采用 KMP 逻辑跨平台 + ArkUI 原生 UI 开发
- Kimi：通过 KMP+CMP 跨端开发方案，实现了 PC 、鸿蒙 和 Android  适配

所以这个方案下需要结合 Kuikly  和 ovCompose 作为代表性来讨论，而在 UI 层 Kuikly  和 ovCompose 也采用了不同的适配逻辑，不过在于 KMP 层面，他们都是基于 KuiklyBase 共享部分来完成适配：

![](https://img.cdn.guoshuyu.cn/image-20250606164043213.png)

而对于 Kuikly 又有 Kotlin/JS 和 Kotlin/Native 两种不同的混合支持，这也是目前 KMP 适配鸿蒙 Next 的两种主流方式，所以我们需要先简单聊聊它们的差异。

首先 Kotlin/JS ，在 B 站大佬分享过的内容里，其实就是在编译时让 Kotlin 编译为 JS，而以 JS 和 ArkTS “近亲”的情况下，其实稍作调整就可以让 Kotlin JS 产物可以直接运行在 Ark Runtime 上，并且在 jsMain 中可以很容易使用平台提供的 ArkTS API。

![](https://img.cdn.guoshuyu.cn/image-20250606165006712.png)

> 这个路子就很像 uni-app x 的方式。

当然局限性也很明显，最明显就是性能瓶颈较低，并且产物体积较大，而且一些三方库的 jsMain 实现是默认在 Node 或 Browser 环境中运行，与鸿蒙环境在一些场景下会存在些许差异，所以调整起来需要适配的细节不少：

![](https://img.cdn.guoshuyu.cn/image-20250606164941720.png)

而相比较起来，Kotlin/Native 则是得到更好的性能，**因为它可以通过鸿蒙的 LLVM 直接编译成可执行文件，可以看到这里又是 LLVM**，同样和标准的 Clang/LLVM 有些不同：

- 这里使用的是 Kotlin 自己的前端编译器来解析 Kotlin 代码，生成 Kotlin 的中间表示 Kotlin IR
- Kotlin/Native 的编译器会将 Kotlin IR 转换为 LLVM IR，处理 Kotlin 特有的语言特性等（如协程、lambda 表达式）
- LLVM 接管 LLVM IR，进行优化（如内联、死代码消除）和代码生成
- LLVM 后端生成目标平台的原生机器码（如 ARM、x86_64），输出可执行文件或库（如 .klib 或独立二进制）

当然，**从这点看 Kotlin/Native 更重，因为它会严重依赖 Kotlin 编译器和 LLVM 的版本支持**，比如当你使用 KMP 适配 Android 和 iOS ，然后现在拓展支持鸿蒙平台，那么 iOS 的 LLVM 就需要和鸿蒙的 LLVM 尽可能对齐，也就是当需要升级的时候，需要 iOS 和鸿蒙双端需要同步。

比如在 KuiklyBase 里，将 Kotlin IR 转 LLVM IR 时采用苹果的 LLVM 11，在 LLVM IR 生成可执行文件时使用鸿蒙的 LLVM 12 从而适配，当前鸿蒙平台能够支持的版本在LLVM 12 ~ 15 ：

![](https://img.cdn.guoshuyu.cn/image-20250606172604054.png)

如果从简单层面看，Kotlin/Native 其实可以依赖 Linux 平台的 KMP，毕竟前面我们说过，鸿蒙的内核支持模拟 Linux 环境，例如 Kotlin/Native 在生成 linux_arm64 的 so 时会使用 gnu GCC 编译链和 `libgcc_s.so`，那我们其实只要让 `libkn.so` 不依赖`libgcc_so` ，转而使用鸿蒙的不就好了？

但是如果作为完整的线上需求，这肯定不行，毕竟模拟环境和系统 API 都是问题，而本质上 KMP 官方并没有支持鸿蒙平台，所以实际上使用  Kotlin/Native 还是需要：

- 新增 Harmony  Target
- 定制交叉编译 toolchain 
- Kotlin/Native Runtime 的适配
- 适配 NAPI，支持 KN 产物通过 NAPI 和 ArkTS 交互
- 针对 lib 增肌 NDK 相关支持

当然，如果是 Kotlin/JS 生成的代码难阅读，那 Kotlin/Native 生成的就更难阅读和使用，特别还要实现大量 NAPI 代码绑定来完成适配和调用：

![](https://img.cdn.guoshuyu.cn/image-20250606170044697.png)

所以，可以看出来 KMP 适配鸿蒙工作量是很大的，特别是针对鸿蒙全新 Target 的 LLVM 适配，并且通过 NAPI 让 KN 可以调用到对应系统 API ，想想都能让人放弃。

所以这时候 KuiklyBase 的价值就体现出来，**就算你不用 Kuikly ，但是 KuiklyBase 的开源的 https://github.com/Tencent-TDS/KuiklyBase-kotlin 这部分是真的有很高的参考价值**，至少你想做 KMP 适配鸿蒙的话，谁都不想从 0 开始：

![](https://img.cdn.guoshuyu.cn/image-20250606170906964.png)

而在 UI 部分 KuiklyUI 和 ovCompose 采用了不同的实现方式：

- KuiklyUI 使用原生 OEM 渲染，但是有自己的「薄原生层」利用原子组件实现 UI 统一，并且 KuiklyUI 侧重于静态化+动态化双运行模式（Kotlin/JS），后续还能可以支持 H5 和小程序，有 Compose DSL 兼容模式：![](https://img.cdn.guoshuyu.cn/image-20250606171117429.png)
- ovCompose 采用官方标准 CMP API ，Skia 自绘，支持 Android 、iOS 和鸿蒙三端，只考虑 Kotlin/Native 方，是对于标准 CMP 的横向拓展：![](https://img.cdn.guoshuyu.cn/image-20250606171134053.png)
  

所以 KuiklyUI 是类 RN 渲染，也就是**通过 C API 实现指令的映射**来完成的适配。

而 ovCompose ，因为是自绘方案，所以是基于 Skia 适配的鸿蒙，**所以也就需要实现 CMP 的 Skiko 增加鸿蒙支持**，比如增加了 `libskikobridge.so`  构建而成的  `skikobridge.har` ：

![](https://img.cdn.guoshuyu.cn/image-20250606171433388.png)

并且，Skia 渲染时使用 XComponent 组件作为画布，通过三明治镂空结构，一定程度解决了与原生组件的混排问题，原生UI可以展示在 Compose 上层或下层，满足了绝大部分的业务需求，并且采用 XComponent 的Texture 模式，将内容绘制到 FBO 中，由 FBO 参与原有的ArkUI的绘制节奏，来保证完全的同步：

![](https://img.cdn.guoshuyu.cn/image-20250606171311095.png)![](https://img.cdn.guoshuyu.cn/image-20250606173123809.png)

所以，可以看到比如 KN 适配鸿蒙的难度，CMP 适配鸿蒙的工作量其实更高，这也进一步体现了 ovCompose 的含金量，还是那句话，如果你不用 ovCompose ，但是它的开源也提供了非常不错的参考。

> 另外有人提到 ovCompose 目前的列表体验不佳，实则是因为 ovcompose 是基于multiplatform compose 1.6.1定制 ，而 1.6.1 长列表本身还有很多问题，所以这个需要等后续升级  Compose 版本来解决。

所以可以看到， KMP/CMP 的适配成本其实是最高的，从 LLVM 的适配 到 NAPI 的绑定，然后再到 Skiko 的支持，这里面都需要维护一套定制化 target 实现。



# 最后

没想到这么长你居然读完了，看来无用的知识又多了一些，所以你是否需要适配鸿蒙？如果需要，你是会选择「卓易通」一把梭哈，还是选择跨平台适配？又或者 ArkUI 重头再来？



# 参考链接



- https://mp.weixin.qq.com/s/RUvM3pl6DM6fNiUq8-tZDQ

- https://gitcode.com/openharmony-tpc/flutter_flutter

- https://gitcode.com/openharmony-sig/ohos_react_native

- https://juejin.cn/post/7503974160264069156

- https://juejin.cn/post/7511525207480926227

- https://mp.weixin.qq.com/s/GTkzHTvWIdDmxtlRVpNgfw

- https://juejin.cn/post/7475719627608965147

- https://blog.jetbrains.com/wp-content/uploads/2024/12/day1_3-BiliBili-Kotlin_JS-Kotlin_Native-.pdf



