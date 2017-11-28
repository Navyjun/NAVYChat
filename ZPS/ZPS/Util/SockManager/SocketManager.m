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
    self.currentSendItem = item;
    if (item.chatMessageType == ChatMessageText) {
        NSData *textData = [self creationMessageDataWithItem:item];
        [self writeMediaMessageWithData:textData];
    }else if (item.chatMessageType == ChatMessageImage || item.chatMessageType == ChatMessageVideo){
        [self imageOrVideoFileSend:item];
    }
}

// 创建消息体
- (NSData *)creationMessageDataWithItem:(ChatMessageModel *)item{
    NSMutableDictionary *messageData = [NSMutableDictionary dictionary];
    messageData[@"fileName"] = item.fileName;
    messageData[@"userName"] = item.userName;
    messageData[@"chatMessageType"] = [NSNumber numberWithInt:item.chatMessageType];
    messageData[@"fileSize"] = [NSNumber numberWithInteger:item.fileSize];
    if (item.chatMessageType == ChatMessageText) {
        messageData[@"messageContent"] = item.messageContent;
    }
    NSString *bodStr = [NSString hj_dicToJsonStr:messageData];
    return [bodStr dataUsingEncoding:NSUTF8StringEncoding];
}

// 图片或者视频文件传输
- (void)imageOrVideoFileSend:(ChatMessageModel *)sendItem{
    PHAsset *asset = (PHAsset *)sendItem.asset;
    [ZPPublicMethod getfilePath:asset Complete:^(NSURL *fileUrl) {
        sendItem.mediaMessageUrl = fileUrl;
        NSData *sendData = [NSData dataWithContentsOfURL:sendItem.mediaMessageUrl options:NSDataReadingMappedIfSafe error:nil];
        [self writeMediaMessageWithData:sendData];
    }];
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
}

/// 客户端连接到的
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"%s",__func__);
}

/// 接收到消息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *readStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *readDic = [readStr hj_jsonStringToDic];
    
    if ([readDic isKindOfClass:[NSDictionary class]]) {
        self.acceptItem = [ChatMessageModel mj_objectWithKeyValues:readDic];
        self.acceptItem.isFormMe = NO;
        // 接收到非字符串类型
        self.acceptItem.isWaitAcceptFile = self.acceptItem.chatMessageType != ChatMessageText ? YES : NO;
    }
   
    if (self.acceptItem.isWaitAcceptFile) {
        self.acceptItem.acceptSize += data.length;
        self.acceptItem.beginAccept = YES;
        NSLog(@"acceptSize = %zd",self.acceptItem.acceptSize);
        if (!self.outputStream) {
            self.acceptItem.acceptFilePath = [self.dataSavePath stringByAppendingPathComponent:[_currentSendItem.fileName lastPathComponent]];
            self.outputStream = [[NSOutputStream alloc] initToFileAtPath:self.acceptItem.acceptFilePath append:YES];
            [self.outputStream open];
        }
        // 输出流 写数据
        NSInteger byt = [self.outputStream write:data.bytes maxLength:data.length];
        NSLog(@"byt = %zd",byt);
        
        if (self.acceptItem.acceptSize >= self.acceptItem.fileSize) {
            _currentSendItem.finishAccept = YES;
            [self.outputStream close];
            self.outputStream = nil;
        }
    }else{
        self.acceptItem.finishAccept = YES;
    }
    
    if ([self.delegate respondsToSelector:@selector(socketManager:itemAcceptingrefresh:)]) {
        [self.delegate socketManager:self itemAcceptingrefresh:self.acceptItem];
    }
    
    [sock readDataWithTimeout:- 1 tag:0];
    
}

// 文件传输完毕后的回调
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    MYLog(@"%s \n tag = %ld",__func__,tag);
    if ([self.delegate respondsToSelector:@selector(socketManager:itemUpFinishrefresh:)]) {
        [self.delegate socketManager:self itemUpFinishrefresh:self.currentSendItem];
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
        NSLog(@"%@",filePath);
    }
    return _dataSavePath;
}

@end