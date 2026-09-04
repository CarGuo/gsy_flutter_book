

# AI 时代，也许你的 Flutter 需要一套 Dartastic OpenTelemetry 监控

先简单说说 OpenTelemetry，大家应该不陌生，它是一个供应商无关的开源可观测性框架，可以用于检测、生成、收集和导出遥测数据，比如 traces、metrics和 logs 等，因为 OTel 是中立性开源工具，所以它可以和各种可观测性后端一起使用， 包括  Jaeger 和 Prometheus 这类开源工具或者其他商业化产品。

![](https://img.cdn.guoshuyu.cn/10345a01-774e-40f7-9eb3-f4e06d612a99.png)

> OpenTelemetry 的一个主要目标是：**不管 App 或者系统采用什么编程语言或者基础设施，都可以轻松将收集到的信息仪表化**。

**所以这里的 `dartastic_opentelemetry` ，其实就是用纯 Dart 实现的一套 OpenTelemetry SDK**，通过让 Dart 服务端、命令行程序、Flutter、Web 和 Wasm 应用都能生成标准化的 Trace、Metric 和 Log，再通过 OTLP 发送给 Grafana、Tempo、Datadog、Elastic、Honeycomb 相关的可观测平台。

以前做监控和业务埋点， Flutter 项目一般需要分别接入 Sentry、Firebase Crashlytics、Analytics 和自定义日志系统，这种情况下错误、性能、网络请求和服务端链路会分散在不同后台，然后现在 Dartastic 把  Dart 和 Flutter  纳入了统一的 OpenTelemetry 数据模型：

> **一次 Flutter 请求可以沿着 Dart 客户端、网关、Java 服务、数据库一直保持同一个 `traceId`，采集端和后端之间使用标准 OTLP 协议，迁移可观测平台时不需要重新改造业务埋点**。

而且，Dartastic 内部已经包含了完整的采样、Context 传播、批处理、资源检测、三类信号、OTLP/gRPC、OTLP/HTTP、W3C Trace Context、Baggage、环境变量配置和生命周期管理。

> 不过目前 Dartastic 已经进入 CNCF/OpenTelemetry 官方 Dart SDK 的捐赠流程，暂时还不是官方 SDK。

**可能一些人会觉得，日志、Crashlytics 和性能监控早就有了，再高一套 OpenTelemetry SDK 的价值高吗**？实际上问题在于，以前这些工具一般都是各自拥有一套封闭的数据结构：

- Crashlytics 看到一次异常
- APM 平台看到一条慢请求
- 业务统计系统看到一次支付失败
- 服务端日志又记录了数据库超时

> **它们可能来自同一次用户操作，但缺少共同的 Trace Context，开发者只能根据时间、用户 ID 和请求参数人工拼接现场，这对 AI 来说也是，它们没办法直接明白平台之间的业务耦合在哪里**。

然后现在 OpenTelemetry 给出的基础模型是：

- `Trace` 描述一次操作经过了哪些环节
- `Span` 描述其中一个具体步骤，例如 HTTP 请求、数据库查询或本地计算
- `Metric` 描述一段时间内的数量和分布，例如请求量、错误率和响应耗时
- `Log` 记录带结构化字段和上下文的事件
- `Resource` 表示这些数据来自哪个应用、版本、设备和运行环境
- `Context` 负责让父子 Span 关系穿过异步调用和服务边界

**实际上这对 AI 场景很重要，因为 AI 需要排查问题的时候，最需要的就是一条从头到位的证据链路，因为 AI 不是人，它不知道你的详细业务和真实情况，所以这种链路其实特别重要。**

> 当然，对 Dart 来说这个 SDK 最困难的点其实不在于定义 `Span`   之类的实现，这里真正麻烦的是让这套上下文在 `Future`、`await`、callback、`Timer`、`Stream`、`Isolate `和 `HTTP` 请求之间可以稳定传播，同时还要实现采样、批量导出、失败处理、关闭刷新，以及符合 OTLP 线协议的序列化等等。

所以 Dartastic 的价值主要就在这些底层部分，Dartastic 实际上是通过两个核心仓库组成：

| 组件                          | 职责                                                         |
| ----------------------------- | ------------------------------------------------------------ |
| `dartastic_opentelemetry_api` | 定义 Tracer、Span、Context、Metric、Logger 等公共接口，并提供 No-op 实现 |
| `dartastic_opentelemetry`     | 实现采样、处理器、存储、资源检测和 OTLP 导出等真正的数据处理能力 |

这种拆分其实就是 OpenTelemetry 的经典风格，一个用于埋点的第三方库，例如 Dart HTTP 客户端，可以只依赖 API 包，就算最终应用没有安装 SDK，这些埋点调用也会进入 No-op 实现，不会报错和产生数据。

然后等到应用调用 `OTel.initialize()` 后，全局工厂从 API 的 No-op Factory  切换成 `OTelSDKFactory`，然后新建的 Tracer、Meter 和 Logger 才开始进入真实处理管线。

> 不过这里有一个容易忽略的细节：**初始化前已经取得的对象还是 No-op 对象，不会被自动升级，所以应用可以晚一点初始化 SDK，第三方库也能安全依赖 API，但业务代码不应该在初始化前缓存 Tracer**。

而且 Dartastic 这层设计上还做了一个很有 Dart 风格，但是也很有争议的实现：**几乎所有对象都通过静态入口 `OTel` 和 Factory 创建，许多实现类的构造函数是私有的**。

所以通常的调用方式是：

```dart
await OTel.initialize(serviceName: 'checkout-service');

final tracer = OTel.tracer();
final span = tracer.startSpan('create-order');
```

> 所以增加一种可创建对象时，需要沿 着 `OTel`、Factory、`*_create.dart`  三层去修改，不能只增加一个公开构造函数。

这样做的优点是 API 路径统一，可以在 API No-op、真实 SDK、Web 和 Native 实现之间切换，但是问题也很明显：

> 全局状态更强，测试需要调用  `OTel.reset()`，同一进程需要多个服务身份或多套端点时要使用 named provider，不能再次调用 `OTel.initialize()`。

接下来，如果从一个请求走完整条链路开始，比如一个 Flutter 应用调用支付服务，支付服务又查询库存，客户端和服务端都接入了 OpenTelemetry，这时候在 Flutter 端点击“支付”时创建一个 Span：

```dart
final tracer = OTel.tracer();
final span = tracer.startSpan(
  'checkout.submit',
  kind: SpanKind.client,
);

try {
  await tracer.withSpanAsync(span, () async {
    await paymentClient.createOrder();
  });
} finally {
  span.end();
}
```

这里 `startSpan()` 只创建 Span，实际上它不会自动把它设置成当前 Span，真正把 Span 写入当前异步上下文的是 `withSpanAsync()`。

> 另外 Dartastic 会是 Dart Zone 保存 `Context.current`， 进入 `withSpanAsync()` 后，同一异步调用链里创建的新 Span 会自动找到当前 Span，然后将它作为父节点，这样跨过多个 `await` 后 Context  还能存在。

然后 HTTP 客户端会通过 W3C propagator 把上下文编码进请求头，典型的 `traceparent`  类似 `00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01` ，服务端收到请求后，从请求头提取 Context，然后在这个 Context 里创建  `POST /orders`  Span，之后服务端查询库存时再创建  `database.query`  子 Span，**最终三个系统里的 Span 共享同一个 `traceId`，但各自拥有不同的 `spanId` 和父子关系**。

> 这条链路里，Dartastic 负责 Dart 进程内部的 Span 生命周期、采样、Context、序列化和导出，具体的 HTTP 客户端、服务端框架或数据库库还是需要相应的 instrumentation，在请求发出和收到时调用 inject/extract，SDK 不可能只靠初始化就知道任意业务请求的含义。

也就是 `dartastic_opentelemetry` 是底层 SDK，**不会自动采集 Flutter 路由、点击、生命周期和掉帧**，上层的 [`flutterrific_opentelemetry`](https://pub.dev/packages/flutterrific_opentelemetry) 才是负责将 Navigator、WidgetsBinding、Flutter Error 和交互事件转换成 OTel 信号。

**所以 Dart 上最棘手的是 Context 问题，OpenTelemetry Trace 能否用起来，很大程度取决于 Context 是否可靠。**

在同步代码里，父子 Span 很容易传递，但是到了 Dart 异步环境，函数调用栈就很难完全表示当前请求，所以 Dartastic 才用 Zone 传播当前 Context：

```dart
await tracer.withSpanAsync(parentSpan, () async {
  await Future<void>.delayed(const Duration(milliseconds: 50));

  final childSpan = tracer.startSpan('child-operation');
  childSpan.end();
});
```

> `childSpan` 会从 Zone 中取得当前 Context，然后自动成为 `parentSpan` 的子节点。

而 Isolate 会更复杂，Zone 只能覆盖一个 Isolate，普通 Dart 对象也不能随意跨 Isolate 传递，所以 Dartastic API 提供 `Context.current.runIsolate()`，把可序列化的 Span Context 传到新 Isolate，然后在接收端恢复成 remote context，新 Isolate 内要重新取得 Tracer，不能捕获父 Isolate 中包含处理器、Exporter 等不可发送对象的 SDK 实例。

> 项目自带的 `isolate_context_example.dart` 会验证两件事：子 Isolate 创建的 Span 与父 Span 拥有相同 `traceId`，并且其 `parentSpanId` 等于父 Span 的 `spanId`。

这项能力对于 Dart 服务端很重要，图片处理、大文件解析、压缩和 CPU 密集任务经常被放进 Isolate，缺少显式传播机制时，Trace 会从任务分发处直接断掉。

不过，它也没办法让任意 `Isolate.spawn()` 自动继承上下文，调用方还是需要使用 `runIsolate()`，或者自己序列化并恢复 W3C Context，自动跨越所有 Isolate 在 Dart 的隔离内存模型下并不现实。

这时候可能就有人有疑问了，那一个 Span 结束后，数据去了哪里？实际上 Dartastic 的 Trace 数据管线可以简单分成四层：

![](https://img.cdn.guoshuyu.cn/image-20260829150547223.png)

创建 Span 时，Sampler 先决定 `DROP`、`RECORD_ONLY`  或者 `RECORD_AND_SAMPLE`，而被丢弃的 Span 还可以保留传播所需的 Span Context，但对应属性、事件和异常操作都会直接成为空操作，结束时也不会通知 Processor。

> 这一点能减少关闭采样后还记录大量对象的成本。

项目提供的采样器数量也很完整，包括  `AlwaysOnSampler`、`AlwaysOffSampler`、`ParentBasedSampler`、`TraceIdRatioSampler`、概率采样、计数采样、令牌桶限流采样和组合采样。

> **生产环境一般更适合用 `ParentBasedSampler(TraceIdRatioSampler(...))`：新 Trace 按 trace ID 稳定抽样，下游服务尊重上游决定，避免同一条分布式链路只留下中间几段。**

Span 结束后，默认进入 `BatchSpanProcessor`，一般源码中的默认配置为：

| 参数         | 默认值 | 作用                       |
| ------------ | ------ | -------------------------- |
| 最大队列     | 2048   | 队列满后，新 Span 会被丢弃 |
| 单批最大数量 | 512    | 限制一次导出的数据规模     |
| 调度间隔     | 5 秒   | 周期性触发导出             |
| 导出超时     | 30 秒  | 防止 Exporter 无限等待     |

Processor 用内存队列和异步锁，Timer 周期性取出一批 Span，再交给 Exporter，目前三类信号都支持 OTLP/gRPC、HTTP/protobuf 和 HTTP/JSON，Web 环境自然更适合 HTTP 方案。

> 而且这里的背压策略比较直接：*队列满时丢弃新数据，它不会暂停业务请求等待 Collector，也不会把遥测数据持久化到磁盘，对可观测 SDK 来说，这是比较合理的默认值，因为监控系统故障不应该拖垮业务，但应用需要通过采样率、队列大小和 Collector 容量控制丢失比例*。

**那另外的 Metric 和 Log 能做到了什么程度？**

Metric 部分目前已经覆盖同步和异步仪表，包括 Counter、UpDownCounter、Histogram、Gauge 以及对应的 Observable 版本，然后数据通过 Metric Storage 聚合，再由 `PeriodicExportingMetricReader` 周期性收集和导出。

> 还有就是 Exemplar，比如 “支付响应耗时” Histogram 的某个桶突然升高，普通 Metric 只能告诉你这一段时间很慢，但是 Exemplar 可以在指标样本中附带一个相关的  `traceId` 和 `spanId`，让开发者从指标跳到具体慢请求，目前代码已为 Sum、Gauge 和 Histogram 接入 `ExemplarFilter` 与 `ExemplarReservoir`。

另外项目也提供 `PrometheusExporter`，但它目前只负责生成 Prometheus 文本格式，SDK 没有内置可供 Prometheus 抓取的 HTTP Server，所以设置 `OTEL_METRICS_EXPORTER=prometheus`  不会自动搭建 `/metrics` 接口，调用方需要自己暴露 `prometheusData`，或者把 OTLP 发送给 Collector，再由 Collector 转成 Prometheus。

Log 管线包含 LoggerProvider、Logger、Simple/Batch LogRecord Processor、OTLP Exporter 以及 `package:logging` bridge，它还能通过 Zone 拦截  `print()`，但需要显式启用和在相应 Zone 中运行，应用也要避免把 SDK 自身调试日志重新送回 SDK，否则容易形成递归采集。

```dart
await OTel.initialize(
  serviceName: 'my-service',
  logPrint: true,  // Enable print interception
  logPrintLoggerName: 'dart.print',  // Optional custom logger name
);

// Use runWithPrintInterception to capture prints
OTel.runWithPrintInterception(() {
  print('This will be captured as an OTel log');
  print('So will this');
});

// For async code
await OTel.runWithPrintInterceptionAsync(() async {
  print('Async print captured');
  await someAsyncOperation();
});
```

> 从实现成熟度看，Trace 是核心，Metric 和 Log 属于可运行的完整管线，而自动 instrumentation 和生产诊断能力还在补齐。

而且这个项目还给做了类型化语义属性，一般大多数语言的 OpenTelemetry SDK 会用字符串表示语义属性，比如：

```dart
span.setStringAttribute('http.request.method', 'GET');
```

这样相对更很灵活，但是比较很容易产生拼写错误或者用了过时字段，甚至把原本应该是整数的值写成字符串，而 Dartastic API  选择生成了对应 OpenTelemetry Semantic Conventions 的枚举，可以写成：

```dart
span.addAttributes(
  OTel.attributesFromSemanticMap({
    Http.requestMethod: 'GET',
    Http.responseStatusCode: 200,
  }),
);
```

>  项目最近还把内部 Resource、异常、Exporter 和环境变量处理中的字符串常量逐步替换成 registry enum。

**不过对 Flutter 项目来说，如果只想获得 Flutter 崩溃上报，其实 Crashlytics 或 Sentry 还是更简单直接，Dartastic 不负责符号化、崩溃后台、告警规则、用户 Session UI 或 Release Health 页面，它提供的是生成与传输标准遥测数据的底座**。

实际上我感觉它更适合下面这种项目：

- 应用包含 Flutter 客户端和 Dart 后端
- 服务端已经采用 OpenTelemetry
- 团队希望统一客户端与服务端 Trace
- 需要把数据发送到自建 Collector
- 希望保留更换 Grafana、Datadog、Elastic 等后端的自由

**纯 Flutter 应用如果希望自动采集页面、生命周期、点击、错误和帧性能，也可以直接用 Flutterrific 和选择相应的 instrumentation 包：**

![](https://img.cdn.guoshuyu.cn/image-20260829151243184.png)

另外，纯 Dart SDK 的 Exporter、Timer 和数据处理主要运行在 Dart 运行时里，移动端如果要捕获 native crash、系统级性能、iOS/Android 原生资源，或者把遥测处理放到独立原生线程，目前单靠 Dartastic 这个仓库到真的不满足，它主要还是处理 Dart 场景的。

> 当然，它也有原生场景的 SDK 版本。

如果感觉还是很抽象，那就直接看 Github 的代码吧。



# 链接

https://github.com/MindfulSoftwareLLC/dartastic_opentelemetry