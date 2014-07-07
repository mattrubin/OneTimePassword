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

    func isValid() -> Bool {
        let validType = (self.type == .Counter) || (self.type == .Timer);
        let validSecret = self.secret.length > 0;
        let validAlgorithm = (self.algorithm == .SHA1) || (self.algorithm == .SHA256) || (self.algorithm == .SHA512);
        let validDigits = (self.digits <= 8) && (self.digits >= 6);
        let validPeriod = (self.period > 0) && (self.period <= 300);

        return validType && validSecret && validAlgorithm && validDigits && validPeriod;
    }
}
