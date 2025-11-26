# 深入理解 Flutter 的 PlatformView 如何在鸿蒙平台实现混合开发

关于 Flutter 的 PlatformView 混合开发，我们在过去聊了很多次，特别是 Android 平台的 PlatformView ，现在已经同时具备 VD、HC、TLHC、HCPP 等多种兼容实现，甚至我们还深入对比过 Flutter 和 Compose 在 PlatformView 的差异，感兴趣的可以通过下方链接回顾：

- [《Flutter 正在推进全新 PlatformView 实现 HCPP》](https://juejin.cn/post/7471979172115152932)
- [《Flutter 混合开发的混乱之治》](https://juejin.cn/post/7260506612971339832)
- [《深入 Flutter 和 Compose 的 PlatformView 实现对比》](https://juejin.cn/post/7461597205342928936)

**而本次我们要深入聊的，则是 Flutter 在鸿蒙平台的 PlatformView 实现，核心是聊聊它是如何实现“同层渲染”**。

# 同层渲染

我们知道，Flutter 是一个自渲染的跨平台框架，在之前的[《为什么跨平台框架可以适配鸿蒙，它们的技术原理是什么？》](https://juejin.cn/post/7513136826073677850)我们就聊过了 Flutter 如何适配到鸿蒙，其中就有：

> 在绘制支持上，现在鸿蒙版 Flutter 已经支持了 skia 和 Impeller 渲染，核心是通过 `XComponent` 支持，`XComponent` 提供了一个用于渲染的 Surface（`NativeWindow`）。

在鸿蒙里，`XComponet` 可以直接获取到系统底层的 `OHNativeWindow` 实例， 然后通过鸿蒙提供的扩展 `VK_OHOS_surface`，将这个窗口转成一个 `Vulkan` 中的 `VKSurface`， 进而通过 `VKSwapchain` 实现了窗口绘制。

而我们接下来要聊的则是鸿蒙里 Flutter 的 PlatformView 如何实现“同层渲染”，简单来说就是：**将 ArkUI 渲染到 Flutter 里，这类似于 ArkUI 里将控件渲染到 Web 组件一样的道理**。

![](https://img.cdn.guoshuyu.cn/image-20250722104345513.png)

事实上，在鸿蒙官方 ArkUI 的 Web 组件里，可以通过开启 `enableNativeEmbedMode` ，从而启用 WebView 里的“同层渲染” ，简单来说就是：

> 底层使用空白的 H5 页面，用 Embed 标签进行占位，ArkTS 使用 `NodeContainer`  占位，最后将 Web 侧的 `surfaceId` 和原生组件绑定，让原生组件渲染到 Web 里。

具体步骤为：

- 1、用 `Stack` 组件层叠 `NodeContainer` 和 Web 组件，并开启 `enableNativeEmbedMode` 模式
- 2、因为要使用 `NodeContainer` ，所以封装一个继承 `NodeController` 的 `SearchNodeController` 对象
- 3、使用 Web 组件加载 `nativeembed_view.html` 文件，Web 组件解析到 Embed 标签后，通过`onNativeEmbedLifecycleChange` 接口上报 Embed 标签创建消息通知到应用侧
- 4、在步骤 3 的回调内，根据 `embed.status`，将配置传入 `searchNodeController` 后，执行 rebuild 方法重新触发 Controller  的 `makeNode` 方法
- 5、`makeNode`方法触发后，`NodeContainer` 组件会获取到 `BuilderNode` 对象，`BuilderNode` 承载了对应原生控件的纹理，页面出现原生组件

看着是不是有点抽象？**实际上其实就是通过 `NodeContainer` 占位，然后实现它对应 `NodeController` 的  `makeNode` 方法，把原生控件绘制到 `BuilderNode` ，而 `BuilderNode` 通过 `surfaceId` 关联到一个可绘制区域**：

```ts
makeNode(uiContext: UIContext): FrameNode | null {
    this.rootNode = new BuilderNode(uiContext, { surfaceId: this.surfaceId, type: this.renderType });
    if (this.componentType === 'native/component') {
      this.rootNode.build(wrapBuilder(searchBuilder), { width: this.componentWidth, height: this.componentHeight });
    }
    return this.rootNode.getFrameNode();
  }


@Builder
function searchBuilder(params: Params) {
  SearchComponent({ params: params })
    .backgroundColor($r('app.color.ohos_id_color_sub_background'))
}
```

所以这里的核心其实就是  `NodeContainer`  和  `BuilderNode`  ，它们是 ArkUI 上混合开发的基础，事实上 Flutter 在鸿蒙的 PlatformView 的实现也类似：

> **通过   `BuilderNode`  导出 ArkUI 控件的纹理，导出的纹理在 `XComponent` 中实现"同层渲染"**，这和 Flutter 在 Android 上的  VD 实现比较接近。

# 各种 Node

所以首先我们需要了解 `BuilderNode` 是什么？`BuilderNode` 在 ArkUI 里是一个自定义声明式节点 ，支持采用无状态的 UI 方式，可以通过全局自定义构建函数 `@Builder` 定制组件树，而定制组件树得到的 `FrameNode` 节点，可以直接由 `NodeController` 返回并挂载于 `NodeContainer` 节点下：

![](https://img.cdn.guoshuyu.cn/image-20250722105701006.png)

另外 `BuilderNode` 还提供了组件预创建的能力，比如通过结合 `BuilderNode`，可以将 `ArkWeb` 组件提前进行离线预渲染，组件不会即时挂载至页面，而是在需要时通过 `NodeController` 动态挂载与显示。

所以，通过 `BuilderNode` ，我们也了解到了 `NodeContainer` 的作用：

> 用于挂载自定义节点（如 `FrameNode` 或 `BuilderNode` ），并通过 `NodeController` 动态控制节点的上树和下树，组件接受一个 `NodeController` 的实例接口，所以  `NodeContainer` 需要和 `NodeController` 组合使用。

当然，严格意义上说， `NodeContainer` 仅支持挂载自定义节点 `FrameNode` ，对于 `BuilderNode` 其实是获取它的根节点 `FrameNode` 。

是不是看到各种 XXXNode 又有点懵？ 其实 ArkUI 和 Flutter 一样，首先 ArkUI 也有三棵树：Component Tree、Element Tree 和 RenderNode Tree ，它们各种的作用也和 Flutter 三棵树基本一致，其中 RenderNode Tree 就是存在于C++后端引擎中的最终渲染结构：

![](https://img.cdn.guoshuyu.cn/image-20250722130635171.png)

而 `FrameNode` 则是可以认为是三棵树中 Component Tree 的特殊实体节点，与自定义占位容器组件 `NodeContainer` 相配合，就可以实现在占位容器内构建一棵自定义的节点树：

![](https://img.cdn.guoshuyu.cn/image-20250722105701006.png)

而  `FrameNode` 作为特殊 Component 节点，它提供了节点创建和删除的能力，**也就是在 ArkUI 这种声明式开发场景里，提供了命令式操作的支持**，另外  `FrameNode`  还提供了 `getRenderNode` 接口，用于获取 `FrameNode` 中的 `RenderNode` ，也就是通过 `FrameNode`  可以直接提供绘制的渲染节点，简单来说：

- `FrameNode`  +  `NodeContainer` 提供自定义节点支持，通过  `FrameNode`   提供 `RenderNode` 
- `BuilderNode` 提供构建支持和纹理导出，并通过 `getFrameNode` 获取得到对应的 `FrameNode` 对象

所以可以简单分类下：

- `BuilderNode` 是一个自定义的声明式节点
- `FrameNode` 是一个自定义组件节点
- `RenderNode` 是一个自渲染节点

# Flutter



所以其实 Flutter 鸿蒙在鸿蒙平台的实现方式接近于 Android 平台的  VD，即通过  `NodeContainer`  挂载了节点，并实现了事件传递，最终通过将提取的纹理合并到 Flutter 内进行渲染。

而这对应到 Flutter 鸿蒙实现里，就是 ` EmbeddingNodeController` 的实现，它通过继承 `NodeContainer` 并实现 `makeNode`创建和管理 ArkUI 的 `BuilderNode` ，而  `BuilderNode` 里的 `wrappedBuilder` 则是来自封装好的 PlatoformView 里的 ArkUI 的  `@Builder` 实现：

![](https://img.cdn.guoshuyu.cn/image-20250722112017064.png)

而另一方， ` EmbeddingNodeController` 作为  `NodeController`  的具体实现，它肯定是用于管理   `NodeContainer`  ，而 Flutter 鸿蒙里，用于创建和加载   `NodeContainer` 的对象则是 `DynamicView` ，**它是一个基于 `DVModel` 数据驱动的对象，我们可以在 `FlutterPage` 的默认实现里看到它的身影**：

![](https://img.cdn.guoshuyu.cn/image-20250722134539996.png)

简单来说，通过上述代码，可以看到鸿蒙 Flutter 的页面默认是在一个 `Stack` 下：

- `XComponent` 提供 surface 绘制，是 Flutter 的渲染画板
- 基于 `this.rootDvModel` 列表的 `DynamicView` ，主要是提供 PlatformView 所需的 `NodeContainer`

![](https://img.cdn.guoshuyu.cn/image-20250722135315442.png)![](https://img.cdn.guoshuyu.cn/image-20250722135351119.png)

**这里可以看到 `DynamicView` 是基于 `DVModel` 实体作为驱动，而 `DVModel` 的存在，则是为了用鸿蒙 ArkUI 的声明式范式来管理和渲染由 Flutter 发出的 PlatformView  命令式 UI 操作**：

> 因为 ArkUI 和原生 Android XML 不同在于，它是纯粹的声明式 UI 框架，你不能像传统 Android 命令式编程那样直接调用 `parent.addView(child)` ，相反需要通过状态驱动，让框架根据新状态重新渲染 UI。

而 `DVModel` 就是这个“状态，它是一个用 `@Observed` 的可被观察的树状数据结构，用纯数据完整地描述了整个界面布局，包括哪个位置应该有一个 PlatformView，它有多大，参数是什么之类，具体类似：

![](https://img.cdn.guoshuyu.cn/image-20250722132736789.png)

所以，当 `DVModel` 作为状态发生变化时，和它相关的 `DynamicView` 也会发生变化，这也是 Flutter 鸿蒙在 PlatformView 实现上的特殊之处 ，比如在鸿蒙 Flutter 里运行 webview_flutter 之后，在 ArkUI Inspector 可以看到以下的布局：

![](https://img.cdn.guoshuyu.cn/image-20250721150136130.png)

可以看到此时通过  `DynamicView` 构建了一个  `NodeContainer` ，而这里的  `NodeContainer` 通过 `BuilderNode` 承载了 `Web` 组件的纹理。

另外，可以看到，当存在两个 `Web` 组件的时候，控件树里就会有两个  `DynamicView` ，这也对应是我们在前面 `FlutterPage` 里基于 `this.rootDvModel` 列表的实现：

![](https://img.cdn.guoshuyu.cn/image-20250722094343235.png)

 如果我们堆叠两个 Web ，并且在 Web 上在加一个 Flutter  红色控件，通过 ArkUI Inspector 我们可以看到对应 `DynamicView` 的 `NodeContainer` 存在的节点，只是该节点的内容并没有渲染在原来的位置：

![](https://img.cdn.guoshuyu.cn/image-20250926124815742.png)![](https://img.cdn.guoshuyu.cn/image-20250926124155823.png)![](https://img.cdn.guoshuyu.cn/image-20250926124441759.png)



而因为此时 `Web` 组件是通过纹理的方式被渲染到 Flutter Engine 里，所以在事件触摸上，触摸事件需要从 Dart 层发送出来，经过中转，最后通过  `EmbeddingNodeController` 的 `postEvent` 转发到  `BuilderNode` ，从这点看，也是和 Flutter Android 的 VD 模式类似：

![](https://img.cdn.guoshuyu.cn/image-20250722114725111.png)

> 当然，和 VD 不同的是，因为  `Web`  是真实存在的节点，所以键盘输入不会像 VD 那样有太多的 connection 问题，从这点看又类似 TLHC 实现。

那么到这里我们知道了通过 ` EmbeddingNodeController` 和 `DynamicView` ，如何创建和渲染 ArkUI 控件实现“同层渲染”，最后一步就是 Dart 如何触发 PlatformView 构建的实现对象：`PlatformViewsChannel` 和  `PlatformViewsController` 。

当用户在 Dart 层使用 `OhosView` 或者 `OhosViewSurface` 创建鸿蒙 PlatformView  时，就会触发 `PlatformViewsChannel` 的 `create` :

![](https://img.cdn.guoshuyu.cn/image-20250722142747806.png)![](https://img.cdn.guoshuyu.cn/image-20250722142827368.png)

此时虽然和 Android 一样存在两个入口，可以根据 Dart 层是否配置了 `hybrid` 来决定使用 `createForPlatformViewLayer` 还是  `createForTextureLayer` ，但是实际上目前只有  `createForTextureLayer` 一种可用，如果配置了 `hybrid` 模式，运行后就会发现此时会出现 `view_embedder` 为空的情况：

![](https://img.cdn.guoshuyu.cn/image-20250721155049356.png)![](https://img.cdn.guoshuyu.cn/image-20250721155035255.png)

> `createForPlatformViewLayer` 在 Android 走的是 HC 的实现，它和 TextureLayer 相反，它把自己作为一个合成边界，它的渲染路径是分叉的，把 Flutter 内容被渲染到离屏缓冲区，然后通过 `SurfaceFlinger` 将这些缓冲区和独立渲染的原生视图组合在一起，Flutter 的 UI 控件会 以 PlatformViewLayer 的前后交际关系，被渲染到不同的 Surface 上。

但是目前在鸿蒙 Flutter 的实现里，关于 `createForPlatformViewLayer`  的 HC 并没有实现，所以实际上只有   `createForTextureLayer` 纹理合成这一种 PlatformView 的场景：

![](https://img.cdn.guoshuyu.cn/image-20250722143932608.png)

而对于 `createForTextureLayer` ，流程会来到 `PlatformViewsController` 对象，核心流程主要有：

- 创建一个 `platformView`，实际上就是调用 Plugin 里开发者 `PlatformViewFactory` 的实现
- 通过 Engine 注册一个得到一个和 Flutter Engine 关联的 Surface id
- 创建 `EmbeddingNodeController `，关联 Surface id 和关联  `platformView` 的 ArkUI 控件
- 创建 `DVModel` ，添加到队列驱动创建 `DynamicView`

![](https://img.cdn.guoshuyu.cn/image-20250722144349562.png)![](https://img.cdn.guoshuyu.cn/image-20250722144516561.png)

这里需要说个题外话，获取 surface id 时，其实是在 Engine 底层，利用系统 Graphic2D 的  NativeImage 能力，通过 `OH_NativeImage_Create` 创建一个 `OH_NativeImage` 实例：

![](https://img.cdn.guoshuyu.cn/image-20250722163618335.png)

>  `OH_NativeImage` 支持将数据和 OpenGL 纹理对接， 或者开发者自行获取 buffer 进行渲染处理。

注意 `OH_NativeImage_SetOnFrameAvailableListener` ，会在 Frame 数据可用时触发 `MarkTextureFrameAvailable` ，实际上它类似于 C++ 层面在纹理对象上设置一个内部标志，本质上是将其标记为“脏”或“过时”，类似 `setState` 的作用：

![](https://img.cdn.guoshuyu.cn/image-20250722163412869.png)

实际这个操作会触发两个 TaskRunner 的工作：

- 在 Raster 线程触发设置 texture 为“脏”
- 在 UI 线程执行 `ScheduleFrame(false)` ，false 表示 Widget 完全相同，Engine 可以跳过整个构建/布局/绘制过程，只需获取最后生成的  layer tree 并在光栅线程上重新渲染它

![](https://img.cdn.guoshuyu.cn/image-20250722163508291.png)

上述就是 TextureLayer 的大致注册和渲染流程，回到主流程上，最后流程在得到 `DVModel` 后，  `DynamicView` 会构建出来 `NodeContainer` ，从而触发  `EmbeddingNodeController ` 的 `makeNode` ，进而 `BuilderNode` 构建并提取 PlatformView 里的 ArkUI 控件纹理，最终渲染出画面。

具体到  webview_flutter 里，就是 `WebViewPlatformView` 继承了 `PlatformView` ，并实现了 `getView()`  方法，方法里返回了 `OhosWebView` ：

```ts
getView(): WrappedBuilder<[Params]> {
  return new WrappedBuilder(WebBuilder);
}
  
@Builder
export function WebBuilder(params: Params) {
  OhosWebView({
    params: params,
    webView: params.platformView as WebViewPlatformView,
    controller: (params.platformView as WebViewPlatformView).getController()
  })
}

```

而这个 `getView(): WrappedBuilder` ，会在 `EmbeddingNodeController` 被获取，并且在 `makeNode` 里被 `BuilderNode` 使用，从而实现最终的纹理提取和渲染：

![](https://img.cdn.guoshuyu.cn/image-20250722145608817.png)

最后，整个 PlatformView 的整体流程如下图所示，可以看到，核心还是在 `NodeContainer` 和 `BuildNode` 的基础上进行展开，然后基于 `DVModel` 驱动 `DynamicView` 更新，进而 `makeNode` 构建出纹理，触发 Engine 更新 Texture 区域实现绘制。

![](https://img.cdn.guoshuyu.cn/mermaid-diagram-2025-07-22-152152.png)





# 参考链接

- https://device.harmonyos.com/cn/docs/apiref/harmonyos-guides/arkts-user-defined-arktsnode-buildernode

- https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-render-web-using-same-layer-render

- https://device.harmonyos.com/cn/docs/apiref/harmonyos-guides/arkts-user-defined

