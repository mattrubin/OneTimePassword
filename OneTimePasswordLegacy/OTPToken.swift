//
//  OTPToken.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/8/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import OneTimePassword

/**
`OTPToken` is a mutable, Objective-C-compatible wrapper around `OneTimePassword.Token`. For more
information about its properties and methods, consult the underlying `OneTimePassword`
documentation.
*/
public final class OTPToken: NSObject {
    required public override init() {}

    public var name: String = Token.defaultName
    public var issuer: String = Token.defaultIssuer
    public var type: OTPTokenType = .Timer
    public var secret: NSData = NSData()
    public var algorithm: OTPAlgorithm = OTPToken.defaultAlgorithm
    public var digits: UInt = OTPToken.defaultDigits
    public var period: NSTimeInterval = OTPToken.defaultPeriod
    public var counter: UInt64 = OTPToken.defaultInitialCounter

    private static let defaultAlgorithm: OTPAlgorithm = .SHA1
    private static var defaultDigits: UInt = 6
    private static var defaultInitialCounter: UInt64 = 0
    private static var defaultPeriod: NSTimeInterval = 30

    public var token: Token? {
        return tokenForOTPToken(self)
    }

    public func updateWithToken(token: Token) {
        self.name = token.name
        self.issuer = token.issuer

        self.secret = token.generator.secret
        self.algorithm = OTPAlgorithm(token.generator.algorithm)
        self.digits = UInt(token.generator.digits)

        switch token.generator.factor {
        case let .Counter(counter):
            self.type = .Counter
            self.counter = counter
        case let .Timer(period):
            self.type = .Timer
            self.period = period
        }
    }

    public convenience init(token: Token) {
        self.init()
        updateWithToken(token)
    }

    public func validate() -> Bool {
        return (token != nil)
    }
}

public extension OTPToken {
    static func tokenWithURL(url: NSURL) -> Self? {
        return tokenWithURL(url, secret: nil)
    }

    static func tokenWithURL(url: NSURL, secret: NSData?) -> Self? {
        guard let token = Token.URLSerializer.deserialize(url, secret: secret) else {
            return nil
        }
        return self.init(token: token)
    }

    func url() -> NSURL? {
        guard let token = token else {
            return nil
        }
        return Token.URLSerializer.serialize(token)
    }
}
