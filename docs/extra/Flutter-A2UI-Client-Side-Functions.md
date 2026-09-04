---
title: "Flutter A2UI 深度解析，它是怎么提供动态生产力的，然后为什么 A2UI 不只是 Flutter"
---

# Flutter A2UI 深度解析，它是怎么提供动态生产力的，然后为什么 A2UI 不只是 Flutter 

在之前的 [《Flutter A2UI 的正确用法，怎么把 AI 和动态 UI 结合有效生产》](https://zhuanlan.zhihu.com/p/2072368727937628010) 我们已经聊过了 A2UI 一些有意思的生成场景，然后现在 Flutter 官方又通过一个  A2UI Client-Side Functions 的例子来介绍 A2UI 的实现方式，。

> 比如 Demo 实际上很简单，功能就是：AI 生成一个餐饮成本界面，需要计算 3 罐黑豆多少钱。

这个如果放以前，可以让 Gemini 自己算，也可以把请求重新发给服务器处理，而现在 A2UI 可以直接在生成的 UI 里写一个 `calculateCost`  调用，然后通过 Flutter 本地的 Dart 代码计算出价格是  `$2.97`，然后直接显示 ：

![](https://img.cdn.guoshuyu.cn/A2UI.1134fa46b3368e010c0b9c5a752d3e51.gif)

虽然 Demo 很简单，但是实际上 A2UI 其实正在形成一套很有意思的 UI 执行模型：

> **Agent 可以决定界面需要什么逻辑，A2UI 描述调用哪个逻辑，真正执行逻辑的代码提前安装在客户端，也就是模型还是有动态组合 UI 的能力，但是不需要直接生成 Dart 代码**。

其实这个恰好是补上了 Generative UI 很容易遇到的问题：*生成式 UI 可以动态决定“界面长什么样”，DataModel 可以负责“当前状态是什么”，但如果某个 UI 属性需要根据当前状态做一段确定性计算、校验、格式转换或者本地行为，谁来执行？*

**现在协议里确定了，这部分属于 Client-Side Functions 就是这一层**。

实际上 Client-Side Functions  在 A2UI 里一直很重要，因为你只生产纯展示类 UI 就很局限了，但是比如 AI 根据用户要求生成一个订单页面，而页面里有数量输入框、单价、折扣、税费和总价，这时候如果用户把数量从 2 改成 3，总价本身也应该能实时变化。

> 以前的做法很弱智，就是把新数量发回 Agent，让模型重新计算一次，再生成一次 A2UI 更新，听着就觉得很弱智对吧？

而另一种方法就是在每个 Flutter Widget 内部写逻辑，例如  `OrderCard` 自己监听数量，然后计算价格，这种做法当然也可以，但它会破坏 GenUI 里很重要的一项能力：

- Agent 原本可以自由组合组件和数据关系，现在某种计算逻辑又重新被写死进某个 Widget，比如：

  - 今天是  `OrderCard` 要显示价格

  - 明天可能是 `Text`

  - 后天又是 `SummaryCard`

如果「*如何计算价格*」被绑定在某个 Widget 里，那 Agent 实际可以组合的能力会缩水很多，所以 A2UI 给出的办法，**是把 UI Component 和 Client Function 都放进 Catalog。**

比如组件 Catalog 告诉 Agent：

> 你可以用  `Text`、`Button`、`Slider`、`IngredientLine` 这些 UI 原语。

而 Function Catalog 告诉 Agent：

> 你还可以使用 `calculateCost`、`formatCurrency`、`required`、`regex`、`openUrl` 这些客户端能力。

所以当前 Flutter `Catalog` 的实现非常直接，它可以同时持有 `CatalogItem` 和 `ClientFunction`，生成 capabilities  时，每个 function 会暴露  `name`、`description`、`parameters` 和 `returnType`，然后生成完整 Catalog Schema 时，会把每个函数变成一个合法的 `FunctionCall` schema。

> **所以实际上在 A2UI 场景，模型拥有的是一张“能力菜单”，它知道有哪些函数，知道函数需要什么参数，也知道返回值是什么，但真正的 Dart 实现还是在 App 手里，具体实现模型不关心**。

**这也是 A2UI 一直强调的安全模型，Agent 发送的是 declarative data，客户端只接受 Catalog 里预先批准的组件和函数，不需要执行 Agent 临时生成的任意代码**。

那一次 `calculateCost` 到底经历了什么？比如开发者会定义一个继承 `SynchronousClientFunction` 的 Dart 类，它最重要的几部分可以简化成下面这样：

```dart
class CalculateCostFunction extends SynchronousClientFunction {
  @override
  String get name => 'calculateCost';

  @override
  String get description =>
      'Calculate ingredient cost from id and quantity';

  @override
  ClientFunctionReturnType get returnType =>
      ClientFunctionReturnType.string;

  @override
  Schema get argumentSchema => S.object(
    properties: {
      'ingredient_id': S.string(),
      'quantity': S.number(),
    },
    required: ['ingredient_id', 'quantity'],
  );

  @override
  Object? executeSync(JsonMap args, ExecutionContext context) {
    // 本地 Dart 逻辑
  }
}
```

这里其实同时存在两份东西：

- 一份是给模型看的 ABI，也就是 `name`、`description`、参数 Schema 和 `returnType`

- 一份才是机器真正执行的 Dart 实现 `executeSync()`

这两个部分被绑定在一个 `ClientFunction` 上，所以 Agent 可以理解能力，不过接触不到具体实现：

> `argumentSchema` 用来做参数验证和为 LLM 生成 function 定义，`description` 用来告诉模型函数用途，真正执行走  `execute()`；的时候，`SynchronousClientFunction` 再提供一个更简单的 `executeSync()` 扩展点。

然后开发者就可以把函数注册到 Catalog，到这里 `calculateCost` 就成为这个客户端允许 Agent 使用的 UI 能力之一 ：

```dart
final catalog = Catalog(
  [
    ingredientLineCatalogItem,
    simpleCardCatalogItem,
  ],
  functions: [
    CalculateCostFunction(),
  ],
);
```

另外，实际上 `PromptBuilder` 在建立会话时会读取 Catalog，把 function 的名字、描述和 schema 加进提供给 Gemini 的系统提示，让模型知道自己可以调用它，比如用户问：

> “做这份菜单需要 3 罐 black beans，大概多少钱？”

Agent 实际不需要返回  `$2.97`， 它可以生成类似下面这样的 A2UI：

```json
{
  "id": "cost",
  "component": "Text",
  "text": {
    "call": "calculateCost",
    "args": {
      "ingredient_id": "black_beans",
      "quantity": 3
    },
    "returnType": "string"
  }
}
```

这里最关键的细节是：**模型生成的是 computation description** ，它说的是

> 这个 `Text.text` 的值，需要调用 `calculateCost`，参数是 `black_beans` 和 `3`。

也就是真正的结果不会出现在模型输出里，A2UI 到达 Flutter 后，renderer 根据当前 Catalog 找到  `calculateCost`，执行客户端 Dart，实现返回类似 `$2.97` 的字符串，最后这个结果才成为 `Text` 的实际内容。

```dart
/// A client-side function that calculates the cost for an ingredient
/// directly on the device using local Dart logic.
class CalculateCostFunction extends SynchronousClientFunction {
  const CalculateCostFunction();

  // 1. The identifier referenced by the LLM in A2UI payloads.
  @override
  String get name => 'calculateCost';

// 2. Clear description provided to the LLM so it knows when
  // and why to use the function.
  @override
  String get description =>
      'Calculates the cost for a certain quantity of an ingredient. '
      'Returns a formatted dollar string (for example,  \$4.50).';

  // 3. The expected return type for the binding.
  @override
  ClientFunctionReturnType get returnType => ClientFunctionReturnType.string;

  // 4. JSON Schema defining required input arguments.
  @override
  Schema get argumentSchema => S.object(
    properties: {
      'ingredient_id': S.string(description: 'The ID of the ingredient.'),
      'quantity': S.number(description: 'The quantity of the ingredient.'),
    },
    required: ['ingredient_id', 'quantity'],
  );

  // 5. Synchronous Dart execution logic on the client
  @override
  Object? executeSync(JsonMap args, ExecutionContext context) {
    final ingredientId = args['ingredient_id'].toString();
    final quantity = num.tryParse(args['quantity'].toString())?.toDouble();

    if (quantity == null || quantity < 1) {
      return '\$0.00';
    }

    // Call the local cost service to fetch price and format as currency
    final cost = CostService().fetchPrice(ingredientId, quantity);
    return '\$${cost.toStringAsFixed(2)}';
  }
}

```

所以这里的  `CostService().fetchPrice()`  是本地逻辑的一部分，这也是 A2UI 协议的意义：

| | A2UI Client Function | LLM Tool |
|---|---|---|
| 谁执行 | Renderer / Flutter App | Agent / Tool Runtime |
| 什么时候执行 | Agent 已经生成 A2UI 之后 | Agent 推理过程中 |
| 常见用途 | UI 校验、格式化、动态属性、本地行为 | 查数据库、调用 API、搜索、后端业务 |
| 能否访问当前 UI 状态 | 可以通过 `ExecutionContext` / DataContext | 通常通过 Agent 自己提供的上下文 |
| 是否需要再次让 LLM 推理 | 一般不需要 | 通常属于 Agent loop 的一部分 |

A2UI 官方就是这样划分的：

- Client Function 的执行者是 A2UI Renderer，主要面向 validation、visible toggles、formatting 等 UI logic
- LLM Tool 更适合 reasoning、data fetching 和 backend actions

所以这两个其实是两个不同的执行平面，**Tool Calling 是 Agent 的能力调用机制，Client Function 是生成出来的 UI 自己的本地运行时能力。**

另外还有一个问题，**Client Function 其实和 A2UI 的响应式 DataModel 是连在一起的**，至少目前从  `genui`  的实现看，Client Function 还包括 reactive computation。

A2UI 的 DataModel 本来就是一个客户端 observable state store ，比如：

> 一个 Slider 绑定 `/quantity`，用户从 2 拖到 3，这个变化首先发生在本地 DataModel，正常情况下不会因为一次拖动就请求 Agent。

而 Flutter 的函数执行链正好建立在这套 DataContext 上：

- 当前  `ExecutionContext` 可以读取值、解析相对路径、订阅 DataModel、获得其他 Client Function
-  `resolve()` 返回的是  `Stream<Object?>` 
-  `ExpressionParser.evaluateFunctionCall()` 同样返回 `Stream<Object?>`
- Flutter 自己的 `BoundValue` 组件负责绑定 DataContext，并在绑定值变化时 rebuild

也就是用户把数量 Slider 从 2 改成 3，DataModel 会更新，然后依赖这个值的函数表达式重新求值，新的价格在客户端生成，相应 Widget rebuild，这里整个过程里 Gemini 可以完全不参与。

**也就是只需要最初的计算关系是 Agent 生成 UI 时声明，但是实际后续使用和执行，是不需要 Agent 再参与**。

目前 A2UI v0.9 的 Basic Catalog 就已经提供了一组 Client Functions，包括 `required`、`regex`、`length`、`numeric`、`email`、`formatString`、`formatNumber`、`formatCurrency`、`formatDate` 和 `pluralize`，协议说这些 Functions 可以用于 validation、data transformation 和 dynamic property binding。

比如 AI 动态生成一个邮编输入框，可以同时生成支持校验的能力：

```json
{
  "condition": {
    "call": "regex",
    "args": {
      "value": {"path": "/form/zip"},
      "pattern": "^[0-9]{5}$"
    }
  },
  "message": "Invalid ZIP code"
}
```

所以在整体实现上，AI 不负责创造新的 Widget 类型，它从已有 Widget Catalog 里组合，同时 AI 也不负责创造新的可执行逻辑，它从已有 Function Catalog 里组合。

所以 A2UI 在这里就有了明确的边界：**AI 可以动态编排，代码还是静态审核和发布的，等于实际上并没有给你提供热更新，惊不惊喜，意不意外**？

> 当然，你要是丧心病狂把 Catalog 拓展成超大业务数据库，那谷歌也只能服气。



