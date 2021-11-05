import 'dart:async';

import 'package:flt_video_player/flt_video_player.dart';
import 'package:flt_video_player/src/plugin.dart';
import 'package:flt_video_player/src/vod/player_define.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

///
/// Created by wei on 2021/11/5.<br/>
///

class VodPlayerController extends ChangeNotifier {
  int _playerId = -1; //播放器 id

  //播放器调用通道
  MethodChannel? _channel;

  late final Completer<int> _initPlayer;
  late final Completer<int> _createTexture;

  bool _isDisposed = false;
  bool _isNeedDisposed = false;

  PlayerValue? _value;
  PlayerState? _state;

  //播放事件广播器
  final StreamController<Map<dynamic, dynamic>> _eventStreamController =
      StreamController.broadcast();

  Stream<Map<dynamic, dynamic>> get onPlayerEvent =>
      _eventStreamController.stream;

  StreamSubscription? _eventSubScription;

  //网络事件广播
  final StreamController<Map<dynamic, dynamic>> _netStreamController =
      StreamController.broadcast();

  Stream<Map<dynamic, dynamic>> get onNetEvent => _netStreamController.stream;

  StreamSubscription? _netSubScription;

  //状态广播
  final StreamController<PlayerState> _stateStreamController =
      StreamController.broadcast();

  Stream<PlayerState> get playState => _stateStreamController.stream;

  VodPlayerController()
      : _initPlayer = Completer(),
        _createTexture = Completer() {
    _value = PlayerValue.uninitialized();
    _state = _value?.state;
    _create();
  }

  Future<int> get textureId async {
    return _createTexture.future;
  }

  ///
  /// 创建播放器
  ///
  Future<void> _create() async {
    _playerId = await Plugin.createVodPlayer();
    //每一个播放器对象创建独立的通信通道
    _channel =
        MethodChannel("${Plugin.methodChannelPrefix}/vodplayer/$_playerId");

    _eventSubScription =
        EventChannel("${Plugin.methodChannelPrefix}/vodplayer/event/$_playerId")
            .receiveBroadcastStream("event")
            .listen(_eventHandler);

    _netSubScription =
        EventChannel("${Plugin.methodChannelPrefix}/vodplayer/net/$_playerId")
            .receiveBroadcastStream("net")
            .listen(_netHandler);
    _initPlayer.complete(_playerId);
  }

  ///
  /// 初始化
  ///
  Future<void> initialize() async {
    if (_isNeedDisposed) return;

    await _initPlayer.future; //等待初始化完成

    //通过初始化得到 Texture id，不等同 palyer id
    final textureId = await _channel?.invokeMethod("init");

    _createTexture.complete(textureId);
  }

  ///
  /// 播放视频
  ///
  Future<bool> play(String url) async {
    await _initPlayer.future;
    await _createTexture.future;

    _updateState(PlayerState.buffering);

    final result = await _channel?.invokeMethod("play", {"url": url});
    return result == 0;
  }

  ///
  /// 播放器事件
  /// event 类型
  /// see:https://cloud.tencent.com/document/product/454/7886#.E6.92.AD.E6.94.BE.E4.BA.8B.E4.BB.B6
  ///
  void _eventHandler(event) {
    if (event == null) return;

    final Map<dynamic, dynamic> map = event;

    switch (map["event"]) {
      case 2002:
        break;
      case 2003:
        if (_isNeedDisposed) return;
        if (_state == PlayerState.buffering) _updateState(PlayerState.playing);
        break;
      case 2004:
        if (_isNeedDisposed) return;
        if (_state == PlayerState.buffering) _updateState(PlayerState.playing);
        break;
      case 2005: //播放进度
        break;
      case 2006:
        _updateState(PlayerState.stopped);
        break;
      case 2007:
        _updateState(PlayerState.buffering);
        break;
      case 2009: //下行视频分辨率改变
        break;
      case 2013: //点播加载完成
        break;
      case 2014: //loading 结束
        break;
      case -2301:
        _updateState(PlayerState.failed);
        break;
      case -2303:
        _updateState(PlayerState.failed);
        break;
      case -2305:
        _updateState(PlayerState.failed);
        break;
      case 2103:
        break;
      case 3001:
        break;
      case 3002:
        break;
      case 3003:
        break;

      default:
        break;
    }

    _eventStreamController.add(map);
  }

  ///
  /// 网络事件
  ///
  void _netHandler(event) {
    if (event == null) return;

    final Map<dynamic, dynamic> map = event;

    _netStreamController.add(map);
  }

  void _updateState(PlayerState playerState) {
    value = _value?.copyWith(state: playerState);
    _state = value?.state;
    if (_state == null) return;
    _stateStreamController.add(_state!);
  }

  Future<void> _release() async {
    await _initPlayer.future;
    await Plugin.releasePlayer(_playerId);
  }

  PlayerValue? get value => _value;

  set value(PlayerValue? value) {
    if (_value == _value) return;
    _value = _value;
    notifyListeners();
  }

  @override
  void dispose() async {
    _isNeedDisposed = true;

    if (!_isDisposed) {
      await _eventSubScription?.cancel();
      _eventSubScription = null;

      await _release();

      _updateState(PlayerState.disposed);

      _isDisposed = true;
      _stateStreamController.close();
      _eventStreamController.close();
      _netStreamController.close();
    }

    super.dispose();
  }
}
