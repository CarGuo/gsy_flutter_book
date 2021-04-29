本篇将带你深入了解 Flutter 中的手势事件传递、事件分发、事件冲突竞争，滑动流畅等等的原理，帮你构建一个完整的 Flutter 闭环手势知识体系，这也许是目前最全面的手势事件和滑动源码的深入文章了。

## 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)


Flutter 中默认情况下，以 Android 为例，所有的事件都是起原生源于 `io.flutter.view.FlutterView` 这个 `SurfaceView` 的子类，整个触摸手势事件实质上经历了 **JAVA => C++ => Dart** 的一个流程，整个流程如下图所示，无论是 Android 还是 IOS ，原生层都只是将所有事件打包下发，比如在 Android 中，手势信息被打包成 `ByteBuffer` 进行传递，最后在 Dart 层的 `_dispatchPointerDataPacket` 方法中，通过  `_unpackPointerDataPacket` 方法解析成可用的 `PointerDataPacket` 对象使用。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-13/image1)

**那么具体在 Flutter 中是如何分发使用手势事件的呢？**


## 1、事件流程

在前面的流程图中我们知道，在 Dart 层中手势事件都是从 `_dispatchPointerDataPacket` 开始的，之后会通过 `Zone` 判断环境回调，会执行 `GestureBinding` 这个胶水类中的 `_handlePointerEvent` 方法。*(如果对 `Zone` 或者 `GestureBinding` 有疑问可以翻阅前面的篇章)*


如下代码所示， `GestureBinding`  的 `_handlePointerEvent` 方法中主要是 `hitTest` 和 `dispatchEvent`： **通过  `hitTest` 碰撞，得到一个包含控件的待处理成员列表 `HitTestResult`，然后通过  `dispatchEvent` 分发事件并产生竞争，得到胜利者相应。**


```
  void _handlePointerEvent(PointerEvent event) {
    assert(!locked);
    HitTestResult hitTestResult;
    if (event is PointerDownEvent || event is PointerSignalEvent) {
      hitTestResult = HitTestResult();
      ///开始碰撞测试了，会添加各个控件，得到一个需要处理的控件成员列表
      hitTest(hitTestResult, event.position);
      if (event is PointerDownEvent) {
        _hitTests[event.pointer] = hitTestResult;
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      ///复用机制，抬起和取消，不用hitTest，移除
      hitTestResult = _hitTests.remove(event.pointer);
    } else if (event.down) {
      ///复用机制，手指处于滑动中，不用hitTest
      hitTestResult = _hitTests[event.pointer];
    }
    if (hitTestResult != null ||
        event is PointerHoverEvent ||
        event is PointerAddedEvent ||
        event is PointerRemovedEvent) {
      ///开始分发事件
      dispatchEvent(event, hitTestResult);
    }
  }
```

了解了结果后，接下来深入分析这两个关键方法：

#### 1.1 、hitTest

`hitTest` 方法主要为了得到一个 `HitTestResult` ，这个 `HitTestResult` 内有一个 `List<HitTestEntry>` 是用于分发和竞争事件的，而每个 `HitTestEntry.target` 都会存储每个控件的 `RenderObject` 。

因为 `RenderObject` 默认都实现了 `HitTestTarget` 接口，所以可以理解为： **`HitTestTarget` 大部分时候都是 `RenderObject` ，而 `HitTestResult` 就是一个带着碰撞测试后的控件列表。**

事实上 `hitTest` 是 `HitTestable` 抽象类的方法，而 Flutter 中所有实现 `HitTestable` 的类有 **`GestureBinding` 和 `RendererBinding`** ，它们都是 `mixins` 在 `WidgetsFlutterBinding` 这个入口类上，并且因为它们的 `mixins` 顺序的关系，所以 **`RendererBinding` 的 `hitTest` 会先被调用，之后才调用 `GestureBinding` 的 `hitTest` 。** 

那么这两个 hitTest 又分别干了什么事呢？

#### 1.2、RendererBinding.hitTest

在 `RendererBinding.hitTest` 中会执行 `renderView.hitTest(result, position: position);` ，如下代码所示，`renderView.hitTest` 方法内会执行 `child.hitTest` ，它将尝试将符合条件的 child 控件添加到 `HitTestResult` 里，最后把自己添加进去。

