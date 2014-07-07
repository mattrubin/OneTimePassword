//
//  Token.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/7/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

@objc class Token: NSObject {
    let name: String
    let issuer: String
    let type: OTPTokenType
    let secret: NSData
    let algorithm: OTPAlgorithm
    let digits: Int
    let period: NSTimeInterval

    init(type: OTPTokenType, secret: NSData, name: String, issuer: String, algorithm: OTPAlgorithm, digits: Int, period: NSTimeInterval) {
        self.type = type
        self.secret = secret
        self.name = name
        self.issuer = issuer
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
    }
}
