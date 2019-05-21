#import "FltVideoPlayerPlugin.h"
#import "FLTVideoPlayer.h"
#import "FLTFrameUpdater.h"
#import "ExceptionHandler.h"

@interface FltVideoPlayerPlugin()
@property(readonly, nonatomic) NSObject<FlutterTextureRegistry>* registry;
@property(readonly, nonatomic) NSObject<FlutterBinaryMessenger>* messenger;
@property(readonly, nonatomic) NSMutableDictionary* players;
@property(readonly, nonatomic) NSObject<FlutterPluginRegistrar>* registrar;
@end

@implementation FltVideoPlayerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    //异常捕获
    InstallUncaughtExceptionHandler().getLogPathBlock(^(NSString *path) {
        NSLog(@"异常捕获文件路径 %@", path);
    });
    
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"bughub.dev/flutterVideoPlayer"
            binaryMessenger:[registrar messenger]];
  FltVideoPlayerPlugin* instance = [[FltVideoPlayerPlugin alloc] initWithRegistrar:registrar];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    self = [super init];
    NSAssert(self, @"super init cannot be nil");
    _registry = [registrar textures];
    _messenger = [registrar messenger];
    _registrar = registrar;
    _players = [NSMutableDictionary dictionaryWithCapacity:1];
    return self;
}

