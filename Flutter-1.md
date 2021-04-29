## 前言

在如今的 Flutter 大潮下，本系列是让你看完会安心的文章。

本系列将完整讲述：如何入门 Flutter 开发，如何快速从 0 开发一个完整的 Flutter APP，配套高完成度  Flutter 开源项目 [GSYGithubAppFlutter](https://github.com/CarGuo/GSYGithubAppFlutter)，提供 Flutter 的开发技巧和问题处理，之后深入源码和实战为你全面解析 Flutter。

> 笔者相继开发过 Flutter、React Native 、Weex 等主流跨平台框架项目，其中 Flutter 的跨平台兼容性无疑最好。前期开发调试完全在 Android 端进行的情况下，第一次在 iOS 平台运行居然没有任何错误，并且还没出现 UI 兼容问题，相信对于经历过跨平台开发的猿们而言，是多么的不可思议画面，并且 Fluuter 的 HotLoad 相比较其他两个平台，也是丝滑的让人无法相信，吹爆了！

## 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)


## 一、基础篇

*本篇主要涉及：环境搭建、Dart语言、Flutter的基础。*


### 1、环境搭建

Flutter 的环境搭建十分省心，特别对应 Android 开发者而言，只是在 Android Stuido
上安装插件，并到 GitHub Clone Flutter 项目到本地之后执行 flutter doctor 命令就可以完成配置，其实中文网的[搭建Futter开发环境](https://flutterchina.club/get-started/install/) 已经很贴心详细，从平台指引开始安装基本都不会遇到问题。

这里主要是需要注意，因为某些不可抗力的原因，国内的用户有时候需要配置 Flutter 的代理，并且国内用户在搜索 Flutter 第三方包时，也是在 https://pub.flutter-io.cn 内查找，下方是需要配置到环境变量的地址。*（ps Android Studio下运行 IOS 也是蛮有意思的感觉）*

```
///win直接配置到环境编辑即可，mac配置到bash_profile或者zsh
export PUB_HOSTED_URL=https://pub.flutter-io.cn //国内用户需要设置
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn //国内用户需要设置
```

###  2、Dart语言下的Flutter

在跨平台开领域被 JS 一统天下的今天，Dart 语言的出现无疑是一股清流。作为后来者，Dart语言有着不少 Java、Kotlin 和 JS 的影子，所以对于 Android 原生开发者、前端开发者而言无疑是非常友好。

官方也提供了包括 iOS 、React Native 等开发者迁移到 Flutter 上的文档，所以请不要担心，Dart 语言不会是你掌握 Flutter 的门槛，甚至作为开发者，就算你不懂 Dart 也可以看着代码摸索。

Come on，下面主要通过对比，简单讲述下 Dart 的一些特性，主要涉及的是 Flutter 下使用。

#### 2.1、基本类型

- var 可以定义变量，如 `var tag = "666"` ，这和 JS 、 Kotlin 等语言类似，同时 Dart 也算半个动态类型语言，同时支持闭包。

- `Dart` 属于是**强类型语言** ，但可以用 `var`  来声明变量，`Dart` 会**自推导出数据类型**，所以 `var` 实际上是编译期的“语法糖”。**`dynamic` 表示动态类型**， 被编译后，实际是一个 `object` 类型，在编译期间不进行任何的类型检查，而是在运行期进行类型检查。

- Dart 中 number 类型分为 `int` 和 `double` ，其中 java 中的 long 对应的也是 Dart 中的 int 类型，Dart 中没有 float 类型。

- Dart 下只有 bool 型可以用于 if 等判断，不同于 JS 这种使用方式是不合法的 `var g = "null"; if(g){}` 。

- Dart 中，switch 支持 String 类型。

#### 2.2、变量

- Dart 不需要给变量设置 `setter getter`  方法， 这和 kotlin 等语言类似。Dart 中所有的基础类型、类等都继承 Object ，默认值是 NULL， 自带 getter 和 setter ，而如果是 final 或者 const 的话，那么它只有一个 getter 方法。

- Dart 中 final 和 const 表示常量，比如 `final name = 'GSY'; const value= 1000000; ` 同时 `static const` 组合代表了静态常量，其中 const 的值在编译期确定，final 的值要到运行时才确定。

- Dart 下的数值，在作为字符串使用时，是需要显式指定的。比如：`int i = 0; print("aaaa" + i);` 这样并不支持，需要 `print("aaaa" + i.toString());` 这样使用，这和 Java 与 JS 存在差异，**所以在使用动态类型时，需要注意不要把 number 类型当做 String 使用。**

- Dart  中数组等于列表，所以 `var list = [];` 和 `List list = new List()` 可以简单看做一样。

#### 2.3、方法

- Dart 下 `??` 、`??=` 属于操作符，如: ` AA ?? "999" ` 表示如果 AA 为空，返回999；` AA ??= "999" ` 表示如果 AA 为空，给 AA 设置成 999。

- Dart 方法可以设置 *参数默认值* 和 *指定名称* 。比如： ` getDetail(Sting userName, reposName, {branch = "master"}){} ` 方法，这里 branch 不设置的话，默认是 “master” 。*参数类型* 可以指定或者不指定。调用效果： `getRepositoryDetailDao(“aaa", "bbbb", branch: "dev");`

- Dart 不像 Java ，没有关键词 public 、private 等修饰符，` _ `下横向直接代表 private ，但是有 `@protected` 注解。

- Dart 中多构造函数，可以通过如下代码实现的。默认构造方法只能有一个，而通过`Model.empty()` 方法可以创建一个空参数的类，其实方法名称随你喜欢，而变量初始化值时，只需要通过 `this.name` 在构造方法中指定即可：

```
class ModelA {
  String name;
  String tag;
  
  //默认构造方法，赋值给name和tag
  ModelA(this.name, this.tag);

  //返回一个空的ModelA
  ModelA.empty();
  
  //返回一个设置了name的ModelA
  ModelA.forName(this.name);
}

```

#### 2.4、Flutter

Flutter 中支持 `async`/`await` ，**如下代码所示**， `async`/`await` 其实只是语法糖，最终会编译为 Flutter 中返回 `Future` 对象，之后通过 `then` 可以执行下一步。如果返回的还是 `Future` 便可以 `then().then.()` 的流式操作了 。

```
  ///模拟等待两秒，返回OK
  request() async {
    await Future.delayed(Duration(seconds: 1));
    return "ok!";
  }

  ///得到"ok!"后，将"ok!"修改为"ok from request"
  doSomeThing() async {
    String data = await request();
    data = "ok from request";
    return data;
  }

  ///打印结果
  renderSome() {
    doSomeThing().then((value) {
      print(value);
      ///输出ok from request
    });
  }
```

- Flutter 中 `setState`  很有 React Native 的既视感，Flutter 中也是通过 State 跨帧实现管理数据状态的，这个后面会详细讲到。

- Flutter 中一切皆 Widget 呈现，通过 `build`方法返回 Widget，这也是和 React Native 中，通过 `render` 函数返回需要渲染的 component 一样的模式。
- Stream 对应的 async* / yield 也可以用于异步，这个后面会说到。


###  3、Flutter Widget

在 Flutter 中一切的显示都是 Widget ，Widget 是一切的基础，利用响应式模式进行渲染。

我们可以通过修改数据，再用`setState` 设置数据，Flutter 会自动通过绑定的数据更新 Widget ， **所以你需要做的就是实现 Widget 界面，并且和数据绑定起来**。

Widget 分为 *有状态* 和 *无状态* 两种，在 Flutter 中每个页面都是一帧，无状态就是保持在那一帧，而有状态的 Widget 当数据更新时，其实是创建了新的 Widget，只是 State 实现了跨帧的数据同步保存。

&emsp;

> 这里有个小 Tip ，当代码框里输入 `stl` 的时候，可以自动弹出创建无状态控件的模板选项，而输入 `stf` 的时，就会弹出创建有状态 Widget 的模板选项。
>
>代码格式化的时候，括号内外的逗号都会影响格式化时换行的位置。
>
>如果觉得默认换行的线太短，可以在设置-Editor-Code Style-Dart-Wrapping and Braces-Hard wrap at 设置你接受的数值。

&emsp;

#### 3.1、无状态StatelessWidget

直接进入主题，如下下代码所示是无状态 Widget 的简单实现。**继承 StatelessWidget，通过 `build ` 方法返回一个布局好的控件**。可能现在你还对 Flutter 的内置控件不熟悉，but **Don't worry , take it easy** ，后面我们就会详细介绍这里你只需要知道，一个无状态的 Widget 就是这么简单。


Widget 和 Widget 之间通过 `  child:  ` 进行嵌套。其中有的 Widget 只能有一个 child，比如下方的 `Container` ；有的 Widget 可以多个 child ，也就是`children`，比如` Column 布局，下方代码便是 Container Widget 嵌套了 Text Widget。

```
import 'package:flutter/material.dart';

class DEMOWidget extends StatelessWidget {
  final String text;

  //数据可以通过构造方法传递进来
  DEMOWidget(this.text);

  @override
  Widget build(BuildContext context) {
    //这里返回你需要的控件
    //这里末尾有没有的逗号，对于格式化代码而已是不一样的。
    return Container(
      //白色背景
      color: Colors.white,
      //Dart语法中，?? 表示如果text为空，就返回尾号后的内容。
      child: Text(text ?? "这就是无状态DMEO"),
    );
  }
}

```

#### 3.2、有状态StatefulWidget

继续直插主题，如下代码，是有状态的widget的简单实现，你需要创建管理的是主要是 `State` ， 通过 State 的 ` build` 方法去构建控件。在 State 中，你可以动态改变数据，在 `setState ` 之后，改变的数据会触发 Widget 重新构建刷新，而下方代码中，是通过延两秒之后，让文本显示为 *"这就变了数值"*。


如下代码还可以看出，State 中主要的声明周期有 ：


 * **initState** ：初始化，理论上只有初始化一次，第二篇中会说特殊情况下。
 * **didChangeDependencies**：在 initState 之后调用，此时可以获取其他 State 。
 * **dispose** ：销毁，只会调用一次。

看到没，Flutter 其实就是这么简单！你的关注点只要在：创建你的 `StatelessWidget` 或者 `StatefulWidget` 而已。**你需要的就是在 `build ` 中堆积你的布局，然后把数据添加到 Widget 中，最后通过 `setState` 改变数据，从而实现画面变化。**

```
import 'dart:async';
import 'package:flutter/material.dart';

class DemoStateWidget extends StatefulWidget {

  final String text;

  ////通过构造方法传值
  DemoStateWidget(this.text);

  ///主要是负责创建state
  @override
  _DemoStateWidgetState createState() => _DemoStateWidgetState(text);
}

class _DemoStateWidgetState extends State<DemoStateWidget> {

  String text;

  _DemoStateWidgetState(this.text);
  
  @override
  void initState() {
    ///初始化，这个函数在生命周期中只调用一次
    super.initState();
    ///定时1秒
    new Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        text = "这就变了数值";
      });
    });
  }

  @override
  void dispose() {
    ///销毁
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    ///在initState之后调 Called when a dependency of this [State] object changes.
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(text ?? "这就是有状态DMEO"),
    );
  }
}
```

&emsp;

###  4、Flutter 布局

Flutter 中拥有需要将近30种内置的 [布局Widget](https://flutterchina.club/widgets/layout)，其中常用有 *Container、Padding、Center、Flex、Stack、Row、Column、ListView* 等，下面简单讲解它们的特性和使用。

| 类型        | 作用特点                                     |
| --------- | ---------------------------------------- |
| Container | 只有一个子 Widget。默认充满，包含了padding、margin、color、宽高、decoration 等配置。 |
| Padding   | 只有一个子 Widget。只用于设置Padding，常用于嵌套child，给child设置padding。 |
| Center    | 只有一个子 Widget。只用于居中显示，常用于嵌套child，给child设置居中。  |
| Stack     | 可以有多个子 Widget。 子Widget堆叠在一起。              |
| Column     | 可以有多个子 Widget。垂直布局。                       |
| Row       | 可以有多个子 Widget。水平布局。                      |
| Expanded  | 只有一个子 Widget。在  Column 和  Row 中充满。                   |
| ListView  | 可以有多个子 Widget。自己意会吧。                                    |

* Container ：最常用的默认控件，但是实际上它是由多个内置控件组成的模版，只能包含一个`child`，支持 *padding,margin,color,宽高,decoration（一般配置边框和阴影）等配置*，在 Flutter 中，不是所有的控件都有 *宽高、padding、margin、color* 等属性，所以才会有 Padding、Center 等 Widget 的存在。
```
    new Container(
        ///四周10大小的maring
        margin: EdgeInsets.all(10.0),
        height: 120.0,
        width: 500.0,
        ///透明黑色遮罩
        decoration: new BoxDecoration(
            ///弧度为4.0
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
            ///设置了decoration的color，就不能设置Container的color。
            color: Colors.black,
            ///边框
            border: new Border.all(color: Color(GSYColors.subTextColor), width: 0.3)),
        child:new Text("666666"));
