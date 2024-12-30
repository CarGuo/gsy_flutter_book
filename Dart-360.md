# Dart 3.6 发布,workspace 和 Digit separators 

# workspace

之前我们就聊过 [Flutter 正在切换成 Monorepo 和支持 workspaces](https://juejin.cn/post/7433673239426007078) ，Dart 3.6 开始，Pub 现在正式支持 monorepo 或 workspace 中 package 之间的共享解析。

pub workspaces 功能可确保 monorepo 中的 package 共享一组一致的依赖项，这样在分组包之间出现依赖关系冲突时可以更轻松解决它们。

>  monorepo（mono repository） ，它是一种项目代码的管理方式，就是将多个项目存储在一个 repo 中，在 monorepo 里多个项目的所有代码都存储在单个仓库里，这个集中式存储库包含 repo 中的所有组件、库和内部依赖项等。

另外，Flutter analyzer 可以在单个 analysis 上下文中处理 pub 工作区中的所有 package，而不是之前为每个 package 使用单独的 context 的行为。

对于大型仓库，特别由于 monorepo 结构化的原因，Analyzer 在工作的时候最终会为每个包及其所有依赖项加载了多个重复的 analysis contexts，从而导致 monorepo 里每个包 analysis 时在内存中生成了多个副本，最终出现内存占用过大问题，而 workspace 这可以显著减少 Dart 语言服务器消耗的内存量，从而提高 IDE 性能。

要定义 pub 工作区，需要在根 `pubspec.yaml` 文件中添加 workspace 字段，并列出相关的 package：

```yaml
name: _
publish_to: none
environment:
  sdk: ^3.6.0
workspace:
  - packages/helper
  - packages/client_package
  - packages/server_package
```

然后运行 `pub get` 在仓库中的任意位置完成映射和剩余文件管理，要使用 pub 工作区，所有工作区包（但不是依赖项）必须具有 `^3.6.0` 或更高版本的 SDK 版本约束:

```yaml
environment:
  sdk: ^3.6.0
resolution: workspace
```

> 如果任何工作区包相互依赖，则无论源如何，它们都将自动解析为工作区中的包。

另外，还可以通过在工作区 `pubspec.yaml` 文件旁边放置一个 `pubspec_overrides.yaml` 文件来做依赖项覆盖。

> 更多可见：https://juejin.cn/post/7433673239426007078 / https://dart.dev/tools/pub/workspaces

# Pub  下载计数

现在 pub.dev 上有更精确指标的要求： downloads，下载计数将替换单个软件包页面上之前的 “popularity score”，除了新指标外，用户还会在每个页面上找到一个迷你图，显示一段时间内的每周下载量：

![](http://img.cdn.guoshuyu.cn/20241212_Dart360/image1.png)

# Digit separators

Dart 3.6 现在允许使用下划线 （_） 作为数字分隔符，这有助于使长数字字面量更具可读性，例如多个连续的下划线表示更高级别的分组：

```
1__000_000__000_000__000_000
0x4000_0000_0000_0000
0.000_000_000_01
0x00_14_22_01_23_45
```

PS ，类似的功能在  Dart 3.7 也会有，（_） 在  Dart 3.7 的局部变量和参数是非绑定的，因此可以在同一个范围中声明它们任意多次，而不会发生冲突：

![](http://img.cdn.guoshuyu.cn/20241212_Dart360/image2.png)





> 参考链接：https://medium.com/dartlang/announcing-dart-3-6-778dd7a80983