# To validate: `$ pod lib lint Appcues.podspec

Pod::Spec.new do |s|
  s.name             = 'Appcues'
  s.module_name      = 'AppcuesKit'
  s.version          = '3.1.0'
  s.summary          = 'Appcues iOS SDK allows you to integrate Appcues experiences into your native iOS apps'

  s.description      = <<-DESC
A Swift library for sending user properties and events to the Appcues API and retrieving and rendering Appcues content based on those properties and events.
                       DESC

  s.homepage         = 'https://github.com/appcues/appcues-ios-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Appcues' => 'mobile@appcues.com' }
  s.source           = { :git => 'https://github.com/appcues/appcues-ios-sdk.git', :tag => s.version.to_s }

  s.swift_version = '5.0'
  s.ios.deployment_target = '11.0'

  s.source_files = 'Sources/AppcuesKit/**/*.swift'
  s.exclude_files = 'Sources/AppcuesKit/AppcuesKit.docc'

  s.resource_bundles = {
      'Appcues' => ['Sources/AppcuesKit/**/*.xcassets']
  }
end
