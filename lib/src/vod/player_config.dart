///
/// Created by wei on 2021/11/5.<br/>
///
class PlayerConfig {
  /// 播放器连接重试次数：最小值为1，最大值为10，默认值为 3
  int connectRetryCount = 3;

  /// 播放器连接重试间隔：单位秒，最小值为3, 最大值为30，默认值为3
  int connectRetryInterval = 3;

  /// 超时时间：单位秒，默认10s
  int timeout = 10;

  /// stopPlay 的时候是否保留最后一帧画面，默认值为 NO
  bool keepLastFrameWhenStop = false;

  /// 首缓需要加载的数据时长，单位ms,   默认值为100ms
  int firstStartPlayBufferTime = 100;

  /// 缓冲时（缓冲数据不够引起的二次缓冲，或者seek引起的拖动缓冲）最少要缓存多长的数据才能结束缓冲，单位ms，默认值为250ms
  int nextStartPlayBufferTime = 250;

  /// 注意：缓存目录应该是单独的目录，SDK可能会清掉其中的文件
  ///< 视频缓存目录，点播MP4、HLS有效
  String cacheFolderPath = "";

  ///< 最多缓存文件个数
  int maxCacheItems = 0;

  ///< 自定义 HTTP Headers
  Map<String, dynamic> headers = {};

  ///< 是否精确 seek，默认YES。开启精确后seek，seek 的时间平均多出200ms
  bool enableAccurateSeek = true;

  /// 设置进度回调间隔时间
  ///  若不设置，SDK默认间隔0.5秒回调一次
  double progressInterval = 0.5;

  /// 最大预加载大小，单位 MB
  ///  此设置会影响playableDuration，设置越大，提前缓存的越多
  int maxBufferSize = 0;

  /// HLS EXT-X-KEY 加密key
  String overlayKey = "";

  /// HLS EXT-X-KEY 加密Iv
  String overlayIv = "";

  Map<String, dynamic> toJson() => <String, dynamic>{
        'connectRetryCount': connectRetryCount,
        'connectRetryInterval': connectRetryInterval,
        'timeout': timeout,
        'keepLastFrameWhenStop': keepLastFrameWhenStop,
        'firstStartPlayBufferTime': firstStartPlayBufferTime,
        'nextStartPlayBufferTime': nextStartPlayBufferTime,
        'cacheFolderPath': cacheFolderPath,
        'maxCacheItems': maxCacheItems,
        'headers': headers,
        'enableAccurateSeek': enableAccurateSeek,
        'progressInterval': progressInterval,
        'maxBufferSize': maxBufferSize,
        'overlayKey': overlayKey,
        'overlayIv': overlayIv
      };
}
