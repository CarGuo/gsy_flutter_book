import 'package:flutter/material.dart';

///共性元素动画
class HonorDemoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: new Text("HonorDemoPage"),
      ),
      body: Container(
        child: Center(
          child: new InkWell(
            onTap: () {
              Navigator.of(context).push(new MaterialPageRoute(
                  builder: (context) {
                    return HonorPage();
                  },
                  fullscreenDialog: true));
            },

            /// Hero  tag 共享
            child: new Hero(
              tag: "image",
              child: new Image.asset(
                "static/gsy_cat.png",
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HonorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.transparent,
      body: new InkWell(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: new Container(
          alignment: Alignment.center,
          child: new Hero(
            tag: "image",
            child: new Image.asset(
              "static/gsy_cat.png",
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width,
            ),
          ),
        ),
      ),
    );
  }
}
