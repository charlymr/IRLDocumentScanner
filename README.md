![Demo](https://github.com/charlymr/IRLDocumentScanner/blob/master/Medias/iphone-scan.gif?raw=true)

# IRLDocumentScanner

IRLDocumentScanner is an Objective-C ViewController that will Automatically scan a document for you you.
**MINIMUM iOS REQUIREMENT: 8.0**

[![Build Status](https://travis-ci.org/charlymr/IRLDocumentScanner.svg?branch=master)](https://travis-ci.org/charlymr/IRLDocumentScanner)[![Version](https://img.shields.io/cocoapods/v/IRLDocumentScanner.svg?style=flat)](http://cocoapods.org/pods/IRLDocumentScanner)[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)[![Platform](https://img.shields.io/cocoapods/p/IRLDocumentScanner.svg?style=flat)](http://cocoapods.org/pods/IRLDocumentScanner)

![Screenshot](https://github.com/charlymr/IRLDocumentScanner/blob/master/Medias/scan.jpg?raw=true)

## Application plist requirement (iOS 10+)

As of iOS 10, you must povide a reason for using thre camera in you plist:
Please add the follwing to your plist:
**NSCameraUsageDescription : We need the camera to scan**

## Installation

The recommended approach for installing IRLDocumentScanner is via the [CocoaPods](http://cocoapods.org/) package manager, as it provides flexible dependency management and dead simple installation. For best results, it is recommended that you install via CocoaPods **>= 1.0** using Git **>= 1.8.0** installed via Homebrew.

### via CocoaPods

Install CocoaPods if not already available:

``` bash
$ [sudo] gem install cocoapods
$ pod setup
```

Change to the directory of your Xcode project, and Create and Edit your Podfile and add IRLDocumentScanner:

``` bash
$ cd /path/to/MyProject
$ touch Podfile
$ edit Podfile

platform :ios, '8.0'

target "YOUR APP" do
pod 'IRLDocumentScanner'
use_frameworks!
end

```

### via Carthage

Install [Carthage](https://github.com/Carthage/Carthage#installing-carthage) if not already available 

Change to the directory of your Xcode project, and Create and Edit your Podfile and add IRLDocumentScanner:

``` bash
$ cd /path/to/MyProject
$ touch CartFile
$ edit CartFile

github "charlymr/IRLDocumentScanner" ~> 0.3.1
```

Save and run:
``` bash
$ carthage update
```

Drop the Carthage/Build/iOS .framework in your project.

For more details on Cartage and how to use it, check the [Carthage Github](https://github.com/Carthage/Carthage) documentation


### Manually

- [Download IRLDocumentScanner](../../archive/master.zip)
- Copy to your project those 2 files: <strong> IRLCamera.storyboard | IRLCameraMedia.xcassets </strong>
- Copy to your project this folder: <strong> Source </strong>
- Make sure your project link to  <strong>  'Foundation', 'UIKit', 'AVFoundation', 'CoreImage',  'GLKit' </strong>
- [Download TOCropViewController](https://github.com/TimOliver/TOCropViewController/archive/2.0.7.zip)
- Add it to TOCropViewController your project


## Getting Started

IRLDocumentScanner is designed to be a standalone drop in dependency. You instanciate the controller, defining its delegate and present it.


## Examples

### Objective-C

```  objective-c
#pragma mark - User Actions

- (IBAction)scan:(id)sender {
    IRLScannerViewController *scanner = [IRLScannerViewController standardCameraViewWithDelegate:self];
        scanner.showCountrols = YES;
        scanner.showAutoFocusWhiteRectangle = YES;
        [self presentViewController:scanner animated:YES completion:nil];
}

#pragma mark - IRLScannerViewControllerDelegate

-(void)pageSnapped:(UIImage *)page_image from:(UIViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
        [self.scannedImage setImage:page_image];
    }];
}

-(void)didCancelIRLScannerViewController:(IRLScannerViewController *)cameraView {
    [cameraView dismissViewControllerAnimated:YES completion:nil];
}
```

### Swift

``` Swift
   // MARK: User Actions

    @IBAction func scan(sender: AnyObject) {
        let scanner = IRLScannerViewController.standardCameraViewWithDelegate(self)
        scanner.showControls = true
        scanner.showAutoFocusWhiteRectangle = true
        presentViewController(scanner, animated: true, completion: nil)
    }
    
    // MARK: IRLScannerViewControllerDelegate
    
    func pageSnapped(page_image: UIImage!, from controller: IRLScannerViewController!) {
        controller.dismissViewControllerAnimated(true) { () -> Void in
            self.imageView.image = page_image
        }
    }
    
    func didCancel(_ cameraView: IRLScannerViewController) {
        cameraView.dismissViewControllerAnimated(true) {}
    }
```


## Authors

- Denis Martin | Web: [www.irlmobile.com](http://www.irlmobile.com)



## Attribution

- [Maximilian Mackh - IPDFCameraViewController](https://github.com/mmackh/IPDFCameraViewController)
- Camera Icons by [Joseph Wain, Glyphish](http://www.glyphish.com)


## Open Source

- Feel free to fork and modify this code. Pull requests are more thant welcome!



## License

**The MIT License (MIT)**

Copyright (c) 2015 Denis Martin. Part of this code where taken from [IPDFCameraViewController](https://github.com/mmackh/IPDFCameraViewController)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
