//
//  CIImage+Utilities.h
//
//  Modified by Denis Martin on 12/07/2015
//  Copyright (c) 2015 iRLMobile. All rights reserved.
//  Based on IPDFCameraViewController: https://github.com/mmackh/IPDFCameraViewController/tree/master/IPDFCameraViewController
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

@import UIKit;
@import CoreImage;

@class IRLRectangleFeature;

/** @brief Protocol defining a Rectangle feature  */
@protocol IRLRectangleFeatureProtocol <NSObject>
/** @return Top Left corner of rectangle Feature  */
@property (readonly) CGPoint topLeft;
/** @return Top Right corner of rectangle Feature  */
@property (readonly) CGPoint topRight;
/** @return Bottom Left corner of rectangle Feature  */
@property (readonly) CGPoint bottomLeft;
/** @return Bottom Right corner of rectangle Feature  */
@property (readonly) CGPoint bottomRight;
@end

/** @brief Conformance of  CIRectangleFeature to `IRLRectangleFeatureProtocol`  */
@interface CIRectangleFeature()<IRLRectangleFeatureProtocol>
@end

/** @brief Extending CIImage to provide some feature  */
@interface CIImage (Utilities)

/** @brief Image fradient
 @param threshold A float from 0 to 100 definining the gradient threshold
 @return a CIImage
 */
+ (CIImage * _Nonnull)imageGradientImage:(CGFloat)threshold;

/** @brief Build an image from a context
 @param context A context
 @return a UIImage
 */
- (UIImage* _Nonnull)makeUIImageWithContext:(CIContext* _Nonnull)context;

/**
 @return Corrected image based on device orinetaiton
 */
- (UIImage* _Nonnull)orientationCorrecterUIImage;

/**
 @param gradient The gradient to apply
 @return Filtered CIImage using Ultra Contrast With provided Gradient
 */
- (CIImage * _Nonnull)filteredImageUsingUltraContrastWithGradient:(CIImage * _Nonnull)gradient ;
/**
 @return Filtered CIImage using Enhance
 */
- (CIImage * _Nonnull)filteredImageUsingEnhanceFilter ;
/**
 @return Filtered CIImage using Contrast
 */
- (CIImage * _Nonnull)filteredImageUsingContrastFilter ;

/**
 @param margin the amoint of point to trim
 @return Cropped CIImage
 */
- (CIImage * _Nonnull)cropBordersWithMargin:(CGFloat)margin;

/**
 @param rectangleFeature A `IRLRectangleFeatureProtocol` feature
 @return Cropped Corrected CIImage image
 */
- (CIImage * _Nonnull)correctPerspectiveWithFeatures:(id<IRLRectangleFeatureProtocol> _Nonnull)rectangleFeature;

/**
 @param color to Draw on top of the image (if you want to see the image, add Alpha)
 @param rectangle A `IRLRectangleFeatureProtocol` feature
 @return Overlay Corrected CIImage image
*/
- (CIImage * _Nonnull)drawHighlightOverlayWithcolor:(UIColor* _Nonnull)color CIRectangleFeature:(id<IRLRectangleFeatureProtocol> _Nonnull)rectangle;

/**
 @param color to Draw on top of the image (if you want to see the image, add Alpha)
 @param point to Draw in the center of the image
 @return Overlay Corrected CIImage image
 */
- (CIImage * _Nonnull)drawCenterOverlayWithColor:(UIColor* _Nonnull)color point:(CGPoint)point;

/**
 @param color to Draw on top of the image (if you want to see the image, add Alpha)
 @param point to Draw in the center of the image
 @param amplitude The Amplitude of the rectangle
 @return Overlay Corrected CIImage image
 */
- (CIImage * _Nonnull)drawFocusOverlayWithColor:(UIColor* _Nonnull)color point:(CGPoint)point amplitude:(CGFloat)amplitude;

@end

/** @brief Extending CIFeature*/
@interface IRLRectangleFeature : CIFeature <IRLRectangleFeatureProtocol>
/** @return Top Left corner of rectangle Feature  */
@property (readwrite) CGPoint topLeft;
/** @return Top Right corner of rectangle Feature  */
@property (readwrite) CGPoint topRight;
/** @return Bottom Left corner of rectangle Feature  */
@property (readwrite) CGPoint bottomLeft;
/** @return Bottom Right corner of rectangle Feature  */
@property (readwrite) CGPoint bottomRight;
@end


