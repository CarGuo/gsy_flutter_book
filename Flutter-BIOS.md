# Flutter iOS  OC 混编 Swift 遭遇动态库和静态库问题填坑


Flutter 在 iOS 上的编译问题相信大家多多少少遇到过，不知道大家在搜索这方便的问题时，得到的答案是不是*让你 clean 或者 install 多几次*，很多时候就算解决完问题，也是处于薛定谔的状态，所以**本篇也简单记录下 Flutter 开发中，OC 混编 Swift 遭遇动态库和静态库的问题**，希望对“蒙圈”中的你有点帮助。

![image-20220422091858815](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIOS/image1)



首先，当我在一个 OC 项目里接入一个 Swift 插件，可能会遇到什么问题？

如下图所示，**如果你是一个比较老的 Flutter 项目，那可能会出现 swift 插件出现 not found 的问题**。

![image-20220422093205569](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIOS/image2)

针对这个问题，一般都是建议在 Podfile 文件下添加  `use_frameworks!` ，有时候还会建议添加 `use_modular_headers!`  ，那这两个标记位的作用是什么？

```shell
target 'Runner' do
  use_frameworks! 
  use_modular_headers!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

> 我们知道 Podfile 的作用是处理 CocoaPads ，而 `use_frameworks!`告诉 CocoaPods 你想使用 Framework 而不是静态库，而默认由于 Swift 不支持静态库，因此有一开始 Swift 必须使用 Framework 的限制。

静态库和 Framework  的区别在于：

- *.a 的静态库类似于编译好的机械代码，源代码和库代码都被整合到单个可执行文件中，所以它会和设备架构绑定，并且不包含资源文件比如图片；
- Framework   支持将动态库、头文件和资源文件封装到一起的一种格式，其中动态库的简单理解是：不会像静态库一样被整合到一起，而是在运行或者运行时动态链接；

另外一个配置 `use_modular_headers!` ，它主要是将 pods 转为 Modular，因为 Modular 是可以直接在 Swift中 import ，所以不需要再经过 bridging-header 的桥接。

> 但是开启 `use_modular_headers!` 之后，会使用更严格的 header 搜索路径，开启后 pod 会启用更严格的搜索路径和生成模块映射，历史项目可能会出现重复引用等问题，因为在一些老项目里 CocoaPods 是利用Header Search Paths 来完成引入编译，当然使用   `use_modular_headers!`可以提高加载性能和减少体积。

继续回到问题上，我们在添加完 `use_frameworks!` 之后，有一定几率中奖各种  *Undefined symbol* 的错误问题，这时候不要慌，因为这是 Swfit 里有静态库导致。

![image-20220422103410759](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIOS/image3)

很明显 Swift 不支持静态库的行为不科学，所以从 Xcode 9 开始 Swift  就开始支持静态库，而  CocoaPods 1.9.0 开始，引入了 **`use_frameworks! :linkage => :static`**   来生支持有静态库和 Framework 的情况。

所以修改 use_frameworks 配置，增加 static 之后可以看到  *Undefined symbol*  的错误都消失了，但是运行之后，可能会喜提新的问题： *non-modular header* 。

![image-20220422104501881](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIOS/image4)

如果你去搜索答案，有很多答案会告诉你如下图所示，通过  `Allow Non-modular Includes in Framework Modules` 设置为 `true` 就可以解决问题，**但是很明显这并不是正解，它更多适用于临时的紧急状体下**。

![image-20220422105705987](http://img.cdn.guoshuyu.cn/20220627_Flutter-BIOS/image5)

当然，你也可以在出现问题的插件的 `.podspec` 下单独配置 ALLOW ，效果相同，更轻量级，但是这也只是临时解决方案。

```shell
s.user_target_xcconfig = { 'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES' }
```

为什么说这种方式不靠谱，因为你不知道官方会什么时候删除这种允许，当然这个问题网友提供的解决方案其实千奇百怪：

- 如果是 App 使用  **dynamic framework** 里的 **header**  导致错误，可以使用 `#import "MyFile.h"` 而不是 `#import <MyFramework/MyFile.h>` ；
- 将`#import`语句移到 `.m`（而不是将其放在`.h`头文件中）， 这样它就不会有包含 *non-modular header*  的问题，例如： https://github.com/AFNetworking/AFNetworking/pull/2206/files ；
- 重命名 header ，不要让 header 和模块名一样，变为 `#import <FrameworkName/Header.h>`
- 在 build setting 配置 OTHER_SWIFT_FLAGS    -Xcc -Wno-error=non-modular-include-in-framework-module 解决 Swift 的问题；

**有可能它们都能解决你的问题，但是为什么呢？下次遇到这些问题要选哪个解决？**

回归到我们的问题，其实我的问题关键是：**不能在 Framework Module 中使用非 Modular 的 Header**，也就问题是在 Framework Module 中加载了非当前 Module 的头文件，而由于 Header 是对外 public ，比如配置到了 `s.public_header_files` ，就会导致非 Modular 的 Header 也出现对外暴露的风险，所以我这边的解放方式也很简单：

**在 `s.public_header_files`  里只放需要公开的 *Plugin.h ，使用了非  Modular 的 Header 不对外 public，从而符合规范达到编译成功**。

所以这里面的核心是：不要在  Umbrella Header File 中引用不需要对外公开的 OC 头文件去作为子 module ，这也解释了为什么上面讲出问题的  `#import`语句移到 `.m` 就解决问题的逻辑。

> 例如有时候你还会引用一些系统的 C Module ，其实在 Framework  Module 化过程中也会有类似的问题。

所以知道了为什么和怎么解决，就不会只是粗暴通过 LLVM 的配置来设置 `Allow Non-modular Includes in Framework Modules`  去解决薛定谔的问题。

另外你可能还有用到的，比如模拟器编译提示 unsupport arm64、 BITCODE 失败，SWIFT_VERSION 版本冲突等等：

```shell
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
        # building for iOS Simulator, but linking in an object file built for iOS, for architecture ‘arm64’
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
        #不支持 BITCODE
        config.build_settings['ENABLE_BITCODE'] = 'NO'
        #解决swift模块问题
        config.build_settings['SWIFT_VERSION'] = '5.0' 
    end
  end
end
```

当然，最后一句话：**珍爱头发，远离 Swift 混编**。