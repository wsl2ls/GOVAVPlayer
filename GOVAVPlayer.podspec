
Pod::Spec.new do |s|

  s.name         = "GOVAVPlayer"
  s.version      = "1.0"
  s.summary      = "GOVVideoPlayer/GOVVideoController是一个基于AVPlayer封装的视频播放器，支持播放/暂停、左右退拽快进、上下滑动调节音量、有缓冲进度指示条、和卡顿指示器."
  s.homepage     = "https://github.com/wslcmk/GOVAVPlayer"
  s.license      = { :type => "MIT", :file => 'LICENSE' }
  s.author       = { "PlutoY" => "15324956576@163.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/wslcmk/GOVAVPlayer.git", :tag => s.version}
  s.frameworks   = 'UIKit'
  s.source_files = "GOVAVPlayer/**/GOVVideoPlayer.{h,m}"
  #s.resource     = "GOVVideoPlayer/**/*.{h,m}"
  s.requires_arc = true
 
end
