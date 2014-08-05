//
//  Token+Generation.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

public extension Token {
    var isValid: Bool {
        let validSecret = (secret.length > 0)
        let validDigits = (digits >= 6) && (digits <= 8)
        let validPeriod: Bool = { switch $0 {
            case .Timer(let period):
                return (period > 0) && (period <= 300)
            default:
                return true
        }}(type)

        return validSecret && validDigits && validPeriod
    }

    func password() -> String? {
        if !self.isValid { return nil }
        switch type {
        case .Counter(let counter):
            return generatePassword(algorithm, digits, secret, counter)
        case .Timer(let period):
            return generatePassword(algorithm, digits, secret, UInt64(NSDate().timeIntervalSince1970 / period))
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
}

public func generatePassword(algorithm: Token.Algorithm, digits: Int, secret: NSData, counter: UInt64) -> String? {
    let generatorAlgorithm: OTPGeneratorAlgorithm = { switch $0 {
    case .SHA1:   return .SHA1
    case .SHA256: return .SHA256
    case .SHA512: return .SHA512
    }}(algorithm)

    return passwordForToken(secret, generatorAlgorithm, digits, counter)
}
