

# Flutter 从 TextField  安全泄漏问题深入探索文本输入流程

Flutter  的 `TextField`  相信大家都很熟悉，作为输入控件 `TextField` 经常出现在需要登录的场景，例如在需要输入密码的 `TextField`   上配置 `obscureText: true` ，这时候就会如下图所示，输入框呈现加密显示的状态。

![](http://img.cdn.guoshuyu.cn/20220627_Flutter-TL/image1)

而在登录成功之后，登录页面一般都会随之被销毁，连带着用户的账号和密码数据也应该会被回收，但是事实上有被回收吗？



## 一、CWE-316 

事实上如果你使用  `TextField`  作用密码输入框，这时候你很可能会在**安全合规**中遇到类似 CWE-316 的警告，主要原因在于：**Flutter 在进行文本输入时，和原生平台通信过程中，会有明文的文本内容残留**。

复现这个问题很简单，首先我们需要一个能够读取 App 运行时内存数据的工具，这里推荐使用 [apk-medit](https://github.com/aktsk/apk-medit) ，具体使用流程为：

- 下载 [apk-medit](https://github.com/aktsk/apk-medit/releases/) 的压缩包，解压得到  `medit` 可执行文件；
-  usb 调试链接上手机，无需 root ，执行 `adb push medit /data/local/tmp/medit` 将可执行文件传输到手机上；
- 执行 `adb shell` 进入手机命令后模式；
- 执行 `run-as <target-package-name>` ，其中  target-package-name 就是你的包名；
- 执行 `cp /data/local/tmp/medit ./medit` 拷贝可执行文件；
- 执行 `./medit` 进入内存检索模式；

成功之后可以看到如下图所示，进入到了待命的状态：

![](http://img.cdn.guoshuyu.cn/20220627_Flutter-TL/image2)

这时候我们在密码输入框输入 abcd12345 ，然后在终端 `find abcd12345` 可以看到在 `String` 类别下找到 7 个相关的内存数据。

![image-20220426115105174](http://img.cdn.guoshuyu.cn/20220627_Flutter-TL/image3)

之后我们通过 `TextField`  的 `controller` 清空输入文本，销毁当前页面，跳转到空白页面下后，同时在 Flutter devTool 上主动点击 GC 清理数据，最后再回到终端执行 `find abcd12345`  ，结果如下图所以：

![image-20220426115504463](http://img.cdn.guoshuyu.cn/20220627_Flutter-TL/image4)

可以看到这时候还有 5 个相关数据存在内存，这里挑选一个地址，如 `0x7194a57b` 执行 `dump` 命令： `dump 0x7194a500 0x7194a5ff`  ，结果如下图所示，**可以看到此时的密码是以 map 格式存在，并且长时间都不会被回收或者销毁**。

![](http://img.cdn.guoshuyu.cn/20220627_Flutter-TL/image5)

**这个问题目前在 Android、iOS、Linux 等平台都普遍存在，那这个问题是从哪里来的**？ 这就需要聊到 Flutter 里的文本输入实现流程。

## 二、文本输入流程

Flutter 作为跨平台框架，它的文本内容输入主要是依赖平台的通道实现，例如在 Android 上就是通过  `InputConnection ` 相关的体系去实现。

在 Android 上，**当输入法要和某些 View 进行交互时，系统会通过` View` 的 `onCreateInputConnection`  方法返回一个 `InputConnection` 实例给输入法用于交互通信**，开发者可以通过 override  `InputConnection`   上的一些方法来进行拦截某些输入或者响应某些 key 逻辑等操作，例如：

> Android  SDK 里提供的 `EditText` 控件之所以支持文本输入，也是因为它继承的父类 `TextView` 实现了对应的  `EditableInputConnection` ，并复写了` View` 的 `onCreateInputConnection` 方法。

![image-20220426084518804](http://img.cdn.guoshuyu.cn/20220627_Flutter-TL/image6)

在 Flutter 上，**`FlutterView`  同样 override 了 `onCreateInputConnection` 方法，并实现了  `InputConnectionAdaptor` 作为交互** ，这里先简单介绍一些后面用到的对象：

- **InputConnectionAdaptor** ： `InputConnection` 的实现，用于输入法和 Flutter 之间的通信交互，内部持有： `TextInputChannel` 、 `ListenableEditingState` 、`InputMethodManager` 、`KeyboardManager` 等对象；
- **TextInputChannel** ： `MethodChannel`  的封装对象， 主要和 Dart 进行交互通信，并实现一些逻辑；
- **InputMethodManager** ：Android 系统的键盘管理对象，例如通过它显示/隐藏键盘，或者配置一些键盘特性；
- **ListenableEditingState**：用于保存当前编辑状态，如文本内容、选择范围等等，因为  `InputConnection` 会需要一个 `Editable` 接口，而它就是 `Editable` 接口的子类，Andorid framework 里键盘输入的内容和状态会通过  `Editable` 接口进行操作；
- **TextInputPlugin** ： 它的作用类似于 FlutterPlugin 的作用，持有 `TextInputChannel`  和 `InputMethodManager` 实现一些输入相关逻辑，**同时本身也实现了  `ListenableEditingState.EditingStateWatcher` 接口，该接口当有文本输入时会被调用**；

简单介绍完这些对象的作用，我们回到文本输入的流程上，当用键盘输入完内容时，文本输入内容会进入到 `InputConnectionAdaptor` 的 `endBatchEdit` ，然后如下图所示：

- 键盘输入的内容会保存在  `ListenableEditingState` 里（源码里的 `mEditable` 参数）;
- 之后会通知到  `TextInputPlugin` 去格式化数据并传入  `TextInputChannel` ;
- 接着通过  `TextInputChannel` 把数据封装在 Map 格式，然后通过  invoke 到  `TextInputClient.updateEditingState`   的 dart 方法上；
- Dart 层面接收到 Map 内容之后，将输入内容更新到 `TextEditingValue` 上，从而渲染出输入的文本；

![image-20220426131155331](http://img.cdn.guoshuyu.cn/20220627_Flutter-TL/image7)



可以看到，整个流程主要是：**通过 `InputConnectionAdaptor` 和输入法交互之后得到输入内容和状态，然后将数据封装为 Map 传给 Dart 层，Dart 层解析显示内容**。

那回到上面的 CWE-316 的问题，可以看到此时内存留残留的明文密码正是 `TextInputClient.updateEditingState`   ，也就是原生平台传给 Dart 层的 Map 数据，这部分数据在传递之后没有被回收，导致残留在内容，出现泄漏。

![image-20220426134842594](http://img.cdn.guoshuyu.cn/20220627_Flutter-TL/image8)

事实上关于改问题，在 Flutter 的 [#84708](https://github.com/flutter/flutter/issues/84708) issues 上有过讨论，虽然官方将其定义为 P3 的状态，但是从回复上可以看到，意思大概是： **CWE-316 问题看起来更多是被误导，因为如果第三方可以随意访问到你的设备数据，那其实无论用什么方式都很难避免所谓的泄漏。**

![image-20220426135249882](http://img.cdn.guoshuyu.cn/20220627_Flutter-TL/image9)

另外从目前的 Dart 设计上看， Dart `String` 对象是不可变的，一旦明文 `String` 进入 Dart heap，就无法确保它何时会被清理，而且即使在 String 被 GC 之后，它曾经占用的内存也将保持不变，直到整个区域被清空并交还给操作系统，或在该地址分配了一个新对象，这时候才可能会被完全清除。

另外这里额外补充两个 `InputConnectionAdaptor` 的知识点：`performEditorAction` 和  `sendKeyEvent ` 。

- **performEditorAction** : 当输入法上一些特别的 Key  如 `IME_ACTION_GO`、`IME_ACTION_SEND`  、 `IME_ACTION_DONE` 这些 Key 被触发是时，会直接通过 `TextInputChannel` 将 code 发送到 Dart ；
- **sendKeyEvent** ： 当某些特殊按键输入时会被回调，例如点击退格键时，但是这个取决于输入的不同，例如小米安全键盘输入法的退格键就不会触发，但是小米安全键盘输入法的数字 key 就会触发该回调；



## 三、最后



所以就目前版本的情况来看，**只要是使用了  `TextField`  ，或者说 `EditableText` ，那么传输过程的 Map 残留问题可能会一直存在**。

当然，**如果你只是使用 String 而不是使用  `EditableText`  ，那么 Dart 上类似   typed data 或者 ffi pointers 的能力，一定程度可以解决此类的问题**。



如果针对  `TextField`  的 CWE-316  你还有什么想法，欢迎留言讨论交流～