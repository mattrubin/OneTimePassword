# Changelog

## [2.0.0][master] (In development)

### [2.0.0-beta.4][] (2016-02-04)
- Refactor and document new Swift framework
- Remove legacy Objective-C framework

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

[master]: https://github.com/mattrubin/OneTimePassword/compare/1.1.1...master

[2.0.0-beta.4]: https://github.com/mattrubin/OneTimePassword/compare/2.0.0-beta.3...2.0.0-beta.4
[2.0.0-beta.3]: https://github.com/mattrubin/OneTimePassword/compare/2.0.0-beta.2...2.0.0-beta.3
[2.0.0-beta.2]: https://github.com/mattrubin/OneTimePassword/compare/2.0.0-beta.1...2.0.0-beta.2
[2.0.0-beta.1]: https://github.com/mattrubin/OneTimePassword/compare/2.0.0-beta...2.0.0-beta.1
[2.0.0-beta]: https://github.com/mattrubin/OneTimePassword/compare/1.1.1...2.0.0-beta
[1.1.1]: https://github.com/mattrubin/OneTimePassword/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/mattrubin/OneTimePassword/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/mattrubin/OneTimePassword/tree/1.0.0