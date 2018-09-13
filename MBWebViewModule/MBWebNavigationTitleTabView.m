//
//  MBWebNavigationTitleTabView.m
//  meb5
//
//  Created by hz on 16/6/23.
//  Copyright © 2016年 hz. All rights reserved.
//

#import "MBWebNavigationTitleTabView.h"
#import <QMUIKit/QMUIKit.h>
#import <Masonry/Masonry.h>

@interface MBWebNavigationTitleTabView()

@property (strong, nonatomic) NSArray *items;

@property (strong, nonatomic) NSMutableArray *itemViews;

@end

@implementation MBWebNavigationTitleTabView

- (CGSize)intrinsicContentSize
{
    return UILayoutFittingExpandedSize;
}

- (NSMutableArray *)itemViews
{
    if (!_itemViews) {
        _itemViews = [NSMutableArray array];
    }
    
    return _itemViews;
}

- (UIView *)line
{
    if (!_line) {
        _line = [[UIView alloc] init];
        _line.backgroundColor = UIColorMake(252, 82, 31);
//        _line.hidden = YES;
    }
    
    return _line;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.

- (UIView *)selectView
{
    if (_selectIndedx < self.itemViews.count) {
        return self.itemViews[_selectIndedx];
    }
    return nil;
}

- (void)setSelectIndedx:(NSInteger)selectIndedx
{
    _selectIndedx = selectIndedx;
    
    //设置选中文字颜色
    for (NSInteger i = 0; i < self.buttons.count; i++)
    {
        UIButton *button = self.buttons[i];
        [button setTitleColor:UIColorMake(51, 51, 51) forState:UIControlStateNormal];
    }
    if (selectIndedx < self.buttons.count) {
        UIButton *selectedButton = self.buttons[selectIndedx];
        [selectedButton setTitleColor:UIColorMake(252, 82, 31) forState:UIControlStateNormal];
        //设置下划线位置
        UIView *selectView = [self selectView];
        [self.line mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(selectedButton);
            make.height.mas_equalTo(3);
            make.bottom.mas_equalTo(0);
            make.centerX.mas_equalTo(selectView);
        }];
    }
}

- (void)setItems:(NSArray *)items
{
    _items = items;
    
    NSMutableArray *views = self.itemViews;
    
    //清空旧的itemView
    for(UIView *view in views)
    {
        [view removeFromSuperview];
    }
    
    //添加itemView
    for(NSInteger i = 0; i < items.count; i++)
    {
        UIView *view = [[UIView alloc] init];
        
        view.backgroundColor = [UIColor clearColor];
        [self addSubview:view];
        
        [views addObject:view];
    }
    
    //添加itemView约束线
    UIView *lastView;
    for (NSInteger i = 0; i < items.count; i++)
    {
        //只有1个分组的情况
        if (items.count == 1)
        {
            UIView *view = views[i];
            [view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(0);
                make.left.bottom.right.mas_equalTo(0);
            }];
            
            break;
        }
        
        UIView *view = views[i];
        
        //第一个
        if(i == 0)
        {
            [view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(0);
                make.bottom.mas_equalTo(0);
                make.left.mas_equalTo(0);
            }];
        }
        
        //最后一个
        else if (i == items.count - 1)
        {
            [view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(0);
                make.bottom.mas_equalTo(0);
                make.left.mas_equalTo(lastView.mas_right);
                make.right.mas_equalTo(0);
                make.size.mas_equalTo(views.firstObject);
            }];
        }
        else
        {
            [view mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(0);
                make.bottom.mas_equalTo(0);
                make.left.mas_equalTo(lastView.mas_right);
                make.size.mas_equalTo(views.firstObject);
            }];
        }
        
        lastView = view;
    }
    
    //添加button
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:views.count];
    for (NSInteger i = 0; i < views.count; i++)
    {
        UIView *view  = views[i];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        [button setTitle:self.items[i] forState:UIControlStateNormal];
        
        if (i == self.selectIndedx)
        {
            [button setTitleColor:UIColorMake(243, 175, 175) forState:UIControlStateNormal];
        }
        else
        {
            [button setTitleColor:UIColorMake(74, 74, 74) forState:UIControlStateNormal];
        }
        
        button.titleLabel.font = [UIFont systemFontOfSize:15];
        
        [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:button];
        
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(view);
        }];
        
        [buttons addObject:button];
    }
    _buttons = buttons;
    
    
    //添加下划线
    [self addSubview:self.line];
    
    UIView *selectView = [self selectView];
    
    [self.line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(selectView);
        make.height.mas_equalTo(1);
        make.bottom.mas_equalTo(0);
        make.centerX.mas_equalTo(selectView);
    }];
}

- (void)buttonAction:(id)sender
{
    UIButton *button = sender;
    
    self.selectIndedx = button.tag;
}

- (void)drawRect:(CGRect)rect {
    // Drawing code

}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _selectIndedx = 0;
}

/**
 *  初始菜单标签控件
 *
 *  @param items 标签名称数组
 *
 *  @return 菜单标签
 */
- (UIView *)initButtonsWithItems:(NSArray *)items
{
    UINib *nib = [UINib nibWithNibName:NSStringFromClass(self.class) bundle:NSBundle.mainBundle];
    
    NSArray *views = [nib instantiateWithOwner:nil options:nil];
    for (UIView *view in views) {
        if ([view isMemberOfClass:[self class]]) {
            self = (id)view;
        }
    }
    
    if (!self) {
        self = [super init];
    }
    
    if (self) {
        self.items = items;
        self.selectIndedx = 0;
    }
    
    return self;
}

@end
