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
/// 包含表情文字 --> 表情文字转换成表情图片
+ (NSMutableAttributedString *)emoticonAttributedWithText:(NSString *)text font:(UIFont *)font;

@end


@interface HJTextPart : NSObject

/// 这段文字的内容
@property (nonatomic, copy) NSString *text;
/// 这段文字的范围
@property (nonatomic, assign) NSRange range;
/// 是否为特殊文字
@property (nonatomic, assign, getter = isSpecical) BOOL special;
/// 是否为表情 
@property (nonatomic, assign, getter = isEmotion) BOOL emotion;

@end
