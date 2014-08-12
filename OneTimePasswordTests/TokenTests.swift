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
        let factor = OneTimePassword.Generator.Factor.Counter(111)
        let secret = "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!
        let name = "Test Name"
        let issuer = "Test Issuer"

        let token = Token(
            name: name,
            issuer: issuer,
            core: Generator(
                factor: factor,
                secret: secret
            )
        )

        XCTAssertEqual(token.core.factor, factor)
        XCTAssertEqual(token.core.secret, secret)
        XCTAssertEqual(token.name, name)
        XCTAssertEqual(token.issuer, issuer)

        // Create another token
        let other_factor = OneTimePassword.Generator.Factor.Timer(period: 123)
        let other_secret = "09876543210987654321".dataUsingEncoding(NSASCIIStringEncoding)!
        let other_name = "Other Test Name"
        let other_issuer = "Other Test Issuer"

        let other_token = Token(
            name: other_name,
            issuer: other_issuer,
            core: Generator(
                factor: other_factor,
                secret: other_secret
            )
        )

        XCTAssertEqual(other_token.core.factor, other_factor)
        XCTAssertEqual(other_token.core.secret, other_secret)
        XCTAssertEqual(other_token.name, other_name)
        XCTAssertEqual(other_token.issuer, other_issuer)

        // Ensure the tokens are different
        XCTAssertNotEqual(token.core.factor, other_token.core.factor)
        XCTAssertNotEqual(token.core.secret, other_token.core.secret)
        XCTAssertNotEqual(token.name, other_token.name)
        XCTAssertNotEqual(token.issuer, other_token.issuer)
    }

    func testDefaults() {
        let generator = Generator(factor: .Counter(0), secret: NSData())

        let n = "Test Name"
        let i = "Test Issuer"

        let tokenWithDefaultName = Token(issuer: i, core: generator)
        XCTAssertEqual(tokenWithDefaultName.name, "")
        XCTAssertEqual(tokenWithDefaultName.issuer, i)

        let tokenWithDefaultIssuer = Token(name: n, core: generator)
        XCTAssertEqual(tokenWithDefaultIssuer.name, n)
        XCTAssertEqual(tokenWithDefaultIssuer.issuer, "")

        let tokenWithAllDefaults = Token(core: generator)
        XCTAssertEqual(tokenWithAllDefaults.name, "")
        XCTAssertEqual(tokenWithAllDefaults.issuer, "")
    }
}
