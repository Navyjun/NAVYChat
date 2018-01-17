//
//  WebRTCManager.m
//  ZPS
//
//  Created by 张海军 on 2017/12/9.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "WebRTCManager.h"
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

#import "RTCICEServer.h"
#import "RTCICECandidate.h"
#import "RTCICEServer.h"
#import "RTCMediaConstraints.h"
#import "RTCMediaStream.h"
#import "RTCPair.h"
#import "RTCPeerConnection.h"
#import "RTCPeerConnectionDelegate.h"
#import "RTCPeerConnectionFactory.h"
#import "RTCSessionDescription.h"
#import "RTCVideoRenderer.h"
#import "RTCVideoCapturer.h"
#import "RTCVideoTrack.h"
#import "RTCAVFoundationVideoSource.h"
#import "RTCSessionDescriptionDelegate.h"
#import "RTCEAGLVideoView.h"

#import "SocketManager.h"

//google提供的
/*
 NSArray *stunServer = @[@"stun.l.google.com:19302",@"stun1.l.google.com:19302",@"stun2.l.google.com:19302",@"stun3.l.google.com:19302",@"stun3.l.google.com:19302",@"stun01.sipphone.com",@"stun.ekiga.net",@"stun.fwdnet.net",@"stun.fwdnet.net",@"stun.fwdnet.net",@"stun.ideasip.com",@"stun.iptel.org",@"stun.rixtelecom.se",@"stun.schlund.de",@"",@"stunserver.org",@"stun.softjoys.com",@"stun.voiparound.com",@"stun.voipbuster.com",@"stun.voipstunt.com",@"stun.voxgratia.org",@"stun.xten.com"];
 */
static NSString *const STUNSERVERURL = @"stun:stun.l.google.com:19302";
static NSString *const STUNSERVERURL2 = @"stun:23.21.150.121";

@interface WebRTCManager() <RTCPeerConnectionDelegate, RTCEAGLVideoViewDelegate, RTCSessionDescriptionDelegate>

@property (nonatomic, strong) RTCPeerConnectionFactory *peerConnectionFactory; /// 工厂类
@property (nonatomic, strong) RTCPeerConnection *peerConnection; /// 连接器

@property (nonatomic, strong) RTCEAGLVideoView *locationVideoView;
@property (nonatomic, strong) RTCVideoTrack    *locationVideoTrack;
@property (nonatomic, strong) RTCEAGLVideoView *remoteVideoView;
@property (nonatomic, strong) RTCVideoTrack    *remoteVideoTrack;

@property (nonatomic, strong)   CTCallCenter *callCenter;

@property (nonatomic, strong) NSMutableArray *ICEServerArray;     /// ICEServer 数组
@property (nonatomic, strong) NSMutableArray *acceptMessageArray; /// 接收到的消息数组
@property (nonatomic, assign) BOOL HaveSentCandidate;
@end


@implementation WebRTCManager
#pragma mark - lazy
- (NSMutableArray *)ICEServerArray{
    if (!_ICEServerArray) {
        _ICEServerArray = [NSMutableArray array];
        [_ICEServerArray addObject:[self ICEServerWithURLStr:STUNSERVERURL]];
        [_ICEServerArray addObject:[self ICEServerWithURLStr:STUNSERVERURL2]];
    }
    return _ICEServerArray;
}

- (NSMutableArray *)acceptMessageArray{
    if (!_acceptMessageArray) {
        _acceptMessageArray = [NSMutableArray array];
    }
    return _acceptMessageArray;
}

- (RTCPeerConnectionFactory *)peerConnectionFactory{
    if (!_peerConnectionFactory) {
        _peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
    }
    return _peerConnectionFactory;
}

#pragma mark - life cycle
static WebRTCManager *manager = nil;
+ (instancetype)webRTCManagerShare{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[WebRTCManager alloc] init];
        [RTCPeerConnectionFactory initializeSSL];
        [manager peerConnectionFactory];
        [manager addNotifications];
    });
    return manager;
}

- (void)addNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveSignalingMessage:) name:@"kReceivedSinalingMessageNotification" object:nil];
}

