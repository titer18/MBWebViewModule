//
//  MBWebViewModule.h
//  mb
//
//  Created by hz on 2018/8/16.
//  Copyright © 2018年 Meibei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PromiseKit/PromiseKit.h>

@interface MBWebViewModule : NSObject

/**
 获取一个webView的VC
 
 @param pageName 页面名称
 @param parameters 参数字典
 [self MBWebVCWithPageName:@"tips_surgerybeforetip" parameters:@{@"orderId":@"123", @"projectId":@"abc"}].then(^(MBWebViewController *vc){
 });
 @return PMKPromise
 */
+ (PMKPromise *)MBWebVCWithPageName:(NSString *)pageName parameters:(NSDictionary *)parameters;

+ (PMKPromise *)MBWebUrlWithPageName:(NSString *)pageName parameters:(NSDictionary *)parameters;

@end
