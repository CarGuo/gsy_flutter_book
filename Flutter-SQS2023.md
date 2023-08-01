![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image1.png)

# 社区说|Flutter 一知半解，带你拨云见月

Hello，大家好，我是 Flutter GDE 郭树煜，今天的主题是科普向的分享内容，主要是带大家更全面的去理解 Flutter ，尽可能帮助大家破除一些误解，**分享内容不会特别长，但是应该会帮助你从新认识下 Flutter** 。

Flutter 发布至今大概有 6 个多年头，相信现在大家对于 Flutter 也不至于太陌生，但可能有的人对于 Flutter 还处于「一知半解」的状态，所以本次分享的主要目的是给大家普及一些 Flutter 常识，解读一些 Flutter 常见的误解，带你拨云见月，重新认识 Flutter 。

> 所以今天不讲技术实现，只谈风花雪月。

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image2.png)

# 从谣言开始

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image3.png)

那首先我们从“谣言”开始，其实 Flutter 从出道以来就一直备受争议，不管是写法还是语言，都在一段时间内饱受“歧视”，如今再回过头来看，会发现这对于 Google 来说是「基础操作」：

> **就像 Android 盘活了 Kotlin 和 Gradle 一样，Flutter 也盘活了 Dart ，它们之间有着相辅相成的关系**。

Dart 作为 Flutter 的开发语言，它原本处于竞争失利的「雪藏项目」，所以它的没什么历史包袱，可以轻装上阵配合 Flutter 的脚步。

尽管一开始选择 Dart 会导致和 JS 与 Kotlin 等的生态分裂而带来「抵触」，但是正如前面所示，在这一方面，谷歌无疑很擅长盘活，而 Dart 从 Dart 1 到 Dart 3 ，也很好的配合着 Flutter 的脚步在逐步成长。

> 当然，另一个方面，这和传闻中 Dart 项目组就在 Flutter 隔壁大概有关系，至少沟通方便。

当然，Flutter 的跨平台设定也给它带来了诸多“负面” 的 buff，其中一些谣言在最初的时候可以说十分盛行，例如：

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image4.png)

其实大家只要稍微思考一下，如果因为是谷歌的技术，就无法上架 iOS 的 App Store 这明显就不合理，而这个谣言更多来自于：

> 因为 Flutter 开发会让 iOS 原生开发流失，所以苹果需要维护自己的开发者。

这里其实是利用了大多数人的误区，不管是使用 Flutter 还是 React Native ，你只要开发 iOS  和上架 App Store ，就不可避免需要 Xcode 和 MacOS ，这对于苹果来说并不是坏事，因为可能更多不是全职的 iOS 开发会投入到 Apple 的体系里，另外：

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image5.png)

Flutter  虽然帮助完成了上层的 UI 和逻辑业务，但是底层交互，构建打包和平台支持都离不开原生开发的支持， 所以：

> Flutter 会在一定程度挤压 iOS 的生态，但是从另一个角度，也会让其他生态的人接触和使用 iOS ，**甚至 Flutter 的 Plugin 一定程度还在为 Swift 的推广提供支持**。

甚至之前还有因为 “Flutter 使用的是 Material 风格的 UI ，所以无法上架” 的言论，按照这个理论，那么作为头部应用的 Twitter ，浓厚的 Material 风格产品应该也在此列才是，并且 Flutter 也有 Cupertino 风格的控件，只是没想到产品设计风格都会被用来变成一个打击的理由。

> **用 Flutter 开发出什么风格的应用，完全看你的使用方式**。

事实上从 Flutter 的 UI 实现上，Flutter 和 React Native 的不同之处就在于它的控件都是独立于平台的自渲染，所以它更像 Unity 一样的独立游戏引擎，既然 Unity 都不是问题，那么 Flutter 自然也只是 App Store 技术生态下的一个小点缀。

**更何况 App Store 的核心是应用提成**，上架应用越多，需要经过平台的抽成可能就越多，只要你符合  App Store 的 Guideline 要求，你用什么技术上架并不会成为上架不了的原因。

