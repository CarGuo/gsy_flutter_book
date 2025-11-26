# iOS 26  开始强制 UIScene ，你的 Flutter 插件准备好迁移支持了吗？

在今年的  WWDC25 上，Apple 发布 [TN3187](https://developer.apple.com/documentation/technotes/tn3187-migrating-to-the-uikit-scene-based-life-cycle) 文档，其中明确了要求：“**在 iOS 26 之后的版本，任何使用最新 SDK 构建的 UIKit 应用都必须使用 `UIScene` 生命周期，否则将无法启动**” ：

> 实际上 UIScene 不是什么新鲜东西，反而是一个老古董，毕竟它是在  iOS 13 中引入的，它的核心思想是将应用的“进程”生命周期和“UI 实例”的生命周期分离，让应用可以同时管理多个独立的 UI 实例 。

而在此之前，iOS 主要围绕单体模型  `UIApplicationDelegate`  来实现生命周期管理，例如：

- 负责处理应用进程的启动与终止 `application(_:didFinishLaunchingWithOptions:)` / `applicationWillTerminate(_:)`  
- 所有与 UI 状态相关的事件，例如应用进入前台并变得活跃 (`applicationDidBecomeActive(_:)`) 或进入后台 (`applicationDidEnterBackground(_:)`)
- 窗口管理 `AppDelegate` 拥有并管理着应用唯一的 `UIWindow` 实例
- 处理系统级事件，包括响应远程推送通知、处理通过 URL Scheme  如 Deeplink 等 

所以可以明显看到，这种单体模型的架构最根本的缺陷在于，将应用进程与 UI 界面紧密绑定，导致整个应用只有一个统一的 UI 状态。

但是这在之前对于 Flutter 来说并没有什么问题，因为 Flutter 默认本身就是一个单页面的架构，**虽然存在 `UIScene ` ，但是  `AppDelegate` 就满足需求了**，所以在本次迁移到 `UIScene` 生命周期之前，Flutter 在 iOS 平台上的整个原生集成都围绕着 `UIApplicationDelegate` 构建 ，而随着本次 TN3187 的要求，Flutter 不得不开始完全迁移到  `UIScene`  模型。

对于 ` UIScene`  模型，整个逻辑主要入了三个概念：

- `UIScene`：代表应用 UI 的一个独立实例，绝大多数情况下开发者熟悉的就是 `UIWindowScene`，它管理着一个或多个窗口以及相关的 UI 
- `UISceneSession`：持久化对象，它代表一个场景的配置和状态，比如即使其对应的 `UIScene`  实例因为资源回收等原因被系统断开连接或销毁，`UISceneSession` 依然存在，保存着恢复该场景所需的信息，是实现状态恢复的关键 
- `UISceneDelegate`：作为 `UIScene` 的代理，它专门负责管理特定场景的生命周期事件，例如连接、断开、进入前台、进入后台等 

所以到这里，可以很明显看出来，`UIApplicationDelegate`  和  `UISceneDelegate` 有了进一步的明显分割：

- `UIApplicationDelegate`  ：处理进程级别的事件，比如应用启动和终止的，并负责处理推送通知的注册等全局任务
- `UISceneDelegate` ：接管了所有与 UI 相关的生命周期管理，包括场景的创建与连接 (`scene(_:willConnectTo:options:)`)，活跃 (`sceneDidBecomeActive(_:)`)；进入后台 (`sceneDidEnterBackground(_:)`)；以及断开连接 (`sceneDidDisconnect(_:)`)  等

具体大概会是以下的关系变化：

| AppDelegate                                                  | SceneDelegate                     | 新增                                                 | **范围与职责转移**                                           | **关键行为差异**                                             |
| ------------------------------------------------------------ | --------------------------------- | ---------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `application(_:didFinishLaunchingWithOptions:)`              | `scene(_:willConnectTo:options:)` | `application(_:configurationForConnecting:options:)` | 从 `AppDelegate` 转移到 `SceneDelegate`，`AppDelegate` 仍处理非 UI 的全局初始化（如三方库配置），`SceneDelegate` 负责创建 `UIWindow` 和设置根视图控制器 | `AppDelegate` 的 `didFinishLaunchingWithOptions` 在应用冷启动时仅调用一次，`SceneDelegate` 的 `willConnectTo` 在每个场景（窗口）创建时都会调用。 |
| `applicationDidBecomeActive(_:)`                             | `sceneDidBecomeActive(_:)`        | -                                                    | 从应用级转移到场景级，`AppDelegate` 的方法在场景模型下不再被调用 | `sceneDidBecomeActive` 针对单个场景，允许对不同窗口进行独立的激活处理 |
| `applicationWillResignActive(_:)`                            | `sceneWillResignActive(_:)`       | -                                                    | 从应用级转移到场景级，`AppDelegate` 的方法在场景模型下不再被调用 | `sceneWillResignActive` 针对单个场景，例如当一个窗口被另一个应用（如 Slide Over）遮挡时触发 |
| `applicationDidEnterBackground(_:)`                          | `sceneDidEnterBackground(_:)`     | -                                                    | 从应用级转移到场景级，`AppDelegate` 的方法在场景模型下不再被调用 | `sceneDidEnterBackground` 允许对每个场景的状态进行独立保存。 |
| `applicationWillEnterForeground(_:)`                         | `sceneWillEnterForeground(_:)`    | -                                                    | 从应用级转移到场景级，`AppDelegate` 的方法在场景模型下不再被调用 | `sceneWillEnterForeground` 在应用冷启动时也会被调用，而 `applicationWillEnterForeground` 不会。这是迁移过程中常见的逻辑错误来源 |
| `application(_:open:options:)`                               | `scene(_:openURLContexts:)`       | -                                                    | 从应用级转移到场景级，`AppDelegate` 的方法在场景模型下不再被调用 | `scene(_:openURLContexts:)` 接收到的 URL 会被路由到最合适的场景进行处理 |
| `application(_:continue:restoreHandler:)`                    | `scene(_:continue:)`              | -                                                    | 从应用级转移到场景级                                         | `scene(_:continue:)` 允许为特定场景恢复用户活动状态          |
| `applicationWillTerminate(_:)`                               | `sceneDidDisconnect(_:)`          | `application(_:didDiscardSceneSessions:)`            | `applicationWillTerminate` 仍表示整个应用的终止，`sceneDidDisconnect` 表示场景被系统回收资源（可能重连），`didDiscardSceneSessions` 表示用户通过应用切换器关闭了场景（永久销毁） | 职责更加细化，`sceneDidDisconnect` 不等于应用终止，而 `didDiscardSceneSessions` 是清理被用户主动关闭的场景资源的入口。 |
| `application(_:didReceiveRemoteNotification:fetchCompletionHandler:)` | -                                 | -                                                    | 职责保留在 `AppDelegate`，推送通知是进程级事件，不与特定 UI 实例绑定 | 即使在场景模型下，推送通知的接收和处理逻辑仍然主要位于 `AppDelegate` |

而对于 Flutter Framework 层面的变化，主要有：

- **引擎渲染逻辑**：Flutter 需要修改 GPU 线程的管理方式，之前引擎主要是根据 `UIApplication` 的全局通知来暂停或恢复渲染，而迁移后必须改为监听基于单个 `UIScene` 的通知，以正确处理多窗口下的渲染暂停和恢复 

  

- **废弃 API 替换**：引擎和框架代码中之前使用了 `UIApplication.shared.keyWindow` API 来获取应用的窗口，这些调用都必须被替换

  

- **插件注册机制**：由于 `FlutterViewController` 的创建时机发生变化，插件的注册和关联 `FlutterEngine` 的机制也需要重构，确保在正确的时机与正确的引擎实例关联 

而对于Flutter 插件来说， **任何依赖于 UI 生命周期事件或需要与 UI 窗口交互的插件都可能受到了影响**，Flutter 官方对第一方插件进行了大规模的迁移 ：  

- `url_launcher_ios`：需要获取当前窗口来呈现浏览器视图
- `local_auth_darwin`：进行生物识别认证时需要与 UI 交互 
- `image_picker_ios`：需要呈现图片选择界面 
- `google_sign_in_ios`：需要弹出登录窗口 
- `quick_actions_ios`：处理主屏幕快捷操作，其回调方法从 `AppDelegate` 转移到了 `SceneDelegate` 

![](https://img.cdn.guoshuyu.cn/image-20251028111609650.png)

而对于 Flutter 应用开发者，Flutter 提供了一条自动化和通用的手动迁移方式：

1、自动化迁移（推荐）：如果你的 Flutter 项目的原生 iOS 部分（`ios` 文件夹）没有经过大量定制化修改，可以使用 Flutter CLI 提供的实验性功能来自动完成迁移。

- 在终端中运行以下命令，开启 `UIScene` 自动迁移开关
    ```sh
    flutter config --enable-uiscene-migration
    ```
- 然后正常地构建或运行你的 iOS 应用
   ```Shell
            flutter build ios
            ///or
            flutter run
   ```
- 在构建过程中，Flutter 工具会检查项目配置，如果符合条件会自动执行以下操作：

  - 修改 `AppDelegate.swift`（或 `.m`），移除过时的 UI 生命周期回调

  - 在 `ios/Runner/` 目录下创建一个新的 `SceneDelegate.swift`（或 `.h`/`.m`）文件继承自 `FlutterSceneDelegate`

  - 更新 `Info.plist` 文件，添加必要的 `UIApplicationSceneManifest` 配置

- 迁移成功后，会在构建日志中看到 "*Finished migration to UIScene lifecycle*" 的提示，如果项目过于复杂无法自动迁移，工具会给出警告，并提示你进行手动迁移 



2、手动迁移：对于那些有复杂原生代码、自定义 `AppDelegate` 或其他特殊配置的应用，需要手动迁移：

- 修改 `AppDelegate.swift`：

	- 打开 `ios/Runner/AppDelegate.swift`，删除所有与 UI 生命周期相关的方法，例如 `applicationDidBecomeActive`、`applicationWillResignActive`、`applicationDidEnterBackground`、`applicationWillEnterForeground` （可以参考前面的表格）
	- 保留 `application(_:didFinishLaunchingWithOptions:)` 方法，但确保其中只包含应用级的初始化逻辑（如注册插件、配置三方服务），移除所有创建和设置 `window` 的代码
	- 确保 `AppDelegate` 类继承自 `FlutterAppDelegate`（如果之前不是的话），或者遵循 `FlutterAppLifeCycleProvider` 协议

- 创建 `SceneDelegate.swift`：

  - 在 Xcode 中，右键点击 `Runner` 文件夹，选择 "New File..." -> "Swift File"，命名为 `SceneDelegate.swift`

  - 将以下代码粘贴到新文件，这段代码定义了一个最简的 `SceneDelegate`，它继承 `FlutterSceneDelegate`，从而自动获得了将场景生命周期事件桥接到 Flutter 引擎的能力
  ```Swift
        import UIKit
        import Flutter

        class SceneDelegate: FlutterSceneDelegate {
          // 你可以在这里重写 FlutterSceneDelegate 的方法
          // 来添加自定义的场景生命周期逻辑。
        }
  ```

- 更新 `Info.plist`：

  - 打开 `ios/Runner/Info.plist`，在根 `dict` 标签内，添加以下 `UIApplicationSceneManifest` ：

      ```XML
      <key>UIApplicationSceneManifest</key>
      <dict>
          <key>UIApplicationSupportsMultipleScenes</key>
          <false/>
          <key>UISceneConfigurations</key>
          <dict>
              <key>UIWindowSceneSessionRoleApplication</key>
              <array>
                  <dict>
                      <key>UISceneConfigurationName</key>
                      <string>Default Configuration</string>
                      <key>UISceneDelegateClassName</key>
                      <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                  </dict>
              </array>
          </dict>
      </dict>
      ```

 

- 迁移自定义逻辑：
  - 如果你之前在 `didFinishLaunchingWithOptions` 中有创建 Method Channels 或 Platform Views 的逻辑，这些逻辑都需要迁移，因为在 `didFinishLaunchingWithOptions` 执行时，`FlutterViewController` 可能还不存在
  - 一个更好的位置是在 `SceneDelegate` 的 `scene(_:willConnectTo:options:)` 方法，或者创建一个专门的初始化方法，在场景连接后调用，Flutter 的建议将这类逻辑移至 `didInitializeImplicitFlutterEngine` 方法



最后就是“天见犹怜”的插件开发者，对于插件作者而言 `UIScene` 迁移带来了更大的挑战：**必须确保插件既能在已经迁移到 `UIScene` 的新应用中正常工作，也要能在尚未迁移的旧应用或旧版 iOS 系统上保持兼容**，例如：

- 一个依赖生命周期事件的插件（例如，一个在应用进入后台时暂停视频播放的插件）不能简单地把监听代码从 `AppDelegate` 移到 `SceneDelegate`，这样做会导致它在未迁移的应用中完全失效，因此插件必须能够同时处理两种生命周期模型 

- 具体插件迁移步骤：

  - **注册场景事件监听**：在插件的 `register(with registrar: FlutterPluginRegistrar)` 方法中，除了像以前一样通过 `registrar.addApplicationDelegate(self)` 注册 `AppDelegate` 事件监听外，还需要调用新的 API 来注册 `SceneDelegate` 事件的监听，Flutter 提供了相应的机制让插件可以接收到场景生命周期的回调 

  - **实现双重生命周期处理**：插件内部需要实现 `UISceneDelegate` 协议中的相关方法，在实现时要设计一种优雅降级的逻辑。例如同时实现 `applicationDidEnterBackground` 和 `sceneDidEnterBackground`，当 `sceneDidEnterBackground` 被调用时，执行相应逻辑并设置一个标志位，以避免 `applicationDidEnterBackground` 中的逻辑重复执行（如果它也被意外调用的话）

  - **更新废弃的 API 调用**：插件代码中任何对 `UIApplication.shared.keyWindow` 或其他与单一窗口相关的废弃 API 的调用都必须被替换


例如 `url_launcher_ios` 插件的迁移： ，在 `UIScene` 之前，当需要弹出一个外部浏览器窗口时，它可能需要获取应用的 `keyWindow` 作为视图层级的参考： 

  ```Swift
  // 迁移前
  if let window = UIApplication.shared.keyWindow {
      // Use window to present something...
  }
  ```

  ```Swift
  ///迁移后
  // Accessing the window through the registrar, which is scene-aware.
  if let window = self.pluginRegistrar.view?.window {
      // Use the scene-specific window...
  }
  // A more robust approach for finding the key window in a scene-based app
  let keyWindow = self.pluginRegistrar.view?.window?.windowScene?.keyWindow
  ```

  这个例子可以看到，插件从直接访问全局单例 `UIApplication.shared.keyWindow`，转变为通过与插件关联的 `pluginRegistrar` 来获取视图 (`view`)，再从该视图向上追溯到其所在的 `window` 和 `windowScene`，最终找到正确的窗口。

> 所以对于插件开发者来说，需要适配不同版本的 Flutter 来完成工作，无疑加大了成本。

这其实也在一定程度来自于历史技术债务，因为其实 `UIScene` 是很早前就存在的 API ，但是由于 Flutter 场景的特殊性，默认  `UIApplicationDelegate`  一直满足需求，而面对这次 iOS 的强制调整，历史债务就很明显的爆发出来，特别是对于社区第三方开发者的适配成本。

不过好消息是，我们还有时间，而全新的 Flutter  `3.38.0-0.1.pre` 也才刚刚出来，但是这对 Flutter 下个版本的稳定性也是一个挑战，因为这也是一个底层较大重构。

# 参考链接

- https://developer.apple.com/documentation/technotes/tn3187-migrating-to-the-uikit-scene-based-life-cycle
- https://docs.flutter.dev/release/breaking-changes/uiscenedelegate#migration-guide-for-flutter-plugins