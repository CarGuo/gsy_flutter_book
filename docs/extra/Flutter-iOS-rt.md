---
title: "经典，Flutter  iOS 又修复了一个构建问题，还是很抽象"
---

#  经典，Flutter  iOS 又修复了一个构建问题，还是很抽象

最近， Flutter 合并了 [*#185868*](https://github.com/flutter/flutter/pull/185868) 这个 PR ，这个 PR 的作用是**将 Flutter iOS 工具链二进制文件升级为 Fat Binary（胖二进制），从而同时支持 `x86_64` 和 `arm64` 两种架构**，也就是让 Apple Silicon （M 系列芯片）不需要 Rosetta 即可原生运行这些工具。

你说 Flutter 不是很早就支持 Apple Silicon 了？其实这是两个不同概念：

- Flutter 编译的 `.app` 产物（`flutter build ios`）编译目标是 iOS 设备，用的是 `arm64` 架构（iPhone/iPad 的 CPU 架构），和 Mac 主机是什么架构完全无关
- 模拟器上跑（Simulator）在 Apple Silicon Mac 上也是原生的，因为 Flutter 会给模拟器单独构建 `arm64-simulator` 

**而这次的 PR 修的是 Flutter 工具链本身**，也就是运行在 Mac 上的 Flutter 工具链里的二进制工具：

| 工具                                 | 用途                                 |
| ------------------------------------ | ------------------------------------ |
| `idevicesyslog`                      | 读取 iOS 设备的实时日志              |
| `idevicescreenshot`                  | 截取 iOS 设备屏幕                    |
| `iproxy`                             | USB 端口转发（连接 Dart VM Service） |
| `libimobiledevice` / `libusbmuxd` 等 | 上述工具依赖的底层库                 |

这些工具主要负责和 iOS  设备通信，它们基本由第三方开源项目（[libimobiledevice](https://github.com/libimobiledevice) 系列）编译过来的，而由于历史原因，之前一直只编译了 `x86_64`，在 Apple Silicon Mac 上只能靠 Rosetta 2 转译才能运行。

所以，**要让这些工具支持 Apple Silicon ，就需要修改 Flutter 基础设施（infra）的构建 Recipe（ 运行在 Chromium CI 的 Python）**，而 `libimobiledevice`  生态本身的构建脚本需要正确支持 `CFLAGS="-arch arm64 -arch x86_64"`，然后通过 `autoconf/automake` 工具链编译出 Fat Binary，然后用 `lipo` 合并：

![](https://img.cdn.guoshuyu.cn/55555555555555555.png)

实际上这个问题在 2022 年 的 [*#121178*](https://github.com/flutter/flutter/issues/121178)  就被提出了，但 infra 侧的修改（build recipe 的 CL）太容易整出 bug，所以是直到最近才完成。

当时 *#121178*  就发现，在 Apple Silicon Mac 上 通过 Rosetta 2 转译运行会有一些列潜在问题：

- 性能损耗比较大
- 可能触发 Rosetta 兼容性问题（进程通信、socket 行为可能异常）
- 需要 Mac 安装了 Rosetta 2

那为什么最近又想起来要适配了？**因为 Rosetta  要退出历史舞台了**，所以如果再不适配，后面你想跑也跑不了，所以这次也是不得不上。

![](https://img.cdn.guoshuyu.cn/image-20260507093751124.png)

可能你觉得，不就是加一个编译 target 么？还能整出来什么问题？是的，还真的可以，这个 PR 从提交到合并又整出来了问题，简单来说就是：

- **#181932**：想用新版 libimobiledevice + Fat Binary，但新版在 x86 Bot 上有 bug 导致日志中断
- **#185384**：记录这个 flake 问题，同时 revert，并推动调查和修复
- **#185868**：最终解法是**回退到旧版 libimobiledevice**，但这次把它正确地编译成 Fat Binary，放到新的 GCS 路径

![](https://img.cdn.guoshuyu.cn/ChatGPT%20Image%202026%E5%B9%B45%E6%9C%887%E6%97%A5%2009_13_34.png)

对，**最终也不知道为什么，反正合并即 Revert ，然后回退老版本解决问题**，是不是很抽象？但是又有莫名的熟悉感？你说他们合并的时候为什么不测试？

![](https://img.cdn.guoshuyu.cn/image-20260507092026928.png)

怎么可能不测试，PR 在 AI 辅助 Code Review  +  CI 验证都跑了好几轮，但是问题就在于它不是必现，然后 `idevicesyslog`  可以启动正常，但是启动后不知道为什么日志流突然就停止了，所以只能在 merge 发布的时候被人发现后才知道这个缺陷。

> 所以基建链条，特别是 CI 链条，总有升级必挂，修改必崩的墨菲定律。

事实上整个 `IosUsbArtifacts`  的工作流程也挺复杂，除了构建成品之后，还需要在流程上每次合理下载和搭配成品，比如在  `FlutterCache`  里就有 6 个 `IosUsbArtifacts` 实例：

```dart
static const artifactNames = <String>[
  'libimobiledevice',   // 包含 idevicescreenshot、idevicesyslog
  'libusbmuxd',         // 包含 iproxy
  'libplist',
  'openssl',
  'libimobiledeviceglue',
  'ios-deploy',
];
```

对于下载后的  zip  需要做「可执行文件存在性检查」和 stamp 正确检查，下载解压后的 `.dylib` 动态库路径需要注入到子进程的 `DYLD_LIBRARY_PATH` 中，否则运行 `idevicesyslog` 时 macOS 的动态链接器找不到 `libimobiledevice.dylib` 等依赖等问题：

![](https://img.cdn.guoshuyu.cn/ChatGPT%20Image%202026%E5%B9%B45%E6%9C%887%E6%97%A5%2009_23_44.png)

当然，最重要的是，**这个 PR 目前还 CP 到了 3.41 上面**，只能说兜兜转转，3.41 上合并了多少 iOS 编译和调试问题？虽然过程很抽象，但是结果还是好的，至少未来 Flutter 终于可以完全不需要 Rosetta，也是跟上了新的适配进度。

![](https://img.cdn.guoshuyu.cn/image-20260507093452998.png)

> Flutter 3.41 还真成了 iOS 的主力修复战场。