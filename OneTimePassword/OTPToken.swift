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
    var type: TokenType?
    var secret: NSData?
    var algorithm: Algorithm?
    var digits: Int?

    enum TokenType {
        case Counter, Timer
    }

    enum Algorithm {
        case SHA1, SHA256, SHA512
    }
}
