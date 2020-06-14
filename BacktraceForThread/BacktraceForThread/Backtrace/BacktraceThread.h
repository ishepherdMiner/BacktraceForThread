//
//  BacktraceThread.h
//  BacktraceForThread
//
//  Created by Shepherd on 2020/6/14.
//  Copyright © 2020 Shepherd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BacktraceThread : NSObject

- (NSString *)backtraceString;

+ (NSString *)backtraceString;

@end

NS_ASSUME_NONNULL_END
