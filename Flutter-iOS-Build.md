
在以前的 [《 Android 和 iOS 打包提交审核指南》](https://juejin.cn/post/6844904042057957383) 里介绍了 Flutter 下打包 Android 和 iOS 的指南，不过这部分内容主要介绍的是如何在本地打包发布流程。

但事实上一般的产品发布流程，都会有专门的机器用于打包服务，**在统一干净的环境下进行打包更有利于发布的管理，避免各种本地环境差异问题**。

当然大多数时候可以直接使用第三方的 CI 服务，但是专门支持 Flutter 的第三方服务并不多，并且**自己动手还免费**，所以本篇主要介绍自己搭建独立打包服务的过程。


> 由于 Android 的命令打包服务比较简单，这里主要介绍配置搭建 iOS 下的 Flutter 打包和发布 CI ，**其实主要也是 iOS 的 CI** 。


## 一、参数支持

首先在 iOS 上很多的配置信息都是写在 `info.plist` 文件，所以一开始需要解决打包时支持动态修改 `info.plist`  的参数，这样有利于我们在输出不同环境的包配置，如：QA、Release、Dev 等等。

```sh
/usr/libexec/PlistBuddy -c "Set  CFBundleVersion ${CFBundleVersion}" ./Runner/Info.plist

/usr/libexec/PlistBuddy -c "Print  CFBundleVersion " ./Runner/Info.plist
```

在 Mac 上其实本身就自带了满足需求的命令行工具：`PlistBuddy`， 如上命令所示

- 通过 `Set` 命令可以直接动态配置 `plist` 下的版本号、 code 和第三方 App Id 等相关配置；
- 通过 `Print` 命令直接输出对应的 `plist`信息；


完成  `plist` 配置的支持， 接下来就需要在机器上配置**开发者信息**，最简单的做法就是打开 Xcode 然后直接登陆上开发者账号，通过账号直接让 Xcode 的 `Automatically manage signing` 帮助我们完成整个开发信息的配置过程。

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-iOS-Build/image1)

但是我个人不推荐这种方式，**打包机器本身可能会涉及多个项目组使用，都把自己的开发账号登陆在一个公用机器上存在风险，而且多个账号同时登陆容易混乱，最后直接登陆也不利于证书和描述和管理**。


所以要实现一个较为安全和通用的服务，这里比较推荐：**通过在机器上配置证书和 mobile provision 等文件的方式来完成打包认证**。


## 二、手动配置证书

手动配置证书和  mobile provision 会比较麻烦，但是它可以让服务更加通用，也让你更熟悉 iOS 打包的流程。

1、首先通过本地钥匙串创建  `CertificateSigningRequest.certSigningRequest` 文件，如图所示自动生成就可以了。

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-iOS-Build/image2)

2、在苹果官方的 [developer](https://developer.apple.com/account/resources/certificates/add) 上点击创建证书，上传步骤 1 中的 `CertificateSigningRequest.certSigningRequest` 文件，然后下载 `.cer` 证书文件。


![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-iOS-Build/image3)


3、这里需要注意**不能直接把这个 `.cer` 证书文件安装到打包服务上**，而是**把这个 `.cer` 先安装到上面第 1 步中生成的 `CertificateSigningRequest.certSigningRequest` 的机器上，然后通过导出证书生成带有密码的 `p12` 证书文件**，这个文件才是可以安装到打包机器上的证书文件。


![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-iOS-Build/image4)


4、安装证书，把 `p12` 文件放置到打包服务上，然后点击证书，输入 3 中创建时输入的密码，安装到钥匙串的 **“登陆”** ，这时候就可以看到钥匙串证书里带有 **TeamId 的 Apple Distribution 证书**。


5、需要额外注意**安装后可能会看到说“证书不受信任”的提示，这可能是因为机器上缺少 AppleWWDRCA** (Apple Worldwide Developer Relations Certification Authority)证书，可以通过下面的地址进行安装解决：

- https://developer.apple.com/cn/support/code-signing/

- https://developer.apple.com/support/expiration/


## 三、配置描述文件

配置完证书后就是配置描述文件，在苹果开发者网站的 [Profiles](https://developer.apple.com/account/resources/profiles/add) 创建对应的   mobile provision 。

1、选择 `Distribution` - `App Store` 创建对应的打包模式，如果是 QA 的话一般选择 Ad Hoc ，也就是需要文件绑定设备 UDID ，而不需要上架 Store 的模式。

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-iOS-Build/image5)

2、选择需要支持的 App Id ，也就是 bundle Id 。

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-iOS-Build/image6)

3、选择前面生成的 `Distribution` 证书 ，这里主要一定要选择同意同一个。

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-iOS-Build/image7)

4、最后输入 Provisioning Profile Name ，这个 Name 在后面会有作用，另外如果是 `Ad Hoc` 的话，在这一步可以选择已经添加的 Devices 的 UDID 。


5、完成配置后下载这个 `mobile provision` 文件，将它放到打包机器上的 `/Users/你的账号/Library/MobileDevice/Provisioning Profiles` 目录下，后面会需要用到它。


