# 再聊 Flutter Riverpod ，注解模式下的 Riverpod 有什么特别之处，还有发展方向



三年前我们通过 [《Flutter Riverpod 全面深入解析》](https://juejin.cn/post/7063111063427874847) 深入理解了 riverpod 的内部实现，而时隔三年之后，如今Riverpod 的主流模式已经是注解，那今天就让我们来聊聊 riverpod 的注解有什么特殊之处。

# 前言

在此之前，我们需要先回忆一下，**riverpod  最明显的特点是将  `BuildContext` 转换成 `WidgetRef` 抽象**  ，从而让状态管理不直接依赖  `BuildContext` ，所以对应的  Provider  可以按需写成全局对象，而在 riverpod 里，主要的核心对象有：

- **ProviderScope** ： `InheritedWidget`   实现，共享实例的顶层存在，提供一个 `ProviderContainer`  全局共享
- **ProviderContainer**：用于管理和保存各种 “Provider” 的 State ，并且支持 override 一些特殊 “Provider” 的行为，还有常见的  read\watch\refesh
- **Ref** ：提供 riverpod 内的  “Provider” 交互接口，是 riverpod 内 ProviderElementBase 的抽象
- **ProviderElementBase** ： Ref 的实现，每个 “Provider” 都会有自己的 “Element” ，而构建 “Provider” 时是传入的 `Create` 函数会在 “Element” 内通过 "`setState`" 调用执行，比如 ` StateProvider((ref)=> 0)` 这里的 ref ，就是内部在  ”Element“  里通过  `setState(_provider.create(this));` "  的时候传入的 this
- **WidgetRef** ：替代 Flutter  `BuildContext`   的抽象，内部通过继承 `StatefulWidget`  实现，作为 BuildContext 的对外替代

![](http://img.cdn.guoshuyu.cn/20250303_riverpod/image1.png)

> 所以   "Provider" 里的 `Ref` 和 “Consumer” 的  `WidgetRef` 严格来说是两个不同的东西，只是它们内部都可以获取到  `ProviderContainer` ，从而支持对应   read\watch\refesh 等功能，这也是为什么你在外部直接通过  `ProviderContainer`  也可以全局直接访问到    read\watch\refesh  的原因。

另外，**riverpod 内部定义了自己的 「Element」 和 「setState」实现，它们并不是 Flutter 里的 Element 和 setState**，所以上面都加了 “”，甚至 riverpod 里的 “Provider” 和 Provider 状态管理库也没有关系， 这么设计是为了贴合 Flutter 本身的 「Element」 和 「setState」概念，所以这也是为什么说 riverpod 是专为 Flutter 而存在的设计。

# 注解模式

现在 riverpod 更多提倡使用注解模式，**注解模式可以让 riverpod 使用起来更方便且规范，从一定程度也降低了使用难度**，但是也对初学者屏蔽了不少过去的手写实现，导致在出现问题时新手也可能会相对更蒙。

## 简单函数注解

首先我们看这个简单的代码，我们在 `main.dart ` 里添加了了一个 `@riverpod`  给 `helloWorld` ，然后运行 `flutter pub run build_runner build --delete-conflicting-outputs` ，可以看到此时生成了对应的 `main.g.dart` 文件：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main.g.dart';

@riverpod
String helloWorld(Ref ref) {
  return 'Hello world';
}
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String value = ref.watch(helloWorldProvider);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Example')),
        body: Center(
          child: Text(value),
        ),
      ),
    );
  }
}
```

我们看  `main.g.dart` 文件，可以看到，根据 `@riverpod` 的规则， `helloWorld` 会生成一个 `helloWorldProvider` 实例让我们在使用时 read/watch/refresh ：

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$helloWorldHash() => r'9abaa5ab530c55186861f2debdaa218aceacb7eb';

/// See also [helloWorld].
@ProviderFor(helloWorld)
final helloWorldProvider = AutoDisposeProvider<String>.internal(
  helloWorld,
  name: r'helloWorldProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$helloWorldHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HelloWorldRef = AutoDisposeProviderRef<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

```

通过生成的代码，我们可以看到：

