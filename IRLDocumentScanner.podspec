Pod::Spec.new do |s|

s.name         = "IRLDocumentScanner"
s.version      = "0.3.0"
s.summary      = "A Drop-in Document Scanner based View Controller."
s.description  = "A very simple to use class allowing you scan document with border detection."
s.license      = { :type => 'MIT', :file => 'LICENSE.txt' }

s.homepage     = "https://github.com/charlymr/IRLDocumentScanner"
s.authors      = { 'Denis Martin' => 'support@irlmobile.com' }
s.source       = { :git => 'https://github.com/charlymr/IRLDocumentScanner.git', :branch => 'master', :tag => '0.2.0'}

s.platform     = :ios, '8.0'

s.source_files = 'Source', 'Source/*.{h,m}', 'Sources/*.swift'
s.ios.frameworks = 'Foundation', 'UIKit', 'AVFoundation', 'CoreImage',  'GLKit'
s.requires_arc = true

end
