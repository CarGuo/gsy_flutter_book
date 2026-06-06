# 终于，Flutter 修复  Android  中文字体异常，但是很草台，不知怎么吐槽

半年了，Flutter 终于修复了 3.38 带来的一个奇葩问题，**在某些 Android 设备上，如果对比会发现，中文字体和之前版本不一样了**，当然不是说完全渲染不对，而是字体变了：

![](https://img.cdn.guoshuyu.cn/image-20260508102541626.png)

这个问题其实是因为中文字体从系统「*默认的无衬线体*」，变成了明显偏「*宋体风格的衬线体*」，问题主要集中在部分三星、OPPO、OnePlus 等设备。

> 所以它不是必现。

而这个问题恶心在于，**其实 Flutter 在这里什么都没改，问题其实是 Skia 引起的，但是又不是完全 Skia 的问题**，因为 Flutter 在 3.38 更新了 Skia 的版本，而 Skia 在这个新版本里，**对 Android 字体回退逻辑发生了一次重构**，而这次重构改变了 `find_family_style_character` 在某些场景下选择 fallback 字体的顺序：

![](https://img.cdn.guoshuyu.cn/01_root_overview.png)

> **你说 Flutter 不是 Impeller 了？为什么还 Skia** ？这个问题其实我们说过很多次了，在字体，字形选择和字体排版等场景，Flutter 还是依赖 Skia 实现，只是最终渲染的是 Impeller 。

简单来说就是，Flutter 3.38 升级了 Skia，而 Skia 的 `a918c0e` 重构了 Android 字体搜索逻辑：**当搜索过程走到 `familyName` 为空的路径时，新逻辑跳过了 `fFallbackFor` 的匹配检查**，然后直接使用了「回退列表」里第一个中文字体。

![](https://img.cdn.guoshuyu.cn/08_a918c0e_side_effect.png)

而在一些设备上，这个第一个被命中的字体刚好是 `NotoSerifCJK-Regular.ttc`，它是衬线体，所以这时候中文就被渲染成了宋体风格。

> **听起来太抽象了？没事，后面聊聊就懂了，因为懂了之后你会觉得更抽象**。

举个例子，在 Flutter 这段代码，虽然你写了  Roboto ，但是 Roboto 本身不包含中文字体，所以当 Flutter 要渲染「重」这个字时，底层会进入 Android  字体 fallback 机制：

```dart
Text(
  '重置密码',
  style: TextStyle(fontFamily: 'Roboto', fontSize: 45),
)
```

当前  Roboto  字体没有这个字形，所以需要去系统配置里找一个可以显示该字符的「后备字体」，而在 Android 上，这部分逻辑由 Skia 的 `SkFontMgr_android.cpp` 负责，其中关键函数就是 `find_family_style_character`：

> **在字体列表里找一个既符合当前字族(Group)约束、又包含目标字符的字体**。

这里有两个关键概念：

- 一个是 `familyName`，也就是当前希望匹配的目标族名，比如 `Roboto`、`serif`，或者空字符串
- 另一个是字体配置里的 `fFallbackFor`，它表示「这个字体是给哪个字族做后备的」

这里以三星设备上的典型配置为例，系统里可能同时存在两个 CJK 字体：

- 一个是无衬线体 `SECCJK-Regular.ttc`，它的 `fFallbackFor` 为空，**表示它是通用后备**
- 另一个是衬线体 `NotoSerifCJK-Regular.ttc`，它声明 `fFallbackFor = 'serif'`，表示它原则上应该只给 serif 字族做后备

![](https://img.cdn.guoshuyu.cn/02_font_config_fallback_list.png)

```xml
<!-- 普通无衬线字体，通用后备，fFallbackFor 为空 -->
<family lang="zh-Hans">
    <font>SECCJK-Regular.ttc</font>
    <!-- fFallbackFor = ""  ← 空，意思是"我是所有字族的通用后备" -->
</family>

<!-- 专门给 serif 字族用的后备，fFallbackFor = "serif" -->
<family lang="zh-Hans">
    <font>NotoSerifCJK-Regular.ttc</font>
    <!-- fFallbackFor = "serif"  ← 意思是"我只给 serif 字族做后备" -->
</family>
```

这里的关键就是，**`SECCJK-Regular.ttc` 是通用 fallback，适合 Roboto 这种默认无衬线场景下兜底中文**，而 `NotoSerifCJK-Regular.ttc` 是 serif 专用 fallback，只有明确要求 serif 风格时才应该使用。

> 但是问题就在这里：**Skia 这个 Bug 版本，在优化匹配逻辑的时候，直接忽略了 `fFallbackFor`**，所以每一个重构的初衷都是好的，自己力不能及，总会带来坑坑洼洼。

而在以前没问题的版本里，**即使 `familyName` 为空，也会继续检查 `fFallbackFor`** ，在 Flutter 3.35 对应的 Skia 旧逻辑里，当 `familyName = ''` 时，Skia 会遍历回退列表做二次匹配。

![](https://img.cdn.guoshuyu.cn/04_correct_version_flow.png)

比如老版本里，它先看到 `NotoSerifCJK-Regular.ttc`，发现它的 `fFallbackFor = 'serif'`，并不等于空字符串，于是跳过。

然后继续往后找，看到 `SECCJK-Regular.ttc`，它的 `fFallbackFor = ''`，匹配空 `familyName`，而且包含“重”这个汉字，于是返回正确字体。

但是 3.38 开始，Flutter 对应使用的新的 Skia 版本里，**当 `familyName` 为空时，它因为忽略 `fFallbackFor` ，所以直接就返回了 fallback 的第一个**。

回到 Skia commit `a918c0e` 这个修改，它起初的目的是重构字体搜索路径，让搜索更完整，但在重构过程中，不知觉的引入了这个其他 bug ：当 `familyName` 为空时，就跳过 `fFallbackFor` 匹配检查。

![](https://img.cdn.guoshuyu.cn/03_bug_version_flow.png)

这在一些极端兜底场景里看起来合理，**因为空 familyName 可以被理解成“找任何能显示这个字符的字体”**，但是它在 Android CJK 字体配置就产生了副作用：

> `NotoSerifCJK-Regular.ttc` 虽然只是 serif 专用后备，但它确实包含中文，如果它在某个无语言约束或空 `familyName` 路径里排在前面，就会被直接返回，这也是为什么只有某些机器才会的原因，**这个 Bug 取决于厂家 fallback 自己排列的顺序**。

![](https://img.cdn.guoshuyu.cn/05_correct_vs_bug.png)

关键差异只有一个：当 `familyName = ''` 时，到底还要不要继续检查 `fFallbackFor`，在旧逻辑继续检查，所以会跳过 `fFallbackFor = 'serif'` 的专用字体，而在 Bug 逻辑里会跳过检查，所以 `NotoSerifCJK` 被直接返回。

> 当然，这里还有一个为什么会空字符串？**因为前几轮搜索没找到时，Skia 内部会用空 familyName 再试一次"无差别全局搜索"。**

而一开始大家发现，只要在 `MaterialApp`  里面显式配置中文  locale ， Flutter  就能正确识别语言环境，从实现正常渲染：

```dart
MaterialApp(
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('zh', 'CN'), // 加上这个，字体渲染恢复正常
    Locale('en', 'US'),
  ],
  locale: Locale('zh', 'CN'), // 或者依赖系统语言
  // ...
)
```

但是后来又发现，**当然系统语言为英文时，出现中文字体还是会 fallback 到错误字体上**，因为根本原因还是在 Skia 层。

比如 Flutter 渲染文字时，最终会调用 Skia 的 `onMatchFamilyStyleCharacter`：

```c++
onMatchFamilyStyleCharacter(
    familyName,  // 字体名，如 "Roboto"
    style,       // 字重等
    bcp47[],     // ！！！！！注意这个，语言标签数组，如 ["zh-Hans"] 或 ["en-US"] ！！！！！
    bcp47Count,
    character    // 要渲染的字符，如 '重'
)
```

而这里的 **`bcp47[]`  这个语言标签数组，就是 locale 直接影响的东西**，正常来说，如下代码所以，带语言标签的搜索（①）优先级高于空语言标签的兜底搜索（②），所以当 `lang.getTag()` 存在时，是可以匹配到正确的字体：

```c++
for (const SkString& currentFamilyName : {familyName, ""}) {
    for (bool elegant : {true, false}) {

        // ① 先用 bcp47 里的每个语言标签搜索
        for (int i = bcp47Count; i --> 0;) {
            SkLanguage lang(bcp47[i]);
            while (!lang.getTag().isEmpty()) {
                matchingTypeface = find(currentFamilyName, lang.getTag(), elegant);
                if (matchingTypeface) return matchingTypeface;  // 找到就立刻返回
                lang = lang.getParent();  // zh-Hans → zh → ""
            }
        }

        // ② bcp47 全部用完还没找到，再用空语言标签兜底搜索
        matchingTypeface = find(currentFamilyName, SkString(""), elegant);
        if (matchingTypeface) return matchingTypeface;
    }
}
```
但是 `bcp47[]` 里放什么，还取决于**系统语言和  App 配置的 locale** 的组合，而  `bcp47[]` 在组装时，代码路径会参考系统 locale ，某些系统下**即使配置了 zh-CN，bcp47 数组里也不一定能正确传入 zh-Hans 标签** 。

> **所以这个 Bug 不单单是 Flutter 版本带的 Skia 导致，而是由 Flutter 版本、Skia 版本、Android 系统字体配置、系统语言、应用 locale 等多个因素共同触发**。

![](https://img.cdn.guoshuyu.cn/10_locale_workaround.png)

**然后更抽象的来了**，在第一次 Skia 侧做修复时（`Fix SkFontMgr_Android fallback bb69b5b`） ，只是把语义调整为“best match” ，让空 family name 时通用 fallback fonts 优先于 family-specific fallback fonts ，但是它忽略了 `find_family_style_character` 的搜索不是一个单阶段流程，它有多种匹配模式：

- 先精确找 named font
- 再找匹配 `fFallbackFor` 的 fallback font
- 再做 named font 的兜底
- 最后做 fallback font 的兜底

![](https://img.cdn.guoshuyu.cn/06_four_search_stages.png)

而第一次修复主要处理的是 `NameType::Fallback` 路径，也就是「找 `fFallbackFor` 匹配当前 familyName 的 fallback 字体」，但是 `NameType::FallbackNot` 这条最后兜底路径，还是会把「专用 fallback」 和「通用 fallback」 混在一起，以 `familyName = 'Roboto'` 为例：

- 阶段 1 找不到叫 Roboto 的 CJK 字体
- 阶段 2 找不到 `fFallbackFor = 'Roboto'` 的 CJK fallback
- 阶段 3 在非回退字体里也找不到汉字
- 最后进入阶段 4 `FallbackNot`，那么排在前面的 `NotoSerifCJK` 还是会被返回

所以  Skia 又又又进行了第二次修改 （`Adjust SkFontMgr_Android fallback order 2636871`），这次修复后的逻辑核心是：

- 如果存在 `fFallbackFor = ''` 的通用后备字体，就应该优先返回通用后备
- 只有在没有通用后备字体可以显示时，才把 `fFallbackFor = 'serif'` 这类专用后备当成最后手段

![](https://img.cdn.guoshuyu.cn/07_second_patch_priority.png)

**所以这也是这个问题为什么修了这么久的原因，因为它是 Skia 带来的问题，你就只能等 Skia 团队修复，但是谁能想到，它还要修两次才修的好**。

![](https://img.cdn.guoshuyu.cn/09_skia_to_flutter_roll.png)

但是，**严格来说这个 Bug 修的算快的**，因为它不只是在 Flutter 上会有问题，如果是某个 Android 版本也引用了这个 Skia 提交，其实也会有类似问题，**所以根据 Flutter 其他问题的时间周期来看，这个 Bug 修的算快了**，因为它同时也影响了 Android 平台本身。

而目前这个修复的 Skia 版本已经合并到 `3.43.0-0.3.pre` ，所以下个版本 3.44 稳定版就可以直接 Fix 问题了，不得不说这个问题真的很抽象又恶心，**最重要这个 Bug 出现的原因和修复过程也是很草台**，同时也不得不感慨，字体问题永远是中文的痛处。
