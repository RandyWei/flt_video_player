///
/// Created by wei on 2021/11/11.<br/>
///
import 'package:flt_video_player/flt_video_player.dart';
import 'package:flt_video_player_example/full/full_player.dart';
import 'package:flutter/material.dart';
import "package:flutter/widgets.dart";

class FullPlayerDemo extends StatefulWidget {
  const FullPlayerDemo({Key? key}) : super(key: key);

  @override
  _FullPlayerDemoState createState() => _FullPlayerDemoState();
}

class _FullPlayerDemoState extends State<FullPlayerDemo> {
  late VodPlayerController controller;
  double _aspectRation = 16 / 9;

  @override
  void initState() {
    super.initState();
    var playerConfig = PlayerConfig();
    playerConfig.headers = {"Referer": "https://videoadmin.chinahrt.com"};

    controller = VodPlayerController(config: playerConfig);

    //监听播放状态
    controller.playState.listen((event) {
      debugPrint("playerState:$event");
    });

    controller.onNetEvent.listen((event) {
      //获取视频宽度高度
      double w = (event["VIDEO_WIDTH"]).toDouble();
      double h = (event["VIDEO_HEIGHT"]).toDouble();

      //计算比例
      if (w > 0 && h > 0) {
        _aspectRation = 1.0 * w / h;
        setState(() {});
      }
    });

    controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Player Demo"),
      ),
      body: Column(
        children: [
          FullPlayer(
            playCall: () {
              if (controller.value.state == PlayerState.stopped) {
                controller.play(
                    "https://look.chinahrt.com.cn/courseyun/rxsl2content/transcode/20211/be3b6935-f678-4303-a1f8-b2a006352656/283006-mp4.mp4");
              } else {
                controller.resume();
              }
            },
            controller: controller,
            aspectRatio: _aspectRation,
            title: "测试视频",
            coverUrl:
                "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fimg.jj20.com%2Fup%2Fallimg%2F1114%2F060421091316%2F210604091316-6-1200.jpg&refer=http%3A%2F%2Fimg.jj20.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1639190767&t=831d19c414f872da0b3cf565b3019bfd",
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
