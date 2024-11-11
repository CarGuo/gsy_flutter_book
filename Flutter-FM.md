# Flutter 小技巧之 equatable 包解析以及宏编程解析

今天我们聊聊 equatable 包的实现，并通过 equatable 去理解 Dart 宏编程的作用和实现，对于 Flutter 开发者来说，Dart 宏编程可以说是「望眼欲穿」。

# equatable

正如 equatable 这个包名所示，它的功能很简单，主要是用来帮助实现 class 级别基于值的「🟰」封装，如下代码所示，就算是一个三岁的程序都知道，正常情况下此时的  `bob == Person("Bob")` 结果会是 false ，因为它们是两个不同的 class 实例，hashcode 默认情况下就是不相等的。

```dart
class Person {
  const Person(this.name);

  final String name;
}

final Person bob = Person("Bob");

print(bob == Person("Bob")); // false
```

那么如果需要它们相等，如下代码所示，我们需要 override `==`  操作符去自定义所需的判断逻辑，这样看起来貌似也不麻烦，但是如果一个类参数很多，那么类似的重复性代码就会很多，这时候就需要  equatable 这个包来减轻工作量。

```dart
class Person {
  const Person(this.name);

  final String name;

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Person &&
    runtimeType == other.runtimeType &&
    name == other.name;

  @override
  int get hashCode => name.hashCode;
}
```

如下代码所示，通过 equatable 你只需要 `extends Equatable` ，然后 `override  props` 参数即可实现对应的  `==`  自定义，这样从代码层级上看是不是更清晰简约了？

```dart
import 'package:equatable/equatable.dart';

class Person extends Equatable {
  const Person(this.name);

  final String name;

  @override
  List<Object> get props => [name];
}


class Person2 extends Equatable {
  const Person2(this.name, [this.age]);

  final String name;
  final int? age;

  @override
  List<Object?> get props => [name, age];
}
```

当然，对于 equatable 还是有一些限制，例如**所有成员变量都必须是 final**， 因为 Dart 官方在说明自定义 `==` 逻辑就表示过， 用可变值覆盖 `hashCode` 可能会破坏基于哈希的集合：

> 定义 `==` 时，还必须定义 `hashCode`，这两者都应该考虑对象的字段，如果字段发生更改，则意味着对象的哈希代码可以更改
>
> 大多数基于哈希的集合不会预料到这一点，它们假设对象的哈希代码将永远相同，如果不是这样，则可能会发生不可预测的行为。

那么回到 equatable 包的实现 ，核心逻辑就是处理  `equals`  来判断🟰 的逻辑，还有生成  `mapPropsToHashCode` 哈希来决定 hash 值。

```dart
	@override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Equatable &&
            runtimeType == other.runtimeType &&
            equals(props, other.props);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ mapPropsToHashCode(props);
```

首先自定义的   `equals`  判断其实就是对于两个 class 的  `props`  列表进行拆分判断，这里主要需要注意的是，由于类变量可以是任何对象，那么也就可以能是集合，例如 Map、Set 等，**所以需要用到 Dart 的 DeepCollectionEquality 对象来处理**，可以减轻很多判断的工作量。

>  DeepCollectionEquality 主要处理集合的深度相等的工具类，简单来说，它可以识别列表、集合、可迭代对象和映射，并深度较它们的元素，甚至可以按照有序或无序的工作模式来进行判断

```dart

const DeepCollectionEquality _equality = DeepCollectionEquality();

/// Determines whether [list1] and [list2] are equal.
bool equals(List<Object?>? list1, List<Object?>? list2) {
  if (identical(list1, list2)) return true;
  if (list1 == null || list2 == null) return false;
  final length = list1.length;
  if (length != list2.length) return false;

  for (var i = 0; i < length; i++) {
    final unit1 = list1[i];
    final unit2 = list2[i];

    if (_isEquatable(unit1) && _isEquatable(unit2)) {
      if (unit1 != unit2) return false;
    } else if (unit1 is Iterable || unit1 is Map) {
      if (!_equality.equals(unit1, unit2)) return false;
    } else if (unit1?.runtimeType != unit2?.runtimeType) {
      return false;
    } else if (unit1 != unit2) {
      return false;
    }
  }
  return true;
}

bool _isEquatable(Object? object) {
  return object is Equatable || object is EquatableMixin;
}
```

