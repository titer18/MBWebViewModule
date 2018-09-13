//
//  OpenLocationModule.m
//  mb
//
//  Created by hz on 2018/8/20.
//  Copyright © 2018年 Meibei. All rights reserved.
//

#import "OpenLocationModule.h"
#import <MapKit/MapKit.h>

@implementation OpenLocationModule

#pragma mark 根据地名确定地理坐标

/**
 根据地址导航
 
 @param address 地址信息
 */
+ (void)getCoordinateByAddress:(NSString *)address
{
    [self navAppleMapWithEndAddress:address];
}

/**
 根据GPS坐标导航

 @param location 地址信息
 @param name 地点名称
 */
+ (void)getCoordinateByLocation:(CLLocation *)location name:(NSString *)name
{
    [self navAppleMapWithEndLocation:location.coordinate name:name];
}

//苹果地图
+ (void)navAppleMapWithEndLocation:(CLLocationCoordinate2D)endLocation name:(NSString *)name
{
    MKMapItem *currentLocation = [MKMapItem mapItemForCurrentLocation];
    MKMapItem *tolocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:endLocation addressDictionary:nil]];
    tolocation.name = name;
    [MKMapItem openMapsWithItems:@[currentLocation,tolocation] launchOptions:@{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDefault,
                          MKLaunchOptionsShowsTrafficKey:@(YES)}];
}

+ (void)navAppleMapWithEndAddress:(NSString *)address
{
    // 1. 创建地理编码对象
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    // 2. 实现地理编码方法
    [geocoder geocodeAddressString:address completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        // 3. 获取第一个地标对象 --> 创建MKPlacemark对象
        MKPlacemark *mkPlacemark = [[MKPlacemark alloc] initWithPlacemark:placemarks.firstObject];
        
        // 4. 根据MKPlacemark对象来创建目的地所在的MKMapItem对象
        MKMapItem *destinationItem = [[MKMapItem alloc] initWithPlacemark:mkPlacemark];
        destinationItem.name = address;
        
        // 5. 获取起点位置
        MKMapItem *sourceItem = [MKMapItem mapItemForCurrentLocation];
        
        // 6. 调用open方法, 打开系统自带地图进行导航
        NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDefault,
                                          MKLaunchOptionsShowsTrafficKey:@(YES)};
        [MKMapItem openMapsWithItems:@[sourceItem, destinationItem] launchOptions:launchOptions];
    }];
}

@end
