//
//  OTPToken.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

class OTPToken: NSObject {
    var token: Token

    init(token: Token) {
        self.token = token
    }

    convenience init() {
        // Stub an invalid token, to be replaced with a modified token via the setters
        self.init(token: Token(type: .Timer, secret: NSData()))
    }

    var name: String {
    get { return token.name }
    set { token = Token(type: type, secret: secret, name: newValue, issuer: issuer, algorithm: algorithm, digits: digits, period: period, counter: counter) }
    }
    var issuer: String {
    get { return token.issuer }
    set { token = Token(type: type, secret: secret, name: name, issuer: newValue, algorithm: algorithm, digits: digits, period: period, counter: counter) }
    }
    var type: OTPTokenType {
    get { return token.type }
    set { token = Token(type: newValue, secret: secret, name: name, issuer: issuer, algorithm: algorithm, digits: digits, period: period, counter: counter) }
    }
    var secret: NSData {
    get { return token.secret }
    set { token = Token(type: type, secret: newValue, name: name, issuer: issuer, algorithm: algorithm, digits: digits, period: period, counter: counter) }
    }
    var algorithm: OTPAlgorithm {
    get { return token.algorithm }
    set { token = Token(type: type, secret: secret, name: name, issuer: issuer, algorithm: newValue, digits: digits, period: period, counter: counter) }
    }
    var digits: Int {
    get { return token.digits }
    set { token = Token(type: type, secret: secret, name: name, issuer: issuer, algorithm: algorithm, digits: newValue, period: period, counter: counter) }
    }
    var period: NSTimeInterval {
    get { return token.period }
    set { token = Token(type: type, secret: secret, name: name, issuer: issuer, algorithm: algorithm, digits: digits, period: newValue, counter: counter) }
    }
    var counter: UInt64 {
    get { return token.counter }
    set { token = Token(type: type, secret: secret, name: name, issuer: issuer, algorithm: algorithm, digits: digits, period: period, counter: newValue) }
    }

    func validate() -> Bool { return token.isValid() }
    override var description: String { return token.description }

    // Generation

    func password() -> String? { return token.password() }
    func updatePassword() { token = token.updatedToken() }

    func generatePasswordForCounter(counter: UInt64) -> String? {
        return token.passwordForCounter(counter)
    }

    // Serialization

    class func tokenWithURL(url: NSURL) -> OTPToken? {
        if let token = Token.tokenWithURL(url) {
            return OTPToken(token: token)
        }
        return nil
    }

    class func tokenWithURL(url: NSURL, secret: NSData? = nil) -> OTPToken? {
        if let token = Token.tokenWithURL(url, secret: secret) {
            return OTPToken(token: token)
        }
        return nil
    }

    var url: NSURL { return token.url() }

    // Persistence

    var keychainItem: Token.KeychainItem?
    var keychainItemRef: NSData? {return self.keychainItem?.keychainItemRef }
    var isInKeychain: Bool { return (keychainItemRef != nil) }

    func saveToKeychain() -> Bool {
        if let keychainRef = self.keychainItem?.keychainItemRef {
            return updateKeychainItemForPersistentRefWithURL(keychainRef, self.url)
        } else {
            self.keychainItem = addTokenToKeychain(self.token)
            return (self.keychainItem != nil)
        }
    }

    func removeFromKeychain() -> Bool {
        if let success = self.keychainItem?.removeFromKeychain() {
            self.keychainItem = nil
            return true
        }
        return false
    }

    class func allTokensInKeychain() -> Array<OTPToken> {
        return Token.KeychainItem.allKeychainItems().map(self.tokenWithKeychainItem)
    }

    class func tokenWithKeychainItem(item: Token.KeychainItem?) -> OTPToken? {
        if let keychainItem = item {
            return tokenWithKeychainItem(keychainItem)
        }
        return nil
    }

    class func tokenWithKeychainItem(keychainItem: Token.KeychainItem) -> OTPToken {
        let otp = OTPToken(token: keychainItem.token)
        otp.keychainItem = keychainItem
        return otp
    }

    class func tokenWithKeychainItemRef(keychainItemRef: NSData) -> OTPToken? {
        return OTPToken.tokenWithKeychainItem(Token.KeychainItem.keychainItemWithKeychainItemRef(keychainItemRef))
    }

    class func tokenWithKeychainDictionary(keychainDictionary: NSDictionary) -> OTPToken? {
        return OTPToken.tokenWithKeychainItem(Token.KeychainItem.keychainItemWithDictionary(keychainDictionary))
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