```
///RendererBinding

bool hitTest(HitTestResult result, { Offset position }) {
    if (child != null)
      child.hitTest(result, position: position);
    result.add(HitTestEntry(this));
    return true;
  }
```

而查看 `child.hitTest` 方法源码，如下所示，`RenderObjcet` 中的`hitTest` ，会通过 `_size.contains` 判断自己是否属于响应区域，确认响应后执行 `hitTestChildren` 和 `hitTestSelf` ，尝试添加下级的 child 和自己添加进去，这样的**递归就让我们自下而上的得到了一个 `HitTestResult` 的相应控件列表了，最底下的 Child 在最上面**。

```
  ///RenderObjcet
  
  bool hitTest(HitTestResult result, { @required Offset position }) {
    if (_size.contains(position)) {
      if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }
```

#### 1.3、GestureBinding.hitTest

最后 `GestureBinding.hitTest` 方法不过最后把 `GestureBinding` 自己也添加到 `HitTestResult` 里，最后因为后面我们的流程还会需要回到 `GestureBinding` 中去处理。

#### 1.4、dispatchEvent

`dispatchEvent` 中主要是对事件进行分发，并且通过上述添加进去的 `target.handleEvent` 处理事件，如下代码所示，在存在碰撞结果的时候，是会通过循环对每个控件内部的`handleEvent` 进行执行。

```
  @override // from HitTestDispatcher
  void dispatchEvent(PointerEvent event, HitTestResult hitTestResult) {
  	 ///如果没有碰撞结果，那么通过 `pointerRouter.route` 将事件分发到全局处理。
    if (hitTestResult == null) {
      try {
        pointerRouter.route(event);
      } catch (exception, stack) {
      return;
    }
    ///上面我们知道 HitTestEntry 中的 target 是一系自下而上的控件
    ///还有 renderView 和 GestureBinding
    ///循环执行每一个的 handleEvent 方法
    for (HitTestEntry entry in hitTestResult.path) {
      try {
        entry.target.handleEvent(event, entry);
      } catch (exception, stack) {
      }
    }
  }
```

事实上并不是所有的控件的 `RenderObject` 子类都会处理 `handleEvent` ，大部分时候，只有带有 `RenderPointerListener` (RenderObject) / `Listener` (Widget) 的才会处理 `handleEvent` 事件，并且从上述源码可以看出，**handleEvent 的执行是不会被拦截打断的。**

那么问题来了，如果同一个区域内有多个控件都实现了 `handleEvent` 时，那最后事件应该交给谁消耗呢？

更具体为一个场景问题就是：**比如一个列表页面内，存在上下滑动和 Item 点击时，Flutter 要怎么分配手势事件？** 这就涉及到事件的竞争了。

> **核心要来了，高能预警！！！**

## 2、事件竞争

Flutter 在设计事件竞争的时候，定义了一个很有趣的概念：**通过一个竞技场，各个控件参与竞争，直接胜利的或者活到最后的第一位，你就获胜得到了胜利。** 那么为了分析接下来的“战争”，我们需要先看几个概念：

- **`GestureRecognizer`** ：手势识别器基类，基本上 `RenderPointerListener` 中需要处理的手势事件，都会分发到它对应的 `GestureRecognizer`，并经过它处理和竞技后再分发出去，常见有 ：`OneSequenceGestureRecognizer` 、 `MultiTapGestureRecognizer` 、`VerticalDragGestureRecognizer` 、`TapGestureRecognizer` 等等。

- **`GestureArenaManagerr`** ：手势竞技管理，它管理了整个“战争”的过程，原则上竞技胜出的条件是 ：**第一个竞技获胜的成员或最后一个不被拒绝的成员。**

- **`GestureArenaEntry`** ：提供手势事件竞技信息的实体，内封装参与事件竞技的成员。

- **`GestureArenaMember`**：参与竞技的成员抽象对象，内部有 `acceptGesture` 和 `rejectGesture` 方法，它代表手势竞技的成员，默认 `GestureRecognizer` 都实现了它，**所有竞技的成员可以理解为就是 `GestureRecognizer` 之间的竞争。**

