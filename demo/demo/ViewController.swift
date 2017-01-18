//
//  ViewController.swift
//  demo
//
//  Created by Denis Martin on 28/06/2015.
//  Copyright (c) 2015 iRLMobile. All rights reserved.
//

import UIKit
import IRLDocumentScanner


class ViewController: UIViewController {

    @IBOutlet weak var imageView:  UIImageView!

	lazy var cameraView: IRLCameraView = {
		return IRLCameraView(frame: CGRect(x: 0, y: 84, width: UIScreen.main.bounds.size.width, height: 500))
	}()

	public lazy var instructionsLabel: UILabel = {
		let label = UILabel(frame: CGRect(x: 0, y: self.view.bounds.height - 60, width: self.view.bounds.width, height: 48))
		label.textColor = .black
		label.textAlignment = .center
		return label
	}()
    
    // MARK: User Actions

    @IBAction func scan(_ sender: AnyObject) {
		/*
		let scanner = IRLScannerViewController.cameraView(withDefaultType: .normal,
		                                                  defaultDetectorType: IRLScannerDetectorType.performance, with: self)
        scanner.showControls = false
        scanner.showAutoFocusWhiteRectangle = false
        present(scanner, animated: true, completion: nil)
		*/
    }

	override func viewDidLoad() {
		super.viewDidLoad()

		view.addSubview(cameraView)
		cameraView.setupCameraView()
		cameraView.delegate = self
		cameraView.overlayColor = .blue
		cameraView.detectorType = .performance
		cameraView.cameraViewType = .normal
		cameraView.isShowAutoFocusEnabled = true
		cameraView.isBorderDetectionEnabled = true

		view.addSubview(instructionsLabel)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		cameraView.start()
	}
}

// MARK: IRLCameraViewProtocol

extension ViewController: IRLCameraViewDelegate {

	func didDetectRectangle(view: IRLCameraView, with confidence: Int) {
		print("didDetectRectangle withConfidence \(confidence)")

		switch confidence > 40 {
		case true:
			instructionsLabel.text = "Hold Still"
		case false:
			instructionsLabel.text = nil
		}
	}

	func didGainFullDetectionConfidence(view: IRLCameraView) {
		print("didGainFullDetectionConfidence")

		//imageView.image = view.latestCorrectedUIImage()

		view.captureImage { [weak self](image: UIImage?) in
			self?.imageView.image = image
			view.stop()
		}
	}

	func didLoseConfidence(view: IRLCameraView) {
		instructionsLabel.text = nil
	}
}