-   ` _$helloWorldHash()` ：它主要是用于提供一个唯一标识，用于追踪 Provider 的来源和状态，它是被  ` debugGetCreateSourceHash` 所使用，例如在 Debug 模式下 hotload 时，riverpod 会用这个值来判断当前 provider 是否需要重建，比如当你重新生成的时候 hash 值就会出现变化。
- `helloWorldProvider`  ：  `AutoDisposeProvider` 的实例，也就是默认情况下 `@riverpod` 生成的都是自动销毁的 Provider ，

> 这里默认使用  `AutoDisposeProvider`  ，也是为了更好的释放内存和避免不必需要的内存泄漏等场景，  `AutoDisposeProvider`   内部，在每次  `read` 、`invalidate` 、页面退出、`ProviderContainer` 销毁等场景会自动调用 dispose 。

## 异步函数注解

接着，如果给 `helloWorld` 增加 async ，那么我们得到一个  `AutoDisposeFutureProvider` ，同理，如果是 `async*` 就会生成一个 `AutoDisposeStreamProvider` ：

```dart
@riverpod
Future<String> helloWorld(Ref ref) async{
  return 'Hello world';
}

------------------------------GENERATED CODE---------------------------------

@ProviderFor(helloWorld)
final helloWorldProvider = AutoDisposeFutureProvider<Object?>.internal(
  helloWorld,
  name: r'helloWorldProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$helloWorldHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
```

当然，在返回结果使用上会有些差别， 异步的 Provider 会返回一个 `AsyncValue` ，或者需要 `.value` 获取一个非空安全的对象：

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final AsyncValue<String> asyncValue = ref.watch(helloWorldProvider);
  final String? value = ref.watch(helloWorldProvider).value;
  return MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Example')),
      body: Center(
        child: Text(asyncValue.when(
            data: (v) => v,
            error: (_, __) => "error",
            loading: () => "loading")),
      ),
    ),
  );
}
```

## 函数注解带参数

当你需要给 `helloWorld`  增加参数的时候，此时的 `helloWorldProvider`  就不再是一个 `AutoDisposeFutureProvider`  实例，它将变成 `HelloWorldFamily` ，它是一个 `Family`  的实现：

```dart
@riverpod
Future<String> helloWorld(Ref ref, String value, String type) async {
  return 'Hello world $value $type';
}

@override
Widget build(BuildContext context, WidgetRef ref) {
  final AsyncValue<String> asyncValue = ref.watch(helloWorldProvider("1", "2"));
  final String? value = ref.watch(helloWorldProvider("1", "2")).value;
}

------------------------------GENERATED CODE---------------------------------

/// See also [helloWorld].
class HelloWorldFamily extends Family<AsyncValue<String>> {
  /// See also [helloWorld].
  const HelloWorldFamily();

  /// See also [helloWorld].
  HelloWorldProvider call(
    String value,
    String type,
  ) {
    return HelloWorldProvider(
      value,
      type,
    );
  }

