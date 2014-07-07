//
//  OTPToken+Serialization.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 6/10/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

/*
let kOTPAuthScheme = "otpauth"
let kQueryAlgorithmKey = "algorithm"
let kQuerySecretKey = "secret"
let kQueryCounterKey = "counter"
let kQueryDigitsKey = "digits"
let kQueryPeriodKey = "period"
let kQueryIssuerKey = "issuer"


extension OTPToken {
    var url: NSURL {
    var urlComponents = NSURLComponents()
        urlComponents.scheme = kOTPAuthScheme
        urlComponents.host = type.toRaw()
        urlComponents.path = "/" + name

        var query = [
            NSURLQueryItem(name:kQueryAlgorithmKey, value:algorithm.toRaw()),
            NSURLQueryItem(name:kQueryDigitsKey, value:String(digits)),
            NSURLQueryItem(name:kQueryIssuerKey, value:issuer)
        ]

        switch type {
        case .Timer:
            query += NSURLQueryItem(name:kQueryPeriodKey, value:String(period))
        case .Counter:
            query += NSURLQueryItem(name:kQueryCounterKey, value:String(counter))
        }

        urlComponents.queryItems = query

        return urlComponents.URL
    }
}
*/
