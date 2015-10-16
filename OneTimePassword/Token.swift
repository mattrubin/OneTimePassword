//
//  Token.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/7/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

/// A `Token` contains a password generator and information identifying the corresponding account.
public struct Token: Equatable {

    /// A string indicating the account represented by the token. This is often an email address or username.
    public let name: String

    /// A string indicating the provider or service which issued the token.
    public let issuer: String

    /// A password generator containing this token's secret, algorithm, etc.
    public let core: Generator

    /**
    Initializes a new token with the given parameters.

    - parameter name:        The user name for the token (defaults to "")
    - parameter issure:      The entity which issued the token (defaults to "")
    - parameter core:        The password generator

    - returns: A new token with the given parameters.
    */
    public init(name: String = defaultName, issuer: String = defaultIssuer, core: Generator) {
        self.name = name
        self.issuer = issuer
        self.core = core
    }

    public static let defaultName: String = ""
    public static let defaultIssuer: String = ""
}

public func ==(lhs: Token, rhs: Token) -> Bool {
    return (lhs.name == rhs.name)
        && (lhs.issuer == rhs.issuer)
        && (lhs.core == rhs.core)
}

/**
- parameter token:   The current token
- returns: A new token, configured to generate the next password.
*/
public func updatedToken(token: Token) -> Token? {
    switch token.core.factor {
    case .Counter(let counter):
        if let updatedGenerator = Generator(factor: .Counter(counter + 1), secret: token.core.secret, algorithm: token.core.algorithm, digits: token.core.digits) {
            return Token(name: token.name, issuer: token.issuer, core: updatedGenerator)
        }
        return nil
    case .Timer:
        return token
    }
}
