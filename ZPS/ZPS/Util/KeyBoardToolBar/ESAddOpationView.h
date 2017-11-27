//
//  ESAddOpationView.h
//  ZPS
//
//  Created by 张海军 on 2017/11/27.
//  Copyright © 2017年 baoqianli. All rights reserved.
//  加号按钮的view

#import <UIKit/UIKit.h>

@class OpationItem;

@interface ESAddOpationView : UIView
/// 功能选项数组
@property (nonatomic, strong) NSArray<OpationItem*>* opationItem;

+ (instancetype)addOpationView;
@end


@interface OpationItem : NSObject
/// 选项名称
@property (nonatomic, copy) NSString *itemName;
/// 选项图片名
@property (nonatomic, copy) NSString *itemIconName;

+ (instancetype)opationItemWithName:(NSString *)itemName iconName:(NSString *)iconName;
@end


@interface OpationButton : UIButton

@end
