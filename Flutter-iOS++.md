# iOS 26 正式版即将发布，Flutter 完成全新 devicectl + lldb 的 Debug JIT 运行支持

在之前的 [《Flutter 又双叒叕可以在 iOS 26 的真机上 hotload》](https://juejin.cn/post/7519118964975992886) 和 [《Flutter 在 iOS 真机 Debug 运行出现 Timed out *** to update》](https://juejin.cn/post/7529752760076009508) 我们聊过，由于 iOS 26 开始，Apple 正式禁止了 Debug 时 `mprotect `的 RX 权限，导致了 Flutter 在 Debug 运行到 iOS 26 真机时会有 `mprotect failed: Permission denied` 的问题 。

> 在 iOS 上 Dart 不管是 JIT 运行还是进行 hotload 的时候，都需要涉及代码在内存从 RW 变成 RWX 的调整，

而为了快速解决这一问题，Flutter 官方之前临时实现了一个过度方案：

- **让 Flutter 应用在需要执行 JIT 新代码时，“暂停下来”（断点），主动通知旁边的调试器，让调试器利用它的特权来帮忙把代码设置为“可执行”，然后再继续运行**
- **通过「双地址映射」让两个地址指向一个内存，一个写入，一个执行，然后利用 `NOTIFY_DEBUGGER_ABOUT_RX_PAGES` 的断点，让 lldb  执行授权赋予 RX ，做到在用一块内存上实现 Debug 时具备 RWX 的效果**

对详细实现感兴趣的可以看之前的  [《Flutter 又双叒叕可以在 iOS 26 的真机上 hotload》](https://juejin.cn/post/7519118964975992886)  ，而从临时实现方案就可以看出来，这一个非常 hack 补丁，并且这个方案预计会为每个代码空间页的分配增加约 500 毫秒的延迟，在加上实际工作中和 `debugserver` 还有等待 Xcode 建立调试会话的时间，让 iOS 在 Debug 开发中十分容易出现 `Timed out *** to update` 等问题。

> 事实上针对这类问题苹果也发现了“盲点”，特别还需要 Xcode 启动配合等繁琐操作，所以在 Xcode 16 增加了 devicectl 和 Xcode 的命令行调试器 `lldb` 协同工作的支持：![](https://img.cdn.guoshuyu.cn/image-20250826133722760.png)

而针对这个问题，Flutter 在 **Xcode 16**  也终于实现了新的调整[#173443](https://github.com/flutter/flutter/pull/173443/)，通过新的 `devicectl` + `lldb` 集成到 `flutter run` 命令来回归 Apple 官方的 debug 体系：

- 通过  `devicectl`  实现安装启动：  `devicectl`   作为在 Xcode 15 中引入的控制工具，它主要负责将编译好的应用包（`.app`）安装到物理设备上，并负责启动应用进程![](https://img.cdn.guoshuyu.cn/image-20250826102637181.png)
- 通过  `lldb`  实现 JIT 和调试运行：作为 LLVM 项目的一部分，`lldb` 是 Apple 标准的底层调试器，在新架构中它将作为核心的调试传输层，负责附加到由 `devicectl` 启动的应用进程，并建立起和 Dart VM 进行通信的桥梁

具体可以在 `flutter_tools` 的 `lldb.dart` 看到，`launchAppWithLLDBDebugger` 启动之后，就会执行 lldb 的 `attachAndStart ` ：

![](https://img.cdn.guoshuyu.cn/image-20250826111933554.png)

而对于 `attachAndStart `  ，主要核心就有：

- 启动一个定时器，如果一分钟内没有成功，提示超时
- 设置一个断点 `_setBreakpoint`
- 依附进程  `_attachToAppProcess` 

**那为什么需要在执行 lldb 的时候通过  `_setBreakpoint` 添加一个断点呢**？实际上这就是在前面临时方案基础上的完善， `_setBreakpoint` 的主要目的就是：

- 设置 `NOTIFY_DEBUGGER_ABOUT_RX_PAGES` 作为 lldb 的断点

- 写入一个 `_pythonScript ` 脚本，当断点触发时，利用 lldb 的权限执行脚本，创建一个新的 rx 内存

![](https://img.cdn.guoshuyu.cn/image-20250826112634544.png)

关于 `NOTIFY_DEBUGGER_ABOUT_RX_PAGES` 作为断点我们在之前讲过，它是 Dart VM 在 `VirtualMemory::AllocateAligned` 时，会通过 `NOTIFY_DEBUGGER_ABOUT_RX_PAGES`  触发，去让 lldb 用它的权限申请执行：

![](https://img.cdn.guoshuyu.cn/image-20250826113442897.png)

而对于在 lldb 里执行的 py 脚本，它主要是：

- 当 Flutter 应用的 Dart VM 需要一块新的内存用于 JIT 编译时，调用这个名为 `NOTIFY_DEBUGGER_ABOUT_RX_PAGES` 的函数，这个调用会触发预设的断点

- 断点触发后，`_pythonScript` 的代码立即被执行

  - 从寄存器 (`x0`, `x1`) 读取 Dart VM 请求的内存地址和长度

  - 利用 lldb 的 `WriteMemory` 向该内存地址写入数据，这个“写入”动作是关键，它会强制 iOS 系统为这块内存做好准备

- 写入一个 `b'IHELPED!'` 的“回执”信号，以便 Dart VM 确认操作已成功
- 执行完毕后，它返回 `False`，告诉 lldb “任务完成，请立即让应用继续运行”

![](https://img.cdn.guoshuyu.cn/image-20250826112708079.png)

之后，通过 `lldb device process attach --pid` 的方式，让进程被纳入“开发者调试上下文”，从而支持 JIT 权限：

![](https://img.cdn.guoshuyu.cn/image-20250826113829855.png)

前面说起来比较抽象，具体可以理解为：

### _attachToAppProcess 获取“权限” ：

因为系统的 W^X 安全策略，`_attachToAppProcess` 的核心作用就是利用 lldb 附加的特权，为整个应用进程**解锁**了这个限制。

在这一步完成之后，应用进程的状态从“不允许 JIT”变成了“**理论上可以 JIT**”，它获得了让内存页变为可读、可写、可执行 (RWX) 的**可能性**。

但是，**仅仅有可能性是不够的** ，因为Dart VM 在运行时和 hotload 是**动态地、按需地**需要新的可执行内页 page，它需要一个“机制”来实现，在需要的时候真正地去执行这个“将内存页变为 RWX”的操作，而 App 本身的 Dart VM 本身没有这个权限，所以它无法自己完成这个操作。

> 这时，它就像一个身处大楼内、知道自己需要打开一扇门，但自己手上没有钥匙的住户。

### _setBreakpoint  建立“通信与执行机制”

`_setBreakpoint` 的作用就是建立这个缺失的机制，类似于：

- **建立通信渠道**：Dart VM 被设计成在需要新内存页时，会去调用 `NOTIFY_DEBUGGER_ABOUT_RX_PAGES` 函数，这就像住户去按下一个特定的“求助”门铃

- **部署执行者**：`_setBreakpoint` 告诉 lldb  “请一直监听这个‘求助’门铃 (`NOTIFY_DEBUGGER_ABOUT_RX_PAGES`)”，这就相当于雇佣了一位管家，让他守在门铃旁边

- **下达具体指令**：`_setBreakpoint` 还通过 `_pythonScript` 告诉管家：“一旦门铃响起，你就用你手上的万能钥匙 (`WriteMemory`特权)，去帮住户打开他指定的那扇门 (在指定地址和长度的内存上执行操作)。”

所以，完整的流程是这样的：

- **`_attachToAppProcess`**：授予 lldb ，大楼的安全限制被解除了，你可以走进去，但是你没有钥匙，**这是前提条件。**

- **`_setBreakpoint`**：管家 (`_pythonScript`) 被部署到位，并且明确了工作指令（监听门铃并开门），**这是执行机制**，当你需要 JIT 的时候，就去按下门铃

所以 `_pythonScript` 是 Flutter lldb 架构的连接点，它作为一个实时协议适配器，在 lldb 的原生世界和 Dart VM 服务的托管世界之间进行翻译。

自此， lldb attach 成功后，Dart VM 在启动时会尝试打开 JIT Compiler ，当然，如果 lldb  失败，它将回退到使用过去的 Xcode 自动化支持：

![](https://img.cdn.guoshuyu.cn/image-20250826133300978.png)

![](https://img.cdn.guoshuyu.cn/image-20250826132230259.png)

所以，随着全新的 iOS 26 稳定版即将发布，Flutter 也完成了它全新 LLDB 调试的适配迁移，不过也可以看出，iOS 上的 JIT 持续支持，确实不是一件容易的事情。



