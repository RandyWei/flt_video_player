///
/// Created by wei on 2021/11/5.<br/>
///
///
import 'package:flt_video_player/src/vod/vodplayer_controller.dart';
import 'package:flutter/widgets.dart';

class VodPlayer extends StatefulWidget {
  final VodPlayerController controller;

  const VodPlayer({Key? key, required this.controller}) : super(key: key);

  @override
  _VodPlayerState createState() => _VodPlayerState();
}

class _VodPlayerState extends State<VodPlayer> {
  int _textureId = -1;

  @override
  void initState() {
    super.initState();

    widget.controller.textureId.then((value) {
      setState(() {
        _textureId = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == -1 ? Container() : Texture(textureId: _textureId);
  }
}
