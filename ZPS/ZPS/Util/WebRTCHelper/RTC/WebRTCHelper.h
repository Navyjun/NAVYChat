//
//  WebRTCHelper.h
//  ZPS
//
//  Created by 张海军 on 2017/12/6.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketManager.h"
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

@class WebRTCHelper;

@protocol WebRTCHelperDelegate <NSObject>
@optional
/// 创建本地流
- (void)webRtcHelper:(WebRTCHelper *)rtcHelper creatLocationStream:(RTCMediaStream *)stream userId:(NSString *)userId;
/// 添加流
- (void)webRtcHelper:(WebRTCHelper *)rtcHelper addStream:(RTCMediaStream *)stream userId:(NSString *)userId;
/// 关闭流
- (void)webRtcHelper:(WebRTCHelper *)rtcHelper closeStreamWithuserId:(NSString *)userId;
@end

@interface WebRTCHelper : NSObject

+ (instancetype)shareWebRTCHelper;

- (void)inviteVoiceOrVideo;

/// delegate
@property (nonatomic, weak) id <WebRTCHelperDelegate> delegate;

@end
