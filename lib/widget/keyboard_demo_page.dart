import 'package:flutter/material.dart';

///键盘相关Demo
///键盘是否弹起等
class KeyBoardDemoPage extends StatefulWidget {
  @override
  _KeyBoardDemoPageState createState() => _KeyBoardDemoPageState();
}

class _KeyBoardDemoPageState extends State<KeyBoardDemoPage> {
  bool isKeyboardShowing = false;

  final FocusNode _focusNode = new FocusNode();

  @override
  Widget build(BuildContext context) {
    ///必须嵌套在外层
    return KeyboardDetector(
      keyboardShowCallback: (isKeyboardShowing) {
        ///当前键盘是否可见
        setState(() {
          this.isKeyboardShowing = isKeyboardShowing;
        });
      },
      content: Scaffold(
        appBar: AppBar(
          title: new Text("KeyBoardDemoPage"),
        ),
        body: new GestureDetector(
          ///透明可以触摸
          behavior: HitTestBehavior.translucent,
          onTap: () {
            /// 触摸收起键盘
            FocusScope.of(context).requestFocus(new FocusNode());
          },
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                new Expanded(
                  child: new Container(
                    alignment: Alignment.center,
                    child: Text(
                      isKeyboardShowing ? "键盘弹起" : "键盘未弹起",
                      style: TextStyle(
                          color: isKeyboardShowing
                              ? Colors.redAccent
                              : Colors.greenAccent),
                    ),
                  ),
                  flex: 2,
                ),
                new Expanded(
                  child: new Center(
                    child: new FlatButton(
                      onPressed: () {
                        if (!isKeyboardShowing) {
                          /// 触摸收起键盘
                          FocusScope.of(context).requestFocus(_focusNode);
                        }
                      },
                      child: new Text("弹出键盘"),
                    ),
                  ),
                ),
                new Expanded(
                  flex: 2,
                  child: new Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    child: new TextField(
                      focusNode: _focusNode,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef KeyboardShowCallback = void Function(bool isKeyboardShowing);

///监听键盘弹出收起
class KeyboardDetector extends StatefulWidget {
  final KeyboardShowCallback keyboardShowCallback;

  final Widget content;

  KeyboardDetector({this.keyboardShowCallback, @required this.content});

  @override
  _KeyboardDetectorState createState() => _KeyboardDetectorState();
}

class _KeyboardDetectorState extends State<KeyboardDetector>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        widget.keyboardShowCallback
            ?.call(MediaQuery.of(context).viewInsets.bottom > 0);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.content;
  }
}
