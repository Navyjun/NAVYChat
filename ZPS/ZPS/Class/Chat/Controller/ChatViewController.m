//
//  ChatViewController.m
//  ZPS
//
//  Created by 张海军 on 2017/11/23.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "ChatViewController.h"
#import "ESKeyBoardToolView.h"
#import "ChatMessageCell.h"
#import "SocketManager.h"
#import "PickerImageVideoTool.h"
#import "VoiceManager.h"
#import "TZImageManager.h"
#import <SDImageCache.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

#import "WebRTCManager.h"


@interface ChatViewController ()
<ESKeyBoardToolViewDelegate,
UITableViewDelegate,
UITableViewDataSource,
TZImagePickerControllerDelegate,
SocketManagerDelegate>

/// 键盘工具条
@property (nonatomic, strong) ESKeyBoardToolView *keyBoardToolView;
/// tableView
@property (nonatomic, strong) UITableView *tableView;
/// 聊天背景图
@property (nonatomic, strong) UIImageView *chatBgImageView;
/// tableView y 原始偏移值
@property (nonatomic, assign) CGFloat orginalOffsetY;
/// 消息集合
@property (nonatomic, strong) NSMutableArray *messageItems;
/// 当前正在发送的item
@property (nonatomic, strong) ChatMessageModel *tempSendingItem;
/// 当前正在接收的item
@property (nonatomic, strong) ChatMessageModel *tempAcceptingItem;

@end

@implementation ChatViewController
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    // 便于测试
    if (HJSCREENH < 667) {
        SocketManager *manager = [SocketManager shareSockManager];
        manager.delegate = self;
        [manager dataSavePath];
        [manager startListenPort:CURRENT_PORT];
    }
    
    [self setupInit];
    
    if (@available(iOS 11.0, *)) {
        NSLog(@"safeAreaInsets = %@",NSStringFromUIEdgeInsets(self.view.safeAreaInsets));
        NSLog(@"frame = %@",NSStringFromCGRect(self.view.frame));
    } else {
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
- (void)setupInit{
    self.navigationItem.title = @"NAVY-Chat";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"背景" style:UIBarButtonItemStyleDone target:self action:@selector(rightItemDidClick)];
    if (HJSCREENH >= 667) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"连接" style:UIBarButtonItemStyleDone target:self action:@selector(leftItemDidClick)];
    }
    
    // UI
    [self tableView];
    [self keyBoardToolView];
    
    // 监听键盘高度变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    self.messageItems = [NSMutableArray array];
}


#pragma mark - notification hadle
- (void)keyBoardWillChange:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    double duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardF = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    if (keyboardF.origin.y >= self.view.hj_height) { // 退出键盘
        [self.keyBoardToolView mas_updateConstraints:^(MASConstraintMaker *make) {
            //make.bottom.mas_equalTo(self.view.mas_bottom);
            make.bottom.mas_equalTo(self.view.mas_bottom).offset(HJSCREENH == IPHONEXH?-34:0);
            make.height.mas_equalTo(self.keyBoardToolView.hj_height);
        }];
    } else {
        [self.keyBoardToolView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self.view.mas_bottom).mas_offset(-keyboardF.size.height);
            make.height.mas_equalTo(self.keyBoardToolView.hj_height);
        }];
    }
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - event
- (void)hideKeyBoard{
    [self.keyBoardToolView exitKeyBoard];
}

- (void)rightItemDidClick{
    WS(weakSelf);
    [[PickerImageVideoTool sharePickerImageVideoTool] showImagePickerWithMaxCount:1 completion:^(NSArray<UIImage *> *photos, NSArray *assets) {
        if (!weakSelf.chatBgImageView) {
            weakSelf.chatBgImageView = [[UIImageView alloc] initWithFrame:weakSelf.tableView.frame];
            weakSelf.chatBgImageView.contentMode = UIViewContentModeScaleAspectFill;
        }
        if (photos.count>0) {
            weakSelf.chatBgImageView.image = [photos firstObject];
            weakSelf.tableView.backgroundView = weakSelf.chatBgImageView;
        }
    }];
    
}

