//
//  IRLScannerViewController
//
//  Created by Denis Martin on 28/06/2015.
//  Copyright (c) 2015 Denis Martin. All rights reserved.
//


@import UIKit;
@import TOCropViewController;


@class IRLScannerViewController;


/**
 This ENUM define the Filter that will be apply to the Image
 */
typedef NS_ENUM(NSInteger,IRLScannerViewType)
{
    /** No filtering */
    IRLScannerViewTypeNormal,
    
    /** Use a black/white filtered camera */
    IRLScannerViewTypeBlackAndWhite,
    
    /** Use a black/white Ultra contrasted camera */
    IRLScannerViewTypeUltraContrast
};

/**
 This ENUM define the Detector Type we use for detecting the document edges
 */
typedef NS_ENUM(NSInteger,IRLScannerDetectorType)
{
    /** Use more Accurate detection */
    IRLScannerDetectorTypeAccuracy,
    
    /** Use Fast detection */
    IRLScannerDetectorTypePerformance
};


/**
 *  This Protocol must be implemented in the instance where you want you scan to be returned.
 */
@protocol IRLScannerViewControllerDelegate <NSObject>

@required

/**
 @brief When the camera has finish the full detection for the scan, it will call this method.
 
 @warning   You must implement this method
 
 @param     image       The scanned image
 @param     cameraView  The instance of the IRLScannerViewController controller which has perform this scan
*/
-(void)pageSnapped:(UIImage* _Nonnull)image from:(IRLScannerViewController* _Nonnull)cameraView;

@optional

/**
 @brief This optional method let you decide what you want to write in the Title bar. It can be use in cases where you want to tell whihc filter the user is using. You can inspect the controller to have more details.
 
 @warning   This method will be call multiple time as long we don't have full confidence of our scan. When the camera is confident enough, you will not be able to change the text anymore.
 
 @param     cameraView  The instance of the IRLScannerViewController controller which has perform this scan
 
 @return    The text you want to display
 */
-(NSString* _Nullable)cameraViewWillUpdateTitleLabel:(IRLScannerViewController* _Nonnull)cameraView;

/**
 @brief The user has pushed the Cancel button.
 
 @warning   You are responsible fo removing the view. The scanner will only stop the scan
 
 @param     cameraView  The instance of the IRLScannerViewController controller which has perform this scan
 */
-(void)didCancelIRLScannerViewController:(IRLScannerViewController* _Nonnull)cameraView;

/**
 @brief <Deprecated> The user has pushed the Cancel button.
 
 @param     cameraView  The instance of the IRLScannerViewController controller which has perform this scan
 */
-(void)cameraViewCancelRequested:(IRLScannerViewController* _Nonnull)cameraView __deprecated_msg("Use [IRLScannerViewControllerDelegate didCancelIRLScannerViewController:] ");

@end

/**
 * A fully functional instance of IRLScannerViewController allowing you to scan a document with automatic border detection.
 *
 *
 */
NS_CLASS_AVAILABLE(NA, 8_0)
@interface IRLScannerViewController : UIViewController

/**  @warning Use one of our provided method to create a controller. */
-(instancetype _Nonnull)init NS_UNAVAILABLE;

/**
 @brief This method instanciate our controller with the default value for cameraViewType: IRLScannerViewTypeBlackAndWhite and detectorType: IRLScannerDetectorTypeAccuracy .
 
 @param     delegate    The Delegate conforming to the protocol IRLScannerViewControllerDelegate
 
 @return    A View controller you can use to scan your image.
 */
+ (instancetype _Nonnull)standardCameraViewWithDelegate:(id<IRLScannerViewControllerDelegate> _Nonnull)delegate;

/**
 @brief This method instanciate our controller
 
 @param     type        The type the camera will use to scan, see: IRLScannerViewType
 @param     detector    The detector type the camera will use to detect our borders, see: IRLScannerDetectorType
 @param     delegate    The Delegate conforming to the protocol IRLScannerViewControllerDelegate
 
 @return    A View controller you can use to scan your image.
 */
