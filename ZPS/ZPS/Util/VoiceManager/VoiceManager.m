//
//  VoiceManager.m
//  ZPS
//
//  Created by 张海军 on 2017/12/4.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "VoiceManager.h"
#import <AVFoundation/AVFoundation.h>

@interface VoiceManager ()<AVAudioRecorderDelegate>
/// 音频录音机
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
/// 音频播放器
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
/// 存储完成后的回调
@property (nonatomic, copy) void(^stopCompletion)(BOOL);

@end

@implementation VoiceManager
static VoiceManager *manager = nil;
+ (instancetype)voiceManagerShare{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[VoiceManager alloc] init];
        [manager setAudioSession];
    });
    return manager;
}

// 开始录音
- (void)beginRecordWithURL:(NSURL *)url{
    self.currentRecordUrl = url;
    [self getAudioRecorderWithUrl:url];
    [self.audioRecorder record];
}

- (void)stopRecordCompletion:(void (^)(BOOL))completion{
    self.stopCompletion = completion;
    [self.audioRecorder stop];
}

- (void)cancleRecord{
    [self.audioRecorder stop];
    BOOL delete = [self.audioRecorder deleteRecording];
    NSLog(@"delete = %zd",delete);
}

// 开始播放
- (void)playAudioWithURL:(NSURL *)url{
    if (url == nil) {
        return;
    }
    [self getAudioPlayerWithUrl:url];
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
}


///  设置音频会话
-(void)setAudioSession{
    AVAudioSession *audioSession=[AVAudioSession sharedInstance];
    //设置为播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
    NSError *audioError = nil;
    BOOL success = [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&audioError];
    if(!success){
        NSLog(@"error doing outputaudioportoverride - %@", [audioError localizedDescription]);
    }
}

/// 取得录音文件设置
-(NSDictionary *)getAudioSetting{
    NSMutableDictionary *dicM=[NSMutableDictionary dictionary];
    //设置录音格式
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(44100) forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [dicM setObject:@(1) forKey:AVNumberOfChannelsKey];
    //每个采样点位数,分为8、16、24、32
    [dicM setObject:@(16) forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    //....其他设置等
    return dicM;
}

#pragma mark - 录音机代理方法
/// 录音完成，录音完成后播放录音
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    if (self.stopCompletion) {
        self.stopCompletion(flag);
    }
    //self.audioRecorder = nil;
    //[self playAudioWithURL:self.currentRecordUrl];
    NSLog(@"录音完成-%zd",flag);
}

#pragma mark - lazy
/// 获得录音机对象
- (AVAudioRecorder *)getAudioRecorderWithUrl:(NSURL *)url{
    //创建录音格式设置
    NSDictionary *setting=[self getAudioSetting];
    //创建录音机
    NSError *error=nil;
    _audioRecorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
    _audioRecorder.delegate=self;
    _audioRecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
    if (error) {
        NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
        return nil;
    }
    return _audioRecorder;
}


/// 创建播放器
- (AVAudioPlayer *)getAudioPlayerWithUrl:(NSURL *)url{
    NSError *error=nil;
    _audioPlayer=[[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
    _audioPlayer.numberOfLoops=0;
    [_audioPlayer prepareToPlay];
    if (error) {
        NSLog(@"创建播放器过程中发生错误，错误信息：%@",error.localizedDescription);
        return nil;
    }
    return _audioPlayer;
}

@end
