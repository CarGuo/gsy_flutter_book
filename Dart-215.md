
> 原文链接 https://medium.com/dartlang/dart-2-15-7e7a598e508a

Dart SDK 的 2.15 版本新增了**具备有更快并发能力的 isolates 、支持 tear-off 的构造函数 、关于 dart:core 库枚举支持的改进、包发布者相关的新功能**等等。




## isolates 的并发

如今的物理设备几乎都有多核的 CPU ，能够并行地执行多个任务，而对于大多数 Dart 程序而言，这些内核的使用过程对开发人员来说是透明的：

> 默认情况下 Dart 运行时所有 Dart 代码只会在单个内核上运行，但会使用其他内核来执行系统级任务，例如：异步的输入/输出、读写文件或者网络调用等。

但有时候 Dart 代码本身可能需要用到并发执行的场景，例如可能同时有“连续的动画和一个需要长时间运行的任务”，或者解析一个大型 JSON 文件等等场景。

如果附加需要执行的任务花费时间太长，可能就会导致 UI 卡顿或运行滞后，所以通过将这些额外的任务移动到另外一个单独的核心运行，保证动画可以继续在主执行线程上运行而不受干扰是必要的支持。

**Dart 的并发模型是基于[isolates](https://dart.dev/guides/language/concurrency)设计的——一种相互隔离的独立执行单元。这是为了防止在共享内存时，出现相关的并发编程错误问题**，例如[data races.](https://en.wikipedia.org/wiki/Race_condition#In_software)等。

Dart 通过不允许在 isolates 之间共享任何可变对象来防止这些错误，而是使用 [*消息传递*](https://dart.dev/guides/language/concurrency#sending-multiple-messages-between-isolates) 在 isolates 之间交换状态，**而如今在 Dart 2.15 中对 isolates 进行了许多实质性的改进。**

**Dart 2.15 重新设计和实现了 isolates 的工作方式，引入了一个新概念：*isolate groups*， isolate groups 中的 isolate 共享正在运行的程序中的各种内部数据结构，这使得 groups 中的个体 isolates 变得更加轻便。**

> 如今在 isolate groups  中启动额外的 isolate 可以快近 100 倍，因为现在不需要初始化程序结构，并且产生新的 isolate 所需要的内存减少了 10-100 倍。

**虽然 isolate groups  还是不允许 isolate 之间共享可变对象，但该 group 可以通过共享堆来实现的，所以能够解锁更多功能**，比如可以将对象从一个 isolate 传递到另一 isolate，这样就可以用于执行需要返回大量内存数据的任务。

> 例如通过网络调用获取数据，将该数据解析为一个大型 JSON 对象，然后将该 JSON 对象返回到主isolates。 在 Dart 2.15 之前执行该操作需要“深度复制”，如果复制花费的时间超过帧预算时间，就可能会导致 UI 卡顿。

**在 2.15 中工作的 isolates 可以调用 `Isolate.exit()` 将其结果作为参数传递**。将运行的 isolates 结果的内存传递给主 isolates ，而不是进行复制，主 isolates 可以在指定时间内接收结果。

这个行为在更新的[Flutter 2.8 中](https://medium.com/flutter/whats-new-in-flutter-2-8-d085b763d181) 的 [`compute()`](https://api.flutter.dev/flutter/foundation/compute-constant.html) 函数里，同样已经改变成这种实现， 如果你已经在使用 `Isolate.exit()` 和 `compute()` 函数，那么在升级到 Flutter 2.8 后将自动获得这些性能提升。

**最后 Dart 2.15 还重新设计了 isolates 消息传递机制的实现方式，使得中小型的消息传递速度提高了大约 8 倍**。另外扩展了 isolates 可以相互发送的对象种类，增加了对函数类型、闭包和堆栈跟踪对象的支持，有关详细信息，请参阅 API 文档 `SendPort.send()`：

> 要了解有关如何使用隔离的更多信息，请参阅 2.15 添加的 [*Dart*](https://dart.dev/guides/language/concurrency) 文档中的[*并发介绍*](https://dart.dev/guides/language/concurrency)， 另外还有许多[代码示例](https://github.com/dart-lang/samples/tree/master/isolates)可以查看。

## 新的语言特性：构造函数 tear-offs

在 Dart 中可以通过使用函数的名称创建一个函数对象，该对象指向另一个对象上的函数，如下代码所示，`main()` 方法的第二行声明了“将 `g`  设置为 `m.greet` ”的语法：



```dart
class Greeter {
  final String name;
  Greeter(this.name);
  
  void greet(String who) {
    print('$name says: Hello $who!');
  }
}void main() {
  final m = Greeter('Michael');
  final g = m.greet; // g holds a function pointer to m.greet.
  g('Leaf'); // Invokes and prints "Michael says: Hello Leaf!"
}
```


在使用 Dart core libraries 时，这种类函数指针（也称为函数 tear-offs）经常出现，如下是`foreach()` 通过传递函数指针来调用可迭代对象的示例：

```dart
final m = Greeter('Michael');['Lasse', 'Bob', 'Erik'].forEach(m.greet);// Prints "Michael says: Hello Lasse!", "Michael says: Hello Bob!",
// "Michael says: Hello Erik!"
```

在之前的版本中 Dart SDK 不支持从构造函数创建 tear-offs（语言问题[#216](https://github.com/dart-lang/language/issues/216)），这就显得很烦人，因为在许多情况下，构建 Flutter UI 时构造函数 tear-offs 会是开发所需要的，所以从 Dart 2.15 开始支持这种语法。

如下是构建 `Column` 包含三个 `Text`  Widget 的示例，通过调用 `.map()` 它并将其传递给`Text` ：

```dart
class FruitWidget extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Column(
        children: ['Apple', 'Orange'].map(Text.new).toList());
    }
}
```

**`Text.new` 指 `Text` 类的默认构造函数，还可以引用命名构造函数，例如： `.map(Text.rich)`**。

## Related language changes

当实现构造函数的 tear-offs 时，Dart 2.15 借此机会修复了现有的函数指针支持中的一些不一致问题，现在可以专门化一个泛型方法来创建一个非泛型方法：

```dart
T id<T>(T value) => value;\
var intId = id<int>; // New in 2.15.\
int Function(int) intId = id; // Pre-2.15 workaround.
```

你甚至可以特化一个泛型函数对象来创建一个非泛型函数对象：


```dart
const fo = id; // Tear off `id`, creating a function object.\
const c1 = fo<int>; // New in 2.15; error before.
```

最后还清理了涉及泛型的类型文字：

```dart
var y = List; // Already supported.\
var z = List<int>; // New in 2.15.\
var z = typeOf<List<int>>(); // Pre-2.15 workaround.
```

## Improved enums in the dart:core library

Dart 2.15 为 `dart:core` 库（[#1511](https://github.com/dart-lang/language/issues/1511)）中的枚举 API 添加了更多的优化，现在开发者可以通过 `.name` 来获取每个枚举值的 `String` 值：

```dart
enum MyEnum {
  one, two, three
}
void main() {
  print(MyEnum.one.name);  // Prints "one".
}
```

还可以按名称查找枚举值：

```dart
print(MyEnum.values.byName('two') == MyEnum.two); // Prints "true".
```

最后还可以获得所有名称-值对的映射：

```dart
final map = MyEnum.values.asNameMap();\
print(map['three'] == MyEnum.three); // Prints "true".
```

有关使用这些新 API 的示例可以参阅 [Flutter PR #94496](https://github.com/flutter/flutter/pull/94496/files)。

## Compressed pointers

Dart 2.15 添加了对 Compressed pointers 的支持，**如果只需要支持 32 位的地址空间（最多 4 GB 内存），则 64 位 SDK 可以使用更节省空间的指针表示形式**。

> 压缩指针导致显着的内存减少，在对 GPay 应用程序的内部测试中，我们看到 Dart 堆大小减少了大约 10%。

由于压缩指针意味着无法寻址 4 GB 以上的 RAM，因此该功能位于 Dart SDK 中的配置选项之后，只能在构建 SDK 时由 Dart SDK 的嵌入器切换。

Flutter SDK 2.8 版已为 Android 构建中启用此配置，Flutter 团队正在考虑在未来版本中[为 iOS](https://github.com/flutter/flutter/issues/94753) 构建启用此配置。


## Dart SDK 中包含 Dart DevTools

以前的 [DevTools](https://dart.dev/tools/dart-devtools#) 调试和性能工具[套件](https://dart.dev/tools/dart-devtools#) 不在 Dart SDK 中，所以开发者需要单独下载。

从 Dart 2.15 开始，现在可以在下载的 Dart SDK 里直接获取 DevTools，而无需进一步的安装步骤。

有关将 DevTools 与 Dart 命令行应用结合使用的更多信息，请参阅 [DevTools 文档](https://dart.dev/tools/dart-devtools#using-devtools-with-a-command-line-app)。

## 包发布者的新 pub 功能

Dart 2.15 SDK 在 `dart pub` 开发者命令和[pub.dev](https://pub.dev/)包存储库中还有两个新的功能。

首先包发布者有了一个新的安全功能，目的是用于检测发布者在发布包中意外发布的机密（例如 Cloud 或 CI 凭据）。

在了解到 GitHub 存储库中[每天有数以千计的秘密被泄露](https://www.ndss-symposium.org/wp-content/uploads/2019/02/ndss2019_04B-3_Meli_paper.pdf)后，Dart SDK 受到启发添加了此泄漏检测。

泄漏检测作为 `dart pub publish` 命令中预发布验证运行的一部分运行，如果它在即将发布的文件中检测到潜在的秘密，该 `publish` 命令将退出而不发布，并打印如下输出：


```
Publishing my_package 1.0.0 to [https://pub.dartlang.org](https://pub.dartlang.org/):\
Package validation found the following errors:\
* line 1, column 1 of lib/key.pem: Potential leak of Private Key detected.\
╷\
1 │ ┌ - - -BEGIN PRIVATE KEY - - -\
2 │ │ H0M6xpM2q+53wmsN/eYLdgtjgBd3DBmHtPilCkiFICXyaA8z9LkJ\
3 │ └ - - -END PRIVATE KEY - - -\
╵\
* line 2, column 23 of lib/my_package.dart: Potential leak of Google OAuth Refresh Token detected.\
╷\
2 │ final refreshToken = "1//042ys8uoFwZrkCgYIARAAGAQSNwF-L9IrXmFYE-sfKefSpoCnyqEcsHX97Y90KY-p8TPYPPnY2IPgRXdy0QeVw7URuF5u9oUeIF0";
```

在极少数情况下此检测可能会出现误报，在这些情况下可以将文件添加到许可白名单。

> 白名单： https://dart.dev/go/false-secrets

其次还为发布者添加了另一个功能：**支持收回已发布的软件包版本。**

当发布了有问题的包版本时，通常建议是发布一个小增量的新版本，以修复意外问题。

在极少数情况下，例如当开发者还没有这样的修复能力时，或者是不小心发布了一个新的主要版本，就可以使用新的包收回功能作为最后的手段，此功能在 pub.dev 上的管理 UI 中可用：


![](http://img.cdn.guoshuyu.cn/20211223_Dart-215/image1)

当一个包版本被收回时，pub 客户端不再为 `pub get` 或者 `pub upgrade` 解析那个版本，如果开发者使用了成功撤回的版本（因此在他们的`pubspec.lock`文件中），他们将在下次运行时看到警告`pub`：


```
$ dart pub get\
Resolving dependencies…\
mypkg 0.0.181-buggy (retracted, 0.0.182-fixed available)\
Got dependencies!
```

## Security analysis for detecting bidirectional Unicode characters (CVE-2021–22567)

最近发现了一个涉及双向 Unicode 字符的通用编程语言漏洞 ( [CVE-2021–42574](https://nvd.nist.gov/vuln/detail/CVE-2021-42574) )，此漏洞影响大多数支持 Unicode 的现代编程语言，下面的 Dart 源代码演示了这个问题：

```dart
main() {
  final accessLevel = 'user';  
  if (accessLevel == 'user‮ .⁦// Check if admin⁩ ⁦') {
    print('You are a regular user.');
  } else {
    print('You are an admin.');
  }
}
```

你可能会认为该程序打印出 *`You are a regular user.`* ，但实际上它可能会打印 *`You are an admin`。* ！

通过使用包含双向 Unicode 字符的字符串，就可以利用此漏洞，例如上述都在一行中的这些字符，将文本的方向从左到右更改为从右到左和回退。

对于双向字符，文本在屏幕上的呈现与实际文本内容截然不同，开发者可以在[GitHub code gist](https://gist.github.com/mit-mit/7dda00ca6278ce7d2555f78d59d9e67b?h=1) 中看到这样的示例。

针对此漏洞的缓解措施包括使用检测双向 Unicode 字符的工具（编辑器、代码审查工具等）以便开发人员了解它们，并在知情的情况下接受它们的使用，上面链接的 GitHub gist 文件查看器是显示这些字符的工具的一个示例。

Dart 2.15 引入了进一步的缓解措施（Dart 安全[公告 CVE-2021–22567](https://github.com/dart-lang/sdk/security/advisories/GHSA-8pcp-6qc9-rqmv)）：Dart 分析器现在扫描双向 Unicode 字符，并标记它们的任何使用：

```
$ dart analyze
Analyzing cvetest...                   2.6sinfo • bin/cvetest.dart:4:27 • The Unicode code point 'U+202E'
       changes the appearance of text from how it's interpreted
       by the compiler. Try removing the code point or using the 
       Unicode escape sequence '\u202E'. •
       text_direction_code_point_in_literal
```

我们建议用 Unicode 转义序列替换这些字符，让它们在任何文本编辑器或查看器中可见，或者如果开发者觉得确实合法使用了这些字符，则可以通过在使用前的行中添加覆盖来禁用警告：

```
// 忽略：text_direction_code_point_in_literal
```


## Pub.dev credentials vulnerability when using third-party pub servers (CVE-2021–22568)


Dart 2.15 还发布了第二个与 pub.dev 相关的 Dart 安全[公告 CVE-2021–22568](https://github.com/dart-lang/sdk/security/advisories/GHSA-r32f-vhjp-qhj7)。

> 此公告面向可能涉及已将包发布到第三方发布包服务器（例如私人或公司内部包服务器）的包发布者，仅发布到公共 pub.dev 存储库（标准配置）的开发人员不受此漏洞的影响。

如果开发者已发布到第三方存储库，则该漏洞是在该第三方存储库中提供用于身份验证的 OAuth2 临时（一小时）访问令牌，可能会被滥用来针对公共 pub.dev 存储库进行身份验证。

因此恶意的第三方 pub 服务器可能会使用访问令牌在 pub.dev 上冒充开发者并在那里发布包。

如果开发者已将软件包发布到不受信任的第三方软件包存储库，请考虑对 pub.dev 公共软件包存储库中的所有帐户活动进行审核，[推荐可以使用 pub.dev 的活动日志](https://pub.dev/my-activity-log)。