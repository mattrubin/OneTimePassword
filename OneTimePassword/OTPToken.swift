//
//  OTPToken.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 6/10/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//


class OTPToken: NSObject {
    var name: String
    var issuer: String
    let type: TokenType
    let secret: NSData
    let algorithm: Algorithm
    let digits: Int
    var counter: UInt64 = 1
    var period: NSTimeInterval = 30

    init(type: TokenType, secret: NSData, name: String = "", issuer: String = "", algorithm: Algorithm = .SHA1, digits: Int = 6) {
        self.type = type
        self.secret = secret
        self.name = name
        self.issuer = issuer
        self.algorithm = algorithm
        self.digits = digits
    }

    func validate() -> Bool {
        var validType = (self.type == .Counter) || (self.type == .Timer)
        var validSecret = (self.secret.length > 0)
        var validAlgorithm = (self.algorithm == .SHA1 ||
                              self.algorithm == .SHA256 ||
                              self.algorithm == .SHA512)
        var validDigits = (self.digits >= 6) && (self.digits <= 8)
        var validCounter = (self.counter > 0)
        var validPeriod = (self.period > 0) && (self.period <= 300)

        return validType && validSecret && validAlgorithm && validDigits && validCounter && validPeriod
    }

    func description() -> String {
        return "<OTPToken type:\(type.toRaw()), name:\(name), issuer:\(issuer), algorithm:\(algorithm.toRaw()), digits:\(digits)>"
    }


    enum TokenType : String {
        case Counter = "hotp", Timer = "totp"
    }

    enum Algorithm : String {
        case SHA1 = "SHA1", SHA256 = "SHA256", SHA512 = "SHA512"
    }
}
