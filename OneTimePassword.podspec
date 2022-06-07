Pod::Spec.new do |s|
  s.name         = "OneTimePassword"
  s.version      = "3.2.0"
  s.summary      = "A small library for generating TOTP and HOTP one-time passwords."
  s.homepage     = "https://github.com/mattrubin/OneTimePassword"
  s.license      = "MIT"
  s.author       = "Matt Rubin"
  s.swift_versions            = "5.0"
  s.ios.deployment_target     = "13.0"
  s.macos.deployment_target   = "10.15"
  s.watchos.deployment_target = "6.0"
  s.source       = { :git => "https://github.com/mattrubin/OneTimePassword.git", :tag => s.version }
  s.source_files = "Sources/*.{swift}"
  s.requires_arc = true
  s.dependency "Base32", "~> 1.1.2"
end
