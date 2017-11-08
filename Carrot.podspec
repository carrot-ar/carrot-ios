#
#  Be sure to run `pod spec lint Carrot.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name               = "Carrot"
  s.version            = "0.0.1"
  s.summary            = "Carrot is an open-source framework for multi-device AR apps."
  s.description        = <<-DESC
                          Carrot is an open-source framework for multi-device AR apps. This is the iOS client-side framework that interacts with your Carrot web app.
                         DESC

  s.homepage           = "https://github.com/senior-buddy/carrot-ios"
  # s.screenshots      = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"

  s.license            = "BSD 3-Clause"
  s.author             = "gonzalonunez"
  s.social_media_url   = "http://twitter.com/gonzalonunez"

  s.platform           = :ios, '11.0'
  s.source             = { :git => 'https://github.com/carrot-ar/carrot-ios.git', :tag => s.version.to_s }
  s.dependency 'Parrot'

  s.source_files       = "Carrot/**/*.swift"

end
