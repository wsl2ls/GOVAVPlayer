//
//  GOVTransitionAnimation.m
//  GOVAVPlayer
//
//  Created by 王双龙 on 2017/8/4.
//  Copyright © 2017年 王双龙. All rights reserved.
//

#import "GOVTransitionAnimation.h"

@interface GOVTransitionAnimation () 

@end

@implementation GOVTransitionAnimation



//返回动画事件
- (NSTimeInterval)transitionDuration:(nullable id <UIViewControllerContextTransitioning>)transitionContext{
    
    return 1.0;
    
}


//所有的过渡动画事务都在这个方法里面完成
- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext{
    
    
    switch (_transitionType) {
        case GOVTransitionTypePresent:
            [self presentAnimation:transitionContext];
            break;
        case GOVTransitionTypeDissmiss:
            [self dismissAnimation:transitionContext];
            break;
        case GOVTransitionTypePush:
            [self pushAnimation:transitionContext];
            break;
        case GOVransitionTypePop:
            [self popAnimation:transitionContext];
            break;
    }
    
}

- (void)presentAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    
//    //通过viewControllerForKey取出转场前后的两个控制器，这里toVC就是vc1、fromVC就是vc2
//    UIViewController * toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
//    UIViewController * fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
//    //缩小动画，这里没有使用3D动画，不知怎的，使用3D动画有点卡顿
//    CGAffineTransform transform = CGAffineTransformMakeScale(0.9, 0.9);
//    CGRect scBound = [UIScreen mainScreen].bounds;
//    //获取的过度动画持续的时间
//    NSTimeInterval duration = [self transitionDuration:transitionContext];
//    //这里有个重要的概念containerView，如果要对视图做转场动画，视图就必须要加入containerView中才能进行，可以理解containerView管理着所有做转场动画的视图
//    UIView * tempView = [transitionContext containerView];
//    //将需要跳转的VC的视图添加到tempView
//    [tempView addSubview:toVC.view];
//    toVC.view.frame = CGRectMake(scBound.size.width, scBound.origin.y, scBound.size.width, scBound.size.height);
//    //动画
//    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//        [fromVC.view setTransform:transform];
//        fromVC.view.frame = CGRectMake(-50, fromVC.view.frame.origin.y, fromVC.view.frame.size.width, fromVC.view.frame.size.height);
//        toVC.view.frame = scBound;
//    } completion:^(BOOL finished) {
//        //转场执行完成
//        [transitionContext completeTransition:YES];
//    }];
    
      [transitionContext completeTransition:YES];
    
}

- (void)dismissAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    
//    //通过viewControllerForKey取出转场前后的两个控制器，这里toVC就是vc1、fromVC就是vc2
//    UIViewController * toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
//    UIViewController * fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
//    
//    CGAffineTransform transform = CGAffineTransformMakeScale(1.0, 1.0);
//    CGRect scBound = [UIScreen mainScreen].bounds;
//    //获取的过度动画持续的时间
//    NSTimeInterval duration = [self transitionDuration:transitionContext];
//    //这里有个重要的概念containerView，如果要对视图做转场动画，视图就必须要加入containerView中才能进行，可以理解containerView管理着所有做转场动画的视图
//    UIView * tempView = [transitionContext containerView];
//    [tempView addSubview:toVC.view];
//    [tempView bringSubviewToFront:fromVC.view];
//    //动画
//    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//        [toVC.view setTransform:transform];
//        toVC.view.frame = CGRectMake(0, fromVC.view.frame.origin.y, fromVC.view.frame.size.width, fromVC.view.frame.size.height);
//        fromVC.view.frame = CGRectMake(scBound.size.width, scBound.origin.y, scBound.size.width, scBound.size.height);
//    } completion:^(BOOL finished) {
//        [transitionContext completeTransition:YES];
//    }];
//
    
    [transitionContext completeTransition:YES];
}

- (void)pushAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{

//    //获取需要转场的当前控制器，这里强转为CollectionViewController，因为需要知道当前点击的cell位置
//    CollectionViewController * collectionVC = (CollectionViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
//    //获取push的控制器
//    PushViewController * pushVC = (PushViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
//    //获取点击的cell
//    HomeCollectionViewCell * cell = (HomeCollectionViewCell *)[collectionVC.collectionView cellForItemAtIndexPath:collectionVC.currentIndexPath];
//    //截取cell的imageView
//    UIView * tempView = [cell.imageView snapshotViewAfterScreenUpdates:NO];
//    UIView * containerView = [transitionContext containerView];
//    //将截取的视图的frame设置为cell的imageView的位置（如果不设置动画会变的不那么流畅，有点突兀）
//    tempView.frame = [cell.imageView convertRect:cell.imageView.frame toView:containerView];
//    pushVC.view.alpha = 0;
//    [containerView addSubview:pushVC.view];
//    [containerView addSubview:tempView];
//    NSTimeInterval duration = [self transitionDuration:transitionContext];
//    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.9 options:UIViewAnimationOptionCurveEaseIn animations:^{
//        tempView.frame = CGRectMake(0, 64, containerView.frame.size.width, containerView.frame.size.width);
//        pushVC.view.alpha = 1;
//    } completion:^(BOOL finished) {
//        //动画完成后就隐藏截取的视图
//        tempView.hidden = YES;
//        //将push页面的imageView的图片设置为cell的image的图片
//        pushVC.ImageView.image = cell.imageView.image;
//        [transitionContext completeTransition:YES];
//    }];
    
      [transitionContext completeTransition:YES];
}

- (void)popAnimation:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    
//    CollectionViewController * collectionVC = (CollectionViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
//    PushViewController * pushVC = (PushViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
//    HomeCollectionViewCell * cell = (HomeCollectionViewCell *)[collectionVC.collectionView cellForItemAtIndexPath:collectionVC.currentIndexPath];
//    UIView * containerView = [transitionContext containerView];
//    UIView * tempView = [pushVC.ImageView snapshotViewAfterScreenUpdates:NO];
//    tempView.frame = [pushVC.ImageView convertRect:pushVC.ImageView.bounds toView:containerView];
//    [containerView addSubview:collectionVC.view];
//    [containerView addSubview:pushVC.view];
//    [containerView addSubview:tempView];
//    NSTimeInterval duration = [self transitionDuration:transitionContext];
//    [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.9 options:UIViewAnimationOptionCurveEaseIn animations:^{
//        tempView.frame = [cell.imageView convertRect:cell.imageView.frame toView:containerView];
//        pushVC.view.alpha = 0;
//    } completion:^(BOOL finished) {
//        [transitionContext completeTransition:YES];
//        [tempView removeFromSuperview];
//    }];
    
      [transitionContext completeTransition:YES];

}



@end
