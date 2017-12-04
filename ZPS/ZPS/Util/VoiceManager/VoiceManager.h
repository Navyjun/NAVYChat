//
//  VoiceManager.h
//  ZPS
//
//  Created by 张海军 on 2017/12/4.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VoiceManager : NSObject

+ (instancetype)voiceManagerShare;

- (void)beginRecordWithURL:(NSURL *)url  completion:(void(^)(BOOL finished))completion;

- (void)stopRecord;

@end
