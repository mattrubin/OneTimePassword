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
        self.init(token: Token(classicType:type, secret:secret, name:name, issuer:issuer, algorithm:algorithm, digits:digits, period:period))
    }

    var name: String { return token.name }
    var issuer: String { return token.issuer }
    var secret: NSData { return token.secret }
    var digits: Int { return token.digits }
    var period: NSTimeInterval { return token.period }

    var type: OTPTokenType {
    switch token.type {
    case .Counter: return .Counter
    case .Timer:   return .Timer
        }
    }

    var algorithm: OTPAlgorithm {
    switch token.algorithm {
    case .SHA1:   return .SHA1
    case .SHA256: return .SHA256
    case .SHA512: return .SHA512
        }
    }

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