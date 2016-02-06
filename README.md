# OneTimePassword
### TOTP and HOTP one-time passwords for iOS

[![Build Status](https://travis-ci.org/mattrubin/OneTimePassword.svg?branch=master)](https://travis-ci.org/mattrubin/OneTimePassword)
[![CocoaPods](https://img.shields.io/cocoapods/v/OneTimePassword.svg)](http://cocoadocs.org/docsets/OneTimePassword)
[![Carthage Compatible](https://img.shields.io/badge/carthage-%E2%9C%93-5BA7E9.svg)](https://github.com/Carthage/Carthage/)
[![MIT License](http://img.shields.io/badge/license-mit-989898.svg)](https://github.com/mattrubin/OneTimePassword/blob/master/LICENSE.md)
[![Platform](https://img.shields.io/cocoapods/p/OneTimePassword.svg)](http://cocoadocs.org/docsets/OneTimePassword)

The OneTimePassword library is the core of [Authenticator](http://mattrubin.me/authenticator/). It can generate both [time-based](https://tools.ietf.org/html/rfc6238) and [counter-based](https://tools.ietf.org/html/rfc4226) one-time passwords as standardized in RFC 4226 and 6238. It can also read and generate the ["otpauth://" URLs](https://code.google.com/p/google-authenticator/wiki/KeyUriFormat) commonly used to set up OTP tokens, and can save and load tokens to and from the iOS secure keychain.


## Installation

### [Carthage][]

Add the following line to your Cartfile:

```
github "mattrubin/OneTimePassword" ~> 2.0
```

Then run `carthage update OneTimePassword` to install the latest version of the framework.

Be sure to check the Carthage README file for the latest instructions on [adding frameworks to an application][carthage-instructions].

[Carthage]: https://github.com/Carthage/Carthage
[carthage-instructions]: https://github.com/Carthage/Carthage/blob/master/README.md#adding-frameworks-to-an-application


## License
OneTimePassword was created by [Matt Rubin](http://mattrubin.me) and the [OneTimePassword authors](AUTHORS.txt) and is released under the [MIT License](LICENSE.md).
