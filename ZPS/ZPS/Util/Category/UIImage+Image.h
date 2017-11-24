//
//  UIImage+Image.h
//  
//
//  Created by NAVY on 15/7/6.
//  Copyright (c) 2015年 NAVY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Image)
/**
 * 返回一张圆形的图片
 */
+ (UIImage *)imageWithCircularImage:(UIImage *)image;

/**
 *  根据颜色生成一张尺寸为1*1的相同颜色图片
 */
+ (UIImage *)imageWithColor:(UIColor *)color;


/**
 根据颜色生成一张尺寸为1*height的相同颜色图片

 @param color  颜色值
 @param height 该图片的高度

 @return 1*height的相同颜色图片
 */
+ (UIImage *)imageWithColor:(UIColor *)color height:(CGFloat)height width:(CGFloat)width;


/**
 返回一张带文字 有背景色的图片

 @param imageSize  图片的size
 @param imageColor 图片的颜色
 @param str        文字内容
 @param textF      文字大小
 @param textC      文字颜色
 */
+ (UIImage *)ImageTitleSize:(CGSize)imageSize imageColor:(UIColor *)imageColor text:(NSString *)str textFont:(UIFont *)textF textColor:(UIColor*)textC;

+ (UIImage *)ImageSize:(CGSize)imageSize text:(NSString *)str textFont:(UIFont *)textF textColor:(UIColor*)textC;

/**
 * 保存原始状态的图片
 */
+ (UIImage *)imageWithOriginal:(NSString *)imageName;

/**
 * 返回一张四周不被拉伸的图片
 */
+ (UIImage *)resizable:(UIImage *)image;

/**
 * 返回一张给定大小的缩略图
 */
+ (UIImage *)imageToThumbnail:(UIImage *)image size:(CGSize)size;

- (UIImage*)imageRotatedByDegrees:(CGFloat)degrees;

+ (UIImage *)imageQRCodeActionGenerate:(NSString *)codess;
@end
