//
//  MBWebNavigationTitleTabView.h
//  meb5
//
//  Created by hz on 16/6/23.
//  Copyright © 2016年 hz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MBWebNavigationTitleTabView : UIView

/**
 *  初始菜单标签控件
 *
 *  @param items 标签名称数组
 *
 *  @return 菜单标签
 */
- (UIView *)initButtonsWithItems:(NSArray *)items;

/**
 *  用于翻页的button Menu
 */
@property (strong, nonatomic, readonly) NSArray *buttons;

/**
 *  设置下划线位置
 */
@property (assign, nonatomic) NSInteger selectIndedx;

/**
 按钮底部的下标线
 */
@property (strong, nonatomic) UIView *line;

@end
