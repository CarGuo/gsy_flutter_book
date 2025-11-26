

# Snapchat  开源全新跨平台框架 Valdi  ，一起来搞懂它究竟有什么特别之处

最近看到好几篇在推 Valdi  的文章，大致意思就是 「RN/Flutter 的地位将受到威胁」，「Valdi  将成为全新的跨平台流行架构」云云，这不仅就让我好奇这个新框架有什么魔力，还能在 2025 的跨平台领域玩出新花样？![](https://img.cdn.guoshuyu.cn/image-20251112142741561.png)

首先，Valdi  是由  Snapchat  开源的跨平台框架，其核心技术已在 Snap 的生产应用中验证长达 8 年，号称在不牺牲开发速度的前提下提供原生性能 ，那它是怎么做到的？

简单来说，**Valdi 是一个 “用 TypeScript（TSX）写 UI，然后编译成原生视图（iOS／Android／macOS）” 的跨平台 UI 框架**，所以它说了 Valdi 不依赖  WebView 和 JS Bridge ，也就是说 Valdi 就是一个将 TS 转化为原生布局的编译支持？

> 答案肯定不是，这也是它和 RN 不同的地方。

虽然 Valdi  采用了“编译时”模型，会将声明式的 TS 直接编译为平台原生视图（iOS/Android/macOS），但是重点在于：

> “Optimized layout engine – C++ layout engine runs on the main thread with minimal marshalling overhead.”

也就是它虽然编译成原生控件，**但是它的布局并不走原生布局，它是通过自己的 C++ 布局引擎来完成布局的**。

而它另一个重要的特性就是 “Polyglot 模块” ，这个模块核心就是实现一个自动类型安全绑定系统，它充当了一个编译时外来函数接口 (FFI) 生成器，**Polyglot  允许开发者“用 C++、Swift、Kotlin 或 Objective-C 编写性能关键代码”** ，允许开发者在 Valdi 中构建完整的功能（包括后台处理），从而消除了特定平台的桥接代码 。  

> 实际上从社区上提及的，就是 Polyglot  在架构上优于 React Native (RN) 的 (JSI) 和 Flutter 的平台通道 (Platform Channels)，理论应该和 Flutter 的线程合并后的 FFI 差不多。

所以，也就是搞懂了这两个东西，我们就大概知道了  Valdi  是什么了。

## 布局

Valdi 布局系统的底层支撑是一个“优化的 C++ 布局引擎” ，并且最有意思的是，这个引擎“**在主线程上运行**” ，这也是这个框架的特色或者说争议点。

对于这个问题，Valdi  表示这是一个优势，理由是“最小化的编组开销” ，**基础是该 C++ 引擎的效率极高，以至于在 UI 线程上直接运行布局计算的成本，低于将布局数据发送到后台线程并异步接收计算结果（涉及数据编组）的总成本**。

> 这其实是一种高风险又高回报的架构，这意味着 Valdi  的 C++  效率必须极高且绝对可信。

而从这点也可以看出，Valdi  并不是直接调用系统的布局机制（例如 iOS Auto Layout 或 Android ViewGroup 的 measure-layout），而是采用了**自定义 C++ 布局引擎**来计算视图尺寸与位置，可以简单理解为：开发者以声明式 TS 写布局，Valdi  的布局引擎负责把这些声明转化为原生视图的 「尺寸／位置／层级」。

整个流程可以大致推论为：

- TSX 写组件  `<view padding={10} backgroundColor="red"><label … /></view>`

- 在编译／运行时，Valdi 的 TSX → 中间结构 → 原生视图映射机制，会建立一个视图树（native views），但这些视图的尺寸与位置不是简单依赖平台默认布局，而是由 C++ 布局引擎计算

- 布局引擎接收节点树、样式（margin/padding/flex etc）

- 引擎在主线程运行，计算每个视图的尺寸和位置，输出布局结果，然后原生视图被 “inflate”／复用（**Valdi 有全局视图池化机制**）

- **当数据状态改变（组件 state 或 viewModel 更新）时，仅受影响的子组件重新渲染**，其对应的视图树／布局会被重新计算／更新，而不会强制父视图全部重绘（“Components re-render independently without triggering parent re-renders”）

这里有一些官方特别提到的点：

- **Automatic view recycling** ： 一个 Global view pooling system ，这个系统会复用现有的原生视图对象（例如 $UILabel$， $TextView$），而不是创建新对象，从而减少原生控件 inflate／销毁开销
- **Viewport-aware rendering**  ：只有可见的视图节点才被 inflate，从而在滚动／大量列表场景中降低资源消耗，这也是 Snapchat 这样的社交媒体应用最需要的能力
- **Optimized component rendering** ： Valdi 组件会“独立地重新渲染，而不会触发父组件的重新渲染” ，从而实现快速、精细化的增量 UI 更新
- **marshalling overhead minimal** ：通过 C++ 布局引擎减少跨语言通信成本

根据目前代码看，Valdi  转化的原生控件应该还是传统 Android View 和 UIKit 体系 ，而 Valdi  的核心之一就是打磨自己的 C++ 布局引擎，虽然用的原生控件，**但是整个布局流程都在 Valdi  自己内部实现，只有绘制流程回归了平台**，这也是为什么是 Snapchat 会说：“*Flexbox layout system with automatic RTL support*.” 

## Polyglot 

Polyglot 是 Valdi 的原生集成解决方案的另外一个关键，也是 Valdi 最重要的架构特性，**因为 Polyglot 可以在 TypeScript 和原生平台之间生成类型安全的绑定** ，通过绑定，可以让 TS 和普通函数一样与原生代码双向通信，允许“复杂的数据结构和回调” 在 TS 和原生代码之间安全传递。

**并且 Polyglot 不是一个运行时桥接**，而是一个编译时 FFI  生成器，从 TS 到 `myNativeModule.doThing()` 的调用，都可以被编译为对底层 Swift/Kotlin 实现的*直接、类型安全、零开销的同步函数调用* 。

> 这个实现主要是为了消除了困扰 RN 和 Flutter 集成的所有样板代码和序列化开销，Snapchat 曾经开源的 `djinni` 工具 （用于生成 C++ 和 Java/Obj-C 之间的绑定）感觉大概率是该 Polyglot  的技术前身。

换言之，Polyglot Modules 在 Valdi 应用中，可以在需要性能或者原生平台特性（camera、硬件加速、第三方原生库）的时候，用 C++／Swift／Kotlin／Obj-C 等语言编写模块，然后通过自动生成的绑定，使得这些模块在 TS 层可以被安全调用。

举个例子，比如关于 `Webview` 支持，虽然 Valdi 内部已经实现了这个功能，但它没有包含在开源项目，用户需要通过定义一个带有 `ExportProxy` 的接口，然后在原生实现这个方法 ：

![image-20251112135413760](https://img.cdn.guoshuyu.cn/image-20251112135413760.png)

简单来说，可以通过 Native 代码将创建一个标记为 `ExportProxy` 的 TypeScript 接口实例，然后实例可以通过组件上下文传递给 TypeScript ，具体为：

TypeScript：

```TypeScript
// @Context
// @ExportModel({ios: 'SCMyComponentContext'})
interface Context {
  serverURL: string;
}

// @Component
// @ExportModel({ios: 'SCMyComponentView'})
class MyComponent extends Component<any, Context> {
  onCreate() {
    // Will print http://api.server.com in the console
    console.log(this.context.serverURL);
  }
}
```

Native :

```objective-c
// Instantiate the context data structure
SCMyComponentContext *context = [[SCMyComponentContext alloc]
    initWithServerURL:@"http://api.server.com"];
// Instantiate the view with the context passed as parameter
SCMyComponentView *view = [[SCMyComponentView alloc]
    initWithViewModel:viewModel
     componentContext:context];
```

> 详细可见：https://github.com/Snapchat/Valdi/blob/main/docs/docs/native-context.md

当然，如果在 UI 层面，这还分为你想把 `WebView` 放到 UI 构建树里，还是仅仅显示在用户 UI 上方，如果是想把 `WebView` 嵌入到视图结构里，就需要需要创建一个自定义视图，整体会更麻烦一些：

![](https://img.cdn.guoshuyu.cn/image-20251112140040156.png)

另外还有比如你需要一些平台调用，如蓝牙、摄像头，那么 Valdi  也可以直接调用本地代码，本地代码也可以调用 Valdi 代码：

- 如果想要一个带有嵌套实时摄像头视图的 Valdi 用户界面，可以添加一个 `<custom-view>` 将它指向 iOS/Android 实时摄像头视图
- 如果想启用/禁用蓝牙，可以原生处理此操作，然后公开一些函数，这些函数可以作为上下文的一部分传递给 Valdi 组件，然后  TS 代码就可以根据需要调用它们

如果需要更形象的使用，具体代码类似：

- 在 TypeScript  调用 Native 代码

```typescript
/**
 * @Context
 * @ExportModel({
 *   ios: 'SCYourComponentContext',
 *   android: 'com.snap.myfeature.YourComponentContext'
 * })
 */
interface YourComponentContext {
  callMeFromTS?();
}
/**
 * @Component
 * [...]
 */
class YourComponent extends Component<YourComponentViewModel, YourComponentContext> {
  onMyButtonWasTapped() {
    // Calls callMeFromTS: on the SCYourComponentContext (if it has been configured)
    this.context.callMeFromTS?.();
  }
}
```

- 然后在 Kotlin 定义好原生实现

```kotlin
package com.snap.myfeature.YourComponentContext

class SCYourComponentContextImpl {
    val onDone: (() -> Unit)?
    // ...
}

//////////

// So you can instantiate YourComponentContext and configure it with the callMeFromTS block:
val componentContext = YourComponentContext()
componentContext.callMeFromTS = {
  // Will be called when this.context.callMeFromTS() is called in TS.
  print("Hello from Kotlin")
}
```

- 在 TypeScript   定义好接口

```typescript
interface YourComponentContext {
  callMeFromTS?(completion: (arg: string) => void);
}
class YourComponent extends Component<any, YourComponentContext> {
  onMyButtonWasTapped() {
    this.context.callMeFromTS((arg) => {
      console.log('the native code called the completion function with arg:', arg);
    });
  }
}
```

- 然后在 Kotlin 调用

```kotlin
componentContext.callMeFromTSWithCompletion = { completion ->
  // This will call the TS callback and provide the given value.
  completion(@"I got you loud and clear");
}
```

可以看到，Polyglot  提供了一套非常方便的调用机制，这也是 Valdi 对自己性能如此有自信的来源。

## 其他

关于 Valdi 的其他优势还有：

- **灵活渐进式采用**：目前的 Valdi 实现上，可以让开发者在已有原生 App 中逐步引入 Valdi，也可以在 Valdi 中插入原生视图，这让 Valdi 的接入和使用门槛相对变低不少，在混合开发领域有些许优势
- 后台处理 ：**支持  worker 线程实现多线程执行**，许开发者使用 worker 线程在 Valdi 中构建完整的功能 ，这也是一个有意思的点，比如和 “Polyglot 模块”  结合，开发者可以在一个 TS worker 线程编写业务逻辑，而线程自身又可以通过 "Polyglot" FFI 对 C++/Swift/Kotlin 代码进行直接、零开销的调用，类似更便捷版本的  Dart isolate Group/backgroud 
- **支持 hot relaod** ，不用多言，开发必备
- **完整的 VSCode 调试：** 可以直接在 VSCode 中设置断点、检查变量、分析性能和捕获堆转储

 ## 问题

那么聊了这么多，相信大家应该了解 Valdi 是怎么实现的跨平台了，那么该简单聊聊它的问题了：

- 社区待发展，虽然 Polyglot 很便捷，但是第三方平台插件总要有人写和封装，大部分开发者其实并不具备多平台的开发能力，所以社区插件生态完善是它未来是否可用的一个很重要的标志
- 文档混乱不全，存在歧义也是目前的主要问题之一![](https://img.cdn.guoshuyu.cn/image-20251112152558799.png)
- 开源还处于 beta 阶段，例如目前 `package.json` 列出了 `@snapchat/eslint-plugin-vivaldi` 还是一个私有 NPM 依赖，类似的还有 Bazel 构建脚本失败，问题也是构建脚本正试图使用 SSH 从一个私有 GitHub 仓库（名为 `@valdi`）抓取依赖，可以看出来本次开源还是相对仓促：![](https://img.cdn.guoshuyu.cn/image-20251112152657071.png)



所以，目前看来 Snapchat  确实有着出色的设计，比如自定义的 C++ 布局引擎和 Polyglot  ，但是它需要走的路还长，毕竟作为跨平台框架，它不再只是需要面对来自内部的压力，Valdi 更需要得到社区的支持，并且有更多丰富的案例来帮助开发者投入其中，重要的是，需要让开发者看到 Snapchat 持续维护开源的决心的行动。

那么，你觉得 Valdi 如何？你会尝试吗？

# 参考链接

- https://github.com/Snapchat/Valdi/
  