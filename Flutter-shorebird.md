# 深入聊聊 Flutter 里最接近官方的热更新方案：Shorebrid

热更新一直都是 Flutter 里的热门话题，毕竟 Flutter 的「先天属性」让它不像 RN 一样有 code push 这样的业内通用方案，不过这么多年下来 Flutter 也发展出了一些热更新的产品路线，比如：

- 用  js/ts 写控件来实现动态下发更新
- 通过 vue 模版来实现动态下发更新
- 通过 json 配置静态 UI 实现更新
- 通过对 Dart 的 DSL 和编码过程做处理来实现动态下发
- 通过提前内置控件模版占位实现动态更新
- ·····

它们都在不同场景有着各自的优劣，而今天我们要聊的 Shorebrid 就比较特殊，因为它是 Flutter 前创始人 Eric 的商业项目，从目前来看，它是 Flutter 业内最接近 RN  code push 的存在，或者说 Shorebrid  更懂 Flutter 在 code push 领域的产品体验。

目前大家在聊 Flutter 的热更新时，关注的核心主要有三点：

- 是否影响性能
- 是否合规
- 接入和退出成本

而从这几个纬度考虑的话，对于 Shorebrid 而言我们可以先有一个简单的结论：

- 性能上 Android 端没有变化，iOS 端根据不同情况会有部份削减
- 更新方式完全合规
- 接入方便，可以随时「一键退出」

那么 Shorebrid 在技术上又是如何做到以上三点的？**这就不得不提 Shorebrid 对于 Flutter Engine 和 Dart VM 的“魔改”**，或者你可以理解为，Shorebrid 对 Flutter 进行了一定程度的分叉。

简单来说，你需要在构建 Flutter 项目时把 `flutter build`  换成   `shorebird build` ，**那么看到这里，或者有人会觉得 Shorebrid 这样的实现「侵入性」或者「接入成本」不是很高**？毕竟连 cli 都换了。

但是事实上并非如此，使用 Shorebrid 时虽然需要通过   `shorebird build`  等 cli 在构建时接入 Shorebrid 分叉过的  Flutter Engine 和 Dart VM  ，但是日常开发里你依然可以使用原本的  `flutter build`  和  `flutter run`  去开发和构建。

> 因为 Shorebrid 的 cache 目录下会内置自己的 flutter lib，和你本地的 flutter 工程是可以直接区分开来的，只要你保证它们版本一致，例如通过 `shorebird flutter versions list`  切换到支持的 flutter 版本。

对于 Shorebrid， 你一般只需要在发布或者构建 patch 的时候接入即可，其他时候和你日常开发 Flutter 并没有区别，这主要也是因为 Shorebrid 虽然“魔改”了 Engine 和 VM ，但是它并没有进行破坏性的功能变动，只是“新增了支持”，基本不影响你在 Flutter 和 Shorebrid 之间切换。

> 甚至 Shorebrid 在 Flutter Engine 的“魔改”只有几百行代码，而真正的核心部份其实是在于 Dart VM 的定制逻辑。

**那 Shorebrid 又是如何进行热更新的？答案就是下发“二进制”的 patch 文件**，可能这时候你会觉得诧异，下发“二进制”能合规吗？没事，我们后面解释这个问题。

首先我们先了解 Shorebrid 的实现，在 Shorebrid 里，**如果在不存在任何 patch 更新的情况下，它和官方的 Flutter 是没有任何区别的，也就是从性能上和原有 Flutter 保持一致**。

而当存在热更新的 patch 文件时，根据平台又会有不同的情况：

- **Android 性能不会任何变化**，因为在 Android 上 Shorebrid 就是简单的二进制替换，Shorebrid 只需告诉 Dart VM 在运行时加载不同的 Dart 代码
- **iOS 上性能会有所变化**，因为在 iOS 上 Shorebrid 对于 patch 的部分需要解释执行，而没有变化的部分依然 AOT 运行

举个例子，我们先看 Android ，当你使用   `shorebird build`  构建完 Android 之后，cli 会将构建完的版本提交到 Shorebrid 集中的托管平台：

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image1.png)

然后**当你需要创建一个 patch 的时候，Shorebrid 会将你发布的版本下载下来**，然后进行对比，创建出一个最小差异的二进制 patch  进行发布：

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image2.png)

如果这时候你去看这个文件，就会发现它是一个大小只有几十 K 到几百 K 的 `dlc.vmcode`  二进制文件：

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image3.png)

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image4.png)



在 Android 上，Shorebrid 会通过下发这个文件来，最终在 Dart VM 层面实现二进制部分替换，从而完成动态化热更新的支持，**所以 Android 上 Shorebrid 一直是 AOT 的运行模式，性能基本没有变化**。

那为什么 Android 上可以采用这样的更新方式？这就不得不说 Google Play 的政策条件，如下图所示，官方在提及更新可执行文件时有一个例外要求：**限制不适用于在虚拟机或解释器中运行的代码**：

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image5.png)

