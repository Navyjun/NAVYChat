//
//  ChatMessageCell.h
//  ZPS
//
//  Created by 张海军 on 2017/11/23.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatMessageModel.h"

@interface ChatMessageCell : UITableViewCell
@property (nonatomic, strong) ChatMessageModel *dataModel;
+ (instancetype)chatMessageCell:(UITableView *)tableView;

@end

