///
/// Created by wei on 2021/11/11.<br/>
///
import 'package:flt_video_player_example/define/function_define.dart';
import 'package:flutter/material.dart';
import "package:flutter/widgets.dart";

class MuteButton extends StatefulWidget {
  const MuteButton({Key? key,this.callback}) : super(key: key);

  final ControlButtonCallback<bool>? callback;
  @override
  _MuteButtonState createState() => _MuteButtonState();
}

class _MuteButtonState extends State<MuteButton> {
  bool _mute = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Image.asset(
        _mute ? "resources/speaker.slash.circle.png" : "resources/speaker.circle.png",
      ),
      onTap: () {
        _mute = !_mute;
        setState(() {});
        widget.callback?.call(_mute);
      },
    );
  }
}