- (void)onPlayerSetup:(FLTVideoPlayer*)player
         frameUpdater:(FLTFrameUpdater*)frameUpdater
               result:(FlutterResult)result {
    
    int64_t textureId = [_registry registerTexture:player];
    frameUpdater.textureId = textureId;
    
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                         eventChannelWithName:[NSString stringWithFormat:@"bughub.dev/flutterVideoPlayer/videoEvents%lld",
                                                               textureId]
                                         binaryMessenger:_messenger];
    
    [eventChannel setStreamHandler:player];
    
    player.eventChannel = eventChannel;
    
    _players[@(textureId)] = player;
    result(@{@"textureId" : @(textureId)});
    
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"init" isEqualToString:call.method]) {
        // Allow audio playback when the Ring/Silent switch is set to silent
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        
        for (NSNumber* textureId in _players) {
            [_registry unregisterTexture:[textureId unsignedIntegerValue]];
            [[_players objectForKey:textureId] dispose];
        }
        [_players removeAllObjects];
        result(nil);
    } else if ([@"create" isEqualToString:call.method]) {
        NSDictionary* argsMap = call.arguments;
        NSLog(@"%@",argsMap);
        FLTFrameUpdater* frameUpdater = [[FLTFrameUpdater alloc] initWithRegistry:_registry];
        
        NSString* pathArg = argsMap[@"path"];
        NSDictionary* playConfigArg = argsMap[@"playerConfig"];
        
        int connectRetryCount = [playConfigArg[@"connectRetryCount"] intValue];
        
        int connectRetryInterval = [playConfigArg[@"connectRetryInterval"] intValue];
        
        int timeout = [playConfigArg[@"timeout"] intValue];
        
        id cacheFolderPath = playConfigArg[@"cacheFolderPath"];
        
        int maxCacheItems = [playConfigArg[@"maxCacheItems"] intValue];
        
        float progressInterval = [playConfigArg[@"progressInterval"] floatValue];
        
        TXVodPlayConfig* playConfig = [[TXVodPlayConfig alloc]init];
        playConfig.connectRetryCount=connectRetryCount;
        playConfig.connectRetryInterval = connectRetryInterval;
        playConfig.timeout = timeout;
        if (cacheFolderPath!=nil&&cacheFolderPath!=NULL&&![@"" isEqualToString:cacheFolderPath]&&cacheFolderPath!=[NSNull null]) {
            playConfig.cacheFolderPath = cacheFolderPath;
        }
        playConfig.maxCacheItems = maxCacheItems;
        playConfig.progressInterval = progressInterval;
        
        BOOL autoPlayArg = [playConfigArg[@"autoPlay"] boolValue];
        
        int startPosition = [argsMap[@"startPosition"] intValue];
        FLTVideoPlayer* player;
        if (pathArg) {
            player = [[FLTVideoPlayer alloc] initWithPath:pathArg autoPlay:autoPlayArg startPosition:startPosition playConfig:playConfig frameUpdater:frameUpdater];
            if (player) {
                [self onPlayerSetup:player frameUpdater:frameUpdater result:result];
            }
            result(nil);
        } else {
            result(FlutterMethodNotImplemented);
        }
    } else {
        NSDictionary* argsMap = call.arguments;
        int64_t textureId = ((NSNumber*)argsMap[@"textureId"]).unsignedIntegerValue;
        FLTVideoPlayer* player = _players[@(textureId)];
        if ([@"dispose" isEqualToString:call.method]) {
            [_registry unregisterTexture:textureId];
            [_players removeObjectForKey:@(textureId)];
            [player dispose];
            result(nil);
        }else if ([@"setLoop" isEqualToString:call.method]){
            [player setLoop:[[argsMap objectForKey:@"loop"] boolValue]];
            result(nil);
        }else if ([@"play" isEqualToString:call.method]){
            [player resume];
            result(nil);
        }else if ([@"position" isEqualToString:call.method]){
            result(@([player position]));
        }else if ([@"seekTo" isEqualToString:call.method]){
            [player seekTo:[[argsMap objectForKey:@"position"] intValue]];
            result(nil);
        }else if ([@"pause" isEqualToString:call.method]){
            [player pause];
            result(nil);
        }else if ([@"playableDuration" isEqualToString:call.method]){
            result(@([player playableDuration]));
        }else if ([@"width" isEqualToString:call.method]){
            result(@([player width]));
        }else if ([@"height" isEqualToString:call.method]){
            result(@([player height]));
        }else if ([@"setRenderMode" isEqualToString:call.method]){
            /// 图像铺满屏幕
            /// RENDER_MODE_FILL_SCREEN  = 0,
            /// 图像长边填满屏幕
            /// RENDER_MODE_FILL_EDGE
            NSString* renderMode = [argsMap objectForKey:@"renderMode"];
            if ([@"RENDER_MODE_FILL_SCREEN" isEqualToString:renderMode]) {
                [player setRenderMode:RENDER_MODE_FILL_SCREEN];
            }else if ([@"RENDER_MODE_FILL_EDGE" isEqualToString:renderMode]){
                [player setRenderMode:RENDER_MODE_FILL_EDGE];
            }
            
            result(nil);
        }else if ([@"setRenderRotation" isEqualToString:call.method]){
            /// home在右边
            /// HOME_ORIENTATION_RIGHT  = 0,
            /// home在下面
            /// HOME_ORIENTATION_DOWN,
            /// home在左边
            /// HOME_ORIENTATION_LEFT,
            /// home在上面
            /// HOME_ORIENTATION_UP,
            NSString* renderRotation = [argsMap objectForKey:@"renderRotation"];
            if ([@"HOME_ORIENTATION_RIGHT" isEqualToString:renderRotation]) {
                [player setRenderRotation:HOME_ORIENTATION_RIGHT];
            }else if ([@"HOME_ORIENTATION_DOWN" isEqualToString:renderRotation]){
                [player setRenderRotation:HOME_ORIENTATION_DOWN];
            }else if ([@"HOME_ORIENTATION_LEFT" isEqualToString:renderRotation]){
                [player setRenderRotation:HOME_ORIENTATION_LEFT];
            }else if ([@"HOME_ORIENTATION_UP" isEqualToString:renderRotation]){
                [player setRenderRotation:HOME_ORIENTATION_UP];
            }
            
            result(nil);
        }else if ([@"setMute" isEqualToString:call.method]){
            [player setMute:[[argsMap objectForKey:@"mute"] boolValue]];
            result(nil);
        }else if ([@"setRate" isEqualToString:call.method]){
            float rate = [[argsMap objectForKey:@"rate"] floatValue];
            
            if (rate<0||rate>2) {
                result(nil);
                return;
            }
            
            [player setRate:rate];
            
            result(nil);
        }else if ([@"setMirror" isEqualToString:call.method]){
            [player setMirror:[[argsMap objectForKey:@"mirror"] boolValue]];
            result(nil);
        }
        else{
            result(FlutterMethodNotImplemented);
        }
    }
}

@end
