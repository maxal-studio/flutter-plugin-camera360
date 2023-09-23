#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint camera_360.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'camera_360'
  s.version          = '0.0.1'
  s.summary          = 'Flutter 360 Camera'
  s.description      = <<-DESC
Flutter 360 Camera
                       DESC
  s.homepage         = 'https://max.al'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'MaxAl' => 'info@max.al' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  # s.source_files = 'Classes/**/*{cpp,h}'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'
  s.ios.deployment_target = '11.0'
 
  s.vendored_frameworks = 'camera_360.framework'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end