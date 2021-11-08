//
//  FltVodPlayer.m
//  flt_video_player
//
//  Created by RandyWei on 2021/11/4.
//

#import "FltVodPlayer.h"
#import <TXLiteAVSDK_Player/TXLiteAVSDK.h>
#import <Flutter/Flutter.h>
#import <stdatomic.h>
#import <libkern/OSAtomic.h>
#import "EventSinkQueue.h"

static const int uninitialized = -1;

@interface FltVodPlayer()<FlutterStreamHandler,FlutterTexture,TXVodPlayListener,TXVideoCustomProcessDelegate>

@end


@implementation FltVodPlayer{
    TXVodPlayer *_vodPlayer;
    
    //最新一帧
    CVPixelBufferRef volatile _latestPixelBuffer;
    //旧的一帧
    CVPixelBufferRef _lastBuffer;
    
    int64_t _textureId;
    
    id<FlutterPluginRegistrar> _registrar;
    id<FlutterTextureRegistry> _textureRegistry;
    
    //通信通道
    FlutterMethodChannel *_methodChannel;
    
    //播放事件回调通信通道
    EventSinkQueue *_eventSink;
    FlutterEventChannel *_eventChannel;
    
    //网络回调通信通道
    EventSinkQueue *_netSink;
    FlutterEventChannel *_netChannel;
}


-(instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar{
    if (self = [self init]) {
        _registrar = registrar;
        _lastBuffer = nil;
        _latestPixelBuffer = nil;
        _textureId = -1;
        
        _eventSink = [EventSinkQueue new];
        _netSink = [EventSinkQueue new];
        
        __weak typeof(self) weakSelf = self;
        
        _methodChannel = [FlutterMethodChannel methodChannelWithName:[@"plugins.bughub.icu/vodplayer/" stringByAppendingString:[self.playerId stringValue]] binaryMessenger:[registrar messenger]];
        [_methodChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
                    [weakSelf handleMethodCall: call result:result];
        }];
        
        _eventChannel = [FlutterEventChannel eventChannelWithName:[@"plugins.bughub.icu/vodplayer/event/" stringByAppendingString:[self.playerId stringValue]] binaryMessenger:[registrar messenger]];
        [_eventChannel setStreamHandler:self];
        
        _netChannel = [FlutterEventChannel eventChannelWithName:[@"plugins.bughub.icu/vodplayer/net/" stringByAppendingString:[self.playerId stringValue]] binaryMessenger:[registrar messenger]];
        [_netChannel setStreamHandler:self];
        
    }
    
    return  self;
}

-(void)destory{
    
    NSLog(@"destory");
    
    //停止播放
    [self stopPlay];
    //移除视频视图
    [_vodPlayer removeVideoWidget];
    
    _vodPlayer = nil;
    
    if (_textureId >= 0) {
        [_textureRegistry unregisterTexture:_textureId];
        _textureId = -1;
        _textureRegistry = nil;
    }
    
    CVPixelBufferRef old = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(old, nil, (void **)&_latestPixelBuffer)) {
        old = _latestPixelBuffer;
    }
    
    if (old) {
        CFRelease(old);
    }
    
    if (_lastBuffer) {
        CVPixelBufferRelease(_lastBuffer);
        _lastBuffer = nil;
    }
    
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
- (NSNumber*)createVodPlayer:(BOOL)onlyAudio config:(TXVodPlayConfig*) config{
    if (_vodPlayer == nil) {
        _vodPlayer = [TXVodPlayer new];
        _vodPlayer.config = config;
        _vodPlayer.vodDelegate = self;
        _vodPlayer.enableHWAcceleration = YES;
        [self setupPlayer:onlyAudio];
    }
    
    return [NSNumber numberWithLongLong:_textureId];
}

///
///配置播放器
///
- (void)setupPlayer:(BOOL)onlyAudio{
    if (_textureId < 0) {
        _textureRegistry = [_registrar textures];
        int64_t tId = [_textureRegistry registerTexture:self];
        _textureId = tId;
    }
    
    if (_vodPlayer != nil) {
        [_vodPlayer setVideoProcessDelegate:self];
        _vodPlayer.enableHWAcceleration = YES;
    }
}

