//
//  SockManager.m
//  ZPS
//
//  Created by 张海军 on 2017/11/28.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "SocketManager.h"
#import "GCDAsyncSocket.h"
#import <MJExtension.h>

// 当接受到SENDFILEHEADINFO  服务端发送的字符
static NSString *const FILE_ACCEPT_END = @"FILE_ACCEPT_END";


@interface SocketManager()
/// socket
@property (nonatomic, strong) GCDAsyncSocket *tcpSocketManager;
/// 客户端socket集合
@property (nonatomic, strong) NSMutableArray *clientSocketArray;
/// 当前正在传送的item
@property (nonatomic, strong) ChatMessageModel *currentSendItem;
/// 当前传输的下标值
@property (nonatomic, assign) NSInteger currentSendTag;
/// 当前接收到的item
@property (nonatomic, strong) ChatMessageModel *acceptItem;
/// 输出流
@property (nonatomic, strong) NSOutputStream *outputStream;

/// 用户接收 比较长的字符串
@property (nonatomic, copy) NSString *saveAcceptLongStr;
@end

@implementation SocketManager
static SocketManager *manager = nil;
+ (instancetype)shareSockManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SocketManager alloc] init];
    });
    return manager;
}

#pragma mark - method
/// 连接
- (BOOL)connentHost:(NSString *)host prot:(uint16_t)port{
    if (host==nil || host.length <= 0) {
        NSAssert(host != nil, @"host must be not nil");
    }
    
    // 确保先断开连接
    [self.tcpSocketManager disconnect];
    self.tcpSocketManager.delegate = nil;
    self.tcpSocketManager = nil;
    if (self.tcpSocketManager == nil) {
        self.tcpSocketManager = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    NSError *connectError = nil;
    [self.tcpSocketManager connectToHost:host onPort:port error:&connectError];
    
    if (connectError) {
        MYLog(@"连接失败");
        return NO;
    }
    // 可读取服务端数据
    [self.tcpSocketManager readDataWithTimeout:-1 tag:0];
    return YES;
}


/// 监听端口
- (BOOL)startListenPort:(uint16_t)prot{
    if (prot <= 0) {
        NSAssert(prot > 0, @"prot must be more zero");
    }
    
    if (!self.tcpSocketManager) {
        self.tcpSocketManager = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    }
    [self.tcpSocketManager disconnect];
    
    NSError *error = nil;
    BOOL result = [self.tcpSocketManager acceptOnPort:prot error:&error];
    if (result && !error) {
        MYLog(@"监听%zd端口成功",prot);
        return YES;
    }else{
        MYLog(@"监听端口失败");
        return NO;
    }
}

/// 发送数据
- (void)sendMessageWithItem:(ChatMessageModel *)item{
    item.atSendArrayIndex = self.needSendMoreItems.count;
    [self.needSendMoreItems addObject:item];
    if (self.needSendMoreItems.count < 2) {
        [self sendOneMessageItem:item];
    }else{
        
    }
}

- (void)sendOneMessageItem:(ChatMessageModel *)item{
    self.currentSendItem = item;
    NSData *textData = [self creationMessageDataWithItem:item];
    [self writeMediaMessageWithData:textData];
}

// 创建消息体
- (NSData *)creationMessageDataWithItem:(ChatMessageModel *)item{
    NSMutableDictionary *messageData = [NSMutableDictionary dictionary];
    messageData[@"fileName"] = item.fileName;
    messageData[@"userName"] = item.userName;
    messageData[@"chatMessageType"] = [NSNumber numberWithInt:item.chatMessageType];
    messageData[@"fileSize"] = [NSNumber numberWithInteger:item.fileSize];
    messageData[@"mediaDuration"] = [NSNumber numberWithFloat:item.mediaDuration];
    if (item.chatMessageType == ChatMessageText) {
        messageData[@"messageContent"] = item.messageContent;
    }else if (item.chatMessageType == ChatMessageImage || item.chatMessageType == ChatMessageVideo || item.chatMessageType == ChatMessageAudio){
        item.isWaitAcceptFile = YES;
        messageData[@"isWaitAcceptFile"] = [NSNumber numberWithBool:YES];
    }
    NSString *bodStr = [NSString hj_dicToJsonStr:messageData];
    return [bodStr dataUsingEncoding:NSUTF8StringEncoding];
}

// 图片或者视频文件传输
- (void)imageOrVideoFileSend:(ChatMessageModel *)sendItem{
    if (sendItem.chatMessageType == ChatMessageImage) {
        NSData *sendData = UIImagePNGRepresentation(sendItem.temImage);
        [self writeMediaMessageWithData:sendData];
    }else if (sendItem.chatMessageType == ChatMessageVideo){
        PHAsset *asset = (PHAsset *)sendItem.asset;
        [ZPPublicMethod getfilePath:asset Complete:^(NSURL *fileUrl) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                sendItem.mediaMessageUrl = fileUrl;
                NSData *sendData = [NSData dataWithContentsOfURL:sendItem.mediaMessageUrl options:NSDataReadingMappedIfSafe error:nil];
                [self writeMediaMessageWithData:sendData];
            });
        }];
    }else if (sendItem.chatMessageType == ChatMessageAudio){
        NSData *sendData = [NSData dataWithContentsOfURL:sendItem.mediaMessageUrl options:NSDataReadingMappedIfSafe error:nil];
        [self writeMediaMessageWithData:sendData];
    }
    
}

