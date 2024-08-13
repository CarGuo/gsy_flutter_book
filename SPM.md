# Flutter 正在迁移到  Swift Package Manager ，未来会弃用 CocoaPods 吗？

什么是 Swift Package Manager ？其实  Swift Package Manager (SwiftPM) 出现已经挺长一段时间了，我记得第一次听说  SwiftPM 的时候，应该还是在 2016 年，那时候 Swift 3 刚发布，不过正式出场应该还是在 2018 年的  Apple 的 WWDC  上。

但是其实这么多年过去了，在社区接触上，其实感觉 SwiftPM 的铺开程度还是比较局限，我觉得这也和 Swift 本身的推广效果有关系， **在 [stackoverflow 2024](https://survey.stackoverflow.co/2024/technology#worked-with-vs-want-to-work-with-misc-tech-worked-want-prof[) 的数据报告里可以看到， Swift 目前的地位还是略显尴尬**。

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image1.png)

那为什么在已经有成熟 CocoaPods 的情况下，Apple 还要多搞一个 Swift Package Manager ？**其实我理解核心还是推广 Swift ，毕竟用 Swift 写 SwiftPM 来管理 Swift  Package ，一听就很合理**。

> 就像 Android，在有 Groovy/Gradle 的情况下，开始推广用 Kotlin 的 kts 来写构建脚本 ，Kotlin First ，很合理。

当然，Swift  Package  本身能更好的做一些拓展和封装，发布也更方便，并且和 Xcode 集成更舒适，作为「迟来」的亲儿子，肯定还是具有一些优势。

> SwiftPM 作为 Swift 工具链中的一部分，同时也包含在 Xcode 中，所以使用 Swift  比起 CocoaPods ，不需要额外的第三方环境 。

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image2.png)

Swift Package 不使用 `.xcodeproj` 或  `.xcworkspace` ，而是依赖其文件夹结构，并使用 Package.swift 进行配置，结构也更简单，例如：

- // swift-tools-version:5.3  ：必须存在的版本信息

- name: 库名称

- products: 库编译后对象，生成可执行文件或者 Library

- dependencies:  依赖的库，依赖库的 URL 和版本等，还可以依赖本地库如 `.package(path:)`

- targets:  包的基本构建目标，target 可以定义模块或测试模块，另外 target 可以依赖于该包中的其他 target 和 Package 依赖的 Library，也可以多 target 。

```swift
// swift-tools-version:5.3
import PackageDescription


let package = Package(
    name: "MyLibrary",
    platforms: [
        .macOS(.v10_14), .iOS(.v13), .tvOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "MyLibrary",
            targets: ["MyLibrary", "SomeRemoteBinaryPackage", "SomeLocalBinaryPackage"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MyLibrary",
            exclude: ["instructions.md"],
            resources: [
                .process("text.txt"),
                .process("example.png"),
                .copy("settings.plist")
            ]
        ),
        .binaryTarget(
            name: "SomeRemoteBinaryPackage",
            url: "https://url/to/some/remote/binary/package.zip",
            checksum: "The checksum of the XCFramework inside the ZIP archive."
        ),
        .binaryTarget(
            name: "SomeLocalBinaryPackage",
            path: "path/to/some.xcframework"
        )
        .testTarget(
            name: "MyLibraryTests",
            dependencies: ["MyLibrary"]),
    ]
)
```

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image3.png)

> 是不是结构也很简单？

**其实采用 SwiftPM 还有其他好处，那就是可视化支持**，例如在 add Package 的时候，可以看到官方支持的一些 Packages 的情况和依赖方式。

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image4.png)

另外一些第三方包，例如 firebase ，**可以把库的 https 的 git 链接放到搜索框**，就可以在 Xcode 看到和添加对应的第三方依赖情况，至于你问我为什么用这么抽象的方式？因为我也不知道图 2 的方式为什么会无法正常被添加。

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image5.png)

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image6.png)

那 SwiftPM 有什么缺点吗？其实还是有的，除了社区 Package 对比 CocoaPods 少太多之外，目前就是单个 target 不能将 Swift 和 C 系列语言混合使用，也就是 **target 可以包含 Swift、Objective-C/C++ 或 C/C++ 代码，但单个 target 不能将 Swift 与 C 系列语言混合使用** 。

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image7.png)

是的，**其实在  Swift Package Manager 里可以单独使用 OC，所以你旧的 OC Package 也可以迁移到 SwiftPM** ，只要选择符合规格就行，例如需要 header 的  `publicHeadersPath`  指定，不配置时，默认是目录下的  `include`  路径。

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image8.png)

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image9.png)

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image10.png)

> 所以如果存在混编，SwiftPM 肯定会是多 target 依赖，这时候如果你的库想要支持 CocoaPods 和 SwiftPM 双平台发布，如果是存在那么你可以需要对整个项目的结果和引用方式做一些调整，甚至添加一些  `swiftSettings: [.define("IS_SwiftPM")]`  这样的宏配置，然后在代码里通过 `#if IS_SwiftPM` 的方式去对如  **import**  等操作做区分。

