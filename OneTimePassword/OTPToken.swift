//
//  OTPToken.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

class OTPTokenBridge: NSObject {
    let token: Token

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
    set { token.counter = newValue }
    }

    var isValid: Bool { return token.isValid() }

    // Serialization

    class func token(URL url: NSURL, secret: NSData?) -> OTPTokenBridge? {

        if let token = Token.token(URL: url, secret: secret) {
            return OTPTokenBridge(token: token)
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
