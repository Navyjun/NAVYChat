//
//  ZPCommentData.h
//  ZPW
//
//  Created by 张海军 on 2017/11/8.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <Foundation/Foundation.h>

///  当前扫描得到的 ip
UIKIT_EXTERN NSString *CURRENT_HOST;
///  当前扫描得到的 端口号
UIKIT_EXTERN NSInteger CURRENT_PORT;
///  当前扫描得到的 wifi 名称
UIKIT_EXTERN NSString *CURRENT_WIFINAME;

///  当前聊天 对方的名称
UIKIT_EXTERN NSString *CURRENT_FRIENDNAME;
///  当前聊天 自己的名称
UIKIT_EXTERN NSString *CURRENT_MENAME;
/// 当前连接状态
UIKIT_EXTERN BOOL CURRENT_CONNECT_STATE;

@interface ZPCommentData : NSObject

@end
