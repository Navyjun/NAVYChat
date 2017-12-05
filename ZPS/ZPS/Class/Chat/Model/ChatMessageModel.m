//
//  ChatMessageModel.m
//  ZPS
//
//  Created by 张海军 on 2017/11/23.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "ChatMessageModel.h"
#import "ESEmoticonTool.h"
#import <SDImageCache.h>

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
        if (self.chatMessageType == ChatMessageText) {
            [self messageContentWH];
        }else if (self.chatMessageType == ChatMessageImage || self.chatMessageType == ChatMessageVideo){
            _messageH = self.messageW * 1.5;
        }else if(self.chatMessageType == ChatMessageAudio){
            _messageH = 40.0;
        }
    }
    return _messageH;
}

- (CGFloat)messageW{
    if (_messageW == 0) {
        if (self.chatMessageType == ChatMessageText) {
            [self messageContentWH];
        }else if (self.chatMessageType == ChatMessageImage || self.chatMessageType == ChatMessageVideo){
            CGFloat maxW = HJSCREENW - 2 * MESSAGELRMARGIN - (messageLabelForHeadLeftMargin + messageLabelForHeadRightMargin);
            _messageW = maxW - 40;
        }else if(self.chatMessageType == ChatMessageAudio){
            // 这个要根据时长来计算
            _messageW = 120;
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

#pragma mark - 存储
- (void)setFinishAccept:(BOOL)finishAccept{
    _finishAccept = finishAccept;
    // 只有视频才来保存第一帧的图片到本地
    if (finishAccept && self.chatMessageType == ChatMessageVideo) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            UIImage *image = [ZPPublicMethod firstFrameWithVideoURL:self.mediaMessageUrl size:CGSizeMake(375, 667)];
            SDImageCache *cache = [SDImageCache sharedImageCache];
            NSString *keyStr = [self.fileName stringByAppendingString:@".JPG"];
            [cache storeImage:image forKey:keyStr toDisk:YES completion:^{
                self.showImageUrl = [NSURL fileURLWithPath:[cache defaultCachePathForKey:keyStr]];
            }];
        });
    }
}

@end
