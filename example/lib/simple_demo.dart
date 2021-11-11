///
/// Created by wei on 2021/11/8.<br/>
///

import 'package:flt_video_player/flt_video_player.dart';
import 'package:flutter/material.dart';
import "package:flutter/widgets.dart";

class SimpleDemo extends StatefulWidget {
  const SimpleDemo({Key? key}) : super(key: key);

  @override
  _SimpleDemoState createState() => _SimpleDemoState();
}

class _SimpleDemoState extends State<SimpleDemo> {
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

    controller.onPlayerEvent.listen((event) {
      debugPrint("PlayerEvent:$event");
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
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: _aspectRation,
          child: VodPlayer(
            controller: controller,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //https://hwonline.oss-cn-beijing.aliyuncs.com/course/浅谈医德医风建设.mp4
          //https://look.chinahrt.com.cn/courseyun/rxsl2content/transcode/20211/be3b6935-f678-4303-a1f8-b2a006352656/283006-mp4.mp4
          //https://video.qiantucdn.com/58pic/00/20/21/09v58PICJQgaWdcC58PICSUbK.mp4?e=1636441061&token=OyzEe_0O8H433pm7zVEjtnSy5dVdfpsIawO2nx3f:eHu6r0m7_zdDEj-L6lTqq_6OYPs=
          //https://stream7.iqilu.com/10339/article/202002/18/2fca1c77730e54c7b500573c2437003f.mp4
          controller.play(
              "https://stream7.iqilu.com/10339/article/202002/18/2fca1c77730e54c7b500573c2437003f.mp4");
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
