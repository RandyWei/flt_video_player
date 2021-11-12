///
/// Created by wei on 2021/11/11.<br/>
///

import 'package:flt_video_player/flt_video_player.dart';
import 'package:flt_video_player_example/full/player_control_overlay.dart';
import 'package:flutter/material.dart';
import "package:flutter/widgets.dart";

class FullPlayer extends StatefulWidget {
  const FullPlayer(
      {Key? key,
      required this.controller,
      this.title,
      this.playCall,
      this.aspectRatio = 16 / 9,
      this.coverUrl})
      : super(key: key);

  final double aspectRatio;
  final String? coverUrl;
  final String? title;
  final Function? playCall;
  final VodPlayerController controller;

  @override
  _FullPlayerState createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        VodPlayer(controller: widget.controller),
        ControlOverlay(
          controller: widget.controller,
          callPlay: widget.playCall,
          coverUrl: widget.coverUrl,
          title: widget.title,
        )
      ],
    );
  }
}
