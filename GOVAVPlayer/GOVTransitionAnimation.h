//
//  GOVTransitionAnimation.h
//  GOVAVPlayer
//
//  Created by 王双龙 on 2017/8/4.
//  Copyright © 2017年 王双龙. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GOVTransitionAnimation : NSObject <UIViewControllerAnimatedTransitioning>

typedef NS_ENUM(NSUInteger, GOVTransitionType) {
    GOVTransitionTypePresent = 0,//管理present动画
    GOVTransitionTypeDissmiss,
    GOVTransitionTypePush,
    GOVransitionTypePop,
};

@property (nonatomic,assign)GOVTransitionType transitionType;

@end
