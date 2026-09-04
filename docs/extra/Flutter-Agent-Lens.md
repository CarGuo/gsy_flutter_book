---
title: "flutter_agent_lens 用 MCP 服务，将 Flutter DevTools 暴露给 AI"
---

# flutter_agent_lens 用 MCP 服务，将 Flutter DevTools 暴露给 AI 

Flutter 的 DevTools 大家应该都用过吧？以前开发调试都会用到，但是 AI 时代来了之后，大家应该很少再打开它了吧？而这时候就有人想到了，为什么我不把 DevTool 也变成 AI 可见的东西呢？

所以这就是 `flutter_agent_lens ` 做的事情，它是一个用 **Dart 写的 MCP Server，专门为 AI 提供对正在运行的 Flutter App 的直接访问能力**。

> 其实就是把 **Dart VM Service 、 Flutter service extensions 、 MCP tool catalog** 包在了一起。

![](https://img.cdn.guoshuyu.cn/image-20260531175445609.png)

简单来说，其实就是  `flutter_agent_lens `  可以通过 **Dart VM Service** 实时连接到 debug/profile 模式下的 Flutter App，同时给基于 dart_mcp 提供服务能力：





![](https://img.cdn.guoshuyu.cn/image-20260531175658652.png)

目前主要支持的模块功能有：

| 文件                        | 职责                                        |
| --------------------------- | ------------------------------------------- |
| `widget_handlers.dart`      | Widget 树、布局约束、debug overlay 开关     |
| `memory_handlers.dart`      | 堆内存分析、内存泄漏审计、引用路径追踪      |
| `connection_handlers.dart`  | 连接/断开/自动发现 VM Service               |
| `performance_handlers.dart` | CPU profile、帧 jank 诊断、rebuild 计数     |
| `debugger_handlers.dart`    | 断点、调用栈、表达式求值                    |
| `bundle_handlers.dart`      | 包大小分析（读本地 code-size-details.json） |
| `network_handlers.dart`     | HTTP 请求记录                               |
| `deeplink_handlers.dart`    | App Links/Universal Links 校验              |
| `logging_handlers.dart`     | 控制台日志捕获                              |

而总结起来，这个项目提供主要提供了 5 大类 30+ 个 tool call 支持：

-  连接与发现
  - `connect_to_app` / `autodiscover_app` / `list_running_apps` / `disconnect` / `get_app_info`

- 性能分析

  - `diagnose_jank`  ： 检测超过 16.6ms 的掉帧

  - `get_cpu_profile`  ：CPU 采样热点

  - `get_widget_rebuild_counts` ：  Widget 重建频率统计

  - `hot_reload` ： 触发热重载

- 布局检查

  - `inspect_layout_constraints`  ： Widget 约束/尺寸详情

  - `toggle_layout_guidelines` / `toggle_repaint_rainbow` / `toggle_slow_animations` / `toggle_oversized_images` / `toggle_baselines` / `toggle_widget_selection`

- 内存与调试

  - `audit_class_memory_leak` ： 验证 disposed 对象是否泄漏

  - `diff_heap_allocations` ：前后堆快照 diff

  - `get_object_referrers` ： 追踪对象引用链

  - `eval_expression` ： 在运行时求值 Dart 表达式

  - `add_breakpoint` / `remove_breakpoint` / `get_call_stack` / `set_exception_pause_mode`

- 其他

  - `analyze_bundle_size`  ：解析 `code-size-details.json`

  - `get_network_profile` ： HTTP 请求历史

  - `trigger_scroll_gesture` ： 驱动 ScrollController

  - `validate_deep_links` ： Android App Links / iOS Universal Links 验证

**项目依赖官方 vm_service 包，其实就是对 DevTools 现在功能的打包**，核心数据获取走和 Flutter DevTools 一样的通道，同时支持同时返回 Markdown + JSON，AI 可以自由选择解析方式，比如：

- 调用的是 Flutter Inspector 的  `ext.flutter.inspector.trackRebuildDirtyWidgets` 和 `widgetLocationIdMap`，监听  `Flutter.RebuiltWidgets` extension event，然后把 location id 映射到 widget 名称和源码位置，**采样 rebuild 事件并整理成 Agent 可读报告**
- **粗粒度 jank 报告** ，`diagnose_jank` 的实现是设置 VM Timeline flags，清空 timeline，等待几秒，再读 `getVMTimeline()`，从 traceEvents 里找 `GPURasterizer::Draw` 或 `Animator::BeginFrame`，duration 超过 16.6ms 就算 janky frame，不是完整的 Flutter frame pipeline 归因
- 其他比如 CPU Profile、Memory / leak、Network Profile 等也可以给 AI 提供性能相关判断信息

**整体来说，这就是一个在开发阶段让 AI 助手自主诊断性能、内存、布局问题，替代手动打开 DevTools 的步骤工具**。

当然它不一定完全准确，但是这个思路还是挺不错的，因为现在我是真的不想去打开 DevTools，而在此之前，让 AI 直接访问  Dart VM Service / Service Extensions 调的效果一致不是很稳定，至少 AI 每次的 tool call 不是稳定的，而  `flutter_agent_lens `  真实补全了这个问题。





https://github.com/dhruvanbhalara/flutter_agent_lens