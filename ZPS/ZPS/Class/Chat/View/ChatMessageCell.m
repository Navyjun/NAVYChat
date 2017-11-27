//
//  ChatMessageCell.m
//  ZPS
//
//  Created by 张海军 on 2017/11/23.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "ChatMessageCell.h"

@interface ChatMessageCell ()
/// 朋友消息的背景图
@property (strong, nonatomic)  UIImage *friendMessageImage;
/// 自己消息的背景图
@property (strong, nonatomic)  UIImage *meMessageImage;
@property (strong, nonatomic)  UIImageView *userIconImageView;
@property (strong, nonatomic)  UILabel *userNameLabel;
@property (strong, nonatomic)  UIImageView *messageBgImageView;
@property (strong, nonatomic)  UILabel *messageLabel;
@property (strong, nonatomic)  UIImageView *meIconImageView;
@end

@implementation ChatMessageCell
+ (instancetype)chatMessageCell:(UITableView *)tableView{
    ChatMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([self class])];
    if (!cell) {
        cell = [[ChatMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([self class])];
        cell.backgroundColor = [UIColor colorWithRed:231.0/255.0 green:232.0/255.0 blue:238.0/255.0 alpha:1];
    }
    return cell;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setUI];
    }
    return self;
}


- (void)setUI{
    [self userIconImageView];
    [self meIconImageView];
    [self userNameLabel];
    [self messageBgImageView];
    [self messageLabel];
}

- (void)setDataModel:(ChatMessageModel *)dataModel{
    _dataModel = dataModel;
    
    [_messageBgImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(dataModel.messageW);
        make.top.mas_equalTo(self.userNameLabel.mas_bottom).offset(6);
        make.bottom.mas_equalTo(self.mas_bottom).offset(-8);
        if (dataModel.isFormMe) {
            make.right.mas_equalTo(self.meIconImageView.mas_left).offset(-15);
        }else{
            make.left.mas_equalTo(self.userIconImageView.mas_right).offset(15);
        }
    }];
    
    [_messageLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.mas_equalTo(self.messageBgImageView);
        make.left.mas_equalTo(self.messageBgImageView.mas_left).offset(dataModel.isFormMe ? messageLabelForHeadRightMargin : messageLabelForHeadLeftMargin);
        make.right.mas_equalTo(self.messageBgImageView.mas_right).offset(dataModel.isFormMe ? -messageLabelForHeadLeftMargin : -messageLabelForHeadRightMargin);
    }];
    
    
    self.userIconImageView.hidden = _dataModel.isFormMe ? YES : NO;
    self.meIconImageView.hidden = _dataModel.isFormMe ? NO : YES;
    self.messageBgImageView.image = _dataModel.isFormMe ? self.meMessageImage : self.friendMessageImage;
    self.userNameLabel.textAlignment = _dataModel.isFormMe ? NSTextAlignmentRight : NSTextAlignmentLeft;
    
    //self.messageLabel.text = _dataModel.messageContent;
    self.messageLabel.attributedText = _dataModel.messageContentAttributed;
    self.userNameLabel.text = _dataModel.userName;
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (self.cellTapBlock) {
        self.cellTapBlock();
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}

#pragma mark - set / get
- (UIImage *)friendMessageImage{
    if (!_friendMessageImage) {
        _friendMessageImage = [self imageResizabelWithName:@"chat_reciver_new"];
    }
    return _friendMessageImage;
}



- (UIImage *)meMessageImage{
    if (!_meMessageImage) {
        _meMessageImage = [self imageResizabelWithName:@"chat_send_new"];
    }
    return _meMessageImage;
}

- (UIImage *)imageResizabelWithName:(NSString *)imageName{
    UIImage *img = [UIImage imageNamed:imageName];
    CGFloat left = img.size.width * 0.5;
    CGFloat tb = img.size.height * 0.5;
    return [img resizableImageWithCapInsets:UIEdgeInsetsMake(left, tb, tb,left) resizingMode:UIImageResizingModeTile];
}

- (UIImageView *)userIconImageView{
    if (!_userIconImageView) {
        _userIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userIcon"]];
        [self addSubview:_userIconImageView];
        [_userIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.mas_top).offset(11.0);
            make.left.mas_equalTo(self.mas_left).offset(15.0);
            make.size.mas_equalTo(CGSizeMake(40, 40));
        }];
    }
    return _userIconImageView;
}

- (UIImageView *)meIconImageView{
    if (!_meIconImageView) {
        _meIconImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"userIcon"]];
        [self addSubview:_meIconImageView];
        [_meIconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.mas_top).offset(11.0);
            make.right.mas_equalTo(self.mas_right).offset(-15.0);
            make.size.mas_equalTo(CGSizeMake(40, 40));
        }];
    }
    return _meIconImageView;
}

- (UILabel *)userNameLabel{
    if (!_userNameLabel) {
        _userNameLabel = [[UILabel alloc] init];
        _userNameLabel.font = [UIFont systemFontOfSize:14.0];
        _userNameLabel.textColor = [UIColor blackColor];
        [self addSubview:_userNameLabel];
        [_userNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.mas_top).offset(8.0);
            make.left.mas_equalTo(self.userIconImageView.mas_right).offset(15.0);
            make.right.mas_equalTo(self.meIconImageView.mas_left).offset(-15.0);
            make.height.mas_equalTo(USERNAMEH);
        }];
    }
    return _userNameLabel;
}

- (UIImageView *)messageBgImageView{
    if (!_messageBgImageView) {
        _messageBgImageView = [[UIImageView alloc] init];
        [self addSubview:_messageBgImageView];
    }
    return _messageBgImageView;
}

- (UILabel *)messageLabel{
    if (!_messageLabel) {
        _messageLabel = [[UILabel alloc] init];
        _messageLabel.font = [UIFont systemFontOfSize:MESSAGEFONT];
        _messageLabel.textColor = [UIColor blackColor];
        _messageLabel.numberOfLines = 0;
        [self addSubview:_messageLabel];
        [_messageLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.messageBgImageView.mas_top);//.offset(5);
            make.bottom.mas_equalTo(self.messageBgImageView.mas_bottom);//.offset(-5);
        }];
        
    }
    return _messageLabel;
}

@end


