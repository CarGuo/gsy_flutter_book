# iOS 26 beta1 重新禁止 JIT 执行，Flutter 下的 iOS 真机 hot load 暂时无法使用

在之前的 [《Flutter iOS 大坑超汇总》](https://juejin.cn/post/7502875709885513764)我们聊过 iOS 18.4 beta mprotect failed: Permission denied 的问题，在 iOS 18.4 beta1 的时候， debug 运行会有 `Permission denied` 的相关错误提示，问题其实就是 Dart VM 在初始化时，对内核文件「解释运行（JIT）」时出现权限不足的问题。

> 只影响真机调试的 hot load。

而这个问题后来在 iOS 18.4 beta2  又可以正常使用了，原因是因为  `EXC_BAD_ACCESS`  从 iOS 18.4 中删除时没有提前通知，导致不少人出现问题来不及反应，所以官方最终回滚了这个操作，但也说了在未来的 iOS 版本中会“卷土重来”。

![](https://img.cdn.guoshuyu.cn/image-20250611143309881.png)

所以，现在在 iOS 26 beta1 里，它又回来了，近期如果更新到 iOS 26 的小伙伴应该又可以看到它的存在，当然网上有人说 iOS 要禁止 JIT 运行，这个就纯属胡扯了，**实际上调试器还是提供 JIT 代码运行，而在正在调试的进程中编译的 JIT 代码将无法运行**，为的就是缓解 App Fraud 滥用调试功能的情况：

![](https://img.cdn.guoshuyu.cn/image-20250611141842163.png)

这怎么理解？在此之前，Flutter 会利用 mprotect 动态修改内存的可读写，让 App 可以动态调整某块内存的访问权限，例如将 RX 只读执行权限切换为 RW 可读写权限，从而支持 hotload ：

![](https://img.cdn.guoshuyu.cn/image-20250611165809139.png)

而这个过程会依赖于 `get-task-allow `，`get-task-allow `可以允许其他进程 （如调试器） 附加到当前 App 上，让额外的进程获取到当前应用的任务端口，从而让它们可以执行诸如在内存上写入和读取内容之类的行为，最终达到 hotload 的目的。

而现在，系统开始加强了对应用运行时修改内存权限的限制，**不再允许未经代码签名的二进制文件修改后通过 JIT 编译直接执行** 。

这其实不只是 Flutter ，例如 StikJIT  ，它也是在 iOS 上的一个 JIT 工具，用于支持需要 JIT 的应用（如模拟器和某些开发工具）在非越狱设备上运行的支持，比如运行 pojav，而在 iOS 26  真机上，它依然可以运行，但是无法再启动 pojav ：

![](https://img.cdn.guoshuyu.cn/image-20250611141647684.png)

> 之前 StikJIT 主要通过调试服务器和` libimobiledevice`，向内核请求将特定内存区域标记为可执行，绕过 W^X 限制，底层也绕不开 mprotect 的支持。

当然，**这个问题主要是出现在真机，对于模拟器并不影响**，因为这个限制主要出现在 iOS 的 XNU 内核来强制执行，而 iOS 模拟器是在 macOS 上运行的应用，它们使用的是宿主内核，目前看 macOS 上用于辅助 JIT 的 `pthread_jit_write_protect_np` API 在 iOS 26 上已经不可用：

![](https://img.cdn.guoshuyu.cn/image-20250611170855713.png)

> 在 macOS 上存在 `com.apple.security.cs.allow-jit` 授权，它允许应用使用 `MAP_JIT` 标志通过 `mmap` 创建可写的然后变为可执行的内存，并使用如 `pthread_jit_write_protect_np` 这样的辅助 API 来管理 JIT 代码段的 W^X 状态 。  

所以，针对这个情况，为了让 Flutter 在 iOS 平台能继续支持 hot load ，需要支持使用解释器来执行 Dart 代码，之前提过的方案，已经可以暂缓，现在看来又要提上日程。

> 解释器的工作方式与 JIT 编译器不同在于，它需要逐条读取应用的 Dart 字节码，并直接执行每条字节码指令对应的操作，而这个过程不涉及在运行时生成新的本地机器码，也就不需要将内存页标记为可执行，从而规避了由于 `mprotect` 调用受限而导致 JIT 失败的问题。

修复的思路主要大概是：

- 在 Flutter debug 构建时使用解释代码支持
- 在解释代码下支持 `dart：ffi`
- 解决 debug 解释字节码可能带来的性能下降问题

而目前暂时评估的方向有：

- 增加 simarm64（Simulator for ARM64）配置支持，让 Dart VM 可以解释生成的代码
- 恢复 Dart 字节码运行
- 混合模式执行，其中 App 通过 AOT/JIT 签名编译，并且仅解释修改后的代码

这里的第三点「混合模式执行」很有趣，因为这是 Flutter 热更新框架 shorebird 在 iOS 上目前的热更新方案：**App 整体通过 AOT 运行，只有热更新 patch 存在的时候，针对该部分进行解释执行** 。

也就是 shorebird 针对 Dart VM 自己“魔改”并“插入”了一个解释器，所以可以看到 shorebird 的 Eric (Flutter 前创始人) 针对这个问题，在 18.4 的时候就和 Dart/Flutter 团队进行了密切的沟通：

![](https://img.cdn.guoshuyu.cn/image-20250611171855879.png)

> 所以这个变更对 shorebird 的热更新没有任何影响，感兴趣的可以看  https://juejin.cn/post/7477147173537366068

类似问题也不是 Flutter 特有，比如 StikJIT  等也受到影响，有问题的不是 JIT 运行过程，而是在 JIT 重新执行的过程被禁止，而目前看来 mprotect  应该不大可能再度回归，所以全新的 Flutter  iOS 解释器应该势在必行了。

你觉得这个 break change 这对你的影响大吗？

# 参考链接

https://github.com/flutter/flutter/issues/163984  

https://github.com/dart-lang/sdk/issues/60202 

https://github.com/apple-oss-distributions/xnu/blob/e3723e1f17661b24996789d8afc084c0c3303b26/bsd/kern/code_signing/ppl.c#L416