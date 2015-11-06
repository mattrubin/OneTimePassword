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
        let name = "Test Name"
        let issuer = "Test Issuer"
        let generator = Generator(
            factor: .Counter(111),
            secret: "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!,
            algorithm: .SHA1,
            digits: 6
        )

        let token = Token(
            name: name,
            issuer: issuer,
            core: generator
        )

        XCTAssertEqual(token.name, name)
        XCTAssertEqual(token.issuer, issuer)
        XCTAssertEqual(token.core, generator)

        // Create another token
        let other_name = "Other Test Name"
        let other_issuer = "Other Test Issuer"
        let other_generator = Generator(
            factor: .Timer(period: 123),
            secret: "09876543210987654321".dataUsingEncoding(NSASCIIStringEncoding)!,
            algorithm: .SHA512,
            digits: 8
        )

        let other_token = Token(
            name: other_name,
            issuer: other_issuer,
            core: other_generator
        )

        XCTAssertEqual(other_token.name, other_name)
        XCTAssertEqual(other_token.issuer, other_issuer)
        XCTAssertEqual(other_token.core, other_generator)

        // Ensure the tokens are different
        XCTAssertNotEqual(token.name, other_token.name)
        XCTAssertNotEqual(token.issuer, other_token.issuer)
        XCTAssertNotEqual(token.core, other_token.core)
    }

    func testDefaults() {
        let generator = Generator(
            factor: .Counter(0),
            secret: NSData(),
            algorithm: .SHA1,
            digits: 6
        )
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