- **`_GestureArena`**：`GestureArenaManager` 内的竞技场，内部持参与竞技的 `members` 列表，官方对这个竞技场的解释是： **如果一个手势试图在竞技场开放时(isOpen=true)获胜，它将成为一个带有“渴望获胜”的属性的对象。当竞技场关闭(isOpen=false)时，竞技场将寻找一个“渴望获胜”的对象成为新的参与者，如果这时候刚好只有一个，那这一个参与者将成为这次竞技场胜利的青睐存在。** 

好了，知道这些概念之后我们开始分析流程，我们知道 `GestureBinding` 在 `dispatchEvent` 时会先判断是否有 `HitTestResult` 是否有结果，一般情况下是存在的，所以直接执行循环 `entry.target.handleEvent` 。

#### 2.1、PointerDownEvent

循环执行过程中，我们知道 `entry.target.handleEvent` 会触发`RenderPointerListener` 的 `handleEvent` ，而事件流程中第一个事件一般都会是 `PointerDownEvent`。

> `PointerDownEvent` 的流程在事件竞技流程中相当关键，因为它会触发 `GestureRecognizer.addPointer`。

**`GestureRecognizer` 只有通过 `addPointer` 方法将 `PointerDownEvent` 事件和自己绑定，并添加到  `GestureBinding`  的 `PointerRouter` 事件路由和 `GestureArenaManager` 事件竞技中，后续的事件这个控件的  `GestureRecognizer` 才能响应和参与竞争。**

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-13/image2)

> 事实上 **Down** 事件在 Flutter 中一般都是用来做添加判断的，如果存在竞争时，大部分时候是不会直接出结果的，而 **Move** 事件在不同 `GestureRecognizer` 中会表现不同，而 **UP** 事件之后，一般会强制得到一个结果。

所以我们知道了**事件在 `GestureBinding` 开始分发的时候，在 `PointerDownEvent` 时需要响应事件的 `GestureRecognizer` 们，会调用 `addPointer` 将自己添加到竞争中。之后流程中如果没有特殊情况，一般会执行到参与竞争成员列表的 last，也就是  `GestureBinding` 自己这个 handleEvent 。** 

如下代码所示，走到 `GestureBinding`  的 `handleEvent` ，在 Down 事件的流程中，一般 `pointerRouter.route` 不会怎么处理逻辑，然后就是 `gestureArena.close` 关闭竞技场了，尝试得到胜利者。

```
  @override // from HitTestTarget
  void handleEvent(PointerEvent event, HitTestEntry entry) {
  	 /// 导航事件去触发  `GestureRecognizer` 的 handleEvent
  	 /// 一般 PointerDownEvent 在 route 执行中不怎么处理。
    pointerRouter.route(event);
    
    ///gestureArena 就是 GestureArenaManager
    if (event is PointerDownEvent) {
    
    	///关闭这个 Down 事件的竞技，尝试得到胜利
      /// 如果没有的话就留到 MOVE 或者 UP。
      gestureArena.close(event.pointer);
      
    } else if (event is PointerUpEvent) {
    	///已经到 UP 了，强行得到结果。
      gestureArena.sweep(event.pointer);
      
    } else if (event is PointerSignalEvent) {
      pointerSignalResolver.resolve(event);
    }
  }
```

让我们看 `GestureArenaManager` 的 `close` 方法，下面代码我们可以看到，如果前面 Down 事件中没有通过 `addPointer` 添加成员到 `_arenas` 中，那会连参加的机会都没有，而进入 `_tryToResolveArena` 之后，**如果 `state.members.length == 1` ，说明只有一个成员了，那就不竞争了，直接它就是胜利者，直接响应后续所有事件。** 那么如果是多个的话，就需要后续的竞争了。

```
  void close(int pointer) {
  	/// 拿到我们上面 addPointer 时添加的成员封装
    final _GestureArena state = _arenas[pointer];
    if (state == null)
      return; // This arena either never existed or has been resolved.
    state.isOpen = false;
    ///开始打起来吧
    _tryToResolveArena(pointer, state);
  }
  
  void _tryToResolveArena(int pointer, _GestureArena state) {
    if (state.members.length == 1) {
      scheduleMicrotask(() => _resolveByDefault(pointer, state));
    } else if (state.members.isEmpty) {
      _arenas.remove(pointer);
    } else if (state.eagerWinner != null) {
      _resolveInFavorOf(pointer, state, state.eagerWinner);
    }
  }
```


#### 2.2 开始竞争

