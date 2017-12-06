//
//  WebRTCHelper.h
//  ZPS
//
//  Created by 张海军 on 2017/12/6.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketManager.h"

@interface WebRTCHelper : NSObject

+ (instancetype)shareWebRTCHelper;

// 用于测试
- (void)createOffers;

@end
