#  吹爆 AI ？Flutter 开发在 Cursor & Trae 不一样的 AI 真实体验

最近几天随着 Claude 3.7 Sonnet 的发布，朋友圈几乎都被各种刷屏，各种内容总结下来一句话： **Claude 3.7 Sonnet 是迄今为止「最智能」且首款支持「混合推理」的模型**。

刚好这段时间一直在使用 Cursor 和 Trae ，并且目前 Cursor 的跟进速度也相当感人，如下图这两天已经在使用 Claude 3.7 Sonnet 了 ，恰逢最近在搞一些项目的框架迁移，正好借此机会通过实际需求对比下 Cursor 和 Trae 的 AI 体验，**而本次体验下来，只能说是一言难尽**。。。

![](http://img.cdn.guoshuyu.cn/20250226_AI/image1.png)

本次需求的核心是**让 AI 帮我在一个 Flutter 项目里把状态管理框架从 redux 迁移到 riverpod** ，相信 Flutter 开发应该会理解，这其实不算是一个简单的需求，因为在状态管理逻辑的实现和 API 使用上，redux  和  riverpod 可以说是“南辕北辙”，具体体现在于：

- redux 在 Flutter 上是通过 Aciton -> Reducers -> Store -> View 结构实现单向数据流
- 整个应用的状态集中存储在一个全局 Store 
- 状态（State）不可以直接修改，需要通过 Reducer 生成新状态
- redux 上会有各种 Middleware  和  Epics 穿插在过程处理

而对于 riverpod，它支持分散式状态管理，状态和存储都可以按需定义和组合，核心是依赖 Ref 和各种 Provider ，并且不需要传递  `BuildContext`  。

另外，**状态管理框架在项目里本身就会涉及很多代码模块**，所以可以看出来，这样一个迁移需求无疑是一个「吃力不讨好」的活。

那么，首先从 Trae 开始，目前版本下 Trae 的 Builder 支持的是 `Claude-3.5-Sonnet`  免费使用，一开始我只是用简单一句话来说明需求 ：

![](http://img.cdn.guoshuyu.cn/20250226_AI/image2.png)

可以看到虽然我说的不多，但是起初 Trae 看起来理解的还不错，只是目前体验下， **Trae 的思考速度还是略慢**，而在等了一段时间之后，Trae 告诉我改完了，结果我定睛一看，**好家伙，只创建了一个新的 `gsy_state_provider.dart` ，然后改了  `app,dart` 和 `pubspec.yaml`  两个文件**：

![](http://img.cdn.guoshuyu.cn/20250226_AI/image3.png)

很明显这才哪到哪，所以我让它继续迁移，然后·····它又帮我改了两个文件，然后告诉我改好了：

![](http://img.cdn.guoshuyu.cn/20250226_AI/image4.png)

到这时候，我开始思考大概是我的描述有问题？然后在经过几次尝试后，我 checkout 了项目，然后重新开了一个会话，并且增加了一下明确的路径和引用描述：

![](http://img.cdn.guoshuyu.cn/20250226_AI/image5.png)

而这一次的结果相对好了一些，**但是依旧还是只改了几个文件**，并且我在 review 代码的时候，发现了不少“一言难尽”的提交，比如：

> 在项目里有一些 mixin  的通用 State 基类，但是由于 Trae 在迁移到 riverpod 时，会让 Widget 直接继承 `ConsumerStatefulWidget` ，从而对应的 State 也需要继承  `ConsumerState`  ，然后“基类们”就出现冲突了，甚至有时候它还会把 mixin 的基类改成 abstract ，然后 mixin 就报错····

尽管看起来 Trae 直接使用  `ConsumerState`  也许大概可能是为了更好全局获取 `Ref` ，但是实际迁移过程中，使用  `Consumer` 才能最低程度降低冲突，所以我又不得不 checkout 之后重开个新的会话。

另外由于 Trae 还会有一些不合规的地方修改 riverpod 的参数，所以又继续丰富相关的任务提示词：

![](http://img.cdn.guoshuyu.cn/20250226_AI/image6.png)

而后 Trae 的修改又转好一丢丢，但是貌似也就好了那么一丢丢，甚至虽然你让它不要用 `ConsumerStatefulWidget`  ，但是它还是在某些地方「坚定」的认为需要使用   `ConsumerStatefulWidget`  ，最后我终于“醒悟”：**Trae 它真的没办法一次性帮自动帮我完成框架迁移**。

**就算后续我在提示词增加了各种使用到 redux 的地方，并且标注上它们的业务逻辑作用**，但是 Trae 一次最多就只会帮我修改那么几个文件，**并且还是会残留不少“大坑”等我去填**，比如：

在某个地方业务上是通过一个 `int` 的` index` 去判断获取哪个 `Color` 传递给 Theme 主题，从而生成新的 `ThemeData` ，然后 Trae 修改后让函数的参数直接变成了 `Color`  ， 我直接把对应报错复制给它处理，结果它的处理方式是：

> **将 `index`  通过  `toInt()` 的方式转为整形，然后它就是一个正常的 `Color `** ？

![](http://img.cdn.guoshuyu.cn/20250226_AI/image7.png)

后面让它再多修改几次，它确实也能将错误解决，但是解决的方式是大概是类似 `setThemeData(Theme.of(context))` ，嗯，错误是没了，但是这代码也没有意义了：**获取了当前主题设置给当前主题**。

> **所以在使用 AI 工具修改代码的时候，审查很重要， 有时候它真的就没报错，但是它可能直接帮你屏蔽了一个需求**。

类似的还有，在不合适的地方去修改 riverpod 内的状态是不合规的，然后针对这个问题，Trae 的解决方案就是：

> 加个 `Future` 。

然后运行后继续报错，这种也是比较“恶心”，编译过程没问题，然后运行才出现的“埋坑”，又一次体现了审查的重要性，并且还需要你有对应的认知能力：

![](http://img.cdn.guoshuyu.cn/20250226_AI/image8.png)

最离谱的还有几次，它在宣称「迁移完成」后，甚至都没往 `pubspec.yml`  内添加过 riverpod 的依赖：

![](http://img.cdn.guoshuyu.cn/20250226_AI/image9.png)

再之后，也不知道是不是因为我「骚操作」太多，Trae 就开始进入「红温」，进入了频繁不可用状态：

![](http://img.cdn.guoshuyu.cn/20250226_AI/image10.png)

**自此我放弃在 Trae 下通过 AI 自动完成迁移的可能，然后我就开始转战 Cursor 的 `Claude 3.7 Sonnet`** ，当我以为会有不一样的体验时，它确实给了我不一样的体验，因为它在简单了几个文件后告诉我：

> 我需要手动逐步完成。

![](http://img.cdn.guoshuyu.cn/20250226_AI/image11.png)

不信邪的我又喂了一份非常详细的迁移计划，然后 Cursor 继续告诉我：**这不是可以一步到“胃”的事情，饭要一口一口的吃**。

![](http://img.cdn.guoshuyu.cn/20250226_AI/image12.png)

**到这里我突然就领悟到自媒体在说 `Claude 3.7 Sonnet ` 是我们正在迈向自动编程重要的一步跨越，嗯，目前它还在迈向这个过程，所以大家还是需要开「手动挡」**。

当然 Cursor 也会写“奇奇怪怪”的代码，比如我让 Cursor 帮我生成一个翻译后的代码文件，然后加载顺序是 3 日语，4 韩语：

![](http://img.cdn.guoshuyu.cn/20250226_AI/image13.png)

但是之后 Cursor 给我生成的选项顺序是 3 韩语 4 日语，然后运行时点击「切换到日语」时就发现界面变成了韩语：

![](http://img.cdn.guoshuyu.cn/20250226_AI/image14.png)

另外，在 Cursor 上开 agent 或者 Thinking 模式下整体效果会更好一些，但是刚改了个开头就被强行结束的体验，也确实很难接受：

![](http://img.cdn.guoshuyu.cn/20250226_AI/image15.png)

> **从 Cursor 谨慎的角度看，某种程度体验上还真不如 Trae ，但是 Cursor 在 Claude 3.7  下的生成速度和思考能力确实强了不少**。

当然，这也和模型在整个「上下文窗口数量」还有「单次响应」的 Token 有关系，**也就是你需要处理的代码越复杂，量越大，就越不好用，AI 理解上更容易出现「断章取义」的情况**。

当然，吐槽了这么多，**其实有了  Cursor 和 Trae  之后，对工作效率提升上还是很有帮助的**，比如多语言翻译，还有修复某些具体编译错误时，AI 给出的建议和自动化能力，确实能很好提升开发体验，前提是需要注意一些关键点：

- 要尽可能让 AI 理解你要修改的业务，虽然它理解能力有限，但是你不让他理解，它就会写出你无法理解的 bug
- 让 AI 改问题，最好不要只告诉他问题，尽可能告诉他解决的思路和方向，不然最后业务改着改着就给你改没了
- 目前的 AI 能力，尽可能拆分需求或者缩小 bug 范围，在复杂场景它每次处理的「量」真的很有限，我试过改一个问题，Trae 光思考就好几分钟后瞎改

最后，聊个题外话，在找资料和具体问题建议上，DeepSeek 的深度思考确实不错，另外 Grok 3 的体验也让我很惊喜，有时候我怕“幻觉”的时候，就在两个平台上同时问后对比，大部分时候两者的答案水平都不相上下，而 Grok 3 开了 DeepSearch 后，往往结果更好一些：

![](http://img.cdn.guoshuyu.cn/20250226_AI/image16.png)

当然，我在 Grok 3 几乎每天都被限制 DeepSearch ，毕竟 Grok 3 的价格感人， 还是继续用用免费额度好了：

![](http://img.cdn.guoshuyu.cn/20250226_AI/image17.png)

**在有了 DeepSeek 和 Grok 3 之后，找资料看问题真的比直接翻文档确实来的方便，虽然它们在代码建议上还是会瞎编 API ，但是思路参考还是挺不错的**，对比之下，现在的 ChatGPT 的推理搜索虽然出结果很快，但是貌似除了快之外，答案的可用性并不是很好。

这大概就是我这段时间完整的 AI 辅助编码体验，它们确实有很大的帮助，但是也没有各种文章中提到那么强力，而根据 Anthropic 的发展图景：**它们希望是在 2025 年 Claude 可以成为独立自主工作数小时的专家级智能体，而到 2027 年能够解决人工团队花费数年才能解决的挑战性难题**。

![](http://img.cdn.guoshuyu.cn/20250226_AI/image18.png)

所以，或者留给我们的时间只有两年了？



