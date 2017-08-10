//
//  GOVVideoPlayer.h
//  GovCn
//
//  Created by 王双龙 on 17/3/31.
//  Copyright © 2017年 cdi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef enum {
    GOVSmallScreen = 0, // 小屏
    GOVVerticalScreen, // 竖屏
    GOVCrossScreen  //横屏
} GOVScreenState;//当前视图处于的状态

static NSString * const GOVStatusBarHiddenNotification = @"GOVStatusBarHidden";//状态栏隐藏通知
static NSString * const GOVStatusBarColorNotification = @"GOVStatusBarColor";//状态栏颜色通知

#define iPhone4 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone6 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(750, 1334), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone6Plus ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2208), [[UIScreen mainScreen] currentMode].size) : NO)
#define iPhone6PlusScale ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2001), [[UIScreen mainScreen] currentMode].size) : NO)

//Block回调方法
typedef void(^FullScreenBlock)(BOOL isFull);

typedef void(^ClosePLayerBlock)();

typedef void(^ShowBarBlock)(BOOL isShow);

typedef void(^PlayFinishedBlock)();

@class GOVVideoPlayer;
//代理方法
@protocol GOVVideoPlayerDelegate  <NSObject>

//播放结束
- (void)videoPlayerPlayFinished:(GOVVideoPlayer *)videoPlayer;

//关闭播放器
- (void)videoPlayerClosePlayer:(GOVVideoPlayer *)videoPlayer;

//全屏按钮
- (void)videoPlayerFullScreen:(GOVVideoPlayer *)videoPlayer withIsFull:(BOOL)isFull;

//隐藏/展示footBar和topBar
- (void)videoPlayerShowBar:(GOVVideoPlayer *)videoPlayer withIsShow:(BOOL)isShow;

@end


@interface GOVVideoPlayer : UIView

//全屏/退出全屏的回调
@property (nonatomic, copy) FullScreenBlock  fullScreenBlock;

//关闭按钮的回调
@property (nonatomic, copy) ClosePLayerBlock closePLayerBlock;

//隐藏footBar和topBar回调
@property (nonatomic, copy) ShowBarBlock showBarBlock;

//播放完成的回调
@property (nonatomic, copy) PlayFinishedBlock playFinishedBlock;

//代理
@property (nonatomic,assign) id <GOVVideoPlayerDelegate>delegate;


@property (nonatomic, strong) AVPlayer *avPlayer;

//视频播放器所在的父视图
@property (nonatomic, weak) UIView * superView;

//是否是直接全屏播放
@property (nonatomic, assign) BOOL straightFull;

//视频内容是否是横屏
@property (nonatomic, assign) BOOL isCrossScreen;

@property (nonatomic, copy) NSString * contentURL;

- (instancetype)initWithFrame:(CGRect)frame url:(NSString *)url;

//切换当前
- (void)replaceCurrentItemWithUrl:(NSString *)url;

//直接全屏播放时调用
- (void)videoPlayerStraightFullPlay:(BOOL)straightFull withIsCrossScreen:(BOOL)isCrossScreen;

- (void)closeVideoPlayer;

- (void)hiddenBarAndCloseGestureRecognizer;

@end
