//
//  ESEmoticonTool.m
//  QianEyeShow
//
//  Created by 张海军 on 16/8/19.
//  Copyright © 2016年 baoqianli. All rights reserved.
//

#import "ESEmoticonTool.h"
#import <MJExtension.h>
#import "RegexKitLite.h"

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

+ (NSMutableAttributedString *)emoticonAttributedWithText:(NSString *)text font:(UIFont *)font
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] init];
    
    // 表情的规则
    NSString *emotionPattern = @"\\[[0-9a-zA-Z\\u4e00-\\u9fa5]+\\]";
    // @的规则
    // NSString *atPattern = @"@[0-9a-zA-Z\\u4e00-\\u9fa5-_]+";
    // #话题#的规则
    // NSString *topicPattern = @"#[0-9a-zA-Z\\u4e00-\\u9fa5]+#";
    // url链接的规则
    // NSString *urlPattern = @"\\b(([\\w-]+://?|www[.])[^\\s()<>]+(?:\\([\\w\\d]+\\)|([^[:punct:]\\s]|/)))";
    
    // 遍历所有的特殊字符串 <此处仅仅遍历表情>
    NSMutableArray *parts = [NSMutableArray array];
    [text enumerateStringsMatchedByRegex:emotionPattern usingBlock:^(NSInteger captureCount, NSString *const __unsafe_unretained *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        if ((*capturedRanges).length == 0) return ;
        HJTextPart *part = [[HJTextPart alloc] init];
        part.text = *capturedStrings;   // 表情对应的文字
        part.range = *capturedRanges;
        part.emotion = YES;
        [parts addObject:part];
    }];
    
    // 遍历所有非特殊字符
    [text enumerateStringsSeparatedByRegex:emotionPattern usingBlock:^(NSInteger captureCount, NSString *const __unsafe_unretained *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        
        HJTextPart *part = [[HJTextPart alloc] init];
        part.text = *capturedStrings;   // 表情对应的文字
        part.range = *capturedRanges;
        [parts addObject:part];
        
    }];
    
    
    // 排序
    [parts sortUsingComparator:^NSComparisonResult(HJTextPart *part1, HJTextPart *part2) {
        if (part1.range.location > part2.range.location) {
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
    }];
    
    // 遍历对应的表情
    ESEmoticonTool *emoticonTool = [[ESEmoticonTool alloc] init];
    for (HJTextPart *part in parts) {
        NSAttributedString *subStr = nil;
        if (part.isEmotion) { // 如果是表情
            NSString *imageName = [emoticonTool hj_emticonImageNameByEmticonName:part.text];
            NSTextAttachment *attch = [[NSTextAttachment alloc] init];
            if (imageName) {
                UIImage *image = [UIImage imageNamed:imageName];
                attch.image = image;
                attch.bounds = CGRectMake(0, -3, font.lineHeight, font.lineHeight);
                subStr = [NSAttributedString attributedStringWithAttachment:attch];
            }else{
                subStr = [[NSAttributedString alloc] initWithString:part.text];
            }
        }else{  // 非表情字符串
            subStr = [[NSAttributedString alloc] initWithString:part.text];
        }
        
        [attributedText appendAttributedString:subStr];
    }
    // 设置文字大小 保证计算的高度正确
    [attributedText addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, attributedText.length)];
    return attributedText;
}

@end


@implementation HJTextPart



@end
