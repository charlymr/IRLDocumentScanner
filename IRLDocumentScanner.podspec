##
## Before you commit to the Podscpec repro, it is good practice to verify your settings via lint
## > pod spec lint IRLDocumentScanner.podspec --sources='https://github.com/CocoaPods/Specs'
##
## When done modifying that file simply run:
## > pod trunk push IRLDocumentScanner.podspec
##

Pod::Spec.new do |s|

s.name         = "IRLDocumentScanner"
s.version      = "0.1.3"
s.summary      = "A Drop-in Document Scanner based View Controller."
s.description  = "A very simple to use class allowing you scan document with border detection."
s.license      = { :type => 'Copyright 2015. iRLMobile. Luxembourg', :file => 'LICENSE.txt' }

s.homepage     = "https://github.com/charlymr/IRLDocumentScanner"
s.authors      = { 'Denis Martin' => 'support@irlmobile.com' }
s.source       = { :git => 'https://github.com/charlymr/IRLDocumentScanner.git', :branch => 'master', :tag => '0.1.3'}

s.platform     = :ios, '8.0'

s.default_subspec = 'Default'

s.subspec 'Default' do |d|
	d.source_files          = 'Source', 'Source/**/*.{h,m}'

	d.resources    = [ '*.storyboard', '*.xcassets' ]

	d.ios.frameworks = 'Foundation', 'UIKit', 'AVFoundation', 'CoreImage',  'GLKit'

	d.requires_arc = true

	d.public_header_files   =  'Source/Public/**/*.h', 'Source/IRLDocumentScanner.h'
	d.private_header_files  =  'Source/Private/**/*.h'
end

s.subspec 'Private' do |p|
	p.source_files          = 'Source', 'Source/**/*.{h,m}'

	p.resources    = [ '*.storyboard', '*.xcassets' ]

	p.ios.frameworks = 'Foundation', 'UIKit', 'AVFoundation', 'CoreImage',  'GLKit'

	p.requires_arc = true

	p.public_header_files = 'Source/Public/**/*.h', 'Source/IRLDocumentScanner.h', 'Source/Private/**/*.h'
end

end