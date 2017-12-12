//
//  VideoOrAudioCallView.h
//  ZPS
//
//  Created by 张海军 on 2017/12/9.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    //发送者
    RoleCaller,
    //被发送者
    RoleCallee,
} CurrentRole;

@interface VideoOrAudioCallView : UIView
/// 显示自己的视频view
@property (nonatomic, strong) UIView *meVideoView;
/// 显示对方的视频view
@property (nonatomic, strong) UIView *friendVideoView;
/// 接受回调
@property (nonatomic, copy) void(^acceptHandle)(void);
/// 切换视频位置的回调
@property (nonatomic, copy) void(^changeVideoPointHandle)();
/// 断开的回调
@property (nonatomic, copy) void(^closeHandle)(void);



+ (instancetype)callViewWithUserName:(NSString *)name isVideo:(BOOL)video role:(CurrentRole)role;

- (void)closeWithCompletion:(void(^)(BOOL finished))fin;

- (void)connectFinshHandle;

@end
