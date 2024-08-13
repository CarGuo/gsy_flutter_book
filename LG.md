# LG 选择 Flutter 来增强其智能电视操作系统 webOS

可以这个话题会让大多数人困惑，2024 年了为什么还会冒出 webOS 这种老古董？然后 LG 为什么选择 webOS ？现在为什么又选择 Flutter ？

![](http://img.cdn.guoshuyu.cn/20240717_LG/image1.png)

其实早在 Google I/O 发布 Flutter 3.22 版本的时候，就提到了 LG 选择 Flutter 来增强其智能电视操作系统 webOS，并预计在 2025 年发布。

而在 2024/7/15 的时候，LG 官方也正式官宣："New and Successful Experiment of webOS with Flutter for Better Performance and Playful Experience" 。

> https://webostv.developer.lge.com/news/2024-07-15-new-and-successful-experiment-of-webos-with-flutter

*那么什么是 webOS ？它为什么又是一个 TV 的 OS* ？

WebOS 顾名思义是 Web 操作系统的缩写，是 LG 独家拥有的基于 Linux 的操作系统，主要集成到他们的智能电视系统中，所以它是属于**基于 Linux 内核的多任务智能电视操作系统**。

但是其实它并不是 LG 发起，WebOS 最初由 Palm 于 2009 年作为移动操作系统推出，最初在多款 Palm 和 HP 智能手机中投入使用，但是众所周知，它凉了，**于是 2013 年，LG 从 HP 收购了 webOS，导致 HP 决定将 webOS 开源**

后续，在 LG 的主导下，WebOS 经过进一步修改，转变为智能电视操作系统，于是 WebOS TV 就诞生了，此后 LG 的 TV 基本路线定为 webOS ，在应用层面，WebOS TV 以基于 Web 的技术为基础。

作为 2024 年仅剩在 TV 领域还能“孤身”抗衡 Android TV 的产品，其存在的地位主要还是依托于 LG 本身的市场占有，WitDisplay消息，**LG 2023 年在全球 OLED 电视市场以 53% 的占有率排名第一，LG 电子已经连续 11 年在 OLED 电视市场排名第一**，而在全球 TV 的本身占有率上， LG 也占据了一席之地：

> 注意，这里的第一仅是 OLED 市场。

![](http://img.cdn.guoshuyu.cn/20240717_LG/image2.png)

例如在 webOS 上，  LG 的 Magic Remote  可以让你感觉就像在 Mac 或 PC 上使用鼠标一样使用遥控，这算是 LG TV 的特色之一，当然，也是由于 webOS ，目前 OS 也缺乏对侧载应用的支持。

![](http://img.cdn.guoshuyu.cn/20240717_LG/image3.png)

其实 LG 在 2021 年就开始重新准备调整 TV 的内置软件，主要是希望改善应用启动和运行时的性能，在原本的场景下，**webOS 下的大多数 App 都是使用 React 开发**，LG 的开发团队对于 React 的开发效率十分满意，但是在在启动时间、内存消耗和响应能力的进一步优化出现了阻碍。

尽管在经过大量复杂的优化后，产品达到了足够好的性能基准，但 LG 开始寻求另外可以实现目的且成本更低的技术。

![](http://img.cdn.guoshuyu.cn/20240717_LG/image4.png)

而此时，**一位工程师建议用 Flutter 重写 LG 上的日语电子节目指南 (EPG)，而完成后的第一个 Flutter 原型轻松超越了之前 LG 团队的目标基准，无需任何优化**。

> 在使用 Flutter 重写的版本，启动速度比原始应用快两倍，运行时内存消耗更少，使用起来更灵敏，而目前这款 Flutter 应用目前已安装在日销售的 2024 台 webOS 电视中。

随着日语 EPG 重写成功， LG 决定使用 Flutter 重写更多应用，包括用户在使用 LG 电视时与之交互的主要软件。

所以 LG 最终决定在 2025 年推出的全球电视中全面引入 Flutter 应用，并在 2026 年推出更多 Flutter 应用，由 Flutter 驱动的 webOS 版本也将通过 `webOS Re:New` 程序在之前的型号上运行。

> 总的来说，这将使 Flutter 进入全球消费者家庭中数千万台 LG 电视。

此外， LG 希望发布工具来帮助所有 Flutter 开发人员参与到 LG 电视开发里，例如：**通过 Flutter 将高性能休闲游戏直接带入 LG 电视**，例如采用 Flutter 的 GameToolkit 或者 Flame 开发游戏，如果以后支持 Impeller ，也许还会有 3D 支持。

> 如果对于这个感兴趣的，可以看看 LG 目前还在举办一场的黑客马拉松（一等奖 10 万美元）：https://weboshackathon.lge.com/，https://webostv.developer.lge.com/develop/flutter/how-to-build-flutter-app-for-webos，目前需要使用  Flutter webOS CLI 和 Plugins  去构建 webOS TV 得 App，不过目前只有与 LG Electronics 签署了保密协议的开发人员才能下载 Flutter webOS SDK（CLI、插件、指南等）。

总的来说，LG 是 Flutter 在 TV 领域的一次新的尝试，并且它是在脱离了 Android 平台的场景下实现的支持，虽然 webOS 并不是什么流行的系统，但是这也体现出了 Flutter 的特点：可以用较低的成本实现较好性能的跨平台。
