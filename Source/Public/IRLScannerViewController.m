//
//  IRLScannerViewController
//
//  Created by Denis Martin on 28/06/2015.
//  Copyright (c) 2015 Denis Martin. All rights reserved.
//

#import "IRLScannerViewController.h"
#import "IRLCameraView.h"
#import "TOCropViewController.h"

@interface IRLScannerViewController () <IRLCameraViewProtocol, TOCropViewControllerDelegate, CameraCapturePhotoDelegate>
{
    BOOL autoCapture;
}
@property (weak)                        id<IRLScannerViewControllerDelegate> camera_PrivateDelegate;

@property (weak, nonatomic, readwrite)  IBOutlet UIButton       *flash_toggle;
@property (weak, nonatomic, readwrite)  IBOutlet UIButton       *contrast_type;
@property (weak, nonatomic, readwrite)  IBOutlet UIButton       *detect_toggle;
@property (weak, nonatomic, readwrite)  IBOutlet UIButton       *cancel_button;
@property (weak, nonatomic, readwrite)  IBOutlet UIButton       *manual_button;
@property (weak, nonatomic, readwrite)  IBOutlet UIButton       *auto_button;

@property (readwrite)                   BOOL     cancelWasTrigger;
@property (weak, nonatomic, nonatomic)  IBOutlet UIButton       *scan_button;
@property (weak, nonatomic, readwrite)  IBOutlet UIButton       *cancel_scanning;

@property (weak, nonatomic)             IBOutlet UIView         *adjust_bar;
@property (weak, nonatomic)             IBOutlet UILabel        *titleLabel;

@property (weak, nonatomic)             IBOutlet UIImageView *focusIndicator;

@property (weak, nonatomic)             IBOutlet IRLCameraView  *cameraView;

- (IBAction)captureButton:(id)sender;

@property (readwrite, nonatomic)        IRLScannerViewType                   cameraViewType;

@property (readwrite, nonatomic)        IRLScannerDetectorType               detectorType;

@end

@implementation IRLScannerViewController

#pragma mark - Initializer

+ (instancetype)standardCameraViewWithDelegate:(id<IRLScannerViewControllerDelegate>)delegate {
    return [self cameraViewWithDefaultType:IRLScannerViewTypeBlackAndWhite defaultDetectorType:IRLScannerDetectorTypeAccuracy withDelegate:delegate];
}

+ (instancetype)cameraViewWithDefaultType:(IRLScannerViewType)type
                      defaultDetectorType:(IRLScannerDetectorType)detector
                             withDelegate:(id<IRLScannerViewControllerDelegate>)delegate {
    
    NSAssert(delegate != nil, @"You must provide a delegate");
    
    IRLScannerViewController*    cameraView = [[UIStoryboard storyboardWithName:@"IRLCamera" bundle:[NSBundle bundleForClass:self]] instantiateInitialViewController];
    cameraView.cameraViewType = type;
    cameraView.detectorType = detector;
    cameraView.camera_PrivateDelegate = delegate;
    cameraView.showControls = YES;
    cameraView.detectionOverlayColor = [UIColor redColor];
    return cameraView;
}

#pragma mark - Button delegates

-(IBAction)cancelTapped:(id)sender{
    if (self.camera_PrivateDelegate){
        [self.camera_PrivateDelegate didCancelIRLScannerViewController:self];
    }
}

#pragma mark - Setters

- (void)setCameraViewType:(IRLScannerViewType)cameraViewType {
    _cameraViewType = cameraViewType;
    [self.cameraView setCameraViewType:cameraViewType];
}

- (void)setDetectorType:(IRLScannerDetectorType)detectorType {
    _detectorType = detectorType;
    [self.cameraView setDetectorType:detectorType];
}

- (void)setShowControls:(BOOL)showControls {
    _showControls = showControls;
    [self updateTitleLabel:nil];
}

