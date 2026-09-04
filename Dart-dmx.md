# 社区版 Dart macros？一个可以解决 JSON 序列化的Fluter “宏编程”第三方包

有点意思，社区最近发布了一个叫 dmx 的第三方包，主要是做 Dart 源码内联的 Code Generator，而且和 Freezed / json_serializable / build_runner 走的不同路线，简单来说就是：**保存 Dart 文件时直接生成代码，同时把生成结果写回当前 `.dart` 文件的 class 里面。**

![](https://img.cdn.guoshuyu.cn/image-20260817152900363.png)

它定位自己叫做 “Dart macros”，**但这里的 macro 不是 Dart 编译器提供的语言级 Macro**，项目提供的 `@dmx('model')` 本质也只是一个普通 annotation，主要靠的还是外部的 dmx generator。

比如比如平时 Flutter 写 mode 大概类似：

```dart
class User {
  const User({
    required this.id,
    required this.name,
    this.email,
  });


  final String id;
  final String name;
  final String? email;
}
```

而常见的 Freezed 做法是定义注解，然后 `dart run build_runner build` ：

```dart
@freezed
class User with _$User {
  ...
}
```

然后 dmx 的想法就简单粗暴很多，比如下面的注解，你只需要 Ctrl+S，然后它自己就直接生成或者修改  `user.dart`：

```dart
import 'package:dmx/dmx.dart';


@dmx('model')
class User {
  const User({
    required this.id,
    required this.name,
    this.email,
  });


  final String id;
  final String name;
  final String? email;
}
```

**最有意思的是什么？生成的代码就在你的 class 里面**，没有比如 `part 'user.g.dart';` 之类的东西，也不用每次 `build_runner watch`，直接就是 “Generated on save ” ：

![](https://img.cdn.guoshuyu.cn/image-20260817153402449.png)

所以它最有意思的就是「内联 Codegen」，dmx 做的事情大概类似：

![](https://img.cdn.guoshuyu.cn/image-20260817153754353.png)

**所以 dmx 主生成器是 Rust 写的**，VS Code 插件里面直接带着对应平台的 `dmx` binary，你安装插件之后，打开 Dart workspace，它自动启动 watcher，watcher 看到 `profile.dart changed` 就只重新处理对应文件。

然后 dmx 内部会用 tree-sitter 解析 Dart ，它没有拿 regex 搜类似 `class xxx {` ，dmx  用的是 `tree-sitter-dart`，构造一个 lossless Concrete Syntax Tree，也就是可以知道：

> class body 在哪，是什么 field，是什么 annotation，已经 `//#region` 到底属于哪个 class。

而且 dmx 的 spec 专门要求 comment token 和 class-body span 必须可靠。

然后 Rust 会把 Dart class 转成生成器能理解的数据，比如：

```
class User {
  final String id;
  final String? email;
}
```

dmx 会解析成类似：

```
className = User


fields:
  id:
    type = String
    nullable = false


  email:
    type = String?
    nullable = true
```

随后 Rust 会进一步算好：

```
decodeExpr
encodeExpr
equalsExpr
hashExpr
copyParam
copyArg
```

然后复杂的 Dart 类型判断放 Rust 里完成，Mustache template 只负责“长什么样”，所以模板可能只是：

```
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    (other is {{className}}
{{#fields}}
      && {{equalsExpr}}
{{/fields}}
    );
```

而 `equalsExpr` 是通过 Rust 算好的，然后用 Mustache 生成 Dart 。

目前 dmx 自带 11 个 generator：

> `model`、`union`、`enum`、`diff`、`lerp`、`validate`、`table`、`route`、`cli`、`fake`、`restClient`。

例如:

- `@dmx('model')  `就走 model template
- `@dmx('table')` 可以生成 SQL schema、binding、row conversion
- `@dmx('restClient')`  可以生成 REST client implementation

**所以它的目标是做一个通用 Dart codegen framework**。**

**而且你自己也可以写「Macro」，这也是最有意思的地方**，比如你可以自己写：

```dart
final class AuditMacro extends DmxMacro {


  @override
  String get name => 'audit';


  @override
  DmxOutput expand(DmxInvocation invocation) {
    final name = invocation.declaration.name;


    return DmxFragment(
      "String get auditLabel => '$name';",
    );
  }
}
```

然后在项目里写：

```dart
@dmx('audit')
class Order {
  final int id;
}
```

保存以后就可以得到：

```dart
@dmx('audit')
class Order {
  final int id;


  //#region


  String get auditLabel => 'Order';


  //#endregion
}
```

所以这里所谓「Dart Custom Macro」其实就是用**用 Dart 编写的外部 source generator plugin**。

而这样的话，其实就能干很多很邪门的东西了，比如 SQLite，Macro 可以直接读 `SQLite database schema`，然后我们：

```
@dmx('sqliteSchema')
class ProductRow {}
```

这样就可以根据真实数据库里的：

```
products
 ├ id INTEGER
 ├ name TEXT
 └ price REAL
```

直接生成：

```dart
class ProductRow {
  final int id;
  final String name;
  final double price;


  ...
}
```

或者读取项目里的 `openapi.json`，然后分析一些列参数：

```
paths
schemas
$ref
nullable
array
response
```

然后直接生成：

- API Client
- Model
- JSON codec

甚至可以处理 OpenAPI 里没名字的结构。同时给它取 Dart class name，也就是这时候 dmx 已经有点接近：

```
source_gen
+
build_runner
+
模板引擎
+
IDE watcher
+
source rewriter
```

整体来看，我感觉这个比 Flutter 搞 runner 舒服好多，角度也很不错，最近社区的想法确实比官方有意思多了，不过问题来了，现在貌似大家都不打开 IDE 了，貌似对 JSON 这种输出场景的需求也不多了，感觉这个项目还是来的有点晚了。

不过就算不开 VSCode 实际项目也可以用， dmx 本身有独立 CLI ，比如 ：

```shell
dmx build [PATHS...] [--insert-regions] [--check]
dmx watch [PATHS...]
```

所以 AI 场景也能用，不过是不是需要就看你个人的想法了。



# 链接 

https://github.com/Nimblesite/dmx