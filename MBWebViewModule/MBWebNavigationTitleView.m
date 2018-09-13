//
//  MBWebNavigationTitleView.m
//  MBWebViewController
//
//  Created by hz on 2018/8/13.
//  Copyright © 2018年 hz. All rights reserved.
//

#import "MBWebNavigationTitleView.h"

@implementation MBWebNavigationTitleView

- (CGSize)intrinsicContentSize
{
    return UILayoutFittingExpandedSize;
}

- (instancetype)init
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
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
