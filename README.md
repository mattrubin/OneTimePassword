# OneTimePassword
### TOTP and HOTP one-time passwords for iOS

[![Build Status](https://travis-ci.org/mattrubin/OneTimePassword.svg?branch=master)](https://travis-ci.org/mattrubin/OneTimePassword)
[![CocoaPods](https://img.shields.io/cocoapods/v/OneTimePassword.svg)](http://cocoadocs.org/docsets/OneTimePassword)
[![Carthage Compatible](https://img.shields.io/badge/carthage-%E2%9C%93-5BA7E9.svg)](https://github.com/Carthage/Carthage/)
[![MIT License](http://img.shields.io/badge/license-mit-989898.svg)](https://github.com/mattrubin/OneTimePassword/blob/master/LICENSE.md)
[![Platform](https://img.shields.io/cocoapods/p/OneTimePassword.svg)](http://cocoadocs.org/docsets/OneTimePassword)

The OneTimePassword library is the core of [Authenticator][]. It can generate both [time-based][RFC 6238] and [counter-based][RFC 4226] one-time passwords as standardized in [RFC 4226][] and [RFC 6238][]. It can also read and generate the ["otpauth://" URLs][otpauth] commonly used to set up OTP tokens, and can save and load tokens to and from the iOS secure keychain.

[Authenticator]: https://mattrubin.me/authenticator/
[RFC 6238]: https://tools.ietf.org/html/rfc6238
[RFC 4226]: https://tools.ietf.org/html/rfc4226
[otpauth]: https://github.com/google/google-authenticator/wiki/Key-Uri-Format

> The latest version of the OneTimePassword library has been designed with a modern Swift API, and does not offer compatibility with Objective-C. To use OneTimePassword in an Objective-C based project, check out the [`objc` branch][objc] and the [1.x releases][releases].

[objc]: https://github.com/mattrubin/OneTimePassword/tree/objc
[releases]: https://github.com/mattrubin/OneTimePassword/releases


## Installation

### [Carthage][]

Add the following line to your [Cartfile][]:

```
github "mattrubin/OneTimePassword" ~> 2.0
```

Then run `carthage update OneTimePassword` to install the latest version of the framework.

Be sure to check the Carthage README file for the latest instructions on [adding frameworks to an application][carthage-instructions].

[Carthage]: https://github.com/Carthage/Carthage
[Cartfile]: https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile
[carthage-instructions]: https://github.com/Carthage/Carthage/blob/master/README.md#adding-frameworks-to-an-application


### [CocoaPods][]

Add the following line to your [Podfile][]:

```ruby
pod 'OneTimePassword', '~> 2.0'
```

OneTimePassword, like all pods written in Swift, can only be integrated as a framework. Make sure to add the line `use_frameworks!` to your Podfile or target to opt into frameworks instead of static libraries.

Then run `pod install` to install the latest version of the framework.

[CocoaPods]: https://cocoapods.org
[Podfile]: https://guides.cocoapods.org/using/the-podfile.html



## License
OneTimePassword was created by [Matt Rubin](http://mattrubin.me) and the [OneTimePassword authors](AUTHORS.txt) and is released under the [MIT License](LICENSE.md).
