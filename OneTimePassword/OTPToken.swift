//
//  OTPToken.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 6/10/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//


class OTPToken: NSObject {
    var name: String?
    var issuer: String?
    let type: TokenType
    let secret: NSData
    let algorithm: Algorithm
    let digits: Int

    init(type: TokenType, secret: NSData, algorithm: Algorithm = .SHA1, digits: Int = 6) {
        self.type = type
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
    }


    enum TokenType {
        case Counter, Timer
    }

    enum Algorithm {
        case SHA1, SHA256, SHA512
    }
}
