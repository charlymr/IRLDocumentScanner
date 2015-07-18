//
//  CIRectangleFeature+Utilities.m
//
//  Modified by Denis Martin on 12/07/2015
//  Based on IPDFCameraViewController: https://github.com/mmackh/IPDFCameraViewController/tree/master/IPDFCameraViewController
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

#import "CIRectangleFeature+Utilities.h"

@implementation CIFeature (Utilities)

+ (CGFloat)polygoneArea:(NSArray*)arrayOfvalueWithCGPoint {
    
    CGFloat     n           = arrayOfvalueWithCGPoint.count;
    CGFloat     area        = 0;            // Accumulates area in the loop
    
    for (NSUInteger i=0; i < n-1; i++)
        
    {
        CGPoint pointI      = [arrayOfvalueWithCGPoint[i] CGPointValue];
        CGPoint pointIp1    = [arrayOfvalueWithCGPoint[i+1] CGPointValue];
        
        CGFloat Xip1 = pointIp1.x;
        CGFloat Xi   = pointI.x;
        CGFloat Yip1 = pointIp1.y;
        CGFloat Yi   = pointI.y;
        
        area = area +  (Xi * Yip1 - Xip1 * Yi);
        
    }
    
    return area / 2.0f;
}

+ (CGPoint)centroid:(NSArray*)arrayOfvalueWithCGPoint {
    
    CGFloat     area        = [self polygoneArea:arrayOfvalueWithCGPoint];
    CGFloat     n           = arrayOfvalueWithCGPoint.count;
    CGFloat     Cx          = 0;            // Accumulates X
    CGFloat     Cy          = 0;            // Accumulates Y
    
    for (NSUInteger i=0; i < n-1; i++)
    {
        CGPoint pointI      = [arrayOfvalueWithCGPoint[i]   CGPointValue];
        CGPoint pointIp1    = [arrayOfvalueWithCGPoint[i+1] CGPointValue];
        
        CGFloat Xip1 = pointIp1.x;
        CGFloat Xi   = pointI.x;
        CGFloat Yip1 = pointIp1.y;
        CGFloat Yi   = pointI.y;
        
        Cx = Cx +  ( Xi + Xip1)  * ( Xi * Yip1 -  Xip1 * Yi );
        Cy = Cy +  ( Yi + Yip1)  * ( Xi * Yip1 -  Xip1 * Yi );
        
    }
    
    return CGPointMake( Cx / (6.0f * area) , Cy / (6.0f * area));
}

@end

@implementation CIRectangleFeature (Utilities)

#pragma mark - Private Getter

- (NSArray*)allPoints {
    return @[
             [NSValue valueWithCGPoint:self.topLeft],
             [NSValue valueWithCGPoint:self.topRight],
             [NSValue valueWithCGPoint:self.bottomRight],
             [NSValue valueWithCGPoint:self.bottomLeft],
             [NSValue valueWithCGPoint:self.topLeft]
             ];
}

#pragma mark - Getters

- (CGFloat)signedArea  {
    return [CIRectangleFeature polygoneArea:[self allPoints]];
    
}

- (CGPoint)centroid {
    return [CIRectangleFeature centroid:[self allPoints]];
}

- (CGPoint)computedCenter {
    
    CGFloat     n   = self.allPoints.count;
    CGFloat     Cx          = 0;            // Accumulates X
    CGFloat     Cy          = 0;            // Accumulates Y
    
    for (NSUInteger i=0; i< n-1; i++)
    {
        CGPoint point = [self.allPoints[i] CGPointValue];
        CGFloat Xi = point.x;
        CGFloat Yi = point.y;
        Cx = Cx +  Xi ;
        Cy = Cy +  Yi;
        
    }
    
    return CGPointMake(Cx / (n-1), Cy / (n-1));
}

+ (CIRectangleFeature *)biggestRectangleInRectangles:(NSArray *)rectangles {
    
    if (![rectangles count]) return nil;
    
    float halfPerimiterValue = 0;
    
    CIRectangleFeature *biggestRectangle = [rectangles firstObject];
    
    for (CIRectangleFeature *rect in rectangles)
    {
        CGFloat currentHalfPerimiterValue =[self halfPerimiterValue:rect];
        if (halfPerimiterValue < currentHalfPerimiterValue)
        {
            halfPerimiterValue = currentHalfPerimiterValue;
            biggestRectangle = rect;
        }
    }
    
    return biggestRectangle;
}

#pragma mark - Private

+ (CGFloat)distanceFrom:(CGPoint)point1 to:(CGPoint)point2 {
    CGFloat xDist = (point2.x - point1.x);
    CGFloat yDist = (point2.y - point1.y);
    return sqrt((xDist * xDist) + (yDist * yDist));
}

+ (CGFloat)halfPerimiterValue:(CIRectangleFeature*)rect {
    
    CGPoint p1 = rect.topLeft;
    CGPoint p2 = rect.topRight;
    CGFloat width = hypotf(p1.x - p2.x, p1.y - p2.y);
    
    CGPoint p3 = rect.topLeft;
    CGPoint p4 = rect.bottomLeft;
    CGFloat height = hypotf(p3.x - p4.x, p3.y - p4.y);
    
    return height + width;
}

@end
