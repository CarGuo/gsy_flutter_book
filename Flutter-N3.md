# Flutter 小技巧之玩转字体渲染和问题修复

这次的 Flutter 小技巧是字体渲染，虽然是小技巧但是内容略长，可能大家在日常开发中不会特别关心字体相关的部分，**而这将是一篇你平时可能用不到 ，但是遇到问题就会翻出来的文章**。

> 本篇将快速普及一些字体渲染相关的基础，解决一些因为字体而导致的异常问题，**并穿插一些实用小技巧**，内容篇幅可能略长，建议先 Mark 后看。

# 一、字体库

首先，问一个我经常问的面试题：**Flutter 在 Android 和 iOS 上使用了哪些字体**？

如果你恰好看过 `typography.dart` 的源码和解释，你可以会有初步结论：

-  Android 上使用的是 `Roboto` 字体；
-  iOS 上使用的是 `.SF UI Display` 或者 `.SF UI Text` 字体；

![image-20220601135913731](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image1.png)

 但是，如果你再进一步去了解就会发现，在加上中文显示之后，结论应该是：

- 默认在 iOS 上：
  - 中文字体：`PingFang SC` (繁体还有 `PingFang TC` 、 `PingFang HK`    )
  - 英文字体：`.SF UI Text`  / `.SF UI Display`
- 默认在 Android 上：
  - 中文字体：`Source Han Sans` / `Noto`
  - 英文字体：`Roboto`

那这时候你可能会问：**.SF 没有中文，那可以使用 `PingFang` 显示英文吗**？ 答案是可以的，但是字形和字重会有微妙区别， 例如下图里的 G 就有很明显的不同。

![image-20220601141145552](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image2.png)

那如果加上韩文呢？这时候 iOS 上的  `PingFang`  和 `.SF`  就不够用了，需要调用如  `Apple SD Gothic Neo`  这样的超集字体库，而说到这里就需要介绍一个 Flutter 上你可能会遇到的 Bug。

如下图所示，**当在使用  `Apple SD Gothic Neo`  字体出现中文和韩文同时显示时，你可能会察觉一些字形很奇怪**，比如【推广】这两个字，其中【广】这个字符在超集上是不存在的，所以会变成了中文的【广】，但是【推】字用的还是超集里的字形。

![image-20220601141720525](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image3.png)

这种情况下，最终渲染的结果会如下图所示，解决的思路也很简单，**小技巧就是给 `TextStyle` 或者 `Theme` 的 `fontFamilyFallback`  配置上 `["PingFang SC" , "Heiti SC"]`**  。

![image-20220601142805434](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image4.png)