**也就是虽然  Shorebrid 下发的是 AOT 的二进制代码，但是它不能直接在 Android 或者 JVM 上运行，它需要 Dart VM 才能运行**。

> 这里可能有人会有疑问，都是编译成机械码了，为什么还需要 VM ？这是因为系统没有提供对应的运行时支持，Dart 的 AOT 代码同样需要有相应的库实现和垃圾回收的 runtime 环境支持，就像 C 语言编译后还是需要依赖于运行时来提供 C 标准库的实现，又比如 so 库可以使用 Android 环境提供的精简版 libstdc++ 等。

但是这在 iOS 上不适合，**因为 App Store 上任何可执行代码都不允许动态下载**，所以在做热更新时，iOS 的开发人员只能使用解释器(interpreter) 来实现，但是完全使用解释器运行会导致 App 性能极低，所以在 iOS 上，Shorebrid 最终实现了：**未更改的代码依然在 CPU 上通过 AOT 运行，而更改的 patch 代码则通过 Shorebrid 实现的解释器运行到 Dart VM 上**。

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image6.png)

这样的实现可以尽可能让 Flutter 在 iOS 上贴近原有的性能，如果你的项目没有任何 patch ，那么它就不会有性能损耗，如果存在 patch ，那么就只会在运行到对应 patch 代码的时候才会有相应的性能损耗，当然这部分涉及到了 Dart VM 的“魔改”支持：**Shorebrid 在 VM 上增加了一个解释器和全新的 Linker**。

**解释器当然就是解析代码让其可以变为 JIT 的模式运行到 Dart VM 上**，这得益于 Dart 本身就同时具有 JIT 和 AOT 编译器两个工作流程，同时 Dart 本身在 JIT 模式下通常会保留有关源代码的信息，这些信息是 JIT 优化 hot code 的关键，同时也是 Shorebrid 让 Dart VM 能够实现“混合模式”运行的关键。

而这里 Linker 可能和我们在 iOS 上理解的链接器不大一样，它不会对代码进行签名，**它更多是通过在生成 patch 文件时判断具体函数是否直接在 CPU 上运行的作用**。

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image7.png)

前面说过，iOS 不允许动态下发任何可执行文件，所以 Shorebrid 不会下发任何可以直接在 CPU 上运行的东西，**甚至是 Dart 编译后 JIT 文件都不行**（还涉及签名问题）， Linker 的作用就是通过分析原有的 AOT 文件，然后通过对比快照 diff 在指令级别找到最小差异部分，而在没改变部分尽可能的在原有 AOT 文件下保留。

> **所有这里的 Linker 更像一个缝合器 ，主就是对比出不能在 CPU 运行的函数，然后剥离出来后续通过解释器运行**。

这里插一个题外话，**为什么 Dart 编译后的 JIT 文件都不行**？因为从 Dart 2.0 开始，Dart VM 就不能直接从原始代码解释执行 Dart ，VM 现在需要的是一个包含序列化的 Kernel AST 文件（dill 二进制文件），Dart 源码会通过前端 CFE 被处理为内核 AST ：

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image8.png)

> 二进制不等于就是可执行   Machine Code

而在  JIT 模式中，Flutter 并不会直接处理 Dart 本身的解析，而时通过另外一个 `frontend_server`  的进程一起工作，从而实现 Flutter 上众所周知的 hotload 的效果，而内核二进制文件加载到 VM 后，对应的程序实体（类、对象）解析都是 Lazy 的，起初只加载有关库和类的基本信息，仅当运行时需要时，才会完全反序列化有关类的信息：

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image9.png)

> 这也导致了 [Flutter Debug 在 iOS 18.4 beta 无法运的问题](https://juejin.cn/post/7476743827202736143)，因为  iOS 18.4 beta **系统不再允许未经代码签名的二进制文件通过 JIT 编译直接执行，之前可以是因为这是一个“安全漏洞”，因为之前的机制允许开发者在真机上绕过某些签名要求**，而现在通过 mprotect 在运行时动态修改内存读写权限的方式不再支持。

所以，在 Dart 里的 JIT 和一般意义上的代码解释运行还有区别，同时这也导致了在 Flutter 社区一直有一个误区，**那就是 debug 模式下 Flutter 性能很差是因为 JIT ，其实这并不完全正确**。

**实际上导致慢的主要原因是因为 Flutter 框架里有着许多一致性检查/断言**，而这些导致性能极具下降的检查/断言仅在 debug 模式下启用，这才是缓慢的主要来源。

> JIT 也会有慢的情况，但是不会像 flutter run debug 那么卡顿。

JIT 模式的主要差别是需要预热，所以程序可能需要一定的时间才能达到最佳性能，同时需要更多内存占用，但是从理论峰值性能考虑，其实并不会输于 AOT。

而 AOT 的特点是启动速度非常快，无需预热就可以达到最佳性能，**所以 AOT 非常适合 UI 场景，因为 UI 无法容忍 JIT 的不可预测性和预热时间**。

所以回到  Shorebrid 热更新 iOS 上：

- 在没有 patch 更新存在时，Shorebrid 完全是 AOT 模式运行
- 在有 patch 更新存在时，运行到对应 patch 的热更新部分代码需要解释执行，性能会有一定损耗
- 理论上，热更新的部分如果是 UI ，可能会比热更新业务逻辑在性能差异上更明显，特别还设计图片渲染等场景

当然，**从整体运行性能上考虑，在有热更新 patch 的情况下，也能接近满血性能的 90% 以上**，因为大多数时候在使用热更新场景，需要 patch 的代码并不会很多。

因为 Flutter 上最耗时的布局计算等部分是直接在 CPU 上 AOT 运行，而真正需要 patch 往往不会很大，因为如果你真的有很大规模的更改，那么用热更新也不合适，从合规场景考虑，大规模变动的场景还是通过平台 update 更合理：

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image10.png)

