///
/// Created by wei on 2021/11/11.<br/>
///
import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui';

import 'package:flt_video_player/flt_video_player.dart';
import 'package:flt_video_player_example/full/full_screen_button.dart';
import 'package:flt_video_player_example/full/play_button.dart';
import 'package:flt_video_player_example/full/rate_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:flutter/widgets.dart";
import 'package:orientation/orientation.dart';

class ControlOverlay extends StatefulWidget {
  const ControlOverlay(
      {Key? key,
      required this.controller,
      this.callPlay,
      this.title,
      this.coverUrl})
      : super(key: key);

  final String? coverUrl;
  final String? title;
  final VodPlayerController controller;

  final Function? callPlay;

  @override
  _ControlOverlayState createState() => _ControlOverlayState();
}

class _ControlOverlayState extends State<ControlOverlay> {
  bool _showLoading = false;
  bool _showCover = true;
  bool _showBigPlayButton = true;

  bool _showControlBar = false;
  bool _showTitleBar = false;

  bool _isPlaying = false;

  Timer? _timer;

  double duration = 0;
  double progress = 0;
  double rate = 1.0;

  @override
  void initState() {
    super.initState();

    var playState = widget.controller.value.state;

    if (playState != PlayerState.stopped) {
      _showCover = false;
      _showBigPlayButton = false;
    }

    widget.controller.playState.listen((PlayerState state) {
      debugPrint(state.toString());
      //状态一旦变化封面要隐藏
      _showLoading = false;
      _showBigPlayButton = true;
      _isPlaying = false;
      if (state == PlayerState.buffering) {
        _showLoading = true;
        _showBigPlayButton = false;
      } else if (state == PlayerState.playing) {
        _showBigPlayButton = false;
        _isPlaying = true;
      }
      setState(() {});
    });

    widget.controller.onPlayerEvent.listen((event) {
      switch (event["event"]) {
        case 2005:
          if (_showControlBar && mounted) {
            duration = event["EVT_PLAY_DURATION"] * 1.0;
            progress = event["EVT_PLAY_PROGRESS"] * 1.0;
            rate = event["EVT_PLAYABLE_RATE"] * 1.0;
            setState(() {});
          }
          break;
      }
    });
  }

  _switchScreenOrientation() {
    //屏幕旋转方向
    final List<DeviceOrientation> orientations = <DeviceOrientation>[];
    if (isPortraitUp) {
      if (Platform.isIOS) {
        orientations.add(DeviceOrientation.landscapeRight);
        SystemChrome.setPreferredOrientations(orientations);
      }
      OrientationPlugin.forceOrientation(DeviceOrientation.landscapeRight);
    } else {
      orientations.add(DeviceOrientation.portraitUp);
      //设置屏幕旋转方向
      SystemChrome.setPreferredOrientations(orientations);
      OrientationPlugin.forceOrientation(DeviceOrientation.portraitUp);
    }
  }

  get isPortraitUp {
    Size screenSize = MediaQueryData.fromWindow(window).size;
    return screenSize.width < screenSize.height;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        //如果当前状态非播放状态，不可呼出控制条
        if (!await widget.controller.isPlaying) return;
        _timer?.cancel();
        _timer = null;
        _timer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          _showControlBar = false;
          setState(() {});
        });
        _showControlBar = !_showControlBar;
        setState(() {});
      },
      child: Stack(
        children: [
          if (_showLoading) const Center(child: CircularProgressIndicator()),

          //封面
          if (_showCover && widget.coverUrl != null)
            Image.network(
              widget.coverUrl!,
            ),

          //大的播放按钮
          if (_showBigPlayButton)
            Center(
              child: SizedBox(
                width: 70,
                child: PlayButton(
                  isPlaying: _isPlaying,
                  callback: (isPlaying) {
                    _showCover = false;
                    setState(() {});
                    widget.callPlay?.call();
                  },
                ),
              ),
            ),

          if (_showControlBar)
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _showTitleBar
                    ? Container(
                        padding: const EdgeInsets.only(left: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.title ?? "",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        color: Colors.black54,
                        height: 30,
                      )
                    : Container(),
                Container(
                  height: 35,
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 25,
                        child: PlayButton(
                          isPlaying: _isPlaying,
                          callback: (isPlaying) {
                            if (isPlaying) {
                              widget.controller.pause();
                            } else {
                              widget.controller.resume();
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          activeColor: Colors.white,
                          inactiveColor: Colors.grey,
                          value: progress,
                          onChanged: (value) {
                            progress = value;
                          },
                          onChangeEnd: (value) {
                            widget.controller.seek(value.toInt());
                          },
                          max: duration,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: RateButton(
                          rate: rate,
                          callback: (rate) {
                            widget.controller.setRate(rate);
                          },
                        ),
                      ),
                      SizedBox(
                        child: FullScreenButton(
                          callback: (isFull) {
                            _switchScreenOrientation();
                          },
                        ),
                        width: 25,
                      )
                    ],
                  ),
                )
              ],
            )
        ],
      ),
    );
  }
}
