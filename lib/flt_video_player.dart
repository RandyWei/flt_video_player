import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final MethodChannel _channel =
    const MethodChannel('bughub.dev/flutterVideoPlayer')..invokeMethod('init');

class VideoPlayerController extends ValueNotifier<VideoPlayerValue> {
  VideoPlayerController.path(this.dataSource,
      {this.startPosition = 0, this.playerConfig})
      : super(VideoPlayerValue(duration: null));

  int _textureId;
  String dataSource;
  int startPosition = 0;
  PlayerConfig playerConfig;
  _VideoAppLifeCycleObserver _lifeCycleObserver;

  @visibleForTesting
  int get textureId => _textureId;
  bool _isDisposed = false;
  Completer<void> _creatingCompleter;
  StreamSubscription<dynamic> _eventSubscription;

  Future<void> initialize() async {
    _lifeCycleObserver = _VideoAppLifeCycleObserver(this);
    _lifeCycleObserver.initialize();
    _creatingCompleter = Completer<void>();

    if (null == playerConfig) {
      playerConfig = PlayerConfig();
    }

    final Map<dynamic, dynamic> response =
        await _channel.invokeMethod('create', {
      "path": dataSource,
      "startPosition": startPosition,
      "playerConfig": playerConfig.toJson()
    });
    _textureId = response['textureId'];
    _creatingCompleter.complete(null);

//    final Completer<void> initializingCompleter = Completer<void>();
    void eventListener(dynamic event) {
      final Map<dynamic, dynamic> map = event;
      switch (map['event']) {
        case "PLAY_EVT_RCV_FIRST_I_FRAME": // 渲染首个视频数据包(IDR)
          break;
        case "PLAY_EVT_VOD_LOADING_END": // loading结束（点播）
          value = value.copyWith(isBuffering: false);
          break;
        case "PLAY_EVT_PLAY_BEGIN": // 视频播放开始
          value = value.copyWith(
            isPlaying: true,
            duration: Duration(seconds: map['duration']),
            position: Duration(seconds: map['position']),
          );
          break;
        case "PLAY_EVT_PLAY_PROGRESS": // 视频播放进度
          value = value.copyWith(
            isPlaying: true,
            duration: Duration(seconds: map['duration']),
            position: Duration(seconds: map['position']),
          );
          break;
        case "PLAY_EVT_PLAY_END": // 视频播放结束
          value = value.copyWith(
            isPlaying: false,
          );
          break;
        case "PLAY_EVT_PLAY_LOADING": // 视频播放loading
          value = value.copyWith(isBuffering: true);
          break;
        case "PLAY_EVT_CONNECT_SUCC": // 已经连接服务器
          break;
      }
    }

    void errorListener(Object obj) {
      print(obj);
      final PlatformException e = obj;
      value = VideoPlayerValue.erroneous(e.message);
    }

    EventChannel _eventChannelFor(int textureId) {
      return EventChannel(
          'bughub.dev/flutterVideoPlayer/videoEvents$textureId');
    }

    _eventSubscription = _eventChannelFor(_textureId)
        .receiveBroadcastStream()
        .listen(eventListener, onError: errorListener);

    return Future.value(null);
  }

  ///开始播放
  Future<void> play() async {
    if (!value.initialized || _isDisposed) {
      return;
    }
    value = value.copyWith(isPlaying: true);
    if (value.isPlaying) {
      await _channel.invokeMethod(
        'play',
        <String, dynamic>{'textureId': _textureId},
      );
    }
  }

  ///暂停播放
  Future<void> pause() async {
    if (!value.initialized || _isDisposed) {
      return;
    }
    value = value.copyWith(isPlaying: false);
    if (!value.isPlaying) {
      await _channel.invokeMethod(
        'pause',
        <String, dynamic>{'textureId': _textureId},
      );
    }
  }

  Future<void> dispose() async {
    if (_creatingCompleter != null) {
      await _creatingCompleter.future;
      if (!_isDisposed) {
        await _eventSubscription?.cancel();
        await _channel.invokeMethod(
          'dispose',
          <String, dynamic>{'textureId': _textureId},
        );
        _isDisposed = true;
      }
      _lifeCycleObserver.dispose();
    }

    super.dispose();
  }

  ///设置是否循环播放
  Future<void> setLoop(bool loop) async {
    value = value.copyWith(isLooping: loop);
    if (!value.initialized || _isDisposed) {
      return;
    }
    _channel.invokeMethod(
      'setLoop',
      <String, dynamic>{'textureId': _textureId, 'loop': value.isLooping},
    );
  }