- (void)leftItemDidClick{
    SocketManager *manager = [SocketManager shareSockManager];
    manager.delegate = self;
    [manager connentHost:CURRENT_HOST prot:CURRENT_PORT];
}

#pragma mark - ESKeyBoardToolViewDelegate
- (void)ESKeyBoardToolViewSendButtonDidClick:(ESKeyBoardToolView *)view message:(NSString *)message{
    ChatMessageModel *messageM = [ChatMessageModel new];
    messageM.isFormMe = YES;
    messageM.userName = [UIDevice currentDevice].name;
    messageM.messageContent = message;
    messageM.chatMessageType = ChatMessageText;
    [self sendMessageWithItem:messageM];
}

- (void)ESKeyBoardToolViewAddOpationDidSelected:(ESKeyBoardToolView *)view withType:(OpationItem_type)type{
    switch (type) {
        case OpationItem_image:{
            [self sendImageOrVideo];
        }
            break;
        case OpationItem_video:{
            [self.keyBoardToolView exitKeyBoard];
            [self inviteVideoChat];
        }
            break;
            
        default:
            break;
    }
}

- (void)ESKeyBoardToolViewDidEditing:(ESKeyBoardToolView *)view changeY:(CGFloat)yValue{    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat contentH = self.tableView.contentSize.height;
        if (yValue == 0) { // 键盘弹出的时候
            CGFloat offsetY = contentH - self.tableView.hj_height + view.systemKeyboardH - BOTTOMSAFEH;
            if (offsetY > 0) {
                [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, offsetY) animated:YES];
            }else{
                if (offsetY > (-NAVBARH)) {
                    [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, offsetY) animated:YES];
                }
            }
        }else{
            // 此处需判断  导航条是否存在
            self.orginalOffsetY = NAVBARH;
            CGFloat showH = view.y - self.orginalOffsetY;
            CGFloat needOffsetY = contentH - showH;
            if (needOffsetY >= 0) {
                [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, needOffsetY-self.orginalOffsetY) animated:NO];
            }
        }
    });
    
    
}

- (void)ESKeyBoardToolViewDidEndEdit:(ESKeyBoardToolView *)view{
    [self scrollToLastCellAnimated:YES];
}

