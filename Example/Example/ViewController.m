//
//  ViewController.m
//  Example
//
//  Created by HZ on 2018/9/12.
//  Copyright © 2018年 HZ. All rights reserved.
//

#import "ViewController.h"
#import <MBWebViewModule/MBWebViewModule.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [MBWebViewModule MBWebVCWithPageName:nil parameters:nil].then(^(UIViewController *vc){
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:nav animated:YES completion:nil];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
