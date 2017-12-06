//
//  RTCViewController.m
//  ZPS
//
//  Created by 张海军 on 2017/12/6.
//  Copyright © 2017年 baoqianli. All rights reserved.
//

#import "RTCViewController.h"
#import "WebRTCHelper.h"

@interface RTCViewController ()

@end

@implementation RTCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // 便于测试
    if (HJSCREENH < 667) {
        SocketManager *manager = [SocketManager shareSockManager];
        [manager startListenPort:CURRENT_PORT];
    }
    
    if (HJSCREENH >= 667) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"连接" style:UIBarButtonItemStyleDone target:self action:@selector(leftItemDidClick)];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)leftItemDidClick{
    SocketManager *manager = [SocketManager shareSockManager];
    manager.delegate = self;
    [manager connentHost:CURRENT_HOST prot:CURRENT_PORT];
}

- (IBAction)sendOffer:(id)sender {
    [[WebRTCHelper shareWebRTCHelper] createOffers];
    
}


@end
