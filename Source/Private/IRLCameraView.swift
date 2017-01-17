//
//  IRLCameraView.swift
//  Pods
//
//  Created by Cody Winton on 1/16/17.
//
//

// MARK: Imports

import AVFoundation
import CoreImage
import GLKit
import UIKit

import ImageIO

// MARK: Protocol

public protocol IRLCameraViewDelegate: class {
	func didDetectRectangle(view: IRLCameraView, with confidence: Int)
	func didGainFullDetectionConfidence(view: IRLCameraView)
	func didLoseConfidence(view: IRLCameraView)
}

// MARK: Enums

public enum IRLScannerViewType: Int {
	case normal, blackAndWhite, ultraContrast
}

public enum IRLScannerDetectorType: Int {
	case accuracy, performance
}

// MARK: -

final public class IRLCameraView: UIView {

	// MARK: - Public Variables

	public weak var delegate: IRLCameraViewDelegate?

	public var detectorType: IRLScannerDetectorType = .accuracy

	public var isBorderDetectionEnabled: Bool = false
	public var isDrawCenterEnabled: Bool = false
	public var isShowAutoFocusEnabled: Bool = false

	public var minimumConfidenceForFullDetection: Int = 66 {
		didSet {
			if minimumConfidenceForFullDetection > 100 {
				minimumConfidenceForFullDetection = 100
			}
		}
	}
	public var maximumConfidenceForFullDetection: Int = 100

	public var overlayColor: UIColor = .white

	public var latestCorrectedImage: UIImage? {
		return latestCorrectedCIImage.makeUIImage(with: coreImageContext)
	}

	public var isTorchEnabled: Bool = false {
		didSet {
			guard hasFlash else { return }

			do {
				try captureDevice.lockForConfiguration()

				switch isTorchEnabled {
				case true:
					captureDevice.torchMode = .on
				case false:
					captureDevice.flashMode = .off
				}

				captureDevice.unlockForConfiguration()

			} catch {
				print("error \(error)")
			}
		}
	}

	public var cameraViewType: IRLScannerViewType = .normal {
		didSet {
			let effect = UIBlurEffect(style: .dark)
			let viewWithBlur = UIVisualEffectView(effect: effect)

			viewWithBlur.frame = bounds
			insertSubview(viewWithBlur, aboveSubview: glkView)

			viewWithBlur.alpha = 0

			UIView.animate(withDuration: 0.1) { 
				viewWithBlur.alpha = 1
			}

			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { 
				UIView.animate(withDuration: 0.1) {
					viewWithBlur.alpha = 0
					viewWithBlur.removeFromSuperview()
				}
			}
		}
	}

	public var hasFlash: Bool {
		return captureDevice.hasTorch && captureDevice.hasFlash
	}

	// MARK: Variables

	fileprivate var isStopped: Bool = false
	fileprivate var borderDetectFrame: Bool = false
	fileprivate var focusCurrentRectangleDone: Bool = false
	fileprivate var didNotifyFullConfidence: Bool = false
	fileprivate var isCapturing: Bool = false
	fileprivate var isCurrentlyFocusing: Bool = false
	fileprivate var forceStop: Bool = false

	fileprivate var imageDedectionConfidence: CGFloat = 0
	fileprivate var borderDetectTimeKeeper: Timer?

	fileprivate var borderDetectLastRectangleFeature: CIRectangleFeature!

	fileprivate var glkView: GLKView!
	fileprivate var renderBuffer = GLuint()
	fileprivate var coreImageContext: CIContext!

	fileprivate var captureSession: AVCaptureSession!
	fileprivate var captureDevice: AVCaptureDevice!
	fileprivate var stillImageOutput: AVCaptureStillImageOutput!

	fileprivate var context: EAGLContext!

	fileprivate var gradient: CIImage!

	fileprivate var latestCorrectedCIImage: CIImage!
	fileprivate var transitionSnapsot: UIImageView!

	fileprivate var rectangleDetectionConfidenceHighEnough: Bool {
		return imageDedectionConfidence > 1.0
	}

