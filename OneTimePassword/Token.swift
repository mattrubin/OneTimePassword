//
//  Token.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/7/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

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

    public enum TokenType {
        case Counter(UInt64)
        case Timer(period: NSTimeInterval)
    }

    public enum Algorithm {
        case SHA1, SHA256, SHA512
    }
}