>  如果是 store 版本的就选择 `Distribution` - `App Store` ，  如果是 QA 版本的就选择 `Distribution` - `Ad Hoc` ， 因为 `App Store`  打出来的包只能通过 Store 或者官方 TestFight 下载，而 `Ad Hoc` 打包的可以通过内部自定义分发下载（通过添加测试设备的 UDID）。


## 四、配置项目


完成了证书和描述文件的配置后，接下来就是针对项目的配置。

首先将需要打包的项目 clone 到打包机器上（只是为了做测试配置），然后打开项目 `ios/Runner.xcworkspace` 目录，这时候可以看到项目因为没有开发者账号，是如下图所示的状态：

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-iOS-Build/image8)


然后我们取消选购 `Automatically manage signing` ， 然后选中我们前面放置的描述文件，就可以看到 Xcode 会自动匹配到钥匙串里的证书，然后显示正常的证书和描述文件配置了。


![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-iOS-Build/image9)


这里有一个需要注意的点，那就是项目在我们本地开发默认使用的就是 `Automatically manage signing` 的方式，因为这样比较方便，所以我们其实是需要**在打包时让它变成手动签名，并且指定 mobile provision 文件的模式**。

所以前面在打包机器上操作 Xcode 取消 `Automatically manage signing` 指定描述文件后，其实已经修改了项目的 `ios/Runner.xcodeproj/project.pbxproj` ，所以这时候你只需要通过 `git diff` 命令就可以导出一个 `patch` 文件，这样在项目被 clone 下来后，通过 `git apply` 直接调整项目的描述文件。


```sh
 git diff >./release.patch     
```

如果有多种编译模式，比如一个项目打包多个 bundleId 和描述文件（QA 、Release）， 那就可以生成多个 `.patch` 文件。


> ⚠️ 注意：**第三方打包机器上每次打包都是 `clone` 一个新项目，打包后删除该项目**，这样可以保证每次打包的独立和干净，而通过改生成不同的 `.patch`  文件，我们可以指向不同的 `mobile provision `，从而加载不同的证书，甚至是同一个项目打包出不同的 `bundle id`。



## 五、开始打包


1、开发打包之前，需要先执行 **`security unlock-keychain  -p xxxxx`** ，解锁下 keychain ，这里的 xxxxx 就是你 Mac 上的密码。


2、通过 `flutter build ios --release` 打包出 release 模式的 `App.framework` 和 `Flutter.framework` 。


3、通过 `xcodebuild` 命令，如下开始编译 iOS 代码了，其中 $PWD 是所在工作目录：


```sh
xcodebuild -workspace Runner.xcworkspace -scheme Runner -sdk iphoneos -configuration Release archive -archivePath $PWD/build/Runner.xcarchive
```


> ⚠️这里有一个需要注意，那就是**打包过程中如果出现 .sh  脚本的相关报错**，比如`xcode_backend.sh" embed_and_thin` 或者 `PhaseScriptExecution Thin\ Binary /Users/xxxxx/Library/Developer/Xcode/DerivedData/` 的错误，推荐先在打包机上用 Xcode 执行一次完整的 `Archive` 流程，在首次执行过程应该会出现关于某些 sh 的授权执行弹框，输入密码点始终完成，然后再重新执行上述脚本。


4、执行完 `Archive ` 之后，就可以进入 `export` 阶段，`exportArchive` 之前需要先准备一个 `ExportOptions.plist` 文件用户指定到处的配置，模板类似：

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>destination</key>
	<string>export</string>
	<key>method</key>
	<string>app-store</string>
	<key>provisioningProfiles</key>
	<dict>
		<key>你的 bundleId </key>
		<string>前面 provision 定义的 name</string>
	</dict>
	<key>signingCertificate</key>
	<string>Apple Distribution</string>
	<key>signingStyle</key>
	<string>manual</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>teamID</key>
	<string>你的开发证书的 Team Id</string>
	<key>uploadBitcode</key>
	<false/>
	<key>uploadSymbols</key>
	<false/>
</dict>
</plist>

```

其中

-  `method` 的数值如果是 store 就写 `app-store` ，如果是 QA 就写 `ad-hoc` ；
-  `provisioningProfiles`  的 `<dict> `需要 `bundleId` 和前面 `provision` 定义的 `name` ；
-  `teamID` 需要的是你的开发证书的 `Team Id`；
-  如果是 store 可以增加 `uploadBitcode` 和 `uploadSymbols` 的配置，如果是 QA 则可以不指定，然后 QA 可以也指定 `thinning` 模式；

![image](http://img.cdn.guoshuyu.cn/20210429_Flutter-iOS-Build/image10)

接着通过指定命令 `exportArchive` ，指定 ExportOptions.plist ，如果是有不同 id 或者不同模式，一般需要配置 QA 和 Prod 两种 `ExportOptions.plist` ，最终输出到 `package_path` 这时候你就得到了一个 ipa 文件。


```sh
xcodebuild -exportArchive -exportOptionsPlist ExportOptions.plist -archivePath $PWD/build/Runner.xcarchive -exportPath $package_path -allowProvisioningUpdates
```


最后如果是 store 模式的，接下来你只需要通过 Mac 的 `Transporter` 将 ipa 上传到 App Store Connect，或者使用命令行工具将自己的应用或内容上传至 App Store Connect 。

```
$ xcrun altool --validate-app -f file -t platform -u username [-p password] [--output-format xml]
$ xcrun altool --upload-app -f file -t platform -u username [-p password] [—output-format xml]

