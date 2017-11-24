//
//  UIView+Extension.m
//
//
//  Created by apple on 14-10-7.
//  Copyright (c) 2014年 zhj. All rights reserved.
//

#import "UIView+Extension.h"

@implementation UIView (Extension)
- (BOOL)hj_viewIsIntersectAnthorView:(UIView *)anthorView
{
    if (anthorView == nil) {
        anthorView = [UIApplication sharedApplication].keyWindow;
    }
    
    // nil代表主窗口
    CGRect viewFrame = [self convertRect:self.bounds toView:nil];
    CGRect anthorViewFrame = [anthorView convertRect:anthorView.bounds toView:nil];
    
    // 是否重叠
    return CGRectIntersectsRect(viewFrame, anthorViewFrame);
}

- (void)hj_viewCornerRadiusValue:(CGFloat)value
{
    self.layer.cornerRadius = value;
    self.clipsToBounds = YES;
}

- (void)hj_viewAddScaleAnimation
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"transform.scale";
    animation.values = @[@1.0,@1.3,@0.9,@1.15,@0.95,@1.02,@1.0];
    animation.duration = 1;
    animation.calculationMode = kCAAnimationCubic;
    [self.layer addAnimation:animation forKey:nil];
}

- (void)hj_shake {
    [self.layer removeAnimationForKey:@"shake"];
    CAKeyframeAnimation *keyFrame = [CAKeyframeAnimation animationWithKeyPath:@"position.x"];
    keyFrame.duration = 0.3;
    CGFloat x = self.layer.position.x;
    keyFrame.values = @[@(x - 30), @(x - 30), @(x + 20), @(x - 20), @(x + 10), @(x - 10), @(x + 5), @(x - 5)];
    [self.layer addAnimation:keyFrame forKey:@"shake"];
}


- (void)setX:(CGFloat)x
{
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (void)setY:(CGFloat)y
{
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)x
{
    return self.frame.origin.x;
}

- (CGFloat)y
{
    return self.frame.origin.y;
}

- (void)setWidth:(CGFloat)width
{
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (void)setHeight:(CGFloat)height
{
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)height
{
    return self.frame.size.height;
}

- (CGFloat)width
{
    return self.frame.size.width;
}

- (void)setSize:(CGSize)size
{
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGSize)size
{
    return self.frame.size;
}

- (void)setOrigin:(CGPoint)origin
{
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGPoint)origin
{
    return self.frame.origin;
}

- (void)setCenterX:(CGFloat)centerX
{
    CGPoint center = self.center;
    center.x = centerX;
    self.center = center;
}

- (CGFloat)centerX
{
    return self.center.x;
}

- (void)setCenterY:(CGFloat)centerY
{
    CGPoint center = self.center;
    center.y = centerY;
    self.center = center;
}

- (CGFloat)centerY
{
    return self.center.y;
}

- (void)setHj_width:(CGFloat)hj_width
{
    CGRect frame = self.frame;
    frame.size.width = hj_width;
    self.frame = frame;
}

- (CGFloat)hj_width
{
    return self.frame.size.width;
}

- (void)setHj_height:(CGFloat)hj_height
{
    CGRect frame = self.frame;
    frame.size.height = hj_height;
    self.frame = frame;
}

- (CGFloat)hj_height
{
    return self.frame.size.height;
}

@end
