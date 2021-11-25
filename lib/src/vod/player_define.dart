///
/// Created by wei on 2021/11/5.<br/>
///

class PlayerValue {
  final PlayerState state;

  double duration = 0;
  double progress = 0;

  PlayerValue.uninitialized() : this(state: PlayerState.stopped);

  PlayerValue({required this.state});

  PlayerValue copyWith({PlayerState? state}) {
    return PlayerValue(state: state ?? this.state);
  }
}

enum PlayerState {
  paused, // 暂停播放
  failed, // 播放失败
  buffering, // 缓冲中
  playing, // 播放中
  stopped, // 停止播放
  disposed // 控件释放了
}

enum RenderRotation {
  homeOrientaionRight, //< HOME 键在右边，横屏模式
  homeOrientationDown, //< HOME 键在下面，手机直播中最常见的竖屏直播模式
  homeOrientationLeft, //< HOME 键在左边，横屏模式
  homeOrientationUp, //< HOME 键在上边，竖屏直播（适合小米 MIX2）
}

///
/// 渲染糊弄
///
enum RenderType {
  texture, //外接纹理
  platformView
}
