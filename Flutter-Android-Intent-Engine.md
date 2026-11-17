# Flutter Android 改动：APK 不再允许通过 Intent 动态修改 Engine 参数

**最近刚刚合并了两个新的 PR #190870 和  #191924，直接禁止了之前应用启动时，外部传入的 Android Intent 可以携带 Flutter Engine 的底层参数的能力，包括引擎启动方式、Dart 配置、渲染和调试选项**：

| PR      | 合并时间   | 主要改动                                                     |
| ------- | ---------- | ------------------------------------------------------------ |
| #190870 | 2026-09-30 | 修改 Flutter CLI，阻止给预编译 Release APK 动态传入 Engine 配置参数 |
| #191924 | 2026-10-03 | 修改 Android Embedding，使 Release 模式直接忽略 Intent 中的 Engine 参数，并移除相应解析逻辑 |

在之前 Flutter 的 Android  App 为了方便开发者调试，支持在启动 `Activity` 时会顺便把 Engine 参数放到 Intent extras 里面，Android Embedding 会读取这些参数，转换成底层 Engine 能识别的命令行参数，比如：

```sh
adb shell am start \
  -n com.example.app/.MainActivity \
  --ez trace-startup true \
  --ez enable-software-rendering true
```

这些参数会被传给 Flutter Engine，控制启动追踪、渲染方式相关的行为，这样的设计对于调试很方便，已经编译好的 APK 不需要修改代码，就能临时调整 Engine 行为。

![](/article-assets/15a5eddd2388010e2b0d014a.webp)

但这里有个安全问题：**Android Intent 是跨组件传递数据的机制，而 Engine 参数属于底层运行时的高权限配置**，如果一个 Flutter Activity 对其他应用开放，或者存在不安全的 Intent 转发路径，恶意应用就可能把自己构造的数据送进 Flutter 的启动流程。

比如最危险的例子之一是 `--aot-shared-library-name`，Flutter Release  用的是  AOT 编译，运行时需要加载包含 Dart 编译产物的原生共享库，这个参数涉及共享库的路径选择，Flutter 团队在最早的 #180686 就说过，攻击者可能利用恶意库路径实现原生代码执行。

> **也就是说，风险可能涉及原生代码加载，后果会比切换一个 UI 路由或者修改日志级别严重。**

当然，这不等于任何第三方应用都能攻击所有 Flutter APK，实际攻击还受到 Activity 是否可达、Android 组件权限、文件路径校验和应用沙箱等条件约束，目前主要还是存在潜在攻击面，所以有处理掉的必要。

Flutter 原本想彻底删除 Intent 配置能力，后来发现这样会破坏大量实际工程场景，尤其是使用 Bazel 等构建系统的项目，它们通常会先构建一次 APK，再重复安装和测试，每次启动时动态修改 Engine 参数，所以如果彻底删除，很多自动化测试就必须重新编译 APK，成本明显增加，**所以官方最终调整方案，只禁止 Release，保留 Debug/Profile**。

之前的实现将 Intent 解析与 Engine 初始化放在同一套 Android Embedding 代码中，通过运行时条件限制行为，现在修改后会用不同构建模式的 Java 实现，在 Android Embedding 编译阶段就将这两个分开，具体就在 `engine/src/flutter/shell/platform/android/BUILD.gn` 新增的选择逻辑：

```dart
if (flutter_runtime_mode == "release" ||
    flutter_runtime_mode == "jit_release") {
  android_java_sources += [
    "release/io/flutter/embedding/engine/flags/FlutterEngineFlagsProviderImpl.java"
  ]
} else {
  android_java_sources += [
    "debug/io/flutter/embedding/engine/flags/FlutterEngineFlagsProviderImpl.java"
  ]
}
```

这里两份实现使用相同的类名和接口，所以上层 `FlutterActivity` 不需要反复判断当前是不是 Release，然后编译时就已经确定采用哪一种实现。

![](/article-assets/8cd1a5e79341a1eb1c683b84.webp)

Debug/Profile 版本的核心逻辑是：

```dart
for (String key : extras.keySet()) {
  FlutterEngineFlags.Flag flag =
      FlutterEngineFlags.getFlagFromIntentKey(key);

  if (flag != null) {
    Object value = extras.get(key);

    if (value instanceof Boolean) {
      // 转换 boolean 参数
    } else if (value instanceof Integer) {
      // 转换 int 参数
    } else if (value instanceof String) {
      // 转换字符串参数
    }
  }
}
```

也就是实际代码在处理 boolean 时还会区分纯开关和带 `=` 的参数，比如 `--trace-startup` 与 `--enable-impeller=false`。

Release 版本的核心逻辑就非常简单：

