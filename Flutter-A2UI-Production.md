# Flutter  A2UI 的正确用法，怎么把 AI 和动态 UI 结合生产。

实际上我们聊谷歌和 Flutter 的 A2UI  挺多次了，但是有个问题之前一直被提到：**LLM 生成界面的速度太慢了**，比如一次 Generative UI 请求，就需要经历：

> *模型读取上下文、理解业务数据、调用工具、生成 A2UI JSON，再由 Flutter 把 JSON 转成 Widget，哪怕模型再快，也是需要几十秒甚至分钟级别的等待*。

所以 Flutter 官方针对这个做了一个场景优化：**如果界面在用户打开 App 之前就已经有足够的信息可以生成，那为什么不提前生成**？

官方提供了一个叫 Commis 的案例，场景是一个给餐饮团队使用的 App ，Firestore 里面保存着 `catering job`，比如某一天几点有活动、地址在哪里、需要准备多少人的餐食之类。

以前的 Generative UI 典型流程是用户打开页面以后，客户端把这些信息交给 Agent，然后让 Gemini 现场生成一张对应的 UI 卡片。

但是现在 Async A2UI 把这个生成时机往前挪了下，比如 Firestore 里的 job 一旦发生变化，就直接触发后台 Cloud Function，Cloud Function 把最新 job 数据交给 AI，让模型生成对应的 A2UI，生成结果再写回 Firestore。

