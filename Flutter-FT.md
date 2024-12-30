# FlutterInProduction ，2024 年末，让我们看看 Flutter 现在的生态数据

Flutter 从立项到现在也有 10 年了，从 2014 年作为代号为 “Sky” 的 Google 实验框架开始，而 2018 年 Flutter 正式推出 1.0 版本， 到现在也有六年：

![](http://img.cdn.guoshuyu.cn/20241218_FT/image1.png)

而在超过 1,400 多名贡献者的努力下，还有 10,000 多名包发布者 50,000 多个社区 package 的协助下，Flutter 才有今天的成长：

![](http://img.cdn.guoshuyu.cn/20241218_FT/image2.png)

根据官方数据，**Flutter 在全球拥有超过 100 万月活跃开发人员，并为近 30% 的新 iOS 应用程序提供支持**，超过 90,000 名开发人员参与的 60 多个国家/地区的 Flutter 本地社区线下会议，而根据  [Apptopia Inc.](https://apptopia.com/) 的数据显示：

> “Apptopia 跟踪 Apple AppStore 和 Google Play Store 中的数百万个应用，并分析和检测哪些开发人员 SDK 用于创建这些应用，Flutter 是跟踪的最受欢迎的 SDK 之一：在 Apple AppStore 中 它的使用量从 2021 年所有跟踪免费应用的 10% 左右稳步增长到 2024 年所有跟踪免费应用的近 30%！

在本次 FlutterInProduction 里也介绍了相关一些典型的国外用户，例如：

获得 「Red Dot Design Award」, 「The Webby People’s Voice Award,」 「iF Design Gold Award」 相关奖项的航空公司  SAS 就采用 Flutter 作为他们 App 的技术栈 ：

![image-20241218090403948](http://img.cdn.guoshuyu.cn/20241218_FT/image3.png)

而更为全球熟知的环球影城，也通过 Flutter 实现了应用大小的减小，同时还将应用崩溃率大幅降低，从而降低了他们的总体成本。

![](http://img.cdn.guoshuyu.cn/20241218_FT/image4.png)

而在之前也说过，LG 选择 Flutter 来增强其智能电视操作系统 webOS，这也是除了丰田之外，少有将 Flutter 作为小众平台开发 SDK 的企业，**而 LG 2023 年在全球 OLED 电视市场以 53% 的占有率排名第一，LG 电子已经连续 11 年在 OLED 电视市场排名第一** 。

![](http://img.cdn.guoshuyu.cn/20241218_FT/image5.png)

另外，对于一些外包形态企业，例如 App agency 的 Superformula ，它从 2020 年 8 月以来一直使用 Flutter 构建，其中包括使用 Flutter 为 MGM Resorts 的 400+ 家餐厅重振了数字用餐体验，基于 Flutter 的新 MGM Rewards 应用在短短 4 个月内就完成了重建，将代码总量减少了一半，并将交付速度提高了 4 倍。

![](http://img.cdn.guoshuyu.cn/20241218_FT/image6.png)

> Superformula 生产力的一个核心推动因素是能够在移动设备、平板电脑的和 Web 的工具之间共享代码。

最后还有如美国汽车保险公司 GEICO 也提到过如何使用 Flutter 提高工作效率，他们能够改变组织的结构，以便 UX 团队能掌握在多个渠道的 App 体验，从而减少相同功能的不同实施之间的偏差。

![](http://img.cdn.guoshuyu.cn/20241218_FT/image7.png)

总的来说，本次 FlutterInProduction 介绍的产品并不多，其他一些耳熟能详的品牌，在过去也有相关 Flutter SDK 的影子，他们也许不是主力 Flutter 开发，但是 Flutter 也出现在他们 App 里，例如：

- 微信小程序的 skyline 引擎
- 起点在鸿蒙开发里的 Flutter 适配
- 优酷视频、天猫精灵、360智慧生活、WPS、企业微信、夸克、小爱音箱、百度网盘、钉钉、阿里云盘、UC 等都有 Flutter 影子

![](http://img.cdn.guoshuyu.cn/20241218_FT/image8.png)

更多详细 case ，也可以通过官方的 https://flutter.dev/showcase 去查阅：

![](http://img.cdn.guoshuyu.cn/20241218_FT/image9.png)

![](http://img.cdn.guoshuyu.cn/20241218_FT/image10.png)

![](http://img.cdn.guoshuyu.cn/20241218_FT/image11.png)

![](http://img.cdn.guoshuyu.cn/20241218_FT/image12.png)

![](http://img.cdn.guoshuyu.cn/20241218_FT/image13.png)



未来，Flutter 将聚焦更多可能的同时，也优化本身的产品体验：

- **更深的 iOS 保真度：**将继续通过扩展 Cupertino Widget 来提供更高的 Apple 设计语言保真度，采用更新的 Apple 生态系统标准，例如 Swift Package Manager，这在 [3.27 就有所体现](https://juejin.cn/post/7447097960011923506)
- **无缝平台集成**： 之前一直提到过的新互操作性方法 ，Dart 直接和本机原生语言互操作 ，从而简化 Dart 对 C、Java、Kotlin、ObjectiveC 或 Swift 中提供的特定于平台的 API 的访问。
- 更多 Dart 语言特性的优化
- **开发人员工作效率增强**，例如之前提到过的[实时预览](https://juejin.cn/post/7441006286765064218)

最后，虽然 Flutter 还有许多坑在填，例如还在努力中的 [PC 落地推进](https://juejin.cn/post/7431894641426202636)，但是按照现在的节奏看，2025 落地应该问题不大，所以，相信未来 Flutter 会更加完善一些短板，虽然路坎坷，但是终究有人在坚持。

> 参考链接 https://medium.com/flutter/flutter-in-production-f9418261d8e1