//
//  AppDelegate.m
//  BacktraceForThread
//
//  Created by Shepherd on 2020/6/14.
//  Copyright © 2020 Shepherd. All rights reserved.
//

#import "AppDelegate.h"
#import "BacktraceThread.h"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    NSSetUncaughtExceptionHandler(HandleException);
    [BacktraceThread backtraceString];
    // @[][1];
    return YES;
}

void HandleException(NSException *exception) {
    
    [BacktraceThread backtraceString];
    
//    //获取调用堆栈
//    NSArray *callStack = [exception callStackSymbols];
//    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
//    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];
//
//    //在主线程中，执行制定的方法, withObject是执行方法传入的参数
//    [[[UncaughtExceptionHandler alloc] init]
//     performSelectorOnMainThread:@selector(handleException:)
//     withObject:
//     [NSException exceptionWithName:[exception name]
//                             reason:[exception reason]
//                           userInfo:userInfo]
//     waitUntilDone:YES];

}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