另外，如果你还对英文下 `.SF UI Display` 和  ``SF UI Text`  之间的关系困惑的话，那其实你不用太过纠结，因为从 SF 设计上大概意思上理解的话： 

> .SF Text 适用于更小的字体；.SF Display 则适用于偏大的字体，分水岭大概是 20pt 左右，不过 SF（San Francisco） 属于动态字体，系统会动态匹配。



# 二、Flutter Text 

虽然上面介绍字体的一些相关内容，但是在 Flutter 上和原生还是有一些差异，在 Flutter 中的文本呈现逻辑是有分层的，其中：

- 衍生自 Minikin 的 libtxt 库用于字体选择，分隔行等；
- HartBuzz 用于字形选择和成型；
- Skia作为 渲染 / GPU后端；
- **在 Android / Fuchsia 上使用 FreeType 渲染，在 iOS 上使用CoreGraphics 来渲染字体** 。

## Text Height

那如果这时候我问你一个问题： **一个 ` fontSize: 100`  的  H 字母需要占据多大的高度** ？你会回答多少？

首先，我们用一个 100 的红色 `Container` 和  ` fontSize: 100`  的 H 文本做个对比，可以看到 H 文本所在的蓝色区域其实是需要大于 100 的红色区域的。

![image-20220601145346189](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image5.png)

**事实上，前面的蓝色区域是字体的行高，也就是 line height**，关于这个行高，首先需要解释的就是 `TextStyle` 中的 `height` 参数。

默认情况下 `height` 参数是 `null`，当我们把它设置为 **`1`** 之后，如下图所示，可以看到蓝色区域的高度和红色小方块对齐，变成了 **100** 的高度，也就是行高变成了 **100** ，而 **H** 字母完整地显示在了蓝色区域内。

![image-20220601145634196](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image6.png)

那 `height` 是什么呢？首先 `TextStyle` 中的 `height` 参数值在设置后，其效果值是 `fontSize` 的倍数：

- 当 `height` 为空时，行高默认是使用字体的**量度**（这个**量度**后面会有解释）；
- 当 `height` 不是空时，行高为 `height` * `fontSize` 的大小；

如下图所示，蓝色区域和红色区域的对比就是 `height` 为 `null` 和 `1` 的对比高度。

![image-20220601145710275](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image7.png)

所以，看到这里你又知道了一个小技巧：**当文字在 `Container` “有限高度” 内容内无法居中时，可以考虑调整 `TextStyle` 中的 `height` 来实现** 。

![image-20220601151621858](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image8.png)

> 当然，这时候如果你把 `Container` 的 `height:50` 去掉，又会是另外一个效果。

所以 height 参数和文本渲染的高度之间是成倍数关系，具体如下图所示，同时最需要注意的点就是：**文本内容在 height 里并不是居中，这里的 height 可以类比于调整行高。**

![image-20220601151923432](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image9.png)

另外，**文本中的除了 `TextStyle` 下的  `height` 之外，还是有  `StrutStyle`  参数下的   `height`**  ，它影响的是字体的整体量度，也就是如下图所示，影响的是 ascent - descent 的高度。

![image-20220601152843273](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image10.png)

**那你说它和  `TextStyle` 下的  `height`  有什么区别**？ 如下图所示例子：

-  `StrutStyle`   的  `froceStrutHeight` 开启后，`TextStyle` 的  `height`  不会生效；
-  `StrutStyle`    设置 `fontSize:50` 影响的内容和 `TextStyle`  的   `fontSize:100` 影响的内容不一样；

![](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image11.png)

另外在  `StrutStyle`    里还有一个叫  `leading`  的 参数，加上了 `leading` 后才是 Flutter 中对字体行高完全的控制组合，`leading` 默认为 `null` ，同时它的效果也是 `fontSize` 的倍数，并且分布是上下均分。

![](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image12.png)所以，看到这里你又知道了一个小技巧：**设置 `leading` 可以均分高度，所以如下图所示，也可以用于调整行间距。** 

![image-20220601154712338](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image13.png)

> 更多行高相关可见 ：[《深入理解 Flutter 中的字体“冷”知识》](https://juejin.cn/post/6844904174023344136)

## FontWeight

另外一个关于字体的知识点就是 `FontWeight` ，相信大家对 `FontWeight`  不会陌生，比如我们默认的 normal 是 w400，而常用的 bold 是 w700 ，整个  `FontWeight`  列表覆盖 100-900 的数值。

![image-20220601155236983](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image14.png)

那么这里又有个问题：**这些  Weight 在字体里都能找到对应的粗细吗**？

答案是不行的，因为正常情况下如下图所示 ，有些字体库在某些  Weight  下是没有对应支持，例如 

- Roboto 没有 w600
- PingFang 没有高于 w600 

![image-20220601162130629](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image15.png)



**那你可能好奇，为什么这里要特意介绍 FontWeight ？因为在 Flutter 3.0 目前它对中文有 Bug**！

从下面这张图你可以看到，在 Flutter 3.0 上中文从 100-500 的字重显示是不正常的，肉眼可以看出在 100 - 500 都显示同一个字重。

![image-20220601162935325](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image16.png)

> 这个 Bug 来自于当 `SkParagraph` 调用 `onMatchFamilyStyleCharacter`  时，`onMatchFamilyStyleCharacter`  的实现没有选择最接近  `TextStyle` 的字体，所以在  `CTFontCreateWithFontDescriptor`  时会带上  weight  参数但是却没有  `familyName` ，所以 CTFontCreateWithFontDescriptor`  函数就会返回 Helvetica 字体的默认 weight。

