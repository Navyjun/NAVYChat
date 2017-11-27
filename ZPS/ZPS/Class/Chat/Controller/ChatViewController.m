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

@interface ChatViewController ()
<ESKeyBoardToolViewDelegate,
UITableViewDelegate,
UITableViewDataSource>

/// 键盘工具条
@property (nonatomic, strong) ESKeyBoardToolView *keyBoardToolView;
/// tableView
@property (nonatomic, strong) UITableView *tableView;
/// tableView y 原始偏移值
@property (nonatomic, assign) CGFloat orginalOffsetY;
/// 消息
@property (nonatomic, strong) NSMutableArray *messageItems;
@end

@implementation ChatViewController
#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"设置聊天背景" style:UIBarButtonItemStyleDone target:self action:@selector(rightItemDidClick)];
    
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
    
}

#pragma mark - ESKeyBoardToolViewDelegate
- (void)ESKeyBoardToolViewSendButtonDidClick:(ESKeyBoardToolView *)view message:(NSString *)message{
    ChatMessageModel *messageM = [ChatMessageModel new];
    messageM.isFormMe = message.length % 2 == 0 ? YES : NO;
    messageM.userName = message.length % 2 == 0 ? @"NAVY" : @"friend";
    messageM.messageContent = message;
    messageM.ChatMessageType = ChatMessageText;
    [self.messageItems addObject:messageM];
    [self.tableView reloadData];
    //[self scrollToLastCell];
}

- (void)ESKeyBoardToolViewDidEditing:(ESKeyBoardToolView *)view changeY:(CGFloat)yValue{
    CGFloat contentH = self.tableView.contentSize.height;
    // 此处需判断  导航条是否存在
    self.orginalOffsetY = NAVBARH;
    CGFloat showH = view.y - self.orginalOffsetY;
    CGFloat needOffsetY = contentH - showH;
    if (needOffsetY >= 0) {
        [self.tableView setContentOffset:CGPointMake(self.tableView.contentOffset.x, needOffsetY-self.orginalOffsetY) animated:yValue == 0 ? YES : NO];
    }
}

- (void)ESKeyBoardToolViewDidEndEdit:(ESKeyBoardToolView *)view{
    [self scrollToLastCell];
}

- (void)scrollToLastCell{
    if (self.messageItems.count <= 0) {
        return;
    }
    NSIndexPath *indexpath = [NSIndexPath indexPathForRow:(self.messageItems.count - 1) inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexpath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

#pragma mark - table view data source delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.messageItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    ChatMessageCell *cell = [ChatMessageCell chatMessageCell:tableView];
    ChatMessageModel *messageM = self.messageItems[indexPath.row];
    cell.dataModel = messageM;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    ChatMessageModel *messageM = self.messageItems[indexPath.row];
    return messageM.cellH;
}

#pragma mark - table view delegate
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (velocity.y >= 0.5) {
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
