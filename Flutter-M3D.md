# Flutter 小技巧之 3.16 升级最坑 M3 默认适配技巧

如果要说 Flutter 3.16 升级里是最坑的是什么？那我肯定要说是 Material  3 default （M3）。

倒不是说 M3 bug 多，也不是 M3 在 3.16 上使用起来多麻烦，因为**虽然从 3.16 开始，`MaterialApp` 里的 `useMaterial3` 默认会是 true，但是你是可以直接 使用 `useMaterial3: false`  来关闭**。

那为什么还收坑？因为未来 **Material 2 相关的东西会被弃用并删除**，所以 Material  3 default（M3） 是一个警告，你可以通过  `useMaterial3: false`  来关闭无视，但是这个技术债未来会很坑。

> 难道你还能一直苟着不更新？

为什么说它很坑？因为适配它纯纯是一个体力活，而且还是一个细节工作，M3 是一套配色方案，**一套和 M2 「毫不相关」的配色方案**：

- 配色方案代表着它已经帮你默认确定了什么地方应该用什么颜色
- M2 毫不相干，代表着你之前用这 M2 的 Widget 默认的 UI 效果，用了 M3 会完全不一样

![](http://img.cdn.guoshuyu.cn/20231123_M3/image1.gif)

如上图所示，看起来好像是就是：

- `AppBar` 配色发生了变化
- `FloatingActionButton` 从圆的变成方的，颜色发生变化
- 默认 Button 按照风格发生了变卦
- ······

似乎看起来也没什么，但是你知道有多少地方用了  `FloatingActionButton` ？每个地方的 `AppBar`  难道都要手动去调整？`ElevatedButton` 和  `TextButton` 有没有办法全局配置？本篇就是为了让你少走适配弯路，提供适配思路的角度。

> 核心还是国内的产品有谁愿意使用 Material Design ？ 像这种 M2 到 M3 的变化，对于开发者来说纯粹就是负优化。

# 开始

首先，**官方 Material 3 配色首推是使用 `ColorScheme.fromSeed()`  来生成配色**，当然你也可以通过 `ColorScheme.fromImageProvider` 的图片来生成配色，不过一般人应该不会这么干，另外还有  `ColorScheme.fromSwatch`  ，不过这个的灵活适配程度不如 fromSeed，所以使用  fromSeed 是比较好的选择。

> 因为 M3 默认从蓝色系列变成紫色系统，所以如果你用的是默认色系，那就更需要配置来恢复，本篇的目的就是，**让 App 在 M3 下恢复到 M2 的 UI 效果，因为它真的不是仅仅一个颜色变化而已。**

![](http://img.cdn.guoshuyu.cn/20231123_M3/image2.png)



如果你以前的 `ThemeData` 是如下所示代码，那么运行之后你会看到，原本应该是 M2 效果的正常列表，现在变成了 M3 那种「无法言喻」的效果，可以看到此时 M3 下  `primarySwatch` 其实并没有起到作用。

```dart
ThemeData(
  primarySwatch: Colors.blue,
  ////
)
  
```

| M2                                                     | M3                                                     |
| ------------------------------------------------------ | ------------------------------------------------------ |
| ![](http://img.cdn.guoshuyu.cn/20231123_M3/image3.png) | ![](http://img.cdn.guoshuyu.cn/20231123_M3/image4.png) |

那么首先我们要做的就是增加  `colorScheme` ，但是你在加完会发现并没有什么变化，这是因为此时控件还是处于 M3 的色系下，所以接下来我们要首先全局恢复 `Appbar`。

```dart
ThemeData(
  primarySwatch: Colors.blue,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
),
```

> Do it。

# AppBar

如下代码所示，我们先添加  `AppBarTheme` ，可以看到 AppBar 的背景这样就变回了蓝色，但是这时候 Appbar 的文本和图标还是黑色。

```dart
ThemeData(
  primarySwatch: Colors.blue,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),

  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue,
  ),
),
```

| ![](http://img.cdn.guoshuyu.cn/20231123_M3/image5.png) | ![](http://img.cdn.guoshuyu.cn/20231123_M3/image6.png) |
| ------------------------------------------------------ | ------------------------------------------------------ |

为了让图标和文本恢复到 M2 的白色，我们可以在  `AppBarTheme` 里配置 `iconTheme` 和 `titleTextStyle` ，可以看到配置后如下图所示，UI 上 `AppBar` 已经恢复到 M2 的效果，那么此时你可以会疑惑，为什么修改的配置是  `size: 24.0` 和  `Typography.dense2021.titleLarge` ？

```dart
AppBarTheme(
  iconTheme: IconThemeData(
    color: Colors.white,
    size: 24.0,
  ),
  backgroundColor: Colors.blue,
  titleTextStyle:  Typography.dense2014.titleLarge,
)
```

![](http://img.cdn.guoshuyu.cn/20231123_M3/image7.png)

其实这就是本篇的核心：**在 M2 控件还没被剔除的时候，通过参考源码将 M3 UI 恢复到 M2** 。

例如在 3.16 的源码里，`theme.useMaterial3 ?`  这样的代码目前随处可见，而此时 `AppBar` 里：

- `_AppBarDefaultsM3` 下 icon 的颜色是通过 `onSurface` 字段，大小是 24
- `_AppBarDefaultsM2` 下 icon 是直接使用 theme 下默认的样式，也就是 size 24， 颜色白色。

![](http://img.cdn.guoshuyu.cn/20231123_M3/image8.png)

| M2                                                           | M3                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------- |
| ![](http://img.cdn.guoshuyu.cn/20231123_M3/image9.png)![](http://img.cdn.guoshuyu.cn/20231123_M3/image10.png) | ![](http://img.cdn.guoshuyu.cn/20231123_M3/image11.png) |

所以我们可以在上面的  `IconThemeData` 里可以直接配置 `color: Colors.white,  size: 24.0,` 来恢复到 M2 的效果。

> 当然你也可以配置 `ColorScheme` 的  `onSurface` 来改变颜色，但是这个影响返回太大，还是推荐配置  `AppBarTheme` 的 `IconThemeData` 。

另外可以看到，此时还有一个  `Typography.dense2014.titleLarge` ，这又是哪里来的？还是回到`_AppBarDefaultsM3`  里，在 M3 下， AppBar 使用的是 `ThemeData `下的 `textTheme.titleLarge` ，而默认字体样式配置，基本来自 `Typography` 对象。

![](http://img.cdn.guoshuyu.cn/20231123_M3/image12.png)

![](http://img.cdn.guoshuyu.cn/20231123_M3/image13.png)

`Typography` 里默认配置了大量字体配置，例如  `Typography.dense2014` 对应就是如下所示配置，从上面代码可以看到**默认情况下 M2 用的是  `Typography.material2014 `，对应就是  `Typography.dense2014`**，也就是在 AppBar 上 `Typography.dense2014.titleLarge` 就可以让 M3 的 AppBar 文本恢复到 M2 的样式。

![](http://img.cdn.guoshuyu.cn/20231123_M3/image14.png)

看到这里你是否已经学会了大概的思路？

**通过 `theme.useMaterial3 ` 去检索控件，然后在源码里找到 M2 的实现，然后将其修改到全局的主题设置里**，比如 AppBar 的就通过 `AppBarTheme` 配置，如果是 M2 的实现又引用了某些默认配置，就去检索这些默认配置的起源，所以说 M3 这个坑是一个体力活。

当然，这个思路下，有一些控件适配起来还是会有坑，因为它的变化确实有点大，例如 Card 控件。

# Card

如图所示，这是 `Card` 控件在 M2 和 M3 下的变化，除了默认弧度之后，最主要就是颜色发生了改变，从默认白色变成了带着浅蓝色的效果，但是这里有个坑，就是，**此时就算你给 Card 设置  `color: Colors.white,` ，它也依旧会带着这个浅蓝色的效果**。

| M2                                                      | M3                                                      |
| ------------------------------------------------------- | ------------------------------------------------------- |
| ![](http://img.cdn.guoshuyu.cn/20231123_M3/image15.png) | ![](http://img.cdn.guoshuyu.cn/20231123_M3/image16.png) |

那么这个颜色如何去除？其实只要  `ColorScheme` 下设置  `surfaceTint` 为透明色就可以了，如下图所示，因为 `Card` 的效果是通过封装 `Material` 控件实现，而  `Material`  在 M3 下会通过 `elevation` 和  `surfaceTint` 去合成一个覆盖色。

```dart
ColorScheme.fromSeed(
  seedColor: Colors.blue,

  ///影响 card 的表色，因为 M3 下是  applySurfaceTint ，在 Material 里
  surfaceTint: Colors.transparent,
),
```

![](http://img.cdn.guoshuyu.cn/20231123_M3/image17.png)

![](http://img.cdn.guoshuyu.cn/20231123_M3/image18.png)

所以根据判断，**将 `surfaceTint` 设置成透明就可以去除 `Card `这个覆盖色，这个逻辑在 `BottomAppBar` 里同样存在**，所以如果你需要把它们都恢复都 M2 效果，那么就只需要把  `surfaceTint` 设置成透明色即可。

![image-20231123172627998](http://img.cdn.guoshuyu.cn/20231123_M3/image19.png)

所以类似的变动才是 M3 里最坑的点，如果你不了解他们的底层实现，那么在升级之后，发现明明代码给了白色，为什么它还是会有浅蓝色效果？这对于开发者来就是一个找🐛的天坑，所以在这里也用 `Card` 提供一个解决问题的典型思路。

另外还有一个典型的控件，那就是 `FloatingActionButton`(FAB) 。

# FloatingActionButton

从 M2 到 M3， `FloatingActionButton`(FAB)  控件最大的变化就是变成了方形，其次颜色也不跟随之前和主题蓝色，我们不说 M3 这个「优化」如何，就说如何恢复到 M2 的效果。

| M2                                                      | M3                                                      |
| ------------------------------------------------------- | ------------------------------------------------------- |
| ![](http://img.cdn.guoshuyu.cn/20231123_M3/image20.png) | ![](http://img.cdn.guoshuyu.cn/20231123_M3/image21.png) |

首先按照惯例，肯定有一个叫  `floatingActionButtonTheme`  的参数，可以用于配置 `FloatingActionButtonThemeData` ，所以这里我们首先添加上配置，然后通过 `shape` 先变回原形，并且修改  `backgroundColor` 变成蓝色。

```dart
floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.blue,
    shape: CircleBorder()
),
```

那么此时剩下的就是 `Icon` 的颜色，我们当然可以在用到   `Icon`  的地方手动修改为白色，但是我们希望的是全局配置默认恢复到 M2 时代，所以我们就要去找  FAB 下     `Icon`  是如何获取到颜色的。

> 而寻找这个颜色的实现，居然就让我开启了一段漫长的旅程·····

首先  `Icon`  肯定是通过` IconThemeData` 去获取默认颜色，因为 FAB 的主题下没有 `iconTheme` 可以配置，那么首先就想到配置一个全局的 `iconTheme: IconThemeData` ，但是神奇的问题来了，配置之后居然无效。

那么就开始往上查找，然后依次返现， FAB 内部是通过  `RawMaterialButton` 实现的点击，而 `RawMaterialButton`  内部就有一个 `IconTheme.merge` 的实现，**那么 FAB 里的 `Icon` 默认应该是使用了  `effectiveTextColor` 这个颜色**。

![](http://img.cdn.guoshuyu.cn/20231123_M3/image22.png)

之后开始经历一番漫长检索关联，最终可以看到：

- 这个 `effectiveTextColor` 来自从 FAB 传入的 TextSytle 的 color
- 而 `textSytle` 来自 `extendedTextStyle`
- 而 `extendedTextStyle` 来自 `foregroundColor`
- `foregroundColor ` 默认来自 `floatingActionButtonTheme` 的  `foregroundColor`

![image-20231123174431747](http://img.cdn.guoshuyu.cn/20231123_M3/image23.png)

![](http://img.cdn.guoshuyu.cn/20231123_M3/image24.png)

![](http://img.cdn.guoshuyu.cn/20231123_M3/image25.png)

![](http://img.cdn.guoshuyu.cn/20231123_M3/image26.png)

所以破案了，**需要全局设置 FAB 下 ` Icon` 的颜色，是要配置 `FloatingActionButtonThemeData` 的  `foregroundColor`** ，这个设定和名称正常情况下谁能想得到呢？

而且这个传递嵌套如此“隐晦”，只能说， FAB 是 Flutter 样式跟踪里很典型的一个代表：**传递深，theme 引用复杂，类似 `merge`/`copy` 的局部实现太过隐蔽**。

```dart
floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.blue,
    foregroundColor:  Colors.blue,
    shape: CircleBorder()),
```

另外关于 **`IconThemeData` 还有一个冷知识，参数不全的情况下，也就是不满足  `isConcrete` 的情况下，其他的参数在 `of（context） `的时候是会被 `fallback` 覆盖**，这个对于 M3  - M2 的降级适配里也是一个关键信息。

![](http://img.cdn.guoshuyu.cn/20231123_M3/image27.png)

![](http://img.cdn.guoshuyu.cn/20231123_M3/image28.png)

![](http://img.cdn.guoshuyu.cn/20231123_M3/image29.png)

# primarySwatch

最后在聊一个 `ThemeData` 的  `primarySwatch`，为什么聊它，因为如果你的代码里用了 `primaryColorDark` 和   `primaryColorLight`  作为配置，那么使用  ` ColorScheme.fromSeed` 之后，它们会发生一些「奇妙的变化」，所以为了它们可以恢复到 M2 模式，那么设置  `primarySwatch` 可以将它们恢复到原有的效果。

![](http://img.cdn.guoshuyu.cn/20231123_M3/image30.png)

![](http://img.cdn.guoshuyu.cn/20231123_M3/image31.png)

![](http://img.cdn.guoshuyu.cn/20231123_M3/image32.png)



# 最后

如下所示是本次升级适配里的示例代码总和，其实 M3 模式下「降级」到 M2 UI 效果真的是一个体力活，类似上面三个典型的例子，都可以看出来跟踪默认 UI 的实现并不轻松，虽然对于 Flutter 团队来说，升级到 M3 可能是一次正向优化，但是对于不喜欢 Material Design 的国区而言，M3 只能是一个负优化，不知道大家同意不？

```dart
return ThemeData(
  ///用来适配 Theme.of(context).primaryColorLight 和 primaryColorDark 的颜色变化，不设置可能会是默认蓝色
  primarySwatch: color as MaterialColor,

  /// Card 在 M3 下，会有 apply Overlay

  colorScheme: ColorScheme.fromSeed(
    seedColor: color,
    primary: color,

    brightness: Brightness.light,

    ///影响 card 的表色，因为 M3 下是  applySurfaceTint ，在 Material 里
    surfaceTint: Colors.transparent,
  ),

  /// 受到 iconThemeData.isConcrete 的印象，需要全参数才不会进入 fallback
  iconTheme: IconThemeData(
    size: 24.0,
    fill: 0.0,
    weight: 400.0,
    grade: 0.0,
    opticalSize: 48.0,
    color: Colors.white,
    opacity: 0.8,
  ),

  ///修改 FloatingActionButton的默认主题行为
  floatingActionButtonTheme: FloatingActionButtonThemeData(
      foregroundColor: Colors.white,
      backgroundColor: color,
      shape: CircleBorder()),
  appBarTheme: AppBarTheme(
    iconTheme: IconThemeData(
      color: Colors.white,
      size: 24.0,
    ),
    backgroundColor: color,
    titleTextStyle: Typography.dense2014.titleLarge,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
```