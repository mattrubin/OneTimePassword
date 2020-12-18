Pod::Spec.new do |s|
  s.name         = "OneTimePassword"
  s.version      = "3.2.0"
  s.summary      = "A small library for generating TOTP and HOTP one-time passwords."
  s.homepage     = "https://github.com/mattrubin/OneTimePassword"
  s.license      = "MIT"
  s.author       = "Matt Rubin"
  s.swift_versions            = ["4.2", "5.0"]
  s.ios.deployment_target     = "10.3.1"
  s.watchos.deployment_target = "3.2"
  s.source       = { :git => "https://github.com/mattrubin/OneTimePassword.git", :tag => s.version }
  s.source_files = "Sources/*.{swift}"
  s.requires_arc = true
  s.dependency "SwiftBase32", "~> 0.9.0"
end