![](https://img.cdn.guoshuyu.cn/17cfe1d7-ab5f-4524-ad00-b6fd5bc06580.png)



这时候，只要用户真正打开 App ，Flutter 客户端就可以直接把已经生成好的 A2UI 读出来同时渲染，也就是根据用户数据，我们可以提前在某些场景生成好页面。

> 如果跟着这个角度想，我们是不是可以在某些活动，或者某些节假日场景，然后让 AI 根据用户自己的数据，提前生成好一些个性化的 UI 或者交互？

如果从架构角度理解，这东西其实很像数据库里的 Materialized View，也就是物化视图：

- Firestore 里面的 job 是原始业务数据
- A2UI 可以看成根据这些业务数据计算出来的一份 UI 投影
- 原始数据变化之后，后台重新计算 UI
- 用户真正需要读取的时候，直接使用提前计算好的结果

![](https://img.cdn.guoshuyu.cn/c04d6593-53a8-4116-955b-9828c41a905c.png)

这一步对 Generative UI 的场景的意义实际上比单纯 “缓存一下 JSON” 要大得多，因为这样想的话，甚至已经开始改变 A2UI 的角色，**A2UI 不再只是 LLM 实时输出过程中短暂存在的一串中间消息，它开始成为一种可以保存、传输、恢复、重新播放的 UI 数据**。

比如过去我们很容易把 Generative UI 想成这样的链路：

```
User → LLM → A2UI → Flutter Widget
```

用户用户产生请求，模型思考，模型生成 UI，Flutter 渲染，但是 Async A2UI 实际上把这条链拆成了两个生命周期，后台生命周期变成：

```
Business Data Change → Agent → A2UI → Storage
```

同时用户侧变成：

```
App Open → Storage → A2UI Runtime → Flutter Widget
```

这两个过程完全可以发生在不同时间，甚至不同设备和不同服务器上，同时 UI 又可以受到 App 开发者的设计规范约束，受到 Flutter 端 Widget Catalog 的限制，不至于完全动态化失去控制。

> 等于你甚至可以把某一张模型生成的界面存到 Firestore、SQLite、Redis、对象存储甚至 CDN。

就比如下面这段代码的 `_transport.addChunk(feeds)` ，表面上看只是把 Firestore 中的一段字符串塞进去，实际上 Flutter GenUI 平时连接 AI  时，`A2uiTransportAdapter`  就会不断收到模型流式输出的文本 chunk，然后交给 `A2uiParserTransformer` 解析成 A2UI Message，之后再由 `SurfaceController` 更新 UI ：

```dart
Future<void> _initAgent() async {
  // This repository is a class I use to hide away queries to Firebase. It's
  // really just grabbing values and providing a stream.
  final repository = context.read<FirestoreRepository>();

  String? feeds;

  try {
    // 1. Fetch active jobs and wait for their cached feed messages
    final jobs = await repository.getJobs();
    final feedFutures = jobs.map((job) => repository.getFeedMessage(job.id));
    final results = await Future.wait(feedFutures);

    // 2. Combine the non-empty cached A2UI messages
    feeds = results
        .map((r) => r?.trim() ?? '')
        .where((r) => r.isNotEmpty)
        .join('\n\n');
  } catch (e) {
    debugPrint('Error initializing agent: $e');
  }

  // 3. Initialize the agent session, passing the cached messages
  _agentService = FirebaseAILogicService(
    repository: repository,
    catalog: _catalog,
    cachedMessages: feeds,
  );

  // 4. Feed the cached messages directly to the transport adapter
  if (feeds != null && feeds.isNotEmpty) {
    _transport.addChunk(feeds);
  }

  setState(() => _isWaiting = false);
}

```

所以实际上 Async A2UI 没有另外开发一套什么 Cached Renderer，它只是从 Firestore 读出来的缓存字符串，直接重新塞进原来的 Transport。

> 也就是 A2UI 的 Runtime 根本不用关心这段 A2UI 到底来自哪里，它可能是 AI 此刻刚刚吐出来的，可能是后台服务器昨天生成的，也可能是本地 SQLite 里保存了一个星期的，甚至可以是开发者手写的测试 fixture，只要消息满足 A2UI 协议，后面的解析和 Surface 构建流程完全一样。

![](https://img.cdn.guoshuyu.cn/image-20260816165025413.png)

**这等于是让 A2UI 有了另外一种可回放的特性。**

A2UI 里面本身就存在  `createSurface`、`updateComponents`、`updateDataModel`、`deleteSurface`  这一类消息，如果把这些消息理解成对 UI 状态的一系列操作会更直观，：

- 创建一个 Surface
- 向 Surface 填组件
- 更新 DataModel
- 再删除某个 Surface

**也就是只要把这一系列输入保存下来，重新播放一次，就可以把 UI 恢复出来，这其实已经有一点 UI Event Log 的味道了，充满了新的想象控件有没有？？**

我感觉如果沿着这个思路继续走，实际上很容易出现另外一种更有意思的架构：**缓存初始 Surface，然后再进行实时增量更新**，比如：

- 一个 AI Dashboard 昨晚已经生成好了结构，用户早上打开 App 时，缓存的 Surface 可以立刻出现
- 同时客户端再启动 Agent，让模型读取今天新增的数据，如果只有几个数字变化，就发送  `updateDataModel`
- 如果某一块 UI 需要改变，再发送  `updateComponents`
- 用户看到的是瞬间出现的旧版本，然后很快被刷新成最新状态

这个过程不需要发版和更新，同时还可以灵活控制，这个缓存支持我觉得挺有意思的，**甚至 Firestore 都可以被替换掉，你可以自己定义或者选择  Cloud Function** 。

而且从 Firestore 读取出来的 cached A2UI 不是只发给 Flutter Renderer，它同时还会交给 Agent，这样比如后台昨天已经生成了一张卡片，今天用户打开 App，Flutter 通过缓存把卡片恢复出来了，然后用户又说了：“*把这个活动改到下周一*”，有了上下文的时候，模型才知道这个活动涉及的 UI 是哪些。

**但是这也出现了新的问题， Generative UI  的 UI State 会需要成为 Agent State 的一部分**，整个状态会复杂很多：

- Generative UI 需要额外保存当前有哪些 Surface
- 每个 Surface 有哪些 Component
- DataModel 当前是什么状态
- 用户刚才操作了什么
- 模型曾经创建过哪些东西
- 当前 UI 是不是当前 Agent Session 创建的

**整套 App 的状态可能会变得相当的耦合，Flutter Runtime 要恢复 UI State，Agent 要恢复对 UI 的认知，两边还必须对应得上。**

而且如果 Surface 越来越复杂，这一套很可能继续演化成带有 *snapshot、revision、event log、checkpoint* 之类的机制，比如保存当前 Surface Snapshot，同时保存生成它时对应的 conversation revision，然后 Agent Session 恢复时直接恢复到那个 checkpoint。

然后新的问题又又又来了，缓存失效了这么办？？比如：

- 10:01 用户修改了一次 job ，后台触发 AI  生成 A
- 10:02 用户又修改一次，后台又开始生成 B
- LLM 请求的完成时间并不确定，如果 B 先回来，A 后回来，旧 UI 完全可能把新 UI 覆盖掉

甚至  Flutter App 更新以后 Widget Catalog 发生变化，服务器以前生成的 A2UI 可能引用旧 Component schema，新版本客户端已经不认识它····

> 所以如果真用到生产出场景，一段 JSON 肯定是不够了，各种元数据都必须完备才行。

从这个角度看，A2UI 想做的已经越来越接近一种 Generative UI Runtime 了，LLM 负责决策和组合，A2UI 负责描述 UI，Flutter Runtime 负责安全地把描述映射到真实 Widget，生成端和渲染端之间不再需要保持同步连接，甚至不需要同时在线，比如：

- Navigation、Scaffold、支付、登录这些稳定核心还是固定代码
- 推荐卡片、Dashboard、任务摘要、个性化 Feed 这种高度动态但可以提前预测的区域，用 Async A2UI 预生成
- 真正依赖用户当前语言指令的表单、工具面板、临时工作流，再交给 Agent 实时生成



或者只有这样，才是 A2UI 正确的落地方向。



# 链接



https://github.com/flutter/demos/tree/main/commis