// 传输数据到服务端
- (void)writeMediaMessageWithData:(NSData *)sendData{
    self.currentSendTag += 1;
    self.currentSendItem.sendTag = self.currentSendTag;
    if (self.clientSocketArray.count > 0) {
        GCDAsyncSocket *clientSocket = [self.clientSocketArray firstObject];
        [clientSocket writeData:sendData withTimeout:-1 tag:self.currentSendItem.sendTag];
    }else{
        [self.tcpSocketManager writeData:sendData withTimeout:-1 tag:self.currentSendItem.sendTag];
    }
}

// 媒体文件接受完成后发送的消息
- (void)sendMediaAcceptEndMessage{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSData *data = [FILE_ACCEPT_END dataUsingEncoding:NSUTF8StringEncoding];
        self.currentSendItem = nil;
        if (self.clientSocketArray.count > 0) {
            GCDAsyncSocket *clientSocket = [self.clientSocketArray firstObject];
            [clientSocket writeData:data withTimeout:-1 tag:-99999];
        }else{
            [self.tcpSocketManager writeData:data withTimeout:-1 tag:-99999];
        }
    });
}

// 发送下一个消息体
- (void)sendNextMessage{
    if (self.needSendMoreItems.count > 0) {
        [self sendOneMessageItem:[self.needSendMoreItems firstObject]];
    }
}

#pragma mark - rtc message send
- (void)RTCMessageSendWithData:(NSData *)rtcData withTag:(long)tag{
    if (self.clientSocketArray.count > 0) {
        GCDAsyncSocket *clientSocket = [self.clientSocketArray firstObject];
        [clientSocket writeData:rtcData withTimeout:-1 tag:tag];
    }else{
        [self.tcpSocketManager writeData:rtcData withTimeout:-1 tag:tag];
    }
}

#pragma mark - GCDSocketDelegate
/// 新的客户端连接上
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    if (!self.clientSocketArray) {
        self.clientSocketArray = [NSMutableArray array];
    }else{
        // 目前只做点对点的聊天
        [self.clientSocketArray removeAllObjects];
    }
    [self.clientSocketArray addObject:newSocket];
    [newSocket readDataWithTimeout:- 1 tag:0];
    NSLog(@"%s",__func__);
}

/// 客户端连接到的
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"%s",__func__);
}

