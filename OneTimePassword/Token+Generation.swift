//
//  Token+Generation.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

extension Token {
    func password() -> String? {
        if (self.type == TokenType.Timer) {
            let newCounter = UInt64(NSDate().timeIntervalSince1970 / self.period)
            if (self.counter != newCounter) {
                self.counter = newCounter
            }
        }

        return self.passwordForCounter(self.counter)
    }

    func passwordForCounter(counter: UInt64) -> String? {
        if !self.isValid() { return nil }
        return passwordForToken(self.secret, hashAlgorithmForAlgorithm(self.algorithm), self.digits, counter)
    }

}