  ///获取当前播放的位置
  Future<Duration> get position async {
    if (_isDisposed) {
      return null;
    }
    return Duration(
      seconds: await _channel.invokeMethod(
        'position',
        <String, dynamic>{'textureId': _textureId},
      ),
    );
  }

  ///获取可播放的时长
  Future<Duration> get playableDuration async {
    if (_isDisposed) {
      return null;
    }
    return Duration(
      seconds: await _channel.invokeMethod(
        'playableDuration',
        <String, dynamic>{'textureId': _textureId},
      ),
    );
  }

  ///获取视频宽度
  Future<Duration> get width async {
    if (_isDisposed) {
      return null;
    }
    return await _channel.invokeMethod(
      'width',
      <String, dynamic>{'textureId': _textureId},
    );
  }

  ///获取视频高度
  Future<Duration> get height async {
    if (_isDisposed) {
      return null;
    }
    return await _channel.invokeMethod(
      'height',
      <String, dynamic>{'textureId': _textureId},
    );
  }

  ///跳转位置
  Future<void> seekTo(Duration moment) async {
    if (_isDisposed) {
      return;
    }
    if (moment > value.duration) {
      moment = value.duration;
    } else if (moment < const Duration()) {
      moment = const Duration();
    }
    await _channel.invokeMethod('seekTo', <String, dynamic>{
      'textureId': _textureId,
      'position': moment.inSeconds,
    });
    value = value.copyWith(position: moment);
  }

  /// 设置画面的裁剪模式
  /// @param renderMode 裁剪
  ///
  /// 图像铺满屏幕
  /// RENDER_MODE_FILL_SCREEN
  /// 图像长边填满屏幕
  /// RENDER_MODE_FILL_EDGE
  Future<void> setRenderMode(String renderMode) async {
    if (_isDisposed) {
      return;
    }
    await _channel.invokeMethod('setRenderMode', <String, dynamic>{
      'textureId': _textureId,
      'renderMode': renderMode,
    });
    value = value.copyWith(renderMode: renderMode);
  }

  /// 设置画面的方向
  /// @param renderRotation 方向
  ///
  /// home在右边
  /// HOME_ORIENTATION_RIGHT
  /// home在下面
  /// HOME_ORIENTATION_DOWN,
  /// home在左边
  /// HOME_ORIENTATION_LEFT,
  /// home在上面
  /// HOME_ORIENTATION_UP,
  Future<void> setRenderRotation(String renderRotation) async {
    if (_isDisposed) {
      return;
    }
    await _channel.invokeMethod('setRenderRotation', <String, dynamic>{
      'textureId': _textureId,
      'renderRotation': renderRotation,
    });
    value = value.copyWith(renderRotation: renderRotation);
  }

  Future<void> setMute(bool isMute) async {
    if (_isDisposed) {
      return;
    }
    await _channel.invokeMethod('setMute', <String, dynamic>{
      'textureId': _textureId,
      'mute': isMute,
    });
    value = value.copyWith(isMute: isMute);
  }

  Future<void> setRate(double rate) async {
    if (_isDisposed) {
      return;
    }
    await _channel.invokeMethod('setRate', <String, dynamic>{
      'textureId': _textureId,
      'rate': rate,
    });
    value = value.copyWith(rate: rate);
  }

  Future<void> setMirror(bool isMirror) async {
    if (_isDisposed) {
      return;
    }
    await _channel.invokeMethod('setMirror', <String, dynamic>{
      'textureId': _textureId,
      'mirror': isMirror,
    });
    value = value.copyWith(isMirror: isMirror);
  }
}

class VideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const VideoPlayer(this.controller);

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  _VideoPlayerState() {
    _listener = () {
      final int newTextureId = widget.controller.textureId;
      if (newTextureId != _textureId) {
        setState(() {
          _textureId = newTextureId;
        });
      }
    };
  }

  VoidCallback _listener;
  int _textureId;

  @override
  void initState() {
    super.initState();
    _textureId = widget.controller.textureId;
    // Need to listen for initialization events since the actual texture ID
    // becomes available after asynchronous initialization finishes.
    widget.controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.removeListener(_listener);
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener);
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == null ? Container() : Texture(textureId: _textureId);
  }
}

/// The duration, current position, buffering state, error state and settings
/// of a [VideoPlayerController].
class VideoPlayerValue {
  VideoPlayerValue({
    @required this.duration,
    this.size,
    this.position = const Duration(),
    this.buffered = const <DurationRange>[],
    this.isPlaying = false,
    this.isLooping = false,
    this.isBuffering = false,
    this.isMute = false,
    this.isMirror = false,
    this.rate = 1,
    this.renderMode,
    this.renderRotation,
    this.volume = 1.0,
    this.errorDescription,
  });