// 语音相关
- (void)ESKeyBoardToolViewRecordWithState:(RecordVoiceState)state{
    switch (state) {
        case RecordVoiceStateBegin:{
            NSString *fileName = [[NSString stringWithFormat:@"%zd",[[NSDate date] timeIntervalSinceReferenceDate]] stringByAppendingString:@".caf"];
            NSString *savePath = [[SocketManager shareSockManager].dataSavePath stringByAppendingPathComponent:[fileName lastPathComponent]];
            [[VoiceManager voiceManagerShare] beginRecordWithURL:[NSURL fileURLWithPath:savePath]];
        }
            break;
        case RecordVoiceStateFinish:{
            WS(weakSelf);
            [[VoiceManager voiceManagerShare] stopRecordCompletion:^(BOOL finished,float duration) {
                if (duration < 1.0) {
                    NSLog(@"时长小于1s 不发送");
                    return ;
                }
                ChatMessageModel *messageM = [ChatMessageModel new];
                messageM.isFormMe = YES;
                messageM.userName = [UIDevice currentDevice].name;
                messageM.chatMessageType = ChatMessageAudio;
                messageM.mediaMessageUrl = [VoiceManager voiceManagerShare].currentRecordUrl;
                messageM.mediaDuration = duration;
                messageM.fileName = [[NSString stringWithFormat:@"%zd",[[NSDate date] timeIntervalSinceReferenceDate]] stringByAppendingString:@".caf"];
                NSData *audioData = [NSData dataWithContentsOfURL:messageM.mediaMessageUrl options:NSDataReadingMappedIfSafe error:nil];
                messageM.fileSize = audioData.length;
                [weakSelf sendMessageWithItem:messageM];
            }];
        }
            break;
        case RecordVoiceStateCancle:{
            [[VoiceManager voiceManagerShare] cancleRecord];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - SocketManagerDelegate
- (void)socketManager:(SocketManager *)manager  itemUpingrefresh:(ChatMessageModel *)upingItem{
    // 刷新当前进度
    ChatMessageCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:upingItem.locationIndex inSection:0]];
    CGFloat progress = 1.0 * upingItem.upSize / upingItem.fileSize;
    [cell updataProgressWithValue:progress];
}

- (void)socketManager:(SocketManager *)manager  itemUpFinishrefresh:(ChatMessageModel *)finishItem{
    [self.tableView reloadData];
    [self scrollToLastCellAnimated:NO];
}

// 正在接受的文件回调
- (void)socketManager:(SocketManager *)manager  itemAcceptingrefresh:(ChatMessageModel *)acceptingItem{
    if (acceptingItem.finishAccept) {
        [self.messageItems addObject:acceptingItem];
        [self.tableView reloadData];
        [self scrollToLastCellAnimated:YES];
    }else{
       
    }
    
}

#pragma mark - private
- (void)scrollToLastCellAnimated:(BOOL)animated{
    if (self.messageItems.count <= 0) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat contentH = self.tableView.contentSize.height;
            CGFloat showH = 0;
            if (self.keyBoardToolView.inputTextView.isFirstResponder) {
                showH = self.tableView.hj_height - self.keyBoardToolView.systemKeyboardH;
            }else{
                showH = self.view.hj_height - self.keyBoardToolView.nowHeight - BOTTOMSAFEH;
            }
            CGFloat needOffsetY =  (contentH - showH);
            if (needOffsetY > 0) {
                [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, needOffsetY) animated:animated];
            }else{
                if (needOffsetY > (-NAVBARH)) {
                    [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, needOffsetY) animated:animated];
                }else{
                    [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, -(NAVBARH)) animated:animated];
                }
            }
        });
    });
}

- (void)sendMessageWithItem:(ChatMessageModel *)item{
    item.locationIndex = self.messageItems.count;
    [self.messageItems addObject:item];
    [self.tableView reloadData];
    [self scrollToLastCellAnimated:YES];
    SocketManager *manager = [SocketManager shareSockManager];
    [manager sendMessageWithItem:item];
}

// 发起视频聊天
- (void)inviteVideoChat{
    WebRTCManager *manager = [WebRTCManager webRTCManagerShare];
    [manager showRTCViewWithRemotName:[UIDevice currentDevice].name isVideo:YES isCaller:YES];
}

- (void)sendImageOrVideo{
    WS(weakSelf);
    [[PickerImageVideoTool sharePickerImageVideoTool] showImagePickerWithMaxCount:9 completion:^(NSArray<UIImage *> *photos, NSArray *assets) {
        NSInteger count = assets.count;
        id objc = nil;
        for (NSInteger i = 0; i < count; i++) {
            objc = assets[i];
            if (![objc isKindOfClass:[PHAsset class]]) {
                continue;
            }
            PHAsset *asset = (PHAsset *)objc;
            ChatMessageModel *messageM = [ChatMessageModel new];
            messageM.isFormMe = YES;
            messageM.userName = [UIDevice currentDevice].name;
            messageM.asset = asset;
            messageM.fileName = [ZPPublicMethod getAssetsName:asset only:YES];
            if (asset.mediaType == PHAssetMediaTypeImage){
                messageM.temImage = photos[i];
                [weakSelf pickImageHandle:messageM];
            }else if (asset.mediaType == PHAssetMediaTypeVideo) {
                messageM.chatMessageType = ChatMessageVideo;
                [weakSelf pickVideoHandle:messageM];
            }else if (asset.mediaType == PHAssetMediaTypeAudio){
                messageM.chatMessageType = ChatMessageAudio;
            }
        }
    }];
}

