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
    public var type: TokenType { return core.type }
    public var secret: NSData { return core.secret }
    public var algorithm: Algorithm { return core.algorithm }
    public var digits: Int { return core.digits }

    public let core: Generator

    public init(type: TokenType, secret: NSData, name: String = "", issuer: String = "", algorithm: Algorithm = .SHA1, digits: Int = 6) {
        self.name = name
        self.issuer = issuer
        self.core = Generator(type: type, secret: secret, algorithm: algorithm, digits: digits)
    }

    public init(name: String = "", issuer: String = "", core: Generator) {
        self.name = name
        self.issuer = issuer
        self.core = core
    }

    public enum TokenType {
        case Counter(UInt64)
        case Timer(period: NSTimeInterval)
    }

    public enum Algorithm {
        case SHA1, SHA256, SHA512
    }

    public struct Generator {
        public let type: TokenType
        public let secret: NSData
        public let algorithm: Algorithm
        public let digits: Int

        public init(type: TokenType, secret: NSData, algorithm: Algorithm = .SHA1, digits: Int = 6) {
            self.type = type
            self.secret = secret
            self.algorithm = algorithm
            self.digits = digits
        }
    }
}
