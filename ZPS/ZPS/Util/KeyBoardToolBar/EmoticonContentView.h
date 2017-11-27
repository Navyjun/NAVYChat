//
//  EmoticonContentView.h
//  QianEyeShow
//
//  Created by 张海军 on 16/8/11.
//  Copyright © 2016年 baoqianli. All rights reserved.
//  表情view

#import <UIKit/UIKit.h>

// 一页中最多3行
#define ESEmotionMaxRows 3
// 一行中最多7列
#define ESEmotionMaxCols 6
// 每一页的表情个数
#define ESEmotionPageSize ((ESEmotionMaxRows * ESEmotionMaxCols) - 1)
@class EmoticonContentView;

@protocol EmoticonContentViewDelegate <NSObject>

@optional
// 点击表情的回调
- (void)emoticonContentInsetEmoticon:(EmoticonContentView *)view insetMessage:(NSString *)message;
// 删除表情的回调
- (void)emoticonContentDeleteEmoticon:(EmoticonContentView *)view;
@end

@interface EmoticonContentView : UIView

/** 这一页显示的表情（里面都是ESEmotion模型） */
@property (nonatomic, strong) NSArray *emotions;

/// delegate
@property (nonatomic, weak) id <EmoticonContentViewDelegate> delegate;

@end


@interface EmoticonButton : UIButton

@end
