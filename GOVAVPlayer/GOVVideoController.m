//
//  GOVVideoController.m
//  GOVAVPlayer
//
//  Created by 王双龙 on 2017/8/2.
//  Copyright © 2017年 王双龙. All rights reserved.
//

#import "GOVVideoController.h"
#import <MediaPlayer/MediaPlayer.h>
//#import "GOVCommon.h"
#import "GOVTransitionAnimation.h"

#define KPLAYVIEWWIDTH (self.view.frame.size.width)
#define KPLAYVIEWHEIGHT (self.view.frame.size.height)

#define KScreenBounds ([[UIScreen mainScreen] bounds])
#define KScreenWidth (KScreenBounds.size.width)
#define KScreenHeight (KScreenBounds.size.height)


@interface GOVVideoController ()<UIViewControllerTransitioningDelegate>
{
    CGRect _initFrame;
    AVPlayerLayer *_videoLayer;
    AVPlayerItem * _currentPlayerItem;
    UISlider *_volumeSlider;//音量slider
    id _playerTimeObserver; //播放进度观察者
    BOOL _isFull; //是否是全屏
    BOOL _isShowBar;
    BOOL _isClose;
    GOVTransitionAnimation * _pushAnimation;
}

@property (nonatomic, strong) UIView * displayView; //背景视图
@property (nonatomic, strong) UIView * topBar;//顶部导航栏
@property (nonatomic, strong) UIView * footBar;//底部导航栏

@property (nonatomic, strong) UIButton * playBtn;
@property (nonatomic, strong) UIButton * fullBtn; //全屏
@property (nonatomic, strong) UIButton * closeBtn;//关闭

//播放进度条
@property (nonatomic, strong) UISlider * slider;
//缓冲进度条
@property (nonatomic, strong) UIProgressView * progressView;
//当前播放时长
@property (nonatomic, strong) UILabel * currentTimeLabel;
//总的时长
@property (nonatomic, strong) UILabel * totalTimeLabel;

//菊花旋转等待
@property (nonatomic, strong) UIActivityIndicatorView *activityView;

//是否正在拖拽
@property (nonatomic, assign) BOOL dragSlider;

@property (nonatomic, assign) CGFloat current;// 当前时长

@property (nonatomic, assign) CGFloat total; //总时长

@property (nonatomic, assign) GOVScreenState  screenState;


@end


@implementation GOVVideoController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (id)initWithFrame:(CGRect)frame url:(NSString *)url{
    
    if(self == [super init]) {
        
        self.view.frame = frame;
        _initFrame = frame;
        _isShowBar = 1;
        _isClose = 0;
        _contentURL = url;
        
        _pushAnimation = [GOVTransitionAnimation new];
        _pushAnimation.transitionType = GOVTransitionTypePresent;
        self.transitioningDelegate = self;
        
        self.view.backgroundColor = [UIColor blackColor ];
    }
    return self;
}

#pragma mark -- Help Methods

- (void)startVideoPlayer{
    
    [self removeObserverAndNotification];
    
    //创建播放器
    _contentURL = [_contentURL stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    _currentPlayerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:_contentURL]];
    self.avPlayer = [AVPlayer playerWithPlayerItem:_currentPlayerItem];
    
    [self addNotification];
    [self addObserverForAVPlayer];
    
    //创建显示器
    [self createDisplay];
    
    [self setupUI];
    
    [self.avPlayer play];
    
}

