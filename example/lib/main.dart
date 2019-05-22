import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flt_video_player/flt_video_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  VideoPlayerController controller;
  bool _showOverlay = false;
  Timer _timer;
  final String title = "播放器播放测试标题";

  VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    //该视频为直播源，没有时长 http://5815.liveplay.myqcloud.com/live/5815_89aad37e06ff11e892905cb9018cf0d4_900.flv
    controller = VideoPlayerController.path(
        "https://look.chinahrt.com.cn//courseyun/rx/topic/video/170508/149421376907147ae58ea-09f2-4b7c-a22c-11567a5ae96b.mp4")
      ..initialize();

    _listener = () {
      setState(() {});
      if (controller.value.hasError) {
        print(controller.value);
      }
    };

    controller?.addListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    final Widget loadingWidget = const Center(child: CircularProgressIndicator());

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: AspectRatio(
          aspectRatio: 1.8,
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                InkWell(
                  onTap: () {
                    _switchOverlay();
                  },
                  child: VideoPlayer(controller),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: _showOverlay ? _buildTopContainer() : null,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: (_showOverlay && controller.value.initialized)
                      ? buildBottomContainer()
                      : null,
                ),
                Center(
                    child: (!controller.value.initialized || controller.value.isBuffering)
                        ? loadingWidget
                        : null),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container buildBottomContainer() {
    String position = controller.value.position.toString();
    if (position.lastIndexOf(".") > -1) {
      position = position.substring(0, position.lastIndexOf("."));
    }

    String duration = controller.value.duration.toString();
    if (duration.lastIndexOf(".") > -1) {
      duration = duration.substring(0, duration.lastIndexOf("."));
    }

    return Container(
      color: Colors.black.withAlpha(127),
      child: Row(
        children: <Widget>[
          Container(
            height: 40,
            child: IconButton(
              color: Colors.white,
              highlightColor: Colors.white.withAlpha(127),
              onPressed: () {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  if (controller.value.position.inSeconds == controller.value.duration?.inSeconds) {
                    controller.seekTo(Duration(seconds: 0));
                  }
                  controller.play();
                }
              },
              icon: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 40,
              child: _SliderWidget(controller),
            ),
          ),
          Text(
            "$position / $duration",
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white),
          ),
          IconButton(
            color: Colors.white,
            highlightColor: Colors.white.withAlpha(127),
            icon: Icon(controller.value.isMute ? Icons.volume_off : Icons.volume_up),
            onPressed: () {
              controller.setMute(!controller.value.isMute);
            },
          ),
          InkWell(
            child: Padding(
              padding: EdgeInsets.all(2.0),
              child: Text(
                "倍速",
                style: TextStyle(color: Colors.white),
              ),
            ),
            onTap: () {
              if (controller.value.rate == 1.0) {
                controller.setRate(1.5);
              } else if (controller.value.rate == 1.5) {
                controller.setRate(2.0);
              } else if (controller.value.rate == 2.0) {
                controller.setRate(0.5);
              } else if (controller.value.rate == 0.5) {
                controller.setRate(1.0);
              }
            },
          ),
          SizedBox(
            width: 10.0,
          )
        ],
      ),
    );
  }

  Container _buildTopContainer() {
    return Container(
      color: Colors.black.withAlpha(127),
      child: Row(
        children: <Widget>[
          Container(
            height: 40,
            child: IconButton(
              color: Colors.white,
              highlightColor: Colors.white.withAlpha(127),
              onPressed: () {},
              icon: const Icon(
                Icons.arrow_back_ios,
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }

  void _switchOverlay() {
    if (_showOverlay) {
      _showOverlay = false;
    } else {
      _showOverlay = true;
      _timer = Timer(Duration(milliseconds: 2000), () {
        _showOverlay = false;
        //This error happens if you call setState() on a State object for a widget that no longer appears in the widget tree
        if (mounted) setState(() {});
      });
    }
    setState(() {});
  }
}

class _SliderWidget extends StatefulWidget {
  _SliderWidget(this.controller);

  final VideoPlayerController controller;

  @override
  _SliderWidgetState createState() =>
      _SliderWidgetState(controller.value.position.inMilliseconds.toDouble());
}

class _SliderWidgetState extends State<_SliderWidget> {
  _SliderWidgetState(this.position);

  double position;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (!mounted) return;
      setState(() {
        position = widget.controller.value.position.inMilliseconds.toDouble();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.controller.value.duration.inMilliseconds.toDouble() > position
        ? Slider(
            max: widget.controller.value.duration.inMilliseconds.toDouble(),
            value: position,
            onChanged: (double value) {
              setState(() {
                position = value.roundToDouble();
                widget.controller.seekTo(Duration(milliseconds: position.toInt()));
              });
            })
        : Container();
  }
}
