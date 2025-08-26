# 聊聊 Flutter 在 iOS 真机 Debug 运行出现 Timed out *** to update 的问题

最近刚好有人在问，他的 Flutter 项目在升级之后出现  `Error starting debug session in Xcode: Timed out waiting for CONFIGURATION_BUILD_DIR to update` 问题，也就是真机 Debug 时始终运行不了的问题：

![](https://img.cdn.guoshuyu.cn/image-20250717131938018.png)

其实这已经是一个老问题了，这个问题不只是 Flutter 会出现，在 React Native 平台也会有，因为本质上 Xcode 15+ 的升级带来的变动，最明显标志就是，**如果你直接在 Xcode 直接运行这个 Flutter 项目是可以正常运行的话，那么 99% 就是因为 Xcode 15+ 上 `ios-deploy` 的“废弃”引起的问题**。

> `ios-deploy` 是一个通过对苹果私有框架进行逆向，提供了无需打开 Xcode.app 即可在物理 iOS 设备上安装和调试应用的第三方框架，而对于 Flutter 而言，  `flutter run` 命令的一键式启动，在很大程度上依赖 `ios-deploy` ，以及至关重要的一步：在设备上启动 `debugserver` 进程。

当然，虽然 `ios-deploy` 不能用了额，但是苹果提供了官方的替代方案：`devicectl` 命令行工具，不过虽然它能够安装应用（例如 `devicectl device install app` ），但它缺少了在设备上启动 `debugserver` 并将其附加到目标进程的支持，这对于 Flutter Debug 时的 JIT  和 hotload 非常重要。

> 详细原因可见：[《Flutter 又双叒叕可以在 iOS 26 的真机上 hotload》](https://juejin.cn/post/7519118964975992886) ，而针对 `devicectl`   可以从下方的 React Native CLI 变动中看到，针对真机按照，现在 React Native 也采用了 `devicectl`  的方式：![image-20250717131819323](https://img.cdn.guoshuyu.cn/image-20250717131819323.png)

所以，虽然有 `devicectl` ，但是 Flutter 的 JIT 离不开  `debugserver` 的权限支持，所以 Flutter 官方针对 Xcode 15 的场景进行了一些临时处理，当开发者运行 `flutter run` 时，流程会是：

- 使用 `xcodebuild` 构建应用
- 启动 Xcode.app 
- 利用脚本让 Xcode 在连接的设备上运行 App
- 等待 Xcode 建立调试会话，将 Flutter 工具的守护进程连接到 Dart VM 的 Observatory 端口

简单说，就是需要安装 Xcode 并且运行时会弹出 Xcode 窗口，还需要用户在 macOS 的“系统设置 > 隐私与安全性 > 自动化”中给予相应的权限 ：

![](https://img.cdn.guoshuyu.cn/image-20250717140933522.png)

而问题主要也是出现在这里，很多开发者发现，Flutter run 并没有拉起 Xcode ，或者拉起后依然出现超时等情况，这也是这个方案最大的问题：

![](https://img.cdn.guoshuyu.cn/image-20250717133640486.png)![](https://img.cdn.guoshuyu.cn/image-20250717134036279.png)

目前看来，这还和用户当前项目的环境有关系，正常来说这个流程是不会有问题的，但是结果来看并不是大家都“正常”，所以根据已有信息看，遇到这类问题一般的做法有：

- flutter clean 清除掉已有的可能存在问题的 build
- 手动启动 Xcode 减少等到时间
- 通过 Xcode 直接运行判断项目本身兼容存在问题，如果可以运行，说明是 Flutter 命令行问题
- 关闭  Wi-Fi，有时候即使 iPhone 通过 USB 数据线连接到 Mac，Xcode 也可能优先选择通过 Wi-Fi 进行调试连接 
- 执行 `flutter run` 命令运行
- 如果还不行，可以尝试 Xcode 直接运行，然后执行 `flutter attatch` 尝试连接  Dart VM Observatory 服务
- 再不行，只能模拟器开发，然后 release 运行真机测试

而针对这个问题，其实苹果也发现了，所以  Xcode 16 增加了 devicectl 和  Xcode 的命令行调试器 `lldb` 协同工作的支持，**虽然 `devicectl` 单独无法启动 `debugserver`，但它可以和 Xcode 的命令行调试器 `lldb` 协同工作**：

![](https://img.cdn.guoshuyu.cn/image-20250717132926651.png)

所以针对这个问题，Flutter 计划也是有在 Xcode 16 做新的调整的计划，通过新的 `devicectl` + `lldb` 集成到 `flutter run` 命令来回归已有的流程，但是因为涉及变动很多，暂时看起来还没什么进展：

![](https://img.cdn.guoshuyu.cn/image-20250717132755525.png)

> 主要是 Xcode automation in CI 也不是完全不能用····

最后总结下，这个问题的核心就是，你用 Xcode 能不能运行，如果可以，就可以尝试使用  `flutter attatch`  ，或者  `flutter run`  之前先打开 Xcode ，并且确保 Xcode 开启了自动签名之类的必备条件，最好关闭手机 Wi-Fi 来排除问题。

> 最极端的情况下，可能会需要你 `flutter clean` 和 `rm -r ~/Library/Developer/Xcode/iOS\ DeviceSupport` 清除设备当前授权。



# 参考链接

https://github.com/flutter/flutter/issues/172095

https://github.com/flutter/flutter/issues/133465

https://github.com/flutter/flutter/issues/144218

https://github.com/flutter/flutter/issues/42969#issuecomment-3057078316