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
    let type: UInt8
    let secret: NSData
    let algorithm: UInt32
    let digits: Int

    init(type: UInt8, secret: NSData, name: String, issuer: String, algorithm: UInt32, digits: Int) {
        self.type = type
        self.secret = secret
        self.name = name
        self.issuer = issuer
        self.algorithm = algorithm
        self.digits = digits
    }
}
