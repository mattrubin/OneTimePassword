//
//  OTPToken.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import OneTimePassword

public class OTPToken: NSObject {
    public var name: String = Token.defaultName
    public var issuer: String = Token.defaultIssuer
    public var type: OTPTokenType  = .Timer
    public var secret: NSData = NSData()
    public var algorithm: OTPAlgorithm = OTPToken.defaultAlgorithm
    public var digits: UInt = OTPToken.defaultDigits
    public var period: NSTimeInterval = OTPToken.defaultPeriod
    public var counter: UInt64 = OTPToken.defaultInitialCounter

    required public override init() {}

    public class func tokenWithType(type: OTPTokenType, secret: NSData, name: NSString, issuer: NSString) -> Self {
        let token = self()
        token.type = type
        token.secret = secret
        token.name = name
        token.issuer = issuer
        return token
    }


    private var keychainItem: Token.KeychainItem?

    var token: Token? {
        return tokenForOTPToken(self)
    }

    private func updateWithToken(token: Token) {
        self.name = token.name
        self.issuer = token.issuer

        self.secret = token.core.secret
        self.algorithm = otpAlgorithm(token.core.algorithm)
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


    public class var defaultAlgorithm: OTPAlgorithm {
        return otpAlgorithm(Generator.defaultAlgorithm)
    }
    public class var defaultDigits: UInt {
        return UInt(Generator.defaultDigits)
    }
    public class var defaultInitialCounter: UInt64 {
        return 0
    }
    public class var defaultPeriod: NSTimeInterval {
        return 30
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
            return generatePassword(token.core.algorithm, token.core.digits, token.core.secret, counter)
        }
        return nil
    }
}

public extension OTPToken {
    class func tokenWithURL(url: NSURL) -> Self? {
        return tokenWithURL(url, secret: nil)
    }

    class func tokenWithURL(url: NSURL, secret: NSData?) -> Self? {
        if let urlString = url.absoluteString {
            if let token = Token.URLSerializer.deserialize(urlString, secret: secret) {
                let otp = self()
                otp.updateWithToken(token)
                return otp
            }
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
                if let newKeychainItem = updateKeychainItemWithToken(keychainItem, token) {
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

    class func allTokensInKeychain() -> Array<OTPToken> {
        return Token.KeychainItem.allKeychainItems().map(self.tokenWithKeychainItem)
    }

    // This should be private, but is public for testing purposes
    class func tokenWithKeychainItem(keychainItem: Token.KeychainItem) -> Self {
        let otp = self()
        otp.updateWithToken(keychainItem.token)
        otp.keychainItem = keychainItem
        return otp
    }

    class func tokenWithKeychainItemRef(keychainItemRef: NSData) -> Self? {
        if let keychainItem = Token.KeychainItem.keychainItemWithKeychainItemRef(keychainItemRef) {
            return self.tokenWithKeychainItem(keychainItem)
        }
        return nil
    }

    // This should be private, but is public for testing purposes
    class func tokenWithKeychainDictionary(keychainDictionary: NSDictionary) -> Self? {
        if let keychainItem = Token.KeychainItem.keychainItemWithDictionary(keychainDictionary) {
            return self.tokenWithKeychainItem(keychainItem)
        }
        return nil
    }
}


private func generatorAlgorithm(otpAlgorithm: OTPAlgorithm) -> Generator.Algorithm {
    switch otpAlgorithm {
    case .SHA1:   return .SHA1
    case .SHA256: return .SHA256
    case .SHA512: return .SHA512
    }
}

private func otpAlgorithm(generatorAlgorithm: Generator.Algorithm) -> OTPAlgorithm {
    switch generatorAlgorithm {
    case .SHA1:   return .SHA1
    case .SHA256: return .SHA256
    case .SHA512: return .SHA512
    }
}

private func factorForOTPToken(token: OTPToken) -> Generator.Factor {
    switch token.type {
    case .Counter:
        return .Counter(token.counter)
    case .Timer:
        return .Timer(period: token.period)
    }
}

private func tokenForOTPToken(token: OTPToken) -> Token? {
    if let generator = Generator(
        factor: factorForOTPToken(token),
        secret: token.secret,
        algorithm: generatorAlgorithm(token.algorithm),
        digits: Int(token.digits)
        )
    {
        return Token(
            name: token.name,
            issuer: token.issuer,
            core: generator
        )
    }
    return nil
}
