# flt_video_player

基于腾讯云原生播放器封装的 Flutter 版本。
使用本播放器前建议查看腾讯云[官方文档](https://cloud.tencent.com/document/product/881/20191)

## 安装

```puml
//import
dependencies:
flt_video_player:
git:
url: git://github.com/RandyWei/flt_video_player.git
```
## Android

在 app/build.gradle 的 defaultConfig 中添加配置
```
ndk {
       abiFilters "armeabi", "armeabi-v7a", "arm64-v8a"
   }
```
在 android/app/src/main/AndroidManifest.xml 中增加如下配置
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    ...
    >

    <application
        tools:replace="android:label">
    ...
    </application>
```