其实我个人也不喜欢混编，因为这样可能会带来一些很奇葩的场景，例如：

- Library B 使用 OC 写的，依赖了  Swift 写的 Library A
- 然后 Library C 用 Swift 写的，又依赖了 OC 写的 Library B 
- 在 CocoaPods 场景下，混编都折腾出不少问题，例如曾经的[《Flutter iOS OC 混编 Swift 遭遇动态库和静态库问题填坑》](https://juejin.cn/post/7089338745941393438)

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image11.png)

但是现实历史场景下，混编又是很常见的需求，所以目前也存在 [swiftlang#5919](https://github.com/swiftlang/swift-package-manager/pull/5919) 在讨论的  support for targets with mixed language sources  ，只是还没落地就是：

> 例如 React Native ，因为不支持混编的原因，在 SwiftPM 的推进上很慢，另外也有人给 CocoaPods 提了 [PR#743](https://github.com/CocoaPods/Core/pull/743)，希望通过在  CocoaPods 增加  `SwiftPM_dependency` 的做法来让  CocoaPods 支持 SwiftPM ，不过目前 SwiftPM 貌似还不支持运行预处理命令，所以没办法对纯 C++ 包进行一些预处理。

甚至对于 RN 没支持 SwiftPM 这件事情下，也有一些人颇有微词，但是其实迁移到 SwiftPM 本身的成本确实不低，特别是对于 RN 本身来说。

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image12.png)



在知道了 Swift Package Manager  的一些简单情况后，而回到本文主题上，**既然迁移成本那么高，为什么 Flutter 还要迁移到 SwiftPM** ？

Flutter 其实很早就在将自己的 Package 下的插件迁移到 Swift 上，而目前也在开始推进 SwiftPM 的迁移，这对于 Flutter 来说，好处就是：

- **Flutter 的 Plugin 可以更贴近 Swift 生态**

- **简化 Flutter 安装环境，Xcode 本身就是包含 SwiftPM**，如果 Flutter 的项目使用 SwiftPM，则完全无需安装 Ruby 和 CocoaPods 等环境（从 Flutter Team 提到的这里预期， Flutter 未来计划弃用 CocoaPods 的可能性很大）

而从目前的官方 Package 上看，[#146922](https://github.com/flutter/flutter/issues/146922) 上需要迁移支持的 Package 大部分都已经迁移完毕，剩下的主要文档和脚本部分的支持。

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image13.png)

![](http://img.cdn.guoshuyu.cn/20240806_SPM/image14.png)

从 Flutter 官方的角度，它肯定希望  Flutter CLI  可以在升级后自动将项目迁移到 SwiftPM 支持，而目前关于 SwiftPM 相关部分尝试，还需要在 main 分支下进行预览。

> 目前看来， SwiftPM 对于项目工程的修改，很大程度是比较不可逆，所以如果  Flutter CLI   无法一键升级的情况下，自己手动调整也挺麻烦的 ，更多可见：https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers

**不过官方的迁移速度不是重点，重点还是 pub 上将近 10,000 多个 iOS 和 macOS 插件**，他们是否能顺序迁移到  SwiftPM ，才是这次迁移里的核心重点。

要之前，Apple 今年开春的 [Privacy Manifest 问题](https://juejin.cn/post/7349895521395884069)就已经把社区插件搞了一遍，而 SwiftPM 对比 Privacy Manifest  得难度只会更高。

**那为什么说 Flutter 最终会会选择弃用 CocoaPods，前面介绍过，兼容两者可能带来一些昂贵的额外维护成本**，并且相比较于 CocoaPods，Flutter Team 目前更看好 Swift 和 SwiftPM 。

所以基本可以看到，目前 Flutter 的整体都在往 SwiftPM 迁移，但是维护两套依赖管理方案肯定不是明智之举，具体原因我们前面也聊过，所以从我个人角度看，**按照 Flutter 的尿性，只要 SwiftPM 正式落地，弃用 CocoaPods 的通知也就不远了**。

> 不过也不用担心，从目前看来，SwiftPM 的落地还有挺长一段时间要走，例如 Add to App  场景的支持就是一个问题，因为 SwiftPM 没有像 CocoaPods 那样将包转换为 xcframework 的方法，同时 SwiftPM 需要知道在哪里找到框架，不然它就无法正常解析。

所以如果你还没使用或者迁移到 SwiftPM， 可以考虑先了解或者尝试下，整体体验式其实 SwiftPM 确实比如 CocoaPods 优秀，并且更轻巧简便，**所以我个人还是希望 SwiftPM 可以在 Flutter 上早日落地，毕竟讨厌 OC 和 CocoaPods 不是很正常吗**？







