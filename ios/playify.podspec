#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint playify.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'playify'
  s.version          = '2.2.1'
  s.summary          = 'Access and control the iOS media library from Flutter.'
  s.description      = <<-DESC
Playify provides access to the iOS media library and system music player.
                       DESC
  s.homepage         = 'https://github.com/nt4f04uNd/playify'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Iber Atkaya' => 'https://github.com/iberatkaya' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.frameworks = 'MediaPlayer'
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
