//
//  VoiceManager.h
//  ZPS
//
//  Created by 张海军 on 2017/12/4.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VoiceManager : NSObject
/// 当前录音url地址
@property (nonatomic, strong) NSURL *currentRecordUrl;

+ (instancetype)voiceManagerShare;

- (void)beginRecordWithURL:(NSURL *)url;

- (void)stopRecordCompletion:(void(^)(BOOL finished,float duration))completion;

- (void)cancleRecord;

- (void)playAudioWithURL:(NSURL *)url;

@end
