//
//  MBWebViewController.h
//  MBWebViewController
//
//  Created by hz on 2018/8/9.
//  Copyright © 2018年 hz. All rights reserved.
//

#import <QMUIKit/QMUIKit.h>
#import "MBTips.h"

//通知
#define kNotificationUserLoginDone @"kNotificationUserLoginDone" //登录成功通知

@interface MBWebViewController : QMUICommonViewController

@property (strong, nonatomic) NSURL *url;

- (instancetype)initWithURL:(NSURL *)url;

- (void)reloadWebView;

/**
 *  返回上一页
 */
- (void)goBack;

@end
