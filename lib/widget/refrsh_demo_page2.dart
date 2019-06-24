import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///刷新演示2
///比较粗略，没有做互斥等
///详细使用还请查看 https://github.com/CarGuo/GSYGithubAppFlutter
class RefreshDemoPage2 extends StatefulWidget {
  @override
  _RefreshDemoPageState2 createState() => _RefreshDemoPageState2();
}

class _RefreshDemoPageState2 extends State<RefreshDemoPage2> {
  final int pageSize = 30;

  List<String> dataList = new List();

  final ScrollController _scrollController = new ScrollController();

  Future<void> onRefresh() async {
    await Future.delayed(Duration(seconds: 2));
    dataList.clear();
    for (int i = 0; i < pageSize; i++) {
      dataList.add("refresh");
    }
    setState(() {});
  }

  Future<void> loadMore() async {
    await Future.delayed(Duration(seconds: 2));
    for (int i = 0; i < pageSize; i++) {
      dataList.add("loadmore");
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    ///直接触发下拉
    new Future.delayed(const Duration(milliseconds: 500), () {
      _scrollController.animateTo(-141,
          duration: Duration(milliseconds: 600), curve: Curves.linear);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: new Text("RefreshDemoPage"),
      ),
      body: Container(
        child: new NotificationListener(
          onNotification: (ScrollNotification notification) {
            ///判断当前滑动位置是不是到达底部，触发加载更多回调
            if (notification is ScrollEndNotification) {
              if (_scrollController.position.pixels > 0 &&
                  _scrollController.position.pixels ==
                      _scrollController.position.maxScrollExtent) {
                loadMore();
              }
            }
            return false;
          },
          child: CustomScrollView(
            controller: _scrollController,

            ///回弹效果
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: <Widget>[
              ///控制显示刷新的 CupertinoSliverRefreshControl
              CupertinoSliverRefreshControl(
                refreshIndicatorExtent: 100,
                refreshTriggerPullDistance: 140,
                onRefresh: onRefresh,
              ),

              ///列表区域
              SliverSafeArea(
                sliver: SliverList(
                  ///代理显示
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      if (index == dataList.length) {
                        return new Container(
                          margin: EdgeInsets.all(10),
                          child: Align(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return Card(
                        child: new Container(
                          height: 60,
                          alignment: Alignment.centerLeft,
                          child: new Text("Item ${dataList[index]} $index"),
                        ),
                      );
                    },
                    childCount: (dataList.length >= pageSize)
                        ? dataList.length + 1
                        : dataList.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