- (void)showRTCViewWithRemotName:(NSString *)remoteName isVideo:(BOOL)video isCaller:(BOOL)caller{
    // 创建 callView
    WS(weakSelf);
    self.callView = [VideoOrAudioCallView callViewWithUserName:remoteName isVideo:video role:caller ? RoleCaller : RoleCallee];
    self.callView.acceptHandle = ^{
        [weakSelf acceptAction];
    };
    self.callView.closeHandle = ^{
        [weakSelf hangupEvent];
    };
    
    // 拨打时，禁止黑屏
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    // 监听系统电话
    [self listenSystemCall];
    
    // 做RTC必要设置
    if (caller) {
        [self setupPeerInit];
        // 如果是发起者，创建一个offer信令
        [self.peerConnection createOfferWithDelegate:self constraints:[self peerConstraints]];
    } else {
        NSLog(@"如果是接收者，就要处理信令信息");
    }
    
}


#pragma mark - private method
// 初始化STUN Server （ICE Server）
- (RTCICEServer *)ICEServerWithURLStr:(NSString *)urlStr {
    NSURL *defaultSTUNServerURL = [NSURL URLWithString:urlStr];
    return [[RTCICEServer alloc] initWithURI:defaultSTUNServerURL
                                    username:@""
                                    password:@""];
}

// 创建SDP约束
- (RTCMediaConstraints *)creatSdpConstraintsWithAudio:(BOOL)audio video:(BOOL)video{
    NSMutableArray *array = [NSMutableArray array];
    RTCPair *receiveAudio = [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:audio ? @"true" : @"flase"];
    [array addObject:receiveAudio];
    
    RTCPair *receiveVideo = [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:video ? @"true" : @"flase"];
    [array addObject:receiveVideo];
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:array optionalConstraints:nil];
    return constraints;
}

// 创建媒体约束
- (RTCMediaConstraints *)peerConstraints{
    NSArray *option = @[[[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"false"]];
    RTCMediaConstraints *peerConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:option];
    return peerConstraints;
}

// 视频相关约束
- (RTCMediaConstraints *)videoConstraints{
    return [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
}

// 初始化设置 peer
- (void)setupPeerInit{
    // 创建连接器
    self.peerConnection = [self.peerConnectionFactory peerConnectionWithICEServers:self.ICEServerArray constraints:[self peerConstraints] delegate:self];
    
    // 设置本地 视频流
    RTCAVFoundationVideoSource *locationSource = [[RTCAVFoundationVideoSource alloc] initWithFactory:self.peerConnectionFactory constraints:[self videoConstraints]];
    RTCVideoTrack *locationVideoTrack = [[RTCVideoTrack alloc] initWithFactory:self.peerConnectionFactory source:locationSource trackId:@"AVAMSv0"];
    self.locationVideoTrack = locationVideoTrack;
    // 本地音频
    RTCAudioTrack *locationAudioTrack = [self.peerConnectionFactory audioTrackWithID:@"ARDAMSa0"];
    // 本地媒体流
    RTCMediaStream *locationStream = [self.peerConnectionFactory mediaStreamWithLabel:@"ARDAMS"];
    [locationStream addVideoTrack:locationVideoTrack];
    [locationStream addAudioTrack:locationAudioTrack];
    
    [self.peerConnection addStream:locationStream];
    
    RTCEAGLVideoView *locationVideoView = [[RTCEAGLVideoView alloc] initWithFrame:self.callView.meVideoView.bounds];
    locationVideoView.delegate = self;
    [self.callView.meVideoView addSubview:locationVideoView];
    self.locationVideoView = locationVideoView;
    [self.locationVideoTrack addRenderer:locationVideoView];
    
    RTCEAGLVideoView *remoteVideoView = [[RTCEAGLVideoView alloc] initWithFrame:self.callView.friendVideoView.bounds];
    remoteVideoView.delegate = self;
    [self.callView.friendVideoView addSubview:remoteVideoView];
    self.remoteVideoView = remoteVideoView;
    
}

- (void)listenSystemCall
{
    self.callCenter = [[CTCallCenter alloc] init];
    self.callCenter.callEventHandler = ^(CTCall* call) {
        if ([call.callState isEqualToString:CTCallStateDisconnected])
        {
            NSLog(@"Call has been disconnected");
        }
        else if ([call.callState isEqualToString:CTCallStateConnected])
        {
            NSLog(@"Call has just been connected");
        }
        else if([call.callState isEqualToString:CTCallStateIncoming])
        {
            NSLog(@"Call is incoming");
        }
        else if ([call.callState isEqualToString:CTCallStateDialing])
        {
            NSLog(@"call is dialing");
        }
        else
        {
            NSLog(@"Nothing is done");
        }
    };
}

- (void)changeVideoPointHandle{
    [self videoView:self.remoteVideoView didChangeVideoSize:self.callView.friendVideoView.bounds.size];
    [self videoView:self.locationVideoView didChangeVideoSize:self.callView.meVideoView.bounds.size];
}

- (void)hangupEvent
{
    NSDictionary *dict = @{@"type":@"bye"};
    [self processMessageDict:dict];
}

- (void)receiveSignalingMessage:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSString *type = dict[@"type"];
    if ([type isEqualToString:@"offer"]) {
        [self showRTCViewWithRemotName:CURRENT_FRIENDNAME isVideo:YES isCaller:NO];
        [self.acceptMessageArray insertObject:dict atIndex:0];
    } else if ([type isEqualToString:@"answer"]) {
        RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:type sdp:dict[@"sdp"]];
        [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];
    } else if ([type isEqualToString:@"candidate"]) {
        
        [self.acceptMessageArray addObject:dict];
    } else if ([type isEqualToString:@"bye"]) {
        [self processMessageDict:dict];
    }
}

