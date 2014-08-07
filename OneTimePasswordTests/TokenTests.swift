//
//  TokenTests.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/16/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import XCTest
import OneTimePassword


extension OneTimePassword.Generator.TokenType: Equatable {}

public func ==(lhs: OneTimePassword.Generator.TokenType, rhs: OneTimePassword.Generator.TokenType) -> Bool {
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
        let type = OneTimePassword.Generator.TokenType.Counter(111)
        let secret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!
        let name = "Test Name"
        let issuer = "Test Issuer"
        let algorithm = Generator.Algorithm.SHA256
        let digits = 8

        let token = Token(type: type,
            secret: secret,
            name: name,
            issuer: issuer,
            algorithm: algorithm,
            digits: digits)

        XCTAssertEqual(token.core.type, type)
        XCTAssertEqual(token.core.secret, secret)
        XCTAssertEqual(token.name, name)
        XCTAssertEqual(token.issuer, issuer)
        XCTAssertEqual(token.core.algorithm, algorithm)
        XCTAssertEqual(token.core.digits, digits)

        // Create another token
        let other_type = OneTimePassword.Generator.TokenType.Timer(period: 123)
        let other_secret = "09876543210987654321".dataUsingEncoding(NSASCIIStringEncoding)!
        let other_name = "Other Test Name"
        let other_issuer = "Other Test Issuer"
        let other_algorithm = Generator.Algorithm.SHA512
        let other_digits = 7

        let other_token = Token(type: other_type,
            secret: other_secret,
            name: other_name,
            issuer: other_issuer,
            algorithm: other_algorithm,
            digits: other_digits)

        XCTAssertEqual(other_token.core.type, other_type)
        XCTAssertEqual(other_token.core.secret, other_secret)
        XCTAssertEqual(other_token.name, other_name)
        XCTAssertEqual(other_token.issuer, other_issuer)
        XCTAssertEqual(other_token.core.algorithm, other_algorithm)
        XCTAssertEqual(other_token.core.digits, other_digits)

        // Ensure the tokens are different
        XCTAssertNotEqual(token.core.type, other_token.core.type)
        XCTAssertNotEqual(token.core.secret, other_token.core.secret)
        XCTAssertNotEqual(token.name, other_token.name)
        XCTAssertNotEqual(token.issuer, other_token.issuer)
        XCTAssertNotEqual(token.core.algorithm, other_token.core.algorithm)
        XCTAssertNotEqual(token.core.digits, other_token.core.digits)
    }

    func testDefaults() {
        let t = OneTimePassword.Generator.TokenType.Counter(111)
        let s = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!
        let n = "Test Name"
        let i = "Test Issuer"
        let a = Generator.Algorithm.SHA256
        let d = 8
        let p: NSTimeInterval = 45
        let c: UInt64 = 111

        let tokenWithDefaultName      = Token(type: t, secret: s,          issuer: i, algorithm: a, digits: d)
        let tokenWithDefaultIssuer    = Token(type: t, secret: s, name: n,            algorithm: a, digits: d)
        let tokenWithDefaultAlgorithm = Token(type: t, secret: s, name: n, issuer: i,               digits: d)
        let tokenWithDefaultDigits    = Token(type: t, secret: s, name: n, issuer: i, algorithm: a           )

        XCTAssertEqual(tokenWithDefaultName.name, "")
        XCTAssertEqual(tokenWithDefaultIssuer.issuer, "")
        XCTAssertEqual(tokenWithDefaultAlgorithm.core.algorithm, Generator.Algorithm.SHA1)
        XCTAssertEqual(tokenWithDefaultDigits.core.digits, 6)

        let tokenWithAllDefaults = Token(type: t, secret: s)

        XCTAssertEqual(tokenWithAllDefaults.name, "")
        XCTAssertEqual(tokenWithAllDefaults.issuer, "")
        XCTAssertEqual(tokenWithAllDefaults.core.algorithm, Generator.Algorithm.SHA1)
        XCTAssertEqual(tokenWithAllDefaults.core.digits, 6)
    }

    func testValidation() {
        let validSecret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!

        let tokenWithTooManyDigits = Token(type: .Timer(period: 30), secret: validSecret, digits: 10)
        let tokenWithTooFewDigits = Token(type: .Timer(period: 30), secret: validSecret, digits: 3)
        let tokenWithNegativeDigits = Token(type: .Timer(period: 30), secret: validSecret, digits: -6)
        let tokenWithValidDigits = Token(type: .Timer(period: 30), secret: validSecret)

        XCTAssertFalse(tokenWithTooManyDigits.core.isValid)
        XCTAssertFalse(tokenWithTooFewDigits.core.isValid)
        XCTAssertFalse(tokenWithNegativeDigits.core.isValid)
        XCTAssertTrue(tokenWithValidDigits.core.isValid)

        let tokenWithTooLongPeriod = Token(type: .Timer(period: 301), secret: validSecret)
        let tokenWithTooShortPeriod = Token(type: .Timer(period: 0), secret: validSecret)
        let tokenWithNegativePeriod = Token(type: .Timer(period: -30), secret: validSecret)
        let tokenWithValidPeriod = Token(type: .Timer(period: 30), secret: validSecret)

        XCTAssertFalse(tokenWithTooLongPeriod.core.isValid)
        XCTAssertFalse(tokenWithTooShortPeriod.core.isValid)
        XCTAssertFalse(tokenWithNegativePeriod.core.isValid)
        XCTAssertTrue(tokenWithValidPeriod.core.isValid)
    }
}
