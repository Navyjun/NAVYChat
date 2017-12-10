//
//  RTCViewController.m
//  ZPS
//
//  Created by 张海军 on 2017/12/6.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "RTCViewController.h"
#import "WebRTCHelper.h"
#import "WebRTCClient.h"

#import "VideoOrAudioCallView.h"

#define KScreenWidth [UIScreen mainScreen].bounds.size.width
#define KScreenHeight [UIScreen mainScreen].bounds.size.height

#define KVedioWidth KScreenWidth/3.0
#define KVedioHeight KVedioWidth*320/240

@interface RTCViewController ()<WebRTCHelperDelegate>
{
    //本地摄像头追踪
    RTCVideoTrack *_localVideoTrack;
    //远程的视频追踪
    NSMutableDictionary *_remoteVideoTracks;
    
}

@end

@implementation RTCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    WebRTCClient *client = [WebRTCClient sharedInstance];
    [client startEngine];
    
    // 便于测试
//    [WebRTCHelper shareWebRTCHelper].delegate = self;
    
    if (HJSCREENH < 667) {
        SocketManager *manager = [SocketManager shareSockManager];
        [manager startListenPort:CURRENT_PORT];
    }
    
    if (HJSCREENH >= 667) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"连接" style:UIBarButtonItemStyleDone target:self action:@selector(leftItemDidClick)];
        SocketManager *manager = [SocketManager shareSockManager];
        [manager connentHost:CURRENT_HOST prot:CURRENT_PORT];
    }
    
    _remoteVideoTracks = [NSMutableDictionary dictionary];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)leftItemDidClick{
    SocketManager *manager = [SocketManager shareSockManager];
    [manager connentHost:CURRENT_HOST prot:CURRENT_PORT];
}

- (IBAction)sendOffer:(id)sender {
    
//    [[WebRTCHelper shareWebRTCHelper] inviteVoiceOrVideo];
    WebRTCClient *client = [WebRTCClient sharedInstance];
    [client startEngine];
    [client showRTCViewByRemoteName:[UIDevice currentDevice].name isVideo:YES isCaller:YES];
}

/// 创建本地流
- (void)webRtcHelper:(WebRTCHelper *)rtcHelper creatLocationStream:(RTCMediaStream *)stream userId:(NSString *)userId{
    RTCEAGLVideoView *localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 100, KVedioWidth, KVedioHeight)];
    //标记本地的摄像头
    localVideoView.tag = 100;
    _localVideoTrack = [stream.videoTracks lastObject];
    [_localVideoTrack addRenderer:localVideoView];
    
    [self.view addSubview:localVideoView];
}
/// 添加流
- (void)webRtcHelper:(WebRTCHelper *)rtcHelper addStream:(RTCMediaStream *)stream userId:(NSString *)userId{
    //缓存起来
    [_remoteVideoTracks setObject:[stream.videoTracks lastObject] forKey:userId];
    [self refreshRemoteView];
}
/// 关闭流
- (void)webRtcHelper:(WebRTCHelper *)rtcHelper closeStreamWithuserId:(NSString *)userId{
    
}
- (void)refreshRemoteView
{
    for (RTCEAGLVideoView *videoView in self.view.subviews) {
        //本地的视频View和关闭按钮不做处理
        if (videoView.tag == 100 ||videoView.tag == 123) {
            continue;
        }
        //其他的移除
        [videoView removeFromSuperview];
    }
    __block int column = 1;
    __block int row = 0;
    //再去添加
    [_remoteVideoTracks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, RTCVideoTrack *remoteTrack, BOOL * _Nonnull stop) {
        
        RTCEAGLVideoView *remoteVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(column * KVedioWidth, 100, KVedioWidth, KVedioHeight)];
        [remoteTrack addRenderer:remoteVideoView];
        [self.view addSubview:remoteVideoView];
        
        //列加1
        column++;
        //一行多余3个在起一行
        if (column > 3) {
            row++;
            column = 0;
        }
    }];
}


@end
