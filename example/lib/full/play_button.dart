///
/// Created by wei on 2021/11/11.<br/>
///

import 'package:flt_video_player_example/define/function_define.dart';
import 'package:flutter/material.dart';
import "package:flutter/widgets.dart";

class PlayButton extends StatefulWidget {
  const PlayButton({Key? key, required this.isPlaying, this.callback})
      : super(key: key);

  final ControlButtonCallback<bool>? callback;
  final bool isPlaying;

  @override
  _PlayButtonState createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> {
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Image.asset(
        _isPlaying ? "resources/pause_circle.png" : "resources/play_circle.png",
      ),
      onTap: () {
        widget.callback?.call(_isPlaying);
        _isPlaying = !_isPlaying;
        setState(() {});
      },
    );
  }
}
