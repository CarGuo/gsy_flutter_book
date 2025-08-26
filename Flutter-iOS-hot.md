# Flutter 又双叒叕可以在 iOS 26 的真机上 hotload 运行了，来看看又是什么黑科技

在之前的 [《iOS 26 beta1 重新禁止 JIT 执行》](https://juejin.cn/post/7514490441317220364) 我们聊过，iOS 18.4 beta1 禁止了 Debug 时  `mprotect ` 的 RX 权限，然后 iOS 18.4 beta2 又放开了，但是在 iOS 26 beta1 又重新禁止了，所以再次导致 Flutter 在 Debug 运行到 iOS 26 真机时又出现  ` mprotect failed: Permission denied` 的问题。

> 因为 Dart 就算是 Debug 的 JIT 运行，在电脑上还是会编译成二进制 Kernel AST 这种 IR ，而在 iOS 上 Dart 不管是 JIT 运行还是进行 hotload 的时候，都需要涉及代码在内存从 RW 变成 RX 的调整，在此之前是通过  `mprotect `完成，而这在 iOS 26 被禁止了。

当然，**每次说这个问题都有人问为什么 JIT 需要涉及 RW 变成 RX 的调整**，它不是解释执行吗？今天就顺带一篇聊完这个问题。

首先答案肯定不是，JIT 是即时编译，这里举个简单的例子：

- 正常的解释执行，可以理解为它只翻译不记录，也就是类似你请了一个翻译，解释运行是一直实时翻译但是不记录
- 而 JIT 虽然也需要翻译，但是它是会编译的成机械码的，对于 JIT 而言，当一个函数被确定为“热点”后，后台的 JIT 编译器会为它生成高度优化的原生机器码，而这段新生成的二进制代码就必须被写入到「可执行」的内存区域中去运行

> 也就是，解释运行是一直实时翻译但是不记录，而 JIT 是翻译一次之后，内容的重点都转成中文了，再听的时候，你就是直接听中文了，这就是两者的差别。

**那有大聪明就要说了，为什么不直接申请 RWX 呢**？那肯定是申请不了啊，现代操作系统都有 **W^X** (Write XOR Execute，即“写入”和“执行”互斥) 特性，基于安全考虑，原则上**一块内存区域，不能同时拥有“可写”(W)和“可执行”(X)两种权限。** 

而在此之前，Flutter 会申请一个 RW 的内存，用于写入翻译好的，或者 hotload 的代码，然后完成写入后，就通过 `mprotect`  将其修改为 RX，从而让代码可以被执行。

**那为什么 iOS 26 之前，Flutter 可以通过 mprotect  实现内存从 RW 到 RX**？实际上并不是 Flutter 或者 App 有这个权限，而是在此之前，iOS 为调试构建的应用提供了一个名为 `get-task-allow` 的特殊授权（entitlement）：

> 这个授权的主要目的是允许调试器（如 LLDB）附加到应用进程并进行控制，而这个能力，可以让带有这个授权的应用，在代码签名验证上会受到较宽松的限制，实际上表现为允许了应用自身修改其可执行内存的支持。

而现在这个能力，在 iOS 26 的真机上被限制了，也就是在  iOS 26 的真机上，就算你是 Debug， App 本身再也不能获得批准修改内存权限的能力。

那为了解决这个问题，Flutter 临时想到了一个 “曲线救国”策略，**因为实际上修改内存权限的能力还是在的，只是普通 App  不行而已**。

在开发过程中，LLDB 还是拥有苹果授予的特殊权限，可以修改应用的内存 ，所以这次的 Flutter 这次实现的临时补丁在于**让 Flutter 应用在需要执行新代码时，暂停下来，主动通知旁边的调试器，让调试器利用它的特权来帮忙把代码设置为“可执行”，然后再继续运行**：

> 因为 LLDB 在设备上并非直接与应用交互，而是通过一个名为 `debugserver` 的中间进程，`debugserver` 是一个由苹果签名、并被授予了特殊私有授权（private entitlements）的系统级程序，这些授权（例如 `com.apple.private.memorystatus`）赋予了它检查和修改其他进程内存空间的强大能力，其中就包括更改内存页的保护权限。

而具体表现为：

- 创建了一个专门用于“求助”的  `NOTIFY_DEBUGGER_ABOUT_RX_PAGES` 函数，主要是为了让 Flutter 在需要执行新代码时，不再调用被禁止的 `mprotect`，而是转而调用这个新的“求助”函数  `NOTIFY_DEBUGGER_ABOUT_RX_PAGES`

- 而 `NOTIFY_DEBUGGER_ABOUT_RX_PAGES` 里面实际什么都没有，它是一个断点函数，用于“暂停”代码运行，通过“求助” LLDB，让 LLDB 拿到应用传过来的新代码的内存地址，让 LLDB 去修改内存权限

举个例子，在此之前，mprotect 的实现是：

- **申请一块“毛坯房”**: Dart VM 向 iOS 系统申请一块内存，这块内存默认是“可读可写”（RW）的，就像一间空房间，你可以在墙上写字画画

- **在“毛坯房”里装修**: 当你修改了 Dart 代码并触发热重载时，JIT 编译器会快速地将你的新 Dart 代码编译成机器能直接运行的二进制指令，然后把这些指令写入到刚才申请的那块内存（“毛坯房”）里

- **挂上“办公室”的牌子**: “装修”完成后，Dart VM 会调用 `mprotect` 函数，告诉 iOS 系统：“我已经把这间房装修好了，现在请把它的属性从‘可读可写’（RW）改成‘可读可执行’（RX）”

在 iOS 26 之前，iOS 系统会批准这个请求，于是这块内存就成功变成了可执行的代码区，热重载完成。

而现在iOS 26 的安保升级了，大楼管理员（iOS 系统）发布了新规定：**“任何房间（App）都不允许自己给自己挂上‘可执行办公室’的牌子，以防有人把沉重墙砸了。”**

所以，之前第三步直接调用 `mprotect` 的方法行不通了，会被管理员直接拒绝（Permission Denied），所以现在需要走新的“后门”：

- **申请一块特殊的“双门房间”**: Dart VM 现在向系统申请一种特殊的内存，这块内存天生就有两个“入口”（虚拟地址），一个入口的权限是“可读可写”（`RW`），另一个入口的权限是“可读可执行”（`RX`），这就是所谓的“双重映射”，你可以想象成虽然只有一间房，从 A 门进去只能写字画画，从 B 门进去只能读取和执行
- **从“写字”的门进去装修**: JIT 编译器像以前一样，通过“可读可写”的 A 门，把新代码编译成机器指令写进去
- **请“大楼保安”（Debugger）来开门**: App 自己没有权限激活那个“可执行”的 B 门，于是它调用一个新增的、特殊的函数 `NOTIFY_DEBUGGER_ABOUT_RX_PAGES`，这个函数就像是按下一个求助按钮，专门通知正在外面巡逻的“大楼保安”，也就是你连接的调试器（LLDB）。
- **“保安”代为授权**: 调试器拥有更高的权限，它收到了求助信号，于是它替 App 向系统管理员打报告：“我确认过了，这间房没问题，可以激活它的‘可执行’入口B门” ，而因为请求来自更高权限的调试器，所以系统管理员就批准了

也就是，在新流程上，虽然还是同一个内存，但是我们用两个“地址”欺骗了保安（LLDB），让保安帮我们激活 RX 地址，这就是这次调整的 “双重映射” 实现。

# 具体实现

**新的流程上，核心关键在于  `NOTIFY_DEBUGGER_ABOUT_RX_PAGES`** ，`NOTIFY_DEBUGGER_ABOUT_RX_PAGES` 本身几乎不执行任何操作，因为它的本质是一个“钩子”，这个函数会被配置到 LLDB 的断点里：

![](https://img.cdn.guoshuyu.cn/image-20250624084631683.png)

也就是，`NOTIFY_DEBUGGER_ABOUT_RX_PAGES` 是一个会触发 LLDB 断点的函数，它是通过 flutter_tools 下的脚本进行绑定断点，另外这个函数还有对应声明：

- `__attribute__((noinline))`: 强制禁止内联优化，它确保了无论编译器优化级别多高，对该函数的调用都会以一个真实且独立的函数调用指令（`call` 或 `bl`）存在于最终的二进制文件中，因为它需要为调试器提供了一个稳定且可预测的地址来设置断点 
- `__attribute__((visibility("default")))`: 函数的符号标记为“公开”，所以在动态链接时对外部可见，这意味着像调试器这样的外部进程可以通过符号名称在应用的可执行文件中找到它 
- `extern "C"`: 声明指示编译器使用 C 语言的链接规范，即不进行 C++ 的名称修饰（name mangling），这保证了函数在符号表中的名称就是简单的 `_NOTIFY_DEBUGGER_ABOUT_RX_PAGES`，为一个外部工具提供了可预测的、稳定的钩子名称 。  

![](https://img.cdn.guoshuyu.cn/image-20250623173807925.png)

而在适配上，会有一个 `ScopedExcBadAccessHandler`  对象用于处理执行失败，**这个内部类是一个临时的异常处理器**，专门用来处理 `EXC_BAD_ACCESS` 类型的异常，也就是尝试执行「不可执行的内存」或访问「无效内存」引起的问题：

- 在构造 `ScopedExcBadAccessHandler()` 时，它会使用 Mach 内核的 `thread_swap_exception_ports` API，为当前线程安装一个自定义的异常处理器
- 通过 `IgnoreExceptionAndReturnToCaller` 让程序会忽略这个异常，并将程序执行点（PC 寄存器）设置到发生异常的函数的返回地址（LR 寄存器），同时在返回值寄存器（X0）中放入一个特殊的错误码 `0xDEADDEAD`

![](https://img.cdn.guoshuyu.cn/image-20250624090005158.png)

这个机制被用在 `CheckIfRXWorks` 函数中用来安全地“试错”，它会尝试执行一块动态生成的代码，如果因为权限问题导致执行失败触发 `EXC_BAD_ACCESS`，程序不会崩溃，而是会得到那个特殊的返回值 `0xDEADDEAD`，从而让 VM 知道 JIT 路径走不通。

![](https://img.cdn.guoshuyu.cn/image-20250623174509692.png)

而 `CheckIfRXWorks` 函数是在启动时判断“可行性检查”，这个函数在 VM 初始化时被调用，用来探测当前的运行环境是否真的允许 JIT 编译：

- 尝试分配一块可执行的内存
- 检查这块内存的开头是否已经被调试器写入了 "IHELPED!" 这个“暗号”，以确认调试器脚本已经正确加载，这个“暗号”是前面 LLDB 的脚本设置，用于判断 LLDB 和脚本状态是否符合要求
- 将内存权限改为可写（RW），写入一小段简单的机器码（一个计算 square  的函数）
- 将内存权限改回只读（R）或可读可执行（RX）
- 使用上面提到的 `ScopedExcBadAccessHandler` ，尝试调用刚才写入的 square 函数
- 检查返回值，如果返回值是正确的结果（例如 11*11=121），则证明 JIT 可行，如果返回值是 `0xDEADDEAD`，则证明执行失败，JIT 不可行

![](https://img.cdn.guoshuyu.cn/image-20250623174239486.png)

通过 `CheckIfRXWorks` 的返回结果会直接决定 `can_jit` 变量的值，进而影响 VM 的后续行为，如果是不能 JIT，那么在` VirtualMemory::AllocateAligned`  分配内存时，当 Dart VM 为 JIT 代码分配了一块内存区域后，它不再直接尝试调用 `mprotect`，而是在在真正使用这块内存之前，插入了对 `NOTIFY_DEBUGGER_ABOUT_RX_PAGES` 的调用 ：

![](https://img.cdn.guoshuyu.cn/image-20250623173452785.png)

大致核心流程有：

- 先申请可执行的内存地址 RX

- 判断当前必须启用“双重映射”，通过 `vm_remap` 让新的虚拟地址 RW（`writable_address`）指向与原始 RX `address`  完全相同的物理内存，此时你的 App 里就有了两个不同的虚拟地址，但它们都通往同一块内存
- 在映射创建成功后，立刻调用 `NOTIFY_DEBUGGER_ABOUT_RX_PAGES`，请求调试器介入，完成后续的“激活”工作，通知 lldb 来“激活”原始的 RX 区域，**因为一个普通的 App ，无权创造出未经签名和验证的、新的可执行代码页**。
- 通过 `Protect` 函数（它包装了 `mprotect`）对新的 RW 地址设置为 `kReadWrite`，因为它是一个全新的地址，所以可以被定义为可读写属性，从而支持被 JIT 编译器写入代码
- 返回的  `VirtualMemory` 对象，同时记录了原始的 RX 地址和新建的 RW 别名地址

说了那么多废话，实际上其实就是：**通过「双地址映射」让两个地址指向一个内存，一个写入，一个执行，然后利用  `NOTIFY_DEBUGGER_ABOUT_RX_PAGES` 的断点，让 LLDB 执行授权赋予 RX ，做到在用一块内存上实现 Debug 时具备 RWX 的效果**。

**那为什么说这是一个临时解决方案呢**？主要原因有：

- 首先，这个方案预计会为每个代码空间页的分配增加约 500 毫秒的延迟（`adds ~500ms of latency per code space page allocation`）

- 其次，操作系统必须挂起应用进程，切换到 `debugserver` 进程的上下文，完成后再切换回来，这是一个耗时的操作
- 最后，整个机制的前提是必须有一个调试器被附加到应用进程上，并且该调试器被正确配置了相应的拦截脚本，环境要求高，需要 IDE、Flutter 工具链、LLDB 和 iOS 版本之间脆弱的协同

![](https://img.cdn.guoshuyu.cn/image-20250624110314397.png)

所以，**未来长期考虑，还是需要一个高性能的 Debug 解释器来支持**，而目前这个实现，主要还是为了让 Flutter 开发者可以快速在 iOS 26 的真机上进行 Debug 开发的“后门”，但是也可以看得出来，系统安全确实是一个有趣的攻防过程。

那么，你觉得这个后门可以存活多久？

# 参考资料

- https://github.com/dart-lang/sdk/blob/main/runtime/vm/virtual_memory_posix.cc

- https://github.com/dart-lang/sdk/commits?author=mraleph&since=2025-05-31&until=2025-06-23 

- https://github.com/flutter/flutter/issues/163984