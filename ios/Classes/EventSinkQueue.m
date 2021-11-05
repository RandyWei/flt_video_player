//
//  EventSinkQueue.m
//  flt_video_player
//
//  Created by RandyWei on 2021/11/5.
//

#import "EventSinkQueue.h"

@interface EventSinkQueue()

@property (nonatomic,strong) NSMutableArray *eventQueue;
@property (nonatomic, copy) FlutterEventSink eventSink;

@end

@implementation EventSinkQueue

- (void)success:(NSObject *)event{
    [self enqueue:event];
    [self flushIfNeed];
}

- (void)setDelegate:(FlutterEventSink)sink{
    self.eventSink = sink;
}

- (void)error:(NSString *)code message:(NSString *)message details:(id)details{
    [self enqueue:[FlutterError errorWithCode:code message:message details:details]];
    [self flushIfNeed];
}

-(instancetype)init{
    if (self = [super init]) {
        _eventQueue = @[].mutableCopy;
    }
    return self;
}

-(void)flushIfNeed{
    if (self.eventSink == nil) {
        return;
    }
    
    for (NSObject *obj in self.eventQueue) {
        self.eventSink(obj);
    }
    [self.eventQueue removeAllObjects];
}

-(void)enqueue:(NSObject*) event{
    [self.eventQueue addObject:event];
}

@end
