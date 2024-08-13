# Flutter CTO  2024 报告出炉解读，看看有没有你关心的问题

Flutter CTO  2024  是由 LeanCode 主导进行的一次技术调查报告，**本次报告数据来自 70 多个国家的 300 名 CTO、CIO 和技术主管，报告包含了 52 个问题、 7 次人物面对面访谈和 10 多位合作伙伴的协助** 。

报告里 85% 的受访者拥有超过 5 年的⼯作经验，超过 50% 的受访者从事过 IT ⾏业超过 10 年，40％ 的受访者在拥有 5 名以上开发⼈员的移动团队中⼯作，22.8％ 的受访者在拥有 200 多⼈的组织中⼯作。

![](http://img.cdn.guoshuyu.cn/20240704_FCTO/image1.png)

另外，报告里 30% 的受访者来⾃拥有超过 10 万⽤⼾的应⽤，13% 来⾃拥有超过 100 万⽤⼾的应⽤。

![image-20240703181631319](http://img.cdn.guoshuyu.cn/20240704_FCTO/image2.png)

报告内容一共有 50 页，这里主要汇总一些我个人或者大家比较感兴趣的内容，例如：**担⼼⾕歌会放弃 Flutter **。

在关于 Flutter 的最⼤争论里，**56% 的受访者表⽰担⼼⾕歌会停⽌⽀持 Flutter** ，关于这个问题，[谷歌的 Craig Labenz 在访谈](https://youtu.be/UcJSgzztgDI)解答了这个问题。

![](http://img.cdn.guoshuyu.cn/20240704_FCTO/image3.png)

Craig Labenz  表示，关于⾕歌会否淘汰 Flutter 是⼀个永恒的问题，从 Flutter Team 看来，他认为这不会是 Flutter 的问题，**因为维持 Flutter Team 不需要⾕歌花钱，同时目前 Flutter 项目对于 Google 是带来收入** ：

- Google 内部有很多应用基于 Flutter，Flutter 也帮助 Google 减少了开发成本，(个人补充)如： Google Pay、Google Earth、Google Ads、Google Classroom、YouTube Create、Google Cloud 、Google One、Crowdsource、Google Analytics、FamilyLink ·····
- 从团队规模上，Dart 和 Flutter team 本身不并不小，但是没有出现亏损的负担状态
-  Flutter 为 Firebase 和 Cloud 带来了配套和流量，甚至 AI 的使用，统计 Flutter 的开发者(海外)更愿意使用 Google 的配套产品

![](http://img.cdn.guoshuyu.cn/20240704_FCTO/image4.png)

**作为企业 ，Flutter 是赚钱的，并不是一个纯开销的状态，所以 Flutter 并不会成为 Google 的负担：And despite that does not cost Google money and is used**。

> 另外我个人补充，在 [Flutter consultants](https://flutter.dev/consultants) 的介绍，目前已经有 70 多家顾问企业，其中包括 IBM、baseflow ，也包括 VGV 等依赖 Flutter 的方案企业。

例如在本次报告里，虽然 AWS 是最受欢迎的云提供商，但 Firebase + Google Cloud 的占比也不低，Flutter 为 Google 本身带来的利润是很可观的。

> 其实可以看到，基本大部分 Flutter 版本里，都会有关于 Firebase SDK，AI SDK 等第一时间跟进。

![image-20240703182141620](http://img.cdn.guoshuyu.cn/20240704_FCTO/image5.png)

同时在后端语言和 BaaS 选择上，报告显示 Firebase 显然是 Flutter 的最占比选择，而这里面居然还有 16% 会用 Dart 做后端服务。

![](http://img.cdn.guoshuyu.cn/20240704_FCTO/image6.png)

另外在对于前 Flutter 创始人之一 Eirc 的访谈中， Eirc 也表示：

> “自 Flutter 创立以来，Flutter 在 Google ⽣态系统中成⻓，以解决 Google 的问题，当时对于某些外部企业，Flutter 也存在了一些缺失，例如热更新，这也是他创建 Shorebird 的动⼒ “

而在报告里，在全球使⽤ Flutter 的前五⼤⾏业中，⾦融、医疗、生产、电子商务相关应⽤场景最多，而图片、视频相关 App 出现次数很低，至于为什么这也和 Flutter 本身的图像处理能力太弱有关系。

![](http://img.cdn.guoshuyu.cn/20240704_FCTO/image7.png)

而在关于使用 Flutter App 的公司所采用开发语言的占比上，可以看到出了 Dart 之后，最多的还是 JS 等前段语言，不过有趣的是，**Kotlin 稳居 Flutter 开发者第⼆喜欢的语⾔之列，排名第三的是 Swift** 。

![](http://img.cdn.guoshuyu.cn/20240704_FCTO/image8.png)

同时上下两个数据都可以看出来：**其实 Flutter 领域目前最多的还是移动 App 的需求，不过 Web 需求也在增长**。

![image-20240704081417131](http://img.cdn.guoshuyu.cn/20240704_FCTO/image9.png)

当然，随着 Flutter Web 的发展，其中 Web 问题也是最突出的问题，相关的⽤⼾体验是最常被提及，而目前 Flutter 对此的解决方向是： [Flutter for Web  WASM Native](https://juejin.cn/post/7368820207576383498) 。

![image-20240703181931466](http://img.cdn.guoshuyu.cn/20240704_FCTO/image10.png)

在访谈里提到，**Flutter 早期的 Web 很不起眼 ，但现在增⻓了三倍，而未来也正在推进三个用于完善 Web 的不足的功能（SEO、JavaScript 中的热重载和 WasmGC）**，另外，在最受期待的功能中，5 个中有 3 个与 Flutter for Web  相关，可以看到 Flutter Web 已经在全球成为 Flutter 的另一个增长项。

![](http://img.cdn.guoshuyu.cn/20240704_FCTO/image11.png)

同时，如何选择正确的 Flutter 架构是对于初始选择 Flutter 的团队⾯临的最⼤问题，例如有 Bloc、Riverpod、Provider 等选项，很容易陷⼊困惑并被分析所困扰。

另外安全、性能和原⽣集成也是 Flutter 里大家最常见的技术问题。

![](http://img.cdn.guoshuyu.cn/20240704_FCTO/image12.png)

**Flutter CTO  2024 报告在某些程度上很好展示了 Flutter 目前在全球的状态**，虽然他的样本不大，只来自 300 个全球不同国家的技术技术 Leader ，「管中窥豹」虽不严谨，但也不失为一种参考，相信 Flutter 本身的盈利状态也可以给予合作伙伴的信心，感兴趣看原文的可以通过下方链接查阅：

> 报告地址：https://leancode.co/LeanCode_Flutter_CTO_Report_2024.pdf?utm_campaign=Flutter%20CTO%20Report&utm_medium=email&_hsenc=p2ANqtz-95ORDXSpybyeGr8sjVRZIADWdw93kO3k6LGYkv4Pdux-UJ58f_1tHwxbNmQW4yKxxysk219aAVSMkGufG1DMxTeD0d-w&_hsmi=90528309&utm_content=90528309&utm_source=hs_email










