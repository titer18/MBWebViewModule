//
//  NavigatorModule.h
//  mb
//
//  Created by hz on 2018/8/17.
//  Copyright © 2018年 Meibei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DCURLRouter/DCURLRouter.h>
#import <PromiseKit/PromiseKit.h>

typedef NS_ENUM(NSInteger, NavigatorModuleOpenType){
    NavigatorModuleOpenTypePush = 0,
    NavigatorModuleOpenTypePresent,
};

@interface NavigatorModule : NSObject

+ (PMKPromise *)URLString:(NSString *)URLString;

+ (PMKPromise *)URLString:(NSString *)URLString query:(NSDictionary *)query;

+ (PMKPromise *)URLString:(NSString *)URLString query:(NSDictionary *)query openType:(NavigatorModuleOpenType)openType;

@end
