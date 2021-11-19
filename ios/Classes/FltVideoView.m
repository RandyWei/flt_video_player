//
//  FltVideoView.m
//  flt_video_player
//
//  Created by RandyWei on 2021/11/17.
//

#import "FltVideoView.h"
#import <TXLiteAVSDK_Player/TXLiteAVSDK.h>

@interface FltVideoView()

@end

@implementation FltVideoView{
    UIView *videoView;
}

-(instancetype)initWithRegistrar:(id<FlutterPluginRegistrar>)registrar viewId:(int64_t)viewId{
    NSLog(@"initWithRegistrar");
    if (self = [super init]) {
        videoView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 1, 1)];
        
        _eventSink = [EventSinkQueue new];
        _netSink = [EventSinkQueue new];
        
        __weak typeof(self) weakSelf = self;
        
        _methodChannel = [FlutterMethodChannel methodChannelWithName:[NSString stringWithFormat:@"plugins.bughub.icu/vodplayer/%lld",viewId] binaryMessenger:[registrar messenger]];
        [_methodChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
            [weakSelf handleMethodCall: call result:result];
        }];

        _eventChannel = [FlutterEventChannel eventChannelWithName:[@"plugins.bughub.icu/vodplayer/event/" stringByAppendingString:[NSString stringWithFormat:@"%lld",viewId]] binaryMessenger:[registrar messenger]];
        [_eventChannel setStreamHandler:self];

        _netChannel = [FlutterEventChannel eventChannelWithName:[@"plugins.bughub.icu/vodplayer/net/" stringByAppendingString:[NSString stringWithFormat:@"%lld",viewId]] binaryMessenger:[registrar messenger]];
        [_netChannel setStreamHandler:self];
        
    }
    return self;
}

- (void)createVodPlayer:(TXVodPlayConfig *)config{
    [super createVodPlayer:config];
    [_vodPlayer setupVideoWidget:videoView insertIndex:0];
    
}

- (nonnull UIView *)view {
    return videoView;
}


@end
