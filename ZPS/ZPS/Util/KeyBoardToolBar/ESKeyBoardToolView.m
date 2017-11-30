//
//  ESKeyBoardToolView.m
//  QianEyeShow
//
//  Created by 张海军 on 16/8/11.
//  Copyright © 2016年 baoqianli. All rights reserved.
//

#import "ESKeyBoardToolView.h"
#import "ESEmoticonView.h"

static CGFloat fontValue = 16.0;

@interface ESKeyBoardToolView () <UITextViewDelegate>
/// 表情按钮
@property (nonatomic, strong) UIButton *emoticonButton;
/// 输入框的背景图片
@property (nonatomic, strong) UIImageView *inputBgImageView;
/// 加号按钮
@property (nonatomic, strong) UIButton *addButton;
/// 占位文字的label
@property (nonatomic, strong) UILabel *placeTitleLabel;
/// inputView
@property (nonatomic, strong) UIView *inputView;
/// 表情view
@property (nonatomic, strong) ESEmoticonView *emoticonView;
/// 其它选项view
@property (nonatomic, strong) ESAddOpationView *addOpationView;
/// 当前textView的高度
@property (nonatomic, assign) CGFloat nowHeight;
/// 没一行文字的高度
@property (nonatomic, assign) CGFloat textRowHeight;
/// 当前的行数
@property (nonatomic, assign) NSInteger currentLine;
/// 当前是否正在编辑 外界不能操作退出键盘
@property (nonatomic, assign) BOOL isEditing;
@end

@implementation ESKeyBoardToolView
@synthesize inputTextView = _inputTextView;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.hj_height = TitleViewHeight;
        [self setupInit];
        self.backgroundColor = [UIColor colorWithRed:231.0/255.0 green:232.0/255.0 blue:238.0/255.0 alpha:1];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat margin = 10;
    // 表情按钮
    self.emoticonButton.size = CGSizeMake(30, 30);
    self.emoticonButton.x = margin;
    self.emoticonButton.centerY = self.hj_height * 0.5;
    
    // 输入框的背景图 / 输入框
    CGFloat inputX = CGRectGetMaxX(self.emoticonButton.frame) + margin;
    CGFloat inpitW = _isNeedHiddenAddButton ? (self.hj_width - inputX - 10) : (self.hj_width - 2 * inputX);
    CGFloat inputY = 5;
    CGFloat inputH = self.hj_height - 2 * inputY;
    NSString *str = @"输入文字";
    self.textRowHeight = [str hj_stringHeightWithMaxWidth:inpitW andFont:[UIFont systemFontOfSize:fontValue]].height;
    self.inputBgImageView.frame = CGRectMake(inputX, inputY, inpitW, inputH);
    self.inputTextView.frame  = CGRectMake(inputX, inputY, inpitW, inputH);
    self.placeTitleLabel.frame = CGRectMake(inputX + 5, inputY, inpitW - 5, inputH);
    
    // 添加按钮
    if (!_isNeedHiddenAddButton) {
        CGFloat addBX = self.hj_width - inputX + margin;
        self.addButton.size = CGSizeMake(30, 30);
        self.addButton.x = addBX;
        self.addButton.centerY = self.hj_height * 0.5;
    }
    
}

