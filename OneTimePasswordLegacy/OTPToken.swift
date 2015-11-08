//
//  OTPToken.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import OneTimePassword

/**
`OTPToken` is a mutable, Objective-C-compatible wrapper around `OneTimePassword.Token`. For more
information about its properties and methods, consult the underlying `OneTimePassword`
documentation.
*/
public final class OTPToken: NSObject {
    required public override init() {}

    public var name: String = Token.defaultName
    public var issuer: String = Token.defaultIssuer
    public var type: OTPTokenType = .Timer
    public var secret: NSData = NSData()
    public var algorithm: OTPAlgorithm = OTPToken.defaultAlgorithm
    public var digits: UInt = OTPToken.defaultDigits
    public var period: NSTimeInterval = OTPToken.defaultPeriod
    public var counter: UInt64 = OTPToken.defaultInitialCounter

    private var keychainItem: Token.KeychainItem?


    public static var defaultAlgorithm: OTPAlgorithm {
        return OTPAlgorithm.SHA1
    }

    public static var defaultDigits: UInt {
        return 6
    }

    public static var defaultInitialCounter: UInt64 {
        return 0
    }

    public static var defaultPeriod: NSTimeInterval {
        return 30
    }


    public var token: Token {
        return tokenForOTPToken(self)
    }

    public func updateWithToken(token: Token) {
        self.name = token.name
        self.issuer = token.issuer

        self.secret = token.generator.secret
        self.algorithm = OTPAlgorithm(token.generator.algorithm)
        self.digits = UInt(token.generator.digits)

        switch token.generator.factor {
        case let .Counter(counter):
            self.type = .Counter
            self.counter = counter
        case let .Timer(period):
            self.type = .Timer
            self.period = period
        }
    }

    public convenience init(token: Token) {
        self.init()
        updateWithToken(token)
    }

    public func validate() -> Bool {
        return validateGeneratorWithGoogleRules(token.generator)
    }
}

public extension OTPToken {
    var password: String? {
        return token.generator.currentPassword
    }

    func updatePassword() {
        let newToken = updatedToken(token)
        updateWithToken(newToken)
    }
}

public extension OTPToken {
    static func tokenWithURL(url: NSURL) -> Self? {
        return tokenWithURL(url, secret: nil)
    }

    static func tokenWithURL(url: NSURL, secret: NSData?) -> Self? {
        guard let token = Token.URLSerializer.deserialize(url, secret: secret)
            where validateGeneratorWithGoogleRules(token.generator) else {
                return nil
        }
        return self.init(token: token)
    }

    func url() -> NSURL? {
        return Token.URLSerializer.serialize(token)
    }
}

public extension OTPToken {
    var keychainItemRef: NSData? {return self.keychainItem?.persistentRef }
    var isInKeychain: Bool { return (keychainItemRef != nil) }

    func saveToKeychain() -> Bool {
        if let keychainItem = self.keychainItem {
            guard let newKeychainItem = updateKeychainItem(keychainItem, withToken: token) else {
                return false
            }
            self.keychainItem = newKeychainItem
            return true
        } else {
            guard let newKeychainItem = addTokenToKeychain(token) else {
                return false
            }
            self.keychainItem = newKeychainItem
            return true
        }
    }

    func removeFromKeychain() -> Bool {
        guard let keychainItem = self.keychainItem else {
            return false
        }
        let success = deleteKeychainItem(keychainItem)
        if success {
            self.keychainItem = nil
        }
        return success
    }

    static func allTokensInKeychain() -> Array<OTPToken> {
        return Token.KeychainItem.allKeychainItems().map(self.tokenWithKeychainItem)
    }

    // This should be private, but is public for testing purposes
    static func tokenWithKeychainItem(keychainItem: Token.KeychainItem) -> Self {
        let otp = self.init()
        otp.updateWithToken(keychainItem.token)
        otp.keychainItem = keychainItem
        return otp
    }

    static func tokenWithKeychainItemRef(keychainItemRef: NSData) -> Self? {
        guard let keychainItem = Token.KeychainItem(keychainItemRef: keychainItemRef) else {
            return nil
        }
        return self.tokenWithKeychainItem(keychainItem)
    }

    // This should be private, but is public for testing purposes
    static func tokenWithKeychainDictionary(keychainDictionary: NSDictionary) -> Self? {
        guard let keychainItem = Token.KeychainItem(keychainDictionary: keychainDictionary) else {
            return nil
        }
        return self.tokenWithKeychainItem(keychainItem)
    }
}

// https://github.com/google/google-authenticator/blob/56ea6af49c958d4b8056e3c26b3c163841abb900/mobile/ios/Classes/OTPGenerator.m#L80
// https://github.com/google/google-authenticator/blob/56ea6af49c958d4b8056e3c26b3c163841abb900/mobile/ios/Classes/TOTPGenerator.m#L41
private func validateGeneratorWithGoogleRules(generator: Generator) -> Bool {
    let validDigits: (Int) -> Bool = { (6 <= $0) && ($0 <= 8) }
    let validPeriod: (NSTimeInterval) -> Bool = { (0 < $0) && ($0 <= 300) }

    switch generator.factor {
    case .Counter:
        return validDigits(generator.digits)
    case .Timer(let period):
        return validDigits(generator.digits) && validPeriod(period)
    }
}
