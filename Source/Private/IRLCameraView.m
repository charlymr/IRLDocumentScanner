//
//  IRLCameraView.m
//
//  Modified by Denis Martin on 12/07/2015
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

#import "IRLCameraView.h"
#import "CIRectangleFeature+Utilities.h"
#import "CIImage+Utilities.h"
#import <ImageIO/ImageIO.h>

@interface IRLCameraView () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    
    CIContext*              _coreImageContext;
    GLuint                  _renderBuffer;
    GLKView*                _glkView;
    
    BOOL                    _isStopped;
    
    CGFloat                 _imageDedectionConfidence;
    NSTimer*                _borderDetectTimeKeeper;
    BOOL                    _borderDetectFrame;
    CIRectangleFeature*     _borderDetectLastRectangleFeature;
    BOOL                    _FocusCurrentRectangleDone;

}

@property (readwrite)               BOOL                            didNotifyFullConfidence;
@property (readwrite)               BOOL                            isCapturing;
@property (readwrite)               BOOL                            isCurrentlyFocusing;
@property (readwrite)               BOOL                            isRotating;

@property (nonatomic,strong)        AVCaptureSession*               captureSession;
@property (nonatomic,strong)        AVCaptureDevice*                captureDevice;
@property (nonatomic,strong)        AVCaptureStillImageOutput*      stillImageOutput;

@property (nonatomic,strong)        EAGLContext*                    context;

@property (nonatomic, assign)       BOOL                            forceStop;
@property (nonatomic, strong)       CIImage*                        gradient;

@property (nonatomic, strong)       CIImage*                        latestCorrectedImage;
@property (nonatomic, readwrite)    NSUInteger                      maximumConfidenceForFullDetection;  // Default 100
@property (readwrite, strong)       UIImageView* transitionSnapsot;

@end

@implementation IRLCameraView

#pragma mark -
#pragma mark Utilites

BOOL rectangleDetectionConfidenceHighEnough(float confidence) {
    return (confidence > 1.0);
}

- (AVCaptureVideoOrientation) videoOrientationFromCurrentDeviceOrientation {
    switch ([[UIApplication sharedApplication] statusBarOrientation]) {
        case UIInterfaceOrientationPortrait:            return AVCaptureVideoOrientationPortrait;
        case UIInterfaceOrientationLandscapeLeft:       return AVCaptureVideoOrientationLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:      return AVCaptureVideoOrientationLandscapeRight;
        case UIInterfaceOrientationPortraitUpsideDown:  return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIInterfaceOrientationUnknown:             return AVCaptureVideoOrientationPortrait;
    }
    return AVCaptureVideoOrientationPortrait;
}

UIImageOrientation imageOrientationForCurrentDeviceOrientation() {
    switch ([[UIApplication sharedApplication] statusBarOrientation]) {
        case UIInterfaceOrientationPortrait:            return UIImageOrientationRight;
        case UIInterfaceOrientationLandscapeLeft:       return UIImageOrientationDown;
        case UIInterfaceOrientationLandscapeRight:      return UIImageOrientationUp;
        case UIInterfaceOrientationPortraitUpsideDown:  return UIImageOrientationLeft;
        case UIInterfaceOrientationUnknown:             return UIImageOrientationUp;
    }
    
    return UIImageOrientationUp;
}

UIImage* makeUIImageFromCIImage(CIImage *ciImage) {
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:[ciImage extent]];
    
    UIImage* uiImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return uiImage;
}

CGImagePropertyOrientation imagePropertyOrientationForUIImageOrientation(UIImageOrientation orientation) {
    switch (orientation) {
        case UIImageOrientationUp:
            return kCGImagePropertyOrientationUp;
        case UIImageOrientationUpMirrored:
            return kCGImagePropertyOrientationUpMirrored;
        case UIImageOrientationDown:
            return kCGImagePropertyOrientationDown;
        case UIImageOrientationDownMirrored:
            return kCGImagePropertyOrientationDownMirrored;
        case UIImageOrientationLeftMirrored:
            return kCGImagePropertyOrientationLeftMirrored;
        case UIImageOrientationRight:
            return kCGImagePropertyOrientationRight;
        case UIImageOrientationRightMirrored:
            return kCGImagePropertyOrientationRightMirrored;
        case UIImageOrientationLeft:
            return kCGImagePropertyOrientationLeft;
    }
}

