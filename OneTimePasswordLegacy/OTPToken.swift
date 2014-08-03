//
//  OTPToken.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import OneTimePassword

public class OTPToken: NSObject {
    var token: Token
    var keychainItem: Token.KeychainItem?

    required public init(token: Token) {
        self.token = token
    }

    convenience init() {
        // Stub an invalid token, to be replaced with a modified token via the setters
        self.init(token: Token(type: .Timer, secret: NSData()))
    }

    class func tokenWithType(type: OTPTokenType, secret: NSData, name: NSString, issuer:NSString) -> Self {
        return self(token: Token(type: type, secret: secret, name: name, issuer: issuer))
    }

    public var name: String {
    get { return token.name }
    set { token = Token(type: type, secret: secret, name: newValue, issuer: issuer, algorithm: algorithm, digits: token.digits, period: period, counter: counter) }
    }
    public var issuer: String {
    get { return token.issuer }
    set { token = Token(type: type, secret: secret, name: name, issuer: newValue, algorithm: algorithm, digits: token.digits, period: period, counter: counter) }
    }
    public var type: OTPTokenType {
    get { return token.type }
    set { token = Token(type: newValue, secret: secret, name: name, issuer: issuer, algorithm: algorithm, digits: token.digits, period: period, counter: counter) }
    }
    public var secret: NSData {
    get { return token.secret }
    set { token = Token(type: type, secret: newValue, name: name, issuer: issuer, algorithm: algorithm, digits: token.digits, period: period, counter: counter) }
    }
    public var algorithm: OTPAlgorithm {
    get { return token.algorithm }
    set { token = Token(type: type, secret: secret, name: name, issuer: issuer, algorithm: newValue, digits: token.digits, period: period, counter: counter) }
    }
    public var digits: UInt {
    get { return UInt(token.digits) }
    set { token = Token(type: type, secret: secret, name: name, issuer: issuer, algorithm: algorithm, digits: Int(newValue), period: period, counter: counter) }
    }
    public var period: NSTimeInterval {
    get { return token.period }
    set { token = Token(type: type, secret: secret, name: name, issuer: issuer, algorithm: algorithm, digits: token.digits, period: newValue, counter: counter) }
    }
    public var counter: UInt64 {
    get { return token.counter }
    set { token = Token(type: type, secret: secret, name: name, issuer: issuer, algorithm: algorithm, digits: token.digits, period: period, counter: newValue) }
    }

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

    public func validate() -> Bool { return token.isValid }
    override public var description: String { return token.description }
}

public extension OTPToken {
    var password: String? { return token.password() }
    func updatePassword() { token = token.updatedToken() }

    func generatePasswordForCounter(counter: UInt64) -> String? {
        return token.passwordForCounter(counter)
    }
}

public extension OTPToken {
    class func tokenWithURL(url: NSURL) -> Self? {
        if let token = Token.tokenWithURL(url) {
            return self(token: token)
        }
        return nil
    }

    class func tokenWithURL(url: NSURL, secret: NSData? = nil) -> Self? {
        if let token = Token.tokenWithURL(url, secret: secret) {
            return self(token: token)
        }
        return nil
    }

    func url() -> NSURL { return token.url }
}

public extension OTPToken {
    var keychainItemRef: NSData? {return self.keychainItem?.persistentRef }
    var isInKeychain: Bool { return (keychainItemRef != nil) }

    func saveToKeychain() -> Bool {
        if let keychainItem = self.keychainItem {
            if let newKeychainItem = updateKeychainItemWithToken(keychainItem, self.token) {
                self.keychainItem = newKeychainItem
                return true
            }
            return false
        } else {
            if let newKeychainItem = addTokenToKeychain(self.token) {
                self.keychainItem = newKeychainItem
                return true
            }
            return false
        }
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

    class func tokenWithKeychainItem(item: Token.KeychainItem?) -> Self? {
        if let keychainItem = item {
            return self.tokenWithKeychainItem(keychainItem)
        }
        return nil
    }

    class func tokenWithKeychainItem(keychainItem: Token.KeychainItem) -> Self {
        let otp = self(token: keychainItem.token)
        otp.keychainItem = keychainItem
        return otp
    }

    class func tokenWithKeychainItemRef(keychainItemRef: NSData) -> Self? {
        return self.tokenWithKeychainItem(Token.KeychainItem.keychainItemWithKeychainItemRef(keychainItemRef))
    }

    class func tokenWithKeychainDictionary(keychainDictionary: NSDictionary) -> Self? {
        return self.tokenWithKeychainItem(Token.KeychainItem.keychainItemWithDictionary(keychainDictionary))
    }
}

extension Token.TokenType {
    func __conversion() -> OTPTokenType {
        switch self {
        case .Counter: return .Counter
        case .Timer:   return .Timer
        }
    }
}

extension OTPTokenType {
    func __conversion() -> Token.TokenType {
        switch self {
        case .Counter: return .Counter
        case .Timer:   return .Timer
        }
    }
}

extension Token.Algorithm {
    func __conversion() -> OTPAlgorithm {
        switch self {
        case .SHA1:   return .SHA1
        case .SHA256: return .SHA256
        case .SHA512: return .SHA512
        }
    }
}

extension OTPAlgorithm {
    func __conversion() -> Token.Algorithm {
        switch self {
        case .SHA1:   return .SHA1
        case .SHA256: return .SHA256
        case .SHA512: return .SHA512
        }
    }
}
