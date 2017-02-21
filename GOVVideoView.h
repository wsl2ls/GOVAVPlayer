//
//  GOVVideoView.h
//  GOVAVPlayer
//
//  Created by 王双龙 on 17/2/7.
//  Copyright © 2017年 王双龙. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

//Block回调方法
typedef void(^FullScreenBlock)(BOOL isFull);

typedef void(^ClosePLayerBlock)();

typedef void(^ShowBarBlock)(BOOL isShow);

typedef void(^PlayFinishedBlock)();


@class GOVVideoView;
//代理方法
@protocol GOVVideoPlayerDelegate  <NSObject>

//播放结束
- (void)videoPlayerPlayFinished:(GOVVideoView *)videoPlayer;

//关闭播放器
- (void)videoPlayerClosePlayer:(GOVVideoView *)videoPlayer;

//全屏按钮
- (void)videoPlayerFullScreen:(GOVVideoView *)videoPlayer withIsFull:(BOOL)isFull;

//隐藏/展示footBar和topBar
- (void)videoPlayerShowBar:(GOVVideoView *)videoPlayer withIsShow:(BOOL)isShow;

@end

@interface GOVVideoView : UIView

@property (nonatomic, strong) AVPlayer *avPlayer;

//全屏/退出全屏的回调
@property (nonatomic, copy) FullScreenBlock  fullScreenBlock;

//关闭按钮的回调
@property (nonatomic, copy) ClosePLayerBlock closePLayerBlock;

//隐藏footBar和topBar回调
@property (nonatomic, copy) ShowBarBlock showBarBlock;

//播放完成的回调
@property (nonatomic, copy) PlayFinishedBlock playFinishedBlock;

//代理
@property (nonatomic, assign) id <GOVVideoPlayerDelegate>delegate;

//是否是直接全屏播放
@property (nonatomic, assign) BOOL straightFull;

- (instancetype)initWithFrame:(CGRect)frame url:(NSString *)url;


@end