///
///开始播放
///
-(int)startPlay:(NSString*)url{
    NSLog(@"startPlay_vodPlayer:%@",_vodPlayer);
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

+(NSDictionary*) getParamsWithEvent:(int)EvtId withParams:(NSDictionary*) params{
    NSMutableDictionary<NSString*,NSObject*> *dict = [NSMutableDictionary dictionaryWithObject:@(EvtId) forKey:@"event"];
    if (params != nil && params.count > 0 ) {
        [dict addEntriesFromDictionary:params];
    }
    return dict;
}

#pragma mark - TXVodPlayListener

-(void)onPlayEvent:(TXVodPlayer *)player event:(int)EvtID withParam:(NSDictionary *)param{
    [_eventSink success:[FltVodPlayer getParamsWithEvent:EvtID withParams:param]];
}

- (void)onNetStatus:(TXVodPlayer *)player withParam:(NSDictionary *)param {
    [_netSink success:param];
}


#pragma mark - Flutter Method Channel
-(void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result{
    NSDictionary *args = call.arguments; //读取参数
    if ([@"init" isEqualToString:call.method]) {
        BOOL onlyAudio = [args[@"onlyAudio"] boolValue];
        
        //读取 config
        
        NSDictionary *configMap = args[@"config"];
        
        TXVodPlayConfig *playerConfig = [[TXVodPlayConfig alloc]init];
        playerConfig.connectRetryCount = [configMap[@"connectRetryCount"] intValue];
        playerConfig.connectRetryInterval = [configMap[@"connectRetryInterval"] intValue];
        playerConfig.timeout = [configMap[@"timeout"] intValue];
        playerConfig.keepLastFrameWhenStop = [configMap[@"keepLastFrameWhenStop"] boolValue];
        playerConfig.firstStartPlayBufferTime = [configMap[@"firstStartPlayBufferTime"] intValue];
        playerConfig.nextStartPlayBufferTime = [configMap[@"nextStartPlayBufferTime"] intValue];
        
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
            playerConfig.overlayKey = overlayKey;
        }
        
        NSString *overlayIv = [configMap[@"overlayIv"] stringValue];
        
        if (overlayIv != nil && overlayIv.length > 0) {
            playerConfig.overlayIv = overlayIv;
        }
        
        
        NSNumber *textureId = [self createVodPlayer:onlyAudio config:playerConfig];
        result(textureId);
    } else if ([@"play" isEqualToString:call.method]) {
        NSString *url = args[@"url"];
        int r = [self startPlay:url];
        result(@(r));
    }
}


#pragma mark - FlutterTexture
- (CVPixelBufferRef _Nullable)copyPixelBuffer{
    CVPixelBufferRef pixelBuffer = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil, (void **)&_latestPixelBuffer)) {
        pixelBuffer = _latestPixelBuffer;
    }
    return pixelBuffer;
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

#pragma mark - TxVideoCustomProcessDelegate

- (BOOL)onPlayerPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    if (_lastBuffer == nil) {
        _lastBuffer = CVPixelBufferRetain(pixelBuffer);
        CFRetain(pixelBuffer);
    } else if (_lastBuffer != pixelBuffer) {
        CVPixelBufferRelease(_lastBuffer);
        _lastBuffer = CVPixelBufferRetain(pixelBuffer);
        CFRetain(pixelBuffer);
    }
    
    CVPixelBufferRef newBuffer = pixelBuffer;
    
    CVPixelBufferRef old = _latestPixelBuffer;
    
    while (!OSAtomicCompareAndSwapPtrBarrier(old, newBuffer, (void **)&_latestPixelBuffer)) {
        old = _latestPixelBuffer;
    }
    
    if (old && old != pixelBuffer) {
        CFRelease(old);
    }
    
    if (_textureId >= 0) {
        [_textureRegistry textureFrameAvailable:_textureId];
    }
    
    return  NO;
}

@end