```dart
@Override
public List<String> getFlags(Intent intent) {
    warnIfFlagsPresent(intent);
    return Collections.emptyList();
}

@Override
public boolean isSoftwareRenderingEnabled(Intent intent) {
    return false;
}
```

> 实际上 Release 版本没有完全不读取 Intent，`warnIfFlagsPresent()` 还是会检查是否存在已知 Engine Flag，用于输出警告，但不会把这些值转换为实际的启动参数。

然后 FlutterActivity 的 API 也改了，原来的 `public FlutterShellArgs getFlutterShellArgs()` 被替换成了  `public List<String> getFlutterEngineFlags()` ，新的 `FlutterActivity` 调用对应模式的 `FlutterEngineFlagsProviderImpl.INSTANCE.getFlags(getIntent())`，同时将返回的参数列表交给 Engine 创建逻辑。

> `FlutterFragment` 也增加了对应 API，同时保留了使用参数列表配置新 Engine 的方式。

同步 Flutter CLI 也改了，比如某个测试系统有一个提前编译的 Release APK：

```sh
flutter run --release \
  --use-application-binary=app-release.apk \
  --trace-startup
```

原来 Flutter CLI 会通过 ADB 将 `trace-startup` 等配置放进 Intent，APK 启动时再解析，现在 Release Engine 已经不会接受这种配置，如果 CLI 不改限制，测试系统可能误以为性能追踪已经开启。

所以 #190870 增加了 `validatePrebuiltAndroidApplicationFlags()`，检测三个条件：

- 当前为 Release 模式
- 运行预编译 APK
- 命令行显式传入 Android Engine 配置参数

三个条件同时成立时直接 `throwToolExit`，要求开发者在构建阶段配置这些参数，这里校验被放在 `RunCommandBase`  里面，通过  `flutter run` 和 `flutter drive` 调用，所以普通的 `flutter doctor`、`flutter clean` 不会被这次修改影响。

其次，PR 新增  `AndroidEngineCliFlags`  集中维护参数名，同时将 `DebuggingOptions` 的配置统一成一份 Map，再分别转换为 Manifest 使用的参数字符串与 ADB Intent extras，减少两套实现不一致的问题：

| 执行方式                                                 | 改造后行为                            |
| -------------------------------------------------------- | ------------------------------------- |
| `flutter run --debug`                                    | 继续通过 Intent 动态传参              |
| `flutter run --profile`                                  | 继续通过 Intent 动态传参              |
| `flutter run --release`                                  | 在构建过程中把支持的参数写入 Manifest |
| `flutter run --release --use-application-binary=app.apk` | 不额外传 Engine 参数时正常执行        |
| 上一条命令再加 `--trace-startup`                         | CLI 直接报错                          |
| 对 Release APK 用 ADB Intent 传 Engine 参数              | Embedding 忽略，并记录警告            |

这里主要可能会影响一些自动化测试的场景，比如你的测试平台要对同一个 APK 执行三组性能实验：默认渲染、启动 Trace、特定 Engine 参数配置。

以前可以先构建一次 Release APK，再多次执行 `adb shell am start`，每次通过 Intent 调整底层 Engine 参数，现在如果采用新版 Flutter 的 Release 产物，这种做就不行，不过你用 Profile 还是能解决问题。

如果必须测量真正的 Release 产物，可以在构建时固定参数，按照测试场景生成不同 APK，比如运行启动追踪：

```
flutter run --release --trace-startup
```

对于允许在 Release 使用的 `trace-startup` 参数，Flutter CLI 会在构建的时候将它写入最终 Manifest，这样就不会再依赖启动时的 Intent，或者直接在 `AndroidManifest.xml` 的 `<application>` 内声明：

```xml
<meta-data
    android:name="io.flutter.embedding.android.TraceStartup"
    android:value="true" />
```

这也意味着 Profile 与 Release 的性能测试需要区分使用场景，Profile 适合自动化迭代、动态切换参数，而 Release 更适合最终发布形态下的性能验收。

另外  Add-to-App 也需要关注原生宿主代码，如果一个原生 Android App 嵌入了 Flutter 页面，然后通过 Intent extras 在运行时修改 Engine 配置，这部分代码需要迁移，比如 ：

```
class MyFlutterActivity : FlutterActivity() {
    override fun getFlutterEngineFlags(): List<String> {
        val flags = super.getFlutterEngineFlags().toMutableList()
        flags.add("--trace-startup")
        return flags
    }
}
```

也可以用 `FlutterFragment.withNewEngine()` 的 `flutterEngineFlags(...)` Builder API，或者通过宿主程序提前初始化和缓存 Engine。

> 需要注意，原生代码直接提供参数还是会受到 Release 参数允许列表 `allowedInRelease` 的限制，对外部输入的校验责任也还是在应用开发者手上。
