//
//  VideoOrAudioCallView.m
//  ZPS
//
//  Created by 张海军 on 2017/12/9.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "VideoOrAudioCallView.h"

static CGFloat const TOPH = 100;
static CGFloat const FVVW = 90.0;
static CGFloat const FVVH = 168.0;
#define BOTTOMH  (HJSCREENH * 0.25)


@interface VideoOrAudioCallView ()
/// 底部功能view
@property (nonatomic, strong) UIView *bottomOpationView;
/// 呼叫者
@property (nonatomic, strong) UIView *bottomForCall;
/// 被呼叫者
@property (nonatomic, strong) UIView *bottomForOnCall;
/// 通话中
@property (nonatomic, strong) UIView *bottomCallinng;
/// 顶部用户信息view
@property (nonatomic, strong) UIView *topUserInfoView;
/// 连接状态
@property (nonatomic, strong) UILabel *stateL;

/// 当前角色
@property (nonatomic, assign) CurrentRole role;
/// 当前用户名称
@property (nonatomic, copy) NSString *currentRoleName;
/// 顶部/底部view的显示状态
@property (nonatomic, assign) BOOL opationViewHiddenState;
/// 是否连接成功
@property (nonatomic, assign) BOOL connectSuccess;
@end

@implementation VideoOrAudioCallView
+ (instancetype)callViewWithUserName:(NSString *)name isVideo:(BOOL)video role:(CurrentRole)role{
    VideoOrAudioCallView *view = [[self alloc] initWithFrame:[UIScreen mainScreen].bounds];
    view.role = role;
    view.currentRoleName = name;
    //view.backgroundColor = [UIColor whiteColor];
    [[UIApplication sharedApplication].keyWindow addSubview:view];
    [view setupInit];
    
    return view;
}

- (void)setupInit{
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
    toolbar.barStyle = UIBarStyleBlackTranslucent;
    [self addSubview:toolbar];
    
    // 自己视频view
    self.meVideoView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self addSubview:self.meVideoView];
    
    // 对方的视频
    self.friendVideoView = [[UIView alloc] init];
    self.friendVideoView.frame = CGRectMake(HJSCREENW - FVVW - 5, 30, FVVW, FVVH);
    [self addSubview:self.friendVideoView];
    
    // 头部view
    [self topUserInfoView];
    
    // 底部功能view
    if (self.role == RoleCaller) { //发送者
        [self bottomForCall];
    }else if (self.role == RoleCallee) { // 被发送者
        [self bottomForOnCall];
    }
}

// 连接成功后的操作
- (void)connectFinshHandle{
    [self showTopAndBottomView:NO];
    self.connectSuccess = YES;
    self.stateL.text = @"已连接";
}

- (void)showTopAndBottomView:(BOOL)isShow{
    [UIView animateWithDuration:0.5 animations:^{
        self.topUserInfoView.y = isShow ? 30 : -TOPH;
        self.bottomOpationView.y = isShow ? (HJSCREENH - (BOTTOMH)) : HJSCREENH;
    } completion:^(BOOL finished) {
        self.opationViewHiddenState = !isShow;
        if (!isShow) {
            self.topUserInfoView.hidden = YES;
        }
    }];
}

#pragma mark - event
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (self.connectSuccess) {
        [self showTopAndBottomView:self.opationViewHiddenState];
    }
}
// 取消按钮的点击
- (void)cancleButtonDidClick:(UIButton *)button{
    if (self.closeHandle) {
        self.closeHandle();
    }
}

// 接听按钮的点击
- (void)acceptButtonDidClick:(UIButton *)button{
    [self.bottomForOnCall removeFromSuperview];
    [self bottomForCall];
    if (self.acceptHandle) {
        self.acceptHandle();
    }
}

- (void)closeWithCompletion:(void (^)(BOOL))fin{
    [UIView animateWithDuration:0.5 animations:^{
        self.topUserInfoView.y = -TOPH;
        self.bottomOpationView.y = HJSCREENH;
    } completion:^(BOOL finished) {
        if (fin) {
            fin(finished);
        }
        [self removeFromSuperview];
    }];
}

