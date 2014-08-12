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

public protocol TokenSerializer {
    class func serialize(token: Token) -> String
    class func deserialize(string: String, secret: NSData?) -> Token?
}
