import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flt_video_player/flt_video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late VodPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = VodPlayerController();
    controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: VodPlayer(
              controller: controller,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(onPressed: (){
          controller.play("https://look.chinahrt.com.cn/courseyun/rxsl2content/transcode/20211/be3b6935-f678-4303-a1f8-b2a006352656/283006-mp4.mp4");
        },),
      ),
    );
  }
}
