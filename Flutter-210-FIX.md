> **相信大家已经都在对 Flutter 2.10 版本跃跃欲试，本篇就目前升级用 Flutter 2.10 版本遇到的问题做一些总结提炼。**


**事实上按照 Flutter 每个版本的投入使用规律，应该是第三个小版本最稳**，以 Flutter 目前庞大的用户量，每次正式版的发布必然带来各种奇奇怪怪的问题，**一般情况下我推荐 2.10 版本等到 2.10.3 发布再投入生产会更稳妥**，但是如果你等不及官方 `hotfix` ，那么后面的内容可能可以帮助到你。


> 本次如果你是从 2.8 升级的到 2.10 ，那么 dart 层需要调整几乎等于零。


## Kotlin 版本

**首先就项目升级的第一个，也就是最重要的一个，就是升级你的 kotlin 插件版本，这个是强制的**，因为之前的旧版本使用的基本都是 `1.3.x` 的版本，而这些 Flutter 2.10 强制要求 `1.5.31` 以上的版本。

```gradle
buildscript {
-    ext.kotlin_version = '1.3.50'
+    ext.kotlin_version = '1.5.31'
```

这里需要注意，**这次升级 Kotlin 版本，会带来一些 Kotlin 包的 API 出现一些 break 的变化** ，所以如果你本身 App 使用了较多 Kotlin 开发，或者插件里使用了一些 Kotlin 的包，就需要注意升级带来的适配成本，例如：

> `ProducerScope` 需要 `override` 新的 `trySend` 方法，但是这个方法需要 `return` 一个 `ChannelResult` ， `ChannelResult` 是  `@InternalCoroutinesApi` 。


## Gradle 版本

因为 Kotlin 版本升级了，所以 AGP 插件必须使用最低 `4.0.0` 配合 Gradle `6.1.1` 的版本，也就是：

```gradle
classpath 'com.android.tools.build:gradle:4.0.0'
 /
distributionUrl=https://services.gradle.org/distributions/gradle-6.1.1-all.zip
```

因为以前的老版本使用的 AGP 可能是 AGP `3.x` 配合  Gradle `5.x` 的版本，**所以如果升级了 Kotlin 版本，这一步升级就必不可少。**

> 这里顺便放一张 AGP 和 Gradle 之间的版本对应截图

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-210-FIX/image1)


## Android SDK 问题


### cmdline-tools & license

这个问题可能大家不一定会遇到，首先如果你在执行 `flutter doctor` 的时候出现以下情况

```
[!] Android toolchain - develop for Android devices (Android SDK version 31.0.0)
    ✗ cmdline-tools component is missing
      Run `path/to/sdkmanager --install "cmdline-tools;latest"`
      See https://developer.android.com/studio/command-line for more details.
    ✗ Android license status unknown.
      Run `flutter doctor --android-licenses` to accept the SDK licenses.
      See https://flutter.dev/docs/get-started/install/macos#android-setup for
      more details.
```


也就是 `cmdline-tools` 和  `Android license` 都是 `✗` 的显示时，那可能你还需要额外做一些步骤来完善配置。


首先你需要安装 `cmdline-tools` ，如下图所示直接安装就可以了



![](http://img.cdn.guoshuyu.cn/20220328_Flutter-210-FIX/image2)


然后执行 `flutter doctor --android-licenses` ，就可以很简单地完善你的环境的配置。


### Build Tools

其次，如果你在编译 Android Apk 的过程中出现 ： `Installed Build Tools revision 31.0.0 is corrupted` 之类的问题：

```
Could not determine the dependencies of task ':app:compileDebugJavaWithJavac'.
> Installed Build Tools revision 31.0.0 is corrupted. Remove and install again using the SDK Manager.
```

那么可以通过执行如下命令行来完成配置 ：

```
# change below to your Android SDK path
cd ~/Library/Android/sdk/build-tools/31.0.0 \
  && mv d8 dx \
  && cd lib  \
  && mv d8.jar dx.jar
```
> Window 用户可以看 https://stackoverflow.com/questions/68387270/android-studio-error-installed-build-tools-revision-31-0-0-is-corrupted


### NDK

如果你在编译过程中出现 `No version of NDK matched` 的问题：


```
Execution failed for task ':app:stripDebugDebugSymbols'.
> No version of NDK matched the requested version 21.0.6113669. Versions available locally: 19.1.5304403
```

这个问题其实很简单，如图打开你的  `SDK Manager`  下载对应的版本就可以了。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-210-FIX/image3)



## 本地 AAR 文件问题


因为前面升级了 AGP 版本，这时候就带来一个问题，这个问题仅存在于**你使用的 Flutter Plugin 里的本地的 aar 文件**。

正常情况下编译时就会遇到如果的提示：

```
> Direct local .aar file dependencies are not supported when building an AAR. The resulting AAR would be broken because the classes and Android resources from any local .aar file dependencies would not be packaged in the resulting AAR. Previous versions of the Android Gradle Plugin produce broken AARs in this case too (despite not throwing this error). The following direct local .aar file dependencies of the :********* project caused this error: /Users/guoshuyu/.pub-cache/git/*********-01d03bf549e512f6e15dd539411a8c236d77cd47/android/libs/libc*********.aar, /Users/guoshuyu/.pub-cache/git/*********-01d03bf549e512f6e15dd539411a8c236d77cd47/android/libs/*********.aar, /Users/guoshuyu/.pub-cache/git/*********-01d03bf549e512f6e15dd539411a8c236d77cd47/android/libs/*********.aar
```