```

> 一般 altool 位于 /Applications/Xcode.app/Contents/Developer/usr/bin/altool ，更多可见 https://help.apple.com/asc/appsaltool/


如果你是 QA 模式，那么你需要先准备一个 `html` 文件，如下所示例子，通过 `a` 标签配置 `itms-service` 指定一个 `DistributionSummary.plist` 文件。

```html

<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>Document</title>
</head>
<body>
<a href=itms-services://?action=download-manifest&url=https://xxxx.xxxx.cn/aaaa/bbbbb/ios/DistributionSummary.plist>install</a>
</body>
</html>

```

然后在 `DistributionSummary.plist` 文件中指定 `software-package` 的 ipa 下载地址，这样就可以完成 QA 的内部自助分发了。（*只能安装 QA provision 里已经配置了 UDID 那些机器*）

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>items</key>
    <array>
        <dict>
            <key>assets</key>
            <array>
                <dict>
                    <key>kind</key>
                    <string>software-package</string>
                    <key>url</key>
                    <string>https://xxxx.xxxxxx.cn/xxxx/Runner.ipa</string>
                </dict>
                <dict>
                    <key>kind</key>
                    <string>full-size-image</string>
                    <key>needs-shine</key>
                    <true/>
                    <key>url</key>
                    <string>http://xxxx.xxxxxx.cn/assets/applog/icon.png</string>
                </dict>
                <dict>
                    <key>kind</key>
                    <string>display-image</string>
                    <key>needs-shine</key>
                    <true/>
                    <key>url</key>
                    <string>http://xxxx.xxxxxx.cn/assets/applog/icon.png</string>
                </dict>
            </array>
            <key>metadata</key>
            <dict>
                <key>bundle-identifier</key>
                <string>com.xxxx.demo</string>
                <key>bundle-version</key>
                <string>1.0.0</string>
                <key>kind</key>
                <string>software</string>
                <key>title</key>
                <string>XXXX App download</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>
```

## 六、多 Flutter 版本环境

如果需求有存在多个项目需要在一个机器打包，但是不同项目的 Flutter 等版本都不同，那么**对于 Mac 可以开启多个不同的登陆用户，这样就可以得到不同的打包环境**，当然这里主要注意的是 CocoaPod 的版本问题，因为比如 ：

- Flutter 1.22 版本默认是使用 1.8.0 之类的 Pod 版本，如果在 Flutter 1.22 上使用 1.10.0 的 Pod 版本会导致 logo 错误等问题；

- Flutter 2.0 需要的是 1.10.0 的 Pod 版本；

而**在 Mac 上默认 CocoaPod  是安装在 `usr/local/bin` 目录**，这个目录其实是多账号共享，所以为了解决这个问题，需要在每个账户环境下安装 `rvm` ，用于管理独立的 CocoaPod 版本。

简单地说：

- 1、先通过 curl 安装 rvm；

```
curl -L get.rvm.io | bash -s stable && source ~/.rvm/scripts/rvm
```

- 2、通过 `rvm install 2.5.5` 安装对应的 ruby 版本，具体可以通过 `rvm list known` 选中你想要需要的版本

> 这里需要注意 `rvm install` 可能会失败，一般和 brew 需要 update 还有网络情况有关系；

- 3、可以安装多个 ruby 版本，然后通过 `rvm use <Version> --default` 或者 `rvm use <Version> ` 来使用具体版本

> 不加 `defalut` 的话，下次启动命令行会变成原来的 `defalut` 版本；

- 4、在当前 ruby 版本下安装想要的 cocoapods 版本，这样当使用 `rvm use` 切换版本时，cocoapods 版本也会跟着切换。

```sh
sudo gem install cocoapods -v <Version> -n /usr/local/bin
```

事实上在不同用户下安装了 rvm 之后，彼此之间的 Pod 版本就已经分割开了。

## 七、最后

说了那么多，其实 Xcode 自动打包确实舒服很多，但是通过整个配置过程，也可以帮助你了解到以前不知道的打包和认证过程。

这里最后额外补充一句，通过如下命令，在打包 Android 或者 iOS 时，可以通过 `--dart-define` 来指定不同的 dart 参数.

```sh
flutter build ios --release --dart-define=CHANNEL=GSY --dart-define=LANGUAGE=Dart
```

在 dart 代码里可以通过 `String.fromEnvironment` 获取到对应的自定义配置参数。

```
const CHANNEL = String.fromEnvironment('CHANNEL');
const LANGUAGE = String.fromEnvironment('LANGUAGE');
```



