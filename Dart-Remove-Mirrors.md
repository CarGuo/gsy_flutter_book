# Dart 4.0 要彻底移除 dart:mirrors，Augmentations 应该要来了

按照目前计划，**Dart 3.14 会在 2026 年 11 月正式把它标成 `@deprecated`，然后 Dart 4.0 再完全移除**，也就是下个版本开始，这个 Flutter 用不上的，但是一直活跃在 Dart 的历史支持  ` dart:mirrors` 就要完全退出历史舞台了。

![](/article-assets/dac9ee4650da8dd5d1723447.webp)

之前的 `dart:mirrors` 其实就是反射的作用，程序运行起来以后，可以拿到自己的 `MirrorSystem`，查相应的 library、class、method、field，也可以通过 `InstanceMirror.invoke()` 这类 API 按名字调用方法，比如：

- 服务端框架启动时扫描所有带路由 annotation 的方法，再自动把它们注册到 HTTP Router
- 序列化、对象映射、测试发现也可以在运行时枚举程序结构，不需要提前生成代码

> 但是在 Dart 2.0  开始 Web 编译器就不再支持 `dart:mirrors` 了，而且 Flutter 很早前也不支持这个能力，不然也不会至今都没有 内置 Json 序列化的原生能力。

其实理解 mirrors 为什么和目前的 Dart 设计冲突，用一个 HTTP Router 就很直观，比如：

- 服务器启动时扫描所有 class，找到带 `@Route('/users')` 的方法，然后运行时按方法名调用它，这样对开发者来说确实很省事，因为增加一个 handler 只需要写方法和 annotation
- 但是对 AOT 编译器来说，未来究竟会通过字符串访问哪些成员就很难确定，只要编译器证明不了某个方法永远不会被反射访问，那它就不能放心删除这个方法，还可能需要保留类名、成员名、annotation、参数等 metadata

**这样就直接削弱了 tree shaking** ，Dart 的 AOT、Web 和 Wasm 编译都希望在编译期尽量建立完整的可达关系，甚至 FFI 都要 tree shaking ，但是 runtime reflection 会把一部分「谁会被调用」的决定留到了程序运行以后，不是说做不了，毕竟也有其他语言做到了，只是说这么做的成本比较高，所以编译器为了保证语义只能更加保守。

毕竟只要 AOT 上了，这一点要做好还是挺麻烦的，**比如 Kotlin 离开了 JVM生态后也是**：

|                                    | Kotlin/JVM                          | Kotlin/Native               |
| ---------------------------------- | ----------------------------------- | --------------------------- |
| 运行环境                           | JVM                                 | 直接编译成本地二进制        |
| 编译方式                           | JVM bytecode，运行时由 JVM/JIT 执行 | LLVM AOT 为主，不需要 JVM   |
| 完整 `kotlin-reflect`              | 支持                                | **不支持 JVM 那套完整能力** |
| `KClass.members`                   | 支持                                | 不支持                      |
| 枚举 class 全部 methods/properties | 支持                                | 很有限                      |
| Java Reflection                    | 支持                                | 没有 JVM，自然没有          |
| `::class` / `KClass`               | 支持                                | 支持，但信息少很多          |
| 函数/属性引用                      | 支持                                | 支持                        |
| Native binary shrinking/AOT        | 不是 JVM 传统强项                   | 是核心设计之一              |

> `KClass` 本身是 Common API，Native 也有，所以你可以写 `obj::class`、取 `simpleName`、`qualifiedName`、做类型判断，但是像 `KClass.members`、`nestedClasses`、`sealedSubclasses`、`supertypes` 这些真正开始“遍历一个类结构”的能力，官方 API 目前直接标的是 JVM only。

不过这次删除 `dart:mirrors` ，其实也是 Dart 把坚持多年的工程方向正式固定下来：

> 动态发现尽量放在编译期或者代码生成阶段，运行时执行已经显式化的调用关系，现在官方自己的 `build_runner` 文档甚至已经直接把 Dart build system 作为 reflection 和 macros 的替代方案。

目前来看这个对 Flutter 来说基本无感，甚至可能还会是好事，因为这说明 Augmentations 要来了，反正之前也都不给用，但是对于 Tooling 或者 Plugin 的开发说不准就得适配一次了，比如一些纯 Dart Server、CLI、测试框架和内部工具，尤其是直接依赖 `import 'dart:mirrors'` 的项目。

> Dart SDK 自己现在就在迁移 `package:test_reflective_loader`，之前它也靠 `dart:mirrors` 做自动发现 `@reflectiveTest` 方法，现在官方也在转 CFE 在编译阶段直接把这些测试方法降成普通 constructor tear-off / method tear-off，目的是**保留“新增 test 方法直接 `dart test`”的体验，同时彻底移除 runtime mirrors，而且不要求用户跑 build_runner**。

**不过如果 Augmentations 能力能全面发布的话，应该可以改善目前 generated code 和原声明之间的关系**，因为很多项目用 `dart:mirrors`，其实也不是真的需要“运行时随便反射一切”，大家可能只是为了解决一些更具体的问题，比如：

> “我写了一个类，能不能自动根据这个类的声明，再补出一批重复代码？”

这也 Augmentations 能补掉相当一部分 mirrors 使用场景的原因，比如最典型的 JSON 序列化，以前用 mirrors 可以在运行时拿到 `User` 的字段列表，看到 `name`、`age` 然后动态读取，而 Augmentations 的思路完全反过来，比如开发者写：

```dart
@JsonSerializable()
class User {
  final String name;
  final int age;
}
```

然后构建阶段 generator/analyzer 已经能看到 `User` 的结构，于是生成的代码可以直接“补进”这个 class：

```dart
augment class User {
  Map<String, Object?> toJson() => {
    'name': name,
    'age': age,
  };
}
```

**也就是不需要运行时已经没有“检查 User 有哪些字段”这一步了** ，	`name`、`ag`e、`toJson()` 全部可以在编译时变成正常 Dart 代码，AOT 编译器可以理清楚关系，该 tree-shake 什么也可以正常判断。

这也是 Augmentations 目前设计的核心能力：

> 一个 declaration 可以分散到多个位置，augmentation 可以给已有 class 增加成员、给函数补 body、增加 top-level declaration、给 enum 增加值等等。

所以， 11 月新版本 Flutter 和 Dart 要来了，然后明年 4 版本也要来了。
