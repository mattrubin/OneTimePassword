//
//  Token+Generation.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

public extension Token {
    func password() -> String? {
        var newCounter = counter
        if (self.type == TokenType.Timer) {
            newCounter = UInt64(NSDate().timeIntervalSince1970 / self.period)
        }

        return self.passwordForCounter(newCounter)
    }

    func updatedToken() -> Token {
        switch type {
        case .Counter:
            return Token(type: type, secret: secret, name: name, issuer: issuer, algorithm: algorithm, digits: digits, period: period, counter: counter + 1)
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
