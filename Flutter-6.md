作为系列文章的第六篇，本篇主要在前文的探索下，针对描述一下 Widget 中的一些有意思的原理。

> 前文：
>* [一、Dart语言和Flutter基础](https://juejin.im/post/5b631d326fb9a04fce524db2)
>* [二、 快速开发实战篇](https://juejin.im/post/5b685a2a5188251ac22b71c0)
>* [三、 打包与填坑篇](https://juejin.im/post/5b6fd4dc6fb9a0099e711162)
>* [四、Redux、主题、国际化](https://juejin.im/post/5b79767ff265da435450a873)
> * [五、 深入探索](https://juejin.im/post/5bc450dff265da0a951f032b)

首先我们需要明白，Widget 是什么？这里有一个 *“总所周知”* 的答就是：**Widget并不真正的渲染对象**  。是的，事实上在 Flutter 中渲染是经历了从 `Widget` 到  `Element`  再到 `RenderObject` 的过程。

我们都知道 Widget 是不可变的，那么 Widget 是如何在不可变中去构建画面的？上面我们知道，`Widget` 是需要转化为  `Element` 去渲染的，而从下图注释可以看到，事实上 **Widget 只是 Element 的一个配置描述** ，告诉 Element 这个实例如何去渲染。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-6/image1)

那么 Widget 和 Element 之间是怎样的对应关系呢？从上图注释也可知： **Widget 和 Element 之间是一对多的关系**  。实际上渲染树是由 Element 实例的节点构成的树，而作为配置文件的 Widget 可能被复用到树的多个部分，对应产生多个 Element 对象。


那么`RenderObject ` 又是什么？它和上述两个的关系是什么？从源码注释写着 `An object in the render tree` 可以看出到 `RenderObject ` 才是实际的渲染对象，而通过 Element 源码我们可以看出：**Element 持有 RenderObject 和 Widget。**

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-6/image2)

再结合下图，可以大致总结出三者的关系是：**配置文件 Widget 生成了 Element，而后创建 RenderObject 关联到 Element 的内部 `renderObject` 对象上，最后Flutter 通过 RenderObject 数据来布局和绘制。** 理论上你也可以认为 RenderObject 是最终给 Flutter 的渲染数据，它保存了大小和位置等信息，Flutter 通过它去绘制出画面。

![](http://img.cdn.guoshuyu.cn/20190604_Flutter-6/image3)

说到 `RenderObject` ，就不得不说 **`RenderBox`** ：`A render object in a 2D Cartesian coordinate system`，从源码注释可以看出，它是在继承 `RenderObject` 基础的布局和绘制功能上，实现了“笛卡尔坐标系”：以 Top、Left 为基点，通过宽高两个轴实现布局和嵌套的。

RenderBox 避免了直接使用  `RenderObject` 的麻烦场景，其中 `RenderBox ` 的布局和计算大小是在 `performLayout()` 和 `performResize()`  这两个方法中去处理，很多时候我们更多的是选择继承  `RenderBox ` 去实现自定义。

综合上述情况，我们知道：

- Widget只是显示的数据配置，所以相对而言是轻量级的存在，而 Flutter 中对 Widget 的也做了一定的优化，所以每次改变状态导致的 Widget 重构并不会有太大的问题。
- RenderObject 就不同了，RenderObject 涉及到布局、计算、绘制等流程，要是每次都全部重新创建开销就比较大了。

所以针对是否每次都需要创建出新的 Element 和 RenderObject 对象，Widget 都做了对应的判断以便于复用，比如：在 `newWidget` 与`oldWidget` 的 *runtimeType* 和 *key* 相等时会选择使用 `newWidget` 去更新已经存在的 Element 对象，不然就选择重新创建新的 Element。

由此可知：**Widget 重新创建，Element 树和 RenderObject 树并不会完全重新创建。**

看到这，说个题外话：*那一般我们可以怎么获取布局的大小和位置呢？* 

首先这里需要用到我们前文中提过的 `GlobalKey ` ，通过 key 去获取到控件对象的 `BuildContext `，而我们也知道 `BuildContext` 的实现其实是 `Element`，而`Element`持有 `RenderObject ` 。So，我们知道的 `RenderObject` ，实际上获取到的就是 `RenderBox` ，那么通过 `RenderBox` 我们就只大小和位置了。

```
  showSizes() {
    RenderBox renderBoxRed = fileListKey.currentContext.findRenderObject();
    print(renderBoxRed.size);
  }

  showPositions() {
    RenderBox renderBoxRed = fileListKey.currentContext.findRenderObject();
    print(renderBoxRed.localToGlobal(Offset.zero));
  }

```

--

>自此，第六篇终于结束了！(///▽///)

### 资源推荐

* Github ： https://github.com/CarGuo
* 本文代码 ：https://github.com/CarGuo/GSYGithubAppFlutter

##### 完整开源项目推荐：

* [GSYGithubAppWeex](https://github.com/CarGuo/GSYGithubAppWeex)
* [GSYGithubApp React Native](https://github.com/CarGuo/GSYGithubApp ) 

##### 文章


[《Flutter完整开发实战详解(一、Dart语言和Flutter基础)》](https://juejin.im/post/5b631d326fb9a04fce524db2)

[《Flutter完整开发实战详解(二、 快速开发实战篇)》](https://juejin.im/post/5b685a2a5188251ac22b71c0)

[《Flutter完整开发实战详解(三、 打包与填坑篇)》](https://juejin.im/post/5b6fd4dc6fb9a0099e711162)

[《Flutter完整开发实战详解(四、Redux、主题、国际化)》](https://juejin.im/post/5b79767ff265da435450a873)

[《Flutter完整开发实战详解(五、 深入探索)》](https://juejin.im/post/5bc450dff265da0a951f032b)

[《Flutter完整开发实战详解(六、 深入Widget原理)》](https://juejin.im/post/5c7e853151882549664b0543)

[《Flutter完整开发实战详解(七、 深入布局原理)》](https://juejin.im/post/5c8c6ef7e51d450ba7233f51)

[《Flutter完整开发实战详解(八、 实用技巧与填坑)》](https://juejin.im/post/5c9e328251882567b91e1cfb)

[《Flutter完整开发实战详解(九、 深入绘制原理)》](https://juejin.im/post/5ca0e0aff265da309728659a)

[《Flutter完整开发实战详解(十、 深入图片加载流程)》](https://juejin.im/post/5cb1896ce51d456e63760449)

[《Flutter完整开发实战详解(十一、全面深入理解Stream)》](https://juejin.im/post/5cc2acf86fb9a0321f042041)

[《跨平台项目开源项目推荐》](https://juejin.im/post/5b6064a0f265da0f8b2fc89d)

[《移动端跨平台开发的深度解析》](https://juejin.im/post/5b395eb96fb9a00e556123ef)

[《React Native 的未来与React Hooks》](https://juejin.im/post/5cb34404f265da0384127fcd)

![我们还会再见吗？](http://img.cdn.guoshuyu.cn/20190604_Flutter-6/image4)