#pragma mark -
#pragma mark Notifications ( Background/Foreground )

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setMinimumConfidenceForFullDetection:66];
    [self setMaximumConfidenceForFullDetection:100];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backgroundMode) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_foregroundMode) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)_backgroundMode {
    self.forceStop = YES;
}

- (void)_foregroundMode {
    self.forceStop = NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    [EAGLContext setCurrentContext:nil];

}

#pragma mark -
#pragma mark Setup

- (void)createSnapshot {
    
    if (_glkView == nil) {
        return;
    }
    
    // Snopshot
    UIImageView *view = [[UIImageView alloc] initWithFrame:self.bounds];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.translatesAutoresizingMaskIntoConstraints = YES;
    view.contentMode = UIViewContentModeScaleAspectFill;
    view.image = [_glkView snapshot] ;
    self.transitionSnapsot = view;
    
    [self insertSubview:view atIndex:0];
}

- (void)prepareForOrientationChange {
    self.isRotating = YES;
    [self createSnapshot];
    _coreImageContext = nil;
    
    [self.captureSession.outputs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[AVCaptureVideoDataOutput class]]) {
            [obj setSampleBufferDelegate:nil queue:NULL];
        }
        [self.captureSession removeOutput:obj];
    }];
    
    [self stop];
    self.context = nil;
    [self removeGLKView];
}

- (void)finishedOrientationChange {
    [self setupCameraView];
    [self start];
    
    // We must bring it to the front as our GLView was create and insert at index 0
    [self bringSubviewToFront:self.transitionSnapsot];
    
    // Animat the fade out
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        weakSelf.transitionSnapsot.alpha = 0;
    } completion:^(BOOL finished) {
        [weakSelf.transitionSnapsot removeFromSuperview];
        weakSelf.isRotating = NO;
    }];
}

- (void)removeGLKView {
    _coreImageContext = nil;
    self.context = nil;
    
    [_glkView removeFromSuperview];
    _glkView = nil;
}

- (void)createGLKView {
    if (self.context) return;

    EAGLContext *lastContext = [EAGLContext currentContext];
    
    if(lastContext != nil) {
        self.context = lastContext;
        [EAGLContext setCurrentContext:lastContext];
    } else {
        self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:self.context];
    }
    
    
    GLKView *view = [[GLKView alloc] initWithFrame:self.bounds];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.translatesAutoresizingMaskIntoConstraints = YES;
    view.context = self.context;
    view.contentScaleFactor = 1.0f;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    [self insertSubview:view atIndex:0];
    
    _glkView = view;
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    _coreImageContext = [CIContext contextWithEAGLContext:self.context];
    [EAGLContext setCurrentContext:self.context];
}

- (void)setupCameraView {
    
    NSArray *possibleDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = [possibleDevices firstObject];
    if (!device) return;
    
    _imageDedectionConfidence = 0.0;
    
    // Session Congfguration
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    [session beginConfiguration];
    
    [self setCaptureDevice:device];
    
    NSError *error = nil;
    
    // Add Input capabilities
    AVCaptureDeviceInput* input     = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    session.sessionPreset           = AVCaptureSessionPresetPhoto;
    [session addInput:input];
    
    // Add Video Sample Buffer Output
    AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [dataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)}];
    
    dispatch_queue_t queue = dispatch_queue_create("ScanSampleBufferQueue", NULL);
    [dataOutput setSampleBufferDelegate:self queue:queue];
    [session addOutput:dataOutput];
    
    // Preview Layer
    [self createGLKView];

    
    // Add Photo Capture capabilities
    AVCaptureStillImageOutput *imgOutput = [[AVCaptureStillImageOutput alloc] init];
    [session addOutput:imgOutput];
    [self setStillImageOutput:imgOutput];
    
    AVCaptureConnection *connection = [dataOutput.connections firstObject];
    [connection setVideoOrientation:[self videoOrientationFromCurrentDeviceOrientation]];
    
    // Configure the Device
    NSError *configError;
    if ([device lockForConfiguration:&configError]) {
        
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        
        if (configError) {
            NSLog(@"Error Configuring Video Catpures: %@", configError.localizedDescription);
        }
        [device unlockForConfiguration];
    }
    
    [session commitConfiguration];
    
    [self setCaptureSession: session];
}

