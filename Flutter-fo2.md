# 简单聊聊 Flutter 在鸿蒙上为什么可以 hotload ？

众所周知， Flutter 最大的特色之一就是 Debug 过程中支持 hotload ，不错的 hotload 体验对于开发效率十分重要，而在此之前，我们在 [《Flutter 又双叒叕可以在 iOS 26 的真机上 hotload》](https://juejin.cn/post/7519118964975992886) 聊过了 Flutter 和 iOS 在 hotload 上的爱恨情仇，那么在鸿蒙上，为什么 Flutter 也可以支持 hotload ？

![](https://img.cdn.guoshuyu.cn/image-20250701155611205.png)

首先我们知道 Flutter 在 Debug 下是 JIT 执行，也就是实际上 Dart 实际上并不是解释执行，而是即时编译的过程，而 hotload 也是基于 JIT 实现，所以很明显 Flutter 在鸿蒙上也是需要 RWX（可读写可执行） 类型的内存支持。

但是代操作系统都有 **W^X** (Write XOR Execute，即“写入”和“执行”互斥) 特性，基于安全考虑，原则上**一块内存区域，不能同时拥有“可写”(W)和“可执行”(X)两种权限，**并且鸿蒙内核从安全考虑，也会限制普通应用动态申请可执行内存的权限。

那基于这个前提， Flutter 是如何在鸿蒙上实现的 hotload ? 这里就不得不提 `prctl` :

![](https://img.cdn.guoshuyu.cn/image-20250701142209246.png)![](https://img.cdn.guoshuyu.cn/image-20250701142336695.png)

Linux 中的 `prctl()` 系统调用是一个多功能的接口，允许进程或线程控制其自身的各种行为方面，而鸿蒙 Next 集成了 POSIX 兼容层等支持，所以能兼容 Linux 调用很正常，**但是这些都不是重点，重点是这是一个非标 prctl 操作**。

`prctl(0x6a6974,...)` 属于是鸿蒙内核的定制信号，实际上这里的  `0x6a6974`  正是对应 "jit" 这个词的 ASCII 码：

- 6a = j
- 69 = i
- 74 = t

也就是实际上鸿蒙上是通过 `prctl()` 来控制在 Debug 时的 JIT 支持，而根据上述设置，可以猜测，在鸿蒙平台上，在 Debug 下可以通过 `prctl()` 可以临时申请可执行地址，并且只在非上架的签名有效：

![](https://img.cdn.guoshuyu.cn/image-20250701143525339.png)

而在 openHarmony 的相关源码里，我们可以看到不少地方都是通过    `0x6a6974`   来实现 JIT 执行的支持，这其实也算是鸿蒙为自身的 Hotload 留的一个后门：

![](https://img.cdn.guoshuyu.cn/image-20250701150906463.png)![](https://img.cdn.guoshuyu.cn/image-20250701154508987.png)

大胆猜测 DevEco Studio 下的热重载也是类似的途径，所以如果你在鸿蒙平台有 Debug JIT 或者 hotload 的需求，这或者是一个可行的方式。



# 参考资料

- https://gitcode.com/openharmony-tpc/flutter_engine/blob/oh-3.27.4-dev/DEPS_ohos

- https://gitcode.com/openharmony-sig/fluttertpc_dart_sdk/blob/flutter_3.27.4_deps/runtime/bin/virtual_memory_posix.cc

















