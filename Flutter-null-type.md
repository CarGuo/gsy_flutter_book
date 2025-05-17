# Flutter 在 Dart 3.8 开始支持 Null-Aware Elements 语法，自动识别集合里的空元素

近日，在 Dart 3.8 的 changelog 里正式提交了 Null-Aware Elements 语法，该语法糖可以用于在 List、Set、Map 等集合中处理可能为 null 的元素或键值对，简化显式检查 null 的场景：

```dart
/////////////////之前
var listWithoutNullAwareElements = [
  if (promotableNullableValue != null) promotableNullableValue,
  if (nullable.value != null) nullable.value!,
  if (nullable.value case var value?) value,
];

/////////////////之后
var listWithNullAwareElements = [
  ?promotableNullableValue,
  ?nullable.value,
  ?nullable.value,
];
```

自然，在 Flutter 的 UI 声明里，也可以简化之前控件的 if 判断，不得不说确实比起之前的写法优雅不少：

````dart
/////////////////之前
Stack(
  fit: StackFit.expand,
  children: [
    const AbsorbPointer(),
    if (widget.child != null) widget.child!,
  ],
)

/////////////////之后
Stack(
  fit: StackFit.expand,
  children: [
    const AbsorbPointer(),
    ?widget.child,
  ],
)
````

同时，官方在分析了大量开源 Dart 代码后（90019 个文件中的 17,941,439 行代码），发现这类需要支持的场景更多是 `Map` ：

```sh
-- Surrounding collection (1812 total) --
   1566 ( 86.424%): Map   ===============================================
    241 ( 13.300%): List  ========
      5 (  0.276%): Set   =
```

而事实上，从以下例子可以看出来，在简化 `Map` 上 Null-Aware Elements  的作用尤为明显：

```dart
/////////////////之前
final tag = Tag()
  ..tags = {
    if (Song.title != null) 'title': Song.title,
    if (Song.artist != null) 'artist': Song.artist,
    if (Song.album != null) 'album': Song.album,
    if (Song.year != null) 'year': Song.year.toString(),
    if (comments != null)
      'comment': comms!
          .asMap()
          .map((key, value) => MapEntry<String, Comment>(value.key, value)),
    if (Song.numberInAlbum != null) 'track': Song.numberInAlbum.toString(),
    if (Song.genre != null) 'genre': Song.genre,
    if (Song.albumArt != null) 'picture': {pic.key: pic},
  }
  ..type = 'ID3'
  ..version = '2.4';

/////////////////之后
final tag = Tag()
  ..tags = {
    'title': ?Song.title,
    'artist': ?Song.artist,
    'album': ?Song.album,
    'year': ?Song.year?.toString(),
    if (comments != null)
      'comment': comms!
          .asMap()
          .map((key, value) => MapEntry<String, Comment>(value.key, value)),
    'track': ?Song.numberInAlbum?.toString(),
    'genre': ?Song.genre,
    if (Song.albumArt != null) 'picture': {pic.key: pic},
  }
  ..type = 'ID3'
  ..version = '2.4';
```

通过下面的简单例子，也可以看出来有了  Null-Aware Elements  之后在代码简化效果上很明显：

![](https://img.cdn.guoshuyu.cn/image-20250427084301008.png)

![](https://img.cdn.guoshuyu.cn/image-20250427083750990.png)

当然，配合其他语法也能达到去 null 的效果，比如最简单的 for 循环，通过 `?i` ，就可以简单到做排除空数据的目的：

![](https://img.cdn.guoshuyu.cn/image-20250427084119690.png)![](https://img.cdn.guoshuyu.cn/image-20250427084136136.png)

当然，你可能会觉得本来 Dart 里就有很多 ? ，比如 ?? 、 ?.  之类，加上语法之后会不会有歧义？这个问题在目前的规则上看起来还行，例如此时的  `?` 前通常是 `,` 、`[`、`{  `或 `:` 等符号，这些上下文和现有 `?` 用法不同 ：

```dart
var list = [1, ?foo]; // ? 是空感知元素，不是其他用法
var map = {key: ?value}; // ? 是空感知值，不是可空类型
```

并且前面介绍过，与现有语法如 `if` 或 `for` 元素结合时，`?` 出现在 `if `或 `for ` 头部后也不会有歧义：

```dart
var list = [
  for (var i in [1, 2]) ?i, // 合法：?i 是空感知元素
];
print(list); // 输出: [1, 2]
```

而在 Flutter 里的 UI 编排了就更加直观了：

![](https://img.cdn.guoshuyu.cn/image-20250427085057405.png)

当然，这个语法还是有一些规则限制，在这个规则下 expression 只能是一个普通表达式，不能是另一个集合，比如嵌套的 `?` 或展开操作 `...` ：

```dart
element ::=
  | nullAwareExpressionElement
  | nullAwareMapElement
  | // Existing productions...

nullAwareExpressionElement ::= '?' expression

nullAwareMapElement ::=
  | '?' expression ':' '?'? expression // Null-aware key or both.
  |     expression ':' '?' expression  // Null-aware value.
```

例如下方代码就可以很直观展示这个错误使用，同时也没有 `????foo` 或 `?if (c) nullableThing else otherNullableThing`  这样的场景：

![](https://img.cdn.guoshuyu.cn/image-20250427084419047.png)![](https://img.cdn.guoshuyu.cn/image-20250427084439064.png)

可以看到， Null-aware elements  语法不管是在逻辑代码还是 UI 代码都十分有用，虽然 Dart 3.8 还没正式发布，但是你可以在 Flutter beta channel 提前体验，那么，你觉这个语法符合你的审美吗？

# 参考链接

- https://github.com/dart-lang/language/blob/main/accepted/future-releases/0323-null-aware-elements/feature-specification.md