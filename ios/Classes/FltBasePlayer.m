//
//  FltBasePlayer.m
//  flt_video_player
//
//  Created by RandyWei on 2021/11/4.
//

#import "FltBasePlayer.h"
#import <stdatomic.h>
#import <libkern/OSAtomic.h>

static atomic_int atomicId = 0;

static const int uninitialized = -1;

@implementation FltBasePlayer

-(instancetype) init{
    if (self = [super init]) {
        int pid = atomic_fetch_add(&atomicId, 1);
        _playerId = @(pid);
    }
    return self;
}


///
///开始播放
///
-(int)startPlay:(NSString*)url{
    if(_vodPlayer != nil){
        return [_vodPlayer startPlay:url];
    }
    return uninitialized;
}

///
///停止播放
///
-(BOOL)stopPlay{
    if (_vodPlayer != nil) {
        return [_vodPlayer stopPlay];
    }
    return NO;
}

///
///播放状态
///
- (BOOL) isPlaying{
    if (_vodPlayer != nil) {
        return  [_vodPlayer isPlaying];
    }
    return NO;
}


- (void) pause{
    if (_vodPlayer != nil) {
        [_vodPlayer pause];
    }
}

- (void) resume{
    if (_vodPlayer != nil) {
        [_vodPlayer resume];
    }
}

/**
 * 播放跳转到音视频流某个时间
 * @param time 流时间，单位为秒
 * @return 0 = OK
 */
-(int) seek: (float) time{
    if (_vodPlayer != nil) {
        return [_vodPlayer seek:time];
    }
    return -1;
}

-(void) setStartTime: (CGFloat) time{
    if (_vodPlayer != nil) {
        [_vodPlayer setStartTime:time];
    }
}

-(float) currentPlaybackTime {
    if (_vodPlayer != nil) {
        return [_vodPlayer currentPlaybackTime];
    }
    return 0;
}

-(float) duration {
    if (_vodPlayer != nil) {
        return [_vodPlayer duration];
    }
    return 0;
}

-(float) playableDuration {
    if (_vodPlayer != nil) {
        return [_vodPlayer playableDuration];
    }
    return 0;
}

-(void) setMute:(BOOL)bEnable {
    if (_vodPlayer != nil) {
        [_vodPlayer setMute:bEnable];
    }
}
/**
 * 设置音量大小
 * @param volume 音量大小。范围：0 ~ 100。
 */
-(void) setAudioPlayoutVolume:(int)volume {
    if (_vodPlayer != nil) {
        [_vodPlayer setAudioPlayoutVolume:volume];
    }
}

/**
 * 设置播放速率
 * @param rate 正常速度为1.0；小于为慢速；大于为快速。最大建议不超过2.0
 */
- (void)setRate:(float)rate{
    if (_vodPlayer != nil) {
        [_vodPlayer setRate:rate];
    }
}

/**
 * 设置画面镜像
 */
- (void)setMirror:(BOOL)isMirror{
    if (_vodPlayer != nil) {
        [_vodPlayer setMirror:isMirror];
    }
}

-(void)setRenderRotation: (int)rotaion{
    if (_vodPlayer != nil) {
        [_vodPlayer setRenderRotation:rotaion];
    }
}


-(void)destory{
    //停止播放
    [self stopPlay];
    
    //移除视频视图
    [_vodPlayer removeVideoWidget];
    
    _vodPlayer = nil;
    
    [_methodChannel setMethodCallHandler:nil];
    _methodChannel = nil;
    
    [_eventSink setDelegate:nil];
    _eventSink = nil;
    
    [_eventChannel setStreamHandler:nil];
    _eventChannel = nil;
    
    [_netSink setDelegate:nil];
    _netSink = nil;
    
    [_netChannel setStreamHandler:nil];
    _netChannel = nil;
}


///
///创建播放器
///
- (void)createVodPlayer:(TXVodPlayConfig*) config{
    if (_vodPlayer == nil) {
        _vodPlayer = [TXVodPlayer new];
        _vodPlayer.config = config;
        _vodPlayer.vodDelegate = self;
        _vodPlayer.enableHWAcceleration = YES;
        [_vodPlayer setVideoProcessDelegate:self];
        _vodPlayer.enableHWAcceleration = YES;
    }
}


+(NSDictionary*) getParamsWithEvent:(int)EvtId withParams:(NSDictionary*) params{
    NSMutableDictionary<NSString*,NSObject*> *dict = [NSMutableDictionary dictionaryWithObject:@(EvtId) forKey:@"event"];
    if (params != nil && params.count > 0 ) {
        [dict addEntriesFromDictionary:params];
    }
    return dict;
}

#pragma mark - TXVodPlayListener

-(void)onPlayEvent:(TXVodPlayer *)player event:(int)EvtID withParam:(NSDictionary *)param{
    [_eventSink success:[FltBasePlayer getParamsWithEvent:EvtID withParams:param]];
}

- (void)onNetStatus:(TXVodPlayer *)player withParam:(NSDictionary *)param {
    [_netSink success:param];
}


