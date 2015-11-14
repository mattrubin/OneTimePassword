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
    public let generator: Generator

    /**
    Initializes a new token with the given parameters.

    - parameter name:       The account name for the token (defaults to "")
    - parameter issure:     The entity which issued the token (defaults to "")
    - parameter generator:  The password generator

    - returns: A new token with the given parameters.
    */
    public init(name: String = defaultName, issuer: String = defaultIssuer, generator: Generator) {
        self.name = name
        self.issuer = issuer
        self.generator = generator
    }

    // MARK: Defaults

    /// The default token name, an empty string.
    public static let defaultName: String = ""

    /// The default token issuer, an empty string.
    public static let defaultIssuer: String = ""

    // MARK: Password Generation

    /**
    Calculates the current password based on the token's generator. The password generated
    will be consistent for a counter-based token, but for a timer-based token the password
    will depend on the current time when this property is accessed.

    - returns: The current password, or `nil` if a password could not be generated.
    */
    public var currentPassword: String? {
        let currentTime = NSDate().timeIntervalSince1970
        return try? generator.passwordAtTime(currentTime)
    }

    // MARK: Update

    /// - returns: A new `Token`, configured to generate the next password.
    @warn_unused_result
    public func updatedToken() -> Token {
        return Token(name: name, issuer: issuer, generator: generator.successor())
    }
}

/// Compares two `Token`s for equality.
public func == (lhs: Token, rhs: Token) -> Bool {
    return (lhs.name == rhs.name)
        && (lhs.issuer == rhs.issuer)
        && (lhs.generator == rhs.generator)
}
