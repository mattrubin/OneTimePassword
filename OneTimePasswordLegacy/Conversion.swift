//
//  Conversion.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 2/3/15.
//  Copyright (c) 2015 Matt Rubin. All rights reserved.
//

import OneTimePassword

internal func generatorAlgorithm(otpAlgorithm: OTPAlgorithm) -> Generator.Algorithm {
    switch otpAlgorithm {
    case .SHA1:   return .SHA1
    case .SHA256: return .SHA256
    case .SHA512: return .SHA512
    }
}

internal func otpAlgorithm(generatorAlgorithm: Generator.Algorithm) -> OTPAlgorithm {
    switch generatorAlgorithm {
    case .SHA1:   return .SHA1
    case .SHA256: return .SHA256
    case .SHA512: return .SHA512
    }
}

internal func factorForOTPToken(token: OTPToken) -> Generator.Factor {
    switch token.type {
    case .Counter:
        return .Counter(token.counter)
    case .Timer:
        return .Timer(period: token.period)
    }
}

internal func tokenForOTPToken(token: OTPToken) -> Token? {
    if let generator = Generator(
        factor: factorForOTPToken(token),
        secret: token.secret,
        algorithm: generatorAlgorithm(token.algorithm),
        digits: Int(token.digits)
        )
    {
        return Token(
            name: token.name,
            issuer: token.issuer,
            core: generator
        )
    }
    return nil
}
