//
//  ESEmoticonTool.m
//  QianEyeShow
//
//  Created by 张海军 on 16/8/19.
//  Copyright © 2016年 baoqianli. All rights reserved.
//

#import "ESEmoticonTool.h"
#import <MJExtension.h>

@interface ESEmoticonTool ()
/// 默认表情数组
@property (nonatomic, strong) NSArray *defaultEmoticonArray;

@end

@implementation ESEmoticonTool
/// 获取默认表情数组
- (NSArray *)hj_getDefaultEmoticons
{
    return self.defaultEmoticonArray;
}



/// 通过表情名称 返回该表情的对应图片名称
- (NSString *)hj_emticonImageNameByEmticonName:(NSString *)enticonName
{
    NSString *pngName = nil;
    for (ESEmotionModel *model in self.defaultEmoticonArray) {
        if ([model.chs isEqualToString:enticonName]) {
            pngName = model.png;
            break;
        }
    }
    return pngName;
}

#pragma mark - lazy
- (NSArray *)defaultEmoticonArray
{
    if (!_defaultEmoticonArray) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"defaultEmotion.plist" ofType:nil];
        
        if (!_defaultEmoticonArray) {
            _defaultEmoticonArray = [ESEmotionModel mj_objectArrayWithKeyValuesArray:[NSArray arrayWithContentsOfFile:path]];
        }
    }
    return _defaultEmoticonArray;
}


@end
