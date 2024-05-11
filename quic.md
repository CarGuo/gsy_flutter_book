#  Flutter 之 HTTP3/QUIC 和 Cronet 你了解过吗？

虽然 HTTP3/QUIC 和 cronet 跟 Flutter 没太大关系，只是最近在整理 Flutter 相关资料时发现还挺多人不了解，就放到一起聊聊。

> 本篇也是主要将现有资料做一些简化整合理解。

# 前言

其实为什么会有 HTTP3/QUIC ？核心原因还是现有协议已经无法满足需求，说个最简单又不严谨的例子：

> 当你在家里拿着手机用  Wi-Fi  下片，这时候觉得饿了要下楼吃饭，然后你带着手机离开了家里，期间一直没有退出 App 的打算，这个过程手机流量会从 Wi-Fi 变成 5G 网络，那么网络链路就会变成了一个全新的网络环境，从 Wi-Fi  到 5G  会是全新的 IP 地址，那么作为新的链接， TCP 就无法复用之前的数据和状态，也就是之前链路就断了，那么下载行为可能就会被打断，而你直到温饱之后要用，才发现资源还没下载完成。

我们知道， HTTP/2 时代，每个网络请求我们都要经历多次 TCP 握手，特别现在基本都强制了 HTTPS ，所以 TLS 加密握手也不可或缺，但是在移动场景下，其实用户的网络环境极有可能在不停的发生变化，所以用户在移动过程中，TCP 链接极有可能被迫打断。

在 App 使用过程中，重启 TCP 连接会带来一些不好的体验，例如等待新的握手、重新开始下载、重建上下文等延迟，而 QUIC 其中就包括解决这一问题的实现，通过 connection migration 实现链路复用，后续我们会详细聊到。

# QUIC

其实只要说到  HTTP/3 就离不开 QUIC (Quick UDP Internet Connections)，**因为 QUIC 是一个通用传输协议，它是 HTTP/3 的灵魂所在，而神奇之处也在于，它是运行在  UDP 的协议的基础上**。

> 大家对于 UDP 应该不陌生，因为相较于 TCP ，它相对不可靠，因为 UDP  不提供任何特性，例如它不会通过握手建立连接，如果包丢失也不会获得自动重传，所以它一直以来都被冠以「不可靠」的称号。

那么 UDP 有什么优点？那肯定是快～因为 UDP 不需要等待握手，也没有队头阻塞，所以它的性能一直很好，**那 QUIC 建立在 UDP 之上就是为了性能吗**？

