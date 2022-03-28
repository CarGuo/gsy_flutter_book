在以前的 [《Flutter 上默认的文本和字体知识点》](https://juejin.cn/post/6844904164082843655)  和  [《带你深入理解 Flutter 中的字体“冷”知识》](https://juejin.cn/post/6844904174023344136) 中，已经介绍了很多 Flutter 上关于字体有趣的知识点，而本篇讲继续介绍 Flutter 上关于 `Text` 的一个属性：`FontFeature` ， **事实上相较于 Flutter ，本篇内容可能和前端或者设计关系更密切**。

> **相信本篇绝对是你能看到关于 Flutter  `FontFeature` 相关的少数资料之一。**


什么是 `FontFeature`？ **简单来说就是影响字体形状的一个属性** ，在前端的对应领域里应该是 `font-feature-settings`，它有别于 `FontFamily` ，是用于指定字体内字的形状的一个参数。

> 如下图所示是 `frac` 分数和  `tnum` 表格数字的对比渲染效果，这种效果可以在不增加字体库时实现特殊的渲染，另外 `Feature` 也有特征的意思，所以也可以理解为字体特征。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-FontFeature/image1)

我们知道 Flutter 默认在 Android 上使用的是 `Roboto` 字体，而在 iOS 上使用的是 `SF` 字体，但是其实 `Roboto` 字体也是分很多类型的，比如你去查阅手机的 `system/fonts` 目录，就会发现很多带有 `Roboto` 字样的字体库存在。


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-FontFeature/image2)


所以 `Roboto` 之类的字体库是一个很大的字体集，不同的 `font-weight` 其实对应着不同的 `ttf` ，例如默认情况下的 **`Roboto` 是不支持 `font-weight` 为 600 的配置**：


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-FontFeature/image3)

所以如下图所示，如果我们设置了 `w400` - `w700` 的 `weight` ，可以很明显看到中间的 500 和 600 其实是一样的粗细，所以在**设置  `weight` 或者设计 UI 时，就需要考虑不同平台上的  `weight` 是否支持想要的效果**。

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-FontFeature/image4)


回归到 `FontFeature` 上，那 `Roboto` 自己默认支持多少种 features 呢？ 答案是 26 种，它们的编码如下所示，运行后效果也如下图所示，从日常使用上看，这 26 种 Feature 基本满足开发的大部分需求。

> "c2sc"、    "ccmp"、    "dlig"、    "dnom"、    "frac"、    "liga"、    "lnum"、    "locl"、    "numr"、    "onum"、    "pnum"、    "salt"、    "smcp"、    "ss01"、    "ss02"、    "ss03"、    "ss04"、    "ss05"、    "ss06"、    "ss07"、    "tnum"、    "unic"、    "cpsp"、    "kern"、    "mark"、    "mkmk"



![](http://img.cdn.guoshuyu.cn/20220328_Flutter-FontFeature/image5)

而 iOS 上的 `SF pro` 默认支持 39 种 Features ， 它们的编码如下所示，运行后效果也如下图所示，可以看到 `SF pro` 支持的 Features 更多。

> "c2sc"、    "calt"、    "case"、    "ccmp"、    "cv01"、    "cv02"、    "cv03"、    "cv04"、    "cv05"、    "cv06"、    "cv07"、    "cv08"、    "cv09"、    "cv10"、    "dnom"、    "frac"、    "liga"、    "locl"、    "numr"、    "pnum"、    "smcp"、    "ss01"、    "ss02"、    "ss03"、    "ss05"、    "ss06"、    "ss07"、    "ss08"、    "ss09"、    "ss12"、    "ss13"、    "ss14"、    "ss15"、    "ss16"、    "ss17"、    "subs"、    "sups"、    "tnum"、    "kern"


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-FontFeature/image6)

所以可以看到，并不是所有字体支持的 Features 都是一样的，比如 iOS 上支持 `sups`   上标显示和 `subs` 下标显示，但是 Android 上的 Roboto 并不支持，甚至很多第三方字体其实并不支持 Features 。

> 同样在 Web 上也存在各种限制，比如 `swsh`（花体）默认下基本不支持浏览器，`fwid` 、 `nlck` 不支持 Safari 浏览器等。

有趣的是，在 Flutter Web 有一个渲染文本时会变模糊的问题[#58159](https://github.com/flutter/flutter/issues/58159)，这个问题目前官方还没有修复，但是你可以通过给 `Text` 设置任意 `FontFeatures`  来解决这个问题。

> **因为出现模糊的情况一般都是因为使用了 `canvas` 标签绘制文本，而如果 `Text` 控件具有 `fontFeatures` 时，就会被设置为 `<p>` + `<span>` 进行渲染，从而避免问题**。

最后，如果对 FontFeature 还感兴趣的朋友，可以通过一下资料深入了解，如果你还有什么关于字体上的问题，欢迎留言讨论。


- 如果你想了解更多的 features 类型，可以通过 https://en.wikipedia.org/wiki/List_of_typographic_features 了解更多；

- 如果你对自己的使用的字体支持什么 features 感兴趣，可以通过 https://wakamaifondue.com 了解更多；

## 补充内容

**基于网友的问题再补充一下拓展知识，毕竟这方面内容也不多**。

事实上在 dart 里就可以看到对应 `FontWeight` 约定俗称用的是字体集里的什么字体：


| 名称                 | 值         |
| -------------------- | ---------- |
| Thin                 | w100       |
| Extra                | w200       |
| Light                | w300       |
| Normal/regular/plain | w400(默认) |
| Medium               | w500       |
| Semi-bold            | w600       |
| Bold                 | w700       |
| Extra-bold-          | w800       |
| Black                | 900        |


所以如果对于默认字体有疑问，可以在你的手机字体找找是否有对应的字体，**比如虽然我们说 roboto 没有 600 ，但是如果是 roboto mono 字体集是有 600 的 fontweight**，甚至还有 600 斜体： https://fonts.google.com/specimen/Roboto+Mono 。


这里可以用 Android Studio 的 `Device File Explorer` 查看`/system/etc/fonts.xml` 下当前手机的字体编码情况，右键该文件 `save as` 到电脑上，下图是华为上的 `fonts.xml` 截图：

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-FontFeature/image7)