临时解决小技巧也很简单：**全局设置 `fontFamilyFallback: ["PingFang SC"]` 或者 `fontFamily: 'PingFang SC'` 就可以解决，又是 Fallback ， 这时候你就会发现，前面介绍的字体常识，可以在这里快速被利用起来**。

![image-20220601163255325](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image17.png)

> 因为 iOS 上中文就是 `PingFang SC` ，只要 Fallback 回  PingFang  就可以正常渲染，而这个问题在 Android 模拟器、iOS 真机、Mac 上等会出现，但是 Android 真机上却不会，该问题我也提交在 [#105014](https://github.com/flutter/flutter/issues/105014) 下开始跟进。

添加的 Fallback  之后效果如上图左侧所示， 那 Fallback 的作用是什么？

前面我们介绍过，系统在多语言中渲染是需要多种字体库来支持，而当找不到字形时，就要依赖提供的 Fallback  里的有序列表，例如：

> 如果在  [fontFamily](https://api.flutter.dev/flutter/painting/TextStyle/fontFamily.html)  中找不到字形，则在 [fontFamilyFallback](https://api.flutter.dev/flutter/painting/TextStyle/fontFamilyFallback.html) 中搜索，如果没有找到，则会在返回默认字体。

另外关于  `FontWeight` 还有一个“小彩蛋”，在 iOS 上，当用户在辅助设置里开启 Bold Text 之后，如果你使用的是 `Text` 控件，那么默认情况下所有的字体都会变成 w700 的粗体。

![image-20220601164236038](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image18.png)

因为在 `Text`  内使用了 `MediaQuery.boldTextOverride`  判断，Flutter 会接收到 iOS 上用户开启了 Bold Text ，从而强行将 `fontWeight` 设置为 `FontWeight.bold ` ，当然如果你直接使用 `RichText` 就 没有这一行为。

![](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image19.png)

这时候小技巧就又来了：**如果你不希望这些系统行为干扰到你，那么你可以通过嵌套 `MediaQuery` 来全局关闭，而类似的行为还有 `textScaleFactor` 和 `platformBrightness`等** 。

```dart
return MediaQuery(
  data: MediaQueryData.fromWindow(WidgetsBinding.instance!.window).copyWith(boldText: false),
  child: MaterialApp(
    useInheritedMediaQuery: true,
  ),
);
```

![image-20220531082324707](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image20.png)



##  FontFeature

最后再介绍一个冷门参数 FontFeature 。

什么是 `FontFeature`？ **简单来说就是影响字体形状的一个属性** ，在前端的对应领域里应该是 `font-feature-settings`，它有别于 `FontFamily` ，是用于指定字体内字的形状参数。

> 如下图所示是 `frac` 分数和 `tnum` 表格数字的对比渲染效果，这种效果可以在不增加字体库时实现特殊的渲染，另外 `Feature` 也有特征的意思，所以也可以理解为字体特征。

![image-20220601165224593](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image21.png)

那  FontFeature 有什么用呢？ 这里又有一个使用小技巧了：**当出现数字和文本同时出现，导致排列不对齐时，可以通过给 `Text` 设置 `fontFeatures: [FontFeature("tnum")]` 来对齐**。

例如下图左边是没有设置 fontFeatures 的情况，右边是设置了 `FontFeature("tnum")` 的情况，对比之下还是很明显的。

![image-20220601165855711](http://img.cdn.guoshuyu.cn/20220611_FONT¥/image22.png)

> 更多关于 FontFeature  的内容可见 [《Flutter 上字体的另类玩法：FontFeature 》](https://juejin.cn/post/7078680758826565662) 

# 三、最后

总结一下，本篇内容信息量相对比较密集，主要涉及：

- 字体基础
- Text Height
- FontWeight
- FontFeature

从以上四个方面介绍了 Flutter 开发里关于字体渲染的“冷知识”和小技巧，包括：解决多语言下的字体错误、如何正确调整行高、如何对其数字内容等相关小技巧。

如果你还有什么关于字体的疑问，欢迎留言讨论～