所以，在 iOS 场景下，好理解又不太精确的解释，大概会是：

> **Dart VM 拥有两个 snapshtos ，一个是已经签名所以可以在 CPU 上运行的；另外一个是 patch snapshot，是无法直接在 CPU 上运行的，需要通过解释器运行，解释器就想是一个 fake CPU**。

这也是 Shorebird “魔改” Engine 的原因，就是为了让 Engine 允许在运行时使用 Dart 虚拟机运行更新的代码更改，然后让 Dart 支持在生产模式下运行对应的解释器：

> 在 JIT 模式运行时 Dart 函数可能具有不同的编译表示形式，例如简单编译和针对同一函数的优化编译，Shorebird 正是利用 Dart 架构的这一特点，插入了一个新的解释器作为函数执行的替代机制，从而能够在运行时有效地替换应用的某些部分，而无需在设备上编译新代码。

说人话大概就是，Dart 有时候会在 function 仍在运行时将执行从未优化的代码切换到优化的代码：

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image11.png)

而在代码层面，我们可以看到，在 Flutter 初始化时，引擎会被插入初始化一个 `ConfigureShorebird`  ，这就是一切“魔法”的源头：

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image12.png)

而配置的目的主要还是读取到 patch 文件的相关信息，如  `vm_snapshot` 和   `isolate_snapshot` 相关的类信息，全局变量，函数指针、堆、指令等内容：

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image13.png)

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image14.png)

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image15.png)

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image16.png)

例如，如果在 iOS 上不是 `App.framework/App` 而是 `foo.vmcode` 时，就需要从中提取符号，然后将符号读入静态变量并保留，同时我们也可以看到，作为 patch 的 **vmcode 文件其实就是带有 shorebird 链接器标头前缀的 elf 文件** ：

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image17.png)

而最终读取到的 patch 会在 `shorebird_init` 变成 FileCallbacks ，接下来就去到 updater 的 rust 代码：

![](http://img.cdn.guoshuyu.cn/20250220_shorebird/image18.png)

在 Shorebrid 里，updater 库是通过 rust 编写，用于在 Flutter 中更新和管理 patch 代码的存在，它是作为静态库构建的，例如在构建 Android 时会链接到 Flutter 引擎中 `libflutter.so` 

当然，**最后 patch 后运行部分肯定是去到了“魔改”的 Dart VM ，这部分才是 Shorebrid 的灵魂核心，但是遗憾的是，这部分目前并没有开源**。

所以到这里，我们基本全面了解了 Shorebrid 的实现原理，那么最后我们需要聊聊它的局限：

- **首先 Shorebrid 是不能更新任何 Native 代码**  ，因为更新 Native 代码是不合规，Shorebrid 的目的是修复 Dart 代码
- **无法跨 Flutter 版本使用 patch，就算是小版本**，因为 Shorebrid 需要通过已发布应用文件去对比得到最小差异 patch ，所以基本保证每次构建 Flutter 都是在同一个固定版本
- **最低支持版本至少 3.10** ：
  - **Android** requires Flutter 3.10.0 or later.
  - **iOS** requires Flutter 3.24.0 or later.
  - **macOS** requires Flutter 3.27.3 or later
  - **windows** requires Flutter 3.27.2 or later.

- 服务器稳定性问题，因为 Shorebird 现在使用的是 CloudFlare CDN，有时候在一些特殊区域还是稳定性问题。

  > 其实在此之前 shorebird 是托管在 Google 的，但是基于国内用户的强烈要求才做的迁移到 CloudFlare，甚至 Discord 还有一个中文子区。

- **不支持自托管部署**

另外，**使用这种框架最怕的就是  Flutter 版本跟进的速度，不过这对于 Shorebird 来说基本不是问题**，Shorebird 在 Flutter 版本跟进上的速度可以说是几乎同步，甚至连前段时间的 Flutter 的 monorepo 迁移也能快速同步，所以在这一问题上基本不需要担心。

最后，**Shorebird 的退出机制几乎无损**， 在不想使用的时候，只需要删号然后切换回 `flutter build` 即可。

# 参考链接

- https://shorebird.dev/blog/how-we-built-code-push/
- https://github.com/dart-lang/sdk/blob/3702cbe573ea2b64f9b6a5dff116f53e431e0791/runtime/docs/README.md