- (void)setShowAutoFocusWhiteRectangle:(BOOL)showAutoFocusWhiteRectangle {
    _showAutoFocusWhiteRectangle = showAutoFocusWhiteRectangle;
    [self.cameraView setEnableShowAutoFocus:showAutoFocusWhiteRectangle];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    autoCapture = YES;
    [self.cameraView setupCameraView];
    [self.cameraView setDelegate:self];
    [self.cameraView setCaptureDelegate:self];
    [self.cameraView setOverlayColor:self.detectionOverlayColor];
    [self.cameraView setDetectorType:self.detectorType];
    [self.cameraView setCameraViewType:self.cameraViewType];
    [self.cameraView setEnableShowAutoFocus:self.showAutoFocusWhiteRectangle];

    if (![self.cameraView hasFlash]){
        self.flash_toggle.enabled = NO;
        self.flash_toggle.hidden = YES;
    }
    
    [self.cameraView setEnableBorderDetection:YES];
    self.scan_button.hidden = YES;
    self.auto_button.hidden = YES;
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateTitleLabel:nil];
    
    self.detect_toggle.selected     =  self.cameraView.detectorType       == IRLScannerDetectorTypePerformance;
    self.contrast_type.selected     =  self.cameraView.cameraViewType   == IRLScannerViewTypeBlackAndWhite;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.cameraView start];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.cameraView stop];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self.cameraView prepareForOrientationChange];
    
    __weak typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // we just want the completion handler
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [weakSelf.cameraView finishedOrientationChange];
        
    }];
}

#pragma mark - CameraVC Actions

- (IBAction)detctingQualityToggle:(id)sender {
    
    [self setDetectorType:(self.detectorType == IRLScannerDetectorTypeAccuracy) ?
        IRLScannerDetectorTypePerformance : IRLScannerDetectorTypeAccuracy];

    [self updateTitleLabel:nil];
}

- (IBAction)filterToggle:(id)sender {
    
    switch (self.cameraViewType) {
        case IRLScannerViewTypeBlackAndWhite:
            [self setCameraViewType:IRLScannerViewTypeNormal];
            break;
        case IRLScannerViewTypeNormal:
            [self setCameraViewType:IRLScannerViewTypeUltraContrast];
            break;
        case IRLScannerViewTypeUltraContrast:
            [self setCameraViewType:IRLScannerViewTypeBlackAndWhite];
            break;
        default:
            break;
    }

    [self updateTitleLabel:nil];
}

- (IBAction)torchToggle:(id)sender {
    
    BOOL enable = !self.cameraView.isTorchEnabled;
    if ([sender isKindOfClass:[UIButton class]]) { [sender setSelected:enable]; }
    self.cameraView.enableTorch = enable;
}

- (IBAction)cancelButtonPush:(id)sender {
    self.cancelWasTrigger = YES;
    [self.cameraView stop];
    [self updateTitleLabel:@""];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if ([self.camera_PrivateDelegate respondsToSelector:@selector(cameraViewCancelRequested:)]) {
        [self.camera_PrivateDelegate cameraViewCancelRequested:self];
    }
#pragma clang diagnostic pop

    if ([self.camera_PrivateDelegate respondsToSelector:@selector(didCancelIRLScannerViewController:)]) {
        [self.camera_PrivateDelegate didCancelIRLScannerViewController:self];
    }
}

- (IBAction)goManual:(id)sender {
    [self.cameraView setEnableBorderDetection:NO];
    self.scan_button.hidden = NO;
    self.auto_button.hidden = NO;
    self.manual_button.hidden = YES;
}

- (IBAction)goAuto:(id)sender {
    [self.cameraView setEnableBorderDetection:YES];
    self.scan_button.hidden = YES;
    self.auto_button.hidden = YES;
    self.manual_button.hidden = NO;
}

#pragma mark - UI animations

- (void)updateTitleLabel:(NSString*)text {
    
    // CShow or not Controlle
    [self.adjust_bar setHidden:!self.showControls];
    
    // Update Button first
    BOOL detectorType = self.detectorType == IRLScannerDetectorTypePerformance;
    [self.detect_toggle setSelected:detectorType];
    
    [self.contrast_type setSelected:NO];
    [self.contrast_type setHighlighted:NO];

    switch (self.cameraViewType) {
        case IRLScannerViewTypeBlackAndWhite:
            [self.contrast_type setSelected:YES];
            break;
        case IRLScannerViewTypeNormal:
            break;
        case IRLScannerViewTypeUltraContrast:
            [self.contrast_type setHighlighted:YES];
            break;
        default:
            break;
    }

    // Update Text
    if (!text && [self.camera_PrivateDelegate respondsToSelector:@selector(cameraViewWillUpdateTitleLabel:)]) {
        text = [self.camera_PrivateDelegate cameraViewWillUpdateTitleLabel:self];
    }
    
    if (text.length == 0 || !text) {
        self.titleLabel.hidden = YES;
        return;
    }
    
    self.titleLabel.hidden = NO;
    if ([text isEqualToString:self.titleLabel.text]) {
        return;
    }
    
    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromTop;
    animation.duration = 0.1;
    [self.titleLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
    self.titleLabel.text = text;
}

- (void)changeButton:(UIButton *)button targetTitle:(NSString *)title toStateEnabled:(BOOL)enabled {
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:(enabled) ? [UIColor colorWithRed:1 green:0.81 blue:0 alpha:1] : [UIColor whiteColor] forState:UIControlStateNormal];
}

