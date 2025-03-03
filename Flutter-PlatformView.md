# 深入 Flutter 和 Compose 的 PlatformView 实现对比，它们是如何接入平台控件

在上一篇[《深入 Flutter 和 Compose 在 UI 渲染刷新时 Diff 实现对比》](https://juejin.cn/post/7458927663538487350)发布之后，收到了大佬的“催稿”，想了解下 Flutter 和 Compose 在 `PlatformView` 实现上的对比，恰好过去写过不少 Flutter 上对于 `PlatformView`  的实现，这次恰好可以用来和 Compose 做个简单对比：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image1.png)

# Flutter

其实 Flutter 在 Android 上的 `PlatformView`  实现过去已经聊过好多次了，Flutter 作为完全脱离平台渲染树的独立 UI 库，它在混合开发的  `PlatformView`  实现可以说是“历经沧桑” 。

> 既然前面我们讲过很多次，这里主要就是简单介绍下，方便和 Compose 做个对比，感兴趣的可以去看后面的详细链接。

在 Flutter 上是通过 `AndroidView` 接入平台控件，目前活跃在 Android 平台的 `PlatformView` 支持主要有以下三种：

- Virtual Display (VD)
- Hybrid Composition (HC)
- Texture Layer Hybrid Composition (TLHC)

为什么会有这么多不同模式支持？因为主要是随着技术推进和适配场景，`PlatformView`   的适配需求都在更新，但是新来的又不能完全提前之前的方案，所以就导致实现都并存下来。

## VD

VD简单来说就是使用 VirtualDisplay 渲染原生控件到内存，然后利用 id 在 Flutter 界面上占用一个相应大小的位置，最后通过 id 关联到 Flutter Texture 里进行渲染。

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image2.png)

问题也很明显，**因为控件不会真实存在渲染的位置，可以不严谨理解，它只是内存里 UI 的“镜像”显示，或者说“副屏镜像”**，所以此时的点击和对原生控件的操作，其实都是需要由 Flutter 这个 View 进行二次转发到原生再回到 Flutter 。

另外因为控件是渲染在内存里，所以和键盘交互需要通过二级代理处理，容易产生各种键盘输入和交互的异常问题，特别是 `WebView` 场景。

> 当然，现在的 VD 已经比初始的时候好很多，并且还在兼容“服役”。

## HC

1.2 版本开始支持 HC 模式，**这个版本就是直接把原生控件「覆盖」在 FlutterView 上进行堆叠**，简单来说就是 HC 模式会直接把原生控件通过 `addView` 添加到 `FlutterView` 上 。如果出现 Flutter Widget 需要渲染在 Native Widget 上，就采用新的 `FlutterImageView` 来承载新图层。

比如在 Layout Inspector，HC 模式可以看出来各种原生布局的边界绘制：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image3.png)

而如下图所示，其中蓝色的文本是原生的 `TextView` ，红色的文本是 Flutter 的 `Text` 控件，在中间 Layout Inspector 的 3D 图层下可以清晰看到：

- 两个蓝色的 `TextView` 是被添加在 `FlutterView` 之上，并且把没有背景色的红色 RE 遮挡住了
- 最顶部有背景色的红色 RE 也是 Flutter 控件，但是因为它需要渲染到 `TextView` 之上，所以这时候多一个 `FlutterImageView` ，它用于承载需要显示在 Native 控件之上的纹理，从而达 Flutter 控件“真正”和原生控件混合堆叠的效果。

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image4.png)

> 这里的 `FlutterImageView` ，其实还有一个作用，就是**为了解决动画同步和渲染**。

当然，这样带来了一个问题，因为此时原生控件是直接渲染，所以需要在原生的平台线程上执行，纯在 Flutter 的 UI 线程就存在线程同步问题，所以在此之前一些场景下会有画面闪烁 bug 。

虽然这个问题最后也通过类似线程同步实现解决，但是也带来一定程度的性能开销，另外在 Android 10 之前还会存在 GPU->CPU->GPU的性能损耗，**所以 HC 属于会性能开销较大，又需要原生控件特性的场景**。

## TLHC

3.0 版本开始支持 TLHC 模式，最初的目的是取代上面这两种模式，可惜最终共存下来，该模式下控件虽然在还是布局在该有的位置上，但是其实是通过一个 `FrameLayout` 代理 `onDraw` 然后替换掉 child 原生控件的 `Canvas` 来实现混合绘制。

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image5.png)

