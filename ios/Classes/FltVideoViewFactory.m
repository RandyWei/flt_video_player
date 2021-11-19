//
//  FltVideoViewFactory.m
//  flt_video_player
//
//  Created by RandyWei on 2021/11/17.
//

#import "FltVideoViewFactory.h"


@implementation FltVideoViewFactory{
    id<FlutterPluginRegistrar> _registrar;
    void (^_onViewCreate)(int64_t,FltVideoView*);
}

-(instancetype) initWithRegistrar:(id<FlutterPluginRegistrar>)registrar onViewCreate:(void (^)(int64_t,FltVideoView*))onViewCreate{
    if (self = [super init]) {
        _registrar = registrar;
        _onViewCreate = onViewCreate;
    }
    return self;
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec{
    return FlutterStandardMessageCodec.sharedInstance;
}

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(id _Nullable)args {
    FltVideoView *videoView = [[FltVideoView alloc]initWithRegistrar:_registrar viewId:viewId];
    _onViewCreate(viewId,videoView);
    return videoView;
}

@end
