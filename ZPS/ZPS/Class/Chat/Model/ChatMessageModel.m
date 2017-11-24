//
//  ChatMessageModel.m
//  ZPS
//
//  Created by 张海军 on 2017/11/23.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "ChatMessageModel.h"

@implementation ChatMessageModel

- (CGFloat)cellH{
    if (_cellH == 0) {
        CGFloat totalH = 8+6+8+17+self.messageH;
        if (totalH < USERICONH) {
            totalH = USERICONH;
        }
        _cellH = totalH;
        NSLog(@"_cellH = %f",_cellH);
    }
    return _cellH;
}

- (CGFloat)messageH{
    if (_messageH == 0) {
        [self messageContentWH];
    }
    return _messageH;
}

- (CGFloat)messageW{
    if (_messageW == 0) {
        [self messageContentWH];
    }
    return _messageW;
}

- (void)messageContentWH{
    CGFloat maxW = HJSCREENW - 2 * MESSAGELRMARGIN - (messageLabelForHeadLeftMargin + messageLabelForHeadRightMargin);
    CGRect topicRect = [self.messageContent boundingRectWithSize:CGSizeMake(maxW, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:MESSAGEFONT]} context:nil];
    _messageH = topicRect.size.height+10;
    _messageW = topicRect.size.width+25;
}

@end
