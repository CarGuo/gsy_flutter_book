import 'package:flutter/material.dart';
import 'dart:math' as Math;

///绘制气泡背景
class BubblePainter extends CustomPainter {
  Rect mRect;
  Path mPath = new Path();
  Paint mPaint = new Paint();
  double mArrowWidth;
  double mAngle;
  double mArrowHeight;
  double mArrowPosition;
  ArrowLocation mArrowLocation;
  BubbleType bubbleType;
  bool mArrowCenter = true;
  Color bubbleColor;

  BubblePainter(BubbleBuilder builder) {
    this.mAngle = builder.mAngle;
    this.mArrowHeight = builder.mArrowHeight;
    this.mArrowWidth = builder.mArrowWidth;
    this.mArrowPosition = builder.mArrowPosition;
    this.bubbleColor = builder.bubbleColor;
    this.mArrowLocation = builder.mArrowLocation;
    this.bubbleType = builder.bubbleType;
    this.mArrowCenter = builder.arrowCenter;
  }

  @override
  void paint(Canvas canvas, Size size) {
    setUp(canvas, size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  ///设置绘制路径
  void setUpPath(ArrowLocation mArrowLocation, Path path) {
    switch (mArrowLocation) {
      case ArrowLocation.LEFT:
        setUpLeftPath(mRect, path);
        break;
      case ArrowLocation.RIGHT:
        setUpRightPath(mRect, path);
        break;
      case ArrowLocation.TOP:
        setUpTopPath(mRect, path);
        break;
      case ArrowLocation.BOTTOM:
        setUpBottomPath(mRect, path);
        break;
    }
  }

  ///开始绘制设置
  void setUp(Canvas canvas, Size size) {
    switch (bubbleType) {
      case BubbleType.COLOR:
        mPaint.color = bubbleColor;
        break;
      case BubbleType.BITMAP:
        break;
    }
    mRect ??= new Rect.fromLTRB(0, 0, size.width, size.height);
    setUpPath(mArrowLocation, mPath);
    canvas.drawPath(mPath, mPaint);
  }

  ///绘制左边三角形
  void setUpLeftPath(Rect rect, Path path) {
    if (mArrowCenter) {
      mArrowPosition = (rect.bottom - rect.top) / 2 - mArrowWidth / 2;
    }
    path.moveTo(rect.left + mArrowWidth, mArrowHeight + mArrowPosition);
    path.lineTo(rect.left + mArrowWidth, mArrowHeight + mArrowPosition);
    path.lineTo(rect.left, mArrowPosition + mArrowHeight / 2);
    path.lineTo(rect.left + mArrowWidth, mArrowPosition);
    path.lineTo(rect.left + mArrowWidth, rect.top + mAngle);

    path.addRRect(RRect.fromLTRBR(rect.left + mArrowHeight, rect.top,
        rect.right, rect.bottom, Radius.circular(mAngle)));

    path.close();
  }

  ///绘制顶部三角形
  void setUpTopPath(Rect rect, Path path) {
    if (mArrowCenter) {
      mArrowPosition = (rect.right - rect.left) / 2 - mArrowWidth / 2;
    }

    path.moveTo(
        rect.left + Math.min(mArrowPosition, mAngle), rect.top + mArrowHeight);
    path.lineTo(rect.left + mArrowPosition, rect.top + mArrowHeight);
    path.lineTo(rect.left + mArrowWidth / 2 + mArrowPosition, rect.top);
    path.lineTo(
        rect.left + mArrowWidth + mArrowPosition, rect.top + mArrowHeight);

    path.addRRect(RRect.fromLTRBR(rect.left, rect.top + mArrowHeight,
        rect.right, rect.bottom, Radius.circular(mAngle)));

    path.close();
  }

  ///绘制右边三角形
  void setUpRightPath(Rect rect, Path path) {
    if (mArrowCenter) {
      mArrowPosition = (rect.bottom - rect.top) / 2 - mArrowWidth / 2;
    }

    path.moveTo(rect.right - mArrowWidth, mArrowPosition);

    path.lineTo(rect.right - mArrowWidth, mArrowPosition);
    path.lineTo(rect.right, mArrowPosition + mArrowHeight / 2);
    path.lineTo(rect.right - mArrowWidth, mArrowPosition + mArrowHeight);

    path.moveTo(rect.left + mAngle, rect.top);

    path.addRRect(RRect.fromLTRBR(rect.left, rect.top,
        rect.right - mArrowHeight, rect.bottom, Radius.circular(mAngle)));

    path.close();
  }

  ///绘制底部三角形
  void setUpBottomPath(Rect rect, Path path) {
    if (mArrowCenter) {
      mArrowPosition = (rect.right - rect.left) / 2 - mArrowWidth / 2;
    }
    path.moveTo(
        rect.left + mArrowWidth + mArrowPosition, rect.bottom - mArrowHeight);
    path.lineTo(
        rect.left + mArrowWidth + mArrowPosition, rect.bottom - mArrowHeight);
    path.lineTo(rect.left + mArrowPosition + mArrowWidth / 2, rect.bottom);
    path.lineTo(rect.left + mArrowPosition, rect.bottom - mArrowHeight);

    path.addRRect(RRect.fromLTRBR(rect.left, rect.top, rect.right,
        rect.bottom - mArrowHeight, Radius.circular(mAngle)));

    path.close();
  }
}

class BubbleBuilder {
  static const double DEFAULT_ARROW_WITH = 15;
  static const double DEFAULT_ARROW_HEIGHT = 15;
  static const double DEFAULT_ANGLE = 20;
  static const double DEFAULT_ARROW_POSITION = 50;
  static const Color DEFAULT_BUBBLE_COLOR = Colors.white;

  ///圆角
  double mAngle = DEFAULT_ANGLE;

  ///箭头宽度
  double mArrowWidth = DEFAULT_ARROW_WITH;

  ///箭头高度
  double mArrowHeight = DEFAULT_ARROW_HEIGHT;

  ///箭头位置
  double mArrowPosition = DEFAULT_ARROW_POSITION;

  ///背景颜色
  Color bubbleColor = DEFAULT_BUBBLE_COLOR;

  ///背景类型，颜色
  BubbleType bubbleType = BubbleType.COLOR;

  ///箭头位置
  ArrowLocation mArrowLocation = ArrowLocation.BOTTOM;

  ///箭头是否需要剧中
  bool arrowCenter = true;

  build() {
    return new BubblePainter(this);
  }
}

enum ArrowLocation {
  LEFT,
  RIGHT,
  TOP,
  BOTTOM,
}

enum BubbleType { COLOR, BITMAP }
