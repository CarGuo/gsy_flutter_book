# 不要升级，Flutter Debug 在  iOS 18.4 beta 无法运行，提示  mprotect failed:  Permission denied

近期如果有开发者的 iOS 真机升级到 18.4 beta，大概率会发现在 debug 运行时会有 `Permission denied`  的相关错误提示，其实从 log 可以很直观看出来，就是 Dart VM 在初始化时，对内核文件「解释运行（JIT）」时出现权限不足的问题：

```
../../../flutter/third_party/dart/runtime/vm/virtual_memory_posix.cc: 428: error: mprotect failed: 13 (Permission denied)
version=3.6.0 (stable) (Thu Dec 5 07:46:24 2024 -0800) on "ios_arm64"
pid=3252, thread=259, isolate_group=vm-isolate(0x107205400), isolate=vm-isolate(0x107369000)
os=ios, arch=arm64, comp=no, sim=no
isolate_instructions=108e375a0, vm_instructions=108e375a0
fp=16bb19560, sp=16bb19540, pc=109889864
  pc 0x0000000109889864 fp 0x000000016bb19560 Dart_DumpNativeStackTrace+0x18
  pc 0x000000010943aeb8 fp 0x000000016bb19580 dart::Assert::Fail(char const*, ...) const+0x30
  pc 0x0000000109536100 fp 0x000000016bb19a30 dart::Code::FinalizeCode(dart::FlowGraphCompiler*, dart::compiler::Assembler*, dart::Code::PoolAttachment, bool, dart::CodeStatistics*)+0x82c
  pc 0x00000001095f51c8 fp 0x000000016bb1a040 dart::StubCode::Init()+0x31c
  pc 0x0000000109485c30 fp 0x000000016bb1ab00 dart::Dart::DartInit(Dart_InitializeParams const*)+0x2a9c
  pc 0x0000000109870310 fp 0x000000016bb1ab20 Dart_Initialize+0x3c
  pc 0x0000000108f1aaf4 fp 0x000000016bb1b0f0 flutter::DartVM::Create(flutter::Settings const&, fml::RefPtr<flutter::DartSnapshot const>, fml::RefPtr<flutter::DartSnapshot const>, std::_fl::shared_ptr<flutter::IsolateNameServer>)+0x1d60
  pc 0x00000001093f17dc fp 0x000000016bb1b850 flutter::Shell::Create(flutter::PlatformData const&, flutter::TaskRunners const&, flutter::Settings, std::_fl::function<std::_fl::unique_ptr<flutter::PlatformView, std::_fl::default_delete<flutter::PlatformView>> (flutter::Shell&)> const&, std::_fl::function<std::_fl::unique_ptr<flutter::Rasterizer, std::_fl::default_delete<flutter::Rasterizer>> (flutter::Shell&)> const&, bool)+0x310
  pc 0x0000000108e3b060 fp 0x000000016bb1c5c0 -[FlutterEngine createShell:libraryURI:initialRoute:]+0x934
  pc 0x0000000108e42c4c fp 0x000000016bb1c630 -[FlutterViewController sharedSetupWithProject:initialRoute:]+0x1cc
  pc 0x0000000108e42a58 fp 0x000000016bb1c660 -[FlutterViewController awakeFromNib]+0x58
```

具体原理就是在于：**从目前 iOS 18.4 beta 上看，iOS 加强了对应用运行时修改内存权限的限制，也就是上面出现 `mprotect failed: 13 (Permission denied) ` 的原因**。

> mprotect 全称是 "memory protect" ，可以用于修改内存页的保护属性，让 App 可以动态调整某块内存的访问权限，例如将 RX 只读执行权限切换为 RW 可读写权限。