//添加通知
- (void)addNotification{
    
    //监测屏幕旋转
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    
    //添加AVPlayerItem播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    
    //添加AVPlayerItem开始缓冲通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bufferStart:) name:AVPlayerItemPlaybackStalledNotification object:self.avPlayer.currentItem];
    
    
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

//KOV监控 播放器进度更新
- (void)addObserverForAVPlayer
{
    
    // 给AVPlayer添加观察者 必须实现 - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context；
    
    //监控播放速率
    [self.avPlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    //监控状态属性(AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态)
    [self.avPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    //监控网络加载缓冲情况属性
    [_currentPlayerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监控是否可播放
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    
    //播放进度观察者  //设置每0.1秒执行一次
    __weak typeof(self) weakSelf = self;
    _playerTimeObserver =  [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 10.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        if (weakSelf.dragSlider) {
            return ;
        }
        
        CGFloat current = CMTimeGetSeconds(time);
        weakSelf.current = current;
        CMTime totalTime = weakSelf.avPlayer.currentItem.duration;
        CGFloat total = CMTimeGetSeconds(totalTime);
        weakSelf.total = total;
        weakSelf.slider.value = current/total;
        weakSelf.currentTimeLabel.text = [weakSelf timeFormatted:current];
        weakSelf.totalTimeLabel.text = [NSString stringWithFormat:@"/%@",[weakSelf timeFormatted:total]] ;
        
    }];
}
//移除KVO监控和观察者
- (void)removeObserverAndNotification{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    
    [self.avPlayer removeObserver:self forKeyPath:@"status"];
    [self.avPlayer removeObserver:self forKeyPath:@"rate"];
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [self.avPlayer removeTimeObserver:_playerTimeObserver];
    _playerTimeObserver = nil;
    
}

- (NSString *)timeFormatted:(int)Seconds
{
    int seconds = Seconds % 60;
    int minutes = (Seconds / 60) % 60;
    //int hours = Seconds / 3600;
    if (seconds < 0 || seconds < 0) {
        return @"00:00";
    }
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}
//通过KVO监控回调
//keyPath 监控属性 object 监视器 change 状态改变 context 上下文
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        
        //监控网络加载情况属性
        NSArray *array = self.avPlayer.currentItem.loadedTimeRanges;
        //本次缓冲时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        CGFloat startSeconds = CMTimeGetSeconds(timeRange.start);
        CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
        //现有缓冲总长度
        CGFloat totalBuffer = startSeconds + durationSeconds;
        //视频总时长
        CMTime totalTime = self.avPlayer.currentItem.duration;
        CGFloat total = CMTimeGetSeconds(totalTime);
        if (totalBuffer/total <= 1.0 ) {
            [self.progressView setProgress:totalBuffer/total animated:YES];
        }
        
    }else if([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        
        if (self.avPlayer.currentItem.playbackLikelyToKeepUp == YES) {
            
            if (_activityView != nil) {
                [self.activityView startAnimating];
                [self.activityView removeFromSuperview];
                //_activityView = nil;
                self.slider.userInteractionEnabled = YES;
            }
        }
    }else if ([keyPath isEqualToString:@"status"]){
        
        //监控状态属性
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        
        switch ((status)) {
            case AVPlayerStatusReadyToPlay:
                if (_activityView != nil) {
                    [self.activityView startAnimating];
                    [self.activityView removeFromSuperview];
                    //_activityView = nil;
                    self.slider.userInteractionEnabled = YES;
                }
                break;
            case AVPlayerStatusUnknown:
                self.slider.userInteractionEnabled = NO;
                [self.displayView addSubview:self.activityView];
                break;
            case AVPlayerStatusFailed:
                self.slider.userInteractionEnabled = NO;
                [self.displayView addSubview:self.activityView];
                break;
                
        }
    }else if ([keyPath isEqualToString:@"rate"]){
        if (self.avPlayer.rate == 1) {
        }
    }
    
}

//app退到后台
- (void)appWillEnterBackground{
    
    [self.avPlayer pause];
    
    if (self.playBtn.selected ) {
        [self.playBtn setImage: [UIImage imageNamed:@"videoContinueBtn"] forState:UIControlStateNormal];
        
    }else{
        [self.playBtn setImage:[UIImage imageNamed:@"videoStopButton"] forState:UIControlStateNormal];
    }
    
}

//app进入前台
- (void)appWillEnterPlayGround{
    
    if (self.playBtn.selected ) {
        [self.avPlayer pause];
    }else{
        [self.avPlayer play];
    }
    
}

- (void)createDisplay{
    
    // 显示图像的
    _videoLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    
    //锚点的坐标
    _videoLayer.position = CGPointMake(KPLAYVIEWWIDTH/2, KPLAYVIEWHEIGHT/2);
    _videoLayer.bounds = CGRectMake(0, 0, KPLAYVIEWWIDTH, KPLAYVIEWHEIGHT);
    // 锚点，值只能是0,1之间
    _videoLayer.anchorPoint = CGPointMake(0.5, 0.5);
    
    //     AVLayerVideoGravityResizeAspect 按比例压缩，视频不会超出Layer的范围（默认）
    //     AVLayerVideoGravityResizeAspectFill 按比例填充Layer，不会有黑边
    //     AVLayerVideoGravityResize 填充整个Layer，视频会变形
    //     视频内容拉伸的选项
    _videoLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    //Layer只能添加到Layer上面
    [self.displayView.layer addSublayer:_videoLayer];
    
}

- (void)setupUI{
    
    [self.view addSubview:self.displayView];
    
    [self.displayView addSubview:self.topBar];
    [self.displayView addSubview:self.footBar];
    
    [self.topBar addSubview:self.closeBtn];
    
    [self.footBar addSubview:self.playBtn];
    [self.footBar addSubview:self.fullBtn];
    [self.footBar addSubview:self.currentTimeLabel];
    [self.footBar addSubview:self.totalTimeLabel];
    [self.footBar addSubview:self.progressView];
    [self.footBar addSubview:self.slider];
    
    [self.displayView addSubview:self.activityView];
    
    //音量
    MPVolumeView *mpVolumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(50,50,40,40)];
    for (UIView *view in [mpVolumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeSlider = (UISlider*)view;
            break;
        }
    }
    [mpVolumeView setHidden:YES];
    [mpVolumeView setShowsVolumeSlider:YES];
    [mpVolumeView sizeToFit];
    
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizer:)];
    [self.displayView addGestureRecognizer:pan];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizer:)];
    [self.displayView addGestureRecognizer:tap];
    
}

