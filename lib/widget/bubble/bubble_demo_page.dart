import 'package:flutter/material.dart';

import 'bubble_painter.dart';
import 'bubble_tip_widget.dart';

///演示提示弹框
class BubbleDemoPage extends StatelessWidget {
  final double bubbleHeight = 60;
  final double bubbleWidth = 120;
  final GlobalKey contentKey = GlobalKey();

  final GlobalKey button1Key = GlobalKey();
  final GlobalKey button2Key = GlobalKey();
  final GlobalKey button3Key = GlobalKey();
  final GlobalKey button4Key = GlobalKey();

  getX(GlobalKey key) {
    RenderBox renderBox = key.currentContext.findRenderObject();
    double dx = renderBox.localToGlobal(Offset.zero).dx;
    return dx;
  }

  getY(GlobalKey key) {
    RenderBox renderBox = key.currentContext.findRenderObject();
    double dy = renderBox.localToGlobal(Offset.zero).dy;
    return dy;
  }

  getWidth(GlobalKey key) {
    RenderBox renderBox = key.currentContext.findRenderObject();
    return renderBox.size.width;
  }

  getHeight(GlobalKey key) {
    RenderBox renderBox = key.currentContext.findRenderObject();
    return renderBox.size.height;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: new Text("BubbleDemoPage"),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        margin: EdgeInsets.all(15),
        child: new Stack(
          key: contentKey,
          children: <Widget>[
            new MaterialButton(
              key: button1Key,
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return BubbleDialog(
                        "Test1",
                        height: bubbleHeight,
                        width: bubbleWidth,
                        arrowLocation: ArrowLocation.TOP,
                        x: getX(button1Key) + getWidth(button1Key) / 2,
                        y: getY(button1Key),
                      );
                    });
              },
              color: Colors.blue,
            ),
            new Positioned(
                child: new MaterialButton(
                  key: button2Key,
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return BubbleDialog(
                            "Test2",
                            height: bubbleHeight,
                            width: bubbleWidth,
                            arrowLocation: ArrowLocation.RIGHT,
                            x: getX(button2Key) - bubbleWidth,
                            y: getY(button2Key) - getHeight(button2Key) / 2,
                          );
                        });
                  },
                  color: Colors.greenAccent,
                ),
                left: MediaQuery.of(context).size.width / 2),
            new Positioned(
              child: new MaterialButton(
                key: button3Key,
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return BubbleDialog(
                          "Test4",
                          height: bubbleHeight,
                          width: bubbleWidth,
                          arrowLocation: ArrowLocation.LEFT,
                          x: getX(button3Key) + getWidth(button4Key),
                          y: getY(button3Key) -
                              getHeight(button4Key) / 2,
                        );
                      });
                },
                color: Colors.yellow,
              ),
              left: MediaQuery.of(context).size.width / 5,
              top: MediaQuery.of(context).size.height / 4 * 3,
            ),
            new Positioned(
              child: new MaterialButton(
                key: button4Key,
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return BubbleDialog(
                          "Test4",
                          height: bubbleHeight,
                          width: bubbleWidth,
                          arrowLocation: ArrowLocation.BOTTOM,
                          x: getX(button4Key) + getWidth(button4Key) / 2,
                          y: getY(button4Key) -
                              bubbleHeight -
                              getHeight(button4Key),
                        );
                      });
                },
                color: Colors.redAccent,
              ),
              left: MediaQuery.of(context).size.width / 2 -
                  Theme.of(context).buttonTheme.minWidth / 2,
              top: MediaQuery.of(context).size.height / 2 -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight,
            ),
          ],
        ),
      ),
    );
  }
}

class BubbleDialog extends StatelessWidget {
  final String text;

  final ArrowLocation arrowLocation;

  ///控件高度
  final double height;

  ///控件宽度
  final double width;

  ///控件圆角
  final double radius;

  ///需要三角形指向的x坐标
  final double x;

  ///需要三角形指向的y坐标
  final double y;

  final VoidCallback voidCallback;

  BubbleDialog(this.text,
      {this.width,
      this.height,
      this.radius = 4,
      this.arrowLocation = ArrowLocation.BOTTOM,
      this.voidCallback,
      this.x = 0,
      this.y = 0});

  confirm(context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.transparent,
      body: new InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () {
          confirm(context);
        },
        child: Container(
          alignment: Alignment.centerLeft,
          child: BubbleTipWidget(
              arrowLocation: arrowLocation,
              width: width,
              height: height,
              radius: radius,
              x: x,
              y: y,
              text: text,
              voidCallback: () {
                confirm(context);
              }),
        ),
      ),
    );
  }
}
