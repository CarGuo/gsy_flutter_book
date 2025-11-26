# Flutter Riverpod  3.0 发布，大规模重构下的全新状态管理框架

在之前的 [《注解模式下的 Riverpod 有什么特别之处》](https://juejin.cn/post/7479474972849143844)我们聊过 Riverpod 2.x 的设计和使用原理，同时当时我们就聊到作者已经在开始探索 3.0 的重构方式，而现在随着 Riverpod 3.0  的发布，riverpod 带来了许多细节性的变化。

> 当然，这也带来了需要使用方式上的变动。

废话不多说，首先 Riverpod 3.0 与 2.0 的对比，新增还的功能有：

- **自动重试失败的 Provider:** 这是 3.0 的一个核心特性，当一个 Provider 出现计算失败时（如网络错误导致），Riverpod 不会立刻报错，而是自动尝试重新计算，从而让对短暂性错误有更强的恢复能力
- **暂停/恢复支持:** 当一个 Widget 不在屏幕上时，与之关联的 Provider 监听器现在会自动暂停
- **离线和变更 (Mutation) 支持 (实验性):** Riverpod 3.0 引入了对离线数据缓存和 “mutation” 操作的实验性支持，让处理数据持久化和异步操作（如表单提交）变得更加容易
- **简化的 API:** 通过合并 `AutoDisposeNotifier` 和 `Notifier` 等接口，API 变得更加统一和简洁

同时 3.0 也引入了一些破坏性改动：

- **传统 Provider 的迁移:** `StateProvider`, `StateNotifierProvider` 和 `ChangeNotifierProvider` 这些在 3.0 属于“传统”API ，它们虽然没有被移除，但都被移至一个新的 `legacy` 导入路径下，推荐开发者使用新的 `Notifier` API
- **统一使用 `==` 进行更新过滤:** 在 3.0 版本所有的 Provider 都使用 `==` (相等性) 而非 `identical` 来判断状态是否发生变化，从而决定是否需要重建
- **简化的 `Ref` 和移除的子类:** `Ref` 不再有泛型参数，并且像 `ProviderRef.state` 和 `Ref.listenSelf` 这样的属性和方法都被移至 `Notifier` ，同时所有 `Ref` 的子类（如 `FutureProviderRef`）都已被移除，现在可以直接使用 `Ref`
- **移除 `AutoDispose` 接口:** 自动释放功能被简化，不再需要独立的 `AutoDisposeProvider`, `AutoDisposeNotifier` 等接口，现在所有 Provider 都可以是 `auto-dispose` 
- **`ProviderObserver` 接口变更:** `ProviderObserver` 的方法签名发生了变化，现在传递的是一个 `ProviderObserverContext` 对象，其中包含了 `ProviderContainer` 和 `ProviderBase` 等信息

> 下面我们详细讲解这些变化。

## 自动重试失败的 Provider

在 Riverpod 3.0 中，Provider 现在默认会自动重试失败的计算，这意味着如果一个 Provider 因为网络波动、服务暂时不可用等瞬时错误而构建失败，它不会立即报错，而是会**自动尝试重新计算，直到成功为止**。

**这个功能是默认开启的，我相信你第一想法就是我不需要**，在某些情况下你可能希望禁用或自定义重试逻辑：

- **全局禁用/自定义:** 你可以在 `ProviderScope` 或 `ProviderContainer` 的顶层进行全局配置，通过设置 `retry` 参数，可以精细地控制重试逻辑，例如根据错误类型或重试次数来决定是否继续重试，以及重试的间隔时间：

  

  ```dart
  void main() {
    runApp(
      ProviderScope(
        // 全局禁用自动重试
        retry: (retryCount, error) => null,
        child: MyApp(),
      ),
    );
  }
  ```

- **针对特定 Provider 禁用/自定义:** 可以在定义单个 Provider 时，通过其 `retry` 参数进行独立的配置：

  ```dart
  @Riverpod(retry: retry)
  class TodoList extends _$TodoList {
    // 从不重试这个特定的 provider
    static Duration? retry(int retryCount, Object error) => null;
  
    @override
    List<Todo> build() => [];
  }
  ```

## 暂停/恢复支持

为了优化资源使用，Riverpod 3.0 引入了暂停/恢复机制。当一个 Widget（及其关联的 Provider 监听器）不在屏幕上时，监听器会**自动暂停，这个行为是默认启用的，并且看起来不支持全局关闭**，你可以通过 Flutter 的 `TickerMode` 来手动控制监听器的暂停行为：

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: false, // 这会暂停监听器
      child: Consumer(
        builder: (context, ref, child) {
          // 这个 "watch" 将会暂停
          // 直到 TickerMode 设置为 true
          final value = ref.watch(myProvider);
        
          return Text(value.toString());
        },
      ),
    );
  }
}
```

![](https://img.cdn.guoshuyu.cn/image-20250911160357872.png)

## 离线和变更 (Mutation) 支持 (实验性)

Riverpod 3.0 引入了两个实验性功能：

- **离线支持:** 允许你轻松地将 Provider 的状态持久化，以便在应用重启或离线时恢复
- **变更 (Mutation) 支持:** 提供了一种结构化的方式来处理异步操作，例如用户登录、提交表单或任何会改变应用状态的动作

```dart
// A mutation to track the "add todo" operation.
// The generic type is optional and can be specified to enable the UI to interact
// with the result of the mutation.
final addTodo = Mutation<Todo>();

 // We listen to the current state of the "addTodo" mutation.
 // Listening to this will not perform any side effects by itself.
 final addTodoState = ref.watch(addTodo);


