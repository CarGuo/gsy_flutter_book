# 2024 Flutter 一季度热门  issue/roadmap 进展和个人感触闲聊

因为最近的[《Flutter：听说你最近到处和人说我解散了？》](https://juejin.cn/post/7362901975421337651)相关事件之后，不少人对于目前 Flutter 的一些进度情况比较关心，刚好这里做一个简要汇总，报告几个过去一季度相关的热门  issue/roadmap 情况，另外这些天看文章评论和公众号留言「偶有感触」，文末也就闲聊扯几句。

# iOS Privacy

关于 iOS 5 月份开始强制要求的隐私清单大家可能都有所了解，如果还没了解的可以看过往的详细解释：

- [2024 Flutter iOS 隐私清单上线，你收到 「ITMS-91053」 了吗？](https://juejin.cn/post/7349895521395884069)
- [2024 春季 iOS 的隐私清单究竟是什么？](https://juejin.cn/post/7311876701909549065)

根据目前最近进展，**从 5 月 1 日开始强制执行的一系列内容会仅限于动态框架**，不过预计插件的静态构建要求的强制执行会在未来回归，从这个角度而言，**对于 Flutter  Plugin 的适配要求就降低了不少**，前提是不在 third-party SDK requirements 列表：

![](http://img.cdn.guoshuyu.cn/20240508_issue/image1.png)

![image-20240508075803090](http://img.cdn.guoshuyu.cn/20240508_issue/image2.png)

# Android 14 TLHC 无法显示

这个 issue 是在 [#146499](https://github.com/flutter/flutter/issues/146499) 出现并被修复，它一开始来自 [#139039](https://github.com/flutter/flutter/issues/139039) ，是被当作一个三星特有的问题被提交，PlatformView 相关内容偶尔会无法被正确渲染，而后问题被认为是 Androd 14 系统 bug 而转到 146499 。

这里面有个很有趣的插曲，那就是对方认为这是三星系统的 bug ，开发者只能等待厂商自己修复发布，并且这个问题其实在   Android 15  已经修复，而这样的说法也导致了上述两个 issue 吵到被强制 lock 冷静的情况。

![](http://img.cdn.guoshuyu.cn/20240508_issue/image3.png)

目前官方最终发现，**在 Android 14 平台上遇到的确实是一个 Android 本身的 bug， PlatformView 在内存修剪时，因为会停止从 Android 获取绘制信息，从而导致底层视图虽然存在并且可以交互，但是平台视图会出现透明的情况**，所以这组触发条件并不是 Flutter 独有的，对应使用的 API 对于 Android 原生 App 也会失败。

目前主要触发原因应该是「内存不足」，所以会在后台出现，而又因为  flutter 3.19 开始，对于 PlatformView 不再缓存最后一帧并在 Resume 上绘制它，所以就出现了目前的情况。

所以目前临时 pr 解决方式就是增加 `getPlatformViewsController().onResume()`  和  `resetSurface  `  处理，并且 Flutter 已经和 Android Team 沟通并推进相关 Android 14 的 patch 落地：



![](http://img.cdn.guoshuyu.cn/20240508_issue/image4.png)

# 多窗口

这是一个悲伤的信息，其实从去年 PC 的相关 PM 离职后，PC 的推进就一直「很迟缓」，而多窗口作为「呼声」最大的功能之一，**目前迎来了进度暂停**，个人猜测还是和本次的财务因素裁员有关系，毕竟谷歌这次财务调整下大多数项目都在「开猿截流」，而 Flutter PC 这一年都没「大动静」的情况下，进一步缩减资源保证「核心」roadmap 在所难免，好了，可以继续唱衰😏。



![image-20240508075748495](http://img.cdn.guoshuyu.cn/20240508_issue/image5.png)

> 不少 Flutter PC 用户，都是因为没有多窗口而选择放弃。

# 热更新

Eric 作为 Flutter 创始人之一，在离职后还一直从事 Flutter 相关创业工作，而最近他负责的 Shorebird 终于发布了 1.0 以上的正式版，正式支持 Android 和 iOS 上的 Flutter 热更新支持。

![](http://img.cdn.guoshuyu.cn/20240508_issue/image6.png)

Eric 表示， Shorebird 作为 Flutter 热更新工具，在遵守 Apple 和 Google 商店政策的前提下，可以做到不影响性能（即使在打补丁之后）的体验，因为它不使用热重载（或 Dart 的 JIT 编译器），而是实现了一个 Dart  的特殊解释器来实现。

> Shorebird 是作为 Flutter 的一个分支存在，里面添加了代码推送，而 Shorebird 并不是 Flutter 的替代，而是 Flutter 引擎的替代，**虽然它看起来不错，不过，它是付费的**。

# skwasm

关于 Wasm Native 在此之前其实已经有相关文章，详细可见：

- [Flutter 即将放弃 Html renderer ](https://juejin.cn/post/7355011549827121179)

- [Wasm Native 即将到来](https://juejin.cn/post/7352527589246599178)

其实这也是 Flutter Web 项目的精明之处，「懂取舍，博资源」，在决定推进 Dart 的 Wasm Native 的时候，就决定了 Flutter Web 是在推进一项「前沿」的技术能力，不管最后落地是否如预期，因为它参与推进的 WasmGC 并不只是为了 Flutter Web ，所以它能拥有话题性和资源。

![](http://img.cdn.guoshuyu.cn/20240508_issue/image7.png)

同时，为了更好「集中」资源，Flutter Web 做出了放弃 Html renderer 的议题，可想而知肯定遭到了许多用户的反对，毕竟现在落地的 skwasm 还是存在不少现实问题，但是作为方向性决策，个人觉得对于 Flutter  Web 而言还是挺好的，毕竟 Html renderer 的优势并不大，并且需要适配的资源还更多，至少从目前来讲，Flutter Web 走 Wasm Native 可以避免陷入 PC team 一样「没突破性进展」的困境。

![](http://img.cdn.guoshuyu.cn/20240508_issue/image8.png)

# 最后

更多未来进展和规划，可以看 [Flutter 2024 的路线规划](https://juejin.cn/post/7335067315452428297)  ，另外今年的 Google I/O 也即将到了，感兴趣的也可以关注下：https://io.google/2024/intl/zh/

# 题外话

说个题外话，**其实本次裁员对 Flutter 带来的舆论之所以这么大，很大程度也是 Flutter 这些年的「招黑属性」，互联网喜欢「情绪化」和「论对错」在技术圈更甚，这也是正常情况，有人骂也算是一种活跃**？

目前看，因为财务调整的各项目裁员很正常，开发人员的减少影响肯定有，但关键还是几个核心 PM 是否留任，几乎谷歌开源项目的路线模块是否有资源，都是背靠 PM，比如上面 Flutter  PC 的现状就是一个典型例子。



![](http://img.cdn.guoshuyu.cn/20240508_issue/image9.png)

而作为开发者我个人一直以来的理解，**程序员更多是开发的能力，而不是框架的能力，开发者的职业生涯是阶段性选择开发框架，而不是把 All in 职业生涯依赖在开发框架**。

从我个人感觉，**就是因为这种把职业生涯完全依托在某个框架下的心态，所以很容易衍生出各种「爱恨情仇」**，不管是 Cordova 、React Native 、uni-app 还是 Flutter ，甚至原生、前端，都很容易「沦陷」在这样的情绪下去做表达和释放：

> 给自己加了个标签，并约束自己只能依赖它生存，从而去进行捍卫和否定。

我感觉这也是所谓焦虑的来源，如果做自媒体，确实只要逮着「这一点」去刺激，稍微一有风吹草动，就可以让舆论沸腾起来。

这些年其实我已经很少去讲这些，甚至很少在和人「争论所谓对错」，毕竟我也不卖课不做广告，流量也没什么用处，不管是公众号或者社区文章，更多是记录和常规输出，说服别人又不会带来什么有用收益，除非真的太闲需要消磨时间。

毕竟到了这个年纪，已经没有所谓执着于什么框架的「情怀」，更多还是什么框架比较顺手，目前什么框架更适合 Team Build，业务是否哪个框架更贴合开发。

回想起来，从嵌入式、Android、Cordova、React Native 、 iOS、Weex、uni-app、Flutter、鸿蒙 ，基本这十来年都是这么过来，而这几年输出的内容集中在 Flutter ，只是因为此时业务上更多需要的是 Flutter 。

与我个人而言，我的角度是：**从业多年后，就没觉得自己必须「精通在」或者「忠于」哪个架构，毕竟这些技术都没什么门槛，更多还是开发的能力，解决问题的能力和项目管理的能力，毕竟我总觉得，开发者最有用的经验，并不是数量掌握某个框架的 API**。

总的来说，放过自己，或者就可以看到不一样的世界？

