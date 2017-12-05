//
//  VoiceManager.m
//  ZPS
//
//  Created by 张海军 on 2017/12/4.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "VoiceManager.h"
#import <AVFoundation/AVFoundation.h>

static CGFloat VOLUMEVWH = 160.0;

@interface VoiceManager ()<AVAudioRecorderDelegate>
/// 音频录音机
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
/// 音频播放器
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
/// 存储完成后的回调
@property (nonatomic, copy) void(^stopCompletion)(BOOL finish,float duration);
/// 音量图标背景
@property (nonatomic, strong) UIView *volumeBgView;
/// 音量图标
@property (nonatomic, strong) UIView *volumeView;
/// 音量图标
@property (nonatomic, strong) UIImageView *volumeImageView;
/// 发送状态按钮
@property (nonatomic, strong) UILabel *volumeStateLabel;
/// 监听录音定时器
@property (nonatomic, weak) NSTimer *timer;
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
    [self volumeBgView];
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(volumeChange) userInfo:nil repeats:YES];
    }
}

// 停止 / 完成
- (void)stopRecordCompletion:(void (^)(BOOL finish,float duration))completion{
    self.stopCompletion = completion;
    [self.audioRecorder stop];
    [self recordStopHandle];
}

// 取消
- (void)cancleRecord{
    [self.audioRecorder stop];
    BOOL delete = [self.audioRecorder deleteRecording];
    self.volumeStateLabel.text = @"取消发送";
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self recordStopHandle];
    });
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

// 停止后的操作
- (void)recordStopHandle{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    [self.volumeBgView removeFromSuperview];
}


// 音量变化动画
- (void)volumeChange{
    //刷新音量数据
    [self.audioRecorder updateMeters];
    double lowPassResults = pow(10, (0.05 * [self.audioRecorder peakPowerForChannel:0]));
    NSLog(@"lowPassResults = %f",lowPassResults);
    NSString *imgName = nil;
    if (0<lowPassResults<=0.06) {
        imgName = @"01";
    }else if (0.06<lowPassResults<=0.13) {
        imgName = @"02";;
    }else if (0.13<lowPassResults<=0.20) {
        imgName = @"03";
    }else if (0.20<lowPassResults<=0.27) {
        imgName = @"04";
    }else if (0.27<lowPassResults<=0.34) {
        imgName = @"05";
    }else if (0.34<lowPassResults<=0.41) {
        imgName = @"06";
    }else if (0.41<lowPassResults<=0.48) {
        imgName = @"07";
    }else if (0.48<lowPassResults<=0.55) {
        imgName = @"08";
    }else if (0.55<lowPassResults<=0.62) {
        imgName = @"09";
    }else if (0.62<lowPassResults<=0.69) {
        imgName = @"10";
    }else if (0.69<lowPassResults<=0.76) {
        imgName = @"11";
    }else if (0.76<lowPassResults<=0.83) {
        imgName = @"12";
    }else if (0.83<lowPassResults<=0.9) {
        imgName = @"13";
    }else {
        imgName = @"14";
    }
    
    if (imgName != nil) {
        self.volumeImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"record_animate_%@",imgName]];
    }
}

#pragma mark - 录音机代理方法
/// 录音完成，录音完成后播放录音
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    if (self.stopCompletion) {
        AVURLAsset* audioAsset =[AVURLAsset URLAssetWithURL:recorder.url options:nil];
        CMTime audioDuration = audioAsset.duration;
        float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
        self.stopCompletion(flag,audioDurationSeconds);
        NSLog(@"录音完成-%zd audioDurationSeconds = %f",flag,audioDurationSeconds);
    }
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

- (UIView *)volumeBgView{
    if (!_volumeBgView) {
        _volumeBgView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [_volumeBgView addSubview:self.volumeView];
    }
    if (_volumeBgView.superview == nil) {
        _volumeStateLabel.text = @"手指上滑 取消发送";
        [[UIApplication sharedApplication].keyWindow addSubview:_volumeBgView];
    }
    return _volumeBgView;
}

- (UIView *)volumeView{
    if (!_volumeView) {
        _volumeView = [[UIView alloc] init];
        _volumeView.size = CGSizeMake(VOLUMEVWH, VOLUMEVWH);
        _volumeView.center = CGPointMake(HJSCREENW * 0.5, HJSCREENH * 0.5);
        _volumeView.backgroundColor = [UIColor colorWithRed:98.0/255 green:98.0/255 blue:98.0/255 alpha:0.5];
        [_volumeView addSubview:self.volumeImageView];
        _volumeStateLabel = [[UILabel alloc] init];
        _volumeStateLabel.textColor = [UIColor whiteColor];
        _volumeStateLabel.font = [UIFont systemFontOfSize:15.0];
        _volumeStateLabel.textAlignment = NSTextAlignmentCenter;
        [_volumeView addSubview:_volumeStateLabel];
        _volumeStateLabel.frame = CGRectMake(0, VOLUMEVWH - 30, VOLUMEVWH, 30);
    }
    if (_volumeView.superview == nil) {
    }
    return _volumeView;
}

- (UIImageView *)volumeImageView{
    if (!_volumeImageView) {
        _volumeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"record_animate_01"]];
        CGFloat imgw = 56;
        _volumeImageView.frame = CGRectMake((VOLUMEVWH - imgw)*0.5, 20, imgw, 83);
    }
    
    return _volumeImageView;
}

@end
