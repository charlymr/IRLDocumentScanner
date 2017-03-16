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
	func didDetectRectangle(_ view: IRLCameraView, with confidence: Int)
	func didGainFullDetectionConfidence(_ view: IRLCameraView, with image: UIImage?)
	func didLoseConfidence(_ view: IRLCameraView)
}

// MARK: Enums

public enum IRLScannerViewType: Int {
	case normal, blackAndWhite, ultraContrast
}

public enum IRLScannerDetectorType: Int {
	case accuracy, performance

	var confidenceSpeed: Int {
		switch self {
		case .accuracy:
			return 1
		case .performance:
			return  3
		}
	}
}

// MARK: -

final public class IRLCameraView: UIView {

	// MARK: - Public Variables

	public weak var delegate: IRLCameraViewDelegate?

	public var detectorType: IRLScannerDetectorType = .accuracy

	public var isBorderDetectionEnabled: Bool = false
	public var isDrawCenterEnabled: Bool = false
	public var isShowAutoFocusEnabled: Bool = false

	public var overlayColor: UIColor = .white

	public var isTorchEnabled: Bool = false {
		didSet {
			guard hasFlash else { return }

			do {
				try captureDevice?.lockForConfiguration()

				switch isTorchEnabled {
				case true:
					captureDevice?.torchMode = .on
				case false:
					captureDevice?.torchMode = .off
				}

				captureDevice?.unlockForConfiguration()

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
			if let view = glkView {
				insertSubview(viewWithBlur, aboveSubview: view)
			}

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
		guard let device = captureDevice else { return false }
		return device.hasTorch && device.hasFlash
	}

	// MARK: Variables

	fileprivate var isStopped: Bool = false
	fileprivate var borderDetectFrame: Bool = false
	fileprivate var didNotifyFullConfidence: Bool = false
	fileprivate var isCapturing: Bool = false
	fileprivate var isCurrentlyFocusing: Bool = false
	fileprivate var forceStop: Bool = false

	fileprivate var imageDedectionConfidence: Int = 0
	fileprivate var maximumConfidenceForFullDetection: Int = 100
	fileprivate var borderDetectTimeKeeper: Timer?

	fileprivate var borderDetectLastRectangleFeature: CIRectangleFeature?

	fileprivate var glkView: GLKView?
	fileprivate var renderBuffer = GLuint()
	fileprivate var coreImageContext: CIContext?

	fileprivate var captureSession: AVCaptureSession?
	fileprivate var captureDevice: AVCaptureDevice?
	fileprivate var stillImageOutput: AVCaptureStillImageOutput?

	fileprivate var context: EAGLContext?

	fileprivate let gradient: CIImage = CIImage(gradientImage: 0.3)

	fileprivate var latestCorrectedCIImage: CIImage?
	fileprivate lazy var transitionSnapsot: UIImageView = {
		let imageView = UIImageView(frame: self.bounds)
		imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		imageView.translatesAutoresizingMaskIntoConstraints = true
		imageView.contentMode = .scaleAspectFill

		return imageView
	}()

	fileprivate var rectangleDetectionConfidenceHighEnough: Bool {
		return imageDedectionConfidence > 1
	}

	fileprivate var isiOS10OrLater: Bool {
		let version = OperatingSystemVersion(majorVersion: 10, minorVersion: 0, patchVersion: 0)
		return ProcessInfo.processInfo.isOperatingSystemAtLeast(version)
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

	fileprivate func imagePropertyOrientation(for orientation: UIImageOrientation) -> Int32 {

		let propOrientation: CGImagePropertyOrientation

		switch orientation {
		case .up: propOrientation = .up
		case .upMirrored: propOrientation = .upMirrored
		case .down: propOrientation = .down
		case .downMirrored: propOrientation = .downMirrored
		case .leftMirrored: propOrientation = .leftMirrored
		case .right: propOrientation = .right
		case .rightMirrored: propOrientation = .rightMirrored
		case .left: propOrientation = .left
		}

		return Int32(propOrientation.rawValue)
	}

	private let performanceDetector: CIDetector? = {
		let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyLow,
		                              CIDetectorAspectRatio: 1,
		                              CIDetectorMinFeatureSize: 0.35] //CIDetectorTracking: true]
		return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)
	}()

	private let accuracyDetector: CIDetector? = {
		let options: [String: Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh,
		                              CIDetectorAspectRatio: 1,
		                              CIDetectorMinFeatureSize: 0.35] //CIDetectorTracking: true]
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

	public override init(frame: CGRect) {
		super.init(frame: frame)

		let center: NotificationCenter = .default
		center.addObserver(self, selector: #selector(backgroundMode), name: .UIApplicationWillResignActive, object: nil)
		center.addObserver(self, selector: #selector(foregroundMode), name: .UIApplicationDidBecomeActive, object: nil)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(frame: .zero)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
		if(!isStopped){
			stop()
		}
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

		isStopped = false
		isCapturing = false

		captureSession?.startRunning()

		borderDetectTimeKeeper = Timer.scheduledTimer(timeInterval: 0.5, target: self,
		                                              selector: #selector(enableBorderDetectFrame), userInfo: nil, repeats: true)
		hideGLKView(hidden: false, completion: nil)
	}

	public func stop() {
		isStopped = true
		captureSession?.stopRunning()

		borderDetectTimeKeeper?.invalidate()
		hideGLKView(hidden: true, completion: nil)
	}

	public func focus(at point: CGPoint, completion: () -> Void) {
		var frameSize = bounds.size
		var pointOfInterest = CGPoint(x: point.y / frameSize.height, y: 1 - (point.x / frameSize.width))
		focus(with: pointOfInterest, completion: completion)
	}

	public func captureImage(with completion: @escaping (_ image: UIImage?) -> Void) {

		guard let output = stillImageOutput, let window = self.window, !isCapturing else { return }

		isCapturing = true

		var videoConnection: AVCaptureConnection?

		for connection in output.connections {
			guard let connection = connection as? AVCaptureConnection,
				let ports = connection.inputPorts as? [AVCaptureInputPort]
				else { continue }

			for port in ports {
				guard port.mediaType == AVMediaTypeVideo else { continue }
				videoConnection = connection
				break
			}

			guard videoConnection == nil else { break }
		}

		output.captureStillImageAsynchronously(from: videoConnection) { [weak self](imageSampleBuffer: CMSampleBuffer?, error) in

			var finalImage: UIImage?

			guard let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer), let sSelf = self else {
				completion(finalImage)
				return
			}

			guard sSelf.isBorderDetectionEnabled else {
				finalImage = UIImage(data: imageData)

				sSelf.hideGLKView(hidden: true, completion: nil)
				sSelf.stop()

				completion(finalImage)
				return
			}

			var enhancedImage = CIImage(data: imageData)

			if sSelf.isiOS10OrLater {
				enhancedImage = enhancedImage?.applyingOrientation(sSelf.imagePropertyOrientation(for: sSelf.imageOrientationForCurrentDeviceOrientation))
			}

			switch sSelf.cameraViewType {
			case .blackAndWhite:
				enhancedImage = enhancedImage?.filteredImageUsingEnhanceFilter()
			case .ultraContrast:
				enhancedImage = enhancedImage?.filteredImageUsingUltraContrast(withGradient: sSelf.gradient)
			case .normal: break
			}

			if let image = enhancedImage, sSelf.rectangleDetectionConfidenceHighEnough {
				if let rectangleFeature = CIRectangleFeature.biggestRectangle(inRectangles: sSelf.detector?.features(in: image)) {
					enhancedImage = enhancedImage?.correctPerspective(withFeatures: rectangleFeature)
				}
			}

			enhancedImage = enhancedImage?.cropBorders(withMargin: 20)

			switch sSelf.isiOS10OrLater {
			case true:
				finalImage = sSelf.makeUIImage(from: enhancedImage)
			case false:
				finalImage = enhancedImage?.orientationCorrecterUIImage()
			}

			sSelf.hideGLKView(hidden: true, completion: nil)
			sSelf.stop()

			completion(finalImage)
		}
	}

	// MARK: Functions

	func prepareForOrientationChange() {
		createSnapshot()
		stop()
		removeGLKView()
	}

	func finishedOrientationChange() {

		setupCameraView()
		start()

		transitionSnapsot.frame = bounds
		bringSubview(toFront: transitionSnapsot)

		UIView.animate(withDuration: 0.3, animations: {
			self.transitionSnapsot.alpha = 0
		}) { (_) in
			self.transitionSnapsot.removeFromSuperview()
		}
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
		guard self.context == nil, let context = EAGLContext(api: .openGLES2) else { return }

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
			self.coreImageContext = CIContext(eaglContext: context)
			EAGLContext.setCurrent(context)
		}

		self.context = context
	}

	func focus(with pointOfInterest: CGPoint, completion: () -> Void) {

		guard let device = captureDevice, device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) else {
			completion()
			return
		}

		do {
			try device.lockForConfiguration()

			if device.isFocusModeSupported(.continuousAutoFocus) {
				device.focusMode = .continuousAutoFocus
				device.focusPointOfInterest = pointOfInterest
			}

			if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.continuousAutoExposure) {
				device.exposurePointOfInterest = pointOfInterest
				device.exposureMode = .continuousAutoExposure
			}

			device.unlockForConfiguration()

		} catch {
			print("error: \(error)")
		}
	}

	func makeUIImage(from ciImage: CIImage?) -> UIImage? {
		guard let ciImage = ciImage else { return nil }
		let context = CIContext(options: nil)
		guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
		let image = UIImage(cgImage: cgImage)
		return image
	}

	func createSnapshot() {
		transitionSnapsot.image = glkView?.snapshot
		insertSubview(transitionSnapsot, at: 0)
	}

	func removeGLKView() {
		glkView?.removeFromSuperview()
		glkView = nil
		coreImageContext = nil
		context = nil
	}
}

extension IRLCameraView: AVCaptureVideoDataOutputSampleBufferDelegate {

