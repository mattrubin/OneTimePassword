# OneTimePassword
### TOTP and HOTP one-time passwords for iOS

[![Build Status](https://travis-ci.org/mattrubin/onetimepassword.svg)](https://travis-ci.org/mattrubin/onetimepassword)
[![Latest Release](http://img.shields.io/github/release/mattrubin/onetimepassword.svg)](https://github.com/mattrubin/onetimepassword/releases)
[![CocoaPods](https://img.shields.io/cocoapods/v/OneTimePassword.svg)](http://cocoadocs.org/docsets/OneTimePassword)
[![Carthage Compatible](https://img.shields.io/badge/carthage-%E2%9C%93-5BA7E9.svg)](https://github.com/Carthage/Carthage/)
[![MIT License](http://img.shields.io/badge/license-mit-989898.svg)](https://github.com/mattrubin/onetimepassword/blob/master/LICENSE.md)
[![Platform](https://img.shields.io/cocoapods/p/OneTimePassword.svg)](http://cocoadocs.org/docsets/OneTimePassword)

The OneTimePassword library is the core of [Authenticator](http://mattrubin.me/authenticator/). It can generate both [time-based](https://tools.ietf.org/html/rfc6238) and [counter-based](https://tools.ietf.org/html/rfc4226) one-time passwords as standardized in RFC 4226 and 6238. It can also read and generate the ["otpauth://" URLs](https://code.google.com/p/google-authenticator/wiki/KeyUriFormat) commonly used to set up OTP tokens.
