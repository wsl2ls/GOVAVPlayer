//
//  GOVVideoView.m
//  GOVAVPlayer
//
//  Created by 王双龙 on 17/2/7.
//  Copyright © 2017年 王双龙. All rights reserved.
//

#import "GOVVideoView.h"
#import <MediaPlayer/MediaPlayer.h>

#define KPLAYVIEWWIDTH (self.frame.size.width)
#define KPLAYVIEWHEIGHT (self.frame.size.height)

#define KScreenBounds ([[UIScreen mainScreen] bounds])
#define KScreenWidth (KScreenBounds.size.width)
#define KScreenHeight (KScreenBounds.size.height)

@interface GOVVideoView ()
{
    CGRect _initFrame;
    AVPlayerLayer *_videoLayer;
    UISlider *_volumeSlider;//音量slider
    id _playerTimeObserver; //播放进度观察者
    BOOL _isFull; //是否是全屏
    BOOL _isShowBar;
}

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

@end

@implementation GOVVideoView

//+ (GOVVideoView *)sharedVideoPlayerWithFrame:(CGRect)frame url:(NSString *)url{
//
//    static dispatch_once_t pred = 0;
//    __strong static GOVVideoView *_sharedObject = nil;
//    dispatch_once(&pred, ^{
//        _sharedObject = [[self alloc] init];
//    });
//    return _sharedObject;
//}

- (instancetype)initWithFrame:(CGRect)frame url:(NSString *)url{
    
    if(self == [super initWithFrame:frame]) {
        
        _initFrame = frame;
        _isShowBar = 1;
        
        self.backgroundColor = [UIColor blackColor];
        self.userInteractionEnabled = YES;
        
        //创建播放器
        url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        AVPlayer *player = [AVPlayer playerWithURL:[NSURL URLWithString:url]];
        self.avPlayer = player;
        
        [self addNotification];
        [self addObserverForAVPlayer];
        
        //创建显示器
        [self createDisplay];
        
        [self setupUI];
        
        //[self.avPlayer play];
        
    }
    return self;
}

#pragma mark -- Help Methods

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
    AVPlayerItem *playerItem = self.avPlayer.currentItem;
    
    // 给AVPlayer添加观察者 必须实现 - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context；
    
    //监控播放速率
    [self.avPlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    //监控状态属性(AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态)
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    //监控网络加载缓冲情况属性
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //监控是否可播放
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    
    //播放进度观察者  //设置每0.1秒执行一次
    __weak GOVVideoView *weakSelf = self;
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
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"rate"];
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
                _activityView = nil;
            }
        }
    }else if ([keyPath isEqualToString:@"status"]){
        
        //监控状态属性
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        
        switch ((status)) {
            case AVPlayerStatusReadyToPlay:
                
                break;
            case AVPlayerStatusUnknown:
                
                break;
            case AVPlayerStatusFailed:
                
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
        [self.playBtn setImage:[UIImage imageNamed:@"wslPlay"] forState:UIControlStateNormal];
    }else{
        [self.playBtn setImage:[UIImage imageNamed:@"wslPause"] forState:UIControlStateNormal];
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
    _videoLayer.videoGravity =  AVLayerVideoGravityResizeAspect;
    //    //播放时，视频实际占的区域
    //    NSLog(@"%@", NSStringFromCGRect(videoLayer.videoRect));
    
    //Layer只能添加到Layer上面
    [self.layer addSublayer:_videoLayer];
    
}

- (void)setupUI{
    
    [self addSubview:self.topBar];
    [self addSubview:self.footBar];
    
    [self.topBar addSubview:self.closeBtn];
    
    [self.footBar addSubview:self.playBtn];
    [self.footBar addSubview:self.fullBtn];
    [self.footBar addSubview:self.currentTimeLabel];
    [self.footBar addSubview:self.totalTimeLabel];
    [self.footBar addSubview:self.progressView];
    [self.footBar addSubview:self.slider];
    
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
    [self addGestureRecognizer:pan];
    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizer:)];
    [self addGestureRecognizer:tap];
    
}

