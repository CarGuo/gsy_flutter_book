作为系列文章的第十篇，本篇主要深入了解 Flutter 中图片加载的流程，剥析图片流程中有意思的片段，结尾再实现 Flutter 实现本地图片缓存的支持。

## 文章汇总地址：

> [Flutter 完整实战实战系列文章专栏](https://juejin.im/collection/5db25bcff265da06a19a304e)
>
> [Flutter 番外的世界系列文章专栏](https://juejin.im/collection/5db25d706fb9a069f422c374)

在 Flutter 中，图片的加载主要是通过 **`Image`** 控件实现的，而 **`Image`** 控件本身是一个 **StatefulWidget** ，通过前文我们可以快速想到， **`Image`**  肯定对应有它的 **RenderObject** 负责 *layout* 和 *paint* ，那么这个过程中，图片是如何变成画面显示出来的？

## 一、图片流程

Flutter 的图片加载流程其实“并不复杂”，具体可点击下方大图查看，以网络图片加载为例子，先简单总结，其中主要流程是：

- 1、首先 `Image` 通过 `ImageProvider` 得到 `ImageStream` 对象
- 2、然后 `_ImageState` 利用 `ImageStream` 添加监听，等待图片数据
- 3、接着 `ImageProvider`  通过 `load` 方法去加载并返回 `ImageStreamCompleter` 对象
- 4、然后 `ImageStream` 会关联  `ImageStreamCompleter`
- 5、之后 `ImageStreamCompleter ` 会通过 http 下载图片，再经过  `PaintingBinding ` 编码转化后，得到  `ui.Codec ` 可绘制对象，并封装成  `ImageInfo ` 返回
- 6、接着 `ImageInfo ` 回调到   `ImageStream ` 的监听，设置给 `_ImageState`  build 的 `RawImage` 对象。
- 7、最后 `RawImage` 的 `RenderImage` 通过 paint 绘制 `ImageInfo` 中的 `ui.Codec`

> **注意，这的 `ui.Codec` 和后面的  `ui.Image`等，只是因为 Flutter 中在导入对象时，为了和其他类型区分而加入的重命名：`import 'dart:ui' as ui show Codec;`**

**是不是感觉有点晕了？relax！后面我们将逐步理解这个流程。**

![点击大图查看](http://img.cdn.guoshuyu.cn/20190604_Flutter-10/image1)

在 Flutter 的图片的加载流程中，主要有三个角色：

- **`Image`** ：用于显示图片的 Widget，最后通过内部的 **`RenderImage` 绘制**。
- **`ImageProvider`**：提供加载图片的方式如 `NetworkImage` 、`FileImage` 、`MemoryImage` 、`AssetImage` 等，从而获取 **`ImageStream`** ，用于**监听结果**。
- **`ImageStream`**：图片的加载对象，通过 `ImageStreamCompleter ` 最后会返回一个 `ImageInfo` ，而 `ImageInfo` 内包含有  `RenderImage`  最后的**绘制对象 `ui.Image`** 。

从上面的大图流程可知，网络图片是通过  `NetworkImage` 这个 *Provider* 去提供加载的，各类 *Provider* 的实现其实大同小异，其中主要需要实现的方法主要如下图所示：

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-10/image2)

#### 1、obtainKey

该方法主要用于标示当前 `Provider` 的存在，比如在 `NetworkImage` 中，这个方法返回的是 `SynchronousFuture<NetworkImage>(this)`，也就是  `NetworkImage`  自己本身，并且得到的这个 key 在 `ImageProvider` 中，是用于**作为内存缓存的 key 值**。

在 `NetworkImage` 中主要是通过 `runtimeType` 、`url` 、`scale` 这三个参数判断两个`NetworkImage`  是否相等，所以除了 `url` ，图片的 `scale` 同样会影响缓存的对象哦。

#### 2、load(T key)

`load` 方法顾名思义就是加载了，而该方法中所使用的 key ，毫无疑问就是上面  `obtainKey` 方法所提供的。

`load` 方法返回的是 `ImageStreamCompleter`  抽象对象，它主要是用于**管理和通知 `ImageStream` 中得到的 `dart:ui.Image`**  ，比如在 `NetworkImage`  中的是子类 `MultiFrameImageStreamCompleter` , 它可以处理多帧的动画，如果图片只有一针，那么将执行一次都结束。

#### 3、resolve

 `ImageProvider` 的关键在于  `resolve ` 方法，从流程图我们可知，该方法在 `Image` 的生命周期回调方法  `didChangeDependencies ` 、 `didUpdateWidget ` 、 `reassemble` 里会被调用，从下方源码可以看出，上面我们所实现的  `obtainKey ` 和  `load ` 都会在这里被调用

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-10/image3)

> 这个有个有意思的对象，就是 **`Zone`** ！
>
> 因为在 Flutter 中，同步异常可以通过try-catch捕获，而异步异常如 `Future` ，是无法被当前的 try-catch 直接捕获的。
>
> 所以在 Dart中 `Zone` 的概念，你可以给执行对象指定一个`Zone`，类似提供一个沙箱环境，而在这个沙箱内，你就可以全部可以捕获、拦截或修改一些代码行为，比如所有未被处理的异常。

  `resolve ` 方法内主要是用到了 **`PaintingBinding.instance.imageCache.putIfAbsent(key, () => load(key)`** ， `PaintingBinding` 是一个胶水类，主要是通过 Mixins 粘在 `WidgetsFlutterBinding` 上使用，而以前的篇章我们说过，  `WidgetsFlutterBinding` 就是我们的启动方法 `runApp` 的执行者。 

**所以图片缓存是在PaintingBinding.instance.imageCache内单例维护的。**

如下图所示，`putIfAbsent` 方法内部，主要是通过 `key` 判断**内存中是否已有缓存、或者正在缓存的对象**，如果是就返回该 `ImageStreamCompleter ` ，不然就调用 `loader` 去加载并返回。

值得注意的是，此时的的 cache 是有两个状态的，因为返回的 `ImageStreamCompleter ` 并不代表着图片就加载完成，所以如果是首次加载，会先有 **`_PendingImage`** 用于标示该key的图片处于**加载中的状态** ，并且添加一个 `listener`， 用于图片加载完成后，替换为缓存 `_CacheImage` 。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-10/image4)

