//
//  HJProgressHub.m
//  ZPS
//
//  Created by 张海军 on 2017/12/1.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "HJProgressHub.h"

@interface HJProgressHub()
/// 菊花
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
/// 灰色的板子
@property (nonatomic, strong) UIView *grayView;
/// 进度label
@property (nonatomic, strong) UILabel *progressLabel;
@end

@implementation HJProgressHub
+ (instancetype)progressHub{
    HJProgressHub *hub = [[HJProgressHub alloc] init];
    [hub setupUI];
    return hub;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.grayView.frame = self.bounds;
    self.indicatorView.center = CGPointMake(self.hj_width * 0.5, self.hj_height * 0.5);
    self.progressLabel.frame = CGRectMake(0, CGRectGetMaxY(self.indicatorView.frame), self.hj_width, 30);
}

- (void)setupUI{
    self.grayView = [[UIView alloc] initWithFrame:self.bounds];
    self.grayView.backgroundColor = [UIColor colorWithRed:90.0/255.0 green:92.0/255.0 blue:96.0/255.0 alpha:0.7];
    [self addSubview:self.grayView];
    
    self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self addSubview:self.indicatorView];
    
    
    self.progressLabel = [[UILabel alloc] init];
    self.progressLabel.textColor = [UIColor whiteColor];
    self.progressLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.progressLabel];
    
}

- (void)setProgress:(CGFloat)progress{
    self.grayView.hidden = NO;
    _progress = progress;
    [self.indicatorView startAnimating];
    self.progressLabel.text = [NSString stringWithFormat:@"%.2f%%",progress*100];
    NSLog(@"+++++++++++++++++++progressLabelText = %@",self.progressLabel.text);
    if (progress >= 1.0) {
        [self.indicatorView stopAnimating];
        self.grayView.hidden = YES;
        self.progressLabel.text = nil;
    }
}


@end