- (void)pickImageHandle:(ChatMessageModel*)messageM{
    messageM.chatMessageType = ChatMessageImage;
    messageM.fileSize = UIImagePNGRepresentation(messageM.temImage).length;
    SDImageCache *cache = [SDImageCache sharedImageCache];
    [cache storeImage:messageM.temImage forKey:messageM.fileName toDisk:YES completion:^{
        messageM.showImageUrl = [NSURL fileURLWithPath:[cache defaultCachePathForKey:messageM.fileName]];
    }];
    [self sendMessageWithItem:messageM];
}

- (void)pickVideoHandle:(ChatMessageModel *)messageM{
    // 视频getPhotoWithAsset
     [ZPPublicMethod getfilePath:messageM.asset Complete:^(NSURL *fileUrl) {
         dispatch_sync(dispatch_get_main_queue(), ^{
             messageM.fileSize = [ZPPublicMethod getFileSize:[[fileUrl absoluteString] substringFromIndex:8]];
             messageM.temImage = [ZPPublicMethod firstFrameWithVideoURL:fileUrl size:CGSizeMake(375, 667)];
             SDImageCache *cache = [SDImageCache sharedImageCache];
             NSString *keyStr = [messageM.fileName stringByAppendingString:@".JPG"];
             [cache storeImage:messageM.temImage forKey:keyStr toDisk:YES completion:^{
                 messageM.showImageUrl = [NSURL fileURLWithPath:[cache defaultCachePathForKey:keyStr]];
             }];
             [self sendMessageWithItem:messageM];
         });
     }];
    
}

#pragma mark - table view data source delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messageItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ChatMessageCell *cell = [ChatMessageCell chatMessageCell:tableView];
    ChatMessageModel *messageM = self.messageItems[indexPath.row];
    cell.dataModel = messageM;
    WS(weakSelf);
    cell.tapCellBlock = ^{
        [weakSelf.keyBoardToolView exitKeyBoard];
    };
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    ChatMessageModel *messageM = self.messageItems[indexPath.row];
    return messageM.cellH;
}

#pragma mark - table view delegate
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
//    if (velocity.y >= 0.1) {
//         [self.keyBoardToolView showKeyBoard];
//    }else if(velocity.y < 0){
//         [self.keyBoardToolView exitKeyBoard];
//    }
    if(velocity.y < 0){
        [self.keyBoardToolView exitKeyBoard];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    ChatMessageModel *messageM = self.messageItems[indexPath.row];
    if (messageM.chatMessageType == ChatMessageVideo) {
        AVPlayerViewController *playVC = [[AVPlayerViewController alloc] init];
        playVC.player = [AVPlayer playerWithURL:messageM.mediaMessageUrl];
        [self presentViewController:playVC animated:YES completion:nil];
    }else if (messageM.chatMessageType == ChatMessageAudio){
        [[VoiceManager voiceManagerShare] playAudioWithURL:messageM.mediaMessageUrl];
    }
}



#pragma mark - get / set
// 添加键盘工具条
- (ESKeyBoardToolView *)keyBoardToolView{
    if (!_keyBoardToolView) {
        self.keyBoardToolView = [[ESKeyBoardToolView alloc] init];
        self.keyBoardToolView.delegate = self;
        [self.view addSubview:self.keyBoardToolView];
        [self.keyBoardToolView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(self.view);
            make.height.mas_equalTo(TitleViewHeight);
            make.bottom.mas_equalTo(self.view.mas_bottom).offset(-BOTTOMSAFEH);
        }];
    }
    return _keyBoardToolView;
}

// chat tableView
- (UITableView *)tableView{
    if (!_tableView) {
        self.tableView = [[UITableView alloc] init];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.backgroundColor = [UIColor colorWithRed:231.0/255.0 green:232.0/255.0 blue:238.0/255.0 alpha:1];
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
        tapGestureRecognizer.cancelsTouchesInView = NO;
        [self.tableView addGestureRecognizer:tapGestureRecognizer];
        [self.view addSubview:self.tableView];
        [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(self.view);
            make.top.mas_equalTo(self.view);
            make.height.mas_equalTo(self.view.hj_height - TitleViewHeight - BOTTOMSAFEH);
        }];
    }
    return _tableView;
}

@end
