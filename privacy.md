# 2024  Flutter  iOS  隐私清单上线，5 月 1 号最后期限，你收到  「ITMS-91053」 了吗？

2023 年底的时候，我就发过了 [《Flutter 上了 Apple 第三方重大列表，2024 春季 iOS 的隐私清单究竟是什么？》](https://juejin.cn/post/7311876701909549065) 相关内容，如果你还对隐私清单等相关要求不了解，建议先看看前文。

如果你已经有相关了解，并且近期也提交过 App 到 App Store ，那么你可能已经收到过类似 「ITMS-91053」 的相关警告邮件，这就是隐私清单里的「必要理由的 API 声明」，也是隐私清单里最大家最容易遇到的问题之一，主要包括了：

- File timestamp APIs
- System boot time APIs
- Disk space APIs
- Active keyboard APIs
- User defaults APIs

![](http://img.cdn.guoshuyu.cn/20240325_privacy/image1.png)

邮件里也写明了，**最后的要求期限是 5 月 1 号，所以正如去年说的那样，春季过去后，也是时候面对隐私清单的适配要求了**。

实际上在 Flutter 进度里，官方和主流的插件基本都已经完成了隐私清单的适配要求，而目前主要出现在 [Upcoming third-party SDK requirements](https://developer.apple.com/support/third-party-SDK-requirements/)  列表的插件，还没适配动静的应该就是 fluttertoast 了，尽管已经有了 [PR #489](	https://github.com/ponnamkarthik/FlutterToast/pull/489) ，但是暂时还没有相关回应。

![](http://img.cdn.guoshuyu.cn/20240325_privacy/image2.png)

> 不过问题不大，最多自己 fork 一个 merge 下。

另外针对之前所说的，对于 “收集” 的定义目前很模糊的问题，类似 `webview_flutter` ，`webview_flutter` 本身不收集任何内容，但是App 可以用来 `webview_flutter` 收集浏览历史记录，然后这如何在 SDK 的隐私清单里去体现？

官方的回复是，如果SDK没有收集任何数据，那么应该提供一个隐私清单，概述没有收集任何信息，所以这也是  `webview_flutter`  等插件目前的适配逻辑之一。

![](http://img.cdn.guoshuyu.cn/20240325_privacy/image3.png)

![](http://img.cdn.guoshuyu.cn/20240325_privacy/image4.png)

> 没适配的插件，也可以考虑自己 fork 过来通过类似方式兼容。

接着我们聊 「ITMS-91053」，如果你收到 `ITMS-91053:  Missing API declaration - Your app’s code in the “Runner” file` ，首先要做的就是确定**你的 Flutter SDK 是否升级到了 3.19** ，因为 Engine 的适配官方是在 3.19 做的，当然，如果你就是想做「钉子户」，那么你也可以参考下方的 issue 和 pr ，自己 fork 个 engine 去适配支持：

- [#48951 Add xcprivacy privacy manifest to iOS framework](https://github.com/flutter/engine/pull/48951/)

- [#131494 Find Required Reason API usage in Flutter Engine and create Privacy Manifest](https://github.com/flutter/flutter/issues/131494)

另外，并不是看到  `Your app’s code in the “Runner” file ` 就是说明是 Engine 的隐私清单有问题，因为构建方式也可能会影响到警告的提示。

Flutter 3.19 本身已经有一个合规的隐私清单，如果你在 3.19 还能遇到 `ITMS-91053:  Missing API declaration - Your app’s code in the “Runner” file`，官方表示可能是：

1. 引入的插件有隐私清单 ( `podspec` 使用了 `s.static_framework = true` )，但目前你使用的是旧版本，所以需要更新插件
2. 使用的插件没有声明隐私清单，或者隐私清单不完整

对于 1 的情况，可以将插件的依赖版本升级到最新，**然后不要忘了运行一次  `flutter pub upgrade`**  ，因为很多插件最近才添加清单支持，另外运行  `flutter pub upgrade`   的必要性在于：

例如 `shared_preferences` 目前是 `2.2.2`，其清单文件是在其依赖的  `shared_preferences_foundation` 上 ，而  `shared_preferences_foundation`  在其内部依赖版本是 `^2.2.0` ，但是其实包含隐私清单的包是 `2.3.5` ，**所以如果你不执行 `flutter pub upgrade` ，那么你本地的  `shared_preferences`  插件所使用的  foundation  依赖可能会是旧版本**。

![](http://img.cdn.guoshuyu.cn/20240325_privacy/image5.png)

> **所以就算升级完插件后，查看插件里是否包含 privacy 文件也是非常重要的一个步骤**。![](http://img.cdn.guoshuyu.cn/20240325_privacy/image6.png)

另外，对于项目的  `Podfile`  构建是否使用 `use_frameworks!` ，也是目前 「ITMS-91053」 警告的主要问题之一  ，为了更好区分和解决  「ITMS-91053」 的问题，官方建议：

1. 一般建议使用  `use_frameworks!`  ，或者插件的 podspec 配置 `static_framework = true` 为强制静态链接，正常情况下可以把出现的警告指向插件，然后沟通插件方配合解决问题，至少清楚问题在哪里。
2. 如果因为构建等原因，无法使用 1 的方式，或者说可以不使用 1 ，那么可以直接在 App 端强制[创建隐私清单](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files#4284009) ，然后通过 `find build/ios/iphoneos -name *.xcprivacy `  在的项目中运行，对于所有 `<some_plugin_name>.bundle/PrivacyInfo.xcprivacy` 查看它们所做的声明，然后合并复制到上面创建的文件，然后自己补充缺少的。

**因为 Flutter 目前在处理 「ITMS-91053」 问题上，最难就是找到警告来自哪个插件，又是因为什么原因不符合**， 例如一开始 `permission_handler_apple`  插件做了隐私清单申明，但是其实少了  `NSUserDefaults` ，因为它设置了 `static_framework = true`，所以导致 NSUserDefaults 代码位于 `Runner` ，一开始找问题的时候，因为它已经适配过了，大家都忽略了 `permission_handler` ，后来才发现，目前 [flutter-permission-handler #1292](https://github.com/Baseflow/flutter-permission-handler/issues/1292) 已经修复了这个问题。

最后，如果你在向官方提出相关 issue 时，例如在 [#145269](https://github.com/flutter/flutter/issues/145269) 下提出相关问题的时候，最好是附上下列配置，以便于快速定位问题：

- `pubspec.yaml` 和 `pubspec.lock` ，特别是 `pubspec.lock` 
- `ios/Podfile`
- 是否自己修改过 Runner 中的 native 代码
- 如果方便提供  `.ipa` 或 `.xcarchive` 

目前来说一些问题还是存在，而存在的原因基本是定位到是哪个插件，和如果理解这样做是否符合条款，目前 issue 都有人提供  create demo 包提交测试是否会触发  「ITMS-91053」，只能说大家都还在“以身试法”，前任种树后人乘凉，感兴趣的可以继续关注：

- https://github.com/flutter/flutter/issues/143232

- https://github.com/flutter/flutter/issues/131940

- https://github.com/flutter/flutter/issues/145269



那么 ，5 月 1 号马上就要来了，你是继续做钉子户，还是升级到 Flutter 3.19 ？如果还有什么问题，欢迎交流讨论。



