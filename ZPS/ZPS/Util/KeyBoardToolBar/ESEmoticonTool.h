//
//  ESEmoticonTool.h
//  QianEyeShow
//
//  Created by 张海军 on 16/8/19.
//  Copyright © 2016年 baoqianli. All rights reserved.
//  表情工具类

#import <Foundation/Foundation.h>
#import "ESEmotionModel.h"

@interface ESEmoticonTool : NSObject
/// 获取默认表情数组
- (NSArray *)hj_getDefaultEmoticons;
/// 通过表情名称 返回该表情的对应图片名称
- (NSString *)hj_emticonImageNameByEmticonName:(NSString *)enticonName;

@end