这时候听我一声劝，**什么办法都不好使，直接搭一个私服 Maven ，很简单的，把 aar 上传上去，然后远程依赖进来就可以了**。

[Alex](https://juejin.cn/user/606586150596360) 大佬建议的本地 maven 构建也可以：https://www.kikt.top/posts/flutter/plugin/flutter-sdk-import-aar/  主要就是构建得到一个如下结构的目录：

```
tree .
.
├── com
│   └── pgyer
│       └── sdk
│           ├── 3.0.9
│           │   ├── sdk-3.0.9.aar
│           │   ├── sdk-3.0.9.aar.md5
│           │   ├── sdk-3.0.9.aar.sha1
│           │   ├── sdk-3.0.9.pom
│           │   ├── sdk-3.0.9.pom.md5
│           │   └── sdk-3.0.9.pom.sha1
│           ├── maven-metadata.xml
│           ├── maven-metadata.xml.md5
│           └── maven-metadata.xml.sha1
└── sdk.aar

```

然后配置 android 下的 gradle

```gradle
// 定义一个方法, 用于获取当前moudle的dir
def getCurrentProjectDir() {
    String result = ""
    rootProject.allprojects { project ->
        if (project.properties.get("identityPath").toString() == ":example_for_flutter_plugin_local_maven") { // 这里是flutter的约定, 插件的module名是插件名, :是gradle的约定. project前加:
            result = project.properties.get("projectDir").toString()
        }
    }
    return result
}

rootProject.allprojects {
    // 这个闭包是循环所有project, 我们让这个仓库可以被所有module找到
    def dir = getCurrentProjectDir()
    repositories {
        google()
        jcenter()
        maven { // 添加这个指向本地的仓库目录
            url "$dir/aar"
        }
    }
}

dependencies {
    implementation "com.pgyer:sdk:3.0.9" // 添加这个, 接着点sync project with gradle file 刷新一下项目就可以了. 是使用api还是implementation根据你的实际情况来看就好了
}
```

## 强制 V2 


Android 上在这个版本上就强制要求 V2 的，例如如果之前使用了 `android:name="io.flutter.app.FlutterApplication"` ，那么在编译时你会看到：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Warning
──────────────────────────────────────────────────────────────────────────────
Your Flutter application is created using an older version of the Android
embedding. It is being deprecated in favor of Android embedding v2. Follow the
steps at

https://flutter.dev/go/android-project-migration

to migrate your project. You may also pass the --ignore-deprecation flag to
ignore this check and continue with the deprecated v1 embedding. However,
the v1 Android embedding will be removed in future versions of Flutter.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The detected reason was:

  /Users/guoshuyu/workspace/***/*********/android/app/src/main/AndroidManifest.xml uses `android:name="io.flutter.app.FutterApplication"`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

这里如果你只需要简单删除  `android:name="io.flutter.app.FutterApplication"` 就可以了。

> 更多关于 V2 的可以参考：https://flutter.dev/go/android-project-migration


## Material 图标出现异常

Flutter 2.10 针对 Material Icon 做了一次升级，结果很明显这次发布不小心又挖了个坑，目前问题看起来是**因为某个 issue 的回滚导致部分 icon 的提交也被回退**，所以这部分只能静待 hotfix ，目前官方已经知道这个问题，具体可见：

> https://github.com/flutter/flutter/issues/97767

## iOS CocoaPods not installed


**如果你运行 iOS 出现 `CocoaPods not installed` 的错误提示，那么不要着急，这个是 Android Studio 团队的锅**。

```
Warning: CocoaPods not installed. Skipping pod install.
  CocoaPods is used to retrieve the iOS and macOS platform side's plugin code that responds to your plugin usage on the Dart side.
  Without CocoaPods, plugins will not work on iOS or macOS.
  For more info, see https://flutter.dev/platform-plugins
To install see https://guides.cocoapods.org/using/getting-started.html#installation for instructions.

Exception: CocoaPods not installed or not in valid state.
```

其实你在执行 `flutter doctor` 时可能就是看到提示，说你本地缺少 `CocoaPods` ， 但是实际上你本地是有 `CocoaPods`  的，这时候解决的方案有几个可以选择：

- 直接通过命令行 `flutter run` 运行就不会有这个问题；
- 通过命令行 `open /Applications/Android\ Studio.app` 启动 Android Studio ；
- 执行 `chmod +x /Applications/Android\ Studio.app/Contents/bin/printenv` （如果你使用了 `JetBrains Toolbox` ，那 `printenv` 文件路径可能会有所变化）
- 静待 Android Studio 的小版本更新


> 更多可以参考 ： https://github.com/flutter/flutter/issues/97251

更新：**新版 Android Studio Patch1 更新已经修复该问题**

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-210-FIX/image4)