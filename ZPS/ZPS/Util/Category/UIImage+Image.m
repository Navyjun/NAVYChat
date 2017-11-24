//
//  UIImage+Image.m
//  
//
//  Created by NAVY on 15/7/6.
//  Copyright (c) 2015年 NAVY. All rights reserved.
//

#import "UIImage+Image.h"

@implementation UIImage (Image)

+ (UIImage *)imageWithColor:(UIColor *)color
{
    return [self imageWithColor:color height:1.0 width:1.0];
}

+ (UIImage *)imageWithColor:(UIColor *)color height:(CGFloat)height width:(CGFloat)width
{
    // 描述矩形
    CGRect rect = CGRectMake(0.0f, 0.0f, width, height);
    
    // 开启位图上下文
    UIGraphicsBeginImageContext(rect.size);
    // 获取位图上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    // 使用color演示填充上下文
    CGContextSetFillColorWithColor(context, [color CGColor]);
    // 渲染上下文
    CGContextFillRect(context, rect);
    // 从上下文中获取图片
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    // 结束上下文
    UIGraphicsEndImageContext();
    
    return theImage;
}


+ (UIImage *)ImageTitleSize:(CGSize)imageSize imageColor:(UIColor *)imageColor text:(NSString *)str textFont:(UIFont *)textF textColor:(UIColor*)textC
{
    NSDictionary *attDic = @{ NSFontAttributeName : textF, NSForegroundColorAttributeName :textC};
    CGSize textSize = [str sizeWithAttributes:attDic];
    
    if (textSize.width > imageSize.width) {
        imageSize.width = textSize.width + 20;
    }
    
    UIImage *image = [self imageWithColor:[UIColor clearColor] height:imageSize.height width:imageSize.width];
    
    UIGraphicsBeginImageContextWithOptions (imageSize, NO , 0.0 );
    
    [image drawAtPoint : CGPointMake ( 0 , 0 )];
    
    UIBezierPath *bezierP = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, imageSize.width, imageSize.height) cornerRadius:4.0];
    bezierP.lineWidth = 1;
    [bezierP addClip];
    //[RGBHEX_(f91c4c) setStroke];
    [bezierP stroke];
    // 获得一个位图图形上下文
    CGContextRef context= UIGraphicsGetCurrentContext ();
    
    
    CGContextDrawPath (context, kCGPathStroke);
    
    // 画
    
    CGFloat textX = (imageSize.width - textSize.width) * 0.5;
    CGFloat textY = (imageSize.height - textSize.height) * 0.5;
    //[str drawInRect:CGRectMake(textX, textY, textSize.width, textSize.height) withAttributes:attDic];
    
    [str drawAtPoint : CGPointMake (textX, textY) withAttributes:attDic];
    
    // 返回绘制的新图形
    
    UIImage *newImage= UIGraphicsGetImageFromCurrentImageContext ();
    
    
    UIGraphicsEndImageContext ();
    
    return newImage;
    
}


+ (UIImage *)ImageSize:(CGSize)imageSize text:(NSString *)str textFont:(UIFont *)textF textColor:(UIColor*)textC
{
    NSDictionary *attDic = @{ NSFontAttributeName : textF, NSForegroundColorAttributeName :textC};
    CGSize textSize = [str sizeWithAttributes:attDic];
    
    if (textSize.width > imageSize.width) {
        imageSize.width = textSize.width + 20;
    }
    
    UIImage *image = [self imageWithColor:[UIColor clearColor] height:imageSize.height width:imageSize.width];
    
    UIGraphicsBeginImageContextWithOptions (imageSize, NO , 0.0 );
    
    [image drawAtPoint : CGPointMake ( 0 , 0 )];

    // 获得一个位图图形上下文
    CGContextRef context= UIGraphicsGetCurrentContext ();
    CGContextDrawPath (context, kCGPathStroke);
    
    // 画
    CGFloat textX = (imageSize.width - textSize.width) * 0.5;
    CGFloat textY = (imageSize.height - textSize.height) * 0.5;
    //[str drawInRect:CGRectMake(textX, textY, textSize.width, textSize.height) withAttributes:attDic];
    
    [str drawAtPoint : CGPointMake (textX, textY) withAttributes:attDic];
    
    // 返回绘制的新图形
    
    UIImage *newImage= UIGraphicsGetImageFromCurrentImageContext ();
    
    
    UIGraphicsEndImageContext ();
    
    return newImage;
    
}


