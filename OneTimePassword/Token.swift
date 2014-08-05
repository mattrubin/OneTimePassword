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

    public init(type: TokenType, secret: NSData, name: String = "", issuer: String = "", algorithm: Algorithm = .SHA1, digits: Int = 6) {
        self.type = type
        self.secret = secret
        self.name = name
        self.issuer = issuer
        self.algorithm = algorithm
        self.digits = digits
    }
}

public extension Token {
    var isValid: Bool {
        let validSecret = (secret.length > 0)
        let validDigits = (digits >= 6) && (digits <= 8)
        var validPeriod = true
        switch type {
        case .Timer(let period):
            validPeriod = (period > 0) && (period <= 300)
        default:
            break
        }


        return validSecret && validDigits && validPeriod
    }

    var description: String {
        return "Token(type:\(type), name:\(name), issuer:\(issuer), algorithm:\(algorithm.toRaw()), digits:\(digits))"
    }

    enum TokenType {
        case Counter(UInt64)
        case Timer(NSTimeInterval)
    }

    enum Algorithm : String {
        case SHA1   = "SHA1",
             SHA256 = "SHA256",
             SHA512 = "SHA512"
    }
}
