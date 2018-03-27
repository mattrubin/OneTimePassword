Pod::Spec.new do |s|
  s.name         = "OneTimePassword"
  s.version      = "3.1"
  s.summary      = "A small library for generating TOTP and HOTP one-time passwords."
  s.homepage     = "https://github.com/mattrubin/OneTimePassword"
  s.license      = "MIT"
  s.author       = "Matt Rubin"
  s.swift_version             = "4.0"
  s.ios.deployment_target     = "8.0"
  s.watchos.deployment_target = "2.0"
  s.source       = { :git => "https://github.com/mattrubin/OneTimePassword.git", :tag => s.version }
  s.source_files = "Sources/*.{swift}"
  s.requires_arc = true
  s.dependency "Base32", "~> 1.1.2"
  s.pod_target_xcconfig = {
    "SWIFT_INCLUDE_PATHS[sdk=appletvos*]"         => "$(SRCROOT)/OneTimePassword/CommonCrypto/appletvos",
    "SWIFT_INCLUDE_PATHS[sdk=appletvsimulator*]"  => "$(SRCROOT)/OneTimePassword/CommonCrypto/appletvsimulator",
    "SWIFT_INCLUDE_PATHS[sdk=iphoneos*]"          => "$(SRCROOT)/OneTimePassword/CommonCrypto/iphoneos",
    "SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]"   => "$(SRCROOT)/OneTimePassword/CommonCrypto/iphonesimulator",
    "SWIFT_INCLUDE_PATHS[sdk=macosx*]"            => "$(SRCROOT)/OneTimePassword/CommonCrypto/macosx",
    "SWIFT_INCLUDE_PATHS[sdk=watchos*]"           => "$(SRCROOT)/OneTimePassword/CommonCrypto/watchos",
    "SWIFT_INCLUDE_PATHS[sdk=watchsimulator*]"    => "$(SRCROOT)/OneTimePassword/CommonCrypto/watchsimulator",
  }
  s.preserve_paths = "CommonCrypto/*"
  # The prepare_command "will be executed after the Pod is downloaded."
  # The script is *not* run on every build, or even on every `pod install`, so if the selected
  # Xcode path changes after the pod is downloaded, you may need to clear the pod from the cache at
  # ~/Library/Caches/CocoaPods so the script can update the modulemaps with the new path.
  # https://guides.cocoapods.org/syntax/podspec.html#prepare_command
  s.prepare_command = "CommonCrypto/injectXcodePath.sh"
end
