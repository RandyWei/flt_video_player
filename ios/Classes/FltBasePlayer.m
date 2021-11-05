//
//  FltBasePlayer.m
//  flt_video_player
//
//  Created by RandyWei on 2021/11/4.
//

#import "FltBasePlayer.h"
#import <stdatomic.h>
#import <libkern/OSAtomic.h>

static atomic_int atomicId = 0;

@implementation FltBasePlayer

-(instancetype) init{
    if (self = [super init]) {
        int pid = atomic_fetch_add(&atomicId, 1);
        _playerId = @(pid);
    }
    return self;
}

-(void)destory{
    
}

@end
