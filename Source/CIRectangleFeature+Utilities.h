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

+ (CGFloat)polygoneArea:(NSArray*)arrayOfvalueWithCGPoint; // Ordonnés sense des aiguille d'une montre... You must close the figure...

+ (CGPoint)centroid:(NSArray*)arrayOfvalueWithCGPoint;    //  Ordonnés sense des aiguille d'une montre... You must close the figure...

@end

@interface CIRectangleFeature  (Utilities)

+ (CIRectangleFeature *)biggestRectangleInRectangles:(NSArray *)rectangles;

// Return all corner as NSValue uwrappabel with CGPointValue (topLeft, topRight, bottomRight, bottomLeft, topLeft)
@property (readonly)        NSArray *allPoints;

@property (readonly)        CGFloat signedArea;

@property (readonly)        CGPoint centroid;

@property (readonly)        CGPoint computedCenter;

@end
