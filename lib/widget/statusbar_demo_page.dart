import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///状态栏颜色
class StatusBarDemoPage extends StatefulWidget {
  @override
  _StatusBarDemoPageState createState() => _StatusBarDemoPageState();
}

class _StatusBarDemoPageState extends State<StatusBarDemoPage> {
  bool customSystemUIOverlayStyle = false;

  @override
  Widget build(BuildContext context) {
    var body = getBody();
    ///如果手动设置过状态栏，就不可以用 AnnotatedRegion ，会影响
    if (customSystemUIOverlayStyle) {
      return body;
    }
    ///如果没有手动设置过状态栏，就可以用 AnnotatedRegion 直接嵌套显示
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: body,
    );
  }

  getBody() {
    return Scaffold(
      appBar: ImageAppBar(),
      body: new Container(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              new FlatButton(
                onPressed: () {
                  ///手动修改
                  setState(() {
                    customSystemUIOverlayStyle = true;
                  });
                  SystemChrome.setSystemUIOverlayStyle(
                      SystemUiOverlayStyle.light);
                },
                child: new Text("Light"),
                color: Colors.yellowAccent,
              ),
              new SizedBox(
                width: 10,
              ),
              new FlatButton(
                onPressed: () {
                  setState(() {
                    customSystemUIOverlayStyle = true;
                  });
                  SystemChrome.setSystemUIOverlayStyle(
                      SystemUiOverlayStyle.dark);
                },
                child: new Text("Dart"),
                color: Colors.greenAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

///自定义 PreferredSizeWidget 做 AppBar
class ImageAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          new Image.asset(
            "static/gsy_cat.png",
            fit: BoxFit.cover,
            width: MediaQuery.of(context).size.width,
            height: kToolbarHeight * 3,
          ),
          SafeArea(
            child: new IconButton(
                color: Colors.white,
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
          )
        ],
      ),
    );
  }

  Size get preferredSize => Size.fromHeight(kToolbarHeight * 3);
}