- (void)setupInit
{
    self.currentLine = 1;
    // 表情键盘按钮
    self.emoticonButton = [[UIButton alloc] init];
    [self.emoticonButton setImage:[UIImage imageNamed:@"表情_bt"] forState:UIControlStateNormal];
    [self.emoticonButton setImage:[UIImage imageNamed:@"文本_bt"] forState:UIControlStateSelected];
    [self.emoticonButton addTarget:self action:@selector(emoticonButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.emoticonButton];
    
    // 输入框背景图
    self.inputBgImageView = [[UIImageView alloc] init];
    UIImage *bgImage = [UIImage imageNamed:@"输入框_bg"];
    self.inputBgImageView.image = [UIImage resizable:bgImage];
    [self addSubview:self.inputBgImageView];
    
    
    // 占位label
    self.placeTitleLabel = [[UILabel alloc] init];
    self.placeTitleLabel.font = [UIFont systemFontOfSize:fontValue];
    self.placeTitleLabel.textColor = [UIColor lightGrayColor];
    self.placeTitleLabel.hidden = YES;
    [self addSubview:self.placeTitleLabel];
    
    // 输入框
    _inputTextView = [[UITextView alloc] init];
    _inputTextView.scrollEnabled = NO;
    _inputTextView.scrollsToTop = NO;
    _inputTextView.showsHorizontalScrollIndicator = NO;
    _inputTextView.enablesReturnKeyAutomatically = YES;
    _inputTextView.backgroundColor = [UIColor clearColor];
    _inputTextView.font = [UIFont systemFontOfSize:fontValue];
    _inputTextView.delegate = self;
    _inputTextView.returnKeyType = UIReturnKeySend;
    [self addSubview:_inputTextView];
    

    // 加号按钮
    self.addButton = [[UIButton alloc] init];
    [self.addButton setImage:[UIImage imageNamed:@"添加_bt"] forState:UIControlStateNormal];
    [self.addButton addTarget:self action:@selector(addButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.addButton];
    
    // 监听键盘高度变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
}


- (void)dealloc
{
    MYLog(@"键盘工具条被销毁");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setPlaceTitle:(NSString *)placeTitle
{
    _placeTitle = placeTitle;
    if (placeTitle.length) {
        self.placeTitleLabel.hidden = NO;
        self.placeTitleLabel.text = placeTitle;
    }
}

#pragma mark - notification hadle
- (void)keyBoardWillChange:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    double duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardF = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.showTime = duration;
    self.systemKeyboardH = keyboardF.size.height;
    if (keyboardF.origin.y < HJSCREENH) { // 键盘弹出
        if (!self.isEditing) {
            self.isEditing = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.showTime * 2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.isEditing = NO;
            });
        }
    }else{ // 退出键盘
        self.systemKeyboardH = 0;
    }
}

- (void)exitKeyBoard{
    if (self.isEditing) {
        return;
    }
    [self endEditing:YES];
}

- (void)showKeyBoard{
    if (!self.inputTextView.isFirstResponder) {
        [self.inputTextView becomeFirstResponder];
    }
}

#pragma mark - textView delegate
- (void)textViewDidChange:(UITextView *)textView
{
    NSString *textStr = textView.text;
    if (textStr.length) {
        self.placeTitleLabel.hidden = YES;
    }else{
        self.placeTitleLabel.hidden = NO;
    }
    self.isEditing = YES;
    NSInteger height = ceilf([textView sizeThatFits:CGSizeMake(textView.bounds.size.width, MAXFLOAT)].height);
    NSInteger lines = height / self.textRowHeight;
    // 判断最后一个字符是否为 "\n"
    if ([textStr hasSuffix:@"\n"]) {
        // 1.发送消息
        self.hj_height = TitleViewHeight;
        self.y += self.textRowHeight * (lines - 1);
        _currentLine = 1;
        self.isEditing = NO;
        textView.text = nil;
        textView.scrollEnabled = NO;
        [textView resignFirstResponder];
        
        NSRange range = [textStr rangeOfString:@"\n"];
        textStr = [textStr substringToIndex:range.location];
        if ([self.delegate respondsToSelector:@selector(ESKeyBoardToolViewSendButtonDidClick: message:)]) {
            [self.delegate ESKeyBoardToolViewSendButtonDidClick:self message:textStr];
        }
        return;
    }
    

    if (lines > maxLines) {
        textView.scrollEnabled = YES;
        _currentLine = maxLines;
        return;
    }
    textView.scrollEnabled = NO;
    
    // 当前变化的高度
    CGFloat offsetH = self.textRowHeight;
    
    if (lines > _currentLine) {
        offsetH = (lines - _currentLine) * self.textRowHeight;
        self.hj_height = height + 10;
        self.y -= offsetH;
    }else if (lines < _currentLine){
        // 文字删除减少的时候 减少的高度 上一次的行数 - 现在的行数
        offsetH = (_currentLine - lines) * self.textRowHeight;
        self.hj_height -= offsetH;
        self.y += offsetH;
    }
    
    if ([self.delegate respondsToSelector:@selector(ESKeyBoardToolViewDidEditing:changeY:)] && _currentLine != lines) {
        [self.delegate ESKeyBoardToolViewDidEditing:self changeY:lines > _currentLine ? (-offsetH) : (offsetH)];
    }
    _currentLine = lines;
    
}

