#
# Be sure to run `pod lib lint RoomKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RoomKit'
  s.version          = '0.1.0'
  s.summary          = 'RoomKit is a framework that allows for you to train and then use a model of bluetooth signals in the rooms of a space.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/dali-lab/RoomKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'johnlev' => 'john.lyme@mac.com' }
  s.source           = { :git => 'https://github.com/johnlev/RoomKit.git', :tag => s.version.to_s }
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'RoomKit/Classes/**/*'
  
  # s.resource_bundles = {
  #   'RoomKit' => ['RoomKit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