- (void)acceptAction
{
    [self setupPeerInit];
    for (NSDictionary *dict in self.acceptMessageArray) {
        [self processMessageDict:dict];
    }
    [self.acceptMessageArray removeAllObjects];
}

- (void)processMessageDict:(NSDictionary *)dict
{
    NSString *type = dict[@"type"];
    if ([type isEqualToString:@"offer"]) {
        RTCSessionDescription *remoteSdp = [[RTCSessionDescription alloc] initWithType:type sdp:dict[@"sdp"]];
        [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:remoteSdp];
        [self.peerConnection createAnswerWithDelegate:self constraints:[self peerConstraints]];
    } else if ([type isEqualToString:@"answer"]) {
        RTCSessionDescription *remoteSdp = [[RTCSessionDescription alloc] initWithType:type sdp:dict[@"sdp"]];
        [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:remoteSdp];
        
    } else if ([type isEqualToString:@"candidate"]) {
        NSString *mid = [dict objectForKey:@"id"];
        NSNumber *sdpLineIndex = [dict objectForKey:@"label"];
        NSString *sdp = [dict objectForKey:@"sdp"];
        RTCICECandidate *candidate = [[RTCICECandidate alloc] initWithMid:mid index:sdpLineIndex.intValue sdp:sdp];
        
        [self.peerConnection addICECandidate:candidate];
    } else if ([type isEqualToString:@"bye"]) {
        
        if (self.callView) {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
            NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            if (jsonStr.length > 0) {
                [[SocketManager shareSockManager] RTCMessageSendWithData:jsonData withTag:-100];
            }
            
            //[self.rtcView dismiss];
            WS(weakSelf);
            [self.callView closeWithCompletion:^(BOOL finished) {
                weakSelf.callView = nil;
            }];
            
            [self cleanCache];
        }
    }
}

- (void)cleanCache
{
    // 将试图置为nil
    self.callView = nil;
    // 取消手机常亮
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    // 取消系统电话监听
    self.callCenter = nil;
    
    _peerConnection = nil;
    _locationVideoTrack = nil;
    _remoteVideoTrack = nil;
    _locationVideoView = nil;
    _remoteVideoView = nil;
    _HaveSentCandidate = NO;
}

#pragma mark - RTCSessionDescriptionDelegate

// Called when creating a session.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didCreateSessionDescription:(RTCSessionDescription *)sdp
                 error:(NSError *)error{
    
    if (!error) {
        [self.peerConnection setLocalDescriptionWithDelegate:self sessionDescription:sdp];
        // 发送offer
        NSDictionary *jsonDic = @{@"type":sdp.type, @"sdp":sdp.description};
        NSData *sendData = [NSJSONSerialization dataWithJSONObject:jsonDic options:0 error:nil];
        [[SocketManager shareSockManager] RTCMessageSendWithData:sendData withTag:-100];
    }else{
        NSLog(@"%s--%@",__func__,error.localizedDescription);
    }
    
}

// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didSetSessionDescriptionWithError:(NSError *)error{
    NSLog(@"+++++++%s++++++",__func__);
    if (peerConnection.signalingState == RTCSignalingHaveLocalOffer) {
        
    }
}