/// 接收到消息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    [sock readDataWithTimeout:- 1 tag:0];
    
    NSString *readStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *readDic = [readStr hj_jsonStringToDic];
    //MYLog(@"readDic = %@",readDic);
    
    // webRTC 音视频通话的处理  RTC 专用回调
    if (readDic == nil) {
        NSString *rtcType = @"{\"type\":\"";
        if ([readStr containsString:rtcType] || (self.saveAcceptLongStr.length > 0)) {
            NSDictionary *rtcDic = [self.saveAcceptLongStr hj_jsonStringToDic];
            if (rtcDic == nil && self.saveAcceptLongStr.length) {
                self.saveAcceptLongStr = [NSString stringWithFormat:@"%@%@",self.saveAcceptLongStr,readStr];
                rtcDic = [self.saveAcceptLongStr hj_jsonStringToDic];
                if (rtcDic) {
                    readDic = rtcDic;
                }
            }
            
            if (self.saveAcceptLongStr.length <= 0) {
                self.saveAcceptLongStr = readStr;
            }
        }
    }
    if (readDic[@"sdp"] || readDic[@"type"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kReceivedSinalingMessageNotification" object:nil userInfo:readDic];
        self.saveAcceptLongStr = nil;
        return;
    }
    
    
    // 发送消息的处理
    if ([readStr isEqualToString:FILE_ACCEPT_END]) {
        [self sendNextMessage];
        return;
    }else if ([readDic isKindOfClass:[NSDictionary class]]) { // 此处还需考虑发送 超长字符串内容的处理
        
        self.acceptItem = [ChatMessageModel mj_objectWithKeyValues:readDic];
        self.acceptItem.isFormMe = NO;
        self.acceptItem.finishAccept = self.acceptItem.chatMessageType != ChatMessageText ? NO : YES;
        
    }else if (self.acceptItem.isWaitAcceptFile) {
        self.acceptItem.finishAccept = NO;
        self.acceptItem.acceptSize += data.length;
        self.acceptItem.beginAccept = YES;
        if (!self.outputStream) {
            self.acceptItem.acceptFilePath = [self.dataSavePath stringByAppendingPathComponent:[self.acceptItem.fileName lastPathComponent]];
            self.acceptItem.mediaMessageUrl = [NSURL fileURLWithPath:self.acceptItem.acceptFilePath];
            self.acceptItem.showImageUrl = self.acceptItem.chatMessageType == ChatMessageImage ? self.acceptItem.mediaMessageUrl : nil;
            self.outputStream = [[NSOutputStream alloc] initToFileAtPath:self.acceptItem.acceptFilePath append:YES];
            [self.outputStream open];
        }
        // 输出流 写数据
        NSInteger byt = [self.outputStream write:data.bytes maxLength:data.length];
        MYLog(@"byt = %zd totalSize = %zd acceptSize = %zd,datal = %zd",byt,self.acceptItem.fileSize,self.acceptItem.acceptSize,data.length);
        if (self.acceptItem.acceptSize >= self.acceptItem.fileSize) {
            self.acceptItem.finishAccept = YES;
            [self.outputStream close];
            self.outputStream = nil;
            [self sendMediaAcceptEndMessage];
        }
    }else{
        
    }
    
    if ([self.delegate respondsToSelector:@selector(socketManager:itemAcceptingrefresh:)]) {
        [self.delegate socketManager:self itemAcceptingrefresh:self.acceptItem];
    }
    
    
    
}

// 文件传输完毕后的回调
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    MYLog(@"%s \n tag = %ld",__func__,tag);
    if ([self.rtcDelegate respondsToSelector:@selector(socketManager:didWriteDataWithTag:)]) {
        [self.rtcDelegate socketManager:self didWriteDataWithTag:tag];
    }
    if (self.currentSendItem.sendTag == tag) {
        if (!self.currentSendItem.isWaitAcceptFile) {
            self.currentSendItem.temImage = nil;
            self.currentSendItem.sendSuccess = YES;
            self.currentSendItem.isSendFinish = YES;
            self.currentSendItem.isSending = NO;
            if ([self.delegate respondsToSelector:@selector(socketManager:itemUpFinishrefresh:)]) {
                [self.delegate socketManager:self itemUpFinishrefresh:self.currentSendItem];
            }

            for (ChatMessageModel *item in self.needSendMoreItems.reverseObjectEnumerator) {
                if (item.isSendFinish) {
                    [self.needSendMoreItems removeObject:item];
                }
            }
            
        }else{
            // 接下来需要传输文件
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.currentSendItem.isWaitAcceptFile = NO; // 改变状态
                [self imageOrVideoFileSend:self.currentSendItem];
            });
        }
    }
    
    [self.tcpSocketManager setAutoDisconnectOnClosedReadStream:YES];
    
}

// 分段传输完成后的 回调
- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    MYLog(@"%lu--tag = %zd",partialLength,tag);
    self.currentSendItem.upSize += partialLength;
    if ([self.delegate respondsToSelector:@selector(socketManager:itemUpingrefresh:)] && (tag==self.currentSendItem.sendTag)) {
        self.currentSendItem.isSending = YES;
        [self.delegate socketManager:self itemUpingrefresh:self.currentSendItem];
    }
}

/// 大文件  分段读取数据
- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag{
    NSLog(@"%s",__func__);
}


///
- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock{
    NSLog(@"%s",__func__);
}

/// 断开连接
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    NSLog(@"%s - err=%@",__func__,err.localizedDescription);
    [self.clientSocketArray removeAllObjects];
    [self.needSendMoreItems removeAllObjects];
    self.currentSendItem = nil;
    self.currentSendTag = 0;
    self.acceptItem = nil;
    self.tcpSocketManager = nil;
    self.outputStream = nil;
}

///
- (void)socketDidSecure:(GCDAsyncSocket *)sock{
    NSLog(@"%s",__func__);
}

#pragma mark - lazy
- (NSString *)dataSavePath{
    if (!_dataSavePath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *filePath = [@"socketData" cacheDir];
        if(![fileManager fileExistsAtPath:filePath]){
            [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        _dataSavePath = filePath;
        NSLog(@"filePath = %@",filePath);
    }
    return _dataSavePath;
}

- (NSMutableArray *)needSendMoreItems{
    if (!_needSendMoreItems) {
        _needSendMoreItems = [NSMutableArray array];
    }
    return _needSendMoreItems;
}

@end
