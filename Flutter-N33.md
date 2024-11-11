# Flutter 小技巧之 Row/Column 即将支持  Flex.spacing 

事实上这是一个相当久远的话题，如果对于前因后果不管兴趣，直接看最后就行。

这个需求最早提及应该是 2018 年初在 [#16957](https://github.com/flutter/flutter/issues/16957) 被人提起，因为在 Flutter 上 `Wrap` 有  `runSpacing` 和 `spacing` 用于配置垂直和水平间距，而为什么  `Colum` 和 `Row`  这样更通用的控件居然没有 `spacing`  支持？

而后在 2020 年，Flutter 在 [#55378](https://github.com/flutter/flutter/issues/55378)  用户希望再一次推进  `Row`/`Column` 内置  `spacing`   的实现，但后续从 PM 的角度却认为，这并不是一个很急需的功能，并且正常情况下通过额外的实现也可以做到类似需求，而通过增加 `Flex`  的复杂度来内置这种“非必需”的   `spacing`    完全没必要。

![](http://img.cdn.guoshuyu.cn/20240903_Flutter-N33/image1.png)

![](http://img.cdn.guoshuyu.cn/20240903_Flutter-N33/image2.png)

事实上   `Colum`  和  `Row`  一开始缺乏  `spacing`  相关配置并非 Flutter 特例，早期 Jetpack Compose 同样缺少 `itemSpacing` ，只是四年前  Jetpack Compose 通过了用户的提议，后续才有了 ` Arrangement.spacedBy` 的相关支持，而这也成为了 Flutter 在  `Row`/`Column` 同样需要内置  `spacing`   的有力佐证。

![](http://img.cdn.guoshuyu.cn/20240903_Flutter-N33/image3.png)



另外后续用户的指出，目前众多 UI 框架上只有极少数的  `Row`/`Column`  没有内置   `spacing`   ， 甚至曾经没有的  Jetpack Compose  都提供了，这时候 Flutter 拒绝内置这样一个「实现并不困难」的功能并不理智，所以官方开始松口。

![](http://img.cdn.guoshuyu.cn/20240903_Flutter-N33/image4.png)

而在  **[TahaTesser](https://github.com/TahaTesser)**  的坚持努力下，最后这个需求终于被合并了，而事实上在 `Flex`  上直接支持 `spacing`   确实侵入性很强，因为它确确实实要侵入性到底层的通用代码。

![](http://img.cdn.guoshuyu.cn/20240903_Flutter-N33/image5.png)

> 相信作为程序员大多应该都能衡量，如果因为这样一个 `spacing`  修改，导致一个大量使用的业务代码可能出现问题，那后果绝对是难以接受的，不得不说 TahaTesser 很头铁，正常人应该都不愿意接这个锅。

而从调整的结果看，核心就是根据主轴布局增加了 `spacing` 的支持，最终体现在 `childMainPosition` 上，落地后的改动量其实并不大，所以最终也被成功合并，风险评估不高。

![](http://img.cdn.guoshuyu.cn/20240903_Flutter-N33/image6.png)

![](http://img.cdn.guoshuyu.cn/20240903_Flutter-N33/image7.png)

最后，前面扯了那么多，对于大多数开发者，**其实就是通过 main 分支，现在可以通过 `spacing`  属性配置   `Row`/`Column`  的 child 间距**，另外  [#78200](https://github.com/flutter/flutter/issues/78200)  对于 `PageView`  增加参数指定页面之间的边距的 issue 也被提了出来。

从目前来看，这对于 Flutter 开发者来说是好事，大概下一个 stable 版本应该就可以在  `Row`/`Column`   用上了  `spacing`   了，同时可以看到，只要能提出有力的证据，还是可以推动一些「必要的功能」，当然可能还需要有一个头铁的「哥们」。

```dart
		const Column(
          spacing: 20.0,
          children: <Widget>[
            Row(
              spacing: 50.0,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                ColoredBox(
                  color: Color(0xffff0000),
                  child: SizedBox(
                    width: 50.0,
                    height: 75.0,
                    child: Center(
                      child: Text(
                        'RED',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                ColoredBox(
                  color: Color(0xff00ff00),
                  child: SizedBox(
                    width: 50.0,
                    height: 75.0,
                    child: Center(
                      child: Text(
                        'GREEN',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 100.0,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ColoredBox(
                  color: Color(0xffff0000),
                  child: SizedBox(
                    width: 50.0,
                    height: 75.0,
                    child: Center(
                      child: Text(
                        'RED',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                ColoredBox(
                  color: Color(0xff00ff00),
                  child: SizedBox(
                    width: 50.0,
                    height: 75.0,
                    child: Center(
                      child: Text(
                        'GREEN',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        )
```

![](http://img.cdn.guoshuyu.cn/20240903_Flutter-N33/image8.png)



