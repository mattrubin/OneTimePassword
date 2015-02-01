//
//  OTPToken.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import OneTimePassword

public class OTPToken: NSObject {
    var token: Token?
    var keychainItem: Token.KeychainItem?

    required public init(token: Token?) {
        self.token = token
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

    convenience override init() {
        // Stub an invalid token, to be replaced with a modified token via the setters
        if let generator = Generator(factor: .Timer(period: 30), secret: NSData()) {
            self.init(token: Token(core: generator))
        } else {
            self.init(token: nil)
        }
    }

    class func tokenWithType(type: OTPTokenType, secret: NSData, name: NSString, issuer:NSString) -> Self {
        switch type {
        case .Counter:
            if let generator = Generator(factor: .Counter(0), secret: secret) {
                return self(token: Token(name: name, issuer: issuer, core: generator))
            }
        case .Timer:
            if let generator = Generator(factor: .Timer(period: 30), secret: secret) {
                return self(token: Token(name: name, issuer: issuer, core: generator))
            }
        }
        return self(token: nil)
    }

    public var name: String {
        didSet {
            if let token = token {
                self.token = Token(name: name, issuer: token.issuer, core: token.core)
            }
        }
    }

    public var issuer: String {
        didSet {
            if let token = token {
                self.token = Token(name: token.name, issuer: issuer, core: token.core)
            }
        }
    }

    public var type: OTPTokenType {
        didSet {
            switch type {
            case .Counter:
                if let token = token {
                    if let generator = Generator(
                        factor: .Counter(counter),
                        secret: token.core.secret,
                        algorithm: token.core.algorithm,
                        digits: token.core.digits
                        ) {
                            self.token = Token(
                                name: token.name,
                                issuer: token.issuer,
                                core: generator
                            )
                    }
                }
            case .Timer:
                if let token = token {
                    if let generator = Generator(
                        factor: .Timer(period: period),
                        secret: token.core.secret,
                        algorithm: token.core.algorithm,
                        digits: token.core.digits
                        ) {
                            self.token = Token(
                                name: token.name,
                                issuer: token.issuer,
                                core: generator
                            )
                    }
                }
            }
        }
    }

    public var secret: NSData {
        didSet {
            if let token = token {
                if let generator = Generator(
                    factor: token.core.factor,
                    secret: secret,
                    algorithm: token.core.algorithm,
                    digits: token.core.digits
                    ) {
                        self.token = Token(
                            name: token.name,
                            issuer: token.issuer,
                            core: generator
                        )
                }
            }
        }
    }

    public var algorithm: OTPAlgorithm {
        didSet {
            let newAlgorithm = generatorAlgorithm(algorithm)
            if let token = token {
                if let generator = Generator(
                    factor: token.core.factor,
                    secret: token.core.secret,
                    algorithm: newAlgorithm,
                    digits: token.core.digits
                    ) {
                        self.token = Token(
                            name: token.name,
                            issuer: token.issuer,
                            core: generator
                        )
                }
            }
        }
    }

    public var digits: UInt {
        didSet {
            if let token = token {
                if let generator = Generator(
                    factor: token.core.factor,
                    secret: token.core.secret,
                    algorithm: token.core.algorithm,
                    digits: Int(digits)
                    ) {
                        self.token = Token(
                            name: token.name,
                            issuer: token.issuer,
                            core: generator
                        )
                }
            }
        }
    }

    public var period: NSTimeInterval {
        didSet {
            if let token = token {
                switch token.core.factor {
                case .Timer:
                    if let generator = Generator(
                        factor: .Timer(period: period),
                        secret: token.core.secret,
                        algorithm: token.core.algorithm,
                        digits: token.core.digits
                        ) {
                            self.token = Token(
                                name: token.name,
                                issuer: token.issuer,
                                core: generator
                            )
                    }
                default: break
                }
            }
        }
    }

    public var counter: UInt64 {
        didSet {
            if let token = token {
                switch token.core.factor {
                case .Counter:
                    if let generator = Generator(
                        factor: .Counter(counter),
                        secret: token.core.secret,
                        algorithm: token.core.algorithm,
                        digits: token.core.digits
                        ) {
                            self.token = Token(
                                name: token.name,
                                issuer: token.issuer,
                                core: generator
                            )
                    }
                default: break
                }
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
            self.token = updatedToken(token)
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
