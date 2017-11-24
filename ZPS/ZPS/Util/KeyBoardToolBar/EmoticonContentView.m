//
//  EmoticonContentView.m
//  QianEyeShow
//
//  Created by 张海军 on 16/8/11.
//  Copyright © 2016年 baoqianli. All rights reserved.
//

#import "EmoticonContentView.h"
#import "ESEmotionModel.h"

@interface EmoticonContentView ()
/// 删除按钮
@property (nonatomic, strong) EmoticonButton *deleteButton;

@end

@implementation EmoticonContentView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        self.deleteButton = [[EmoticonButton alloc] init];
        [self.deleteButton setImage:[UIImage imageNamed:@"表情删除"] forState:UIControlStateNormal];
        [self.deleteButton addTarget:self action:@selector(emotionDelegateButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        self.deleteButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // 内边距(四周)
    CGFloat inset = 15;
    NSUInteger count = self.emotions.count;
    CGFloat btnW = (self.hj_width - 2 * inset) / ESEmotionMaxCols;
    CGFloat btnH = (self.hj_height - inset) / ESEmotionMaxRows;
    for (int i = 0; i<count; i++) {
        UIButton *btn = self.subviews[i];
        btn.hj_width = btnW;
        btn.hj_height = btnH;
        btn.x = inset + (i % ESEmotionMaxCols) * btnW;
        btn.y = inset + (i / ESEmotionMaxCols) * btnH;
    }
    
    CGFloat deleteX = self.hj_width - inset - btnW;
    CGFloat deleteY = self.hj_height - btnH;
    self.deleteButton.frame = CGRectMake(deleteX, deleteY, btnW, btnH);
    
}

- (void)setEmotions:(NSArray *)emotions
{
    _emotions = emotions;
    
    NSUInteger count = emotions.count;
    ESEmotionModel *emotion = nil;
    for (int i = 0; i<count; i++) {
        EmoticonButton *btn = [[EmoticonButton alloc] init];
        btn.imageView.contentMode = UIViewContentModeScaleAspectFit;
        btn.tag = i;
        emotion = emotions[i];
        UIImage *image = [UIImage imageNamed:emotion.png];
        [btn setImage:image forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:32];
        [btn addTarget:self action:@selector(emoticonButtonClik:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:btn];
    }
    
    [self addSubview:self.deleteButton];
}

#pragma mark - event
- (void)emoticonButtonClik:(UIButton *)button
{
    ESEmotionModel *emotion = _emotions[button.tag];
    if ([self.delegate respondsToSelector:@selector(emoticonContentInsetEmoticon:insetMessage:)]) {
        [self.delegate emoticonContentInsetEmoticon:self insetMessage:emotion.chs];
    }
    
}

// 删除按钮
- (void)emotionDelegateButtonClick:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(emoticonContentDeleteEmoticon:)]) {
        [self.delegate emoticonContentDeleteEmoticon:self];
    }
}

@end


@implementation EmoticonButton

- (void)layoutSubviews
{
    [super layoutSubviews];
    UIFont *font = [UIFont systemFontOfSize:28.0]; //HJFont(28.0);
    CGFloat WH = font.lineHeight;
    CGFloat x = (self.hj_width - WH) * 0.5;
    CGFloat y = (self.hj_height - WH) * 0.5;
    self.imageView.frame = CGRectMake(x, y, WH, WH);
}

@end
