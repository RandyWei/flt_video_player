//
//  FltVideoView.h
//  flt_video_player
//
//  Created by RandyWei on 2021/11/17.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "FltBasePlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface FltVideoView : FltBasePlayer<FlutterPlatformView>

-(instancetype) initWithRegistrar:(id<FlutterPluginRegistrar>)registrar viewId:(int64_t)viewId;

@end

NS_ASSUME_NONNULL_END
