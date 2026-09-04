---
title: "Flutter  3.44 发布前夕，官方宣布 SwiftPM 将完全取代 CocoaPods"
---

# Flutter  3.44 发布前夕，官方宣布 SwiftPM 将完全取代 CocoaPods

马上就是 Google I/O 了，而在这个时候，官方突然官宣，**从下一个 Flutter 稳定版  3.44 开始，Swift Package Manager (SwiftPM) 将取代 CocoaPods**，成为 iOS 和 macOS 应用的默认依赖管理器。

![](https://img.cdn.guoshuyu.cn/ezgif-1f56cd80354430b3.gif)

**也就是 CocoaPods trunk 明确会在 2026-12-02 进入只读**，所以今年年底  SwiftPM 就会开始完全取代 CocoaPods 这个老古董。

其实这个也不算突然，因为在 2024 我们就聊过这个话题，在去年也谈论过 SwiftPM 的相关情况，而现在 Flutter 也开始正式提醒开发者，**虽然现有版本还可以继续使用 CocoaPods，但是 2026-12-02 之后将不会在对 Pod 进行适配和支持 pod**。

![](https://img.cdn.guoshuyu.cn/image-20260502202821504.png)

实际对于 App 开发来说，Flutter CLI 会自动处理迁移，当你开始运行或构建 iOS 或 macOS 应用时，CLI 会自动更新  Xcode 项目使用全新的  Swift 包管理器。

![](https://img.cdn.guoshuyu.cn/14df6570-ecd7-4f03-afcc-2f23a5edbd41.png)

**如果 App 依赖的插件还没适配 SwiftPM，Flutter 会打印一条警告信息，列出所有不受支持的依赖项，同时暂时回退到 CocoaPods**。

> 不过官方也说了，未来 CocoaPods 的支持会被完全移除，所以这种回退并不长久。

当然，如果真的遇到  SwiftPM 导致无法构建等问题，官方也提供了暂时关闭的方式：

```yaml
flutter:
  config:
    enable-swift-package-manager: false
```

而对于插件的开发者， 如果你还没有适配，那么适配  SwiftPM 是必选项，**目前排名前 100 的 iOS 插件里已经有 61% 完成了迁移**，后续如果没添加 Swift Package Manager 支持的 Package ，在 pub.dev 评分中得分也会被拉低。

另外，**Flutter 插件在切到 SwiftPM 之后，必须显式声明“我依赖 Flutter 引擎”，否则编译链路就不完整**，所以需要添加一个 `Package.swift` 文件，并将源文件移动到符合标准 Swift 包结构的位置。

因为在 **CocoaPods 时代**，Flutter 插件的 `.podspec` 里其实已经隐式做了：

- 自动把 `Flutter.framework` 加进来
- 自动处理 header / linker / search path

- **不用关心 Flutter 引擎怎么进来的**

换成 SwiftPM 后：

- SwiftPM 是**完全声明式依赖系统**
- 不会有 CocoaPods 那种“魔法注入”
- **所有依赖都必须在 `Package.swift` 明确写出来**

也就是**你的插件代码其实是运行在 Flutter 引擎之上的，所以你需要在 `Package.swift` 里加这个依赖**，例如类似：

```swift
let package = Package(
    name: "MyPlugin",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "MyPlugin", targets: ["MyPlugin"])
    ],
    dependencies: [
        // 关键就是这个
        .package(name: "FlutterFramework", path: "../Flutter")
    ],
    targets: [
        .target(
            name: "MyPlugin",
            dependencies: [
                "FlutterFramework"
            ]
        )
    ]
)
```



>另外如果在 2025 年做过迁移了插件，现在还也需要补充一个操作：在  `Package.swift`  文件中添加 FlutterFramework 作为依赖项，因为现在必须显式声明依赖。

可以看出来，对 Flutter 来说这次变化影响最大的是**插件生态**，以前 Flutter 插件的 iOS/macOS native 部分基本靠 `.podspec + Podfile + pod install` 接入，而迁到 SwiftPM 后，插件作者需要提供 `Package.swift`，Flutter CLI 需要负责把插件依赖转成 Xcode 可识别的 Swift Package 集成。

实际上今年 KMP 也提到了这个，不过进度相对 Flutter 慢一些，不过都是在今年开始推  SwiftPM ，可以看出来  CocoaPods 真的是末路了，这个陪伴了大家这么多年的依赖管理框架，终究要消失在历史的进程了。

![](https://img.cdn.guoshuyu.cn/image-20260502192123862.png)

最后，**使用 SwiftPM 是全支持 Objective-C  的**，只是一些支持的力度和方式不太一样，比如 SwiftPM  不允许同一个 target 里同时混放 Swift 和 C-family 源码，target 可以包含 Swift、Objective-C/C++ 或 C/C++，但单个 target 不能混合 Swift 和 C-family 语言。

> 所以旧的纯 OC 插件/库迁到 SwiftPM 是可行的，关键是目录结构要符合 SwiftPM 规则。

真正麻烦的是 Swift + OC 混编项目，迁移到 SwiftPM 后，通常需要拆成多个 target，让 Swift target 依赖 OC/C-family target。

那么，你开始使用 SwiftPM 了吗？