- (void)updateFrame:(NSInteger)isOrNotFull{
    
    if (isOrNotFull == GOVCrossScreen) {
        
        self.displayView.frame = CGRectMake(0,0,KScreenHeight,KScreenWidth);
        _topBar.frame = CGRectMake(0, 10 , KScreenHeight, 45);
        _footBar.frame = CGRectMake(0, KScreenHeight - 45, KScreenWidth, 45);
        _fullBtn.frame = CGRectMake(KPLAYVIEWHEIGHT - 30 - 15, 7.5, 30, 30);
        _activityView.center = CGPointMake(KScreenWidth/2, KScreenHeight/2);
        
    }else if(isOrNotFull == GOVVerticalScreen){
        
        self.displayView.frame = CGRectMake(0,0,KScreenWidth,KScreenHeight);
        _topBar.frame = CGRectMake(0, 10 , KScreenWidth, 45);
        _footBar.frame = CGRectMake(0, KScreenHeight - 45, KScreenWidth, 45);
        _fullBtn.frame = CGRectMake(KPLAYVIEWWIDTH- 30 - 15, 7.5, 30, 30);
        _activityView.center = CGPointMake(KScreenWidth/2, KScreenHeight/2);
        
    } else{
        
        self.view.frame = _initFrame;
        _displayView.frame = CGRectMake(0,0,KPLAYVIEWWIDTH,KPLAYVIEWHEIGHT);
        _topBar.frame = CGRectMake(0, 0 , KPLAYVIEWWIDTH, 45);
        _footBar.frame = CGRectMake(0, KPLAYVIEWHEIGHT - 45, KPLAYVIEWWIDTH, 45);
        _fullBtn.frame = CGRectMake(KPLAYVIEWWIDTH - 30 - 15, 7.5, 30, 30);
        _activityView.center = CGPointMake(KPLAYVIEWWIDTH/2, KPLAYVIEWHEIGHT/2);
        
    }
    
    _videoLayer.frame = self.displayView.bounds;
    _playBtn.frame = CGRectMake(15, 7.5, 30, 30);
    _totalTimeLabel.frame = CGRectMake(self.fullBtn.frame.origin.x - 5 - 50, self.fullBtn.frame.origin.y, 50, 30);
    _currentTimeLabel.frame = CGRectMake(self.totalTimeLabel.frame.origin.x - 50,self.playBtn.frame.origin.y,50,30);
    if (iPhone6Plus || iPhone6PlusScale) {
        _progressView.frame = CGRectMake(self.playBtn.frame.origin.x + 30 + 5 ,45/2.0f - 0.3,self.currentTimeLabel.frame.origin.x - self.playBtn.frame.origin.x - 30 - 5,0.1);
    }else{
        _progressView.frame = CGRectMake(self.playBtn.frame.origin.x + 30 + 5 ,45/2,self.currentTimeLabel.frame.origin.x - self.playBtn.frame.origin.x - 30 - 5,0.1);
    }
    _slider.frame = CGRectMake(self.progressView.frame.origin.x - 2.5,0.2,self.progressView.frame.size.width + 3,45);
    
}

- (void)videoPlayerStraightFullPlay:(BOOL)straightFull withIsCrossScreen:(BOOL)isCrossScreen{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GOVStatusBarColorNotification object:self userInfo:@{@"isVideoFull" : @(YES)}];
    //刷新状态栏状态
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.isCrossScreen = isCrossScreen;
    
    if (straightFull) {
        
        if (self.isCrossScreen) {
            
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
            
            self.view.frame = CGRectMake(0,0,KScreenHeight,KScreenWidth);
            self.displayView.center = CGPointMake(KScreenHeight/2, KScreenWidth/2);
            
            [UIView animateWithDuration:0.2 animations:^{
                self.displayView.transform = CGAffineTransformMakeRotation(M_PI_2);
            }completion:^(BOOL finished) {
                [self updateFrame:GOVCrossScreen];
            }];
            self.screenState = GOVCrossScreen;
            
        } else {
            
            [UIView animateWithDuration:0.2 animations:^{
                self.displayView.transform = CGAffineTransformMakeRotation(0);
            }completion:^(BOOL finished) {
                [self updateFrame:GOVVerticalScreen];
            }];
            self.screenState = GOVVerticalScreen;
            
        }
        _isFull = 1;
        [self.fullBtn setImage:[UIImage imageNamed:@"videoZoomOut"] forState:UIControlStateNormal];
        
    }
    
    if (self.superView == nil || self.presentVC == nil) {
        self.presentVC = nil;
        self.superView = nil;
    }
    NSLog(@"self.presentViewController %@",self.presentVC);
    [self.presentVC  presentViewController:self animated:NO completion:^{
        
    }];
    
}

