///
/// Created by wei on 2021/11/5.<br/>
///
///
import 'dart:async';

import 'package:flutter/services.dart';

class Plugin {
  static const methodChannelPrefix = "plugins.bughub.icu";

  static const MethodChannel _channel =
      MethodChannel('$methodChannelPrefix/flt_video_player');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<int> createVodPlayer() async {
    return await _channel.invokeMethod('createVodPlayer');
  }

  static Future<int> releasePlayer(int playerId) async {
    return await _channel.invokeMethod("releasePlayer", {"playerId": playerId});
  }
}
