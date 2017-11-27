//
//  ChatMessageModel.m
//  ZPS
//
//  Created by 张海军 on 2017/11/23.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "ChatMessageModel.h"
#import "ESEmoticonTool.h"

@implementation ChatMessageModel

- (CGFloat)cellH{
    if (_cellH == 0) {
        CGFloat totalH = 8+6+8+17+self.messageH;
        if (totalH < USERICONH) {
            totalH = USERICONH;
        }
        _cellH = totalH;
    }
    return _cellH;
}

- (CGFloat)messageH{
    if (_messageH == 0) {
        if (self.ChatMessageType == ChatMessageText) {
            [self messageContentWH];
        }else if (self.ChatMessageType == ChatMessageImage || self.ChatMessageType == ChatMessageVideo){
            _messageH = self.messageW * 1.5;
        }
    }
    return _messageH;
}

- (CGFloat)messageW{
    if (_messageW == 0) {
        if (self.ChatMessageType == ChatMessageText) {
            [self messageContentWH];
        }else if (self.ChatMessageType == ChatMessageImage || self.ChatMessageType == ChatMessageVideo){
            CGFloat maxW = HJSCREENW - 2 * MESSAGELRMARGIN - (messageLabelForHeadLeftMargin + messageLabelForHeadRightMargin);
            _messageW = maxW - 40;
        }
    }
    return _messageW;
}

- (void)messageContentWH{
    CGFloat maxW = HJSCREENW - 2 * MESSAGELRMARGIN - (messageLabelForHeadLeftMargin + messageLabelForHeadRightMargin);
    CGRect topicRect = [self.messageContentAttributed boundingRectWithSize:CGSizeMake(maxW, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    
    _messageH = topicRect.size.height+10;
    _messageW = topicRect.size.width+25;
}

- (NSMutableAttributedString *)messageContentAttributed{
    if (!_messageContentAttributed) {
        _messageContentAttributed = [ESEmoticonTool emoticonAttributedWithText:self.messageContent font:[UIFont systemFontOfSize:MESSAGEFONT]];
    }
    return _messageContentAttributed;
}

@end