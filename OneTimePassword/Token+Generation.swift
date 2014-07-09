//
//  Token+Generation.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import Foundation

extension Token {
    func passwordForCounter(counter: UInt64) -> String?
    {
        if !self.isValid() { return nil }
        return passwordForToken(self.secret, hashAlgorithmForAlgorithm(self.algorithm), self.digits, counter)
    }

}
