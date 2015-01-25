//
//  Generator.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

public struct Generator: Equatable {
    public let factor: Factor
    public let secret: NSData
    public let algorithm: Algorithm
    public let digits: Int

    public init?(factor: Factor, secret: NSData, algorithm: Algorithm = .SHA1, digits: Int = 6) {
        if !validateGenerator(factor, secret, algorithm, digits) {
            return nil
        }
        self.factor = factor
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
    }

    public enum Factor: Equatable {
        case Counter(UInt64)
        case Timer(period: NSTimeInterval)
    }

    public enum Algorithm: Equatable {
        case SHA1, SHA256, SHA512
    }
}

public func ==(lhs: Generator, rhs: Generator) -> Bool {
    return (lhs.factor == rhs.factor)
        && (lhs.algorithm == rhs.algorithm)
        && (lhs.secret == rhs.secret)
        && (lhs.digits == rhs.digits)
}

public func ==(lhs: Generator.Factor, rhs: Generator.Factor) -> Bool {
    switch (lhs, rhs) {
    case (.Counter(let l), .Counter(let r)):
        return l == r
    case (.Timer(let l), .Timer(let r)):
        return l == r
    default:
        return false
    }
}

public extension Generator {
    var isValid: Bool {
        return validateGenerator(factor, secret, algorithm, digits)
    }

    var password: String? {
        if !self.isValid { return nil }
        let counter = counterForGeneratorWithFactor(self.factor, atTimeIntervalSince1970: NSDate().timeIntervalSince1970)
        return generatePassword(self.algorithm, self.digits, self.secret, counter)
    }
}
