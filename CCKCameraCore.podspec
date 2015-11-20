Pod::Spec.new do |s|
  s.name = 'CCKCameraCore'
  s.version = '0.1.0'
  s.license = 'MIT'
  s.summary = 'ChiChak camera component'
  s.homepage = 'https://github.com/allabttony/CCKCameraCore'
  s.author = { 'Tony Chan' => 'allabttony@gmail.com' }
  s.source = { :git => 'git@github.com:allabttony/CCKCameraCore.git', :tag => s.version.to_s }
  s.platform = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'CCKCameraCore/Core/*.{h,m}'
 end
