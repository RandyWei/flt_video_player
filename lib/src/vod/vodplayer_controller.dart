import 'dart:async';

import 'package:flt_video_player/flt_video_player.dart';
import 'package:flt_video_player/src/plugin.dart';
import 'package:flt_video_player/src/vod/player_define.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

///
/// Created by wei on 2021/11/5.<br/>
///

class VodPlayerController extends ChangeNotifier
    implements ValueListenable<PlayerValue> {
  int _playerId = -1; //播放器 id

  //播放器调用通道
  MethodChannel? _channel;

  late final Completer<int> _initPlayer;
  late final Completer<int> _createTexture;

  bool _isDisposed = false;
  bool _isNeedDisposed = false;

  late PlayerValue _value;
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

  PlayerConfig? config;

  RenderType? renderType;

  VodPlayerController({this.config, this.renderType = RenderType.texture})
      : _initPlayer = Completer(),
        _createTexture = Completer() {
    _value = PlayerValue.uninitialized();
    _state = _value.state;
    if (renderType == RenderType.texture) {
      _create();
    }
  }

  Future<int> get textureId async {
    return _createTexture.future;
  }

  ///
  /// 创建播放器
  ///
  Future<void> _create() async {
    var configJson = config?.toJson() ?? {};
    _playerId = await Plugin.createVodPlayer(configJson);
    _initChannel();
  }

  void _initChannel() {
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
    if (!_initPlayer.isCompleted) _initPlayer.complete(_playerId);
  }

  ///
  /// PlatformView 初始化完成回调
  ///
  void onPlatformViewCreated(int id) {
    debugPrint("onPlatformViewCreated:$id");
    _playerId = id;
    _initChannel();
  }

  ///
  /// 初始化
  ///
  Future<void> initialize() async {
    if (_isNeedDisposed) return;

    await _initPlayer.future; //等待初始化完成

    debugPrint("initialize");
    //通过初始化得到 Texture id，不等同 palyer id
    final textureId = await _channel?.invokeMethod("init");

    _createTexture.complete(textureId);
    _updateState(PlayerState.stopped);
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
  /// 停止播放
  ///
  Future<bool> stop() async {
    if (_isNeedDisposed) return false;

    await _initPlayer.future;

    final result = await _channel?.invokeMethod("stop");
    _updateState(result == 0 ? PlayerState.stopped : _state!);
    return result == 0;
  }

  ///
  /// 暂停播放
  ///
  Future<void> pause() async {
    if (_isNeedDisposed) return;

    await _initPlayer.future;

    await _channel?.invokeMethod("pause");
    _updateState(PlayerState.paused);
  }

  ///
  /// 继续播放
  ///
  Future<void> resume() async {
    if (_isNeedDisposed) return;

    await _initPlayer.future;

    await _channel?.invokeMethod("resume");
    _updateState(PlayerState.buffering);
  }

  ///
  ///  跳转到某个时间点
  ///
  Future<void> seek(int time) async {
    if (_isNeedDisposed) return;

    await _initPlayer.future;

    await _channel?.invokeMethod("seek", {"time": time});
  }

  ///
  ///  开始播放前设置时间点
  ///
  Future<void> setStartTime(int time) async {
    if (_isNeedDisposed) return;

    await _initPlayer.future;

    await _channel?.invokeMethod("setStartTime", {"time": time});
  }

  ///
  /// 设置静音
  ///
  Future<void> setMute(bool enable) async {
    if (_isNeedDisposed) return;

    await _initPlayer.future;

    await _channel?.invokeMethod("setMute", {"enable": enable});
  }

  /// 设置音量大小
  /// @param volume 音量大小。范围：0 ~ 100。
  Future<void> setAudioPlaybackVolume(int volume) async {
    if (_isNeedDisposed) return;

    await _initPlayer.future;

    await _channel?.invokeMethod("setAudioPlaybackVolume", {"volume": volume});
  }

  /// 设置播放速率
  /// @param rate 正常速度为1.0；小于为慢速；大于为快速。最大建议不超过2.0
  Future<void> setRate(double rate) async {
    if (_isNeedDisposed) return;

    await _initPlayer.future;

    await _channel?.invokeMethod("setRate", {"rate": rate});
  }

  /// 设置画面镜像
  ///
  Future<void> setMirror(bool mirror) async {
    if (_isNeedDisposed) return;

    await _initPlayer.future;

    await _channel?.invokeMethod("setMirror", {"mirror": mirror});
  }

  ///
  /// 设置画面旋转
  /// homeOrientaionRight, //< HOME 键在右边，横屏模式
  ///   homeOrientationDown, //< HOME 键在下面，手机直播中最常见的竖屏直播模式
  ///   homeOrientationLeft, //< HOME 键在左边，横屏模式
  ///   homeOrientationUp, //< HOME 键在上边，竖屏直播（适合小米 MIX2）
  ///
  Future<void> setRenderRotation(RenderRotation rotaion) async {
    if (_isNeedDisposed) return;

    await _initPlayer.future;

    await _channel
        ?.invokeMethod("setRenderRotation", {"rotaion": rotaion.index});
  }

  ///获取是否正在播放
  Future<bool> get isPlaying async {
    if (_isNeedDisposed) return false;

    await _initPlayer.future;

    return await _channel?.invokeMethod("isPlaying");
  }

  ///当前播放进度
  Future<double> get currentPlaybackTime async {
    if (_isNeedDisposed) return 0;

    await _initPlayer.future;

    return await _channel?.invokeMethod("currentPlaybackTime");
  }

  ///获取视频总进度
  Future<double> get duration async {
    if (_isNeedDisposed) return 0;

    await _initPlayer.future;

    return await _channel?.invokeMethod("duration");
  }

  ///获取可播放进度
  Future<double> get playableDuration async {
    if (_isNeedDisposed) return 0;

    await _initPlayer.future;

    return await _channel?.invokeMethod("playableDuration");
  }

  ///
  /// 播放器事件
  /// event 类型
  /// see:https://cloud.tencent.com/document/product/454/7886#.E6.92.AD.E6.94.BE.E4.BA.8B.E4.BB.B6
  ///
  void _eventHandler(event) {
    if (event == null) return;

    final Map<dynamic, dynamic> map = event;
    debugPrint("_eventHandler:${map["event"]}");
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
        _value.duration = event["EVT_PLAY_DURATION"] * 1.0;
        _value.progress = event["EVT_PLAY_PROGRESS"] * 1.0;
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

  ///
  /// 更新播放器状态
  ///
  void _updateState(PlayerState playerState) {
    value = _value.copyWith(state: playerState);
    _state = value.state;
    debugPrint("_updateState:$_state");
    if (_state == null) return;
    _stateStreamController.add(_state!);
  }

  ///
  /// 释放播放器
  ///
  Future<void> _release() async {
    await _initPlayer.future;
    await Plugin.releasePlayer(_playerId);
  }

  @override
  PlayerValue get value => _value;

  set value(PlayerValue value) {
    if (_value == value) return;
    _value = value;
    notifyListeners();
  }

  @override
  void dispose() async {
    _isNeedDisposed = true;

    if (!_isDisposed) {
      stop();

      await _eventSubScription?.cancel();
      _eventSubScription = null;

      await _netSubScription?.cancel();
      _netSubScription = null;

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
