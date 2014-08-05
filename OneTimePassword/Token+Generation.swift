//
//  Token+Generation.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

public extension Token {
    var isValid: Bool {
        let validDigits: (Int) -> Bool = { (6 <= $0) && ($0 <= 8) }
        let validPeriod: (NSTimeInterval) -> Bool = { (0 < $0) && ($0 <= 300) }

        switch type {
        case .Counter:
            return validDigits(digits)
        case .Timer(let period):
            return validDigits(digits) && validPeriod(period)
        }
    }

    var password: String? {
        if !self.isValid { return nil }
        switch type {
        case .Counter(let counter):
            return generatePassword(algorithm, digits, secret, counter)
        case .Timer(let period):
            return generatePassword(algorithm, digits, secret, UInt64(NSDate().timeIntervalSince1970 / period))
        }
    }
}

public func updatedToken(token: Token) -> Token {
    switch token.type {
    case .Counter(let counter):
        return Token(type: .Counter(counter + 1), secret: token.secret, name: token.name, issuer: token.issuer, algorithm: token.algorithm, digits: token.digits)
    case .Timer:
        return token
    }
}

public func generatePassword(algorithm: Token.Algorithm, digits: Int, secret: NSData, counter: UInt64) -> String? {
    let generatorAlgorithm: OTPGeneratorAlgorithm = { switch $0 {
    case .SHA1:   return .SHA1
    case .SHA256: return .SHA256
    case .SHA512: return .SHA512
    }}(algorithm)

    return passwordForToken(secret, generatorAlgorithm, digits, counter)
}