- (void)textViewDidBeginEditing:(UITextView *)textView{
    if ([self.delegate respondsToSelector:@selector(ESKeyBoardToolViewDidEditing:changeY:)]) {
        [self.delegate ESKeyBoardToolViewDidEditing:self changeY:0];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    self.isEditing = NO;
    if ([self.delegate respondsToSelector:@selector(ESKeyBoardToolViewDidEndEdit:)]) {
        [self.delegate ESKeyBoardToolViewDidEndEdit:self];
    }
    [self exitKeyBoardInputView];
}


#pragma mark - event
// 表情按钮的点击
- (void)emoticonButtonDidClick:(UIButton *)button
{
    _isChangeEmoticon = YES;
    if (self.addButton.selected) {
        self.addButton.selected = NO;
    }
    self.addOpationView.hidden = YES;
    self.emoticonView.hidden = NO;
    if (!self.emoticonView.superview) {
        [self.inputView addSubview:self.emoticonView];
    }
    [self changeInputView:self.inputView selected:button.selected];
    button.selected = !button.selected;
}

- (void)addButtonDidClick:(UIButton *)button{
    if (self.emoticonButton.selected) {
        self.emoticonButton.selected = NO;
    }
    self.emoticonView.hidden = YES;
    self.addOpationView.hidden = NO;
    if (!self.addOpationView.superview) {
        [self.inputView addSubview:self.addOpationView];
    }
    [self changeInputView:self.inputView selected:button.selected];
    button.selected = !button.selected;
}

- (void)changeInputView:(UIView *)inputView selected:(BOOL)isSelected{
    if (!isSelected && self.inputTextView.inputView) {
        self.inputTextView.inputView = inputView;
        return;
    }
    
    __block CGFloat orginY = self.y;
    if (!self.inputTextView.inputView) {
        self.inputTextView.inputView = inputView;
    }else{
        self.inputTextView.inputView = nil;
    }
    // 退出键盘
    [self.inputTextView resignFirstResponder];
    // 再次成为第一响应者
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.inputTextView becomeFirstResponder];
            orginY = self.y - orginY;
            if ([self.delegate respondsToSelector:@selector(ESKeyBoardToolViewDidEditing:changeY:)]) {
                [self.delegate ESKeyBoardToolViewDidEditing:self changeY:orginY];
            }
            _isChangeEmoticon = NO;
    });
}

// 退出表情键盘 选项键盘
- (void)exitKeyBoardInputView{
    self.emoticonButton.selected = NO;
    self.addButton.selected = NO;
    self.inputTextView.inputView = nil;
}

#pragma mark - lazy
- (ESEmoticonView *)emoticonView
{
    if (!_emoticonView) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"defaultEmotion.plist" ofType:nil];
        _emoticonView = [ESEmoticonView emoticonView];
        _emoticonView.emotions = [ESEmotionModel mj_objectArrayWithKeyValuesArray:[NSArray arrayWithContentsOfFile:path]];
        _emoticonView.backgroundColor = [UIColor whiteColor];
        WS(weakSelf);
        _emoticonView.sendButtonDidClickBlock = ^{
            NSString *message = weakSelf.inputTextView.text;
            [weakSelf.inputTextView resignFirstResponder];
            if ([weakSelf.delegate respondsToSelector:@selector(ESKeyBoardToolViewSendButtonDidClick: message:)]) {
                weakSelf.isEditing = NO;
                [weakSelf.delegate ESKeyBoardToolViewSendButtonDidClick:weakSelf message:message];
            }
            NSInteger count = message.length;
            for (NSInteger i = 0; i < count; i++) {
                [weakSelf.inputTextView deleteBackward];
            }
        };
        _emoticonView.insetEmoticonBlock = ^ (NSString *message){
            [weakSelf.inputTextView insertText:message];
        };
        _emoticonView.deleteEmoticonBlock = ^{
            [weakSelf.inputTextView deleteBackward];
        };
    }
    return _emoticonView;
}

- (ESAddOpationView *)addOpationView{
    if (!_addOpationView) {
        _addOpationView = [ESAddOpationView addOpationView];
        OpationItem *item = [OpationItem opationItemWithName:@"照片" iconName:@"chat_img" type:OpationItem_image];
        _addOpationView.opationItem = @[item];
        
        WS(weakSelf);
        _addOpationView.selectedOpationHandle = ^(OpationItem_type type){
            if ([weakSelf.delegate respondsToSelector:@selector(ESKeyBoardToolViewAddOpationDidSelected:withType:)]) {
                [weakSelf.delegate ESKeyBoardToolViewAddOpationDidSelected:weakSelf withType:type];
            }
        };
    }
    return _addOpationView;
}

- (UIView *)inputView{
    if (!_inputView) {
        _inputView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, HJSCREENW, 216)];
    }
    return _inputView;
}

@end