#pragma mark - lazy
- (UIView *)topUserInfoView{
    if (!_topUserInfoView) {
        _topUserInfoView = [[UIView alloc] initWithFrame:CGRectMake(0, 30, HJSCREENW, TOPH)];
        [self addSubview:_topUserInfoView];
        CGFloat imgWH = TOPH - 20;
        UIImageView *userIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 10, imgWH, imgWH)];
        userIcon.contentMode = UIViewContentModeCenter;
        userIcon.image = [UIImage imageNamed:@"userIcon"];
        [_topUserInfoView addSubview:userIcon];
        
        // 名称
        UILabel *nameL = [[UILabel alloc] init];
        nameL.text = self.currentRoleName;
        nameL.font = [UIFont boldSystemFontOfSize:18.0];
        [_topUserInfoView addSubview:nameL];
        CGFloat nameLx = CGRectGetMaxX(userIcon.frame);
        nameL.origin = CGPointMake(nameLx, 25);
        [nameL sizeToFit];

        // 状态
        UILabel *stateL = [[UILabel alloc] init];
        stateL.text = self.role == RoleCaller ? @"等待对方接听..." : @"邀请你视频聊天";
        [_topUserInfoView addSubview:stateL];
        stateL.origin = CGPointMake(nameLx, CGRectGetMaxY(nameL.frame));
        [stateL sizeToFit];
        self.stateL = stateL;
    }
    return _topUserInfoView;
}
// 呼叫者
- (UIView *)bottomForCall{
    if (!_bottomForCall) {
        self.bottomOpationView = [[UIView alloc] initWithFrame:CGRectMake(0, HJSCREENH - (BOTTOMH), HJSCREENW, BOTTOMH)];
        [self addSubview:self.bottomOpationView];
        _bottomForCall = [[UIView alloc] initWithFrame:self.bottomOpationView.bounds];
        [self.bottomOpationView addSubview:_bottomForCall];
        UIButton *button = [self creationButtonWithImg:@"icon_call_reject_press"];
        [_bottomForCall addSubview:button];
        button.center = CGPointMake(HJSCREENW * 0.5, BOTTOMH * 0.5);
        [button addTarget:self action:@selector(cancleButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
        
        //_bottomForOnCall.backgroundColor = [UIColor grayColor];
    }
    return _bottomForCall;
}

// 被呼叫者
- (UIView *)bottomForOnCall{
    if (!_bottomForOnCall) {
        self.bottomOpationView = [[UIView alloc] initWithFrame:CGRectMake(0, HJSCREENH - (BOTTOMH), HJSCREENW, BOTTOMH)];
        [self addSubview:self.bottomOpationView];
        _bottomForOnCall = [[UIView alloc] initWithFrame:self.bottomOpationView.bounds];
        [self.bottomOpationView addSubview:_bottomForOnCall];
        UIButton *canCleB = [self creationButtonWithImg:@"icon_call_reject_press"];
        [_bottomForOnCall addSubview:canCleB];
        canCleB.center = CGPointMake(HJSCREENW * 0.25, BOTTOMH * 0.5);
        [canCleB addTarget:self action:@selector(cancleButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *acceptB = [self creationButtonWithImg:@"icon_audio_receive_normal"];
        [_bottomForOnCall addSubview:acceptB];
        acceptB.center = CGPointMake(HJSCREENW * 0.75, BOTTOMH * 0.5);
        [acceptB addTarget:self action:@selector(acceptButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
        
        //_bottomForOnCall.backgroundColor = [UIColor grayColor];
    }
    return _bottomForOnCall;
}

- (UIButton *)creationButtonWithImg:(NSString *)imgName{
    UIButton *cancleButton = [[UIButton alloc] init];
    cancleButton.size = CGSizeMake(60, 60);
    [cancleButton setImage:[UIImage imageNamed:imgName] forState:UIControlStateNormal];
    return cancleButton;
}

@end
