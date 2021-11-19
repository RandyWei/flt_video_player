//
//  FltBasePlayer.h
//  flt_video_player
//
//  Created by RandyWei on 2021/11/4.
//

#import <Foundation/Foundation.h>
#import <TXLiteAVSDK_Player/TXLiteAVSDK.h>
#import <Flutter/Flutter.h>
#import "EventSinkQueue.h"

NS_ASSUME_NONNULL_BEGIN

@interface FltBasePlayer : NSObject<FlutterStreamHandler,TXVodPlayListener,TXVideoCustomProcessDelegate>{
    @protected
    TXVodPlayer *_vodPlayer;
    
    @protected
    int64_t _textureId;
    
    
    
    //通信通道
    @protected
    FlutterMethodChannel *_methodChannel;
    
    //播放事件回调通信通道
    @protected
    EventSinkQueue *_eventSink;
    @protected
    FlutterEventChannel *_eventChannel;
    
    //网络回调通信通道
    @protected
    EventSinkQueue *_netSink;
    @protected
    FlutterEventChannel *_netChannel;
}

@property(atomic, readonly) NSNumber *playerId;

-(void)destory;


///
///开始播放
///
-(int)startPlay:(NSString*)url;

///
///停止播放
///
-(BOOL)stopPlay;

///
///播放状态
///
- (BOOL) isPlaying;


- (void) pause;

- (void) resume;

/**
 * 播放跳转到音视频流某个时间
 * @param time 流时间，单位为秒
 * @return 0 = OK
 */
-(int) seek: (float) time;

-(float) currentPlaybackTime;

-(float) duration;

-(float) playableDuration;

-(void) setMute:(BOOL)bEnable;
/**
 * 设置音量大小
 * @param volume 音量大小。范围：0 ~ 100。
 */
-(void) setAudioPlayoutVolume:(int)volume;

/**
 * 设置播放速率
 * @param rate 正常速度为1.0；小于为慢速；大于为快速。最大建议不超过2.0
 */
- (void)setRate:(float)rate;

/**
 * 设置画面镜像
 */
- (void)setMirror:(BOOL)isMirror;

- (void)setRenderRotation: (int)rotaion;

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

- (void)createVodPlayer:(TXVodPlayConfig*) config;

@end

NS_ASSUME_NONNULL_END
