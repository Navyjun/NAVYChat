//
//  ChatMessageModel.h
//  ZPS
//
//  Created by 张海军 on 2017/11/23.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <Foundation/Foundation.h>

static CGFloat const messageLabelForHeadLeftMargin = 15.0;
static CGFloat const messageLabelForHeadRightMargin = 8.0;

typedef NS_ENUM(int,ChatMessageType) {
    ChatMessageText     = 0,
    ChatMessageImage    = 1,
    ChatMessageVideo    = 2,
    ChatMessageAudio    = 3,
    ChatMessageLoaction = 4
};

@interface ChatMessageModel : NSObject
/// userName
@property (nonatomic, copy) NSString *userName;
/// userIcon
@property (nonatomic, copy) NSString *iconUrl;
/// 消息类型
@property (nonatomic, assign) int chatMessageType;
/// 消息内容 文字
@property (nonatomic, copy) NSString *messageContent;
/// 富文本消息内容
@property (nonatomic, copy) NSMutableAttributedString *messageContentAttributed;
/// PHAsset 媒体资源
@property (nonatomic, strong) id asset;
/// 媒体消息本地保存地址
@property (nonatomic, copy) NSURL *mediaMessageUrl;
/// 是否来至于自己
@property (nonatomic, assign) BOOL isFormMe;
/// 临时引用图片
@property (nonatomic, strong) UIImage *temImage;

/*************************** 传输相关 *****************************/
/// userName
@property (nonatomic, copy) NSString *fileName;
/// sendTag
@property (nonatomic, assign) NSInteger sendTag;
/// 文件总大小
@property (nonatomic, assign) NSInteger fileSize;

/// 文件已上传大小
@property (nonatomic, assign) NSInteger upSize;
/// 是否正在上传中
@property (nonatomic, assign) BOOL isSending;
/// 当前文件是否已经全部传输完毕
@property (nonatomic, assign) BOOL isSendFinish;


/// 已接受的文件大小
@property (nonatomic, assign) NSInteger acceptSize;
/// 开始接受
@property (nonatomic, assign) BOOL beginAccept;
/// 接受完成
@property (nonatomic, assign) BOOL finishAccept;
/// 当前文件保存在本地的路径 <接收到文件>
@property (nonatomic, copy) NSString *acceptFilePath;
/// 是否在等待接收 <图片 / 视频 / 音频> 类型
@property (nonatomic, assign) BOOL isWaitAcceptFile;

/**************************** 发送相关 *********************************/
/// 是否发送成功
@property (nonatomic, assign) BOOL sendSuccess;

/*************************** UI相关 *****************************/
/// 消息宽度
@property (nonatomic, assign) CGFloat messageW;
/// 消息高度
@property (nonatomic, assign) CGFloat messageH;
/// cell高度
@property (nonatomic, assign) CGFloat cellH;
@end