那竞争呢？接下来我们以 `TapGestureRecognizer` 为例子，如果控件区域内存在两个  `TapGestureRecognizer` ，那么在 `PointerDownEvent` 流程是不会产生胜利者的，这时候如果没有 MOVE 打断的话，**到了 UP 事件时，就会执行 ` gestureArena.sweep(event.pointer);` 强行选取一个。**

而选择的方式也是很简单，**就是 `state.members.first` ，从我们之前 `hitTest` 的结果上理解的话，就是控件树的最里面 Child 了。** 这样胜利的 member 会通过 `members.first.acceptGesture(pointer)` 回调到 `TapGestureRecognizer.acceptGesture` 中，**设置 `_wonArenaForPrimaryPointer` 为 ture 标志为胜利区域，然后执行
`_checkDown` 和 `_checkUp` 发出事件响应触发给这个控件。**

而这里有个有意思的就是 ，Down 流程的 `acceptGesture` 中的  `_checkUp` 因为没有 `_finalPosition` 此时是不会被执行的，**`_finalPosition` 会在 `handlePrimaryPointer` 方法中，获得`_finalPosition`  并判断 `_wonArenaForPrimaryPointer` 标志为，再次执行  `_checkUp` 才会成功。**

> `handlePrimaryPointer` 是在 UP 流程中 `pointerRouter.route` 触发 `TapGestureRecognizer` 的 `handleEvent` 触发的。

**那么问题来了，`_checkDown ` 和 `_checkUp ` 时在 UP 事件一次性被执行，那么如果我长按住的话，`_checkDown` 不是没办法正确回调了？**


当然不会，在 `TapGestureRecognizer` 中有一个  `didExceedDeadline` 的机制，在前面 Down 流程中，**在 `addPointer` 时  `TapGestureRecognizer` 会创建一个定时器**，这个定时器的时间时 ` kPressTimeout = 100毫秒` ，**如果我们长按住的话，就会等待到触发  `didExceedDeadline` 去执行 `_checkDown` 发出 `onTabDown` 事件了。**


> `_checkDown ` 执行发送过程中，会有一个标志为 `_sentTapDown` 判断是否已经发送过，如果发送过了也不会在重发，之后回到原本流程去竞争，手指抬起后得到胜利者相应，同时在 `_checkUp` 之后 `_sentTapDown`  标识为会被重置。

这也可以分析点击下的几种场景:

##### 普通按下：

- 1、区域内只有一个 `TapGestureRecognizer` ：Down 事件时直接在竞技场 `close` 时就得到竞出胜利者，调用 `acceptGesture` 执行 `_checkUp`，到 Up 事件的时候通过 `handlePrimaryPointer` 执行 `_checkUp`，结束。

- 2、区域内有多个 `TapGestureRecognizer` ：Down 事件时在竞技场 `close` 不会竞出胜利者，在 Up 事件的时候，会在 `route` 过程通过`handlePrimaryPointer` 设置好 `_finalPosition`，之后经过竞技场 `sweep` 选取排在第一个位置的为胜利者，调用 `acceptGesture`，执行 `_checkDown` 和 `_checkUp ` 。

##### 长按之后抬起：

1、区域内只有一个 `TapGestureRecognizer` ：除了 Down 事件是在  `didExceedDeadline` 时发出 `_checkDown ` 外其他和上面基本没区别。

- 2、区域内有多个 `TapGestureRecognizer` ：Down 事件时在竞技场 `close` 时不会竞出胜利者，但是会触发定时器 `didExceedDeadline`，先发出 `_checkDown`，之后再经过 `sweep` 选取第一个座位胜利者，调用 `acceptGesture`，触发 `_checkUp `

**那么问题又来了，你有没有疑问，如果有区域两个 `TapGestureRecognizer` ，长按的时候因为都触发了 `didExceedDeadline` 执行 `_checkDown ` 吗？**

答案是：会的！**因为定时器都触发了 `didExceedDeadline`，所以 `_checkDown ` 都会被执行，从而都发出了 `onTapDown` 事件。但是后续竞争后，只会执行一个 `_checkUp ` ，所有只会有一个控件响应  `onTap` 。**


##### 竞技失败：

**在竞技场竞争失败的成员会被移出竞技场，移除后就没办法参加后面事件的竞技了** ，比如 `TapGestureRecognizer` 在接受到 `PointerMoveEvent` 事件时就会直接 `rejected` , 并触发 `rejectGesture` ，之后定时器会被关闭，并且触发 `onTapCancel` ，然后重置标志位.

