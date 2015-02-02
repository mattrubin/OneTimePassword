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

    public init?(factor: Factor, secret: NSData, algorithm: Algorithm = defaultAlgorithm, digits: Int = defaultDigits) {
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
    var password: String? {
        if !validateGenerator(factor, secret, algorithm, digits) { return nil }
        let counter = counterForGeneratorWithFactor(self.factor, atTimeIntervalSince1970: NSDate().timeIntervalSince1970)
        return generatePassword(self.algorithm, self.digits, self.secret, counter)
    }
}