+ (UIImage *)imageWithOriginal:(NSString *)imageName
{
    UIImage *image = [UIImage imageNamed:imageName];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    return image;
}


+ (UIImage *)resizable:(UIImage *)image {
    CGFloat top = image.size.height * 0.5;
    CGFloat left = image.size.width * 0.5;
    return  [image resizableImageWithCapInsets:UIEdgeInsetsMake(top, left, top - 1, left - 1)];
}

+ (UIImage *)imageWithCircularImage:(UIImage *)image {
    
    // 开启位图上下文
    CGFloat W = image.size.width;
    CGFloat H = image.size.height;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(W, H), NO, 0);
    
    // 设置裁剪圆
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, W, H)];
    [clipPath addClip];
    
    // 把图片渲染到上下文种
    [image drawAtPoint:CGPointMake(0, 0)];
    
    // 取出图片
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 关闭上下文
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *)imageToThumbnail:(UIImage *)image size:(CGSize)size
{
    // 开启位图上下文
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    
    // 设置裁剪圆
//    UIBezierPath *clipPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, size.width, size.height)];
//    [clipPath addClip];
    
    // 把图片渲染到上下文种
    [image drawInRect:CGRectMake(0.0, 0.0, size.width, size.height)];
    
    // 取出图片
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 关闭上下文
    UIGraphicsEndImageContext();
    
    return newImage;
   
}

- (UIImage*)imageRotatedByDegrees:(CGFloat)degrees
{
    
    CGFloat width = CGImageGetWidth(self.CGImage);
    CGFloat height = CGImageGetHeight(self.CGImage);
    
    CGSize rotatedSize;
    
    rotatedSize.width = width;
    rotatedSize.height = height;
    
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    CGContextRotateCTM(bitmap, degrees * M_PI / 180);
    CGContextRotateCTM(bitmap, M_PI);
    CGContextScaleCTM(bitmap, -1.0, 1.0);
    CGContextDrawImage(bitmap, CGRectMake(-rotatedSize.width/2, -rotatedSize.height/2, rotatedSize.width, rotatedSize.height), self.CGImage);
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

//生成二维码
+ (UIImage *)imageQRCodeActionGenerate:(NSString *)codess
{
    NSString *text = codess;
    
    NSData *stringData = [text dataUsingEncoding: NSUTF8StringEncoding];
    
    //生成
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"M" forKey:@"inputCorrectionLevel"];
    
    UIColor *onColor = [UIColor blackColor];
    UIColor *offColor = [UIColor whiteColor];
    
    //上色
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor" keysAndValues:@"inputImage",qrFilter.outputImage,@"inputColor0",[CIColor colorWithCGColor:onColor.CGColor],@"inputColor1",[CIColor colorWithCGColor:offColor.CGColor],nil];
    
    CIImage *qrImage = colorFilter.outputImage;
    
    //绘制
    CGSize size = CGSizeMake(200, 200);
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:qrImage fromRect:qrImage.extent];
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    UIImage *codeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRelease(cgImage);
    
    return codeImage;
}

- (UIImage*)transformWidth:(CGFloat)width height:(CGFloat)height {
    
    
    CGFloat destW = width;
    
    CGFloat destH = height;
    
    CGFloat sourceW = width;
    
    CGFloat sourceH = height;
    
    CGImageRef imageRef = self.CGImage;
    
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                destW,
                                                destH,
                                                CGImageGetBitsPerComponent(imageRef),
                                                4*destW,
                                                CGImageGetColorSpace(imageRef),
                                                (kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst));
    
    CGContextDrawImage(bitmap, CGRectMake(0, 0, sourceW, sourceH), imageRef);
    
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    
    UIImage *resultImage = [UIImage imageWithCGImage:ref];
    
    CGContextRelease(bitmap);
    
    CGImageRelease(ref);
    
    return resultImage;
    
}

@end
