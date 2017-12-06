//
//  WebRTCHelper.m
//  ZPS
//
//  Created by 张海军 on 2017/12/6.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "WebRTCHelper.h"
#import "RTCMediaStream.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCPeerConnection.h"
#import "RTCPair.h"
#import "RTCMediaConstraints.h"
#import "RTCAudioTrack.h"
#import "RTCVideoTrack.h"
#import "RTCVideoCapturer.h"
#import "RTCSessionDescription.h"
#import "RTCSessionDescriptionDelegate.h"
#import "RTCEAGLVideoView.h"
#import "RTCICEServer.h"
#import "RTCVideoSource.h"
#import "RTCAVFoundationVideoSource.h"
#import "RTCICECandidate.h"

/*
 流程 :
 1:发送方点击开启视频/语音通话 -> Socket 连接 -> 发送 id
 2:接收方收到 id 保存 -> 创建所有的RTCPeerConnection -> 保存到字典 -> 给所有的RTCPeerConnection 创建offer
 3:发送方发送offer
 4:接收方收到offer -> 在发送 answer
 */


//google提供的
/*
 NSArray *stunServer = @[@"stun.l.google.com:19302",@"stun1.l.google.com:19302",@"stun2.l.google.com:19302",@"stun3.l.google.com:19302",@"stun3.l.google.com:19302",@"stun01.sipphone.com",@"stun.ekiga.net",@"stun.fwdnet.net",@"stun.fwdnet.net",@"stun.fwdnet.net",@"stun.ideasip.com",@"stun.iptel.org",@"stun.rixtelecom.se",@"stun.schlund.de",@"",@"stunserver.org",@"stun.softjoys.com",@"stun.voiparound.com",@"stun.voipbuster.com",@"stun.voipstunt.com",@"stun.voxgratia.org",@"stun.xten.com"];
 */
static NSString *const STUNSERVERURL = @"stun:stun.l.google.com:19302";
static NSString *const STUNSERVERURL2 = @"stun:23.21.150.121";

static NSString *const NEW_PEER = @"new_peer"; // 新人加入
static NSString *const OFFER = @"offer";       // offer
static NSString *const ANSWER = @"answer";     // answer
static NSString *const ICE_CANDIDATE = @"ice_candidate"; //ice_candidate

@interface WebRTCHelper () <RTCSessionDescriptionDelegate, RTCPeerConnectionDelegate, SocketManagerDelegate>
/// 工厂类 用于创建 RTCPeerConnection 类
@property (nonatomic, strong) RTCPeerConnectionFactory *connectionFactory;
/// 存储ICEServer数组
@property (nonatomic, strong) NSMutableArray *ICEServers;
/// SocketManager
@property (nonatomic, strong) SocketManager *socketM;
/// 连接ID 的保存
@property (nonatomic, strong) NSMutableArray *connectionIdArray;
/// id : RTCPeerConnection 的键值对字典
@property (nonatomic, strong) NSMutableDictionary *connectionDic;
/// 本机的连接id
@property (nonatomic, copy) NSString *myConnectionId;
@end


@implementation WebRTCHelper
#pragma mark - lazy
- (SocketManager *)socketM{
    // 单例
    SocketManager *manager = [SocketManager shareSockManager];
    manager.delegate = self;
    return manager;
}

- (NSMutableArray *)connectionIdArray{
    if (!_connectionIdArray) {
        _connectionIdArray = [NSMutableArray array];
        // 本机的ID
        NSString *connectionId = [UIDevice currentDevice].identifierForVendor.UUIDString;
        [_connectionIdArray addObject:connectionId];
    }
    return _connectionIdArray;
}

- (NSMutableDictionary *)connectionDic{
    if (!_connectionDic) {
        _connectionDic = [NSMutableDictionary dictionary];
    }
    return _connectionDic;
}

#pragma mark - life cycle
/// 初始化
static WebRTCHelper *helper = nil;
+ (instancetype)shareWebRTCHelper{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[WebRTCHelper alloc] init];
        helper.myConnectionId = [UIDevice currentDevice].identifierForVendor.UUIDString;
        [helper socketM];
    });
    return helper;
}

- (void)invitevoiceOrVideo{
    NSDictionary *dic = @{@"eventName": NEW_PEER, @"socketId": self.myConnectionId};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    [_socketM RTCMessageSendWithData:data];
}

/// 创建所有的连接
- (void)createAllPeerConnections{
    [self.connectionIdArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        RTCPeerConnection *peerConnection = [self createPeerConnection];
        [self.connectionDic setObject:peerConnection forKey:obj];
    }];
}

/// 创建点对点连接
- (RTCPeerConnection *)createPeerConnection
{
    if (!self.connectionFactory){
        //先初始化工厂
        [RTCPeerConnectionFactory initializeSSL];
        self.connectionFactory = [[RTCPeerConnectionFactory alloc] init];
    }
    
    //得到ICEServer
    if (!self.ICEServers) {
        self.ICEServers = [NSMutableArray array];
        [self.ICEServers addObject:[self stunServerWithUrlStr:STUNSERVERURL]];
        [self.ICEServers addObject:[self stunServerWithUrlStr:STUNSERVERURL2]];
    }
    
    //创建连接
    RTCPeerConnection *connection = [self.connectionFactory peerConnectionWithICEServers:self.ICEServers constraints:[self peerConnectionConstraints] delegate:self];
    return connection;
}


