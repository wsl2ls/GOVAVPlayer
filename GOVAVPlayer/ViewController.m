//
//  ViewController.m
//  GOVAVPlayer
//
//  Created by 王双龙 on 17/2/7.
//  Copyright © 2017年 王双龙. All rights reserved.
//

#import "ViewController.h"
#import "GOVVideoView.h"

#define KScreenBounds ([[UIScreen mainScreen] bounds])
#define KScreenWidth (KScreenBounds.size.width)
#define KScreenHeight (KScreenBounds.size.height)


@interface ViewController () <GOVVideoPlayerDelegate>

@property (nonatomic, assign) BOOL isHiddenStatusBar;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GOVVideoView * videoView = [[GOVVideoView alloc] initWithFrame:CGRectMake(0, 0, KScreenWidth, KScreenHeight/2) url:@"http://baobab.kaiyanapp.com/api/v1/playUrl?vid=13867&editionType=normal&source=ucloud"];
    
    
//    videoView.fullScreenBlock = ^(BOOL isFull){
//        NSLog(@" Block 是否全屏 %d",isFull);
//    };
//    videoView.closePLayerBlock = ^{
//        
//        NSLog(@" Block 我点击了关闭按钮");
//    };
//    
//    videoView.showBarBlock = ^(BOOL isShow){
//        self.isHiddenStatusBar = !isShow;
//        //刷新状态栏状态
//        [self setNeedsStatusBarAppearanceUpdate];
//        NSLog(@" Block 是否隐藏 %d",isShow);
//    };
//    videoView.playFinishedBlock = ^{
//        
//        NSLog(@" Block 播放完成");
//        
//    };
    
    
    videoView.delegate = self;
    
    [self.view addSubview:videoView];
    
    //videoView.straightFull = YES;
    
}

//是否支持自动转屏
- (BOOL)shouldAutorotate{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark -- 隐藏/显示状态栏的方法
/*[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];这个方法在iOS9之后弃用了，并且需要
 将View controller-based status bar appearance设置为NO；而下面的重写方法需要将View controller-based status bar appearance设置为YES，这个方法在iOS7之后就有了；
 */
//设置样式
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
//设置是否隐藏
- (BOOL)prefersStatusBarHidden {
    return self.isHiddenStatusBar;
}
//设置隐藏动画
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

#pragma mark -- GOVVideoPlayerDelegate

- (void)videoPlayerPlayFinished:(GOVVideoView *)videoPlayer{
    NSLog(@" 代理 播放完成");
}

- (void)videoPlayerFullScreen:(GOVVideoView *)videoPlayer withIsFull:(BOOL)isFull{
    NSLog(@" 代理 是否全屏 %d",isFull);
}

- (void)videoPlayerClosePlayer:(GOVVideoView *)videoPlayer{

    NSLog(@" 代理 我点击了关闭按钮");
}

- (void)videoPlayerShowBar:(GOVVideoView *)videoPlayer withIsShow:(BOOL)isShow{
    
    self.isHiddenStatusBar = !isShow;
    //刷新状态栏状态
    [self setNeedsStatusBarAppearanceUpdate];
    NSLog(@" 代理 是否隐藏 %d",isShow);
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
