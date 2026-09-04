---
title: "聊个比较有意思的 Flutter Web 问题"
---

# 聊个比较有意思的 Flutter Web 问题

首先是，前段时间 Flutter 和 Dart 的官网都选择离开 medium ，然后迁到了自己的域名下，你觉得是为什么？

![](https://img.cdn.guoshuyu.cn/ab3408ef6c178505bbd6b0e2ea6e4f40.jpg)

其实理由很简单，之前的 Flutter Web 不支持 SEO ，所以 Flutter 官方不得不一直把文章发布在 medium ，但是现在不一样了，今年开始社区搞了一个项目叫  **Jaspr** ，这是是一个第三方的 Dart Web 框架，记住不是 Flutter，然后  `dart.dev`、 `flutter.dev` 和 `docs.flutter.dev`  这些官方网站，现在都已经全部迁移到 Jaspr。

Jaspr 的特别在于，这是一个传统的 Dart Web 框架，支持客户端渲染、服务器端渲染和静态网站生成，它有点古法回归的味道，其实就是可以用 Flutter 写传统 DOM Web ，因为 Flutter 官方现在都是 WASM 了，所以基于  HTML 和 CSS 的场景就变成  Jaspr 承担了，当然只是写法一样，代码不会完全一模一样 ：

```dart
class FeatureCard extends StatelessComponent {
const FeatureCard({
    required this.title,
    required this.description,
    super.key,
  });

finalString title;
finalString description;

@override
  Component build(BuildContext context) {
    return div(classes: 'feature-card', [
      h3([.text(title)]),
      p([.text(description)]),
    ]);
  }
}
```

官方之所以迁移到 Jaspr ，**主要是因为 Jaspr 内置的部分渲染支持将每个页面预渲染为静态 HTML，然后只为需要的组件附加客户端逻辑，而因为 Flutter  官网的大部分内容都是静态的，只需要少量的交互功能，这样可以实现提速和针对 SEO 的场景优化**。

> 最最重要是，**Jaspr Content 支持 Markdown 驱动型网站**， 

所以官方能迁回自己的域名托管 blog ，考的是社区靠谱的支持。

**然后就是现在 Flutter Web 的情况，在最新版发布后其实已经有了一些变化，比如支持了 `flutter build web --release --wasm --enable-wasm-deferred-loading` ，可以对 wasm 进行拆包，也就是加载可以加快了**。

然后目前基于 `dart2wasm`  加速器和多线程渲染 `skwasm` 的支持，WebAssembly 在 Flutter Web 上的表现确实已经可圈可点了：

![](https://img.cdn.guoshuyu.cn/f8a18640-603f-4bc7-9c2e-5c0a9fc5f97f.png)

核心表现主要是在性能上，比如：

- 在运行大量组件的情况下的 diff 更新，Wasm 帧时间保持流畅的 60 FPS 输出
- Skwasm 将光栅化操作发送到专用的 Web Worker，支持保证了浏览器线程的交互流
- 对比以前包更小了，还可以拆包

但是这里有个最重要的是，**Flutter 定位一直都不是主打和传统 H5 竞争，它的目标是让 Flutter 的 canvas 可以无缝支持到浏览器，同时深耕 wasm 场景**。

不过目前可惜的是，Flutter 官方还是没有支持 webgpu ，社区版本的 webgpu 倒是有，但是官方对这个一直闭口不谈，确实有点可惜了。

![](https://img.cdn.guoshuyu.cn/76ba3c76-3a56-401a-beea-c2f9ea01d17d.png)

反而 Flutter Web 不完全解决 SEO 和 Ctrl + F 的问题，就只能被局部应用，不过实际上官方对 Web 甚至比对 PC 上心。