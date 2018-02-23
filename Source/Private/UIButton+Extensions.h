//
//  IRLScannerViewController.h
//
//  Created by Denis Martin on 23/02/2018.
//  Copyright (c) 2015 Denis Martin. All rights reserved.
//

@import Foundation;
@import UIKit;

/**
 @brief UIButton utlitity
 */
@interface UIButton (HitTestEdgeInsetsExtensions)

/**
 @brief You can increase/reduce the hit detection radius of a button with this method.
 
 To increase the radius you should pass Negative values, to reduce pass positive values.
 
 @warning Use at your ow risk, do not increase the size too much and be aware of the button surrounding
 
 @return hitTestEdgeInsets The current hitTestEdgeInsets.
 */
@property(nonatomic, assign) UIEdgeInsets hitTestEdgeInsets;

@end
