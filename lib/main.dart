import 'package:flutter/material.dart';
import 'package:gsy_flutter_demo/widget/clip_demo_page.dart';
import 'package:gsy_flutter_demo/widget/controller_demo_page.dart';
import 'package:gsy_flutter_demo/widget/scroll_listener_demo_page.dart';
import 'package:gsy_flutter_demo/widget/scroll_to_index_demo_page.dart';
import 'package:gsy_flutter_demo/widget/scroll_to_index_demo_page2.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
      routes: routers,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    var routeLists = routers.keys.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: new Container(
        child: new ListView.builder(
          itemBuilder: (context, index) {
            return new InkWell(
              onTap: () {
                Navigator.of(context).pushNamed(routeLists[index]);
              },
              child: new Card(
                child: new Container(
                  alignment: Alignment.centerLeft,
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  height: 50,
                  child: new Text(routerName[index]),
                ),
              ),
            );
          },
          itemCount: routers.length,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

const routerName = [
  "Controller 例子",
  "圆角 例子",
  "滑动监听 例子",
  "滑动到指定位置 例子",
  "滑动到指定位置2 例子",
];

Map<String, WidgetBuilder> routers = {
  "widget/controller": (context) {
    return new ControllerDemoPage();
  },
  "widget/clip": (context) {
    return new ClipDemoPage();
  },
  "widget/scroll": (context) {
    return new ScrollListenerDemoPage();
  },
  "widget/scroll_index": (context) {
    return new ScrollToIndexDemoPage();
  },
  "widget/scroll_index2": (context) {
    return new ScrollToIndexDemoPage2();
  },


};
