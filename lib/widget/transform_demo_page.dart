import 'package:flutter/material.dart';

class TransformDemoPage extends StatelessWidget {

  ///头像
  getHeader(context) {
    ///向上偏移 -30 位置
    return Transform.translate(
      offset: Offset(0, -30),
      child: new Container(
        width: 72.0,
        height: 72.0,
        decoration: BoxDecoration(
          ///阴影
          boxShadow: [
            BoxShadow(color: Theme.of(context).cardColor, blurRadius: 4.0)
          ],

          ///形状
          shape: BoxShape.circle,

          ///图片
          image: DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage(
              "static/gsy_cat.png",
            ),
          ),
        ),
      ),
    );

    ///圆形头像还可以 CircleAvatar， ClipOval等实现
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      appBar: AppBar(
        title: new Text("TransformDemoPage"),
      ),
      body: Container(
        alignment: Alignment.center,
        child: new Card(
          margin: EdgeInsets.all(10),
          child: Container(
            height: 150,
            padding: EdgeInsets.all(10),
            child: new Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                getHeader(context),
                new Text(
                  "Flutter is Google's portable UI toolkit for crafting "
                  "beautiful, natively compiled applications for mobile, "
                  "web, and desktop from a single codebase. ",
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  maxLines: 3,
                  style: TextStyle(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
