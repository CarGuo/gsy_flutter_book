作为系列文章的第三篇，本篇将为你着重展示：**Flutter开发过程的打包流程、APP包对比、细节技巧与问题处理**，本篇主要描述的 Flutter 的打包、在开发过程中遇到的各类问题与细节，算是对上两篇的补全。

## 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)


## 一、打包

首先我们先看结果，如下表所示，是 **Flutter 与 React Native 、iOS 与 Android 的纵向与横向对比** 。

| 项目          | IOS |Android|
| ---------------------- | ---------------------------------------- | ---------------------------------------- |
| [**GSYGithubAppFlutter**](https://github.com/CarGuo/GSYGithubAppFlutter) |     ![flutter-ipa](http://img.cdn.guoshuyu.cn/20190604_Flutter-3/image1)            |      ![flutter-apk](http://img.cdn.guoshuyu.cn/20190604_Flutter-3/image2)         |
| [**GSYGithubAppRN**](https://github.com/CarGuo/GSYGithubApp) |   ![rn-ipa](http://img.cdn.guoshuyu.cn/20190604_Flutter-3/image3) |  ![rn-apk](http://img.cdn.guoshuyu.cn/20190604_Flutter-3/image4)|


从上表我们可以看到：
* Fluuter的 apk 会比 ipa 更小一些，这其中的一部分原因是 Flutter 使用的 `Skia ` 在Android 上是自带的。
* 横向对比 React Native ，虽然项目不完全一样，但是大部分功能一致的情况下， Flutter 的 Apk 确实更小一些。这里又有一个细节，rn 的 ipa 包体积小很多，这其实是因为 `javascriptcore` 在 ios上 是内置的原因。

* 对上述内容有兴趣的可以看看[《移动端跨平台开发的深度解析》](https://juejin.im/post/5b395eb96fb9a00e556123ef)。

### 1、Android 打包

![I'm Android](http://img.cdn.guoshuyu.cn/20190604_Flutter-3/image5)

在 Android 的打包上，笔者基本没有遇到什么问题，在`android/app/build.grade`文件下，配置`applicationId`、`versionCode`、`versionName` 和签名信息，最后通过 `flutter build app` 即可完成编译。编程成功的包在 `build/app/outputs/apk/release` 下。


### 2、iOS 打包与真机运行

在 iOS 的打包上，笔者倒是经历了一波曲折，这里主要讲笔者遇到的问题。

首先你需要一个 apple 开发者账号，然后创建证书、创建AppId，创建配置文件、最后在`info.plist`文件下输入相关信息，更详细可看官方的[《发布的IOS版APP》](https://flutterchina.club/ios-release/)的教程。

但由于笔者项目中使用了第三方的插件包如 `shared_preferences` 等，在执行 `Archive` 的过程却一直出现如下问题：

```
在 `Archive` 时提示找不到
#import <connectivity/ConnectivityPlugin.h>  ///file not found
#import <device_info/DeviceInfoPlugin.h>
#import <flutter_statusbar/FlutterStatusbarPlugin.h>
#import <flutter_webview_plugin/FlutterWebviewPlugin.h>
#import <fluttertoast/FluttertoastPlugin.h>
#import <get_version/GetVersionPlugin.h>
#import <package_info/PackageInfoPlugin.h>
#import <share/SharePlugin.h>
#import <shared_preferences/SharedPreferencesPlugin.h>
#import <sqflite/SqflitePlugin.h>
#import <url_launcher/UrlLauncherPlugin.h>
```

通过 Android Studio 运行到 iOS 模拟器时没有任何问题，说明这不是第三方包问题。通过查找问题发现，在 iOS 执行  `Archive`  之前，需要执行  `flutter build release`，如下图在命令执行之后，Pod 的执行目录会发现改变，并且生成打包需要的文件。（*ps 普通运行时自动又会修改回来*）


![文件变化](http://img.cdn.guoshuyu.cn/20190604_Flutter-3/image6)
　

但是实际在执行  `flutter build release` 后，问题依然存在，最终翻山越岭(╯‵□′)╯︵┻━┻，终于找到两个答案：

*   [Issue#19241](https://github.com/flutter/flutter/issues/19241#issuecomment-404601754) 下描述了类似问题，但是他们因为路径问题导致，经过尝试并不能解决。

* [Issue#18305](https://github.com/flutter/flutter/issues/18305) 真实的解决了这个问题，居然是因为 Pod 的工程没引入：

```
open ios/Runner.xcodeproj

I checked Runner/Pods is empty in Xcode sidebar.

drop Pods/Pods.xcodeproj into Runner/Pods.

"Valid architectures" to only "arm64" (I removed armv7 armv7s) 
```

最后终于成功打包，心累啊(///▽///)。同时如果希望直接在真机上调试 Flutter，可以参考 :[《Flutter基础—开发环境与入门》](https://blog.csdn.net/hekaiyou/article/details/52874796?locationNum=4&fps=1) 下的 **iOS 真机**部分。




## 二、细节

*这里主要讲一些小细节*

### 1、AppBar

在 Flutter 中 AppBar 算是常用 Widget ，而 AppBar 可不仅仅作为标题栏和使用，AppBar上的 `leading` 和 `bottom` 同样是有用的功能。

* AppBar 的 `bottom` 默认支持 `TabBar`,  也就是常见的顶部 Tab 的效果，这其实是因为`TabBar` 实现了 `PreferredSizeWidget ` 的 `preferredSize`。
所以只要你的控件实现了 `preferredSize`，就可以放到 AppBar 的  `bottom` 中使用。比如下图搜索栏，这是TabView下的页面又实用了AppBar。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-3/image7)

* `leading` ：通常是左侧按键，不设置时一般是 Drawer 的图标或者返回按钮。

* `flexibleSpace` ：位于 `bottom ` 和 `leading ` 之间。


### 2、按键

Flutter 中的按键，如 `FlatButton` 默认是否有边距和最小大小的。所以如果你想要无 *padding、margin、border 、默认大小* 等的按键效果，其中一种方式如下：

```
///
new RawMaterialButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: padding ?? const EdgeInsets.all(0.0),
        constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
        child: child,
        onPressed: onPressed);
```

如果在再上 Flex ，如下所示，一个可控的填充按键就出来了。

```
new RawMaterialButton(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: padding ?? const EdgeInsets.all(0.0),
        constraints: const BoxConstraints(minWidth: 0.0, minHeight: 0.0),
        ///flex
        child: new Flex(
          mainAxisAlignment: mainAxisAlignment,
          direction: Axis.horizontal,
          children: <Widget>[],
        ),
        onPressed: onPressed);
```

### 3、StatefulWidget 赋值

这里我们以给 `TextField ` 主动赋值为例，其实 Flutter 中，给有状态的 Widget 传递状态或者数据，一般都是通过各种 controller 。如 `TextField` 的主动赋值，如下代码所示：

```

 final TextEditingController controller = new TextEditingController();

 @override
 void didChangeDependencies() {
    super.didChangeDependencies();
    ///通过给 controller 的 value 新创建一个 TextEditingValue
    controller.value = new TextEditingValue(text: "给输入框填入参数");
 }

 @override
  Widget build(BuildContext context) {
    return new TextField(
     ///controller
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      decoration: new InputDecoration(
        hintText: hintText,
        icon: iconData == null ? null : new Icon(iconData),
      ),
    );
  }
```

其实 ` TextEditingValue `  是 `ValueNotifier`，其中 `value` 的 setter 方法被重载，一旦改变就会触发 `notifyListeners` 方法。而 `TextEditingController` 中，通过调用 `addListener` 就监听了数据的改变，从而让UI更新。

当然，赋值有更简单粗暴的做法是：**传递一个对象 class A 对象，在控件内部使用对象 A.b 的变量绑定控件，外部通过 setState({ A.b = b2}) 更新**。

### 4、GlobalKey

在Flutter中，要主动改变子控件的状态，还可以使用 `GlobalKey `。 比如你需要主动调用 `RefreshIndicator` 显示刷新状态，如下代码所示。

```

 GlobalKey<RefreshIndicatorState> refreshIndicatorKey;
  
 showForRefresh() {
    ///显示刷新
    refreshIndicatorKey.currentState.show();
  }

  @override
  Widget build(BuildContext context) {
    refreshIndicatorKey =  new GlobalKey<RefreshIndicatorState>();
    return new RefreshIndicator(
      key: refreshIndicatorKey,
      onRefresh: onRefresh,
      child: new ListView.builder(
        ///·····
      ),
    );
  }
```

### 5、Redux 与主题

使用 Redux 来做 Flutter 的全局 State 管理最合适不过，由于Redux内容较多，如果感兴趣的可以看看 [篇章二](https://www.jianshu.com/p/5768a999790d) ，这里主要通过 Redux 来实现实时切换主题的效果。

如下代码，通过 `StoreProvider ` 加载了  store ，再通过 `StoreBuilder ` 将 store 中的 themeData 绑定到 `MaterialApp`  的  theme 下，之后在其他 Widget 中通过 `Theme.of(context)` 调你需要的颜色，最终在任意位置调用 `store.dispatch` 就可实时修改主题，效果如后图所示。

```
class FlutterReduxApp extends StatelessWidget {
  final store = new Store<GSYState>(
    appReducer,
    initialState: new GSYState(
      themeData: new ThemeData(
        primarySwatch: GSYColors.primarySwatch,
      ),
    ),
  );

  FlutterReduxApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// 通过 StoreProvider 应用 store
    return new StoreProvider(
      store: store,
      ///通过 StoreBuilder 获取 themeData
      child: new StoreBuilder<GSYState>(builder: (context, store) {
        return new MaterialApp(
            theme: store.state.themeData,
            routes: {
              HomePage.sName: (context) {
                return HomePage();
              },
            });
      }),
    );
  }
}
```

![主题](http://img.cdn.guoshuyu.cn/20190604_Flutter-3/image8)

### 6、Hotload 与 Package

Flutter 在 Debug 和 Release 下分别是 *JIT* 和 *AOT* 模式，而在 DEBUG 下，是支持 Hotload 的，而且十分丝滑。但是需要注意的是：**如果开发过程中安装了新的第三方包 ，而新的第三方包如果包含了原生代码，需要停止后重新运行哦。**

`pubspec.yaml` 文件下就是我们的包依赖目录，其中 `^`  代表大于等于，一般情况下 `upgrade ` 和 `get ` 都能达到下载包的作用。但是：**upgrade 会在包有更新的情况下，更新 `pubspec.lock` 文件下包的版本** 。


## 三、问题处理


* `Waiting for another flutter command to release the startup lock ` ：如果遇到这个问题：

```
  1、打开flutter的安装目录/bin/cache/ 
  2、删除lockfile文件 
  3、重启AndroidStudio
```

* dialog下的黄色线
[yellow-lines-under-text-widgets-in-flutter](https://stackoverflow.com/questions/47114639/yellow-lines-under-text-widgets-in-flutter)：showDialog 中，默认是没使用 Scaffold ，这回导致文本有黄色溢出线提示，可以使用 Material 包一层处理。

* TabBar + TabView + KeepAlive 的问题
可以通过 TabBar + PageView 解决，具体可见 [篇章二](https://www.jianshu.com/p/5768a999790d)。


>自此，第三篇终于结束了！(///▽///)

### 资源推荐

* Github ： [https://github.com/CarGuo/](https://github.com/CarGuo)
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**

##### 完整开源项目推荐：

* [GSYGithubAppWeex](https://github.com/CarGuo/GSYGithubAppWeex)
* [GSYGithubApp React Native](https://github.com/CarGuo/GSYGithubApp ) 


![我们还会再见吗？](http://img.cdn.guoshuyu.cn/20190604_Flutter-3/image9)