#pragma mark - RTCPeerConnectionDelegate
// Triggered when the SignalingState changed.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged
{
    NSLog(@"信令状态改变");
    switch (stateChanged) {
        case RTCSignalingStable:
        {
            NSLog(@"stateChanged = RTCSignalingStable");
        }
            break;
        case RTCSignalingClosed:
        {
            NSLog(@"stateChanged = RTCSignalingClosed");
        }
            break;
        case RTCSignalingHaveLocalOffer:
        {
            NSLog(@"stateChanged = RTCSignalingHaveLocalOffer");
        }
            break;
        case RTCSignalingHaveRemoteOffer:
        {
            NSLog(@"stateChanged = RTCSignalingHaveRemoteOffer");
        }
            break;
        case RTCSignalingHaveRemotePrAnswer:
        {
            NSLog(@"stateChanged = RTCSignalingHaveRemotePrAnswer");
        }
            break;
        case RTCSignalingHaveLocalPrAnswer:
        {
            NSLog(@"stateChanged = RTCSignalingHaveLocalPrAnswer");
        }
            break;
    }
    
}

// Triggered when media is received on a new stream from remote peer.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream
{
    NSLog(@"已添加多媒体流");
    NSLog(@"Received %lu video tracks and %lu audio tracks",
          (unsigned long)stream.videoTracks.count,
          (unsigned long)stream.audioTracks.count);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([stream.videoTracks count]) {
            self.remoteVideoTrack = nil;
            [self.remoteVideoView renderFrame:nil];
            self.remoteVideoTrack = stream.videoTracks[0];
            [self.remoteVideoTrack addRenderer:self.remoteVideoView];
            // 连接成功后的UI操作
            [self.callView connectFinshHandle];
        }
        
        [self videoView:self.remoteVideoView didChangeVideoSize:self.callView.friendVideoView.bounds.size];
        [self videoView:self.locationVideoView didChangeVideoSize:self.callView.meVideoView.bounds.size];
        
    });
}

// Triggered when a remote peer close a stream.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream
{
    NSLog(@"a remote peer close a stream");
}

// Triggered when renegotiation is needed, for example the ICE has restarted.
- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection
{
    NSLog(@"Triggered when renegotiation is needed");
}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState
{
    NSLog(@"%s",__func__);
    switch (newState) {
        case RTCICEConnectionNew:
        {
            NSLog(@"newState = RTCICEConnectionNew");
        }
            break;
        case RTCICEConnectionChecking:
        {
            NSLog(@"newState = RTCICEConnectionChecking");
        }
            break;
        case RTCICEConnectionConnected:
        {
            NSLog(@"newState = RTCICEConnectionConnected");//15:56:56.698 15:56:57.570
        }
            break;
        case RTCICEConnectionCompleted:
        {
            NSLog(@"newState = RTCICEConnectionCompleted");//5:56:57.573
        }
            break;
        case RTCICEConnectionFailed:
        {
            NSLog(@"newState = RTCICEConnectionFailed");
        }
            break;
        case RTCICEConnectionDisconnected:
        {
            NSLog(@"newState = RTCICEConnectionDisconnected");
        }
            break;
        case RTCICEConnectionClosed:
        {
            NSLog(@"newState = RTCICEConnectionClosed");
        }
            break;
        case RTCICEConnectionMax:
        {
            NSLog(@"newState = RTCICEConnectionMax");
        }
            break;
    }
}

// Called any time the ICEGatheringState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState
{
    NSLog(@"%s",__func__);
    switch (newState) {
        case RTCICEGatheringNew:
        {
            NSLog(@"newState = RTCICEGatheringNew");
        }
            break;
        case RTCICEGatheringGathering:
        {
            NSLog(@"newState = RTCICEGatheringGathering");
        }
            break;
        case RTCICEGatheringComplete:
        {
            NSLog(@"newState = RTCICEGatheringComplete");
        }
            break;
    }
    
}

// New Ice candidate have been found.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate
{
    if (self.HaveSentCandidate) {
        return;
    }
    NSDictionary *jsonDict = @{@"type":@"candidate",
                               @"label":[NSNumber numberWithInteger:candidate.sdpMLineIndex],
                               @"id":candidate.sdpMid,
                               @"sdp":candidate.sdp
                               };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
    if (jsonData.length > 0) {
        [[SocketManager shareSockManager] RTCMessageSendWithData:jsonData withTag:-100];
        self.HaveSentCandidate = YES;
    }
}

#pragma mark - RTCEAGLVideoViewDelegate
- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size
{
    if (videoView == self.locationVideoView) {
        
        NSLog(@"local size === %@",NSStringFromCGSize(size));
    }else if (videoView == self.remoteVideoView){
        NSLog(@"remote size === %@",NSStringFromCGSize(size));
    }
}

@end
