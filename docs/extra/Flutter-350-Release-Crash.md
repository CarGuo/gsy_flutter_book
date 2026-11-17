---
title: "Flutter 3.50.0 Release 的第一个崩溃，修好了，还没 hotfix"
---

# Flutter 3.50.0 Release 的第一个崩溃，修好了，还没 hotfix

Flutter 3.50.0 刚发布就收获一个 P0，比如同一份代码在 Dart 3.13.5 可以编译，在 Dart 3.14.0 用 `dart run` 也完全正常，但只要执行 AOT 编译，`gen_snapshot` 就直接报 `linearscan.cc:3013: unreachable code`，原因是 **Dart 前端生成的控制流和后端的一项变量读取优化产生了“孽缘”，然后生成了不合法的编译器中间表示**。

出现问题的代码大概如下所示，其中 `Opt` 是只包含 `Query` 和 `Item` 两种子类型的 `sealed class`：

```dart
final Object value;
switch (opt) {
  case Query(:final text):
    print(text);
    return;
  case Item(value: final picked):
    value = picked;
}
run(() {
  committed = value;
});
```

你按源码看的话也没啥问题：`Query` 直接返回，`Item` 给 `value` 赋值后才进入闭包，然后两种情况已经覆盖 `Opt`，就不可能在没赋值的情况下执行最后的 `run`。

但 Dart CFE（Common Front End）把模式匹配的 `switch` 转成底层条件判断的时候，**就算最后一个 `Item` 分支在这里已经必然成立，还是相当“良心”的给你生成了一个 `if (opt is Item)`**，从后端看到的控制流图来说，就多出了一条“判断不是 Item，跳过赋值，继续往下执行”的路径。

![](/article-assets/d8c144d061a12f67384f7943.webp)

这条路径在 Dart 的 `sealed` 类型语义下不真的发生，但是编译器的中间表示里又留着，所以后端优化没办法直接假设它不存在，这个问题 Dart 团队也开了 [#64923](https://github.com/dart-lang/sdk/issues/64923) 跟进这个 CFE lowering 问题。

然后 Dart 3.14 之前有个  [`25ae146`](https://github.com/dart-lang/sdk/commit/25ae146f8414107c64581629433b8b64abfd0fae)  修改，原本是为了追踪 *effectively final* 变量，也就是初始化之后不会再改的变量，然后被闭包捕获的局部变量通常放在 Context 里，后面读取的时候可以再从 Context 取值，然后这次改动就是让不可变 Context 槽也可以直接复用初始化时写入的值，少一次内存读取，也就是所谓的 Store-to-Load Forwarding。

> 而在 AOT 模式下，像 `final Object value;` 这种声明时没赋值的非 `late final` 变量，也不需要先写一次 `null`。

**那问题来了，这个旧实现有个前提假设：只要找到了唯一的初始化写入，这次写入就一定发生在所有读取之前**。

然后对于上面的 `switch` 这个就假设失效了，因为在 CFE 生成的控制流图里，`picked` 只在 `Item` 分支定义，而那条多余的假路径可以绕开它，然后编译器把对被闭包捕获变量 `value` 的读取直接替换成 `picked`，结果出现了「用一个在当前路径上还没有定义的值」 的诡异情况。

> 其实这里对应的就是编译原理里的 **Dominance（支配关系）**：要把某个读取替换成一个值，必须确保到达读取位置的每条路径都已经定义了这个值，否则生成的 IL 就不合法。

然后这个 P0 很快就修复了，临时给 `LoadFieldInstr::Canonicalize()` 增加检查：

```cpp
Definition* value = initializing_store->value()->definition();
if (IsDominatedBy(value)) {
  return value;
}
```

**也就是只有当初始化的那个值能够支配当前读取，才可以把读取替换掉，如果不满足条件就保留原来的读取**。

>  所以这次临时修复保留了原来的性能优化，只补上正确性判断。

然后这个问题已经合并了，只是  Flutter 3.50.1 还没出来，不不过修复代码已经进 Dart Stable，也就是 Dart 3.14.1 应该马上就发了。

所以如果现在被这个 Bug 卡住，你临时改法是把变量定义和闭包使用放回同一个 `case`：

```dart
switch (opt) {
  case Query(:final text):
    print(text);
  case Item(value: final value):
    run(() {
      committed = value;
    });
    print(value);
}
```

**只能说，搞编译器的，最怕 AI 给你优化出来这种边角料**。
