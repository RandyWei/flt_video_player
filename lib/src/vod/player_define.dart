///
/// Created by wei on 2021/11/5.<br/>
///

class PlayerValue {
  final PlayerState state;

  PlayerValue.uninitialized() :this(state: PlayerState.stopped);

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
