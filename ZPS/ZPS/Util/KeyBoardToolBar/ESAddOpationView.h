//
//  ESAddOpationView.h
//  ZPS
//
//  Created by 张海军 on 2017/11/27.
//  Copyright © 2017年 baoqianli. All rights reserved.
//  加号按钮的view

#import <UIKit/UIKit.h>

@class OpationItem;

typedef NS_ENUM(NSInteger, OpationItem_type)
{
    OpationItem_image = 0, // 照片选择
    OpationItem_video = 1  // 视频选择
};


@interface ESAddOpationView : UIView
/// 功能选项数组
@property (nonatomic, strong) NSArray<OpationItem*>* opationItem;
/// 选中回调
@property (nonatomic, copy) void(^selectedOpationHandle)(OpationItem_type type);
+ (instancetype)addOpationView;

@end


@interface OpationItem : NSObject
/// 选项名称
@property (nonatomic, copy) NSString *itemName;
/// 选项图片名
@property (nonatomic, copy) NSString *itemIconName;
/// 类型
@property (nonatomic, assign)  OpationItem_type type;

+ (instancetype)opationItemWithName:(NSString *)itemName iconName:(NSString *)iconName type:(OpationItem_type)type;
@end


@interface OpationButton : UIButton

@end
