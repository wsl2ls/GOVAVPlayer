//
//  ViewController.m
//  GOVAVPlayer
//
//  Created by 王双龙 on 17/2/7.
//  Copyright © 2017年 王双龙. All rights reserved.
//

#import "ViewController.h"
#import "GOVVideoController.h"
#import "GOVTransitionAnimation.h"

#define KScreenBounds ([[UIScreen mainScreen] bounds])
#define KScreenWidth (KScreenBounds.size.width)
#define KScreenHeight (KScreenBounds.size.height)

@interface ViewController () <GOVVideoControllerDelegate>
{
    //必须是成员变量，防止对象被提前释放
    GOVVideoController * _videoController;
    
}

@property (nonatomic, assign) BOOL isHiddenStatusBar;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor greenColor];
    
    
    UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(100, 40, 50, 50)];
    [button addTarget:self action:@selector(buttonClicked) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"切换" forState:UIControlStateNormal];
    [self.view addSubview:button];
    
    _videoController = [[GOVVideoController alloc] initWithFrame:CGRectMake(0,100, KScreenWidth, KScreenHeight/2) url:@"http://baobab.kaiyanapp.com/api/v1/playUrl?vid=39183&editionType=normal&source=qcloud"];
    _videoController.delegate = self;
    _videoController.superView = self.view;
    _videoController.presentVC = self;
    _videoController.isCrossScreen = YES;
    
    [_videoController startVideoPlayer];
    
    [self.view addSubview:_videoController.view];
    
}

- (void)buttonClicked{
    
    [_videoController replaceCurrentItemWithUrl:@"http://baobab.kaiyanapp.com/api/v1/playUrl?vid=39182&editionType=normal&source=qcloud"];
    
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
    return UIStatusBarStyleDefault;
}
//设置是否隐藏
- (BOOL)prefersStatusBarHidden {
    return self.isHiddenStatusBar;
}
//设置隐藏动画
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

#pragma mark -- GOVVideoControllerDelegate

- (void)videoPlayerPlayFinished:(GOVVideoController *)videoController{
    
    NSLog(@" 代理 播放完成");
}

- (void)videoPlayerFullScreen:(GOVVideoController *)videoController withIsFull:(BOOL)isFull{
    
    NSLog(@" 代理 是否全屏 %d",isFull);
}

- (void)videoPlayerClosePlayer:(GOVVideoController *)videoController{
    
    NSLog(@" 代理 我点击了关闭按钮");
}

- (void)videoPlayerShowBar:(GOVVideoController *)videoController withIsShowBar:(BOOL)isShow ishiddenStatusBar:(BOOL)hidden{
    
    self.isHiddenStatusBar = hidden;
    //刷新状态栏状态
    [self setNeedsStatusBarAppearanceUpdate];
    NSLog(@" 代理 是否隐藏 %d",isShow);
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
