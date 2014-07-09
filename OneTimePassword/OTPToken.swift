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

    convenience init(type: OTPTokenType, secret: NSData, name: String, issuer: String, algorithm: OTPAlgorithm, digits: Int, period: NSTimeInterval) {
        self.init(token: Token(type:type, secret:secret, name:name, issuer:issuer, algorithm:algorithm, digits:digits, period:period))
    }

    var name: String { return token.name }
    var issuer: String { return token.issuer }
    var type: OTPTokenType { return token.type }
    var secret: NSData { return token.secret }
    var algorithm: OTPAlgorithm { return token.algorithm }
    var digits: Int { return token.digits }
    var period: NSTimeInterval { return token.period }

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