- (void)updateFrame:(BOOL)isOrNotFull{
    
    if (isOrNotFull == 1) {
        
        self.frame = CGRectMake(0,0,KScreenHeight,KScreenWidth);
        self.topBar.frame = CGRectMake(0, 0 , KPLAYVIEWHEIGHT, 45);
        self.footBar.frame = CGRectMake(0, KPLAYVIEWWIDTH - 45, KPLAYVIEWHEIGHT, 45);
        _fullBtn.frame = CGRectMake(KPLAYVIEWHEIGHT - 30 - 10, 7.5, 30, 30);
        _activityView.center = CGPointMake(KScreenHeight/2, KScreenWidth/2);
        
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        
    }else{
        
        self.frame = _initFrame;
        self.topBar.frame = CGRectMake(0, 0 , KPLAYVIEWWIDTH, 45);
        self.footBar.frame = CGRectMake(0, KPLAYVIEWHEIGHT - 45, KPLAYVIEWWIDTH, 45);
        _fullBtn.frame = CGRectMake(KPLAYVIEWWIDTH - 30 - 15, 7.5, 30, 30);
        _activityView.center = CGPointMake(KPLAYVIEWWIDTH/2, KPLAYVIEWHEIGHT/2);
        
    }
    
    _videoLayer.frame = self.bounds;
    _playBtn.frame = CGRectMake(15, 7.5, 30, 30);
    _totalTimeLabel.frame = CGRectMake(self.fullBtn.frame.origin.x - 5 - 40, self.fullBtn.frame.origin.y, 40, 30);
    _currentTimeLabel.frame = CGRectMake(self.totalTimeLabel.frame.origin.x - 40,self.playBtn.frame.origin.y,40,30);
    _progressView.frame = CGRectMake(self.playBtn.frame.origin.x + 30 + 5 ,45/2.0f,self.currentTimeLabel.frame.origin.x - 15 - self.currentTimeLabel.frame.size.width,45);
    _slider.frame = CGRectMake(self.progressView.frame.origin.x - 2,0.2,self.progressView.frame.size.width + 3,45);
    
}

#pragma mark -- Events Handle

//播放完成
- (void)playFinished:(NSNotification *)notification{
    
    [self.playBtn setImage:[UIImage imageNamed:@"wslPlay"] forState:UIControlStateNormal];
    self.playBtn.selected = 1;
    
    if(self.playFinishedBlock){
        self.playFinishedBlock();
    } else if ([_delegate respondsToSelector:@selector(videoPlayerPlayFinished:)]){
        [_delegate videoPlayerPlayFinished:self];
    }
    
}

//缓冲开始回调
- (void)bufferStart:(NSNotification *)notification{
    
    [self addSubview:self.activityView];
    
}

//根据设备方向旋转屏幕
- (void)orientationChange:(NSNotification *)notification{
    
    UIDeviceOrientation  orientation = [UIDevice currentDevice].orientation;
    
    switch (orientation) {
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
            
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
            [UIView animateWithDuration:0.2 animations:^{
                self.transform = CGAffineTransformMakeRotation(M_PI_2);
            }completion:^(BOOL finished) {
                [self updateFrame:1];
            }];
            
            [self.fullBtn setImage:[UIImage imageNamed:@"wslZoomOut"] forState:UIControlStateNormal];
            _isFull = 1;
            
            [[UIApplication sharedApplication].keyWindow addSubview:self];
            
        }else{
            //非全屏
            [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
            [UIView animateWithDuration:0.2 animations:^{
                self.transform = CGAffineTransformIdentity;
                [self updateFrame:0];
            }completion:^(BOOL finished) {
                
            }];
            
            [self.fullBtn setImage:[UIImage imageNamed:@"wslZoomIn"] forState:UIControlStateNormal];
            _isFull = 0;
        }
        
    }else if(orientation == UIDeviceOrientationLandscapeLeft){
        
        
        
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
        }completion:^(BOOL finished) {
            [self updateFrame:1];
        }];
        
        [self.fullBtn setImage:[UIImage imageNamed:@"wslZoomOut"] forState:UIControlStateNormal];
        _isFull = 1;
        
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        
    }else if(orientation == UIDeviceOrientationLandscapeRight){
        
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft];
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformMakeRotation(-M_PI_2);
        }completion:^(BOOL finished) {
            [self updateFrame:1];
        }];
        
        [self.fullBtn setImage:[UIImage imageNamed:@"wslZoomOut"] forState:UIControlStateNormal];
        _isFull = 1;
        
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        
    }else{
    }
    
    if (self.fullScreenBlock) {
        self.fullScreenBlock(_isFull);
    } else if ([_delegate respondsToSelector:@selector(videoPlayerFullScreen:withIsFull:)]) {
        [_delegate videoPlayerFullScreen:self withIsFull:_isFull];
    }
    
}