你也可以通过如下原生代码，获取到对应现在 Android 系统支持的字体 `Typeface` ，但是这个  `Typeface`  并不是真正的字体名，还是要对应在 `fonts.xml` 下查看。

```java
protected Map<String, Typeface> getSSystemFontMap() {
    Map<String, Typeface> sSystemFontMap = null;
    try {
        //Typeface typeface = Typeface.class.newInstance();
        Typeface typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL);
        Field f = Typeface.class.getDeclaredField("sSystemFontMap");
        f.setAccessible(true);
        sSystemFontMap = (Map<String, Typeface>) f.get(typeface);
        for (Map.Entry<String, Typeface> entry : sSystemFontMap.entrySet()) {
            Log.e("FontMap", entry.getKey() + " ---> " + entry.getValue() + "\n");
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    return sSystemFontMap;
}

private static List<String> getKeyWithValue(Map map, Typeface value) {
    Set set = map.entrySet();
    List<String> arr = new ArrayList<>();
    for (Object obj : set) {
        Map.Entry entry = (Map.Entry) obj;
        if (entry.getValue().equals(value)) {
            String str = (String) entry.getKey();
            arr.add(str);
        }
    }
    return arr;
}
```

例如前面我们说过 Roboto 没有 `w600` , 但是通过输出比对，华为上有 `source-sans-pro` 是支持 `w600` ：

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-FontFeature/image8)


另外注意这是 Flutter 而不是原生，具体实现调用是在 Engine 的 *paragraph_skia.cc* 和 *paragraph_builder_skia.cc* 下对应的 `setFontFamilies` 相关逻辑，当然默认字体库指定在  `typography.dart` 下就看到，例如 `'Roboto'` 、 `'.SF UI Display'` 、`'.SF UI Text'` 、`'.AppleSystemUIFont'` 、 `'Segoe UI'` ：

| 名称                    | 值                          |
| ----------------------- | --------------------------- |
| Android，Fuchsia，Linux | Roboto                      |
| iOS                     | .SF UI Display，.SF UI Text |
| MacOS                   | .AppleSystemUIFont          |
| Windows                 | Segoe UI                    |

> 例如：**.SF Text 适用于更小的字体；.SF Display 则适用于偏大的字体，我记得分水岭好像是 20pt 左右，不过 SF（San Francisco） 属于动态字体，系统会动态匹配**。

另外如果你在 Mac 的 Web 上使用 Flutter Web，可以看到指定的是 `.AppleSystemUIFont` ，而对于 `.AppleSystemUIFont` 它其实不算是一种字体，而是苹果上字体的一种集合别称：

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-FontFeature/image9)

还有，如果你去看 Flutter 默认自带的 `cupertino/context_menu_action.dart` ，就可以看到一个有趣的情况：

> **为了强调和 iOS 上的样式尽量一直，当开发者配置 `isDefaultAction == true` 时，会强行指定 `'.SF UI Text'` 并指定为 `FontWeight.w600`**。


**当然，前面我们说了那么多，主要是针对英文的情况下，而在中文下还是有差异的**，之前的文章也介绍过：

-   默认在 iOS 上：

    -   中文字体：`PingFang SC`
    -   英文字体：`.SF UI Text` 、`.SF UI Display`

-   默认在 Android 上：

    -   中文字体：`Source Han Sans` / `Noto`
    -   英文字体：`Roboto`

例如，在苹果上的简体中文其实会是 `PingFang SC` 字体，对应还有`PingFang TC` 和 `PingFang HK` 的繁体集，而关于这个问题在 Flutter 上之前还出现过比较有意思的 bug ：
> 用户在输入拼音时，iOS 会在中文拼音之间添加额外的 `unicode \u2006` 字符，比如输入 `"nihao"` ，iOS 系统会在 skia 中添加文字 `“ni\u2006hao ”`，从而导致字体无效的情况。

当然后续的 [#16709](https://github.com/flutter/engine/pull/16709/files) 修复了这个问题 ，而在以前的文章我也讲过，当时我遇到了 **“Flutter 在 iOS 系统上，系统语言是韩文时，在和中文一起出现会导致字体显示异常" 的问题** ：


![](http://img.cdn.guoshuyu.cn/20220328_Flutter-FontFeature/image10)

解决方法也很简单，就是给 `fontFamilyFallback` 配置上 `["PingFang SC" , "Heiti SC"]` 就可以了，这是因为韩文在苹果手机上使用的应该是 `Apple SD Gothic Neo` 这样的超集字体库，【广】这个字符在这个字体集上是不存在的，所以就变成了中文的【广】；

![](http://img.cdn.guoshuyu.cn/20220328_Flutter-FontFeature/image11)

**所以可以看到，字体相关是一个平时很少会深入接触的东西，但是一旦涉及多语言和绘制，就很容易碰到问题的领域**。