> 所以看到此时上图 `TextView` 里没有了内容，因为 `TextView` 里的 `Canvas` 被替换成 Flutter 在内存里创建的 `Canvas` 。

其实 TLHC 流程上和 VD 基本一样，简单对比 *VirtualDisplay* 和 *TextureLayer* 的实现差异，**可以看到主要还是在于原生控件纹理的提取方式上** ：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image6.png)

从上图我们可以得知：

- 从 VD 到 TLHC， **Plugin 的实现是可以无缝切换，因为主要修改的地方在于底层对于纹理的提取和渲染逻辑**；

- 以前 Flutter 中会将 `AndroidView` 需要渲染的内容绘制到 `VirtualDisplays` ，然后在 `VirtualDisplay` 对应的内存中，绘制的画面就可以通过其 `Surface` 获取得到；**现在 `AndroidView` 需要的内容，会通过 View 的 `draw` 方法被绘制到 `SurfaceTexture` 里，然后同样通过 `TextureId` 获取绘制在内存的纹理** ；

从这个简单流程上看，**这里面的关键就在于 `super.draw(surfaceCanvas);`**  ，给 Android 的 View “模拟” 出来工作环境，然后通过“替换” Canvas 让 View 绘制需要的 Surface 上合成：

![ ](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image7.png)

那 TLHC 有什么问题？因为它是通过“替换” Canvas 来得到 UI ，**但是这种实现天然不支持 `SurfaceView`等场景**，因为 `SurfaceView` 是自己独立的 Surface 和 Canvas，所以通过 parent 替换 `Canvas` 的实现并不支持。

所以目前的 `PlatformVIew`  支持上的结果：

- 默认会是 TLHC 模式，如果发现接入的 View 是  `SurfaceView`  ，那么就会“降级”使用 VD 来适配
- 可以通过 `initExpensiveAndroidView` 接口强行使用 HC

## 详细链接：

- https://juejin.cn/post/7257119213889454139

- https://juejin.cn/post/7113655154347343909

- https://juejin.cn/post/7260506612971339832



# Compose

Compose 的 PlatformView 原理这里可以详细聊聊，这个目前的资料不多，比较有聊的价值。

众所周知，Jetpack Compose 虽然是 Android 平台的全新 UI 开发框架，**但是它的 UI 渲染树和「传统 xml View 控件」是“不直接兼容”的**，Compose 属于独立的 UI 库，它的 UI 模式更接近 Flutter ，但是 @Composable 函数又不是和 Flutter 一样 return ，在实际工作中，Compose 代码在编译时会给 @Composable 函数添加 `Composer` 参数 ，而实际的 UI Node Tree 等的创建，都是从“隐藏”的 `Composer` 开始：

> 详细可见：https://juejin.cn/post/7458927663538487350#heading-1

所以，一旦你需要在 Jetpack Compose  里接入一个原生控件，你就需要用到 PlatformView 的相关实现，**PlatformView 本质上就是把「传统 xml  View 控件」渲染进 Compose 渲染树里**，而在 Compose 在 Android 平台，使用的就是 `AndroidView`：

```kotlin
@Composable
fun CustomView() {
    var selectedItem by remember { mutableStateOf("Hello from View") }

    // Adds view to Compose
    AndroidView(modifier = Modifier.fillMaxSize(), // Occupy the max size in the Compose UI tree
        factory = { context ->
            // Creates view
            TextView(context).apply {
                text = "Hello from View"
                textSize = 30f
                textAlignment = TextView.TEXT_ALIGNMENT_CENTER
            }
        }, update = { view ->
            // View's been inflated or state read in this block has been updated
            // Add logic here if necessary

            // As selectedItem is read here, AndroidView will recompose
            // whenever the state changes
            // Example of Compose -> View communication
            view.text = selectedItem
        })
}
```

如上代码所示，通过  `AndroidView` 我们可以把一个 Android 传统的 `TextView` 添加到 Compose 里，当然这没什么实际意义，只是作为一个简单例子。

渲染之后，我们可以看到在 Layout Inspector 的 Component tree 里并没有 `TextView` ，因为它只是被渲染到 Compose 里，但是**它其实并不是 “直接” 存在于 Compose 的 LayoutNode ，它只是“依附”在   `AndroidView`** 。

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image8.png)

