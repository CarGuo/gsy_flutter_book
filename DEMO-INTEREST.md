本篇主要通过一个简单例子，讨论一下 Dart 代码里一个有趣的现象。

我们都知道 Dart 里一切都是对象，就连基础类型 `int` 、`double` 、`bool` 也都是 `class` 。

当我们对于 `int` 、 `double` 这些 `class` 进行的 `+` 、`-` 、`*` 、 `\` 等操作时，其实是执行了这个 `class` 的 `operator` 操作符的操作， 然后返回了新的 `num` 对象。

![](http://img.cdn.guoshuyu.cn/20211223_DEMO-INTEREST/image1)

对于这些 `operator` 操作最终会通过 `VM` 去进行实现返回，而本质上 dart 代码也只是文本，需要最终编译成二进制去运行。

![](http://img.cdn.guoshuyu.cn/20211223_DEMO-INTEREST/image2)

> **以下例子基于 dart 2.12.3 测试**

那这里想要讨论什么呢？

首先我们看一段代码，如下代码所示，可以看到：

- 首先我们定义了一个叫 `idx` 的 `int` 型参数；
- 然后在 `for` 循环里添加了三个 `InkWell` 可点击控件；
- 最后在 `onTap` 里面将 `idx` 打印出来；


```dart
class MyHomePage extends StatelessWidget {
  var images = ["RRR", "RRR", "RRR",];
  @override
  Widget build(BuildContext context) {
    List<Widget> contents = [];
    int idx = 0;
    for (var imgUrl in images) {
      contents.add(InkWell(
          onTap: () {
            print("######## $idx");
          },
          child: Container(
            height: 100,
            width: 100,
            color: Colors.red,
            child: Text(imgUrl),
          )));
      idx++;
    }
    return Scaffold(
      appBar: AppBar(),
      body: Center(
          child: Column(
        children: [
          ...contents,
        ],
      )));
  }
}

