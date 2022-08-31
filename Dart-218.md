# Dart 2.18 发布，Objective-C 和 Swift interop

> 原文链接： https://medium.com/dartlang/dart-2-18-f4b3101f146c

**Dart 2.18 版本开始提供与 Objective-C 和 Swift 交互的能力预览**，以及在这基础上构建的新 iOS / macOS 包支持。

**Dart 2.18 还包含对通用函数的类型推断改进、异步代码的性能改进、新的pub.dev 功能支持以及对工具和核心库的整理**。

最后，**还有最新的 *null safety*  迁移状态解析**，以及通往完全 *null safety*   的重要路线图更新。

![](http://img.cdn.guoshuyu.cn/20220831_# Dart/image1.png)



# Dart 支持与 Objective-C 和 Swift 交互的能力

在 2020 年的时候我们预览了用于调用原生 C API 的 Dart 外函数接口（FFI），并于 2021 年 3 月在 Dart 2.12 中发布了它。

自该版本发布以来，大量软件包利用此功能与现有的原生C API集成，例如： `file_picker`、`printing`、`win32`、`objectbox`、`realm`、`isar`、`tflite_flutter  `和 `dbus ` 等。

**Dart 团队希望支持所运行平台上所有主要语言的交互能力，而 Dart 2.18达到了实现这一目标的下一个里程碑**。

在 2.18， Dart 代码可以调用 Objective-C 和 Swift 代码，这通常用于调用 macOS 和 iOS 平台上的API，Dart在任何应用中都支持这种互操作机制，从CLI 应用到后端代码和 Flutter UI。

这种新机制其实是利用了 Objective-C 和 Swift 代码可以基于 API 绑定 C 代码公开，Dart API 包装了生成工具 `ffigen` ，可以从 API 标头创建这些绑定。



# 使用Objective-C的时区示例

macOS 有一个 API 可用于查询 `NSTimeZone` 上公开的时区信息，开发者可以查询该 API 以了解用户为其设备配置的时区和 UTC [时区偏移量](https://www.w3.org/International/core/2005/09/timezone.html#:~:text=What is a "zone offset,or "-" from UTC.)。

以下示例中 Objective-C 使用此时区 API 获取系统时区和GMT偏移量：

```objective-c
#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSTimeZone *timezone = [NSTimeZone systemTimeZone]; // Get current time zone.
        NSLog(@"Timezone name: %@", timezone.name);
        NSLog(@"Timezone offset GMT: %ld hours", timezone.secondsFromGMT/60/60);
    }
    return 0;
}
```

这里导入了 `Foundation.h`，其中包含 Apple Foundation 库的 API headers。

接下来，在 `main` 方法中，它从 `NSTimeZone` 类调用了 `systemTimeZone` 方法，此方法返回设备上选定时区的 `NSTimeZone` 实例。

最后，应用向控制台输出两行结果，其中包含时区名称和UTC偏移量（以小时为单位）。

如果运行此程序，它应该会返回类似于以下内容的东西，具体取决于开发者的位置：

```
Timezone name: Europe/Copenhagen
Timezone offset GMT: 2 hours
```



# 使用 Dart 的时区示例

让我们使用新的 Dart  与  Objective-C  一起重新实现上面的结果。

首先创建一个新的 Dart CLI ：

```
$ dart create timezones
```

然后编辑 `pubspec `文件以包含 `ffigen` 配置，配置指向头文件，并列出了哪些 Objective-C 接口应该生成包装器：

```yaml

ffigen:
  name: TimeZoneLibrary
  language: objc
  output: "foundation_bindings.dart"
  exclude-all-by-default: true
  objc-interfaces:
    include:
      - "NSTimeZone"
  headers:
    entry-points:
      - "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/System/Library/Frameworks/Foundation.framework/
         Headers/NSTimeZone.h"
```

这就为 `NSTimeZone.h` 中的 headers 选择 Objective-C 绑定，并仅包括`NSTimeZone `接口中的API，要生成 wrappers， 可以允行 `ffigen`：

```
$ dart run ffigen
```

该命令会创建一个新文件 `foundation_bindings.dart`，其中包含一堆生成的API绑定，使用该绑定文件，就可以编写 Dart `main` 方法，此方法镜像Objective-C 代码：

```dart
void main(List<String> args) async {
  const dylibPath =
      '/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation';
  final lib = TimeZoneLibrary(DynamicLibrary.open(dylibPath));

  final timeZone = NSTimeZone.getLocalTimeZone(lib);
  if (timeZone != null) {
    print('Timezone name: ${timeZone.name}');
    print('Offset from GMT: ${timeZone.secondsFromGMT / 60 / 60} hours');
  }
}
```

就这样，从 Dart 2.18 开始，这种新的支持在实验状态下可用，该能力增强了Dart 的交互支持，以直接调用 macOS 和 iOS API 支持。

并且这也反向补充了 Flutter 的插件，提供了允许开发者直接从 Dart 代码调用macOS 和 iOS API 的能力。

> 要了解有关这种互操作性的更多信息，请参阅 [Objective-C 和 Swift 交互指南](https://dart.dev/guides/libraries/objective-c-interop)。



# 特定于平台的http库

Dart 里包括一个通用的多平台`http`库，该库允许开着编写代码而无需考虑平台细节，但是有时候开发者可能希望编写特定于特定 native 平台的 网络 API的代码，例如：苹果的网络 库`NSURLSession `允许指定仅限 WiFi 或 VPN的网络。

为了支持这些用例，我们为 macOS 和 iOS 平台创建了一个新的网络包 `cupertino_http`，该能力建立在上一节中提到的 Objective-C 直接交互的基础上。

# Cupertino http library 示例

以下示例将 Flutter 的 http 客户端设置为在其他平台上使用 `cupertino_http`库，以及 `dart:io` 下的 http 库：

```dart

late Client client;
if (Platform.isIOS || Platform.isMacOS) {
  final config = URLSessionConfiguration.ephemeralSessionConfiguration()
    ..allowsCellularAccess = false
    ..allowsExpensiveNetworkAccess = false;
  client = CupertinoClient.fromSessionConfiguration(config);
} else {
  client = Client(); // Uses an HTTP client based on dart:io
}
```

初始配置后，应用会对特定客户端进行后续网络调用，例如 http `get()` 请求现在类似于以下内容：

```dart
final response = await get(
  Uri.https(
    'www.googleapis.com',
    '/books/v1/volumes',
    {'q': 'HTTP', 'maxResults': '40', 'printType': 'books'},
  ),
);
```

当开发者无法使用通用客户端接口时，就可以直接使用 `cupertino_http` 库调用苹果的网络API：

```dart
final session = URLSession.sessionWithConfiguration(
    URLSessionConfiguration.backgroundSession('com.example.bgdownload'),
    onFinishedDownloading: (s, t, fileUri) {
      actualContent = File.fromUri(fileUri).readAsStringSync();
    });

final task = session.downloadTaskWithRequest(
    URLRequest.fromUrl(Uri.https(...))
    ..resume();
```



# 多平台应用程序中特定于平台的网络

在设计该功能时，目标仍然是使应用尽支持更多的平台，为了实现这个目标，我们为基本的  http  操作保留了通用的多平台 `http` API 集，并允许为每个平台配置要使用的网络库。

[`package:http`](https://pub.dev/documentation/http/latest/http/Client-class.html) 将需要编写的特定于平台的代码量降至最低，此 API 可以按平台配置，但以独立于平台的方式使用。

Dart 2.18 提供了对两个对于 `package:http`  特定于平台的 http 库的实验性支持：

- `cupertino_http` 基于 `NSURLSession` 的 macOS/iOS 支持。
- `cronet_http `基于 [Cronet](https://developer.android.com/guide/topics/connectivity/cronet)，Android 上流行的网络库支持。

将一个通用客户端  API  与多个 HTTP 实现相结合，以获得特定于平台的行为，同时仍然从所有平台的一组共享源中维护应用。



# 改进的类型推断

Dart 使用了许多通用函数，例如 `fold`方法，它将元素集合减少为单个值，如计算整数列表的总和：

```dart
List<int> numbers = [1, 2, 3];
final sum = numbers.fold(0, (x, y) => x + y);
print(‘The sum of $numbers is $sum’);
```

对于 Dart 2.17 或更早版本，这个方法返回类型错误：

```
line 2 • The operator ‘+’ can’t be unconditionally invoked because the receiver can be ‘null’.
```

**Dart 2.18 改进了类型推断，前面的示例通过了静态分析，可以推断出 x 和 y 都是不可为空的整数**，此更改允许开发者编写更简洁的 Dart 代码，同时保留强推断类型的完整可靠性属性。



# 异步性能改进

此版本的 Dart 改进了 Dart VM 应用 `async` 方法和 `async*`/`sync* `生成器功能的方式。

这减少了代码大小，在两个大型内部 Google 应用程序中，我们看到 AOT 快照大小减少了约 10%，还可以看到微基准测试的性能有所提高。

>  这些变化包括额外的小行为变化；要了解更多信息，请参阅[更改日志](https://github.com/dart-lang/sdk/blob/master/CHANGELOG.md#dart-vm)。



# pub.dev 改进

结合 2.18 版本，我们对 `pub.dev`包 存储库进行了两项更改。

个人业余时间通过  `pub.dev` 维护和发布的可能会产生一些时间上的投入，为了促进赞助，我们现在在 中支持一个新 `funding` 标签，`pubspec`包发布者可以使用该标签列出指向一种或多种赞助包的方式的链接。然后这些链接显示`pub.dev`在侧边栏中：

![](http://img.cdn.guoshuyu.cn/20220831_# Dart/image2.png)

> 要了解更多信息，请参阅`pubspec`[文档](https://dart.dev/tools/pub/pubspec#funding)。

此外，我们希望鼓励丰富的开源软件包生态系统，为了突出这一点，自动包评分对使用 [OSI 批准的许可证](https://opensource.org/licenses)  的 `pub.dev`包额外奖励 10 分。



# 一些重大变化

Dart 非常注重简单和易学的能力，在添加新功能时，我们一直在努力保持谨慎的平衡。

保持简单的一种方法是删除历史功能和 API，Dart 2.18 清理了此类别中的项目，包括一些较小的重大更改：

- 我们早在 2020 年 10 月就添加了统一的 `dart` CLI 开发人员工具，在 2.18 中我们完成了过渡。此版本删除了最后两个已弃用的工具 `dart2js` (use `dart compile js`) 和 `dartanalyzer` (use `dart analyze`)。
- 随着语言版本控制的引入，`pub  `生成了一个新的解析文件：`.dart_tool/package_config.json` 。 之前的 `.packages` 文件使用了一种不能包含版本的格式，而现在我们停止使用 `.packages`文件，如果你有任何`.packages`文件，现在可以删除它们了。
- 不能使用未扩展的类的混合 `Object`（重大更改[#48167](https://github.com/dart-lang/sdk/issues/48167)）。
- `dart:io`  的 `RedirectException`的 `uri` 属性已更改为可为空（重大更改[#49045](https://github.com/dart-lang/sdk/issues/49045)）。
- `dart:io `遵循 SCREAMING_SNAKE 约定的网络 API 中的常量已被删除（重大更改# [34218](https://github.com/dart-lang/sdk/issues/34218)；以前已弃用），请改用相应的 lowerCamelCase 常量。
- Dart VM 在退出时不再恢复初始终端设置，更改 `Stdin` 设置 `lineMode` 的 `echoMode` 现在负责在程序退出时恢复设置（重大更改[#45630](https://github.com/dart-lang/sdk/issues/45630)）。



# 空安全更新

自 2020 年 11 月发布测试版和 2021 年 3 月发布 [Dart 2.12](https://medium.com/dartlang/announcing-dart-2-12-499a6e689c87) 以来，我们很高兴看到 null 安全性的广泛使用。

首先，大多数流行包的开发人员都在 `pub.dev` 迁移到了零安全性，分析表明，100% 的前 250 个和 98% 的前 1000 个最常用的包支持零安全。

其次，大多数应用开发人员在具有完全空安全迁移的代码库中工作，这是至关重要的条件，在迁移所有代码和所有依赖项（包括传递性）之前， Dart [健全的 null safety](https://dart.dev/null-safety/understanding-null-safety) 不会发挥作用。

下图显示了 `flutter run`  在引入零安全和没有引起之间的对比，随着应用开始迁移到零安全，开发人员进行了部分迁移，但仍存在部分内容未迁移到 null safety。

随着时间的推移可以看到， null safety  使用在健康地增长。到上月底，与不使用 null safety 相比， null safety  多出四倍，所以我们希望，在接下来的几个季度中，我们将看到 100% 的可靠零安全方法。

![](http://img.cdn.guoshuyu.cn/20220831_# Dart/image3.png)



# 重要的零安全路线图更新

同时支持空安全和非空安全会增加开销和复杂性。

首先，Dart 开发者需要学习和理解这两种模式，每当阅读一段 Dart 代码时，检查[语言版本](https://dart.dev/guides/language/evolution#language-versioning)以查看类型是否默认为非空（Dart 2.12 及更高版本）或默认可空（Dart 2.11 及更早版本）。

其次，在我们的编译器和运行时同时支持这两种模式会减慢 Dart SDK 的发展以支持新功能。

**基于非空安全的开销和上一节中提到的非常积极的采用数字，我们的目标是过渡到仅支持可靠的空值安全，并停止非空值安全和不健全的空值安全模式，我们暂时将其定于 2023 年年中发布**。

**这将意味着停止对 Dart 2.11 及更早版本的支持**，具有低于 2.12 的 SDK 约束的 Pubspec 文件将不再在 Dart 3 及更高版本中解析。

> 在包含语言标记的源代码中，如果设置为小于 2.12（例如`// @dart=2.9`）也会失败。

如果已迁移到可靠的 null 安全性，那么你的代码将在 Dart 3 中以完全的 null 安全性工作，如果还没有，请立即迁移！

> 要了解有关这些更改的更多信息，请参阅[此 GitHub 问题](https://github.com/dart-lang/sdk/issues/49530)。