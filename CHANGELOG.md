# Changelog

## [In development][master]

## [2.0.0][] (2016-02-07)

### [2.0.0-rc][] (2016-02-07)
- Update `Token` tests for full test coverage. (#66)
- Add installation and usage instructions to the README. (#63, #65, #67)
- Upgrade the Travis build configuration to use Xcode 7.2 and iOS 9.2. (#66)
- Add a README file to the CommonCrypto folder to explain the custom modulemaps. (#64)
- Assorted cleanup and formatting improvements. (#61, #62)

### [2.0.0-beta.5][] (2016-02-05)
- Use custom `modulemap`s to link CommonCrypto, removing external dependency on `soffes/Crypto` (#57)
- Make `jspahrsummers/xcconfigs` a private dependency. (#58)
- Update `OneTimePassword.podspec` to build the new framework. (#59) 

### [2.0.0-beta.4][] (2016-02-04)
- Refactor and document new Swift framework
- Remove legacy Objective-C framework
- Add framework dependency for CommonCrypto
- Improve framework tests

### [2.0.0-beta.3][] (2015-02-03)
- Add documentation comments to `Token` and `Generator`
- Add static constants for default values
- Remove useless convenience initializer from `OTPToken`

### [2.0.0-beta.2][] (2015-02-01)
- Fix compatibility issues in OneTimePasswordLegacy
- Build and link dependencies directly, instead of relying on a pre-built framework

### [2.0.0-beta.1][] (2015-02-01)
- Refactor `OTPToken` to prevent issues when creating invalid tokens
- Improve testing of legacy tokens with invalid timer period or digits
- Turn off Swift optimizations in Release builds (to avoid a keychain access issue)

### [2.0.0-beta][] (2015-01-26)
- Convert the library to Swift and compile it into a Framework bundle for iOS 8+.
- Replace CocoaPods with Carthage for dependency management.

## [1.1.1][] (2015-12-05)
- Bump deployment target to iOS 8 (the framework product was already unsupported on iOS 7) (#46, #48)
- Replace custom query string parsing and escaping with iOS 8's `NSURLQueryItem`. (#47)
- Add `.gitignore` (#46)
- Configure for Travis CI, adding `.travis.yml` and sharing `OneTimePassword.xcscheme` (#46)
- Update `Podfile` and check in the CocoaPods dependencies. (#46)
- Update `.xcodeproj` version and specify project defaults for indentation and prefixing. (#49)
- Add `README` with project description and a note linking to the latest version of the project (#50)

## [1.1.0][] (2014-07-23)

## [1.0.0][] (2014-07-17)

[master]: https://github.com/mattrubin/OneTimePassword/compare/2.0.0...master

[2.0.0]: https://github.com/mattrubin/OneTimePassword/compare/1.1.1...2.0.0
[2.0.0-rc]: https://github.com/mattrubin/OneTimePassword/compare/2.0.0-beta.5...2.0.0
[2.0.0-beta.5]: https://github.com/mattrubin/OneTimePassword/compare/2.0.0-beta.4...2.0.0-beta.5
[2.0.0-beta.4]: https://github.com/mattrubin/OneTimePassword/compare/2.0.0-beta.3...2.0.0-beta.4
[2.0.0-beta.3]: https://github.com/mattrubin/OneTimePassword/compare/2.0.0-beta.2...2.0.0-beta.3
[2.0.0-beta.2]: https://github.com/mattrubin/OneTimePassword/compare/2.0.0-beta.1...2.0.0-beta.2
[2.0.0-beta.1]: https://github.com/mattrubin/OneTimePassword/compare/2.0.0-beta...2.0.0-beta.1
[2.0.0-beta]: https://github.com/mattrubin/OneTimePassword/compare/1.1.1...2.0.0-beta
[1.1.1]: https://github.com/mattrubin/OneTimePassword/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/mattrubin/OneTimePassword/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/mattrubin/OneTimePassword/tree/1.0.0