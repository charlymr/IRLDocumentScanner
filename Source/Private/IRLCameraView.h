//
// IRLCameraView.h
//
//  Modified by Denis Martin on 12/07/2015
//  Based on IPDFCameraViewController: https://github.com/mmackh/IPDFCameraViewController/tree/master/IPDFCameraViewController
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

@import UIKit;
@import AVFoundation;
@import CoreImage;
@import GLKit;

#import "IRLScannerViewController.h"

@protocol IRLCameraViewProtocol;

@interface IRLCameraView : UIView

- (void)setupCameraView;
- (void)start;
- (void)stop;

@property (weak)    id<IRLCameraViewProtocol>  delegate;

@property (nonatomic, readwrite)    NSUInteger      minimumConfidenceForFullDetection;  // Default 66
@property (nonatomic, readonly)     NSUInteger      maximumConfidenceForFullDetection;  // Default 100

@property (readwrite, strong, nonatomic)   UIColor *overlayColor;

- (UIImage*)latestCorrectedUIImage;

@property (nonatomic,assign,    getter=isBorderDetectionEnabled)    BOOL enableBorderDetection;
@property (nonatomic,assign,    getter=isTorchEnabled)              BOOL enableTorch;
@property (nonatomic,readonly,  getter=hasFlash)                    BOOL flash;

@property (nonatomic,assign)    IRLScannerViewType                   cameraViewType;
@property (nonatomic,assign)    IRLScannerDetectorType               detectorType;         // Default IRLScannerDetectorTypeAccuracy

@property (nonatomic,assign,    getter=isDrawCenterEnabled)         BOOL enableDrawCenter;
@property (nonatomic,assign,    getter=isShowAutoFocusEnabled)      BOOL enableShowAutoFocus;

- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)(void))completionHandler;

- (void)captureImageWithCompletionHander:(void(^)(UIImage* image))completionHandler;

- (void)prepareForOrientationChange;
- (void)finishedOrientationChange;

@end


@protocol IRLCameraViewProtocol <NSObject>

@optional
/**
 @brief this optional delegation method will notify the Delegate of the confidence we detected a Rectangle
 
 @param view            The IRLCameraView calling the delegate
 @param confidence      A value between 0 .. 100% indicating the confidence of the detection
 */
-(void)didDetectRectangle:(IRLCameraView*)view withConfidence:(NSUInteger)confidence;

-(void)didGainFullDetectionConfidence:(IRLCameraView*)view;

-(void)didLostConfidence:(IRLCameraView*)view;

@end
