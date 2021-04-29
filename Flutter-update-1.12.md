`Flutter Interact` 除了带来各种新的开发工具之外，最大的亮点莫过于 **1.12 稳定版本**的发布。

不同于之前的版本，**1.12.x 版本**对 `Flutter Framework` 做了较多的不兼容性升级，例如在 Dart 层： `ImageProvider` 的 `load` 增加了 `DecoderCallback` 参数、[TextField's minimum height 从 40 调整到了 48](https://github.com/flutter/flutter/pull/42449) 、[PageView 开始使用 SliverLayoutBuilder 而弃用 RenderSliverFillViewport](https://github.com/flutter/flutter/pull/37024) 等相关的不兼容升级。

但是上述的问题都不致命，因为只需要调整相关的 Dart 代码便可以直接解决问题，而此次涉及最大的调整，应该是 **[Android 插件的改进 Android plugins APIs](https://flutter.dev/docs/development/packages-and-plugins/plugin-api-migration) 的相关变化，该调整需要用户重新调整 Flutter 项目中 Android 模块和插件的代码进行适配。**

## 一、Android Plugins 

### 1、介绍

在 Flutter 1.12 开始 Flutter 团队调整了 Android 插件的实现代码，**在 1.12 之后 Android 开始使用新的插件 API ，基于的旧的 `PluginRegistry.Registrar` 不会立即被弃用，但官方建议迁移到基于的新API `FlutterPlugin` ，另外新版本官方建议插件直接使用 `Androidx` 支持**，官方提供的插件也已经全面升级到  `Androidx`。

与旧的 API 相比，新 API 的优势在于：为插件所依赖的生命周期提供了一套更解耦的使用方法，例如以前 `PluginRegistry.Registrar.activity()` 在使用时，如果 Flutter 还没有添加到 `Activity` 上时可能返回 `null` ，同时插件不知道自己何时被引擎加载使用，而新的 API 上这些问题都得到了优化。

### 1、升级

**在新 API 上 Android 插件需要使用 `FlutterPlugin` 和 `MethodCallHandler` 进行实现**，同时还提供了 **`ActivityAware`** 用于 `Activity` 的生命周期管理和获取，提供 **`ServiceAware`** 用于 `Service` 的生命周期管理和获取，具体迁移步骤为：

1、更新主插件类（`*Plugin.java`）用于实现 `FlutterPlugin`， 也就是正常情况下 Android 插件需要继承 `FlutterPlugin`  和 `MethodCallHandler` 这两个接口，如果需要用到 `Activity` 有需要继承 `ActivityAware` 接口。

以前的 Flutter 插件都是直接继承 `MethodCallHandler` 然后提供  `registerWith` 静态方法；而升级后如下代码所示，这里还保留了 `registerWith` 静态方法，是因为还需要针对旧版本做兼容支持，同时新版 API 中 `MethodCallHandler` 将在 `onAttachedToEngine` 方法中被初始化和构建，在 `onDetachedFromEngine` 方法中释放；同时 `Activity` 相关的四个实现方法也提供了相应的操作逻辑。

```
public class FlutterPluginTestNewPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  private static MethodChannel channel;

   /// 保留旧版本的兼容
  public static void registerWith(Registrar registerWith) {
    Log.e("registerWith", "registerWith");
    channel = new MethodChannel(registerWith.messenger(), "flutter_plugin_test_new");
    channel.setMethodCallHandler(new FlutterPluginTestNewPlugin());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      Log.e("onMethodCall", call.method);
      result.success("Android " + android.os.Build.VERSION.RELEASE);
      Map<String, String> map = new HashMap<>();
      map.put("message", "message");
      channel.invokeMethod("onMessageTest", map);
    } else {
      result.notImplemented();
    }
  }

//// FlutterPlugin 的两个 方法
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    Log.e("onAttachedToEngine", "onAttachedToEngine");
    channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "flutter_plugin_test_new");
    channel.setMethodCallHandler(new FlutterPluginTestNewPlugin());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    Log.e("onDetachedFromEngine", "onDetachedFromEngine");
  }


  ///activity 生命周期
  @Override
  public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
    Log.e("onAttachedToActivity", "onAttachedToActivity");

  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    Log.e("onDetachedFromActivityForConfigChanges", "onDetachedFromActivityForConfigChanges");

  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding activityPluginBinding) {
    Log.e("onReattachedToActivityForConfigChanges", "onReattachedToActivityForConfigChanges");
  }

  @Override
  public void onDetachedFromActivity() {
    Log.e("onDetachedFromActivity", "onDetachedFromActivity");
  }
}
```
---

**简单来说就是需要多继承 `FlutterPlugin` 接口，然后在 `onAttachedToEngine` 方法中构建 `MethodCallHandler` 并且 `setMethodCallHandler` ，之后同步在保留的 `registerWith`  方法中实现 `onAttachedToEngine` 中类似的初始化。** 

运行后的插件在正常情况下调用的输入如下所示：

```
2019-12-19 18:01:31.481 24809-24809/? E/onAttachedToEngine: onAttachedToEngine
2019-12-19 18:01:31.481 24809-24809/? E/onAttachedToActivity: onAttachedToActivity
2019-12-19 18:01:31.830 24809-24809/? E/onMethodCall: getPlatformVersion
2019-12-19 18:05:48.051 24809-24809/com.shuyu.flutter_plugin_test_new_example E/onDetachedFromActivity: onDetachedFromActivity
2019-12-19 18:05:48.052 24809-24809/com.shuyu.flutter_plugin_test_new_example E/onDetachedFromEngine: onDetachedFromEngine
```

另外，**如果你插件是想要更好兼容模式对于旧版 Flutter Plugin 运行，`registerWith` 静态方法其实需要调整为如下代码所示：**

```
  public static void registerWith(Registrar registrar) {
    channel = new MethodChannel(registrar.messenger(), "flutter_plugin_test_new");
    channel.startListening(registrar.messenger());
  }
```

---

当然，如果是 Kotlin 插件，可能会是如下图所示类似的更改。

![](http://img.cdn.guoshuyu.cn/20191227_Flutter-update-1.12/image1)



2、如果条件允许可以修改主项目的 `MainActivity` 对象，**将继承的 `FlutterActivity 从 io.flutter.app.FlutterActivity` 替换为 `io.flutter.embedding.android.FlutterActivity`，之后 插件就可以自动注册；** 如果条件不允许不继承  `FlutterActivity` 的需要自己手动调用 `GeneratedPluginRegistrant.registerWith` 方法 ，当然到此处可能会提示 `registerWith` 方法调用不正确，不要急忽略它往下走。

```
/// 这个方法如果在下面的 3 中 AndroidManifest.xml 不打开 flutterEmbedding v2 的配置，就需要手动调用
@Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }
```

> 如果按照 3 中一样打开了 v2 ，那么生成的 GeneratedPluginRegistrant 就是使用 FlutterEngine ，不配置  v2 使用的就是 PluginRegistry 。

3、之后还需要调整 `AndroidManifest.xml` 文件，如下图所示，需要将原本的 `io.flutter.app.android.SplashScreenUntilFirstFrame` 这个 `meta-data` 移除，然后增加为 `io.flutter.embedding.android.SplashScreenDrawable` 和 `io.flutter.embedding.android.NormalTheme` 这两个 `meta-data` ，主要是用于应用打开时的占位图样式和进入应用后的主题样式。 

![](http://img.cdn.guoshuyu.cn/20191227_Flutter-update-1.12/image2)

**这里还要注意，如上图所示需要在 `application` 节点内配置 `flutterEmbedding` 才能生效新的插件加载逻辑。**

```
    <meta-data
        android:name="flutterEmbedding"
        android:value="2" />
```

4、之后就可以执行 `flutter packages get` 去生成了新的 `GeneratedPluginRegistrant` 文件，如下代码所示，新的 `FlutterPlugin` 将被 `flutterEngine.getPlugins().add` 直接加载，而旧的插件实现方法会通过 `ShimPluginRegistry` 被兼容加载到 v2 的实现当中。

```
@Keep
public final class GeneratedPluginRegistrant {
  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
    ShimPluginRegistry shimPluginRegistry = new ShimPluginRegistry(flutterEngine);
    flutterEngine.getPlugins().add(new io.flutter.plugins.androidintent.AndroidIntentPlugin());
    flutterEngine.getPlugins().add(new io.flutter.plugins.connectivity.ConnectivityPlugin());
    flutterEngine.getPlugins().add(new io.flutter.plugins.deviceinfo.DeviceInfoPlugin());
      io.github.ponnamkarthik.toast.fluttertoast.FluttertoastPlugin.registerWith(shimPluginRegistry.registrarFor("io.github.ponnamkarthik.toast.fluttertoast.FluttertoastPlugin"));
    flutterEngine.getPlugins().add(new io.flutter.plugins.packageinfo.PackageInfoPlugin());
    flutterEngine.getPlugins().add(new io.flutter.plugins.pathprovider.PathProviderPlugin());
      com.baseflow.permissionhandler.PermissionHandlerPlugin.registerWith(shimPluginRegistry.registrarFor("com.baseflow.permissionhandler.PermissionHandlerPlugin"));
    flutterEngine.getPlugins().add(new io.flutter.plugins.share.SharePlugin());
    flutterEngine.getPlugins().add(new io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin());
      com.tekartik.sqflite.SqflitePlugin.registerWith(shimPluginRegistry.registrarFor("com.tekartik.sqflite.SqflitePlugin"));
    flutterEngine.getPlugins().add(new io.flutter.plugins.urllauncher.UrlLauncherPlugin());
    flutterEngine.getPlugins().add(new io.flutter.plugins.webviewflutter.WebViewFlutterPlugin());
  }
}
```

5、最后是可选升级，在 `android/gradle/wrapper` 下的 `gradle-wrapper.properties` 文件，可以将 `distributionUrl` 修改为 `gradle-5.6.2-all.zip` 的版本，同时需要将 `android/` 目录下的 `build.gradle` 文件的 gradle 也修改为 `com.android.tools.build:gradle:3.5.0` ; 另外 `kotlin` 插件版本也可以升级到 `ext.kotlin_version = '1.3.50'` 。

## 二、其他升级

1、如果之前的项目还没有启用 `Androidx` ，那么可以在 `android/` 目录下的 `gradle.properties` 添加如下代码打开 `Androidx` 。

```
android.enableR8=true
android.useAndroidX=true
android.enableJetifier=true

```


2、需要在忽略文件增加 `.flutter-plugins-dependencies` 。

3、更新之后如果对 iOS 包变大有疑问，可以查阅 [#47101](https://github.com/flutter/flutter/issues/47101#issuecomment-567522077) ，这里已经很好的描述了这段因果关系；另外如果发现 iOS13 真机无法输入 log 的问题，可以查看 [#41133](https://github.com/flutter/flutter/issues/41133) 。

![](http://img.cdn.guoshuyu.cn/20191227_Flutter-update-1.12/image3)

4、如下图所示，1.12.x 的升级中 iOS 的 `Podfile` 文件也进行了调整，如果还使用旧文件可能会到相应的警告，相关配置也在下方贴出。


![](http://img.cdn.guoshuyu.cn/20191227_Flutter-update-1.12/image4)


```
# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def parse_KV_file(file, separator='=')
  file_abs_path = File.expand_path(file)
  if !File.exists? file_abs_path
    return [];
  end
  generated_key_values = {}
  skip_line_start_symbols = ["#", "/"]
  File.foreach(file_abs_path) do |line|
    next if skip_line_start_symbols.any? { |symbol| line =~ /^\s*#{symbol}/ }
    plugin = line.split(pattern=separator)
    if plugin.length == 2
      podname = plugin[0].strip()
      path = plugin[1].strip()
      podpath = File.expand_path("#{path}", file_abs_path)
      generated_key_values[podname] = podpath
    else
      puts "Invalid plugin specification: #{line}"
    end
  end
  generated_key_values
end

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # Flutter Pod

  copied_flutter_dir = File.join(__dir__, 'Flutter')
  copied_framework_path = File.join(copied_flutter_dir, 'Flutter.framework')
  copied_podspec_path = File.join(copied_flutter_dir, 'Flutter.podspec')
  unless File.exist?(copied_framework_path) && File.exist?(copied_podspec_path)
    # Copy Flutter.framework and Flutter.podspec to Flutter/ to have something to link against if the xcode backend script has not run yet.
    # That script will copy the correct debug/profile/release version of the framework based on the currently selected Xcode configuration.
    # CocoaPods will not embed the framework on pod install (before any build phases can generate) if the dylib does not exist.

    generated_xcode_build_settings_path = File.join(copied_flutter_dir, 'Generated.xcconfig')
    unless File.exist?(generated_xcode_build_settings_path)
      raise "Generated.xcconfig must exist. If you're running pod install manually, make sure flutter pub get is executed first"
    end
    generated_xcode_build_settings = parse_KV_file(generated_xcode_build_settings_path)
    cached_framework_dir = generated_xcode_build_settings['FLUTTER_FRAMEWORK_DIR'];

    unless File.exist?(copied_framework_path)
      FileUtils.cp_r(File.join(cached_framework_dir, 'Flutter.framework'), copied_flutter_dir)
    end
    unless File.exist?(copied_podspec_path)
      FileUtils.cp(File.join(cached_framework_dir, 'Flutter.podspec'), copied_flutter_dir)
    end
  end

  # Keep pod path relative so it can be checked into Podfile.lock.
  pod 'Flutter', :path => 'Flutter'

  # Plugin Pods

  # Prepare symlinks folder. We use symlinks to avoid having Podfile.lock
  # referring to absolute paths on developers' machines.
  system('rm -rf .symlinks')
  system('mkdir -p .symlinks/plugins')
  plugin_pods = parse_KV_file('../.flutter-plugins')
  plugin_pods.each do |name, path|
    symlink = File.join('.symlinks', 'plugins', name)
    File.symlink(path, symlink)
    pod name, :path => File.join(symlink, 'ios')
  end
end

# Prevent Cocoapods from embedding a second Flutter framework and causing an error with the new Xcode build system.
install! 'cocoapods', :disable_input_output_paths => true

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end

```
----

#### 好了，暂时就到这了。


### Flutter 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)


### 资源推荐

* Github ： https://github.com/CarGuo
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**
* 开源 React Native 项目：https://github.com/CarGuo/GSYGithubApp



![](http://img.cdn.guoshuyu.cn/20191227_Flutter-update-1.12/image5)