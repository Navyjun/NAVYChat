//
//  WebRTCManager.h
//  ZPS
//
//  Created by 张海军 on 2017/12/9.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoOrAudioCallView.h"

@interface WebRTCManager : NSObject

@property (nonatomic, strong) VideoOrAudioCallView *callView;

+ (instancetype)webRTCManagerShare;

- (void)showRTCViewWithRemotName:(NSString *)remoteName isVideo:(BOOL)video isCaller:(BOOL)caller;

@end