switch (addTodoState) {
  case MutationIdle():
  // Show a button to add a todo
  case MutationPending():
  // Show a loading indicator
  case MutationError():
  // Show an error message
  case MutationSuccess():
  // Show the created todo
}
```



##  API 变动

Riverpod 3.0 对其核心 API 进行了大幅简化和统一，具体有：

### 1、合并 AutoDispose 接口

在之前的版本中，有大量带有 `AutoDispose` 前缀的接口，如 `AutoDisposeProvider`、`AutoDisposeNotifier` ，而在 3.0 中这些接口被统一了，现在，你只需要使用 `Provider`、`Notifier` 等核心接口：

```dart
//**V2.0:**
// 使用 .autoDispose 修饰符
final myProvider = Provider.autoDispose((ref) {
  return MyObject();
});

//**V3.0:**
// 1. 对于手写 Provider
final myProvider = Provider(
  (ref) => MyObject(),
  isAutoDispose: true, // 使用 isAutoDispose 参数
);

// 2. 对于代码生成的 Provider
@Riverpod(keepAlive: false) // keepAlive: false 是默认行为，等同于 autoDispose
int myProvider(MyProviderRef ref) {
  return 0;
}
```

### 2、移除 FamilyNotifier 变体

 类似于 `AutoDispose` 的简化，`FamilyNotifier`、`FamilyAsyncNotifier` 等家族变体也被移除了，现在你只需要使用 `Notifier`、`AsyncNotifier` 等核心 `Notifier`，并通过构造函数来传递参数

```diff
final provider = NotifierProvider.family<CounterNotifier, int, String>(CounterNotifier.new);

