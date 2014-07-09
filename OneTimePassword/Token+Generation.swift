//
//  Token+Generation.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

extension Token {
    // TODO: KVO on password
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
        if !self.isValid() { return nil }
        return passwordForToken(self.secret, self.algorithm, self.digits, counter)
    }

}
