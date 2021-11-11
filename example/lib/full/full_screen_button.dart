///
/// Created by wei on 2021/11/11.<br/>
///
import 'package:flt_video_player_example/define/function_define.dart';
import 'package:flutter/material.dart';
import "package:flutter/widgets.dart";

class FullScreenButton extends StatefulWidget {
  const FullScreenButton({Key? key, this.callback}) : super(key: key);

  final ControlButtonCallback<bool>? callback;

  @override
  _FullScreenButtonState createState() => _FullScreenButtonState();
}

class _FullScreenButtonState extends State<FullScreenButton> {
  bool _full = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Image.asset(
        _full
            ? "resources/arrow.down.right.and.arrow.up.left.circle.png"
            : "resources/arrow.up.backward.and.arrow.down.forward.circle.png",
      ),
      onTap: () {
        _full = !_full;
        setState(() {});
        widget.callback?.call(_full);
      },
    );
  }
}