-class CounterNotifier extends FamilyNotifier<int, String> {
+class CounterNotifier extends Notifier<int> {
+  CounterNotifier(this.arg);
+  final String arg;

  @override
-  int build(String arg) {
+  int build() {
     // 在这里使用 `arg`
      return 0;
  }
}
```

### 3、 Provider  变动

统一在 Riverpod 3.0 中，`StateProvider`, `StateNotifierProvider`, 和 `ChangeNotifierProvider` 被归类为“传统（legacy）”API，这新的 `Notifier` API 更加灵活、功能更强大，并且与代码生成（code generation）的结合更紧密，可以显著减少样板代码，现在推荐使用：

- **`Notifier`**: 用于替换 `StateNotifierProvider`，管理同步状态，它是一个可以被监听的类，并且可以定义自己的公共方法来修改状态。
- **`AsyncNotifier`**: 用于替换处理异步操作的 `StateNotifierProvider` 或 `FutureProvider`，它专门用于管理异步状态（如从网络获取数据），并内置了对加载、数据和错误状态的处理
- **`StreamNotifier`**: 用于替代 `StreamProvider`

**V2.0 :**

```dart
import 'package:flutter_riverpod/legacy.dart'; // 需要使用 legacy 导入

// Before:
final valueProvider = FutureProvider<int>((ref) async {
  ref.listen(anotherProvider, (previous, next) {
    ref.state++;
  });
  
  ref.listenSelf((previous, next) {
    print('Log: $previous -> $next');
  });
  
  ref.future.then((value) {
    print('Future: $value');
  });

  return 0;
});
```

**V3.0 (新的 Notifier API):**

```dart
// After
class Value extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    ref.listen(anotherProvider, (previous, next) {
      ref.state++;
    });
  
    listenSelf((previous, next) {
      print('Log: $previous -> $next');
    });
  
    future.then((value) {
      print('Future: $value');
    });
  
    return 0;
  }
}
final valueProvider = AsyncNotifierProvider<Value, int>(Value.new);
```

> 可以看到，如果用的是 2.x 的注解，其实并不需要变动什么。

所以，**现在推荐的 API 是 `Notifier` 和 `AsyncNotifier`**，它们是基于类的 Provider，其原理是将**状态的定义 (`build` 方法)** 和 **修改状态的方法** 封装在同一个类中，目的在于：

- **逻辑内聚：** 与特定状态相关的所有代码都在一个地方，易于管理
- **代码更简洁：** 结合代码生成，你只需要定义一个类，Provider 会被自动创建
- **类型安全：** 你可以定义强类型的公共方法来修改状态，而不是直接暴露状态对象本身

### 4、统一使用  ==  进行更新过滤

这个改动统一了 Provider 的行为：

- **`identical`**:  之前它检查两个引用是否指向**同一个内存地址**，两个内容完全相同的不同对象，`identical` 会返回 `false`
- **`==` (相等性)**: 现在检查两个对象是否相等，对于自定义类，你可以重写 `==` 操作符来定义相等的标准（例如，如果两个 `User` 对象的 `id` 相同，则认为它们相等）

具体是，在 V2.0 中某些 Provider（如 `Provider`）使用 `identical` 来判断状态是否变化，而另一些则使用 `==`，这意味着，即使你提供了一个内容相同但实例不同的新对象，前者也不会通知监听者更新，因为它认为对象“没有变化”。

在 V3.0 中，**所有 Provider 都默认使用 `==` 来比较新旧状态**，如果新旧状态通过 `==` 比较后结果为 `true`，则不会通知监听者进行重建

举个例子，假设你有一个 `User` 类，并且你已经重写了 `==` 操作符：

```dart
class User {
  final String name;
  User(this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode
}
```

现在，有一个 Provider 返回 `User` 对象：

```dart
final userProvider = Provider((ref) => User('John'));
```

在某个操作后，你让这个 Provider 返回了一个**新的** `User` 实例，但 `name` 属性仍然是 'John'：

- **V2.0 (使用 `identical`)**: 由于新旧 `User` 对象是不同的实例（内存地址不同），`identical` 会返回 `false`，UI 会重建。
- **V3.0 (使用 `==`)**: 由于我们重写了 `==`，只要 `name` 相同，`user1 == user2` 就会返回 `true`。因此，Riverpod 会认为状态**没有变化**，UI **不会**重建，从而避免了不必要的刷新。

> 另外，如果你需要自定义这种行为，可以在你的 `Notifier` 中重写 `updateShouldNotify` 方法。

### 5、 简化的 Ref  和移除的子类

这个改动的核心目的是**简化 AP和提升类型安全**，保证API 更统一，因为以前根据 Provider 类型的不同（如 `Provider` vs `FutureProvider`），`ref` 的类型也不同（`ProviderRef` vs `FutureProviderRef`），它们各自有不同的属性（例如 `FutureProviderRef` 有一个 `.future` 属性），这增加了学习成本，而现在**所有 `ref` 都是同一个 `Ref` 类型**，API 更加一致：

**V2.0:**

```dart
// 使用 .autoDispose 修饰符
final myProvider = Provider.autoDispose((ref) {
  return MyObject();
});
```

**V3.0:**

```dart
// 1. 对于手写 Provider
final myProvider = Provider(
  (ref) => MyObject(),
  isAutoDispose: true, // 使用 isAutoDispose 参数
);

// 2. 对于代码生成的 Provider
@Riverpod(keepAlive: false) // keepAlive: false 是默认行为，等同于 autoDispose
int myProvider(MyProviderRef ref) {
  return 0;
}
```

> 类似改动让 API 更加统一，你不需要再记忆两套不同的 Provider 名称，同时**职责更清晰**，像 `ref.state` 或 `ref.listenSelf` 这样的操作，本质上是与**状态本身**的管理相关的，将这些功能移入 `Notifier` 类，让 `Notifier` 成为状态和其业务逻辑的唯一管理者，而 `ref` 则专注于依赖注入（读取其他 providers）。

例如你需要在一个 Provider 内部监听自身状态的变化来执行某些副作用（比如日志记录）:

**V2.0:**

```dart
final myProvider = FutureProvider<int>((ref) {
  // 使用 ref.listenSelf 监听自身状态变化
  ref.listenSelf((previous, next) {
    print('Value changed from $previous to $next');
  });
  return Future.value(0);
});
```

**V3.0:**

```dart
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  Future<int> build() async {
    // listenSelf 现在是 Notifier 的一个方法
    listenSelf((previous, next) {
      print('Value changed from $previous to $next');
    });
    return 0;
  }
}
```

可以看到，在 V3.0 中，`listenSelf` 成为了 `MyNotifier` 类的一部分，代码的组织结构更加清晰，或者假设你想在一个 Provider 内部，每当其状态更新时，就将新状态持久化到本地存储：

**V2.0 (使用 `ref.listenSelf`):**

```dart
final counterProvider = FutureProvider<int>((ref) async {
  // 在 Provider 内部监听自身
  ref.listenSelf((previous, next) {
    if (next.hasValue) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('counter', next.value!);
      });
    }
  });
  
  // 返回初始值
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('counter') ?? 0;
});
```

**V3.0 (使用 `Notifier.listenSelf`):**

```dart
@riverpod
class Counter extends _$Counter {
  @override
  Future<int> build() async {
    // listenSelf 现在是 Notifier 的一个方法
    listenSelf((previous, next) {
      if (next.hasValue) {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setInt('counter', next.value!);
        });
      }
    });
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('counter') ?? 0;
  }

  void increment() async {
    state = AsyncData((state.value ?? 0) + 1);
  }
}
```

可以看到，在 V3.0 中逻辑更加内聚，`Counter` 类不仅负责创建状态，还负责处理与该状态相关的副作用，代码的可读性和维护性更高。

### 6、 ProviderObserver 接口变更

`ProviderObserver` 是一个用于监听应用中所有 Provider 变化的强大工具，常用于日志记录或调试，在 V3.0 中它的接口发生了变化：

> 以前 `ProviderObserver` 的方法会接收 `provider`、`value` 和 `container` 等多个独立的参数，现在这些参数被统一封装在一个 `ProviderObserverContext` 对象。

**V2.0:**

```dart
class MyObserver extends ProviderObserver {
  @override
  void didAddProvider(
    ProviderBase provider,
    Object? value,
    ProviderContainer container,
  ) {
    print('Provider ${provider.name ?? provider.runtimeType} was created');
  }
}
```

**V3.0:**

```diff
class MyObserver extends ProviderObserver {
  @override
-  void didAddProvider(ProviderBase provider, Object? value, ProviderContainer container) {
+  void didAddProvider(ProviderObserverContext context, Object? value) {
-    print('Provider ${provider.name ?? provider.runtimeType} was created');
+    print('Provider ${context.provider.name ?? context.provider.runtimeType} was created');
  }
}
```

**最后，注解模式并没有被抛弃，而是得到了进一步加强，如果是在 2.x 版本使用了注解模式，那么你的迁移成本会更低，例如**：

```dart
// Before:
@riverpod
Future<int> value(ValueRef ref) async {
  ref.listen(anotherProvider, (previous, next) {
    ref.state++;
  });
  
  ref.listenSelf((previous, next) {
    print('Log: $previous -> $next');
  });
  
  ref.future.then((value) {
    print('Future: $value');
  });

  return 0;
}

// After
@riverpod
class Value extends _$Value {
  @override
  Future<int> build() async {
    ref.listen(anotherProvider, (previous, next) {
      ref.state++;
    });
  
    listenSelf((previous, next) {
      print('Log: $previous -> $next');
    });
  
    future.then((value) {
      print('Future: $value');
    });
  
    return 0;
  }
}
```

整体来看， Riverpod 3.0 的重构主要围绕：

- **简化 API**  ，例如移除 `AutoDispose` 和 `Family` 的各种变体，统一 `Ref` 的类型，通过更少的、功能更强大的构建块来替代大量专用但零散的 API

- **提升一致性** ，通过统一内部行为，让对应 Provider 的表现更加可预测，例如统一使用 `==` 进行更新过滤，确保了无论使用哪种 Provider，对应的重建逻辑都是一致
- **增强功能** ，在不增加复杂度的前提下，引入如自动重试、离线缓存和 Mutation (变更) 支持

**那么，你喜欢 Riverpod 3.0 吗**？

# 参考链接

- https://riverpod.dev/docs/3.0_migration