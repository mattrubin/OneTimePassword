Pod::Spec.new do |s|
  s.name         = "OneTimePassword"
  s.version      = "1.1.0"
  s.summary      = "A small library for generating TOTP and HOTP one-time passwords."
  s.homepage     = "https://github.com/mattrubin/onetimepassword"
  s.license      = "MIT"
  s.author       = "Matt Rubin"
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/mattrubin/onetimepassword.git", :tag => s.version }
  s.source_files = "OneTimePassword/**/*.{h,m}"
  s.requires_arc = true
  s.dependency "Base32", "~> 1.0.2"
end