最后，再介绍一个新鲜落地的消息，前几天微信发布了全新的小程序新渲染引擎 Skyline 正式版，宣称加载速度提升 50% 以上，而网友通过抓包，确认是 Skyline 的渲染是 [flutter 绘制方案](https://gist.github.com/OpenGG/1c71380dd1401b7c93d39294772344fe) 。

| ![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image6.png) | ![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image7.png) |
| ----------------------------------------------------------- | ----------------------------------------------------------- |

> 微信小程序使用 Flutter 渲染，**更主要是其渲染更加精细可控，同步光栅化的策略，可以更好解决局部渲染、原生组件融合**等问题。

当然，这里微信小程序使用的是 flutter 的渲染模式，而不是 flutter 开发方式，开发依然是原来的套件，只是 Skyline 做了一层转化，这也是大厂对于 Flutter 常见的玩法。

# Flutter 的定位

接下来就不得不聊一聊 Flutter 的定位，其实 Flutter 在发布之后，因为跨平台的“招黑” 属性，自然不可避免会有围绕跨平台来做焦虑的自媒体，这和前段时间 AI 盛行的“焦虑”氛围类似。

既然前面有“尬黑”，那么肯定也有“尬吹”的存在，如下图就是 Flutter 前期最常被用的“尬吹”场景：

> 这些“尬吹”不仅会给人带来焦虑，更会激起大家的抵触心理，潜移默化让人觉得，Flutter 的定位就是过来抢夺 Android 和 iOS 生态，是不死不休的局面。

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image8.png)

但是其实 Flutter 的定位并非如此，虽然 Flutter 的发展在不可避免会有挤压到部分原生开发的情况，但是 Flutter 的实际目的并不在此，或者说我们的视角和 Flutter 团队并不在一个层面。

举个例子，在之前我发起过一个简单问卷，如下图所示，关于「Flutter 你更常用的 IDE 工具」的统计下，有 71.9% 选择是使用 Android Studio 作为开发工具。



![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image9.png)

但是对于官方统计的数据，可以看到这个情况只能对应到 “部分” 场景，例如 “软件工程师”和“技术主管” 等头衔的人会更可能使用  Android Studio 开发 Flutter 。

> 这在我们的认知里貌似没什么问题，因为感觉 flutter 开发很多都是从 Android 开发转换过的，所以更习惯用 Android Studio 好像没什么毛病。

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image10.png)

但是其实总体趋势还是在 VS Code ，因为在全球，除了开发者之外，还有使用 Flutter 的「非开发者存在」，他们的角色可能是学生、设计师、PM 等非专业开发人员，而 Flutter 团队的理念是：

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image11.png)

**Flutter 不会在专业和非专业开发人员之间划出一条强硬的界限，因为今天的许多学生和业余爱好者开发人员明天也可以成为专业人士**。 

> 例如 Flutter 上饱受争议的 GetX 的作者，他主职业是一个名律师，但是热爱开发，他花了十年时间从事网络安全和网络犯罪工作，后面开始学习了 Dart 语言，然后学习了 Flutter，进而开始从而开源活动。

**所以官方的市场定位绝不是去掠夺和转化 Android 、iOS 、Web 和 PC 等原生开发者**，它有更多的愿景，是希望可以提供给非专业人士拥有开发的能力，所以 Flutter 的发布会上，也多次提及了 FlutterFlow 等地代码平台，另外也有类似 Daro 的 Flutter 的低代码平台。

Flutter 作为跨平台 UI 框架，它提供的是全平台的 UI 和逻辑支持，通过降低开发门槛和提高代码复用率来拓展技术能力，这是 Flutter 团队的愿景，只是回归到我们开发者的视角，就可能变成一种挤压。

不过另一方面，随着技术的成熟，开发的门槛本来就会越来越低，例如：

> 现阶段 Android 和 iOS 工作生态的变化，并非归咎于跨平台框架的出现，而是技术越来越成熟，资源越来越多，开发门槛也自然随着下降，现在开发 Android 起手一套官方 Jetpack 体系，完善程度确实不像曾经 13 年那样什么都需要靠“自己”。

随着设备的硬件支持也越来越强，官方配套越来越齐全，跨平台的需求自然也就越来越多，因为提高资源的重复利用是生产中的一个必然趋势，所以就像 Compose 也在走跨平台的支持

> 所以从我的角度去看，跨平台并不是完全是挤压，相反还有帮助 A 平台的开发者可以接触到 B 平台的东西，反之也是，一定程度也是提高了 AB 两个平台的活跃能力。

另外，Flutter 这个定位从最近的 Web 更新也可以看出来，在 Flutter 3.10 关于 Web 的发布里，官方就对 Flutter Web 有明确的定位：

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image12.png)

> **“Flutter 是第一个围绕 CanvasKit 和 WebAssembly 等新兴 Web 技术进行架构设计的框架。”**

