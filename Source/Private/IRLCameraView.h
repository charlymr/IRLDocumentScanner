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

/**
 @brief This is the UIView subclass use in our prject
 */
@interface IRLCameraView : UIView

/**
 @brief Setup the View. Should be call only Once.
 */
- (void)setupCameraView;

/**
@brief Start the camera.
*/
- (void)start;

/**
 @brief Stop the camera.
 */
- (void)stop;

/**
 @return delegate cofroming to `IRLCameraViewProtocol`
 */
@property (weak)    id<IRLCameraViewProtocol>  _Nullable delegate;

/**
@return minimumConfidenceForFullDetection Integer for 0 to 100 defining what is the our minimum confidence to detect the scan. Default 66.
*/
@property (nonatomic, readwrite)    NSUInteger      minimumConfidenceForFullDetection;  // Default 66

/**
 @return minimumConfidenceForFullDetection Integer for 0 to 100 defining what is the our maximum confidence to detect the scan. Default 100.
 */
@property (nonatomic, readonly)     NSUInteger      maximumConfidenceForFullDetection;  // Default 100

/**
 @return The color use for overlay. Default is [UIColor red]
 */
@property (readwrite, strong, nonatomic)   UIColor * _Nonnull overlayColor;

/**
 @return A quick corrected image (use for preview).
 */
- (UIImage* _Nullable)latestCorrectedUIImage;

/**
 @return enableBorderDetection Auto detect border
 */
@property (nonatomic,assign,    getter=isBorderDetectionEnabled)    BOOL enableBorderDetection;
/**
 @return enableTorch Enable the torch
 */
@property (nonatomic,assign,    getter=isTorchEnabled)              BOOL enableTorch;
/**
 @return enableTorch Enable the Flash
 */
@property (nonatomic,readonly,  getter=hasFlash)                    BOOL flash;

/**
 @return cameraViewType The type of Filter that will be apply to the Image
 */
@property (nonatomic,assign)    IRLScannerViewType                   cameraViewType;

/**
 @return detectorType The  Detector Type we use for detecting the document edges. Default: IRLScannerDetectorTypeAccuracy
 */
@property (nonatomic,assign)    IRLScannerDetectorType               detectorType;

/**
 @return enableDrawCenter Will draw a rectangle in the center
 */
@property (nonatomic,assign,    getter=isDrawCenterEnabled)         BOOL enableDrawCenter;

/**
 @return enableShowAutoFocus Will show auto focus rigth before capture.
 */
@property (nonatomic,assign,    getter=isShowAutoFocusEnabled)      BOOL enableShowAutoFocus;

/**
 @brief Force focus at a particular point.
 
 @param point a Point where to focuse
 @param completionHandler a block taking no parameter to be exctuted when done
 */
- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^ _Nullable)(void))completionHandler;

/**
 @brief Force focus at a particular point.
 
 @warning If for some reason the AVCaptureConnection could not be found (the view disapear or app resign active, your capture image will be nil).
 
 @param completionHandler a block retruning 1 parameter image to be exctuted when done
 */
- (void)captureImageWithCompletionHander:(void(^_Nonnull)(UIImage* _Nullable image))completionHandler;

/**
 @brief Prepare the view for orientation changes (stop the camera)
 */
- (void)prepareForOrientationChange;

/**
 @brief Must be call at teh end of the orientation changes.
 */
- (void)finishedOrientationChange;

@end


@protocol IRLCameraViewProtocol <NSObject>

@optional
/**
 @brief this optional delegation method will notify the Delegate of the confidence we detected a Rectangle
 
 @param view            The IRLCameraView calling the delegate
 @param confidence      A value between 0 .. 100% indicating the confidence of the detection
 */
-(void)didDetectRectangle:(IRLCameraView* _Nonnull)view withConfidence:(NSUInteger)confidence;

/**
 @brief Call when the view gain the full confiende for the detection (stayed long enough over the [IRLCameraView minimumConfidenceForFullDetection] and close enough from [IRLCameraView maximumConfidenceForFullDetection]
 
 @param view            The IRLCameraView calling the delegate
 */
-(void)didGainFullDetectionConfidence:(IRLCameraView* _Nonnull)view;

/**
 @brief Call when the view lostconfiende for the detection got bellow [IRLCameraView minimumConfidenceForFullDetection]
 
 @param view            The IRLCameraView calling the delegate
 */
-(void)didLostConfidence:(IRLCameraView* _Nonnull)view;

@end
