//
//  WebRTCClient.h
//  ChatDemo
//
//  Created by Harvey on 16/5/30.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoOrAudioCallView.h"


@interface WebRTCClient : NSObject

///
@property (nonatomic, strong) VideoOrAudioCallView *callView;

+ (instancetype)sharedInstance;

- (void)startEngine;

- (void)stopEngine;

- (void)showRTCViewByRemoteName:(NSString *)remoteName isVideo:(BOOL)isVideo isCaller:(BOOL)isCaller;

- (void)resizeViews;

@end
