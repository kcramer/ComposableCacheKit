Pod::Spec.new do |s|
  s.name             = 'ComposableCacheKit'
  s.version          = '0.2.0'
  s.summary          = 'A Swift framework that provides a lightweight, composable cache.'
  s.description      = <<-DESC
ComposableCacheKit is a Swift framework that provides a lightweight, composable cache.
                       DESC

  s.homepage         = 'https://github.com/kcramer/ComposableCacheKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Kevin Cramer' => 'kevinx@sent.com' }
  s.source           = { :git => 'https://github.com/kcramer/ComposableCacheKit', :tag => s.version.to_s }

  s.dependency 'Promises'

  s.swift_version = '5.0'
  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.watchos.deployment_target = '3.0'
  s.tvos.deployment_target = '10.0'

  s.source_files = 'ComposableCacheKit/**/*.swift'
end