  @override
  HelloWorldProvider getProviderOverride(
    covariant HelloWorldProvider provider,
  ) {
    return call(
      provider.value,
      provider.type,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'helloWorldProvider';
}

```

> 在 Dart 中，call 方法是一个特殊的方法，它可以让一个类的实例像函数一样调用。

说到  `Family`  ， 它的作用是主要就是支持**使用额外的参数构建 Provider** ，因为前面  `helloWorld`  需要传递参数，所以 `HelloWorldFamily` 的主要作用，就是提供创建和覆盖需要参数的 Provider，例如前面的：

```dart
  final AsyncValue<String> asyncValue = ref.watch(helloWorldProvider("1", "2"));
  final String? value = ref.watch(helloWorldProvider("1", "2")).value;
```

当然，这里你需要注意，不同与前面的 `helloWorldProvider` 实例，需要参数的 Provider 需要你每次使用时通过参数构建，而此时你每次调用如  `helloWorldProvider("1", "2")`  都是创建了一个全新实例，如果你需要同一个数据源下 read/watch ，那么你应该在调用时共用一个全局  `helloWorldProvider("1", "2")`   实例。

如果是不同 Provider 实例，那么你获取到的参数其实是不一样的，因为内部 map 登记的映射关系就是基于 Provider 实例为 key ：

![](http://img.cdn.guoshuyu.cn/20250303_riverpod/image2.png)

不过对比之下，过去你使用 `FutureProvider.family` 只能覆带一个 `Arg` 参数，虽然可以通过语法糖传递多个参数，但是终究还是比注解生成的麻烦：

```dart
final helloWorldFamily =
    FutureProvider.family<String, (String, String)>((value, type) async {
  return 'Hello world $value $type';
});
```

另外，注解生成时，还会动态生成一个对应的 "Element" ，让 Element 支持获取 Provider 的参数，并实现对应 `build` 方法，也就是通过 ref 可以获取到相关参数：

```dart
mixin HelloWorldRef on AutoDisposeFutureProviderRef<String> {
  /// The parameter `value` of this provider.
  String get value;

  /// The parameter `type` of this provider.
  String get type;
}

class _HelloWorldProviderElement
    extends AutoDisposeFutureProviderElement<String> with HelloWorldRef {
  _HelloWorldProviderElement(super.provider);

  @override
  String get value => (origin as HelloWorldProvider).value;
  @override
  String get type => (origin as HelloWorldProvider).type;
}
```

最后，带参数之后，生成的 `_SystemHash` 也会根据参数动态变化，从而支持 hotload 等场景：

```dart
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}
```

## 类注解

接着，我们看 `@riverpod` 除了可以注解函数之后，还可以直接注解 class ，只是 class 需要继承 `_$***` 一个子类：

```dart
@riverpod
class HelloWorld extends _$HelloWorld {
  @override
  String build() {
    return 'Hello world';
  }
  changeValue(String value) {
    state = value;
  }
}

@override
Widget build(BuildContext context, WidgetRef ref) {
  final String asyncValue = ref.watch(helloWorldProvider);
  ref.read(helloWorldProvider.notifier).changeValue("next");
}
```

通过生成代码可以看到，此时生成的是 `AutoDisposeNotifierProvider` ，也就是在读取时，可以通过 `read(****Provider.notifier)` 去改变状态：

```dart
String _$helloWorldHash() => r'52966cfeefb6334e736061e19443e4c8b94160d8';

/// See also [HelloWorld].
@ProviderFor(HelloWorld)
final helloWorldProvider =
    AutoDisposeNotifierProvider<HelloWorld, String>.internal(
  HelloWorld.new,
  name: r'helloWorldProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$helloWorldHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$HelloWorld = AutoDisposeNotifier<String>;
```

也就是，**通过  `@riverpod`  注解的 class ，是带有 state 状态的 NotifierProvider ，这是对比注解函数最明显的差异**。

而如果注解 class 需要携带参数，那么可以在 `build` 上添加需要的参数，最终同样和函数一样会生成一个对应的 `HelloWorldFamily` ：

```dart
@riverpod
class HelloWorld extends _$HelloWorld {
  @override
  String build(String value, String type) {
    return 'Hello world';
  }

  changeValue(String value) {
    state = value;
  }
}
```

同理，如果你给 build 增加了 async，那么就会生成一个 `AutoDisposeAsyncNotifierProviderImpl`  的相关实现：

```dart
@riverpod
class HelloWorld extends _$HelloWorld {
  @override
  Future<String> build(String value, String type) async {
    return 'Hello world';
  }

  changeValue(String value) {
    final currentValue = state.valueOrNull ?? "";
    state = AsyncData(currentValue + value);
  }
  
  removeString(String value) {
    final currentValue = state.valueOrNull ?? "";
    state = state.copyWithPrevious(AsyncData(currentValue.replaceAll(value, "")));
  }
}
```

可以看到，**在注解 class 下可操作空间是在 build ，并且需要注意的是，当你调用 `refresh` 的时候，State 是会被清空，并且重新调用 build**。

## KeepAlive

那么我们前面说的都是  AutoDispose ，如果我不想他被释放呢？那就是需要用到大写字母开头的  `@Riverpod`  ，给参数配置上 `keepAlive: true` ：

```dart
@Riverpod(keepAlive: true)
class HelloWorld extends _$HelloWorld 
```

然后再看输出文件，你就会看到此时  `HelloWorldProvider` 继承的是  `AsyncNotifierProviderImpl` 而不是  `AutoDispose` 了：

```dart
class HelloWorldProvider extends AsyncNotifierProviderImpl<HelloWorld, String> {
  /// See also [HelloWorld].
  HelloWorldProvider(
    String value,
    String type,
  ) : this._internal(
```

## dependencies

另外 ` @Riverpod` 还有另外一个可配置参数  `dependencies` ，从名字上理解起来是依赖的意思，但是其实它更多用于「作用域」相关的处理。

在 riverpod 里，框架的设计是支持多个 ProviderContainer 的场景，并且每个容器可以覆盖（override）某些 Provider 的数据，例如我只是添加了一个  `dependencies: []` ，**此时无论列表是否为空，它都可以被认为是一个具有作用域支持的 Provider，从而实现根据上下文进行数据隔离，另外不为空时还可以看作声明 Provider 在作用域内的依赖关系**。

```dart
@Riverpod(dependencies: [])
```

**但是，不是你加了 dependencies 它就自动产生作用域隔离了，不为空时也不会自动追加依赖**，它只是一个声明作用，后续还是需要代码配合。

如下代码所示，这里简单的声明了一个带有 `dependencies` 的 `Counter` ，然后：

- 在页面通过 `ref.watch(counterProvider)` 监听了 Counter
- 在新的 dialog 也通过 `ref2.watch(counterProvider)` 监听了 Counter

```dart
@Riverpod(dependencies: [])
class Counter extends _$Counter {
  @override
  int build() => 0;

  void update(int count) {
    state = count;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        home: Consumer(builder: (ctx, ref, __) {
          final count = ref.watch(counterProvider);
          return Scaffold(
            appBar: AppBar(),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Counter: $count'),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: ctx,
                      builder: (context) => AlertDialog(
                          title: Text('Dialog'),
                          content: Consumer(builder: (_, ref2, __) {
                            final count2 = ref2.watch(counterProvider);
                            return InkWell(
                              onTap: () {
                                ref2
                                    .read(counterProvider.notifier)
                                    .update(count2 + 1);
                              },
                              child: Text('Dialog Counter: $count2'),
                            );
                          })),
                    );
                  },
                  child: Text('Open Dialog'),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(onPressed: () {
              ref.read(counterProvider.notifier).update(count + 1);
            }),
          );
        }),
      ),
    );
  }
}

