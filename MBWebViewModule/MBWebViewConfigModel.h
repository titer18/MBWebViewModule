//
//  MBWebViewConfigModel.h
//  MBWebViewController
//
//  Created by hz on 2018/8/10.
//  Copyright © 2018年 hz. All rights reserved.
//

#import <JSONModel/JSONModel.h>

@protocol MBWebViewConfigNavigationItemModel
@end

@interface MBWebViewConfigModel : JSONModel

@property (strong, nonatomic) NSString *pullCommand;
@property (strong, nonatomic) NSNumber *opaqueHeight;
@property (strong, nonatomic) NSArray <MBWebViewConfigNavigationItemModel>*buttons;
@property (strong, nonatomic) NSNumber *mode;
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSURL *icon;
@property (strong, nonatomic) NSNumber *tabCheckd;
@property (strong, nonatomic) NSArray <MBWebViewConfigNavigationItemModel>*tabs;

@end

@interface MBWebViewConfigNavigationItemModel : JSONModel

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSURL *icon;
@property (strong, nonatomic) NSString *command;
@property (strong, nonatomic) NSArray <MBWebViewConfigNavigationItemModel>*subMenus;

@end
