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
    var type: UInt8 = 0
    var secret: NSData?
    var algorithm: UInt32 = 0
    var digits: Int = 6
}