- (void)replaceCurrentItemWithUrl:(NSString *)url{
    
    //移除之前Playeritem的观察者
    [self.avPlayer.currentItem  removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.avPlayer.currentItem  removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    
    _current = 00;
    _total = 00;
    _slider.value = 0;
    _currentTimeLabel.text = @"00:00";
    _totalTimeLabel.text = @"/00:00";
    
    
    _contentURL =  [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    _currentPlayerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:_contentURL]];
    
    [self.avPlayer replaceCurrentItemWithPlayerItem:_currentPlayerItem];
    [self.avPlayer play];
    [self.playBtn setImage: [UIImage imageNamed:@"videoStopButton"] forState:UIControlStateNormal];
    self.playBtn.selected = 0;
    [self bufferStart:nil];
    
    //添加AVPlayerItem播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    
    //添加AVPlayerItem开始缓冲通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bufferStart:) name:AVPlayerItemPlaybackStalledNotification object:self.avPlayer.currentItem];
    
    //监控网络加载缓冲情况属性
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
}

#pragma mark -- Events Handle

//播放完成
- (void)playFinished:(NSNotification *)notification{
    
    //    [[NSNotificationCenter defaultCenter] postNotificationName:GOVStatusBarColorNotification object:self userInfo:@{@"isVideoFull" : @(NO)}];
    //    [[NSNotificationCenter defaultCenter] postNotificationName:GOVStatusBarHiddenNotification object:self userInfo:@{@"hidden" : @(NO)}];
    //    //刷新状态栏状态
    //    [self setNeedsStatusBarAppearanceUpdate];
    
    //    if (!self.screenState) {
    //        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
    //    }
    
    
    [self.playBtn setImage: [UIImage imageNamed:@"videoContinueBtn"] forState:UIControlStateNormal];
    self.playBtn.selected = 1;
    
    if(self.playFinishedBlock){
        self.playFinishedBlock();
    } else if ([_delegate respondsToSelector:@selector(videoPlayerPlayFinished:)]){
        [_delegate videoPlayerPlayFinished:self];
    }
    
}

//缓冲开始回调
- (void)bufferStart:(NSNotification *)notification{
    
    [self.displayView addSubview:self.activityView];
    
}

//根据设备方向旋转屏幕
- (void)orientationChange:(NSNotification *)notification{
    
    if (_isClose) {
        return;
    }
    
    UIDeviceOrientation  orientation = [UIDevice currentDevice].orientation;
    
    switch (orientation) {
        case UIDeviceOrientationUnknown:
            break;
        case UIDeviceOrientationPortrait:
            [self autoDeviceOrientation:UIDeviceOrientationPortrait];
            break;
        case UIDeviceOrientationLandscapeLeft:
            [self autoDeviceOrientation:UIDeviceOrientationLandscapeLeft];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            
            break;
        case UIDeviceOrientationLandscapeRight:
            [self autoDeviceOrientation:UIDeviceOrientationLandscapeRight];
            break;
    }
    
}

