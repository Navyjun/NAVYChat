//
//  PickerImageVideoTool.m
//  ZPS
//
//  Created by 张海军 on 2017/11/28.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "PickerImageVideoTool.h"

@interface PickerImageVideoTool ()<TZImagePickerControllerDelegate>
@property (nonatomic, copy) pickerFinishBlock finishBlock;
@end


@implementation PickerImageVideoTool
static PickerImageVideoTool *tool = nil;
+ (instancetype)sharePickerImageVideoTool{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tool = [[self alloc] init];
    });
    return tool;
}

- (void)showImagePickerWithMaxCount:(NSInteger)maxCount completion:(pickerFinishBlock)finishBlock{
    self.finishBlock = finishBlock;
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:maxCount columnNumber:4 delegate:self pushPhotoPickerVc:NO];
    imagePickerVc.allowTakePicture = YES; //内部显示拍照按钮
    imagePickerVc.allowPickingVideo = YES;
    imagePickerVc.allowPickingImage = YES;
    imagePickerVc.allowPickingOriginalPhoto = YES;
    imagePickerVc.allowPickingGif = YES;
    imagePickerVc.allowPickingMultipleVideo = YES; // 是否可以多选视频
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootVC presentViewController:imagePickerVc animated:YES completion:nil];
}

#pragma mark - TZImagePickerControllerDelegate
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto{
    if (self.finishBlock) {
        self.finishBlock(photos, assets);
    }
}

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset{
    MYLog(@"用户选择了一个视频");
    
}


@end
