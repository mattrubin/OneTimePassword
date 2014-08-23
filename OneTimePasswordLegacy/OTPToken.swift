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
        self.init(token: Token(core: Generator(factor: .Timer(30), secret: NSData())))
    }

    class func tokenWithType(type: OTPTokenType, secret: NSData, name: NSString, issuer:NSString) -> Self {
        switch type {
        case .Counter:
            return self(token: Token(name: name, issuer: issuer, core: Generator(factor: .Counter(0), secret: secret)))
        case .Timer:
            return self(token: Token(name: name, issuer: issuer, core: Generator(factor: .Timer(30), secret: secret)))
        }
    }

    public var name: String {
        get { return token.name }
        set { token = Token(name: newValue, issuer: token.issuer, core: token.core) }
    }

    public var issuer: String {
        get { return token.issuer }
        set { token = Token(name: token.name, issuer: newValue, core: token.core) }
    }

    public var type: OTPTokenType {
        get {
            switch token.core.factor {
            case .Counter: return .Counter
            case .Timer:   return .Timer
            }
        }
        set {
            switch newValue {
            case .Counter:
                token = Token(
                    name: token.name,
                    issuer: token.issuer,
                    core: Generator(
                        factor: .Counter(_counter),
                        secret: token.core.secret,
                        algorithm: token.core.algorithm,
                        digits: token.core.digits
                    )
                )
            case .Timer:
                token = Token(
                    name: token.name,
                    issuer: token.issuer,
                    core: Generator(
                        factor: .Timer(_period),
                        secret: token.core.secret,
                        algorithm: token.core.algorithm,
                        digits: token.core.digits
                    )
                )
            }
        }
    }

    public var secret: NSData {
        get { return token.core.secret }
        set {
            token = Token(
                name: token.name,
                issuer: token.issuer,
                core: Generator(
                    factor: token.core.factor,
                    secret: newValue,
                    algorithm: token.core.algorithm,
                    digits: token.core.digits
                )
            )
        }
    }

    public var algorithm: OTPAlgorithm {
        get {
            switch token.core.algorithm {
            case .SHA1:   return .SHA1
            case .SHA256: return .SHA256
            case .SHA512: return .SHA512
            }
        }
        set {
            let newAlgorithm: OneTimePassword.Generator.Algorithm = ({
                switch $0 {
                case .SHA1:   return .SHA1
                case .SHA256: return .SHA256
                case .SHA512: return .SHA512
                }
            })(newValue)
            token = Token(
                name: token.name,
                issuer: token.issuer,
                core: Generator(
                    factor: token.core.factor,
                    secret: token.core.secret,
                    algorithm: newAlgorithm,
                    digits: token.core.digits
                )
            )
        }
    }

    public var digits: UInt {
        get { return UInt(token.core.digits) }
        set {
            token = Token(
                name: token.name,
                issuer: token.issuer,
                core: Generator(
                    factor: token.core.factor,
                    secret: token.core.secret,
                    algorithm: token.core.algorithm,
                    digits: Int(newValue)
                )
            )
        }
    }

    private var _period: NSTimeInterval = 30
    public var period: NSTimeInterval {
        get {
            switch token.core.factor {
            case .Timer(let period):
                _period = period
            default: break
            }
            return _period
        }
        set {
            _period = newValue
            switch token.core.factor {
            case .Timer:
                token = Token(
                    name: token.name,
                    issuer: token.issuer,
                    core: Generator(
                        factor: .Timer(_period),
                        secret: token.core.secret,
                        algorithm: token.core.algorithm,
                        digits: token.core.digits
                    )
                )
            default: break
            }
        }
    }

    private var _counter: UInt64 = 0
    public var counter: UInt64 {
        get {
            switch token.core.factor {
            case .Counter(let counter):
                _counter = counter
            default: break
            }
            return _counter
        }
        set {
            _counter = newValue
            switch token.core.factor {
            case .Counter:
                token = Token(
                    name: token.name,
                    issuer: token.issuer,
                    core: Generator(
                        factor: .Counter(_counter),
                        secret: token.core.secret,
                        algorithm: token.core.algorithm,
                        digits: token.core.digits
                    )
                )
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

    public func validate() -> Bool { return token.core.isValid }
}

public extension OTPToken {
    var password: String? { return token.core.password }
    func updatePassword() { token = updatedToken(token) }

    func generatePasswordForCounter(counter: UInt64) -> String? {
        return generatePassword(token.core.algorithm, token.core.digits, token.core.secret, counter)
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

    func url() -> NSURL { return NSURL(string: Token.URLSerializer.serialize(token)) }
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
