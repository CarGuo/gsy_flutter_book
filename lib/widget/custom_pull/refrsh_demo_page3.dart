import 'dart:math';

import 'package:flutter/cupertino.dart' as IOS;
import 'package:flutter/material.dart';
import 'package:gsy_flutter_demo/widget/custom_pull/gsy_refresh_sliver.dart';

///刷新演示3
///在刷新2的基础上，支持了放手位置时需要刷新才触发
///比较粗略，没有做互斥等
///详细使用还请查看 https://github.com/CarGuo/GSYGithubAppFlutter
class RefreshDemoPage3 extends StatefulWidget {
  @override
  _RefreshDemoPageState3 createState() => _RefreshDemoPageState3();
}

class _RefreshDemoPageState3 extends State<RefreshDemoPage3> {
  final GlobalKey<CupertinoSliverRefreshControlState> sliverRefreshKey =
      GlobalKey<CupertinoSliverRefreshControlState>();

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
            ///通知 CupertinoSliverRefreshControl 当前的拖拽状态
            sliverRefreshKey.currentState
                .notifyScrollNotification(notification);
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
                key: sliverRefreshKey,
                refreshIndicatorExtent: 100,
                refreshTriggerPullDistance: 140,
                onRefresh: onRefresh,
                builder: buildSimpleRefreshIndicator,
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

Widget buildSimpleRefreshIndicator(
  BuildContext context,
  RefreshIndicatorMode refreshState,
  double pulledExtent,
  double refreshTriggerPullDistance,
  double refreshIndicatorExtent,
) {
  const Curve opacityCurve = Interval(0.4, 0.8, curve: Curves.easeInOut);
  return Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: refreshState != RefreshIndicatorMode.refresh
          ? Opacity(
              opacity: opacityCurve.transform(
                  min(pulledExtent / refreshTriggerPullDistance, 1.0)),
              child: const Icon(
                IOS.CupertinoIcons.down_arrow,
                color: IOS.CupertinoColors.inactiveGray,
                size: 36.0,
              ),
            )
          : Opacity(
              opacity: opacityCurve
                  .transform(min(pulledExtent / refreshIndicatorExtent, 1.0)),
              child: const IOS.CupertinoActivityIndicator(radius: 14.0),
            ),
    ),
  );
}
