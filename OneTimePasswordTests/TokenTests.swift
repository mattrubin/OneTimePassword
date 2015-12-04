//
//  TokenTests.swift
//  OneTimePassword
//
//  Copyright (c) 2014-2015 Matt Rubin and the OneTimePassword authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import XCTest
import OneTimePassword

class TokenTests: XCTestCase {
    func testInit() {
        // Create a token
        let name = "Test Name"
        let issuer = "Test Issuer"
        guard let generator = Generator(
            factor: .Counter(111),
            secret: "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!,
            algorithm: .SHA1,
            digits: 6
        ) else {
            XCTFail()
            return
        }

        let token = Token(
            name: name,
            issuer: issuer,
            generator: generator
        )

        XCTAssertEqual(token.name, name)
        XCTAssertEqual(token.issuer, issuer)
        XCTAssertEqual(token.generator, generator)

        // Create another token
        let other_name = "Other Test Name"
        let other_issuer = "Other Test Issuer"
        guard let other_generator = Generator(
            factor: .Timer(period: 123),
            secret: "09876543210987654321".dataUsingEncoding(NSASCIIStringEncoding)!,
            algorithm: .SHA512,
            digits: 8
        ) else {
            XCTFail()
            return
        }

        let other_token = Token(
            name: other_name,
            issuer: other_issuer,
            generator: other_generator
        )

        XCTAssertEqual(other_token.name, other_name)
        XCTAssertEqual(other_token.issuer, other_issuer)
        XCTAssertEqual(other_token.generator, other_generator)

        // Ensure the tokens are different
        XCTAssertNotEqual(token.name, other_token.name)
        XCTAssertNotEqual(token.issuer, other_token.issuer)
        XCTAssertNotEqual(token.generator, other_token.generator)
    }

    func testDefaults() {
        guard let generator = Generator(
            factor: .Counter(0),
            secret: NSData(),
            algorithm: .SHA1,
            digits: 6
        ) else {
            XCTFail()
            return
        }
        let n = "Test Name"
        let i = "Test Issuer"

        let tokenWithDefaultName = Token(issuer: i, generator: generator)
        XCTAssertEqual(tokenWithDefaultName.name, "")
        XCTAssertEqual(tokenWithDefaultName.issuer, i)

        let tokenWithDefaultIssuer = Token(name: n, generator: generator)
        XCTAssertEqual(tokenWithDefaultIssuer.name, n)
        XCTAssertEqual(tokenWithDefaultIssuer.issuer, "")

        let tokenWithAllDefaults = Token(generator: generator)
        XCTAssertEqual(tokenWithAllDefaults.name, "")
        XCTAssertEqual(tokenWithAllDefaults.issuer, "")
    }
}