	public func captureOutput(_ captureOutput: AVCaptureOutput!,
	                          didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {

		guard !forceStop && !isStopped && !isCapturing && CMSampleBufferIsValid(sampleBuffer) else { return }


		//__weak  typeof(self) weakSelf = self;

		guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

		var image = CIImage(cvPixelBuffer: pixelBuffer)

		switch cameraViewType {
		case .blackAndWhite:
			image = image.filteredImageUsingEnhanceFilter()
		case .ultraContrast:
			image = image.filteredImageUsingUltraContrast(withGradient: gradient)
		case .normal:
			break
		}

		guard isBorderDetectionEnabled else {
			guard let context = context, let imageContext = coreImageContext else { return }

			imageContext.draw(image, in: bounds, from: image.extent)
			context.presentRenderbuffer(Int(GL_RENDERBUFFER))
			glkView?.setNeedsDisplay()
			return
		}

		if borderDetectFrame {
			let rects = detector?.features(in: image)
			borderDetectLastRectangleFeature = CIRectangleFeature.biggestRectangle(inRectangles: rects)
			borderDetectFrame = false
		}

		switch borderDetectLastRectangleFeature {

		case nil:
			DispatchQueue.main.async {
				[weak self] in
				guard let sSelf = self else { return }
				sSelf.delegate?.didLoseConfidence(sSelf)
			}

			imageDedectionConfidence = 0
			isCurrentlyFocusing = false

		case let rectFeature?:

			imageDedectionConfidence += detectorType.confidenceSpeed
			imageDedectionConfidence = imageDedectionConfidence > 100 ? 100 : imageDedectionConfidence

			var alpha = CGFloat(imageDedectionConfidence) / 100
			alpha = alpha > 0.8 ? 0.8 : alpha

			latestCorrectedCIImage = image.correctPerspective(withFeatures: rectFeature)

			image = image.drawHighlightOverlayWithcolor(overlayColor.withAlphaComponent(alpha), ciRectangleFeature: rectFeature)

			if isDrawCenterEnabled {
				image = image.drawCenterOverlay(with: .white, point: rectFeature.centroid)
			}

			let amplitude: CGFloat = rectFeature.bounds.size.width / 4

			if isCurrentlyFocusing && isShowAutoFocusEnabled {
				image = image.drawFocusOverlay(with: UIColor.white.withAlphaComponent(0.7), point: rectFeature.centroid, amplitude: amplitude)
			}

			DispatchQueue.main.async {
				[weak self] in
				guard let sSelf = self else { return }
				sSelf.delegate?.didDetectRectangle(sSelf, with: sSelf.imageDedectionConfidence)
			}

			if imageDedectionConfidence >= 100 && !didNotifyFullConfidence {
				didNotifyFullConfidence = true

				captureImage() { (image: UIImage?) in
					DispatchQueue.main.async {
						[weak self] in
						guard let sSelf = self else { return }
						sSelf.delegate?.didGainFullDetectionConfidence(sSelf, with: image)
					}
				}

				DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
					[weak self] in
					self?.didNotifyFullConfidence = false
				}
			}
		}

		guard let context = context, let imageContext = coreImageContext else { return }

		imageContext.draw(image, in: bounds, from: image.extent)
		context.presentRenderbuffer(Int(GL_RENDERBUFFER))
		glkView?.setNeedsDisplay()
	}
}
