# flt_video_player_example

Demonstrates how to use the flt_video_player plugin.

### Example
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