总结下：

**Down 事件时通过 `addPointer` 加入了 `GestureRecognizer` 竞技场的区域，在没移除的情况下，事件可以参加后续事件的竞技，在某个事件阶段移除的话，之后的事件序列也会无法接受。事件的竞争如果没有胜利者，在 UP 流程中会强制指定第一个为胜利者。**

#### 2.3 滑动事件

滑动事件也是需要在 Down 流程中  `addPointer` ，然后 MOVE 流程中，通过在 `PointerRouter.route` 之后执行 `DragGestureRecognizer.handleEvent` 。

![image.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-13/image3)

在 `PointerMoveEvent` 事件的 `DragGestureRecognizer.handleEvent` 里，会通过在 `_hasSufficientPendingDragDeltaToAccept `判断是否符合条件，如：

```
bool get _hasSufficientPendingDragDeltaToAccept => _pendingDragOffset.dy.abs() > kTouchSlop;
```

如果符合条件就直接执行 `resolve(GestureDisposition.accepted);` ，将流程回到竞技场里，然后执行 `acceptGesture` ，然后触发`onStart` 和 `onUpdate` 。

回到我们前面的上下滑动可点击列表，是不是很明确了：**如果是点击的话，没有产生 MOVE 事件，所以 `DragGestureRecognizer` 没有被接受，而Item 作为 Child 第一位，所以响应点击。如果有 MOVE 事件， `DragGestureRecognizer` 会被 `acceptGesture`，而点击 `GestureRecognizer` 会被移除事件竞争，也就没有后续 UP 事件了。**


那这个 `onUpdate` 是怎么让节目动起来的？

我们以 `ListView` 为例子，通过源码可以知道， `onUpdate` 最后会调用到 `Scrollable` 的 `_handleDragUpdate` ，这时候会执行 `Drag.update`。 

![image.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-13/image4)


通过源码我们知道  `ListView` 的 `Drag` 实现其实是 `ScrollDragController`, 它在 `Scrollable` 中是和 `ScrollPositionWithSingleContext` 关联的在一起的。那么 `ScrollPositionWithSingleContext` 又是什么？


`ScrollPositionWithSingleContext` 其实就是这个滑动的关键，它其实就是 `ScrollPosition` 的子类，而  `ScrollPosition` 又是 `ViewportOffset` 的子类，而 `ViewportOffset` 又是一个 `ChangeNotifier`，出现如下关系：

> 继承关系：**ScrollPositionWithSingleContext : ScrollPosition : ViewportOffset : ChangeNotifier**

所以 **ViewportOffset** 就是滑动的关键点。上面我们知道响应区域 `DragGestureRecognizer` 胜利之后执行 `Drag.update` ，最终会调用到 `ScrollPositionWithSingleContext` 的 `applyUserOffset`，导致内部确定位置的 `pixels` 发生改变，并执行父类 `ChangeNotifier ` 的方法`notifyListeners` 通知更新。


而在 `ListView` 内部 `RenderViewportBase` 中，这个 `ViewportOffset` 是通过 `_offset.addListener(markNeedsLayout);` 绑定的，so ，**触摸滑动导致 `Drag.update` ，最终会执行到 `RenderViewportBase` 中的 `markNeedsLayout` 触发页面更新。**


至于  `markNeedsLayout` 如何更新界面和滚动列表，这里暂不详细描述了，给个图感受下：

![image.png](http://img.cdn.guoshuyu.cn/20190604_Flutter-13/image5)



>自此，第十三篇终于结束了！(///▽///)

### 资源推荐

* 本文Demo ：https://github.com/CarGuo/state_manager_demo
* Github ： [https://github.com/CarGuo/](https://github.com/CarGuo)
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**

##### 完整开源项目推荐：

* [GSYGithubApp Flutter](https://github.com/CarGuo/GSYGithubAppFlutter ) 
* [GSYGithubApp React Native](https://github.com/CarGuo/GSYGithubApp ) 
* [GSYGithubAppWeex](https://github.com/CarGuo/GSYGithubAppWeex)



![我们还会再见吗？](http://img.cdn.guoshuyu.cn/20190604_Flutter-13/image6)




