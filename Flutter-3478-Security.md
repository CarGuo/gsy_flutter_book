# Flutter 紧急发布 3.47.8 安全升级版本，建议都升级

Flutter 周末紧急发布了 Flutter  3.47.8  和  Dart 3.13.7 版本，因为最近印度老哥的骚操作被人扫出来， **eMudhra 的 CA 证书密钥泄露，而泄漏的原因是因为它的证书密钥是个位数，比如一个 4， 是的，没看错，它的证书密钥就是一个 4** 。

![](/article-assets/e026ea3668a2695ec445f63b.webp)

正常的 P-384 椭圆曲线私钥，是一个接近 384 位的随机整数，理论上有应该有  \(2^{384}\)  种可能，但是 eMudhra 的 8 个私钥居然是下面这些数字：

![](/article-assets/fff070d67448cbad1c30a66b.webp)

一家做数字信任生意的公司，把中间 CA 的私钥做成了单字节整数，然后挂在全球信任链上跑了一年半，你觉得这是什么刺激 Play ？？而原因是发布的时候他们员工看错了····

也就是现在这家公司的“合法” CA  谁都可以伪造，攻击者可以利用网络路径伪造任意域名的有效 TLS/HTTPS 证书，而为了阻止被入侵的 eMudhra 中间证书颁发机构的  CA) 证书，现在你需要升级 Flutter 来保证这个安全问题。

虽然浏览器和操作系统都[发布了紧急中间证书黑名单 ](https://blog.google/security/protecting-chrome-and-android-users-from-compromised-emudhra-intermediate-ca-certificates/)，但是 Android、Windows 和 Linux 上的 dart:io 用的是内置的 BoringSSL 引擎验证 TLS 证书链，它不会读操作系统的中间证书黑名单，所以这次主要就是更新  BoringSSL ，用来在 TLS 验证期间直接阻止被入侵的 eMudhra 中间证书。

另外，在 Android 14+ 上， `dart:io` 现在会从可更新的 Conscrypt APEX 模块加载系统根证书，确保通过 Google Play 系统更新提供的未来的无线根存储撤销能够自动生效。

当然，你要是说，你发布的 App 里直接都忽略了证书验证的，那当我没说话。
