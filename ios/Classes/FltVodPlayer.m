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


@interface FltVodPlayer()<FlutterTexture>

@end


@implementation FltVodPlayer{
    
    //最新一帧
    CVPixelBufferRef volatile _latestPixelBuffer;
    //旧的一帧
    CVPixelBufferRef _lastBuffer;
    
    id<FlutterPluginRegistrar> _registrar;
    id<FlutterTextureRegistry> _textureRegistry;
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
    [super destory];
    
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
}


-(void)createVodPlayer:(TXVodPlayConfig*) config{
    [super createVodPlayer:config];
    [self setupTexture];
}
///
///配置播放器
///
- (void)setupTexture{
    if (_textureId < 0) {
        _textureRegistry = [_registrar textures];
        int64_t tId = [_textureRegistry registerTexture:self];
        _textureId = tId;
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
