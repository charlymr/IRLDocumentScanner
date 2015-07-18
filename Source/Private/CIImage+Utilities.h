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

@interface CIImage (Utilities)

+ (CIImage *)imageGradientImage:(CGFloat)threshold;

- (UIImage*)makeUIImageWithContext:(CIContext*)context;
- (UIImage *)orientationCorrecterUIImage;


// Filters
- (CIImage *)filteredImageUsingUltraContrastWithGradient:(CIImage *)gradient ;
- (CIImage *)filteredImageUsingEnhanceFilter ;
- (CIImage *)filteredImageUsingContrastFilter ;

- (CIImage *)cropBordersWihtMargin:(CGFloat)margin;
- (CIImage *)correctPerspectiveWithFeatures:(CIRectangleFeature *)rectangleFeature;
- (CIImage *)drawHighlightOverlayWithcolor:(UIColor*)color CIRectangleFeature:(CIRectangleFeature*)rectangle;
- (CIImage *)drawCenterOverlayWithColor:(UIColor*)color point:(CGPoint)point;
- (CIImage *)drawFocusOverlayWithColor:(UIColor*)color point:(CGPoint)point amplitude:(CGFloat)amplitude;

@end
