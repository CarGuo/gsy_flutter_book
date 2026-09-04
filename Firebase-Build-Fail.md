# Firebase 如何让全球  Android  和  Flutter 开发者集体 Build Fail

前几天看到这个的时候都无语了， 24 号发布的 `firebase_auth 6.6.0`  有一个改动：`REFACTOR(auth,android): migrate native implementation to Kotlin` ，也就是 FlutterFire 的 `firebase_auth` Android 插件刚从 Java 重写成 Kotlin，而与此同时，`firebase_core 4.14.0` 也迁移到了 Kotlin，迁移后的代码里有这样的 Java SAM 转换：

```kotlin
FirebaseAuth.IdTokenListener { auth ->
    // auth 类型由 Kotlin 推断
}
```

`IdTokenListener` 是 Firebase Android SDK 提供的 Java 单抽象方法接口，而 Kotlin 为了推断 `auth` 的类型，需要读取 Firebase SDK class 文件里的完整类型信息。

然后这时候问题就来了：`firebase-auth:24.2.0` 的 class 文件引用了 Checker Framework 的：

```
org.checkerframework.checker.initialization.qual.UnknownInitialization
```

但它发布到 Maven 的 POM 实际上一直没有声明 `checker-qual`，导致 Kotlin 编译器能看到“这里有一个注解”，但没办法加载这个注解的类，所以最终报错：

```
Type annotation class
'org.checkerframework.checker.initialization.qual.UnknownInitialization'
of the inferred type is inaccessible.
```

所以其实整个问题可以分成三层：

| 层级               | 问题                                                         |
| ------------------ | ------------------------------------------------------------ |
| 上游缺陷           | `firebase-auth` 的 class 文件引用 `@UnknownInitialization`，POM 却没有声明 `checker-qual` |
| FlutterFire 触发器 | `firebase_auth 6.6.0` 从 Java 迁移到 Kotlin，出现了需要推断参数类型的 SAM lambda |
| Kotlin 放大器      | Kotlin 2.3 对这个问题主要给警告，Kotlin 2.4 将其作为编译错误处理 |

所以问题在哪里？有趣的就在，**Firebase Android SDK 的发布元数据一直存在这个缺口，不过这个缺口之前一直没发现**。

然后叠加其他两个情况之后，这个 Bug 才爆发出来，所以在  Flutter  场景，FlutterFire  修复也很简单，没有增加 `checker-qual` 依赖，它选择把两处 lambda 参数写成显式类型：

```diff
- FirebaseAuth.IdTokenListener { auth ->
+ FirebaseAuth.IdTokenListener { auth: FirebaseAuth ->
```

```diff
- FirebaseAuth.AuthStateListener { auth ->
+ FirebaseAuth.AuthStateListener { auth: FirebaseAuth ->
```

这样 Kotlin 就不再需要从带有缺失注解的 Java 签名中推断参数类型，然后绕过了编译器报错路径，而且 PR 还把测试工程升级到：

- Kotlin 2.4.10
- AGP 8.11.1
- Gradle 8.14

> 确保 CI 真正覆盖“在 Kotlin 2.4 下由警告变错误”的场景。

而实际上在 Android 也是一样的，Java 可能没问题，但是 Kotlin 项目，只要是：

- 使用 Kotlin 2.4
- classpath 中没有其他依赖偶然带入 `checker-qual`
- Kotlin 代码对 `FirebaseAuth.IdTokenListener`、`AuthStateListener` 使用参数类型推断

那 Kotlin 的 Andorid 也一样要挂，这个等于是一个长期存在的 bug ， Firebase Auth AAR 发布时漏了 Checker Framework 编译依赖，直到 FlutterFire 6.6.0 的 Kotlin 重写和 Kotlin 2.4  类型推断组合才发现问题，只能说这种 Bug 太典了，之前没问题只是没诱因，很多低级错误都是不知不觉沉淀下来的。

**甚至前 Flutter 创始人 Eric 也公开吐槽 Firebase 架构有问题**，说到底 Google Play 一直喊着要大家 R8 和优化，但是你自己的 SDK 本身反而没优化好，也是讽刺：

![](https://img.cdn.guoshuyu.cn/image-20260827143628975.png)

