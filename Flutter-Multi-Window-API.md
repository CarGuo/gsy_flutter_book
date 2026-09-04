# Flutter 多窗口支持类型和 API 介绍

这么多年了，官方终于正式把多窗口 API 单独拿出来说了，两年前 Canonical 开始负责 Flutter PC 端的开发和维护之后，多窗口也一直是它在推进，**目前的完成的设计主要围绕五种窗口类型展开 regular、dialog、tooltip、 popup 和 satellite 窗口**：

![](https://flutter.dev/assets/banner.df0bc5595c2e4e6809d9e828c1d43acd.gif)

其中普通的 Regular 常规窗口就不用说了，基本默认的多窗口下都会用到类似的窗口能力：

![](https://flutter.dev/assets/regular.87ef9745dace73b5ebf4b0d1aba0db51.gif)

其次是 Popup 窗口，Popup 主要提供类似独立窗口菜单的功能，属于子窗口，可以有输入焦点，用户可以通过方向键在下拉菜单里切换选中目标，另外还会内部还会强制要求 Popup  窗口保持可见，不会因为弹出位置导致窗口出现在屏幕之外被裁剪：

![](https://flutter.dev/assets/popup.b3aade54ebd547823ebbcfbce218e2e4.gif)

然后就是 Tooltip，它和于弹出窗口很类似，区别在于它们没有输入焦点，一般用来展示一些提示信息，比如当鼠标悬停在某个控件上时，就提示控件的作用：

![img](https://flutter.dev/assets/tooltip.06579f86a696fbcb798a0ee2e8396629.gif)

Dialog 也很常见，属于子窗口，分模态和非模态，当对话框通过模态方式显示在另一个窗口里面时， 对话框窗口关闭之前，窗口会禁止获得焦点。：

![](https://flutter.dev/assets/dialog.1caa0909badaac0a391edd43758d143b.gif)

Satellite 窗口也是月中很常见的辅助弹出框，它可以保持相对于父窗口的位置， 父窗口移动和调整大小时它们也会跟随变化， Satellite  还有具备对接能力，也就是它们可以从漂浮式 Satellite  窗口转到嵌入到主窗口内部：

![](https://flutter.dev/assets/satellite.ed178b92b9a794eade59f357b42d032a.gif)

> 而这里这些窗口类型目前都存在于一个窗口层级结构里，比如一个 App 可以在它 Root 里设置一个主窗口（普通窗口)，然后在它下面嵌套 Pop 窗口和 Dialog ，对话框内部还可以嵌套 ToolTip。

目前这些多窗口 API 已经在 master 可以用，我自己也用了一段时间，其实用 main 分支没什么不好的：

```sh
flutter channel main
flutter upgrade
flutter config --enable-windowing
```

配置后你就可以创建原生窗口，要创建一个窗口，我们首先需要创建一个 `WindowController`，这个 controller 主要和底层平台交互，用来创建和更新窗口：

```dart
final controller = WindowController(
  title: 'My Application',
  size: const Size(800, 600),
);
```


控制器会收到窗口的初始配置信息，比如窗口大小和标题等，然后每种窗口类型都有自己的窗口控制器，比如如果要创建一个对话框窗口：

```dart
final dialogController = DialogWindowController(
  title: 'My Dialog',
  size: const Size(400, 300),
  parent: parentController,
);
```

> 这里和普通窗口不同在于， `DialogWindowController` 有一个可选的父窗口控制器。

然后控制器创建完成后，就可以直接用于后续修改窗口，例如我们可以修改之前创建的常规窗口的标题、大小和销毁：

```dart
controller.setTitle('Hello, world!');
controller.setSize(const Size.square(1000));
controller.destroy();
```

然后就是渲染到窗口，这里需要同样需要将控制器和要渲染的内容传递给 `Window` 组件：

```dart
Widget build(BuildContext context) {
  return Window(
    controller: controller,
    child: MyPage(),
  );
}
```


每种窗口类型都有其对应的控件，比如：

- 对于普通窗口用 `Window` 控件
- 对于对话框窗口用 `DialogWindow` 控件

> 然后因为有窗口都位于同一个控件树，所以实际上可以做到跨窗口共享状态。

然后如果你需要在窗口监听事件，比如接受窗口关闭通知，目前有两种获取窗口状态的方式：通过 `WindowControllerDelegate` 或者  `WindowScope` ，比如：

```dart
// Create the class first...
class MyWindowDelegate with WindowControllerDelegate {
  @override
  void onWindowDestroyed() {
    super.onWindowDestroyed();
    ServicesBinding.instance.exitApplication(AppExitType.required);
  }
}

// and then pass it to the controller constructor.
final controller = WindowController(
  title: 'My Application',
  size: const Size(800, 600),
  delegate: MyWindowDelegate(),
);

```

另外通过  `WindowScope`  也可以做到类似监听，你可以通过  `WindowScope.of` 访问 Scope ，然后获取对应状态：

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = WindowScope.titleOf(context);
    // ... do something with the window title
  }
}
```

整个 Demo 大概类似：

```dart
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/widgets.dart';

/// Exits the application when the user closes the window.
class ExitOnCloseDelegate with WindowControllerDelegate {
  @override
  void onWindowCloseRequested(WindowController controller) {
    ServicesBinding.instance.exitApplication(AppExitType.required);
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runWidget(const HelloWindow());
}

/// Displays a window and owns its [WindowController].
class HelloWindow extends StatefulWidget {
  const HelloWindow({super.key});

  @override
  State<HelloWindow> createState() => _HelloWindowState();
}

class _HelloWindowState extends State<HelloWindow> {
  final WindowController _controller = WindowController(
    size: const Size(600, 400),
    title: 'MyApp',
    delegate: ExitOnCloseDelegate(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Window(
      controller: _controller,
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: Color(0xFFFFFFFF),
          child: Center(
            child: Text(
              'Hello, Window',
              style: TextStyle(color: Color(0xFF000000), fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }
}
```

 不过需要注意的是，多窗口现在用的不是 `runApp`，你需要用 `runWidget` 替代：

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runWidget(const MultiWindowApp());
}
```

总体来说，目前 Flutter 的多窗口从我的体验上已经可以直接用了，虽然有小问题，但是不会很影响主流程，至少 Window 和 macOS 上还行，Linux 我就没测试过了。

# 链接

https://flutter.dev/to/windowing-example

https://flutter.dev/blog/desktop-windowing-apis