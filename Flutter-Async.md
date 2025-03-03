#  Dart async/await 和 Kotlin suspend 有什么区别？顺带看看 Oppo ColorOS 上的 Flutter “彩蛋”

在之前闲聊的[《Kotlin 协程能够完全替代线程吗？》](https://juejin.cn/post/7455576220374368282)的内容里，有人提了这样的问题：*Dart async/await 和 Kotlin suspend 还有 JS 的异步有什么区别*？

![](http://img.cdn.guoshuyu.cn/20250104_Async/image1.png)

实际上不管是 async/await 还是 Kotlin suspend ，它们其实只是  syntactic sugar  ，也就是我们常说的语法糖，也就是**它们只是为了让内容更好理解，结构更加清晰的一种表达风格**，那么如果从「上层」意义上看，它们是没区别的，仅仅只是语法糖。

当然，如果你想说它们的实现是不是有什么特别之处，那这个倒是可以聊聊。

> 本篇就简单聊聊语法糖，最后顺便介绍下 Oppo ColorOS 上的 Flutter 

# Dart async/await 

大家都知道，在 Dart 上的  async/await ，它背后实际工作的还是我们熟知的 `Future` ，比如下面的 async/await 例子：

```dart
Future<int> doSomething() async {
  whatTF();

  var x = await someIntFuture();
  return godGG(x);
}
```

在实际工作上它应该等同这样的：

```dart
Future<int> foo() {
  whatTF();

  return someIntFuture.then((x) {
    return godGG(x);
  });
}
```

也就是其实 `await` 的背后应该是  `Future.then`  的逻辑，那它是如何变成 `Future.then` ？

在   `Future` 的实现  [future_impl.dart](https://github.com/dart-lang/sdk/blob/main/sdk/lib/async/future_impl.dart) 里我们可以看到，还有一个私有的 `_thenAwait`  用于实现 `await` 语法糖，它主要是注册了一个  `Future`  ，并和默认的 `then `一样创建一个 `_FutureListener` ：

![=](http://img.cdn.guoshuyu.cn/20250104_Async/image2.png)

稍微不同之处在于 `then `  会提前判断 onError 方式是否正常，而它的调用节点，则是在 Dart 的 [sdk/lib/_internal/vm/lib/async_patch.dart](https://github.com/dart-lang/sdk/blob/main/sdk/lib/_internal/vm/lib/async_patch.dart) 里，我们可以看到相关的异步实现逻辑：

![](http://img.cdn.guoshuyu.cn/20250104_Async/image3.png)

**这里的一开始的  `_createAsyncCallbacks`  才是处理注册 Zone 回调的地方**，另外  ` _await(Object? object)`  传入对象是一个  `Object?` ，因为**在 Dart 代码所有可见的类型，都是 `Object` 的子类型**，而所有函数类型都是 `Function` 的子类型，但  `Function`  函数也是一种 `Object` ：

```dart
int doSomeThing(){
   return 1;
}

void main() {
		///输出 true
    print('${doSomeThing is Object}');
}
```

>  更多类型介绍可见：https://juejin.cn/post/6968369768596242469

而如下代码所示，其实前面的 `then` 和 `thenAwait`  本质并没太多区别，也就是  `then`  和 `await`  的实现没什么不一样，看得到的 `stateThenAwait` 和 `stateThen`  / `stateThenOnerror`  差别，也只是体现在  stack_trace 的细微差异而已：

![](http://img.cdn.guoshuyu.cn/20250104_Async/image4.png)

![](http://img.cdn.guoshuyu.cn/20250104_Async/image5.png)

![](http://img.cdn.guoshuyu.cn/20250104_Async/image6.png)

![](http://img.cdn.guoshuyu.cn/20250104_Async/image7.png)

![](http://img.cdn.guoshuyu.cn/20250104_Async/image8.png)

咦，看到这里你是否好奇， `then` 和 `_thenAwait` 有个 `state`  ？为什么 `Future` 里会有 `state`  ，这就可以从前面提到的 stack_trace 说起：

运行时系统会使用  *awaiter stack trace* 来增强堆栈跟踪，每个 awaiter 都代表一个闭包或一个可挂起的  `async` 函数 ，而每个 awaiter 都是一对 `（closure， nextFrame）` ：

- 当这个 Awaiter 的 future 完成时，`closure`  会被调用
- 而 `next` 是一个对象，表示下一个 Awaiter ，就像是一个链表

![](http://img.cdn.guoshuyu.cn/20250104_Async/image9.png)

而从 Awaiter Stack Traces 的路径图上可以看出来，**整个流程里会有一个关键对象叫 `_SuspendState`**。

看到  `_SuspendState` ，是不是会想起 Kotlin 的 suspend ？没错，它就是在 Dart 内部负责异步挂起的状态机：

![](http://img.cdn.guoshuyu.cn/20250104_Async/image10.png)

抽象一点的说法：

- `_SuspendState._initAsync`  会创建一个 `_Future<T>` 实例，而实例会用作 async 函数的结果，并且 `_Future<T>` 实例将保留在 vm c++ 的 `:suspend_state` 变量里

- 之后从  `_SuspendState._await` 返回， `_SuspendState._returnAsync` 、`_SuspendState._returnAsyncNotFuture` 和  `_SuspendState._handleException` 方法会作为 async 函数的结果。

- 而 `_SuspendState._await` 在首次调用时会分配 `then` 和 `error'`回调闭包，这些回调闭包会通过 _resume 来恢复异步函数的执行，如果 `await` 的参数是 `Future`，则 `_SuspendState._await` 会将 `then'`和 `error` 回调附加到该 Future 上，否则就直接安排一个 micro task 去继续执行 suspended 的函数

说人话，那就是在前面介绍过的  [sdk/lib/_internal/vm/lib/async_patch.dart](https://github.com/dart-lang/sdk/blob/main/sdk/lib/_internal/vm/lib/async_patch.dart) 里面，`_SuspendState._await` 这个函数，就是它实现了  `await`  表达式：

![](http://img.cdn.guoshuyu.cn/20250104_Async/image11.png)

另外对应处理异常的部份也是在 ` _SuspendState` 的  `_handleException` ，可以看出来，**整个 async/await 的 Future 实现，都是通过 ` _SuspendState`   的状态机链表来实现支持挂起和恢复**。

![](http://img.cdn.guoshuyu.cn/20250104_Async/image12.png)

**而如果再解释 async/await 语法糖实现，简单说就是 `Future` / `then`** ，其实工作起来，Dart 会将其转换为状态机，用于管理函数在 `await` 的执行和挂起，只是语法糖让我们可以用同步样式去编写异步代码，从而提高了代码的可读性。

# Kotlin Suspend

那在 Kotlin 里，suspend 函数也是可以暂停和恢复的函数，它不会阻塞正在运行它的线程，也是作为语法糖，让开发者可以通过同步样式去编写异步代码。

>  添加 suspend 关键字，其实就是告诉编译器这个函数可以被挂起。

当 Kotlin 编译器处理  `suspend`  函数时，它同样需要转换为对应的内部实现，一般称之为 **CPS**，关键在于 **continuation**  ， continuation 保存保留函数的状态、局部变量和执行上下文等等。

>  continuation 一般会保留对调用方 continuation 的引用，**因此它们会形成类似一个 continuation 链，同样可以用于生成堆栈跟踪**。

比如简单的说，就是   `suspend` 函数被重写为接受 `Continuation` 参数的一个过程：

```kotlin
suspend fun getUser(): User?
suspend fun setUser(user: User)
suspend fun checkAvailability(flight: Flight): Boolean


fun getUser(continuation: Continuation<*>): Any?
fun setUser(user: User, continuation: Continuation<*>): Any
fun checkAvailability(
flight: Flight,
continuation: Continuation<*>): Any

```

实际上，大概类似：

```kotlin
////转换前
suspend fun fetchData(): String {
    println("Start fetching data")
    val result = networkRequest()
    println("Data fetched: $result")
    return result
}
suspend fun networkRequest(): String {
    delay(1000) 
    return "Hello, World!"
}


////转换后
fun fetchData(completion: Continuation<String>): Any {
    class FetchDataContinuation(
        private val completion: Continuation<String>
    ) : Continuation<Any> {
        var label = 0
        lateinit var result: String
       override val context = EmptyCoroutineContext
        override fun resumeWith(data: Result<Any>) {
            try {
                when (label) {
                    0 -> {
                        println("Start fetching data")
                        label = 1
                        val networkResult = networkRequest(this)
                        if (networkResult == COROUTINE_SUSPENDED) return
                    }
                    1 -> {
                        result = data.getOrThrow() as String
                        println("Data fetched: $result")
                        completion.resumeWith(Result.success(result))
                    }
                }
            } catch (e: Exception) {
                completion.resumeWith(Result.failure(e))
            }
        }
    }
    val continuation = FetchDataContinuation(completion)
    continuation.resumeWith(Result.success(Unit))
    return continuation
}

fun networkRequest(continuation: Continuation<String>): Any {
    Timer().schedule(object : TimerTask() {
        override fun run() {
            continuation.resumeWith(Result.success("Hello, World!"))
        }
    }, 1000)
    return COROUTINE_SUSPENDED
}

```

可以看到， **Kotlin 编译器会为 suspend 函数生成类似状态机概念**，状态机会跟踪函数的执行状态，例如通过 `label` 来跟踪恢复的位置。

所以，在设计上，Kotlin 的 suspend  也是状态机转换和延续传递的组合，从而实现允许挂起暂停和恢复的设计模式。

# 结论

那么，**但从语法糖的实现上看，其实大家还是很类似的，都是链表传递、状态机、保存上下文和执行环境等，最终的目标就是：实现一个同步方式编写异步代码的效果**。

当然，如果你从背后线程模型上去区分，那么又是很大的差别，毕竟：

- Kotlin 在 JVM 上的协程是真的多线程模式，并且支持跨线程调度切换
- Dart 的协程是单线程轮询模式，而多线程的 isolate 和 Thread 也不是绝对一一对应关系

# OPPO ColorOS

最后简单扯的题外话，昨天刚好看到  Alex 大佬在群里分享的 ColorOS 灵动岛在运行时的输出截图，可以看到此时 ColorOS 灵动岛的 UI 渲染是基于 Flutter 实现的：

![](http://img.cdn.guoshuyu.cn/20250104_Async/image13.png)

而其实早期在 [OPPO 的开发平台](https://open.oppomobile.com/new/developmentDoc/info?id=12639) 也看到过负一屏相关的 log 截图，当时其实也可以看到，相关输出也是 Flutter ：

![](http://img.cdn.guoshuyu.cn/20250104_Async/image14.png)

只是说它们上层或者并不是采用 Dart 开发，而是通过自己的定制模版来实现支持，这其实和微信小程序的 skyline 也是异曲同工：

![](http://img.cdn.guoshuyu.cn/20250104_Async/image15.png)

所以，这也是 Flutter 更不为人知的另一面。



# 参考资料

- https://open.oppomobile.com/new/developmentDoc/info?id=12639

- https://github.com/dart-lang/sdk/blob/main/runtime/docs/async.md

- https://medium.com/kotlin-android-chronicle/explaining-how-suspend-works-in-kotlin-with-code-examples-256d7861c315