```

- 问题来了，**你觉得点击这三个 `InkWell` 打印出来的会是什么结果？**

- **答案是打印出来的都是 3。**

为什么呢？让我们看这段代码编译后的逻辑，如下所示代码，可以看到上述代码编译后， **`print` 函数里指向的永远是 `idx` 这个 `int*` 指针，当我们点击时，最终打印出来的都是最后的  `idx` 的值**。

```c++
    @#C475
    method build(fra2::BuildContext* context) → fra2::Widget* {
      core::List<fra2::Widget*>* contents = core::_GrowableList::•<fra2::Widget*>(0);
      core::int* idx = 0;
      {
        core::Iterator<core::String*>* :sync-for-iterator = this.{main::MyHomePage::images}.{core::Iterable::iterator};
        for (; :sync-for-iterator.{core::Iterator::moveNext}(); ) {
          core::String* imgUrl = :sync-for-iterator.{core::Iterator::current};
          {
            [@vm.call-site-attributes.metadata=receiverType:dart.core::List<library package:flutter/src/widgets/framework.dart::Widget*>*] contents.{core::List::add}(new ink5::InkWell::•(onTap: () → Null {
              core::print("######## ${idx}");
            }, child: new con7::Container::•(height: 100.0, width: 100.0, color: #C40086, $creationLocationd_0dea112b090073317d4: #C66610), $creationLocationd_0dea112b090073317d4: #C66614));
            idx = idx.{core::num::+}(1);
          }
        }
      }
```


**那如果我们需要打印出来的是每个 `InkWell` 自己的 `index` 呢？**

如下代码所示，我们在 for 循环里增加了一个 `index` 参数，把每次 `idx` 都赋值给 `index` ，这样点击打印出来的结果，就会是点击对应的 `index` 。


```dart
class MyHomePage extends StatelessWidget {
  var images = ["RRR", "RRR", "RRR",];
  @override
  Widget build(BuildContext context) {
    List<Widget> contents = [];
    int idx = 0;
    for (var imgUrl in images) {
      int index = idx;
      contents.add(InkWell(
          onTap: () {
            print("######## $index");
          },
          child: Container(
            height: 100,
            width: 100,
            color: Colors.red,
            child: Text(imgUrl),
          )));
      idx++;
    }
    return Scaffold(
      appBar: AppBar(),
      body: Center(
          child: Column(
        children: [
          ...contents,
        ],
      )));
  }
}

```

为什么呢？

让我们看新编译出来的代码，如下所示，可以看到对了 `core::int* index = idx;` 这段代码，然后回忆下前面所说的，**Dart 里基本类型都是对象，而  `operator` 操作符运算后返回新的对象。**


这样就等于用 `index` 把每次的操作到保存下来，而 `print` 打印的自然就是每次被保存下来的 `idx` 。


```c++
    @#C475
    method build(fra2::BuildContext* context) → fra2::Widget* {
      core::List<fra2::Widget*>* contents = core::_GrowableList::•<fra2::Widget*>(0);
      core::int* idx = 0;
      {
        core::Iterator<core::String*>* :sync-for-iterator = this.{main::MyHomePage::images}.{core::Iterable::iterator};
        for (; :sync-for-iterator.{core::Iterator::moveNext}(); ) {
          core::String* imgUrl = :sync-for-iterator.{core::Iterator::current};
          {
            core::int* index = idx;
            [@vm.call-site-attributes.metadata=receiverType:dart.core::List<library package:flutter/src/widgets/framework.dart::Widget*>*] contents.{core::List::add}(new ink5::InkWell::•(onTap: () → Null {
              core::print("######## ${index}");
            }, child: new con7::Container::•(height: 100.0, width: 100.0, color: #C40086, $creationLocationd_0dea112b090073317d4: #C66610), $creationLocationd_0dea112b090073317d4: #C66614));
            idx = idx.{core::num::+}(1);
          }
        }
      }
```

**那再来个不一样的写法**。

如下代码所示，把 `InkWell` 放到一个 `getItem` 函数里返回，然后 `index` 通过函数参数传递进来，可以看到运行后的结果，也是点击对应 `InkWell` 打印对应的 `index` 。


```dart
class MyHomePage extends StatelessWidget {
  var images = ["RRR", "RRR", "RRR",];
  @override
  Widget build(BuildContext context) {
    List<Widget> contents = [];
    int idx = 0;
    getItem(int index, String imgUrl) {
      return InkWell(
          onTap: () {
            print("######## $index");
          },
          child: Container(
            height: 100,
            width: 100,
            color: Colors.red,
            child: Text(imgUrl)));
    }
    for (var imgUrl in images) {
      contents.add(getItem(idx, imgUrl));
      idx++;
    }
    return Scaffold(
      appBar: AppBar(),
      body: Center(
          child: Column(
        children: [
          ...contents,
        ],
      )));
  }
}
```

为什么呢？

我们继续看编译后的代码，如下代码所示，其实就是每次的 `idx` 都通过 ` getItem.call(idx)` 被 `getItem` 的 `index` 引用，然后下次又再次传递一个对应的 `idx` 进去，原理其实和上面的情况一样，所以每次点击也会打印对应的 `index` 。


```c++
    @#C475
    method build(fra2::BuildContext* context) → fra2::Widget* {
      core::List<fra2::Widget*>* contents = core::_GrowableList::•<fra2::Widget*>(0);
      core::int* idx = 0;
      function getItem(core::int* index) → ink5::InkWell* {
        return new ink5::InkWell::•(onTap: () → Null {
          core::print("######## ${index}");
        }, child: new con7::Container::•(height: 100.0, width: 100.0, color: #C40086, $creationLocationd_0dea112b090073317d4: #C66610), $creationLocationd_0dea112b090073317d4: #C66614);
      }
      {
        core::Iterator<core::String*>* :sync-for-iterator = this.{main::MyHomePage::images}.{core::Iterable::iterator};
        for (; :sync-for-iterator.{core::Iterator::moveNext}(); ) {
          core::String* imgUrl = :sync-for-iterator.{core::Iterator::current};
          {
            [@vm.call-site-attributes.metadata=receiverType:dart.core::List<library package:flutter/src/widgets/framework.dart::Widget*>*] contents.{core::List::add}([@vm.call-site-attributes.metadata=receiverType:library package:flutter/src/material/ink_well.dart::InkWell* Function(dart.core::int*)*] getItem.call(idx));
            idx = idx.{core::num::+}(1);
          }
        }
      }
      
```

**最后我们再换种写法。**

如下代码所示，直接用最基本的 `for` 循环添加 `InkWell` 并打印 `idx` ，结果会怎么样呢？


```dart
class MyHomePage extends StatelessWidget {
  var images = [ "RRR","RRR", "RRR"];

  @override
  Widget build(BuildContext context) {
    List<Widget> contents = [];
    for (int idx = 0; idx < images.length; idx++) {
      contents.add(InkWell(
          onTap: () {
            print("######## $idx");
          },
          child: Container(
            height: 100,
            width: 100,
            color: Colors.red,
            child: Text(images[idx]),
          )));
    }
    return Scaffold(
        appBar: AppBar(),
        body: Center(
            child: Column(
          children: [
            ...contents,
          ],
        )));
  }
}
```

答案就是：**点击对应 `InkWell` 打印对应的 `index`**。

为什么呢？

我们继续看编译后的代码，可以看到都是打印的 `idx` ，为什么这样就可以正常呢？

**这里最大的不同就是`idx` 被声明的位置不同**。


```c++
    @#C475
    method build(fra2::BuildContext* context) → fra2::Widget* {
      core::List<fra2::Widget*>* contents = core::_GrowableList::•<fra2::Widget*>(0);
      for (core::int* idx = 0; idx.{core::num::<}(this.{main::MyHomePage::images}.{core::List::length}); idx = idx.{core::num::+}(1)) {
        [@vm.call-site-attributes.metadata=receiverType:dart.core::List<library package:flutter/src/widgets/framework.dart::Widget*>*] contents.{core::List::add}(new ink5::InkWell::•(onTap: () → Null {
          core::print("######## ${idx}");
        }, child: new con7::Container::•(height: 100.0, width: 100.0, color: #C40086, child: new text::Text::•(this.{main::MyHomePage::images}.{core::List::[]}(idx), $creationLocationd_0dea112b090073317d4: #C66607), $creationLocationd_0dea112b090073317d4: #C66613), $creationLocationd_0dea112b090073317d4: #C66617));
      }
```

那这时候我们重新调整下，**把 `idx` 放到 for 外面，点击测试会发现，打印的结果又都是 3**。


```
class MyHomePage extends StatelessWidget {
  var images = [ "RRR", "RRR","RRR"];

  @override
  Widget build(BuildContext context) {
    List<Widget> contents = [];
    int idx = 0;
    for (; idx < images.length; idx++) {
      contents.add(InkWell(
          onTap: () {
            print("######## $idx");
          },
          child: Container(
            height: 100,
            width: 100,
            color: Colors.red,
            child: Text(images[idx]),
          )));
    }
    return Scaffold(
        appBar: AppBar(),
        body: Center(
            child: Column(
          children: [
            ...contents,
          ],
        )));
  }
}
```

这是为什么呢？

看编译后的代码，唯一不同的就是 `core::int* idx` 的声明位置，那原因究竟是什么呢？

```c++
    @#C475
    method build(fra2::BuildContext* context) → fra2::Widget* {
      core::List<fra2::Widget*>* contents = core::_GrowableList::•<fra2::Widget*>(0);
      core::int* idx = 0;
      for (; idx.{core::num::<}(this.{main::MyHomePage::images}.{core::List::length}); idx = idx.{core::num::+}(1)) {
        [@vm.call-site-attributes.metadata=receiverType:dart.core::List<library package:flutter/src/widgets/framework.dart::Widget*>*] contents.{core::List::add}(new ink5::InkWell::•(onTap: () → Null {
          core::print("######## ${idx}");
        }, child: new con7::Container::•(height: 100.0, width: 100.0, color: #C40086, child: new text::Text::•(this.{main::MyHomePage::images}.{core::List::[]}(idx), $creationLocationd_0dea112b090073317d4: #C66607), $creationLocationd_0dea112b090073317d4: #C66613), $creationLocationd_0dea112b090073317d4: #C66617));
      }
```


因为 `onTap` 是在点击后才输出参数的，而对于 `for (core::int* idx = 0;` 来说，`idx` 的作用域是在 `for` 循环之内，所以编译后在 `onTap` 内要有对应持有一个值，来保存需要输出的结果。

而对于 `for` 循环外定义的 `core::int* idx` ， 循环内的所有 `onTap`  都可以指向它这个地址，所以导致点击时都输出了同一个 `idx` 的值。

至于为什么会有这样的逻辑，在深入的运行时逻辑就没有去探索了（懒），**推测应该是编译后的二进制文件在运行时，针对循环外的参数和循环内的参数优化有关系**。

理论上，应该是属于变量捕获:

* 对于全局变量，不会捕获，通过全局变量访问。
* 对于局部变量，自动变量将会捕获，且是值传递。



最后，如果你也想查看 `dill` 内容，可以通过 mac 下的 xxd 命令：

```
xxd /Users/xxxxxxx/workspace/flutter-wrok/flutter_app_test/.dart_tool/flutter_build/bf7ed8e7e7b3e64f28f0af8a89a29ca9/app.dill
```

也可以通过  `dump_kernel.dart` （在完整版 `dart-sdk` 的`/Users/guoshuyu/workspace/dart-sdk/pkg/vm` 目录下）执行如下命令，生成 `app.dill.txt` 查看，比如你可以查看 `final` 和 `const` 编译后的区别。

```
dart dump_kernel.dart /Users/xxxxxxx/workspace/flutter-wrok/flutter_app_test/.dart_tool/flutter_build/bf7ed8e7e7b3e64f28f0af8a89a29ca9/app.dill /Users/xxxxxxx/workspace/flutter-wrok/flutter_app_test/.dart_tool/flutter_build/bf7ed8e7e7b3e64f28f0af8a89a29ca9/app.dill.txt
```