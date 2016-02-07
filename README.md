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

````
github "mattrubin/OneTimePassword" ~> 2.0
````

Then run `carthage update OneTimePassword` to install the latest version of the framework.

Be sure to check the Carthage README file for the latest instructions on [adding frameworks to an application][carthage-instructions].

[Carthage]: https://github.com/Carthage/Carthage
[Cartfile]: https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile
[carthage-instructions]: https://github.com/Carthage/Carthage/blob/master/README.md#adding-frameworks-to-an-application

### [CocoaPods][]

Add the following line to your [Podfile][]:

````ruby
pod 'OneTimePassword', '~> 2.0'
````

OneTimePassword, like all pods written in Swift, can only be integrated as a framework. Make sure to add the line `use_frameworks!` to your Podfile or target to opt into frameworks instead of static libraries.

Then run `pod install` to install the latest version of the framework.

[CocoaPods]: https://cocoapods.org
[Podfile]: https://guides.cocoapods.org/using/the-podfile.html


## Usage

### Create a Token

The [`Generator`][Generator] struct contains the parameters necessary to generate a one-time password. The [`Token`][Token] struct associates a `generator` with a `name` and an `issuer` string.

[Generator]: https://github.com/mattrubin/OneTimePassword/blob/master/OneTimePassword/Generator.swift
[Token]: https://github.com/mattrubin/OneTimePassword/blob/master/OneTimePassword/Token.swift

To initialize a token with an `otpauth://` url:
````swift
if let token = Token(url: url) {
    print("Password: \(token.currentPassword)")
} else {
    print("Invalid token URL")
}
````

To create a generator and a token from user input:
````swift
let name = "..."
let issuer = "..."
let secretString = "..."

guard let secretData = NSData(base32String: secretString)
    where secretData.length > 0 else {
        print("Invalid secret")
        return nil
}

guard let generator = Generator(
    factor: .Timer(period: 30),
    secret: secretData,
    algorithm: .SHA1,
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
let now: NSTimeInterval = NSDate().timeIntervalSince1970
let passwordAtTime = token.generator.passwordAtTime(now)
````

### Persistence

Token persistence is managed by the [`Keychain`][Keychain] class, which represents the iOS system keychain.
````swift
let keychain = Keychain.sharedInstance
````

The [`PersistentToken`][PersistentToken] struct represents a `Token` that has been saved to the keychain, and associates a `token` with a keychain-provided data `identifier`.

[Keychain]: https://github.com/mattrubin/OneTimePassword/blob/master/OneTimePassword/Keychain.swift
[PersistentToken]: https://github.com/mattrubin/OneTimePassword/blob/master/OneTimePassword/PersistentToken.swift

To save a token to the keychain:
````swift
do {
    let persistentToken = try keychain.addToken(token)
    print("Saved to keychain with identifier: \(persistentToken.identifier)")
} catch {
    print("Keychain error: \(error)")
}
````

To retrieve a token from the keychain:
````swift
do {
    let persistentToken = try keychain.persistentTokenWithIdentifier(identifier)
    print("Retrieved token: \(persistentToken.token)")
    // Or...
    let persistentTokens = try keychain.allPersistentTokens()
} catch {
    print("Keychain error: \(error)")
}
````

To update a saved token in the keychain:
````swift
do {
    let updatedPersistentToken = try keychain.updatePersistentToken(persistentToken,
        withToken: token)
    print("Updated token: \(updatedPersistentToken)")
} catch {
    print("Keychain error: \(error)")
}
````

To delete a token from the keychain:
````swift
do {
    try keychain.deletePersistentToken(persistentToken)
    print("Deleted token.")
} catch {
    print("Keychain error: \(error)")
}
````


## License
OneTimePassword was created by [Matt Rubin](http://mattrubin.me) and the [OneTimePassword authors](AUTHORS.txt) and is released under the [MIT License](LICENSE.md).
