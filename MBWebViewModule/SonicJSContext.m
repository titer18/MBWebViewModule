//
//  SonicJSContext.m
//  SonicSample
//
//  Tencent is pleased to support the open source community by making VasSonic available.
//  Copyright (C) 2017 THL A29 Limited, a Tencent company. All rights reserved.
//  Licensed under the BSD 3-Clause License (the "License"); you may not use this file except
//  in compliance with the License. You may obtain a copy of the License at
//
//  https://opensource.org/licenses/BSD-3-Clause
//
//  Unless required by applicable law or agreed to in writing, software distributed under the
//  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
//  either express or implied. See the License for the specific language governing permissions
//  and limitations under the License.
//
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "SonicJSContext.h"
#import <VasSonic/Sonic.h>

@implementation SonicJSContext

- (void)getDiffData:(NSDictionary *)option withCallBack:(JSValue *)jscallback
{
    JSContext *jscontext = [self.owner valueForKey:@"jscontext"];
    JSValue *callback = jscontext.globalObject;
    
    [[SonicEngine sharedEngine] sonicUpdateDiffDataByWebDelegate:(id)self.owner completion:^(NSDictionary *result) {
       
        if (result) {
            
            NSData *json = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil];
            NSString *jsonStr = [[NSString alloc]initWithData:json encoding:NSUTF8StringEncoding];
            
            //fix:切换到主线程
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [callback invokeMethod:@"getDiffDataCallback" withArguments:@[jsonStr]];
            });
        }
        
    }];
}

- (NSString *)getPerformance:(NSDictionary *)option withCallBack:(JSValue *)jscallback
{
    NSNumber *clickTime = [self.owner valueForKey:@"clickTime"];
    NSDictionary *result = @{
                             @"clickTime":clickTime,
                             };
    NSData *json = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonStr = [[NSString alloc]initWithData:json encoding:NSUTF8StringEncoding];
    
    return jsonStr;
}

@end
