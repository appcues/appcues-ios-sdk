# To validate: `$ pod lib lint AppcuesNotificationService.podspec

Pod::Spec.new do |s|
  s.name             = 'AppcuesNotificationService'
  s.version          = '4.3.8'
  s.summary          = 'Provide rich push notifications via Appcues'

  s.description      = <<-DESC
A Swift library for providing rich push notifications via Appcues.
                      DESC

  s.homepage         = 'https://github.com/appcues/appcues-ios-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Appcues' => 'mobile@appcues.com' }
  s.source           = { :git => 'https://github.com/appcues/appcues-ios-sdk.git', :tag => s.version.to_s }

  s.swift_version = '5.0'
  s.ios.deployment_target = '11.0'

  s.source_files = 'Sources/AppcuesNotificationService/**/*.swift'
  s.exclude_files = 'Sources/AppcuesNotificationService/AppcuesNotificationService.docc'
end