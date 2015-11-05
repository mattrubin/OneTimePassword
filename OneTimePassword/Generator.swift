//
//  Generator.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

/// A `Generator` contains all of the parameters needed to generate a one-time password.
public struct Generator: Equatable {

    /// The moving factor, either timer- or counter-based.
    public let factor: Factor

    /// The secret shared between the client and server.
    public let secret: NSData

    /// The cryptographic hash function used to generate the password.
    public let algorithm: Algorithm

    /// The number of digits in the password.
    public let digits: Int

    /**
    Initializes a new password generator with the given parameters, if valid.

    - parameter factor:      The moving factor
    - parameter secret:      The shared secret
    - parameter algorithm:   The cryptographic hash function (defaults to SHA-1)
    - parameter digits:      The number of digits in the password (defaults to 6)

    - returns: A valid password generator, or `nil` if the parameters are invalid.
    */
    public init(factor: Factor, secret: NSData, algorithm: Algorithm = defaultAlgorithm, digits: Int = defaultDigits) {
        self.factor = factor
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
    }

    /**
    A moving factor with which a generator produces different one-time passwords over time.

    Counter:
        Indicates a HOTP, with an associated 8-byte counter value for the moving factor. After
        each use of the password generator, the counter should be incremented to stay in sync with
        the server.
    Timer:
        Indicates a TOTP, with an associated time interval for calculating the time-based moving
        factor. This period value remains constant, and is used as a divisor for the number of
        seconds since the Unix epoch.
    */
    public enum Factor: Equatable {
        case Counter(UInt64)
        case Timer(period: NSTimeInterval)
    }

    /// A cryptographic hash function used to calculate the HMAC from which a password is derived.
    /// The supported algorithms are SHA-1, SHA-256, and SHA-512
    public enum Algorithm: Equatable {
        case SHA1, SHA256, SHA512
    }

    public static let defaultAlgorithm: Algorithm = .SHA1
    public static let defaultDigits: Int = 6
}

public func ==(lhs: Generator, rhs: Generator) -> Bool {
    return (lhs.factor == rhs.factor)
        && (lhs.algorithm == rhs.algorithm)
        && (lhs.secret == rhs.secret)
        && (lhs.digits == rhs.digits)
}

public func ==(lhs: Generator.Factor, rhs: Generator.Factor) -> Bool {
    switch (lhs, rhs) {
    case let (.Counter(l), .Counter(r)):
        return l == r
    case let (.Timer(l), .Timer(r)):
        return l == r
    default:
        return false
    }
}

public extension Generator {
    var isValid: Bool {
        switch factor {
        case .Counter:
            return validateDigits(digits)
        case .Timer(let period):
            return validateDigits(digits) && validatePeriod(period)
        }
    }

    /**
    Calculates the current password based on the generator's configuration. The password generated
    will be consistent for a counter-based generator, but for a timer-based generator the password
    will depend on the current time when this method is called.

    Note: Calling this method does *not* increment the counter of a counter-based generator.

    - returns: The current password, or `nil` if a password could not be generated.
    */
    var password: String? {
        do {
            let counter = try counterForGeneratorWithFactor(factor, atTimeIntervalSince1970: NSDate().timeIntervalSince1970)
            let password = try generatePassword(algorithm: algorithm, digits: digits, secret: secret, counter: counter)
            return password
        } catch {
            return nil
        }
    }
}
