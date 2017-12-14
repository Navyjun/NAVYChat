//
//  WebRTCHelper.m
//  ZPS
//
//  Created by 张海军 on 2017/12/6.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "WebRTCHelper.h"


/*
 流程 :
 1:发送方点击开启视频/语音通话 -> Socket 连接 -> 发送 id
 2:接收方收到 id 保存 -> 创建所有的RTCPeerConnection -> 保存到字典 -> 给所有的RTCPeerConnection 创建offer
 3:发送方发送offer
 4:接收方收到offer -> 在发送 answer
 */

typedef enum : NSUInteger {
    //发送者
    RoleCaller,
    //被发送者
    RoleCallee,
} Role;


//google提供的
/*
 NSArray *stunServer = @[@"stun.l.google.com:19302",@"stun1.l.google.com:19302",@"stun2.l.google.com:19302",@"stun3.l.google.com:19302",@"stun3.l.google.com:19302",@"stun01.sipphone.com",@"stun.ekiga.net",@"stun.fwdnet.net",@"stun.fwdnet.net",@"stun.fwdnet.net",@"stun.ideasip.com",@"stun.iptel.org",@"stun.rixtelecom.se",@"stun.schlund.de",@"",@"stunserver.org",@"stun.softjoys.com",@"stun.voiparound.com",@"stun.voipbuster.com",@"stun.voipstunt.com",@"stun.voxgratia.org",@"stun.xten.com"];
 */
static NSString *const STUNSERVERURL = @"stun:stun.l.google.com:19302";
static NSString *const STUNSERVERURL2 = @"stun:23.21.150.121";

static NSString *const NEW_PEER = @"new_peer"; // 新人加入
static NSString *const ACCEPT_FINISH = @"accept_finish"; // 接收到新人加入后发送的 -> 用于让对方发送 offer
static NSString *const OFFER = @"offer";       // offer
static NSString *const ANSWER = @"answer";     // answer
static NSString *const ICE_CANDIDATE = @"ice_candidate"; //ice_candidate
static int const RTCTAG = -11111; // 默认
static int const ACCEPTFINISHTAT = -999999; // 发送接收完成

@interface WebRTCHelper () <RTCSessionDescriptionDelegate, RTCPeerConnectionDelegate, SocketManagerForRTCDelegate>
/// 工厂类 用于创建 RTCPeerConnection 类
@property (nonatomic, strong) RTCPeerConnectionFactory *connectionFactory;
/// 本地流
@property (nonatomic, strong) RTCMediaStream *localStream;;
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
/// 当前的角色
@property (nonatomic, assign) Role currentRole;
@end


@implementation WebRTCHelper
#pragma mark - lazy
- (NSMutableArray *)connectionIdArray{
    if (!_connectionIdArray) {
        _connectionIdArray = [NSMutableArray array];
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
    });
    return helper;
}

- (instancetype)init{
    if (self = [super init]) {
        self.socketM = [SocketManager shareSockManager];
        self.socketM.rtcDelegate = self;
    }
    return self;
}

// 邀请 音频/视频 通话
- (void)inviteVoiceOrVideo{
    [self conn];
    NSDictionary *dic = @{@"eventName": NEW_PEER, @"socketId": self.myConnectionId};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    [_socketM RTCMessageSendWithData:data withTag:RTCTAG];
}

- (void)sendAcceptFinish{
    NSDictionary *dic = @{@"eventName": ACCEPT_FINISH, @"socketId": self.myConnectionId};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    [_socketM RTCMessageSendWithData:data withTag:ACCEPTFINISHTAT];
}

