//
//  ChatMessageModel.h
//  ZPS
//
//  Created by 张海军 on 2017/11/23.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <Foundation/Foundation.h>

static CGFloat const messageLabelForHeadLeftMargin = 15.0;
static CGFloat const messageLabelForHeadRightMargin = 8.0;

@interface ChatMessageModel : NSObject
/// userName
@property (nonatomic, copy) NSString *userName;
/// userIcon
@property (nonatomic, copy) NSString *iconUrl;
/// 消息类型
@property (nonatomic, assign) NSInteger messageType;
/// 消息内容 文字
@property (nonatomic, copy) NSString *messageContent;
/// 媒体消息本地保存地址
@property (nonatomic, copy) NSString *mediaMessageUrl;
/// 是否来至于自己
@property (nonatomic, assign) BOOL isFormMe;

/// 消息宽度
@property (nonatomic, assign) CGFloat messageW;
/// 消息高度
@property (nonatomic, assign) CGFloat messageH;
/// cell高度
@property (nonatomic, assign) CGFloat cellH;
@end
