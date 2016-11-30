#
#  Be sure to run `pod spec lint VideoKit.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = 'VideoKit'
  s.version      = '0.1.0'
  s.summary      = 'VideoKit your video edition toolbox'

  s.homepage     = 'https://github.com/jeremygrenier/VideoKit'

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author       = 'Jeremy Grenier'


  s.platform     = :ios, '9.0'
  s.source       = { :git => 'https://github.com/jeremygrenier/VideoKit.git', :tag => s.version }


  s.source_files  = 'Source/*.swift'

  s.requires_arc = true
end
