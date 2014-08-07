//
//  TokenTests.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/16/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import XCTest
import OneTimePassword


extension Token.TokenType: Equatable {}

public func ==(lhs: Token.TokenType, rhs: Token.TokenType) -> Bool {
    switch (lhs, rhs) {
    case (.Counter(let l), .Counter(let r)):
        return l == r
    case (.Timer(let l), .Timer(let r)):
        return l == r
    default:
        return false
    }
}


class TokenTests: XCTestCase {
    func testInit() {
        // Create a token
        let type = Token.TokenType.Counter(111)
        let secret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!
        let name = "Test Name"
        let issuer = "Test Issuer"
        let algorithm = Token.Algorithm.SHA256
        let digits = 8

        let token = Token(type: type,
            secret: secret,
            name: name,
            issuer: issuer,
            algorithm: algorithm,
            digits: digits)

        XCTAssertEqual(token.type, type)
        XCTAssertEqual(token.secret, secret)
        XCTAssertEqual(token.name, name)
        XCTAssertEqual(token.issuer, issuer)
        XCTAssertEqual(token.algorithm, algorithm)
        XCTAssertEqual(token.digits, digits)

        // Create another token
        let other_type = Token.TokenType.Timer(period: 123)
        let other_secret = "09876543210987654321".dataUsingEncoding(NSASCIIStringEncoding)!
        let other_name = "Other Test Name"
        let other_issuer = "Other Test Issuer"
        let other_algorithm = Token.Algorithm.SHA512
        let other_digits = 7

        let other_token = Token(type: other_type,
            secret: other_secret,
            name: other_name,
            issuer: other_issuer,
            algorithm: other_algorithm,
            digits: other_digits)

        XCTAssertEqual(other_token.type, other_type)
        XCTAssertEqual(other_token.secret, other_secret)
        XCTAssertEqual(other_token.name, other_name)
        XCTAssertEqual(other_token.issuer, other_issuer)
        XCTAssertEqual(other_token.algorithm, other_algorithm)
        XCTAssertEqual(other_token.digits, other_digits)

        // Ensure the tokens are different
        XCTAssertNotEqual(token.type, other_token.type)
        XCTAssertNotEqual(token.secret, other_token.secret)
        XCTAssertNotEqual(token.name, other_token.name)
        XCTAssertNotEqual(token.issuer, other_token.issuer)
        XCTAssertNotEqual(token.algorithm, other_token.algorithm)
        XCTAssertNotEqual(token.digits, other_token.digits)
    }

    func testDefaults() {
        let t = Token.TokenType.Counter(111)
        let s = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!
        let n = "Test Name"
        let i = "Test Issuer"
        let a = Token.Algorithm.SHA256
        let d = 8
        let p: NSTimeInterval = 45
        let c: UInt64 = 111

        let tokenWithDefaultName      = Token(type: t, secret: s,          issuer: i, algorithm: a, digits: d)
        let tokenWithDefaultIssuer    = Token(type: t, secret: s, name: n,            algorithm: a, digits: d)
        let tokenWithDefaultAlgorithm = Token(type: t, secret: s, name: n, issuer: i,               digits: d)
        let tokenWithDefaultDigits    = Token(type: t, secret: s, name: n, issuer: i, algorithm: a           )

        XCTAssertEqual(tokenWithDefaultName.name, "")
        XCTAssertEqual(tokenWithDefaultIssuer.issuer, "")
        XCTAssertEqual(tokenWithDefaultAlgorithm.algorithm, Token.Algorithm.SHA1)
        XCTAssertEqual(tokenWithDefaultDigits.digits, 6)

        let tokenWithAllDefaults = Token(type: t, secret: s)

        XCTAssertEqual(tokenWithAllDefaults.name, "")
        XCTAssertEqual(tokenWithAllDefaults.issuer, "")
        XCTAssertEqual(tokenWithAllDefaults.algorithm, Token.Algorithm.SHA1)
        XCTAssertEqual(tokenWithAllDefaults.digits, 6)
    }

    func testValidation() {
        let validSecret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!

        let tokenWithTooManyDigits = Token(type: .Timer(period: 30), secret: validSecret, digits: 10)
        let tokenWithTooFewDigits = Token(type: .Timer(period: 30), secret: validSecret, digits: 3)
        let tokenWithNegativeDigits = Token(type: .Timer(period: 30), secret: validSecret, digits: -6)
        let tokenWithValidDigits = Token(type: .Timer(period: 30), secret: validSecret)

        XCTAssertFalse(tokenWithTooManyDigits.isValid)
        XCTAssertFalse(tokenWithTooFewDigits.isValid)
        XCTAssertFalse(tokenWithNegativeDigits.isValid)
        XCTAssertTrue(tokenWithValidDigits.isValid)

        let tokenWithTooLongPeriod = Token(type: .Timer(period: 301), secret: validSecret)
        let tokenWithTooShortPeriod = Token(type: .Timer(period: 0), secret: validSecret)
        let tokenWithNegativePeriod = Token(type: .Timer(period: -30), secret: validSecret)
        let tokenWithValidPeriod = Token(type: .Timer(period: 30), secret: validSecret)

        XCTAssertFalse(tokenWithTooLongPeriod.isValid)
        XCTAssertFalse(tokenWithTooShortPeriod.isValid)
        XCTAssertFalse(tokenWithNegativePeriod.isValid)
        XCTAssertTrue(tokenWithValidPeriod.isValid)
    }
}