想知道   `AndroidView`  的工作原理，我们需要看它的 `factory` 实现，从源码我们可以看到，它主要是通过 `ViewFactoryHolder` 创建了一个代理 `layoutNode`  来“进入” Compose 渲染树：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image9.png)

而 Android 上 `ViewFactoryHolder` 的实现主要在它基类  `AndroidViewHolder` ，这里可以看到  **`AndroidViewHolder`  那可是一个“实实在在”的传统 `ViewGroup`  实现** ：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image10.png)

> 我们可以假设，我们前面的传统 `TextView` ，在 `AndroidView` 内部实际上就是被添加到 `AndroidViewHolder`   这个 ` ViewGroup` 里 ，而且这里还有一个   `Owner` ，从命名上也很“关键”。

带着这两个问题，我们继续看，首先我们在  `AndroidViewHolder`   里可以看到有 `layoutNode`  的实现，也就是其实这个 Holder ，**它既是传统  ` ViewGroup`  ，又具备 Compose 里的  `layoutNode`  实现**：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image11.png)

通过查看  `layoutNode`  的实现，我们可以看到：

- 在 `layoutNode` 被 `onAttach` 到 Compose 布局里的时候，会执行 `addAndroidView` ，其实这里的  `addAndroidView`  内部，就是一个 `ViewGroup` 的  `addView`  操作
- 另外，在 layoutNode 被 `onDetach` 时执行 `removeAndroidView`  ，内部也就是  `ViewGroup` 的`removeViewInLayout` 
- 另外还有通过 `MeasurePolicy` 处理布局，简单说就是将 Compose 的布局状态同步到 `AndroidViewHolder`  这个  `ViewGroup`  去布局，给 「传统 XML View」“模拟” 布局环境。

所以我们可以看到，`AndroidViewHolder`  类似一个“中转站”，它将 Compose UI 的生命周期和测绘布局状态同步到传统  ViewGroup 控件，从而给添加进来的 `TextView`  “模拟” 出布局和绘制环境，大概可以总结：

> **`AndroidViewHolder`  类似于 Compose 代理 Node，它 Compose 中的 UI 环境“模拟”到 `ViewGroup` 中，通过控制 `ViewGroup` 的绘制与布局来控制我们的「传统 xml View 控件」**。

那么  `AndroidViewHolder`   肯定就是从  `onAttach`  开始进入 Compose 的 LayoutNode 体系工作，这里关键在于 `AndroidComposeView`  的这个操作：

```kotlin
(owner as? AndroidComposeView)?.addAndroidView(this, layoutNode)
```

这里又冒出来一个**新对象  `AndroidComposeView` ，它就是我们前面所说的  `owner`** ，那它又是什么？

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image12.png)

我们看   `AndroidComposeView`  的源码，可以看到   `AndroidComposeView`   同样是一个 `ViewGroup` ，它的内部主要是有一个  `AndroidViewsHandler`  的  `ViewGroup`  在处理 `AndroidViewHolder`  ，比如前面的 `addAndroidView` 就是将 *Holder* 添加到 *Handler* ：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image13.png)

那到这里就有三个东西：

-  `AndroidComposeView`   
-  `AndroidViewsHandler`  
-  `AndroidViewHolder`  

它们都是传统 `ViewGroup` 的实现，且关系大概如下所示：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image14.png)

那么到这里，流程上我们应该就清晰了，我们只需要搞清楚   `AndroidComposeView`  是什么，来自哪里，然后往下，大概就可以理清它的实现。

我们通过    `AndroidComposeView`   内部有个 `root` 节点的实现，可以猜测它应该是一个顶层节点，所以我们直接从顶部开始找：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image15.png)

我们从 Activity 开始往下找，经过几个简单调整，就可以在  `AbstractComposeView.setContent`  找到创建   `AndroidComposeView`   的地方：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image16.png)

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image17.png)

因为  ` AbstractComposeView` 的实现是  `ComposeView`  ，所以可以看到：

> **`AndroidComposeView`  是在初始时被  `ComposeView`  创建并 `addView` ，然后 Composition 里 UiApplier 的 root 节点就是  `AndroidComposeView`**。

