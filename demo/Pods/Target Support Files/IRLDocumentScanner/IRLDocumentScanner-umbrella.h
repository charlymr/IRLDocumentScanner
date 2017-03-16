#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CIImage+Utilities.h"
#import "CIRectangleFeature+Utilities.h"
#import "IRLDocumentScanner-Bridging-Header.h"
#import "IRLDocumentScanner.h"

FOUNDATION_EXPORT double IRLDocumentScannerVersionNumber;
FOUNDATION_EXPORT const unsigned char IRLDocumentScannerVersionString[];

