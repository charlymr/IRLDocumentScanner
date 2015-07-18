//
//  IRLScannerViewController
//
//  Created by Denis Martin on 28/06/2015.
//  Copyright (c) 2015 Denis Martin. All rights reserved.
//


@import UIKit;
@class IRLScannerViewController;

/**
 This ENUM define the Camera View Type
 */
typedef NS_ENUM(NSInteger,IRLScannerViewTypeN)
{
    /** No filtering */
    IRLScannerViewTypeNNormal,
    
    /** Use a black/white filtered camera */
    IRLScannerViewTypeNBlackAndWhite,

    /** Use a black/white Ultra contrasted camera */
    IRLScannerViewTypeNUltraContrast
};

/**
 This ENUM define the Detector Type use for detecting the paper edges
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
-(void)pageSnapped:(UIImage *)image from:(IRLScannerViewController*)cameraView;

@optional

/**
 @brief This optional method let you decide what you want to write in the Title bar. It can be use in cases where you want to tell whihc filter the user is using. You can inspect the controller to have more details.
 
 @warning   This method will be call multiple time as long we don't have full confidence of our scan. When the camera is confident enough, you will not be able to change the text anymore.
 
 @param     cameraView  The instance of the IRLScannerViewController controller which has perform this scan
 
 @return    The text you want to display
 */
-(NSString*)cameraViewWillUpdateTitleLabel:(IRLScannerViewController*)cameraView;

@end

/**
 * A fully functional instance of IRLScannerViewController allowing you to scan a document
 *
 * Example of usage in Swift:
 *
 * let scanner = IRLScannerViewController.standardCameraViewWithDelegate(self)
 *
 * scanner.showCountrols = false
 *
 * presentViewController(scanner, animated: true, completion: nil)
 *
 */
NS_CLASS_AVAILABLE(NA, 8_0)
@interface IRLScannerViewController : UIViewController

/**  @warning Use one of our provided method to create a controller. */
-(instancetype)init NS_UNAVAILABLE;

/**
 @brief This method instanciate our controller with the default value for cameraViewType: IRLScannerViewTypeNBlackAndWhite and dectorType: IRLScannerDetectorTypeAccuracy .
 
 @param     delegate    The Delegate conforming to the protocol IRLScannerViewControllerDelegate
 
 @return    A View controller you can use to scan your image.
 */
+ (instancetype)standardCameraViewWithDelegate:(id<IRLScannerViewControllerDelegate>)delegate;

/**
 @brief This method instanciate our controller
 
 @param     type        The type the camera will use to scan, see: IRLScannerViewTypeN
 @param     detector    The detector type the camera will use to detect our borders, see: IRLScannerDetectorType
 @param     delegate    The Delegate conforming to the protocol IRLScannerViewControllerDelegate
 
 @return    A View controller you can use to scan your image.
 */
+ (instancetype)cameraViewWithDefaultType:(IRLScannerViewTypeN)type defaultDetectorType:(IRLScannerDetectorType)detector withDelegate:(id<IRLScannerViewControllerDelegate>)delegate;

/**
 @return The color we want to use when we are detecting our page. Default is [UIColor redColor].
 */
@property (readwrite, nonatomic)      UIColor*                      detectionOverlayColor;


/**
 @return the current filtering type: 'IRLScannerViewTypeN' use by the camera.
 */
@property (readonly, nonatomic) IRLScannerViewTypeN                   cameraViewType;

/**
 @return the current detection sensitivity: 'IRLScannerDetectorType' use by the camera.
 */
@property (readonly, nonatomic) IRLScannerDetectorType               dectorType;

/**
 @brief This Boolan will show/hide the controlls of the camera. The controlls includ flash_toggle (If available), contrast_type, detect_toggle
 
 @warning Default value is YES
 
 @return Wherever the Camera View will show or not the controlls.
 */
@property (readwrite, nonatomic)      BOOL                          showCountrols;

/**
 @return Wherever the Camera View will show or not when the Auto Focus is trigger. It is automatically triger when we reach about 50% of confidence for the detection and we are focusing on the center of the document. Default is NO
 */
@property (readwrite, nonatomic)      BOOL                          showAutoFocusWhiteRectangle;


/**
 @brief This Button is for the flash of the camera
 
 @discussion We provide an access to that button so you coudl personalized it's aspect. We are using the following images (Defaut-OFF: "856-lightning-bolt", Selected-ON: "856-lightning-bolt-selected")
 
 @return The button for ou Flash Toggle.
 */
@property (weak, nonatomic, readonly) IBOutlet UIButton*            flash_toggle;

/**
 @brief This Button is for the contrast/ Image filter use by the camera.
 
 @discussion We provide an access to that button so you could personalized it's aspect. We are using the following images (Defaut-Normal: "822-photo-2", Selected-BlackAndWhite: "856-lightning-bolt-selected", Highlited-UltraContrast: "810-document-2-selected")
 
 @see IRLScannerViewTypeN cameraViewType
 
 @return The button for ou Constrast Filter Toggle.
 */
@property (weak, nonatomic, readonly) IBOutlet UIButton*            contrast_type;

/**
 @brief This Button is for the Detection use by the camera to detect our borders.
 
 @discussion We provide an access to that button so you could personalized it's aspect. We are using the following images (Defaut-Accuracy: "873-magic-wand", Selected-Performance: "795-gauge-selected")
 
 @see IRLScannerDetectorType dectorType
 
 @return The button for ou Detector Filter Toggle.
 */
@property (weak, nonatomic, readonly) IBOutlet UIButton*            detect_toggle;

@end

