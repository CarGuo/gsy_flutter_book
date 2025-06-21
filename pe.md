# Flutter 小技巧之：Flutter 3.32 的 Property Editor  生产力工具

快速介绍一下 Flutter Property Editor ，它需要 Flutter 3.32+ 才支持使用，属于 IDE 增强工具，可以直接在可视化界面查看和修改 Widget 属性：

![](https://img.cdn.guoshuyu.cn/image-20250521155530425.png)

**开发者可以快速发现和修改 Widget 的现有和可用的参数，不需要跳转到定义或手动编辑源代码**，如果配合 Flutter inspector 和热重载，修改后可以直接实时查看更改。

Property Editor 支持 VS Code 和 Android Studio/IntelliJ，你只需要在侧边栏找到下放这个图标，就可以打开对应面板，前提是需要 3.32+，不然你看到的会是如下所示 ：

![](https://img.cdn.guoshuyu.cn/image-20250521160018323.png)

而如果你是 3.32 +，那么打开应该是下面这样：

![](https://img.cdn.guoshuyu.cn/image-20250521162849950.png)

Flutter Property Editor 可以和 Flutter inspector 结合使用，然后在这两个工具中同时检查你的 Widget，比如：

- 首先在 IDE 中打开 Flutter inspector，然后：
  - 在 tree 中选择一个 Widget，然后点击某个 Widget
  - 或者在 inspector 启用 "Select Widget Mode" ，然后选择某个 Widget
- 然后再切 tab 回到 Flutter Property Editor 中修改选中的 Widget 属性

你还可以配合 hot reload ，如果喜欢自动保存，可以在 `.vscode/settings.json` 添加：

```json
"files.autoSave": "afterDelay",
"dart.flutterHotReloadOnSave": "all",
```

或者在 Android Studio   打开 `Settings > Tools > Actions on Save` 并选择 `Configure autosave options` ，然后配置 `Save files if the IDE is idle for X seconds`  ：

![](https://img.cdn.guoshuyu.cn/image-20250521160920660.png)

当然，默认 `Settings > Languages & Frameworks > Flutter`  下 `Perform hot reload on save` 是选中的：

![](https://img.cdn.guoshuyu.cn/image-20250521161107123.png)

在 Flutter Property Editor 中选择一个 Widget 时，它对应的文档会显示在顶部，开发者可以直接阅读 Widget 文档无需跳转：

![](https://img.cdn.guoshuyu.cn/property-editor-documentation.gif)

而对于 Flutter Property Editor  内的字段：

- **string、double 和 int 属性** ：这些由文本输入表示，只需在字段中输入新值即可，按 ••Tab•• 或 ••Enter•• 将编辑直接应用到源代码
- **boolean 和 enum 属性：** 这些由下拉菜单表示，单击下拉列表可查看可用选项
- **对象属性**（如`TextStyle`、`EdgeInsets`、`Color`）：目前不支持

![](https://img.cdn.guoshuyu.cn/image-20250521163115383.png)

另外，Flutter Property Editor 中的每个 property input 都附带了信息：

- **Type and name:** 构造函数参数的类型（例如  `StackFit`）和名称（例如 `fit`），将显示为每个输入字段的标签：![](https://img.cdn.guoshuyu.cn/image-20250521161657494.png)

- **Info tooltip** ⓘ ：将鼠标悬停在属性输入旁边的 info 图标上会显示工具提示：![](https://img.cdn.guoshuyu.cn/image-20250521161739599.png)

- **“Set” 和 “default” 标签：** 

  - 如果已在源代码中显式设置了该属性， 则 “set” 标签会显示在输入旁边，这意味着 Widget 构造函数调用中提供了相应的参数
  - 如果当前属性值与小组件中定义的默认参数值匹配， 则 “default” 标签将显示在输入旁边

  ![image-20250521161854806](https://img.cdn.guoshuyu.cn/image-20250521161854806.png)

最后，Flutter Property  Edit 还支持筛选：

- 只需在筛选栏中输入筛选以仅显示和输入匹配的属性，比如  “main” 将筛选到 `mainAxisAlignment`、`mainAxisSize`：![](C:\Users\Asher.Guo\AppData\Roaming\Typora\typora-user-images\image-20250521162158793.png)
- 你还可以仅显示 set 的属性，通过选打开选项：![](https://img.cdn.guoshuyu.cn/image-20250521162158793.png)
- 最后支持正则表达式切换（`*` )：![](https://img.cdn.guoshuyu.cn/image-20250521162237492.png)

简单来说，最终效果如下图所示，你可以字节选中一个 Widget ，然后对他的属性进行修改和配置，当然实际场景可能更多会和  Flutter inspector 一起使用，比如你通过 Flutter inspector 查看某些问题，然后需要修改对应参数时，就可以通过  Property  Editor 来完成：

![](https://img.cdn.guoshuyu.cn/ezgif-62b7a6ac556008.gif)

> 当然，Flutter inspector 和  Property  Editor 没有直接联动，你还是需要在侧边栏手动切换 tab 。

# 参考链接

- https://docs.flutter.dev/tools/property-editor