//
//  TokenTests.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/16/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import XCTest
import OneTimePassword

class TokenTests: XCTestCase {
    func testInit() {
        // Create a token
        let type = Token.TokenType.Counter(111)
        let secret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!
        let name = "Test Name"
        let issuer = "Test Issuer"
        let algorithm = Token.Algorithm.SHA256
        let digits = 8
        let period: NSTimeInterval = 45
        let counter: UInt64 = 111

        let token = Token(type: type,
            secret: secret,
            name: name,
            issuer: issuer,
            algorithm: algorithm,
            digits: digits,
            period: period,
            counter: counter)

        XCTAssertEqual(token.type, type)
        XCTAssertEqual(token.secret, secret)
        XCTAssertEqual(token.name, name)
        XCTAssertEqual(token.issuer, issuer)
        XCTAssertEqual(token.algorithm, algorithm)
        XCTAssertEqual(token.digits, digits)
        XCTAssertEqual(token.period, period)
        XCTAssertEqual(token.counter, counter)

        // Create another token
        let other_type = Token.TokenType.Timer(123)
        let other_secret = "09876543210987654321".dataUsingEncoding(NSASCIIStringEncoding)!
        let other_name = "Other Test Name"
        let other_issuer = "Other Test Issuer"
        let other_algorithm = Token.Algorithm.SHA512
        let other_digits = 7
        let other_period: NSTimeInterval = 123
        let other_counter: UInt64 = 222

        let other_token = Token(type: other_type,
            secret: other_secret,
            name: other_name,
            issuer: other_issuer,
            algorithm: other_algorithm,
            digits: other_digits,
            period: other_period,
            counter: other_counter)

        XCTAssertEqual(other_token.type, other_type)
        XCTAssertEqual(other_token.secret, other_secret)
        XCTAssertEqual(other_token.name, other_name)
        XCTAssertEqual(other_token.issuer, other_issuer)
        XCTAssertEqual(other_token.algorithm, other_algorithm)
        XCTAssertEqual(other_token.digits, other_digits)
        XCTAssertEqual(other_token.period, other_period)
        XCTAssertEqual(other_token.counter, other_counter)

        // Ensure the tokens are different
        XCTAssertNotEqual(token.type, other_token.type)
        XCTAssertNotEqual(token.secret, other_token.secret)
        XCTAssertNotEqual(token.name, other_token.name)
        XCTAssertNotEqual(token.issuer, other_token.issuer)
        XCTAssertNotEqual(token.algorithm, other_token.algorithm)
        XCTAssertNotEqual(token.digits, other_token.digits)
        XCTAssertNotEqual(token.period, other_token.period)
        XCTAssertNotEqual(token.counter, other_token.counter)
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

        let tokenWithDefaultName      = Token(type: t, secret: s,          issuer: i, algorithm: a, digits: d, period: p, counter: c)
        let tokenWithDefaultIssuer    = Token(type: t, secret: s, name: n,            algorithm: a, digits: d, period: p, counter: c)
        let tokenWithDefaultAlgorithm = Token(type: t, secret: s, name: n, issuer: i,               digits: d, period: p, counter: c)
        let tokenWithDefaultDigits    = Token(type: t, secret: s, name: n, issuer: i, algorithm: a,            period: p, counter: c)
        let tokenWithDefaultPeriod    = Token(type: t, secret: s, name: n, issuer: i, algorithm: a, digits: d,            counter: c)
        let tokenWithDefaultCounter   = Token(type: t, secret: s, name: n, issuer: i, algorithm: a, digits: d, period: p            )

        XCTAssertEqual(tokenWithDefaultName.name, "")
        XCTAssertEqual(tokenWithDefaultIssuer.issuer, "")
        XCTAssertEqual(tokenWithDefaultAlgorithm.algorithm, Token.Algorithm.SHA1)
        XCTAssertEqual(tokenWithDefaultDigits.digits, 6)
        XCTAssertEqual(tokenWithDefaultPeriod.period, 30)
        XCTAssertEqual(tokenWithDefaultCounter.counter, 0)

        let tokenWithAllDefaults = Token(type: t, secret: s)

        XCTAssertEqual(tokenWithAllDefaults.name, "")
        XCTAssertEqual(tokenWithAllDefaults.issuer, "")
        XCTAssertEqual(tokenWithAllDefaults.algorithm, Token.Algorithm.SHA1)
        XCTAssertEqual(tokenWithAllDefaults.digits, 6)
        XCTAssertEqual(tokenWithAllDefaults.period, 30)
        XCTAssertEqual(tokenWithAllDefaults.counter, 0)
    }

    func testValidation() {
        let validSecret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!

        let tokenWithInvalidSecret = Token(type: .Timer(30), secret: NSData())
        let tokenWithValidSecret = Token(type: .Timer(30), secret: validSecret)

        XCTAssertFalse(tokenWithInvalidSecret.isValid)
        XCTAssertTrue(tokenWithValidSecret.isValid)

        let tokenWithTooManyDigits = Token(type: .Timer(30), secret: validSecret, digits: 10)
        let tokenWithTooFewDigits = Token(type: .Timer(30), secret: validSecret, digits: 3)
        let tokenWithNegativeDigits = Token(type: .Timer(30), secret: validSecret, digits: -6)
        let tokenWithValidDigits = Token(type: .Timer(30), secret: validSecret)

        XCTAssertFalse(tokenWithTooManyDigits.isValid)
        XCTAssertFalse(tokenWithTooFewDigits.isValid)
        XCTAssertFalse(tokenWithNegativeDigits.isValid)
        XCTAssertTrue(tokenWithValidDigits.isValid)

        let tokenWithTooLongPeriod = Token(type: .Timer(301), secret: validSecret, period: 301)
        let tokenWithTooShortPeriod = Token(type: .Timer(0), secret: validSecret, period: 0)
        let tokenWithNegativePeriod = Token(type: .Timer(-30), secret: validSecret, period: -30)
        let tokenWithValidPeriod = Token(type: .Timer(30), secret: validSecret, period: 30)

        XCTAssertFalse(tokenWithTooLongPeriod.isValid)
        XCTAssertFalse(tokenWithTooShortPeriod.isValid)
        XCTAssertFalse(tokenWithNegativePeriod.isValid)
        XCTAssertTrue(tokenWithValidPeriod.isValid)
    }
}
