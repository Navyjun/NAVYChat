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
// 针对 WebRTC 信令的发送/接收
- (void)socketManager:(SocketManager *)manager  RTCDidReadData:(NSDictionary *)readDic;
@end

@interface SocketManager : NSObject
/// delegate
@property (nonatomic, weak) id <SocketManagerDelegate> delegate;
/// 保存数据的主地址
@property (nonatomic, copy)  NSString *dataSavePath;
/// 当有多个需要发送时
@property (nonatomic, strong) NSMutableArray *needSendMoreItems;
+ (instancetype)shareSockManager;
/// 监听端口
- (BOOL)startListenPort:(uint16_t)prot;
/// 连接
- (BOOL)connentHost:(NSString *)host prot:(uint16_t)port;
/// 发送数据 <单条数据的发送>
- (void)sendMessageWithItem:(ChatMessageModel *)item;
/// 值针对 rtc 信息的发送
- (void)RTCMessageSendWithData:(NSData*)rtcData;
@end