- (void)autoDeviceOrientation:(UIDeviceOrientation)orientation{
    
    if (orientation == UIDeviceOrientationPortrait) {
        
        if (self.straightFull) {
            
            if (self.isCrossScreen) {
                
                [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
                
                self.view.frame = CGRectMake(0,0,KScreenHeight,KScreenWidth);
                self.displayView.center = CGPointMake(KScreenHeight/2, KScreenWidth/2);
                
                [UIView animateWithDuration:0.2 animations:^{
                    self.displayView.transform = CGAffineTransformMakeRotation(M_PI_2);
                    [self updateFrame:GOVCrossScreen];
                }completion:^(BOOL finished) {
                    
                }];
                self.screenState = GOVCrossScreen;
            }else{
                self.view.frame = CGRectMake(0,0,KScreenWidth,KScreenHeight);
                self.displayView.center = CGPointMake(KScreenWidth/2, KScreenHeight/2);
                [UIView animateWithDuration:0.2 animations:^{
                    self.displayView.transform = CGAffineTransformMakeRotation(0);
                    [self updateFrame:GOVVerticalScreen];
                }completion:^(BOOL finished) {
                }];
                self.screenState = GOVVerticalScreen;
            }
            
            [self.fullBtn setImage: [UIImage imageNamed:@"videoZoomOut"] forState:UIControlStateNormal];
            _isFull = 1;
            
        }else{
            if (!_isFull) {
                return;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:GOVStatusBarHiddenNotification object:self userInfo:@{@"isHidden" : @(NO)}];
            //刷新状态栏状态
            [self setNeedsStatusBarAppearanceUpdate];
            
            //非全屏
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
            [UIView animateWithDuration:0.2 animations:^{
                self.displayView.transform = CGAffineTransformIdentity;
                [self updateFrame:GOVSmallScreen];
            }completion:^(BOOL finished) {
            }];
            self.screenState = GOVSmallScreen;
            [self.fullBtn setImage: [UIImage imageNamed:@"videoZoomIn"]
                          forState:UIControlStateNormal];
            
            _isFull = 0;
        }
        
    }else if(orientation == UIDeviceOrientationLandscapeLeft){
        
        if (_isFull) {
            return;
        }
        
        if (!_isShowBar) {
            [self tapGestureRecognizer:nil];
        }
        
        if (self.isCrossScreen) {
            
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
            
            self.view.frame = CGRectMake(0,0,KScreenHeight,KScreenWidth);
            self.displayView.center = CGPointMake(KScreenHeight/2, KScreenWidth/2);
            
            [UIView animateWithDuration:0.2 animations:^{
                self.displayView.transform = CGAffineTransformMakeRotation(M_PI_2);
                [self updateFrame:GOVCrossScreen];
            }completion:^(BOOL finished) {
                
            }];
            self.screenState = GOVCrossScreen;
        }else{
            
            self.view.frame = CGRectMake(0,0,KScreenWidth,KScreenHeight);
            self.displayView.center = CGPointMake(KScreenWidth/2, KScreenHeight/2);
            
            [UIView animateWithDuration:0.2 animations:^{
                self.displayView.transform = CGAffineTransformMakeRotation(0);
                [self updateFrame:GOVVerticalScreen];
            }completion:^(BOOL finished) {
                
            }];
            self.screenState = GOVVerticalScreen;
        }
        
        [self.fullBtn setImage:  [UIImage imageNamed:@"videoZoomOut"] forState:UIControlStateNormal];
        
        _isFull = 1;
        
    }else if(orientation == UIDeviceOrientationLandscapeRight){
        
        if (_isFull) {
            return;
        }
        
        if (!_isShowBar) {
            [self tapGestureRecognizer:nil];
        }
        
        if (self.isCrossScreen) {
            
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft];
            
            self.view.frame = CGRectMake(0,0,KScreenHeight,KScreenWidth);
            self.displayView.center = CGPointMake(KScreenHeight/2, KScreenWidth/2);
            
            [UIView animateWithDuration:0.2 animations:^{
                self.displayView.transform = CGAffineTransformMakeRotation(-M_PI_2);
                [self updateFrame:GOVCrossScreen];
            }completion:^(BOOL finished) {
                
            }];
            self.screenState = GOVCrossScreen;
        }else{
            
            self.view.frame = CGRectMake(0,0,KScreenWidth,KScreenHeight);
            self.displayView.center = CGPointMake(KScreenWidth/2, KScreenHeight/2);
            [UIView animateWithDuration:0.2 animations:^{
                self.displayView.transform = CGAffineTransformMakeRotation(0);
                [self updateFrame:GOVVerticalScreen];
            }completion:^(BOOL finished) {
                
            }];
            self.screenState = GOVVerticalScreen;
        }
        [self.fullBtn setImage: [UIImage imageNamed:@"videoZoomOut"] forState:UIControlStateNormal];
        _isFull = 1;
        
    }else{
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GOVStatusBarColorNotification object:self userInfo:@{@"isVideoFull" : @(_isFull)}];
    //刷新状态栏状态
    [self setNeedsStatusBarAppearanceUpdate];
    
    if (self.superView == nil || self.presentVC == nil) {
        self.presentVC = nil;
        self.superView = nil;
    }
    
    if (self.screenState == GOVSmallScreen) {
        [self dismissViewControllerAnimated:YES completion:^{
            [self.superView addSubview:self.view];
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
        }];
    }else{
        NSLog(@"self.presentViewController %@",self.presentVC);
        [self.presentVC  presentViewController:self animated:NO completion:nil];
    }
    
    
    if (self.fullScreenBlock) {
        self.fullScreenBlock(_isFull);
    } else if ([_delegate respondsToSelector:@selector(videoPlayerFullScreen:withIsFull:)]) {
        [_delegate videoPlayerFullScreen:self withIsFull:_isFull];
    }
    
}

- (void)playBtnClicked:(UIButton *)btn{
    
    if (btn.selected == 0) {
        
        [btn setImage:[UIImage imageNamed:@"videoContinueBtn"] forState:UIControlStateNormal];
        btn.selected = 1;
        [self.avPlayer pause];
        
    }else{
        
        if (self.current == self.total) {
            [self.avPlayer seekToTime: CMTimeMake(0,1) completionHandler:^(BOOL finished) {
            }];
        }
        
        [btn setImage: [UIImage imageNamed:@"videoStopButton"] forState:UIControlStateNormal];
        btn.selected = 0;
        [self.avPlayer play];
    }
    
}

