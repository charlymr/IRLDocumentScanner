![Demo](https://github.com/charlymr/IRLDocumentScanner/blob/master/Medias/iphone-scan.gif?raw=true)

# IRLDocumentScanner

IRLDocumentScanner is an Objective-C ViewController that will Automatically scan a document for you you.

**MINIMUM iOS REQUIREMENT: 8.0**

![Screenshot](https://github.com/charlymr/IRLDocumentScanner/blob/master/Medias/scan.jpg?raw=true)

## Installation

The recommended approach for installing IRLDocumentScanner is via the [CocoaPods](http://cocoapods.org/) package manager, as it provides flexible dependency management and dead simple installation. For best results, it is recommended that you install via CocoaPods **>= 0.19.1** using Git **>= 1.8.0** installed via Homebrew.

### via CocoaPods

Install CocoaPods if not already available:

``` bash
$ [sudo] gem install cocoapods
$ pod setup
```

Change to the directory of your Xcode project, and Create and Edit your Podfile and add RestKit:

``` bash
$ cd /path/to/MyProject
$ touch Podfile
$ edit Podfile
platform :ios, '8.0'
pod 'IRLDocumentScanner', '~> 0.1.2'
```

### Manually

- [Download IRLDocumentScanner](../../archive/master.zip)
- Copy to your project those 2 files: <strong> IRLCamera.storyboard | IRLCameraMedia.xcassets </strong>
- Copy to your project this folder: <strong> Source </strong>
- Make sure your project link to  <strong>  'Foundation', 'UIKit', 'AVFoundation', 'CoreImage',  'GLKit' </strong>




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

-(void)cameraViewCancelRequested:(IRLScannerViewController *)cameraView {
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
    
    func cameraViewCancelRequested(cameraView: IRLScannerViewController!) {
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
