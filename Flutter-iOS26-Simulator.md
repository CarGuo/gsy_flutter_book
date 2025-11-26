

# Flutter 在 iOS 26 模拟器跑不起来？其实很简单

在之前的[《Flutter 完成全新 devicectl + lldb 的 Debug JIT 运行支持》](https://juejin.cn/post/7542461507402924075)我们提到，在 iOS 26 上为了更好的 Debug 体验，Flutter 在将开发和调试场景切换到了 devicectl + lldb  ，从而支持 JIT 运行和 hotload，不过暂时这部分还在 master 没有 3.35 版本。

> 上述说的这个调整主要影响真机 Debug ，不会影响 Release 和模拟器。

所以 3.35 版本虽然也能在 iOS 26 上进行 Debug 开发，但是在 Xcode 26 的真机上的体验会相对较差，比如 timeout 和耗时是比较常见的情况。

但是最近的一些开发者里发现，它们在 iOS 26 模拟器上也“随机”出现无法运行的情况，运行时会出现 `Unable to find a destination matching the provided destination specifie` 这样的提示，而在之前的  iOS 18.6 模拟器又运行良好：

````
Uncategorized (Xcode): Unable to find a destination matching the provided destination specifier:
                { id:6B4F9D28-C76C-4146-9527-E844395B4434 }

        Available destinations for the "Runner" scheme:
                { platform:macOS, arch:arm64, variant:Designed for [iPad,iPhone], id:00006020-000221002EE8C01E, name:My Mac }
                { platform:iOS, id:dvtdevice-DVTiPhonePlaceholder-iphoneos:placeholder, name:Any iOS Device }
                { platform:iOS Simulator, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-iphonesimulator:placeholder, name:Any iOS Simulator Device }
````

![](https://img.cdn.guoshuyu.cn/image-20251015092321461.png)

这是 iOS 26 模拟器和 Flutter 的适配问题吗？其**实问题确实是适配导致，但是却不是 Flutter 的问题**，而是一些插件和模拟器之间的适配问题，实际上问题是：

> 用的插件不支持 “ARM 模拟器”，而你默认使用的 iOS 26  模拟器只支持 ARM 。

而解决问题的方式也很简单，只需在 Mac 上安装 **Rosetta** ，然后从 Xcode 中移除 **iOS 26** 平台，然后运行以下命令：

> `xcodebuild -downloadPlatform iOS -architectureVariant universal`

重新下载的会是具有通用架构支持的 iOS 26，而不仅仅是基于 Apple 的 ARM 架构默认配置：

![](https://img.cdn.guoshuyu.cn/image-20251015092516267.png)

所以，解决方案是强制 Xcode 下载 iOS 26 模拟器的“通用”版本，而不是默认的“Apple Silicon”，所以你首先要通过 `Xcode` -> `Settings` -> `Components` -> `iOS 26.0 info symbol` 确定你的模拟器架构：

![](https://img.cdn.guoshuyu.cn/image-20251015093332568.png)![](https://img.cdn.guoshuyu.cn/image-20251015093340705.png)

删除后重新下载“通用”模拟器，通过 `xcodebuild -downloadPlatform iOS -architectureVariant universal` 之后，就可以看到通用的 iOS 26 模拟器组件以及 Rosetta 模拟器：

![](https://img.cdn.guoshuyu.cn/image-20251015093526572.png)

当然，**Rosetta 只能说是一个临时的解决方式，核心还是要看哪些插件仍然无法运行 ARM** ，所以对于这个问题，更建议的是：

> 可以创建一个新的 Flutter 项目，然后逐个现在添加插件，看看哪些插件无法在 iOS 26 模拟器上运行，从而找出哪个插件配置错误，**因为有可能只是老旧插件 ARCHS 配置错误，它不一定真的就不支持 arm64** 。

所以这次的问题核心并不是 Flutter 的兼容问题，**这也是为什么有的人发现，换了个电脑居然有可以跑的原因，主要是升级 Xcode16 之后模拟器重新安装后默认只支持 ARM 架构**，如果你的插件之前配置或者设置并没有完全兼容，那么就会让问题暴露出来。

所以，这只是升级 iOS26 下的微小插曲，后面有时间再介绍更大的坑。

# 参考资

https://github.com/flutter/flutter/issues/176188