#pragma mark -
#pragma mark Instance Methods Public

- (void)start {
    
    if (self.gradient == nil){
        self.gradient =  [CIImage imageGradientImage:0.3];
    }
    
    _isStopped = NO;
    self.isCapturing = NO;
    
    [self.captureSession startRunning];
    
    _borderDetectTimeKeeper = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(enableBorderDetectFrame) userInfo:nil repeats:YES];
    
    [self hideGLKView:NO completion:nil];
}

- (void)stop {
    _isStopped = YES;
    
    [self.captureSession stopRunning];
    
    [_borderDetectTimeKeeper invalidate];
    
    [self hideGLKView:YES completion:nil];
}

- (void)focusWithPoinOfInterest:(CGPoint)pointOfInterest completionHandler:(void(^)(void))completionHandler {
    
    AVCaptureDevice *device = self.captureDevice;
    
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        NSError *error;
        if ([device lockForConfiguration:&error])
        {
			[device setFocusPointOfInterest:pointOfInterest];

            if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus])
            {
                [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            }

			if([device isExposurePointOfInterestSupported])
			{
				[device setExposurePointOfInterest:pointOfInterest];
			}
            /*
            if([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
            {
                [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            */
            [device unlockForConfiguration];

			if(completionHandler) completionHandler();
        }
    }
    else
    {
        if (completionHandler) completionHandler();
    }
    
}

- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)(void))completionHandler {
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGPoint pointOfInterest = CGPointZero;
        CGSize frameSize        = weakSelf.bounds.size;
        pointOfInterest = CGPointMake(point.y / frameSize.height, 1.f - (point.x / frameSize.width));
        [weakSelf focusWithPoinOfInterest:pointOfInterest completionHandler:completionHandler];
    });
    
}

- (void)captureImageWithCompletionHander:(void(^)(UIImage* image))completionHandler {
    
    if (self.isCapturing || self.window == nil) return;
    
    __weak typeof(self) weakSelf = self;
    
    self.isCapturing = YES;
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) break;
    }
    
    if (videoConnection == nil) {
        completionHandler(nil);
        return;
    }
    
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        UIImage *finalImage;
        
        if (weakSelf.isBorderDetectionEnabled) {
            // The original code worked great in iOS 9.  iOS10 created all sorts of problems which were fixed, but iOS 9 can't seem to use them.
            BOOL isiOS10OrLater = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 10, .minorVersion = 0, .patchVersion = 0}];
            
            CIImage *enhancedImage = [[CIImage alloc] initWithData:imageData];
            
            if (isiOS10OrLater) {
                // match the orientation of the image to the device
                enhancedImage = [enhancedImage imageByApplyingOrientation:imagePropertyOrientationForUIImageOrientation(imageOrientationForCurrentDeviceOrientation())];
            }
            
            // perform any filters
            switch (self.cameraViewType) {
                case IRLScannerViewTypeBlackAndWhite:
                    enhancedImage = [enhancedImage filteredImageUsingEnhanceFilter];
                    break;
                case IRLScannerViewTypeNormal:
                    enhancedImage = [enhancedImage filteredImageUsingContrastFilter];
                    break;
                case IRLScannerViewTypeUltraContrast:
                    enhancedImage = [enhancedImage filteredImageUsingUltraContrastWithGradient:weakSelf.gradient];
                    break;
                default:
                    break;
            }
            
            // crop and correct perspective
            if (rectangleDetectionConfidenceHighEnough(_imageDedectionConfidence)) {
                 CIRectangleFeature *rectangleFeature = [CIRectangleFeature biggestRectangleInRectangles:(NSArray<CIRectangleFeature*>*)[[weakSelf detector] featuresInImage:enhancedImage]];
                 
                 if (rectangleFeature) {
                     enhancedImage = [enhancedImage correctPerspectiveWithFeatures:rectangleFeature];
                 }
            }
            
            enhancedImage = [enhancedImage cropBordersWithMargin:40.0f];

            if (isiOS10OrLater) {
                finalImage = makeUIImageFromCIImage(enhancedImage);
            }
            else {
                finalImage = [enhancedImage orientationCorrecterUIImage];
            }
        }
        else {
            finalImage = [[UIImage alloc] initWithData:imageData];
        }
        
        [weakSelf hideGLKView:NO completion:nil];
        
        if (completionHandler) completionHandler(finalImage);
        
        [self stop];
    }];
}

