//
//  OpenLocationModule.h
//  mb
//
//  Created by hz on 2018/8/20.
//  Copyright © 2018年 Meibei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OpenLocationModule : NSObject

/**
 根据地址导航
 
 @param address 地址信息
 */
+ (void)getCoordinateByAddress:(NSString *)address;

/**
 根据GPS坐标导航
 
 @param location 地址信息
 @param name 地点名称
 */
+ (void)getCoordinateByLocation:(CLLocation *)location name:(NSString *)name;

@end
