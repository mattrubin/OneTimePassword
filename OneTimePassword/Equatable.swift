//
//  Equatable.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 8/12/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

extension OneTimePassword.Generator.Factor: Equatable {}

public func ==(lhs: OneTimePassword.Generator.Factor, rhs: OneTimePassword.Generator.Factor) -> Bool {
    switch (lhs, rhs) {
    case (.Counter(let l), .Counter(let r)):
        return l == r
    case (.Timer(let l), .Timer(let r)):
        return l == r
    default:
        return false
    }
}


extension Generator: Equatable {}

public func ==(lhs: Generator, rhs: Generator) -> Bool {
    return (lhs.factor == rhs.factor)
        && (lhs.algorithm == rhs.algorithm)
        && (lhs.secret == rhs.secret)
        && (lhs.digits == rhs.digits)
}


extension Token: Equatable {}

public func ==(lhs: Token, rhs: Token) -> Bool {
    return (lhs.name == rhs.name)
        && (lhs.issuer == rhs.issuer)
        && (lhs.core == rhs.core)
}
