# Flutter Gradle 命令式插件正式移除，你迁移旧版 Gradle 配置了吗？

在 Flutter 3.29 版本里官方正式移除了 Flutter Gradle Apply 插件，其实该插件自 3.19 起已被弃用，同时 Flutter 团队后续也打算把 Flutter Gradle 从 Groovy 转换为 Kotlin，并将其迁移到使用 AGP（Android Gradle Plugin）的公共 API，所以这个改动有望降低在发布新 AGP 版本时损坏的频率，并减少基于构建的回归。

> 从这里也可以看出来，Flutter 团队也为 AGP 升级迭代适配感到“头痛”。

**所以如果你的项目是在 3.16 版本之前创建，但一直尚未迁移，那么在 3.29 版本下肯定会受到直接影响**，比如之前  Flutter 工具在构建项目时有警告：“`You are applying Flutter's main Gradle plugin imperatively`”，那么基本可以确定会 3.29 版本会无法正常运行，开发者需要手动进行迁移。

# 各种版本对应关系

**首先要说一些额外前置关系，和本文没直接关联，适合在迁移时还有升级需求的，如果不感兴趣可以直接看第二部分**，因为在 Android  Gradle 里，AGP 相关升级可以说是 Android 开发者最头疼的问题之一，这里面除了涉及 JDK 、Gradle、AGP、Kotlin、KGP（Kotlin Gradle Plugin）等版本之外，甚至还和 Android Studio 的版本有关系，而 [Android Studio 正式版又刚刚度过 10 周年](https://juejin.cn/post/7465280957088956427)， 种种因素之下，**想要不那么难受的升级迁移，或者你需要简单理清下他们的版本对应关系**。

> 比如之前就出现过，由于某些官方的 androidx 开始升级到了 JDK 21 ，但是官方在旧版 AGP 中没有正确处理，从而引发如 [`D8 Cannot invoke "String.length()" because "<parameter1>`](https://juejin.cn/post/7418456558978039817) 等相关 issue 。

首先我们以 JDK 作为视角，简单看看 Android 构建中的 JDK 关系，大概可以知道 JDK 在 Gradle、Kotlin、Android Studio 和 AGP 里的角色：

![](http://img.cdn.guoshuyu.cn/20250212_KF/image1.png)

然后，我们再简单看看，在不同 Android Studio 里，默认自带的 JDK 版本是什么：

- Android Studio Ladybug （ **JDK 21**）      
- Android Studio Koala
- Android Studio Jellyfish 
- Android Studio Iguana 
- Android Studio Hedgehog 
- Android Studio Giraffe 
- Android Studio Flamingo （ **JDK 17**）
- Android Studio Electric Eel 
- Android Studio Dolphin
- Android Studio Chipmunk 
- Android Studio Bumblebee 
- Android Studio Arctic Fox （**JDK 11**）

接着，我们再看看 Android Studio 和 AGP 版本之间的对应关系：

![](http://img.cdn.guoshuyu.cn/20250212_KF/image2.png)

然后我们再看 [Java version 和 Gradle](https://docs.gradle.org/current/userguide/compatibility.html) 之间的版本对应关系：

![](http://img.cdn.guoshuyu.cn/20250212_KF/image3.png)

最后是 [AGP 和 Gradle](https://developer.android.com/build/releases/gradle-plugin) 版本之间的关系：

![](http://img.cdn.guoshuyu.cn/20250212_KF/image4.png)

到这里，我们可以直观知道，Gradle 版本其实和 Java 版本有关系的，而不同 Android Studio 默认自带的 JDK 版本是不同的，所以在迁移过程中，你需要确定：

- Android Studio  版本
- AGP 版本
- Gradle 版本
- JDK 版本

只有这**四者之间版本范围合适**，你才可以减少在迁移升级版本的过程中冲突踩坑，**当然 Android Studio 内置的 JDK 版本是支持手动切换的** ，你可以在设置里手动下载想要的 JDK 版本：

![](http://img.cdn.guoshuyu.cn/20250212_KF/image5.png)

> 当然，如果你不用 Andriod Studio ，只用 VSCode 的话，那么就可以减少考虑 Android Studio  版本和内置 JDK 的问题。

接着，其实还有 KGP 、 Kotlin  和 AGP 的版本对应关系问题，因为在 Flutter 里，各种 Plugin 和主工程都可能有不同的 kotlin versoin：

![](http://img.cdn.guoshuyu.cn/20250212_KF/image6.png)

关于 [KGP 、Gradle 和 AGP](https://kotlinlang.org/docs/gradle-configure-project.html#apply-the-plugin) 的对应关系：

![](http://img.cdn.guoshuyu.cn/20250212_KF/image7.png)

可以看到，在选择对应 KGP 的时候，最好是在合适 AGP 范围内，不然编译可能也会出现意料之外的报错。

![](http://img.cdn.guoshuyu.cn/20250212_KF/image8.png)

# 迁移

从 Flutter 3.16 开始，官方就增加了使用 Gradle 的[声明式插件 {} 块](https://docs.gradle.org/8.5/userguide/plugins.html#sec:plugins_block)（也称为插件 DSL）应用插件的支持，而 DSL 会要求静态定义插件，这也是 `plugins {}` 块机制和传统 `apply()` 的差异之一，例如：

- `plugins{}` 只能在项目的构建脚本 `build.gradle（.kts）` 和 `settings.gradle（.kts）` 文件中使用，并且它必须出现在任何其他块之前，同时不能在 script plugins 或 init 脚本中使用
- `plugins {}` 块不支持任意代码，它必须是无副作用，每次都产生相同的结果
- `plugins{}`  必须是构建脚本中的顶级语句，它不能嵌套在另一个结构中（如 if 语句或 for 循环）

所以，迁移时，我们首先需要找到项目当前使用的 Android Gradle Plugin （AGP） 和 Kotlin 的值，一般都在 `/android/build.gradle` 文件的 `buildscript` 里，比如这里的 `kotlin_version` 和 `com.android.tools.build:gradle` ：

```groovy
buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
```

接下来，需要将项目下  `/android/settings.gradle`  的内容替换为以下内容，这里的 `{agpVersion}` 和 `{kotlinVersion}` 就是前面原本的数值 ：

```groovy
pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "{agpVersion}" apply false
    id "org.jetbrains.kotlin.android" version "{kotlinVersion}" apply false
}

include ":app"
```

如果你还有一些其他参数配置，需要确保将它们放在 `pluginManagement {}` 和 `plugins {}` 块之后，正如前面所说， Gradle 强制要求不能将其他代码放在这些块之前。

接着，从 `/android/build.gradle` 中删除整个 `buildscript` 块：

![](http://img.cdn.guoshuyu.cn/20250212_KF/image9.png)

默认情况下，`android/build.gradle`  文件应该只剩下这个样子：

```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}
subprojects {
    project.evaluationDependsOn(':app')
}

tasks.register("clean", Delete) {
    delete rootProject.buildDir
}
```

接着你还需要对代码 `android/app/build.gradle`  进行一些调整，例如删除以下 2 个使用旧版命令式 apply 方法的代码块：

![](http://img.cdn.guoshuyu.cn/20250212_KF/image10.png)

然后再次添加对应的插件，但这次使用 Plugin DSL 语法，同样需要在文件的最顶部：

```groovy
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}
```

最后，如果您的 `dependencies` 块包含对  `"org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"`  的依赖项，还需要删除该依赖项:

![image-20250212224117799](http://img.cdn.guoshuyu.cn/20250212_KF/image11.png)

以上是属于官方默认最简配置下的迁移，如果你还是用了其他 `classpath` 和  `apply ` 模块，那么你还需要将他们都移除：

![](http://img.cdn.guoshuyu.cn/20250212_KF/image12.png)

![](http://img.cdn.guoshuyu.cn/20250212_KF/image13.png)

然后将它们添加到应用 `android/settings.gradle` 文件的 `plugins` 块里面：

```groovy
plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "{agpVersion}" apply false
    id "org.jetbrains.kotlin.android" version "{kotlinVersion}" apply false
    /// 这个
    id "com.google.gms.google-services" version "4.4.0" apply false
    /// 这个
    id "com.google.firebase.crashlytics" version "2.9.9" apply false
}
```

并且在 `android/app/build.gradle`  同步添加：

```groovy
plugins {
    id "com.android.application"
    id "dev.flutter.flutter-gradle-plugin"
    id "org.jetbrains.kotlin.android"
    /// 这个
    id "com.google.gms.google-services"
    /// 这个
    id "com.google.firebase.crashlytics"
}
```

最后，以下是一个简单迁移后的 git diff patch 参考：

```diff
Index: android/app/build.gradle
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/android/app/build.gradle b/android/app/build.gradle
--- a/android/app/build.gradle	(revision 69dfe7ed0d762bfd35e470fc31d2aebf1e1690bf)
+++ b/android/app/build.gradle	(revision 1adf2a436b02e7af99121553eb67d7880ad91571)
@@ -1,3 +1,9 @@
+plugins {
+    id "com.android.application"
+    id "kotlin-android"
+    id "dev.flutter.flutter-gradle-plugin"
+}
+
 def localProperties = new Properties()
 def localPropertiesFile = rootProject.file('local.properties')
 if (localPropertiesFile.exists()) {
@@ -6,14 +12,6 @@
     }
 }
 
-def flutterRoot = localProperties.getProperty('flutter.sdk')
-if (flutterRoot == null) {
-    throw new GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")
-}
-
-apply plugin: 'com.android.application'
-apply plugin: 'kotlin-android'
-apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"
 apply from: "exported.gradle"
 
 android {
@@ -31,9 +29,9 @@
         // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
         applicationId "com.shuyu.gsygithub.gsygithubappflutter"
         minSdkVersion 21
-        targetSdkVersion 31
+        targetSdkVersion 33
         versionCode 54
-        versionName "4.0.1"
+        versionName "5.0.0"
         testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
     }
 
@@ -70,9 +68,4 @@
     source '../..'
 }
 
-dependencies {
-    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
-    testImplementation 'junit:junit:4.12'
-    androidTestImplementation 'androidx.test:runner:1.1.1'
-    androidTestImplementation 'androidx.test.espresso:espresso-core:3.1.1'
-}
+dependencies {}
Index: android/build.gradle
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/android/build.gradle b/android/build.gradle
--- a/android/build.gradle	(revision 69dfe7ed0d762bfd35e470fc31d2aebf1e1690bf)
+++ b/android/build.gradle	(revision 1adf2a436b02e7af99121553eb67d7880ad91571)
@@ -1,16 +1,3 @@
-buildscript {
-    ext.kotlin_version = '1.8.10'
-    repositories {
-        google()
-        jcenter()
-    }
-
-    dependencies {
-        classpath "com.android.tools.build:gradle:7.0.3"
-        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
-    }
-}
-
 allprojects {
     repositories {
         google()
Index: android/settings.gradle
IDEA additional info:
Subsystem: com.intellij.openapi.diff.impl.patch.CharsetEP
<+>UTF-8
===================================================================
diff --git a/android/settings.gradle b/android/settings.gradle
--- a/android/settings.gradle	(revision 69dfe7ed0d762bfd35e470fc31d2aebf1e1690bf)
+++ b/android/settings.gradle	(revision 1adf2a436b02e7af99121553eb67d7880ad91571)
@@ -1,15 +1,25 @@
-include ':app'
+pluginManagement {
+    def flutterSdkPath = {
+        def properties = new Properties()
+        file("local.properties").withInputStream { properties.load(it) }
+        def flutterSdkPath = properties.getProperty("flutter.sdk")
+        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
+        return flutterSdkPath
+    }()
 
-def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()
+    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
 
-def plugins = new Properties()
-def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
-if (pluginsFile.exists()) {
-    pluginsFile.withReader('UTF-8') { reader -> plugins.load(reader) }
+    repositories {
+        google()
+        mavenCentral()
+        gradlePluginPortal()
+    }
 }
 
-plugins.each { name, path ->
-    def pluginDirectory = flutterProjectRoot.resolve(path).resolve('android').toFile()
-    include ":$name"
-    project(":$name").projectDir = pluginDirectory
+plugins {
+    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
+    id "com.android.application" version "7.0.3" apply false
+    id "org.jetbrains.kotlin.android" version "1.8.10" apply false
 }
+
+include ":app"
\ No newline at end of file

```





# 参考链接

- https://docs.flutter.dev/release/breaking-changes/flutter-gradle-plugin-apply

