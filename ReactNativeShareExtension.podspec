require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = "ReactNativeShareExtension"
  s.version      = package['version']
  s.summary      = package['description']
  s.license      = package['license']

  s.authors      = package['author']
  s.homepage     = package['repository']['url']
  s.platform     = :ios, "11.0"
  s.ios.deployment_target = '11.0'

  s.source       = { :git => "https://github.com/sgiggles/react-native-share-extension.git", :tag => "master" }
  s.source_files  = "ios/**/*.{h,m}"

  s.dependency 'React'
end
