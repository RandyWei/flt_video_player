//
//  RXExceptionHandler.m
//  ExceptionHandler_OC
//
//  Created by Apple on 2018/5/22.
//  Copyright © 2018年 Apple. All rights reserved.
//

#import "ExceptionHandler.h"
#import <UIKit/UIKit.h>
#include <libkern/OSAtomic.h>
#include <execinfo.h>

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

const NSInteger ExceptionHandlerSkipAddressCount = 4;
const NSInteger ExceptionHandlerReportAddressCount = 5;

@implementation RXExceptionHandler

+ (instancetype)shareInstance{
    static RXExceptionHandler *manager = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        manager = [[self alloc] init];
        [manager configLog];
    });
    return manager;
}

#pragma mark - 设置日志存取的路径
- (void)configLog {
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filePath = [docPath stringByAppendingPathComponent:@"ExceptionHandlerLog.log"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:filePath]) {
        [fileManager createFileAtPath:filePath contents:[@"程序异常日志" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    }
    self.logFilePath = filePath;
}

- (void)saveLogData:(NSException *)exception {
    NSString *exceptionMessage = [NSString stringWithFormat:NSLocalizedString(@"\n\n%@\n异常原因:\n%@\n%@\n%@", nil), [self currentTimeString], [exception name], [exception reason], [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]];
    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:self.logFilePath];
    [handle seekToEndOfFile];
    [handle writeData:[exceptionMessage dataUsingEncoding:NSUTF8StringEncoding]];
    [handle closeFile];
    if(self.pathBlock){
        self.pathBlock(self.logFilePath);
    }
}
- (NSString *)currentTimeString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *currentDateStr = [dateFormatter stringFromDate:[NSDate date]];
    return currentDateStr;
}

- (RXExceptionHandler *(^)(void (^ logPathBlock)(NSString *path)))getLogPathBlock {
    return ^(void(^ logPathBlock)(NSString *path)) {
        self.pathBlock = logPathBlock;
        return [RXExceptionHandler shareInstance];
    };
}

+ (NSArray *)backtrace {
    void *callStack[128]; // 堆栈方法数组
    int frames = backtrace(callStack, 128); // 从 iOS 的方法 backtrace 中获取错误堆栈方法指针数组，返回数目
    char ** strs = backtrace_symbols(callStack, frames); // 符号化
    
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (i=ExceptionHandlerSkipAddressCount; i < ExceptionHandlerSkipAddressCount +
         ExceptionHandlerReportAddressCount; i++) {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    return backtrace;
}

- (void)handleException:(NSException *)exception {
    [self saveLogData:exception];
    
    NSString *message = [NSString stringWithFormat:@"如果点击继续，程序有可能会出现其他问题，建议点击退出按钮并重新打开\n\n异常报告:\n异常名称:%@\n异常原因:%@\n其他信息:%@\n", exception.name, exception.reason, exception.userInfo[UncaughtExceptionHandlerAddressesKey]];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"抱歉，程序出现了异常" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *exit = [UIAlertAction actionWithTitle:@"退出" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        self->dismissed = YES;
    }];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"继续" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self->dismissed = NO;
    }];
    [alert addAction:exit];
    [alert addAction:ok];
    [UIApplication.sharedApplication.keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    while (!dismissed) {
        for (NSString *mode in (__bridge NSArray *)allModes) {
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, NO);
        }
    }
    CFRelease(allModes);
    
    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    
    if ([exception.name isEqual:UncaughtExceptionHandlerSignalExceptionName]) {
        kill(getpid(), [[exception.userInfo objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
    }else {
        [exception raise];
    }
}

@end

void HandleException(NSException *exception) {
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum) {
        return;
    }
    
    NSArray *callStack = [exception callStackSymbols];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:exception.userInfo];
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];
    
    RXExceptionHandler *exceptionHandler = [RXExceptionHandler shareInstance];
    NSException *uncaughtException = [NSException exceptionWithName:exception.name reason:exception.reason userInfo:userInfo];
    [exceptionHandler performSelectorOnMainThread:@selector(handleException:) withObject:uncaughtException waitUntilDone:YES];
}

void SignalHandler(int signal) {
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum) {
        return;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal] forKey:UncaughtExceptionHandlerSignalKey];
    NSArray *callBack = [RXExceptionHandler backtrace];
    [userInfo setObject:callBack forKey:UncaughtExceptionHandlerAddressesKey];
    
    RXExceptionHandler *exceptionHandler = [RXExceptionHandler shareInstance];
    NSException *signalException = [NSException exceptionWithName:UncaughtExceptionHandlerSignalExceptionName reason:[NSString stringWithFormat:@"Signal %d was raised.", signal] userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:signal] forKey:UncaughtExceptionHandlerSignalKey]];
    [exceptionHandler performSelectorOnMainThread:@selector(handleException:) withObject:signalException waitUntilDone:YES];
}

RXExceptionHandler *InstallUncaughtExceptionHandler(void) {
    NSSetUncaughtExceptionHandler(&HandleException); // 设置未捕获的异常处理
    
    // 设置信号类型的异常处理
    signal(SIGABRT, SignalHandler);
    signal(SIGILL, SignalHandler);
    signal(SIGSEGV, SignalHandler);
    signal(SIGFPE, SignalHandler);
    signal(SIGBUS, SignalHandler);
    signal(SIGPIPE, SignalHandler);
    
    return [RXExceptionHandler shareInstance];
}
