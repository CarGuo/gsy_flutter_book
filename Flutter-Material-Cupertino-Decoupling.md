# Flutter  material/cupertino 解耦最新进展，已经在做新样式了

下个月就要发布新的 Flutter 版本了，今天看了下 Flutter 样式解耦的进度，看起来进度还挺可以。上个月那个 60 多万行改动的 [*#11888 Decoupling recopy*](https://github.com/flutter/packages/pull/11888) 已经合并了，也就是**所有 Material/Cupertino 的源码、测试、examples、dart fixes 整体搬到 `flutter/packages`。**

![](https://img.cdn.guoshuyu.cn/image-20260707144941408.png)

> *之前#11669、#11887 有好几次尝试都失败，这次 "recopy" 总算是一次性干净地搬完*。

目前 `material_ui` 和  `cupertino_ui` 已经是具备完整源码的独立样式包，然后项目已经开始跑各种 test ，同时版本依赖上：

```
version: 0.0.2      # 没发布到 pub.dev（publish_to: none）
flutter: ">=3.44.0" # 依赖最低 Flutter 3.44
```

不过 flutter/flutter 里的原始代码还在，只是暂时冻结，这部分代码估计还是需要等到 package 完全稳定后才会删除切换。

> 新增的 *[#12119] `[material_ui, cupertino_ui]` Localizations*，多语言本地化迁移算是是解耦最后模块了，这部分处理完后基本就可以完全进入测试收尾了。

另外  Material 3 Expressive 的相关支持也开始了，目前几个 PR 算是开启了 M3 Expressive  的第一批控件起步，至少比起 Liquid Glass 来说进度快了不少：

| PR                                                       | 内容                                                         | 状态          |
| -------------------------------------------------------- | ------------------------------------------------------------ | ------------- |
| [#12093](https://github.com/flutter/packages/pull/12093) | Add M3 Expressive IconButton                                 | open，5 天前  |
| [#11931](https://github.com/flutter/packages/pull/11931) | Add global Material style variant（Expressive 风格切换机制） | open，19 天前 |
| [#12121](https://github.com/flutter/packages/pull/12121) | Add helper methods in gen_defaults template（为批量生成 Expressive token 准备工具） | open，今天    |
| [#12122](https://github.com/flutter/packages/pull/12122) | Migrate AppBar M3 template                                   | open，今天    |

但是 iOS 26 Liquid Glass 风格的暂时还么新进展，按照之前官方的说法，至少需要等到 Package 稳定了才会开始，或者苹果开始强制要求适配了，官方才会着急。

不过至少目前来看整体进度还是可以的：

| 类型                                 | 状态                       | 比例      |
| ------------------------------------ | -------------------------- | --------- |
| **源码迁移**（Material + Cupertino） | 完成                       | **100%**  |
| **测试重新启用**（unskip）           | 完成（#188395 已关闭）     | **~100%** |
| **API 文档（@example 指令）**        | 收尾中                     | ~90%      |
| **本地化（Localizations）**          | 进行中（PR #12119 open）   | ~80%      |
| **发布到 pub.dev**                   | 未完成（publish_to: none） | **0%**    |
| **M3 Expressive 新功能**             | 刚开始                     | <5%       |
| **iOS 26 Liquid Glass**              | 未开始                     | **0%**    |
| **flutter_test 解耦**                | 未完成                     | ~0%       |

不过从目前情况来看， 8 月的新版本大概率是等不到这次解耦的正式发布了，预览版应该还是有希望的，至于 Liquid Glass  下半年可能都有点悬，大概率 2027 才能看到影子，除非 9 月的苹果发布会有新政策刺激下，不然感觉不管是 Flutter 还是 CMP ，对于 Liquid Glass 貌似都不太上心，毕竟这玩意确实对自渲染场景压力比较大。

> RN 表示这波优势在我。

**就是如果 8 月不发布这个解耦 package 好像也不行，因为 4 月 Framework 冻结了 flutter/flutter 的 UI package 更新了，如果 8 月版本不发 package ，等于就是没有任何 UI 更新和修复**，这个貌似也不太合理，剩一个月时间，就看官方能不能收尾掉了，按照目前的进度看，其实想收尾也问题不大，可以期待一下。

