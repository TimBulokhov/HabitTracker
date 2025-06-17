# Uncomment the next line to define a global platform for your project
platform :ios, '16.0'

target 'HabitTracker' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  inhibit_all_warnings!

  # Pods for HabitTracker

  pod 'AppMetricaCore', '~> 5.4.0' 

  # Firebase
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'GoogleSignIn'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      
      # Исправление предупреждений о дублировании библиотек
      config.build_settings['OTHER_LDFLAGS'] = '$(inherited) -lc++'
      
      # Исправление предупреждений о скриптах сборки
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        target.build_configurations.each do |config|
            config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        end
      end
    end
  end
end