而对于生成哈希，equatable 用了 Jenkins 哈希算法，核心就是将任意长度的数值转换为固定长度的哈希值，算法的实现也相对简单，它只需要利用位移操作和迭代来生成哈希值，通过不断递归将所有参数进行 Jenkins 哈希计算，例如：

- 将哈希值左移 10 位，与原哈希值相加，扩大了哈希值，增加了变化范围
- 将哈希值右移 6 位，与原哈希值进行异或运算，减少了哈希值中的线性依赖

```dart
int mapPropsToHashCode(Iterable<Object?>? props) {
  return _finish(props == null ? 0 : props.fold(0, _combine));
}

int _combine(int hash, Object? object) {
  if (object is Map) {
    object.keys
        .sorted((Object? a, Object? b) => a.hashCode - b.hashCode)
        .forEach((Object? key) {
      hash = hash ^ _combine(hash, [key, (object! as Map)[key]]);
    });
    return hash;
  }
  if (object is Set) {
    object = object.sorted((Object? a, Object? b) => a.hashCode - b.hashCode);
  }
  if (object is Iterable) {
    for (final value in object) {
      hash = hash ^ _combine(hash, value);
    }
    return hash ^ object.length;
  }

  hash = 0x1fffffff & (hash + object.hashCode);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

int _finish(int hash) {
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}
```

到这里我们大概就解析了  equatable 的作用和实现，但是其实在使用上还不够优雅简介，因为需要手写 props 和显式继承的操作，还是让人觉得侵入性太强，那么这时候就该说宏编程的作用了。



# Macro

事实上在这类应用场景上，宏编程对于 equatable 来说无疑是最适合的操作，equatable 包的作者在 `3.0.0-dev.1`    中就迫不及待发布了采用 macros 实现的 package ，而修改后的 equatable 代码如下所示：

```dart
@Equatable()
class Person {
  const Person(this.name);

  final String name;
}
```

可以看到，他就是一个正常的 class ，你只需要添加 `@Equatable()` 注释，它就拥有了前面所说的 equatable class 的特性，这样看是不是优雅和简单了不少？

> 并且和之前旧的 build_runner 等不同，它不会在你项目里直接生产 `.g.dart` 的文件。

 在引入带有宏编程的 equatable 包之后，只需要运行  `flutter run --enable-experiment=macros` ，就可以直接得到之前一样的结果：

