# 2025 一季度 Flutter iOS 大坑超汇总，看看你踩中了没

在过去的 2025 一季度里，iOS 存在不少大坑，这些大坑也不全是 Flutter 的问题，很大一部分其实和 iOS 本身和 MacOS 升级带来的 bug 有关系。

> 适配系统 bug 也叫适配。

首先就是之前我们聊过的 [《iOS 18.4 beta mprotect failed: Permission denied》](https://juejin.cn/post/7476743827202736143) 问题 [#163984](https://github.com/flutter/flutter/issues/163984)，在 iOS 18.4 beta 的时候， debug 运行会有 `Permission denied` 的相关错误提示，问题其实就是 Dart VM 在初始化时，对内核文件「解释运行（JIT）」时出现权限不足的问题。

这个问题是 Dart VM  虽然在 Debug 模式下是通过 JIT 模式解释执行，但是**从 Dart 2.0 之后就不再支持直接从源码运行**，对于 Dart 代码现在会统一编译成一种「预处理」形式的**二进制 dill 文件**：

> 此时 JIT 运行的是一个**未签名的二进制文件**，并且需要直接 hotload ，也就是需要 Dart VM 在运行时根据 Kernel 二进制文件生成机械码，并且在可以接受 hotload 的热更新，所以它是通过 VM 来“解释”和“生成“，所以它会需要 mprotect 的系统调用。

利用 mprotect 动态修改内存的可读写也算是一种比较 hack 的操作，一开始大家以为是 iOS 想要封杀这种 “后门漏洞”，可是谁知道，iOS 18 beta2 该“漏洞”又可以正常使用了，目前看起来更多是 iOS 系统在版本更新时出现的错误封杀：

![](https://img.cdn.guoshuyu.cn/image-20250424104959803.png)

然后同样是之前聊过的 [《「ITMS-90048」This bundle is invalid 》](https://juejin.cn/post/7489405244038201378) 的 [#166367](https://github.com/flutter/flutter/issues/166367)，不上用户在升级到 macOS 15.4 后发现，通过命令行打包的 ipa 在提交后会出现 ITMS-90048 被拒绝问题：

![](https://img.cdn.guoshuyu.cn/image-20250424105051963.png)

这个错误的核心原因是在提交给 App Store Connect 的归档文件 (`.xcarchive`) 里，包含了一个不允许存在的隐藏文件 `._Symbols` 。

而出现这个 bug 的原因，大概率在于 macOS 15.4对内置 `rsync` 的重大修订，在构建或归档过程中，系统对 `Symbols` 文件进行了某种操作（如 rsync），导致 macOS 生成了对应的 `._Symbols` 元数据文件，并且这个隐藏文件被错误地打包进了 `.xcarchive` 文件

> **在 Xcode 里通过 `Prodict > Archive` 这种方式来提交，目前这种方式并不会有这个问题**。

![](https://img.cdn.guoshuyu.cn/image-20250424105248246.png)

解决问题很简单，如果已经是 macOS 15.4 的用户，最简单的做法就是使用 Xcode 的  `Prodict > Archive`  ，或者手动删除该文件：

```bash
bash 代码解读复制代码unzip -q app.ipa -d x
rm -rf app.ipa x/._Symbols
cd x
zip -rq ../app.ipa .
cd ..
rm -rf x
```

或者 `flutter build ipa --release ` 之后，执行一个 `./cleanup.sh `  ：

```sh
sh 代码解读复制代码IPA_PATH="build/ios/ipa/your_app_name.ipa"
# export IPA_PATH="$(find "build/ios/ipa" -name '*.ipa' -type f -print -quit)"

if [ -f "$IPA_PATH" ]; then
  echo "Checking for unwanted files like ._Symbols in $IPA_PATH"
  unzip -l "$IPA_PATH" | grep ._Symbols && zip -d "$IPA_PATH" ._Symbols/ || echo "No ._Symbols found"
else
  echo "IPA not found at $IPA_PATH"
fi
```

当然，暂时不要升级  macOS 15.4 是最好的，不过苹果说这个问题已经修复，所以可以确定基本就是系统升级的 bug：

![](https://img.cdn.guoshuyu.cn/image-20250430084138990.png)

接下来的问题是 [#166333](https://github.com/flutter/flutter/issues/166333) 的 「Could not register as server for FlutterDartVMServicePublisher」 ，问题还是和 macOS 15.4 和 Xcode 关联，主要影响的是  macOS 15.4 上的模拟器，会让 iOS 模拟器上的 `flutter attach` 不起作用。

> 大概问题就是调试时，将 DartVM 发布为 mDNS 服务有问题。

如果需要在 iOS 模拟器上使用 `flutter attach`，可以从 Xcode 复制 Dart VM Service 的 url ，然后在命令行进行传递 `flutter attach --debug-url` ：

![](https://img.cdn.guoshuyu.cn/image-20250424110009304.png)

其实这个问题大部分时候不会影响正常开发和发布，只是对于有洁癖的开发而言，确实有点恶心，而 Flutter 官方的修复也很值得吐槽，就是把 error 变成 warning：

![](https://img.cdn.guoshuyu.cn/image-20250424110256279.png)

另外值得一提的是，如果在 macOS 上通过 TestFlight 安装 App 并允许本地网络访问，之后在模拟器中再安装的 App 也可以正常工作。

> 只能说，一个 Bug 背后，总有一个更骚的 fix 途径。

目前苹果也确定了这是它们的 bug 导致，只能说这一届是我看到最差的 iOS/macOS ：

![image-20250430084558369](https://img.cdn.guoshuyu.cn/image-20250430084558369.png)

![](https://img.cdn.guoshuyu.cn/image-20250430084634380.png)

![](https://img.cdn.guoshuyu.cn/image-20250430084745437.png)

接着就是 [#165656](https://github.com/flutter/flutter/issues/165656) 的 hot restart 问题，在 iOS 上会出现 hot restart 需要等待几分钟的问题，这个问题目前看起来和 Flutter 里的 iproxy 有关系：

![](https://img.cdn.guoshuyu.cn/425517395-24d3deeb-b584-44f2-9b79-e3f2dd4bddc2.gif)

> 这里的 iproxy 是一个命令行工具，一般用在和 USB 连接在 macOS 上的 iOS 设备进行通信的场景，它是 usbmuxd（USB Multiplex Daemon）的一部分，iproxy 的主要功能是将本地的 TCP 端口映射到 iOS 设备上的端口，从而实现通过 USB 进行网络通信而无需依赖 Wi-Fi。

目前看起来这个问题主要是由  `iproxy`  的内部错误引起，这个错误会导致偶尔的数据丢失（并非所有数据都在主机和设备之间转发），主要是由  `select`+ `send ` 的时候，比如 `select`  时 `fd` 是可写的，但随后的 `send（fd， ...）` 返回 `EAGAIN` 而不是 Success。

而好消息是， `iproxy` 的新版本不受影响：不是因为处理 `send` 返回的 `EAGAIN`，而是新版本切换到 `poll` 而不是 `select` ，从而没有出现类似的问题。

目前临时的修复方式，可以尝试将 Flutter SDK 中的 `iproxy` 替换为 brew 中的版本：

```markdown
$ brew install libimobiledevice

# Go to the root of the Flutter SDK
$ cd flutter_sdk

# Kill old versions of iproxy and related binaries (though iproxy alone should be enough)
$ rm -rf bin/cache/artifacts/usbmuxd/* bin/cache/artifacts/libimobiledevice/*

# Copy newer versions installed by brew
$ cp `which iproxy` bin/cache/artifacts/usbmuxd/
$ cp `which idevicescreenshot` bin/cache/artifacts/libimobiledevice
$ cp `which idevicesyslog` bin/cache/artifacts/libimobiledevice
```

> 另外这个问题，在使用 cpu profiler 的情况也可能会出现 lost connection to device 。

除此之外，[#167343 ](https://github.com/flutter/flutter/issues/167343)目前在  iOS 18.5 Public Beta 上会出现某些 font weights 会出现  "thin font"  问题：

![](https://img.cdn.guoshuyu.cn/image-20250424114741357.png)

> 猜测也可能只是使用 `CupertinoSystemDisplay` 字体系列的字体导致，切换到 `CupertinoSystemText` 可以解决字体粗细问题，但字母间距将比以前更紧密。

虽然不知道是什么问题，但是 iOS 18.5 beta4 修复了这个问题，只能说，苹果现在的稳定性是真的越来越不可靠了：

![](https://img.cdn.guoshuyu.cn/image-20250430083757453.png)

最后，还有个 [#138464](https://github.com/flutter/flutter/issues/138464) 的老问题，就是在 iOS 内输入某些文本后点击输入框，大概是因为 `autocorrect` 的缘故，会导致偶尔可能出现 crash ：

![311165301-130b72a9-c9d6-4e2f-aa00-73a377d880e4](https://img.cdn.guoshuyu.cn/311165301-130b72a9-c9d6-4e2f-aa00-73a377d880e4.gif)

目前看起来 3.30 已经在处理删除崩溃的断言，如果你想临时解决，可以试试：`keyboardType:TextInputType.name` +  `autocorrect:false `，因为其他 TextInputType 貌似 autocorrect 的关闭没起作用。

好了，基本上这就是 2025 年一季度你大概率会遇到的 iOS 大坑，其他的都是一些细枝末节的小事，比如修复了 iOS 上 PlatformView 出现闪烁问题之类。

那么，2025 年你是否还遇到什么奇葩 iOS 大坑？



 