发现没有，这里和我们理解上的 Cache 概念稍微有点不同，以前我们缓存的一般是 key - bitmap 对象，也就是实际绘制数据，而**在 Flutter 中，缓存的仅是`ImageStreamCompleter ` 对象，而不是实际绘制对象  `dart:ui.Image`** 。

#### 3、ImageStreamCompleter

`ImageStreamCompleter`  是一个抽象对象，它主要是用于**管理和通知 `ImageStream` ，处理图片数据后得到的包含有 `dart:ui.Image` 的对象 ImageInfo** 。

接下来我们看 `NetworkImage` 中的 `ImageStreamCompleter` 实现类 `MultiFrameImageStreamCompleter` 。如下图代码所示，`MultiFrameImageStreamCompleter` 主要通过 `codec` 参数获得渲染数据，而这个数据来源通过 `_loadAsync` 方法得到，该方法主要通过 **http 下载图片后，对图片数据通过 `PaintingBinding` 进行 `ImageCodec` 编码处理，将图片转化为引擎可绘制数据。**

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-10/image5)

而在 `MultiFrameImageStreamCompleter` 内部， `ui.Codec` 会被 `ui.Image` ，通过 `ImageInfo` 封装起来，并逐步往回回调到 `_ImageState` 中，然后通过 `setState` 将数据传递到 `RenderImage` 内部去绘制。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-10/image6)

怎么样，现在再回过头去看开头的流程图，有没有一切明了的感觉？

## 二、本地图片缓存

通过上方流程的了解，我们知道 Flutter 实现了图片的内存缓存，但是并没有实现图片的本地缓存，所以我们入手的点，应该从  `ImageProvider` 开始。

通过上面对  `NetworkImage`  的分析，我们知道图片是在 `_loadAsync` 方法通过 http 下载的，所以最简单的就是，我们从   `NetworkImage` cv 一份代码，修改   `_loadAsync`  支持 http 下载前读取本地缓存，下载后通过将数据保存在本地。

结合 `flutter_cache_manager` 插件，如下方代码所示，就可以快速简单实现图片的本地缓存：

```
 Future<ui.Codec> _loadAsync(NetworkImage key) async {
    assert(key == this);

    /// add this start
    /// flutter_cache_manager DefaultCacheManager
    final fileInfo = await DefaultCacheManager().getFileFromCache(key.url);
    if(fileInfo != null && fileInfo.file != null) {
      final Uint8List cacheBytes = await fileInfo.file.readAsBytes();
      if (cacheBytes != null) {
        return PaintingBinding.instance.instantiateImageCodec(cacheBytes);
      }
    }
    /// add this end

    final Uri resolved = Uri.base.resolve(key.url);
    final HttpClientRequest request = await _httpClient.getUrl(resolved);
    headers?.forEach((String name, String value) {
      request.headers.add(name, value);
    });
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok)
      throw Exception('HTTP request failed, statusCode: ${response?.statusCode}, $resolved');

    final Uint8List bytes = await consolidateHttpClientResponseBytes(response);
    if (bytes.lengthInBytes == 0)
      throw Exception('NetworkImage is an empty file: $resolved');
    
    /// add this start
    await DefaultCacheManager().putFile(key.url, bytes);
    /// add this edn

    return PaintingBinding.instance.instantiateImageCodec(bytes);
  }
```

## 三、其他补充

#### 1、缓存数量

在闲鱼关于 Flutter 线上应用的[内存分析文章](https://juejin.im/post/5bbec3d15188255c4322bbee)中，有过对图片加载对内存问题的详细分析，其中就有一个是 `ImageCache` 的问题。

上面的流程我们知道， `ImageCache` 缓存的是一个异步对象，缓存异步加载对象的一个问题是，在图片加载解码完成之前，你无法知道到底将要消耗多少内存，并且大量的图片加载，会导致的解码任务需要产生大量的IO。

而在 Flutter 中， `ImageCache` 默认的缓存大小是
```
const int _kDefaultSize = 1000;
const int _kDefaultSizeBytes = 100 << 20; // 100 
```
所以简单粗暴的做法是： `  PaintingBinding.instance.imageCache.maximumSize = 100;` 同时在页面不可见时暂停图片的加载等。



#### 2、.9图
在 Image中，可以通过 `centerSlice` 配置参数设置.9图效果哦。


>自此，第十篇终于结束了！(///▽///)

### 资源推荐

* Github ： [https://github.com/CarGuo/](https://github.com/CarGuo)
* **开源 Flutter 完整项目：https://github.com/CarGuo/GSYGithubAppFlutter**
* **开源 Flutter 多案例学习型项目: https://github.com/CarGuo/GSYFlutterDemo**
* **开源 Fluttre 实战电子书项目：https://github.com/CarGuo/GSYFlutterBook**

##### 完整开源项目推荐：

* [GSYGithubApp Flutter](https://github.com/CarGuo/GSYGithubAppFlutter ) 
* [GSYGithubApp React Native](https://github.com/CarGuo/GSYGithubApp ) 
* [GSYGithubAppWeex](https://github.com/CarGuo/GSYGithubAppWeex)



![我们还会再见吗？](http://img.cdn.guoshuyu.cn/20190604_Flutter-10/image7)