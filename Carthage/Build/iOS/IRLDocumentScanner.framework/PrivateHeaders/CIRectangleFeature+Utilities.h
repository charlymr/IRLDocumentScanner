//
//  CIRectangleFeature+Utilities.h
//
//  Modified by Denis Martin on 12/07/2015
//  Based on IPDFCameraViewController: https://github.com/mmackh/IPDFCameraViewController/tree/master/IPDFCameraViewController
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

@import UIKit;
@import CoreImage;

// http://en.wikipedia.org/wiki/Centroid

@interface CIFeature (Utilities)
/**
@brief Helper method. Polygone. Cloackwise points... You must close the figure...
*/
+ (CGFloat)polygoneArea:(NSArray<NSValue*>  * _Nonnull )arrayOfvalueWithCGPoint;

/**
 @brief Helper method. Centroid. Cloackwise points... You must close the figure...
 */
+ (CGPoint)centroid:(NSArray<NSValue*> * _Nonnull )arrayOfvalueWithCGPoint;

@end

@interface CIRectangleFeature  (Utilities)

/**
 @brief Helper method to extract the buggest detected rectangel
 
 @param rectangles Array of CIRectangleFeature
 @return the Biggest CIRectangleFeature
 */
+ (CIRectangleFeature * _Nullable)biggestRectangleInRectangles:(NSArray< CIRectangleFeature* >* _Nonnull)rectangles;

/**
 @return all corner as NSValue uwrappabel with CGPointValue (topLeft, topRight, bottomRight, bottomLeft, topLeft)
*/
@property (readonly)        NSArray <NSValue*> * _Nonnull allPoints;

/**
 @return Retrun the polygone point
 */
@property (readonly)        CGFloat signedArea;

/**
 @return Retrun the centroid point
 */
@property (readonly)        CGPoint centroid;

/**
 @return Retrun the computedCenter point
 */
@property (readonly)        CGPoint computedCenter;

@end
