# Flutter 多版本管理工具 Puro ，它和 FVM 有什么区别？

你平常是如何管理本地的 Flutter 版本？是每次都是通过 `git checkout` 之后 `flutter doctor` 这种低效率的方式来切换 Flutter SDK 吗？还是使用 FVM 来进行版本管理？而今天我们要聊的是另一个 Flutter 多版本管理工具 Puro：

![](https://img.cdn.guoshuyu.cn/image-20250609172020281.png)

# Puro
Puro 一款管理 Flutter 版本的工具，支持同时使用不同版本的 Flutter ，并支持全局或者按项目来使用，同时还提供比 FVM 更快的性能支持，其核心设计目标在于显著提升 Flutter 版本的安装和切换速度:

```SH
# Create a new environment "foo" with the latest stable release
puro create foo stable

# Create a new environment "bar" with with Flutter 3.13.6
puro create bar 3.13.6

# Switch "bar" to a specific Flutter version
puro upgrade bar 3.10.6

# List available environments
puro ls

# List available Flutter releases
puro releases

# Switch the current project to use "foo"
puro use foo

# Switch the global default to "bar"
puro use -g bar

# Remove puro configuration from the current project
puro clean

# Delete the "foo" environment
puro rm foo

# Run flutter commands in a specific environment
puro -e foo flutter ...
puro -e foo dart ...
puro -e foo pub ...
```

Puro 的核心优化理念在于竭力避免冗余数据的下载和存储，例如：

- **全局 Git 历史缓存与对象去重** ：Puro 实现了一种与 GitLab 的对象去重（object deduplication）技术相类似的方法，当安装或切换不同 Flutter 版本时，Puro 不会为每个版本都下载和存储完整的 Git 历史记录，而是维护一个全局的 Git 对象缓存，如果不同 Flutter 版本之间共享相同的 Git 对象，这些对象在全局缓存中只存储一份![](https://img.cdn.guoshuyu.cn/image-20250609172543383.png)

- **全局引擎版本缓存**：Puro 会对 Flutter 引擎的不同版本进行全局缓存，比如 Flutter 的不同 SDK 版本有时会使用完全相同的预编译引擎，在这种情况下，Puro 不会为每个 SDK 版本重复下载或存储相同的引擎文件，取而代之的是，它会利用操作系统的符号链接（Symlinks ）功能，让多个 Flutter 环境指向全局缓存中同一份引擎文件，这在同一稳定渠道下的不同补丁版本下作用明显

> 所以，Puro 的架构决策主要为基于 Git 历史（通过对象去重）和引擎二进制文件（通过 Symlinks ）实现全局共享缓存

**这里的核心之一就是对象去重**，在实现上 Puro 会先创建一个 Flutter 的裸仓库，只包含 `.git` 目录里的所有内容（ Git 的对象数据库、引用等），但没有实际 checkout 出工作文件，所以在创建一个新的 Flutter 环境时，可以快速从本地签出一个目录。

同时新创建的环境里的 `.git` 并不是独立的，Puro 会在其内部配置一个名为 `objects/info/alternates` 的文件，这个 `alternates` 文件里写着一个路径，指向那个中央裸仓库的对象数据库，当 Git 在环境中需要寻找一个对象（比如一个文件或一次提交）时，它会先在自己本地的 `objects` 目录里找，如果找不到，它会根据 `alternates` 文件的指示，去那个共享的“总仓库”里寻找：

![](https://img.cdn.guoshuyu.cn/image-20250610104020301.png)

> 通过这种方式，无论你创建多少个 Flutter 环境，所有环境历史上共同的 Git 对象（代码文件、目录树、提交记录等）在你的磁盘上永远只存储一份(中央裸仓库)，每个环境只在本地存储自己独有的、或者新产生的对象。

所以，简单理解，下载一个新版本，往往意味着仅下载 Git 对象的增量部分，并在引擎兼容时链接到已有的引擎，这就是 Puro 的实现目的：

![](https://img.cdn.guoshuyu.cn/image-20250609173107573.png)![](https://img.cdn.guoshuyu.cn/image-20250609173114715.png)

另外，Puro 还会使用并行下载与 Symlinks  来进行加速：

- **并行 Git 克隆和引擎下载**：和传统的 Flutter 安装流程，先完整克隆框架代码，然后才由 `flutter doctor` 工具根据需要触发引擎下载不同，在安装一个新的 Flutter 版本时，Puro 会同时启动 Flutter 框架代码（即 Git 仓库）的克隆过程和对应引擎二进制文件的下载 。
- **符号链接（Symlinks ）** ： Symlinks  不仅被用于共享引擎版本，Puro 还利用它来构建和管理不同的 Flutter “环境”，例如在 Puro 的管理目录下，会有一个如 `~/.puro/envs/default`  的 Symlinks  ，它指向当前被用户设为全局默认的 Flutter 环境 ，而当用户切换 Flutter 版本或环境时，Puro 本质上是更新这些符号链接的指向，由于修改符号链接是一个非常轻量级的操作系统层面操作，所以保证了切换速度

所以，在 Puro 里，主要是基于“环境”(Environments) 的概念来组织和管理不同的 Flutter 版本，比如每个“环境”都可以关联到一个特定的 Flutter SDK ，例如：

- 版本号 `3.32.2`
- 发布渠道（如 `stable`, `beta`, `master`）
- 具体的 Git 提交哈希 (commit hash)
- 甚至是一个自定义的 Flutter 代码仓库分支 (fork) 

![](https://img.cdn.guoshuyu.cn/image-20250610094014014.png)![](https://img.cdn.guoshuyu.cn/image-20250610094054419.png)

如果你不想全局切换，那么不是用 `-g` ，就只切换当前项目的环境，这个命令会创建一个 `.puro.json`，这个文件告诉 Puro 要使用哪个环境，并且会自动被 git ignored：

![](https://img.cdn.guoshuyu.cn/image-20250610094118745.png)

> Puro 会检测 VSCode 和 Android Studio （IntelliJ） 的配置文件，并调整它们使用正确版本的 Dart 和 Flutter，也可以使用 `--intellij --vscode` 或 `--no-intellij --no-vscode` 手动控制对应行为

当用户通过 Puro 切换 Flutter 环境后，Puro 会尝试更新相应 IDE 的项目设置，使其 Flutter SDK 路径指向当前 Puro 环境所管理的 SDK，当然，你甚至还可以使用 `-e <name>`  来忽略全局和项目默认值：

![](https://img.cdn.guoshuyu.cn/image-20250610094345813.png)

或者使用 `--fork` 选项需要的 fork 分支：

![](https://img.cdn.guoshuyu.cn/image-20250610094445555.png)

甚至还有 `puro gc` 命令手动删除未使用的缓存：

![](https://img.cdn.guoshuyu.cn/image-20250610094535082.png)

所以，Puro 在自身数据目录结果上，会将其所有相关文件，包括各种缓存（Git 对象缓存、引擎版本缓存）、克隆的 Git 仓库、已构建的引擎、用户配置文件等，都集中存放在用户主目录下的一个名为 `.puro` 的隐藏文件夹，而在 `.puro` 目录内部，通常会有一个 `envs` 子目录，用于存放所有已创建的 Puro 环境，同时还有一个名为 `default` 的符号链接用于指向用户当前设置的全局默认环境。

Puro 的设计，就是为了更少的本地占用和更快的操作结果。

# 对比 FVM

对比 FVM，FVM 的核心机制围绕着为每个需要管理的 Flutter SDK 版本在本地创建一个独立的缓存副本，并通过项目内的配置文件来指定所使用的版本，也就是：

> FVM 会为每个通过它安装的 Flutter SDK 版本在本地缓存中保留一个完整的、独立的副本

另外，FVM 通过在项目根目录下创建一个名为 `.fvmrc` 的配置文件和 `.fvm` 目录，从而实现项目级的 Flutter SDK 版本固定 ：

- `.fvmrc` 文件通常包含一个 `flutter` 字段，用于指定项目应使用的 Flutter SDK 版本号（比如 `"3.19.1"`）或发布渠道名称（如 `"stable"`），同时 `.fvmrc` 还支持定义不同的 "flavors"，并为每个 flavor 指定不同的 Flutter 版本![](https://img.cdn.guoshuyu.cn/image-20250610101044316.png)
- `.fvm` 目录中最重要的是一个名为 `flutter_sdk` 的符号链接，会指向 FVM 全局缓存中该项目所指定的 Flutter SDK 版本的实际存储位置 ，另外`.fvm/flutter_sdk` 这个路径会作为其 Flutter SDK 的路径，从而确保 IDE 使用的是由 FVM 管理的正确版本

所以，从设计上可以看出来，**FVM 的设计优先考虑的是明确性和项目级别的隔离**，资源优化和速度并不是首要考虑目标，甚至`.fvmrc` 文件还是可提交 Git 跟踪的内容，用来规定项目所使用的 Flutter 版本和团队协同约定。

> 所以，也就出现了使用 FVM 的整体占用空间也就大了，因为都是完整副本，基本存储在 `.fvm/versions/` 目录下。

# 最后

所以，从简单的概念对比上，可以看出来 Puro 的优势在于更快的安装和切换，还有更小的本地占用，而 FVM 则胜在明确性和项目级别的隔离，从实现理解上成本更低，出现问题的概率也更低，同时 FVM 的共享 `.fvmrc`在团队协作和 CI 环境中会更占据优势。

但是 Puro 对于个人开发者而言，特别是网络环境容易受限和 Mac 硬盘拮据的开发者来说，确实也是不错的选择。

所以你会选择 Puro 还是 FVM ？又或者，你只用最基本的 git checkout ？

# 参考链接

- http://github.com/pingbird/puro