/// 创建所有的offer
- (void)createOffers
{
    [self.connectionDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, RTCPeerConnection *obj, BOOL * _Nonnull stop) {
        [obj createOfferWithDelegate:self constraints:[self offerOranswerConstraint]];
    }];
}


//初始化STUN Server （ICE Server）
- (RTCICEServer *)stunServerWithUrlStr:(NSString *)urlStr {

    NSURL *defaultSTUNServerURL = [NSURL URLWithString:urlStr];
    return [[RTCICEServer alloc] initWithURI:defaultSTUNServerURL
                                    username:@""
                                    password:@""];
}

/// 创建媒体约束
- (RTCMediaConstraints *)peerConnectionConstraints
{
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:@[[[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]]];
    return constraints;
}

/// 设置offer/answer的约束
- (RTCMediaConstraints *)offerOranswerConstraint
{
    NSMutableArray *array = [NSMutableArray array];
    RTCPair *receiveAudio = [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"];
    [array addObject:receiveAudio];
    
    NSString *video = @"true";
    RTCPair *receiveVideo = [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:video];
    [array addObject:receiveVideo];
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:array optionalConstraints:nil];
    return constraints;
}

- (NSString *)getKeyFromConnectionDic:(RTCPeerConnection *)peerConnection
{
    static NSString *socketId;
    [self.connectionDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, RTCPeerConnection *obj, BOOL * _Nonnull stop) {
        if ([obj isEqual:peerConnection])
        {
            NSLog(@"%@",key);
            socketId = key;
        }
    }];
    return socketId;
}


#pragma mark--RTCSessionDescriptionDelegate
// Called when creating a session.
//创建了一个SDP就会被调用，（只能创建本地的）
- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp
                 error:(NSError *)error
{
    NSLog(@"%s",__func__);
    NSLog(@"type = %@",sdp.type);
    //设置本地的SDP
    [peerConnection setLocalDescriptionWithDelegate:self sessionDescription:sdp];
    
}

// Called when setting a local or remote description.
//当一个远程或者本地的SDP被设置就会调用
- (void)peerConnection:(RTCPeerConnection *)peerConnection didSetSessionDescriptionWithError:(NSError *)error
{
    NSLog(@"%s",__func__);
    
    if (peerConnection.signalingState == RTCSignalingHaveLocalOffer) { // 创建本地offer
        // 发送offer
        NSDictionary *dic = @{@"eventName": OFFER, @"data": @{@"sdp": @{@"type": @"offer", @"sdp": peerConnection.localDescription.description}, @"socketId": self.myConnectionId}};
        NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
        [_socketM RTCMessageSendWithData:data];
    }
    
}
#pragma mark--RTCPeerConnectionDelegate
// Triggered when the SignalingState changed.
- (void)peerConnection:(RTCPeerConnection *)peerConnection signalingStateChanged:(RTCSignalingState)stateChanged
{
    NSLog(@"%s",__func__);
    NSLog(@"%d", stateChanged);
}

// Triggered when media is received on a new stream from remote peer.
- (void)peerConnection:(RTCPeerConnection *)peerConnection addedStream:(RTCMediaStream *)stream
{
    NSLog(@"%s",__func__);
}

// Triggered when a remote peer close a stream.
- (void)peerConnection:(RTCPeerConnection *)peerConnection removedStream:(RTCMediaStream *)stream
{
    NSLog(@"%s",__func__);
}

// Triggered when renegotiation is needed, for example the ICE has restarted.
- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection
{
    NSLog(@"%s",__func__);
}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState
{
    NSLog(@"%s",__func__);
    NSLog(@"%d", newState);
}

// Called any time the ICEGatheringState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState
{
    NSLog(@"%s",__func__);
    NSLog(@"%d", newState);
}

// New Ice candidate have been found.
//创建peerConnection之后，从server得到响应后调用，得到ICE 候选地址
- (void)peerConnection:(RTCPeerConnection *)peerConnection gotICECandidate:(RTCICECandidate *)candidate
{
    NSLog(@"%s",__func__);
    
    NSString *currentId = [self getKeyFromConnectionDic : peerConnection];

    NSDictionary *dic = @{@"eventName": ICE_CANDIDATE, @"data": @{@"id":candidate.sdpMid,@"label": [NSNumber numberWithInteger:candidate.sdpMLineIndex], @"candidate": candidate.sdp, @"socketId": currentId}};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    [_socketM RTCMessageSendWithData:data];
}

// New data channel has been opened.
- (void)peerConnection:(RTCPeerConnection*)peerConnection didOpenDataChannel:(RTCDataChannel*)dataChannel

{
    NSLog(@"%s",__func__);
}



#pragma mark - SocketManager
- (void)socketManager:(SocketManager *)manager RTCDidReadData:(NSDictionary *)readDic {
    NSLog(@"RTCReadDic = %@",readDic);
}



@end