![](https://files.mdnice.com/user/4488/2d64a1ad-32bb-4ac5-8359-57bb92f33173.png)

而为什么 Flutter 在 Debug 时需要 mprotect ？其实这就要说到 Dart VM ，虽然在 Debug 模式下 Dart VM 是通过 JIT 模式解释执行的，但是**从 Dart 2.0 之后就不再支持直接从源码运行**，对于 Dart 代码现在会统一编译成一种「预处理」形式的**二进制 dill 文件**，我们一般称它会 Kernel AST 文件：

![](http://img.cdn.guoshuyu.cn/20250302_iOS184/image1.png)

**也就是如今在 Dart 里，就算你是 JIT 运行，那么你也是跑着一个二进制的 Kernel dill** ，只是 Kernel AST 不包含解析和优化：

> 简单说，它仅仅是对源码进行了二进制加工转化， 让 Dart 代码从高级语法转换为统一且平台无关的中间格式。

所以 Flutter 在 debug 运行时， JIT 运行的是一个**未签名的二进制文件**，并且需要直接 hotload ，也就是需要 Dart VM 在运行时根据  Kernel 二进制文件生成机械码，并且在可以接受 hotload 的热更新，所以它是通过 VM 来“解释”和“生成“，所以它会需要 mprotect 的系统调用。

> 比如上面的 StubCode 相关部分，在当前的 kernel JIT 模式下就极度依赖 VM 运行时的动态生成。

当然，这个过程依赖于 `get-task-allow ` ，`get-task-allow ` 可以允许其他进程 （如调试器） 附加到当前 App 上，让额外的进程获取到当前应用的任务端口，从而让它们可以执行诸如在内存上写入和读取内容之类的行为，最终达到 hotload 的目的。

**那为什么在 release/profile 就不会有问题呢？很简单，代码已经被完全打包成机械码，并且需要生成的代码都包括在 snapshot 内，所以并不需要上述这些“魔法加持”**。

那么回过头来，从 iOS 18.4 开始， 系统加强了对应用运行时修改内存权限的限制，具体来说就是：

> **系统不再允许未经代码签名的二进制文件通过 JIT 编译直接执行，之前可以是因为这是一个“安全漏洞”，因为之前的机制允许开发者在真机上绕过某些签名要求**，也就是 iOS 18.4 的新安全策略禁止了这种未经签名的动态代码生成支持。

那么到这里你应该大概了解了问题的原因，目前 Flutter 官方表示：**在他们热修复此问题之前，尽可能先请不要升级到 iOS 18.4 beta**。

而目前官方修复的思路主要大概是：

- 在 Flutter debug 构建时使用解释代码支持
- 在解释代码下支持  `dart：ffi`
- 解决 debug 解释字节码可能带来的性能下降问题

而目前暂时评估的方向有：

- 增加 simarm64（Simulator for ARM64）配置支持，让 Dart VM 可以解释生成的代码
- 恢复 Dart 字节码运行
- 混合模式执行，其中 App 通过 AOT/JIT  签名编译，并且仅解释修改后的代码

其实这里的第三点「混合模式执行」很有趣，因为这是 Flutter 热更新框架 shorebird 在 iOS 上目前的热更新方案：**App 整体通过 AOT 运行，只有热更新 patch 存在的时候，针对该部分进行解释执行** ，也就是 shorebird 针对 Dart VM 自己“魔改”并“插入”了一个解释器，所以可以看到 shorebird 的 Eric (Flutter 前创始人) 针对和这个也和 Dart/Flutter 团队进行了密切的沟通：

![](http://img.cdn.guoshuyu.cn/20250302_iOS184/image2.png)

事实上，Eric 对于 Dart VM 这部分工作还是很“担心的”，毕竟 shorebird 作为分支方，这种修改合并无疑会给他们带来许多工作量，而如果 Dart 团队的方案能尽可能贴近 shorebird ，那就最好不过了：

![](http://img.cdn.guoshuyu.cn/20250302_iOS184/image3.png)

目前来说，好消息在于，只要你的真机不升级到 iOS 18.4 beta ，那么就不会有影响，而 Flutter/Dart 团队大概率会在 iOS 18.4 正式发布前修复这个问题，毕竟方向都有了。

当然，这也体现了“利用漏洞”完成需求的可靠性很低，因为你不知道哪天平台就把后门关闭了。







