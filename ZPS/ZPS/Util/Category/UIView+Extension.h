//
//  UIView+Extension.h
//
//
//  Created by apple on 14-10-7.
//  Copyright (c) 2014年 zhj. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Extension)
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
//@property (nonatomic, assign) CGFloat width;
//@property (nonatomic, assign) CGFloat height;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGPoint origin;
@property (nonatomic, assign) CGFloat centerX;
@property (nonatomic, assign) CGFloat centerY;
@property (nonatomic, assign) CGFloat hj_width;
@property (nonatomic, assign) CGFloat hj_height;

/**
 *  两个view是否重叠
 */
- (BOOL)hj_viewIsIntersectAnthorView:(UIView *)anthorView;

/**
 *  view周边倒角
 */
- (void)hj_viewCornerRadiusValue:(CGFloat)value;

/**
 *  添加一个缩放动画
 */
- (void)hj_viewAddScaleAnimation;


/**
 抖动动画
 */
- (void)hj_shake;

@end