Flutter 团队表示，**Flutter Web 的定位不是设计为通用 Web 的框架**，类似的 Web 框架现在有很多，比如 Angular 和 React 等在这个领域表现就很出色，而 Flutter 应该是围绕 CanvasKit 和 [WebAssembly](https://link.juejin.cn/?target=https%3A%2F%2Fwebassembly.org%2F) 等新技术进行架构设计的平台。

所以 Flutter 本身的定位就不是去竞争和转化开发者，例如在 Web 领域，它更多是对前沿技术的尝试：Dart 已经开始支持直接编译为原生的 wasm 代码，一个叫 WasmGC 的垃圾收集实现被引入到标准里，未来因为 WebGPU 的落地，**WebGPU + WebAssembly 在未来也可能让 Flutter Web 支持全新的 Flutter Impeller 引擎**。

> PS：这里的  WebGPU  来自 W3C 制定的标准，与 WebGL 不同，WebGPU 不是基于 OpenGL ，它是一个新的全新标准，可以提供在浏览器绘制 3D 的全新实现，它属于 GPU硬件（显卡）向 Web（浏览器）开放的低级 API，包括图形和计算两方面相关接口。

所以 Flutter 可能会转化一些原生开发，但是并不会冲击原生开发，Flutter 的愿景和目的都不是这个。

# Flutter 的局限和未来

说了那么多正面的，那 Flutter 有什么样的局限？其实是框架就会有它的局限性，而 Flutter 的局限很大程度来自它的优势。

这里我们简单回顾下跨平台的框架的发展：

- 最初的跨平台框架如 Cordova ，是通过 `WebView`  加载本地 h5 资源实现 UI 跨平台，然后 js bridge 和原生平台交互调用 Plugin 来实现原生调用
- 第二阶段是为了性能而出现的  React Native 和 Weex ，通过统一的前端标签控件转化为原生控件进行渲染，从而提高了性能，不过因为是通过原生控件渲染，所以存在 UI 会有一致问题和兼容适配的成本。
- 第三阶段出现在了 Flutter 上，Flutter 通过独立渲染引擎，利用 GPU 直接渲染控件，从而避免了代理渲染的性能开销，同时也保证了不同平台上 UI 一致。

这么看好像 Flutter 更优秀，那为什么说局限性？

## 局限

因为这种独立渲染 UI 的实现，让 Flutter 的 UI 渲染树脱离了原生平台，这时候，如果你需要在 Flutter 里接入原生控件，那么接入成本和对性能的影响都会比较大。

事实上开发 App 就不可避免需要接入 WebView 、地图、广告、视频等原生 UI ，所以在很长一段时间， Flutter 每个版本都在为接入原生控件而努力调整，比如 Android 至今已经有个三次较大的 PlatformView 接入变化，目前基本上算是可以实现接入使用，但是还存在一些局限，例如：

> 3.10 ，当 `PlatformViews `出现在屏幕上时，Flutter会限制 iOS 上的[刷新率以减少卡顿](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fflutter%2Fengine%2Fpull%2F39172)，当应用显示动画或可滚动时，用户可能会在应用出现 `PlatformViews` 时注意到这一点。

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image13.png)

详细的我们就不展开，感兴趣可以看我理解发过的文章：

- [Flutter 3.0下的混合开发演进](https://juejin.cn/post/7113655154347343909)

- [告别 VirtualDisplay ，拥抱 TextureLayer](https://juejin.cn/post/7098275267818291236)

- [Flutter 深入探索混合开发的技术演进](https://juejin.cn/post/7093858055439253534)

另外还有的局限就是「热更新」，虽然说 Flutter 不是不能支持热更新，甚至 Flutter 团队的元老之一 Eric 在离职之后，也创立了 [shorebirddev](https://github.com/shorebirdtech/shorebird) 来支持 Flutter 热更新，但是 Flutter 本身的属性，其实非常不适合热更新。

> 因为 Flutter 在 Release 下是编译为 AOT 的可执行二进制代码，而下发二进制代码本来就是 Google Play 和 App Store 的禁止行为，当然国内也有很多通过下发各种文本，然后通过映射或者代理的方式去更新 Flutter ，不过这种操作一定程度上提高了维护成本和降低了性能。

而 shorebirddev 就更大胆，直接 fork 了一个 Flutter 分支进行魔改，从而支持热更新的能力，为此目前还不支持使用了 shorebirddev 的 Flutter App 去上架市场。

> 当然，未来有可能会支持，比如官方已经表示可以上架的 iOS 正在支持中。

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image14.png)

还有一个局限就是文本排版和编辑，Flutter 在文本排版上的局限，因为是全新的独立引擎，所以它拥有一套自己独立的文本渲染和排版逻辑，而和发展沉淀多年的 Web 排版相比，可以说是足足的「萌新」，不管是在多语言中文的兼容上，还是在字体字形的问题上，Flutter 都存在需要时间去调整的细节问题。

> 甚至因为最近换了新的 Impeller 引擎的原因，文本上需要修复的问题会更多

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image15.png)

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image16.png)

例如 Impeller 标签下就有很多关于文本和排版相关的问题。

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image17.png)

