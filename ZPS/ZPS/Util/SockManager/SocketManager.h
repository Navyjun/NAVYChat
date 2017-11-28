//
//  SockManager.h
//  ZPS
//
//  Created by 张海军 on 2017/11/28.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ChatMessageModel.h"
@class SocketManager;

@protocol SocketManagerDelegate <NSObject>
// 正在上传的文件回调
- (void)socketManager:(SocketManager *)manager  itemUpingrefresh:(ChatMessageModel *)upingItem;
// 文件上传完毕的回调
- (void)socketManager:(SocketManager *)manager  itemUpFinishrefresh:(ChatMessageModel *)finishItem;
// 正在接受的文件回调
- (void)socketManager:(SocketManager *)manager  itemAcceptingrefresh:(ChatMessageModel *)acceptingItem;

@end

@interface SocketManager : NSObject
/// delegate
@property (nonatomic, weak) id <SocketManagerDelegate> delegate;
/// 保存数据的主地址
@property (nonatomic, copy)  NSString *dataSavePath;

+ (instancetype)shareSockManager;
/// 监听端口
- (BOOL)startListenPort:(uint16_t)prot;
/// 连接
- (BOOL)connentHost:(NSString *)host prot:(uint16_t)port;
/// 发送数据
- (void)sendMessageWithItem:(ChatMessageModel *)item;
@end
