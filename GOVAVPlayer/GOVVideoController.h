//
//  GOVVideoController.h
//  GOVAVPlayer
//
//  Created by 王双龙 on 2017/8/2.
//  Copyright © 2017年 王双龙. All rights reserved.
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

typedef void(^ShowBarBlock)(BOOL isShowBar, BOOL hiddenStatusBar);

typedef void(^PlayFinishedBlock)();

@class GOVVideoController;
//代理方法
@protocol GOVVideoControllerDelegate  <NSObject>

//播放结束
- (void)videoPlayerPlayFinished:(GOVVideoController *)videoController;

//关闭播放器
- (void)videoPlayerClosePlayer:(GOVVideoController *)videoController;

//全屏按钮
- (void)videoPlayerFullScreen:(GOVVideoController *)videoController withIsFull:(BOOL)isFull;

//隐藏/展示footBar和topBar
- (void)videoPlayerShowBar:(GOVVideoController *)videoController withIsShowBar:(BOOL)isShow ishiddenStatusBar:(BOOL)hidden;

@end


@interface GOVVideoController : UIViewController 


//全屏/退出全屏的回调
@property (nonatomic, copy) FullScreenBlock  fullScreenBlock;

//关闭按钮的回调
@property (nonatomic, copy) ClosePLayerBlock closePLayerBlock;

//隐藏footBar和topBar回调
@property (nonatomic, copy) ShowBarBlock showBarBlock;

//播放完成的回调
@property (nonatomic, copy) PlayFinishedBlock playFinishedBlock;

//代理
@property (nonatomic,assign) id <GOVVideoControllerDelegate>delegate;


@property (nonatomic, strong) AVPlayer *avPlayer;

////视频播放器所在的父视图View
@property (nonatomic, weak) UIView * superView;
//视频播放器的上一个presentViewController
@property (nonatomic, weak) UIViewController * presentVC;  // (superView != nil && presentVC != nil)

//是否是直接全屏播放
@property (nonatomic, assign) BOOL straightFull;

//视频内容全屏时是否是横屏
@property (nonatomic, assign) BOOL isCrossScreen;

@property (nonatomic, copy) NSString * contentURL;

- (instancetype)initWithFrame:(CGRect)frame url:(NSString *)url;

//切换当前视频源
- (void)replaceCurrentItemWithUrl:(NSString *)url;

//直接全屏播放时调用
- (void)videoPlayerStraightFullPlay:(BOOL)straightFull withIsCrossScreen:(BOOL)isCrossScreen;

- (void)closeVideoPlayer;

- (void)startVideoPlayer;

//隐藏Bar和手势
- (void)hiddenBarAndCloseGestureRecognizer;

- (void)removeObserverAndNotification;

@end