#pragma mark - CameraVC Capture Image

- (IBAction)captureButton:(id)sender {
    
    if (self.cancelWasTrigger == YES) return;
    
    if ([sender isKindOfClass:[UIButton class]]) {
        [sender setHidden:YES];
    }
    
    if ([sender isKindOfClass:[UIButton class]]) {
        autoCapture = NO;
        [self.cameraView captureImage];
    } else {
        // the Actual Capture
        [self.cameraView captureImage];
        autoCapture = YES;
    }

}

-(void)cameraDidCaptureImage:(UIImage *)image {
    
    // Getting a Preview
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[self.cameraView latestCorrectedUIImage]];
    imgView.frame = self.cameraView.frame;
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    imgView.backgroundColor = [UIColor clearColor];
    imgView.opaque = NO;
    imgView.alpha = 0.0f;
    imgView.transform = CGAffineTransformMakeScale(0.4f, 0.4f);
    
    // Some Feedback to the User
    UIView *white = [[UIView alloc] initWithFrame:self.view.frame];
    white.backgroundColor = UIColor.whiteColor;
    white.alpha = 0.0f;
    
    [self.view addSubview:white];
    [UIView animateWithDuration:0.2f animations:^{
        white.alpha = 1.0f;
    }];

    if (autoCapture) {
        
        [self.view addSubview:imgView];
        
        [UIView animateWithDuration:0.8f delay:0.5f usingSpringWithDamping:0.3f initialSpringVelocity:0.7f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            imgView.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
            imgView.alpha = 1.0f;
            
        } completion:nil];
        
        if (self.camera_PrivateDelegate){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01 *NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self.camera_PrivateDelegate pageSnapped:image from:self];
            });
        }
        
    }else{
        
        TOCropViewController *cropViewController = [[TOCropViewController alloc] initWithImage:image];
        cropViewController.delegate = self;
        cropViewController.aspectRatioPickerButtonHidden = YES;
        cropViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:cropViewController animated:YES completion:nil];
    }
    
}


#pragma mark - TOCropViewControllerDelegate

- (void)cropViewController:(TOCropViewController *)cropViewController didCropToImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 *NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self.camera_PrivateDelegate pageSnapped:image from:self];
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)cropViewController:(TOCropViewController *)cropViewController didCropToCircularImage:(UIImage *)image withRect:(CGRect)cropRect angle:(NSInteger)angle {
    
}

- (void)cropViewController:(TOCropViewController *)cropViewController didFinishCancelled:(BOOL)cancelled {
    [self dismissViewControllerAnimated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 *NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self cancelButtonPush:nil];
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

#pragma mark - IRLCameraViewProtocol

-(void)didLostConfidence:(IRLCameraView*)view {
    __weak  typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[weakSelf adjust_bar] setHidden:NO];
        [weakSelf updateTitleLabel:nil];
        [[weakSelf titleLabel] setBackgroundColor:[UIColor blackColor]];
    });
}

-(void)didDetectRectangle:(IRLCameraView*)view withConfidence:(NSUInteger)confidence {
    __weak  typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (confidence > view.minimumConfidenceForFullDetection) {
            NSInteger range     = view.maximumConfidenceForFullDetection - view.minimumConfidenceForFullDetection;
            CGFloat   delta     = 4.0f / range;
            NSInteger current   = view.maximumConfidenceForFullDetection - confidence;
            NSInteger value     = (range - range / current) * delta;
            
            [[weakSelf adjust_bar] setHidden:YES];
            
            if (value == 0) {
                [weakSelf.titleLabel setHidden:YES];
                
            } else {
                long displayValue = MAX((long)value - 1, 1);
                [weakSelf.titleLabel setHidden:NO];
                [weakSelf updateTitleLabel:[NSString stringWithFormat: @"... %ld ...", displayValue]];
            }
            
            [[weakSelf titleLabel] setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5f]];
            
        } else {
            [[weakSelf adjust_bar] setHidden:NO];
            [weakSelf updateTitleLabel:nil];
            [[weakSelf titleLabel] setBackgroundColor:[UIColor blackColor]];
        }
    });
}

-(void)didGainFullDetectionConfidence:(IRLCameraView*)view {
    __weak  typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[weakSelf adjust_bar] setHidden:YES];
        [weakSelf.titleLabel setHidden:YES];
        [[weakSelf titleLabel] setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5f]];
        
    });

    [self captureButton:view];
}


@end