![](http://img.cdn.guoshuyu.cn/20241018_FM/image1.png)

并且  `@Equatable()`  和实验性的 `@JsonCodabel` 是可以同时使用，此时只需要两个注解，你就可以得到一个包含序列化能力的和类对比能力的 class 对象。

![](http://img.cdn.guoshuyu.cn/20241018_FM/image2.png)

这里提一个题外话， 在 VSCode 其实你可以看到一个 `Go to Augmentation`  的区域，点击后可以跳转的 augment class ，也就是类似「宏生成效果」的文件预览里，通过 augment class， 你可以实时预览注解生成的代码：

> 这个增强能力属于宏生成带有 augment 的文件，与旧代码生成的实际区别在于，它是存在于内存中，而不是在 `.g.dart` 这样的形式出现在项目里。
>
> Dart 的 augmentation 功能通过添加成员，或替换原始块之外的主体，来达到更改类或函数的能力，这个功能独立于宏之外。

![](http://img.cdn.guoshuyu.cn/20241018_FM/image3.gif)

当然，如果你是 Android Studio ，可能会看不到这样的支持，那么你可以通过引入一个  ` show_augmentation ` 的包来做到类似的功能预览，如下所示，通过运行 `dart run show_augmentation --file=lib/person.dart` 后，也可在命令行得到类似的输出：

![](http://img.cdn.guoshuyu.cn/20241018_FM/image4.png)

回到 equatable，我们简单说下它的实现，常规上就是通过实现 `ClassDeclarationsMacro ` 和 `ClassDefinitionMacro` 来完成宏编程额基础操作，通过 `buildDeclarationsForClass`  去编辑需要的声明，然后通过 `buildDefinitionForClass`  去定义实现：

![](http://img.cdn.guoshuyu.cn/20241018_FM/image5.png)

例如，一般在声明时，我们需要用到 `Uri.parse('dart:core')` ，因为我们需要用到 Dart 的能力支持，例如这里的  `final boolean = await builder. codeFrom(_dartCore, 'bool');` ，当然这里的 codeFrom 实现 其实是 equatable 做了一些封装，我们可以通过下面一个简单的例子更好理解。

![](http://img.cdn.guoshuyu.cn/20241018_FM/image6.png)

如下代码所示，首先我们通过 `Uri.parse('dart:core')`  得到了 Dart 的核心库，然后通过 `MemberDeclarationBuilder`  得到了 Dart 里的 `print`  方法：

![](http://img.cdn.guoshuyu.cn/20241018_FM/image7.png)

>  所以这里是通过 `dart:core` 获取  `print` 方法，然后再生成的  `hello` 代码里输出所有参数，而 `ClassDeclarationsMacro`  会告诉编译器它可以应用于 class。

那为什么需要 `dart:core`  加载这一步，其实它其中一个作用就是可以**自动生成前缀**，还记得前面我们命令行到输出么？你会发现 `dart：core` 是用前缀导入的：

![](http://img.cdn.guoshuyu.cn/20241018_FM/image8.png)

>  前缀是动态的，它能确保你的代码不会与任何核心内容（如 `print`）发生冲突，而且因为是动态，所以你也不知道它会是什么，所以你不能直接在代码里写 `print（xxxxx）` ，所以需要通过  *parts* 构建生成的代码。

回到 equatable ，同样的在实现对应的生成代码定义时，如果我们用到了自己的某些 function ，也需要通过  `Uri.parse` 引入，例如通过  `final _equatable = Uri.parse('package:equatable/equatable.dart');` ，之后就可以使用对应的 equatable 能力：

![](http://img.cdn.guoshuyu.cn/20241018_FM/image9.png)

而从最终实现效果看，equatable 借用宏完成了可以重复生成的部份，最终开发者只需要通过  `@Equatable()` 即可完成功能引入，类似 ` @JsonCodable()` 即可引入 `toJson` 和 `fromJson`  一样。

其实我们还可以通过另外一种方式去查看宏的效果，那就是通过对 debug 编译后的 app.dill 文件进行分析，通过 `dump_kernel.dart` 可以转化出 app.dill.txt 文件，通过最终生成的 txt 文件我们可以直观感受宏的作用。

```sh
dart pkg/vm/bin/dump_kernel.dart xxxxxx/app.dill xxxxxx/app.dill.txt 
```

如下图所示，可以看到 `"dart: core"` 都加上了前缀，然后对应的方法都已经动态添加进入，并且标明了 marco 和 file 路径，同时如  `deepEquals` 和 `jenkinsHash ` 也成功引入。

![](http://img.cdn.guoshuyu.cn/20241018_FM/image10.png)

当然，上面命令的`pkg/vm/bin/dump_kernel.dart`  需要在官方 [dart-lang/sdk ](https://github.com/dart-lang/sdk) 的全量 SDK 才能找到，但是如果你直接 clone  dart-lang/sdk 项目，然后去执行 dump_kernel ，基本上会遇到下面这个问题：

![](http://img.cdn.guoshuyu.cn/20241018_FM/image11.png)

因为如果想要使用 dump_kernel，你就需要 depot_tools  工具，depot_tools  是 Chromium 的源码管理工具，同时也需要对应的环境支持：

- python3  环境
- git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git ，并将路径配置 `export PATH=/Users/xxxxx/workspace/depot_tools:$PATH` 
- 创建一个目录，并执行  `fetch dart` ，会比较耗时，大概几个 G 的大小
- 进入 sdk 目录，执行 git checkout xxxx ，切换到对应 dart 版本 tag ，因为一般情况下，你 debug 运行的 dart 版本和 sdk 的 dart 版本需要一致
- 执行 gclient sync -D
- 现在你就可以通过 `dart pkg/vm/bin/dump_kernel.dart xxxxxx/app.dill xxxxxx/app.dill.txt `  去 dump kernel ，这里的  `pkg/vm/bin/dump_kernel.dart` 路径就是前面 sdk 下的路径。



# 最后

总结一下，本篇主要通过 equatable 介绍了一些 Dart 的基础知识和技巧，同时利用 equatable 展开介绍了下宏的概念和作用，并且介绍了不同方式查看宏编程的产物，对于未来宏编程支持的正式发布，相信 Flutter 开发者们还是翘首以待的，那么你是否已经体验过 Dart 3.5 里的宏编程实验性支持了？













