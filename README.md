
GOVVideoPlayer/GOVVideoController是一个基于AVPlayer封装的视频播放器，支持播放/暂停、左右退拽快进、上下滑动调节音量、有缓冲进度指示条、和卡顿指示器，总效果如下：

![11.gif](http://upload-images.jianshu.io/upload_images/1708447-deb207a25b858272.gif?imageMogr2/auto-orient/strip)
主要代码如下：
```
//监测屏幕旋转
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    //添加AVPlayerItem播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    
    //添加AVPlayerItem开始缓冲通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bufferStart:) name:AVPlayerItemPlaybackStalledNotification object:self.avPlayer.currentItem];

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

#pragma mark -- 隐藏/显示状态栏的方法
/*[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];这个方法在iOS9之后弃用了，并且需要
 将View controller-based status bar appearance设置为NO；而下面的重写方法需要将View controller-based status bar appearance设置为YES，这个方法在iOS7之后就有了；
//刷新状态栏状态
 [self setNeedsStatusBarAppearanceUpdate];
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
```
