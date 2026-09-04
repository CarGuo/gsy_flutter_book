---
title: "Flutter 最好的 AI 自动化测试工具：Patrol"
---

# Flutter 最好的 AI 自动化测试工具：Patrol

Patrol 是一个**专为 Flutter 实现的跨平台 E2E 测试开源框架**， 主要是 LeanCode 在开发和维护，它最大的作用就是弥补了 Flutter 官方 integration_test 的短板，特别是在 Native 交互方面和对 AI 友好。

![](https://img.cdn.guoshuyu.cn/723a121f-3ba8-4103-9a27-e50f37c9c54a.png)

开发者可以用  Flutter 风格来写 Patrol 的测试用力，**测试过程除了支持操控 Flutter Widget 之外，最重要是可以深入控制 iOS/Android 的原生组件**。

> 简单说，Patrol 通过在 Flutter 测试进程和原生自动化服务之间，建立双向 gRPC 通信来实现 Flutter 的全面自动化测试。

![](https://img.cdn.guoshuyu.cn/ezgif-3cdad68e52289fca.gif)



除了 Flutter 控件，它在原生自动化上还可以实现：

- 处理权限弹窗（位置、相机等）
- 操作通知（打开通知栏、点击特定通知）
- 与 WebView 交互
- 控制设备设置：开关 WiFi、蜂窝数据、暗黑模式
- 模拟网络条件、后台/前台切换、App 生命周期等
- 浏览器相关操作（Web 支持）

![](https://img.cdn.guoshuyu.cn/image-20260530223027319.png)



![](https://img.cdn.guoshuyu.cn/image-20260530223123702.png)



**这对于在真实 Flutter E2E 测试是非常不错的补全，另外它对 Flutter 也很友好**，例如：

- 自定义 Finder 系统，语法很简单（如 $(#emailTextField).enterText('xxx')），比官方 tester.enterText(find.byKey(...)) 可读性高得多
- 支持 Hot Restart，写测试时迭代更快
- Patrol DevTools 扩展，可直接查看 Android/iOS 原生视图属性
- 全测试隔离 + 分片（Sharding），适合大规模 CI/CD 
- 多平台支持

相比起另外一个知名测试框架 Maestro ，Patrol 它更贴近 Flutter ，而且本身  LeanCode 也是专业的 Flutter 咨询公司，项目生态在很多真实产品上实践过，**最重要是开源和 Free**，配合 AI 可以对项目进行全流程脚本自动化测试，这就是为什么我觉得 Patrol 是目前最好的 Flutter 测试框架。

那来到源码里，目前 Patrol 项目是通过 Melos 管理的 monorepo，核心主要包括：

| 包                          | 作用                                            |
| --------------------------- | ----------------------------------------------- |
| `patrol`                    | Flutter 端核心库（Dart）                        |
| `patrol_cli`                | 命令行工具，负责构建、打包、编排测试运行        |
| `patrol_finders`            | 可单独使用的自定义查找器（finders）             |
| `patrol_gen`                | 代码生成器，从 `schema.dart` 生成跨平台协议代码 |
| `patrol_log`                | 结构化日志                                      |
| `adb`                       | ADB 封装（用于 Android 设备操作）               |
| `patrol_devtools_extension` | DevTools 扩展                                   |
| `patrol_mcp`                | MCP 服务支持                                    |

![](https://img.cdn.guoshuyu.cn/image-20260530215951127.png)

**这里面最重要的就是双向 gRPC 通信架构**，这是 Patrol 的核心，整个系统存在两个独立的 gRPC 服务，分别运行在不同端实现交互：

- PatrolAppService（Dart 侧作为 Server，原生侧作为 Client）
  - Dart/Flutter 测试进程作为服务端，暴露两个接口：列出所有测试、执行某个具体测试
  - 原生侧（Android JUnit Runner / iOS XCTest）作为客户端，主动向 Dart 侧请求要跑哪个测试

- MobileAutomator / AndroidAutomator / IosAutomator（原生侧作为 Server，Dart 侧作为 Client）
  - 原生侧启动一个 HTTP/gRPC 服务器，监听来自 Dart 测试代码的指令
  - Dart 测试代码在需要做系统级操作时，向本机的这个服务发 RPC 请求

整个简要流程如下所示：

![](https://img.cdn.guoshuyu.cn/ChatGPT%20Image%202026%E5%B9%B45%E6%9C%8830%E6%97%A5%2022_38_40.png)

![](https://img.cdn.guoshuyu.cn/image-20260530221949626.png)

而所有跨进程通信的数据结构和服务接口都定义在根目录的 `schema.dart` ，然后 `patrol_gen` 会解析这份 schema，分别生成代码：

- Dart 端：gRPC client stub、server stub、消息类
- Kotlin/Android 端：对应的 Kotlin 数据类和服务实现
- Swift/iOS 端：对应的 Swift 数据类和服务实现

![](https://img.cdn.guoshuyu.cn/image-20260530225144058.png)

接着就是  `PatrolBinding` ，作为整个框架运行时的核心，它主要起到了 gRPC 绑定的支持：

```dart
class PatrolBinding extends LiveTestWidgetsFlutterBinding {
  // 1. 启动时注册 setUp/tearDown 钩子，监听原生侧的测试执行请求
  // 2. 通过 patrolAppService.testExecutionRequested 挂起等待
  // 3. 测试完成后主动通知原生侧结果（pass/fail + details）
  // 4. 收集 FlutterError，序列化后传回原生，使 JUnit/XCTest 报告准确
  // 5. 注册 DevTools Service Extension 支持 UI 树检查
}
```

> 这里最重要的是，**测试并不是顺序全部跑，而是每个测试体都会先  `await patrolAppService.waitForExecutionRequest(testName)`  挂起，然后等到原生 Runner 通过 gRPC 发 `runDartTest` 指令时才真正执行**，也就是原生侧可以精确控制哪个测试在什么时机运行，并在 JUnit/XCTest 报告中单独呈现每个测试的结果。

然后就是去到原声侧，**Android 原生层主要有**：

- `Automator.kt`：封装了 UIAutomator2 API，实现所有系统级操作（点击通知、处理权限弹窗、切换 WiFi 等）

- `AutomatorServer.kt`：基于 Ktor 启动 HTTP 服务，将 gRPC 调用路由到 `Automator`

- `PatrolJUnitRunner.java`：

  - 先通过 `PatrolAppServiceClient` 调用 Dart 侧 `listDartTests()` 获取测试列表

  - 为每个测试动态注册一个 JUnit test case

  - 逐一调用 `runDartTest()` 触发 Dart 执行

  - 收集结果，输出标准 JUnit XML

> 也就是最终  Android CI 系统（Firebase Test Lab、BrowserStack、LambdaTest 等）可以直接识别每个测试用例的结果。

**而对于 iOS 原生层，则是使用 XCTest + XCUIApplication 框架**，原理类似，XCTest runner 和 Dart 进程之间通过 gRPC 完成握手和测试编排，对系统的操作（权限弹窗、通知、深色模式等）通过  `XCUIApplication` 和 `XCUIDevice` API 完成，基本都是官方原生支持的测试自动化接口。

**最后不得不提 patrol_cli**，它是整个运行机制的编排器，主要包括：

- 解析 `patrol.yaml` / `pubspec.yaml` 配置
- 使用 `test_bundler.dart` 将多个测试文件打包成单个入口（`_bundled_test.dart`），配合 Dart `group/test` 机制构建完整测试树
- 通过 ADB（Android）或 `xcodebuild` / `xcrun simctl`（iOS）安装、启动测试
- **支持 Hot Restart 开发模式**
- 聚合各设备的测试结果

![](https://img.cdn.guoshuyu.cn/image-20260530220408400.png)

也就是，原生 Runner 动态注册每个 Dart 测试为独立的 JUnit/XCTest 用例，而 CI 系统（Firebase Test Lab、Bitrise、BrowserStack 等）可以按单测试维度展示结果，这就结果表现上也可以有比较好的测试颗粒度，整个能力核心主要包括：

| 类型       | 能力                                                |
| ---------- | --------------------------------------------------- |
| Flutter UI | 点击、输入文本、滑动、等待 widget 出现、查找 widget |
| 系统权限   | 检测弹窗、授权（使用时/仅一次/拒绝）、精确/模糊位置 |
| 通知       | 打开通知栏、读取通知列表、点击通知                  |
| 网络       | WiFi 开关、蜂窝开关、飞行模式、蓝牙开关             |
| 设备状态   | 回到 Home、Recent Apps、音量键、深色模式            |
| 跨 App     | 打开指定 App（包名/Bundle ID）、跳转 URL            |
| 相机/相册  | 拍照、从相册选择单/多图                             |
| 位置       | 设置 Mock GPS 坐标                                  |
| 系统信息   | 获取 OS 版本、判断是否虚拟设备                      |

更具体的 Flutter  Method 有：

| Method                 | Purpose            | Example                                        |
| ---------------------- | ------------------ | ---------------------------------------------- |
| `$(pattern)`           | 查找并链接 widgets | `$(Scaffold).$(TextField).at(1)`               |
| `.tap()`               | 点击 widget        | `$(FloatingActionButton).tap()`                |
| `.enterText(text)`     | 在字段中输入文本   | `$(#emailField).enterText('user@example.com')` |
| `.scrollTo()`          | 滚动到  widget     | `$(#submitButton).scrollTo()`                  |
| `.waitUntilVisible()`  | 等待能见度         | `$(Dialog).waitUntilVisible()`                 |
| `.waitUntilExists()`   | 等待存在           | `$(LoadingSpinner).waitUntilExists()`          |
| `.containing(pattern)` | 按后代筛选         | `$(ListTile).containing($('Premium'))`         |
| `.which(condition)`    | 自定义筛选         | `$(TextField).which((w) => w.enabled)`         |
| `.visible`             | 检查可见性         | `if ($(Dialog).visible) { ... }`               |
| `.exists`              | 检查是否存在       | `if ($(#errorMessage).exists) { ... }`         |

![](https://img.cdn.guoshuyu.cn/image-20260530220029836.png)

另外对应的 Finder 的行为可以通过 `PatrolTesterConfig` 进行配置，你可以根据场景定制脚本的事件设定，比如超过多久没出现结果就是 UX 的 Bug：

| Property                      | Default     | Purpose                   |
| ----------------------------- | ----------- | ------------------------- |
| `existsTimeout`               | 10s         | `waitUntilExists()` 超时  |
| `visibleTimeout`              | 10s         | `waitUntilVisible()` 超时 |
| `settleTimeout`               | 10s         | `pumpAndSettle()` 超时    |
| `settlePolicy`                | `trySettle` | 行动在什么时候进行结算    |
| `dragDuration`                | 100ms       | 拖拽手势持续时间          |
| `settleBetweenScrollsTimeout` | 5s          | 滚动过程中设置超时时间    |

同样的，在原生层也可以直接通过 Dart 进行操作管理，整个实现都有相同的抽象适配：

![](https://img.cdn.guoshuyu.cn/image-20260530225214216.png)

![](https://img.cdn.guoshuyu.cn/image-20260530225240513.png)

基本上原生的大部分功能都支持，除了 iOS 的无障碍标签还不支持之外， 基本能力都已经对齐：

| Property                                                | Android | iOS  | Description                 |
| ------------------------------------------------------- | ------- | ---- | --------------------------- |
| `text` / `label`                                        | ✓       | ✓    | 可见文本内容                |
| `resourceId` / `identifier`                             | ✓       | ✓    | Unique element ID           |
| `className` / `elementType`                             | ✓       | ✓    | View/element type           |
| `contentDescription` 内容描述                           | ✓       | ✗    | 无障碍标签                  |
| `isClickable`, `isEnabled` `isClickable` ， `isEnabled` | ✓       | ✓    | 交互状态                    |
| `instance` 实例                                         | ✓       | ✓    | Index when multiple matches |

![](https://img.cdn.guoshuyu.cn/image-20260530225306670.png)

之后，**目前 Patrol 除了 Android 、iOS、Web 之外，也开始支持 macOS ，不过没支持 win 确实是一大遗憾**：

![](https://img.cdn.guoshuyu.cn/image-20260530220429922.png)

| Feature                | Android        | iOS                 | macOS               |
| ---------------------- | -------------- | ------------------- | ------------------- |
| **Test Runner**        | Gradle + JUnit | xcodebuild + XCTest | xcodebuild + XCTest |
| **UI Automation**      | UiAutomator 2  | XCTest              | XCTest              |
| **Min API/Version**    | API 21+        | iOS 13.0+           | macOS 12.0+         |
| **Back Button**        | ✓              | ✗                   | ✗                   |
| **Control Center**     | Quick Settings | ✓                   | ✓                   |
| **Permission Dialogs** | ✓              | ✓                   | ✓                   |
| **Notifications**      | ✓              | ✓                   | Limited             |
| **Camera/Gallery**     | ✓              | ✓                   | Partial             |
| **Build Flavors**      | ✓              | ✓ Schemes           | ✓ Schemes           |

> 这里 iOS 和 macOS 不支持  Back Button ，是因为 iOS 和 macOS 从设计上就没有全局 Back Button，XCTest 框架本身没有提供模拟"系统返回"的方法，在 patrol 测试中针对 iOS/macOS，需要**显式操作 UI 元素**来实现返回 ，也就是 Android 可以直接用 `await $.native.pressBack();` ，但是 iOS需要 `await $('Back').tap();` 或者  `await $.tap(find.byTooltip('Back'));` 。

当然，一些局限还是有的，比如：

- Web 支持仍不完整，部分原生能力在 Web 上不适用
- 真实 Android 设备上 Mock Location 不可用（仅模拟器）
- Bluetooth 开关在 Android 12 以下不可用
- iOS 控制中心操作在模拟器上不可用

不过这些局限都算不上什么大问题，所以，如果你在做 Flutter，尤其是需要测试复杂用户流程（权限、支付、推送、OAuth 等），个人强烈推荐直接用 Patrol，特别是通过 AI 完成自动化测试的验收上，真的比直接对接 Flutter MCP 效果更好。

因为 Patrol 同样支持 MCP 服， 可以让 AI 直接在 Flutter 项目中运行和管理 Patrol 测试，AI 能够直接**运行测试、看设备截图、读原生 UI 树、查看日志状态、重跑测试并修复测试，然后 Hot Restart 后直接执行**。

![](https://img.cdn.guoshuyu.cn/d46d41f8-8b26-4e6c-9905-588ebf55efb4.png)

所以，如果你没有试过，真的可以试试 Patrol，AI 时代，你值得拥有。









