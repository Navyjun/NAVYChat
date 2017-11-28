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
#import <TZImagePickerController.h>

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
/// 消息
@property (nonatomic, strong) NSMutableArray *messageItems;
@end

@implementation ChatViewController
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    SocketManager *manager = [SocketManager shareSockManager];
    manager.delegate = self;
    [manager startListenPort:CURRENT_PORT];
    
    [self setupInit];
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
    
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"连接" style:UIBarButtonItemStyleDone target:self action:@selector(leftItemDidClick)];
    
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
            make.bottom.mas_equalTo(self.view.mas_bottom);
            make.height.mas_equalTo(TitleViewHeight);
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
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 columnNumber:4 delegate:self pushPhotoPickerVc:NO];
    imagePickerVc.allowTakePicture = YES; //内部显示拍照按钮
    imagePickerVc.allowPickingVideo = NO;
    imagePickerVc.allowPickingImage = YES;
    imagePickerVc.allowPickingOriginalPhoto = YES;
    imagePickerVc.allowPickingGif = YES;
    [self presentViewController:imagePickerVc animated:YES completion:nil];
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

- (void)ESKeyBoardToolViewDidEditing:(ESKeyBoardToolView *)view changeY:(CGFloat)yValue{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        CGFloat contentH = self.tableView.contentSize.height;
        // 此处需判断  导航条是否存在
        self.orginalOffsetY = NAVBARH;
        CGFloat showH = view.y - self.orginalOffsetY;
        CGFloat needOffsetY = contentH - showH;
        if (needOffsetY >= 0) {
            [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, needOffsetY-self.orginalOffsetY) animated:yValue == 0 ? YES : NO];
        }
        
    });
    
}

- (void)ESKeyBoardToolViewDidEndEdit:(ESKeyBoardToolView *)view{
    [self scrollToLastCell];
}

- (void)scrollToLastCell{
    if (self.messageItems.count <= 0) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat contentH = self.tableView.contentSize.height;
        CGFloat showH = self.tableView.hj_height - (self.view.hj_height - self.keyBoardToolView.y - TitleViewHeight);
        CGFloat needOffsetY =  (contentH - showH);
        if (needOffsetY > 0) {
            [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, needOffsetY) animated:YES];
        }
        
    });
    
}

- (void)sendMessageWithItem:(ChatMessageModel *)item{
    SocketManager *manager = [SocketManager shareSockManager];
    [manager sendMessageWithItem:item];
}

#pragma mark - TZImagePickerControllerDelegate
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto{
    if (!self.chatBgImageView) {
        self.chatBgImageView = [[UIImageView alloc] initWithFrame:self.tableView.frame];
        self.chatBgImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    if (photos.count>0) {
        self.chatBgImageView.image = [photos firstObject];
        self.tableView.backgroundView = self.chatBgImageView;
    }
}

#pragma mark - SocketManagerDelegate
- (void)socketManager:(SocketManager *)manager  itemUpingrefresh:(ChatMessageModel *)upingItem{
    
}

- (void)socketManager:(SocketManager *)manager  itemUpFinishrefresh:(ChatMessageModel *)finishItem{
    [self.messageItems addObject:finishItem];
    [self.tableView reloadData];
    [self scrollToLastCell];
}

// 正在接受的文件回调
- (void)socketManager:(SocketManager *)manager  itemAcceptingrefresh:(ChatMessageModel *)acceptingItem{
    if (acceptingItem.finishAccept) {
        [self.messageItems addObject:acceptingItem];
        [self.tableView reloadData];
        [self scrollToLastCell];
    }
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
    if (velocity.y >= 0.1) {
         [self.keyBoardToolView showKeyBoard];
    }else if(velocity.y < 0){
         [self.keyBoardToolView exitKeyBoard];
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
            make.left.right.bottom.mas_equalTo(self.view);
            make.height.mas_equalTo(TitleViewHeight);
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
            make.height.mas_equalTo(self.view.hj_height - TitleViewHeight);
        }];
    }
    return _tableView;
}

@end
