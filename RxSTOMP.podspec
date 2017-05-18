Pod::Spec.new do |s|

  # 1
  s.platform = :ios
  s.ios.deployment_target = '10.0'
  s.name = "RxSTOMP"
  s.summary = "Simple implementation of STOMP protocol via CocoaAsyncSocket and RxSwift"
  s.requires_arc = true

  # 2
  s.version = "0.1.1"

  # 3
  s.license = { :type => "MIT", :file => "LICENSE" }

  # 4 - Replace with your name and e-mail address
  s.author = { "Pavel Shatalov" => "shatalovp@gmail.com" }

  # 5 - Replace this URL with your own Github page's URL (from the address bar)
  s.homepage = "https://github.com/seidju/RxSTOMP"

  # 6 - Replace this URL with your own Git URL from "Quick Setup"
  s.source = { :git => "https://github.com/seidju/RxSTOMP.git", :tag => "#{s.version}"}


  # 7
  s.framework = "Foundation"
  s.dependency 'CocoaAsyncSocket'
  s.dependency 'RxSwift'

  # 8
  s.source_files = "RxSTOMP/**/*.{swift}"

  # 9
  #s.resources = "RxSTOMP/**/*.{png,jpeg,jpg,storyboard,xib}"
end
