//
//  FltVodPlayer.h
//  flt_video_player
//
//  Created by RandyWei on 2021/11/4.
//


#import <Foundation/Foundation.h>
#import "FltBasePlayer.h"

@protocol FlutterPluginRegistrar;

NS_ASSUME_NONNULL_BEGIN

@interface FltVodPlayer : FltBasePlayer

-(instancetype) initWithRegistrar:(id<FlutterPluginRegistrar>)registrar;

@end

NS_ASSUME_NONNULL_END
