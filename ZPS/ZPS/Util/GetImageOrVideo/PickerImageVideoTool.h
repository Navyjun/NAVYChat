//
//  PickerImageVideoTool.h
//  ZPS
//
//  Created by 张海军 on 2017/11/28.
//  Copyright © 2017年 baoqianli. All rights reserved.
//  获取图片/视频工具类

#import <Foundation/Foundation.h>
#import <TZImagePickerController.h>

typedef void(^pickerFinishBlock)(NSArray<UIImage *> *photos,NSArray *assets );

@interface PickerImageVideoTool : NSObject
+ (instancetype)sharePickerImageVideoTool;
- (void)showImagePickerWithMaxCount:(NSInteger)maxCount completion:(pickerFinishBlock)finishBlock;
@end
