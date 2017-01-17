//
//  IRLCameraView.m
//
//  Modified by Denis Martin on 12/07/2015
//  Copyright (c) 2015 mackh ag. All rights reserved.
//

@implementation IRLCameraView




#pragma mark -
#pragma mark Setup

- (void)createSnapshot {

	if (_glkView == nil) {
		return;
	}

	// Snopshot
	UIImageView *view = [[UIImageView alloc] initWithFrame:self.bounds];
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	view.translatesAutoresizingMaskIntoConstraints = YES;
	view.contentMode = UIViewContentModeScaleAspectFill;
	view.image = [_glkView snapshot] ;
	self.transitionSnapsot = view;

	[self insertSubview:view atIndex:0];
}

- (void)prepareForOrientationChange {
	[self createSnapshot];
	[self stop];
	[self removeGLKView];
}

- (void)finishedOrientationChange {
	[self setupCameraView];
	[self start];

	// We must bring it to the front as our GLView was create and insert at index 0
	[self bringSubviewToFront:self.transitionSnapsot];

	// Animat the fade out
	__weak typeof(self) weakSelf = self;
	[UIView animateWithDuration:0.3 animations:^{
		weakSelf.transitionSnapsot.alpha = 0;
	} completion:^(BOOL finished) {
		[weakSelf.transitionSnapsot removeFromSuperview];
	}];
}

- (void)removeGLKView {
	[_glkView removeFromSuperview];
	_glkView = nil;
	_coreImageContext = nil;
	self.context = nil;
}


#pragma mark -
#pragma mark Instance Methods Public


- (void)captureImageWithCompletionHander:(void(^)(UIImage* image))completionHandler {

	if (self.isCapturing || self.window == nil) return;

	__weak typeof(self) weakSelf = self;

	self.isCapturing = YES;

	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
		for (AVCaptureInputPort *port in [connection inputPorts])
		{
			if ([[port mediaType] isEqual:AVMediaTypeVideo] )
			{
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) break;
	}

	[self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
		NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
		UIImage *finalImage;

		if (weakSelf.isBorderDetectionEnabled) {
			// The original code worked great in iOS 9. iOS10 created all sorts of problems which were fixed, but iOS 9 can't seem to use them.
			BOOL isiOS10OrLater = [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){.majorVersion = 10, .minorVersion = 0, .patchVersion = 0}];

			CIImage *enhancedImage = [[CIImage alloc] initWithData:imageData];

			if (isiOS10OrLater) {
				// match the orientation of the image to the device
				enhancedImage = [enhancedImage imageByApplyingOrientation:imagePropertyOrientationForUIImageOrientation(imageOrientationForCurrentDeviceOrientation())];
			}

			// perform any filters
			switch (self.cameraViewType) {
				case IRLScannerViewTypeBlackAndWhite:
					enhancedImage = [enhancedImage filteredImageUsingEnhanceFilter];
					break;
				case IRLScannerViewTypeNormal:
					//enhancedImage = [enhancedImage filteredImageUsingContrastFilter];
					break;
				case IRLScannerViewTypeUltraContrast:
					enhancedImage = [enhancedImage filteredImageUsingUltraContrastWithGradient:weakSelf.gradient];
					break;
				default:
					break;
			}

			// crop and correct perspective
			if (rectangleDetectionConfidenceHighEnough(_imageDedectionConfidence)) {
				CIRectangleFeature *rectangleFeature = [CIRectangleFeature biggestRectangleInRectangles:[[weakSelf detector] featuresInImage:enhancedImage]];

				if (rectangleFeature) {
					enhancedImage = [enhancedImage correctPerspectiveWithFeatures:rectangleFeature];
				}
			}

			enhancedImage = [enhancedImage cropBordersWithMargin:40.0f];

			if (isiOS10OrLater) {
				finalImage = makeUIImageFromCIImage(enhancedImage);
			}
			else {
				finalImage = [enhancedImage orientationCorrecterUIImage];
			}
		}
		else {
			finalImage = [[UIImage alloc] initWithData:imageData];
		}

		[weakSelf hideGLKView:NO completion:nil];

		if (completionHandler) completionHandler(finalImage);

		[self stop];
	}];
}





@end