所以这就是为什么前面我们那个   `owner`  为什么是 `AndroidComposeView` 的来源，然后往下就是   `AndroidViewsHandler`  ，它主要就是持有所有 Holder ，然后根据调用给它的 children 执行各种布局和绘制操作：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image18.png)

所以我们就知道了：

- 在初始化的时候，Compose 就会创建一个顶层 ViewGroup 节点 `AndroidComposeView`  ，它是一个 root LayoutNode 
- `AndroidComposeView`  内部的  `AndroidViewsHandler`   会通过一个 hashMap 去触发和管理 children Holder 的布局和重绘
-  `AndroidViewHolder`  是一个代理 LayoutNode ，同时它将 Compose UI 的生命周期和测绘布局状态同步到传统  ViewGroup 控件

大概会是下面这样的结构，**但是它虽然被 `addView` 到 `ViewGroup` 里，但是它并不会直接渲染在 `ViewGroup` 里 ，而是「被代理渲染」到 LayoutNode 对应的 Scope 里** ：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image19.png)

比如我们接入了两个 `SurfaceView ` 到 Compose ，如果我们打印传统布局结构，大概可以看到这样的一个结果，：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image20.png)

> 这里举例的 `SurfaceView` 后面会顺便聊聊 。

最后就是绘制，知道流程后，我们直接看回  `AndroidViewHolder`   里的 layoutNode 实现，在这里有一个来自 `drawBehind` 的 `canvas` ：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image21.png)

一般情况下，`drawBehind` 修饰符可以想任何可组合函数后面绘制内容时，例如：

```kotlin
Text(
    "Hello Compose!",
    modifier = Modifier
        .drawBehind {
            drawRoundRect(
                Color(0xFFBBAAEE),
                cornerRadius = CornerRadius(10.dp.toPx())
            )
        }
        .padding(4.dp)
)
```

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image22.png)

而这里的 Canvas 是来自  `DrawScope` ， `DrawScope` 属于一个针对 Canvas 接口的高级封装，内部 Canvas 的底层支持还是原生平台的 Canvas ，因为 Compose 有多平台支持，而 **Android 平台对应的就是 `AndroidCanvas` 对象，这里是通过  `canvas.nativeCanvas`  获取到的，就是 `android.graphics.Canvas`  对象，也就是传入了一个 Android 原生 Canvas** 。

流程上如下图所示，这里的核心其实就是：**将  Compose 里 `drawBehind`  的 Canvas 传递给「传统 XML View」，这样在绘制时用的就是来自 Compose 体系 `drawBehind`  的 Canvas 链条**：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image23.png)

所以这里可以看到，在绘制的时候，**采用的其实就是通过 AndroidViewHolder 这个  `ViewGroup ` 作为 Parent 来  “替换” 掉作为 child 的传统 View 的 Canvas ，让 View 的内容通过 Compose 的 Canvas 绘制到它所在的 LayoutNode 上**。

另外， `pointerInteropFilter` 也会处理手势事件，用户在当前 LayoutNode 交互的手势，会被发送到  `AndroidViewHolder` 这个 `ViewGroup` ，从而触发传统 Androd 控件的点击等效果。

最后，在 navigate 切换的时候， `AndroidViewHolder`  也会相对应的被 add/remove 。

> 从这角度看，**Compose 的 PlatformView 实现和 Flutter 的 TextureLayer 理念很接近，都是通过“替换” Canvas 和“模拟”布局环境来实现 View 接入，但是，它们又有本质不同，这个不同就体现在 `SurfaceView`** 。

因为 `SurfaceView`  是有自己独立的 Surface 和 Canvas ，所以它是无法被 Parent  的 Canvas “替换” ，这也是 Flutter 里 TLHC 的问题，但是在 Compose 里，你会发现  `SurfaceView`   在 `AndroidView` 里可以正常工作：

