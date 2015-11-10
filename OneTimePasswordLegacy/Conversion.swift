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


internal func tokenForOTPToken(otpToken: OTPToken) -> Token? {
    guard let generator = Generator(
        factor: factorForOTPToken(otpToken),
        secret: otpToken.secret,
        algorithm: algorithmForOTPAlgorithm(otpToken.algorithm),
        digits: Int(otpToken.digits)
    ) else {
        return nil
    }
    return Token(name: otpToken.name, issuer: otpToken.issuer, generator: generator)
}

private func factorForOTPToken(otpToken: OTPToken) -> Generator.Factor {
    switch otpToken.type {
    case .Counter:
        return .Counter(otpToken.counter)
    case .Timer:
        return .Timer(period: otpToken.period)
    }
}

private func algorithmForOTPAlgorithm(algorithm: OTPAlgorithm) -> Generator.Algorithm {
    switch algorithm {
    case .SHA1:   return .SHA1
    case .SHA256: return .SHA256
    case .SHA512: return .SHA512
    }
}
