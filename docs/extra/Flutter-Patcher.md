---
title: "新开源 Flutter 热更新？flutter_patcher 可以简单了解下"
---

# 新开源  Flutter 热更新？ flutter_patcher  可以简单了解下

最近刚好看到有人在分享一个 flutter 的热更新项目  `flutter_patcher` ，好奇了解了下，原来是给 Flutter Android 提供自托管的 Dart 代码热更新能力，实际上其实就是以前 Android 那套 so 动态库的替换支持：

> **在 Android App 下一次冷启动时，让 Flutter Engine 不再加载 APK 里原本的 `libapp.so`，而是加载一个提前下载好的补丁版 `libapp.so`**。

所以它本质就是 so 加载的动态替换，不过做了不少边界情况支持，虽然不支持 iOS ，但是实际上可用性还是可以的：

![](https://img.cdn.guoshuyu.cn/01_loader_hook.png)

`flutter_patcher`  的主要作用就是替换 FlutterLoader ，它的做法是**把补丁版 `libapp.so` 下载到 App 私有目录，然后在 Flutter 初始化阶段把加载路径改过去**。

所以在它项目里自定义了一个 `PatchedFlutterLoader`，主要是继承官方 `FlutterLoader`，重写 `ensureInitializationComplete`，然后往启动参数里追加：

```kotlin
--aot-shared-library-name=/data/data/.../patch/libapp.so
```

> 这个参数主要就是告诉 Flutter runtime，AOT 共享库不要按默认路径找，而是用指定路径。

但问题是 App 正常启动时拿到的是默认 `FlutterLoader`，你怎么让系统用你的 `PatchedFlutterLoader`？**这里就用到了反射**。

> `FlutterInjector` 是 Flutter Android embedding 里的一个单例注入容器，在它的内部持有 `flutterLoader ，也就是 flutter_patcher` 在比较早的时机，通过反射找到这个字段，然后把默认 Loader 换成自己的 Loader。

**所以这一步必须发生在 `Application.attachBaseContext` 阶段**，不能等到 `FlutterActivity` 创建后，因为一旦 Engine 已经初始化完成，`libapp.so` 就已经被加载进进程，这时候再改参数就没意义了。

而 `flutter_patcher` 的链路可以拆成两段，首先是开发侧负责生成补丁，设备侧负责下载、校验、保存，并在下一次冷启动时让补丁生效。

![](https://img.cdn.guoshuyu.cn/02_patch_pipeline.png)

开发侧大概是这样：

```bash
flutter build apk --release

dart run flutter_patcher:pack \
  --apk app-release.apk \
  --version 1.0.1 \
  --target-version-code 100
```

打包工具会从 APK 里提取对应 ABI 的 `libapp.so`，同时生成描述补丁信息的 `manifest.json`，然后后续你把 `libapp.so` 和 `manifest.json` 放到自己的 CDN 或对象存储上就行了。

而用户设备上，App 运行期间可以调用 `FlutterPatcher.applyPatch` 下载补丁，下载完成后原生侧会做 MD5 校验，也可以做签名校验，然后通过原子 rename 写入补丁目录，然后保存 `meta.json`。

> 当然，补丁下载完成也不会马上生效。

因为当前进程里的 `libapp.so` 已经被加载了，而 Linux/Android 下，现在相对一个已经 dlopen 的动态库进行安全替换，成本太高了，所以需要下一次进程启动时生效。

下次启动后，在 `attachBaseContext` 先执行，插件检查 `meta.json`，确认 versionCode 匹配、文件完整、补丁没有被拉黑，再安装 LoaderHook，之后 Flutter Engine 初始化，`PatchedFlutterLoader` 注入 `--aot-shared-library-name`，Engine 才会从补丁路径加载新的 `libapp.so`。

所以 `flutter_patcher` 替换的是 `libapp.so`，也就是 Dart AOT 代码产物，所以它的限制也很直接：

- 不能更新 Kotlin、Java、C++ 原生代码
- 不能更新 AndroidManifest
- 不能更新 Flutter Engine
- 不支持图片、字体、`flutter_assets` 

![](https://img.cdn.guoshuyu.cn/03_capability_boundary.png)

> 另外就是它是全量替换 `libapp.so`，所以整体大小也会比较大。

还有一个点需要考虑，他和 Shorebird 实现不同，因为它是直接下发动态库，**这其实违反了  Google Play 的政策，所以如果用了这个，就不能上家 GP 了**。

另外 `flutter_patcher`  里也设置了「补丁熔断」，原生层可以基于 Android 的 `ApplicationExitInfo` 记录进程异常退出，如果某个补丁连续导致崩溃，超过阈值就丢弃补丁，回退到 APK 内置的 `libapp.so`。

所以，你要说它有多少生产力吧，其实并没有，因为不支持 GP ，不支持 iOS ，但是好在它够简单，而且使用起来方便，所以用来做一些场景的兜底也还可以。

所以，你觉得你会需要这种支持吗？
