//
//  Equatable.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 8/12/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

extension Generator.Factor: Equatable {}

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


extension Generator: Equatable {}

public func ==(lhs: Generator, rhs: Generator) -> Bool {
    return (lhs.factor == rhs.factor)
        && (lhs.algorithm == rhs.algorithm)
        && (lhs.secret == rhs.secret)
        && (lhs.digits == rhs.digits)
}
