//
//  OTPToken.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import OneTimePassword

public class OTPToken: NSObject {
    var token: Token? {
        return tokenForOTPToken(self)
    }
    var keychainItem: Token.KeychainItem?

    required public init(token: Token?) {
        self.name = token?.name ?? ""
        self.issuer = token?.issuer ?? ""

        self.secret = token?.core.secret ?? NSData()
        if let algorithm = token?.core.algorithm {
            self.algorithm = otpAlgorithm(algorithm)
        } else {
            self.algorithm = OTPToken.defaultAlgorithm()
        }


        if let digits = token?.core.digits {
            self.digits = UInt(digits)
        } else {
            self.digits = OTPToken.defaultDigits()
        }

        switch token?.core.factor {
        case let .Some(.Counter(counter)):
            self.type = .Counter
            self.period = OTPToken.defaultPeriod()
            self.counter = counter
        case let .Some(.Timer(period)):
            self.type = .Timer
            self.period = period
            self.counter = OTPToken.defaultInitialCounter()
        default:
            self.type = .Timer
            self.period = OTPToken.defaultPeriod()
            self.counter = OTPToken.defaultInitialCounter()
        }
    }

    required override public init() {
        name = ""
        issuer = ""
        secret = NSData()
        type = .Timer
        period = OTPToken.defaultPeriod()
        counter = OTPToken.defaultInitialCounter()
        algorithm = OTPToken.defaultAlgorithm()
        digits = OTPToken.defaultDigits()
    }

    class func tokenWithType(type: OTPTokenType, secret: NSData, name: NSString, issuer:NSString) -> Self {
        let token = self()
        token.type = type
        token.secret = secret
        token.name = name
        token.issuer = issuer
        return token
    }

    public var name: String
    public var issuer: String
    public var type: OTPTokenType
    public var secret: NSData
    public var algorithm: OTPAlgorithm
    public var digits: UInt
    public var period: NSTimeInterval
    public var counter: UInt64

    public class func defaultAlgorithm() -> OTPAlgorithm {
        return .SHA1
    }
    public class func defaultDigits() -> UInt {
        return 6
    }
    public class func defaultInitialCounter() -> UInt64 {
        return 0
    }
    public class func defaultPeriod() -> NSTimeInterval {
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
                switch newToken.core.factor {
                case let .Counter(counter):
                    self.counter = counter
                default:
                    break
                }
            }
        }
    }

    func generatePasswordForCounter(counter: UInt64) -> String? {
        if let token = token {
            return generatePassword(token.core.algorithm, token.core.digits, token.core.secret, counter)
        }
        return nil
    }
}

public extension OTPToken {
    class func tokenWithURL(url: NSURL) -> Self? {
        if let urlString = url.absoluteString {
            if let token = Token.URLSerializer.deserialize(urlString) {
                return self(token: token)
            }
        }
        return nil
    }

    class func tokenWithURL(url: NSURL, secret: NSData? = nil) -> Self? {
        if let urlString = url.absoluteString {
            if let token = Token.URLSerializer.deserialize(urlString, secret: secret) {
                return self(token: token)
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

    class func tokenWithKeychainItem(keychainItem: Token.KeychainItem) -> Self {
        let otp = self(token: keychainItem.token)
        otp.keychainItem = keychainItem
        return otp
    }

    class func tokenWithKeychainItemRef(keychainItemRef: NSData) -> Self? {
        if let keychainItem = Token.KeychainItem.keychainItemWithKeychainItemRef(keychainItemRef) {
            return self.tokenWithKeychainItem(keychainItem)
        }
        return nil
    }

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
