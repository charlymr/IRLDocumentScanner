//
//  ViewController.swift
//  demo
//
//  Created by Denis Martin on 28/06/2015.
//  Copyright (c) 2015 iRLMobile. All rights reserved.
//

import UIKit

class ViewController : UIViewController, IRLScannerViewControllerDelegate {
    
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var imageView:  UIImageView!
    
    // MARK: User Actions

    @IBAction func scan(sender: AnyObject) {
        let scanner = IRLScannerViewController.standardCameraViewWithDelegate(self)
        scanner.showControls = true
        scanner.showAutoFocusWhiteRectangle = true
        presentViewController(scanner, animated: true, completion: nil)
    }
    
    // MARK: IRLScannerViewControllerDelegate
    
    func pageSnapped(page_image: UIImage, from controller: IRLScannerViewController) {
        controller.dismissViewControllerAnimated(true) { () -> Void in
            self.imageView.image = page_image
        }
    }
    
    func cameraViewCancelRequested(cameraView: IRLScannerViewController) {
        cameraView.dismissViewControllerAnimated(true) {}

    }
    
    func cameraViewWillUpdateTitleLabel(cameraView: IRLScannerViewController) -> String? {
        
        var text = ""
        switch cameraView.cameraViewType {
        case .Normal:           text = text + "NORMAL"
        case .BlackAndWhite:    text = text + "B/W-FILTER"
        case .UltraContrast:    text = text + "CONTRAST"
        }
        
        switch cameraView.detectorType {
        case .Accuracy:         text = text + " | Accuracy"
        case .Performance:      text = text + " | Performance"
        }
        
        return text
    }
    
}