# Rive 动画框架竟然支持响应式布局，全平台动画框架开启全新 UI 交互能力

没用过 Rive 的可能对于 Rive 还不熟悉，其实之前已经介绍过 Rive 好几次，例如[《Rive 2  动画库「完全商业化」》](https://juejin.cn/post/7275155682051145787) 和[《给掘金 Logo 快速添加动画效果》](https://juejin.cn/post/7126661045564735519) 等文章都介绍过 Rive ，之所以会接触 Rive 到， 也是因为多年前想在 Flutter 平台找个 Lottie 的替代品，当时的 Rive 还叫 Flare ，而那时候的 Rive 可以说是我接触到的最全平台动画支持框架。

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image1.png)

Rive 作为一个面向设计师的动画框架，他支持在 **Web Editor** 里进行 UI 编排和动画绘制，当然现在他也支持 PC 客户端开发，而他的好处是轻量化，随时随地可以编辑开发，不需要任何插件或者安装工具。

而在今年的 10 月底，**Rive 上线了 Layout 功能，这项新功能让设计师和开发人员能更好协调，从而构建出动态和可交互的布局效果，从而让动画适应任何屏幕尺寸或设备**。

> 当一个动画引擎开始支持响应式布局和交互，那么它将不再只是一个动画引擎。

如下 GIF 所示，在支持 Layout 之后，设计师可以更灵活地去配置动画的布局和过度效果，整个布局的调整和交互（状态机）可以提前都在设计端完成：

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image2.gif)

> Rive 可以提前内置各种状态机和图层，在代码里也可以通过参数修改状态机的状态来改变各种动画或者交互效果。

例如在 Rive 设计端，可以直接完成**动态调整大小的菜单**的支持， 使用 Layouts 之后，对象可以根据屏幕大小进行拉伸、收缩或重新对齐，而且不会丢失对应的动画效果。

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image3.gif)

甚至通过状态机配置，布局可以在如汽车仪表台和手机等不同屏幕尺寸之间平滑过渡，整个 UI 可以在设计端就根据需求配置好响应式布局效果，而在代码层面只需要做简单的配置即可：

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image4.gif)

例如通过 Rive，可以快速生成一个动画按键，按键支持在不同点击状态之间调整布局并展示动画效果，设置支持各种嵌套、混合、匹配对齐、换行和间距等复杂用例的布局。

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image5.gif)

在启用 Layout 之后， Rive 会检测组件宽度、高度或纵横比，从而在 Rive 的状态机中触发不同的状态，让动画或者 UI 在设计阶段即可直接产出，而这一切最终只会生成一个几百K到几M的 `.riv` 文件，最终通过 riv 引擎在平台通过 canvas 绘制。

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image6.gif)

> 不是生成代码而是通过 canvas ，可以保证不同平台的一致性。

使用 Layout 其实并不复杂，例如，在 Rive Edit 里，选中需要需要布局的组件，右键 Wrap in - Layout ，可以看到空间就被添加都 `Row`  组件下，实现了最基础的布局：

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image7.gif)

选中组件，再右键 Wrap in - Layout  ，就可以看到又嵌套了新的 `Row`，通过拖拽可以调整大小和定位，另外还有 `Column`  等可以选择，同时还支持更高级的约束布局等。

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image8.gif)

而在简单的 `Row` 布局里，可以配置定位方式，是否 Wrap ，对齐方式，颜色，圆角，padding，margin 等各种参数，**甚至其实你可以把它当作一个可视化可拖拽的 UI 布局引擎生成器**。

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image9.png)

而在 Rive 里，你可以决定 Layout 中的对象是否参与 Layout 引擎，也就是你可以将一些动画图形（如高度动画化的角色）混合到结构化的布局中：

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image10.gif)

对比没有响应式 Layout 支持的动画效果，可以一目了然看出区别：

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image11.gif)

目前 Layout 支持在 Web 上已经可用，需要在使用时配置为 `Fit.Layout` 模式，配置后如下 GIF 所示，可以看到此时 Button 会根据页面尺寸进行 Wrap 变化：

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image12.png)

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image13.gif)

对比如下所示没有 Layout 的效果，可以看到在支持响应式布局之后，**Rive 已经不在是一个简单的动画框架，它不再只是一个简单的画板，因为 Rive 还支持点击交互，并且支持通过代码动态配置 Text 内容等，所以在一定程度 Rive 也具备了 UI 产生的能力**。

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image14.gif)

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image15.gif)

>  特别是在折叠屏的场景下

可以看到， 在支持 Layout 响应式布局支持后，**Rive 已经开始跳出单纯动画框架范畴，它已经在往 UI 框架和更完善的轻量化游戏框架发展，最主要是，它几乎是全平台全语言支持**。

那你要说它有什么缺点？那肯定是 Rive 是收费的商业化框架，商用场景还是需要付费，另外对于设计师来说，Rive 还是有一点点学习成本，不过瑕不掩瑜，毕竟付费的是公司又不是自己，学习成本是设计师又不是我开发对不？

![](http://img.cdn.guoshuyu.cn/20241031_Rive/image16.gif)