- (void)coloseBtnClicked:(UIButton *)closeBtn{
    
    if (_isFull) {
        [[NSNotificationCenter defaultCenter] postNotificationName:GOVStatusBarHiddenNotification object:self userInfo:@{@"hidden" : @(NO)}];
        [[NSNotificationCenter defaultCenter] postNotificationName:GOVStatusBarColorNotification object:self userInfo:@{@"isVideoFull" : @(NO)}];
        //刷新状态栏状态
        [self setNeedsStatusBarAppearanceUpdate];
        
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
        
    }else{
        
        [self.view removeFromSuperview];
    }
    
    _isClose = 1;
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
    [self.avPlayer pause];
    [self removeObserverAndNotification];
    self.avPlayer = nil;
    
    if (self.closePLayerBlock) {
        self.closePLayerBlock();
    }else if ([_delegate respondsToSelector:@selector(videoPlayerClosePlayer:)]){
        [_delegate videoPlayerClosePlayer:self];
    }
    
}

- (void)fullBtnClicked:(UIButton *)fullBtn{
    
    if(self.straightFull){
        [self coloseBtnClicked:self.closeBtn];
        return;
    }
    
    if (!_isFull) {
        
        if (self.isCrossScreen) {
            
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
            self.view.frame = CGRectMake(0,0,KScreenHeight,KScreenWidth);
            self.displayView.center = CGPointMake(KScreenHeight/2, KScreenWidth/2);
            
            [UIView animateWithDuration:0.2 animations:^{
                self.displayView.transform = CGAffineTransformMakeRotation(M_PI_2);
                [self updateFrame:GOVCrossScreen];
            }completion:^(BOOL finished) {
                
            }];
            self.screenState = GOVCrossScreen;
        }else{
            
            self.view.frame = CGRectMake(0,0,KScreenWidth,KScreenHeight);
            self.displayView.center = CGPointMake(KScreenWidth/2, KScreenHeight/2);
            
            [UIView animateWithDuration:0.2 animations:^{
                self.displayView.transform = CGAffineTransformMakeRotation(0);
                [self updateFrame:GOVVerticalScreen];
            }completion:^(BOOL finished) {
            }];
            self.screenState = GOVVerticalScreen;
        }
        
        _isFull = 1;
        [fullBtn setImage:[UIImage imageNamed:@"videoZoomOut"] forState:UIControlStateNormal];
        
    }else{
        
        [[NSNotificationCenter defaultCenter] postNotificationName:GOVStatusBarHiddenNotification object:self userInfo:@{@"isHidden" : @(NO)}];
        
        //非全屏
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
        
        self.view.frame = _initFrame;
        
        if (self.screenState == GOVVerticalScreen) {
            [self updateFrame:GOVSmallScreen];
        }else{
            [UIView animateWithDuration:0.2 animations:^{
                self.displayView.transform = CGAffineTransformIdentity;
                [self updateFrame:GOVSmallScreen];
            }completion:^(BOOL finished) {
//                                [self dismissViewControllerAnimated:YES completion:^{
//                                    [self.superView addSubview:self.view];
//                                    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
//                                }];
                
            }];
        }
        self.screenState = GOVSmallScreen;
        _isFull = 0;
        [fullBtn setImage: [UIImage imageNamed:@"videoZoomIn"] forState:UIControlStateNormal];
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GOVStatusBarColorNotification object:self userInfo:@{@"isVideoFull" : @(_isFull)}];
    //刷新状态栏状态
    [self setNeedsStatusBarAppearanceUpdate];
    
    
    if (self.superView == nil || self.presentVC == nil) {
        self.presentVC = nil;
        self.superView = nil;
    }
    
    if (self.screenState == GOVSmallScreen) {
        
        [self dismissViewControllerAnimated:YES completion:^{
            [self.superView addSubview:self.view];
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
        }];
        
    }else{
        NSLog(@"self.presentViewController %@",self.presentVC);
        [self.presentVC  presentViewController:self animated:NO completion:nil];
    }
    
    
    if (self.fullScreenBlock) {
        self.fullScreenBlock(_isFull);
    } else if ([_delegate respondsToSelector:@selector(videoPlayerFullScreen:withIsFull:)]) {
        [_delegate videoPlayerFullScreen:self withIsFull:_isFull];
    }
    
}

