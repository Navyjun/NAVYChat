//
//  HJProgressHub.h
//  ZPS
//
//  Created by 张海军 on 2017/12/1.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HJProgressHub : UIView
/// progress
@property (nonatomic, assign) CGFloat progress;

+ (instancetype)progressHubWithFrame:(CGRect)frame;

@end
