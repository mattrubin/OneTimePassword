# OneTimePassword Changelog

<!--## [In development][master]-->

## [2.1][]
#### Enhancements
- Add watchOS support ([#96](https://github.com/mattrubin/OneTimePassword/pull/96), [#98](https://github.com/mattrubin/OneTimePassword/pull/98))
- Inject Xcode path into the CommonCrypto modulemaps, to support non-standard Xcodelocations ([#92](https://github.com/mattrubin/OneTimePassword/pull/92), [#101](https://github.com/mattrubin/OneTimePassword/pull/101))

#### Other Changes
- Clean up project configuration and build settings ([#95](https://github.com/mattrubin/OneTimePassword/pull/95), [#97](https://github.com/mattrubin/OneTimePassword/pull/97))


## [2.0.1][] (2016-09-20)
#### Enhancements
- Update the project to support Xcode 8 and Swift 2.3. ([#73](https://github.com/mattrubin/OneTimePassword/pull/73), [#75](https://github.com/mattrubin/OneTimePassword/pull/75), [#84](https://github.com/mattrubin/OneTimePassword/pull/84))

#### Fixes
- Disable broken keychain tests on iOS 10. ([#77](https://github.com/mattrubin/OneTimePassword/pull/77), [#88](https://github.com/mattrubin/OneTimePassword/pull/88))

#### Other Changes
- Update badge images and links in the README. ([#69](https://github.com/mattrubin/OneTimePassword/pull/69))
- Reorganize source and test files following the conventions the Swift Package Manager. ([#70](https://github.com/mattrubin/OneTimePassword/pull/70))
- Isolate the CommonCrypto dependency inside a custom wrapper function. ([#71](https://github.com/mattrubin/OneTimePassword/pull/71))
- Clean up whitespace. ([#79](https://github.com/mattrubin/OneTimePassword/pull/79))
- Integrate with codecov.io for automated code coverage reporting. ([#82](https://github.com/mattrubin/OneTimePassword/pull/82))
- Update SwiftLint configuration. ([#87](https://github.com/mattrubin/OneTimePassword/pull/87))
- Update Travis configuration to use Xcode 8. ([#89](https://github.com/mattrubin/OneTimePassword/pull/89))


## [2.0.0][] (2016-02-07)

Version 2 of the OneTimePassword library has been completely redesigned and rewritten with a modern Swift API. The new library source differs too greatly from its predecessor for the changes to be representable in a changelog. The README has a usage guide for the new API.

Additional changes of note:
- The library is well-tested and the source fully documented.
- Carthage is used to manage dependencies, which are checked in as Git submodules.
- Travis CI is used for testing, and Hound CI for linting.
- The project now has a detailed README, as well as a changelog, guidelines for contributing, and a code of conduct.

Changes between prerelease versions of OneTimePassword version 2 can be found below.

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

[master]: https://github.com/mattrubin/OneTimePassword/compare/2.1...master

[2.1]: https://github.com/mattrubin/OneTimePassword/compare/2.0.1...2.1
[2.0.1]: https://github.com/mattrubin/OneTimePassword/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/mattrubin/OneTimePassword/compare/1.1.0...2.0.0
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