#pragma mark - Flutter Stream Handler
-(FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events{
    if ([arguments isKindOfClass:NSString.class]) {
        if ([arguments isEqualToString: @"event"]) {
            [_eventSink setDelegate:events];
        } else if ([arguments isEqualToString:@"net"]){
            [_netSink setDelegate:events];
        }
    }
    return  nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments{
    if ([arguments isKindOfClass:NSString.class]) {
        if ([arguments isEqualToString: @"event"]) {
            [_eventSink setDelegate:nil];
        } else if ([arguments isEqualToString:@"net"]){
            [_netSink setDelegate:nil];
        }
    }
    return  nil;
}




#pragma mark - Flutter Method Channel
-(void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSLog(@"method: %@",call.method);
    NSDictionary *args = call.arguments; //读取参数
    if ([@"init" isEqualToString:call.method]) {
//        BOOL onlyAudio = [args[@"onlyAudio"] boolValue];
        
        //读取 config
        
        NSDictionary *configMap = args[@"config"];
        
        TXVodPlayConfig *playerConfig = [[TXVodPlayConfig alloc]init];
        playerConfig.connectRetryCount = [configMap[@"connectRetryCount"] intValue];
        playerConfig.connectRetryInterval = [configMap[@"connectRetryInterval"] intValue];
        playerConfig.timeout = [configMap[@"timeout"] intValue];
        playerConfig.keepLastFrameWhenStop = [configMap[@"keepLastFrameWhenStop"] boolValue];
        [playerConfig setFirstStartPlayBufferTime: [configMap[@"firstStartPlayBufferTime"] intValue]];
//        playerConfig.firstStartPlayBufferTime = [configMap[@"firstStartPlayBufferTime"] intValue];
        [playerConfig setNextStartPlayBufferTime:[configMap[@"nextStartPlayBufferTime"] intValue]];
//        playerConfig.nextStartPlayBufferTime = [configMap[@"nextStartPlayBufferTime"] intValue];
        
        NSString *cacheFolderPath = [configMap[@"cacheFolderPath"] stringValue];
        if (cacheFolderPath != nil && cacheFolderPath.length > 0) {
            playerConfig.cacheFolderPath = cacheFolderPath;
        }
        
        playerConfig.maxCacheItems = [configMap[@"maxCacheItems"] intValue];
        playerConfig.headers = configMap[@"headers"];
        
        playerConfig.enableAccurateSeek = [configMap[@"enableAccurateSeek"] boolValue];
        playerConfig.progressInterval = [configMap[@"progressInterval"] doubleValue];
        playerConfig.maxBufferSize = [configMap[@"maxBufferSize"] intValue];
        
        NSString *overlayKey = [configMap[@"overlayKey"] stringValue];
        
        if (overlayKey != nil && overlayKey.length > 0) {
//            playerConfig.overlayKey = overlayKey;
            [playerConfig setOverlayKey:overlayKey];
        }
        
        NSString *overlayIv = [configMap[@"overlayIv"] stringValue];
        
        if (overlayIv != nil && overlayIv.length > 0) {
//            playerConfig.overlayIv = overlayIv;
            [playerConfig setOverlayIv:overlayIv];
        }
        
        [self createVodPlayer:playerConfig];
        NSNumber *textureId = [NSNumber numberWithLongLong:_textureId];
        result(textureId);
    } else if ([@"play" isEqualToString:call.method]) {
        NSString *url = args[@"url"];
        int r = [self startPlay:url];
        result(@(r));
    } else if ([@"stop" isEqualToString:call.method]){
        BOOL r = [self stopPlay];
        result([NSNumber numberWithBool:r]);
    } else if ([@"isPlaying" isEqualToString:call.method]){
        result([NSNumber numberWithBool:[self isPlaying]]);
    } else if ([@"pause" isEqualToString:call.method]) {
        [self pause];
        result(nil);
    } else if ([@"resume" isEqualToString:call.method]){
        [self resume];
        result(nil);
    } else if ([@"seek" isEqualToString:call.method]){
        float time = [args[@"time"] intValue];
        BOOL r = [self seek:time];
        result([NSNumber numberWithBool:r]);
    } else if ([@"setStartTime" isEqualToString:call.method]){
        float time = [args[@"time"] floatValue];
        [self setStartTime:time];
        result(nil);
    } else if([@"currentPlaybackTime" isEqualToString:call.method]){
        result(@([self currentPlaybackTime]));
    } else if ([@"duration" isEqualToString:call.method]){
        result(@([self duration]));
    } else if ([@"playableDuration" isEqualToString:call.method]){
        result(@([self playableDuration]));
    } else if ([@"setMute" isEqualToString:call.method]){
        BOOL enable = [args[@"enable"] boolValue];
        [self setMute:enable];
        result(nil);
    } else if([@"setAudioPlayoutVolume" isEqualToString:call.method]){
        int volume = [args[@"volume"] intValue];
        volume = MAX(0, volume);
        volume = MIN(100, volume);
        [self setAudioPlayoutVolume:volume];
        result(nil);
    } else if ([@"setRate" isEqualToString:call.method]){
        int rate = [args[@"rate"] floatValue];
        [self setRate:rate];
        result(nil);
    } else if([@"setMirror" isEqualToString:call.method]){
        BOOL mirror = [args[@"mirror"] boolValue];
        [self setMirror:mirror];
        result(nil);
    } else if([@"setLoop" isEqualToString:call.method]){
        if (_vodPlayer != nil) {
            BOOL loop = [args[@"loop"] boolValue];
            [_vodPlayer setLoop:loop];
        }
        result(nil);
    } else if([@"setRenderRotation" isEqualToString:call.method]){
        BOOL rotation = [args[@"rotation"] intValue];
        [self setRenderRotation:rotation];
        result(nil);
    }
}

@end
