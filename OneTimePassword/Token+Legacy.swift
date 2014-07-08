//
//  Token+Legacy.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/7/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

extension Token {
    convenience init(classicType: OTPTokenType, secret: NSData, name: String, issuer: String, algorithm: OTPAlgorithm, digits: Int, period: NSTimeInterval) {
        var type: TokenType
        switch classicType {
        case .Counter:
            type = .Counter
        case .Timer:
            type = .Timer
        default:
            type = .Timer
        }
        self.init(type:type, secret:secret, name:name, issuer:issuer, algorithm:algorithm, digits:digits, period:period)
    }

    var classicType: OTPTokenType {
    switch self.type {
    case .Counter:
        return .Counter
    case .Timer:
        return .Timer
        }
    }
}
