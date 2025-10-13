Pod::Spec.new do |s|
  s.name             = 'LivenessCheck'
  s.version          = '1.3.0'
  s.summary          = 'Liveness Check SDK'
  s.description      = 'A SDK for liveness detection'
  s.homepage         = 'https://github.com/EQua-Dev/ios-single-liveness-expo'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'SourceID' => 'tech@sourceid.com' }
  s.source           = { :git => 'https://github.com/EQua-Dev/ios-single-liveness-expo', :tag => s.version.to_s }
  
  s.ios.deployment_target = '14.0'
  s.swift_version = '5.0'
  
  # Changed this line to match your structure
  s.source_files = 'LivenessCheck/**/*.swift'
  
  s.frameworks = 'UIKit', 'SwiftUI', 'AVFoundation'
end
