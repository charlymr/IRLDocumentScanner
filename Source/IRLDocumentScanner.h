//
//  IRLScanner.h
//  Pods
//
//  Created by Denis Martin on 12/07/2015.
//
//  This code is based on the following project by Maximilian Mackh
//  Based on https://github.com/mmackh/IPDFCameraViewController
//

#import <Availability.h>

#ifndef __IPHONE_8_4
#warning "This project uses features only available in iPhone SDK 8.4 and later."
#endif

// Version
#define IRLDOCUMENTSCANNER_VERSION       @"0.3.1"

// iOS Framework
#ifdef __OBJC__
@import UIKit;
@import CoreImage;
@import AVFoundation;
@import GLKit;
#endif

// All-in-one Scanner
#import "CIImage+Utilities.h"
#import "CIRectangleFeature+Utilities.h"
