# flt_video_player

A Video Player Flutter plugin based on TXVodPlayer

*Note*: This plugin is still under development, and some APIs might not be available yet.
[Feedback welcome](https://github.com/RandyWei/flt_video_player/issues) and
[Pull Requests](https://github.com/RandyWei/flt_video_player/pulls) are most welcome!

## Installation

```
//pub(暂未上传)
dependencies:
  flt_video_player: ^0.0.1

//import
dependencies:
  flt_video_player:
    git:
      url: git://github.com/RandyWei/flt_video_player.git
```

### Android

Ensure the following permission and tools:replace="android:label" is present in your Android Manifest file, located in `<project root>/android/app/src/main/AndroidManifest.xml:

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


The Flutter project template adds it, so it may already be there.

### Supported Formats
The backing player is [TxVodPlayer](https://cloud.tencent.com/document/product/881/),
  please refer [here](https://cloud.tencent.com/document/product/881/) for list of supported formats.


### Example
```dart
import 'package:flt_video_player/video_player.dart';
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