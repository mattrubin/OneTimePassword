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
    var type: OTPTokenType?
    var secret: NSData?
    var algorithm: OTPAlgorithm?
    var digits: Integer?
}

enum OTPTokenType {
    case OTPTokenTypeUndefined
    case OTPTokenTypeCounter
    case OTPTokenTypeTimer
};

enum OTPAlgorithm {
    case OTPAlgorithmSHA1
    case OTPAlgorithmSHA256
    case OTPAlgorithmSHA512
}