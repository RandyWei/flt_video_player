#import "FltVideoPlayerPlugin.h"
#import "FltVodPlayer.h"
#import "FltVideoViewFactory.h"


@interface FltVideoPlayerPlugin()

@property (nonatomic,strong) NSObject<FlutterPluginRegistrar>* registrar; //存储 flutter registrar
@property (nonatomic,strong) NSMutableDictionary *players; //存储播放器对象，可能有多个

@end

@implementation FltVideoPlayerPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                   methodChannelWithName:@"plugins.bughub.icu/flt_video_player"
            binaryMessenger:[registrar messenger]];
    
    FltVideoPlayerPlugin* instance = [[FltVideoPlayerPlugin alloc] initWithRegistrar:registrar];
    
    [registrar addMethodCallDelegate:instance channel:channel];
    
    [registrar registerViewFactory:[[FltVideoViewFactory alloc]initWithRegistrar:registrar onViewCreate:^(int64_t viewId,FltBasePlayer *player)  {
        [[instance players] setValue:player forKey:[NSString stringWithFormat:@"%lld",viewId]];
    }] withId:@"FltVideoView"];
}

- (instancetype) initWithRegistrar: (NSObject<FlutterPluginRegistrar> *) registrar{
    self = [super init];
    if (self) {
        _registrar = registrar;
        _players = @{}.mutableCopy;
    }
    return self;
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ( [@"createVodPlayer" isEqualToString:call.method] ) { //初始化 vod player
      FltVodPlayer *vodPlayer = [[FltVodPlayer alloc]initWithRegistrar:self.registrar];
      NSNumber *playerId = vodPlayer.playerId;
      _players[[playerId stringValue]] = vodPlayer;
      result(playerId);
  } else if ([@"releaseVodPlayer" isEqualToString:call.method] ) {
      NSDictionary *args = call.arguments;
      NSNumber *playerId = args[@"playerId"];
      FltBasePlayer *player = [_players objectForKey:[playerId stringValue]];
      [player destory];
      if (player != nil) {
          [_players removeObjectForKey:playerId];
      }
  }
  
  else {
    result(FlutterMethodNotImplemented);
  }
}

@end
