---
title: "Flutter 3.47 首坑，analysis_options 问题连环回归"
---

# Flutter 3.47 首坑，analysis_options 问题连环回归

Flutter 3.47 刚发布出现 [#191056](https://github.com/flutter/flutter/issues/191056) 和 [#191131](https://github.com/flutter/flutter/issues/191131) 这两个卧龙凤雏的问题，刚好这个问题还和 Alex 在上海 Google 的 APAC Summit 聊到过，两个问题基本都来自同一个改动 ：Flutter 3.47 新加入的  `AnalysisOptionsMigration`。

这个改动原本只是想解决一个很小问题，最后变成两个设计漏洞：

- 判断配置时没有理解 `analysis_options.yaml`  的  `include:` 继承关系
- 决定要排除哪些目录时，又把 Flutter 的六个平台目录全部写死

> 前一个问题会反复改写 monorepo 里的配置文件，后一个甚至可能把真正的 Dart Web 代码直接静默踢出 Analyzer 的检查范围。

事情最早来自  [#187728](https://github.com/flutter/flutter/issues/187728) ，问题是 FlutterFire 配合 Swift Package Manager 等场景会在  `build/`  中留下 Dart 文件，Analysis Server 可能继续扫描这些生成内容，然后产生大量没有意义的分析错误。

这个问题本身确实需要解决，  `build/` 以及各个平台工程目录一般来说确实不属于用户需要分析的 Dart 代码，所以默认排除这些目录很合理，然后 [#187940](https://github.com/flutter/flutter/pull/187940) 这个 PR 做了两件事：

- 修改 `flutter create` 的模板，让新项目的 `analysis_options.yaml` 默认出现：

```yaml
analyzer:
  exclude:
    - build/**
    - android/**
    - ios/**
    - web/**
    - windows/**
    - macos/**
    - linux/**
```

- 为了照顾已经存在的 Flutter 项目，又增加了  `AnalysisOptionsMigration`，自动把这些配置补进去。

**问题就在于，这个 migration 被直接接到  `FlutterProject.ensureReadyForPlatformSpecificTooling()`  里面**，导致它不会只在某个专门的 “升级项目”命令里运行，`flutter pub get`、`flutter analyze`、`flutter run`、`flutter build`  这些日常命令都会触发。

结果问题就来了，本来一个会自动修改用户仓库文件的 migration，理论上判断应该必须足够保守，但第一版实现又很粗糙：

- 读取当前项目根目录的 `analysis_options.yaml`
- 解析 YAML
- 直接检查当前文件里的 `root['analyzer']['exclude']`
- **如果没有 `analyzer`、没有 `exclude`，或者七个规定目录少了任何一个，就认为项目需要迁移，并把缺失项写回当前文件**

这就导致了  #191056 的问题，Dart 的  `analysis_options.yaml`  很常见的一种写法是把配置集中维护起来，例如：

```yaml
# analysis_options.yaml
include: package:company_lints/flutter.yaml
```

真正的配置可能在  `company_lints`  里面：

```yaml
analyzer:
  exclude:
    - build/**
    - android/**
    - ios/**
    - web/**
    - windows/**
    - macos/**
    - linux/**
```

而对 Dart Analyzer 来说，这些 exclusion 已经生效，比如：

- 把一个明显的类型错误放进  `android/probe.dart`，`dart analyze` 不会报告它
- 同样的错误放进  `lib/probe.dart`，Analyzer 会正常报错

但问题就在于， Flutter 3.47 的 migration 根本没有解析  `include: `，它只看到当前文件里没有字面意义上的：

```yaml
analyzer:
  exclude:
```

然后就进入“还没有迁移”的 case ，然后又往当前文件补上一份完全相同的 exclusion，Flutter  又又又跑一次命令后，然后变成：

```yaml
include: package:company_lints/flutter.yaml

analyzer:
  exclude:
    - build/**
    - android/**
    - ios/**
    - web/**
    - windows/**
    - macos/**
    - linux/**
```

然后就算你手动删除了，只要再运行一次 `flutter pub get` 或  `flutter analyze`，migration 又会重新加回来，所以被大量反馈后，官方紧急在  [#191082](https://github.com/flutter/flutter/pull/191082) 这个 PR 进行了修复：

> *新的 `_collectExcludes()` 会读取当前文件自己的 `analyzer.exclude`，然后递归解析 `include:`， 同时相对路径可以继续从当前文件目录寻找，`package:` URI 会通过  `PackageConfig` resolve 到真实文件，而且递归过程中还会记录 canonical path，避免两个配置文件互相 include 后无限递归，最后格式错误、无法读取的文件、异常的 exclude 类型也增加了保护*。

但是问题又来了， #191082 刚解决完 “已有配置怎么看” 的问题，#191131 马上暴露出另一半：**Flutter 到底凭什么认为所有项目都应该排除这七个目录？**

第一版 `AnalysisOptionsMigration` 的 exclusion 是一个固定列表：

```dart
const excludesToExclude = <String>[
  'build/**',
  'android/**',
  'ios/**',
  'web/**',
  'windows/**',
  'macos/**',
  'linux/**',
];
```

它跟项目实际启用了哪些平台没有关系，一个只创建 Android 和 iOS 的 Flutter 项目，照样会出现 `web/**`、`windows/**`、`macos/**` 和 `linux/**`，你就算手工删除这些配置，下一次 Flutter 命令还会再加回来，也就是问题还是存在污染。

特别如果是 Dart 官方自己的 `dart create -t web webrepro` 创建出来的项目，本来就会把真正的 Dart Web 代码放在：

```text
web/
└── main.dart
```

这里的 `web/` 不是 Flutter Web 的平台壳，也不是需要忽略的生成目录，它就是源码目录，然后按照现在的情况，默认每次都会全量覆盖和添加所有平台，这就导致 Analyzer 会不再扫描 `web/`。

所这个问题解决的方式也很简单，对应修复 PR [#191151](https://github.com/flutter/flutter/pull/191151) 的处理方案是，在 migration 开头判断当前 package 是否真的依赖 Flutter：

```dart
if (!_project.manifest.dependencies.contains('flutter')) {
  return;
}
```

纯 Dart package 直接退出，Flutter Tool 不再修改  `analysis_options.yaml`，然后第二层会取消固定的七项列表，项目自己会根据 FlutterProject 实际存在的平台 scaffold 动态生成：

```dart
final excludesToExclude = <String>[
  'build/**',
  if (_project.android.existsSync()) 'android/**',
  if (_project.ios.existsSync()) 'ios/**',
  if (_project.web.existsSync()) 'web/**',
  if (_project.windows.existsSync()) 'windows/**',
  if (_project.macos.existsSync()) 'macos/**',
  if (_project.linux.existsSync()) 'linux/**',
];
```

最后还同步修 `flutter create` 模板，否则 migration 虽然正确了，新项目生成时还会有问题。

**所以，实际上这两个 issue 都来自同一个问题，虽然不是什么大事，但是纯纯的恶心人**，随意执行下 flutter 命令，就莫名其妙修改了你的 analysis_options ，而且只要是和固定模板不一样就无脑覆盖，纯纯让人不爽。

实际上这个问题从一开始就很简单，只是修的人修的随意，合并的人也合的随意，然后最后就成了这么一坨。