- (void)sliderChange:(UISlider *)slider{
    
    _dragSlider = YES;
    [self.avPlayer pause];
    
    CMTime totalTime = self.avPlayer.currentItem.duration;
    CGFloat total = CMTimeGetSeconds(totalTime);
    self.currentTimeLabel.text = [self timeFormatted:(slider.value * total)];
    [self.avPlayer seekToTime: CMTimeMake(slider.value * total,1) completionHandler:^(BOOL finished) {
    }];
    
}

- (void)sliderChangeEnd:(UISlider *)slider{
    
    _dragSlider = NO;
    
    [self.avPlayer play];
    [self.playBtn setImage: [UIImage imageNamed:@"videoStopButton"] forState:UIControlStateNormal];
    self.playBtn.selected = 0;
    
}

//拖拽
- (void)panGestureRecognizer:(UIPanGestureRecognizer *)pan{
    
    if (pan.numberOfTouches > 1) {
        return;
    }
    
    CGPoint translationPoint = [pan translationInView:self.displayView];
    [pan setTranslation:CGPointZero inView:self.displayView];
    
    
    CGFloat x = translationPoint.x;
    CGFloat y = translationPoint.y;
    
    //上下调节音量
    if ((x == 0 && fabs(y) >= 5)|| fabs(y)/fabs(x) >= 3) {
        CGFloat ratio = ([[UIDevice currentDevice].model rangeOfString:@"iPad"].location != NSNotFound) ? 20000.0f:13000.0f;
        CGPoint velocity = [pan velocityInView:self.displayView];
        
        CGFloat nowValue = _volumeSlider.value;
        CGFloat changedValue = 1.0f * (nowValue - velocity.y / ratio);
        if(changedValue < 0) {
            changedValue = 0;
        }
        if(changedValue > 1) {
            changedValue = 1;
        }
        
        [_volumeSlider setValue:changedValue animated:YES];
        [_volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
        
    }else
        //左右调节进度
        if ((y == 0 && fabs(x) >= 10)||fabs(x) / fabs(y) >= 6) {
            
            if(self.total == 0){
                return;
            }
            
            _dragSlider = YES;
            
            [self.avPlayer pause];
            self.slider.value = self.slider.value+(x/self.view.bounds.size.width);
            
            if (self.slider.value > 1.0) {
                self.slider.value = 0.99;
            }
            
            self.currentTimeLabel.text = [self timeFormatted:(self.slider.value * self.total)];
            [self.avPlayer seekToTime: CMTimeMake(self.slider.value * self.total,1) completionHandler:^(BOOL finished) {
            }];
        }
    
    if (pan.state == UIGestureRecognizerStateEnded ) {
        _dragSlider = NO;
        [self.avPlayer play];
        [self.playBtn setImage: [UIImage imageNamed:@"videoStopButton"] forState:UIControlStateNormal];
        self.playBtn.selected = 0;
    }
    
}


- (void)tapGestureRecognizer:(UITapGestureRecognizer *)tap{
    
    if(_isShowBar){
        [UIView animateWithDuration:0.8 animations:^{
            self.topBar.hidden = YES;
            self.footBar.hidden = YES;
            self.topBar.alpha = 0;
            self.footBar.alpha = 0;
        }];
        _isShowBar = 0;
    }else{
        [UIView animateWithDuration:0.8 animations:^{
            self.topBar.hidden = NO;
            self.footBar.hidden = NO;
            self.topBar.alpha = 1;
            self.footBar.alpha = 1;
        }];
        _isShowBar = 1;
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GOVStatusBarHiddenNotification object:self userInfo:@{@"hidden" : @((_isFull ? !_isShowBar: NO))}];
    if (self.showBarBlock) {
        self.showBarBlock(_isShowBar,(_isFull ? !_isShowBar: NO));
    }else if ([_delegate respondsToSelector:@selector(videoPlayerShowBar:withIsShowBar:ishiddenStatusBar:)]) {
        //刷新状态栏状态
        
        [_delegate videoPlayerShowBar:self withIsShowBar:_isShowBar ishiddenStatusBar:(_isFull ? !_isShowBar: NO)];
        [self setNeedsStatusBarAppearanceUpdate];
    }
    
    
}

- (void)closeVideoPlayer{
    [self coloseBtnClicked:self.closeBtn];
}

- (void)hiddenBarAndCloseGestureRecognizer{
    
    self.topBar.hidden = YES;
    self.footBar.hidden = YES;
    self.displayView.userInteractionEnabled = NO;
    
}

#pragma mark -- Getter

- (UIView *)displayView{
    
    if (_displayView == nil) {
        _displayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0,KPLAYVIEWWIDTH , KPLAYVIEWHEIGHT)];
        _displayView.backgroundColor = [UIColor blackColor];
        _displayView.userInteractionEnabled = YES;
    }
    return _displayView;
}

- (UIView *)topBar{
    
    if (_topBar == nil) {
        _topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, KPLAYVIEWWIDTH, 45)];
        _topBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    }
    
    return _topBar;
}