/// 创建所有的连接
- (void)createAllPeerConnections{
    [self.connectionIdArray enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (self.connectionDic[obj] == nil) {
            RTCPeerConnection *peerConnection = [self createPeerConnection];
            [self.connectionDic setObject:peerConnection forKey:obj];
        }
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
    
    //ICEServer
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
        self.currentRole = RoleCaller;
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

/// 获取 peerConnection 对象对应的 ID
- (NSString *)getKeyFromConnectionDic:(RTCPeerConnection *)peerConnection
{
    static NSString *socketId;
    [self.connectionDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, RTCPeerConnection *obj, BOOL * _Nonnull stop) {
        if (obj == peerConnection)
        {
            socketId = key;
        }
    }];
    return socketId;
}

#pragma mark - stream
/**
 *  创建本地流，并且把本地流回调出去
 */
- (void)createLocalStream
{
    self.localStream = [self.connectionFactory mediaStreamWithLabel:@"ARDAMS"];
    //音频
    RTCAudioTrack *audioTrack = [self.connectionFactory audioTrackWithID:@"ARDAMSa0"];
    [self.localStream addAudioTrack:audioTrack];
    //视频
    
    NSArray *deviceArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = [deviceArray lastObject];
    //检测摄像头权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)
    {
        NSLog(@"相机访问受限");
        if ([_delegate respondsToSelector:@selector(webRtcHelper:creatLocationStream:userId:)]){
            [_delegate webRtcHelper:self creatLocationStream:nil userId:self.myConnectionId];
        }
    }
    else
    {
        if (device)
        {
            RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:device.localizedName];
            RTCVideoSource *videoSource = [self.connectionFactory videoSourceWithCapturer:capturer constraints:[self localVideoConstraints]];
            RTCVideoTrack *videoTrack = [self.connectionFactory videoTrackWithID:@"ARDAMSv0" source:videoSource];
            
            [self.localStream addVideoTrack:videoTrack];
            
            if ([self.delegate respondsToSelector:@selector(webRtcHelper:creatLocationStream:userId:)]){
                [self.delegate webRtcHelper:self creatLocationStream:self.localStream userId:self.myConnectionId];
            }
        }
        else
        {
            NSLog(@"该设备不能打开摄像头");
            if ([self.delegate respondsToSelector:@selector(webRtcHelper:creatLocationStream:userId:)]){
                [self.delegate webRtcHelper:self creatLocationStream:nil userId:self.myConnectionId];
            }
        }
    }
}
/**
 *  视频的相关约束
 */
- (RTCMediaConstraints *)localVideoConstraints
{
    RTCPair *maxWidth = [[RTCPair alloc] initWithKey:@"maxWidth" value:@"640"];
    RTCPair *minWidth = [[RTCPair alloc] initWithKey:@"minWidth" value:@"640"];
    
    RTCPair *maxHeight = [[RTCPair alloc] initWithKey:@"maxHeight" value:@"480"];
    RTCPair *minHeight = [[RTCPair alloc] initWithKey:@"minHeight" value:@"480"];
    
    RTCPair *minFrameRate = [[RTCPair alloc] initWithKey:@"minFrameRate" value:@"15"];
    
    NSArray *mandatory = @[maxWidth, minWidth, maxHeight, minHeight, minFrameRate];
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatory optionalConstraints:nil];
    return constraints;
}

/**
 *  为所有连接添加流
 */
- (void)addStreams
{
    //给每一个点对点连接，都加上本地流
    NSLog(@"connectionIdCount = %zd",self.connectionIdArray.count);
    [self.connectionDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, RTCPeerConnection *obj, BOOL * _Nonnull stop) {
        if (!self.localStream){
            [self createLocalStream];
        }
        [obj addStream:_localStream];
    }];
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
    NSString *socketId = [self getKeyFromConnectionDic:peerConnection];
    
    if (peerConnection.signalingState == RTCSignalingHaveRemoteOffer){
        //创建一个answer,会把自己的SDP信息返回出去
        [peerConnection createAnswerWithDelegate:self constraints:[self offerOranswerConstraint]];
        NSLog(@"RTCSignalingHaveRemoteOffer");
    }else if (peerConnection.signalingState == RTCSignalingHaveLocalOffer) { // 创建本地offer
        // 发送offer
        NSDictionary *dic = nil;
        if (self.currentRole == RoleCaller) { // 发送者 -> 发送offer
            dic = @{@"eventName": OFFER, @"data": @{@"sdp": @{@"type": @"offer", @"sdp": peerConnection.localDescription.description}, @"socketId": socketId}};
            NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
            [_socketM RTCMessageSendWithData:data withTag:RTCTAG];
            
        }else if (self.currentRole == RoleCallee){ // 被发送者 -> 发送answer
            dic = @{@"eventName": ANSWER, @"data": @{@"sdp": @{@"type": @"answer", @"sdp": peerConnection.localDescription.description}, @"socketId": socketId}};
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
                [_socketM RTCMessageSendWithData:data withTag:RTCTAG];
            });
        }

//        if (dic) {
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
//                [_socketM RTCMessageSendWithData:data withTag:RTCTAG];
//            });
//        }
        
         NSLog(@"RTCSignalingHaveLocalOffer");
    }else if (peerConnection.signalingState == RTCSignalingStable)
    {
        if (self.currentRole == RoleCallee)
        {
            NSDictionary *dic = @{@"eventName": ANSWER, @"data": @{@"sdp": @{@"type": @"answer", @"sdp": peerConnection.localDescription.description}, @"socketId": socketId}};
            NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
            [_socketM RTCMessageSendWithData:data withTag:RTCTAG];
        }
        NSLog(@"RTCSignalingStable");
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
    NSString *uid = [self getKeyFromConnectionDic : peerConnection];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(webRtcHelper:addStream:userId:)]){
            [self.delegate webRtcHelper:self addStream:stream userId:uid];
        }
    });
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSString *currentId = [self getKeyFromConnectionDic:peerConnection];
        NSDictionary *dic = @{@"eventName": ICE_CANDIDATE, @"data": @{@"id":candidate.sdpMid,@"label": [NSNumber numberWithInteger:candidate.sdpMLineIndex], @"candidate": candidate.sdp, @"socketId": currentId}};
        NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
        [_socketM RTCMessageSendWithData:data withTag:RTCTAG];
    });
}

