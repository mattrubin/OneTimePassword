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
        return OTPAlgorithm(Generator.defaultAlgorithm)
    }

    public static var defaultDigits: UInt {
        return UInt(Generator.defaultDigits)
    }

    public static var defaultInitialCounter: UInt64 {
        return 0
    }

    public static var defaultPeriod: NSTimeInterval {
        return 30
    }


    private var token: Token? {
        return tokenForOTPToken(self)
    }

    private func updateWithToken(token: Token) {
        self.name = token.name
        self.issuer = token.issuer

        self.secret = token.core.secret
        self.algorithm = OTPAlgorithm(token.core.algorithm)
        self.digits = UInt(token.core.digits)

        switch token.core.factor {
        case let .Counter(counter):
            self.type = .Counter
            self.counter = counter
        case let .Timer(period):
            self.type = .Timer
            self.period = period
        }
    }

    public func validate() -> Bool {
        return (token != nil)
    }
}

public extension OTPToken {
    var password: String? {
        return token?.core.password
    }

    func updatePassword() {
        if let token = token {
            if let newToken = updatedToken(token) {
                updateWithToken(newToken)
            }
        }
    }

    // This should be private, but is public for testing purposes
    func generatePasswordForCounter(counter: UInt64) -> String? {
        if let token = token {
            return generatePassword(algorithm: token.core.algorithm, digits: token.core.digits, secret: token.core.secret, counter: counter)
        }
        return nil
    }
}

public extension OTPToken {
    static func tokenWithURL(url: NSURL) -> Self? {
        return tokenWithURL(url, secret: nil)
    }

    static func tokenWithURL(url: NSURL, secret: NSData?) -> Self? {
        if let token = Token.URLSerializer.deserialize(url.absoluteString, secret: secret) {
            let otp = self.init()
            otp.updateWithToken(token)
            return otp
        }
        return nil
    }

    func url() -> NSURL? {
        if let token = token {
            if let string = Token.URLSerializer.serialize(token) {
                return NSURL(string: string)
            }
        }
        return nil
    }
}

public extension OTPToken {
    var keychainItemRef: NSData? {return self.keychainItem?.persistentRef }
    var isInKeychain: Bool { return (keychainItemRef != nil) }

    func saveToKeychain() -> Bool {
        if let token = token {
            if let keychainItem = self.keychainItem {
                if let newKeychainItem = updateKeychainItem(keychainItem, withToken: token) {
                    self.keychainItem = newKeychainItem
                    return true
                }
                return false
            } else {
                if let newKeychainItem = addTokenToKeychain(token) {
                    self.keychainItem = newKeychainItem
                    return true
                }
                return false
            }
        }
        return false
    }

    func removeFromKeychain() -> Bool {
        if let keychainItem = self.keychainItem {
            if deleteKeychainItem(keychainItem) {
                self.keychainItem = nil
                return true
            }
        }
        return false
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
        if let keychainItem = Token.KeychainItem.keychainItemWithKeychainItemRef(keychainItemRef) {
            return self.tokenWithKeychainItem(keychainItem)
        }
        return nil
    }

    // This should be private, but is public for testing purposes
    static func tokenWithKeychainDictionary(keychainDictionary: NSDictionary) -> Self? {
        if let keychainItem = Token.KeychainItem.keychainItemWithDictionary(keychainDictionary) {
            return self.tokenWithKeychainItem(keychainItem)
        }
        return nil
    }
}
