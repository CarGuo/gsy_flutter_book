# Dart 3.7 发布，快来看看有什么更新吧

在聊 Dart  3.7 发布的之前，就不得不提[ Dart 宏功能推进暂停](https://juejin.cn/post/7464998185485877311) ，在春节期间，Dart 团队决定，**由于宏的性能具体目标还太遥远，团队决定把当前的实现回归到编辑（例如静态分析和代码完成）和增量编译（热重载的第一步）上**。

关于数据支持，**具体在于重新投资Dart 中的数据实现**，因为这也是Dart & Flutter issue 里[请求最多的问题](https://link.juejin.cn/?target=https%3A%2F%2Fgithub.com%2Fdart-lang%2Flanguage%2Fissues%2F314)，事实上一开始 Dart 对宏支持的主要动机，也是为了提供更好的数据序列化和反序列化，但是目前看来，通过更多定制语言功能来实现这一点更加实际。

另外，Dart 团队目前已经在研究[改进 build_runner 性能](https://github.com/dart-lang/build/issues/3800)和推出  [augmentations language feature](https://github.com/dart-lang/language/blob/main/working/augmentation-libraries/feature-specification.md) （可能以略有不同的形式）支持，最终目的是找到更直接和方便的方法，来支持建模数据以及处理[序列化和反序列化](https://github.com/dart-lang/language/issues/4232)适配。

# 通配符变量语言功能

回到 Dart 3.7 的功能，在聊 Dart 3.6  **Digit separators** 支持的时候我们提到过，Dart 3.6 允许使用下划线 （_） 作为数字分隔符，这有助于使长数字的字面量更具可读性，例如多个连续的下划线表示更高级别的分组：

```markdown
1__000_000__000_000__000_000
0x4000_0000_0000_0000
0.000_000_000_01
0x00_14_22_01_23_45
```

而  (_) 在 Dart 3.7 的局部变量和参数会变成非绑定的状态，因此可以在同一个范围中声明它们任意多次，而不会发生冲突：

![](http://img.cdn.guoshuyu.cn/20250212_D370/image1.png)

在 Dart 中，如果回调的主体实际上不需要使用参数，一般大家都会使用 `_` 作为回调参数的名称，但是如果回调有多个不需要使用的参数，过去可能会命名为 `_`、`__`、`___` 等，否则名称会发生冲突。

而在 Dart 3.7 中， `_` 的参数和局部变量实际上不会再创建变量，因此不存在名称冲突的可能性，当然，下面这种写法也就不生效了：

```dart
var [1, 2, 3].map((_) {
  return _.toString();
  //     ^ Error! Reference to unknown variable.
});
```

> 类似的在 patterns 也是同样的道理：`var [_, _, third, _, _] = [1, 2, 3, 4, 5];`

# Dart 格式化中的新样式

Dart 3.7 包含了重新编写的 Dart 格式化（`dart format`），并采用了[新的格式样式](https://github.com/dart-lang/dart_style/issues/1253)。

新样式看起来类似于向参数列表添加尾随逗号时获得的样式，不同之处在于现在格式化程序将为开发者添加和删除这些逗号：

```dart
// Old style:
void writeArgumentList(
    Token leftBracket, List<AstNode> elements, Token rightBracket) {
  writeList(
      leftBracket: leftBracket,
      elements,
      rightBracket: rightBracket,
      allowBlockArgument: true);
}

// New style:
void writeArgumentList(
  Token leftBracket,
  List<AstNode> elements,
  Token rightBracket,
) {
  writeList(
    leftBracket: leftBracket,
    elements,
    rightBracket: rightBracket,
    allowBlockArgument: true,
  );
}

```

而目前，对于格式样式的处理取决于要格式化的代码的语言版本：

- 如果语言版本为 3.6 或更早版本，则代码的格式为旧样式
- 如果是 3.7 或更高版本，它将获得新样式

另外，为了确定格式化的每个文件的语言版本，`dart format` 会寻找一个 `package_config.json` 文件，这意味着**开发者需要在格式化 package 代码之前运行 `dart pub get`**。

> 在未来，当大多数生态系统都在 3.7 或更高版本上时，对旧样式的支持将被删除。

同时，dart format 对于新样式包含了一些期待已久的功能，例如：

- **项目范围的页面宽度配置** ，现在开发者可以在 `analysis_options.yaml` 文件中，配置项目范围内的首选格式页面宽度：

  ```yaml
  formatter:
    page_width: 123
  ```

- **从格式设置中选择退出代码区域**，开发者可以使用一对特殊标记注释将代码区域从自动格式化中剔除：

  ```dart
      main() {
        // dart format off
        no   +   formatting     +     here;
        // dart format on
      }
  ```

另外，格式化程序不再支持  `dart format --fix`  ，相反会使用 `dart fix` 可以直接触发   `dart format`  处理所有修复。

# 更新了 Dart analyzer 中的快速修复和新的 lint

在 Dart 3.7 中增加了新的 lints ，一个值得注意的新增功能是  `unnecessary_underscores`  这个 lint，它支持新的通配符变量功能。

另外，在 Dart 3.7 包含的大量新的快速修复和帮助支持，包括如缺少 `await` 关键字、不正确的导入前缀以及违反 lint 规则（如 `cascade_invocations`）等。

还有一些方便代码重构辅助的工具，例如将 `else` 块转换为 `else if`，以及使用 `Expanded` 或 `Flexible` 包装 Flutter widget 等。

> 更多可见：https://github.com/dart-lang/sdk/blob/master/CHANGELOG.md#analyzer-1



#  Dart Web 

由于现在主要的 JavaScript 库是 `dart:js_interop` ，而对于浏览器 API 是 `package:web` ，所以在 Dart 3.7 版本里，有 7 个 Dart SDK 库被弃用：

-  `dart：html`
- `dart:indexed_db` 
- `dart:js` 
- `dart:js_util` 
- `dart:web_audio`
- `dart:web_gl` 

# pub.dev 生产力

去年12 月 Dart 在 pub.dev 上启动了 package 的下载计数，而本次调整扩展了这一功能，**现在支持查看每个 package 版本的下载计数**。

通过这些数据，可以提示包的使用者中有多少人已升级到最新版本（或仅升级到最新的主要版本），旨在帮助包作者衡量将修复程序向后移植到包的较旧主要版本的价值。

![](http://img.cdn.guoshuyu.cn/20250212_D370/image2.png)

![](http://img.cdn.guoshuyu.cn/20250212_D370/image3.png)

同时 pub.dev 正式支持暗模式：

![](http://img.cdn.guoshuyu.cn/20250212_D370/image4.png)

另外，针对 topic 搜索支持，现在 pub.dev 上的搜索关键词推出了一个类似 IDE 的自动完成器，用户可以通过按 ctrl+space 来触发它，也可以在键入匹配的前缀（如 “topic:” 或 “license:”）时自动触发它。

# 最后

目前来看，Dart 3.7 属于“平平无奇”，和“带着大坑”的 Flutter 3.29 不同，升不升级影响不大，最多也只是能不能体验全新的格式化支持而已。

# 参考链接

- https://medium.com/@mbelanger_65682/bf864a1b195c