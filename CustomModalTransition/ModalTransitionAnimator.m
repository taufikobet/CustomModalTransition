//
//  ModalTransitionAnimator.m
//  CustomModalTransition
//
//  Created by pronebird on 29/05/14.
//  Copyright (c) 2014 codeispoetry.ru. All rights reserved.
//

#import "ModalTransitionAnimator.h"

static CGFloat kModalScreenOffset = 40.0f;

@implementation ModalTransitionAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.4;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController* destination = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    if([destination isBeingPresented]) {
        [self animatePresentation:transitionContext];
    } else {
        [self animateDismissal:transitionContext];
    }
}

//
// Calculate a final frame for presenting controller according to interface orientation
// Presenting controller should always slide down and its top should coincide with the bottom of screen
//
- (CGRect)presentingControllerFrameWithContext:(id<UIViewControllerContextTransitioning>)transitionContext {
    CGRect frame = transitionContext.containerView.bounds;

    if(floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) // iOS 8+
    {
        //
        // On iOS 8, UIKit handles rotation using transform matrix
        // Therefore we should always return a frame for portrait mode
        //
        CGRect rect = CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame));
        NSLog(@"transition context frame: %@", NSStringFromCGRect(rect));
        return rect;
    }
    else
    {
        //
        // On iOS 7, UIKit does not handle rotation
        // To make sure our view is moving in the right direction (always down) we should
        // fix the frame accoding to interface orientation.
        //
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

        switch (orientation) {
            case UIInterfaceOrientationLandscapeLeft:
                return CGRectMake(CGRectGetWidth(frame), 0, CGRectGetWidth(frame), CGRectGetHeight(frame));
                break;
            case UIInterfaceOrientationLandscapeRight:
                return CGRectMake(-CGRectGetWidth(frame), 0, CGRectGetWidth(frame), CGRectGetHeight(frame));
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                return CGRectMake(0, -CGRectGetHeight(frame), CGRectGetWidth(frame), CGRectGetHeight(frame));
                break;
            default:
            case UIInterfaceOrientationPortrait:
                return CGRectMake(0, CGRectGetHeight(frame), CGRectGetWidth(frame), CGRectGetHeight(frame));
                break;
        }
    }
}

- (void)animatePresentation:(id<UIViewControllerContextTransitioning>)transitionContext
{
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    UIViewController* source = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController* destination = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView* container = transitionContext.containerView;

    // Orientation bug fix
    // See: http://stackoverflow.com/a/20061872/351305
    destination.view.frame = container.bounds;
    CGRect destinationFrame = CGRectMake(container.bounds.origin.x, CGRectGetHeight(container.bounds), container.bounds.size.width, container.bounds.size.height);

    destination.view.frame = destinationFrame;
    source.view.frame = container.bounds;

    // Place container view before source view
    //[container.superview sendSubviewToBack:container];

    // Add destination view to container
    [container addSubview:destination.view];

    // Start appearance transition for source controller
    // Because UIKit does not do this automatically
    [source beginAppearanceTransition:NO animated:YES];

    // Animate
    [UIView animateKeyframesWithDuration:transitionDuration delay:0.0
                                 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
                                     [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
                                         CGRect targetFrame = [self presentingControllerFrameWithContext:transitionContext];
                                         destination.view.frame = CGRectMake(0, 0 + kModalScreenOffset, targetFrame.size.width, targetFrame.size.height);
                                     }];
                                     [UIView addKeyframeWithRelativeStartTime:0.2 relativeDuration:0.8 animations:^{

                                         source.view.alpha = 0.5f;

                                         CATransform3D perspectiveTransform = source.view.layer.transform;
                                         perspectiveTransform.m34 = 1.0 / -1000.0;
                                         perspectiveTransform = CATransform3DTranslate(perspectiveTransform, 0, 0, -100);
                                         source.view.layer.transform = perspectiveTransform;
                                     }];
                                 } completion:^(BOOL finished) {
                                     // End appearance transition for source controller

                                     [source endAppearanceTransition];

                                     // Finish transition
                                     [transitionContext completeTransition:YES];
                                 }];
}

- (void)animateDismissal:(id<UIViewControllerContextTransitioning>)transitionContext
{
    NSTimeInterval transitionDuration = [self transitionDuration:transitionContext];
    UIViewController *source = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *destination = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *container = transitionContext.containerView;

    // Orientation bug fix
    // See: http://stackoverflow.com/a/20061872/351305
    destination.view.frame = container.bounds;
    source.view.frame = CGRectMake(0, kModalScreenOffset, container.bounds.size.width, container.bounds.size.height);
    // Move destination view below source view
    destination.view.frame = [self presentingControllerFrameWithContext:transitionContext];

    // Start appearance transition for destination controller
    // Because UIKit does not do this automatically
    [destination beginAppearanceTransition:YES animated:YES];
    // Animate
    [UIView animateKeyframesWithDuration:transitionDuration delay:0.0
                                 options:UIViewKeyframeAnimationOptionCalculationModeCubic animations:^{
                                     [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
                                         //destination.view.frame = container.bounds;
                                     }];
                                     [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:1.0 animations:^{
                                         // Important: original transform3d is different from CATransform3DIdentity
                                         destination.view.alpha = 1.0f;
                                         destination.view.layer.transform = CATransform3DIdentity;
                                         source.view.frame = CGRectMake(0, container.bounds.size.height, container.bounds.size.width, container.bounds.size.height);
                                     }];
                                 } completion:^(BOOL finished) {
                                     // End appearance transition for destination controller
                                     [destination endAppearanceTransition];

                                     // Finish transition
                                     [transitionContext completeTransition:YES];
                                 }];
}

@end
