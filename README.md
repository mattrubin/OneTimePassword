# OneTimePassword
### TOTP and HOTP one-time passwords for iOS

[![Build Status](https://travis-ci.org/mattrubin/OneTimePassword.svg?branch=develop)](https://travis-ci.org/mattrubin/OneTimePassword)
[![Codecov](https://codecov.io/gh/mattrubin/OneTimePassword/branch/develop/graph/badge.svg)](https://codecov.io/gh/mattrubin/OneTimePassword)
[![CocoaPods](https://img.shields.io/cocoapods/v/OneTimePassword.svg)](https://cocoapods.org/pods/OneTimePassword)
[![Carthage Compatible](https://img.shields.io/badge/carthage-%E2%9C%93-5BA7E9.svg)](https://github.com/Carthage/Carthage/)
![Platform](https://img.shields.io/cocoapods/p/OneTimePassword.svg)
[![MIT License](https://img.shields.io/cocoapods/l/OneTimePassword.svg)](./LICENSE.md)

The OneTimePassword library is the core of [Authenticator][]. It can generate both [time-based][RFC 6238] and [counter-based][RFC 4226] one-time passwords as standardized in [RFC 4226][] and [RFC 6238][]. It can also read and generate the ["otpauth://" URLs][otpauth] commonly used to set up OTP tokens, and can save and load tokens to and from the iOS secure keychain.

[Authenticator]: https://mattrubin.me/authenticator/
[RFC 6238]: https://tools.ietf.org/html/rfc6238
[RFC 4226]: https://tools.ietf.org/html/rfc4226
[otpauth]: https://github.com/google/google-authenticator/wiki/Key-Uri-Format


## Installation

### [Carthage][]

Add the following line to your [Cartfile][]:

````config
github "mattrubin/OneTimePassword" ~> 3.1
````

Then run `carthage update OneTimePassword` to install the latest version of the framework.

Be sure to check the Carthage README file for the latest instructions on [adding frameworks to an application][carthage-instructions].

[Carthage]: https://github.com/Carthage/Carthage
[Cartfile]: https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile
[carthage-instructions]: https://github.com/Carthage/Carthage/blob/master/README.md#adding-frameworks-to-an-application

### [CocoaPods][]

Add the following line to your [Podfile][]:

````ruby
pod 'OneTimePassword', '~> 3.1'
````

OneTimePassword, like all pods written in Swift, can only be integrated as a framework. Make sure to add the line `use_frameworks!` to your Podfile or target to opt into frameworks instead of static libraries.

Then run `pod install` to install the latest version of the framework.

[CocoaPods]: https://cocoapods.org
[Podfile]: https://guides.cocoapods.org/using/the-podfile.html


## Usage

> The [latest version][swift-4] of OneTimePassword compiles with Swift 4.x, and can be linked with Swift 3.2+ projects using the Swift compiler's [compatibility mode](https://swift.org/blog/swift-4-0-released/#new-compatibility-modes). To use OneTimePassword with earlier versions of Swift, check out the [`swift-3`][swift-3] and [`swift-2.3`][swift-2.3] branches. To use OneTimePassword in an Objective-C based project, check out the [`objc` branch][objc] and the [1.x releases][releases].

[swift-4]: https://github.com/mattrubin/OneTimePassword/tree/swift-4
[swift-3]: https://github.com/mattrubin/OneTimePassword/tree/swift-3
[swift-2.3]: https://github.com/mattrubin/OneTimePassword/tree/swift-2.3
[objc]: https://github.com/mattrubin/OneTimePassword/tree/objc
[releases]: https://github.com/mattrubin/OneTimePassword/releases

### Create a Token

The [`Generator`][Generator] struct contains the parameters necessary to generate a one-time password. The [`Token`][Token] struct associates a `generator` with a `name` and an `issuer` string.

[Generator]: ./Sources/Generator.swift
[Token]: ./Sources/Token.swift

To initialize a token with an `otpauth://` url:

````swift
if let token = Token(url: url) {
    print("Password: \(token.currentPassword)")
} else {
    print("Invalid token URL")
}
````

To create a generator and a token from user input:

> This example assumes the user provides the secret as a Base32-encoded string. To use the decoding function seen below, add `import Base32` to the top of your Swift file.

````swift
let name = "..."
let issuer = "..."
let secretString = "..."

guard let secretData = MF_Base32Codec.data(fromBase32String: secretString),
    !secretData.isEmpty else {
        print("Invalid secret")
        return nil
}

guard let generator = Generator(
    factor: .timer(period: 30),
    secret: secretData,
    algorithm: .sha1,
    digits: 6) else {
        print("Invalid generator parameters")
        return nil
}

let token = Token(name: name, issuer: issuer, generator: generator)
return token
````

### Generate a One-Time Password

To generate the current password:

````swift
let password = token.currentPassword
````

To generate the password at a specific point in time:

````swift
let time = Date(timeIntervalSince1970: ...)
do {
    let passwordAtTime = try token.generator.password(at: time)
    print("Password at time: \(passwordAtTime)")
} catch {
    print("Cannot generate password for invalid time \(time)")
}
````

### Persistence

Token persistence is managed by the [`Keychain`][Keychain] class, which represents the iOS system keychain.

````swift
let keychain = Keychain.sharedInstance
````

The [`PersistentToken`][PersistentToken] struct represents a `Token` that has been saved to the keychain, and associates a `token` with a keychain-provided data `identifier`.

[Keychain]: ./Sources/Keychain.swift
[PersistentToken]: ./Sources/PersistentToken.swift

To save a token to the keychain:

````swift
do {
    let persistentToken = try keychain.add(token)
    print("Saved to keychain with identifier: \(persistentToken.identifier)")
} catch {
    print("Keychain error: \(error)")
}
````

To retrieve a token from the keychain:

````swift
do {
    if let persistentToken = try keychain.persistentToken(withIdentifier: identifier) {
        print("Retrieved token: \(persistentToken.token)")
    }
    // Or...
    let persistentTokens = try keychain.allPersistentTokens()
    print("All tokens: \(persistentTokens.map({ $0.token }))")
} catch {
    print("Keychain error: \(error)")
}
````

To update a saved token in the keychain:

````swift
do {
    let updatedPersistentToken = try keychain.update(persistentToken, with: token)
    print("Updated token: \(updatedPersistentToken)")
} catch {
    print("Keychain error: \(error)")
}
````

To delete a token from the keychain:

````swift
do {
    try keychain.delete(persistentToken)
    print("Deleted token.")
} catch {
    print("Keychain error: \(error)")
}
````


## License

OneTimePassword was created by [Matt Rubin][] and the [OneTimePassword authors](AUTHORS.txt) and is released under the [MIT License](LICENSE.md).

[Matt Rubin]: https://mattrubin.me
