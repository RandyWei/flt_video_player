# flt_video_player

基于腾讯云播放器TXVodPlayer封装的Flutter Video Player

#### [English](https://github.com/RandyWei/flt_video_player/blob/master/README.md) | 中文文档

## 安装

```
//pub方式
dependencies:
  flt_video_player: ^0.0.2

//导入方式
dependencies:
  flt_video_player:
    git:
      url: git://github.com/RandyWei/flt_video_player.git
```

### Android
确定在mainfest中添加网络权限
确定在application标签中添加tools:replace="android:label"属性，示例如下:

```xml
<manifest
    ...
    xmlns:tools="http://schemas.android.com/tools" >

    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        ...
        tools:replace="android:label">
        ...
    </application>
</manifest>
```



### 格式支持
播放器是基于腾讯云播放器 [TxVodPlayer](https://cloud.tencent.com/document/product/881/),
  可以访问[腾讯云播放器](https://cloud.tencent.com/document/product/881/) 查看支持的格式。

### 截图
![screenshot](https://github.com/RandyWei/flt_video_player/blob/master/screenshot/device-2019-05-22-100616.png)

### 示例
```dart
import 'package:flt_video_player/flt_video_player.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.path(
        "https://github.com/RandyWei/flt_video_player/blob/master/example/SampleVideo_1280x720_30mb.mp4?raw=true")
      ..initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Simple Demo",
      home: Scaffold(
        appBar: AppBar(
          title: Text("Simple Demo"),
        ),
        body: AspectRatio(
          aspectRatio: 1.8,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
  }
}

```
