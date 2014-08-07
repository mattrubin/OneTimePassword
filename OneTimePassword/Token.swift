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
    public var secret: NSData { return core.secret }
    public var algorithm: Algorithm { return core.algorithm }
    public var digits: Int { return core.digits }

    public let core: Generator

    public init(type: Generator.TokenType, secret: NSData, name: String = "", issuer: String = "", algorithm: Algorithm = .SHA1, digits: Int = 6) {
        self.name = name
        self.issuer = issuer
        self.core = Generator(type: type, secret: secret, algorithm: algorithm, digits: digits)
    }

    public init(name: String = "", issuer: String = "", core: Generator) {
        self.name = name
        self.issuer = issuer
        self.core = core
    }

    public typealias Algorithm = Generator.Algorithm
}

public func updatedToken(token: Token) -> Token {
    return Token(name: token.name, issuer: token.issuer, core: updatedGenerator(token.core))
}
