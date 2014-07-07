//
//  OTPToken.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 6/10/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

/*
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
        var validType = (type == .Counter) || (type == .Timer)
        var validSecret = (secret.length > 0)
        var validAlgorithm = (algorithm == .SHA1 ||
                              algorithm == .SHA256 ||
                              algorithm == .SHA512)
        var validDigits = (digits >= 6) && (digits <= 8)
        var validCounter = (counter > 0)
        var validPeriod = (period > 0) && (period <= 300)

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
*/