![](http://img.cdn.guoshuyu.cn/20240417_quic/image1.png)

**其实并不全是，或者是关键因素并不是**，因为如果把 QUIC 作为一个直接运行在  IP 之上的全新独立协议，那么就意味着 HTTP/3 会无法兼容现有的许多硬件设备，这明显并不现实，**但是如果构建在 UDP 上，那么 QUIC 就拥有更好的兼容和部署支持** 。

所以最终落地的结果就是： **QUIC 在 UDP 之上重新实现了一套「更高效的 “new TCP”」 的通用协议**。

> 当然，**如果你硬要简单说 HTTP/3 是将 TCP 换成了 UDP  也说得通，只是并不是因为 UDP 更快，而是为了 QUIC 能更好兼容部署，并且 QUIC 本身就是一套基于 UDP 的全新的高级的 “TCP”** 。

**那么 QUIC 有哪些优秀的地方呢？其中就包括前面说的在移动环境下让连接可以保持更长时间**。

## QUIC 支持连接迁移（ connection migration ）

我们前面知道了，当用户手机在 Wi-Fi 和 5G 网络进行切换时，TCP 链接会出现中断，如果我们定义 App 和服务器之间的链接是通过  「App IP +  App 端口 + 服务器 IP + 服务器端口」 这样四个元素来表示一个链接，那么 Wi-Fi 和 5G 网络的时候，App 端的 IP 变了，那么对于服务端而言，这就是一个全新的链接，所以旧的 TCP 链接就无法被复用。

为了解决这个问题，QUIC 提出了连接标识符（CID， connection identifier），每个连接都在前面提到的四个元素之上分配了另一个 CID 编号，可以在 App-服务器端点之间来唯一标识它。

简单说，**因为这里 CID 在 QUIC 中的传输层定义，所以它不会因为切换网络时发生改变**，比如下图所示，一般情况下 CID 是包含在每个 QUIC 数据包的前端，而 CID 也是 QUIC  header 中少数几个没有加密的数据。

![](http://img.cdn.guoshuyu.cn/20240417_quic/image2.png)

> 通过 CID ，前面提到的四个元素里，就算 App IP 发生变化，QUIC 服务器和 App 只需要看下 CID，就能知道这其实还是之前的同一个连接，不需要重新握手，可以继续复用之前的下载状态，这也是前面提到过的 connection migration 。

当然，前面这个介绍相对简化，如何考虑到安全问题，CID 不会被直接使用，而是使用映射。

假设 App 和服务器都知道有 CID A、B 、C  都是映射到连接 X， 然后 App 可能会在 Wi-Fi 上会使用 A 标记数据包，而在 5G 上使用 B 标记 ，而映射的列表在 QUIC 中是完全加密，从而让黑客只知道  A、B、C，但是不知道 X 的存在。

![](http://img.cdn.guoshuyu.cn/20240417_quic/image3.png)

当然，这也还是简化后的逻辑，只是为了更好理解，现实中 CID 的相关逻辑更加复杂，只是通过这些，大家应该就可以更快速理解 QUIC 为什么可以做到 connection migration 和其关键实现理念。

就这样，有了 QUIC 支持，在移动场景中，当网络切换时，可以看到如下图右侧使用 QUIC 手机很快便响应了请求，而左侧手机因为需要建立新的链路，所以需要等待超时后，重新握手成功再请求的效率对比。

![](http://img.cdn.guoshuyu.cn/20240417_quic/image4.gif)

## TLS 集成

其实通过一开始的架构图，大家应该也可以看出来，和 HTTP/2 不同的是，QUCI 他直接集成了 TLS ，其目的就是加快和减少 HTTPS 请求是所需的时间。

![](http://img.cdn.guoshuyu.cn/20240417_quic/image5.png)

因为在以前使用 HTTPS 请求时， HTTP 数据需要先由 TLS 加密，再由 TCP 传输，虽然 TLS 随着版本发展所需的加密握手次数已经得到优化，但是相比较起来，加密所带来的开销还是客观存在。

![](http://img.cdn.guoshuyu.cn/20240417_quic/image6.png)

而在 QUIC 里就不一样了，QUIC 将 TLS  进行了封装，所以，**对于 TCP 模式下 TLS 和 TCP 协议都需要单独握手， QUIC 将传输和加密握手合并为一次握手，节省了往返时间**，但这也表明了 QUIC 必须使用 TLS，  HTTP/3 下会是始终完全加密的状态，同时 QUIC 还加密它的（除了前面的 CID 等）数据包头字段，甚至传输层信息一般情况下都不能再被中间件读取。

![](http://img.cdn.guoshuyu.cn/20240417_quic/image7.png)

所以，QUIC 默认深度加密，与之前的 TCP 相比，他也可以在一定程度节省 TLS 的开销，当然，QUIC 使用 TLS 单独加密每个数据包，而 TLS-TCP 可以同时加密多个数据包，所以 QUIC 也可能在高吞吐量的场景中变慢。

## 优化多路复用字节流

简单说，**多路复用字节流就是单一 TCP 连接下载不同的资源**，在传输时将不同文件的数据混合，比如 ABC 三种数据混合在一起传输。

![](http://img.cdn.guoshuyu.cn/20240417_quic/image8.png)

而在 TCP 时代，TCP 是不知道多路复用字节流里数据的混合情况，也即是 TCP 不知道数据是 ABC，它直管传输数据，如果这时候 C 出现数据丢失， TCP 会认为整个数据传输出现丢失，从而导致整个链路里其他 AB 因为这个等待而变慢，这就是传说中的队头阻塞问题。

而 QUIC 的在某种意义上解决了传输层的队头阻塞问题，因为 QUIC 会知道有多路复用的多字节流存在，是真正意义上“理解了”多路复用，所以它可以在每个流的基础上执行丢包监测和恢复逻辑。

当然，这也造成了 TCP 和 QUIC 出现了本质的不兼容区别，QUIC 「理论上」来说是不兼容 HTTP/2 运行，因为 HTTP/2 还包括在单一 TCP 连接上运行多个流的概念。

> 其实 TCP 的设计目的从来不是在单一 TCP 上传输多个独立的文件，只是因为现实场景用到了，所以才有这样奇怪的兼容方式，而 QUIC 通过在传输层传输多个字节流以及在每个流基础上处理丢包问题，来解决  TCP 上一直存在的问题。

总的来说，**QUIC 算是 TCP 的不兼容升级，而又由于它基于 UDP 实现，所以可以兼容已有的设备运行，并且集成了 TLS，默认全加密，支持 connection migration 等，在不可靠的网络场景下也可以实现更可靠的网络运行**。



# QUIC 下的 Flutter ：Cronet 

既然我们知道 HTTP/3 和 QUIC 可以得到更好的体验，那就不得不说 Cronet，因为 Cronet 是 Chromium 网络堆栈，所以才被称为 Cronet ，它和 Chromium 使用相同的网络引擎。

**使用 Cronet 最重要的意义是，它能够同时支持 TCP 协议和 QUIC 协议**，一般情况下 App 发送请求时会说明“我支持 QUIC” ，然后服务端收到请求后，根据自身情况确实是否使用 QUIC 。

> 目前的说法是，只要 Cronet 知道了服务端支持 QUIC ，那么 Cronet 后续请求就会开始使用 QUIC ， **QUIC 的协议发现过程是通过识别响应头中的特殊字段来实现**。

而 Cronet 核心网络引擎完全基于C/C++，所以它除了可以在 Android 中使用之外，也可以通过 FFI 的方式被 Dart 使用，在 Google 产品里，  YouTube、 Google App、 Google Photos、 Maps 等都是用 Cronet 来处理网络请求，所以总的来说，**Cronet 还是相对可靠的**。

> 所以其实对于 Cronet 而言， Flutter 和 Android 都是大差不差的情况。

Cronet 在 Flutter 得推进主要是依赖 Dart 语言的发展进程，例如：

- Dart 2.18 提供了对两个对于 `package:http` 特定于平台的 http 库的实验性支持：

  - `cupertino_http` 基于 `NSURLSession` 的 macOS/iOS 支持。

  - `cronet_http` 基于 [Cronet](https://link.juejin.cn/?target=https%3A%2F%2Fdeveloper.android.com%2Fguide%2Ftopics%2Fconnectivity%2Fcronet)，Android 上的网络库支持。

- Dart 3.2
  - 改进 [package:jnigen](https://link.juejin.cn/?target=https%3A%2F%2Fdart.dev%2Fguides%2Flibraries%2Fjava-interop) 实现 Java 和 Kotlin 的直接调用支持，现在可以将 [package:cronet_http](https://link.juejin.cn/?target=https%3A%2F%2Fpub.dev%2Fpackages%2Fcronet_http)（Android Cronet HTTP 客户端的包装器）从手写绑定代码迁移到[自动生成的](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fdart-lang%2Fhttp%2Fblob%2Fmaster%2Fpkgs%2Fcronet_http%2Fjnigen.yaml)包装器

> 目前 Flutter 使用 Cronet 可以通过引入 [cronet_http](https://pub.dev/packages/cronet_http) 包，新版的 dio 内也实现了对应的 [cronet_adapter](https://github.com/cfug/dio/blob/0364fe6343c494f4d00306b582f8f73318907915/plugins/native_dio_adapter/lib/src/cronet_adapter.dart#L4) ，如果你使用了 dio ，基本就可以直接使用 Cronet。

对于 Cronet 的使用，也可以分为 **使用Google Play 支持版本和使用嵌入式 Cronet 支持版本** ：

- 如果你的 App 使用 GP 服务，那么其实可以不额外植入 Cronet 依赖，这样的好处就是 Cronet 的更新迭代完全和你的 App 没有关系，升级维护完全交给 GP 负责，相对体积也会小很多。

- 如果你不使用或者没条件使用 GP 服务，那么也可以使用嵌入式的运行方式，例如 `flutter run --dart-define=cronetHttpNoPlay=true` 。

而如果你使用 Dio，那么使用 Cronet 则非常“简单”，只需要一行配置即可完成，不过目前来说，Cronet 只会在 Android 生效，在 iOS 上 `NativeAdapter` 使用的是基于 `NSURLSession` 的  [`cupertino_http`](https://pub.dev/packages/cupertino_http) 。

```dart
final dioClient = Dio();
dioClient.httpClientAdapter = NativeAdapter();
```

> **为什么 iOS 使用  ``NSURLSession`` ？因为  iOS 15 和 macOS Monterey 默认就启用适配了 HTTP/3**。



# 最后

本篇主要还是基于科普性质居多，核心还是简单的告诉大家，什么是 HTTP/3 和 QUIC ，QUIC 和 TCP 的区别和优势，最后是 Cronet 的介绍已经如何在 Flutter 里使用 QUIC。

目前基本云厂商都已经支持了 QUIC 配置，所以如果你还没开始接触 HTTP/3 ，现在也许是时候可以试试了，不过我认为，其实也许你的项目已经在使用 HTTP/3 ，只是你还没发现而已。



参考资料：

- https://unsuitable001.medium.com/package-cronet-an-http-dart-flutter-package-with-dart-ffi-84f9b69c8a24

- https://www.smashingmagazine.com/2021/08/http3-core-concepts-part1/

- https://calendar.perfplanet.com/2020/head-of-line-blocking-in-quic-and-http-3-the-details/

- https://pub.dev/packages/cronet_http

- https://www.youtube.com/watch?v=YWiRef3wOYY