- (void)playBtnClicked:(UIButton *)btn{
    
    if (btn.selected == 0) {
        [btn setImage:[UIImage imageNamed:@"wslPlay"] forState:UIControlStateNormal];
        btn.selected = 1;
        [self.avPlayer pause];
        
    }else{
        
        if (self.current == self.total) {
            [self.avPlayer seekToTime: CMTimeMake(0,1) completionHandler:^(BOOL finished) {
            }];
        }
        
        [btn setImage:[UIImage imageNamed:@"wslPause"] forState:UIControlStateNormal];
        btn.selected = 0;
        [self.avPlayer play];
    }
    
}

- (void)coloseBtnClicked:(UIButton *)closeBtn{
    
    [self.avPlayer pause];
    self.avPlayer = nil;
    
    if (self.closePLayerBlock) {
        self.avPlayer = nil;
        self.closePLayerBlock();
    } else if ([_delegate respondsToSelector:@selector(videoPlayerClosePlayer:)]){
        [_delegate videoPlayerClosePlayer:self];
    }
    
    
}

- (void)fullBtnClicked:(UIButton *)fullBtn{
    
    if (_isFull == 0) {
        
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight];
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
        }completion:^(BOOL finished) {
            [self updateFrame:1];
        }];
        
        [fullBtn setImage:[UIImage imageNamed:@"wslZoomOut"] forState:UIControlStateNormal];
        _isFull = 1;
        
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        
    }else{
        
        //非全屏
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformIdentity;
            [self updateFrame:0];
        }completion:^(BOOL finished) {
            
        }];
        
        [fullBtn setImage:[UIImage imageNamed:@"wslZoomIn"] forState:UIControlStateNormal];
        _isFull = 0;
        
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
    [self.playBtn setImage:[UIImage imageNamed:@"wslPause"] forState:UIControlStateNormal];
    self.playBtn.selected = 1;
    
}

//拖拽
- (void)panGestureRecognizer:(UIPanGestureRecognizer *)pan{
    
    if (pan.numberOfTouches > 1) {
        return;
    }
    
    CGPoint translationPoint = [pan translationInView:self];
    [pan setTranslation:CGPointZero inView:self];
    
    CGFloat x = translationPoint.x;
    CGFloat y = translationPoint.y;
    
    //上下调节音量
    if ((x == 0 && fabs(y) >= 5)|| fabs(y)/fabs(x) >= 3) {
        CGFloat ratio = ([[UIDevice currentDevice].model rangeOfString:@"iPad"].location != NSNotFound) ? 20000.0f:13000.0f;
        CGPoint velocity = [pan velocityInView:self];
        
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
        
    }else {
        
        //左右调节进度
        if ((y == 0 && fabs(x) >= 5)||fabs(x) / fabs(y) >= 3) {
            
            if(self.total == 0){
                return;
            }
            
            _dragSlider = YES;
            
            [self.avPlayer pause];
            self.slider.value = self.slider.value+(x/self.bounds.size.width);
            
            self.currentTimeLabel.text = [self timeFormatted:(self.slider.value * self.total)];
            [self.avPlayer seekToTime: CMTimeMake(self.slider.value * self.total,1) completionHandler:^(BOOL finished) {
            }];
        }
        
        if (pan.state == UIGestureRecognizerStateEnded ) {
            _dragSlider = NO;
            [self.avPlayer play];
            [self.playBtn setImage:[UIImage imageNamed:@"wslPause"] forState:UIControlStateNormal];
            self.playBtn.selected = 0;
        }
    }
    
}


