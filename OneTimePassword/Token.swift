//
//  Token.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/7/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

public struct Token {
    public let name: String
    public let issuer: String
    public let type: TokenType
    public let secret: NSData
    public let algorithm: Algorithm
    public let digits: Int
    public let period: NSTimeInterval
    public let counter: UInt64

    public init(type: TokenType, secret: NSData, name: String = "", issuer: String = "", algorithm: Algorithm = .SHA1, digits: Int = 6, period: NSTimeInterval = 30, counter: UInt64 = 0) {
        self.type = type
        self.secret = secret
        self.name = name
        self.issuer = issuer
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
        self.counter = counter
    }
}

public extension Token {
    var isValid: Bool {
        let validType = (type == .Counter) || (type == .Timer)
        let validSecret = (secret.length > 0)
        let validAlgorithm = (algorithm == .SHA1) || (algorithm == .SHA256) || (algorithm == .SHA512)
        let validDigits = (digits >= 6) && (digits <= 8)
        let validPeriod = (period > 0) && (period <= 300)

        return validType && validSecret && validAlgorithm && validDigits && validPeriod
    }

    var description: String {
        return "Token(type:\(type.toRaw()), name:\(name), issuer:\(issuer), algorithm:\(algorithm.toRaw()), digits:\(digits))"
    }

    enum TokenType : String {
        case Counter = "hotp",
             Timer   = "totp"
    }

    enum Algorithm : String {
        case SHA1   = "SHA1",
             SHA256 = "SHA256",
             SHA512 = "SHA512"
    }
}
