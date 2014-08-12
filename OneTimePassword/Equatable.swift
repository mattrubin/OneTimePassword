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
