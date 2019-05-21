//
//  RXExceptionHandler.h
//  ExceptionHandler_OC
//
//  Created by Apple on 2018/5/22.
//  Copyright © 2018年 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

//返回地址路径
typedef void(^ logPathBlock)(NSString *path);

@interface RXExceptionHandler : NSObject
{
    BOOL dismissed; // 是否继续程序
}

//错误日志路径
@property (nonatomic,copy) logPathBlock pathBlock;
@property (nonatomic,strong) NSString *logFilePath;
//回调返回错误日志
@property (nonatomic, copy) RXExceptionHandler*(^getLogPathBlock)(void(^)(NSString *path));

//// 处理未捕获的异常
//void HandleUncaughtException(NSException *exception);
//// 处理信号类型的异常
//void HandleSignal(int signal);
// 为两种类型的信号注册处理函数
RXExceptionHandler *InstallUncaughtExceptionHandler(void);

@end
