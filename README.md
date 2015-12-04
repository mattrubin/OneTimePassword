# OneTimePassword
### TOTP and HOTP one-time passwords for iOS

[![Build Status](https://travis-ci.org/mattrubin/OneTimePassword.svg?branch=master)](https://travis-ci.org/mattrubin/OneTimePassword)
[![CocoaPods](https://img.shields.io/cocoapods/v/OneTimePassword.svg)](http://cocoadocs.org/docsets/OneTimePassword)
[![Carthage Compatible](https://img.shields.io/badge/carthage-%E2%9C%93-5BA7E9.svg)](https://github.com/Carthage/Carthage/)
[![MIT License](http://img.shields.io/badge/license-mit-989898.svg)](https://github.com/mattrubin/OneTimePassword/blob/master/LICENSE.md)
[![Platform](https://img.shields.io/cocoapods/p/OneTimePassword.svg)](http://cocoadocs.org/docsets/OneTimePassword)

The OneTimePassword library is the core of [Authenticator](http://mattrubin.me/authenticator/). It can generate both [time-based](https://tools.ietf.org/html/rfc6238) and [counter-based](https://tools.ietf.org/html/rfc4226) one-time passwords as standardized in RFC 4226 and 6238. It can also read and generate the ["otpauth://" URLs](https://code.google.com/p/google-authenticator/wiki/KeyUriFormat) commonly used to set up OTP tokens, and can save and load tokens to and from the iOS secure keychain.

## Getting Started

1. Check out the latest version of the project using Git.

2. Check out the project's dependencies with `git submodule init` and `git submodule update`.

3. Open the `OneTimePassword.xcworkspace` file.
> If you open the `.xcodeproj` instead, the app will not be able to find its dependencies.

4. Build and run the "OneTimePassword" scheme.

## Dependencies

OneTimePassword uses [Carthage](https://github.com/Carthage/Carthage) to manage its dependencies, but it does not currently use Carthage to build those dependencies. The dependent projects are checked out as submodules, are included in `OneTimePassword.xcworkspace`, and are built by Xcode as target dependencies of the OneTimePassword framework.

To check out the dependencies, simply follow the "Getting Started" instructions above.

To update the dependencies, modify the [Cartfile](https://github.com/mattrubin/OneTimePassword/blob/master/Cartfile) and run:
```
$ carthage update --no-build --use-submodules
```

## License
OneTimePassword was created by [Matt Rubin](http://mattrubin.me) and the [OneTimePassword authors](AUTHORS.txt) and is released under the [MIT License](LICENSE.md).
