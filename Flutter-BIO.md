# 移动端系统生物认证技术详解


相信大家对于生物认证应该不会陌生，使用指纹登陆或者 FaceId 支付等的需求场景如今已经很普遍，所以基本上只要涉及移动端开发，不管是 Android 、iOS 或者是 RN 、Flutter  都多多少少会接触到这一业务场景。

当然，不同之处可能在于大家对于平台能力或者接口能力的熟悉程度，**所以本篇主要介绍 Android 和 iOS 上使用系统的生物认证需要注意什么，具体流程是什么，给需要或者即将需要的大家出一份汇总的资料**。

> ⚠️注意：**本篇更倾向于调研资料的角度，适合需要接入或者在接入过程中出现疑问的方向，而不是 API 使用教程，另外篇幅较长警告～**

首先，先简单说一个大家都知道的概念，那就是不管是  Android 或者 iOS ，不管是指纹还是 FaceId ，只要使用的是系统提供的 API ，**作为开发者是拿不到任何用户的生物特征数据，所以简单来说你只能调用系统 API ，然后得到成功或者失败的结果**。



![image-20220329172335926](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIO/image1)



## 一、Android

Android 上的生物认证发展史可以说是十分崎岖，目前简单来说经历了两个阶段：

- `FingerprintManager` (API 23)
- `BiometricPrompt`（API 28）

所以如下图所示，你会看到其实底层有两套 `Service` 在支持生物认证的 API 能力，但是值得注意的是， **`FingerprintManager ` 在  Api28（Android P）被添加了 `@Deprecated` 标记 ，包括 androidx 里的兼容包 `FingerprintManagerCompat` 也是被标注了 `@Deprecated` ，因为官方提供更傻瓜式，更开箱即用的 `androidx.biometrics.BiometricPrompt`**。





![image-20220329172806492](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIO/image2)



###  1.1、使用 BiometricPrompt

简单介绍下接入  `BiometricPrompt` ，首先第一步是添加权限

```xml

<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.test.biometric">
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
    <uses-permission android:name="android.permission.USE_FINGERPRINT" />

</manifest>
```

接着调用  `BiometricPrompt` 构建系统弹出框信息，具体内容对应可见下图：

![image-20220329175140111](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIO/image3)

最用设置 `AuthenticationCallback` 和调用 `authenticate` ，然后等待授权结果进入到成功的回调：

```java
    biometricPrompt = new BiometricPrompt(activity, uiThreadExecutor, authenticationCallback);
    biometricPrompt.authenticate(promptInfo);
```

当然上述代码还少了很多细节：

- 比如需要是 `FragmentActivity` ;

- 检测设备是否支持生物认证（还有不支持的现在？）;
- 判断支持哪种生物认证，当然默认 `BiometricPrompt` 会帮你处理，如果有多种会弹出选择；

而认证不成功的时候可以在 `onAuthenticationError`  里获取到对应的错误码：

| onAuthenticationError             | Type                                                         |
| --------------------------------- | ------------------------------------------------------------ |
| BIOMETRIC_ERROR_LOCKOUT           | 操作被取消，因为 API 由于尝试次数过多而被锁定（一般就是在一次  `authenticate`  里例如多次指纹没通过，锁定了， 但是过一会还可以调用） |
| BIOMETRIC_ERROR_LOCKOUT_PERMANENT | 由于 BIOMETRIC_ERROR_LOCKOUT 发生太多次，操作被取消，这个就是真的 LOCK 了。 |
| BIOMETRIC_ERROR_NO_SPACE          | 剩余存储空间不足                                             |
| BIOMETRIC_ERROR_TIMEOUT           | 超时                                                         |
| BIOMETRIC_ERROR_UNABLE_TO_PROCESS | 传感器异常或者无法处理当前信息                               |
| BIOMETRIC_ERROR_USER_CANCELED     | 用户取消了操作                                               |
| BIOMETRIC_ERROR_NO_BIOMETRIC      | 用户没有在设备中注册任何生物特征                             |
| BIOMETRIC_ERROR_CANCELED          | 由于生物传感器不可用，操作被取消                             |
| BIOMETRIC_ERROR_HW_NOT_PRESENT    | 设备没有生物识别传感器                                       |
| BIOMETRIC_ERROR_HW_UNAVAILABLE    | 设备硬件不可用                                               |
| BIOMETRIC_ERROR_VENDOR            | 如果存在不属于上述之外的情况，Other                          |

### 1.2、BiometricPrompt 自定义

简单接入完 `BiometricPrompt`  之后， 你可能会有个疑问： *`BiometricPrompt` 是很方便，但是 UI 有点丑了，可以自定义吗？*