- (UIView *)footBar{
    
    if (_footBar == nil) {
        _footBar = [[UIView alloc] initWithFrame:CGRectMake(0, KPLAYVIEWHEIGHT - 45, KPLAYVIEWWIDTH, 45)];
        _footBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    }
    return _footBar;
}

- (UIButton *)playBtn{
    
    if (_playBtn == nil) {
        _playBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 7.5, 30, 30)];
        [_playBtn setImage:[UIImage imageNamed:@"videoStopButton"] forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(playBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (UIButton *)closeBtn{
    
    if (_closeBtn == nil) {
        _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 15, 30, 30)];
        [_closeBtn setImage: [UIImage imageNamed:@"videoCloseButton"] forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(coloseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

- (UIButton *)fullBtn{
    
    if (_fullBtn == nil) {
        
        _fullBtn = [[UIButton alloc] initWithFrame:CGRectMake(KPLAYVIEWWIDTH - 30 - 10, 7.5, 30, 30)];
        [_fullBtn setImage:[UIImage imageNamed:@"videoZoomIn"] forState:UIControlStateNormal];
        [_fullBtn addTarget:self action:@selector(fullBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _fullBtn;
}

- (UILabel *)currentTimeLabel{
    
    if (_currentTimeLabel == nil) {
        
        _currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.totalTimeLabel.frame.origin.x - 50,self.playBtn.frame.origin.y,50,30)];
        _currentTimeLabel.text = @"00.00";
        _currentTimeLabel.textAlignment = NSTextAlignmentRight;
        _currentTimeLabel.font = [UIFont systemFontOfSize:13];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        
    }
    return _currentTimeLabel;
}

- (UILabel *)totalTimeLabel{
    
    if (_totalTimeLabel == nil) {
        _totalTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.fullBtn.frame.origin.x - 5 - 50, self.fullBtn.frame.origin.y, 50, 30)];
        _totalTimeLabel.text = @"/00.00";
        _totalTimeLabel.textAlignment = NSTextAlignmentLeft;
        _totalTimeLabel.font = [UIFont systemFontOfSize:13];
        _totalTimeLabel.textColor = [UIColor whiteColor];
    }
    return _totalTimeLabel;
}

- (UIProgressView *)progressView{
    if (_progressView == nil) {
        
        //缓冲进度条
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        
        if (iPhone6Plus || iPhone6PlusScale) {
            _progressView.frame = CGRectMake(self.playBtn.frame.origin.x + 30 + 5 ,45/2.0f - 0.3,self.currentTimeLabel.frame.origin.x - self.playBtn.frame.origin.x - 30 - 5,0.1);
        }else{
            _progressView.frame = CGRectMake(self.playBtn.frame.origin.x + 30 + 5 ,45/2,self.currentTimeLabel.frame.origin.x - self.playBtn.frame.origin.x - 30 - 5,0.1);
        }
        _progressView.progressTintColor = [UIColor whiteColor];
        _progressView.trackTintColor = [UIColor grayColor];
        _progressView.progress = 0.0;
    }
    return _progressView;
}

- (UISlider *)slider{
    if (_slider == nil) {
        _slider = [[UISlider alloc] initWithFrame:CGRectMake(self.progressView.frame.origin.x - 2.5,0.2,self.progressView.frame.size.width + 3,45)];
        [_slider setThumbImage: [UIImage imageNamed:@"videoSlider"] forState:UIControlStateNormal];
        _slider.value = 0.0;
        _slider.minimumTrackTintColor = [UIColor colorWithRed:0 green:85/255.0f blue:142/255.0f alpha:1.0];
        _slider.maximumTrackTintColor = [UIColor clearColor];
        [_slider addTarget:self action:@selector(sliderChange:) forControlEvents:UIControlEventValueChanged | UIControlEventTouchDown];
        [_slider addTarget:self action:@selector(sliderChangeEnd:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    }
    return _slider;
}

- (UIActivityIndicatorView *)activityView{
    
    if (_activityView == nil) {
        
        _activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 40 , 40)];
        _activityView.center = CGPointMake(KPLAYVIEWWIDTH/2, KPLAYVIEWHEIGHT/2);
        [_activityView startAnimating];
    }
    
    return _activityView;
    
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
    return !_isShowBar;
}
//设置隐藏动画
- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationNone;
}

//是否支持自动转屏
- (BOOL)shouldAutorotate{
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    
    return UIInterfaceOrientationMaskPortrait;
}


//- (void)dealloc{
//    [self removeObserverAndNotification];
//}

#pragma mark -- UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    return _pushAnimation;
}
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    //这里我们初始化dismissType
    _pushAnimation.transitionType = GOVTransitionTypeDissmiss;
    return _pushAnimation;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