另外，前面我们介绍过，未来 Flutter Web 更多会投入到 Wasm 里，这也会引起一些兼容问题，例如这个页面是采用 wasm 渲染的 Flutter Web 页面，但是当我们用插件翻译页面内容时，可以看到只有标题被翻译了，主体内容并没有。

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image18.png)

这是因为此时 Flutter Web 的主体内容都是 canvas 绘制，没有 html 内容，所以无法被识别翻译，另外如果你保存或者打印网页，也是输出不了完整 body 内容。

另外一个 Web 上的局限就是 SEO ，Flutter 会让谷歌在查看网站并认为它是 3-8mb，如果使用 google 洞察力测试一个网站，会需要你的网站应该小于 1.8mb，并且必须在 1 秒内加载才能排名。

Google 和 Bing 这样的搜索引擎会根据速度、编程语言、图像自动大小、CDN 和最终内容对网站进行排名，Google 要求机器人视图和用户视图相同。

> 例如使用 [seo_renderer](https://pub.dev/packages/seo_renderer) 可能会违反谷歌关于伪装的 SEO 指南，虽然看起来本质上是在 `Text `中添加“替代文本”，但对于 Googlebot 返回的是完全不同的 HTML 内容，这就是问题的症结所在。

最后， Flutter 开发的中后期肯定还是需要原生开发，这个是无法回避的问题，就算社区插件生态再丰富，总归抵不住产品和老板的天马行空，比如：

> 虽然社区已经有完善的第三方生物认证插件，但是我最终不得不 fork 一个份自己过来修改已满足产品的特殊需求。

所以 Flutter 本身就具备它的局限性，即是优点也是缺点，是否选择 Flutter 主要从你的产品定位和需求出发去判断。

## 未来

最后不得不谈 Flutter 的未来，Flutter 目前最大的改动就是全新的底层  Engine： Impeller 。

作为 skia 的替代，这是 Flutter 团队发展的必经之路，就如前面所说， skia 本身有着许多历史包袱和平台需要考虑，没办法和 Flutter 步步紧扣，所以 Flutter 选择开始全新的自研 Impeller 是一个非常重要的投资，它也给了 Flutter 团队更多的可能。

> 正如 React Native 也自研了 Hermes ，然后 JSI 开始支持同步调用一样。

目前 Impeller 已经在正式版支持 iOS ， Android 也正在适配，它也带来了不少「阵痛期」的问题，比如一些渲染字体的问题，但是这个投资带来的收益是可观的，也许未来还可能诞生一个全新的通用  “skia” 。

另外就是游戏，近两年 Google I/O 都通过 Flutter 发布了对应的游戏，例如 Pin 和 Card 游戏，这两个游戏也展示了 Flutter 在游戏领域的可能，Flutter 的天然设定让它有用和 unity 相似的场景，所以通过 Flutter 来实现游戏也是官方展示的另外一种可能。

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image19.png)

![](http://img.cdn.guoshuyu.cn/20230728_JJ/image5.gif)

可以看到 Flutter 在这两年的 I/O 上，把 Flutter 的游戏能力发挥的很不错，从整体 UI 和游戏体验上都很优质，特别是今天的游戏结合了 AI 生成和设计，可玩度得到了进一步提升。

最后就 Flutter 团队在 Flutter Forward 上展示的 3D 能力，因为在此之前 skia 是 2D 引擎，所以无法完整支持 3D 的场景，而现在 Flutter 为我们展示了它未来 3D 渲染的可能，虽然还只是一个 Demo ，属于画饼阶段，但是这也是 Flutter 未来的一个期待。

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image20.gif)

![](http://img.cdn.guoshuyu.cn/20230801_SQS2023/image21.gif)

所以未来 Flutter 上的 3D 游戏支持也可以期待，不过前提也是 Flutter 能把现在已有的坑都填完先。

好了，今天分享的内容就这些，谢谢大家。