#pragma mark -
#pragma mark Instance Methods Private

- (void)enableBorderDetectFrame {
    _borderDetectFrame = YES;
}

- (void)hideGLKView:(BOOL)hidden completion:(void(^)(void))completion {
    [UIView animateWithDuration:0.1 animations:^{
        _glkView.alpha = (hidden) ? 0.0 : 1.0;
        
    } completion:^(BOOL finished) {
        if (completion) completion();
    }];
}

#pragma mark -
#pragma mark Setters / Getters

- (void)setMinimumConfidenceForFullDetection:(NSUInteger)minimumConfidenceForFullDetection {
    if (minimumConfidenceForFullDetection > 100) _minimumConfidenceForFullDetection = 100;
    else _minimumConfidenceForFullDetection = minimumConfidenceForFullDetection;
}

- (void)setCameraViewType:(IRLScannerViewType)cameraViewType {
    UIBlurEffect * effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *viewWithBlurredBackground =[[UIVisualEffectView alloc] initWithEffect:effect];
    viewWithBlurredBackground.frame = self.bounds;
    [self insertSubview:viewWithBlurredBackground aboveSubview:_glkView];
    
    _cameraViewType = cameraViewType;
    
    viewWithBlurredBackground.alpha = 0.0;
    [UIView animateWithDuration:0.1 animations:^{
        viewWithBlurredBackground.alpha = 1.0;
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                   {
                       
                       [UIView animateWithDuration:0.1 animations:^{
                           viewWithBlurredBackground.alpha = 0.0;
                           [viewWithBlurredBackground removeFromSuperview];
                       }];
                       
                   });
}

- (void)setEnableTorch:(BOOL)enableTorch {
    _enableTorch = enableTorch;
    
    AVCaptureDevice *device = self.captureDevice;
    if ([device hasTorch] && [device hasFlash])
    {
        [device lockForConfiguration:nil];
        if (enableTorch)
        {
            [device setTorchMode:AVCaptureTorchModeOn];
        }
        else
        {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
        [device unlockForConfiguration];
    }
}

- (BOOL)hasFlash{
    AVCaptureDevice *device = self.captureDevice;
    return ([device hasTorch] && [device hasFlash]);
}

- (CIDetector*)detector {
    static CIDetector *detectorPerf = nil;
    static CIDetector *detectorHigh = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
                  {
                      detectorPerf = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{
                                                                                                              CIDetectorAccuracy        : CIDetectorAccuracyLow,
                                                                                                              CIDetectorTracking        : @YES,
                                                                                                              CIDetectorMinFeatureSize  : @.5f
                                                                                                              }];
                      
                      detectorHigh = [CIDetector detectorOfType:CIDetectorTypeRectangle context:nil options:@{
                                                                                                              CIDetectorAccuracy        : CIDetectorAccuracyHigh,
                                                                                                              CIDetectorTracking        : @YES,
                                                                                                              CIDetectorMinFeatureSize  : @.5f
                                                                                                              
                                                                                                              }];
                  });
    
    switch (self.detectorType) {
            
        case IRLScannerDetectorTypePerformance: return detectorPerf;
            break;
        case IRLScannerDetectorTypeAccuracy:
        default: break;
    }
    return detectorHigh;
    
}

- (UIColor*)overlayColor {
    if (!_overlayColor) {
        _overlayColor = [UIColor redColor];
    }
    return _overlayColor;
}

