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

    convenience override init() {
        // Stub an invalid token, to be replaced with a modified token via the setters
        self.init(token: Token(type: .Timer(period: 30), secret: NSData()))
    }

    class func tokenWithType(type: OTPTokenType, secret: NSData, name: NSString, issuer:NSString) -> Self {
        switch type {
        case .Counter:
            return self(token: Token(type: .Counter(0), secret: secret, name: name, issuer: issuer))
        case .Timer:
            return self(token: Token(type: .Timer(period: 30), secret: secret, name: name, issuer: issuer))
        }
    }

    public var name: String {
        get { return token.name }
        set { token = Token(type: token.type, secret: secret, name: newValue, issuer: issuer, algorithm: token.algorithm, digits: token.digits) }
    }

    public var issuer: String {
        get { return token.issuer }
        set { token = Token(type: token.type, secret: secret, name: name, issuer: newValue, algorithm: token.algorithm, digits: token.digits) }
    }

    public var type: OTPTokenType {
        get {
            switch token.type {
            case .Counter: return .Counter
            case .Timer:   return .Timer
            }
        }
        set {
            switch newValue {
            case .Counter:
                token = Token(type: .Counter(_counter), secret: secret, name: name, issuer: issuer, algorithm: token.algorithm, digits: token.digits)
            case .Timer:
                token = Token(type: .Timer(period: _period), secret: secret, name: name, issuer: issuer, algorithm: token.algorithm, digits: token.digits)
            }
        }
    }

    public var secret: NSData {
        get { return token.secret }
        set { token = Token(type: token.type, secret: newValue, name: name, issuer: issuer, algorithm: token.algorithm, digits: token.digits) }
    }

    public var algorithm: OTPAlgorithm {
        get {
            switch token.algorithm {
            case .SHA1:   return .SHA1
            case .SHA256: return .SHA256
            case .SHA512: return .SHA512
            }
        }
        set {
            let newAlgorithm: Token.Algorithm = ({
                switch $0 {
                case .SHA1:   return .SHA1
                case .SHA256: return .SHA256
                case .SHA512: return .SHA512
                }
            })(newValue)
            token = Token(type: token.type, secret: secret, name: name, issuer: issuer, algorithm: newAlgorithm, digits: token.digits)
        }
    }

    public var digits: UInt {
        get { return UInt(token.digits) }
        set { token = Token(type: token.type, secret: secret, name: name, issuer: issuer, algorithm: token.algorithm, digits: Int(newValue)) }
    }

    private var _period: NSTimeInterval = 30
    public var period: NSTimeInterval {
        get {
            switch token.type {
            case .Timer(let period):
                _period = period
            default: break
            }
            return _period
        }
        set {
            _period = newValue
            switch token.type {
            case .Timer:
                token = Token(type: .Timer(period: _period), secret: secret, name: name, issuer: issuer, algorithm: token.algorithm, digits: token.digits)
            default: break
            }
        }
    }

    private var _counter: UInt64 = 0
    public var counter: UInt64 {
        get {
            switch token.type {
            case .Counter(let counter):
                _counter = counter
            default: break
            }
            return _counter
        }
        set {
            _counter = newValue
            switch token.type {
            case .Counter:
                token = Token(type: .Counter(_counter), secret: secret, name: name, issuer: issuer, algorithm: token.algorithm, digits: token.digits)
            default: break
            }
        }
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
}

public extension OTPToken {
    var password: String? { return token.password }
    func updatePassword() { token = updatedToken(token) }

    func generatePasswordForCounter(counter: UInt64) -> String? {
        return generatePassword(token.algorithm, token.digits, token.secret, counter)
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
