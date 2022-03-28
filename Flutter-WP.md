
Flutter Web 作为 Flutter 框架中最特殊的平台，由于 Web 平台的特殊性，它默认就具备了两种不同的渲染引擎：

- html ： 通过平台的 canvas 和 Element 完成布局绘制；
- canvaskit  ： 通过  Webassembly + Skia 绘制控件；

虽然都知道 canvavskit  更接近 Flutter 的设计理念，**但是由于它构建的 wasm 文件大小和字体加载等问题带来的成本考虑，业界一般会选用更轻量化的 html 引擎**，而今天的问题也是基于 html 引擎来展开。

> **本篇算是目前少有关于 `deferred-components` 和 Flutter Web 构建过程分析的文章**。

## 一、deferred-components

我们都知道 Flutter Web 打包构建后的 `main.dart.js` 文件会很大，所以**一般都会采用一些方法来对包大小进行优化，而其中最常用的方式之一就是使用  [deferred-components](https://docs.flutter.dev/perf/deferred-components) **。

> 对于 `deferred-components` 官方起初主要是用于支持 Android App Bundle 上的动态发布，而经过适配后这项能力被很好地拓展到了 Web 上，通过 `deferred-components` 可以方便地根据需求来拆分  `main.dart.js` 文件的大小。

当然这里并不是介绍如何使用  `deferred-components`  ，而是在使用  `deferred-components`  时，**遇到了一个关于 Flutter Web 在打包构建上的神奇问题**。

首先，代码如下图所示，可以看到，这里主要是**通过 `deferred as`  关键字将一个普通页面变成  `deferred-components`   ，然后在路由打开时通过 `libraryFuture` 加载后渲染页面**。

![image-20220325173721875](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image1)

这里省略了无关的 yaml 文件代码，*那么上述简略的代码，大家觉得有没有什么问题* ？

一开始我也觉得没什么问题， 通过 `flutter run -d chrome --web-renderer html `  运行到浏览器调试也没问题，页面都可以正常加载打开，**但是当我通过 ` flutter build  web --release --web-renderer  html` 打包部署到服务器后，打开时却遇到了这个问题**：

```
Deferred library scroll_listener_demo_page was not loaded.
main.dart.js:16911     at Object.d (http://localhost:64553/main.dart.js:3532:3)
main.dart.js:16911     at Object.aL (http://localhost:64553/main.dart.js:3690:34)
main.dart.js:16911     at asV.$1 (http://localhost:64553/main.dart.js:54352:3)
main.dart.js:16911     at pB.BE (http://localhost:64553/main.dart.js:36580:23)
main.dart.js:16911     at akx.$1 (http://localhost:64553/main.dart.js:51891:10)
main.dart.js:16911     at eT.t (http://localhost:64553/main.dart.js:47281:22)
main.dart.js:16911     at Cw.bp (http://localhost:64553/main.dart.js:48714:51)
main.dart.js:16911     at Cw.ih (http://localhost:64553/main.dart.js:48691:9)
main.dart.js:16911     at Cw.rz (http://localhost:64553/main.dart.js:48659:6)
main.dart.js:16911     at Cw.zk (http://localhost:64553/main.dart.js:48689:11)
```

这就很奇怪了，**明明 debug 运行时没有问题，为什么 release 发布就会 `not loaded` 了？**

经过简单调试和打印发现，在出错时代码时根本进入不到  `ContainerAsyncRouterPage`  这个容器里，也就是在外部就出现了 `not loaded`异常，但是明明 `widget` 是在 `ContainerAsyncRouterPage`  容器内才调用，为什么会在外部就抛出 `not loaded` 的异常？

通过异常信息比对源码发现，**编译时在对于 `deferred as`  进行处理时，会插入一段 `checkDeferredIsLoaded` 的检查逻辑，所以抛出异常的代码是在编译期时处理  `import  * deferred as`  时添加**。



![image-20220325231047005](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image2)

通过查看打包后的文件，可以看到如果在  `checkDeferredIsLoaded`  之前没有完成加载，也就是对应 `importPrefix` 没有被添加到 `set` 里，就会抛出异常。

![image-20220325214838143](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image3)

所以初步推断，问题应该是出现在 debug 和 release  时，对于   `import  * deferred as`    的编译处理有不同之处。

## 二、构建区别

通过资料可以发现，**Flutter  Web 在不同编译期间会使用 `dartdevc` 和 `dart2js` 两个不同的编译器**，而如下图所示，**默认 debug 运行到 chrome 时采用的是 `dartdevc` ，因为 `dartdevc`  支持增量编译**，所以可以很方便用 hot reload 来调试，通过这种方式运行的 Flutter Web 并不会在 build 目录下生成 web 目录，而是会在 build 目录下生成一个临时的 `*.cache.dill.track.dill` 用于加载和更新。

![image-20220325165759471](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image4)

> .dill 属于 Flutter 编译过程的中间文件，该文件一般是二进制的编码，如果想要查看它的内容，可以在完整版 `dart-sdk` 的`/Users/xxxxx/workspace/dart-sdk/pkg/vm/bin` 目录下）执行 `dart dump_kernel.dart xxx.dill  output.dill.txt` 查看，注意是完整版 dart-sdk 。

而 Flutter  Web 在 release 编译时，如下图所示，**会经过 `flutter_tools` 的  `web.dart` 内的对应配置逻辑进行打包，使用的是 `dart2js` 的命令**，打包后会在 build 下生成包含 main.dart.js 等产物的 web目录，而打包过程中的产物，例如 `app.dill`  则是存在 `.dart_tool/flutter_build/一串特别编码/` 目录下。

![image-20220325164442683](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image5)

> .dart_tool/flutter_build/ 目录下根据编译平台会输出不同的编译过程目录，点开可以看到是带 armeabi-v7a 之类的一般是 Android 、带有 *.framework  的一般是 iOS ，带有 main.dart.js  的一般是 Web 。

而打开 `web.dart` 文件可以看到很多可配置参数，其中关键的比如：

- --no-source-maps ： 是否需要生成 source-maps ；
- -O4 ：代表着优化等级，默认就是 -O4，dart2js 支持 O0-O4，其中 0 表示不做任何优化，4 表示优化开到最大；
- --no-minify ： 表示是否混淆压缩 js 代码，默认` build web --profile` 就可以关闭混淆；

![image-20220325180245530](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image6)

所以到这里，我初步怀疑是不是优化等级 -O4 带来的问题，但是正常情况下，Flutter  打包时的 `flutter_tools` 并不是使用源码路径，而是使用以下两个文件：

> `/Users/xxxx/workspace/flutter/bin/cache/flutter_tools.stamp`
>
> `/Users/xxxx/workspace/flutter/bin/cache/flutter_tools.snapshot`

难道就为了改个参数就去编译整个 engine ？这样肯定是不值得的，所幸的是官方提供了使用源码 `flutter_tools` 编译的方式，同样是在项目目录下，通过一下方式就可以用 `flutter_tools`  源码的形式进行编译：

> dart ~/workspace/flutter/packages/flutter_tools/bin/flutter_tools.dart  build web --release --web-renderer html

而在源码里直接将 -O4 调整了 -O0 之后，我发现编译后的 web 居然无法正常运行，但是基于编译后的产物，我可以直接比对它们的差异，如下图所示，左边是 O0，右边是O4：

![image-20220325163734572](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image7)

![image-20220325164259841](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image8)

>  -O0 之后为什么会无法运行有谁知道吗？

首先可以看到， O4 确实做了不少优化从而精简了它们的体积，但是在关键的 `loadDeferredLibrary` 部分基本一样，所以问题并不是出现在这里。

但是到这里可以发现另外一个问题，因为 `loadDeferredLibrary`  方法是异步的，而从编译后的 `js` 代码上看，在执行完  `loadDeferredLibrary`   之后马上就进入到了` checkDeferredIsLoaded` ，这显然存在问题。

那为什么 debug 可以正常执行呢？ 通过查看 debug 运行时的 js 代码，我发现同样的执行逻辑，在   `dartdevc`  构建出来后居然完全不一样。

![image-20220325181735145](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image9)

可以看到 ` checkDeferredIsLoaded`  函数和对应的 `Widget` 是被一起放在逗号表达式里，所以从执行时序上会是和 `Widget` 在调用时被一起被执行，也就是在   `loadDeferredLibrary`    之后，所以代码可以正常运行。

通过断点调试也验证了这个时序问题，在 debug 下会先走完 `loadDeferredLibrary`   的全部逻辑，之后再进入   ` checkDeferredIsLoaded`  。

![image-20220325141938694](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image10)



而在 release 模式下，代码虽然也会先进入  `loadDeferredLibrary` , 但是会在 ` checkDeferredIsLoaded`  执行之后才进入到 `add(0.this.loadId) `，从而导致前面的异常被抛出。



![image-20220325141617745](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image11)

![image-20220325141632451](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image12)

那到这里问题基本就很清楚了，**前面的代码写法在当前（2.10.3）的 Flutter Web 上，经过 dart2js 的 release 编译后会出现某些时序不一致的问题**，知道了问题也很好解决，如下代码所示，只需要把原先代码里的 `Widget` 变成 `WidgetBuilder` 就可以了。

![image-20220325194206188](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image13)

我们再去看 release 编译后的 js 文件，可以看到此时的因为多了 `WidgetBuilder` ，传入的内容变成了 `closure69` ，这样就可以保证在调用到 `call` 之后才触发` checkDeferredIsLoaded` 。

![image-20220325182649022](http://img.cdn.guoshuyu.cn/20220328_Flutter-WP/image14)



## 三、最后

虽然这个问题不难解决，但是通过这个问题去了解 dart2js 的编译和构建过程，可以看到很多平时不会接触的内容，不过**现在我还是不是特别确定是我写法有问题，还是有官方的 dart2js 有 bug** 。

另外 -O0 的转化为什么会不能成功运行也没有头绪，如果有小伙伴知道的欢迎评论告知下～ 。