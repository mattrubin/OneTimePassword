//
//  Conversion.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 2/3/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

import OneTimePassword


internal extension OTPAlgorithm {
    init(_ generatorAlgorithm: Generator.Algorithm) {
        switch generatorAlgorithm {
        case .SHA1:   self = .SHA1
        case .SHA256: self = .SHA256
        case .SHA512: self = .SHA512
        }
    }
}


internal func tokenForOTPToken(token: OTPToken) -> Token? {
    guard let generator = generatorForOTPToken(token)
        else { return nil }

    return Token(name: token.name, issuer: token.issuer, core: generator)
}

private func generatorForOTPToken(token: OTPToken) -> Generator? {
    return Generator(
        factor: factorForOTPToken(token),
        secret: token.secret,
        algorithm: algorithmForOTPAlgorithm(token.algorithm),
        digits: Int(token.digits)
    )
}

private func factorForOTPToken(token: OTPToken) -> Generator.Factor {
    switch token.type {
    case .Counter:
        return .Counter(token.counter)
    case .Timer:
        return .Timer(period: token.period)
    }
}

private func algorithmForOTPAlgorithm(algorithm: OTPAlgorithm) -> Generator.Algorithm {
    switch algorithm {
    case .SHA1:   return .SHA1
    case .SHA256: return .SHA256
    case .SHA512: return .SHA512
    }
}