// New data channel has been opened.
- (void)peerConnection:(RTCPeerConnection*)peerConnection didOpenDataChannel:(RTCDataChannel*)dataChannel
{
    NSLog(@"%s",__func__);
}


- (void)conn{
    //如果为空，则创建点对点工厂
    if (!self.connectionFactory)
    {
        //设置SSL传输
        [RTCPeerConnectionFactory initializeSSL];
        self.connectionFactory = [[RTCPeerConnectionFactory alloc] init];
    }
    //如果本地视频流为空
    if (!self.localStream)
    {
        //创建本地流
        [self createLocalStream];
    }
    //创建连接
    [self createAllPeerConnections];
    
    //添加
    //[self addStreams];
    
}


#pragma mark - SocketManager
- (void)socketManager:(SocketManager *)manager RTCDidReadData:(NSDictionary *)readDic {
    NSLog(@"RTCReadDic = %@",readDic);
    NSString *eventName = readDic[@"eventName"];
    if ([eventName isEqualToString:NEW_PEER]) { // 收到新加入的请求 服务端
        NSString *socketId = readDic[@"socketId"];
        [self.connectionIdArray addObject:socketId];
        [self conn];
        [self addStreams];
        [self sendAcceptFinish];
    }else if ([eventName isEqualToString:ACCEPT_FINISH]){ // 收到接受完成信息 -> 发送offer 客户端
        NSString *socketId = readDic[@"socketId"];
        [self.connectionIdArray addObject:socketId];
        [self conn];
        [self createOffers];
    }else if ([eventName isEqualToString:ICE_CANDIDATE]){ // 接收到新加入的人发起的ICE候选
        NSDictionary *dataDic = readDic[@"data"];
        NSString *socketId = dataDic[@"socketId"];
        NSString *sdpMid = dataDic[@"id"];
        NSInteger sdpMLineIndex = [dataDic[@"label"] integerValue];
        NSString *sdp = dataDic[@"candidate"];
    
        // 生成远端网络地址
        RTCICECandidate *candidate = [[RTCICECandidate alloc] initWithMid:sdpMid index:sdpMLineIndex sdp:sdp];
        // 获取对应的连接
        RTCPeerConnection *peerConnection = [self.connectionDic objectForKey:socketId];
        // 添加到连接中
        [peerConnection addICECandidate:candidate];
    }else if ([eventName isEqualToString:OFFER]) { // 收到offer
        NSDictionary *dataDic = readDic[@"data"];
        NSDictionary *sdpDic = dataDic[@"sdp"];
        //拿到SDP
        NSString *sdp = sdpDic[@"sdp"];
        NSString *type = sdpDic[@"type"];
        NSString *socketId = dataDic[@"socketId"];
        // 保存offer
        RTCPeerConnection *peerConnection = [self.connectionDic objectForKey:socketId];
        RTCSessionDescription *remoteSdp = [[RTCSessionDescription alloc] initWithType:type sdp:sdp];
        [peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:remoteSdp];
        [self createOffers];
        //设置当前角色状态为被呼叫，（被发offer）
        self.currentRole = RoleCallee;
    }else if ([eventName isEqualToString:ANSWER]) { // 回应offer
        NSDictionary *dataDic = readDic[@"data"];
        NSDictionary *sdpDic = dataDic[@"sdp"];
        NSString *sdp = sdpDic[@"sdp"];
        NSString *type = sdpDic[@"type"];
        NSString *socketId = dataDic[@"socketId"];
        RTCPeerConnection *peerConnection = [_connectionDic objectForKey:socketId];
        RTCSessionDescription *remoteSdp = [[RTCSessionDescription alloc] initWithType:type sdp:sdp];
        [peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:remoteSdp];
        
    }else if ([eventName isEqualToString:@"SEND_OFFER"]){
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self createOffers];
        });
        //self.currentRole = RoleCallee;
    }
}

- (void)socketManager:(SocketManager *)manager didWriteDataWithTag:(long)tag{
    MYLog(@"%s tag = %ld",__func__,tag);
}


@end
