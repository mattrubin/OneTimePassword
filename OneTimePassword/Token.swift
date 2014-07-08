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
    var counter: UInt64 = 1

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


let kOTPAuthScheme = "otpauth"
let kQueryAlgorithmKey = "algorithm"
let kQuerySecretKey = "secret"
let kQueryCounterKey = "counter"
let kQueryDigitsKey = "digits"
let kQueryPeriodKey = "period"
let kQueryIssuerKey = "issuer"

extension Token {

    func url() -> NSURL {
        let urlComponents = NSURLComponents()
        urlComponents.scheme = kOTPAuthScheme
        urlComponents.host = NSString(forTokenType:self.type)
        urlComponents.path = "/" + self.name

        var queryItems = [
            NSURLQueryItem(name:kQueryAlgorithmKey, value:NSString(forAlgorithm:self.algorithm)),
            NSURLQueryItem(name:kQueryDigitsKey, value:String(self.digits)),
            NSURLQueryItem(name:kQueryIssuerKey, value:self.issuer),
        ]

        if (self.type == .Timer) {
            queryItems += NSURLQueryItem(name:kQueryPeriodKey, value:String(format: "%.0f", self.period))
        } else if (self.type == .Counter) {
            queryItems += NSURLQueryItem(name:kQueryCounterKey, value:String(self.counter))
        }

        urlComponents.queryItems = queryItems

        return urlComponents.URL
    }
}
