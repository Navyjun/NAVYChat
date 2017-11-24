//
//  ESEmoticonView.m
//  QianEyeShow
//
//  Created by 张海军 on 16/8/11.
//  Copyright © 2016年 baoqianli. All rights reserved.
//

#import "ESEmoticonView.h"
#import "EmoticonContentView.h"


static CGFloat viewH = 216;

@interface ESEmoticonView () <UIScrollViewDelegate, EmoticonContentViewDelegate>
/// 表情内容view
@property (nonatomic, strong) UIScrollView *emoticonContentView;
/// 显示多少页
@property (nonatomic, strong) UIPageControl *pageControl;
/// 间隔线
@property (nonatomic, strong) UIView *marginView;
/// 底部的选项卡view
@property (nonatomic, strong) UIView *bottomOpationView;
/// 发送按钮
@property (nonatomic, strong) UIButton *sendButton;
@end

@implementation ESEmoticonView
+ (instancetype)emoticonView
{
    ESEmoticonView *view = [[ESEmoticonView alloc] initWithFrame:CGRectMake(0, 0, HJSCREENW, viewH)];
    
    return view;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupInit];
    }
    return self;
}

- (void)setupInit
{
    CGFloat bottomH = 36;
    
    // 表情内容view
    self.emoticonContentView = [[UIScrollView alloc] init];
    self.emoticonContentView.pagingEnabled = YES;
    self.emoticonContentView.showsVerticalScrollIndicator = NO;
    self.emoticonContentView.showsHorizontalScrollIndicator = NO;
    self.emoticonContentView.frame = CGRectMake(0, 0, HJSCREENW, viewH - bottomH - 20);
    self.emoticonContentView.delegate = self;
    self.emoticonContentView.bounces = NO;
    [self addSubview:self.emoticonContentView];
    
    // 显示多少页表情
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.currentPage = 0;
    self.pageControl.numberOfPages = 3;
    self.pageControl.currentPageIndicatorTintColor = [UIColor grayColor];
    self.pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    [self addSubview:self.pageControl];
    self.pageControl.size = CGSizeMake(100, 20);
    self.pageControl.y = viewH - bottomH - 20;
    self.pageControl.centerX = HJSCREENW * 0.5;

    // 分割线
    self.marginView = [[UIView alloc] init];
    self.marginView.backgroundColor = [UIColor grayColor];
    self.marginView.frame = CGRectMake(0, 0, HJSCREENW, 0.5);
    
    
    // 底部选择卡
    self.bottomOpationView = [[UIView alloc] init];
    self.bottomOpationView.backgroundColor = [UIColor whiteColor];
    self.bottomOpationView.frame = CGRectMake(0, viewH - bottomH, HJSCREENW, bottomH);
    [self addSubview:self.bottomOpationView];
    
    // 发送按钮
    self.sendButton = [[UIButton alloc] init];
    [self.sendButton setTitle:@"发送" forState:UIControlStateNormal];
    [self.sendButton setTitle:@"发送" forState:UIControlStateDisabled];
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    [self.sendButton setBackgroundImage:[UIImage imageWithColor:[UIColor grayColor]] forState:UIControlStateDisabled];
    [self.sendButton setBackgroundImage:[UIImage imageWithColor:[UIColor grayColor]] forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(sendButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.frame = CGRectMake(HJSCREENW - 80, 0, 80, bottomH);
    
    [self.bottomOpationView addSubview:self.sendButton];
    [self.bottomOpationView addSubview:self.marginView];
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // 3.设置scrollView内部每一页的尺寸
    NSUInteger count = self.emoticonContentView.subviews.count;
    for (int i = 0; i<count; i++) {
        ESEmoticonView *pageView = self.emoticonContentView.subviews[i];
        pageView.hj_height = self.emoticonContentView.hj_height;
        pageView.hj_width = self.emoticonContentView.hj_width;
        pageView.x = pageView.hj_width * i;
        pageView.y = 0;
    }
    
    // 4.设置scrollView的contentSize
    self.emoticonContentView.contentSize = CGSizeMake(count * self.emoticonContentView.hj_width, 0);
}



- (void)setEmotions:(NSArray *)emotions
{
    _emotions = emotions;
    
    NSUInteger count = (emotions.count + ESEmotionPageSize - 1) / ESEmotionPageSize;
    
    // 1.设置页数
    self.pageControl.numberOfPages = count;
    
    // 2.创建用来显示每一页表情的控件
    for (int i = 0; i<count; i++) {
        EmoticonContentView *pageView = [[EmoticonContentView alloc] init];
        pageView.delegate = self;
        // 计算这一页的表情范围
        NSRange range;
        range.location = i * ESEmotionPageSize;
        // left：剩余的表情个数（可以截取的）
        NSUInteger left = emotions.count - range.location;
        if (left >= ESEmotionPageSize) { // 这一页足够20个
            range.length = ESEmotionPageSize;
        } else {
            range.length = left;
        }
        // 设置这一页的表情
        pageView.emotions = [emotions subarrayWithRange:range];
        [self.emoticonContentView addSubview:pageView];
    }
}

#pragma mark - event
- (void)sendButtonDidClick:(UIButton *)button
{
    if (_sendButtonDidClickBlock) {
        _sendButtonDidClickBlock();
    }
}

#pragma mark - scrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    double pageNo = scrollView.contentOffset.x / scrollView.hj_width;
    self.pageControl.currentPage = (int)(pageNo + 0.5);
}

// 点击表情的回调
- (void)emoticonContentInsetEmoticon:(EmoticonContentView *)view insetMessage:(NSString *)message
{
    if (_insetEmoticonBlock) {
        _insetEmoticonBlock(message);
    }
}
// 删除表情的回调
- (void)emoticonContentDeleteEmoticon:(EmoticonContentView *)view;
{
    if (_deleteEmoticonBlock) {
        _deleteEmoticonBlock();
    }
}

@end
