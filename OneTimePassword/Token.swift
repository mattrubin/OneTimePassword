//
//  Token.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/7/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

@objc class Token: NSObject {
    var name: String?
    var issuer: String?
    let type: UInt8
    let secret: NSData
    let algorithm: UInt32
    let digits: Int

    init(type: UInt8, secret: NSData, algorithm: UInt32, digits: Int) {
        self.type = type
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
    }
}