```

* Column、Row 绝对是必备布局， 横竖布局也是日常中最常见的场景。如下方所示，它们常用的有这些属性配置：主轴方向是 start 或 center 等；副轴方向方向是 start 或 center 等；mainAxisSize 是充满最大尺寸，或者只根据子 Widget 显示最小尺寸。

```
//主轴方向，Column的竖向、Row我的横向
mainAxisAlignment: MainAxisAlignment.start, 
//默认是最大充满、还是根据child显示最小大小
mainAxisSize: MainAxisSize.max,
//副轴方向，Column的横向、Row我的竖向
crossAxisAlignment :CrossAxisAlignment.center,
```

* Expanded 在 Column 和  Row 中代表着平均充满的作用，当有两个存在的时候默认均分充满。同时页可以设置 `flex` 属性决定比例。

```
    new Column(
     ///主轴居中,即是竖直向居中
     mainAxisAlignment: MainAxisAlignment.center,
     ///大小按照最小显示
     mainAxisSize : MainAxisSize.min,
     ///横向也居中
      crossAxisAlignment : CrossAxisAlignment.center,
      children: <Widget>[
        ///flex默认为1
        new Expanded(child: new Text("1111"), flex: 2,),
        new Expanded(child: new Text("2222")),
      ],
    );
```
接下来我们来写一个复杂一些的控件，首先我们创建一个私有方法`_getBottomItem `，返回一个 `Expanded Widget`，因为后面我们需要将这个方法返回的 Widget 在 Row 下平均充满。

如代码中注释，布局内主要是现实一个居中的Icon图标和文本，中间间隔5.0的 padding：

```
  ///返回一个居中带图标和文本的Item
  _getBottomItem(IconData icon, String text) {
    ///充满 Row 横向的布局
    return new Expanded(
      flex: 1,
      ///居中显示
      child: new Center(
        ///横向布局
        child: new Row(
          ///主轴居中,即是横向居中
          mainAxisAlignment: MainAxisAlignment.center,
          ///大小按照最大充满
          mainAxisSize : MainAxisSize.max,
          ///竖向也居中
          crossAxisAlignment : CrossAxisAlignment.center,
          children: <Widget>[
            ///一个图标，大小16.0，灰色
            new Icon(
              icon,
              size: 16.0,
              color: Colors.grey,
            ),
            ///间隔
            new Padding(padding: new EdgeInsets.only(left:5.0)),
            ///显示文本
            new Text(
              text,
              //设置字体样式：颜色灰色，字体大小14.0
              style: new TextStyle(color: Colors.grey, fontSize: 14.0),
              //超过的省略为...显示
              overflow: TextOverflow.ellipsis,
              //最长一行
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
```


![item效果](http://img.cdn.guoshuyu.cn/20190604_Flutter-1/image1)


接着我们把上方的方法，放到新的布局里，如下流程和代码：

* 首先是 `Container `包含了` Card`，用于快速简单的实现圆角和阴影。
* 然后接下来包含了`FlatButton`实现了点击，通过Padding实现了边距。
* 接着通过`Column`垂直包含了两个子Widget，一个是`Container`、一个是`Row`。
* Row 内使用的就是`_getBottomItem `方法返回的 Widget ，效果如下图。

```
  @override
  Widget build(BuildContext context) {
    return new Container(
      ///卡片包装
      child: new Card(
           ///增加点击效果
          child: new FlatButton(
              onPressed: (){print("点击了哦");},
              child: new Padding(
                padding: new EdgeInsets.only(left: 0.0, top: 10.0, right: 10.0, bottom: 10.0),
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ///文本描述
                    new Container(
                        child: new Text(
                          "这是一点描述",
                          style: TextStyle(
                            color: Color(GSYColors.subTextColor),
                            fontSize: 14.0,
                          ),
                          ///最长三行，超过 ... 显示
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        margin: new EdgeInsets.only(top: 6.0, bottom: 2.0),
                        alignment: Alignment.topLeft),
                    new Padding(padding: EdgeInsets.all(10.0)),

                    ///三个平均分配的横向图标文字
                    new Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _getBottomItem(Icons.star, "1000"),
                        _getBottomItem(Icons.link, "1000"),
                        _getBottomItem(Icons.subject, "1000"),
                      ],
                    ),
                  ],
                ),
              ))),
    );
  }

```

![完整Item](http://img.cdn.guoshuyu.cn/20190604_Flutter-1/image2)


Flutter 中，你的布局很多时候就是这么一层一层嵌套出来的，当然还有其他更高级的布局方式，这里就先不展开了。


###  5、Flutter 页面

Flutter 中除了布局的 Widget，还有交互显示的 Widget 和完整页面呈现的Widget，其中常见的有 *MaterialApp、Scaffold、Appbar、Text、Image、FlatButton*等，下面简单介绍这些 Wdiget，并完成一个页面。


| 类型          | 作用特点                                     |
| ----------- | ---------------------------------------- |
| MaterialApp | 一般作为APP顶层的主页入口，可配置主题，多语言，路由等                |
| Scaffold    | 一般用户页面的承载Widget，包含appbar、snackbar、drawer等material design的设定。 |
| Appbar      | 一般用于Scaffold的appbar ，内有标题，二级页面返回按键等，当然不止这些，tabbar等也会需要它 。|
| Text        |  显示文本，几乎都会用到，主要是通过style设置TextStyle来设置字体样式等。                                  |
| RichText    |富文本，通过设置`TextSpan`，可以拼接出富文本场景。|
| TextField   | 文本输入框 ：`new TextField(controller: //文本控制器, obscureText: "hint文本");`|
| Image       |  图片加载: `new FadeInImage.assetNetwork(  placeholder: "预览图",   fit: BoxFit.fitWidth,  image: "url");`|
| FlatButton  |按键点击: `new FlatButton(onPressed: () {},child: new Container());`|

那么再次直插主题实现一个简单完整的页面试试。如下方代码：

* 首先我们创建一个StatefulWidget：`DemoPage `。
* 然后在` _DemoPageState` 中，通过`build`创建了一个`Scaffold `。
* Scaffold内包含了一个`AppBar`和一个`ListView`。
* AppBar类似标题了区域，其中设置了 `title `为 Text Widget。
* body是`ListView`,返回了20个之前我们创建过的 DemoItem Widget。

```
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/test/DemoItem.dart';

class DemoPage extends StatefulWidget {
  @override
  _DemoPageState createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  @override
  Widget build(BuildContext context) {
    ///一个页面的开始
    ///如果是新页面，会自带返回按键
    return new Scaffold(
      ///背景样式
      backgroundColor: Colors.blue,
      ///标题栏，当然不仅仅是标题栏
      appBar: new AppBar(
        ///这个title是一个Widget
        title: new Text("Title"),
      ),
      ///正式的页面开始
      ///一个ListView，20个Item
      body: new ListView.builder(
        itemBuilder: (context, index) {
          return new DemoItem();
        },
        itemCount: 20,
      ),
    );
  }
}
```

最后我们创建一个StatelessWidget作为入口文件，实现一个`MaterialApp `将上方的`DemoPage`设置为home页面，通过`main`入口执行页面。

```
import 'package:flutter/material.dart';
import 'package:gsy_github_app_flutter/test/DemoPage.dart';

void main() {
  runApp(new DemoApp());
}

class DemoApp extends StatelessWidget {
  DemoApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(home: DemoPage());
  }
}

```


![最终显示](http://img.cdn.guoshuyu.cn/20190604_Flutter-1/image3)


好吧，第一部分终于完了，这里主要讲解都是一些简单基础的东西，适合安利入坑，后续更多实战等你开启

### 资源推荐

* Github ： [https://github.com/CarGuo/](https://github.com/CarGuo)
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**

##### 完整开源项目推荐：

*  [本文相关 ：GSYGithubAppFlutter](https://github.com/CarGuo/GSYGithubAppFlutter)
* [GSYGithubAppWeex](https://github.com/CarGuo/GSYGithubAppWeex)
* [GSYGithubApp React Native](https://github.com/CarGuo/GSYGithubApp )


![](http://img.cdn.guoshuyu.cn/20190604_Flutter-1/image4)