```

结果最后运行发现，Dialog 和主页的 Counter 其实还是共享的， `dependencies` 并没有起到作用：

![](http://img.cdn.guoshuyu.cn/20250303_riverpod/image3.gif)

之所以这样，原因在于没有增加新的  `ProviderScope` ，如下代码所示，只要将上面的 `showDialog`  部分修改为如下代码所示：

- 新增一个 的  `ProviderScope` 
- 通过 `overrides` 指定对应  `counterProvider` 

```dart
showDialog(
  context: ctx,
  builder: (context) => ProviderScope(
    overrides: [
      counterProvider，
      ///你还可以 overrideWith 覆盖修改
      //counterProvider.overrideWith(()=>Counter())
    ],
    child: AlertDialog(
        title: Text('Dialog'),
        content: Consumer(builder: (_, ref2, __) {
          final count2 = ref2.watch(counterProvider);
          return InkWell(
            onTap: () {
              ref2
                  .read(counterProvider.notifier)
                  .update(count2 + 1);
            },
            child: Text('Dialog Counter: $count2'),
          );
        })),
  ),
);
```

以上条件缺一不可以，运行后如下图所示，可以看到此时 `counterProvider` 在主页和 Dialog 之间被有效分割开：

![](http://img.cdn.guoshuyu.cn/20250303_riverpod/image4.gif)

其实原因从源码里也可以看出来，在 `ProviderContainer` 内部源码我们可以看到，要产生一个独立的作用域，你需要：

- root 不为空，也就是有一个上级 `ProviderContainer` 
- 其次存在 `dependencies` 且  ` ProviderContainer`  的 override 不为空，也就是 `dependencies` 不为 null 就行，但是 override 必须有 Provider 
- 最后才是返回全新的 `_StateReader`  用于提供状态数据

![](http://img.cdn.guoshuyu.cn/20250303_riverpod/image5.png)

所以，从这里就可以看出，**`dependencies` 只是一个先置条件，具体它是不是局部作用域，还得是你用的时候怎么用**。

同理依赖也是，比如你写了一个 `@Riverpod(dependencies: [maxCountProvider])` ，但是你还是需要对应写上  `ref.watch(maxCountProvider)` ，不然它也并不起作用：

```dart
@Riverpod(dependencies: [maxCountProvider])
int limitedCounter(LimitedCounterRef ref) {
  final max = ref.watch(maxCountProvider); // 监听 
  return 0.clamp(0, max); 
}
```

> PS ，如果你只是正常监听，不需要作用域的场景，其实直接写 `ref.watch` 而不需要 `dependencies: [maxCountProvider]` 也是可以的。

如果我们从输出端看，可以看到有没有 `dependencies` ，主要就是 `_dependencies` 和  `_allTransitiveDependencies` 是否为空的区别：

![](http://img.cdn.guoshuyu.cn/20250303_riverpod/image6.png)

## 注意事项

最后也有一些注意事项，例如：

- 通过注解生成的 Provider 好不要依赖非生成的 Provider，比如这里的 `example` 是注解，它监听了一个非注解生成的 `depProvider` ，这样并不规范：

  ```dart
  final depProvider = Provider((ref) => 0);
  
  @riverpod
  void example(Ref ref) {
    // Generated providers should not depend on non-generated providers
    ref.watch(depProvider);
  }
  ```

  

- 有作用域时，如果监听了某个 Provider ，那么 dependencies 里必须写上依赖 Provider，以下写法就不合规：

  ```dart
  @Riverpod(dependencies: [])
  void example(Ref ref) {
    // scopedProvider is used but not present in the list of dependencies
    ref.watch(scopedProvider);
  }
  ```

  

- Provider 里不应该接收 `BuildContext` ：

  ```dart
  // Providers should not receive a BuildContext as a parameter.
  @riverpod
  int fn(Ref ref, BuildContext context) => 0;
  
  @riverpod
  class MyNotifier extends _$MyNotifier {
    int build() => 0;
  
    // Notifiers should not have methods that receive a BuildContext as a parameter.
    void event(BuildContext context) {}
  }
  ```

其实类型的注意事项在 [riverpod_lint](https://github.com/rrousselGit/riverpod/tree/master/packages/riverpod_lint#provider_dependencies-riverpod_generator-only) 里都声明了，只是 Custom lint rules 不会直接展示在 dart analyze ，所以需要用户在添加完  [riverpod_lint](https://github.com/rrousselGit/riverpod/tree/master/packages/riverpod_lint#provider_dependencies-riverpod_generator-only)  后，执行对应的 `dart run custom_lint `：

![](http://img.cdn.guoshuyu.cn/20250303_riverpod/image7.png)



# 最后

可以看到，通过注解模式，riverpod 可以让开发者少些很多代码，在整体设计理念没有变化的情况下，模版生成的代码会更规范，并且在上层屏蔽了许多复杂度和工作量。

另外通过  `dependencies`  我们可以可以看到 riverpod **在存储管理上它是统一的，但是在组合上它是分散的**的设计理念。

而 Flutter 状态管理一直以来也是「是非之地」，比如近期就出现说 riverpod 在基准性能测试表示不如 signals 的情况，但是作者也回应了该测试属于「春秋笔法」之流：

![](http://img.cdn.guoshuyu.cn/20250303_riverpod/image8.png)

![](http://img.cdn.guoshuyu.cn/20250303_riverpod/image9.png)

另外，由于[Dart 宏功能推进暂停](https://juejin.cn/post/7464998185485877311) ，而 build runner 与数据类的优化还没落地，作者也在探索没有 codegen 下如何也可以便捷使用 riverpod ，比如让 family 支持多个参数：

![](http://img.cdn.guoshuyu.cn/20250303_riverpod/image10.png)

当然，从作者的维护体验上看，貌似作者又有停滞 codegen 的倾向，看起来左右摇摆的状态还会持续一段时间：

![](http://img.cdn.guoshuyu.cn/20250306_333/image1.png)

![](http://img.cdn.guoshuyu.cn/20250309_678/image1.png)

**那么， 2025 年 riverpod 还是你状态管理的首选吗**？


