Pod::Spec.new do |s|
  s.name         = "OneTimePassword"
  s.version      = "2.0.1"
  s.summary      = "A small library for generating TOTP and HOTP one-time passwords."
  s.homepage     = "https://github.com/mattrubin/OneTimePassword"
  s.license      = "MIT"
  s.author       = "Matt Rubin"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/mattrubin/OneTimePassword.git", :tag => s.version }
  s.source_files = "Sources/*.{swift}"
  s.requires_arc = true
  s.dependency "Base32", "~> 1.0.2"
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
  s.prepare_command = <<-CMD
  CommonCrypto/injectXcodePath
                   CMD
end
