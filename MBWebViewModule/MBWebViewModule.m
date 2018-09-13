//
//  MBWebViewModule.m
//  mb
//
//  Created by hz on 2018/8/16.
//  Copyright © 2018年 Meibei. All rights reserved.
//

#import "MBWebViewModule.h"
#import "MBWebViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <VasSonic/Sonic.h>
#import "WEBPURLProtocol.h"
#import "WEBPDemoDecoder.h"
#import "MBURLProtocol.h"
#import <PromiseKit/NSNotificationCenter+PromiseKit.h>
#import <PromiseKit/NSURLConnection+PromiseKit.h>

@interface MBWebViewModule ()

@property (strong, nonatomic) NSDictionary *configData;

@end

@implementation MBWebViewModule

+ (void)load {
    
    [NSNotificationCenter once:UIApplicationDidFinishLaunchingNotification].then(^(NSNotification *note, NSDictionary *userInfo){
        
        [NSURLProtocol registerClass:[SonicURLProtocol class]];
        
        [NSURLProtocol registerClass:[MBURLProtocol class]];
        
        [WEBPURLProtocol registerWebP:[WEBPDemoDecoder new]];
        
        //设置 UserAgent
        [self setupUserAgent];
    });
}

+ (void)setupUserAgent
{
    //get the original user-agent of webview
    static NSString *oldAgent;
    
    if (oldAgent == nil)
    {
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        oldAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        webView = nil;
    }
    
    //add my info to the new agent
    NSString *newAgent = [oldAgent stringByAppendingString:@" Meb/1.0.0"];
    
    //regist the new agent
    NSDictionary *dictionnary = [[NSDictionary alloc] initWithObjectsAndKeys:newAgent, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionnary];
}

+ (instancetype)sharedInstance
{
    static MBWebViewModule *sharedManagerInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedManagerInstance = [[self alloc] init];
    });
    return sharedManagerInstance;
}

/**
 获取一个webView的VC

 @param pageName 页面名称
 @param parameters 参数字典
 [self MBWebVCWithPageName:@"tips_surgerybeforetip" parameters:@{@"orderId":@"123", @"projectId":@"abc"}].then(^(MBWebViewController *vc){
 });
 @return PMKPromise
 */
+ (PMKPromise *)MBWebVCWithPageName:(NSString *)pageName parameters:(NSDictionary *)parameters
{
    return
    [self MBWebUrlWithPageName:pageName parameters:parameters]
    .then(^(NSURL *url){
        return [[MBWebViewController alloc] initWithURL:url];
    });
}

+ (PMKPromise *)MBWebUrlWithPageName:(NSString *)pageName parameters:(NSDictionary *)parameters
{
#if API_DEV == 1 //测试地址(外网能访问)
    NSString *host = @"http://m2dev.meb.com";
#else
    NSString *host = @"https://m2.meb.com";
#endif
    
    PMKPromise *promise;
    
    if ([MBWebViewModule sharedInstance].configData.allKeys.count) {
        promise = [PMKPromise promiseWithResolver:^(PMKResolver resolve) {
            resolve([MBWebViewModule sharedInstance].configData);
        }];
    }
    else
    {
        promise = [NSURLConnection GET:[NSString stringWithFormat:@"%@/app.json", host]];
    }
    
    return
    promise.then(^(NSDictionary *data){
        
        [MBWebViewModule sharedInstance].configData = data;
        
        //默认页面
        if (!pageName.length) {
            return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", host, data[@"views"][@"startup"][@"url"]]];
        }
        
        NSString *url = data[@"views"][pageName][@"url"];
        
        url = [NSString stringWithFormat:@"%@%@", host, url];
        
        NSString *args = AFQueryStringFromParameters(parameters);
        
        if ([url containsString:@"?"]) {
            url = [NSString stringWithFormat:@"%@&%@", url, args];
        }
        else
        {
            url = [NSString stringWithFormat:@"%@?%@", url, args];
        }
        
        return [NSURL URLWithString:url];
    });
}

@end
