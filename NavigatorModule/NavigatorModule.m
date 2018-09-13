//
//  NavigatorModule.m
//  mb
//
//  Created by hz on 2018/8/17.
//  Copyright © 2018年 Meibei. All rights reserved.
//

#import "NavigatorModule.h"
#import <DCURLRouter/DCURLNavgation.h>
#import "OpenLocationModule.h"
#import <QMUIKit/QMUIKit.h>
#import <PromiseKit/NSNotificationCenter+PromiseKit.h>

@implementation NavigatorModule

+ (void)load {
    
    [NSNotificationCenter once:UIApplicationDidFinishLaunchingNotification].then(^(NSNotification *note, NSDictionary *userInfo){
        
        [DCURLRouter loadConfigDictFromPlist:@"NavigatorModule.plist"];
    });
}

+ (PMKPromise *)URLString:(NSString *)URLString
{
    return [self URLString:URLString query:nil openType:NavigatorModuleOpenTypePush];
}

+ (PMKPromise *)URLString:(NSString *)URLString query:(NSDictionary *)query
{
    return [self URLString:URLString query:query openType:NavigatorModuleOpenTypePush];
}

+ (void)advisory
{
    //            [WXOpenIMUtils contactMBService];
    [QMUITips showError:@"没有集成咨询模块"];
}

+ (PMKPromise *)URLString:(NSString *)URLString query:(NSDictionary *)query openType:(NavigatorModuleOpenType)openType
{
    return [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
        
        //咨询
        if ([URLString  hasPrefix:@"meb://advisory"])
        {
            [self advisory];
            return;
        }
        
        //地图坐标跳转
        if ([URLString hasPrefix:@"meb://map"])
        {
            NSString *lat = query[@"latitude"];
            NSString *lng = query[@"longitude"];
            NSString *name = query[@"name"];
            
            CLLocation *location = [[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lng.doubleValue];
            
            [OpenLocationModule getCoordinateByLocation:location name:name];
            
            return;
        }
        
        NSDictionary *configDict = [[DCURLRouter sharedDCURLRouter] valueForKey:@"configDict"];
        
        UIViewController *viewController = [UIViewController initFromString:URLString withQuery:query fromConfig:configDict];
        
        if (openType == NavigatorModuleOpenTypePush)
        {
            [DCURLNavgation pushViewController:viewController animated:YES replace:NO];
        }
        else
        {
            [DCURLNavgation presentViewController:viewController animated:YES completion:nil];
        }
        
        resolve(viewController);
    }];
}

@end
