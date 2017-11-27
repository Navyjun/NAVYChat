//
//  ESAddOpationView.m
//  ZPS
//
//  Created by 张海军 on 2017/11/27.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "ESAddOpationView.h"
static CGFloat viewH = 216;

@implementation ESAddOpationView
+ (instancetype)addOpationView{
    ESAddOpationView *opationView = [[ESAddOpationView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, viewH)];
    opationView.backgroundColor = [UIColor colorWithRed:241.0/255.0 green:242.0/255.0 blue:245.0/255.0 alpha:1];
    return opationView;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    CGFloat lRMargin = 15.0;
    CGFloat bottomM = 20.0;
    NSInteger rowCount = 4;
    NSInteger lineCount = 2;
    
    CGFloat buttonW = (self.hj_width-2*lRMargin)/rowCount;
    CGFloat buttonH = (self.hj_height-bottomM)/lineCount;
    
    NSInteger count = self.subviews.count;
    for (NSInteger i = 0; i < count; i++) {
        UIButton *button = self.subviews[i];
        button.hj_width = buttonW;
        button.hj_height = buttonH;
        button.x = lRMargin + (i % rowCount) * buttonW;
        button.y = (i / rowCount) * buttonH;
    }
}


- (void)setOpationItem:(NSArray<OpationItem *> *)opationItem{
    _opationItem = opationItem;
    NSInteger count = opationItem.count;
    for (NSInteger i = 0; i < count; i++) {
        OpationItem *item = opationItem[i];
        OpationButton *button = [[OpationButton alloc] init];
        button.tag = i;
        [button setTitle:item.itemName forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:item.itemIconName] forState:UIControlStateNormal];
        [self addSubview:button];
    }
}

@end



@implementation OpationItem

+ (instancetype)opationItemWithName:(NSString *)itemName iconName:(NSString *)iconName{
    OpationItem *item = [[self alloc] init];
    item.itemName = itemName;
    item.itemIconName = iconName;
    return item;
}

@end


@implementation OpationButton
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont systemFontOfSize:15.0];
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    self.titleLabel.frame = CGRectMake(0,
                                       self.hj_height - self.titleLabel.hj_height,
                                       self.hj_width,
                                       self.titleLabel.hj_height);
    CGFloat imgW = 56.0;
    self.imageView.frame = CGRectMake((self.hj_width - imgW)*0.5,
                                      self.hj_height - self.titleLabel.hj_height - imgW - 5,
                                      imgW, imgW);
}

@end
