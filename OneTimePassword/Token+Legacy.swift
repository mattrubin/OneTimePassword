//
//  Token+Legacy.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/7/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

extension Token {
    convenience init(classicType: OTPTokenType, secret: NSData, name: String, issuer: String, algorithm classicAlgorithm: OTPAlgorithm, digits: Int, period: NSTimeInterval) {
        var type: TokenType
        switch classicType {
        case .Counter: type = .Counter
        case .Timer:   type = .Timer
        default:       type = .Timer
        }

        var algorithm: Algorithm
        switch classicAlgorithm {
        case .SHA1:   algorithm = .SHA1
        case .SHA256: algorithm = .SHA256
        case .SHA512: algorithm = .SHA512
        default:      algorithm = .SHA1
        }

        self.init(type:type, secret:secret, name:name, issuer:issuer, algorithm:algorithm, digits:digits, period:period)
    }

    var classicType: OTPTokenType {
    switch self.type {
    case .Counter: return .Counter
    case .Timer:   return .Timer
    }
    }

    var classicAlgorithm: OTPAlgorithm {
    switch self.algorithm {
    case .SHA1:   return .SHA1
    case .SHA256: return .SHA256
    case .SHA512: return .SHA512
    }
    }
}
