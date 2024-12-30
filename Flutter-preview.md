# Flutter 终于正式规划 IDE  Widget 预览支持，基础技术架构公布

2024 了， Flutter 终于"醒悟"，开始规划 Widget Previews[#159342](https://github.com/flutter/flutter/issues/159342) ，在 *Jetpack Compose* 和 *SwiftUI* 都支持 IDE Preview 的情况下，一直以来 Flutter 缺乏预览能力是被吐槽最多的问题之一。

![](http://img.cdn.guoshuyu.cn/20241125_preview/image1.png)

> 目前只是进入规划阶段，还没正式落地，但是可以作为基础架构参考。

在当前设计上，预期通过在函数上代入  `@Preview` 注解来开启 Widget 预览，被预览的 Widget 是直接在 Flutter 应用中被渲染，所以一般情况下它们是完全交互式的，可用于预览 UI 布局和动画。

```dart
@Preview()
List<WidgetPreview> myFirstPreview() {
 return <WidgetPreview>[
     WidgetPreview(
       name: 'Full App Preview',
       height: 700,
       device: Devices.ios.all.first,
       child: GalleryApp(),
     ),
 ];

```

在这点上看和 Compose 的 Preview 很类似：

![](http://img.cdn.guoshuyu.cn/20241125_preview/image2.png)

按照目前架构文档上的描述，整个预览存在以下几个关键节点：

- **Widget Preview**：在预览环境中显示 Widget，用于开发工作流程
- **Preview Scaffold**：用于生成 Flutter 应用，显示项目中定义的 widget 预览
- **Preview Environment**: 托管 Preview  Scaffold 的原生 Flutter 桌面应用
- **Preview Viewer**：一个 Flutter Web 应用，可将帧从 Preview Environment 流式传输到 IDE ，并将用户交互流式传输到 Preview Environment

>  从这点看，可以理解为**预览其实是通过 Flutter Web + Flutter PC 来实现**。

![](http://img.cdn.guoshuyu.cn/20241125_preview/image3.png)



而实现后的大致效果就是，当客户端连接到 Preview Environment 的 Web 服务器时，服务器会立即注册一个持久性帧回调，该回调负责在渲染时捕获每个帧，然后捕获的帧将通过 web socket 连接转发到客户端：

```dart
 /// Sends the current frame to the preview viewer for rendering.
 Future<void> sendFrame() async {
   if (_sendingFrame) {
     return;
   }
   _sendingFrame = true;
   final RenderView renderView =
       WidgetsBinding.instance.rootElement!.renderObject! as RenderView;
   final OffsetLayer layer = renderView.debugLayer! as OffsetLayer;
   final ui.Image image = await layer.toImage(
     Offset.zero & (renderView.size * renderView.flutterView.devicePixelRatio),
   );
   final Uint8List data = (await image.toByteData())!.buffer.asUint8List();
   image.dispose();
   _client.sendFrame(frame: data);
   _sendingFrame = false;
 }

```

通过对应容器，Flutter 开发者就可以在对应 IDE 中的预览环境对他们的 Widget 进行预览和交互， Preview 支持缩放或者平移，从而让开发者可以在像素级别检查 UI，同时开发人员还可以使用 `package:device_frame`  将他们的 widget 包装在一个设备框架中，该框架可以使用设备的显示特性来呈现 widget。

![](http://img.cdn.guoshuyu.cn/20241125_preview/image4.gif)

![](http://img.cdn.guoshuyu.cn/20241125_preview/image5.gif)

> Flutter tool  同时新增了 `flutter widget-preview` 命令，该命令负责为项目生成 preview scaffold 并与preview environment 交互，并负责为给定项目创建 preview scaffold  并管理 preview environment 。

正常来说，首次在用户设备上为项目运行命令时，工具将执行以下任务：

- 在 `.dart_tool` 目录下创建一个新的 Flutter 项目（当前名为 `preview_scaffold`），它目前被配置为 Flutter 桌面 App

- 使用 `preview_scaffold`  entrypoint 覆盖 `lib/main.dart` ，该入口能够托管开发人员项目中的 widget previews ，文件会导入` lib/generated_preview.dart`，它将包含一个函数，函数用于返回项目的 widget 预览集
- 初始化 `preview_scaffold` 的 `pubspec.yaml`，在开发者的项目中添加路径依赖，并列出开发者项目中的资源，此步骤还处理导入 `package:flutter_gen` 以获得本地化支持，当然如果宏编程正式发布，就不需要`package:flutter_gen`  了。
- 使用 `package:analyzer`，在返回 `List<WidgetPreview>` 的 Top 函数上搜索 `@Preview()` 注释的实例，并记录预览函数名称以及它们的库
- 使用开发人员项目中的预览搜索结果生成 `lib/generated_preview.dart`  ， `package:code_builder` 用于生成代码，该代码导入并调用每个 widget 预览函数用于返回预览列表，例如：

```dart
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:gallery/main.dart' as _i1;
import 'package:gallery/demos/material/list_demo.dart' as _i2;
import 'package:flutter/widget_preview.dart';


List<WidgetPreview> previews() => [
     ..._i1.preview(),
     ..._i2.preview(),
   ];

```

> Flutter  Tool 最终会在开发者的项目目录上初始化一个文件观察器，以检测源代码的更改，analyzer API 会检测更新文件中添加或删除 Widget 预览定义，并在必要时重新生成 lib/generated_preview.dart，同时 Flutter Tool 将使用 Flutter Tool 守护进程协议与预览环境通信，从而触发热重载，更新预览环境。

IDE 插件将负责使用 `flutter widget-preview` 命令启动活动项目的预览环境，为了在 IDE 中显示 Preview Environment 的内容，Preview Environment 需要将帧和交互事件流式传输到 Web 的应用（VSCode 仅支持嵌入基于 Web 的工具），这个 Web 应用将是一个简约的 Flutter Web 应用，它渲染预览环境发送的帧，并使用现有的 Widget 如 `KeyboardListener` 和 `Listener` 捕获和转发用户交互（例如光标移动、点击、滚动和按键），流式处理将通过 websocket 连接完成，使用 JSON RPC 协议将用户交互传达到 Preview Environment 。

目前，`@Preview` 注解类只是一个标记，表示以下函数应该由预览环境导入和显示，将来这个注解应该会增加比如指定应应用于某些预览内容设置，如语言区域、主题详情的属性，或以编程方式生成多个预览，例如类似 Compose：

![](http://img.cdn.guoshuyu.cn/20241125_preview/image6.gif)

目前 `WidgetPreview` 类是一个 wrapper ，用于初始化各种状态和属性，允许在 Widget 预览环境中呈现 Widget：

```dart
class WidgetPreview extends StatefulWidget {
 const WidgetPreview({
   super.key,
   required this.child,
   this.name,
   this.width,
   this.height,
   this.device,
   this.orientation,
   this.textScaleFactor,
   this.platformBrightness,
 });
  
  final String? name;


 /// The [Widget] to be rendered in the preview.
 final Widget child;


 /// Artificial constraints to be applied to the [child].
 final double? width;
 final double? height;


 /// An optional device configuration.
 final DeviceInfo? device;


 /// The orientation of [device].
 final Orientation? orientation;


 /// Applies font scaling to text within the [child].
 final double? textScaleFactor;


 /// Light or dark mode (defaults to platform theme).
 final Brightness? platformBrightness;


 @override
 State<WidgetPreview> createState() => _WidgetPreviewState();
}
```

目前接口允许开发人员指定如下属性：

- 要在预览环境中与预 preview 一起显示的描述
- 预览的高度和宽度，将覆盖 MediaQuery 返回的大小，从而允许预览自适应 UI
- `package：device_frame` 中的设备，它在 device_frame 中渲染预览的 Widget，并应用了正确的显示属性,还可以通过方向来指定设备最初应以横向模式还是纵向模式显示
- 用于调整默认字体缩放行为的文本缩放
- 用于控制主题选择的平台亮度（例如浅色与深色模式）

而对于交互协议，目前允许将以下交互转发到预览环境：

- Pointer location 
- Hover location
- Tap up / down 
- Scrolling with a mouse wheel
- Scrolling with a trackpad
- Keypress events (down, up, repeated)
- Window size changes 

最后，可以看到目前整个预览的基础架构还比较粗糙，另外类似  `device_frame` 这种第三方包直接在 Flutter 引用是否合适也存在一些讨论，还有 native assets 等支持等，可以预见 preview 的落地难度还是有的，但是踏出这一步后，相信离最后的落地就不远了。



参考连接：https://github.com/flutter/flutter/issues/159342