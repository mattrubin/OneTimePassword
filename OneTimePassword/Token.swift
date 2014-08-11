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
    public let core: Generator

    public init(name: String = "", issuer: String = "", core: Generator) {
        self.name = name
        self.issuer = issuer
        self.core = core
    }
}

public func updatedToken(token: Token) -> Token {
    return Token(name: token.name, issuer: token.issuer, core: updatedGenerator(token.core))
}

public extension Token {
    static func tokenWithURL(url: NSURL, secret: NSData? = nil) -> Token? {
        return tokenFromURL(url, secret: secret)
    }
    
    var url: NSURL {
        return urlForToken(name: self.name, issuer: self.issuer, factor: self.core.factor, algorithm: self.core.algorithm, digits: self.core.digits)
    }
}
