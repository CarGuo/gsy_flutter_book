作为系列文章的第二篇，本篇将为你着重展示：**如何搭建一个通用的Flutter App 常用功能脚手架，快速开发一个完整的 Flutter 应用**。

>友情提示：本文所有代码均在 [**GSYGithubAppFlutter**](https://github.com/CarGuo/GSYGithubAppFlutter) ，文中示例代码均可在其中找到，看完本篇相信你应该可以轻松完成如下效果。相关基础还请看[篇章一](https://juejin.im/post/5b631d326fb9a04fce524db2)。

![我们的目标是！(￣^￣)ゞ](http://img.cdn.guoshuyu.cn/20190604_Flutter-2/image1)


## 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)

## 前言

本篇内容结构如下图，主要分为： **基础控件、数据模块、其他功能** 三部分。每大块中的小模块，除了涉及的功能实现外，对于实现过程中笔者遇到的问题，会一并展开阐述，本系列的最终目的是： **让你感受 Flutter 的愉悦！** 那么就让我们愉悦的往下开始吧！


![我是简陋的下图](http://img.cdn.guoshuyu.cn/20190604_Flutter-2/image2)



## 一、基础控件

*所谓的基础，大概就是砍柴功了吧！*

### 1、Tabbar控件实现

Tabbar 页面是常有需求，而在Flutter中： **Scaffold + AppBar + Tabbar + TabbarView** 是 Tabbar 页面的最简单实现，但在加上 `AutomaticKeepAliveClientMixin`  用于页面 *keepAlive* 之后，早期诸如[#11895](https://github.com/flutter/flutter/issues/11895)的问题便开始成为Crash的元凶，直到 *flutter v0.5.7 sdk* 版本修复后，问题依旧没有完全解决，所以无奈最终修改了实现方案。（1.9.1 stable 中已经修复）

目前笔者是通过 **Scaffold + Appbar + Tabbar + PageView** 来组合实现效果，从而解决上述问题。下面我们直接代码走起，首先作为一个Tabbar Widget，它肯定是一个 `StatefulWidget` ，所以我们先实现它的 `State ` ：

```
 class _GSYTabBarState extends State<GSYTabBarWidget> with SingleTickerProviderStateMixin {
  	///···省略非关键代码
    @override
    void initState() {
      super.initState();
      ///初始化时创建控制器
      ///通过 with SingleTickerProviderStateMixin 实现动画效果。
      _tabController = new TabController(vsync: this, length: _tabItems.length);
    }

    @override
    void dispose() {
      ///页面销毁时，销毁控制器
      _tabController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      ///底部TAbBar模式
      return new Scaffold(
          ///设置侧边滑出 drawer，不需要可以不设置
          drawer: _drawer,
          ///设置悬浮按键，不需要可以不设置
          floatingActionButton: _floatingActionButton,
          ///标题栏
          appBar: new AppBar(
            backgroundColor: _backgroundColor,
            title: _title,
          ),
          ///页面主体，PageView，用于承载Tab对应的页面
          body: new PageView(
            ///必须有的控制器，与tabBar的控制器同步
            controller: _pageController,
            ///每一个 tab 对应的页面主体，是一个List<Widget>
            children: _tabViews,
            onPageChanged: (index) {
              ///页面触摸作用滑动回调，用于同步tab选中状态
              _tabController.animateTo(index);
            },
          ),
          ///底部导航栏，也就是tab栏
          bottomNavigationBar: new Material(
            color: _backgroundColor,
            ///tabBar控件
            child: new TabBar(
              ///必须有的控制器，与pageView的控制器同步
              controller: _tabController,
              ///每一个tab item，是一个List<Widget>
              tabs: _tabItems,
              ///tab底部选中条颜色
              indicatorColor: _indicatorColor,
            ),
          ));
    }
  }
```

如上代码所示，这是一个 *底部 TabBar* 的页面的效果。TabBar 和 PageView 之间通过 `_pageController` 和 `_tabController` 实现 Tab 和页面的同步，通过 `SingleTickerProviderStateMixin ` 实现 Tab 的动画切换效果 *(ps 如果有需要多个嵌套动画效果，你可能需要`TickerProviderStateMixin`)*，从代码中我们可以看到：

* 手动左右滑动 `PageView ` 时，通过 `onPageChanged` 回调调用 `_tabController.animateTo(index);` 同步TabBar状态。

* _tabItems 中，监听每个 TabBarItem 的点击，通过  `_pageController`  实现PageView的状态同步。


而上面代码还缺少了 TabBarItem 的点击，因为这块被放到了外部实现。当然你也可以直接在内部封装好控件，直接传递配置数据显示，这个可以根据个人需要封装。

外部调用代码如下：每个 Tabbar 点击时，通过`pageController.jumpTo` 跳转页面，每个页面需要跳转坐标为：**当前屏幕大小乘以索引 index** 。

```
class _TabBarBottomPageWidgetState extends State<TabBarBottomPageWidget> {

  final PageController pageController = new PageController();
  final List<String> tab = ["动态", "趋势", "我的"];

  ///渲染底部Tab
  _renderTab() {
    List<Widget> list = new List();
    for (int i = 0; i < tab.length; i++) {
      list.add(new FlatButton(onPressed: () {
      	///每个 Tabbar 点击时，通过jumpTo 跳转页面
      	///每个页面需要跳转坐标为：当前屏幕大小 * 索引index。
        topPageControl.jumpTo(MediaQuery
            .of(context)
            .size
            .width * i);
      }, child: new Text(
        tab[i],
        maxLines: 1,
      )));
    }
    return list;
  }

  ///渲染Tab 对应页面
  _renderPage() {
    return [
      new TabBarPageFirst(),
      new TabBarPageSecond(),
      new TabBarPageThree(),
    ];
  }


  @override
  Widget build(BuildContext context) {
    ///带 Scaffold 的Tabbar页面
    return new GSYTabBarWidget(
        type: GSYTabBarWidget.BOTTOM_TAB,
        ///渲染tab
        tabItems: _renderTab(),
        ///渲染页面
        tabViews: _renderPage(),
        topPageControl: pageController,
        backgroundColor: Colors.black45,
        indicatorColor: Colors.white,
        title: new Text("GSYGithubFlutter"));
  }
}
```

如果到此结束，你会发现页面点击切换时，`StatefulWidget` 的子页面每次都会重新调用`initState`。这肯定不是我们想要的，所以这时你就需要`AutomaticKeepAliveClientMixin`  。

每个 Tab 对应的 `StatefulWidget ` 的 State ，需要通过` with AutomaticKeepAliveClientMixin` ，然后重写 ` @override bool get wantKeepAlive => true;` ，就可以实不重新构建的效果了，效果如下图。

![页面效果](http://img.cdn.guoshuyu.cn/20190604_Flutter-2/image3)

既然底部Tab页面都实现了，干脆顶部tab页面也一起完成。如下代码，和底部Tab页的区别在于：

* 底部tab是放在了 `Scaffold` 的 `bottomNavigationBar` 中。
* 顶部tab是放在 `AppBar` 的 `bottom` 中，也就是标题栏之下。

同时我们在顶部 TabBar 增加 `isScrollable: true` 属性，实现常见的顶部Tab的效果，如下方图片所示。

```
    return new Scaffold(
        ///设置侧边滑出 drawer，不需要可以不设置
        drawer: _drawer,
        ///设置悬浮按键，不需要可以不设置
        floatingActionButton: _floatingActionButton,
        ///标题栏
        appBar: new AppBar(
          backgroundColor: _backgroundColor,
          title: _title,
          ///tabBar控件
          bottom: new TabBar(
            ///顶部时，tabBar为可以滑动的模式
            isScrollable: true,
            ///必须有的控制器，与pageView的控制器同步
            controller: _tabController,
            ///每一个tab item，是一个List<Widget>
            tabs: _tabItems,
            ///tab底部选中条颜色
            indicatorColor: _indicatorColor,
          ),
        ),
        ///页面主体，PageView，用于承载Tab对应的页面
        body: new PageView(
          ///必须有的控制器，与tabBar的控制器同步
          controller: _pageController,
          ///每一个 tab 对应的页面主体，是一个List<Widget>
          children: _tabViews,
          ///页面触摸作用滑动回调，用于同步tab选中状态
          onPageChanged: (index) {
            _tabController.animateTo(index);
          },
        ),
      );
```


![顶部TabBar效果](http://img.cdn.guoshuyu.cn/20190604_Flutter-2/image4)

在 TabBar  页面中，一般还会出现：**父页面需要控制 PageView 中子页的需求**，这时候就需要用到`GlobalKey`了，比如 `GlobalKey<PageOneState> stateOne = new GlobalKey<PageOneState>();` ，通过 globalKey.currentState 对象，你就可以调用到 PageOneState 中的公开方法，这里需要注意 `GlobalKey` 实例需要全局唯一。

### 2、上下刷新列表

*毫无争议，必备控件*。

Flutter 中 为我们提供了 `RefreshIndicator` 作为内置下拉刷新控件；同时我们通过给 `ListView` 添加 `ScrollController` 做滑动监听，在最后增加一个 Item， 作为上滑加载更多的 Loading 显示。

如下代码所示，通过 `RefreshIndicator`  控件可以简单完成下拉刷新工作，这里需要注意一点是：**可以利用 `GlobalKey<RefreshIndicatorState>` 对外提供 `RefreshIndicator` 的 `RefreshIndicatorState`，这样外部就 可以通过 GlobalKey 调用 ` globalKey.currentState.show(); `，主动显示刷新状态并触发 `onRefresh`** 。

**上拉加载更多**在代码中是通过  ` _getListCount() ` 方法，在原本的数据基础上，增加实际需要渲染的 item 数量给 ListView 实现的，最后**通过 `ScrollController` 监听到底部，触发 `onLoadMore`**。

 如下代码所示，通过  ` _getListCount() ` 方法，还可以配置空页面，头部等常用效果。其实就是**在内部通过改变实际item数量与渲染Item，以实现更多配置效果**。

```
class _GSYPullLoadWidgetState extends State<GSYPullLoadWidget> {
  ///···
  final ScrollController _scrollController = new ScrollController();

  @override
  void initState() {
    ///增加滑动监听
    _scrollController.addListener(() {
      ///判断当前滑动位置是不是到达底部，触发加载更多回调
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (this.onLoadMore != null && this.control.needLoadMore) {
          this.onLoadMore();
        }
      }
    });
    super.initState();
  }

  ///根据配置状态返回实际列表数量
  ///实际上这里可以根据你的需要做更多的处理
  ///比如多个头部，是否需要空页面，是否需要显示加载更多。
  _getListCount() {
    ///是否需要头部
    if (control.needHeader) {
      ///如果需要头部，用Item 0 的 Widget 作为ListView的头部
      ///列表数量大于0时，因为头部和底部加载更多选项，需要对列表数据总数+2
      return (control.dataList.length > 0) ? control.dataList.length + 2 : control.dataList.length + 1;
    } else {
      ///如果不需要头部，在没有数据时，固定返回数量1用于空页面呈现
      if (control.dataList.length == 0) {
        return 1;
      }

      ///如果有数据,因为部加载更多选项，需要对列表数据总数+1
      return (control.dataList.length > 0) ? control.dataList.length + 1 : control.dataList.length;
    }
  }

  ///根据配置状态返回实际列表渲染Item
  _getItem(int index) {
    if (!control.needHeader && index == control.dataList.length && control.dataList.length != 0) {
      ///如果不需要头部，并且数据不为0，当index等于数据长度时，渲染加载更多Item（因为index是从0开始）
      return _buildProgressIndicator();
    } else if (control.needHeader && index == _getListCount() - 1 && control.dataList.length != 0) {
      ///如果需要头部，并且数据不为0，当index等于实际渲染长度 - 1时，渲染加载更多Item（因为index是从0开始）
      return _buildProgressIndicator();
    } else if (!control.needHeader && control.dataList.length == 0) {
      ///如果不需要头部，并且数据为0，渲染空页面
      return _buildEmpty();
    } else {
      ///回调外部正常渲染Item，如果这里有需要，可以直接返回相对位置的index
      return itemBuilder(context, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new RefreshIndicator(
      ///GlobalKey，用户外部获取RefreshIndicator的State，做显示刷新
      key: refreshKey,
      ///下拉刷新触发，返回的是一个Future
      onRefresh: onRefresh,
      child: new ListView.builder(
        ///保持ListView任何情况都能滚动，解决在RefreshIndicator的兼容问题。
        physics: const AlwaysScrollableScrollPhysics(),
        ///根据状态返回子孔健
        itemBuilder: (context, index) {
          return _getItem(index);
        },
        ///根据状态返回数量
        itemCount: _getListCount(),
        ///滑动监听
        controller: _scrollController,
      ),
    );
  }
  
  ///空页面
  Widget _buildEmpty() {
     ///···
  }

  ///上拉加载更多
  Widget _buildProgressIndicator() {
     ///···
  }
}
```


![效果如图](http://img.cdn.guoshuyu.cn/20190604_Flutter-2/image5)


### 3、Loading框

在上一小节中，我们实现上滑加载更多的效果，其中就需要展示 Loading 状态的需求。默认系统提供了`CircularProgressIndicator`等，但是有追求的我们怎么可能局限于此，这里推荐一个第三方 Loading 库 ：[flutter_spinkit](https://pub.flutter-io.cn/packages/flutter_spinkit) ，通过简单的配置就可以使用丰富的 Loading 样式。

继续上一小节中的 `_buildProgressIndicator `方法实现，通过 flutter_spinkit 可以快速实现更不一样的 Loading 样式。

```
 ///上拉加载更多
  Widget _buildProgressIndicator() {
    ///是否需要显示上拉加载更多的loading
    Widget bottomWidget = (control.needLoadMore)
        ? new Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            ///loading框
            new SpinKitRotatingCircle(color: Color(0xFF24292E)),
            new Container(
              width: 5.0,
            ),
            ///加载中文本
            new Text(
              "加载中···",
              style: TextStyle(
                color: Color(0xFF121917),
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            )
          ])
          /// 不需要加载
        : new Container();
    return new Padding(
      padding: const EdgeInsets.all(20.0),
      child: new Center(
        child: bottomWidget,
      ),
    );
  }
```

![loading样式](http://img.cdn.guoshuyu.cn/20190604_Flutter-2/image6)

### 4、矢量图标库

**矢量图标**对笔者是必不可少的，比起一般的 png 图片文件，矢量图标在开发过程中：**可以轻松定义颜色，并且任意调整大小不模糊**。矢量图标库是引入 ttf 字体库文件实现，在 Flutter 中通过 `Icon` 控件，加载对应的 `IconData` 显示即可。

Flutter 中默认内置的 `Icons` 类就提供了丰富的图标，直接通过 `Icons` 对象即可使用，同时个人推荐阿里爸爸的 **iconfont** 。如下代码，通过在 `pubspec.yaml` 中添加字体库支持，然后在代码中创建 `IconData` 指向字体库名称引用即可。

```
  fonts:
    - family: wxcIconFont
      fonts:
        - asset: static/font/iconfont.ttf

··················
          ///使用Icons
          new Tab(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[new Icon(Icons.list, size: 16.0), new Text("趋势")],
            ),
          ),
         ///使用iconfont
          new Tab(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[new Icon(IconData(0xe6d0, fontFamily: "wxcIconFont"), size: 16.0), new Text("我的")],
            ),
          )
```



### 5、路由跳转

Flutter 中的页面跳转是通过 `Navigator`  实现的，路由跳转又分为：**带参数跳转和不带参数跳转**。不带参数跳转比较简单，默认可以通过 MaterialApp 的路由表跳转；而带参数的跳转，参数通过跳转页面的构造方法传递。常用的跳转有如下几种使用：

> 新版本开始可以给 `pushNamed` 设置 `arguments` 参数，然后在新页面通过 `ModalRoute.of(context).settings.arguments` 获取。

```
///不带参数的路由表跳转
Navigator.pushNamed(context, routeName);

///跳转新页面并且替换，比如登录页跳转主页
Navigator.pushReplacementNamed(context, routeName);

///跳转到新的路由，并且关闭给定路由的之前的所有页面
Navigator.pushNamedAndRemoveUntil(context, '/calendar', ModalRoute.withName('/'));

///带参数的路由跳转，并且监听返回
Navigator.push(context, new MaterialPageRoute(builder: (context) => new NotifyPage())).then((res) {
      ///获取返回处理
    });
```

同时我们可以看到，Navigator 的 push 返回的是一个 `Future`，这个`Future ` 的作用是**在页面返回时被调用的**。也就是你可以通过 `Navigator` 的 `pop` 时返回参数，之后在 `Future` 中可以的监听中处理页面的返回结果。


```
@optionalTypeArgs
static Future<T> push<T extends Object>(BuildContext context, Route<T> route) {
  return Navigator.of(context).push(route);
}
```

![中场休息](http://img.cdn.guoshuyu.cn/20190604_Flutter-2/image7)


## 二、数据模块

*数据为王，不过应该不是隔壁老王吧。*

### 1、网络请求

当前 Flutter 网络请求封装中，国内最受欢迎的就是 [Dio](https://github.com/flutterchina/dio) 了，Dio 封装了网络请求中的**数据转换、拦截器、请求返回**等。如下代码所示，通过对 Dio 的简单封装即可快速网络请求，真的很简单，更多的可以查 Dio 的官方文档，这里就不展开了。

```
    ///创建网络请求对象，主要最好吧 dio 实例全局单里
    Dio dio = new Dio();
    Response response;
    try {
      ///发起请求
      ///url地址，请求数据，一般为Map或者FormData
      ///options 额外配置，可以配置超时，头部，请求类型，数据响应类型，host等
      response = await dio.request(url, data: params, options: option);
    } on DioError catch (e) {
      ///http错误是通过 DioError 的catch返回的一个对象
    }
```

### 2、Json序列化

在 Flutter 中，json 序列化是有些特殊的，不同与 JS ，比如使用上述 Dio 网络请求返回，如果配置了返回数据格式为 **json** ，实际上的到会是一个Map。而 Map 的 key-value 使用，在开发过程中并不是很方便，所以你需要对Map 再进行一次转化，转为实际的 Model 实体。

所以 `json_serializable` 插件诞生了，  [中文网Json](https://flutterchina.club/json/) 对其已有一段教程，这里主要补充说明下具体的使用逻辑。

```
dependencies:
  # Your other regular dependencies here
  json_annotation: ^0.2.2

dev_dependencies:
  # Your other dev_dependencies here
  build_runner: ^0.7.6
  json_serializable: ^0.3.2
```

如下发代码所示：

* 创建你的实体 Model 之后，继承 Object 、然后通过 `@JsonSerializable()` 标记类名。

* 通过 `with  _$TemplateSerializerMixin`，将 `fromJson` 方法委托到  `Template.g.dart` 的实现中。 其中 `*.g.dart`、`_$* SerializerMixin`、`_$*FromJson`  这三个的引入， 和 **Model 所在的 dart 的文件名与 Model 类名**有关，具体可见代码注释和后面图片。

* 最后通过 `flutter packages pub run build_runner build` 编译自动生成转化对象。（个人习惯完成后手动编译）

```
import 'package:json_annotation/json_annotation.dart';

///关联文件、允许Template访问 Template.g.dart 中的私有方法
///Template.g.dart 是通过命令生成的文件。名称为 xx.g.dart，其中 xx 为当前 dart 文件名称
///Template.g.dart中创建了抽象类_$TemplateSerializerMixin，实现了_$TemplateFromJson方法
part 'Template.g.dart';

///标志class需要实现json序列化功能
@JsonSerializable()

///'xx.g.dart'文件中，默认会根据当前类名如 AA 生成 _$AASerializerMixin
///所以当前类名为Template，生成的抽象类为 _$TemplateSerializerMixin
class Template extends Object with _$TemplateSerializerMixin {

  String name;

  int id;

  ///通过JsonKey重新定义参数名
  @JsonKey(name: "push_id")
  int pushId;

  Template(this.name, this.id, this.pushId);

  ///'xx.g.dart'文件中，默认会根据当前类名如 AA 生成 _$AAeFromJson方法
  ///所以当前类名为Template，生成的抽象类为 _$TemplateFromJson
  factory Template.fromJson(Map<String, dynamic> json) => _$TemplateFromJson(json);
}

```


![序列化源码部分](http://img.cdn.guoshuyu.cn/20190604_Flutter-2/image8)

上述操作生成后的 `Template.g.dart` 下的代码如下，这样我们就可以通过 `Template.fromJson` 和` toJson` 方法对实体与map进行转化，再结合`json.decode` 和 `json.encode`，你就可以愉悦的在**string 、map、实体间相互转化了**。

```

part of 'Template.dart';

Template _$TemplateFromJson(Map<String, dynamic> json) => new Template(
    json['name'] as String, json['id'] as int, json['push_id'] as int);

abstract class _$TemplateSerializerMixin {
  String get name;
  int get id;
  int get pushId;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'name': name, 'id': id, 'push_id': pushId};
}

```

## *注意：新版json序列化中做了部分修改，代码更简单了，详见demo* 。

### 3、Redux

相信在前端领域、*Redux* 并不是一个陌生的概念，作为**全局状态管理机**，用于 Flutter 中再合适不过。如果你没听说过，**Don't worry**，简单来说就是：**它可以跨控件管理、同步State** 。所以 [flutter_redux](https://pub.flutter-io.cn/packages/flutter_redux) 等着你征服它。

大家都知道在 Flutter 中 ，是通过实现 `State` 与 `setState` 来渲染和改变 `StatefulWidget` 的，如果使用了`flutter_redux` 会有怎样的效果？

比如把用户信息存储在 `redux` 的 `store` 中， 好处在于: **比如某个页面修改了当前用户信息，所有绑定的该 State 的控件将由 Redux 自动同步修改，State 可以跨页面共享。**

更多 Redux 的详细就不再展开，后续会有详细介绍，接下来我们讲讲 flutter_redux 的使用，在 redux 中主要引入了 *action、reducer、store* 概念。

* action 用于定义一个数据变化的请求。
* reducer 用于根据 action 产生新状态
* store 用于存储和管理 state，监听 action，将 action 自动分配给 reducer 并根据 reducer 的执行结果更新 state。

&emsp; 所以如下代码，我们先创建一个 State 用于存储需要保存的对象，其中关键代码在于 ` UserReducer `。

```
///全局Redux store 的对象，保存State数据
class GSYState {
  ///用户信息
  User userInfo;
  ///构造方法
  GSYState({this.userInfo});

}

///通过 Reducer 创建 用于store 的 Reducer
GSYState appReducer(GSYState state, action) {
  return GSYState(
    ///通过 UserReducer 将 GSYState 内的 userInfo 和 action 关联在一起
    userInfo: UserReducer(state.userInfo, action),
  );
}
```

下面是上方使用的  `UserReducer` 的实现，这里主要通过 `TypedReducer` 将 reducer 的处理逻辑与定义的 Action 绑定，最后通过 `combineReducers`  返回 `Reducer<State>`  对象应用于上方 Store 中。

```
/// redux 的 combineReducers, 通过 TypedReducer 将 UpdateUserAction 与 reducers 关联起来
final UserReducer = combineReducers<User>([
  TypedReducer<User, UpdateUserAction>(_updateLoaded),
]);

/// 如果有 UpdateUserAction 发起一个请求时
/// 就会调用到 _updateLoaded
/// _updateLoaded 这里接受一个新的userInfo，并返回
User _updateLoaded(User user, action) {
  user = action.userInfo;
  return user;
}

///定一个 UpdateUserAction ，用于发起 userInfo 的的改变
///类名随你喜欢定义，只要通过上面TypedReducer绑定就好
class UpdateUserAction {
  final User userInfo;
  UpdateUserAction(this.userInfo);
}

```

下面正式在 Flutter 中引入 store，通过 `StoreProvider` 将创建 的 store 引用到 Flutter 中。

```
void main() {
  runApp(new FlutterReduxApp());
}

class FlutterReduxApp extends StatelessWidget {

  /// 创建Store，引用 GSYState 中的 appReducer 创建的 Reducer
  /// initialState 初始化 State
  final store = new Store<GSYState>(appReducer, initialState: new GSYState(userInfo: User.empty()));

  FlutterReduxApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// 通过 StoreProvider 应用 store
    return new StoreProvider(
      store: store,
      child: new MaterialApp(
        home: DemoUseStorePage(),
      ),
    );
  }
}
```

在下方 DemoUseStorePage 中，通过 `StoreConnector` 将State 绑定到 Widget；通过 `StoreProvider.of ` 可以获取 state 对象；通过 ` dispatch ` 一个 Action 可以更新State。

```
class DemoUseStorePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ///通过 StoreConnector 关联 GSYState 中的 User
    return new StoreConnector<GSYState, User>(
      ///通过 converter 将 GSYState 中的 userInfo返回
      converter: (store) => store.state.userInfo,
      ///在 userInfo 中返回实际渲染的控件
      builder: (context, userInfo) {
        return new Text(
          userInfo.name,
          style: Theme.of(context).textTheme.display1,
        );
      },
    );
  }
}

·····
///通过 StoreProvider.of(context) （带有 StoreProvider 下的 context）
/// 可以任意的位置访问到 state 中的数据
StoreProvider.of(context).state.userInfo;

·····
///通过 dispatch UpdateUserAction，可以更新State
StoreProvider.of(context).dispatch(new UpdateUserAction(newUserInfo));

```

看到这是不是有点想静静了？先不管静静是谁，但是Redux的实用性是应该比静静更吸引人，作为一个有追求的程序猿，多动手撸撸还有什么拿不下的山头是不？更详细的实现请看：[GSYGithubAppFlutter](https://github.com/CarGuo/GSYGithubAppFlutter) 。


### 4、数据库


在 GSYGithubAppFlutter 中，数据库使用的是 [sqflite](https://github.com/tekartik/sqflite) 的封装，其实就是 sqlite 语法的使用而已，有兴趣的可以看看完整代码 [DemoDb.dart](https://github.com/CarGuo/GSYGithubAppFlutter/blob/master/lib/test/DemoDb.dart) 。 这里主要提供一种思路，按照 sqflite 文档提供的方法，重新做了一小些修改，通过定义 **Provider** 操作数据库：

* 在 Provider 中定义**表名**与**数据库字段常量**，用于创建表与字段操作；

* 提供数据库与数据实体之间的映射，比如数据库对象与User对象之间的转化；

* 在调用 Provider 时才先判断表是否创建，然后再返回数据库对象进行用户查询。

如果结合网络请求，通过闭包实现，在需要数据库时先返回数据库，然后通过 `next` 方法将网络请求的方法返回，最后外部可以通过调用`next`方法再执行网络请求。如下所示：

```
    UserDao.getUserInfo(userName, needDb: true).then((res) {
      ///数据库结果
      if (res != null && res.result) {
        setState(() {
          userInfo = res.data;
        });
      }
      return res.next;
    }).then((res) {
      ///网络结果
      if (res != null && res.result) {
        setState(() {
          userInfo = res.data;
        });
      }
    });   
```

## 三、其他功能

*其他功能，只是因为想不到标题。*

### 1、返回按键监听

Flutter 中 ，通过`WillPopScope` 嵌套，可以用于监听处理 Android 返回键的逻辑。其实 `WillPopScope` 并不是监听返回按键，如名字一般，是当前页面将要被pop时触发的回调。

通过`onWillPop `回调返回的`Future`，判断是否响应 pop 。下方代码实现按下返回键时，弹出提示框，按下确定退出App。

```
class HomePage extends StatelessWidget {
  /// 单击提示退出
  Future<bool> _dialogExitApp(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) => new AlertDialog(
              content: new Text("是否退出"),
              actions: <Widget>[
                new FlatButton(onPressed: () => Navigator.of(context).pop(false), child:  new Text("取消")),
                new FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: new Text("确定"))
              ],
            ));
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        ///如果返回 return new Future.value(false); popped 就不会被处理
        ///如果返回 return new Future.value(true); popped 就会触发
        ///这里可以通过 showDialog 弹出确定框，在返回时通过 Navigator.of(context).pop(true);决定是否退出
        return _dialogExitApp(context);
      },
      child: new Container(),
    );
  }
}
```

### 2、前后台监听

`WidgetsBindingObserver` 包含了各种控件的生命周期通知，其中的 `didChangeAppLifecycleState` 就可以用于做前后台状态监听。

```
/// WidgetsBindingObserver 包含了各种控件的生命周期通知
class _HomePageState extends State<HomePage> with WidgetsBindingObserver {

  ///重写 WidgetsBindingObserver 中的 didChangeAppLifecycleState
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ///通过state判断App前后台切换
    if (state == AppLifecycleState.resumed) {

    }
  }

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
```

### 3、键盘焦点处理

一般触摸收起键盘也是常见需求，如下代码所示， `GestureDetector` + `FocusScope` 可以满足这一需求。

```
class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
      ///定义触摸层
      return new GestureDetector(
        ///透明也响应处理
        behavior: HitTestBehavior.translucent,
        onTap: () {
          ///触摸手气键盘
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: new Container(
        ),
      );
  }
}
```

### 4、启动页

IOS启动页，在`ios/Runner/Assets.xcassets/LaunchImage.imageset/`下， 有 **Contents.json** 文件和启动图片，将你的启动页放置在这个目录下，并且修改 **Contents.json** 即可，具体尺寸自行谷歌即可。

Android启动页，在 `android/app/src/main/res/drawable/launch_background.xml` 中已经有写好的启动页，`<item><bitmap>` 部分被屏蔽，只需要打开这个屏蔽，并且将你启动图修改为`launch_image`并放置到各个 **mipmap** 文件夹即可，记得各个文件夹下提供相对于大小尺寸的文件。

>自此，第二篇终于结束了！(///▽///)

## 资源推荐

* Github ： [https://github.com/CarGuo/](https://github.com/CarGuo)
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**

#### 完整开源项目推荐：

* [GSYGithubAppWeex](https://github.com/CarGuo/GSYGithubAppWeex)
* [GSYGithubApp React Native](https://github.com/CarGuo/GSYGithubApp ) 


![我们还会再见的](http://img.cdn.guoshuyu.cn/20190604_Flutter-2/image9)
