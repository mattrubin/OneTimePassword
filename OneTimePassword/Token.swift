//
//  Token.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/7/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

public struct Token: Equatable {
    public let name: String
    public let issuer: String
    public let core: Generator

    public init(name: String = "", issuer: String = "", core: Generator) {
        self.name = name
        self.issuer = issuer
        self.core = core
    }
}

public func ==(lhs: Token, rhs: Token) -> Bool {
    return (lhs.name == rhs.name)
        && (lhs.issuer == rhs.issuer)
        && (lhs.core == rhs.core)
}

public func updatedToken(token: Token) -> Token {
    switch token.core.factor {
    case .Counter(let counter):
        let updatedGenerator = Generator(factor: .Counter(counter + 1), secret: token.core.secret, algorithm: token.core.algorithm, digits: token.core.digits)
        return Token(name: token.name, issuer: token.issuer, core: updatedGenerator)
    case .Timer:
        return token
    }
}
