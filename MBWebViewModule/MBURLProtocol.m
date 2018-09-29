//
//  MBURLProtocol.m
//  mb
//
//  Created by hz on 2018/8/27.
//  Copyright © 2018年 Meibei. All rights reserved.
//

#import "MBURLProtocol.h"
#import <JSONModel/JSONModel.h>

@implementation MBURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if (!request) {
        return NO;
    }
    
    if (!request.URL) {
        return NO;
    }
    
    if (!request.URL.absoluteString) {
        return NO;
    }
    
    NSString *scheme = request.URL.scheme;
    
    if (!scheme) {
        return NO;
    }
    
    scheme = [scheme lowercaseString];
    
    if (!scheme) {
        return NO;
    }
    
    if (([@"http" isEqualToString:scheme] == NO) && ([@"https" isEqualToString:scheme] == NO)) {
        return NO;
    }
    
    //AppleWebKit
    NSString *userAgent = [request valueForHTTPHeaderField:@"User-Agent"];
    if (![userAgent containsString:@"AppleWebKit"])
    {
        return NO;
    }
    
    //添加headers (SonicSession 未添加header 时添加header)
    //通过UA判断是否是UIWebView
    if(![[request allHTTPHeaderFields] objectForKey:@"mebAppName"] && [request isKindOfClass:[NSMutableURLRequest class]])
    {
        // set the new headers
        if ([NSClassFromString(@"MBRequestHeaderModel") respondsToSelector:NSSelectorFromString(@"sharedInstance")])
        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            
            JSONModel *model = [NSClassFromString(@"MBRequestHeaderModel") performSelector:NSSelectorFromString(@"sharedInstance")];
            
#pragma clang diagnostic pop

            NSDictionary *headersDic = [model toDictionary];
            for (NSString *key in headersDic.allKeys) {
                [(id)request setValue:headersDic[key] forHTTPHeaderField:key];
            }
        }
    };
    
    return NO;
}

@end