```kotlin

@Composable
fun ContentExample() {
    Box() {
        ComposableSurfaceView(Modifier.size(100.dp))
        Text("Compose", modifier = Modifier
            .drawBehind {
                drawRoundRect(
                    color = Color(0x9000FFFF), cornerRadius = CornerRadius(10.dp.toPx())
                )
            }
            .padding(vertical = 30.dp))
    }
}

@Composable
fun ComposableSurfaceView(modifier: Modifier = Modifier) {
    AndroidView(factory = { context ->
        SurfaceView(context).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT
            )
            holder.addCallback(MySurfaceCallback())//添加回调
        }

    }, modifier = modifier)
}

class MySurfaceCallback : SurfaceHolder.Callback {
    private var _canvas: Canvas? = null
    override fun surfaceCreated(p0: SurfaceHolder) {
        _canvas = p0.lockCanvas()
        _canvas?.drawColor(android.graphics.Color.GRAY)//设置背景颜色
        _canvas?.drawCircle(100f, 100f, 50f, Paint().apply {
            color = android.graphics.Color.YELLOW
        })//绘制一个红色的图像
        p0.unlockCanvasAndPost(_canvas)
    }
}
```

可以看到，上面代码的 `SurfaceView`  灰色的背景和黄色的圆都被渲染出来，另外 `Text` 的 *Compose* 文本也正常带着背景色覆盖显示在  `SurfaceView`   上：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image24.png)

有没有觉得奇怪，为什么   `SurfaceView`   的 `Canvas`  没有被替换，但是   `SurfaceView`    的内容和层级却又正常渲染在了 Compose UI 树里？

其实道理很简单，**虽然 Compose 和「传统 XML View」 是两套 UI 框架，但是 Compose 的本质还是 Android 里面的 View ，也就是它依旧在 View 体系的范畴内**：

> 依赖 Android 的 Surface、Window、SurfaceFlinger 体系去渲染。

我们简单回忆下 `SurfaceView` 是怎么工作的？

- Android 里控件基本都是以 `View`  为基类，所有可见 View 对象都会渲染到一个 Surface ，这个 Surface 来自 SurfaceFlinger ，也就是当前 Window 下。

- 尽管  `SurfaceView`  继承自类View，但是它有自己独立的 Surface，是直接提交到 SurfaceFlinger 

这也是 `SurfaceView`  会有自己独立 Canvas 的原因，简单说它是一个可以绘制到 Surface 并直接输出到 SurfaceFlinger 的视图。

一般情况下， `SurfaceView` 在其 Window 层上始终是一个透明的 Rect，类似于**`SurfaceView` 在其窗口中打了一个洞**， 并且默认情况下，`SurfaceView` 的 Z 顺序始终低于其附加的 Window 层，也就是  `SurfaceView`  的 Surface 是在默认 Surface 的下面。

而最终渲染时，**SurfaceFlinger 会将 `SurfaceView` 的图像层和 Window 的图像层叠加在一起**。

那么回到 Compose，Compose 的底层还是一个传统的 View ，所以它还是依赖 View 的 Surface 和 SurfaceFlinger，也就是：

> Compose 和「传统 View」 共用同一个 Window 和  `DecorView`，`AndroidView` 作为一个桥接节点，将「传统 View」 “插入” 到 Compose 的布局树中，虽然 `SurfaceView` 绘制内容是独立的，但在屏幕上是共享一个 `Window` ， `SurfaceFlinger`  依然会统一管理窗口合成。

如给上方 `SurfaceView` 的代码加上 **`setZOrderOnTop(true)`**，就会看到 Compose 的 `Text` 看不到了，因为此时的 Z 层面发生了变化：

![](http://img.cdn.guoshuyu.cn/20250117_PlatformView/image25.png)

这就是 Compose  和 Flutter  在 `AndroidView` 上最大的区别：

> **Flutter 是完全脱离了渲染体系，但是 Compose 还是在 View 体系内，所以 `SurfaceView` 不会是问题，甚至官方还推出了  `SurfaceView`  对应的 Compose 封装 [AndroidExternalSurfaceScope](https://developer.android.com/reference/kotlin/androidx/compose/foundation/AndroidExternalSurfaceScope)** 。

只是说，在 「传统 XML View」 体系中，每个 View 会有一个 RenderNode，而 Compose 中“一般”只有 ComposeView 一个 RenderNode，也就是传说的单页面状态，而 Compose 内部最终就是将自己的 LayoutNode 通过 Composer 组合完成后塞到 RenderNode 里面。

# 最后

可以看到，在 Android 平台上， Flutter 和 Compose 在最终实现思路很接近，大家都叫  `AndroidView` ，**理念都是“模拟”环境和“替换” Canvas** ，但是在 Android 平台上 Compose 有着原生 View 体系的优势，所以它对 `SurfaceView` 的支持更友好。

