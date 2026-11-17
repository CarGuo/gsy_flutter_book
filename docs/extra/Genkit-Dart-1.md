---
title: "Genkit Dart 1.0 发布，Flutter 原生的 AI Agent 终于完整了"
---

# Genkit Dart 1.0 发布，Flutter 原生的 AI Agent 终于完整了

Genkit Dart 1.0 之后，Flutter 终于也有了一套稳定版本的 Dart AI 应用框架，比如你用 Flutter 开发一个 AI 订餐助手，用户说：“今晚 7 点，帮我找一家能坐 4 个人的餐厅” ，这里 Genkit  现在可以提供整套：

- Flutter 怎么访问后台
- 怎么避免模型返回错误的数据结构
- AI 调用业务接口时怎么控制权限
- 线上出现问题后怎么知道是哪一步出错
- ····



Genkit Dart 现在基本把这些工作统一管理起来了，比如订餐助手的第一步应该是查餐，Flutter 把人数、日期和时间传给 Dart 服务端，服务端再让模型理解需求，然后通过真正的餐厅库存接口查询结果。

> 听起来很简单，但是这里肯定不能直接相信模型说“有位置”，因为模型没有实时库存，只有业务工具返回的结果才有这个依据，查到的结果也需要整理成确定的数据字段，比如餐厅、时间、人数和可订状态，然后交给 Flutter 显示。

**这部分在 Genkit 里面叫作 Flow，它是一个带有输入、输出类型的 Dart 函数，可以在里面调用模型和工具，比如输入用 `TableRequest`，输出使用 `TableOptions`，两边通过 `schemantic` 定义、生成和校验**。

甚至服务端也可以通过 `GenkitRouter` 把 Flow 注册成 HTTP 接口，客户端再通过  `defineRemoteAction` 调用，之前的 Preview  版本其实已经支持远程 Flow，但需要借用  Shelf 等方式挂载接口，**现在 1.0 把 `GenkitRouter` 加入到了核心公开 API，统一提供 `dart:io`、已有 HTTP Server 和 Shelf 的接入路径** ：

![](/article-assets/3124b7283bc37597291e5959.webp)

**而且还有第二种部署方式：`defineRemoteModel` 支持 Flutter 留住自己的提示词和流程**，只把模型请求交给受保护的 Dart 后端转发，这样做 Demo 或者 BYOK 应用的时候也比较方便，不过对真实订餐业务之类的，肯定还是把查询、确认和预订都放进服务端 Flow 好一点，因为模型最终会操作用户订单，不能只靠客户端逻辑约束。

不过查餐位其实还算简单的场景，真正麻烦的是控制它什么时候可以下单，比如 AI 查到了 19:00 的餐位，用户接着说“就订这家”，那模型可能会调用 `bookTable`，但这一步会改变真实业务数据，甚至产生费用，如果只是靠 Prompt 里要求“必须先询问用户” 那肯定扑街。

所以各类 Agent SDK 都会有对应的  API 支持，这里 Genkit  是通过工具函数在执行实际预订之前返回 `.interrupt(...)`，生成过程就会暂停，Flutter 可以拿到等待确认的信息，用户同意后才恢复工具执行。

简单来说类似这样的流程：

```dart
final approved = ctx.resumed is Map && ctx.resumed['approved'] == true;
if (!approved) {
  return .interrupt({'restaurant': input.restaurant, 'time': input.time});
}
return .response(await bookingService.book(input));
```

确认操作发生后，应用再把之前的消息历史和 `interruptRestart` 的审批元数据传回 Genkit，工具函数能够从  `ctx.resumed` 读到它，然后继续执行。

> 也就是模型自己不能跳过工具函数里的审批分支。

有了这些控制，我们有时候还需要知道出错时系统究竟走到了哪一步，这个真实的 Developer UI Trace 截图就很不错：

- 左边 `uiAgent` 的执行记录包括首次 Gemini 调用、`checkAvailability` 查询和第二次 Gemini 调用
- 右边能看到输入消息以及模型输出的结构化内容

![](/article-assets/0339a3672c7143fe401b26a4.webp)

如果需要还要加统一的重试、日志、模型调用次数上限和工具审批，就可以通过 Middleware 处理，1.0  开始进一步提供 `ai.defineGenerateMiddleware` 来注册自定义拦截器，然后 Genkit 能够按 Schema 配置同时在 Developer UI 里显示。

> 还可以用 Middleware 限制单次生成最多调用模型多少次。

如果在配合 A2UI 的自持，基本上 Flutter 现在开发 AI 和 Agent 场景是真的就原生一条龙了，虽然不是最强的，但是这一套在 Flutter 上的开发体验是真的意外的不错。

![](/article-assets/8f69a017a8c5b1b0ebc59b7a.webp)