+ (instancetype _Nonnull)cameraViewWithDefaultType:(IRLScannerViewType)type
                      defaultDetectorType:(IRLScannerDetectorType)detector
                             withDelegate:(id<IRLScannerViewControllerDelegate> _Nonnull)delegate;

/**
 @brief You can set the overlay color of the detected document here.
 
 @warning Default is [UIColor redColor]
 
 @return The color we want to use when we are detecting our page.
 */
@property (readwrite, nonatomic)      UIColor*                      _Nonnull detectionOverlayColor;


/**
 @brief Depending what you want, there is some build-in filter that can be apply to the image.
 
 @see IRLScannerViewType for more details
 
 @return The current filtering type: IRLScannerViewType applied to the image on the camera.
 */
@property (readonly, nonatomic) IRLScannerViewType                   cameraViewType;

/**
 @brief Depending what you want, you can have either Fast or Accurate detection of borders
 
 @see IRLScannerDetectorType for more details
 
 @return The current detection sensitivity: IRLScannerDetectorType use by the detector.
 */
@property (readonly, nonatomic) IRLScannerDetectorType               detectorType;

/**
 @brief This Boolan will show/hide the controlls of the camera. The controlls includ flash_toggle (If available), contrast_type, detect_toggle
 
 @warning Default value is YES
 
 @return Wherever the Camera View will show or not the controlls.
 */
@property (readwrite, nonatomic)      BOOL                          showControls;

/**
 @brief The controller can show a flashing white rectangle when the Auto Focus is trigger. It is automatically trigger when we reach about 50% of confidence for the detection and we are focusing on the center of the document.
 
 @warning Default value is NO
 
 @return Wherever the Camera View will show or not a flashing white rectangle.
 */
@property (readwrite, nonatomic)      BOOL                          showAutoFocusWhiteRectangle;


/**
 @brief This Button is for the flash of the camera
 
 @discussion We provide an access to that button  for you topersonalize its aspect.
 We are using the following images (Defaut-OFF: "856-lightning-bolt", Selected-ON: "856-lightning-bolt-selected")
 
 @return The button for our Flash Toggle.
 */
@property (weak, nonatomic, readonly) IBOutlet UIButton*           _Nullable flash_toggle;

/**
 @brief This Button is for the contrast/ Image filter use by the camera.
 
 @discussion We provide an access to that button for you to personalize its aspect.
 We are using the following images (Defaut-Normal: "822-photo-2", Selected-BlackAndWhite: "856-lightning-bolt-selected", Highlited-UltraContrast: "810-document-2-selected")
 
 @see IRLScannerViewType cameraViewType
 
 @return The button for our Constrast Filter Toggle.
 */
@property (weak, nonatomic, readonly) IBOutlet UIButton*            _Nullable contrast_type;

/**
 @brief This Button is for the Detection use by the camera to detect our borders.
 
 @discussion We provide an access to that button for you topersonalize its aspect.
 We are using the following images (Defaut-Accuracy: "873-magic-wand", Selected-Performance: "795-gauge-selected")
 
 @see IRLScannerDetectorType detectorType
 
 @return The button for our Detector Filter Toggle.
 */
@property (weak, nonatomic, readonly) IBOutlet UIButton*            _Nullable detect_toggle;

/**
 @brief This Button is here for the user to press in case if want to cancel the aciton.
 
 @discussion We provide an access to that button for you topersonalize its aspect.
 
 @return The button for our Cancel.
 */
@property (weak, nonatomic, readonly) IBOutlet UIButton*            _Nullable cancel_button;

/**
 @brief This Button is here for the user to press in case if want to cancel the aciton.
 
 @discussion This button is here to provide compatibilty with Seth previous commit.
 
 @return The button for our Cancel.
 */
@property (weak, nonatomic, readonly) IBOutlet UIButton*            _Nullable cancel_scanning;

/**
 @brief Call the cancel directlly .
 */
- (IBAction)cancelTapped:(id _Nullable )sender;

/**
@brief <Deprecated> This property was introduce by mistake and is not use in the project.
*/
@property(nonatomic, assign) id _Nullable  delegate __deprecated_msg("This property was introduce by mistake and is not use in the project!");

@end








