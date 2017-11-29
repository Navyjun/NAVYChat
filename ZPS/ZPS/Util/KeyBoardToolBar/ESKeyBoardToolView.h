//
//  ESKeyBoardToolView.h
//  QianEyeShow
//
//  Created by 张海军 on 16/8/11.
//  Copyright © 2016年 baoqianli. All rights reserved.
//  键盘工具条

#import <UIKit/UIKit.h>
#import "ESAddOpationView.h"

/// 输入框最多显示多少行
static NSInteger maxLines = 4;
/// 输入框的高度
static CGFloat const TitleViewHeight = 44.0;

typedef NS_ENUM(NSInteger, ESKeyBoardToolView_type)
{
    ESKeyBoardToolView_typeEmoticon = 0,       // 表情按钮的点击
    ESKeyBoardToolView_typeAdd                 // 加号按钮的点击
};

@class ESKeyBoardToolView;

@protocol ESKeyBoardToolViewDelegate <NSObject>

@optional
/// 加号选项view的点击
- (void)ESKeyBoardToolViewAddOpationDidSelected:(ESKeyBoardToolView *)view withType:(OpationItem_type)type;
/// 点击发送按钮
- (void)ESKeyBoardToolViewSendButtonDidClick:(ESKeyBoardToolView *)view message:(NSString *)message;
/// 当正在编辑文字时view的Y值变化
- (void)ESKeyBoardToolViewDidEditing:(ESKeyBoardToolView *)view  changeY:(CGFloat)yValue;
/// 结束编辑回调
- (void)ESKeyBoardToolViewDidEndEdit:(ESKeyBoardToolView *)view;
@end

@interface ESKeyBoardToolView : UIView
/// delegate
@property (nonatomic, weak) id <ESKeyBoardToolViewDelegate> delegate;
/// 输入框
@property (nonatomic, strong,readonly) UITextView *inputTextView;
/// 占位文字
@property (nonatomic, copy) NSString *placeTitle;
/// 是否需要显示右边的添加按钮
@property (nonatomic, assign) BOOL isNeedHiddenAddButton;
/// 是否正在切换表情键盘
@property (nonatomic, assign) BOOL isChangeEmoticon;
/// 键盘完全弹出所需的时间
@property (nonatomic, assign) CGFloat showTime;
/// 系统键盘的高度
@property (nonatomic, assign) CGFloat systemKeyboardH;

- (void)exitKeyBoard;

- (void)showKeyBoard;

@end
