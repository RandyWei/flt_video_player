//
//  FltVideoViewFactory.h
//  flt_video_player
//
//  Created by RandyWei on 2021/11/17.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
#import "FltVideoView.h"

NS_ASSUME_NONNULL_BEGIN

@interface FltVideoViewFactory : NSObject<FlutterPlatformViewFactory>
-(instancetype) initWithRegistrar:(id<FlutterPluginRegistrar>)registrar onViewCreate:(void (^)(int64_t,FltVideoView*))onViewCreate;
@end

NS_ASSUME_NONNULL_END