	fileprivate var videoOrientationFromCurrentDeviceOrientation: AVCaptureVideoOrientation {
		switch UIApplication.shared.statusBarOrientation {
		case .landscapeLeft: return .landscapeLeft
		case .landscapeRight: return .landscapeRight
		case .portraitUpsideDown: return .portraitUpsideDown
		case .portrait, .unknown: return .portrait
		}
	}

	fileprivate var imageOrientationForCurrentDeviceOrientation: UIImageOrientation {
		switch UIApplication.shared.statusBarOrientation {
		case .portrait: return .right
		case .landscapeLeft: return .down
		case .landscapeRight: return .up
		case .portraitUpsideDown: return .left
		case .unknown: return .up
		}
	}

	fileprivate func imagePropertyOrientation(for orientation: UIImageOrientation) -> CGImagePropertyOrientation {
		switch orientation {
		case .up: return .up
		case .upMirrored: return .upMirrored
		case .down: return .down
		case .downMirrored: return .downMirrored
		case .leftMirrored: return .leftMirrored
		case .right: return .right
		case .rightMirrored: return .rightMirrored
		case .left: return .left
		}
	}

	private let performanceDetector: CIDetector? = {
		let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyLow,
		                              CIDetectorAspectRatio: 1,
		                              CIDetectorMinFeatureSize: 0.38] //CIDetectorTracking: true]
		return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)
	}()

	private let accuracyDetector: CIDetector? = {
		let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh,
		                              CIDetectorAspectRatio: 1,
		                              CIDetectorMinFeatureSize: 0.38] //CIDetectorTracking: true]
		return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)
	}()

	fileprivate var detector: CIDetector? {
		switch detectorType {
		case .accuracy:
			return accuracyDetector
		case .performance:
			return performanceDetector
		}
	}

	// MARK: Inits

	init() {
		super.init(frame: .zero)

		let center: NotificationCenter = .default
		center.addObserver(self, selector: #selector(backgroundMode), name: .UIApplicationWillResignActive, object: nil)
		center.addObserver(self, selector: #selector(foregroundMode), name: .UIApplicationDidBecomeActive, object: nil)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}




	// MARK: - Public Functions

	public func setupCameraView() {

		let possibleDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
		guard let device = possibleDevices?.first as? AVCaptureDevice else { return }

		imageDedectionConfidence = 0

		let session = AVCaptureSession()
		session.beginConfiguration()

		captureDevice = device

		let input: AVCaptureDeviceInput? = try? AVCaptureDeviceInput(device: device)
		session.sessionPreset = AVCaptureSessionPresetPhoto
		session.addInput(input)

		let dataOutput = AVCaptureVideoDataOutput()
		dataOutput.alwaysDiscardsLateVideoFrames = true
		dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_32BGRA]

		let queue = DispatchQueue(label: "ScanSampleBufferQueue")
		dataOutput.setSampleBufferDelegate(self, queue: queue)
		session.addOutput(dataOutput)

		createGLKView()

		let imgOutput = AVCaptureStillImageOutput()
		session.addOutput(imgOutput)
		stillImageOutput = imgOutput

		guard let connection = dataOutput.connections.first as? AVCaptureConnection else { return }
		connection.videoOrientation = videoOrientationFromCurrentDeviceOrientation

		do {

			try device.lockForConfiguration()

			if device.isFocusModeSupported(.continuousAutoFocus) {
				device.focusMode = .continuousAutoFocus
			}

			if device.isExposureModeSupported(.continuousAutoExposure) {
				device.exposureMode = .continuousAutoExposure
			}

			if device.isFlashAvailable {
				device.focusMode = .continuousAutoFocus
			}

			device.unlockForConfiguration()
		} catch {
			print("error: \(error)")
		}

		session.commitConfiguration()
		captureSession = session
	}

	public func start() {

		if gradient == nil {
			gradient = CIImage(gradientImage: 0.3)
		}

		isStopped = false
		isCapturing = false

		captureSession.startRunning()

		borderDetectTimeKeeper = Timer.scheduledTimer(timeInterval: 0.5, target: self,
		                                              selector: #selector(enableBorderDetectFrame), userInfo: nil, repeats: true)
		hideGLKView(hidden: false, completion: nil)
	}

	public func stop() {
		isStopped = true
		captureSession.stopRunning()

		borderDetectTimeKeeper?.invalidate()
		hideGLKView(hidden: true, completion: nil)
	}

	public func focus(at point: CGPoint, completion: () -> Void) {
		var frameSize = bounds.size
		var pointOfInterest = CGPoint(x: point.y / frameSize.height, y: 1 - (point.x / frameSize.width))
		focus(with: pointOfInterest, completion: completion)
	}

	public func captureImage(with completion: (_ image: UIImage?) -> Void) {
		completion(nil)
	}

	// MARK: Functions

	func prepareForOrientationChange() {

	}

	func finishedOrientationChange() {

	}

	func enableBorderDetectFrame() {
		borderDetectFrame = true
	}

	func backgroundMode() {
		forceStop = true
	}

	func foregroundMode() {
		forceStop = false
	}

	func hideGLKView(hidden: Bool, completion: (() -> Void)?) {
		UIView.animate(withDuration: 0.1, animations: { 
			self.glkView?.alpha = hidden ? 0 : 1
		}) { (_) in
			completion?()
		}
	}

	func createGLKView() {
		guard context == nil else { return }

		context = EAGLContext(api: .openGLES2)

		let view = GLKView(frame: bounds)
		view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		view.translatesAutoresizingMaskIntoConstraints = true
		view.context = context
		view.contentScaleFactor = 1
		view.drawableDepthFormat = .format24
		insertSubview(view, at: 0)

		glkView = view

		withUnsafeMutablePointer(to: &renderBuffer) {
			(pointer) in

			glGenRenderbuffers(1, pointer)
			glBindRenderbuffer(GLenum(GL_RENDERBUFFER), self.renderBuffer)
			self.coreImageContext = CIContext(eaglContext: self.context)
			EAGLContext.setCurrent(self.context)
		}
	}

	func focus(with pointOfInterest: CGPoint, completion: () -> Void) {

		guard captureDevice.isFocusPointOfInterestSupported && captureDevice.isFocusModeSupported(.autoFocus) else {
			completion()
			return
		}

		do {
			try captureDevice.lockForConfiguration()

			if captureDevice.isFocusModeSupported(.continuousAutoFocus) {
				captureDevice.focusMode = .continuousAutoFocus
				captureDevice.focusPointOfInterest = pointOfInterest
			}

			if captureDevice.isExposurePointOfInterestSupported && captureDevice.isExposureModeSupported(.continuousAutoExposure) {
				captureDevice.exposurePointOfInterest = pointOfInterest
				captureDevice.exposureMode = .continuousAutoExposure
			}

			captureDevice.unlockForConfiguration()

		} catch {
			print("error: \(error)")
		}
	}

	func makeUIImage(from ciImage: CIImage) -> UIImage? {
		let context = CIContext(options: nil)
		guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
		let image = UIImage(cgImage: cgImage)
		return image
	}
}

extension IRLCameraView: AVCaptureVideoDataOutputSampleBufferDelegate {

	public func captureOutput(_ captureOutput: AVCaptureOutput!,
	                          didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {

		/*
		if (self.forceStop) return;
		if (_isStopped || self.isCapturing || !CMSampleBufferIsValid(sampleBuffer)) return;

		__weak  typeof(self) weakSelf = self;

		// Get The Pixel Buffer here
		CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);

		// First we Capture the Image
		CIImage *image = [CIImage imageWithCVPixelBuffer:pixelBuffer];

		switch (self.cameraViewType) {
		case IRLScannerViewTypeBlackAndWhite:        image = [image filteredImageUsingEnhanceFilter];
		break;
		case IRLScannerViewTypeNormal:               //image = [image filteredImageUsingContrastFilter];
			break;
		case IRLScannerViewTypeUltraContrast:        image = [image filteredImageUsingUltraContrastWithGradient:self.gradient ];
		break;
		default:
			break;
		}

		if (self.isBorderDetectionEnabled) {

			// Get The current Confidence
			NSUInteger confidence   =  _imageDedectionConfidence;
			confidence = confidence > 100 ? 100 : confidence;

			// Fix the last rectangle detected
			if (_borderDetectFrame && confidence < self.minimumConfidenceForFullDetection) {
				NSArray *rectangles = [self.detector featuresInImage:image];
				_borderDetectLastRectangleFeature = [CIRectangleFeature biggestRectangleInRectangles:rectangles];
				_borderDetectFrame = NO;
			}

			// Create teh Overlay
			if (_borderDetectLastRectangleFeature) {

				// Notify Our Delegate eventually
				if ([self.delegate respondsToSelector:@selector(didDetectRectangle:withConfidence:)]) {

					dispatch_async(dispatch_get_main_queue(), ^{
						[weakSelf.delegate didDetectRectangle:weakSelf withConfidence:confidence];
						});

					if (confidence > 98 && [self.delegate respondsToSelector:@selector(didGainFullDetectionConfidence:)] && self.didNotifyFullConfidence == NO) {

						self.didNotifyFullConfidence = YES;
						dispatch_async(dispatch_get_main_queue(), ^{
							[weakSelf.delegate didGainFullDetectionConfidence:weakSelf];
							});

						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0f *NSEC_PER_SEC), dispatch_get_main_queue(), ^{
							weakSelf.didNotifyFullConfidence = NO;
							});
					}
				}

				_imageDedectionConfidence += 1.0f;

				CGFloat alpha    = 0.1f;
				if (_imageDedectionConfidence > 0.0f) {
					alpha = _imageDedectionConfidence / 100.0f;
					alpha = alpha > 0.8f ? 0.8f : alpha;
				}

				// Keep Ref to the latest corrected Image:
				self.latestCorrectedImage = [image correctPerspectiveWithFeatures:_borderDetectLastRectangleFeature];

				// Draw OverLay
				image = [image drawHighlightOverlayWithcolor:[self.overlayColor colorWithAlphaComponent:alpha] CIRectangleFeature:_borderDetectLastRectangleFeature];

				// Draw Center
				if(self.enableDrawCenter) image = [image drawCenterOverlayWithColor:[UIColor redColor] point:_borderDetectLastRectangleFeature.centroid];

				// Draw Overlay Focus
				CGFloat amplitude = _borderDetectLastRectangleFeature.bounds.size.width / 4.0f;
				if(self.isCurrentlyFocusing && self.enableShowAutoFocus) image = [image drawFocusOverlayWithColor:[UIColor colorWithWhite:1.0f alpha:0.7f-alpha] point:_borderDetectLastRectangleFeature.centroid amplitude:amplitude*alpha];

				// Focus Image on center
				if (confidence > 50.0f && _FocusCurrentRectangleDone == NO)  {
					_FocusCurrentRectangleDone = YES;
					self.isCurrentlyFocusing = YES;

					[self focusAtPoint:_borderDetectLastRectangleFeature.centroid completionHandler:^{
						if (self.enableShowAutoFocus) {
						dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0f *NSEC_PER_SEC), dispatch_get_main_queue(), ^{
						self.isCurrentlyFocusing = NO;
						});
						}
						}];
				}
			}
			else {
				if ([self.delegate respondsToSelector:@selector(didLostConfidence:)]) {
					dispatch_async(dispatch_get_main_queue(), ^{
						[weakSelf.delegate didLostConfidence:self];
						});
				}
				_imageDedectionConfidence = 0.0f;
				_FocusCurrentRectangleDone = NO;
				self.isCurrentlyFocusing = NO;
			}

		}

		// Send the Resulting Image to the Sample Buffer
		if (self.context && _coreImageContext)
		{
			[_coreImageContext drawImage:image inRect:self.bounds fromRect:image.extent];
			[self.context presentRenderbuffer:GL_RENDERBUFFER];
			[_glkView setNeedsDisplay];
		}
		*/
	}
}





















