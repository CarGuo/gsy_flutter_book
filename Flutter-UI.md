# 注意，暂时不要升级 MacOS ，Flutter/RN 等构建 ipa 可能会因 「ITMS-90048」This bundle is invalid 被拒绝

近期，不少使用构建 ipa 提交 App Store 的用户遇到 「ITMS-90048」This bundle is invalid 而拒绝的问题，这个 错误的核心原因是在提交给 App Store Connect 的归档文件 (`.xcarchive`) 里，包含了一个不允许存在的隐藏文件  `._Symbols` ：

![](http://img.cdn.guoshuyu.cn/20250406_UI/image1.png)

而用户在 ipa 存档里，确实也可以看到 `.Symbols`  这个隐藏文件的存在，可以看到这个目录是一个空文件夹：

![](http://img.cdn.guoshuyu.cn/20250406_UI/image2.png)

这个问题目前在 [Flutter#166367](https://github.com/flutter/flutter/issues/166367)  、[RN#50447 ](https://github.com/facebook/react-native/issues/50447) 等平台都有相关 issue ，而出现这个的原因，主要在于这些平台都是从脚本构建出一个 ipa 包进行提交，而如果原生平台，**一般更习惯在 Xcode 里通过 `Prodict > Archive`  这种方式来提交，目前这种方式并不会有这个问题**。

> 所以如果你遇到这个问题，也可以先实现 `fluter build ios` ，然后通过  `Prodict > Archive`  这种方式提交来绕靠问题。

目前这个问题推测来自新的 macOS 15.4 ，因为对于 macOS （尤其是  APFS 文件系统）在处理文件时，会为文件创建以  `._`  开头的隐藏文件，这些文件用于存储 Finder 信息、资源 fork 或其他元数据等。

而在 iOS 构建过程中，需要生成 `Symbols` 文件目录，用于存储调试符号 (dSYMs) 等信息，所以推测问题可能出在构建或归档过程中，系统对  `Symbols`  文件进行了某种操作（如 rsync），导致 macOS 生成了对应的  `._Symbols`  元数据文件，并且这个隐藏文件被错误地打包进了 `.xcarchive` 文件。

目前看来，macOS 15.4 确实包括对内置 `rsync` 的重大修订：

![image-20250406133119461](http://img.cdn.guoshuyu.cn/20250406_UI/image3.png)

另外，**用户在遇到该问题后，也尝试降级到 Xcode 和 Command Line Tools ，但是问题依然存在；也有用户未升级 Xcode ，但升级到  macOS 15.4，也同样触发该问题，所以问题看起来主要是  macOS 15.4 导致**。

而如果已经是 macOS 15.4 的用户，最简单的做法就是使用 Xcode 的  `Prodict > Archive`  ，或者手动删除该文件：

```
unzip -q app.ipa -d x
rm -rf app.ipa x/._Symbols
cd x
zip -rq ../app.ipa .
cd ..
rm -rf x
```

或者 `flutter build ipa --release ` 之后，执行一个 `./cleanup.sh `  ：

```sh
IPA_PATH="build/ios/ipa/your_app_name.ipa"
# export IPA_PATH="$(find "build/ios/ipa" -name '*.ipa' -type f -print -quit)"

if [ -f "$IPA_PATH" ]; then
  echo "Checking for unwanted files like ._Symbols in $IPA_PATH"
  unzip -l "$IPA_PATH" | grep ._Symbols && zip -d "$IPA_PATH" ._Symbols/ || echo "No ._Symbols found"
else
  echo "IPA not found at $IPA_PATH"
fi
```

目前看来问题并不在框架端，所以非必要还是暂时不要升级  macOS 15.4 ，避免不必要的问题。





# 参考资料

- https://github.com/flutter/flutter/issues/166367
- https://github.com/facebook/react-native/issues/50447
- https://developer.apple.com/forums/thread/776674?page=1#833095022























