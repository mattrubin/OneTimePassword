//
//  Token+Generation.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

public extension Token {
    func password() -> String? {
        switch type {
        case .Counter(let counter):
            return self.passwordForCounter(counter)
        case .Timer(let period):
            return self.passwordForCounter(UInt64(NSDate().timeIntervalSince1970 / period))
        }
    }

    func updatedToken() -> Token {
        switch type {
        case .Counter(let counter):
            return Token(type: .Counter(counter + 1), secret: secret, name: name, issuer: issuer, algorithm: algorithm, digits: digits)
        case .Timer:
            return self
        }
    }

    func passwordForCounter(counter: UInt64) -> String? {
        if !self.isValid { return nil }
        return passwordForToken(self.secret, generatorAlgorithmForTokenAlgorithm(self.algorithm), self.digits, counter)
    }
}

func generatorAlgorithmForTokenAlgorithm(algorithm: Token.Algorithm) -> OTPGeneratorAlgorithm {
    switch algorithm {
    case .SHA1:   return .SHA1
    case .SHA256: return .SHA256
    case .SHA512: return .SHA512
    }
}
