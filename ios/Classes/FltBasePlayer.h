//
//  FltBasePlayer.h
//  flt_video_player
//
//  Created by RandyWei on 2021/11/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FltBasePlayer : NSObject

@property(atomic, readonly) NSNumber *playerId;
-(void)destory;
@end

NS_ASSUME_NONNULL_END