- (UIImage*)latestCorrectedUIImage {
    return [self.latestCorrectedImage makeUIImageWithContext:_coreImageContext];
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (self.forceStop || self.isRotating) return;
    if (_isStopped || self.isCapturing || !CMSampleBufferIsValid(sampleBuffer)) return;
    
    __weak  typeof(self) weakSelf = self;
    
    // Get The Pixel Buffer here
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // First we Capture the Image
    CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    
    switch (self.cameraViewType) {
        case IRLScannerViewTypeBlackAndWhite:        image = [image filteredImageUsingEnhanceFilter];
            break;
        case IRLScannerViewTypeNormal:               image = [image filteredImageUsingContrastFilter];
            break;
        case IRLScannerViewTypeUltraContrast:        image = [image filteredImageUsingUltraContrastWithGradient:self.gradient ];
            break;
        default:
            break;
    }
    
    if (self.isBorderDetectionEnabled) {
        
        // Get The current Confidence
        NSUInteger confidence   =  _imageDedectionConfidence;
        confidence = confidence > 100 ? 100 : confidence;
        
        // Fix the last rectangle detected
        if (_borderDetectFrame && confidence < self.minimumConfidenceForFullDetection) {
            _borderDetectLastRectangleFeature = [CIRectangleFeature biggestRectangleInRectangles:(NSArray<CIRectangleFeature*>*)[[self detector] featuresInImage:image]];
            _borderDetectFrame = NO;
        }
        
        // Create teh Overlay
        if (_borderDetectLastRectangleFeature) {
            
            // Notify Our Delegate eventually
            if ([self.delegate respondsToSelector:@selector(didDetectRectangle:withConfidence:)]) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.delegate didDetectRectangle:weakSelf withConfidence:confidence];
                });
                
                if (confidence > 98 && [self.delegate respondsToSelector:@selector(didGainFullDetectionConfidence:)] && self.didNotifyFullConfidence == NO) {
                    
                    self.didNotifyFullConfidence = YES;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf.delegate didGainFullDetectionConfidence:weakSelf];
                    });
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0f *NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        weakSelf.didNotifyFullConfidence = NO;
                    });
                }
            }
            
            _imageDedectionConfidence += 1.0f;
            
            CGFloat alpha    = 0.1f;
            if (_imageDedectionConfidence > 0.0f) {
                alpha = _imageDedectionConfidence / 100.0f;
                alpha = alpha > 0.8f ? 0.8f : alpha;
            }
            
            // Keep Ref to the latest corrected Image:
            self.latestCorrectedImage = [image correctPerspectiveWithFeatures:_borderDetectLastRectangleFeature];
            
            // Draw OverLay
            image = [image drawHighlightOverlayWithcolor:[self.overlayColor colorWithAlphaComponent:alpha] CIRectangleFeature:_borderDetectLastRectangleFeature];
            
            // Draw Center
            if(self.enableDrawCenter) image = [image drawCenterOverlayWithColor:[UIColor redColor] point:_borderDetectLastRectangleFeature.centroid];
            
            // Draw Overlay Focus
            CGFloat amplitude = _borderDetectLastRectangleFeature.bounds.size.width / 4.0f;
            if(self.isCurrentlyFocusing && self.enableShowAutoFocus) image = [image drawFocusOverlayWithColor:[UIColor colorWithWhite:1.0f alpha:0.7f-alpha] point:_borderDetectLastRectangleFeature.centroid amplitude:amplitude*alpha];
            
            // Focus Image on center
            if (confidence > 50.0f && _FocusCurrentRectangleDone == NO)  {
                _FocusCurrentRectangleDone = YES;
                self.isCurrentlyFocusing = YES;
                
                [self focusAtPoint:_borderDetectLastRectangleFeature.centroid completionHandler:^{
                    if (self.enableShowAutoFocus) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0f *NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                            self.isCurrentlyFocusing = NO;
                        });
                    }
                }];
            }
        }
        else {
            if ([self.delegate respondsToSelector:@selector(didLostConfidence:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.delegate didLostConfidence:self];
                });
            }
            _imageDedectionConfidence = 0.0f;
            _FocusCurrentRectangleDone = NO;
            self.isCurrentlyFocusing = NO;
        }
        
    }
    
    __weak CIContext *weakCoreImageContext = _coreImageContext;
    __weak GLKView *weakGlkView            = _glkView;
    __weak EAGLContext* weakContext        = _context;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect bound = weakSelf.bounds;
        // Send the Resulting Image to the Sample Buffer
        if (weakContext && weakCoreImageContext && weakGlkView != nil && CGRectIsNull(bound) == NO && weakSelf.window != nil)
        {
            [weakCoreImageContext drawImage:image inRect:bound fromRect:image.extent];
            [weakContext presentRenderbuffer:GL_RENDERBUFFER];
            [weakGlkView setNeedsDisplay];
        }
    });
    
}

@end
