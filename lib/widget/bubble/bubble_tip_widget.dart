import 'package:flutter/material.dart';

import 'bubble_painter.dart';

///提示弹框
class BubbleTipWidget extends StatefulWidget {
  ///控件高度
  final double height;

  ///控件宽度
  final double width;

  ///控件圆角
  final double radius;

  ///控件文本
  final String text;

  ///需要三角形指向的x坐标
  final double x;

  ///需要三角形指向的y坐标
  final double y;

  ///三角形的位置
  final ArrowLocation arrowLocation;

  final VoidCallback voidCallback;

  const BubbleTipWidget(
      {this.width,
      this.height,
      this.radius,
      this.text = "",
      this.arrowLocation = ArrowLocation.BOTTOM,
      this.voidCallback,
      this.x = 0,
      this.y = 0});

  @override
  State<StatefulWidget> createState() => _BubbleTipWidgetState();
}

class _BubbleTipWidgetState extends State<BubbleTipWidget>
    with SingleTickerProviderStateMixin {
  AnimationController progressController;

  final GlobalKey paintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double arrowHeight = 10;
    double arrowWidth = 10;

    double x = widget.x;
    double y = widget.y;
    Size size = MediaQuery.of(context).size;

    ///计算出位置的中心点
    if (widget.arrowLocation == ArrowLocation.BOTTOM ||
        widget.arrowLocation == ArrowLocation.TOP) {
      x = widget.x - widget.width / 2;
    } else {
      y = widget.y - widget.height / 2;
    }

    ///宽度是否超出
    bool widthOut = (widget.width + x) > size.width || x < 0;

    ///高度是否超出
    bool heightOut = (widget.height + y) > size.height || y < 0;

    ///不能小于0
    if (x < 0) {
      x = 0;
    } else if (widthOut) {
      x = size.width - widget.width;
    }
    if (y < 0) {
      y = 0;
    } else if (heightOut) {
      y = size.height - widget.height;
    }

    ///箭头在这个状态下是否需要居中
    bool arrowCenter = (widget.arrowLocation == ArrowLocation.BOTTOM ||
            widget.arrowLocation == ArrowLocation.TOP)
        ? !widthOut
        : !heightOut;

    ///调整箭头状态，因为此时箭头会可能不是局中的
    double arrowPosition = (widget.arrowLocation == ArrowLocation.BOTTOM ||
            widget.arrowLocation == ArrowLocation.TOP)
        ? (widget.x - x - arrowWidth / 2)
        : (widget.y - y - arrowHeight / 2);

    ///箭头的位置是按照弹出框的左边为起点计算的
    if (widget.arrowLocation == ArrowLocation.BOTTOM ||
        widget.arrowLocation == ArrowLocation.TOP) {
      if (arrowPosition < widget.radius + 2) {
        arrowPosition = widget.radius + 4;
      } else if (arrowPosition > widget.width - widget.radius - 2) {
        arrowPosition = widget.width - widget.radius - 4;
      }
    } else {
      if (arrowPosition < widget.radius + 2) {
        arrowPosition = widget.radius + 4;
      } else if (x > widget.height - widget.radius - 2) {
        arrowPosition = widget.height - widget.radius - 4;
      }
    }

    EdgeInsets margin = EdgeInsets.zero;
    if (widget.arrowLocation == ArrowLocation.TOP) {
      margin = EdgeInsets.only(top: arrowHeight, right: 5, left: 5);
    }

    var bubbleBuild = BubbleBuilder()
      ..mAngle = widget.radius
      ..mArrowHeight = arrowHeight
      ..mArrowWidth = arrowWidth
      ..mArrowPosition = arrowPosition
      ..mArrowLocation = widget.arrowLocation
      ..arrowCenter = arrowCenter;

    var alignment = Alignment.centerLeft;
    if(widget.arrowLocation == ArrowLocation.TOP || widget.arrowLocation ==ArrowLocation.BOTTOM) {
       alignment = Alignment.center;
    }


    return new Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        ///透明可以点击
        behavior: HitTestBehavior.translucent,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          alignment: Alignment.centerLeft,
          width: widget.width,
          height: widget.height,
          margin: EdgeInsets.only(left: x, top: y),
          child: new Stack(
            children: <Widget>[
              ///绘制气泡背景
              CustomPaint(
                  key: paintKey,
                  size: new Size(widget.width, widget.height),
                  painter: bubbleBuild.build()),

              Align(
                alignment: alignment,

                ///显示文本等
                child: new Container(
                  margin: margin,
                  width: widget.width,
                  height: widget.height - arrowHeight,
                  alignment: Alignment.centerLeft,
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      new Container(
                        margin: EdgeInsets.only(left: 20),
                        height: widget.height,
                        child: new Icon(
                          Icons.notifications,
                          size: widget.height - 30,
                          color: Theme.of(context).primaryColorDark,
                        ),
                      ),
                      new Expanded(
                        child: new Container(
                          margin: EdgeInsets.only(left: 5, right: 5),
                          child: new Text(
                            widget.text,
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {}

  void _onPanUpdate(DragUpdateDetails details) {}

  void _onPanEnd(DragEndDetails details) {
    widget.voidCallback?.call();
  }
}