  VideoPlayerValue.uninitialized() : this(duration: null);

  VideoPlayerValue.erroneous(String errorDescription)
      : this(duration: null, errorDescription: errorDescription);

  /// The total duration of the video.
  ///
  /// Is null when [initialized] is false.
  final Duration duration;

  /// The current playback position.
  final Duration position;

  /// The currently buffered ranges.
  final List<DurationRange> buffered;

  /// True if the video is playing. False if it's paused.
  final bool isPlaying;

  /// True if the video is looping.
  final bool isLooping;

  /// True if the video is currently buffering.
  final bool isBuffering;

  /// The current volume of the playback.
  final double volume;

  /// A description of the error if present.
  ///
  /// If [hasError] is false this is [null].
  final String errorDescription;

  /// The [size] of the currently loaded video.
  ///
  /// Is null when [initialized] is false.
  final Size size;

  final String renderMode;
  final String renderRotation;
  final bool isMute;
  final double rate;
  final bool isMirror;

  bool get initialized => duration != null;

  bool get hasError => errorDescription != null;

  double get aspectRatio => size != null ? size.width / size.height : 1.0;

  VideoPlayerValue copyWith({
    Duration duration,
    Size size,
    Duration position,
    List<DurationRange> buffered,
    bool isPlaying,
    bool isLooping,
    bool isBuffering,
    String renderMode,
    String renderRotation,
    bool isMute,
    double rate,
    double volume,
    String errorDescription,
    bool isMirror,
  }) {
    return VideoPlayerValue(
      duration: duration ?? this.duration,
      size: size ?? this.size,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      isPlaying: isPlaying ?? this.isPlaying,
      isLooping: isLooping ?? this.isLooping,
      isBuffering: isBuffering ?? this.isBuffering,
      isMute: isMute ?? this.isMute,
      isMirror: isMirror ?? this.isMirror,
      rate: rate ?? this.rate,
      renderMode: renderMode ?? this.renderMode,
      renderRotation: renderRotation ?? this.renderRotation,
      volume: volume ?? this.volume,
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'duration: $duration, '
        'size: $size, '
        'position: $position, '
        'buffered: [${buffered.join(', ')}], '
        'isPlaying: $isPlaying, '
        'isLooping: $isLooping, '
        'isBuffering: $isBuffering'
        'volume: $volume, '
        'errorDescription: $errorDescription)';
  }
}

class DurationRange {
  DurationRange(this.start, this.end);

  final Duration start;
  final Duration end;

  double startFraction(Duration duration) {
    return start.inMilliseconds / duration.inMilliseconds;
  }

  double endFraction(Duration duration) {
    return end.inMilliseconds / duration.inMilliseconds;
  }

  @override
  String toString() => '$runtimeType(start: $start, end: $end)';
}

class PlayerConfig {
  PlayerConfig(
      {this.connectRetryCount = 3,
      this.connectRetryInterval = 3,
      this.timeout = 10,
      this.cacheFolderPath,
      this.maxCacheItems = 1,
      this.progressInterval = 0.5,
      this.autoPlay = true});

  /// 自动播放
  final bool autoPlay;

  /// 播放器连接重试次数 : 最小值为 1， 最大值为 10, 默认值为 3
  final int connectRetryCount;

  /// 播放器连接重试间隔 : 单位秒，最小值为 3, 最大值为 30， 默认值为 3
  final int connectRetryInterval;

  /// 超时时间： 单位秒，默认10s
  final int timeout;

  /// 视频缓存目录，点播MP4、HLS有效
  /// 注意：缓存目录应该是单独的目录，SDK可能会清掉其中的文件
  final String cacheFolderPath;

  /// 最多缓存文件个数
  final int maxCacheItems;

  /// 设置进度回调间隔时间
  ///  若不设置，SDK默认间隔0.5秒回调一次
  final double progressInterval;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'connectRetryCount': this.connectRetryCount,
        'connectRetryInterval': this.connectRetryInterval,
        'timeout': this.timeout,
        'cacheFolderPath': this.cacheFolderPath,
        'maxCacheItems': this.maxCacheItems,
        'progressInterval': this.progressInterval,
        'autoPlay': this.autoPlay,
      };
}

/// APP生命周期监听
class _VideoAppLifeCycleObserver with WidgetsBindingObserver {
  _VideoAppLifeCycleObserver(this._controller);

  bool _wasPlayingBeforePause = false;
  final VideoPlayerController _controller;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        _wasPlayingBeforePause = _controller.value.isPlaying;
        _controller.pause();
        break;
      case AppLifecycleState.resumed:
        if (_wasPlayingBeforePause) {
          _controller.play();
        }
        break;
      default:
    }
  }
}
