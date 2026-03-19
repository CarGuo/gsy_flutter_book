# Flutter 3.41 iOS 键盘负优化：一个代码洁癖引发的负优化

「能正常跑的代码就尽量不要动」，这句话再一次证明了它的立场，实际上确实不少程序员都存在「代码洁癖」，喜欢对代码进行「清洗」和「重构」，但是优雅的背后，很多时候也伴随着看不见的坑在等着你。

> 你以为上一代的人为什么就偏要写的「那么蠢」？

回到正题，近日不少人在 [*#180842*](https://github.com/flutter/flutter/issues/180842) 中反馈，当 Flutter 升级后，点击带有 AutoFill 的输入框时，键盘会像“抽风”一样先弹起、收缩、再弹起：

![](https://img.cdn.guoshuyu.cn/ezgif-80583c2a7fd11bc6.gif)

这个咋一看好像也没什么问题，但是如果在  Flutter 3.38.7 的版本里，它的表现是这样的：

![](https://img.cdn.guoshuyu.cn/ezgif-831f8efa9f8dd1bd.gif)

这么一对比就可以很直观看出来，这是一个负优化，特别是对于刚升级的用户来说，这就显示很莫名其妙：

![](https://img.cdn.guoshuyu.cn/image-20260220224130313.png)

而从目前的情况来看，问题的来源是以下这个 PR ，它是一个用来修复 autofill 上下文清理的提交，在这个 commit 里，他对 `FlutterTextInputPlugin.mm` 进行重构，主要是**简化输入视图的生命周期管理**：

![](https://img.cdn.guoshuyu.cn/image-20260220224413390.png)

但是在这个过程里，它修改了 `removeFromSuperview` 的调用时机，看起来合理，是在清理无用 view，但问题在于**调用顺序** ：

![](https://img.cdn.guoshuyu.cn/image-20260220225531200.png)

在多输入框切换（A → B）时，Flutter 平台侧的调用顺序通常是：

```dart
TextInput.clearClient (A)
TextInput.setClient   (B)
```

也就是说：

- 旧字段先被 clear

- 紧接着新字段被 set

但是如果在 **clear 阶段**就把承载输入的 `_activeView` 从 view hierarchy 里 remove ，那么

- iOS 会认为“输入上下文结束”
- 系统可能触发键盘 dismiss 和高度重算
- 下一帧新字段 `becomeFirstResponder`
- 键盘又被拉起

对比 3.38 里，当时采用的是“懒清理”策略，即使输入客户端关闭，底层的原生视图（`activeView`）依然挂载在视图树上。

而 3.41 一旦 `clearTextInputClient` 被调用，就会立即执行 `removeFromSuperview` ，因为：

- 在 iOS 上，当系统检测到输入框支持自动填充（AutoFill）时，它会发送两次键盘显示通知，第一次是普通高度，第二次是加上“自动填充工具栏”后的高度

- 而在 iOS 准备计算第二次高度、弹出工具栏的微秒时间内，Flutter 执行了“清理逻辑”，强行把焦点所在的 `activeView` 删除了

- iOS 发现“焦点视图没了”，于是键盘收回；紧接着，Flutter 的下一个逻辑又激活了新视图，键盘再次弹出

而这个情况，在 iOS 18+ 之后的的输入栈 + AutoFill / Password suggestion UI 更敏感：

- 登录/密码场景下，系统会在键盘上方插入 suggestion 条
- 键盘 frame / safe area 会更频繁变化
- 中间态更容易被放大成视觉抖动

> 实际上述的修改，如果不是现在「马后炮」来看，正在体验里和逻辑上看，都不会觉得有什么问题。

而这就是导致键盘在屏幕内高低闪动的原因，**而实际上类似问题在  RN 上也出现过**：

![](https://img.cdn.guoshuyu.cn/image-20260220230142448.png)

因为无论是 Flutter 还是 RN，它们都不是“原生实时渲染”，而是通过一个中间层与 iOS 通讯，**所以 RN 也有过类似键盘高度计算等问题**， 不过 RN 上主要是 AutoFill UI + layout 竞态导致的问题。

而针对这个问题，造成问题的原作者也对此提交了新的修复 PR [#182661](https://github.com/flutter/flutter/pull/182661) ，在  `FlutterTextInputPlugin.mm`  引入了全新状态，不再直接 `removeFromSuperview`，而是标记一个 `_pendingInputViewRemoval = YES` ：

![](https://img.cdn.guoshuyu.cn/image-20260220230746866.png)

PR 的目的是将真正的移除动作推迟到 `hideTextInput` 阶段，也就是确保 `resignFirstResponder` 已经完成，从而对其原本的系统节奏。

可以看到，这原本也不是什么大改动，出发点也是好的，但是这种细节的边界情况，往往也是造成大问题的稻草，这种 Bug 对于用户来说，虽然不影响实际使用，但是在体验上确实是致命缺陷。

> 所以很多时候，你可能觉得为什么一些简单的修改，Flutter 整这么久都没合并或者提交，其实这就是一个典型例子，**谁能保证 feature 有被完整回归？说人话就是：我究竟要不要为这个东西的未来去背锅**？

所以，每个历史屎山代码，大多都有它存在的原因，单纯因为屎而屎的也有，但是更多时候，大家还是更倾向于屎上雕花，除非这一坨当初就是自己拉的，你还知道它臭在哪里。