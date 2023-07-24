///
/// Created by wei on 2021/11/11.<br/>
///
import 'package:flt_video_player/flt_video_player.dart';
import 'package:flt_video_player_example/define/function_define.dart';
import 'package:flutter/material.dart';

class RateButton extends StatefulWidget {
  const RateButton({Key? key, required this.controller, this.callback})
      : super(key: key);

  final ControlButtonCallback<double>? callback;

  final VodPlayerController controller;

  @override
  _RateButtonState createState() => _RateButtonState();
}

class _RateButtonState extends State<RateButton> {
  final _rates = [1.0, 1.5, 1.75, 2.0];
  var _index = 0;
  double _rate = 1.0;

  @override
  void initState() {
    super.initState();
    _rate = widget.controller.rate;
    _index = _rates.indexWhere((element) => element == _rate);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Text(
        "${_rate}x",
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () {
        _index++;
        if (_index >= _rates.length) {
          _index = 0;
        }
        _rate = _rates[_index];
        widget.controller.setRate(_rate);
        setState(() {});
        widget.callback?.call(_rate);
      },
    );
  }
}
