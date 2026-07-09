# Flutter Patchwork，不用 Fork 改依赖包源码的第三方工具

其实这个在 JS 生态很常见，类似 Node.js 生态的  `patch-package`  ，[*Patchwork*](https://github.com/medz/patchwork) 是一个专门为 **Dart/Flutter 项目设计的依赖包补丁管理工具**。

其实功能很简单：

> 当你需要修改某个第三方 pub 包的源码时（比如修复 bug、临时添加功能），不用 fork 整个仓库，只需要通过 Patchwork 生成一个 `.patch` 文件，保存在项目里就行了。

也就是你遇到问题时，可以直接先把本地问题修复能跑了，然后同步给团队，最后有时间了再把 patch 变成 PR 提交给包的维护人员就行了。

| 命令                                       | 作用                                          |
| ------------------------------------------ | --------------------------------------------- |
| `dart run patchwork patch <包名>`          | 开始一个可编辑的 patch 会话，复制包源码到本地 |
| `dart run patchwork patch --commit <包名>` | 把你的编辑提交为 `.patch` 文件                |
| `dart run patchwork apply`                 | 把所有已提交的 patch 应用到项目               |
| `dart run patchwork status`                | 查看 patch 和 override 状态                   |
| `dart run patchwork doctor`                | 检查本地环境是否就绪（比如是否安装了 git）    |

所以这个 patch 文件是可以提交到 git 的，所有人运行 `patchwork apply` 就可以覆盖使用，**同时保持 `pubspec.yaml` 不被污染，原始第三方本地依赖也不会被污染** ，页可以在官方发版前先用 patch 临时解决。

目前整个工作流主要分为**三个阶段**，第一个是通过  `patchwork patch <包名>`   创建会话：

```sh
dart run patchwork patch greeter
```

这个命令主要做：

- 读取 `package_config.json`（pub 解析结果），找到目标包的实际路径

- 把包源码复制两份到 `.dart_tool/patchwork/`：

- **baseline** （基准副本）：`baseline/pub/greeter@0.1.0/`  永远不变
- **edit**（可编辑副本）：`edit/pub/greeter@0.1.0/`  我们可以在这里改代码

然后 `sessions/pub/greeter@0.1.0.json`  会写入会话元数据（记录路径、版本等）：

```
.dart_tool/patchwork/
  baseline/pub/greeter@0.1.0/   //原始快照
  edit/pub/greeter@0.1.0/        //用户编辑这里
  sessions/pub/greeter@0.1.0.json
```

然后就是第 2 阶段的 `patchwork patch --commit <包名>`  生成 patch 文件，其实就是生成 diff  信息，通过调用系统 `git diff --no-index` 对  `baseline/` 和 `edit/` 两个目录做 diff，生成标准 unified diff 格式的文本：

```dart
final arguments = [
  'diff', '--no-ext-diff', '--no-color',
  '--src-prefix=a/', '--dst-prefix=b/',
  '--no-index',
  baselinePath,
  editPath,
];
```

然后就是patch 验证，在临时目录里把 baseline 再复制一份，用 `git apply --check` 验证生成的 patch 能不能正常工作。

最后第三阶段是 `patchwork apply`，大概流程是：

- 读取 `patchwork.lock`，获取所有 patch 条目

- 然后做 hash 检查，对比 store 目录中的 `.patchwork-patch-hash` 标记文件，判断已 apply 的副本是否还是最新的，避免重复 apply

- 如果需要重建：

  - 在临时目录 `tmp/` 复制原始包源码

  - 调用 `git apply --binary` 把 patch 文件打入临时副本

  - 写入 hash 标记文件

  - 原子替换 `store/pub/greeter@0.1.0_patch_hash=xxxx/` 目录

- 最后写入 `pubspec_overrides.yaml` ：

```yaml
# 自动生成，不要手动修改
dependency_overrides:
  greeter:
    path: .dart_tool/patchwork/store/pub/greeter@0.1.0_patch_hash=xxxx
```

> 之后你只需要运行 `pub get`，pub 就会通过 path override 使用打了 patch 的本地副本，所以其实整个实现并不复杂，但是思路上还是挺不错的。

至少**不修改 `pubspec.yaml`，只是入侵了  `pubspec_overrides.yaml`，**提交到 git 的只有两样东西`patchwork.lock`  和 `patches/pub/*.patch` ，**`.dart_tool/patchwork/` 的全是可重现的生成模块**，失败也可以自动回滚（commit 阶段有文件快照机制）。

在一些临时修复，又需要团队协作和快速打包的场景还是挺合适的，毕竟过去真有人直接修改了本地的 package ，把 bug 修了之后就提交的卧龙，这个 Patchwork 还是有点用的。

# 链接

https://github.com/medz/patchwork