- (void)tapGestureRecognizer:(UITapGestureRecognizer *)tap{
    
    if(_isShowBar){
        self.topBar.hidden = YES;
        self.footBar.hidden = YES;
        _isShowBar = 0;
    }else{
        self.topBar.hidden = NO;
        self.footBar.hidden = NO;
        _isShowBar = 1;
    }
    if (self.showBarBlock) {
        self.showBarBlock(_isShowBar);
    }else if ([_delegate respondsToSelector:@selector(videoPlayerShowBar:withIsShow:)]) {
        [_delegate videoPlayerShowBar:self withIsShow:_isShowBar];
    }
}


#pragma mark -- Getter

- (UIView *)topBar{
    
    if (_topBar == nil) {
        _topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, KPLAYVIEWWIDTH, 40)];
        _topBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    }
    
    return _topBar;
}

- (UIView *)footBar{
    
    if (_footBar == nil) {
        _footBar = [[UIView alloc] initWithFrame:CGRectMake(0, KPLAYVIEWHEIGHT - 40, KPLAYVIEWWIDTH, 40)];
        _footBar.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
    }
    return _footBar;
}

- (UIButton *)playBtn{
    
    if (_playBtn == nil) {
        _playBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 5, 30, 30)];
        [_playBtn setImage:[UIImage imageNamed:@"wslPause"] forState:UIControlStateNormal];
        [_playBtn addTarget:self action:@selector(playBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (UIButton *)closeBtn{
    
    if (_closeBtn == nil) {
        _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 30, 30)];
        [_closeBtn setImage:[UIImage imageNamed:@"closeBtn"] forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(coloseBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

- (UIButton *)fullBtn{
    
    if (_fullBtn == nil) {
        
        _fullBtn = [[UIButton alloc] initWithFrame:CGRectMake(KPLAYVIEWWIDTH - 30 - 10, 5, 30, 30)];
        [_fullBtn setImage:[UIImage imageNamed:@"wslZoomIn"] forState:UIControlStateNormal];
        [_fullBtn addTarget:self action:@selector(fullBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _fullBtn;
}

- (UILabel *)currentTimeLabel{
    
    if (_currentTimeLabel == nil) {
        
        _currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.totalTimeLabel.frame.origin.x - 40,self.playBtn.frame.origin.y,40,30)];
        _currentTimeLabel.text = @"00.00";
        _currentTimeLabel.textAlignment = NSTextAlignmentRight;
        _currentTimeLabel.font = [UIFont systemFontOfSize:13];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        
    }
    return _currentTimeLabel;
}

- (UILabel *)totalTimeLabel{
    
    if (_totalTimeLabel == nil) {
        _totalTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.fullBtn.frame.origin.x - 5 - 40, self.fullBtn.frame.origin.y, 40, 30)];
        _totalTimeLabel.text = @"/00.00";
        _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
        _totalTimeLabel.font = [UIFont systemFontOfSize:13];
        _totalTimeLabel.textColor = [UIColor whiteColor];
    }
    return _totalTimeLabel;
}

- (UIProgressView *)progressView{
    if (_progressView == nil) {
        
        //缓冲进度条
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.frame = CGRectMake(self.playBtn.frame.origin.x + 30 + 5 ,45/2,self.currentTimeLabel.frame.origin.x - 10 - self.currentTimeLabel.frame.size.width,45);
        _progressView.progressTintColor = [UIColor whiteColor];
        _progressView.trackTintColor = [UIColor grayColor];
        _progressView.progress = 0.0;
    }
    return _progressView;
}

- (UISlider *)slider{
    if (_slider == nil) {
        _slider = [[UISlider alloc] initWithFrame:CGRectMake(self.progressView.frame.origin.x - 2,0,self.progressView.frame.size.width + 3,45)];
        [_slider setThumbImage:[UIImage imageNamed:@"wslSlider"] forState:UIControlStateNormal];
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

- (void)dealloc{
    [self removeObserverAndNotification];
}


@end
