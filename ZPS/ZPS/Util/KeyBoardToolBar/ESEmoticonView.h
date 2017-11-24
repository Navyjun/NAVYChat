//
//  ESEmoticonView.h
//  QianEyeShow
//
//  Created by 张海军 on 16/8/11.
//  Copyright © 2016年 baoqianli. All rights reserved.
//  显示表情的view 包括 表情 + 下面的选项卡

#import <UIKit/UIKit.h>
#import "ESEmotionModel.h"
#import <MJExtension.h>

@interface ESEmoticonView : UIView

+ (instancetype)emoticonView;

/** 表情(里面存放的ESEmotion模型) */
@property (nonatomic, strong) NSArray *emotions;

/// 发送按钮的点击回调
@property (nonatomic, copy) void(^sendButtonDidClickBlock)(void);
/// 点击表情的回调
@property (nonatomic, copy) void(^insetEmoticonBlock)(NSString *message);
/// 删除表情的回调
@property (nonatomic, copy) void(^deleteEmoticonBlock)(void);
@end