**抱歉，不可以** ，是的，`BiometricPrompt  `不能自定义 UI，甚至你想改个颜色都“费劲”， 如果你去看  [biometric](https://android.googlesource.com/platform/frameworks/support/+/androidx-main/biometric) 的源码，就会发现官方并没有让你自定义的打算，除非你 cv 这些代码自己构建一套，至于为什么会有这样的设计，我个人猜测**其中一条就是屏下指纹**。

> 在官方的 [《Migrating from FingerprintManager to BiometricPrompt》](https://medium.com/androiddevelopers/migrating-from-fingerprintmanager-to-biometricprompt-4bc5f570dccd)里也说了：丢弃指纹的布局文件，因为你将不再需要它们，AndroidX 生物识别库带有标准化的 UI。

什么是标准化的 UI ？如下所示是使用 `BiometricPrompt` 的三台手机，可以看到：

- 第一和第二台除了位置有些许不同，其他基本一致；
- 第三胎手机是屏下指纹，可以看到整个指纹输入的 UI 效果完全是厂家自己的另外一种风格；

![image-20220329183129880](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIO/image4)

**所以使用  `BiometricPrompt`  你将不需要关注 UI 问题，因为你没得选，甚至你也不需要关注手机上的生物认证类型的安全度问题，因为不管是  CDD 还是 UI ，OEM 厂商的都会直接实现好**，例如三星的 UI 是如下图所示：

![](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIO/image5)



> [Android 兼容性定义文档 (Android CDD)](https://source.android.com/compatibility/android-cdd#7_3_10_biometric_sensors)_里描述了生物认证传感器安全度的强弱，而在 framework 层面 `BiometricFragment` 和 `FingerprintDialogFragment` 都是 `@hide` ，甚至你单纯去翻 `androidx.biometric:biometric.aar` 的库，你都看不到   `BiometricFragment`  的布局，只能看到   `FingerprintDialogFragment`  的 layout。

那就没办法自定义 UI 了吗？还是有的，有两个选择：

- 继续使用 `FingerprintManager` ，虽然标注了弃用，但是目前还是可以用，在 Android 11 上也可以正常执行对应逻辑，下图是同一台手机在 Android 11 上使用  `FingerprintManager`  和   `BiometricPrompt  ` 的对比：

  ![image-20220329202726403](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIO/image6)

- 使用腾讯的 [soter ](https://github.com/Tencent/soter ) ，这个我们后面讲；



### 1.3、Login + BiometricPrompt

介绍完调用和 UI ，那就再结合 Login 场景聊聊  `BiometricPrompt` ，官方针对 Login  场景提供了一个 [Demo]( https://github.com/android/security-samples/tree/master/BiometricLoginKotlin) ，这里主要介绍整个业务流程，具体代码可以看官方的  [BiometricLoginKotlin]( https://github.com/android/security-samples/tree/master/BiometricLoginKotlin)  ，前面说过生物认证只提供认证结果，那么结合 Login 业务，在官方的例子中 **`BiometricPrompt`  主要是用于做认证和加密的作用**：

![image-20220329162115306](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIO/image7)

如上图所示，场景是在登陆之后，我们获取到了用户的 Token 信息，这个 Token 信息可能是服务器基于用户密码合并后的内容，所以它包含了一些敏感隐私，为了安全期间我们不能直接存储，而是利用   `BiometricPrompt` 去实现加密后存储：

- 首先通过 `KeyStore`，主要是得到一个包含密码的  `SecretKey`  ，当然这里有一个关键操作，那就是 `setUserAuthenticationRequired(true)`，后面我们再解释；
- 然后利用  `SecretKey`  创建  `Clipher`  ， `Clipher`  就是 Java 里常用于加解密的对象；
- 利用  `BiometricPrompt.CryptoObject(cipher)`   去调用生物认证授权；
- 授权成功后会得到一个 `AuthenticationResult` ，Result 里面包含存在密钥信息的 `cryptoObject?.cipher` 和 `cipher.iv` 加密偏移向量；
- 利用授权成功后的 `cryptoObject?.cipher`  对 Token 进行加密，然后和  `cipher.iv` 一起保存到 `SharePerferences` ，就完成了基于 `BiometricPrompt`  的加密保存；

是不是觉得有点懵？ 简单说就是：**我们通过一个只有用户通过身份验证时才授权使用的密钥来加密 Token ，这样不管这个 Token 是否泄漏，对于我们来说都是安全的。**

然后在 `KeyStore` 逻辑里这里有个 `setUserAuthenticationRequired(true)`  操作，这个操作的意思就是：是否仅在用户通过身份验证时才授权使用此密钥，也就是当设置为 `true` 时：

**用户必须通过使用其锁屏凭据的子集（例如密码/PIN/图案或生物识别）向此 Android 设备进行身份验证，才能够而授权使用密钥。**

也就是只有设置了安全锁屏时才能生成密钥，而一旦安全锁屏被禁用（重新配置为无、不验证用户身份的模式、被强制重置）时，密钥将*不可逆转地失效。*

> 另外可以设置了 `setUserAuthenticationValidityDurationSeconds`  来要求密钥必须至少有一个生物特征才可用，而一但它设置为 true，如果用户注册了新的生物特征，它也将不可逆转地失效。

**所以可以看到，这个流程下密钥会和系统安全绑定到一起，从而不害怕 Token 等信息的泄漏**，也因为授权成功后的 `CryptoObject` 和 `KeyStore` 集成到一起，可以更有效地抵御例如 root 的攻击。

而反之获取的流程也是类似，如下图所示：

- 在 `SharePerferences`  里获取加密后的  Token  和 iv 信息；
- 同样是利用  `SecretKey`  创建  `Clipher`  ，不过这次要带上保存的  iv 信息；
- 利用  `BiometricPrompt.CryptoObject(cipher)`   去调用生物认证授权；
- 通过授权成功后的 `cryptoObject?.cipher`  对 Token 进行加密，得到原始的 Token 信息；



![image-20220329162133600](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIO/image8)



所以可以看到，**基本思路就是利用 `BiometricPrompt` 认证后得到  `CryptoObject?.Cipher` 去加解密，通过系统的安全等级要保护我们的隐私信息**。

最后补充一个知识点，虽然一般我们不关心，但是在  `BiometricPrompt` 里有  ***auth-per-use***  和 ***time-bound***  这两个概念：

-   ***auth-per-use***  密钥要求每次使用密钥时，都必须进行认证 ，前面我们通过  `BiometricPrompt.CryptoObject(cipher)`  去调用授权方法就是这类实现；
-  ***time-bound***  密钥是一种在一定的时间段内有效的密钥，可以通过 `setUserAuthenticationValidityDurationSeconds`  设置有效时长，如果你设置为很短，例如 5 秒，那行为上和 auth-per-use 基本类似；

> 更多资料可以参考官方的 [biometric-authentication-on-android](https://medium.com/androiddevelopers/biometric-authentication-on-android-part-1-264523bce85d)

### 1.4、Tencent soter

前面说到 Android 上还有 soter ，腾讯在微信指纹支付全流程之上，将它的流程抽象为一套完备的生物识别标准：SOTER。

SOTER 会与手机厂商合作，在系统原有的接口能力之上提供安全加固，通过业务无关的安全域（TEE，即独立于手机操作系统的安全区域，root或越狱无法访问到）应用程序（TA）降低开发难度和适配成本，**做到即使外部环境不可信，依然可以安全授权。**

> TEE（Trusted Execution Environment）是独立于手机操作系统的一块独立运行的安全区域，SOTER标准中，所有的密钥生成、数据签名处理、指纹验证、敏感数据传输等敏感操作均在 TEE 中进行，**并且 SOTER使用的设备根密钥由厂商在产线上烧入，从根本上解决了根密钥不可信的问题，并以此根密钥为信任链根，派生密钥，从而完成**，与微信合作的所有手机厂商将均带有硬件TEE，并且通过腾讯安全平台和微信支付安全团队验收，符合SOTER标准。

![image-20220329214046518](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIO/image9)

简而言之，这是一个支持直通厂商，并且具备后台服务对接校验的第三方库，目前最近 5 个月都还有在更新，那它有什么问题呢？

那就是**必须是与微信合作的所有手机厂商和机型才能正常使用** ，而且经常在一些厂商系统上出现奇奇怪怪的问题，比如：

- MiUI13 绑定服务异常；
- 鸿蒙系统API层面报错；
- 莫名其妙地出现崩溃；

但是它可以实现基本类似于微信支付的能力，所以如何取舍就看你的业务需求了。

> 支持机型可查阅 ：[#有多少设备已经支持tencent-soter](https://github.com/Tencent/soter/wiki#有多少设备已经支持tencent-soter)



## iOS

相对来说 iOS 上的生物认证就舒适不少，相比较 Android 上需要区分系统版本和厂商的  `fingerprint` 、`face` 和 `iris` ，iOS 上的 Face ID 和 Touch ID  就十分统一和简洁。

简单介绍下 iOS 上使用生物认证，首先需要在 `Info.plist` 文件添加描述信息：

```xml
<key>NSFaceIDUsageDescription</key>
<string>Why is my app authenticating using face id?</string>
```

然后导入头文件 `#import <LocalAuthentication/LocalAuthentication.h>` ，最后创建 `LAContext`  去执行授权操作，这里也简单展示对应的错误码：

| Error Code                  | Type                              |
| --------------------------- | --------------------------------- |
| LAErrorSystemCancel         | 系统取消了授权，比如有其他APP切换 |
| LAErrorUserCancel           | 用户取消验证                      |
| LAErrorAuthenticationFailed | 授权失败                          |
| LAErrorPasscodeNotSet       | 系统未设置密码                    |
| LAErrorBiometryNotAvailable | ID不可用，例如未打开              |
| LAErrorBiometryNotEnrolled  | ID不可用，用户未录入              |
| LAErrorUserFallback         | 用户选择输入密码                  |

而同样关于自定义 UI 问题上，想必大家都知道了，**iOS 生物认证没有自定义 UI 的说法，也不支持自定义 UI ，系统怎么样就怎么样，你可以做的只有类似配置‘是否允许使用密码授权’这样的行为** 。

> 在这一点上相信 Android 开发都十分羡慕 iOS ，有问题也是系统问题，无法修复。

同样，简单说说在 iOS  上使用生物识别的 Login 场景流程：

- 获取到 Token 信息后，验证用户的 TouchID/FaceID ；
- 验证通过后，将 Token 等信息保存到 keychain (keychain  只是一个数据存储，用于存储一些敏感数据如密码、证书等)；
- 保存成功后，下次再次登录时通过验证 TouchID/FaceID 获取对应信息；

![image-20220329223329042](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIO/image10)

这里主要有两个关键点：

- **访问级别** ： 例如是否需要每次都进行身份验证时才可以访问项目；
- **身份验证级别**： 也就是什么场景下可以访问到存储的信息；

举个例子，访问 keychain 首先是需要创建 accessControl ，一般可以通过  **`SecAccessControlCreateWithFlags`** 来创建 accessControl ，这里有个关键参数用于指定访问级别：

- kSecAttrAccessibleAfterFirstUnlock	开机之后密钥不可用，需要等用户输入开机密码
- kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly:	开机之后密钥不可用，需要等用户输入开机密码，但是仅限于当前设备
- kSecAttrAccessibleWhenUnlocked:	解锁过的设备密钥会保持可用状态
- kSecAttrAccessibleWhenUnlockedThisDeviceOnly:	 解锁过的设备密钥会保持可用状态，仅当前设备
- kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly:	解锁过的设备密钥会保持可用状态，只有用户设置密码后密钥才可用
- kSecAttrAccessibleAlways:	始终可用，已经 Deprecated
- kSecAttrAccessibleAlwaysThisDeviceOnly:	密钥始终可用，但无法迁移到其他设备，已经 Deprecated

类似场景下一般使用 `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`  ，另外还有 `SecAccessControlCreateFlags`标志，它主要是用于指定希望用户在访问钥匙串时的约束，一般类似场景会使用 `userPresence` ：

- devicePasscode:  限制使用密码访问
- biometryAny:  使用任何已注册 touch 或 face ID  访问
- biometryCurrentSet:  限制使用当前注册 touch 或 face ID   访问
- userPresence:  限制使用生物特征或密码访问
- watch:  使用手表访问

创建完成  accessControl  之后，通过设置 kSecAttrAccessControl 后正常把信息存储到  keychain  就可以了，在存储 keychain   时也有可选的 `kSecClass` ，一般选用 `kSecClassGenericPassword`：

- kSecClassGenericPassword:  通用密码
- kSecClassInternetPassword： Internet 密码
- kSecClassCertificate：证书
- kSecClassKey：加密密钥
- kSecClassIdentity:  身份认证

*当然，此时你是否发现，在谈及 accessControl  和  keychain   时没有说明  `LAContext` ？*

其实在创建 accessControl   时是有对应  `kSecUseAuthenticationContext` 参数用于设置 `LAContext ` 到 keychain  认证，但是也可以不设置，具体为：

- 如果未指定，并且该项目需要 authentication 认证，那就会自动创建一个新的  `LAContext `  ，使用一次后丢弃；
- 如果是使用先前已通过身份验证的   `LAContext `   ，则操作直接成功而不要求用户进行身份验证；
- 如果是使用先前未经过身份验证的    `LAContext `    ，则系统会尝试在该    `LAContext `   上进行身份验证，如果成功就可以在后续的钥匙串操作中重用。

> 更多可见官方的： [accessing_keychain_items_with_face_id_or_touch_id](https://developer.apple.com/documentation/localauthentication/accessing_keychain_items_with_face_id_or_touch_id/)

可以看到， iOS 上都只需要简单地配置就行了，因为系统层面也不会给你多余的能力。

> ⚠️提示，如果你有需要屏蔽 iOS 在生物验证失败之后，不展示输入密码的选项，可以配置  `LAContext `  的 `context.localizedFallbackTitle=""` 来实现。

## 三、最后

虽然本篇从头到位并没有教你如何使用 Android 或者 iOS 的生物认证，但是作为汇总资料，本篇基本覆盖了 Android 或者 iOS 生物认证相关的基本概念和问题，相信本篇将会特别适合正在调研生物认证相关开发的小伙伴。

最后，还是惯例，如果对于这方便你有什么问题或者建议，欢迎留言评论交流。