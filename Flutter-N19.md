# Flutter 小技巧之 3.7 更灵活的编译变量支持



今天我们聊个简单的知识点，在 Flutter 3.7 的 [release-notes](https://docs.flutter.dev/development/tools/sdk/release-notes/release-notes-3.7.0)  里，有一个没有出现在 announcement 说明上的 change log ，可能对于 Flutter 团队来说这个功能并不是特别重要，但是对于我个人而言，这是一个十分重要的能力补充：

- [flutter_tools] Fix so that the value set by `--dart-define-from-file` can be passed to Gradle by @blendthink in https://github.com/flutter/flutter/pull/114297

> 翻到这个小功能，纯属是意外之喜。

# Dart

在 3.7 版本之前，如果我们需要在编译时动态给 Flutter 添加变量信息，那么我们会用到 `--dart-define` ，例如：

```dart
flutter run --dart-define=APP_CHANNEL=Offical

const APP_CHANNEL = String.fromEnvironment('APP_CHANNEL');
```

我们可以通过  `--dart-define` 在命令行指定一个变量，然后在 Flutter 里通过  `String.fromEnvironment` 读取它，一般场景下它是满足需求的，但是：

- 如果当你需要定义多个变量时，命令就会变得冗长且不好维护

- 如果你是混合开发，变量还需要同步修改到原生项目的配置里，就会变得麻烦

在此之前，针对同步修改到不同原生项目的配置，我是通过自定义脚本去实现：

- Android 上利用 gradle 脚本，参考 RN 上的 `dotenv ` 读取某个脚本配置，修改 `project.env` 
- iOS 上通过读取脚本配置，然后利用系统的 `PlistBuddy` 命令在编译时插入和修改某些参数

而现在，**从 Flutter 3.7 开始，它变得更简单了，因为你可以使用  `--dart-define-from-file`** ：

```dart
flutter run --dart-define-from-file=config.json

////// config.json ////// 
{
  "TEST_KEY1": "test key 1",
  "TEST_KEY2": "test key 2"
}  
```

同样是  dart define ，但是 `--dart-define-from-file` 可以直接从一个 json 文件上读取配置，然后转成一个 `Map`，之后配置到 Environment 里，同样是可以在 dart 里通过 `String.fromEnvironment`  去读取参数，而 json 文件的配置方式，可以让你在需要配置多个变量时参数管理变得更好维护。

![](http://img.cdn.guoshuyu.cn/20230209_df/image1.png)

那到这里就结束了吗？显然不是，前面我们说过同步修改到不同原生项目的配置，而 Flutter 3.7 下官方也正式支持。

# Android

首先是 Android ，我们可以在  `app/build.gradle` 文件下定义一个 `dartEnvVar` 变量，它主要是用来读取前面 json 文件注入到 `project` 的参数。

![](http://img.cdn.guoshuyu.cn/20230209_df/image2.png)

然后我们就可以在  `app/build.gradle ` 下直接通过  `dartEnvVar`  引用对应参数，比如定义 `resValue` ，可以看到  `dartEnvVar`   在编译时，成功读取到 json 文件里的参数。

| ![](http://img.cdn.guoshuyu.cn/20230209_df/image3.png) | ![](http://img.cdn.guoshuyu.cn/20230209_df/image4.png) |
| ------------------------------------------------------ | ------------------------------------------------------ |

如下图所示，能通过  `project`  读取 dart 的环境变量配置之后，我们就可以定义有  `resValue ` 去修改 `AndroidManifest` 文件，甚至定义插入到 `BuildConfig` 里在原生代码引用，而对于配置我们只需要维护一份 json 文件即可。

![image-20230208182506190](http://img.cdn.guoshuyu.cn/20230209_df/image5.png)

那它是如何实现的？简单来说，在 *flutter/packages/flutter_tools/lib/src/build_info.dart* 脚本下，之前读取的 json 文件可以得到一个 `dartDefineConfigJsonMap` 对象，它会被转化为一个 Gradle 参数列表，在之后的 `assembleTask` 里被作为参数执行。

> 这里需要注意，定义的 key 不能和与定制的 key 冲突，比如  `dart-obfuscation` 等。

![](http://img.cdn.guoshuyu.cn/20230209_df/image6.png)

如下图所示，最终执行的时候就会是  -PTEST_KEY1=test key 1 -PTEST_KEY2=test key 2   这样的效果。

![](http://img.cdn.guoshuyu.cn/20230209_df/image7.png)



# iOS

iOS 上同样也很简单，你只需要在 `Info.plist` 上定义好 key-value 的引用即可，因为 iOS 上在  `--dart-define-from-file`  编译时，同样会生成对应的 `xcconfig`  配置信息。

![](http://img.cdn.guoshuyu.cn/20230209_df/image8.png)

在 ` ios/Flutter` 目录下，编译时会产生两个忽略文件，分别是 `flutter_export_environment.sh` 和  `Generated.xcconfig` ，可以看到编译后这两个文件下都产生了对应的  key-value 。

| ![](http://img.cdn.guoshuyu.cn/20230209_df/image9.png) | ![](http://img.cdn.guoshuyu.cn/20230209_df/image10.png) |
| ------------------------------------------------------ | ------------------------------------------------------- |

> 这里需要注意，在 iOS 上 `xcconfig` 格式会将 `// `  读取为注释分隔符 ，也就是 `//` 之后的内容会被忽略，也就是说，你不能通过它来传递 url ，比如 `https://xxxx` ，因为 `//` 后会被忽略。

当然，如果你需要默认值，那么你也可以在 ` ios/Flutter` 目录下的 `Debug.xcconfig` 和 `Release.xcconfig` 上进行定制配置。

![](http://img.cdn.guoshuyu.cn/20230209_df/image11.png)



和 Android 一样， iOS 在编译时会对 `--dart-define-from-file`  的参数进行转化变成 `xcconfig` 参数，从而实现 dart 和 iOS 端公用一份变量配置的效果。

| ![](http://img.cdn.guoshuyu.cn/20230209_df/image12.png) | ![](http://img.cdn.guoshuyu.cn/20230209_df/image13.png) |
| ------------------------------------------------------- | ------------------------------------------------------- |



# 最后

可以看到  `--dart-define-from-file`  的使用和实现并不复杂，在没有它之前我们也可以通过一些手段来实现类似的效果。

但是   `--dart-define-from-file`   命令的出现简化了整个构建流程，让编译动态配置的链条变得更加灵活可靠，所以它无疑是 3.7 里最容易被忽略的实用更新。

不得不说，Flutter  3.7 给我们带来了不少的惊喜，例如 [toImageSync ](https://juejin.cn/post/7197326179933372476) 和 [background isolate](https://juejin.cn/post/7195825738472620087) 都是期待已久的功能，而类似   `--dart-define-from-file`   的支持，也在不断完善 Flutter 的开发体验。

最后，从 3.7 开始的小版本更新有两个特征：

- 1、impeller 确实还有不少问题
- 2、impeller 真的来了，就算预览功能也要 fix 到稳定分支

![](http://img.cdn.guoshuyu.cn/20230209_df/image14.png)

期待下个版本 impeller 能给我们带来更好的体验。