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
static CGFloat MAXH = 103.0;

@interface ESKeyBoardToolView () <UITextViewDelegate>
/// 表情按钮
@property (nonatomic, strong) UIButton *emoticonButton;
/// 加号按钮
@property (nonatomic, strong) UIButton *addButton;
/// 语音按钮
@property (nonatomic, strong) UIButton *voiceButton;
/// 开始录音按钮
@property (nonatomic, strong) UIButton *beginRecordButton;
/// 输入框的背景图片
@property (nonatomic, strong) UIImageView *inputBgImageView;
/// 占位文字的label
@property (nonatomic, strong) UILabel *placeTitleLabel;
/// inputView
@property (nonatomic, strong) UIView *inputView;
/// 表情view
@property (nonatomic, strong) ESEmoticonView *emoticonView;
/// 其它选项view
@property (nonatomic, strong) ESAddOpationView *addOpationView;
/// 每一行文字的高度
@property (nonatomic, assign) CGFloat textRowHeight;
/// 当前的行数
@property (nonatomic, assign) NSInteger currentLine;
/// 最大行数时的高度
@property (nonatomic, assign) CGFloat maxHeight;
@end

@implementation ESKeyBoardToolView
@synthesize inputTextView = _inputTextView;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.hj_height = TitleViewHeight;
        self.nowHeight = TitleViewHeight;
        [self setupInit];
        self.backgroundColor = [UIColor colorWithRed:231.0/255.0 green:232.0/255.0 blue:238.0/255.0 alpha:1];
        NSString *str = @"输入文字";
        self.textRowHeight = [str hj_stringHeightWithMaxWidth:MAXFLOAT andFont:[UIFont systemFontOfSize:fontValue]].height;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat margin = 10;
    self.hj_height = self.nowHeight;
  
    
    // 语音按钮
    self.voiceButton.size = CGSizeMake(30, 30);
    self.voiceButton.x = margin;
    self.voiceButton.centerY = self.nowHeight * 0.5;
    
    // 输入框的背景图 / 输入框
    CGFloat inputX = CGRectGetMaxX(self.voiceButton.frame) + margin;
    CGFloat inpitW = _isNeedHiddenAddButton ? (self.hj_width - inputX - 10) : (self.hj_width - 3 * inputX + margin);
    CGFloat inputY = 5;
    CGFloat inputH = self.nowHeight - 2 * inputY;

    self.inputBgImageView.frame = CGRectMake(inputX, inputY, inpitW, inputH);
    self.inputTextView.frame  = CGRectMake(inputX, inputY, inpitW, inputH);
    self.placeTitleLabel.frame = CGRectMake(inputX + 5, inputY, inpitW - 5, inputH);
    self.beginRecordButton.frame = self.inputTextView.frame;
    
    // 表情按钮
    self.emoticonButton.size = CGSizeMake(30, 30);
    self.emoticonButton.x = CGRectGetMaxX(self.inputTextView.frame) + margin;;
    self.emoticonButton.centerY = self.nowHeight * 0.5;
    
    // 添加按钮
    if (!_isNeedHiddenAddButton) {
        CGFloat addBX = self.hj_width - inputX + margin;
        self.addButton.size = CGSizeMake(30, 30);
        self.addButton.x = addBX;
        self.addButton.centerY = self.nowHeight * 0.5;
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
    
    // 语音按钮
    self.voiceButton = [[UIButton alloc] init];
    [self.voiceButton setImage:[UIImage imageNamed:@"音频_bt"] forState:UIControlStateNormal];
    [self.voiceButton setImage:[UIImage imageNamed:@"文本_bt"] forState:UIControlStateSelected];
    [self.voiceButton addTarget:self action:@selector(voiceButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.voiceButton];
    
    
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
    [self.addButton setImage:[UIImage imageNamed:@"文本_bt"] forState:UIControlStateSelected];
    [self.addButton addTarget:self action:@selector(addButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.addButton];
    
    // 开始录音按钮
    self.beginRecordButton = [[UIButton alloc] init];
    self.beginRecordButton.backgroundColor = [UIColor colorWithRed:231.0/255.0 green:232.0/255.0 blue:238.0/255.0 alpha:0.5];
    [self.beginRecordButton setTitle:@"按住 说话" forState:UIControlStateNormal];
    [self.beginRecordButton setTitle:@"松开 结束" forState:UIControlStateHighlighted];
    [self.beginRecordButton setBackgroundImage:[UIImage imageWithColor:[UIColor grayColor]] forState:UIControlStateHighlighted];
    [self.beginRecordButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.beginRecordButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
    [self.beginRecordButton addTarget:self action:@selector(recordButtonDidBegin:) forControlEvents:UIControlEventTouchDown];
    [self.beginRecordButton addTarget:self action:@selector(recordButtonDidFinish:) forControlEvents:UIControlEventTouchUpInside];
    [self.beginRecordButton addTarget:self action:@selector(recordButtonDidCancle:) forControlEvents:UIControlEventTouchUpOutside];
    [self addSubview:self.beginRecordButton];
    self.beginRecordButton.hidden = YES;
    
    // 监听键盘高度变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyBoardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
}


- (void)dealloc
{
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
    }else{ // 退出键盘
        self.systemKeyboardH = 0;
    }
}

- (void)exitKeyBoard{
//    if (self.isEditing) {
//        return;
//    }
    [self endEditing:YES];
    [self exitKeyBoardInputView];
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
    
    NSInteger height = ceilf([textView sizeThatFits:CGSizeMake(textView.bounds.size.width, MAXFLOAT)].height);
    NSInteger lines = height / self.textRowHeight;
    
    // 判断最后一个字符是否为 "\n" 发送消息
    if ([textStr hasSuffix:@"\n"]) {
        [self sendMessageLayoutWithTextLines:lines message:textStr];
        return;
    }
    

    if (lines > maxLines) {
        textView.scrollEnabled = YES;
        _currentLine = maxLines;
//        if (self.nowHeight == TitleViewHeight) { // 第一次发送消息
//            CGFloat offsetH = (maxLines - 1) * self.textRowHeight;
//            self.hj_height = MAXH;
//            self.y -= offsetH;
//            [self layoutIfNeeded];
//        }
        return;
    }
    textView.scrollEnabled = NO;
    
    // 同一行不需要再次计算
    if (_currentLine == lines) {
        return;
    }
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
    self.nowHeight = self.hj_height;
    
    if ([self.delegate respondsToSelector:@selector(ESKeyBoardToolViewDidEditing:changeY:)] && _currentLine != lines) {
        [self.delegate ESKeyBoardToolViewDidEditing:self changeY:lines > _currentLine ? (-offsetH) : (offsetH)];
    }
    _currentLine = lines;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"])
    {
        NSInteger height = ceilf([textView sizeThatFits:CGSizeMake(textView.bounds.size.width, MAXFLOAT)].height);
        NSInteger lines = height / self.textRowHeight;
        [self sendMessageLayoutWithTextLines:lines message:textView.text];
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView{
    if ([self.delegate respondsToSelector:@selector(ESKeyBoardToolViewDidEditing:changeY:)]) {
        [self.delegate ESKeyBoardToolViewDidEditing:self changeY:0];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    if ([self.delegate respondsToSelector:@selector(ESKeyBoardToolViewDidEndEdit:)]) {
        [self.delegate ESKeyBoardToolViewDidEndEdit:self];
    }
    
}

#pragma mark - method
// 消息发送后重新布局
- (void)sendMessageLayoutWithTextLines:(NSInteger)lines message:(NSString *)message{
    self.hj_height = TitleViewHeight;
    self.nowHeight = TitleViewHeight;
    self.y += self.textRowHeight * (lines - 1);
    self.currentLine = 1;
    self.inputTextView.text = nil;
    self.inputTextView.scrollEnabled = NO;
    [self.inputTextView resignFirstResponder];
    
    if ([self.delegate respondsToSelector:@selector(ESKeyBoardToolViewSendButtonDidClick: message:)]) {
        [self.delegate ESKeyBoardToolViewSendButtonDidClick:self message:message];
    }
}


#pragma mark - event
// 语音按钮
- (void)voiceButtonDidClick:(UIButton *)button{
    button.selected = !button.selected;
    self.beginRecordButton.hidden = !button.selected;
    if (button.selected) {
        [self.inputTextView resignFirstResponder];
        [self exitKeyBoardInputView];
    }
}

// 开始录音
- (void)recordButtonDidBegin:(UIButton *)button{
    if ([self.delegate respondsToSelector:@selector(ESKeyBoardToolViewRecordWithState:)]) {
        [self.delegate ESKeyBoardToolViewRecordWithState:RecordVoiceStateBegin];
    }
}

// 发送录音
- (void)recordButtonDidFinish:(UIButton *)button{
    if ([self.delegate respondsToSelector:@selector(ESKeyBoardToolViewRecordWithState:)]) {
        [self.delegate ESKeyBoardToolViewRecordWithState:RecordVoiceStateFinish];
    }
}

// 取消
- (void)recordButtonDidCancle:(UIButton *)button{
    if ([self.delegate respondsToSelector:@selector(ESKeyBoardToolViewRecordWithState:)]) {
        [self.delegate ESKeyBoardToolViewRecordWithState:RecordVoiceStateCancle];
    }
}


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
    button.selected = !button.selected;
    [self changeInputView:self.inputView selected:button.selected];
}
// 加号按钮
- (void)addButtonDidClick:(UIButton *)button{
    if (self.emoticonButton.selected) {
        self.emoticonButton.selected = NO;
    }
    self.emoticonView.hidden = YES;
    self.addOpationView.hidden = NO;
    if (!self.addOpationView.superview) {
        [self.inputView addSubview:self.addOpationView];
    }
    button.selected = !button.selected;
    [self changeInputView:self.inputView selected:button.selected];
}

- (void)changeInputView:(UIView *)inputView selected:(BOOL)isSelected{
    // 取消语音按钮选中
    if (self.voiceButton.isSelected) {
        [self voiceButtonDidClick:self.voiceButton];
    }
    
    if (isSelected && self.inputTextView.inputView) {
        [self.inputTextView becomeFirstResponder];
        self.inputTextView.inputView = inputView;
        return;
    }
    
    __block CGFloat orginY = self.y;
    if (!isSelected) {
        self.inputTextView.inputView = nil;
    }else{
        self.inputTextView.inputView = inputView;
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
            NSInteger height = ceilf([weakSelf.inputTextView sizeThatFits:CGSizeMake(weakSelf.inputTextView.bounds.size.width, MAXFLOAT)].height);
            NSInteger lines = height / weakSelf.textRowHeight;
            // 1.发送消息
            [weakSelf sendMessageLayoutWithTextLines:lines message:message];
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
        OpationItem *imgItem = [OpationItem opationItemWithName:@"照片" iconName:@"chat_img" type:OpationItem_image];
        OpationItem *videoItem = [OpationItem opationItemWithName:@"视频聊天" iconName:@"chat_video" type:OpationItem_video];
        _addOpationView.opationItem = @[imgItem,videoItem];
        
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
